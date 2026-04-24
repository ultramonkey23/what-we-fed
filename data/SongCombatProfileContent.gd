extends RefCounted

const RUN_PACING_CONTENT = preload("res://data/RunPacingContent.gd")
const SONG_LIBRARY = preload("res://data/SongLibraryContent.gd")

# Song-to-encounter mapping entrypoint.
# Keeps regular song routing explicit and boss routing stable.
const REGION_ENCOUNTER_SONG_MAP: Dictionary = {
	"feeding_hollow": {"regular": "tricky", "boss": "boss_1"},
	"pale_shelf": {"regular": "newness", "boss": "boss_1"},
	"drowned_cut": {"regular": "grind_the_orbit", "boss": "boss_1"},
	"echoing_chasm": {"regular": "void_echo", "boss": "boss_1"},
	"crystalline_spire": {"regular": "crystal_refraction", "boss": "boss_1"},
	"whispering_marsh": {"regular": "marsh_whispers", "boss": "boss_1"},
	"iron_boneyard": {"regular": "iron_forged", "boss": "boss_1"},
	"sunken_library": {"regular": "dissolved_knowledge", "boss": "boss_1"}
}

const DEFAULT_PROFILE: Dictionary = {
	"id": "default",
	"display_name": "Default Song Combat",
	"cadence_law": {
		"cycle_interval_mult": 1.0,
		"fire_stagger_mult": 1.0,
		"section_spawn_cap_by_id": {
			"final": 0.86
		}
	},
	"lane_law": {
		"accent_burst_strength": 1.0
	},
	"pressure_law": {
		"accent_feedback_scale": 1.2
	},
	"reward_emphasis_law": {
		"offer_decay_mult": 1.0,
		"level_choice_delta": 0
	},
	"progression_law": {
		"beat_quality_values": {
			"perfect": 1.0,
			"good": 0.74,
			"off": 0.38
		},
		"skill_weights": {
			"combo": 0.38,
			"phrase": 0.30,
			"tier": 0.22,
			"beat": 0.10
		}
	},
	"conductor_contract": {
		"cadence_window_rules": [
			{"window": "surge", "section_ids": ["final"], "intensity_gte": 0.85},
			{"window": "drive", "section_ids": ["chorus"], "intensity_gte": 0.62}
		],
		"accent_threshold": -1.0
	},
	"boss_decree_law": {
		"section_triggers": {
			"chorus": {
				"decree_id": "boss_song_chorus",
				"duration": 0.90,
				"meta": {"boss_phase": "song_chorus"}
			},
			"final": {
				"decree_id": "boss_song_final",
				"duration": 1.04,
				"meta": {"boss_phase": "song_final"},
				"set_boss_threshold_fired": true,
				"notify_threshold": {
					"id": "sovereign_unleash",
					"value": 8.0,
					"label": "BOSS BREAK"
				},
				"trigger_threshold_spectacle": true
			}
		}
	}
}

# ─── RESONANCE TIERS ────────────────────────────────────────────────────────
# Maps song intensity to core mechanical laws.
const RESONANCE_TIERS: Dictionary = {
	"GHOST": {
		"id": "ghost",
		"intensity_range": [0.0, 0.2],
		"cadence_mult": 1.2,
		"density_mult": 0.8,
		"perfect_window_ms": 150,
		"accent_boost": 0.0
	},
	"STEADY": {
		"id": "steady",
		"intensity_range": [0.2, 0.5],
		"cadence_mult": 1.0,
		"density_mult": 1.0,
		"perfect_window_ms": 130,
		"accent_boost": 0.0
	},
	"DRIVE": {
		"id": "drive",
		"intensity_range": [0.5, 0.75],
		"cadence_mult": 0.8,
		"density_mult": 1.2,
		"perfect_window_ms": 100,
		"accent_boost": 60
	},
	"SURGE": {
		"id": "surge",
		"intensity_range": [0.75, 0.9],
		"cadence_mult": 0.6,
		"density_mult": 1.5,
		"perfect_window_ms": 80,
		"accent_boost": 60
	},
	"APEX": {
		"id": "apex",
		"intensity_range": [0.9, 1.0],
		"cadence_mult": 0.4,
		"density_mult": 2.0,
		"perfect_window_ms": 65,
		"accent_boost": 80
	}
}

static func resolve_resonance_tier(intensity: float) -> Dictionary:
	var intensity_val: float = clampf(intensity, 0.0, 1.0)
	if intensity_val >= 0.9: return RESONANCE_TIERS.APEX
	if intensity_val >= 0.75: return RESONANCE_TIERS.SURGE
	if intensity_val >= 0.5: return RESONANCE_TIERS.DRIVE
	if intensity_val >= 0.2: return RESONANCE_TIERS.STEADY
	return RESONANCE_TIERS.GHOST

const SONG_PROFILES: Dictionary = {
	"tricky": {
		"id": "tricky",
		"display_name": "Tricky Combat Law",
		"cadence_law": {
			"cycle_interval_mult": 1.0,
			"fire_stagger_mult": 1.0,
			"section_spawn_cap_by_id": {"final": 0.86}
		},
		"lane_law": {"accent_burst_strength": 1.03},
		"pressure_law": {"accent_feedback_scale": 1.17},
		"reward_emphasis_law": {
			"offer_decay_mult": 1.00,
			"level_choice_delta": 0
		},
		"progression_law": {
			"beat_quality_values": {
				"perfect": 1.00,
				"good": 0.74,
				"off": 0.38
			},
			"skill_weights": {
				"combo": 0.40,
				"phrase": 0.29,
				"tier": 0.21,
				"beat": 0.10
			}
		},
		"conductor_contract": {
			"cadence_window_rules": [
				{"window": "surge", "section_ids": ["final"], "intensity_gte": 0.84},
				{"window": "drive", "section_ids": ["chorus"], "intensity_gte": 0.61}
			],
			"accent_threshold": 0.52
		}
	},
	"newness": {
		"id": "newness",
		"display_name": "Newness Combat Law",
		"cadence_law": {
			"cycle_interval_mult": 0.99,
			"fire_stagger_mult": 1.05,
			"section_spawn_cap_by_id": {"final": 0.90}
		},
		"lane_law": {"accent_burst_strength": 0.94},
		"pressure_law": {"accent_feedback_scale": 1.08},
		"reward_emphasis_law": {
			"offer_decay_mult": 0.97,
			"level_choice_delta": 1
		},
		"progression_law": {
			"beat_quality_values": {
				"perfect": 1.00,
				"good": 0.78,
				"off": 0.42
			},
			"skill_weights": {
				"combo": 0.34,
				"phrase": 0.33,
				"tier": 0.20,
				"beat": 0.13
			}
		},
		"conductor_contract": {
			"cadence_window_rules": [
				{"window": "surge", "section_ids": ["final"], "intensity_gte": 0.88},
				{"window": "drive", "section_ids": ["chorus"], "intensity_gte": 0.68}
			],
			"accent_threshold": 0.56
		}
	},
	"grind_the_orbit": {
		"id": "grind_the_orbit",
		"display_name": "Grind the Orbit Combat Law",
		"cadence_law": {
			"cycle_interval_mult": 0.94,
			"fire_stagger_mult": 0.97,
			"section_spawn_cap_by_id": {"final": 0.82}
		},
		"lane_law": {"accent_burst_strength": 1.10},
		"pressure_law": {"accent_feedback_scale": 1.26},
		"reward_emphasis_law": {
			"offer_decay_mult": 1.03,
			"level_choice_delta": -1
		},
		"progression_law": {
			"beat_quality_values": {
				"perfect": 1.00,
				"good": 0.71,
				"off": 0.34
			},
			"skill_weights": {
				"combo": 0.43,
				"phrase": 0.27,
				"tier": 0.22,
				"beat": 0.08
			}
		},
		"conductor_contract": {
			"cadence_window_rules": [
				{"window": "surge", "section_ids": ["final"], "intensity_gte": 0.81},
				{"window": "drive", "section_ids": ["chorus"], "intensity_gte": 0.58}
			],
			"accent_threshold": 0.49
		}
	},
	"black_sun_rising_over_shattered_spires": {
		"id": "black_sun_rising_over_shattered_spires",
		"display_name": "Black Sun Combat Law",
		"cadence_law": {
			"cycle_interval_mult": 0.96,
			"fire_stagger_mult": 1.02,
			"section_spawn_cap_by_id": {"final": 0.84}
		},
		"lane_law": {"accent_burst_strength": 1.05},
		"pressure_law": {"accent_feedback_scale": 1.20}
	},
	"damnheavy": {
		"id": "damnheavy",
		"display_name": "DAMNHEAVY Combat Law",
		"cadence_law": {
			"cycle_interval_mult": 0.92,
			"fire_stagger_mult": 1.06,
			"section_spawn_cap_by_id": {"final": 0.82}
		},
		"lane_law": {"accent_burst_strength": 1.10},
		"pressure_law": {"accent_feedback_scale": 1.28},
		"reward_emphasis_law": {
			"offer_decay_mult": 1.04,
			"level_choice_delta": 0
		}
	},
	"boss_1": {
		"id": "boss_1",
		"display_name": "Boss 1 Decree Law",
		"cadence_law": {
			"cycle_interval_mult": 0.98,
			"fire_stagger_mult": 0.96,
			"section_spawn_cap_by_id": {
				"chorus": 0.92,
				"final": 0.84
			}
		},
		"lane_law": {"accent_burst_strength": 1.08},
		"pressure_law": {"accent_feedback_scale": 1.25},
		"conductor_contract": {
			"cadence_window_rules": [
				{"window": "surge", "section_ids": ["final"], "intensity_gte": 0.78},
				{"window": "drive", "section_ids": ["chorus"], "intensity_gte": 0.56}
			],
			"accent_threshold": 0.47
		},
		"boss_decree_law": {
			"section_triggers": {
				"chorus": {
					"decree_id": "boss_song_chorus",
					"duration": 0.94,
					"meta": {"boss_phase": "song_chorus", "intensity_step": "medium"}
				},
				"final": {
					"decree_id": "boss_song_final",
					"duration": 1.08,
					"meta": {"boss_phase": "song_final", "intensity_step": "high"},
					"set_boss_threshold_fired": true,
					"notify_threshold": {
						"id": "sovereign_unleash",
						"value": 8.0,
						"label": "BOSS BREAK"
					},
					"trigger_threshold_spectacle": true
				}
			}
		}
	}
}


static func get_profile(song_id: String) -> Dictionary:
	var profile: Dictionary = DEFAULT_PROFILE.duplicate(true)
	if SONG_PROFILES.has(song_id):
		_merge_dict(profile, Dictionary(SONG_PROFILES[song_id]))
	return profile


static func get_regular_song_id_for_region(region_id: String) -> String:
	var map_entry: Dictionary = Dictionary(REGION_ENCOUNTER_SONG_MAP.get(region_id, {}))
	if not String(map_entry.get("regular", "")).is_empty():
		return String(map_entry.get("regular", ""))
	return String(SONG_LIBRARY.REGION_MAIN_RUN_SONG_IDS.get(region_id, SONG_LIBRARY.LIVE_MAIN_RUN_SONG_ID))


static func get_boss_song_id_for_region(region_id: String) -> String:
	var map_entry: Dictionary = Dictionary(REGION_ENCOUNTER_SONG_MAP.get(region_id, {}))
	if not String(map_entry.get("boss", "")).is_empty():
		return String(map_entry.get("boss", ""))
	return SONG_LIBRARY.LIVE_BOSS_SONG_ID


static func get_playlist_for_region(level_count: int, region_id: String, rng: RandomNumberGenerator) -> Array:
	var playlist: Array = SONG_LIBRARY.build_randomized_regular_level_playlist(level_count, rng)
	if playlist.is_empty():
		return playlist

	var region_song_id: String = get_regular_song_id_for_region(region_id)
	if region_song_id.is_empty():
		return playlist
	var region_song: Dictionary = SONG_LIBRARY.get_song(region_song_id)
	if region_song.is_empty():
		return playlist
	if String(region_song.get("status", "")) != "live":
		return playlist
	if String(region_song.get("timing_map_status", "")) != "mapped":
		return playlist
	if SONG_LIBRARY.get_song_map(region_song) == null:
		return playlist
	playlist[0] = region_song
	return playlist


static func build_level_difficulty_modifiers(region_id: String, level_idx: int, encounter_options: Dictionary, song_profile: Dictionary = {}) -> Dictionary:
	var mods: Dictionary = RUN_PACING_CONTENT.get_level_difficulty_modifiers(region_id, level_idx)
	if bool(encounter_options.get("elite", false)):
		var quality_band: Dictionary = Dictionary(mods.get("threat_quality", {}))
		quality_band["high_grade_weight_mult"] = float(quality_band.get("high_grade_weight_mult", 1.0)) * 1.12
		mods["threat_quality"] = quality_band

		var lane_band: Dictionary = Dictionary(mods.get("lane_pressure", {}))
		lane_band["respawn_delay_mult"] = float(lane_band.get("respawn_delay_mult", 1.0)) * 0.90
		lane_band["max_active_threats_bonus"] = int(lane_band.get("max_active_threats_bonus", 0)) + 1
		mods["lane_pressure"] = lane_band

		var reward_band: Dictionary = Dictionary(mods.get("reward_pressure", {}))
		reward_band["level_choice_delta"] = int(reward_band.get("level_choice_delta", 0)) - 1
		mods["reward_pressure"] = reward_band

	_apply_risk_modifier_law(mods, Dictionary(encounter_options.get("risk_modifier", {})))
	_apply_profile_reward_law(mods, song_profile)
	return mods


static func apply_cadence_law_to_values(song_profile: Dictionary, section_id: String, spawn_mult: float, cycle_interval: float, fire_stagger: float) -> Dictionary:
	var cadence_law: Dictionary = Dictionary(song_profile.get("cadence_law", {}))
	var section_cap_by_id: Dictionary = Dictionary(cadence_law.get("section_spawn_cap_by_id", {}))
	var resolved_spawn_mult: float = spawn_mult
	if section_cap_by_id.has(section_id):
		resolved_spawn_mult = minf(resolved_spawn_mult, float(section_cap_by_id.get(section_id, resolved_spawn_mult)))

	return {
		"spawn_mult": resolved_spawn_mult,
		"cycle_interval": cycle_interval * float(cadence_law.get("cycle_interval_mult", 1.0)),
		"fire_stagger": fire_stagger * float(cadence_law.get("fire_stagger_mult", 1.0))
	}


static func resolve_cadence_window(song_profile: Dictionary, section_id: String, intensity: float) -> String:
	var conductor_contract: Dictionary = Dictionary(song_profile.get("conductor_contract", {}))
	var rules: Array = Array(conductor_contract.get("cadence_window_rules", []))
	for rule in rules:
		var entry: Dictionary = Dictionary(rule)
		var sections: Array = Array(entry.get("section_ids", []))
		if not sections.is_empty() and not sections.has(section_id):
			continue
		if intensity < float(entry.get("intensity_gte", 0.0)):
			continue
		var window_id: String = String(entry.get("window", ""))
		if not window_id.is_empty():
			return window_id
	return ""


static func resolve_accent_threshold(song_profile: Dictionary, song_map_script) -> float:
	var contract: Dictionary = Dictionary(song_profile.get("conductor_contract", {}))
	var profile_threshold: float = float(contract.get("accent_threshold", -1.0))
	if profile_threshold >= 0.0:
		return profile_threshold
	if "BASS_ACCENT_THRESHOLD" in song_map_script:
		return float(song_map_script.BASS_ACCENT_THRESHOLD)
	return 0.5


static func get_boss_section_rule(song_profile: Dictionary, section_id: String) -> Dictionary:
	var boss_law: Dictionary = Dictionary(song_profile.get("boss_decree_law", {}))
	var section_rules: Dictionary = Dictionary(boss_law.get("section_triggers", {}))
	if section_rules.has(section_id):
		return Dictionary(section_rules[section_id]).duplicate(true)
	return {}


static func _apply_profile_reward_law(mods: Dictionary, song_profile: Dictionary) -> void:
	var reward_law: Dictionary = Dictionary(song_profile.get("reward_emphasis_law", {}))
	if reward_law.is_empty():
		return
	var reward_band: Dictionary = Dictionary(mods.get("reward_pressure", {}))
	reward_band["offer_decay_mult"] = float(reward_band.get("offer_decay_mult", 1.0)) * float(reward_law.get("offer_decay_mult", 1.0))
	reward_band["level_choice_delta"] = int(reward_band.get("level_choice_delta", 0)) + int(reward_law.get("level_choice_delta", 0))
	mods["reward_pressure"] = reward_band


static func _apply_risk_modifier_law(mods: Dictionary, risk_modifier: Dictionary) -> void:
	if risk_modifier.is_empty():
		return
	var modifier_bands: Dictionary = Dictionary(risk_modifier.get("difficulty_modifiers", {}))
	for band_key in modifier_bands.keys():
		var current_band: Dictionary = Dictionary(mods.get(band_key, {})).duplicate(true)
		var risk_band: Dictionary = Dictionary(modifier_bands.get(band_key, {}))
		for value_key in risk_band.keys():
			var risk_value: Variant = risk_band[value_key]
			if risk_value is int or risk_value is float:
				if String(value_key).ends_with("_bonus"):
					current_band[value_key] = int(current_band.get(value_key, 0)) + int(risk_value)
				else:
					current_band[value_key] = float(current_band.get(value_key, 1.0)) * float(risk_value)
			else:
				current_band[value_key] = risk_value
		mods[band_key] = current_band


static func _merge_dict(base: Dictionary, overlay: Dictionary) -> void:
	for key in overlay.keys():
		var next_value: Variant = overlay[key]
		if next_value is Dictionary and base.get(key) is Dictionary:
			var nested: Dictionary = Dictionary(base.get(key)).duplicate(true)
			_merge_dict(nested, Dictionary(next_value))
			base[key] = nested
		else:
			base[key] = next_value
