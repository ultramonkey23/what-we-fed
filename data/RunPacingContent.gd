extends RefCounted

# Regular level pacing rules for the current run-structure pass.
# Non-boss levels must end within this cap.
const MAX_REGULAR_LEVEL_DURATION_SECONDS: float = 180.0
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


static func get_phase_start_fractions() -> Array[float]:
	return LEVEL_PHASE_START_FRACTIONS.duplicate()


static func get_level_scaling(region_id: String, level_index: int) -> Dictionary:
	var region_scaling: Array = REGION_LEVEL_SCALING[region_id] if REGION_LEVEL_SCALING.has(region_id) else REGION_LEVEL_SCALING["feeding_hollow"]
	var resolved_index: int = clampi(level_index, 0, region_scaling.size() - 1)
	return Dictionary(region_scaling[resolved_index]).duplicate(true)


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
