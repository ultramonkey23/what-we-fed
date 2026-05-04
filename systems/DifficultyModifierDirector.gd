extends RefCounted
class_name DifficultyModifierDirector

# DifficultyModifierDirector (v1)
# Final layer that translates music-control + progression into active pressure.

const DEFAULT_MODIFIERS: Dictionary = {
	"threat_cadence": {
		"cycle_interval_mult": 1.0,
		"fire_stagger_mult": 1.0
	},
	"threat_quality": {
		"high_grade_weight_mult": 1.0,
		"clutch_species_weight_mult": 1.0,
		"elite_spawn_chance_bonus": 0.0
	},
	"lane_pressure": {
		"respawn_delay_mult": 1.0,
		"max_active_threats_bonus": 0
	},
	"punish_severity": {
		"projectile_damage_mult": 1.0
	},
	"reward_pressure": {
		"offer_decay_mult": 1.0,
		"level_choice_delta": 0
	}
}


func compute_active_modifiers(base_mods: Dictionary, music_state: Dictionary, progression_state: Dictionary) -> Dictionary:
	var mods: Dictionary = _merge_with_defaults(base_mods)

	var run_progress: float = clampf(float(progression_state.get("run_progress", 0.0)), 0.0, 1.0)
	var section_intensity: float = clampf(float(music_state.get("section_intensity", 0.0)), 0.0, 1.0)
	var phrase_intensity: float = clampf(float(music_state.get("phrase_intensity", 0.0)), 0.0, 1.0)
	var accent_window: float = clampf(float(music_state.get("accent_window", 0.0)), 0.0, 1.0)
	var escalation_window: float = clampf(float(music_state.get("escalation_window", 0.0)), 0.0, 1.0)
	var tempo_band: String = String(music_state.get("tempo_band", "mid"))
	var section_mood: String = String(music_state.get("section_mood", "steady"))
	var level_progress: float = clampf(float(progression_state.get("level_progress", 0.0)), 0.0, 1.0)
	var skill_expression: float = clampf(float(progression_state.get("skill_expression", 0.5)), 0.0, 1.0)
	var skill_delta: float = (skill_expression - 0.5) * 2.0

	# Attack density is run-led so pressure ramps reliably through the run,
	# then is shaped by music so it still feels authored to the track.
	var attack_density: float = clampf(
		run_progress * 0.70 +
		level_progress * 0.15 +
		section_intensity * 0.10 +
		escalation_window * 0.05,
		0.0,
		1.0
	)
	# Skill expression adjusts pressure around the run baseline.
	# Stronger performance earns denser attack flow; weaker performance gets relief.
	attack_density = clampf(attack_density + skill_delta * 0.16, 0.0, 1.0)

	var pressure_core: float = (
		run_progress * 0.54 +
		section_intensity * 0.25 +
		phrase_intensity * 0.13 +
		accent_window * 0.04 +
		escalation_window * 0.04
	)
	pressure_core = clampf(pressure_core, 0.0, 1.0)
	var cadence_boost: float = clampf(attack_density * 0.72 + pressure_core * 0.20 + accent_window * 0.08, 0.0, 1.0)
	var lane_boost: float = clampf(attack_density * 0.70 + escalation_window * 0.30, 0.0, 1.0)

	var cadence_band: Dictionary = Dictionary(mods.get("threat_cadence", {}))
	cadence_band["cycle_interval_mult"] = clampf(
		float(cadence_band.get("cycle_interval_mult", 1.0)) * lerpf(1.0, 0.80, cadence_boost),
		0.72,
		1.38
	)
	cadence_band["fire_stagger_mult"] = clampf(
		float(cadence_band.get("fire_stagger_mult", 1.0)) * lerpf(1.0, 0.92, clampf(phrase_intensity * 0.65 + accent_window * 0.35, 0.0, 1.0)),
		0.84,
		1.18
	)
	if tempo_band == "fast":
		cadence_band["fire_stagger_mult"] = clampf(float(cadence_band.get("fire_stagger_mult", 1.0)) * 0.98, 0.84, 1.18)
	elif tempo_band == "slow":
		cadence_band["fire_stagger_mult"] = clampf(float(cadence_band.get("fire_stagger_mult", 1.0)) * 1.02, 0.84, 1.18)
	mods["threat_cadence"] = cadence_band

	var lane_band: Dictionary = Dictionary(mods.get("lane_pressure", {}))
	var skill_respawn_factor: float = lerpf(1.08, 0.92, skill_expression)
	lane_band["respawn_delay_mult"] = clampf(
		float(lane_band.get("respawn_delay_mult", 1.0)) * lerpf(1.0, 0.84, lane_boost) * skill_respawn_factor,
		0.60,
		1.45
	)
	var max_bonus: int = int(lane_band.get("max_active_threats_bonus", 0))
	if run_progress >= 0.25 and skill_expression >= 0.35:
		max_bonus += 1
	if run_progress >= 0.62 and skill_expression >= 0.58 and section_mood in ["drive", "surge"] and escalation_window >= 0.18:
		max_bonus += 1
	lane_band["max_active_threats_bonus"] = clampi(max_bonus, 0, 2)
	mods["lane_pressure"] = lane_band

	var quality_band: Dictionary = Dictionary(mods.get("threat_quality", {}))
	quality_band["high_grade_weight_mult"] = clampf(
		float(quality_band.get("high_grade_weight_mult", 1.0)) * lerpf(1.0, 1.24, pressure_core),
		0.70,
		2.20
	)
	quality_band["clutch_species_weight_mult"] = clampf(
		float(quality_band.get("clutch_species_weight_mult", 1.0)) * lerpf(1.0, 1.12, run_progress),
		0.70,
		2.20
	)
	quality_band["elite_spawn_chance_bonus"] = clampf(
		0.04 + pressure_core * 0.08 + escalation_window * 0.10,
		0.0,
		0.24
	)
	mods["threat_quality"] = quality_band

	var punish_band: Dictionary = Dictionary(mods.get("punish_severity", {}))
	punish_band["projectile_damage_mult"] = clampf(
		float(punish_band.get("projectile_damage_mult", 1.0)) * lerpf(1.0, 1.10, run_progress * 0.70 + section_intensity * 0.30),
		0.75,
		1.50
	)
	mods["punish_severity"] = punish_band

	var reward_band: Dictionary = Dictionary(mods.get("reward_pressure", {}))
	reward_band["offer_decay_mult"] = clampf(
		float(reward_band.get("offer_decay_mult", 1.0)) * lerpf(1.0, 1.08, pressure_core),
		0.75,
		1.45
	)
	if pressure_core >= 0.72 and escalation_window >= 0.25:
		reward_band["level_choice_delta"] = int(reward_band.get("level_choice_delta", 0)) - 1
	mods["reward_pressure"] = reward_band

	return mods


func _merge_with_defaults(source_mods: Dictionary) -> Dictionary:
	var merged: Dictionary = DEFAULT_MODIFIERS.duplicate(true)
	for key in merged.keys():
		if not source_mods.has(key):
			continue
		if typeof(source_mods[key]) != TYPE_DICTIONARY:
			continue
		var band: Dictionary = Dictionary(merged[key]).duplicate(true)
		var incoming: Dictionary = Dictionary(source_mods[key])
		for band_key in incoming.keys():
			band[band_key] = incoming[band_key]
		merged[key] = band
	return merged
