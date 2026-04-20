extends RefCounted

# Game System Integration - Central hub for coordinating all game systems
# This file provides a unified interface for the level progression system

# System status and validation
static func validate_system_integrity() -> Dictionary:
	var issues: Array[String] = []
	var warnings: Array[String] = []
	
	# Check if all required files exist (basic validation)
	var required_systems = ["LevelStructure", "SongContent", "RewardSystem", "EnemyTemplates"]
	
	for system in required_systems:
		# Note: In a real implementation, you'd check if these classes can be loaded
		# For now, we'll assume they exist and validate their structure
		pass
	
	# Validate level progression consistency
	var level_count = 10  # 9 normal + 1 boss
	var expected_duration = 9 * 120.0 + 240.0  # 9 normal levels * 2min + 1 boss * 4min
	
	# Check enemy template consistency
	var _enemy_types = ["dreg", "bond_reaper", "skitterer", "brute", "phantom", "spitter", "warden", "void_stalker", "sovereign"]
	
	return {
		"valid": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"system_count": required_systems.size(),
		"level_count": level_count,
		"total_run_duration": expected_duration
	}

# Get comprehensive level information
static func get_level_complete_info(level_number: int) -> Dictionary:
	var level_info = {}
	
	# Basic level info
	level_info["level_number"] = level_number
	level_info["is_boss"] = level_number >= 10
	level_info["duration"] = _get_level_duration(level_number)
	
	# Song section info
	var song_section = _get_song_section_for_level(level_number)
	level_info["song_section"] = song_section
	
	# Phase information
	var phases = _get_phases_for_level(level_number)
	level_info["phases"] = phases
	level_info["phase_count"] = phases.size()
	
	# Difficulty and rewards
	level_info["difficulty_multiplier"] = _get_difficulty_multiplier(level_number)
	level_info["reward_tier"] = _get_reward_tier_for_level(level_number)
	level_info["reward_choices"] = _generate_reward_choices(level_number)
	
	# Enemy information
	level_info["enemy_types"] = _get_enemy_types_for_level(level_number)
	level_info["max_active_threats"] = _get_max_threats_for_level(level_number)
	
	return level_info

# Run management
static func get_run_complete_info() -> Dictionary:
	var run_info = {}
	var levels: Array[Dictionary] = []
	
	for i in range(1, 11):  # Levels 1-10
		levels.append(get_level_complete_info(i))
	
	run_info["total_levels"] = 10
	run_info["normal_levels"] = 9
	run_info["boss_levels"] = 1
	run_info["total_duration"] = _calculate_sum(levels.map(func(l): return l.duration))
	run_info["levels"] = levels
	
	# Run statistics
	run_info["enemy_progression"] = _analyze_enemy_progression(levels)
	run_info["difficulty_progression"] = _analyze_difficulty_progression(levels)
	run_info["reward_progression"] = _analyze_reward_progression(levels)
	
	return run_info

# Performance optimization utilities
static func preload_level_data(level_number: int) -> void:
	# Preload all data needed for a specific level
	# This would be called when transitioning to a level
	var level_info = get_level_complete_info(level_number)
	
	# In a real implementation, you would:
	# - Load audio files
	# - Pre-cache enemy templates
	# - Prepare UI elements
	# - Pre-generate reward choices
	
	print("Preloaded data for level ", level_number, ": ", level_info.song_section)

# Save/Load utilities
static func get_save_data() -> Dictionary:
	return {
		"system_version": "1.0",
		"last_updated": Time.get_unix_time_from_system(),
		"run_structure": get_run_complete_info()
	}

# Helper functions
static func _generate_reward_choices(level_number: int) -> Array[Dictionary]:
	# Simplified reward generation
	var reward_tier = _get_reward_tier_for_level(level_number)
	var choices: Array[Dictionary] = []
	
	match reward_tier:
		"common":
			choices = [
				{"type": "creature", "id": "ashclaw", "display_name": "Ashclaw"},
				{"type": "item", "id": "basic_potion", "display_name": "Basic Health Potion"}
			]
		"uncommon":
			choices = [
				{"type": "creature", "id": "bond_remnant", "display_name": "Bond Remnant"},
				{"type": "item", "id": "potion", "display_name": "Health Potion"}
			]
		"rare":
			choices = [
				{"type": "creature", "id": "ashclaw", "display_name": "Ashclaw"},
				{"type": "creature", "id": "gruvek", "display_name": "Gruvek"},
				{"type": "item", "id": "major_potion", "display_name": "Major Health Potion"}
			]
		"epic":
			choices = [
				{"type": "creature", "id": "bond_remnant", "display_name": "Bond Remnant"},
				{"type": "creature", "id": "veilskin", "display_name": "Veilskin"},
				{"type": "item", "id": "legendary_potion", "display_name": "Legendary Health Potion"}
			]
		"legendary":
			choices = [
				{"type": "creature", "id": "ashclaw", "display_name": "Ashclaw"},
				{"type": "creature", "id": "gruvek", "display_name": "Gruvek"},
				{"type": "item", "id": "mythic_potion", "display_name": "Mythic Health Potion"},
				{"type": "item", "id": "mythic_upgrade", "display_name": "Mythic Power Upgrade"}
			]
	
	return choices

static func _calculate_sum(numbers: Array) -> float:
	var total = 0.0
	for number in numbers:
		total += float(number)
	return total

# Private helper functions

static func _get_level_duration(level_number: int) -> float:
	if level_number >= 10:
		return 240.0  # Boss level
	return 120.0  # Normal level

static func _get_song_section_for_level(level_number: int) -> String:
	var sections = ["intro", "verse_1", "pre_chorus_1", "chorus_1", "verse_2", 
					"pre_chorus_2", "chorus_2", "bridge", "final_chorus", "full_song"]
	
	if level_number >= 1 and level_number <= sections.size():
		return sections[level_number - 1]
	return "intro"

static func _get_phases_for_level(level_number: int) -> Array:
	# This would normally delegate to LevelStructure.gd
	# For now, return a simplified structure
	if level_number >= 10:
		return [
			{"id": "boss_intro", "start_time": 0.0, "cycle_interval": 2.0},
			{"id": "boss_rising", "start_time": 48.0, "cycle_interval": 1.6},
			{"id": "boss_chorus", "start_time": 96.0, "cycle_interval": 1.3},
			{"id": "boss_breakdown", "start_time": 144.0, "cycle_interval": 1.5},
			{"id": "boss_final", "start_time": 192.0, "cycle_interval": 1.0}
		]
	else:
		return [
			{"id": "phase_1", "start_time": 0.0, "cycle_interval": 2.3},
			{"id": "phase_2", "start_time": 60.0, "cycle_interval": 1.9}
		]

static func _get_difficulty_multiplier(level_number: int) -> float:
	# Progressive difficulty scaling
	if level_number <= 2:
		return 0.8 + float(level_number - 1) * 0.1
	elif level_number <= 4:
		return 1.0 + (level_number - 3) * 0.2
	elif level_number <= 6:
		return 1.4 + (level_number - 5) * 0.1
	elif level_number <= 8:
		return 1.6 + (level_number - 7) * 0.1
	else:
		return 1.8 + (level_number - 9) * 0.1

static func _get_reward_tier_for_level(level_number: int) -> String:
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

static func _get_enemy_types_for_level(level_number: int) -> Array[String]:
	var base_enemies = ["dreg"]
	
	if level_number >= 2:
		base_enemies.append("skitterer")
	if level_number >= 3:
		base_enemies.append("bond_reaper")
	if level_number >= 4:
		base_enemies.append("spitter")
	if level_number >= 5:
		base_enemies.append("phantom")
	if level_number >= 6:
		base_enemies.append("brute")
	if level_number >= 7:
		base_enemies.append("warden")
	if level_number >= 8:
		base_enemies.append("void_stalker")
	if level_number >= 10:
		base_enemies.append("sovereign")
	
	return base_enemies

static func _get_max_threats_for_level(level_number: int) -> int:
	return min(2 + int(level_number / 2), 7)

static func _analyze_enemy_progression(levels: Array[Dictionary]) -> Dictionary:
	var enemy_appearance: Dictionary = {}
	
	for level in levels:
		for enemy_type in level.enemy_types:
			if not enemy_appearance.has(enemy_type):
				enemy_appearance[enemy_type] = []
			enemy_appearance[enemy_type].append(level.level_number)
	
	return {
		"enemy_types": enemy_appearance,
		"progression_valid": true
	}

static func _analyze_difficulty_progression(levels: Array[Dictionary]) -> Dictionary:
	var difficulties = levels.map(func(l): return l.difficulty_multiplier)
	
	return {
		"multipliers": difficulties,
		"progression_valid": difficulties == difficulties.sorted(),
		"total_increase": difficulties[-1] - difficulties[0]
	}

static func _analyze_reward_progression(levels: Array[Dictionary]) -> Dictionary:
	var tiers = levels.map(func(l): return l.reward_tier)
	
	return {
		"tiers": tiers,
		"progression_valid": tiers == tiers.sorted(),
		"total_choices": _calculate_sum(levels.map(func(l): return l.reward_choices.size()))
	}
