extends RefCounted

# SongContent.gd - Legacy compatibility layer
# NOTE: For new development, use LevelStructure.gd instead
# This file provides backward compatibility for existing code

# Legacy constants - kept for backward compatibility
const SONG_DURATION: float = 120.0

# Legacy SONG_PHASES - simplified structure for backward compatibility
# This represents a basic 2-minute level structure
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
		"start_time": 40.0,
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
		"id": "final",
		"label": "FINAL CHORUS",
		"start_time": 80.0,
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

# Backward compatibility functions
# These functions provide a bridge to the new LevelStructure system
# Import LevelStructure when needed to avoid circular dependencies

static func get_current_level_phases(_level_number: int = 1) -> Array:
	# For now, return legacy phases
	# TODO: Integrate with LevelStructure.gd when called from proper context
	return SONG_PHASES.duplicate(true)

static func get_level_duration(level_number: int = 1) -> float:
	# Return 2 minutes for normal levels, 4 minutes for boss (level 10)
	if level_number >= 10:
		return 240.0
	return 120.0

static func get_reward_tier_for_level(level_number: int = 1) -> String:
	# Simple progression based on level number
	if level_number <= 2:
		return "common"
	elif level_number <= 4:
		return "uncommon"
	elif level_number <= 6:
		return "rare"
	elif level_number <= 8:
		return "epic"
	else:
		return "legendary"
