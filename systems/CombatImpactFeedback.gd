extends RefCounted

# Small impact/readability helper for CombatScene.
# Now uses centralized CombatFeelConstants for consistent feel across all systems.

const COMBAT_FEEL_CONSTANTS = preload("res://data/CombatFeelConstants.gd")


static func build_timed_attack_profile(quality: String, _beat_quality: String) -> Dictionary:
	var base_flash: Dictionary = COMBAT_FEEL_CONSTANTS.get_screen_flash_params("light_damage")
	var base_shake: Dictionary = COMBAT_FEEL_CONSTANTS.get_camera_shake_params("light_hit")
	var base_hitstop: float = COMBAT_FEEL_CONSTANTS.get_hit_stop_duration("light_attack")
	var base_impact: Dictionary = COMBAT_FEEL_CONSTANTS.get_impact_scaling("light_hit")
	
	var profile: Dictionary = {
		"flash_color": base_flash.get("color", Color(1.0, 0.80, 0.28, 0.07)),
		"flash_duration": base_flash.get("duration", 0.04),
		"shake_intensity": base_shake.get("intensity", 0.40),
		"shake_duration": base_shake.get("duration", 0.04),
		"hitstop_scale": 0.88,
		"hitstop_duration": base_hitstop,
		"ring_width": 3.4,
		"burst_color": Color(1.0, 0.86, 0.38, 0.54),
		"burst_scale": base_impact.get("scale_multiplier", 1.10),
		"enemy_push": 8.0,
		"enemy_scale": Vector2(1.16, 0.84),
		"sfx_cue": "timed_hit"
	}

	if quality == "perfect":
		var perfect_flash: Dictionary = COMBAT_FEEL_CONSTANTS.get_screen_flash_params("perfect_parry")
		var perfect_shake: Dictionary = COMBAT_FEEL_CONSTANTS.get_camera_shake_params("perfect_parry")
		var perfect_hitstop: float = COMBAT_FEEL_CONSTANTS.get_hit_stop_duration("perfect_parry")
		var perfect_impact: Dictionary = COMBAT_FEEL_CONSTANTS.get_impact_scaling("critical_hit")
		
		profile["flash_color"] = perfect_flash.get("color", Color(1.0, 0.88, 0.32, 0.13))
		profile["flash_duration"] = perfect_flash.get("duration", 0.07)
		profile["shake_intensity"] = perfect_shake.get("intensity", 0.95)
		profile["shake_duration"] = perfect_shake.get("duration", 0.07)
		profile["hitstop_scale"] = 0.70
		profile["hitstop_duration"] = perfect_hitstop
		profile["ring_width"] = 5.4
		profile["burst_color"] = Color(1.0, 0.92, 0.50, 0.70)
		profile["burst_scale"] = perfect_impact.get("scale_multiplier", 1.50)
		profile["enemy_push"] = 13.0
		profile["enemy_scale"] = Vector2(1.26, 0.74)
		profile["sfx_cue"] = "perfect_timed_hit"

	return profile


static func build_parry_profile(quality: String, _beat_quality: String) -> Dictionary:
	var profile: Dictionary = {
		"flash_color": Color(0.40, 0.90, 0.65, 0.08),
		"flash_duration": 0.05,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"ring_width": 3.6,
		"burst_color": Color(0.64, 1.0, 0.84, 0.54),
		"burst_scale": 1.14,
		"sfx_cue": "parry"
	}

	if quality == "perfect":
		var perf_flash: Dictionary = COMBAT_FEEL_CONSTANTS.get_screen_flash_params("perfect_parry")
		profile["flash_color"] = perf_flash.get("color", Color(1.0, 1.0, 1.0, 0.99))
		profile["flash_duration"] = perf_flash.get("duration", 0.08)
		profile["shake_intensity"] = 0.85
		profile["shake_duration"] = 0.07
		profile["hitstop_scale"] = 0.65
		profile["hitstop_duration"] = 0.09
		profile["ring_width"] = 6.0
		profile["burst_color"] = Color(0.70, 1.0, 0.86, 0.72)
		profile["burst_scale"] = 1.46
		profile["sfx_cue"] = "perfect_parry"

	return profile


static func build_enemy_hit_profile(damage: float, is_boss_target: bool) -> Dictionary:
	var heavy: bool = damage >= 18.0
	var profile: Dictionary = {
		"flash_color": Color(1.0, 0.44, 0.28, 0.058),
		"flash_duration": 0.04,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"burst_color": Color(1.0, 0.54, 0.36, 0.42),
		"burst_scale": 0.96,
		"enemy_push": 7.0,
		"enemy_scale": Vector2(1.12, 0.88),
		"sfx_cue": "enemy_hit"
	}

	if heavy:
		profile["flash_color"] = Color(1.0, 0.42, 0.20, 0.075)
		profile["flash_duration"] = 0.05
		profile["shake_intensity"] = 0.72
		profile["shake_duration"] = 0.06
		profile["hitstop_scale"] = 0.82
		profile["hitstop_duration"] = 0.05
		profile["burst_scale"] = 1.22
		profile["enemy_push"] = 11.0
		profile["enemy_scale"] = Vector2(1.20, 0.80)
		profile["sfx_cue"] = "heavy_enemy_hit"

	if is_boss_target:
		profile["flash_color"] = Color(1.0, 0.62, 0.24, 0.065)
		profile["flash_duration"] = 0.05
		profile["shake_intensity"] = float(profile["shake_intensity"]) + 0.55
		profile["shake_duration"] = max(float(profile["shake_duration"]), 0.07)
		profile["hitstop_scale"] = min(float(profile.get("hitstop_scale", 0.90)), 0.76)
		profile["hitstop_duration"] = max(float(profile.get("hitstop_duration", 0.03)), 0.06)
		profile["burst_scale"] = float(profile["burst_scale"]) + 0.22
		profile["enemy_push"] = float(profile["enemy_push"]) + 2.0
		profile["enemy_scale"] = Vector2(1.24, 0.78) if heavy else Vector2(1.18, 0.84)
		profile["sfx_cue"] = "boss_hit"

	return profile


static func build_support_profile(effect_id: String, cadence_surge: bool, bond_surge: bool = false) -> Dictionary:
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
		"coldvein_expose":
			# Precision parry counter — cold, sharp, immediate. Blue-white burst on the exposed enemy.
			profile["burst_color"] = Color(0.74, 0.92, 1.0, 0.44)
			profile["shake_intensity"] = 0.55
			profile["shake_duration"] = 0.05
			profile["sfx_cue"] = "support_expose"
		"siltgrip_drag":
			# Kill-rend — teal, wet, spreading. Rends survivors across all lanes on each kill.
			profile["burst_color"] = Color(0.38, 0.78, 0.62, 0.40)
			profile["shake_intensity"] = 0.65
			profile["shake_duration"] = 0.06
			profile["sfx_cue"] = "support_drag"
		_:
			pass

	if cadence_surge:
		profile["shake_intensity"] = float(profile["shake_intensity"]) + 0.35
		profile["shake_duration"] = max(float(profile["shake_duration"]), 0.06)
		profile["burst_scale"] = float(profile["burst_scale"]) + 0.12
		profile["sfx_cue"] = "%s_surge" % String(profile["sfx_cue"])

	if bond_surge:
		profile["flash_color"] = Color(0.44, 0.96, 0.78, 0.12)
		profile["flash_duration"] = 0.14
		profile["burst_scale"] = float(profile.get("burst_scale", 1.0)) + 0.25
		profile["sfx_cue"] = "support_sync"

	return profile


static func build_boss_threshold_profile() -> Dictionary:
	return {
		"flash_color": Color(0.74, 0.28, 0.04, 0.34),
		"flash_duration": 0.28,
		"shake_intensity": 4.4,
		"shake_duration": 0.30,
		"sfx_cue": "boss_unleash"
	}


static func build_tendency_surge_profile(tendency_id: String) -> Dictionary:
	# Visual accent profile for real-time tendency surge events.
	# Lightweight — suggests power shift without disrupting combat reads.
	var profile: Dictionary = {
		"flash_color": Color(0.80, 0.70, 0.26, 0.08),
		"flash_duration": 0.08,
		"shake_intensity": 0.55,
		"shake_duration": 0.06,
		"sfx_cue": "tendency_surge"
	}
	match tendency_id:
		"aggression":
			profile["flash_color"] = Color(0.90, 0.28, 0.08, 0.10)
		"cadence":
			profile["flash_color"] = Color(0.90, 0.82, 0.22, 0.09)
		"guard":
			profile["flash_color"] = Color(0.38, 0.70, 0.90, 0.09)
		"bond":
			profile["flash_color"] = Color(0.38, 0.88, 0.62, 0.09)
	return profile
