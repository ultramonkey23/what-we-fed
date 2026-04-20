extends RefCounted

# Level Structure - Defines the progression and timing of levels in a run
# Each run consists of 9 normal levels (2-minute song sections) + 1 boss level (full song)

# Run structure constants
const NORMAL_LEVELS_PER_RUN: int = 9
const BOSS_LEVELS_PER_RUN: int = 1
const TOTAL_LEVELS_PER_RUN: int = NORMAL_LEVELS_PER_RUN + BOSS_LEVELS_PER_RUN

# Level timing constants
const NORMAL_LEVEL_DURATION: float = 120.0  # 2 minutes in seconds
const BOSS_LEVEL_DURATION: float = 240.0   # 4 minutes for full boss song

# Level types
enum LevelType {
	NORMAL,
	BOSS
}

# Level progression structure
const LEVEL_PROGRESSION: Array[Dictionary] = [
	{"level": 1, "type": LevelType.NORMAL, "song_section": "intro"},
	{"level": 2, "type": LevelType.NORMAL, "song_section": "verse_1"},
	{"level": 3, "type": LevelType.NORMAL, "song_section": "pre_chorus_1"},
	{"level": 4, "type": LevelType.NORMAL, "song_section": "chorus_1"},
	{"level": 5, "type": LevelType.NORMAL, "song_section": "verse_2"},
	{"level": 6, "type": LevelType.NORMAL, "song_section": "pre_chorus_2"},
	{"level": 7, "type": LevelType.NORMAL, "song_section": "chorus_2"},
	{"level": 8, "type": LevelType.NORMAL, "song_section": "bridge"},
	{"level": 9, "type": LevelType.NORMAL, "song_section": "final_chorus"},
	{"level": 10, "type": LevelType.BOSS, "song_section": "full_song"}
]

# Song section configurations for normal levels
const SONG_SECTIONS: Dictionary = {
	"intro": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 0.8,
		"enemy_spawn_rate": 0.7,
		"reward_tier": "common",
		"phase_count": 2,
		"phases": [
			{
				"id": "intro_opening",
				"label": "INTRO BEGINS",
				"start_time": 0.0,
				"cycle_interval": 2.5,
				"max_active_threats": 2,
				"enemy_pool": [
					{"type": "dreg", "hp": 25.0, "damage": 6.0, "weight": 1.0}
				],
				"intro_text": "The song awakens."
			},
			{
				"id": "intro_build",
				"label": "INTRO BUILD",
				"start_time": 60.0,
				"cycle_interval": 2.2,
				"max_active_threats": 3,
				"enemy_pool": [
					{"type": "dreg", "hp": 28.0, "damage": 7.0, "weight": 0.8},
					{"type": "skitterer", "hp": 20.0, "damage": 5.0, "weight": 0.2}
				],
				"intro_text": "Rhythm builds."
			}
		]
	},
	"verse_1": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.0,
		"enemy_spawn_rate": 0.8,
		"reward_tier": "common",
		"phase_count": 2,
		"phases": [
			{
				"id": "verse1_opening",
				"label": "FIRST VERSE",
				"start_time": 0.0,
				"cycle_interval": 2.0,
				"max_active_threats": 3,
				"enemy_pool": [
					{"type": "dreg", "hp": 30.0, "damage": 8.0, "weight": 0.7},
					{"type": "skitterer", "hp": 22.0, "damage": 5.0, "weight": 0.3}
				],
				"intro_text": "The story begins."
			},
			{
				"id": "verse1_rising",
				"label": "VERSE RISING",
				"start_time": 60.0,
				"cycle_interval": 1.8,
				"max_active_threats": 3,
				"enemy_pool": [
					{"type": "dreg", "hp": 32.0, "damage": 8.0, "weight": 0.6},
					{"type": "skitterer", "hp": 22.0, "damage": 5.0, "weight": 0.2},
					{"type": "bond_reaper", "hp": 55.0, "damage": 12.0, "weight": 0.2}
				],
				"intro_text": "Complexity grows."
			}
		]
	},
	"pre_chorus_1": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.2,
		"enemy_spawn_rate": 0.9,
		"reward_tier": "uncommon",
		"phase_count": 2,
		"phases": [
			{
				"id": "prechorus1_build",
				"label": "PRE-CHORUS BUILD",
				"start_time": 0.0,
				"cycle_interval": 1.7,
				"max_active_threats": 3,
				"enemy_pool": [
					{"type": "dreg", "hp": 32.0, "damage": 9.0, "weight": 0.5},
					{"type": "bond_reaper", "hp": 58.0, "damage": 13.0, "weight": 0.4},
					{"type": "spitter", "hp": 28.0, "damage": 6.0, "weight": 0.1}
				],
				"intro_text": "Tension rises."
			},
			{
				"id": "prechorus1_peak",
				"label": "PRE-CHORUS PEAK",
				"start_time": 60.0,
				"cycle_interval": 1.5,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "dreg", "hp": 34.0, "damage": 9.0, "weight": 0.4},
					{"type": "bond_reaper", "hp": 60.0, "damage": 14.0, "weight": 0.5},
					{"type": "spitter", "hp": 30.0, "damage": 6.0, "weight": 0.1}
				],
				"intro_text": "The peak approaches."
			}
		]
	},
	"chorus_1": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.4,
		"enemy_spawn_rate": 1.0,
		"reward_tier": "uncommon",
		"phase_count": 2,
		"phases": [
			{
				"id": "chorus1_explosion",
				"label": "FIRST CHORUS",
				"start_time": 0.0,
				"cycle_interval": 1.4,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "dreg", "hp": 35.0, "damage": 10.0, "weight": 0.3},
					{"type": "bond_reaper", "hp": 62.0, "damage": 14.0, "weight": 0.6},
					{"type": "spitter", "hp": 30.0, "damage": 6.0, "weight": 0.1}
				],
				"intro_text": "EXPLOSION!"
			},
			{
				"id": "chorus1_sustain",
				"label": "CHORUS SUSTAIN",
				"start_time": 60.0,
				"cycle_interval": 1.3,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 64.0, "damage": 15.0, "weight": 0.7},
					{"type": "spitter", "hp": 32.0, "damage": 7.0, "weight": 0.2},
					{"type": "phantom", "hp": 33.0, "damage": 9.0, "weight": 0.1}
				],
				"intro_text": "The song holds its power."
			}
		]
	},
	"verse_2": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.3,
		"enemy_spawn_rate": 0.9,
		"reward_tier": "uncommon",
		"phase_count": 2,
		"phases": [
			{
				"id": "verse2_return",
				"label": "SECOND VERSE",
				"start_time": 0.0,
				"cycle_interval": 1.6,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "dreg", "hp": 36.0, "damage": 11.0, "weight": 0.3},
					{"type": "bond_reaper", "hp": 64.0, "damage": 15.0, "weight": 0.5},
					{"type": "phantom", "hp": 35.0, "damage": 9.0, "weight": 0.2}
				],
				"intro_text": "The story deepens."
			},
			{
				"id": "verse2_complex",
				"label": "VERSE COMPLEXITY",
				"start_time": 60.0,
				"cycle_interval": 1.5,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 66.0, "damage": 15.0, "weight": 0.5},
					{"type": "phantom", "hp": 35.0, "damage": 9.0, "weight": 0.3},
					{"type": "brute", "hp": 80.0, "damage": 11.0, "weight": 0.2}
				],
				"intro_text": "Layers intertwine."
			}
		]
	},
	"pre_chorus_2": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.5,
		"enemy_spawn_rate": 1.0,
		"reward_tier": "rare",
		"phase_count": 2,
		"phases": [
			{
				"id": "prechorus2_tension",
				"label": "PRE-CHORUS TENSION",
				"start_time": 0.0,
				"cycle_interval": 1.4,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 68.0, "damage": 16.0, "weight": 0.5},
					{"type": "phantom", "hp": 37.0, "damage": 10.0, "weight": 0.3},
					{"type": "brute", "hp": 82.0, "damage": 12.0, "weight": 0.2}
				],
				"intro_text": "Higher stakes."
			},
			{
				"id": "prechorus2_break",
				"label": "PRE-CHORUS BREAK",
				"start_time": 60.0,
				"cycle_interval": 1.3,
				"max_active_threats": 5,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 70.0, "damage": 17.0, "weight": 0.4},
					{"type": "phantom", "hp": 37.0, "damage": 10.0, "weight": 0.3},
					{"type": "brute", "hp": 85.0, "damage": 12.0, "weight": 0.2},
					{"type": "warden", "hp": 115.0, "damage": 13.0, "weight": 0.1}
				],
				"intro_text": "The break before the storm."
			}
		]
	},
	"chorus_2": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.7,
		"enemy_spawn_rate": 1.1,
		"reward_tier": "rare",
		"phase_count": 2,
		"phases": [
			{
				"id": "chorus2_magnitude",
				"label": "SECOND CHORUS",
				"start_time": 0.0,
				"cycle_interval": 1.2,
				"max_active_threats": 5,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 72.0, "damage": 18.0, "weight": 0.4},
					{"type": "phantom", "hp": 39.0, "damage": 11.0, "weight": 0.3},
					{"type": "brute", "hp": 88.0, "damage": 13.0, "weight": 0.2},
					{"type": "warden", "hp": 118.0, "damage": 14.0, "weight": 0.1}
				],
				"intro_text": "GREATER EXPLOSION!"
			},
			{
				"id": "chorus2_climax",
				"label": "CHORUS CLIMAX",
				"start_time": 60.0,
				"cycle_interval": 1.1,
				"max_active_threats": 5,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 74.0, "damage": 19.0, "weight": 0.3},
					{"type": "phantom", "hp": 39.0, "damage": 11.0, "weight": 0.3},
					{"type": "brute", "hp": 90.0, "damage": 13.0, "weight": 0.2},
					{"type": "warden", "hp": 120.0, "damage": 14.0, "weight": 0.2}
				],
				"intro_text": "The peak intensifies."
			}
		]
	},
	"bridge": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.6,
		"enemy_spawn_rate": 0.8,
		"reward_tier": "rare",
		"phase_count": 2,
		"phases": [
			{
				"id": "bridge_calm",
				"label": "BRIDGE CALM",
				"start_time": 0.0,
				"cycle_interval": 1.8,
				"max_active_threats": 3,
				"enemy_pool": [
					{"type": "phantom", "hp": 41.0, "damage": 12.0, "weight": 0.5},
					{"type": "warden", "hp": 122.0, "damage": 15.0, "weight": 0.3},
					{"type": "void_stalker", "hp": 46.0, "damage": 15.0, "weight": 0.2}
				],
				"intro_text": "A moment of reflection."
			},
			{
				"id": "bridge_build",
				"label": "BRIDGE BUILD",
				"start_time": 60.0,
				"cycle_interval": 1.4,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "phantom", "hp": 41.0, "damage": 12.0, "weight": 0.4},
					{"type": "warden", "hp": 122.0, "damage": 15.0, "weight": 0.3},
					{"type": "void_stalker", "hp": 48.0, "damage": 16.0, "weight": 0.3}
				],
				"intro_text": "Building toward the end."
			}
		]
	},
	"final_chorus": {
		"duration": NORMAL_LEVEL_DURATION,
		"difficulty_multiplier": 1.8,
		"enemy_spawn_rate": 1.2,
		"reward_tier": "epic",
		"phase_count": 2,
		"phases": [
			{
				"id": "final_chorus_opening",
				"label": "FINAL CHORUS",
				"start_time": 0.0,
				"cycle_interval": 1.0,
				"max_active_threats": 5,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 76.0, "damage": 20.0, "weight": 0.3},
					{"type": "brute", "hp": 92.0, "damage": 14.0, "weight": 0.2},
					{"type": "warden", "hp": 125.0, "damage": 16.0, "weight": 0.2},
					{"type": "void_stalker", "hp": 50.0, "damage": 17.0, "weight": 0.3}
				],
				"intro_text": "THE FINAL EXPLOSION!"
			},
			{
				"id": "final_chorus_crescendo",
				"label": "CRESCENDO",
				"start_time": 60.0,
				"cycle_interval": 0.9,
				"max_active_threats": 6,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 78.0, "damage": 21.0, "weight": 0.3},
					{"type": "brute", "hp": 95.0, "damage": 15.0, "weight": 0.2},
					{"type": "warden", "hp": 128.0, "damage": 16.0, "weight": 0.2},
					{"type": "void_stalker", "hp": 52.0, "damage": 18.0, "weight": 0.3}
				],
				"intro_text": "THE SONG REACHES ITS PEAK!"
			}
		]
	},
	"full_song": {
		"duration": BOSS_LEVEL_DURATION,
		"difficulty_multiplier": 2.0,
		"enemy_spawn_rate": 1.5,
		"reward_tier": "legendary",
		"phase_count": 5,
		"phases": [
			{
				"id": "boss_intro",
				"label": "BOSS INTRO",
				"start_time": 0.0,
				"cycle_interval": 2.0,
				"max_active_threats": 4,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 80.0, "damage": 22.0, "weight": 0.4},
					{"type": "brute", "hp": 100.0, "damage": 16.0, "weight": 0.3},
					{"type": "warden", "hp": 130.0, "damage": 18.0, "weight": 0.2},
					{"type": "void_stalker", "hp": 55.0, "damage": 19.0, "weight": 0.1}
				],
				"intro_text": "The boss awakens."
			},
			{
				"id": "boss_rising",
				"label": "BOSS RISING",
				"start_time": 48.0,
				"cycle_interval": 1.6,
				"max_active_threats": 5,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 82.0, "damage": 23.0, "weight": 0.3},
					{"type": "brute", "hp": 105.0, "damage": 17.0, "weight": 0.3},
					{"type": "warden", "hp": 135.0, "damage": 19.0, "weight": 0.2},
					{"type": "void_stalker", "hp": 58.0, "damage": 20.0, "weight": 0.2}
				],
				"intro_text": "Power builds."
			},
			{
				"id": "boss_chorus",
				"label": "BOSS CHORUS",
				"start_time": 96.0,
				"cycle_interval": 1.3,
				"max_active_threats": 6,
				"enemy_pool": [
					{"type": "bond_reaper", "hp": 85.0, "damage": 24.0, "weight": 0.3},
					{"type": "brute", "hp": 110.0, "damage": 18.0, "weight": 0.2},
					{"type": "warden", "hp": 140.0, "damage": 20.0, "weight": 0.2},
					{"type": "void_stalker", "hp": 60.0, "damage": 21.0, "weight": 0.3}
				],
				"intro_text": "FULL POWER!"
			},
			{
				"id": "boss_breakdown",
				"label": "BOSS BREAKDOWN",
				"start_time": 144.0,
				"cycle_interval": 1.5,
				"max_active_threats": 5,
				"enemy_pool": [
					{"type": "brute", "hp": 115.0, "damage": 19.0, "weight": 0.3},
					{"type": "warden", "hp": 145.0, "damage": 21.0, "weight": 0.3},
					{"type": "void_stalker", "hp": 62.0, "damage": 22.0, "weight": 0.4}
				],
				"intro_text": "The boss adapts."
			},
			{
				"id": "boss_final",
				"label": "BOSS FINAL",
				"start_time": 192.0,
				"cycle_interval": 1.0,
				"max_active_threats": 7,
				"enemy_pool": [
					{"type": "brute", "hp": 120.0, "damage": 20.0, "weight": 0.2},
					{"type": "warden", "hp": 150.0, "damage": 22.0, "weight": 0.2},
					{"type": "void_stalker", "hp": 65.0, "damage": 23.0, "weight": 0.3},
					{"type": "sovereign", "hp": 160.0, "damage": 25.0, "weight": 0.3}
				],
				"intro_text": "FINAL ASSAULT!"
			}
		]
	}
}

# Reward tiers and their contents
const REWARD_TIERS: Dictionary = {
	"common": {
		"creature_choices": ["ashclaw", "gruvek"],
		"item_choices": ["basic_potion", "minor_upgrade"],
		"choice_count": 2
	},
	"uncommon": {
		"creature_choices": ["bond_remnant", "veilskin"],
		"item_choices": ["potion", "upgrade"],
		"choice_count": 2
	},
	"rare": {
		"creature_choices": ["ashclaw", "gruvek", "bond_remnant", "veilskin"],
		"item_choices": ["major_potion", "major_upgrade"],
		"choice_count": 3
	},
	"epic": {
		"creature_choices": ["ashclaw", "gruvek", "bond_remnant", "veilskin"],
		"item_choices": ["legendary_potion", "legendary_upgrade"],
		"choice_count": 3
	},
	"legendary": {
		"creature_choices": ["ashclaw", "gruvek", "bond_remnant", "veilskin"],
		"item_choices": ["mythic_potion", "mythic_upgrade"],
		"choice_count": 4
	}
}

# Utility functions
static func get_level_info(level_number: int) -> Dictionary:
	if level_number < 1 or level_number > LEVEL_PROGRESSION.size():
		return {}
	return LEVEL_PROGRESSION[level_number - 1].duplicate(true)

static func get_song_section(section_id: String) -> Dictionary:
	if not SONG_SECTIONS.has(section_id):
		return {}
	return SONG_SECTIONS[section_id].duplicate(true)

static func get_reward_tier_info(tier: String) -> Dictionary:
	if not REWARD_TIERS.has(tier):
		return {}
	return REWARD_TIERS[tier].duplicate(true)

static func is_boss_level(level_number: int) -> bool:
	var level_info = get_level_info(level_number)
	return level_info.get("type", LevelType.NORMAL) == LevelType.BOSS

static func get_level_duration(level_number: int) -> float:
	if is_boss_level(level_number):
		return BOSS_LEVEL_DURATION
	return NORMAL_LEVEL_DURATION
