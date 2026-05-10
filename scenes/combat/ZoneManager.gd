extends Node

const STATUS_DIRECTOR = preload("res://systems/StatusDirector.gd")
const SOVEREIGN_DAMAGE_CALCULATOR = preload("res://systems/SovereignDamageCalculator.gd")
const COMBAT_LIFECYCLE_DIRECTOR = preload("res://systems/CombatLifecycleDirector.gd")
const COMBAT_FIRE_DIRECTOR = preload("res://systems/CombatFireDirector.gd")
const CREATURE_LOCOMOTION_DIRECTOR = preload("res://systems/CreatureLocomotionDirector.gd")

const THREAT_COUNT: int = 8
# Attack cadence state (fire_stagger, cycle_interval, attack_authority_budget) lives in CombatFireDirector.
# Sector geometry constants (SPAWN_DISTANCE_RATIO, HIT_ZONE_DISTANCE, visual spreads) live in SectorLayout.

const PROJECTILE_SCENE_PATH: String = "res://scenes/combat/Projectile.tscn"
const MELEE_APPROACH_SCRIPT_PATH: String = "res://scenes/combat/MeleeApproach.gd"
const MIN_IMPACT_SEPARATION: float = 0.40

var combat_scene: Node = null
var _fire_director: Node = null
var _locom_director: Node = null

var _sector_layout: SectorLayout = null

var _projectile_scene: PackedScene = null
var _enemy_projectile_scenes: Dictionary = {} # enemy_id -> PackedScene
var _striker_objects: Dictionary = {} # enemy_id -> EnemyStriker
var _melee_approach_script: Script = null
var _active_projectiles: Dictionary = {} # enemy_id -> projectile node
var _enemies: Dictionary = {} # enemy_id -> Dictionary (Population)
var _strikers: Dictionary = {} # enemy_id -> Dictionary (Attacker state)
var _orbiting_enemy_ids: Array[int] = []
# Authority state (_enemy_authority_debt, _enemy_last_fired_cycle, _fire_cycle_index) lives in CombatFireDirector.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _enemy_positions: Dictionary = {} # enemy_id -> Vector2
var _orbit_angles: Dictionary = {} # enemy_id -> float
var _orbit_radius_offsets: Dictionary = {} # enemy_id -> float
var _enemy_visual_offsets: Dictionary = {} # enemy_id -> Vector2, presentation only
# _orbit_drift_accum and _orbit_speed live in CreatureLocomotionDirector.
var _next_enemy_id: int = 5000 # For non-song mode or internal spawns

var _song_mode: bool = false
# _combat_running and _cycle_stalled live in CombatFireDirector.
var _punish_damage_mult: float = 1.0
var _status_director: StatusDirector = STATUS_DIRECTOR.new()
var _lifecycle_director: RefCounted = COMBAT_LIFECYCLE_DIRECTOR.new()



func _ready() -> void:
	_sector_layout = SectorLayout.new()
	_fire_director = COMBAT_FIRE_DIRECTOR.new()
	_fire_director.name = "CombatFireDirector"
	add_child(_fire_director)
	_fire_director.init(self)
	_locom_director = CREATURE_LOCOMOTION_DIRECTOR.new()
	_locom_director.name = "CreatureLocomotionDirector"
	add_child(_locom_director)
	_locom_director.init(self, _enemies, _enemy_positions, _orbit_angles, _orbit_radius_offsets, _strikers)


func setup_layout(viewport_size: Vector2) -> void:
	_sector_layout.setup(viewport_size)


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

	if ResourceLoader.exists(MELEE_APPROACH_SCRIPT_PATH):
		var melee_script: Resource = load(MELEE_APPROACH_SCRIPT_PATH)
		if melee_script is Script:
			_melee_approach_script = melee_script as Script

	return true


func _cache_enemy_scene(id: int, enemy: Dictionary) -> void:
	var path: String = String(enemy.get("projectile_scene_path", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		_enemy_projectile_scenes[id] = scene if scene != null else _projectile_scene
	else:
		_enemy_projectile_scenes[id] = _projectile_scene


func start_combat(enemy_data: Array) -> void:
	# Starts or restarts a combat cycle with dynamic strikers.
	if combat_scene == null:
		push_error("LaneManager.combat_scene must be set before start_combat().")
		return

	if _projectile_scene == null:
		push_error("LaneManager.load_scene() must be called before start_combat().")
		return

	stop()

	_enemies.clear()
	_strikers.clear()
	_enemy_positions.clear()
	_orbiting_enemy_ids.clear()
	_orbit_angles.clear()
	_orbit_radius_offsets.clear()
	_enemy_visual_offsets.clear()

	for lane in range(enemy_data.size()):
		var enemy = enemy_data[lane].duplicate(true)
		var id = int(enemy.get("id", _next_enemy_id))
		if id == _next_enemy_id: _next_enemy_id += 1
		enemy["id"] = id
		enemy["lane"] = lane # Maintain legacy lane ID for signals
		_enemies[id] = enemy
		_cache_enemy_scene(id, enemy)
		var so_init := EnemyStriker.new()
		so_init.setup(enemy, _enemy_projectile_scenes.get(id, _projectile_scene) as PackedScene)
		_striker_objects[id] = so_init

		# Any-angle initialization: map 8 lanes to angles, but store as dynamic striker.
		var angle: float = (float(lane) / float(THREAT_COUNT)) * TAU - PI/2.0
		_strikers[id] = {"angle": angle, "lane": lane}
		_enemy_positions[id] = _sector_layout.get_spawn_pos_for_angle(angle)
		_assign_striker_visual_offset_for_angle(id, angle)
		_locom_director.on_enemy_added(id)

	if not EventBus.song_beat_pulse.is_connected(_on_song_beat_pulse):
		EventBus.song_beat_pulse.connect(_on_song_beat_pulse)

	EventBus.emit_signal("combat_started", enemy_data)
	_fire_director.start(_song_mode)


func _on_song_beat_pulse(_beat_index: int, _intensity: float, _quality: String) -> void:
	if not _fire_director.is_running():
		return
	_status_director.tick_song_beat(_enemies, Callable(self, "damage_enemy_by_id"))


func get_projectile(lane: int) -> Node:
	# VISUAL LOOKUP ONLY: Find the projectile currently associated with this spawn sector.
	for id in _active_projectiles:
		var striker = _strikers.get(id, {})
		if int(striker.get("lane", -1)) == lane:
			var projectile = _active_projectiles[id]
			if is_instance_valid(projectile):
				return projectile
	return null


func get_all_active_projectiles() -> Array[Node]:
	var result: Array[Node] = []
	for id in _active_projectiles:
		var projectile = _active_projectiles[id]
		if is_instance_valid(projectile):
			result.append(projectile)
	return result


func get_projectile_by_id(id: int) -> Node:
	var projectile = _active_projectiles.get(id)
	if is_instance_valid(projectile):
		return projectile
	return null


func get_enemy(lane: int) -> Dictionary:
	# VISUAL LOOKUP ONLY: Find the enemy currently associated with this spawn sector.
	for striker_id in _strikers:
		if int(_strikers[striker_id].get("lane", -1)) == lane:
			return _enemies.get(striker_id, {})
	return {}


func is_lane_empty(lane: int) -> bool:
	for id in _strikers:
		if int(_strikers[id].get("lane", -1)) == lane:
			return false
	return true


func get_enemy_by_id(id: int) -> Dictionary:
	return _enemies.get(id, {})


func get_all_enemies() -> Dictionary:
	return _enemies


func alive_count() -> int:
	var total: int = 0
	for id in _enemies:
		var enemy = _enemies[id]
		if enemy.has("hp") and float(enemy["hp"]) > 0.0:
			total += 1
	return total


func alive_striker_count() -> int:
	return _strikers.size()


func get_player_pos() -> Vector2:
	if combat_scene != null:
		var player = combat_scene.get_node_or_null("PlayerCombat")
		if player != null:
			return player.global_position
	return _sector_layout.center_pos


func get_arena_center() -> Vector2:
	return _sector_layout.center_pos


func get_spawn_distance() -> float:
	return _sector_layout.spawn_distance()


func notify_enemy_approaching(id: int) -> void:
	_locom_director.on_enemy_approaching(id)
	var striker_data: Dictionary = _strikers.get(id, {})
	var lane: int = int(striker_data.get("lane", -1))
	EventBus.emit_signal("enemy_attack_telegraphed", id, lane, get_enemy_pos(id), 0.36)
	# Compatibility sector pulse remains for HUD rhythm, but enemy intent now has its
	# own signal so it does not read like player input.
	if lane >= 0 and lane < THREAT_COUNT:
		EventBus.emit_signal("timing_ring_pressed", lane)


func get_threat_spawn_pos(lane: int) -> Vector2:
	return _sector_layout.get_spawn_pos(lane)


func get_threat_hit_zone_pos(lane: int) -> Vector2:
	return _sector_layout.get_hit_zone_pos(lane)


func get_spawn_pos_for_angle(angle: float) -> Vector2:
	return _sector_layout.get_spawn_pos_for_angle(angle)


func get_hit_zone_pos_for_angle(angle: float) -> Vector2:
	return _sector_layout.get_hit_zone_pos_for_angle(angle)


func set_cycle_interval(interval: float) -> void:
	_fire_director.set_cycle_interval(interval)


func set_fire_stagger(stagger: float) -> void:
	_fire_director.set_fire_stagger(stagger)


func start_song_cycle() -> void:
	# Compatibility wrapper: fire cycle authority lives in CombatFireDirector.
	_fire_director.start_song_cycle()


func set_song_mode_enabled(enabled: bool) -> void:
	_song_mode = enabled
	_fire_director.set_song_mode(enabled)


func set_punish_damage_mult(mult: float) -> void:
	_punish_damage_mult = clampf(mult, 0.75, 1.50)


func set_attack_authority_budget(budget: int) -> void:
	_fire_director.set_attack_authority_budget(budget)


func trigger_accent_burst() -> void:
	# Compatibility wrapper: burst scheduling lives in CombatFireDirector.
	_fire_director.trigger_accent_burst()


func is_combat_running() -> bool:
	return _fire_director.is_running()


func is_song_cycle_stalled() -> bool:
	return _fire_director.is_stalled()


func spawn_enemy_at_angle(angle: float, enemy_data: Dictionary) -> int:
	# SOVEREIGN SPATIAL: Spawning is now angle-driven, not lane-locked.
	var enemy = enemy_data.duplicate(true)
	var id = int(enemy.get("id", _next_enemy_id))
	if id == _next_enemy_id: _next_enemy_id += 1
	enemy["id"] = id
	
	# Determine legacy lane index for backward compatibility with older HUD/Signals
	var lane: int = _sector_layout.get_lane_from_angle(angle)
	enemy["lane"] = lane
	
	_enemies[id] = enemy
	_cache_enemy_scene(id, enemy)
	
	var so := EnemyStriker.new()
	so.setup(enemy, _enemy_projectile_scenes.get(id, _projectile_scene) as PackedScene)
	_striker_objects[id] = so

	# Logic for joining orbit vs striker slot remains authority-budget driven
	if alive_striker_count() < _fire_director.attack_authority_budget:
		_strikers[id] = {"angle": angle, "lane": lane}
		_enemy_positions[id] = _sector_layout.get_spawn_pos_for_angle(angle)
		_assign_striker_visual_offset_for_angle(id, angle)
		_locom_director.on_enemy_added(id)
	else:
		_orbiting_enemy_ids.append(id)
		_orbit_angles[id] = angle
		_orbit_radius_offsets[id] = _rng.randf_range(-28.0, 28.0)
		var radius: float = _sector_layout.spawn_distance() + float(_orbit_radius_offsets[id])
		_enemy_positions[id] = _sector_layout.center_pos + Vector2(cos(angle), sin(angle)) * radius
		_locom_director.on_enemy_added(id)

	if _song_mode:
		if not _fire_director.is_running():
			start_song_cycle()
		elif _fire_director.is_stalled():
			_fire_director.resume_stalled_cycle()
			
	return id


func set_enemy(lane: int, enemy_data: Dictionary) -> void:
	# LEGACY WRAPPER: Maps old lane-index calls to the new angle-driven spatial model.
	var angle: float = (float(lane) / float(THREAT_COUNT)) * TAU - PI/2.0
	if lane < 0:
		angle = _rng.randf_range(0.0, TAU)
	spawn_enemy_at_angle(angle, enemy_data)


func damage_enemy_by_id(id: int, amount: float) -> void:
	# Compatibility wrapper: damage math lives in SovereignDamageCalculator.
	var enemy = _enemies.get(id, {})
	if enemy.is_empty():
		return
	if not enemy.has("hp"):
		return
	if float(enemy["hp"]) <= 0.0:
		return

	var result: Dictionary = SOVEREIGN_DAMAGE_CALCULATOR.apply_enemy_damage(enemy, amount, _status_director.get_damage_mult(id))
	if not bool(result.get("applied", false)):
		return
	enemy = Dictionary(result.get("enemy", enemy))
	_enemies[id] = enemy

	EventBus.emit_signal("enemy_damaged", id, float(result.get("damage", 0.0)))

	_status_director.consume_rend_hit(id, Callable(self, "_find_lane_for_enemy"))

	if bool(result.get("defeated", false)):
		_handle_enemy_defeat(id)


func _handle_enemy_defeat(id: int) -> void:
	# Compatibility wrapper: defeat side effects and victory checks live in CombatLifecycleDirector.
	_lifecycle_director.resolve_enemy_defeat(
		id,
		_status_director,
		Callable(self, "remove_enemy_spatial"),
		Callable(self, "alive_count"),
		Callable(self, "_set_combat_running"),
		_song_mode
	)


func remove_enemy_spatial(id: int) -> void:
	# Spatial cleanup only: lifecycle/status/event authority lives outside LaneManager.
	var projectile = _active_projectiles.get(id)
	if projectile != null:
		if is_instance_valid(projectile):
			projectile.resolve("enemy_defeated")
		_active_projectiles.erase(id)
	
	_locom_director.on_enemy_removed(id)
	_strikers.erase(id)
	_enemy_positions.erase(id)
	_orbiting_enemy_ids.erase(id)
	_orbit_angles.erase(id)
	_orbit_radius_offsets.erase(id)
	_enemy_visual_offsets.erase(id)
	_enemy_projectile_scenes.erase(id)
	_striker_objects.erase(id)
	_enemies.erase(id)


func _set_combat_running(running: bool) -> void:
	_fire_director.set_combat_running(running)


func _find_lane_for_enemy(id: int) -> int:
	var striker = _strikers.get(id, {})
	return int(striker.get("lane", -1))


func _get_lane_from_angle(angle: float) -> int:
	return _sector_layout.get_lane_from_angle(angle)


func stop() -> void:
	# Clears active projectile state, statuses, and stops future fire cycles.
	_fire_director.stop()
	_locom_director.clear()
	_status_director.clear_all()
	_enemies.clear()
	_strikers.clear()
	_enemy_positions.clear()
	_orbiting_enemy_ids.clear()
	_orbit_angles.clear()
	_orbit_radius_offsets.clear()
	_enemy_visual_offsets.clear()
	_enemy_projectile_scenes.clear()
	_striker_objects.clear()

	for id in _active_projectiles:
		var projectile = _active_projectiles[id]
		if is_instance_valid(projectile):
			projectile.queue_free()
	_active_projectiles.clear()


func _process(delta: float) -> void:
	_locom_director.tick(delta)
	_status_director.tick_durations(delta, Callable(self, "_find_lane_for_enemy"))


func apply_status(enemy_id: int, status_id: String, params: Dictionary = {}) -> void:
	apply_status_by_id(enemy_id, status_id, params)


func apply_status_by_id(id: int, status_id: String, params: Dictionary = {}) -> void:
	# Compatibility wrapper: status rules live in StatusDirector.
	var enemy: Dictionary = _enemies.get(id, {})
	_status_director.apply_status(id, enemy, status_id, params)


func get_enemy_bleed_stacks(id: int) -> int:
	return _status_director.get_bleed_stacks(id)


func clear_enemy_status_by_id(id: int) -> void:
	_status_director.clear_status(id)


# ── Spatial queries and executor for CombatFireDirector ──────────────────────

func get_all_strikers() -> Dictionary:
	return _strikers


func has_active_projectile(id: int) -> bool:
	return _active_projectiles.has(id) and is_instance_valid(_active_projectiles[id])


func get_effective_projectile_speed(id: int) -> float:
	return _get_enemy_projectile_speed(_enemies.get(id, {}))


func execute_fire(id: int) -> bool:
	# Spatial executor: CombatFireDirector decides who fires; this performs the projectile spawn.
	var result: bool = _fire_striker(id)
	if result:
		_locom_director.on_enemy_fired(id)
	return result


## _run_fire_cycle removed — fire loop and striker authorization live in CombatFireDirector.


func _fire_striker(id: int) -> bool:
	if _active_projectiles.has(id) and is_instance_valid(_active_projectiles[id]):
		return false
		
	var enemy: Dictionary = _enemies.get(id, {})
	if enemy.is_empty():
		return false

	var striker_data = _strikers.get(id, {})
	var angle: float = float(striker_data.get("angle", 0.0))
	var lane: int = int(striker_data.get("lane", -1))

	var striker: EnemyStriker = _striker_objects.get(id) as EnemyStriker
	if striker == null:
		return false

	if striker.is_melee():
		return _fire_melee_striker(id, enemy, angle, lane)

	var base_speed: float = _get_enemy_projectile_speed(enemy)

	if not _can_schedule_projectile_id(base_speed):
		return false

	var scene: PackedScene = striker.projectile_scene
	if scene == null:
		return false
	var projectile: Projectile = scene.instantiate() as Projectile
	if projectile == null:
		return false

	var pale_active: bool = _status_director.consume_pale_fire_pending(id, Callable(self, "_find_lane_for_enemy"))

	var projectile_damage: float = striker.compute_projectile_damage(_punish_damage_mult, pale_active)
	var projectile_speed: float = striker.compute_projectile_speed(base_speed)

	var section_id: String = ""
	if combat_scene != null and combat_scene.has_method("get_current_song_section_id"):
		section_id = String(combat_scene.get_current_song_section_id())
	var telegraph_profile: Dictionary = striker.build_telegraph_profile(section_id)

	var player_pos: Vector2 = get_player_pos()
	var spawn_pos: Vector2 = get_enemy_pos(id)
	var player_combat: Node2D = null
	if combat_scene != null:
		player_combat = combat_scene.get_node_or_null("PlayerCombat") as Node2D
	var aimed_player_pos: Vector2 = _get_projectile_aim_point(player_pos, player_combat)
	# hit_zone_pos is the point where the projectile enters the player's timing ring.
	# Aim once at fire time; normal shots commit to this direction after launch.
	var dir_to_player: Vector2 = (aimed_player_pos - spawn_pos).normalized()
	if dir_to_player.length_squared() < 0.01:
		dir_to_player = Vector2(cos(angle), sin(angle)) * -1.0
	var hit_zone_pos: Vector2 = aimed_player_pos - dir_to_player * SectorLayout.HIT_ZONE_DISTANCE

	combat_scene.add_child(projectile)
	
	projectile.setup(
		lane,
		id,
		projectile_damage,
		projectile_speed,
		spawn_pos,
		hit_zone_pos,
		aimed_player_pos,
		telegraph_profile,
		player_combat
	)

	projectile.resolved.connect(_on_projectile_resolved_id.bind(id, lane))
	projectile.enemy_contact.connect(_on_projectile_enemy_contact_id.bind(id, lane))
	_active_projectiles[id] = projectile

	# ABSOLUTE SONG SYNC:
	if _song_mode and combat_scene != null:
		var conductor: SongConductor = combat_scene.get_song_conductor()
		if conductor != null:
			var travel_time: float = _travel_time_to_hit_zone(projectile_speed)
			var hit_time: float = conductor.get_song_time() + travel_time
			projectile.set_song_sync(conductor, hit_time)

	EventBus.emit_signal("projectile_fired", lane, id)
	return true


func _get_projectile_aim_point(current_player_pos: Vector2, player_combat: Node2D) -> Vector2:
	if player_combat == null or not is_instance_valid(player_combat):
		return current_player_pos
	var velocity_v: Variant = player_combat.get("_move_velocity")
	if typeof(velocity_v) != TYPE_VECTOR2:
		return current_player_pos
	var velocity: Vector2 = velocity_v
	if velocity.length_squared() < 4.0:
		return current_player_pos
	return current_player_pos + velocity * 0.16


func _fire_melee_striker(id: int, enemy: Dictionary, angle: float, lane: int) -> bool:
	if _active_projectiles.has(id) and is_instance_valid(_active_projectiles[id]):
		return false

	if _melee_approach_script == null:
		return false

	var melee: MeleeApproach = _melee_approach_script.new() as MeleeApproach
	if melee == null:
		return false

	var striker: EnemyStriker = _striker_objects.get(id) as EnemyStriker
	if striker == null:
		return false

	var melee_damage: float = striker.compute_melee_damage(_punish_damage_mult)
	var approach_speed: float = striker.compute_approach_speed()

	var player_pos: Vector2 = get_player_pos()
	var spawn_pos: Vector2 = get_enemy_pos(id)
	var dir_to_player: Vector2 = (player_pos - spawn_pos).normalized()
	var hit_zone_pos: Vector2 = player_pos - dir_to_player * SectorLayout.HIT_ZONE_DISTANCE

	var player_combat: Node2D = null
	if combat_scene != null:
		player_combat = combat_scene.get_node_or_null("PlayerCombat") as Node2D

	combat_scene.add_child(melee)

	melee.setup(
		lane,
		id,
		melee_damage,
		approach_speed,
		spawn_pos,
		hit_zone_pos,
		player_pos,
		{},
		player_combat
	)

	melee.connect("resolved", _on_projectile_resolved_id.bind(id, lane))
	melee.connect("player_contact", _on_melee_player_contact_id.bind(id, lane))
	_active_projectiles[id] = melee

	EventBus.emit_signal("projectile_fired", lane, id)
	return true


## _resolve_authorized_strikers_for_cycle removed — striker selection lives in CombatFireDirector.


func promote_orbiting(budget: int) -> void:
	# Called by CombatFireDirector: fills striker slots from the orbiting queue up to budget.
	if _orbiting_enemy_ids.is_empty():
		return

	var current_strikers: int = alive_striker_count()
	var orbit_index: int = 0
	while current_strikers < budget and orbit_index < _orbiting_enemy_ids.size():
		var id: int = _orbiting_enemy_ids[orbit_index]
		var angle: float = _orbit_angles.get(id, _rng.randf_range(0.0, TAU))
		var lane: int = _get_lane_from_angle(angle)

		_strikers[id] = {"angle": angle, "lane": lane}
		_enemies[id]["lane"] = lane
		_assign_striker_visual_offset_for_angle(id, angle)

		_orbiting_enemy_ids.remove_at(orbit_index)
		_orbit_angles.erase(id)
		_orbit_radius_offsets.erase(id)
		current_strikers += 1
		# Don't increment orbit_index — element was removed at that index.


func _pick_best_lane_for_strike(_id: int) -> int:
	var occupied_lanes = []
	for sid in _strikers:
		occupied_lanes.append(int(_strikers[sid].get("lane", -1)))

	var free_lanes = []
	for i in range(THREAT_COUNT):
		if not i in occupied_lanes:
			free_lanes.append(i)

	if free_lanes.is_empty():
		return -1

	return free_lanes[_rng.randi() % free_lanes.size()]

func get_enemy_pos(id: int) -> Vector2:
	if _enemy_positions.has(id):
		return _enemy_positions[id]

	if not _enemies.has(id):
		return _sector_layout.center_pos

	var lane = _find_lane_for_enemy(id)
	if lane >= 0:
		var visual_offset: Vector2 = _enemy_visual_offsets.get(id, Vector2.ZERO)
		return get_threat_spawn_pos(lane) + visual_offset

	return _sector_layout.center_pos


func _assign_striker_visual_offset_for_angle(id: int, angle: float) -> void:
	var radial: Vector2 = Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-radial.y, radial.x)
	var tangent_offset: float = _rng.randf_range(-SectorLayout.STRIKER_VISUAL_TANGENT_SPREAD, SectorLayout.STRIKER_VISUAL_TANGENT_SPREAD)
	var radial_offset: float = _rng.randf_range(-SectorLayout.STRIKER_VISUAL_RADIAL_SPREAD, SectorLayout.STRIKER_VISUAL_RADIAL_SPREAD)
	_enemy_visual_offsets[id] = tangent * tangent_offset + radial * radial_offset


func _can_schedule_projectile_id(new_speed: float) -> bool:
	# Prevents incoming hit windows from stacking too closely.
	var new_eta: float = _travel_time_to_hit_zone(new_speed)

	for id in _active_projectiles:
		var projectile = _active_projectiles[id]
		if not is_instance_valid(projectile):
			continue

		var existing_eta: float = projectile.time_until_hit_zone()
		if existing_eta < 0.0:
			continue

		if abs(existing_eta - new_eta) < MIN_IMPACT_SEPARATION:
			return false

	return true


func _travel_time_to_hit_zone(projectile_speed: float) -> float:
	var distance: float = _sector_layout.spawn_distance() - SectorLayout.HIT_ZONE_DISTANCE
	if projectile_speed <= 0.0:
		return 9999.0
	return distance / projectile_speed


func _on_projectile_resolved_id(projectile: Node, result: String, id: int, lane: int) -> void:
	if _active_projectiles.get(id) == projectile:
		_active_projectiles.erase(id)

	if result == "miss":
		EventBus.emit_signal("projectile_missed", lane, float(projectile.get("damage") if "damage" in projectile else 8.0))


func _on_projectile_enemy_contact_id(projectile: Projectile, id: int, _lane: int) -> void:
	# Resolves reflected projectiles when they reach the enemy side.
	if projectile == null or projectile.is_resolved:
		return

	var target_id: int = _resolve_reflected_projectile_target(id, projectile.global_position)
	if target_id >= 0:
		damage_enemy_by_id(target_id, float(projectile.get("reflected_damage") if "reflected_damage" in projectile else 0.0))
	projectile.resolve("reflected_hit")

	if _active_projectiles.get(id) == projectile:
		_active_projectiles.erase(id)


func _resolve_reflected_projectile_target(original_id: int, impact_pos: Vector2) -> int:
	var original: Dictionary = _enemies.get(original_id, {})
	if not original.is_empty() and float(original.get("hp", 0.0)) > 0.0:
		return original_id

	var best_id: int = -1
	var best_dist_sq: float = INF
	for enemy_id in _enemies.keys():
		var enemy: Dictionary = _enemies.get(enemy_id, {})
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var dist_sq: float = impact_pos.distance_squared_to(get_enemy_pos(int(enemy_id)))
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_id = int(enemy_id)
	return best_id


func _on_melee_player_contact_id(_melee: Node2D, _id: int, _lane: int) -> void:
	# Player damage is handled by PlayerCombat via its player_contact listener.
	# The melee entity auto-bounces in MeleeApproach._process_approach().
	pass


func debug_fire_lane(lane: int) -> bool:
	if not _fire_director.is_running():
		return false
	# Find first striker in this lane
	for id in _strikers:
		if int(_strikers[id].get("lane", -1)) == lane:
			return _fire_striker(id)
	return false


func _get_enemy_projectile_speed(enemy: Dictionary) -> float:
	var base_speed: float = 265.0
	
	if enemy.has("projectile_speed"):
		var explicit_speed: float = float(enemy.get("projectile_speed", 0.0))
		if explicit_speed > 0.0:
			base_speed = explicit_speed
	else:
		var enemy_type: String = String(enemy.get("type", "dreg"))
		match enemy_type:
			"dreg":
				base_speed = 265.0
			"bond_reaper":
				base_speed = 430.0
			"sovereign":
				base_speed = 310.0
			_:
				base_speed = 265.0
	
	var id = int(enemy.get("id", -1))
	if id != -1:
		base_speed *= _status_director.get_projectile_speed_mult(id)
			
	return base_speed
