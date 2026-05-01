extends Node

# EncounterEscalationDirector v2
# Centralizes live escalation, phase progression, and pressure-aware spawning.
# Now includes timer management to prevent phantom spawns across state changes.

const COMBAT_DATA = preload("res://data/CombatContent.gd")
const ENCOUNTER_IDENTITY_RUNTIME = preload("res://systems/EncounterIdentityRuntime.gd")
const IDENTITY_CONTENT = preload("res://data/EncounterIdentityContent.gd")

signal phase_changed(index, phase_data)
signal spawn_requested(lane, enemy_data)
signal feedback_requested(text, color, duration)
signal ecology_state_changed(snapshot)

const DEFAULT_DIFFICULTY_MODIFIERS: Dictionary = {
	"threat_cadence": {},
	"threat_quality": {
		"high_grade_weight_mult": 1.0,
		"clutch_species_weight_mult": 1.0,
		"elite_spawn_chance_bonus": 0.0
	},
	"lane_pressure": {
		"respawn_delay_mult": 1.0,
		"max_active_threats_bonus": 0
	},
	"punish_severity": {},
	"reward_pressure": {}
}

const MOMENTUM_MAX: float = 100.0
const MOMENTUM_KILL_GAIN: float = 10.0
const MOMENTUM_HIT_LOSS: float = 18.0
const MOMENTUM_DECAY_PER_SEC: float = 4.0
const MOMENTUM_RELIEF_CAP: float = 45.0
const LOW_HP_RELIEF_RATIO: float = 0.35
const RECENT_HIT_RELIEF_SECONDS: float = 2.2
const KILL_SPAWN_DEBT_GAIN: float = 1.5
const MAX_SPAWNS_SCHEDULED_PER_KILL: int = 3
const BPM_RESPAWN_BEATS: float = 2.0
const DEFAULT_BPM: float = 120.0

const BASE_POPULATION_CAP: int = 6
const POPULATION_MOMENTUM_BONUS: int = 12
const DEFAULT_PRESSURE_CAP: float = 2.2
const PRESSURE_CAP_MOMENTUM_BONUS: float = 0.55
const PRESSURE_CAP_RELIEF: float = 0.25
const AUTHORITY_MOMENTUM_THRESHOLD: float = 0.62
const AUTHORITY_MOMENTUM_BONUS: int = 1
const MOMENTUM_PERFECT_KILL_BONUS: float = 8.0

var _region_id: String = ""
var _phases: Array = []
var _current_phase_index: int = -1
var _song_elapsed: float = 0.0
var _running: bool = false
var _paused: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _escalation_rules: Dictionary = {}

var zone_manager: Node = null
var player_combat: Node2D = null

var _player_hp_ratio: float = 1.0
var _boss_hp_ratio: float = 1.0
var _boss_escalation_fired: bool = false

var _pending_spawn_timers: Array[SceneTreeTimer] = []
var _difficulty_modifiers: Dictionary = DEFAULT_DIFFICULTY_MODIFIERS.duplicate(true)
var _kill_momentum: float = 0.0
var _perfect_kill_streak: int = 0
var _last_hit_quality_by_enemy: Dictionary = {}
var _recent_hit_timer: float = 0.0
var _last_ecology_snapshot: Dictionary = {}
var _last_synced_budget: int = -1
var _spawn_debt: float = 0.0
var _song_bpm: float = DEFAULT_BPM

func _ready():
	set_process(true)
	if not EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)


func _exit_tree() -> void:
	stop()
	if EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.disconnect(_on_timed_attack_resolved)
	
func _process(delta):
	_prune_finished_timers()
	if not _running or _paused:
		return
	if _kill_momentum > 0.0:
		_kill_momentum = maxf(_kill_momentum - MOMENTUM_DECAY_PER_SEC * delta, 0.0)
	if _recent_hit_timer > 0.0:
		_recent_hit_timer = maxf(_recent_hit_timer - delta, 0.0)
		
	_sync_budgets_to_zone_manager()
	_emit_ecology_state_if_changed()

func setup(region_id: String, phases: Array, rng: RandomNumberGenerator) -> void:
	_clear_spawn_timers()
	_region_id = region_id
	_phases = phases
	_rng = rng
	_current_phase_index = -1
	_song_elapsed = 0.0
	_escalation_rules = IDENTITY_CONTENT.get_escalation_rules(region_id)
	_running = false
	_difficulty_modifiers = DEFAULT_DIFFICULTY_MODIFIERS.duplicate(true)
	_kill_momentum = 0.0
	_perfect_kill_streak = 0
	_last_hit_quality_by_enemy.clear()
	_recent_hit_timer = 0.0
	_last_ecology_snapshot.clear()
	_last_synced_budget = -1
	_spawn_debt = 0.0
	_song_bpm = DEFAULT_BPM


func set_difficulty_modifiers(mods: Dictionary) -> void:
	_difficulty_modifiers = DEFAULT_DIFFICULTY_MODIFIERS.duplicate(true)
	if mods.is_empty():
		return
	for band_key in _difficulty_modifiers.keys():
		if not mods.has(band_key):
			continue
		if typeof(mods[band_key]) != TYPE_DICTIONARY:
			continue
		var target_band: Dictionary = Dictionary(_difficulty_modifiers[band_key]).duplicate(true)
		var incoming_band: Dictionary = Dictionary(mods[band_key])
		for key in incoming_band.keys():
			target_band[key] = incoming_band[key]
		_difficulty_modifiers[band_key] = target_band


func set_song_bpm(bpm: float) -> void:
	_song_bpm = maxf(bpm, 1.0)

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

func resume() -> void:
	_paused = false
	if _running:
		_tick_phase_logic()
		if _current_phase_index >= 0:
			_seed_initial_phase_enemies(_phases[_current_phase_index])

func _clear_spawn_timers() -> void:
	# SceneTreeTimer is RefCounted, not a Node; it has no queue_free().
	# Just clearing the array is sufficient as the timer's timeout lambda 
	# already checks _running before spawning.
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
	if not _running or _paused:
		return
	_song_elapsed = elapsed
	_tick_phase_logic()


func _tick_phase_logic() -> void:
	if _phases.is_empty():
		return
		
	# Use while loop so we can skip through multiple phases if song time jumps.
	while _current_phase_index + 1 < _phases.size():
		var next_idx: int = _current_phase_index + 1
		var next_phase = _phases[next_idx]
		if typeof(next_phase) != TYPE_DICTIONARY:
			push_error("Phase at index %d is not a Dictionary!" % next_idx)
			break
		if _song_elapsed >= float(next_phase.get("start_time", 9999.0)):
			_enter_phase(next_idx)
		else:
			break

func _enter_phase(new_idx: int) -> void:
	_current_phase_index = new_idx
	var phase: Dictionary = _phases[new_idx]
	
	phase_changed.emit(new_idx, phase)
	
	var intro_text: String = ENCOUNTER_IDENTITY_RUNTIME.get_phase_intro_text(_region_id, phase)
	if not intro_text.is_empty():
		feedback_requested.emit(intro_text, Color(0.92, 0.88, 0.74, 1.0), 0.55)
	
	if _escalation_rules.get("surge_on_phase_start", true) or zone_manager.alive_count() == 0:
		_seed_initial_phase_enemies(phase)
	_emit_ecology_state_if_changed()

func _seed_initial_phase_enemies(phase: Dictionary) -> void:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return
		
	var max_threats: int = _resolve_authority_budget(phase)
	var current_alive: int = zone_manager.alive_count()
	var lanes_to_fill: int = min(max_threats - current_alive, zone_manager.THREAT_COUNT)
	
	if lanes_to_fill <= 0:
		return

	var empty_lanes: Array = []
	for lane in range(zone_manager.THREAT_COUNT):
		if zone_manager.call("is_lane_empty", lane):
			empty_lanes.append(lane)

	var player_lane: int = 1 # Default fallback
	if player_combat != null:
		if player_combat.has_method("get_active_focus_lane"):
			player_lane = int(player_combat.call("get_active_focus_lane"))
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

func _sync_budgets_to_zone_manager() -> void:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return
	
	var budget: int = _resolve_authority_budget(get_current_phase_data())
	if budget != _last_synced_budget:
		_last_synced_budget = budget
		if zone_manager.has_method("set_attack_authority_budget"):
			zone_manager.call("set_attack_authority_budget", budget)

	# Frequency scaling (only if boss escalation hasn't taken over)
	if not _boss_escalation_fired:
		var momentum_ratio: float = _resolve_effective_momentum_ratio()
		var interval: float = 2.2
		interval -= momentum_ratio * 0.7
		if _player_hp_ratio <= LOW_HP_RELIEF_RATIO or _recent_hit_timer > 0.0:
			interval += 0.85 # Visible relief
		
		if zone_manager.has_method("set_cycle_interval"):
			zone_manager.call("set_cycle_interval", clampf(interval, 1.2, 3.5))

func notify_enemy_defeated(enemy_id: int, lane: int, replaced_immediately: bool = false) -> void:
	if not _running or _current_phase_index < 0:
		return
	
	var gain: float = MOMENTUM_KILL_GAIN
	var quality: String = String(_last_hit_quality_by_enemy.get(enemy_id, ""))
	
	if quality == "perfect":
		gain += MOMENTUM_PERFECT_KILL_BONUS
		_perfect_kill_streak += 1
		if _perfect_kill_streak >= 3:
			feedback_requested.emit("PERFECT STREAK: %d" % _perfect_kill_streak, Color(0.78, 0.94, 0.62, 1.0), 0.35)
	else:
		_perfect_kill_streak = 0
	
	_kill_momentum = minf(_kill_momentum + gain, MOMENTUM_MAX)
	_spawn_debt = minf(_spawn_debt + KILL_SPAWN_DEBT_GAIN, float(_resolve_population_cap()))
	_last_hit_quality_by_enemy.erase(enemy_id)
	
	if replaced_immediately:
		_emit_ecology_state_if_changed()
		return
		
	var delay: float = float(_escalation_rules.get("respawn_delay", 0.40))
	var lane_pressure_band: Dictionary = Dictionary(_difficulty_modifiers.get("lane_pressure", {}))
	delay *= clampf(float(lane_pressure_band.get("respawn_delay_mult", 1.0)), 0.60, 1.45)
	delay *= lerpf(1.12, 0.64, _resolve_effective_momentum_ratio())
	
	# Mercy relief on spawn frequency
	if _player_hp_ratio <= LOW_HP_RELIEF_RATIO or _recent_hit_timer > 0.0:
		delay *= 1.45 # Significant slow down
	
	delay = clampf(delay, 0.08, 2.80)
	
	var shaping: String = String(_escalation_rules.get("pressure_shaping", "default"))
	
	var find_new_lane: bool = false
	match shaping:
		"aggressive":
			find_new_lane = true
		"resonant":
			delay *= 0.5
		"attritional":
			delay *= 1.5
			find_new_lane = true
		_:
			pass

	_schedule_spawn_debt(lane, delay, find_new_lane)
	
	_sync_budgets_to_zone_manager()
	_emit_ecology_state_if_changed()


func _schedule_spawn_debt(origin_lane: int, base_delay: float, find_new_lane: bool) -> void:
	var scheduled: int = 0
	while _spawn_debt >= 1.0 and scheduled < MAX_SPAWNS_SCHEDULED_PER_KILL:
		var beat_delay: float = _resolve_bpm_respawn_delay() * float(scheduled + 1)
		var spawn_delay: float = clampf(base_delay + beat_delay, 0.10, 3.20)
		_spawn_debt -= 1.0
		_schedule_smart_respawn(origin_lane, spawn_delay, find_new_lane or origin_lane < 0)
		scheduled += 1


func _resolve_bpm_respawn_delay() -> float:
	var beat_duration: float = 60.0 / maxf(_song_bpm, 1.0)
	return clampf(beat_duration * BPM_RESPAWN_BEATS, 0.34, 1.65)

func _schedule_smart_respawn(origin_lane: int, delay: float, find_new_lane: bool) -> void:
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(_on_smart_respawn_timeout.bind(origin_lane, find_new_lane), CONNECT_ONE_SHOT)
	_pending_spawn_timers.append(timer)


func _on_smart_respawn_timeout(origin_lane: int, find_new_lane: bool) -> void:
	if not _running or _paused or zone_manager == null or not is_instance_valid(zone_manager):
		return
	
	var phase: Dictionary = _phases[_current_phase_index]
	var max_threats: int = _resolve_authority_budget(phase)
	
	if zone_manager.alive_count() < max_threats:
		var target_lane: int = origin_lane
		if find_new_lane:
			target_lane = _pick_best_empty_lane(origin_lane)
		
		if not _request_spawn(target_lane):
			_refund_blocked_spawn_debt()
			_schedule_smart_respawn(target_lane, _resolve_bpm_respawn_delay(), true)


func _refund_blocked_spawn_debt() -> void:
	_spawn_debt = minf(_spawn_debt + 1.0, float(_resolve_population_cap()))

func _pick_best_empty_lane(exclude_lane: int) -> int:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return exclude_lane

	var empty_lanes: Array = []
	var any_empty_lanes: Array = []
	for lane in range(zone_manager.THREAT_COUNT):
		if zone_manager.call("is_lane_empty", lane):
			any_empty_lanes.append(lane)
			if lane != exclude_lane:
				empty_lanes.append(lane)
	
	if not empty_lanes.is_empty():
		return int(empty_lanes[_rng.randi() % empty_lanes.size()])
		
	if not any_empty_lanes.is_empty():
		return int(any_empty_lanes[_rng.randi() % any_empty_lanes.size()])
		
	return -1

func _request_spawn(lane: int) -> bool:
	if lane < 0 or _current_phase_index < 0:
		return false
	var phase: Dictionary = _phases[_current_phase_index]
	
	var enemy: Dictionary = _pick_pressure_aware_enemy(phase)
	
	if enemy.is_empty():
		return false
	if not _can_schedule_spawn(phase, enemy):
		return false
	
	spawn_requested.emit(lane, enemy)
	_emit_ecology_state_if_changed()
	return true

func _on_timed_attack_resolved(_lane: int, quality: String, _damage: float, enemy_id: int) -> void:
	# Store the most recent quality for the specific enemy ID.
	if enemy_id != -1:
		_last_hit_quality_by_enemy[enemy_id] = quality

func _can_schedule_spawn(phase: Dictionary, enemy: Dictionary) -> bool:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return false
	
	# POPULATION LIMIT: Scaled by momentum
	var pop_cap: int = _resolve_population_cap()
	if zone_manager.alive_count() >= pop_cap:
		return false

	var pressure_cap: float = _resolve_pressure_cap(phase)
	var current_pressure: float = _resolve_current_pressure_points()
	var incoming_pressure: float = _estimate_enemy_pressure_points(enemy) * 0.68
	return (current_pressure + incoming_pressure) <= pressure_cap

func _resolve_population_cap() -> int:
	var momentum_ratio: float = _resolve_effective_momentum_ratio()
	var cap: int = BASE_POPULATION_CAP + int(momentum_ratio * POPULATION_MOMENTUM_BONUS)
	
	# Mercy relief on population
	if _player_hp_ratio <= LOW_HP_RELIEF_RATIO or _recent_hit_timer > 0.0:
		cap = clampi(cap - 4, BASE_POPULATION_CAP - 2, BASE_POPULATION_CAP + 4)
	
	return clampi(cap, 2, 24)

func _pick_pressure_aware_enemy(phase: Dictionary) -> Dictionary:
	var pool: Array = phase.get("enemy_pool", [])
	if pool.is_empty():
		return {}
		
	var alive_count: int = zone_manager.alive_count() if zone_manager != null else 0
	var momentum_ratio: float = _resolve_effective_momentum_ratio()
	var shaping: String = String(_escalation_rules.get("pressure_shaping", "default"))
	var quality_band: Dictionary = Dictionary(_difficulty_modifiers.get("threat_quality", {}))
	var high_grade_mult: float = clampf(float(quality_band.get("high_grade_weight_mult", 1.0)), 0.7, 2.0)
	var clutch_species_mult: float = clampf(float(quality_band.get("clutch_species_weight_mult", 1.0)), 0.7, 2.0)
	var elite_spawn_bonus: float = clampf(float(quality_band.get("elite_spawn_chance_bonus", 0.0)), 0.0, 0.30)
	elite_spawn_bonus = clampf(elite_spawn_bonus + momentum_ratio * 0.10, 0.0, 0.34)
	
	var filtered_pool: Array = []
	var weights: Array = []
	var elite_pool: Array = []
	var elite_weights: Array = []
	
	for entry in pool:
		var weight: float = float(entry.get("weight", 1.0))
		var species_id: String = String(entry.get("species_id", ""))
		var grade_id: String = String(entry.get("grade", "brood"))
		if grade_id in ["alpha", "apex", "sovereign"]:
			weight *= high_grade_mult * lerpf(1.0, 1.24, momentum_ratio)
		
		match shaping:
			"aggressive":
				if alive_count < 2 and species_id in ["ashclaw", "thornback"]:
						weight *= 1.5
				if momentum_ratio >= 0.6 and species_id in ["ashclaw", "gorefane", "thornback"]:
					weight *= 1.16
			"attritional":
				if alive_count <= 1 and grade_id == "alpha":
					weight *= 2.0
			"resonant":
				var hp: float = float(entry.get("hp", 30.0))
				if hp < 25.0:
					weight *= 1.4

		if _player_hp_ratio < 0.40 and species_id in COMBAT_DATA.CLUTCH_SPECIES:
			weight *= 2.5 * clutch_species_mult
			if _rng.randf() < 0.15:
				feedback_requested.emit("THE HOLLOW PROVIDES", Color(0.70, 0.96, 0.84, 1.0), 0.35)
		elif _player_hp_ratio < 0.40:
			weight *= 0.92
		
		filtered_pool.append(entry)
		weights.append(weight)
		if grade_id in ["alpha", "apex", "sovereign"]:
			elite_pool.append(entry)
			elite_weights.append(weight)
	
	if filtered_pool.is_empty():
		return {}

	if not elite_pool.is_empty() and _rng.randf() <= elite_spawn_bonus:
		return _roll_weighted_entry(elite_pool, elite_weights)
		
	return _roll_weighted_entry(filtered_pool, weights)


func _roll_weighted_entry(pool: Array, weights: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	var total_weight: float = 0.0
	for w in weights:
		total_weight += float(w)
	if total_weight <= 0.0:
		return Dictionary(pool.pick_random()).duplicate(true)

	var roll: float = _rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for i in range(pool.size()):
		cursor += float(weights[i])
		if roll <= cursor:
			return Dictionary(pool[i]).duplicate(true)
	return Dictionary(pool.back()).duplicate(true)

func get_current_phase_index() -> int:
	return _current_phase_index

func get_current_phase_data() -> Dictionary:
	if _current_phase_index >= 0 and _current_phase_index < _phases.size():
		return _phases[_current_phase_index]
	return {}

func notify_player_hp_changed(ratio: float) -> void:
	_player_hp_ratio = clampf(ratio, 0.0, 1.0)
	_emit_ecology_state_if_changed()

func notify_player_took_damage(amount: float = 0.0, _source_lane: int = -1) -> void:
	_recent_hit_timer = RECENT_HIT_RELIEF_SECONDS
	var loss: float = MOMENTUM_HIT_LOSS
	if amount > 0.0:
		loss += clampf(amount * 0.45, 0.0, 12.0)
	_kill_momentum = maxf(_kill_momentum - loss, 0.0)
	_emit_ecology_state_if_changed()

func notify_boss_hp_changed(ratio: float) -> void:
	_boss_hp_ratio = clampf(ratio, 0.0, 1.0)
	
	if not _boss_escalation_fired and _boss_hp_ratio <= 0.5:
		_boss_escalation_fired = true
		_trigger_boss_escalation()

func _trigger_boss_escalation() -> void:
	if zone_manager == null:
		return
		
	feedback_requested.emit("SOVEREIGN UNLEASH", Color(0.92, 0.42, 0.12, 1.0), 0.70)
	
	if zone_manager.has_method("set_cycle_interval"):
		zone_manager.call("set_cycle_interval", 0.60)
	if zone_manager.has_method("set_fire_stagger"):
		zone_manager.call("set_fire_stagger", 0.44)

func get_kill_momentum_ratio() -> float:
	return _resolve_effective_momentum_ratio()

func get_ecology_snapshot() -> Dictionary:
	var phase: Dictionary = get_current_phase_data()
	var authority_budget: int = _resolve_authority_budget(phase)
	var pressure_cap: float = _resolve_pressure_cap(phase)
	return {
		"phase_index": _current_phase_index,
		"alive_count": zone_manager.alive_count() if zone_manager != null and is_instance_valid(zone_manager) else 0,
		"authority_budget": authority_budget,
		"attack_authority_budget": authority_budget,
		"pressure_points": _resolve_current_pressure_points(),
		"pressure_cap": pressure_cap,
		"kill_momentum": _kill_momentum,
		"kill_momentum_ratio": _resolve_effective_momentum_ratio(),
		"player_hp_ratio": _player_hp_ratio,
		"recent_hit_timer": _recent_hit_timer,
		"spawn_debt": _spawn_debt,
		"song_bpm": _song_bpm
	}

func _resolve_authority_budget(phase: Dictionary) -> int:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return 1
	var lane_pressure_band: Dictionary = Dictionary(_difficulty_modifiers.get("lane_pressure", {}))
	var authority_target: int = int(phase.get("authority_target", phase.get("max_active_threats", 2)))
	var max_threats: int = authority_target + int(lane_pressure_band.get("max_active_threats_bonus", 0))
	var momentum_ratio: float = _resolve_effective_momentum_ratio()
	if momentum_ratio >= AUTHORITY_MOMENTUM_THRESHOLD and _player_hp_ratio > LOW_HP_RELIEF_RATIO and _recent_hit_timer <= 0.0:
		max_threats += AUTHORITY_MOMENTUM_BONUS
	max_threats = clampi(max_threats, 1, zone_manager.THREAT_COUNT)
	if _player_hp_ratio <= LOW_HP_RELIEF_RATIO or _recent_hit_timer > 0.0:
		max_threats = max(1, max_threats - 1)
	return max_threats

func _resolve_pressure_cap(phase: Dictionary) -> float:
	var base_cap: float = float(phase.get("pressure_cap", DEFAULT_PRESSURE_CAP))
	var momentum_cap_bonus: float = lerpf(0.0, PRESSURE_CAP_MOMENTUM_BONUS, _resolve_effective_momentum_ratio())
	var pressure_cap: float = base_cap + momentum_cap_bonus
	if _player_hp_ratio <= LOW_HP_RELIEF_RATIO or _recent_hit_timer > 0.0:
		pressure_cap -= PRESSURE_CAP_RELIEF
	return clampf(pressure_cap, 1.1, 4.6)

func _resolve_effective_momentum_ratio() -> float:
	var effective_momentum: float = _kill_momentum
	if _player_hp_ratio <= LOW_HP_RELIEF_RATIO:
		effective_momentum = minf(effective_momentum, MOMENTUM_RELIEF_CAP)
	if _recent_hit_timer > 0.0:
		effective_momentum = minf(effective_momentum, MOMENTUM_RELIEF_CAP * 0.85)
	return clampf(effective_momentum / MOMENTUM_MAX, 0.0, 1.0)

func _resolve_current_pressure_points() -> float:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return 0.0
	var total: float = 0.0
	var all_enemies: Dictionary = zone_manager.call("get_all_enemies")
	for id in all_enemies.keys():
		var enemy: Dictionary = all_enemies[id]
		if not enemy.is_empty() and float(enemy.get("hp", 0.0)) > 0.0:
			total += _estimate_enemy_pressure_points(enemy) * 0.52
			
		var projectile = zone_manager.call("get_projectile_by_id", id)
		if projectile != null:
			var projectile_damage: float = float(projectile.get("damage"))
			var projectile_speed: float = float(projectile.get("speed"))
			var damage_norm: float = clampf(projectile_damage / 10.0, 0.40, 1.80)
			var speed_norm: float = clampf(projectile_speed / 320.0, 0.60, 1.60)
			total += 0.70 * damage_norm * speed_norm
	return total

func _estimate_enemy_pressure_points(enemy: Dictionary) -> float:
	var damage_norm: float = clampf(float(enemy.get("damage", 8.0)) / 10.0, 0.50, 2.00)
	var projectile_speed: float = float(enemy.get("projectile_speed", 300.0))
	var speed_norm: float = clampf(projectile_speed / 320.0, 0.60, 1.60)
	var grade_bonus: float = 0.0
	match String(enemy.get("grade", "mature")):
		"alpha":
			grade_bonus = 0.12
		"apex":
			grade_bonus = 0.18
		"sovereign":
			grade_bonus = 0.24
	return 0.44 * damage_norm * speed_norm + grade_bonus

func _emit_ecology_state_if_changed() -> void:
	var snapshot: Dictionary = get_ecology_snapshot()
	if snapshot == _last_ecology_snapshot:
		return
	_last_ecology_snapshot = snapshot.duplicate(true)
	ecology_state_changed.emit(snapshot)
