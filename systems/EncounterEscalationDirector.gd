extends Node

# EncounterEscalationDirector v2
# Centralizes live escalation, phase progression, and pressure-aware spawning.
# Now includes timer management to prevent phantom spawns across state changes.

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const ENCOUNTER_IDENTITY_RUNTIME = preload("res://systems/EncounterIdentityRuntime.gd")
const IDENTITY_CONTENT = preload("res://data/EncounterIdentityContent.gd")

signal phase_changed(index, phase_data)
signal spawn_requested(lane, enemy_data)
signal feedback_requested(text, color, duration)

var _region_id: String = ""
var _phases: Array = []
var _current_phase_index: int = -1
var _song_elapsed: float = 0.0
var _running: bool = false
var _paused: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _escalation_rules: Dictionary = {}
var _next_enemy_id_seed: int = 1000

var lane_manager: Node = null
var player_combat: Node2D = null

var _player_hp_ratio: float = 1.0
var _boss_hp_ratio: float = 1.0
var _boss_escalation_fired: bool = false

var _pending_spawn_timers: Array[SceneTreeTimer] = []

func _ready():
	set_process(true)
	
func _process(_delta):
	_prune_finished_timers()

func setup(region_id: String, phases: Array, rng: RandomNumberGenerator) -> void:
	_clear_spawn_timers()
	_region_id = region_id
	_phases = phases
	_rng = rng
	_current_phase_index = -1
	_song_elapsed = 0.0
	_escalation_rules = IDENTITY_CONTENT.get_escalation_rules(region_id)
	_running = false

func start(initial_time: float = 0.0) -> void:
	_clear_spawn_timers()
	_song_elapsed = initial_time
	_running = true
	_paused = false
	_tick_phase_logic()

func stop() -> void:
	_running = false
	_clear_spawn_timers()

func pause() -> void:
	_paused = true
	for timer in _pending_spawn_timers:
		if is_instance_valid(timer): timer.paused = true

func resume() -> void:
	_paused = false
	for timer in _pending_spawn_timers:
		if is_instance_valid(timer): timer.paused = false

func _clear_spawn_timers() -> void:
	for timer in _pending_spawn_timers:
		if is_instance_valid(timer):
			timer.queue_free()
	_pending_spawn_timers.clear()

func _prune_finished_timers() -> void:
	var to_remove = []
	for i in range(_pending_spawn_timers.size() - 1, -1, -1):
		var timer = _pending_spawn_timers[i]
		if not is_instance_valid(timer) or timer.time_left <= 0:
			to_remove.append(i)
	for i in to_remove:
		_pending_spawn_timers.remove_at(i)

func update_song_time(elapsed: float) -> void:
	if not _running:
		return
	_song_elapsed = elapsed
	_tick_phase_logic()

func _tick_phase_logic() -> void:
	var next_idx: int = _current_phase_index + 1
	if next_idx >= _phases.size():
		return
	
	var next_phase: Dictionary = _phases[next_idx]
	if _song_elapsed >= float(next_phase.get("start_time", 9999.0)):
		_enter_phase(next_idx)

func _enter_phase(new_idx: int) -> void:
	_current_phase_index = new_idx
	var phase: Dictionary = _phases[new_idx]
	
	phase_changed.emit(new_idx, phase)
	
	var intro_text: String = ENCOUNTER_IDENTITY_RUNTIME.get_phase_intro_text(_region_id, phase)
	if not intro_text.is_empty():
		feedback_requested.emit(intro_text, Color(0.92, 0.88, 0.74, 1.0), 0.55)
	
	if _escalation_rules.get("surge_on_phase_start", true):
		_seed_initial_phase_enemies(phase)

func _seed_initial_phase_enemies(phase: Dictionary) -> void:
	if lane_manager == null or not is_instance_valid(lane_manager):
		return
		
	var max_threats: int = int(phase.get("max_active_threats", 2))
	var current_alive: int = lane_manager.alive_count()
	var lanes_to_fill: int = min(max_threats - current_alive, lane_manager.LANE_COUNT)
	
	if lanes_to_fill <= 0:
		return

	var empty_lanes: Array = []
	for lane in range(lane_manager.LANE_COUNT):
		if lane_manager.get_enemy(lane).is_empty() or float(lane_manager.get_enemy(lane).get("hp", 0.0)) <= 0.0:
			empty_lanes.append(lane)

	var player_lane: int = player_combat.current_lane if player_combat != null else 1
	var ordered_lanes: Array = ENCOUNTER_IDENTITY_RUNTIME.order_empty_lanes(
		_region_id,
		phase,
		empty_lanes,
		player_lane,
		_rng
	)

	var filled: int = 0
	for i in range(ordered_lanes.size()):
		if filled >= lanes_to_fill:
			break
		_request_spawn(int(ordered_lanes[i]))
		filled += 1

func notify_enemy_defeated(enemy_id: int, lane: int) -> void:
	if not _running or _current_phase_index < 0:
		return
		
	var phase: Dictionary = _phases[_current_phase_index]
	var delay: float = float(_escalation_rules.get("respawn_delay", 0.40))
	
	var shaping: String = String(_escalation_rules.get("pressure_shaping", "default"))
	
	match shaping:
		"aggressive":
			_schedule_smart_respawn(lane, delay, true)
		"resonant":
			_schedule_smart_respawn(lane, delay * 0.5, false)
		"attritional":
			_schedule_smart_respawn(lane, delay * 1.5, true)
		_:
			_schedule_smart_respawn(lane, delay, false)

func _schedule_smart_respawn(origin_lane: int, delay: float, find_new_lane: bool) -> void:
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(func() -> void:
		if not _running or _paused or lane_manager == null or not is_instance_valid(lane_manager):
			return
		
		var phase: Dictionary = _phases[_current_phase_index]
		var max_threats: int = int(phase.get("max_active_threats", 2))
		
		if lane_manager.alive_count() < max_threats:
			var target_lane: int = origin_lane
			if find_new_lane:
				target_lane = _pick_best_empty_lane(origin_lane)
			
			_request_spawn(target_lane)
	, CONNECT_ONE_SHOT)
	_pending_spawn_timers.append(timer)

func _pick_best_empty_lane(exclude_lane: int) -> int:
	if lane_manager == null or not is_instance_valid(lane_manager):
		return exclude_lane

	var empty_lanes: Array = []
	var any_empty_lanes: Array = []
	for lane in range(lane_manager.LANE_COUNT):
		if lane_manager.get_enemy(lane).is_empty() or float(lane_manager.get_enemy(lane).get("hp", 0.0)) <= 0.0:
			any_empty_lanes.append(lane)
			if lane != exclude_lane:
				empty_lanes.append(lane)
	
	if not empty_lanes.is_empty():
		return int(empty_lanes[_rng.randi() % empty_lanes.size()])
		
	if not any_empty_lanes.is_empty():
		return int(any_empty_lanes[_rng.randi() % any_empty_lanes.size()])
		
	return -1

func _request_spawn(lane: int) -> void:
	if lane < 0 or _current_phase_index < 0:
		return
	var phase: Dictionary = _phases[_current_phase_index]
	
	var enemy: Dictionary = _pick_pressure_aware_enemy(phase)
	
	if enemy.is_empty():
		return
	
	spawn_requested.emit(lane, enemy)

func _pick_pressure_aware_enemy(phase: Dictionary) -> Dictionary:
	var pool: Array = phase.get("enemy_pool", [])
	if pool.is_empty():
		return {}
		
	var alive_count: int = lane_manager.alive_count() if lane_manager != null else 0
	var shaping: String = String(_escalation_rules.get("pressure_shaping", "default"))
	
	var filtered_pool: Array = []
	var weights: Array = []
	
	for entry in pool:
		var weight: float = float(entry.get("weight", 1.0))
		var species_id: String = String(entry.get("species_id", ""))
		
		match shaping:
			"aggressive":
				if alive_count < 2 and species_id in ["ashclaw", "thornback"]:
						weight *= 1.5
			"attritional":
				var grade: String = String(entry.get("grade", "brood"))
				if alive_count <= 1 and grade == "alpha":
					weight *= 2.0
			"resonant":
				var hp: float = float(entry.get("hp", 30.0))
				if hp < 25.0:
					weight *= 1.4

		if _player_hp_ratio < 0.40 and species_id in COMBAT_CONTENT.CLUTCH_SPECIES:
			weight *= 2.5
			if _rng.randf() < 0.15:
				feedback_requested.emit("THE HOLLOW PROVIDES", Color(0.70, 0.96, 0.84, 1.0), 0.35)
		
		filtered_pool.append(entry)
		weights.append(weight)
	
	if filtered_pool.is_empty():
		return {}
		
	var total_weight: float = 0.0
	for w in weights:
		total_weight += w
		
	if total_weight <= 0.0:
		return filtered_pool.pick_random()

	var roll: float = _rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for i in range(filtered_pool.size()):
		cursor += weights[i]
		if roll <= cursor:
			return filtered_pool[i].duplicate(true)
			
	return filtered_pool.back().duplicate(true)

func get_current_phase_index() -> int:
	return _current_phase_index

func get_current_phase_data() -> Dictionary:
	if _current_phase_index >= 0 and _current_phase_index < _phases.size():
		return _phases[_current_phase_index]
	return {}

func notify_player_hp_changed(ratio: float) -> void:
	_player_hp_ratio = clampf(ratio, 0.0, 1.0)

func notify_boss_hp_changed(ratio: float) -> void:
	_boss_hp_ratio = clampf(ratio, 0.0, 1.0)
	
	if not _boss_escalation_fired and _boss_hp_ratio <= 0.5:
		_boss_escalation_fired = true
		_trigger_boss_escalation()

func _trigger_boss_escalation() -> void:
	if lane_manager == null:
		return
		
	feedback_requested.emit("SOVEREIGN UNLEASH", Color(0.92, 0.42, 0.12, 1.0), 0.70)
	
	if lane_manager.has_method("set_cycle_interval"):
		lane_manager.call("set_cycle_interval", 0.60)
	if lane_manager.has_method("set_fire_stagger"):
		lane_manager.call("set_fire_stagger", 0.44)
