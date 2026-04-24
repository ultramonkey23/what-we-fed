extends Node

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")

const THREAT_COUNT: int = 4
# fire_stagger is the wait between firing successive directions in a single cycle.
# Wider = each lane projectile arrives as a distinct timed event.
# Tighter = projectiles arrive in a cluster, reading the whole lane set at once.
# Must stay >= MIN_IMPACT_SEPARATION to avoid the second lane being blocked
# by the proximity check. Use set_fire_stagger() to change it at runtime.
var fire_stagger: float = 0.45
var cycle_interval: float = 2.2
var attack_authority_budget: int = THREAT_COUNT

const SPAWN_DISTANCE_RATIO: float = 0.42
const HIT_ZONE_DISTANCE: float = 110.0

const PROJECTILE_SCENE_PATH: String = "res://scenes/combat/Projectile.tscn"
const MELEE_APPROACH_SCRIPT_PATH: String = "res://scenes/combat/MeleeApproach.gd"
const MIN_IMPACT_SEPARATION: float = 0.40

# Status effect constants.
const REND_DAMAGE_MULT: float = 1.30        # +30% damage to the enemy while REND is active
const REND_BASE_CHARGES: int = 3            # REND consumes on hit; expires after 3 hits
const PALE_DAMAGE_MULT: float = 0.50        # PALE halves the enemy's next fired projectile damage
const EXPOSE_DAMAGE_MULT: float = 1.25      # +25% damage to the enemy while EXPOSE is active
const EXPOSE_BASE_DURATION: float = 2.5     # EXPOSE expires after 2.5 seconds
const GORGE_MARK_BONUS_CHARGE: float = 5.0  # Extra support charge when a GORGE-MARK enemy is defeated
const VENOM_DAMAGE_RATIO: float = 0.10      # 10% of max HP (or current?) dealt per beat
const VENOM_BASE_BEATS: int = 4
const SLOW_SPEED_MULT: float = 0.70         # -30% projectile speed while SLOW is active
const ENEMY_DEFENSE_MAX_REDUCTION_RATIO: float = 0.35
const ENEMY_DEFENSE_MIN_DAMAGE: float = 1.0

# Per-enemy-type status flags. bond_reaper: EXPOSE windows are shorter (harder to exploit).
# sovereign: REND can only be applied once (resilient apex predator).
const ENEMY_STATUS_FLAGS: Dictionary = {
	"bond_reaper": {"expose_duration_mult": 0.5},
	"sovereign": {"rend_max_charges": 1}
}

var combat_scene: Node = null

var _viewport_size: Vector2 = Vector2.ZERO
var _center_pos: Vector2 = Vector2.ZERO
var _threat_spawn_positions: Array[Vector2] = []
var _threat_hit_zone_positions: Array[Vector2] = []

var _projectile_scene: PackedScene = null
var _melee_approach_script: Script = null
var _projectile_slots: Array = [null, null, null, null]
var _enemies: Dictionary = {} # enemy_id -> Dictionary (Population)
var _strikers: Array[int] = [-1, -1, -1, -1] # enemy_id per direction (N, S, E, W)
var _orbiting_enemy_ids: Array[int] = [] # Ordered for fair authority
var _lane_authority_debt: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _lane_last_fired_cycle: Array[int] = [-999, -999, -999, -999]
var _fire_cycle_index: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _orbit_angles: Dictionary = {} # enemy_id -> float
var _orbit_radius_offsets: Dictionary = {} # enemy_id -> float
var _orbit_drift_accum: Dictionary = {} # enemy_id -> float
var _orbit_speed: float = 0.35 # Rad/sec
var _next_enemy_id: int = 5000 # For non-song mode or internal spawns

var _combat_running: bool = false
var _song_mode: bool = false
var _cycle_stalled: bool = false
var _punish_damage_mult: float = 1.0
# Per-lane active status. Only one status per lane at a time; new application overwrites.
# Structure: { "id": String, "hits_remaining": int, "duration": float, "fire_pending": bool }
var _enemy_statuses: Dictionary = {}

# _cycle_task_id is incremented every time start_combat() or stop() is called.
# _run_fire_cycle() captures the ID at launch and bails out if it no longer matches,
# preventing ghost fire cycles from continuing after combat has been stopped or restarted.
var _cycle_task_id: int = 0


func setup_layout(viewport_size: Vector2) -> void:
	# Computes the 4 cardinal threat positions centered on the screen.
	_viewport_size = viewport_size
	_center_pos = viewport_size * 0.5
	
	_threat_spawn_positions.clear()
	_threat_hit_zone_positions.clear()
	
	var spawn_dist: float = viewport_size.y * SPAWN_DISTANCE_RATIO
	
	# Mapping: 0=N, 1=S, 2=E, 3=W
	var directions = [
		Vector2(0, -1), # North
		Vector2(0, 1),  # South
		Vector2(1, 0),  # East
		Vector2(-1, 0)  # West
	]
	
	for dir in directions:
		_threat_spawn_positions.append(_center_pos + dir * spawn_dist)
		_threat_hit_zone_positions.append(_center_pos + dir * HIT_ZONE_DISTANCE)


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
	_strikers = [-1, -1, -1, -1]
	_orbiting_enemy_ids.clear()
	_orbit_angles.clear()
	_orbit_radius_offsets.clear()
	_orbit_drift_accum.clear()

	for lane in range(THREAT_COUNT):
		if lane < enemy_data.size():
			var enemy = enemy_data[lane].duplicate(true)
			var id = int(enemy.get("id", _next_enemy_id))
			if id == _next_enemy_id: _next_enemy_id += 1
			enemy["id"] = id
			enemy["lane"] = lane
			_enemies[id] = enemy
			_strikers[lane] = id

	_combat_running = true
	_cycle_task_id += 1
	_reset_attack_authority_state()

	if not EventBus.song_beat_pulse.is_connected(_on_song_beat_pulse):
		EventBus.song_beat_pulse.connect(_on_song_beat_pulse)

	EventBus.emit_signal("combat_started", enemy_data)
	_run_fire_cycle(_cycle_task_id)


func _on_song_beat_pulse(_beat_index: int, _intensity: float) -> void:
	if not _combat_running:
		return
	
	var expired: Array = []
	for id in _enemy_statuses:
		var status: Dictionary = _enemy_statuses[id]
		if status.get("id", "") == "venom":
			var beats: int = int(status.get("beats_remaining", 0))
			if beats > 0:
				# Apply venom damage
				var enemy: Dictionary = _enemies.get(id, {})
				if not enemy.is_empty() and enemy.has("max_hp"):
					var damage: float = float(enemy["max_hp"]) * float(status.get("venom_damage", 0.10))
					damage_enemy_by_id(id, damage)
					EventBus.proc_feedback_requested.emit("VENOM", Color(0.48, 0.12, 0.64, 1.0))
				
				status["beats_remaining"] = beats - 1
				if int(status["beats_remaining"]) <= 0:
					expired.append(id)
	
	for id in expired:
		_enemy_statuses.erase(id)
		# For backward compatibility, we'll try to find if this enemy is in a lane
		# but the new system uses enemy_id for status.
		var lane: int = _find_lane_for_enemy(id)
		if lane >= 0:
			EventBus.emit_signal("enemy_status_cleared", lane)


func get_projectile(lane: int):
	if lane < 0 or lane >= THREAT_COUNT:
		return null

	var projectile = _projectile_slots[lane]
	if projectile == null:
		return null

	if not is_instance_valid(projectile):
		_projectile_slots[lane] = null
		return null

	return projectile


func is_lane_empty(lane: int) -> bool:
	if lane < 0 or lane >= THREAT_COUNT:
		return false
	return _strikers[lane] == -1


func clear_slot(lane: int) -> void:
	if lane < 0 or lane >= THREAT_COUNT:
		return

	var existing = _projectile_slots[lane]
	if existing != null and is_instance_valid(existing):
		var is_melee_approach: bool = ("is_melee_approach" in existing and existing.get("is_melee_approach"))
		var is_resolved: bool = ("is_resolved" in existing and existing.get("is_resolved"))
		if is_melee_approach and not is_resolved:
			return  # Alive melee stays in slot; it bounces, not vanishes

	_projectile_slots[lane] = null


func get_player_pos() -> Vector2:
	return _center_pos


func get_threat_spawn_pos(lane: int) -> Vector2:
	if lane < 0 or lane >= _threat_spawn_positions.size():
		return _center_pos
	return _threat_spawn_positions[lane]


func get_threat_hit_zone_pos(lane: int) -> Vector2:
	if lane < 0 or lane >= _threat_hit_zone_positions.size():
		return _center_pos
	return _threat_hit_zone_positions[lane]


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


func set_punish_damage_mult(mult: float) -> void:
	_punish_damage_mult = clampf(mult, 0.75, 1.50)


func set_attack_authority_budget(budget: int) -> void:
	# Distinct from alive enemy count: only this many lanes can claim attack authority
	# in one fire cycle. Presence can stay high without unreadable overlap.
	attack_authority_budget = clampi(budget, 1, THREAT_COUNT)


func trigger_accent_burst() -> void:
	# Forces an immediate cycle start if combat is running and not currently firing.
	# If a cycle was already waiting, this effectively cancels the wait.
	if not _combat_running or _cycle_stalled:
		return
	
	# Accent refinement: briefly tighten fire_stagger for this immediate cycle 
	# to create a "chord" or "cluster" feel.
	var original_stagger = fire_stagger
	fire_stagger = 0.42 # Tightest possible safe stagger
	
	# Pull forward the cycle
	_cycle_task_id += 1
	_run_fire_cycle(_cycle_task_id)
	
	# Restore stagger
	get_tree().create_timer(cycle_interval * 0.5).timeout.connect(
		func(): fire_stagger = original_stagger
	)


func is_combat_running() -> bool:
	return _combat_running


func is_song_cycle_stalled() -> bool:
	return _cycle_stalled


func set_enemy(lane: int, enemy_data: Dictionary) -> void:
	# Places a new enemy in the population.
	# Restarts the fire cycle if it stalled because all enemies were defeated.
	var enemy = enemy_data.duplicate(true)
	var id = int(enemy.get("id", _next_enemy_id))
	if id == _next_enemy_id: _next_enemy_id += 1
	enemy["id"] = id
	_enemies[id] = enemy
	
	# Decide if they join orbit or take an empty lane
	if lane >= 0 and lane < THREAT_COUNT and _strikers[lane] == -1 and alive_striker_count() < attack_authority_budget:
		_strikers[lane] = id
		enemy["lane"] = lane
	else:
		_orbiting_enemy_ids.append(id)
		_orbit_angles[id] = _rng.randf_range(0.0, TAU)
		_orbit_radius_offsets[id] = _rng.randf_range(-15.0, 15.0)
		enemy["lane"] = -1
	
	if _song_mode:
		if not _combat_running:
			start_song_cycle()
		elif _cycle_stalled:
			_cycle_stalled = false
			_run_fire_cycle(_cycle_task_id)


func damage_enemy(lane: int, amount: float) -> void:
	# Applies damage to a lane's active enemy.
	if lane < 0 or lane >= THREAT_COUNT:
		return
	
	var id = _strikers[lane]
	if id == -1:
		return
		
	damage_enemy_by_id(id, amount)


func damage_enemy_by_id(id: int, amount: float) -> void:
	# Applies damage to an enemy by ID and handles defeat.
	var enemy = _enemies.get(id, {})
	if enemy.is_empty():
		return
	if not enemy.has("hp"):
		return
	if float(enemy["hp"]) <= 0.0:
		return

	# Status multipliers (REND, EXPOSE) are applied using the enemy ID now.
	var modified_amount: float = maxf(amount * _get_status_damage_mult_by_id(id), 0.0)
	if modified_amount <= 0.0:
		return
	var defense: float = maxf(float(enemy.get("defense", 0.0)), 0.0)
	var defense_reduction: float = minf(defense, modified_amount * ENEMY_DEFENSE_MAX_REDUCTION_RATIO)
	var actual_amount: float = maxf(modified_amount - defense_reduction, ENEMY_DEFENSE_MIN_DAMAGE)
	enemy["hp"] = max(float(enemy["hp"]) - actual_amount, 0.0)
	_enemies[id] = enemy

	EventBus.emit_signal("enemy_damaged", id, actual_amount)

	# Consume one REND charge per hit.
	if _enemy_statuses.has(id) and _enemy_statuses[id].get("id", "") == "rend":
		var rend: Dictionary = _enemy_statuses[id]
		rend["hits_remaining"] = rend.get("hits_remaining", 0) - 1
		if rend["hits_remaining"] <= 0:
			_enemy_statuses.erase(id)
			var lane = _find_lane_for_enemy(id)
			if lane >= 0: EventBus.emit_signal("enemy_status_cleared", lane)

	if float(enemy["hp"]) <= 0.0:
		_handle_enemy_defeat(id)


func _handle_enemy_defeat(id: int) -> void:
	# GORGE-MARK: emit triggered event for bonus charge before clearing.
	var lane = _find_lane_for_enemy(id)
	
	if _enemy_statuses.has(id) and _enemy_statuses[id].get("id", "") == "gorge_mark":
		_enemy_statuses.erase(id)
		if lane >= 0: 
			EventBus.emit_signal("enemy_status_applied", lane, "gorge_mark_triggered", {})
			EventBus.emit_signal("enemy_status_cleared", lane)
	elif _enemy_statuses.has(id):
		_enemy_statuses.erase(id)
		if lane >= 0: EventBus.emit_signal("enemy_status_cleared", lane)

	EventBus.emit_signal("enemy_defeated", id)

	if lane >= 0:
		var projectile = get_projectile(lane)
		if projectile != null:
			projectile.resolve("enemy_defeated")
			clear_slot(lane)
		_strikers[lane] = -1
	
	_orbiting_enemy_ids.erase(id)
	_orbit_angles.erase(id)
	_orbit_radius_offsets.erase(id)
	_enemies.erase(id)

	if alive_count() <= 0:
		if _song_mode:
			pass  # Song continues
		else:
			_combat_running = false
			EventBus.emit_signal("combat_ended", true)


func get_enemy(lane: int) -> Dictionary:
	if lane < 0 or lane >= THREAT_COUNT:
		return {}
	var id = _strikers[lane]
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
	var total: int = 0
	for id in _strikers:
		if id != -1:
			total += 1
	return total


func _find_lane_for_enemy(id: int) -> int:
	for i in range(THREAT_COUNT):
		if _strikers[i] == id:
			return i
	return -1


func stop() -> void:
	# Clears active projectile state, statuses, and stops future fire cycles.
	_combat_running = false
	_cycle_task_id += 1
	_cycle_stalled = false
	_enemy_statuses.clear()
	_reset_attack_authority_state()
	_enemies.clear()
	_strikers = [-1, -1, -1, -1]
	_orbiting_enemy_ids.clear()
	_orbit_angles.clear()
	_orbit_radius_offsets.clear()
	_orbit_drift_accum.clear()

	for lane in range(THREAT_COUNT):
		var projectile = get_projectile(lane)
		if projectile != null:
			projectile.queue_free()
		_projectile_slots[lane] = null


func _process(delta: float) -> void:
	# 1. Update Orbit Positions
	for id in _orbiting_enemy_ids:
		var current_angle: float = float(_orbit_angles[id]) if _orbit_angles.has(id) else 0.0
		_orbit_angles[id] = wrapf(current_angle + _orbit_speed * delta, 0.0, TAU)
		
		# Predatory Drifting: radius oscillates subtly to feel more "alive"
		var drift: float = float(_orbit_drift_accum[id]) if _orbit_drift_accum.has(id) else 0.0
		_orbit_drift_accum[id] = drift + delta * 0.4
		var base_offset: float = float(_orbit_radius_offsets[id]) if _orbit_radius_offsets.has(id) else 0.0
		_orbit_radius_offsets[id] = base_offset + sin(_orbit_drift_accum[id]) * 0.15
		
	# 2. Tick EXPOSE duration; clear when expired.
	var expired: Array = []
	for id in _enemy_statuses:
		var status: Dictionary = _enemy_statuses[id]
		if status.get("duration", -1.0) > 0.0:
			status["duration"] -= delta
			if status["duration"] <= 0.0:
				expired.append(id)
	for id in expired:
		_enemy_statuses.erase(id)
		var lane = _find_lane_for_enemy(id)
		if lane >= 0:
			EventBus.emit_signal("enemy_status_cleared", lane)


func apply_status(lane: int, status_id: String, params: Dictionary = {}) -> void:
	# Applies a combat status to the enemy in the given lane.
	if lane < 0 or lane >= THREAT_COUNT:
		return
	var id = _strikers[lane]
	if id == -1:
		return
	apply_status_by_id(id, status_id, params)


func apply_status_by_id(id: int, status_id: String, params: Dictionary = {}) -> void:
	var enemy: Dictionary = _enemies.get(id, {})
	if enemy.is_empty() or float(enemy.get("hp", 0.0)) <= 0.0:
		return

	var flags: Dictionary = _get_enemy_status_flags(enemy)
	var status: Dictionary = {"id": status_id, "hits_remaining": 0, "duration": -1.0, "fire_pending": false}

	match status_id:
		"rend":
			var base_charges: int = int(params.get("charges", REND_BASE_CHARGES))
			var max_charges: int = int(flags.get("rend_max_charges", REND_BASE_CHARGES))
			status["hits_remaining"] = min(base_charges, max_charges)
		"pale":
			status["fire_pending"] = true
		"gorge_mark":
			pass
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
		_:
			return

	_enemy_statuses[id] = status
	var lane = _find_lane_for_enemy(id)
	if lane >= 0:
		EventBus.emit_signal("enemy_status_applied", lane, status_id, params)


func get_status_id(lane: int) -> String:
	if lane < 0 or lane >= THREAT_COUNT: return ""
	var id = _strikers[lane]
	if id == -1 or not _enemy_statuses.has(id):
		return ""
	return String(_enemy_statuses[id].get("id", ""))


func _get_status_damage_mult_by_id(id: int) -> float:
	if not _enemy_statuses.has(id):
		return 1.0
	match _enemy_statuses[id].get("id", ""):
		"rend":
			return REND_DAMAGE_MULT
		"expose":
			return EXPOSE_DAMAGE_MULT
		_:
			return 1.0


func _run_fire_cycle(task_id: int) -> void:
	if not _combat_running or task_id != _cycle_task_id:
		return
	
	_cycle_stalled = false

	var paused: bool = false
	if _song_mode and combat_scene != null and combat_scene.has_method("is_song_paused"):
		paused = combat_scene.is_song_paused()

	if not paused:
		var lanes_to_fire: Array[int] = _resolve_authorized_lanes_for_cycle()
		for i in range(lanes_to_fire.size()):
			if not _combat_running or task_id != _cycle_task_id:
				return

			var lane: int = lanes_to_fire[i]
			if _fire_lane(lane):
				_lane_authority_debt[lane] = maxf(_lane_authority_debt[lane] - 2.0, 0.0)
				_lane_last_fired_cycle[lane] = _fire_cycle_index

			if i < lanes_to_fire.size() - 1:
				var offset_timer: SceneTreeTimer = get_tree().create_timer(fire_stagger)
				await offset_timer.timeout

	if not _combat_running or task_id != _cycle_task_id:
		return
		
	if alive_count() <= 0 and not paused:
		if _song_mode:
			_cycle_stalled = true
		return

	var cycle_timer: SceneTreeTimer = get_tree().create_timer(cycle_interval)
	await cycle_timer.timeout

	if _combat_running and task_id == _cycle_task_id:
		_run_fire_cycle(task_id)


func _fire_lane(lane: int) -> bool:
	if get_projectile(lane) != null:
		return false

	var id = _strikers[lane]
	if id == -1:
		return false
		
	var enemy: Dictionary = _enemies.get(id, {})
	if enemy.is_empty():
		return false

	var behaviour_tags = enemy.get("behaviour_tags", [])
	if behaviour_tags is Array and (behaviour_tags as Array).has("melee"):
		return _fire_melee_lane(lane, enemy, id)

	var projectile_speed: float = _get_enemy_projectile_speed(enemy)

	if not _can_schedule_projectile(projectile_speed):
		return false

	var projectile = _projectile_scene.instantiate()
	if projectile == null:
		return false

	var projectile_damage: float = float(enemy.get("damage", 8.0))
	projectile_damage *= _punish_damage_mult

	# PALE
	if _enemy_statuses.has(id) and _enemy_statuses[id].get("id", "") == "pale" and _enemy_statuses[id].get("fire_pending", false):
		projectile_damage *= PALE_DAMAGE_MULT
		_enemy_statuses.erase(id)
		EventBus.emit_signal("enemy_status_cleared", lane)

	var telegraph_profile: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
	telegraph_profile["projectile_body_path"] = COMBAT_CONTENT.get_projectile_body_resource_path(enemy)
	var section_id: String = ""
	if combat_scene != null and combat_scene.has_method("get_current_song_section_id"):
		section_id = String(combat_scene.get_current_song_section_id())
	var section_mod: String = COMBAT_CONTENT.get_shot_modifier_for_section(section_id)
	var species_mod: String = String(telegraph_profile.get("species_shot_modifier", "")).strip_edges()
	
	if not species_mod.is_empty():
		telegraph_profile["shot_modifier"] = species_mod
	else:
		telegraph_profile["shot_modifier"] = section_mod
	telegraph_profile.erase("species_shot_modifier")

	var player_combat: Node2D = null
	if combat_scene != null:
		player_combat = combat_scene.get_node_or_null("PlayerCombat") as Node2D

	combat_scene.add_child(projectile)
	projectile.setup(
		lane,
		id,
		projectile_damage,
		projectile_speed,
		get_threat_spawn_pos(lane),
		get_threat_hit_zone_pos(lane),
		get_player_pos(),
		telegraph_profile,
		player_combat
	)

	projectile.resolved.connect(_on_projectile_resolved.bind(lane))
	projectile.enemy_contact.connect(_on_projectile_enemy_contact.bind(lane))
	_projectile_slots[lane] = projectile

	# ABSOLUTE SONG SYNC:
	if _song_mode and combat_scene != null and combat_scene.has_method("get_song_conductor"):
		var conductor: Node = combat_scene.get_song_conductor()
		if conductor != null and conductor.has_method("get_song_elapsed"):
			var travel_time: float = _travel_time_to_hit_zone(projectile_speed)
			var song_now: float = conductor.call("get_song_elapsed")
			var hit_time: float = song_now + travel_time
			projectile.call("set_song_sync", conductor, hit_time)

	EventBus.emit_signal("projectile_fired", lane, id)
	return true


func _fire_melee_lane(lane: int, enemy: Dictionary, id: int) -> bool:
	if get_projectile(lane) != null:
		return false

	if _melee_approach_script == null:
		return false

	var melee: Node2D = _melee_approach_script.new() as Node2D
	if melee == null:
		return false

	var melee_damage: float = float(enemy.get("damage", 14.0)) * _punish_damage_mult
	var approach_speed: float = float(enemy.get("approach_speed", 80.0))

	combat_scene.add_child(melee)
	melee.call("setup",
		lane,
		id,
		melee_damage,
		approach_speed,
		get_threat_spawn_pos(lane),
		get_threat_hit_zone_pos(lane),
		get_player_pos(),
		{}
	)

	melee.connect("resolved", _on_projectile_resolved.bind(lane))
	melee.connect("player_contact", _on_melee_player_contact.bind(lane))
	_projectile_slots[lane] = melee

	EventBus.emit_signal("projectile_fired", lane, id)
	return true


func _on_melee_player_contact(_melee: Node2D, _lane: int) -> void:
	# Player damage is handled by PlayerCombat via its player_contact listener.
	# The melee entity auto-bounces in MeleeApproach._process_approach().
	pass


func _resolve_authorized_lanes_for_cycle() -> Array[int]:
	_fire_cycle_index += 1
	
	# 1. Promote Orbiting to Strikers if budget allows
	_promote_orbiting_to_strikers()
	
	var candidates: Array = []
	for lane in range(THREAT_COUNT):
		var id = _strikers[lane]
		if id == -1: continue
		
		var enemy: Dictionary = _enemies.get(id, {})
		if enemy.is_empty(): continue
		if get_projectile(lane) != null:
			continue
			
		_lane_authority_debt[lane] = minf(_lane_authority_debt[lane] + 1.0, 8.0)
		
		var damage_score: float = clampf(float(enemy.get("damage", 8.0)) / 10.0, 0.60, 1.80)
		var speed_score: float = clampf(_get_enemy_projectile_speed(enemy) / 320.0, 0.70, 1.70)
		var cycles_since_last: int = _fire_cycle_index - _lane_last_fired_cycle[lane]
		var age_bonus: float = clampf(float(cycles_since_last) / 4.0, 0.0, 1.4)
		var jitter: float = _rng.randf() * 0.08
		var score: float = _lane_authority_debt[lane] * 1.35 + age_bonus + damage_score * 0.35 + speed_score * 0.25 + jitter
		candidates.append({
			"lane": lane,
			"score": score
		})
		
	if candidates.is_empty():
		return []

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var budget: int = clampi(attack_authority_budget, 1, THREAT_COUNT)
	var selected_count: int = mini(budget, candidates.size())
	var selected_lanes: Array[int] = []
	for i in range(selected_count):
		selected_lanes.append(int(candidates[i]["lane"]))
	return selected_lanes


func _promote_orbiting_to_strikers() -> void:
	if _orbiting_enemy_ids.is_empty():
		return
		
	var budget = clampi(attack_authority_budget, 1, THREAT_COUNT)
	var current_strikers = alive_striker_count()
	
	# Try to fill lanes from orbit
	var orbit_index = 0
	while current_strikers < budget and orbit_index < _orbiting_enemy_ids.size():
		var id = _orbiting_enemy_ids[orbit_index]
		var best_lane = _pick_best_lane_for_strike(id)
		if best_lane != -1:
			_strikers[best_lane] = id
			_enemies[id]["lane"] = best_lane
			_orbiting_enemy_ids.remove_at(orbit_index)
			_orbit_angles.erase(id)
			_orbit_radius_offsets.erase(id)
			current_strikers += 1
			# Don't increment orbit_index as we just removed an element
		else:
			orbit_index += 1


func _pick_best_lane_for_strike(_id: int) -> int:
	var free_lanes = []
	for i in range(THREAT_COUNT):
		if _strikers[i] == -1:
			free_lanes.append(i)
	
	if free_lanes.is_empty():
		return -1
		
	return free_lanes[_rng.randi() % free_lanes.size()]


func get_enemy_pos(id: int) -> Vector2:
	if not _enemies.has(id):
		return _center_pos
		
	var lane = _find_lane_for_enemy(id)
	if lane >= 0:
		return get_threat_spawn_pos(lane)
		
	# If orbiting
	if _orbit_angles.has(id):
		var angle: float = float(_orbit_angles.get(id, 0.0))
		var radius: float = (_viewport_size.y * SPAWN_DISTANCE_RATIO) + float(_orbit_radius_offsets.get(id, 0.0))
		return _center_pos + Vector2(cos(angle), sin(angle)) * radius
		
	return _center_pos


func _reset_attack_authority_state() -> void:
	_lane_authority_debt = [0.0, 0.0, 0.0, 0.0]
	_lane_last_fired_cycle = [-999, -999, -999, -999]
	_fire_cycle_index = 0


func _can_schedule_projectile(new_speed: float) -> bool:
	# Prevents incoming hit windows from stacking too closely.
	var new_eta: float = _travel_time_to_hit_zone(new_speed)

	for lane in range(THREAT_COUNT):
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
	var distance: float = SPAWN_DISTANCE_RATIO * _viewport_size.y - HIT_ZONE_DISTANCE
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


func _get_enemy_status_flags(enemy: Dictionary) -> Dictionary:
	var enemy_type: String = String(enemy.get("type", "dreg"))
	var flags: Dictionary = ENEMY_STATUS_FLAGS.get(enemy_type, {}).duplicate(true)
	var explicit_flags: Dictionary = enemy.get("status_flags", {})
	for key in explicit_flags.keys():
		flags[key] = explicit_flags[key]
	return flags


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
	
	# Apply Slow Status
	var id = int(enemy.get("id", -1))
	if id != -1 and _enemy_statuses.has(id):
		var status: Dictionary = _enemy_statuses[id]
		if status.get("id", "") == "slow" or (status.get("id", "") == "venom" and bool(status.get("slow", false))):
			base_speed *= SLOW_SPEED_MULT
			
	return base_speed
