extends RefCounted

# Per-region song phase definitions.
# CombatScene._start_song_run() selects from here based on GameState.active_region.id.
#
# Three identities:
#   feeding_hollow — predatory baseline; kill-tempo, flesh-forward, escalating bond_reaper density
#   pale_shelf     — attritional exposure; bond_reapers arrive early, enemies hit harder, fewer
#                    active threats but each is more punishing
#   drowned_cut    — resonant volume; weaker enemies, more alive at once, fast kills fuel support

const SONG_PHASES_BY_REGION: Dictionary = {

	"feeding_hollow": [
		# Collapse / hunt cadence: stagger narrows as the song accelerates.
		# Wide opening → tighter chorus → brief relief in breakdown → tightest final.
		{
			"id": "opening",
			"label": "THE SONG BEGINS",
			"start_time": 0.0,
			"cycle_interval": 2.3,
			"fire_stagger": 0.52,
			"max_active_threats": 2,
			"enemy_pool": [
				{"type": "dreg", "hp": 28.0, "damage": 7.0, "weight": 1.0}
			],
			"intro_text": "Something stirs above.",
			"reward_pool": ["ashclaw", "gruvek"]
		},
		{
			"id": "rising",
			"label": "RISING VERSE",
			"start_time": 45.0,
			"cycle_interval": 1.9,
			"fire_stagger": 0.50,
			"max_active_threats": 3,
			"enemy_pool": [
				{"type": "dreg", "hp": 32.0, "damage": 8.0, "weight": 0.65},
				{"type": "bond_reaper", "hp": 58.0, "damage": 13.0, "weight": 0.35}
			],
			"intro_text": "It learns your rhythm.",
			"reward_pool": ["bond_remnant", "veilskin"]
		},
		{
			"id": "chorus",
			"label": "FIRST CHORUS",
			"start_time": 105.0,
			"cycle_interval": 1.5,
			"fire_stagger": 0.46,
			"max_active_threats": 3,
			"enemy_pool": [
				{"type": "dreg", "hp": 34.0, "damage": 9.0, "weight": 0.50},
				{"type": "bond_reaper", "hp": 62.0, "damage": 14.0, "weight": 0.50}
			],
			"intro_text": "The song opens its mouth.",
			"reward_pool": []
		},
		{
			"id": "breakdown",
			"label": "BREAKDOWN",
			"start_time": 150.0,
			"cycle_interval": 1.8,
			"fire_stagger": 0.54,
			"max_active_threats": 2,
			"enemy_pool": [
				{"type": "dreg", "hp": 30.0, "damage": 8.0, "weight": 0.60},
				{"type": "bond_reaper", "hp": 58.0, "damage": 13.0, "weight": 0.40}
			],
			"intro_text": "A breath. Then the weight returns.",
			"reward_pool": []
		},
		{
			"id": "final",
			"label": "FINAL CHORUS",
			"start_time": 180.0,
			"cycle_interval": 1.2,
			"fire_stagger": 0.44,
			"max_active_threats": 4,
			"enemy_pool": [
				{"type": "dreg", "hp": 36.0, "damage": 10.0, "weight": 0.40},
				{"type": "bond_reaper", "hp": 66.0, "damage": 16.0, "weight": 0.60}
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
		{
			"id": "opening",
			"label": "NOTHING HIDES",
			"start_time": 0.0,
			"cycle_interval": 2.6,
			"fire_stagger": 0.65,
			"max_active_threats": 2,
			"enemy_pool": [
				{"type": "dreg", "hp": 32.0, "damage": 9.0, "weight": 0.70},
				{"type": "bond_reaper", "hp": 56.0, "damage": 14.0, "weight": 0.30}
			],
			"intro_text": "Nothing hides here. Neither do you.",
			"reward_pool": ["ashclaw", "gruvek"]
		},
		{
			"id": "rising",
			"label": "THE SHELF WATCHES",
			"start_time": 45.0,
			"cycle_interval": 2.2,
			"fire_stagger": 0.62,
			"max_active_threats": 2,
			"enemy_pool": [
				{"type": "dreg", "hp": 34.0, "damage": 10.0, "weight": 0.40},
				{"type": "bond_reaper", "hp": 62.0, "damage": 16.0, "weight": 0.60}
			],
			"intro_text": "The shelf offers no cover.",
			"reward_pool": ["bond_remnant", "veilskin"]
		},
		{
			"id": "chorus",
			"label": "FULLY EXPOSED",
			"start_time": 105.0,
			"cycle_interval": 1.7,
			"fire_stagger": 0.55,
			"max_active_threats": 3,
			"enemy_pool": [
				{"type": "dreg", "hp": 36.0, "damage": 10.0, "weight": 0.30},
				{"type": "bond_reaper", "hp": 66.0, "damage": 17.0, "weight": 0.70}
			],
			"intro_text": "It has seen everything you have.",
			"reward_pool": []
		},
		{
			"id": "breakdown",
			"label": "COLD BREATH",
			"start_time": 150.0,
			"cycle_interval": 2.0,
			"fire_stagger": 0.62,
			"max_active_threats": 2,
			"enemy_pool": [
				{"type": "dreg", "hp": 32.0, "damage": 9.0, "weight": 0.50},
				{"type": "bond_reaper", "hp": 60.0, "damage": 15.0, "weight": 0.50}
			],
			"intro_text": "The cold does not forgive.",
			"reward_pool": []
		},
		{
			"id": "final",
			"label": "THE SHELF CLAIMS ALL",
			"start_time": 180.0,
			"cycle_interval": 1.4,
			"fire_stagger": 0.50,
			"max_active_threats": 3,
			"enemy_pool": [
				{"type": "dreg", "hp": 38.0, "damage": 11.0, "weight": 0.30},
				{"type": "bond_reaper", "hp": 70.0, "damage": 18.0, "weight": 0.70}
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
		{
			"id": "opening",
			"label": "THE WATER STIRS",
			"start_time": 0.0,
			"cycle_interval": 1.9,
			"fire_stagger": 0.50,
			"max_active_threats": 3,
			"enemy_pool": [
				{"type": "dreg", "hp": 22.0, "damage": 6.0, "weight": 1.0}
			],
			"intro_text": "Something older moved through here.",
			"reward_pool": ["ashclaw", "gruvek"]
		},
		{
			"id": "rising",
			"label": "THE WEIGHT RETURNS",
			"start_time": 45.0,
			"cycle_interval": 1.6,
			"fire_stagger": 0.47,
			"max_active_threats": 3,
			"enemy_pool": [
				{"type": "dreg", "hp": 24.0, "damage": 7.0, "weight": 0.70},
				{"type": "bond_reaper", "hp": 52.0, "damage": 11.0, "weight": 0.30}
			],
			"intro_text": "The current recognizes you.",
			"reward_pool": ["bond_remnant", "veilskin"]
		},
		{
			"id": "chorus",
			"label": "DEEP RESONANCE",
			"start_time": 105.0,
			"cycle_interval": 1.3,
			"fire_stagger": 0.45,
			"max_active_threats": 3,
			"enemy_pool": [
				{"type": "dreg", "hp": 26.0, "damage": 7.0, "weight": 0.60},
				{"type": "bond_reaper", "hp": 54.0, "damage": 12.0, "weight": 0.40}
			],
			"intro_text": "The song is older than this place.",
			"reward_pool": []
		},
		{
			"id": "breakdown",
			"label": "STILL WATER",
			"start_time": 150.0,
			"cycle_interval": 1.8,
			"fire_stagger": 0.50,
			"max_active_threats": 2,
			"enemy_pool": [
				{"type": "dreg", "hp": 22.0, "damage": 6.0, "weight": 0.65},
				{"type": "bond_reaper", "hp": 50.0, "damage": 11.0, "weight": 0.35}
			],
			"intro_text": "The water still remembers its weight.",
			"reward_pool": []
		},
		{
			"id": "final",
			"label": "THE CUT OPENS",
			"start_time": 180.0,
			"cycle_interval": 0.9,
			"fire_stagger": 0.44,
			"max_active_threats": 4,
			"enemy_pool": [
				{"type": "dreg", "hp": 28.0, "damage": 8.0, "weight": 0.50},
				{"type": "bond_reaper", "hp": 58.0, "damage": 13.0, "weight": 0.50}
			],
			"intro_text": "IT WILL NOT LET YOU SURFACE.",
			"reward_pool": []
		}
	]
}


static func get_song_phases(region_id: String) -> Array:
	if SONG_PHASES_BY_REGION.has(region_id):
		return SONG_PHASES_BY_REGION[region_id]
	return SONG_PHASES_BY_REGION["feeding_hollow"]
