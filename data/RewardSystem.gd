extends RefCounted

# Reward System - Manages reward choices and progression for levels
# Integrates with LevelStructure.gd for comprehensive reward management

# Reward choice generation
static func generate_reward_choices(level_number: int) -> Array[Dictionary]:
	var reward_tier = _get_reward_tier_for_level(level_number)
	var tier_info = _get_reward_tier_info(reward_tier)
	
	if tier_info.is_empty():
		return []
	
	var choices: Array[Dictionary] = []
	var choice_count = tier_info.get("choice_count", 2)
	
	# Generate creature choices
	var creature_choices = tier_info.get("creature_choices", [])
	for i in range(min(2, choice_count)):
		if creature_choices.size() > 0:
			var creature = creature_choices[randi() % creature_choices.size()]
			choices.append({
				"type": "creature",
				"id": creature,
				"display_name": _format_creature_name(creature),
				"description": _get_creature_description(creature)
			})
	
	# Generate item choices if we have more slots
	if choices.size() < choice_count:
		var item_choices = tier_info.get("item_choices", [])
		for i in range(choice_count - choices.size()):
			if item_choices.size() > 0:
				var item = item_choices[randi() % item_choices.size()]
				choices.append({
					"type": "item",
					"id": item,
					"display_name": _format_item_name(item),
					"description": _get_item_description(item)
				})
	
	return choices

# Apply reward to player state
static func apply_reward(reward: Dictionary) -> void:
	match reward.get("type", ""):
		"creature":
			_apply_creature_reward(reward.get("id", ""))
		"item":
			_apply_item_reward(reward.get("id", ""))
		_:
			push_error("Unknown reward type: " + str(reward.get("type", "")))

# Check if player can receive reward
static func can_receive_reward(reward: Dictionary) -> bool:
	match reward.get("type", ""):
		"creature":
			return _can_receive_creature(reward.get("id", ""))
		"item":
			return _can_receive_item(reward.get("id", ""))
		_:
			return false

# Get reward tier progression info
static func get_reward_progression_info() -> Dictionary:
	return {
		"tiers": ["common", "uncommon", "rare", "epic", "legendary"],
		"level_thresholds": {
			"common": [1, 2],
			"uncommon": [3, 4],
			"rare": [5, 6],
			"epic": [7, 8],
			"legendary": [9, 10]
		},
		"choice_counts": {
			"common": 2,
			"uncommon": 2,
			"rare": 3,
			"epic": 3,
			"legendary": 4
		}
	}

# Helper functions for reward tier management
static func _get_reward_tier_for_level(level_number: int) -> String:
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

static func _get_reward_tier_info(tier: String) -> Dictionary:
	match tier:
		"common":
			return {
				"creature_choices": ["ashclaw", "gruvek"],
				"item_choices": ["basic_potion", "minor_upgrade"],
				"choice_count": 2
			}
		"uncommon":
			return {
				"creature_choices": ["bond_remnant", "veilskin"],
				"item_choices": ["potion", "upgrade"],
				"choice_count": 2
			}
		"rare":
			return {
				"creature_choices": ["ashclaw", "gruvek", "bond_remnant", "veilskin"],
				"item_choices": ["major_potion", "major_upgrade"],
				"choice_count": 3
			}
		"epic":
			return {
				"creature_choices": ["ashclaw", "gruvek", "bond_remnant", "veilskin"],
				"item_choices": ["legendary_potion", "legendary_upgrade"],
				"choice_count": 3
			}
		"legendary":
			return {
				"creature_choices": ["ashclaw", "gruvek", "bond_remnant", "veilskin"],
				"item_choices": ["mythic_potion", "mythic_upgrade"],
				"choice_count": 4
			}
		_:
			return {}

# Private helper functions

static func _format_creature_name(creature_id: String) -> String:
	match creature_id:
		"ashclaw":
			return "Ashclaw"
		"gruvek":
			return "Gruvek"
		"bond_remnant":
			return "Bond Remnant"
		"veilskin":
			return "Veilskin"
		_:
			return creature_id.capitalize()

static func _get_creature_description(creature_id: String) -> String:
	match creature_id:
		"ashclaw":
			return "A fierce creature with burning claws. High attack power."
		"gruvek":
			return "A sturdy defender with natural armor. High health."
		"bond_remnant":
			return "A spectral ally that phases through attacks. Evasive."
		"veilskin":
			return "A mysterious being that manipulates reality. Support abilities."
		_:
			return "A mysterious creature with unknown powers."

static func _format_item_name(item_id: String) -> String:
	match item_id:
		"basic_potion":
			return "Basic Health Potion"
		"minor_upgrade":
			return "Minor Power Upgrade"
		"potion":
			return "Health Potion"
		"upgrade":
			return "Power Upgrade"
		"major_potion":
			return "Major Health Potion"
		"major_upgrade":
			return "Major Power Upgrade"
		"legendary_potion":
			return "Legendary Health Potion"
		"legendary_upgrade":
			return "Legendary Power Upgrade"
		"mythic_potion":
			return "Mythic Health Potion"
		"mythic_upgrade":
			return "Mythic Power Upgrade"
		_:
			return item_id.capitalize().replace("_", " ")

static func _get_item_description(item_id: String) -> String:
	match item_id:
		"basic_potion":
			return "Restores a small amount of health."
		"minor_upgrade":
			return "Slightly increases your attack power."
		"potion":
			return "Restores a moderate amount of health."
		"upgrade":
			return "Increases your attack power."
		"major_potion":
			return "Restores a large amount of health."
		"major_upgrade":
			return "Significantly increases your attack power."
		"legendary_potion":
			return "Restores a massive amount of health."
		"legendary_upgrade":
			return "Greatly increases your attack power."
		"mythic_potion":
			return "Fully restores health and grants temporary regeneration."
		"mythic_upgrade":
			return "Dramatically increases your attack power and unlocks new abilities."
		_:
			return "A mysterious item with unknown effects."

static func _apply_creature_reward(creature_id: String) -> void:
	# This would integrate with the creature/bonding system
	# For now, just log the reward
	print("Player received creature: ", creature_id)
	
	# TODO: Add to GameState.creature_collection
	# TODO: Update bonding progress

static func _apply_item_reward(item_id: String) -> void:
	# This would integrate with the item/power-up system
	# For now, just log the reward
	print("Player received item: ", item_id)
	
	# TODO: Apply effects to GameState.player_stats
	# TODO: Add to inventory if applicable

static func _can_receive_creature(_creature_id: String) -> bool:
	# Check if player can bond with this creature
	# TODO: Check against GameState.creature_collection
	# TODO: Check bonding limits
	return true

static func _can_receive_item(_item_id: String) -> bool:
	# Check if player can receive this item
	# TODO: Check inventory space
	# TODO: Check duplicate items
	return true
