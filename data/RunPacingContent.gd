extends RefCounted

# Regular level pacing rules for the current run-structure pass.
# Non-boss levels must end within this cap.
const MAX_REGULAR_LEVEL_DURATION_SECONDS: float = 120.0
const REGULAR_LEVEL_COUNT: int = 3

# Shared five-phase arc used per regular level.
const LEVEL_PHASE_START_FRACTIONS: Array[float] = [0.0, 0.20, 0.45, 0.68, 0.84]

# Authored level windows per region song.
# Values are fractions of the full song duration and are clamped at runtime
# so each regular level stays <= MAX_REGULAR_LEVEL_DURATION_SECONDS.
const REGION_LEVEL_WINDOWS: Dictionary = {
	"feeding_hollow": [
		{"label": "FIRST FEED", "start_fraction": 0.00, "end_fraction": 0.30},
		{"label": "SECOND FEED", "start_fraction": 0.30, "end_fraction": 0.60},
		{"label": "THIRD FEED", "start_fraction": 0.60, "end_fraction": 0.88}
	],
	"pale_shelf": [
		{"label": "SHELF I", "start_fraction": 0.00, "end_fraction": 0.30},
		{"label": "SHELF II", "start_fraction": 0.30, "end_fraction": 0.60},
		{"label": "SHELF III", "start_fraction": 0.60, "end_fraction": 0.88}
	],
	"drowned_cut": [
		{"label": "CUT I", "start_fraction": 0.00, "end_fraction": 0.30},
		{"label": "CUT II", "start_fraction": 0.30, "end_fraction": 0.58},
		{"label": "CUT III", "start_fraction": 0.58, "end_fraction": 0.86}
	]
}

# Per-region level-to-level escalation profile.
# Later regular levels tighten cadence and increase pressure expression without
# relying on heavy HP inflation.
const REGION_LEVEL_SCALING: Dictionary = {
	"feeding_hollow": [
		{
			"cycle_interval_mult": 1.00,
			"fire_stagger_mult": 1.00,
			"max_active_threats_bonus": 0,
			"enemy_hp_mult": 1.00,
			"enemy_damage_mult": 1.00,
			"enemy_projectile_speed_mult": 1.00
		},
		{
			"cycle_interval_mult": 0.92,
			"fire_stagger_mult": 0.94,
			"max_active_threats_bonus": 0,
			"enemy_hp_mult": 1.03,
			"enemy_damage_mult": 1.09,
			"enemy_projectile_speed_mult": 1.05
		},
		{
			"cycle_interval_mult": 0.84,
			"fire_stagger_mult": 0.88,
			"max_active_threats_bonus": 1,
			"enemy_hp_mult": 1.06,
			"enemy_damage_mult": 1.16,
			"enemy_projectile_speed_mult": 1.10
		}
	],
	"pale_shelf": [
		{
			"cycle_interval_mult": 1.00,
			"fire_stagger_mult": 1.00,
			"max_active_threats_bonus": 0,
			"enemy_hp_mult": 1.00,
			"enemy_damage_mult": 1.00,
			"enemy_projectile_speed_mult": 1.00
		},
		{
			"cycle_interval_mult": 0.95,
			"fire_stagger_mult": 0.95,
			"max_active_threats_bonus": 0,
			"enemy_hp_mult": 1.02,
			"enemy_damage_mult": 1.10,
			"enemy_projectile_speed_mult": 1.06
		},
		{
			"cycle_interval_mult": 0.90,
			"fire_stagger_mult": 0.90,
			"max_active_threats_bonus": 1,
			"enemy_hp_mult": 1.04,
			"enemy_damage_mult": 1.20,
			"enemy_projectile_speed_mult": 1.12
		}
	],
	"drowned_cut": [
		{
			"cycle_interval_mult": 1.00,
			"fire_stagger_mult": 1.00,
			"max_active_threats_bonus": 0,
			"enemy_hp_mult": 1.00,
			"enemy_damage_mult": 1.00,
			"enemy_projectile_speed_mult": 1.00
		},
		{
			"cycle_interval_mult": 0.90,
			"fire_stagger_mult": 0.94,
			"max_active_threats_bonus": 0,
			"enemy_hp_mult": 1.01,
			"enemy_damage_mult": 1.08,
			"enemy_projectile_speed_mult": 1.06
		},
		{
			"cycle_interval_mult": 0.80,
			"fire_stagger_mult": 0.88,
			"max_active_threats_bonus": 1,
			"enemy_hp_mult": 1.03,
			"enemy_damage_mult": 1.15,
			"enemy_projectile_speed_mult": 1.12
		}
	]
}

# Typed run-pressure bands for Difficulty Modifier Director v1.
# These bands are consumed by runtime systems (cadence, quality, lane pressure,
# punish severity, reward pressure) and intentionally avoid broad stat sludge.
const REGION_DIFFICULTY_BANDS: Dictionary = {
	"feeding_hollow": [
		{
			"threat_cadence": {"cycle_interval_mult": 1.00, "fire_stagger_mult": 1.00, "section_spawn_mult": 1.00},
			"threat_quality": {"high_grade_weight_mult": 1.00, "clutch_species_weight_mult": 1.00},
			"lane_pressure": {"respawn_delay_mult": 1.00, "max_active_threats_bonus": 0},
			"punish_severity": {"projectile_damage_mult": 1.00},
			"reward_pressure": {"offer_decay_mult": 1.00, "level_choice_delta": 0}
		},
		{
			"threat_cadence": {"cycle_interval_mult": 0.94, "fire_stagger_mult": 0.97, "section_spawn_mult": 0.98},
			"threat_quality": {"high_grade_weight_mult": 1.10, "clutch_species_weight_mult": 1.08},
			"lane_pressure": {"respawn_delay_mult": 0.92, "max_active_threats_bonus": 0},
			"punish_severity": {"projectile_damage_mult": 1.06},
			"reward_pressure": {"offer_decay_mult": 1.08, "level_choice_delta": 0}
		},
		{
			"threat_cadence": {"cycle_interval_mult": 0.88, "fire_stagger_mult": 0.94, "section_spawn_mult": 0.95},
			"threat_quality": {"high_grade_weight_mult": 1.20, "clutch_species_weight_mult": 1.15},
			"lane_pressure": {"respawn_delay_mult": 0.82, "max_active_threats_bonus": 1},
			"punish_severity": {"projectile_damage_mult": 1.12},
			"reward_pressure": {"offer_decay_mult": 1.16, "level_choice_delta": -1}
		}
	],
	"pale_shelf": [
		{
			"threat_cadence": {"cycle_interval_mult": 1.00, "fire_stagger_mult": 1.00, "section_spawn_mult": 1.00},
			"threat_quality": {"high_grade_weight_mult": 1.00, "clutch_species_weight_mult": 1.00},
			"lane_pressure": {"respawn_delay_mult": 1.00, "max_active_threats_bonus": 0},
			"punish_severity": {"projectile_damage_mult": 1.00},
			"reward_pressure": {"offer_decay_mult": 1.00, "level_choice_delta": 0}
		},
		{
			"threat_cadence": {"cycle_interval_mult": 0.96, "fire_stagger_mult": 0.98, "section_spawn_mult": 0.99},
			"threat_quality": {"high_grade_weight_mult": 1.12, "clutch_species_weight_mult": 1.05},
			"lane_pressure": {"respawn_delay_mult": 0.94, "max_active_threats_bonus": 0},
			"punish_severity": {"projectile_damage_mult": 1.07},
			"reward_pressure": {"offer_decay_mult": 1.10, "level_choice_delta": 0}
		},
		{
			"threat_cadence": {"cycle_interval_mult": 0.92, "fire_stagger_mult": 0.96, "section_spawn_mult": 0.96},
			"threat_quality": {"high_grade_weight_mult": 1.24, "clutch_species_weight_mult": 1.10},
			"lane_pressure": {"respawn_delay_mult": 0.88, "max_active_threats_bonus": 1},
			"punish_severity": {"projectile_damage_mult": 1.14},
			"reward_pressure": {"offer_decay_mult": 1.20, "level_choice_delta": -1}
		}
	],
	"drowned_cut": [
		{
			"threat_cadence": {"cycle_interval_mult": 1.00, "fire_stagger_mult": 1.00, "section_spawn_mult": 1.00},
			"threat_quality": {"high_grade_weight_mult": 1.00, "clutch_species_weight_mult": 1.00},
			"lane_pressure": {"respawn_delay_mult": 1.00, "max_active_threats_bonus": 0},
			"punish_severity": {"projectile_damage_mult": 1.00},
			"reward_pressure": {"offer_decay_mult": 1.00, "level_choice_delta": 0}
		},
		{
			"threat_cadence": {"cycle_interval_mult": 0.93, "fire_stagger_mult": 0.96, "section_spawn_mult": 0.97},
			"threat_quality": {"high_grade_weight_mult": 1.08, "clutch_species_weight_mult": 1.12},
			"lane_pressure": {"respawn_delay_mult": 0.88, "max_active_threats_bonus": 0},
			"punish_severity": {"projectile_damage_mult": 1.05},
			"reward_pressure": {"offer_decay_mult": 1.12, "level_choice_delta": 0}
		},
		{
			"threat_cadence": {"cycle_interval_mult": 0.86, "fire_stagger_mult": 0.92, "section_spawn_mult": 0.93},
			"threat_quality": {"high_grade_weight_mult": 1.18, "clutch_species_weight_mult": 1.18},
			"lane_pressure": {"respawn_delay_mult": 0.78, "max_active_threats_bonus": 1},
			"punish_severity": {"projectile_damage_mult": 1.10},
			"reward_pressure": {"offer_decay_mult": 1.18, "level_choice_delta": -1}
		}
	]
}


static func get_phase_start_fractions() -> Array[float]:
	return LEVEL_PHASE_START_FRACTIONS.duplicate()


static func get_level_scaling(region_id: String, level_index: int) -> Dictionary:
	var region_scaling: Array = REGION_LEVEL_SCALING[region_id] if REGION_LEVEL_SCALING.has(region_id) else REGION_LEVEL_SCALING["feeding_hollow"]
	var resolved_index: int = clampi(level_index, 0, region_scaling.size() - 1)
	return Dictionary(region_scaling[resolved_index]).duplicate(true)


static func get_level_difficulty_modifiers(region_id: String, level_index: int) -> Dictionary:
	var region_bands: Array = REGION_DIFFICULTY_BANDS[region_id] if REGION_DIFFICULTY_BANDS.has(region_id) else REGION_DIFFICULTY_BANDS["feeding_hollow"]
	var resolved_index: int = clampi(level_index, 0, region_bands.size() - 1)
	return Dictionary(region_bands[resolved_index]).duplicate(true)


static func build_regular_level_windows(region_id: String, song_duration: float) -> Array:
	var windows_source: Array = REGION_LEVEL_WINDOWS[region_id] if REGION_LEVEL_WINDOWS.has(region_id) else REGION_LEVEL_WINDOWS["feeding_hollow"]
	var max_end_time: float = max(song_duration, 0.0)
	if max_end_time <= 0.0:
		max_end_time = 1.0
	var min_level_duration: float = 20.0
	var built: Array = []
	for i in range(min(REGULAR_LEVEL_COUNT, windows_source.size())):
		var raw: Dictionary = Dictionary(windows_source[i])
		var start_time: float = clampf(float(raw.get("start_fraction", 0.0)) * max_end_time, 0.0, max_end_time)
		var end_cap: float = max(max_end_time, start_time + min_level_duration)
		var end_time: float = clampf(float(raw.get("end_fraction", 1.0)) * max_end_time, start_time + min_level_duration, end_cap)
		if end_time - start_time > MAX_REGULAR_LEVEL_DURATION_SECONDS:
			end_time = min(start_time + MAX_REGULAR_LEVEL_DURATION_SECONDS, max_end_time)
		built.append({
			"index": i,
			"label": String(raw.get("label", "LEVEL %d" % (i + 1))),
			"start_time": start_time,
			"end_time": end_time,
			"duration": max(end_time - start_time, min_level_duration)
		})

	if built.size() >= REGULAR_LEVEL_COUNT:
		return built

	# Fallback: even segmentation if authored windows are missing.
	built.clear()
	var fallback_slice: float = min(max_end_time / float(REGULAR_LEVEL_COUNT), MAX_REGULAR_LEVEL_DURATION_SECONDS)
	for i in range(REGULAR_LEVEL_COUNT):
		var start_time: float = min(i * fallback_slice, max_end_time)
		var end_time: float = min(start_time + fallback_slice, max_end_time)
		built.append({
			"index": i,
			"label": "LEVEL %d" % (i + 1),
			"start_time": start_time,
			"end_time": end_time,
			"duration": max(end_time - start_time, min_level_duration)
		})
	return built
