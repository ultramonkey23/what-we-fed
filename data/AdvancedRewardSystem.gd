extends RefCounted

# Advanced Reward System - Enhances RewardSystem.gd with synergies and combos
# This system adds depth without breaking existing reward functionality

# Reward synergy combinations
const REWARD_SYNERGIES: Dictionary = {
	"creature_combos": {
		"ashclaw_gruvek": {
			"name": "Predator Pair",
			"description": "Ashclaw and Gruvek work together for increased damage",
			"effects": {
				"damage_bonus": 15.0,
				"combo_ability": "coordinated_strike"
			}
		},
		"bond_remnant_veilskin": {
			"name": "Ethereal Bond",
			"description": "Spectral creatures with enhanced evasion",
			"effects": {
				"evasion_bonus": 20.0,
				"combo_ability": "phase_shift"
			}
		},
		"ashclaw_bond_remnant": {
			"name": "Life-Death Cycle",
			"description": "Balanced offense with life steal properties",
			"effects": {
				"life_steal": 10.0,
				"damage_bonus": 8.0
			}
		},
		"gruvek_veilskin": {
			"name": "Mystic Guardian",
			"description": "Defensive creature with reality manipulation",
			"effects": {
				"defense_bonus": 12.0,
				"support_power": 25.0
			}
		}
	},
	"item_combos": {
		"potion_upgrade": {
			"name": "Enhanced Recovery",
			"description": "Potion and upgrade work together for better healing",
			"effects": {
				"healing_bonus": 30.0,
				"temporary_boost": true
			}
		},
		"major_potion_major_upgrade": {
			"name": "Power Surge",
			"description": "Major combination provides significant temporary boost",
			"effects": {
				"power_multiplier": 1.5,
				"duration": 60.0
			}
		}
	},
	"mixed_combos": {
		"ashclaw_basic_potion": {
			"name": "Berserker's Brew",
			"description": "Creature + item provides rage-like state",
			"effects": {
				"berserk_mode": true,
				"duration": 30.0
			}
		},
		"veilskin_legendary_upgrade": {
			"name": "Reality Bender",
			"description": "Ultimate combination for reality manipulation",
			"effects": {
				"reality_warp": true,
				"omniscience": 15.0
			}
		}
	}
}

# Reward progression paths
const PROGRESSION_PATHS: Dictionary = {
	"offensive_path": {
		"name": "Path of Destruction",
		"description": "Focus on damage and aggressive abilities",
		"recommended_rewards": ["ashclaw", "bond_reaper", "power_upgrades"],
		"milestone_rewards": {
			3: "damage_boost_10",
			6: "critical_strike_chance",
			9: "ultimate_destruction"
		}
	},
	"defensive_path": {
		"name": "Path of Resilience",
		"description": "Focus on survival and defensive abilities",
		"recommended_rewards": ["gruvek", "warden", "health_upgrades"],
		"milestone_rewards": {
			3: "health_boost_20",
			6: "damage_reduction",
			9: "immunity_field"
		}
	},
	"balanced_path": {
		"name": "Path of Balance",
		"description": "Mixed approach with versatility",
		"recommended_rewards": ["ashclaw", "gruvek", "mixed_upgrades"],
		"milestone_rewards": {
			3: "balanced_stats",
			6: "adaptability",
			9: "perfect_balance"
		}
	},
	"mystic_path": {
		"name": "Path of Mysticism",
		"description": "Focus on reality manipulation and support",
		"recommended_rewards": ["veilskin", "bond_remnant", "support_upgrades"],
		"milestone_rewards": {
			3: "reality_sight",
			6: "phase_mastery",
			9: "omnipotence"
		}
	}
}

# Special reward events
const SPECIAL_REWARD_EVENTS: Dictionary = {
	"perfect_level": {
		"name": "Flawless Victory",
		"description": "Complete level with no damage taken",
		"bonus_rewards": ["legendary_choice", "mythic_upgrade"],
		"multiplier": 2.0
	},
	"speed_clear": {
		"name": "Light Speed",
		"description": "Complete level in under 60 seconds",
		"bonus_rewards": ["time_bonus", "speed_upgrade"],
		"multiplier": 1.5
	},
	"combo_master": {
		"name": "Combo Master",
		"description": "Achieve 10x combo multiplier",
		"bonus_rewards": ["combo_enhancer", "critical_upgrade"],
		"multiplier": 1.8
	},
	"survivor": {
		"name": "True Survivor",
		"description": "Survive with less than 10% health",
		"bonus_rewards": ["second_wind", "desperation_power"],
		"multiplier": 1.3
	},
	"collector": {
		"name": "Collector",
		"description": "Collect all reward types in a run",
		"bonus_rewards": ["collector_bonus", "completion_reward"],
		"multiplier": 1.6
	}
}

# Enhanced reward generation with synergies
static func generate_enhanced_rewards(
	level_number: int, 
	player_history: Dictionary = {},
	current_rewards: Array = []
) -> Array[Dictionary]:
	var enhanced_rewards = _generate_base_reward_choices(level_number)
	
	# Check for synergy opportunities
	var synergy_rewards = _check_synergy_opportunities(current_rewards, level_number)
	
	# Add synergy rewards if available
	for synergy in synergy_rewards:
		enhanced_rewards.append(synergy)
	
	# Check for special events
	var event_rewards = _check_special_events(player_history, level_number)
	for event in event_rewards:
		enhanced_rewards.append(event)
	
	# Apply progression path bonuses
	var path_bonus = _get_progression_path_bonus(player_history, level_number)
	if not path_bonus.is_empty():
		enhanced_rewards.append(path_bonus)
	
	return enhanced_rewards

# Calculate reward synergy effects
static func calculate_synergy_effects(player_rewards: Array[String]) -> Dictionary:
	var active_synergies: Array[Dictionary] = []
	var total_effects: Dictionary = {}
	
	# Check creature combos
	var creature_rewards = player_rewards.filter(func(r): return r in ["ashclaw", "gruvek", "bond_remnant", "veilskin"])
	
	if creature_rewards.size() >= 2:
		var combo_key = creature_rewards[0] + "_" + creature_rewards[1]
		if REWARD_SYNERGIES["creature_combos"].has(combo_key):
			var synergy = REWARD_SYNERGIES["creature_combos"][combo_key]
			active_synergies.append(synergy)
			_merge_effects(total_effects, synergy["effects"])
	
	# Check item combos
	var item_rewards = player_rewards.filter(func(r): return "potion" in r or "upgrade" in r)
	
	if "potion" in str(item_rewards) and "upgrade" in str(item_rewards):
		var synergy = REWARD_SYNERGIES["item_combos"]["potion_upgrade"]
		active_synergies.append(synergy)
		_merge_effects(total_effects, synergy["effects"])
	
	# Check mixed combos
	for reward in player_rewards:
		for combo_key in REWARD_SYNERGIES["mixed_combos"].keys():
			if reward in combo_key:
				var synergy = REWARD_SYNERGIES["mixed_combos"][combo_key]
				active_synergies.append(synergy)
				_merge_effects(total_effects, synergy["effects"])
	
	return {
		"active_synergies": active_synergies,
		"total_effects": total_effects,
		"synergy_count": active_synergies.size()
	}

# Reward recommendation system
static func get_reward_recommendations(
	player_history: Dictionary,
	current_level: int,
	available_rewards: Array[Dictionary]
) -> Dictionary:
	var recommendations: Array[Dictionary] = []
	
	# Analyze player's current path
	var player_path = _determine_player_path(player_history)
	var path_info = PROGRESSION_PATHS.get(player_path, PROGRESSION_PATHS["balanced_path"])
	
	# Recommend rewards that fit the player's path
	for reward in available_rewards:
		var score = 0.0
		
		# Path alignment bonus
		if reward["id"] in path_info["recommended_rewards"]:
			score += 2.0
		
		# Synergy potential
		var synergy_potential = _calculate_synergy_potential(reward["id"], player_history.get("rewards", []))
		score += synergy_potential
		
		# Level appropriateness
		var level_score = _calculate_level_appropriateness(reward["id"], current_level)
		score += level_score
		
		# Balance considerations
		var balance_score = _calculate_balance_score(reward["id"], player_history.get("rewards", []))
		score += balance_score
		
		recommendations.append({
			"reward": reward,
			"score": score,
			"reason": _generate_recommendation_reason(score, player_path, synergy_potential)
		})
	
	# Sort by score
	recommendations.sort_custom(func(a, b): return a.score > b.score)
	
	return {
		"player_path": player_path,
		"recommendations": recommendations,
		"path_info": path_info
	}

# Reward tracking and analytics
static func create_reward_analytics() -> Dictionary:
	return {
		"rewards_collected": [],
		"synergies_unlocked": [],
		"path_progress": {},
		"special_events": [],
		"reward_efficiency": {},
		"completion_rate": 0.0
	}

# Update reward analytics
static func update_analytics(analytics: Dictionary, new_reward: String, performance_data: Dictionary = {}) -> void:
	analytics["rewards_collected"].append(new_reward)
	
	# Check for new synergies
	var current_synergies = analytics["synergies_unlocked"]
	var new_synergies = _check_new_synergies(analytics["rewards_collected"])
	for synergy in new_synergies:
		if not synergy in current_synergies:
			current_synergies.append(synergy)
	
	# Update path progress
	var path = _determine_player_path({"rewards": analytics["rewards_collected"]})
	if not analytics["path_progress"].has(path):
		analytics["path_progress"][path] = 0
	analytics["path_progress"][path] += 1
	
	# Track reward efficiency
	if performance_data.has("efficiency"):
		var reward_type = _get_reward_type(new_reward)
		if not analytics["reward_efficiency"].has(reward_type):
			analytics["reward_efficiency"][reward_type] = []
		analytics["reward_efficiency"][reward_type].append(performance_data["efficiency"])

# Helper function to generate base reward choices
static func _generate_base_reward_choices(level_number: int) -> Array[Dictionary]:
	# Simplified reward generation (copied from RewardSystem logic)
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

# Private helper functions

static func _check_synergy_opportunities(current_rewards: Array, _level_number: int) -> Array[Dictionary]:
	var opportunities: Array[Dictionary] = []
	
	# Check for near-complete combos
	for combo_key in REWARD_SYNERGIES["creature_combos"].keys():
		var creatures = combo_key.split("_")
		var has_creature = 0
		
		for creature in creatures:
			if creature in current_rewards:
				has_creature += 1
		
		if has_creature == 1:  # One creature already owned
			var missing_creature = creatures[0] if creatures[1] in current_rewards else creatures[1]
			opportunities.append({
				"type": "synergy_opportunity",
				"id": missing_creature,
				"display_name": "Complete " + REWARD_SYNERGIES["creature_combos"][combo_key]["name"],
				"description": "You already have one creature from this pair!",
				"synergy_info": REWARD_SYNERGIES["creature_combos"][combo_key]
			})
	
	return opportunities

static func _check_special_events(player_history: Dictionary, _level_number: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	
	# Check for special achievement milestones
	var total_levels = player_history.get("levels_completed", 0)
	
	if total_levels == 9:  # About to complete a run
		events.append({
			"type": "special_event",
			"id": "run_completion_bonus",
			"display_name": "Run Completion",
			"description": "Bonus reward for completing a full run!",
			"rarity": "legendary"
		})
	
	# Check for streak bonuses
	var current_streak = player_history.get("current_streak", 0)
	if current_streak >= 3:
		events.append({
			"type": "streak_bonus",
			"id": "victory_streak",
			"display_name": "Victory Streak",
			"description": "Bonus for " + str(current_streak) + " wins in a row!",
			"rarity": "epic"
		})
	
	return events

static func _get_progression_path_bonus(player_history: Dictionary, level_number: int) -> Dictionary:
	var path = _determine_player_path(player_history)
	var path_info = PROGRESSION_PATHS[path]
	
	# Check for milestone rewards
	for milestone in path_info["milestone_rewards"].keys():
		if level_number == milestone:
			var milestone_reward = path_info["milestone_rewards"][milestone]
			return {
				"type": "milestone_bonus",
				"id": milestone_reward,
				"display_name": "Milestone: " + milestone_reward,
				"description": "Achievement for following the " + path_info["name"],
				"rarity": "rare"
			}
	
	return {}

static func _determine_player_path(player_history: Dictionary) -> String:
	var rewards = player_history.get("rewards", [])
	
	var offense_score = 0
	var defense_score = 0
	var mystic_score = 0
	
	for reward in rewards:
		match reward:
			"ashclaw", "bond_reaper":
				offense_score += 2
			"gruvek", "warden":
				defense_score += 2
			"veilskin", "bond_remnant":
				mystic_score += 2
			_:
				if "upgrade" in reward and "power" in reward:
					offense_score += 1
				elif "potion" in reward:
					defense_score += 1
	
	var max_score = max(offense_score, defense_score, mystic_score)
	
	if max_score == offense_score:
		return "offensive_path"
	elif max_score == defense_score:
		return "defensive_path"
	elif max_score == mystic_score:
		return "mystic_path"
	else:
		return "balanced_path"

static func _merge_effects(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if target.has(key):
			target[key] += source[key]
		else:
			target[key] = source[key]

static func _calculate_synergy_potential(new_reward: String, existing_rewards: Array[String]) -> float:
	var potential = 0.0
	
	# Check all possible combos
	for combo_key in REWARD_SYNERGIES["creature_combos"].keys():
		if new_reward in combo_key:
			var creatures = combo_key.split("_")
			var other_creature = creatures[0] if creatures[1] == new_reward else creatures[1]
			if other_creature in existing_rewards:
				potential += 3.0
	
	for combo_key in REWARD_SYNERGIES["mixed_combos"].keys():
		if new_reward in combo_key:
			var parts = combo_key.split("_")
			for part in parts:
				if part != new_reward and part in existing_rewards:
					potential += 2.0
					break
	
	return potential

static func _calculate_level_appropriateness(reward_id: String, level: int) -> float:
	# Higher level rewards are more appropriate for later levels
	var reward_tiers = {
		"basic": 1, "minor": 1,
		"": 2,  # Regular items
		"major": 3,
		"legendary": 4,
		"mythic": 5
	}
	
	var tier = 2  # Default
	for tier_name in reward_tiers.keys():
		if tier_name in reward_id:
			tier = reward_tiers[tier_name]
			break
	
	# Calculate appropriateness based on level
	var expected_tier = min(1 + int(level / 3), 5)
	var difference = abs(tier - expected_tier)
	
	return max(0.0, 1.0 - difference * 0.3)

static func _calculate_balance_score(reward_id: String, existing_rewards: Array[String]) -> float:
	# Encourage variety in reward choices
	var reward_type = _get_reward_type(reward_id)
	var type_count = existing_rewards.filter(func(r): return _get_reward_type(r) == reward_type).size()
	
	# Lower score for too many of the same type
	if type_count >= 3:
		return -1.0
	elif type_count == 2:
		return -0.5
	else:
		return 0.5

static func _get_reward_type(reward_id: String) -> String:
	if reward_id in ["ashclaw", "gruvek", "bond_remnant", "veilskin"]:
		return "creature"
	elif "potion" in reward_id:
		return "potion"
	elif "upgrade" in reward_id:
		return "upgrade"
	else:
		return "other"

static func _generate_recommendation_reason(score: float, path: String, synergy_potential: float) -> String:
	var reasons = []
	
	if score >= 2.5:
		reasons.append("Highly recommended")
	elif score >= 1.5:
		reasons.append("Good choice")
	else:
		reasons.append("Consider alternatives")
	
	if synergy_potential > 2.0:
		reasons.append("Strong synergy potential")
	elif synergy_potential > 0.0:
		reasons.append("Some synergy potential")
	
	reasons.append("Fits " + PROGRESSION_PATHS[path]["name"])
	
	return ", ".join(reasons)

static func _check_new_synergies(all_rewards: Array[String]) -> Array[String]:
	var new_synergies: Array[String] = []
	
	for combo_key in REWARD_SYNERGIES["creature_combos"].keys():
		var creatures = combo_key.split("_")
		if creatures[0] in all_rewards and creatures[1] in all_rewards:
			new_synergies.append(combo_key)
	
	return new_synergies
