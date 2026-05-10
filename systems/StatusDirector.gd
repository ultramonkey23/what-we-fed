extends RefCounted
class_name StatusDirector

# Owns enemy affliction state and rules. LaneManager keeps spatial authority and
# calls this director for status mutation, ticking, and damage modifiers.

const PALE_DAMAGE_MULT: float = 0.50
const EXPOSE_DAMAGE_MULT: float = 1.25
const EXPOSE_BASE_DURATION: float = 2.5
const REND_DAMAGE_MULT: float = 1.50
const REND_HITS_BASE: int = 3
const GORGE_MARK_BONUS_CHARGE: float = 5.0
const VENOM_DAMAGE_RATIO: float = 0.10
const VENOM_BASE_BEATS: int = 4
const SLOW_SPEED_MULT: float = 0.70
const BLEED_MAX_STACKS: int = 5
const BLEED_DAMAGE_AMP_PER_STACK: float = 0.10

const ENEMY_STATUS_FLAGS: Dictionary = {
	"bond_reaper": {"expose_duration_mult": 0.5},
	"sovereign": {}
}

var _enemy_statuses: Dictionary = {}


func clear_all() -> void:
	_enemy_statuses.clear()


func apply_status(id: int, enemy: Dictionary, status_id: String, params: Dictionary = {}) -> void:
	if enemy.is_empty() or float(enemy.get("hp", 0.0)) <= 0.0:
		return

	var flags: Dictionary = get_enemy_status_flags(enemy)
	var status: Dictionary = {"id": status_id, "hits_remaining": 0, "duration": -1.0, "fire_pending": false}

	match status_id:
		"pale":
			status["fire_pending"] = true
		"gorge_mark":
			pass
		"rend":
			status["hits_remaining"] = int(params.get("hits", REND_HITS_BASE))
		"expose":
			var base_dur: float = float(params.get("duration", EXPOSE_BASE_DURATION))
			var dur_mult: float = float(flags.get("expose_duration_mult", 1.0))
			status["duration"] = base_dur * dur_mult
		"venom":
			status["beats_remaining"] = int(params.get("beats", VENOM_BASE_BEATS))
			status["venom_damage"] = float(params.get("damage_ratio", VENOM_DAMAGE_RATIO))
			status["slow"] = bool(params.get("slow", false))
		"slow":
			status["duration"] = float(params.get("duration", 2.0))
		"bleed":
			var current_stacks: int = 0
			if _enemy_statuses.has(id) and _enemy_statuses[id].get("id") == "bleed":
				current_stacks = int(_enemy_statuses[id].get("stacks", 0))
			status["stacks"] = clampi(current_stacks + 1, 1, BLEED_MAX_STACKS)
			EventBus.enemy_bleed_changed.emit(id, status["stacks"], BLEED_MAX_STACKS)
		_:
			return

	_enemy_statuses[id] = status
	EventBus.emit_signal("enemy_status_applied", id, status_id, params)


func clear_status(id: int) -> void:
	if _enemy_statuses.has(id):
		_enemy_statuses.erase(id)
		EventBus.emit_signal("enemy_status_cleared", id)


func clear_status_if_present(id: int, emit_only_if_lane_active: bool, lane_lookup: Callable) -> void:
	if not _enemy_statuses.has(id):
		return
	_enemy_statuses.erase(id)
	if not emit_only_if_lane_active or int(lane_lookup.call(id)) >= 0:
		EventBus.emit_signal("enemy_status_cleared", id)


func consume_rend_hit(id: int, lane_lookup: Callable) -> void:
	if not _enemy_statuses.has(id) or _enemy_statuses[id].get("id", "") != "rend":
		return
	var rend: Dictionary = _enemy_statuses[id]
	rend["hits_remaining"] = rend.get("hits_remaining", 0) - 1
	if int(rend["hits_remaining"]) <= 0:
		_enemy_statuses.erase(id)
		if int(lane_lookup.call(id)) >= 0:
			EventBus.emit_signal("enemy_status_cleared", id)
	else:
		_enemy_statuses[id] = rend


func clear_on_enemy_defeat(id: int) -> void:
	if not _enemy_statuses.has(id):
		return
	if _enemy_statuses[id].get("id", "") == "gorge_mark":
		_enemy_statuses.erase(id)
		EventBus.emit_signal("enemy_status_applied", id, "gorge_mark_triggered", {})
		EventBus.emit_signal("enemy_status_cleared", id)
	else:
		_enemy_statuses.erase(id)
		EventBus.emit_signal("enemy_status_cleared", id)


func consume_pale_fire_pending(id: int, lane_lookup: Callable) -> bool:
	if not _enemy_statuses.has(id):
		return false
	var status: Dictionary = _enemy_statuses[id]
	if status.get("id", "") != "pale" or not bool(status.get("fire_pending", false)):
		return false
	_enemy_statuses.erase(id)
	if int(lane_lookup.call(id)) >= 0:
		EventBus.emit_signal("enemy_status_cleared", id)
	return true


func tick_durations(delta: float, lane_lookup: Callable) -> void:
	var expired: Array = []
	for id in _enemy_statuses.keys():
		var status: Dictionary = _enemy_statuses[id]
		if float(status.get("duration", -1.0)) > 0.0:
			status["duration"] = float(status["duration"]) - delta
			_enemy_statuses[id] = status
			if float(status["duration"]) <= 0.0:
				expired.append(id)
	for id in expired:
		_enemy_statuses.erase(id)
		if int(lane_lookup.call(id)) >= 0:
			EventBus.emit_signal("enemy_status_cleared", id)


func tick_song_beat(enemies: Dictionary, damage_callback: Callable) -> void:
	var expired: Array = []
	for id in _enemy_statuses.keys():
		if not _enemy_statuses.has(id):
			continue
		var status: Dictionary = _enemy_statuses[id]
		if status.get("id", "") != "venom":
			continue
		var beats: int = int(status.get("beats_remaining", 0))
		if beats <= 0:
			continue

		var enemy: Dictionary = enemies.get(id, {})
		if not enemy.is_empty() and enemy.has("max_hp"):
			var damage: float = float(enemy["max_hp"]) * float(status.get("venom_damage", VENOM_DAMAGE_RATIO))
			damage_callback.call(id, damage)
			EventBus.proc_feedback_requested.emit("VENOM", Color(0.48, 0.12, 0.64, 1.0))

		if not _enemy_statuses.has(id):
			continue
		status = _enemy_statuses[id]
		status["beats_remaining"] = beats - 1
		_enemy_statuses[id] = status
		if int(status["beats_remaining"]) <= 0:
			expired.append(id)

	for id in expired:
		if _enemy_statuses.has(id):
			_enemy_statuses.erase(id)
			EventBus.emit_signal("enemy_status_cleared", id)


func get_damage_mult(id: int) -> float:
	if not _enemy_statuses.has(id):
		return 1.0
	match _enemy_statuses[id].get("id", ""):
		"expose":
			return EXPOSE_DAMAGE_MULT
		"rend":
			return REND_DAMAGE_MULT
		"bleed":
			var stacks: int = int(_enemy_statuses[id].get("stacks", 0))
			return 1.0 + (BLEED_DAMAGE_AMP_PER_STACK * stacks)
		_:
			return 1.0


func get_bleed_stacks(id: int) -> int:
	if _enemy_statuses.has(id) and _enemy_statuses[id].get("id") == "bleed":
		return int(_enemy_statuses[id].get("stacks", 0))
	return 0


func get_projectile_speed_mult(id: int) -> float:
	if not _enemy_statuses.has(id):
		return 1.0
	var status: Dictionary = _enemy_statuses[id]
	if status.get("id", "") == "slow" or (status.get("id", "") == "venom" and bool(status.get("slow", false))):
		return SLOW_SPEED_MULT
	return 1.0


func get_enemy_status_flags(enemy: Dictionary) -> Dictionary:
	var enemy_type: String = String(enemy.get("type", "dreg"))
	var flags: Dictionary = ENEMY_STATUS_FLAGS.get(enemy_type, {}).duplicate(true)
	var explicit_flags: Dictionary = enemy.get("status_flags", {})
	for key in explicit_flags.keys():
		flags[key] = explicit_flags[key]
	return flags
