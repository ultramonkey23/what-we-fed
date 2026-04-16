extends RefCounted

# Region data for the Route-Lite layer.
# Each region has a name, flavor line, tag, and one run modifier.
# Modifier types:
#   "attack_bonus"           — adds to GameState.player_base_damage at run start
#   "max_hp_bonus"           — adds to GameState.player_max_hp at run start
#   "starting_support_charge" — sets RunGrowth.support_charge at run start (needs a bonded creature)

const REGIONS: Array[Dictionary] = [
	{
		"id": "feeding_hollow",
		"name": "The Feeding Hollow",
		"flavor": "Every creature here learned hunger from the same wound.",
		"tag": "FAMILIAR",
		"modifier": {"type": "attack_bonus", "value": 3.0},
		"modifier_label": "+3 attack damage"
	},
	{
		"id": "pale_shelf",
		"name": "The Pale Shelf",
		"flavor": "Nothing hides here. Neither do you.",
		"tag": "EXPOSED",
		"modifier": {"type": "max_hp_bonus", "value": 20.0},
		"modifier_label": "+20 max HP"
	},
	{
		"id": "drowned_cut",
		"name": "The Drowned Cut",
		"flavor": "Something older moved through here. The water still remembers its weight.",
		"tag": "RESONANT",
		"modifier": {"type": "starting_support_charge", "value": 30.0},
		"modifier_label": "Bond starts 30% charged\nRequires a bonded creature to take effect"
	}
]
