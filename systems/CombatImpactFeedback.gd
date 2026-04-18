extends RefCounted

# Small impact/readability helper for CombatScene.
# Keeps impact tuning in one place without inventing a full combat FX architecture.


static func build_timed_attack_profile(quality: String, beat_quality: String) -> Dictionary:
	var profile: Dictionary = {
		"flash_color": Color.TRANSPARENT,
		"flash_duration": 0.0,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"ring_width": 0.0,
		"burst_color": Color(1.0, 0.86, 0.38, 0.42),
		"burst_scale": 1.0,
		"enemy_push": 7.0,
		"enemy_scale": Vector2(1.14, 0.86),
		"sfx_cue": "timed_hit"
	}

	if quality == "perfect":
		profile["burst_color"] = Color(1.0, 0.92, 0.50, 0.52)
		profile["burst_scale"] = 1.18
		profile["enemy_push"] = 9.0
		profile["enemy_scale"] = Vector2(1.18, 0.82)
		profile["sfx_cue"] = "perfect_timed_hit"

	return profile


static func build_parry_profile(quality: String, beat_quality: String) -> Dictionary:
	var profile: Dictionary = {
		"flash_color": Color.TRANSPARENT,
		"flash_duration": 0.0,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"ring_width": 0.0,
		"burst_color": Color(0.64, 1.0, 0.84, 0.48),
		"burst_scale": 1.0,
		"sfx_cue": "parry"
	}

	if quality == "perfect":
		profile["burst_color"] = Color(0.70, 1.0, 0.86, 0.60)
		profile["burst_scale"] = 1.18
		profile["sfx_cue"] = "perfect_parry"

	return profile


static func build_enemy_hit_profile(damage: float, is_boss_target: bool) -> Dictionary:
	var heavy: bool = damage >= 18.0
	var profile: Dictionary = {
		"flash_color": Color(1.0, 0.44, 0.28, 0.035),
		"flash_duration": 0.035,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"burst_color": Color(1.0, 0.54, 0.36, 0.34),
		"burst_scale": 0.92,
		"enemy_push": 7.0,
		"enemy_scale": Vector2(1.12, 0.88),
		"sfx_cue": "enemy_hit"
	}

	if heavy:
		profile["shake_intensity"] = 0.55
		profile["shake_duration"] = 0.05
		profile["burst_scale"] = 1.08
		profile["enemy_push"] = 9.0
		profile["enemy_scale"] = Vector2(1.16, 0.84)
		profile["sfx_cue"] = "heavy_enemy_hit"

	if is_boss_target:
		profile["flash_color"] = Color(1.0, 0.64, 0.28, 0.04)
		profile["flash_duration"] = 0.04
		profile["shake_intensity"] = float(profile["shake_intensity"]) + 0.45
		profile["shake_duration"] = max(float(profile["shake_duration"]), 0.06)
		profile["burst_scale"] = float(profile["burst_scale"]) + 0.16
		profile["enemy_push"] = float(profile["enemy_push"]) + 2.0
		profile["enemy_scale"] = Vector2(1.20, 0.82) if heavy else Vector2(1.16, 0.86)
		profile["sfx_cue"] = "boss_hit"

	return profile


static func build_support_profile(effect_id: String, cadence_surge: bool) -> Dictionary:
	var profile: Dictionary = {
		"flash_color": Color.TRANSPARENT,
		"flash_duration": 0.0,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"burst_color": Color(0.92, 0.58, 0.24, 0.38),
		"burst_scale": 1.0,
		"sfx_cue": "support_trigger"
	}

	match effect_id:
		"bond_remnant_mend":
			profile["burst_color"] = Color(0.64, 0.98, 0.86, 0.34)
			profile["sfx_cue"] = "support_mend"
		"gruvek_gorge":
			profile["burst_color"] = Color(0.92, 0.54, 0.20, 0.44)
			profile["shake_intensity"] = 1.0
			profile["shake_duration"] = 0.08
			profile["sfx_cue"] = "support_gorge"
		"veilskin_phase":
			profile["burst_color"] = Color(0.62, 0.86, 1.0, 0.40)
			profile["sfx_cue"] = "support_phase"
		"knellspine_peal":
			profile["burst_color"] = Color(0.98, 0.82, 0.42, 0.40)
			profile["sfx_cue"] = "support_peal"
		"marrowward_ward":
			profile["burst_color"] = Color(0.78, 0.90, 0.82, 0.34)
			profile["sfx_cue"] = "support_ward"
		"gorefane_maul":
			profile["burst_color"] = Color(0.96, 0.42, 0.18, 0.46)
			profile["shake_intensity"] = 1.1
			profile["shake_duration"] = 0.08
			profile["sfx_cue"] = "support_maul"
		"hushcoil_lull":
			profile["burst_color"] = Color(0.60, 0.74, 0.96, 0.36)
			profile["sfx_cue"] = "support_lull"
		"thornback_rend":
			profile["burst_color"] = Color(0.98, 0.76, 0.32, 0.42)
			profile["shake_intensity"] = 0.7
			profile["shake_duration"] = 0.06
			profile["sfx_cue"] = "support_rend"
		_:
			pass

	if cadence_surge:
		profile["shake_intensity"] = float(profile["shake_intensity"]) + 0.35
		profile["shake_duration"] = max(float(profile["shake_duration"]), 0.06)
		profile["burst_scale"] = float(profile["burst_scale"]) + 0.12
		profile["sfx_cue"] = "%s_surge" % String(profile["sfx_cue"])

	return profile


static func build_boss_threshold_profile() -> Dictionary:
	return {
		"flash_color": Color(0.60, 0.28, 0.06, 0.22),
		"flash_duration": 0.22,
		"shake_intensity": 3.2,
		"shake_duration": 0.22,
		"sfx_cue": "boss_unleash"
	}
