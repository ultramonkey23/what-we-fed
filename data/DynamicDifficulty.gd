extends RefCounted

# Dynamic Difficulty System - Enhances the existing level structure with adaptive difficulty
# This system works alongside LevelStructure.gd without modifying it

# Difficulty adjustment factors
const DIFFICULTY_FACTORS: Dictionary = {
	"player_performance": {
		"excellent": 1.3,    # Player doing very well
		"good": 1.1,         # Player doing well
		"normal": 1.0,       # Baseline difficulty
		"struggling": 0.9,   # Player having difficulty
		"failing": 0.8       # Player really struggling
	},
	"run_modifier": {
		"none": 1.0,
		"easy": 0.85,
		"hard": 1.15,
		"extreme": 1.3
	},
	"region_bonus": {
		"feeding_hollow": 1.0,
		"pale_shelf": 1.05,
		"drowned_cut": 1.1,
		"echoing_chasm": 1.15,
		"crystalline_spire": 1.2,
		"whispering_marsh": 1.1,
		"iron_boneyard": 1.15,
		"sunken_library": 1.05
	}
}

# Performance tracking
static func create_performance_tracker() -> Dictionary:
	return {
		"damage_taken": 0.0,
		"enemies_defeated": 0,
		"accuracy": 1.0,
		"time_survived": 0.0,
		"powers_used": 0,
		"perfect_phases": 0,
		"total_phases": 0
	}

# Calculate performance rating based on tracked metrics
static func calculate_performance_rating(tracker: Dictionary) -> String:
	var score = 0.0
	
	# Damage taken (lower is better)
	var damage_score = max(0.0, 100.0 - tracker.damage_taken)
	score += damage_score * 0.3
	
	# Enemies defeated (higher is better)
	var defeat_score = float(tracker.enemies_defeated) * 10.0
	score += defeat_score * 0.25
	
	# Accuracy (higher is better)
	score += tracker.accuracy * 25.0
	
	# Perfect phases (higher is better)
	if tracker.total_phases > 0:
		var perfect_ratio = float(tracker.perfect_phases) / float(tracker.total_phases)
		score += perfect_ratio * 20.0
	
	# Time survived (higher is better)
	score += (tracker.time_survived / 120.0) * 10.0  # Normalized to 2 minutes
	
	# Convert score to rating
	if score >= 85:
		return "excellent"
	elif score >= 70:
		return "good"
	elif score >= 50:
		return "normal"
	elif score >= 30:
		return "struggling"
	else:
		return "failing"

# Apply dynamic difficulty to level data
static func apply_dynamic_difficulty(
	base_level_data: Dictionary, 
	performance_rating: String,
	run_modifier: String = "none",
	region_id: String = "feeding_hollow"
) -> Dictionary:
	var modified_data = base_level_data.duplicate(true)
	
	# Get difficulty multipliers
	var perf_multiplier = DIFFICULTY_FACTORS["player_performance"].get(performance_rating, 1.0)
	var run_multiplier = DIFFICULTY_FACTORS["run_modifier"].get(run_modifier, 1.0)
	var region_multiplier = DIFFICULTY_FACTORS["region_bonus"].get(region_id, 1.0)
	
	# Combine multipliers
	var total_multiplier = perf_multiplier * run_multiplier * region_multiplier
	
	# Apply to enemy stats
	if modified_data.has("phases"):
		for phase in modified_data["phases"]:
			if phase.has("enemy_pool"):
				for enemy in phase["enemy_pool"]:
					enemy["hp"] *= total_multiplier
					enemy["damage"] *= total_multiplier
			
			# Adjust spawn rate
			if phase.has("cycle_interval"):
				phase["cycle_interval"] = phase["cycle_interval"] / (1.0 + (total_multiplier - 1.0) * 0.3)
			
			# Adjust threat count
			if phase.has("max_active_threats"):
				var threat_increase = int((total_multiplier - 1.0) * 2.0)
				phase["max_active_threats"] = max(1, phase["max_active_threats"] + threat_increase)
	
	# Store difficulty info for debugging/UI
	modified_data["dynamic_difficulty"] = {
		"performance_rating": performance_rating,
		"run_modifier": run_modifier,
		"region_id": region_id,
		"total_multiplier": total_multiplier,
		"applied_changes": ["enemy_stats", "spawn_rate", "threat_count"]
	}
	
	return modified_data

# Adaptive reward system based on performance
static func get_adaptive_reward_choices(
	base_rewards: Array[Dictionary],
	performance_rating: String,
	consistency_bonus: float = 0.0
) -> Array[Dictionary]:
	var adapted_rewards = base_rewards.duplicate(true)
	
	# Add bonus rewards for excellent performance
	if performance_rating == "excellent":
		var bonus_reward = {
			"type": "bonus",
			"id": "performance_bonus",
			"display_name": "Performance Bonus",
			"description": "Extra reward for excellent performance!",
			"rarity": "legendary"
		}
		adapted_rewards.append(bonus_reward)
	
	# Improve reward quality for consistent good performance
	# Omen (Luck) multiplies the consistency bonus.
	var omen_mult: float = 1.0
	# Since DynamicDifficulty is a static RefCounted, we must assume GameState is an autoload or passed in.
	# Standard practice in this repo seems to be using GameState directly if it's an autoload.
	if Engine.has_singleton("GameState") or true: # Fallback to global if needed
		omen_mult = GameState.get("stat_luck") if "stat_luck" in GameState else 1.0

	if performance_rating in ["excellent", "good"] and consistency_bonus * omen_mult > 0.5:
		var effective_bonus: float = consistency_bonus * omen_mult
		for reward in adapted_rewards:
			if reward.has("rarity"):
				# Upgrade rarity if possible
				match reward["rarity"]:
					"common":
						if randf() < effective_bonus:
							reward["rarity"] = "uncommon"
					"uncommon":
						if randf() < effective_bonus * 0.7:
							reward["rarity"] = "rare"
					"rare":
						if randf() < effective_bonus * 0.4:
							reward["rarity"] = "epic"
	
	return adapted_rewards

# Difficulty scaling suggestions for next run
static func suggest_difficulty_adjustment(performance_history: Array[String]) -> String:
	if performance_history.size() < 3:
		return "none"
	
	var recent_ratings = performance_history.slice(-3)  # Last 3 performances
	var excellent_count = 0
	var struggling_count = 0
	
	for rating in recent_ratings:
		if rating == "excellent":
			excellent_count += 1
		elif rating in ["struggling", "failing"]:
			struggling_count += 1
	
	if excellent_count >= 2:
		return "hard"  # Player is ready for more challenge
	elif struggling_count >= 2:
		return "easy"  # Player needs some help
	else:
		return "none"

# Region-specific difficulty patterns
static func get_region_difficulty_pattern(region_id: String) -> Dictionary:
	var patterns = {
		"feeding_hollow": {
			"description": "Balanced difficulty with familiar enemies",
			"enemy_focus": ["dreg", "bond_reaper"],
			"special_modifier": "none"
		},
		"pale_shelf": {
			"description": "Exposed enemies with lower health but higher accuracy",
			"enemy_focus": ["dreg", "skitterer"],
			"special_modifier": "exposed"
		},
		"drowned_cut": {
			"description": "Resonant enemies with coordinated attacks",
			"enemy_focus": ["bond_reaper", "phantom"],
			"special_modifier": "coordinated"
		},
		"echoing_chasm": {
			"description": "Amplified attacks with increased spawn rates",
			"enemy_focus": ["spitter", "brute"],
			"special_modifier": "amplified"
		},
		"crystalline_spire": {
			"description": "Refracted damage patterns with unpredictable timing",
			"enemy_focus": ["phantom", "warden"],
			"special_modifier": "refracted"
		},
		"whispering_marsh": {
			"description": "Haunted enemies with stealth abilities",
			"enemy_focus": ["void_stalker", "phantom"],
			"special_modifier": "haunted"
		},
		"iron_boneyard": {
			"description": "Forged enemies with increased defense",
			"enemy_focus": ["brute", "warden"],
			"special_modifier": "fortified"
		},
		"sunken_library": {
			"description": "Dissolved enemies with area effects",
			"enemy_focus": ["spitter", "void_stalker"],
			"special_modifier": "area_damage"
		}
	}
	
	return patterns.get(region_id, patterns["feeding_hollow"])

# Apply region-specific modifiers to level data
static func apply_region_modifiers(level_data: Dictionary, region_id: String) -> Dictionary:
	var modified_data = level_data.duplicate(true)
	var pattern = get_region_difficulty_pattern(region_id)
	var modifier = pattern["special_modifier"]
	
	match modifier:
		"exposed":
			# Lower enemy health, higher accuracy
			if modified_data.has("phases"):
				for phase in modified_data["phases"]:
					if phase.has("enemy_pool"):
						for enemy in phase["enemy_pool"]:
							enemy["hp"] *= 0.85
							enemy["damage"] *= 1.1
		"coordinated":
			# More synchronized attacks
			if modified_data.has("phases"):
				for phase in modified_data["phases"]:
					if phase.has("cycle_interval"):
						phase["cycle_interval"] *= 0.9
		"amplified":
			# Higher damage, faster attacks
			if modified_data.has("phases"):
				for phase in modified_data["phases"]:
					if phase.has("enemy_pool"):
						for enemy in phase["enemy_pool"]:
							enemy["damage"] *= 1.2
					if phase.has("cycle_interval"):
						phase["cycle_interval"] *= 0.85
		"refracted":
			# Unpredictable timing
			if modified_data.has("phases"):
				for phase in modified_data["phases"]:
					if phase.has("cycle_interval"):
						var variation = phase["cycle_interval"] * 0.2
						phase["cycle_interval"] += randf_range(-variation, variation)
		"haunted":
			# Stealth elements
			if modified_data.has("phases"):
				for phase in modified_data["phases"]:
					if phase.has("enemy_pool"):
						for enemy in phase["enemy_pool"]:
							enemy["stealth_chance"] = 0.3
		"fortified":
			# Higher defense
			if modified_data.has("phases"):
				for phase in modified_data["phases"]:
					if phase.has("enemy_pool"):
						for enemy in phase["enemy_pool"]:
							enemy["defense"] = enemy.get("defense", 0) + 2.0
		"area_damage":
			# More area effect enemies
			if modified_data.has("phases"):
				for phase in modified_data["phases"]:
					if phase.has("enemy_pool"):
						# Increase weight of area damage enemies
						for enemy in phase["enemy_pool"]:
							if enemy["type"] in ["spitter", "void_stalker"]:
								enemy["weight"] *= 1.5
	
	modified_data["region_modifier"] = {
		"region_id": region_id,
		"modifier": modifier,
		"description": pattern["description"]
	}
	
	return modified_data
