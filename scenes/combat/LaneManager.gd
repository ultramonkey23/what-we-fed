extends Node

const LANE_COUNT: int = 3
const FIRE_OFFSET: float = 0.45
const CYCLE_INTERVAL: float = 2.2

const TOP_Y_RATIO: float = 0.18
const BOTTOM_Y_RATIO: float = 0.68
const PLAYER_X_RATIO: float = 0.16
const ENEMY_X_RATIO: float = 0.80
const HIT_ZONE_X_RATIO: float = 0.22

const PROJECTILE_SCENE_PATH: String = "res://scenes/combat/Projectile.tscn"
const MIN_IMPACT_SEPARATION: float = 0.40

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


func damage_enemy(lane: int, amount: float) -> void:
	# Applies damage to a lane's active enemy and handles defeat.
	if lane < 0 or lane >= _enemies.size():
		return

	var enemy: Dictionary = _enemies[lane]
	if enemy.is_empty():
		return
	if not enemy.has("hp"):
		return
	if float(enemy["hp"]) <= 0.0:
		return

	enemy["hp"] = max(float(enemy["hp"]) - amount, 0.0)
	_enemies[lane] = enemy

	EventBus.emit_signal("enemy_damaged", int(enemy.get("id", lane)), amount)

	if float(enemy["hp"]) <= 0.0:
		EventBus.emit_signal("enemy_defeated", int(enemy.get("id", lane)))

		var projectile = get_projectile(lane)
		if projectile != null:
			projectile.resolve("enemy_defeated")
			clear_slot(lane)

		if alive_count() <= 0:
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
	# Clears active projectile state and stops future fire cycles.
	_combat_running = false
	_cycle_task_id += 1

	for lane in range(LANE_COUNT):
		var projectile = get_projectile(lane)
		if projectile != null:
			projectile.queue_free()
		_projectile_slots[lane] = null


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
			var offset_timer: SceneTreeTimer = get_tree().create_timer(FIRE_OFFSET)
			await offset_timer.timeout

	if not _combat_running or task_id != _cycle_task_id or alive_count() <= 0:
		return

	var cycle_timer: SceneTreeTimer = get_tree().create_timer(CYCLE_INTERVAL)
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
		"pack_dreg":
			return 315.0
		"bond_reaper":
			return 430.0
		"render":
			return 355.0
		_:
			return 265.0
