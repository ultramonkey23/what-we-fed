extends RefCounted

# Combat Feel Constants - Centralized combat timing, visual feedback, and feel parameters
# This system ensures consistent combat feel across all systems and makes balance adjustments easier

# === TIMING CONSTANTS ===
const SLOW_MOTION_DURATION := {
	"parry_perfect_beat_perfect": 0.10,
	"parry_perfect_beat_good": 0.08,
	"parry_perfect_offbeat": 0.08,
	"timed_attack_perfect_beat_perfect": 0.08,
	"timed_attack_perfect_other": 0.06,
	"timed_attack_good": 0.04,
	"parry_followup": 0.04,
	"ultimate_perfect": 0.14,
	"ultimate_good": 0.12,
	"ultimate_base": 0.10,
	"counter_warp_perfect": 0.12,
	"counter_warp_good": 0.08,
	"boss_defeat": 0.8,
	"critical_hit": 0.2
}

const SLOW_MOTION_SCALES := {
	"parry_perfect_beat_perfect": 0.52,
	"parry_perfect_beat_good": 0.64,
	"parry_perfect_offbeat": 0.76,
	"timed_attack_perfect_beat_perfect": 0.68,
	"timed_attack_perfect_other": 0.80,
	"timed_attack_good": 0.88,
	"parry_followup": 0.86,
	"ultimate_perfect": 0.55,
	"ultimate_good": 0.62,
	"ultimate_base": 0.72,
	"counter_warp_perfect": 0.05,
	"counter_warp_good": 0.05,
	"hit_stop": 0.05
}

const HIT_STOP_DURATION := {
	"light_attack": 0.08,
	"heavy_attack": 0.12,
	"parry": 0.15,
	"perfect_parry": 0.2,
	"ultimate": 0.3,
	"boss_hit": 0.1
}

const TELEGRAPH_TIMING := {
	"base_duration": 0.8,
	"elite_duration": 1.2,
	"boss_duration": 1.5,
	"warning_fade": 0.15,
	"attack_windup": 0.3
}

const EXPOSE_WINDOW := {
	"base_duration": 1.2,
	"elite_duration": 1.0,
	"boss_duration": 0.8,
	"perfect_window": 0.4,
	"good_window": 0.8
}

# === CAMERA EFFECTS ===
const CAMERA_SHAKE := {
	"light_hit": {
		"intensity": 2.0,
		"duration": 0.15,
		"frequency": 15.0
	},
	"heavy_hit": {
		"intensity": 4.0,
		"duration": 0.25,
		"frequency": 12.0
	},
	"parry": {
		"intensity": 3.0,
		"duration": 0.2,
		"frequency": 20.0
	},
	"perfect_parry": {
		"intensity": 5.0,
		"duration": 0.3,
		"frequency": 25.0
	},
	"ultimate": {
		"intensity": 8.0,
		"duration": 0.5,
		"frequency": 10.0
	},
	"boss_impact": {
		"intensity": 6.0,
		"duration": 0.4,
		"frequency": 8.0
	}
}

const CAMERA_ZOOM := {
	"attack_zoom": {
		"amount": 1.1,
		"duration": 0.2,
		"ease_type": "ease_out"
	},
	"parry_zoom": {
		"amount": 1.15,
		"duration": 0.25,
		"ease_type": "ease_out"
	},
	"ultimate_zoom": {
		"amount": 1.3,
		"duration": 0.4,
		"ease_type": "ease_out"
	},
	"boss_zoom": {
		"amount": 1.2,
		"duration": 0.3,
		"ease_type": "ease_in_out"
	}
}

# === VISUAL EFFECTS ===
const AFFINITY_COLORS := {
	"flesh": Color(0.92, 0.28, 0.18, 0.52),    # Aggressive Red-Orange
	"hollow": Color(0.58, 0.88, 1.0, 0.44),    # Cold Ethereal Blue
	"gorge": Color(0.96, 0.52, 0.12, 0.48),    # Warm Predatory Orange
	"reflex": Color(0.24, 0.78, 1.0, 0.46),    # Sharp Signal Blue
	"cadence": Color(1.0, 0.88, 0.26, 0.50),   # Alert Pulse Gold
	"guard": Color(0.42, 0.72, 0.96, 0.46),    # Stable Shield Azure
	"hush": Color(0.64, 0.62, 0.84, 0.42),     # Dampened Violet
	"steel": Color(0.88, 0.92, 0.96, 0.48),    # Hard Metallic Grey
	"void": Color(0.12, 0.08, 0.16, 0.60)      # Deep Ink Black
}

const SCREEN_FLASH := {
	"light_damage": {
		"color": Color(1.0, 0.2, 0.2, 0.3),
		"duration": 0.1
	},
	"heavy_damage": {
		"color": Color(1.0, 0.1, 0.1, 0.5),
		"duration": 0.15
	},
	"perfect_parry": {
		"color": Color(1.0, 1.0, 1.0, 0.99), # 0.99 is the signal for Manga Inversion
		"duration": 0.08
	},
	"manga_inversion": {
		"color": Color(1.0, 1.0, 1.0, 0.99),
		"duration": 0.08
	},
	"ultimate_activation": {
		"color": Color(1.0, 0.8, 0.2, 0.6),
		"duration": 0.3
	},
	"heal": {
		"color": Color(0.2, 1.0, 0.4, 0.3),
		"duration": 0.2
	},
	"shield": {
		"color": Color(0.4, 0.8, 1.0, 0.3),
		"duration": 0.15
	},
	"boss_intro_1": {
		"color": Color(0.68, 0.32, 0.06, 0.34),
		"duration": 0.20
	},
	"boss_intro_2": {
		"color": Color(0.62, 0.24, 0.04, 0.20),
		"duration": 0.14
	},
	"boss_threshold": {
		"color": Color(0.74, 0.28, 0.04, 0.34),
		"duration": 0.20
	},
	"boss_threshold_pulse": {
		"color": Color(0.80, 0.32, 0.04, 0.20),
		"duration": 0.16
	}
}

const IMPACT_SCALING := {
	"light_hit": {
		"scale_multiplier": 1.2,
		"duration": 0.15
	},
	"heavy_hit": {
		"scale_multiplier": 1.5,
		"duration": 0.25
	},
	"critical_hit": {
		"scale_multiplier": 2.0,
		"duration": 0.3
	},
	"parry": {
		"scale_multiplier": 1.8,
		"duration": 0.2
	},
	"ultimate": {
		"scale_multiplier": 2.5,
		"duration": 0.4
	}
}

# === AUDIO FEEDBACK ===
const AUDIO_PITCH := {
	"light_attack": 1.0,
	"heavy_attack": 0.9,
	"perfect_timing": 1.2,
	"parry": 1.1,
	"ultimate": 0.8,
	"boss_hit": 0.85
}

const AUDIO_VOLUME := {
	"base_sfx": 1.0,
	"impact_sfx": 1.2,
	"parry_sfx": 1.3,
	"ultimate_sfx": 1.5,
	"boss_sfx": 1.4,
	"ambient_music": 0.7,
	"combat_music": 0.9
}

# === COMBAT METER FEEL ===
const COMBO_FEEDBACK := {
	"combo_break_shake": {
		"intensity": 3.0,
		"duration": 0.2,
		"frequency": 18.0
	},
	"tier_upgrade_flash": {
		"color": Color(1.0, 0.9, 0.3, 0.4),
		"duration": 0.25
	},
	"ultimate_ready_glow": {
		"color": Color(1.0, 0.7, 0.2, 0.6),
		"pulse_duration": 1.0,
		"pulse_intensity": 0.3
	}
}

const STAMINA_FEEDBACK := {
	"low_stamina_tint": Color(1.0, 0.3, 0.3, 0.2),
	"no_stamina_flash": {
		"color": Color(1.0, 0.1, 0.1, 0.5),
		"duration": 0.2
	},
	"stamina_gain_pulse": {
		"scale": 1.1,
		"duration": 0.1
	}
}

# === UI ANIMATION ===
const UI_ANIMATIONS := {
	"damage_number": {
		"rise_speed": 60.0,
		"fade_duration": 1.0,
		"scale_curve": [0.5, 1.2, 1.0, 0.8],
		"critical_scale": 1.5
	},
	"combo_counter": {
		"pop_scale": 1.3,
		"pop_duration": 0.15,
		"shake_intensity": 2.0,
		"shake_duration": 0.1
	},
	"health_bar": {
		"shake_on_damage": {
			"intensity": 1.5,
			"duration": 0.1
		},
		"smooth_lerp_speed": 8.0,
		"damage_show_duration": 0.3
	},
	"ultimate_ready": {
		"glow_pulse_speed": 2.0,
		"border_flash_speed": 3.0,
		"ready_scale": 1.05
	}
}

# === LANE AND TIMING ===
const LANE_VISUALS := {
	"ring_active_scale": 1.0,
	"ring_inactive_scale": 0.8,
	"ring_perfect_scale": 1.2,
	"ring_good_scale": 1.1,
	"ring_transition_speed": 0.15,
	"lane_highlight_intensity": 0.3,
	"danger_lane_tint": Color(1.0, 0.2, 0.2, 0.4)
}

const TIMING_WINDOWS := {
	"perfect_timing_ms": 65,
	"good_timing_ms": 130,
	"attack_buffer_ms": 100,
	"parry_buffer_ms": 150,
	"dodge_buffer_ms": 200
}

# === PARTICLE EFFECTS ===
const PARTICLE_SYSTEMS := {
	"blood_splash": {
		"count": 15,
		"spread": 45.0,
		"initial_velocity": 100.0,
		"lifetime": 0.8,
		"color": Color(0.8, 0.1, 0.1, 0.8)
	},
	"parry_spark": {
		"count": 8,
		"spread": 30.0,
		"initial_velocity": 150.0,
		"lifetime": 0.4,
		"color": Color(0.2, 1.0, 0.8, 0.9)
	},
	"ultimate_burst": {
		"count": 25,
		"spread": 360.0,
		"initial_velocity": 200.0,
		"lifetime": 1.2,
		"color": Color(1.0, 0.8, 0.2, 0.7)
	},
	"heal_aura": {
		"count": 12,
		"spread": 180.0,
		"initial_velocity": 50.0,
		"lifetime": 1.0,
		"color": Color(0.2, 1.0, 0.4, 0.6)
	}
}

# === UTILITY FUNCTIONS ===
static func get_slow_motion_duration(event_type: String) -> float:
	return SLOW_MOTION_DURATION.get(event_type, 0.1)

static func get_slow_motion_scale(event_type: String) -> float:
	return SLOW_MOTION_SCALES.get(event_type, 1.0)

static func get_hit_stop_duration(attack_type: String) -> float:
	return HIT_STOP_DURATION.get(attack_type, 0.1)

static func get_camera_shake_params(shake_type: String) -> Dictionary:
	return CAMERA_SHAKE.get(shake_type, {"intensity": 1.0, "duration": 0.1, "frequency": 10.0})

static func get_screen_flash_params(flash_type: String) -> Dictionary:
	return SCREEN_FLASH.get(flash_type, {"color": Color.WHITE, "duration": 0.1})

static func get_affinity_color(affinity: String) -> Color:
	return AFFINITY_COLORS.get(affinity, Color(1.0, 1.0, 1.0, 0.4))

static func get_timing_window_ms(window_type: String) -> float:
	return TIMING_WINDOWS.get(window_type, 100.0)

static func get_impact_scaling(impact_type: String) -> Dictionary:
	return IMPACT_SCALING.get(impact_type, {"scale_multiplier": 1.0, "duration": 0.1})

static func get_ui_animation_params(ui_element: String) -> Dictionary:
	return UI_ANIMATIONS.get(ui_element, {})

static func get_particle_params(particle_type: String) -> Dictionary:
	return PARTICLE_SYSTEMS.get(particle_type, {"count": 5, "lifetime": 0.5})

# === DIFFICULTY SCALING ===
static func apply_difficulty_scaling(base_value: float, difficulty: String, scaling_type: String) -> float:
	var scaling_factors: Dictionary = {
		"easy": {"timing": 1.2, "damage": 0.8, "speed": 0.9},
		"medium": {"timing": 1.0, "damage": 1.0, "speed": 1.0},
		"hard": {"timing": 0.8, "damage": 1.3, "speed": 1.1},
		"extreme": {"timing": 0.6, "damage": 1.6, "speed": 1.2}
	}
	
	var factors: Dictionary = scaling_factors.get(difficulty, scaling_factors["medium"])
	var multiplier: float = factors.get(scaling_type, 1.0)
	
	return base_value * multiplier
