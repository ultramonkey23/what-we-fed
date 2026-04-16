extends RefCounted

# Total song duration before the boss triggers (seconds).
const SONG_DURATION: float = 240.0

# Five phases over 4 minutes. Each phase defines:
#   start_time      — when this phase begins (seconds elapsed)
#   cycle_interval  — seconds between fire cycles for this phase
#   max_active_threats — max enemies alive at once across all lanes
#   enemy_pool      — weighted enemy types that can spawn this phase
#   intro_text      — brief feedback label shown on phase entry
#   reward_pool     — creature species_ids offered when leaving this phase (empty = no reward)
const SONG_PHASES: Array = [
	{
		"id": "opening",
		"label": "THE SONG BEGINS",
		"start_time": 0.0,
		"cycle_interval": 2.3,
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
		"max_active_threats": 4,
		"enemy_pool": [
			{"type": "dreg", "hp": 36.0, "damage": 10.0, "weight": 0.40},
			{"type": "bond_reaper", "hp": 66.0, "damage": 16.0, "weight": 0.60}
		],
		"intro_text": "IT WILL NOT LET YOU LEAVE.",
		"reward_pool": []
	}
]
