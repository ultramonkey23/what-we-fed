extends RefCounted

# Level Variations System - Adds variety and modifiers to existing level structure
# This system enhances LevelStructure.gd without modifying it

# Level variation types
enum VariationType {
	NONE,
	TIME_PRESSURE,
	ENEMY_SWARM,
	ELITE_CHALLENGE,
	STEALTH_ATTACK,
	DEFENSE_TEST,
	BOSS_RUSH,
	MOBILITY_CHALLENGE,
	ACCURACY_TEST,
	SURVIVAL_MODE
}

# Variation modifiers that can be applied to any level
const VARIATION_MODIFIERS: Dictionary = {
	VariationType.TIME_PRESSURE: {
		"name": "Time Pressure",
		"description": "Level duration reduced by 25%, but rewards increased",
		"duration_multiplier": 0.75,
		"enemy_speed_multiplier": 1.1,
		"reward_bonus": 1.5,
		"spawn_rate_multiplier": 1.2
	},
	VariationType.ENEMY_SWARM: {
		"name": "Enemy Swarm",
		"description": "More enemies with lower health, faster spawn rate",
		"enemy_health_multiplier": 0.7,
		"max_threats_multiplier": 1.5,
		"spawn_rate_multiplier": 1.4,
		"enemy_speed_multiplier": 0.9
	},
	VariationType.ELITE_CHALLENGE: {
		"name": "Elite Challenge",
		"description": "Fewer but tougher enemies with enhanced abilities",
		"enemy_health_multiplier": 1.8,
		"enemy_damage_multiplier": 1.3,
		"max_threats_multiplier": 0.7,
		"elite_chance": 0.8
	},
	VariationType.STEALTH_ATTACK: {
		"name": "Stealth Attack",
		"description": "Enemies appear and disappear, test your awareness",
		"stealth_chance": 0.6,
		"visibility_duration": 3.0,
		"invisibility_duration": 2.0,
		"spawn_rate_multiplier": 0.8
	},
	VariationType.DEFENSE_TEST: {
		"name": "Defense Test",
		"description": "Enemies have higher defense, require strategic attacks",
		"enemy_defense_bonus": 3.0,
		"enemy_health_multiplier": 1.2,
		"weak_point_chance": 0.3
	},
	VariationType.BOSS_RUSH: {
		"name": "Boss Rush",
		"description": "Mini-boss enemies appear throughout the level",
		"boss_enemy_chance": 0.4,
		"enemy_health_multiplier": 2.0,
		"enemy_damage_multiplier": 1.5,
		"max_threats_multiplier": 0.5
	},
	VariationType.MOBILITY_CHALLENGE: {
		"name": "Mobility Challenge",
		"description": "Fast-moving enemies with unpredictable patterns",
		"enemy_speed_multiplier": 1.8,
		"pattern_change_frequency": 5.0,
		"spawn_rate_multiplier": 1.1
	},
	VariationType.ACCURACY_TEST: {
		"name": "Accuracy Test",
		"description": "Smaller, faster enemies that are harder to hit",
		"enemy_size_multiplier": 0.7,
		"enemy_speed_multiplier": 1.5,
		"accuracy_threshold": 0.7,
		"reward_bonus": 1.3
	},
	VariationType.SURVIVAL_MODE: {
		"name": "Survival Mode",
		"description": "Gradually increasing difficulty throughout the level",
		"difficulty_ramp": 0.02,  # 2% increase per second
		"starting_difficulty": 0.7,
		"max_difficulty": 2.0,
		"reward_bonus": 1.4
	}
}

# Environmental modifiers that can be combined with variations
const ENVIRONMENTAL_MODIFIERS: Dictionary = {
	"zero_gravity": {
		"name": "Zero Gravity",
		"description": "Projectiles move differently, enemies float",
		"gravity_multiplier": 0.1,
		"projectile_speed_multiplier": 0.7,
		"enemy_float_chance": 1.0
	},
	"heavy_gravity": {
		"name": "Heavy Gravity",
		"description": "Everything falls faster, projectiles arc more",
		"gravity_multiplier": 2.0,
		"projectile_speed_multiplier": 1.3,
		"enemy_speed_multiplier": 0.8
	},
	"reversed_controls": {
		"name": "Reversed Controls",
		"description": "Left/right controls are swapped",
		"control_reversal": true,
		"difficulty_bonus": 1.2,
		"reward_bonus": 1.3
	},
	"limited_visibility": {
		"name": "Limited Visibility",
		"description": "Reduced vision range, enemies appear suddenly",
		"visibility_range": 0.5,
		"enemy_stealth_bonus": 0.3,
		"reward_bonus": 1.2
	},
	"weapon_malfunction": {
		"name": "Weapon Malfunction",
		"description": "Random weapon jams and misfires",
		"jam_chance": 0.15,
		"misfire_chance": 0.1,
		"reward_bonus": 1.4
	},
	"power_surge": {
		"name": "Power Surge",
		"description": "Your abilities are enhanced but overheat faster",
		"power_multiplier": 1.5,
		"overheat_rate": 1.8,
		"reward_bonus": 1.1
	}
}

# Get random variation for a level (with weights based on level number)
static func get_random_variation(level_number: int, exclude_types: Array[VariationType] = []) -> VariationType:
	var available_variations: Array[VariationType] = []
	var weights: Array[float] = []
	
	for variation in VariationType.values():
		if variation == VariationType.NONE or variation in exclude_types:
			continue
		
		# Weight based on level appropriateness
		var weight = _get_variation_weight(variation, level_number)
		if weight > 0:
			available_variations.append(variation)
			weights.append(weight)
	
	if available_variations.is_empty():
		return VariationType.NONE
	
	# Weighted random selection
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(available_variations.size()):
		current_weight += weights[i]
		if roll <= current_weight:
			return available_variations[i]
	
	return available_variations[0]

# Apply variation to level data
static func apply_variation(
	base_level_data: Dictionary, 
	variation: VariationType,
	environmental_modifier: String = ""
) -> Dictionary:
	var modified_data = base_level_data.duplicate(true)
	
	# Apply variation modifier
	if variation != VariationType.NONE and VARIATION_MODIFIERS.has(variation):
		var modifier = VARIATION_MODIFIERS[variation]
		modified_data = _apply_modifier_to_level(modified_data, modifier)
		modified_data["variation"] = {
			"type": variation,
			"name": modifier["name"],
			"description": modifier["description"]
		}
	
	# Apply environmental modifier
	if environmental_modifier != "" and ENVIRONMENTAL_MODIFIERS.has(environmental_modifier):
		var env_modifier = ENVIRONMENTAL_MODIFIERS[environmental_modifier]
		modified_data = _apply_modifier_to_level(modified_data, env_modifier)
		modified_data["environmental_modifier"] = {
			"type": environmental_modifier,
			"name": env_modifier["name"],
			"description": env_modifier["description"]
		}
	
	return modified_data

# Get variation combinations for special occasions
static func get_special_variation_combination(occasion: String) -> Dictionary:
	var combinations = {
		"boss_preview": {
			"variation": VariationType.BOSS_RUSH,
			"environmental": "power_surge",
			"description": "Preview of boss challenges with enhanced powers"
		},
		"training_mode": {
			"variation": VariationType.ACCURACY_TEST,
			"environmental": "",
			"description": "Focus on accuracy and precision"
		},
		"extreme_challenge": {
			"variation": VariationType.SURVIVAL_MODE,
			"environmental": "limited_visibility",
			"description": "Maximum difficulty with reduced visibility"
		},
		"chaos_mode": {
			"variation": VariationType.ENEMY_SWARM,
			"environmental": "reversed_controls",
			"description": "Chaotic swarm with reversed controls"
		},
		"stealth_training": {
			"variation": VariationType.STEALTH_ATTACK,
			"environmental": "limited_visibility",
			"description": "Stealth challenges with reduced visibility"
		}
	}
	
	return combinations.get(occasion, {"variation": VariationType.NONE, "environmental": ""})

# Progressive variation system - variations get more complex at higher levels
static func get_progressive_variations(level_number: int) -> Array[Dictionary]:
	var variations: Array[Dictionary] = []
	
	# Early levels (1-3): Simple variations
	if level_number <= 3:
		variations.append({
			"variation": get_random_variation(level_number, [VariationType.ELITE_CHALLENGE, VariationType.BOSS_RUSH]),
			"environmental": ""
		})
	
	# Mid levels (4-6): More complex variations
	elif level_number <= 6:
		var variation = get_random_variation(level_number)
		var environmental = ""
		
		# 30% chance of environmental modifier
		if randf() < 0.3:
			environmental = _get_random_environmental_modifier()
		
		variations.append({
			"variation": variation,
			"environmental": environmental
		})
	
	# Late levels (7-9): Complex combinations
	else:
		var variation = get_random_variation(level_number)
		var environmental = _get_random_environmental_modifier()
		
		# 50% chance of environmental modifier
		if randf() < 0.5:
			environmental = _get_random_environmental_modifier()
		else:
			environmental = ""
		
		variations.append({
			"variation": variation,
			"environmental": environmental
		})
	
	# Boss level (10): Special combinations
	if level_number == 10:
		variations.append(get_special_variation_combination("boss_preview"))
	
	return variations

# Calculate variation difficulty impact
static func calculate_variation_difficulty_impact(variation: VariationType, environmental: String = "") -> float:
	var impact = 1.0
	
	if variation != VariationType.NONE and VARIATION_MODIFIERS.has(variation):
		var modifier = VARIATION_MODIFIERS[variation]
		# Estimate difficulty based on modifiers
		if modifier.has("enemy_health_multiplier"):
			impact *= modifier["enemy_health_multiplier"]
		if modifier.has("enemy_damage_multiplier"):
			impact *= modifier["enemy_damage_multiplier"]
		if modifier.has("spawn_rate_multiplier"):
			impact *= (1.0 + (modifier["spawn_rate_multiplier"] - 1.0) * 0.5)
	
	if environmental != "" and ENVIRONMENTAL_MODIFIERS.has(environmental):
		var env_modifier = ENVIRONMENTAL_MODIFIERS[environmental]
		if env_modifier.has("difficulty_bonus"):
			impact *= env_modifier["difficulty_bonus"]
		elif environmental == "reversed_controls":
			impact *= 1.3  # Reversed controls are significantly harder
	
	return impact

# Private helper functions

static func _get_variation_weight(variation: VariationType, level_number: int) -> float:
	# Base weights for different level ranges
	match variation:
		VariationType.TIME_PRESSURE:
			return 1.0 if level_number >= 2 else 0.3
		VariationType.ENEMY_SWARM:
			return 1.2 if level_number >= 3 else 0.8
		VariationType.ELITE_CHALLENGE:
			return 1.0 if level_number >= 5 else 0.2
		VariationType.STEALTH_ATTACK:
			return 0.8 if level_number >= 4 else 0.4
		VariationType.DEFENSE_TEST:
			return 0.9 if level_number >= 3 else 0.5
		VariationType.BOSS_RUSH:
			return 0.7 if level_number >= 7 else 0.1
		VariationType.MOBILITY_CHALLENGE:
			return 1.0 if level_number >= 4 else 0.6
		VariationType.ACCURACY_TEST:
			return 0.8 if level_number >= 2 else 0.9
		VariationType.SURVIVAL_MODE:
			return 0.6 if level_number >= 6 else 0.2
		_:
			return 0.5

static func _apply_modifier_to_level(level_data: Dictionary, modifier: Dictionary) -> Dictionary:
	var modified_data = level_data.duplicate(true)
	
	if modified_data.has("phases"):
		for phase in modified_data["phases"]:
			# Apply enemy stat multipliers
			if phase.has("enemy_pool"):
				for enemy in phase["enemy_pool"]:
					if modifier.has("enemy_health_multiplier"):
						enemy["hp"] *= modifier["enemy_health_multiplier"]
					if modifier.has("enemy_damage_multiplier"):
						enemy["damage"] *= modifier["enemy_damage_multiplier"]
					if modifier.has("enemy_speed_multiplier"):
						enemy["speed"] = enemy.get("speed", 1.0) * modifier["enemy_speed_multiplier"]
					if modifier.has("enemy_size_multiplier"):
						enemy["size"] = enemy.get("size", 1.0) * modifier["enemy_size_multiplier"]
					if modifier.has("enemy_defense_bonus"):
						enemy["defense"] = enemy.get("defense", 0.0) + modifier["enemy_defense_bonus"]
			
			# Apply phase multipliers
			if modifier.has("spawn_rate_multiplier"):
				phase["cycle_interval"] = phase["cycle_interval"] / modifier["spawn_rate_multiplier"]
			
			if modifier.has("max_threats_multiplier"):
				phase["max_active_threats"] = int(phase["max_active_threats"] * modifier["max_threats_multiplier"])
			
			# Apply special properties
			if modifier.has("stealth_chance"):
				phase["stealth_chance"] = modifier["stealth_chance"]
			if modifier.has("elite_chance"):
				phase["elite_chance"] = modifier["elite_chance"]
			if modifier.has("boss_enemy_chance"):
				phase["boss_enemy_chance"] = modifier["boss_enemy_chance"]
	
	# Apply duration multiplier
	if modifier.has("duration_multiplier"):
		modified_data["duration"] = modified_data.get("duration", 120.0) * modifier["duration_multiplier"]
	
	return modified_data

static func _get_random_environmental_modifier() -> String:
	var modifiers = ENVIRONMENTAL_MODIFIERS.keys()
	return modifiers[randi() % modifiers.size()]
