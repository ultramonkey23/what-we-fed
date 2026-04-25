extends Node2D

# Same timing-window interface as Projectile — PlayerCombat and LaneManager
# interact with it through identical calls. Difference: resolve() bounces the
# entity back and it re-approaches until HP reaches zero.

signal reached_hit_zone(melee)
signal player_contact(melee)
@warning_ignore("unused_signal")
signal enemy_contact(melee)
signal resolved(melee, result: String)

const ATTACK_GOOD_MIN: float = 0.96
const ATTACK_PERFECT_MIN: float = 0.98
const ATTACK_PERFECT_MAX: float = 1.02
const ATTACK_GOOD_MAX: float = 1.04
const PARRY_GOOD_MIN: float = 0.96
const PARRY_PERFECT_MIN: float = 0.98
const PARRY_PERFECT_MAX: float = 1.02
const PARRY_GOOD_MAX: float = 1.04
const BOUNCE_SPEED_MULT: float = 2.0
const PLAYER_CONTACT_PROGRESS: float = 1.12
const _DEBUG_LOG_PATH: String = "debug-1960b2.log"
const _DEBUG_SESSION_ID: String = "1960b2"

# Duck-typing flag for LaneManager.clear_slot() guard.
const is_melee_approach: bool = true

var lane: int = 0
var enemy_id: int = -1
var damage: float = 12.0
var speed: float = 80.0
var reflected_damage: float = 0.0  # Projectile interface compat
var telegraph_profile: Dictionary = {}

var is_resolved: bool = false
var is_reflected: bool = false  # Projectile interface compat

var progress: float = 0.0
var _state: String = "approaching"
var _spawn_pos: Vector2
var _hit_zone_pos: Vector2
var _player_pos: Vector2
var _initial_dist: float
var _hit_zone_dist: float
var _approach_total: float
var _radial_dir: Vector2

var _reported_hit_zone: bool = false
var _reported_player_contact: bool = false

var _body: Polygon2D = null
var _inner_shard: Polygon2D = null
var _aura: Line2D = null
var _approach_tick: Line2D = null
var _base_color: Color = Color(0.90, 0.28, 0.10, 0.92)
var _hit_tween: Tween = null


func _agent_log(run_id: String, hypothesis_id: String, location: String, message: String, data: Dictionary = {}) -> void:
	var file: FileAccess = FileAccess.open(_DEBUG_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(_DEBUG_LOG_PATH, FileAccess.WRITE_READ)
	if file == null:
		return
	file.seek_end()
	var payload: Dictionary = {
		"sessionId": _DEBUG_SESSION_ID,
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000
	}
	file.store_line(JSON.stringify(payload))
	file.close()


func _ready() -> void:
	# Aura — expands and brightens as the entity closes.
	_aura = Line2D.new()
	_aura.name = "Aura"
	_aura.default_color = Color(0.90, 0.28, 0.10, 0.0)
	_aura.width = 2.8
	_aura.closed = true
	_aura.joint_mode = Line2D.LINE_JOINT_ROUND
	var aura_pts := PackedVector2Array()
	for i in range(20):
		var a: float = (float(i) / 20.0) * TAU
		aura_pts.append(Vector2(cos(a), sin(a)) * 28.0)
	_aura.points = aura_pts
	add_child(_aura)

	# Outer diamond — the primary readable shape.
	_body = Polygon2D.new()
	_body.name = "Body"
	_body.polygon = PackedVector2Array([
		Vector2(0.0, -22.0),
		Vector2(16.0, 0.0),
		Vector2(0.0, 14.0),
		Vector2(-16.0, 0.0)
	])
	_body.color = Color(0.90, 0.28, 0.10, 0.92)
	add_child(_body)

	# Inner shard — brighter core inside the diamond.
	_inner_shard = Polygon2D.new()
	_inner_shard.name = "InnerShard"
	_inner_shard.polygon = PackedVector2Array([
		Vector2(0.0, -11.0),
		Vector2(8.0, 0.0),
		Vector2(0.0, 7.0),
		Vector2(-8.0, 0.0)
	])
	_inner_shard.color = Color(1.0, 0.75, 0.50, 0.85)
	add_child(_inner_shard)

	# Approach tick — line pointing toward center so direction is always legible.
	# Local +X in this node points toward center (rotation is set to face player in setup).
	_approach_tick = Line2D.new()
	_approach_tick.name = "ApproachTick"
	_approach_tick.default_color = Color(1.0, 0.70, 0.40, 0.60)
	_approach_tick.width = 2.0
	_approach_tick.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_approach_tick.end_cap_mode = Line2D.LINE_CAP_ROUND
	_approach_tick.add_point(Vector2(18.0, 0.0))
	_approach_tick.add_point(Vector2(34.0, 0.0))
	add_child(_approach_tick)


func setup(
	melee_lane: int,
	melee_enemy_id: int,
	melee_damage: float,
	melee_speed: float,
	start_pos: Vector2,
	target_hit_zone_pos: Vector2,
	target_player_pos: Vector2,
	_melee_telegraph_profile: Dictionary = {}
) -> void:
	lane = melee_lane
	enemy_id = melee_enemy_id
	damage = melee_damage
	speed = melee_speed
	_spawn_pos = start_pos
	_hit_zone_pos = target_hit_zone_pos
	_player_pos = target_player_pos

	_initial_dist = start_pos.distance_to(target_player_pos)
	_hit_zone_dist = _hit_zone_pos.distance_to(target_player_pos)
	_approach_total = maxf(_initial_dist - _hit_zone_dist, 1.0)
	_radial_dir = (start_pos - target_player_pos).normalized()

	# Rotate to face center — local +X will point toward the player.
	rotation = (target_player_pos - start_pos).angle()

	position = start_pos
	progress = 0.0
	_state = "approaching"
	_reported_hit_zone = false
	_reported_player_contact = false

	_apply_lane_color(lane)


func _process(delta: float) -> void:
	if is_resolved:
		return

	match _state:
		"approaching":
			_process_approach(delta)
		"bouncing":
			_process_bounce(delta)

	_update_visuals()


func _process_approach(delta: float) -> void:
	progress += (speed * delta) / _approach_total

	var current_dist: float = lerpf(_initial_dist, _hit_zone_dist, progress)
	position = _player_pos + _radial_dir * current_dist

	if not _reported_hit_zone and progress >= 1.0:
		_reported_hit_zone = true
		reached_hit_zone.emit(self)

	if not _reported_player_contact and progress >= PLAYER_CONTACT_PROGRESS:
		_reported_player_contact = true
		player_contact.emit(self)
		# #region agent log
		_agent_log("baseline", "H2", "MeleeApproach.gd:_process_approach", "melee emitted player_contact", {
			"lane": lane,
			"enemy_id": enemy_id,
			"progress": progress
		})
		# #endregion
		_start_bounce()


func _process_bounce(delta: float) -> void:
	progress -= (speed * BOUNCE_SPEED_MULT * delta) / _approach_total
	progress = maxf(progress, 0.0)

	var current_dist: float = lerpf(_initial_dist, _hit_zone_dist, progress)
	position = _player_pos + _radial_dir * current_dist

	if progress <= 0.0:
		_state = "approaching"
		_reported_hit_zone = false
		_reported_player_contact = false


func evaluate_attack_timing() -> String:
	if is_resolved or _state == "bouncing":
		return "miss"
	if progress < ATTACK_GOOD_MIN:
		return "early"
	elif progress < ATTACK_PERFECT_MIN:
		return "good"
	elif progress <= ATTACK_PERFECT_MAX:
		return "perfect"
	elif progress <= ATTACK_GOOD_MAX:
		return "good"
	return "miss"


func evaluate_parry_timing() -> String:
	if is_resolved or _state == "bouncing":
		return "miss"
	if progress < PARRY_GOOD_MIN:
		return "early"
	elif progress < PARRY_PERFECT_MIN:
		return "good"
	elif progress <= PARRY_PERFECT_MAX:
		return "perfect"
	elif progress <= PARRY_GOOD_MAX:
		return "good"
	return "miss"


func time_until_hit_zone() -> float:
	if is_resolved or _state == "bouncing":
		return -1.0
	var remaining: float = maxf(1.0 - progress, 0.0)
	return (remaining * _approach_total) / maxf(speed, 1.0)


func time_until_player_contact() -> float:
	return time_until_hit_zone()


func resolve(result: String) -> void:
	if is_resolved:
		return
	if result == "enemy_defeated":
		is_resolved = true
		resolved.emit(self, result)
		# #region agent log
		_agent_log("baseline", "H4", "MeleeApproach.gd:resolve", "melee resolved enemy_defeated", {
			"lane": lane,
			"enemy_id": enemy_id
		})
		# #endregion
		var timer: SceneTreeTimer = get_tree().create_timer(0.10)
		timer.timeout.connect(queue_free)
	else:
		_start_bounce()


func reflect_to_enemy(_return_damage: float) -> void:
	_start_bounce()


func _start_bounce() -> void:
	_state = "bouncing"
	_flash_hit()


func _flash_hit() -> void:
	if _body == null or not is_inside_tree():
		return
	if _hit_tween != null:
		_hit_tween.kill()
	_hit_tween = create_tween()
	_hit_tween.tween_property(_body, "color", Color(1.0, 1.0, 1.0, 0.95), 0.04)
	_hit_tween.tween_property(_body, "color", _base_color, 0.14)
	_hit_tween.parallel().tween_property(_inner_shard, "color", Color(1.0, 1.0, 1.0, 0.95), 0.04)
	_hit_tween.tween_property(_inner_shard, "color", Color(1.0, 0.75, 0.50, 0.85), 0.14)


func _update_visuals() -> void:
	var approach_t: float = clampf(progress, 0.0, 1.0)
	var is_bouncing: bool = (_state == "bouncing")

	# Scale grows significantly as it closes — creates approach pressure.
	var scale_t: float = approach_t if not is_bouncing else clampf(progress, 0.0, 1.0)
	var entity_scale: float = lerpf(0.7, 1.3, scale_t)
	_body.scale = Vector2(entity_scale, entity_scale)
	_inner_shard.scale = Vector2(entity_scale, entity_scale)

	# Aura brightens and expands on approach, fades during bounce.
	var aura_alpha: float
	if is_bouncing:
		aura_alpha = lerpf(0.0, 0.30, scale_t)
	else:
		aura_alpha = lerpf(0.0, 0.70, approach_t)
	_aura.default_color.a = aura_alpha

	# Approach tick fades when bouncing (entity is retreating).
	_approach_tick.default_color.a = lerpf(0.60, 0.0, float(is_bouncing))


func _apply_lane_color(l: int) -> void:
	var colors: Array[Color] = [
		Color(0.65, 0.15, 0.88, 0.92),  # 0 = North: deep violet
		Color(0.15, 0.80, 0.44, 0.92),  # 1 = South: predatory green
		Color(0.92, 0.30, 0.08, 0.92),  # 2 = East:  threat orange-red
		Color(0.10, 0.48, 0.92, 0.92)   # 3 = West:  cold blue
	]
	var col: Color = colors[clampi(l, 0, colors.size() - 1)]
	_base_color = col
	if _body != null:
		_body.color = col
	if _aura != null:
		_aura.default_color = Color(col.r, col.g, col.b, 0.0)
	if _approach_tick != null:
		_approach_tick.default_color = Color(
			lerpf(col.r, 1.0, 0.45),
			lerpf(col.g, 1.0, 0.45),
			lerpf(col.b, 1.0, 0.45),
			0.60
		)
