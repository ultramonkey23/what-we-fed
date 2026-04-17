extends Node

const LANE_COUNT: int = 3
# fire_stagger is the wait between firing successive lanes in a single cycle.
# Wider = each lane projectile arrives as a distinct timed event.
# Tighter = projectiles arrive in a cluster, reading the whole lane set at once.
# Must stay >= MIN_IMPACT_SEPARATION to avoid the second lane being blocked
# by the proximity check. Use set_fire_stagger() to change it at runtime.
var fire_stagger: float = 0.45
var cycle_interval: float = 2.2

const TOP_Y_RATIO: float = 0.24
const BOTTOM_Y_RATIO: float = 0.74
const PLAYER_X_RATIO: float = 0.16
const ENEMY_X_RATIO: float = 0.80
const HIT_ZONE_X_RATIO: float = 0.22

const PROJECTILE_SCENE_PATH: String = "res://scenes/combat/Projectile.tscn"
const MIN_IMPACT_SEPARATION: float = 0.40

# Status effect constants.
const REND_DAMAGE_MULT: float = 1.30        # +30% damage to the enemy while REND is active
const REND_BASE_CHARGES: int = 3            # REND consumes on hit; expires after 3 hits
const PALE_DAMAGE_MULT: float = 0.50        # PALE halves the enemy's next fired projectile damage
const EXPOSE_DAMAGE_MULT: float = 1.25      # +25% damage to the enemy while EXPOSE is active
const EXPOSE_BASE_DURATION: float = 2.5     # EXPOSE expires after 2.5 seconds
const GORGE_MARK_BONUS_CHARGE: float = 5.0  # Extra support charge when a GORGE-MARK enemy is defeated

# Per-enemy-type status flags. bond_reaper: EXPOSE windows are shorter (harder to exploit).
# sovereign: REND can only be applied once (resilient apex predator).
const ENEMY_STATUS_FLAGS: Dictionary = {
	"bond_reaper": {"expose_duration_mult": 0.5},
	"sovereign": {"rend_max_charges": 1}
}

var combat_scene: Node = null

var _viewport_size: Vector2 = Vector2.ZERO
var _lane_ys: Array[float] = []
var _player_x: float = 0.0
var _enemy_x: float = 0.0
var _hit_zone_x: float = 0.0

var _projectile_scene: PackedScene = null
var _projectile_slots: Array = [null, null, null]
var _enemies: Array[Dictionary] = []

var _combat_running: bool = false
var _song_mode: bool = false
var _cycle_stalled: bool = false
# Per-lane active status. Only one status per lane at a time; new application overwrites.
# Structure: { "id": String, "hits_remaining": int, "duration": float, "fire_pending": bool }
var _enemy_statuses: Dictionary = {}

# _cycle_task_id is incremented every time start_combat() or stop() is called.
# _run_fire_cycle() captures the ID at launch and bails out if it no longer matches,
# preventing ghost fire cycles from continuing after combat has been stopped or restarted.
var _cycle_task_id: int = 0


func setup_layout(viewport_size: Vector2) -> void:
	# Computes the three combat lane positions and anchor X points.
	_viewport_size = viewport_size
	_player_x = viewport_size.x * PLAYER_X_RATIO
	_enemy_x = viewport_size.x * ENEMY_X_RATIO
	_hit_zone_x = viewport_size.x * HIT_ZONE_X_RATIO

	_lane_ys.clear()

	var top_y: float = viewport_size.y * TOP_Y_RATIO
	var bottom_y: float = viewport_size.y * BOTTOM_Y_RATIO
	var spacing: float = (bottom_y - top_y) / float(LANE_COUNT - 1)

	for lane in range(LANE_COUNT):
		_lane_ys.append(top_y + spacing * lane)


func load_scene() -> bool:
	# Loads Projectile.tscn at runtime without preload, per project rules.
	if not ResourceLoader.exists(PROJECTILE_SCENE_PATH):
		push_error("Projectile scene not found: " + PROJECTILE_SCENE_PATH)
		return false

	var loaded_resource: Resource = load(PROJECTILE_SCENE_PATH)
	if loaded_resource == null or not (loaded_resource is PackedScene):
		push_error("Failed to load Projectile.tscn as PackedScene.")
		return false

	_projectile_scene = loaded_resource as PackedScene
	return true


func start_combat(enemy_data: Array) -> void:
	# Starts or restarts a combat cycle with one enemy dictionary per lane.
	if combat_scene == null:
		push_error("LaneManager.combat_scene must be set before start_combat().")
		return

	if _projectile_scene == null:
		push_error("LaneManager.load_scene() must be called before start_combat().")
		return

	stop()

	_enemies.clear()
	for lane in range(LANE_COUNT):
		if lane < enemy_data.size():
			_enemies.append(enemy_data[lane].duplicate(true))
		else:
			_enemies.append({})

	_combat_running = true
	_cycle_task_id += 1

	EventBus.emit_signal("combat_started", enemy_data)
	_run_fire_cycle(_cycle_task_id)


func get_projectile(lane: int):
	if lane < 0 or lane >= LANE_COUNT:
		return null

	var projectile = _projectile_slots[lane]
	if projectile == null:
		return null

	if not is_instance_valid(projectile):
		_projectile_slots[lane] = null
		return null

	return projectile


func clear_slot(lane: int) -> void:
	if lane < 0 or lane >= LANE_COUNT:
		return

	_projectile_slots[lane] = null


func get_lane_y(lane: int) -> float:
	if lane < 0 or lane >= _lane_ys.size():
		return 0.0
	return _lane_ys[lane]


func get_player_x() -> float:
	return _player_x


func get_enemy_x() -> float:
	return _enemy_x


func get_hit_zone_x() -> float:
	return _hit_zone_x


func set_cycle_interval(interval: float) -> void:
	cycle_interval = max(0.3, interval)


func set_fire_stagger(stagger: float) -> void:
	# Clamp to a safe range: lower bound respects MIN_IMPACT_SEPARATION so
	# sequential same-speed enemies always clear the ETA proximity check.
	fire_stagger = clamp(stagger, 0.42, 0.90)


func start_song_cycle() -> void:
	# Starts (or restarts) the fire cycle for song mode without resetting enemy data.
	_combat_running = true
	_cycle_stalled = false
	_cycle_task_id += 1
	_run_fire_cycle(_cycle_task_id)


func set_song_mode_enabled(enabled: bool) -> void:
	_song_mode = enabled


func is_combat_running() -> bool:
	return _combat_running


func is_song_cycle_stalled() -> bool:
	return _cycle_stalled


func set_enemy(lane: int, enemy_data: Dictionary) -> void:
	# Places a new enemy in a lane during song mode. Restarts the fire cycle
	# if it stalled because all enemies were defeated.
	if lane < 0 or lane >= LANE_COUNT:
		return
	# Lazy-init: _enemies is empty if start_combat() was never called (song mode entry).
	while _enemies.size() < LANE_COUNT:
		_enemies.append({})
	_enemies[lane] = enemy_data.duplicate(true)
	if _song_mode and _combat_running and _cycle_stalled:
		_cycle_stalled = false
		_run_fire_cycle(_cycle_task_id)


func damage_enemy(lane: int, amount: float) -> void:
	# Applies damage to a lane's active enemy and handles defeat.
	# Status multipliers (REND, EXPOSE) are applied before dealing damage.
	if lane < 0 or lane >= _enemies.size():
		return

	var enemy: Dictionary = _enemies[lane]
	if enemy.is_empty():
		return
	if not enemy.has("hp"):
		return
	if float(enemy["hp"]) <= 0.0:
		return

	var actual_amount: float = amount * _get_status_damage_mult(lane)
	enemy["hp"] = max(float(enemy["hp"]) - actual_amount, 0.0)
	_enemies[lane] = enemy

	EventBus.emit_signal("enemy_damaged", int(enemy.get("id", lane)), actual_amount)

	# Consume one REND charge per hit.
	if _enemy_statuses.has(lane) and _enemy_statuses[lane].get("id", "") == "rend":
		var rend: Dictionary = _enemy_statuses[lane]
		rend["hits_remaining"] = rend.get("hits_remaining", 0) - 1
		if rend["hits_remaining"] <= 0:
			_enemy_statuses.erase(lane)
			EventBus.emit_signal("enemy_status_cleared", lane)

	if float(enemy["hp"]) <= 0.0:
		# GORGE-MARK: emit triggered event for bonus charge before clearing.
		if _enemy_statuses.has(lane) and _enemy_statuses[lane].get("id", "") == "gorge_mark":
			_enemy_statuses.erase(lane)
			EventBus.emit_signal("enemy_status_applied", lane, "gorge_mark_triggered")
			EventBus.emit_signal("enemy_status_cleared", lane)
		elif _enemy_statuses.has(lane):
			_enemy_statuses.erase(lane)
			EventBus.emit_signal("enemy_status_cleared", lane)

		EventBus.emit_signal("enemy_defeated", int(enemy.get("id", lane)))

		var projectile = get_projectile(lane)
		if projectile != null:
			projectile.resolve("enemy_defeated")
			clear_slot(lane)

		if alive_count() <= 0:
			if _song_mode:
				pass  # Song continues; CombatScene will respawn enemies.
			else:
				_combat_running = false
				EventBus.emit_signal("combat_ended", true)


func get_enemy(lane: int) -> Dictionary:
	if lane < 0 or lane >= _enemies.size():
		return {}
	return _enemies[lane]


func alive_count() -> int:
	var total: int = 0
	for enemy in _enemies:
		if enemy.has("hp") and float(enemy["hp"]) > 0.0:
			total += 1
	return total


func stop() -> void:
	# Clears active projectile state, statuses, and stops future fire cycles.
	_combat_running = false
	_cycle_task_id += 1
	_cycle_stalled = false
	_enemy_statuses.clear()

	for lane in range(LANE_COUNT):
		var projectile = get_projectile(lane)
		if projectile != null:
			projectile.queue_free()
		_projectile_slots[lane] = null


func _process(delta: float) -> void:
	# Tick EXPOSE duration; clear when expired.
	var expired: Array = []
	for lane in _enemy_statuses:
		var status: Dictionary = _enemy_statuses[lane]
		if status.get("duration", -1.0) > 0.0:
			status["duration"] -= delta
			if status["duration"] <= 0.0:
				expired.append(lane)
	for lane in expired:
		_enemy_statuses.erase(lane)
		EventBus.emit_signal("enemy_status_cleared", lane)


func apply_status(lane: int, status_id: String, params: Dictionary = {}) -> void:
	# Applies a combat status to the enemy in the given lane.
	# One status per lane — new application always overwrites the previous one.
	if lane < 0 or lane >= LANE_COUNT:
		return
	var enemy: Dictionary = get_enemy(lane)
	if enemy.is_empty() or float(enemy.get("hp", 0.0)) <= 0.0:
		return

	var enemy_type: String = String(enemy.get("type", "dreg"))
	var flags: Dictionary = ENEMY_STATUS_FLAGS.get(enemy_type, {})
	var status: Dictionary = {"id": status_id, "hits_remaining": 0, "duration": -1.0, "fire_pending": false}

	match status_id:
		"rend":
			var base_charges: int = int(params.get("charges", REND_BASE_CHARGES))
			var max_charges: int = int(flags.get("rend_max_charges", REND_BASE_CHARGES))
			status["hits_remaining"] = min(base_charges, max_charges)
		"pale":
			status["fire_pending"] = true
		"gorge_mark":
			pass  # Persists until the enemy is defeated; no other expiry.
		"expose":
			var base_dur: float = float(params.get("duration", EXPOSE_BASE_DURATION))
			var dur_mult: float = float(flags.get("expose_duration_mult", 1.0))
			status["duration"] = base_dur * dur_mult
		_:
			return  # Unknown status — do nothing.

	_enemy_statuses[lane] = status
	EventBus.emit_signal("enemy_status_applied", lane, status_id)


func get_status_id(lane: int) -> String:
	# Returns the active status id for the given lane, or "" if none.
	if not _enemy_statuses.has(lane):
		return ""
	return String(_enemy_statuses[lane].get("id", ""))


func _get_status_damage_mult(lane: int) -> float:
	# Returns the incoming-damage multiplier for the current status on this lane.
	# REND (+30%) and EXPOSE (+25%) amplify damage. Others have no effect.
	if not _enemy_statuses.has(lane):
		return 1.0
	match _enemy_statuses[lane].get("id", ""):
		"rend":
			return REND_DAMAGE_MULT
		"expose":
			return EXPOSE_DAMAGE_MULT
		_:
			return 1.0


func _run_fire_cycle(task_id: int) -> void:
	if not _combat_running or task_id != _cycle_task_id:
		return

	for lane in range(LANE_COUNT):
		if not _combat_running or task_id != _cycle_task_id:
			return

		var enemy: Dictionary = get_enemy(lane)
		if enemy.has("hp") and float(enemy["hp"]) > 0.0:
			_fire_lane(lane)

		if lane < LANE_COUNT - 1:
			var offset_timer: SceneTreeTimer = get_tree().create_timer(fire_stagger)
			await offset_timer.timeout

	if not _combat_running or task_id != _cycle_task_id:
		return
	if alive_count() <= 0:
		if _song_mode:
			_cycle_stalled = true
		return

	var cycle_timer: SceneTreeTimer = get_tree().create_timer(cycle_interval)
	await cycle_timer.timeout

	if _combat_running and task_id == _cycle_task_id:
		_run_fire_cycle(task_id)


func _fire_lane(lane: int) -> void:
	if get_projectile(lane) != null:
		return

	var enemy: Dictionary = get_enemy(lane)
	if enemy.is_empty():
		return

	var enemy_type: String = String(enemy.get("type", "dreg"))
	var projectile_speed: float = _get_enemy_projectile_speed(enemy_type)

	if not _can_schedule_projectile(projectile_speed):
		return

	var projectile = _projectile_scene.instantiate()
	if projectile == null:
		return

	var projectile_damage: float = float(enemy.get("damage", 8.0))

	# PALE: halve the damage of the next fired projectile, then consume the status.
	if _enemy_statuses.has(lane) and _enemy_statuses[lane].get("fire_pending", false):
		projectile_damage *= PALE_DAMAGE_MULT
		_enemy_statuses.erase(lane)
		EventBus.emit_signal("enemy_status_cleared", lane)

	var enemy_id: int = int(enemy.get("id", lane))

	combat_scene.add_child(projectile)
	projectile.setup(
		lane,
		enemy_id,
		projectile_damage,
		projectile_speed,
		_enemy_x,
		_hit_zone_x,
		_player_x,
		get_lane_y(lane)
	)

	projectile.resolved.connect(_on_projectile_resolved.bind(lane))
	projectile.enemy_contact.connect(_on_projectile_enemy_contact.bind(lane))
	_projectile_slots[lane] = projectile

	EventBus.emit_signal("projectile_fired", lane, enemy_id)


func _can_schedule_projectile(new_speed: float) -> bool:
	# Prevents incoming hit windows from stacking too closely.
	var new_eta: float = _travel_time_to_hit_zone(new_speed)

	for lane in range(LANE_COUNT):
		var projectile = get_projectile(lane)
		if projectile == null:
			continue

		var existing_eta: float = projectile.time_until_hit_zone()
		if existing_eta < 0.0:
			continue

		if abs(existing_eta - new_eta) < MIN_IMPACT_SEPARATION:
			return false

	return true


func _travel_time_to_hit_zone(projectile_speed: float) -> float:
	var distance: float = _enemy_x - _hit_zone_x
	if projectile_speed <= 0.0:
		return 9999.0
	return distance / projectile_speed


func _on_projectile_resolved(projectile, result: String, lane: int) -> void:
	if get_projectile(lane) == projectile:
		_projectile_slots[lane] = null

	if result == "miss":
		EventBus.emit_signal("projectile_missed", lane, float(projectile.damage))


func _on_projectile_enemy_contact(projectile, lane: int) -> void:
	# Resolves reflected projectiles when they reach the enemy side.
	if projectile == null or projectile.is_resolved:
		return

	damage_enemy(lane, float(projectile.reflected_damage))
	projectile.resolve("reflected_hit")

	if get_projectile(lane) == projectile:
		_projectile_slots[lane] = null


func _get_enemy_projectile_speed(enemy_type: String) -> float:
	match enemy_type:
		"dreg":
			return 265.0
		"bond_reaper":
			return 430.0
		"sovereign":
			return 310.0
		_:
			return 265.0
