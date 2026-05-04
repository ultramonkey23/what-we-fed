extends Node
class_name ZoneManager

const THREAT_COUNT: int = 8
# fire_stagger is the wait between firing successive directions in a single cycle.
# Wider = each lane projectile arrives as a distinct timed event.
# Tighter = projectiles arrive in a cluster, reading the whole lane set at once.
# Must stay >= MIN_IMPACT_SEPARATION to avoid the second lane being blocked
# by the proximity check. Use set_fire_stagger() to change it at runtime.
var fire_stagger: float = 0.38
var cycle_interval: float = 2.0
var attack_authority_budget: int = 4

const SPAWN_DISTANCE_RATIO: float = 0.42
const HIT_ZONE_DISTANCE: float = 110.0
const STRIKER_VISUAL_TANGENT_SPREAD: float = 32.0
const STRIKER_VISUAL_RADIAL_SPREAD: float = 18.0

const PROJECTILE_SCENE_PATH: String = "res://scenes/combat/Projectile.tscn"
const MELEE_APPROACH_SCRIPT_PATH: String = "res://scenes/combat/MeleeApproach.gd"
const MIN_IMPACT_SEPARATION: float = 0.40

# --- Hunting Field - Any-Angle Spawning ---
# Instead of fixed 8 positions, we can now derive any spawn point from an angle.
func get_spawn_pos_for_angle(angle: float) -> Vector2:
	var spawn_dist: float = _viewport_size.y * SPAWN_DISTANCE_RATIO
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	return _center_pos + dir * spawn_dist

func get_hit_zone_pos_for_angle(angle: float) -> Vector2:
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	return _center_pos + dir * HIT_ZONE_DISTANCE

# Status effect constants.
const PALE_DAMAGE_MULT: float = 0.50        # PALE halves the enemy's next fired projectile damage
const EXPOSE_DAMAGE_MULT: float = 1.25      # +25% damage to the enemy while EXPOSE is active
const EXPOSE_BASE_DURATION: float = 2.5     # EXPOSE expires after 2.5 seconds
const REND_DAMAGE_MULT: float = 1.50        # +50% damage while REND is active
const REND_HITS_BASE: int = 3               # REND lasts for 3 hits by default
const GORGE_MARK_BONUS_CHARGE: float = 5.0  # Extra support charge when a GORGE-MARK enemy is defeated
const VENOM_DAMAGE_RATIO: float = 0.10      # 10% of max HP (or current?) dealt per beat
const VENOM_BASE_BEATS: int = 4
const SLOW_SPEED_MULT: float = 0.70         # -30% projectile speed while SLOW is active
const ENEMY_DEFENSE_MAX_REDUCTION_RATIO: float = 0.35
const ENEMY_DEFENSE_MIN_DAMAGE: float = 1.0

# Bleed / Blood-Ember constants
const BLEED_MAX_STACKS: int = 5
const BLEED_DAMAGE_AMP_PER_STACK: float = 0.10 # +10% damage per stack (Sovereign Burn synergy)

# Per-enemy-type status flags. bond_reaper: EXPOSE windows are shorter (harder to exploit).
# sovereign: REND can only be applied once (resilient apex predator).
const ENEMY_STATUS_FLAGS: Dictionary = {
	"bond_reaper": {"expose_duration_mult": 0.5},
	"sovereign": {}
}

var combat_scene: CombatScene = null

var _viewport_size: Vector2 = Vector2.ZERO
var _center_pos: Vector2 = Vector2.ZERO
var _threat_spawn_positions: Array[Vector2] = []
var _threat_hit_zone_positions: Array[Vector2] = []

var _projectile_scene: PackedScene = null
var _enemy_projectile_scenes: Dictionary = {} # enemy_id -> PackedScene
var _striker_objects: Dictionary = {} # enemy_id -> EnemyStriker
var _melee_approach_script: Script = null
var _active_projectiles: Dictionary = {} # enemy_id -> projectile node
var _enemies: Dictionary = {} # enemy_id -> Dictionary (Population)
var _strikers: Dictionary = {} # enemy_id -> Dictionary (Attacker state)
var _orbiting_enemy_ids: Array[int] = [] # Ordered for fair authority
var _enemy_authority_debt: Dictionary = {} # enemy_id -> float
var _enemy_last_fired_cycle: Dictionary = {} # enemy_id -> int
var _fire_cycle_index: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _enemy_positions: Dictionary = {} # enemy_id -> Vector2
var _orbit_angles: Dictionary = {} # enemy_id -> float
var _orbit_radius_offsets: Dictionary = {} # enemy_id -> float
var _orbit_drift_accum: Dictionary = {} # enemy_id -> float
var _enemy_visual_offsets: Dictionary = {} # enemy_id -> Vector2, presentation only
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
	# Computes the 8 cardinal and intercardinal threat positions centered on the screen.
	var safe_size: Vector2 = viewport_size
	if safe_size.x < 10.0 or safe_size.y < 10.0:
		safe_size = Vector2(1280.0, 720.0) # Fallback to HD default

	_viewport_size = safe_size
	_center_pos = safe_size * 0.5

	_threat_spawn_positions.clear()
	_threat_hit_zone_positions.clear()

	var spawn_dist: float = safe_size.y * SPAWN_DISTANCE_RATIO	
	
	# Mapping 8 directions: N, NE, E, SE, S, SW, W, NW
	for i in range(THREAT_COUNT):
		var angle: float = (float(i) / float(THREAT_COUNT)) * TAU - PI/2.0
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
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
	_orbit_drift_accum.clear()
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
		
		var spawn_dist: float = _viewport_size.y * SPAWN_DISTANCE_RATIO
		_enemy_positions[id] = _center_pos + Vector2(cos(angle), sin(angle)) * spawn_dist
		
		_assign_striker_visual_offset_for_angle(id, angle)

	_combat_running = true
	_cycle_task_id += 1
	_reset_attack_authority_state()

	if not EventBus.song_beat_pulse.is_connected(_on_song_beat_pulse):
		EventBus.song_beat_pulse.connect(_on_song_beat_pulse)

	EventBus.emit_signal("combat_started", enemy_data)
	_run_fire_cycle(_cycle_task_id)


func _on_song_beat_pulse(_beat_index: int, _intensity: float, _quality: String) -> void:
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
		EventBus.emit_signal("enemy_status_cleared", id)


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
	_cache_enemy_scene(id, enemy)
	var so := EnemyStriker.new()
	so.setup(enemy, _enemy_projectile_scenes.get(id, _projectile_scene) as PackedScene)
	_striker_objects[id] = so

	# Decide if they join orbit or take a striker slot
	# Hunting Field expansion: attack_authority_budget now allows more than 8.
	if alive_striker_count() < attack_authority_budget:
		var angle: float = (float(lane) / float(THREAT_COUNT)) * TAU - PI/2.0
		if lane < 0:
			angle = _rng.randf_range(0.0, TAU)
		
		_strikers[id] = {"angle": angle, "lane": lane}
		enemy["lane"] = lane
		
		var spawn_dist: float = _viewport_size.y * SPAWN_DISTANCE_RATIO
		_enemy_positions[id] = _center_pos + Vector2(cos(angle), sin(angle)) * spawn_dist
		
		_assign_striker_visual_offset_for_angle(id, angle)
	else:
		_orbiting_enemy_ids.append(id)
		var angle: float = _rng.randf_range(0.0, TAU)
		_orbit_angles[id] = angle
		_orbit_radius_offsets[id] = _rng.randf_range(-28.0, 28.0)
		enemy["lane"] = -1
		
		var radius: float = (_viewport_size.y * SPAWN_DISTANCE_RATIO) + float(_orbit_radius_offsets[id])
		_enemy_positions[id] = _center_pos + Vector2(cos(angle), sin(angle)) * radius
	
	if _song_mode:
		if not _combat_running:
			start_song_cycle()
		elif _cycle_stalled:
			_cycle_stalled = false
			_run_fire_cycle(_cycle_task_id)


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
			if lane >= 0: EventBus.emit_signal("enemy_status_cleared", id)

	if float(enemy["hp"]) <= 0.0:
		_handle_enemy_defeat(id)


func _handle_enemy_defeat(id: int) -> void:
	# GORGE-MARK: emit triggered event for bonus charge before clearing.
	var lane = _find_lane_for_enemy(id)
	
	if _enemy_statuses.has(id) and _enemy_statuses[id].get("id", "") == "gorge_mark":
		_enemy_statuses.erase(id)
		EventBus.emit_signal("enemy_status_applied", id, "gorge_mark_triggered", {})
		EventBus.emit_signal("enemy_status_cleared", id)
	elif _enemy_statuses.has(id):
		_enemy_statuses.erase(id)
		EventBus.emit_signal("enemy_status_cleared", id)

	EventBus.emit_signal("enemy_defeated", id)

	var projectile = _active_projectiles.get(id)
	if projectile != null:
		if is_instance_valid(projectile):
			projectile.resolve("enemy_defeated")
		_active_projectiles.erase(id)
	
	_strikers.erase(id)
	_enemy_positions.erase(id)
	_orbiting_enemy_ids.erase(id)
	_orbit_angles.erase(id)
	_orbit_radius_offsets.erase(id)
	_enemy_visual_offsets.erase(id)
	_enemy_projectile_scenes.erase(id)
	_striker_objects.erase(id)
	_enemies.erase(id)

	if alive_count() <= 0:
		if _song_mode:
			pass  # Song continues
		else:
			_combat_running = false
			EventBus.emit_signal("combat_ended", true)


func _find_lane_for_enemy(id: int) -> int:
	var striker = _strikers.get(id, {})
	return int(striker.get("lane", -1))


func _get_lane_from_angle(angle: float) -> int:
	# Sector size is TAU/8 (45 degrees)
	var sector: float = TAU / 8.0
	# Offset so sector 0 is centered on -PI/2 (North)
	var norm_angle: float = fposmod(angle + PI/2.0 + sector/2.0, TAU)
	return int(floor(norm_angle / sector)) % 8


func stop() -> void:
	# Clears active projectile state, statuses, and stops future fire cycles.
	_combat_running = false
	_cycle_task_id += 1
	_cycle_stalled = false
	_enemy_statuses.clear()
	_reset_attack_authority_state()
	_enemies.clear()
	_strikers.clear()
	_enemy_positions.clear()
	_orbiting_enemy_ids.clear()
	_orbit_angles.clear()
	_orbit_radius_offsets.clear()
	_orbit_drift_accum.clear()
	_enemy_visual_offsets.clear()
	_enemy_projectile_scenes.clear()
	_striker_objects.clear()

	for id in _active_projectiles:
		var projectile = _active_projectiles[id]
		if is_instance_valid(projectile):
			projectile.queue_free()
	_active_projectiles.clear()


func _process(delta: float) -> void:
	var player_pos: Vector2 = get_player_pos()
	var base_radius: float = _viewport_size.y * SPAWN_DISTANCE_RATIO
	
	# 1. Update all enemy positions using Spatial Steering
	for id in _enemies:
		if not _enemy_positions.has(id):
			continue
			
		var pos: Vector2 = _enemy_positions[id]
		var to_player: Vector2 = player_pos - pos
		var dist: float = to_player.length()
		
		if dist < 1.0: # Prevent div by zero
			continue
			
		var dir: Vector2 = to_player / dist
		
		# Resolve desired radius: Orbiters stay out, Strikers might lean in.
		var target_radius: float = base_radius
		if _orbit_radius_offsets.has(id):
			target_radius += float(_orbit_radius_offsets[id])
		
		# Strikers lean in slightly when authorized to attack
		if _strikers.has(id):
			target_radius *= 0.85
			
		# Predatory Drifting (from legacy logic)
		var drift_accum: float = float(_orbit_drift_accum.get(id, 0.0)) + delta * 0.4
		_orbit_drift_accum[id] = drift_accum
		target_radius += sin(drift_accum) * 12.0
		
		# Steering: Radial correction towards target radius
		var radius_error: float = dist - target_radius
		# Move towards radius (Arrival-style)
		var radial_vel: float = radius_error * 2.5
		
		# Angular steering (Orbiting)
		# We maintain a consistent orbit speed but allow it to be influenced by position
		var tangent: Vector2 = Vector2(-dir.y, dir.x)
		var angular_vel: float = _orbit_speed * target_radius
		
		# Final Velocity Integration
		var velocity: Vector2 = (dir * radial_vel) + (tangent * angular_vel)
		
		# Apply movement
		_enemy_positions[id] = pos + velocity * delta
		
		# Sync legacy angle for visual/scaffolding compatibility
		var angle: float = (pos - player_pos).angle()
		_orbit_angles[id] = angle
		if _strikers.has(id):
			_strikers[id]["angle"] = angle
		
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
			EventBus.emit_signal("enemy_status_cleared", id)


func apply_status(enemy_id: int, status_id: String, params: Dictionary = {}) -> void:
	apply_status_by_id(enemy_id, status_id, params)


func apply_status_by_id(id: int, status_id: String, params: Dictionary = {}) -> void:
	var enemy: Dictionary = _enemies.get(id, {})
	if enemy.is_empty() or float(enemy.get("hp", 0.0)) <= 0.0:
		return

	var flags: Dictionary = _get_enemy_status_flags(enemy)
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


func _get_status_damage_mult_by_id(id: int) -> float:
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


func get_enemy_bleed_stacks(id: int) -> int:
	if _enemy_statuses.has(id) and _enemy_statuses[id].get("id") == "bleed":
		return int(_enemy_statuses[id].get("stacks", 0))
	return 0


func clear_enemy_status_by_id(id: int) -> void:
	if _enemy_statuses.has(id):
		_enemy_statuses.erase(id)
		EventBus.emit_signal("enemy_status_cleared", id)


func _run_fire_cycle(task_id: int) -> void:
	if not _combat_running or task_id != _cycle_task_id:
		return
	
	_cycle_stalled = false

	var paused: bool = false
	if _song_mode and combat_scene != null and combat_scene.has_method("is_song_paused"):
		paused = combat_scene.is_song_paused()

	if not paused:
		var ids_to_fire: Array[int] = _resolve_authorized_strikers_for_cycle()
		for i in range(ids_to_fire.size()):
			if not _combat_running or task_id != _cycle_task_id:
				return

			var id: int = ids_to_fire[i]
			if _fire_striker(id):
				_enemy_authority_debt[id] = maxf(_enemy_authority_debt.get(id, 0.0) - 2.0, 0.0)
				_enemy_last_fired_cycle[id] = _fire_cycle_index

			if i < ids_to_fire.size() - 1:
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

	var pale_active: bool = false
	if _enemy_statuses.has(id) and _enemy_statuses[id].get("id", "") == "pale" and _enemy_statuses[id].get("fire_pending", false):
		pale_active = true
		_enemy_statuses.erase(id)
		if lane >= 0: EventBus.emit_signal("enemy_status_cleared", id)

	var projectile_damage: float = striker.compute_projectile_damage(_punish_damage_mult, pale_active)
	var projectile_speed: float = striker.compute_projectile_speed(base_speed)

	var section_id: String = ""
	if combat_scene != null and combat_scene.has_method("get_current_song_section_id"):
		section_id = String(combat_scene.get_current_song_section_id())
	var telegraph_profile: Dictionary = striker.build_telegraph_profile(section_id)

	var player_pos: Vector2 = get_player_pos()
	var spawn_pos: Vector2 = get_enemy_pos(id)
	# hit_zone_pos is the point where the projectile enters the player's timing ring.
	# We calculate it dynamically based on the current relative vector.
	var dir_to_player: Vector2 = (player_pos - spawn_pos).normalized()
	var hit_zone_pos: Vector2 = player_pos - dir_to_player * HIT_ZONE_DISTANCE

	var player_combat: Node2D = null
	if combat_scene != null:
		player_combat = combat_scene.get_node_or_null("PlayerCombat") as Node2D

	combat_scene.add_child(projectile)
	
	projectile.setup(
		lane,
		id,
		projectile_damage,
		projectile_speed,
		spawn_pos,
		hit_zone_pos,
		player_pos,
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
	var hit_zone_pos: Vector2 = player_pos - dir_to_player * HIT_ZONE_DISTANCE

	var player_combat: PlayerCombat = null
	if combat_scene != null:
		player_combat = combat_scene.get_node_or_null("PlayerCombat") as PlayerCombat

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


func _resolve_authorized_strikers_for_cycle() -> Array[int]:
	_fire_cycle_index += 1
	
	# 1. Promote Orbiting to Strikers if budget allows
	_promote_orbiting_to_strikers()
	
	var candidates: Array = []
	for id in _strikers:
		var enemy: Dictionary = _enemies.get(id, {})
		if enemy.is_empty(): continue
		if _active_projectiles.has(id) and is_instance_valid(_active_projectiles[id]):
			continue
			
		_enemy_authority_debt[id] = minf(_enemy_authority_debt.get(id, 0.0) + 1.0, 8.0)

		var cycles_since_last: int = _fire_cycle_index - int(_enemy_last_fired_cycle.get(id, -999))
		var cooldown_cycles: int = int(enemy.get("cooldown_cycles", 0))
		if cooldown_cycles > 0 and cycles_since_last < cooldown_cycles:
			continue

		var damage_score: float = clampf(float(enemy.get("damage", 8.0)) / 10.0, 0.60, 1.80)
		var speed_score: float = clampf(_get_enemy_projectile_speed(enemy) / 320.0, 0.70, 1.70)
		var age_bonus: float = clampf(float(cycles_since_last) / 4.0, 0.0, 1.4)
		var jitter: float = _rng.randf() * 0.08
		var score: float = _enemy_authority_debt[id] * 1.35 + age_bonus + damage_score * 0.35 + speed_score * 0.25 + jitter
		
		# Bloodscent: Ashclaw is more aggressive if player is bleeding
		if enemy.get("species_id") == "ashclaw":
			score += float(GameState.player_bleed_stacks) * 2.0

		candidates.append({
			"id": id,
			"score": score
		})
		
	if candidates.is_empty():
		return []

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var budget: int = clampi(attack_authority_budget, 1, 16) # Pressure expansion: allowed more than 8
	var selected_count: int = mini(budget, candidates.size())
	var selected_ids: Array[int] = []
	for i in range(selected_count):
		selected_ids.append(int(candidates[i]["id"]))
	return selected_ids


func _promote_orbiting_to_strikers() -> void:
	if _orbiting_enemy_ids.is_empty():
		return
		
	var budget = clampi(attack_authority_budget, 1, 16)
	var current_strikers = alive_striker_count()
	
	# Try to fill strikers from orbit
	var orbit_index = 0
	while current_strikers < budget and orbit_index < _orbiting_enemy_ids.size():
		var id = _orbiting_enemy_ids[orbit_index]
		
		# Any-Angle Promotion: Use their current orbit angle as their strike angle
		var angle = _orbit_angles.get(id, _rng.randf_range(0.0, TAU))
		var lane = _get_lane_from_angle(angle) # Derive closest lane for visuals
		
		_strikers[id] = {"angle": angle, "lane": lane}
		_enemies[id]["lane"] = lane
		_assign_striker_visual_offset_for_angle(id, angle)
		
		_orbiting_enemy_ids.remove_at(orbit_index)
		_orbit_angles.erase(id)
		_orbit_radius_offsets.erase(id)
		current_strikers += 1
		# Don't increment orbit_index as we just removed an element


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
		return _center_pos
		
	var lane = _find_lane_for_enemy(id)
	if lane >= 0:
		var visual_offset: Vector2 = _enemy_visual_offsets.get(id, Vector2.ZERO)
		return get_threat_spawn_pos(lane) + visual_offset
		
	return _center_pos


func _assign_striker_visual_offset_for_angle(id: int, angle: float) -> void:
	var radial: Vector2 = Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-radial.y, radial.x)
	var tangent_offset: float = _rng.randf_range(-STRIKER_VISUAL_TANGENT_SPREAD, STRIKER_VISUAL_TANGENT_SPREAD)
	var radial_offset: float = _rng.randf_range(-STRIKER_VISUAL_RADIAL_SPREAD, STRIKER_VISUAL_RADIAL_SPREAD)
	_enemy_visual_offsets[id] = tangent * tangent_offset + radial * radial_offset


func _reset_attack_authority_state() -> void:
	_enemy_authority_debt.clear()
	_enemy_last_fired_cycle.clear()
	_fire_cycle_index = 0


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
	var distance: float = SPAWN_DISTANCE_RATIO * _viewport_size.y - HIT_ZONE_DISTANCE
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

	damage_enemy_by_id(id, float(projectile.get("reflected_damage") if "reflected_damage" in projectile else 0.0))
	projectile.resolve("reflected_hit")

	if _active_projectiles.get(id) == projectile:
		_active_projectiles.erase(id)


func _on_melee_player_contact_id(_melee: Node2D, _id: int, _lane: int) -> void:
	# Player damage is handled by PlayerCombat via its player_contact listener.
	# The melee entity auto-bounces in MeleeApproach._process_approach().
	pass


func debug_fire_lane(lane: int) -> bool:
	if not _combat_running:
		return false
	# Find first striker in this lane
	for id in _strikers:
		if int(_strikers[id].get("lane", -1)) == lane:
			return _fire_striker(id)
	return false


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
