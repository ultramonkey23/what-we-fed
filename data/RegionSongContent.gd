extends RefCounted

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")

# Per-region song phase definitions.
# CombatScene._start_song_run() selects from here based on GameState.active_region.id.
#
# Three identities:
#   feeding_hollow — predatory baseline; kill-tempo, flesh-forward, escalating bond_reaper density
#   pale_shelf     — attritional exposure; bond_reapers arrive early, enemies hit harder, fewer
#                    active threats but each is more punishing
#   drowned_cut    — resonant volume; weaker enemies, more alive at once, fast kills fuel support
#
# start_time values:
#   Used ONLY by the dev harness to seed the SongConductor at the right playback position
#   when jumping to a specific phase mid-song. Normal gameplay ignores these — all transitions
#   are driven by the SongConductor's fraction-based section boundaries.
#
#   Each value is derived from: section_start_fraction × actual_song_duration_seconds.
#   Song durations confirmed from WAV headers:
#     tricky.wav          (feeding_hollow) — 142.9 s  (44100 Hz 32-bit stereo)
#     newness.wav         (pale_shelf)     — 202.8 s  (48000 Hz 16-bit stereo)
#     Grind the Orbit.wav (drowned_cut)    — 323.0 s  (48000 Hz 16-bit stereo)

const SONG_PHASES_BY_REGION: Dictionary = {

	"feeding_hollow": [
		# Collapse / hunt cadence: stagger narrows as the song accelerates.
		# Wide opening → tighter chorus → brief relief in breakdown → tightest final.
		# Phase start_times: fraction × 142.9 s (tricky.wav confirmed duration)
		{
			"id": "opening",
			"label": "THE SONG BEGINS",
			"start_time": 0.0,
			"cycle_interval": 2.3,
			"fire_stagger": 0.52,
			"max_active_threats": 2,
			"population_target": 4,
			"authority_target": 2,
			"pressure_cap": 1.65,
			"enemy_pool": [
				{"species_id": "ashclaw", "grade": "brood", "hp": 28.0, "damage": 7.0, "weight": 0.50},
				{"species_id": "gruvek", "grade": "brood", "hp": 30.0, "damage": 8.0, "weight": 0.25},
				{"species_id": "gorefane", "grade": "brood", "hp": 27.0, "damage": 7.0, "weight": 0.25}
			],
			"intro_text": "Something stirs above.",
			"reward_pool": ["ashclaw", "gruvek", "gorefane"]
		},
		{
			"id": "rising",
			"label": "RISING VERSE",
			"start_time": 27.0,
			"cycle_interval": 1.9,
			"fire_stagger": 0.50,
			"max_active_threats": 3,
			"population_target": 5,
			"authority_target": 2,
			"pressure_cap": 2.00,
			"enemy_pool": [
				{"species_id": "ashclaw", "hp": 31.0, "damage": 8.0, "weight": 0.36},
				{"species_id": "gruvek", "hp": 34.0, "damage": 9.0, "weight": 0.20},
				{"species_id": "gorefane", "hp": 32.0, "damage": 8.0, "weight": 0.26},
				{"species_id": "thornback", "grade": "brood", "hp": 35.0, "damage": 9.0, "weight": 0.18}
			],
			"intro_text": "It learns your rhythm.",
			"reward_pool": ["ashclaw", "gorefane", "thornback"]
		},
		{
			"id": "chorus",
			"label": "FIRST CHORUS",
			"start_time": 63.0,
			"cycle_interval": 1.5,
			"fire_stagger": 0.46,
			"max_active_threats": 3,
			"population_target": 6,
			"authority_target": 2,
			"pressure_cap": 2.25,
			"enemy_pool": [
				{"species_id": "gruvek", "hp": 36.0, "damage": 10.0, "weight": 0.28},
				{"species_id": "gorefane", "hp": 35.0, "damage": 9.0, "weight": 0.24},
				{"species_id": "thornback", "hp": 38.0, "damage": 10.0, "weight": 0.30},
				{"species_id": "bond_remnant", "grade": "brood", "hp": 40.0, "damage": 10.0, "weight": 0.18}
			],
			"intro_text": "The song opens its mouth.",
			"reward_pool": ["gruvek", "gorefane", "thornback", "bond_remnant"]
		},
		{
			"id": "breakdown",
			"label": "BREAKDOWN",
			"start_time": 90.0,
			"cycle_interval": 1.8,
			"fire_stagger": 0.54,
			"max_active_threats": 2,
			"population_target": 5,
			"authority_target": 2,
			"pressure_cap": 1.90,
			"enemy_pool": [
				{"species_id": "ashclaw", "hp": 30.0, "damage": 8.0, "weight": 0.32},
				{"species_id": "bond_remnant", "hp": 42.0, "damage": 11.0, "weight": 0.30},
				{"species_id": "hushcoil", "hp": 34.0, "damage": 8.0, "weight": 0.20},
				{"species_id": "knellspine", "grade": "brood", "hp": 31.0, "damage": 8.0, "weight": 0.18}
			],
			"intro_text": "A breath. Then the weight returns.",
			"reward_pool": ["bond_remnant", "hushcoil", "knellspine"]
		},
		{
			"id": "final",
			"label": "FINAL CHORUS",
			"start_time": 107.0,
			"cycle_interval": 1.2,
			"fire_stagger": 0.44,
			"max_active_threats": 4,
			"population_target": 7,
			"authority_target": 3,
			"pressure_cap": 2.75,
			"enemy_pool": [
				{"species_id": "ashclaw", "grade": "alpha", "hp": 34.0, "damage": 10.0, "weight": 0.18},
				{"species_id": "gruvek", "grade": "alpha", "hp": 38.0, "damage": 11.0, "weight": 0.18},
				{"species_id": "gorefane", "grade": "alpha", "hp": 35.0, "damage": 10.0, "weight": 0.24},
				{"species_id": "thornback", "grade": "alpha", "hp": 39.0, "damage": 11.0, "weight": 0.24},
				{"species_id": "bond_remnant", "hp": 44.0, "damage": 11.0, "weight": 0.16}
			],
			"intro_text": "IT WILL NOT LET YOU LEAVE.",
			"reward_pool": []
		}
	],

	"pale_shelf": [
		# Attritional exposure: bond_reapers appear earlier and hit harder.
		# Spawn cadence is slower — the pressure is sustained individual lethality, not volume.
		# max_active_threats stays low so each enemy demands full attention.
		# Wide fire_stagger keeps each threat isolated: you face one projectile at a time.
		# Phase start_times: fraction × 202.8 s (newness.wav confirmed duration)
		{
			"id": "opening",
			"label": "NOTHING HIDES",
			"start_time": 0.0,
			"cycle_interval": 2.6,
			"fire_stagger": 0.65,
			"max_active_threats": 2,
			"population_target": 3,
			"authority_target": 1,
			"pressure_cap": 1.45,
			"enemy_pool": [
				{"species_id": "bond_remnant", "hp": 36.0, "damage": 10.0, "weight": 0.38},
				{"species_id": "pale_shelf_shardshroud_sentinel", "reward_species_id": "marrowward", "hp": 38.0, "damage": 10.0, "weight": 0.34},
				{"species_id": "pale_shelf_precision_stalker", "reward_species_id": "veilskin", "grade": "brood", "hp": 28.0, "damage": 9.0, "weight": 0.28}
			],
			"intro_text": "Nothing hides here. Neither do you.",
			"reward_pool": ["bond_remnant", "marrowward", "veilskin", "coldvein"]
		},
		{
			"id": "rising",
			"label": "THE SHELF WATCHES",
			"start_time": 51.0,
			"cycle_interval": 2.2,
			"fire_stagger": 0.62,
			"max_active_threats": 2,
			"population_target": 4,
			"authority_target": 2,
			"pressure_cap": 1.70,
			"enemy_pool": [
				{"species_id": "pale_shelf_precision_stalker", "reward_species_id": "veilskin", "hp": 30.0, "damage": 10.0, "weight": 0.32},
				{"species_id": "knellspine", "hp": 31.0, "damage": 10.0, "weight": 0.28},
				{"species_id": "hushcoil", "hp": 34.0, "damage": 10.0, "weight": 0.20},
				{"species_id": "pale_shelf_shardshroud_sentinel", "reward_species_id": "marrowward", "grade": "brood", "hp": 36.0, "damage": 9.0, "weight": 0.20},
				{"species_id": "coldvein", "grade": "brood", "hp": 29.0, "damage": 9.0, "weight": 0.18}
			],
			"intro_text": "The shelf offers no cover.",
			"reward_pool": ["veilskin", "hushcoil", "knellspine", "marrowward", "coldvein"]
		},
		{
			"id": "chorus",
			"label": "FULLY EXPOSED",
			"start_time": 85.0,
			"cycle_interval": 1.7,
			"fire_stagger": 0.55,
			"max_active_threats": 3,
			"population_target": 5,
			"authority_target": 2,
			"pressure_cap": 2.10,
			"enemy_pool": [
				{"species_id": "pale_shelf_precision_stalker", "reward_species_id": "veilskin", "grade": "alpha", "hp": 30.0, "damage": 10.0, "weight": 0.26},
				{"species_id": "pale_shelf_shardshroud_sentinel", "reward_species_id": "marrowward", "hp": 39.0, "damage": 11.0, "weight": 0.24},
				{"species_id": "hushcoil", "hp": 35.0, "damage": 10.0, "weight": 0.22},
				{"species_id": "knellspine", "hp": 33.0, "damage": 11.0, "weight": 0.18},
				{"species_id": "bond_remnant", "grade": "alpha", "hp": 40.0, "damage": 11.0, "weight": 0.10},
				{"species_id": "coldvein", "hp": 30.0, "damage": 10.0, "weight": 0.20}
			],
			"intro_text": "It has seen everything you have.",
			"reward_pool": ["veilskin", "marrowward", "hushcoil", "knellspine", "bond_remnant", "coldvein"]
		},
		{
			"id": "breakdown",
			"label": "COLD BREATH",
			"start_time": 126.0,
			"cycle_interval": 2.0,
			"fire_stagger": 0.62,
			"max_active_threats": 2,
			"population_target": 4,
			"authority_target": 2,
			"pressure_cap": 1.72,
			"enemy_pool": [
				{"species_id": "bond_remnant", "hp": 37.0, "damage": 10.0, "weight": 0.32},
				{"species_id": "knellspine", "hp": 32.0, "damage": 10.0, "weight": 0.24},
				{"species_id": "pale_shelf_shardshroud_sentinel", "reward_species_id": "marrowward", "hp": 38.0, "damage": 10.0, "weight": 0.24},
				{"species_id": "hushcoil", "grade": "brood", "hp": 32.0, "damage": 9.0, "weight": 0.20},
				{"species_id": "coldvein", "grade": "brood", "hp": 28.0, "damage": 9.0, "weight": 0.18}
			],
			"intro_text": "The cold does not forgive.",
			"reward_pool": ["bond_remnant", "knellspine", "marrowward", "hushcoil", "coldvein"]
		},
		{
			"id": "final",
			"label": "THE SHELF CLAIMS ALL",
			"start_time": 158.0,
			"cycle_interval": 1.4,
			"fire_stagger": 0.50,
			"max_active_threats": 3,
			"population_target": 6,
			"authority_target": 3,
			"pressure_cap": 2.40,
			"enemy_pool": [
				{"species_id": "pale_shelf_precision_stalker", "reward_species_id": "veilskin", "grade": "alpha", "hp": 31.0, "damage": 11.0, "weight": 0.26},
				{"species_id": "pale_shelf_shardshroud_sentinel", "reward_species_id": "marrowward", "grade": "alpha", "hp": 39.0, "damage": 11.0, "weight": 0.24},
				{"species_id": "hushcoil", "grade": "alpha", "hp": 35.0, "damage": 10.0, "weight": 0.22},
				{"species_id": "bond_remnant", "grade": "alpha", "hp": 40.0, "damage": 11.0, "weight": 0.16},
				{"species_id": "knellspine", "grade": "alpha", "hp": 33.0, "damage": 11.0, "weight": 0.12},
				{"species_id": "coldvein", "grade": "alpha", "hp": 31.0, "damage": 11.0, "weight": 0.16}
			],
			"intro_text": "EVERY BONE HERE BELONGS TO THE SHELF.",
			"reward_pool": []
		}
	],

	"drowned_cut": [
		# Resonant volume: weaker enemies, more alive simultaneously, faster spawn cadence.
		# Low HP per enemy means kills come quickly — support charge fills fast, bond fires often.
		# Pressure is volume-based, not individual lethality.
		# Tighter fire_stagger creates cluster pressure — projectiles arrive in quick succession.
		# Phase start_times: fraction × 323.0 s (Grind the Orbit.wav confirmed duration)
		{
			"id": "opening",
			"label": "THE WATER STIRS",
			"start_time": 0.0,
			"cycle_interval": 1.9,
			"fire_stagger": 0.50,
			"max_active_threats": 3,
			"population_target": 5,
			"authority_target": 2,
			"pressure_cap": 2.00,
			"enemy_pool": [
				{"species_id": "gruvek", "grade": "brood", "hp": 24.0, "damage": 6.0, "weight": 0.30},
				{"species_id": "knellspine", "grade": "brood", "hp": 22.0, "damage": 6.0, "weight": 0.40},
				{"species_id": "hushcoil", "grade": "brood", "hp": 23.0, "damage": 6.0, "weight": 0.30},
				{"species_id": "siltgrip", "grade": "brood", "hp": 21.0, "damage": 5.0, "weight": 0.22}
			],
			"intro_text": "Something older moved through here.",
			"reward_pool": ["gruvek", "knellspine", "hushcoil", "siltgrip"]
		},
		{
			"id": "rising",
			"label": "THE WEIGHT RETURNS",
			"start_time": 45.0,
			"cycle_interval": 1.6,
			"fire_stagger": 0.47,
			"max_active_threats": 3,
			"population_target": 6,
			"authority_target": 2,
			"pressure_cap": 2.15,
			"enemy_pool": [
				{"species_id": "ashclaw", "grade": "brood", "hp": 24.0, "damage": 7.0, "weight": 0.24},
				{"species_id": "knellspine", "hp": 24.0, "damage": 7.0, "weight": 0.30},
				{"species_id": "hushcoil", "hp": 25.0, "damage": 7.0, "weight": 0.24},
				{"species_id": "gorefane", "grade": "brood", "hp": 25.0, "damage": 7.0, "weight": 0.22},
				{"species_id": "siltgrip", "grade": "brood", "hp": 22.0, "damage": 6.0, "weight": 0.18}
			],
			"intro_text": "The current recognizes you.",
			"reward_pool": ["ashclaw", "knellspine", "hushcoil", "gorefane", "siltgrip"]
		},
		{
			"id": "chorus",
			"label": "DEEP RESONANCE",
			"start_time": 107.0,
			"cycle_interval": 1.3,
			"fire_stagger": 0.45,
			"max_active_threats": 3,
			"population_target": 7,
			"authority_target": 2,
			"pressure_cap": 2.35,
			"enemy_pool": [
				{"species_id": "thornback", "grade": "brood", "hp": 26.0, "damage": 7.0, "weight": 0.24},
				{"species_id": "gorefane", "hp": 27.0, "damage": 7.0, "weight": 0.24},
				{"species_id": "knellspine", "hp": 25.0, "damage": 7.0, "weight": 0.28},
				{"species_id": "gruvek", "hp": 28.0, "damage": 8.0, "weight": 0.24},
				{"species_id": "siltgrip", "hp": 24.0, "damage": 7.0, "weight": 0.20}
			],
			"intro_text": "The song is older than this place.",
			"reward_pool": ["thornback", "gorefane", "knellspine", "gruvek", "siltgrip"]
		},
		{
			"id": "breakdown",
			"label": "STILL WATER",
			"start_time": 181.0,
			"cycle_interval": 1.8,
			"fire_stagger": 0.50,
			"max_active_threats": 2,
			"population_target": 5,
			"authority_target": 2,
			"pressure_cap": 1.92,
			"enemy_pool": [
				{"species_id": "veilskin", "grade": "brood", "hp": 22.0, "damage": 6.0, "weight": 0.22},
				{"species_id": "hushcoil", "hp": 24.0, "damage": 6.0, "weight": 0.32},
				{"species_id": "knellspine", "hp": 24.0, "damage": 6.0, "weight": 0.28},
				{"species_id": "bond_remnant", "grade": "brood", "hp": 27.0, "damage": 7.0, "weight": 0.18},
				{"species_id": "siltgrip", "hp": 23.0, "damage": 6.0, "weight": 0.18}
			],
			"intro_text": "The water still remembers its weight.",
			"reward_pool": ["veilskin", "hushcoil", "knellspine", "bond_remnant", "siltgrip"]
		},
		{
			"id": "final",
			"label": "THE CUT OPENS",
			"start_time": 223.0,
			"cycle_interval": 0.9,
			"fire_stagger": 0.44,
			"max_active_threats": 4,
			"population_target": 8,
			"authority_target": 3,
			"pressure_cap": 2.80,
			"enemy_pool": [
				{"species_id": "gruvek", "grade": "alpha", "hp": 29.0, "damage": 8.0, "weight": 0.20},
				{"species_id": "gorefane", "grade": "alpha", "hp": 28.0, "damage": 8.0, "weight": 0.20},
				{"species_id": "knellspine", "grade": "alpha", "hp": 26.0, "damage": 8.0, "weight": 0.24},
				{"species_id": "hushcoil", "grade": "alpha", "hp": 27.0, "damage": 8.0, "weight": 0.24},
				{"species_id": "thornback", "grade": "alpha", "hp": 30.0, "damage": 9.0, "weight": 0.12},
				{"species_id": "siltgrip", "grade": "alpha", "hp": 26.0, "damage": 8.0, "weight": 0.14}
			],
			"intro_text": "IT WILL NOT LET YOU SURFACE.",
			"reward_pool": []
		}
	]
}


static func get_song_phases(region_id: String) -> Array:
	var source_phases: Array = SONG_PHASES_BY_REGION[region_id] if SONG_PHASES_BY_REGION.has(region_id) else SONG_PHASES_BY_REGION["feeding_hollow"]
	var built_phases: Array = []
	for phase in source_phases:
		var resolved_phase: Dictionary = phase.duplicate(true)
		var built_pool: Array = []
		for entry in resolved_phase.get("enemy_pool", []):
			built_pool.append(COMBAT_CONTENT.build_creature_enemy(entry))
		resolved_phase["enemy_pool"] = built_pool
		built_phases.append(resolved_phase)
	return built_phases
