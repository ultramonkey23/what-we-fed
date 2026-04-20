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
		"flavor": "Every mouth here learned hunger from the same wound.",
		"tag": "FAMILIAR",
		"modifier": {"type": "attack_bonus", "value": 3.0},
		"modifier_label": "+3 attack damage\nThe hollow answers force with force"
	},
	{
		"id": "pale_shelf",
		"name": "The Pale Shelf",
		"flavor": "Nothing hides here. Loss stays in plain sight.",
		"tag": "EXPOSED",
		"modifier": {"type": "max_hp_bonus", "value": 20.0},
		"modifier_label": "+20 max HP\nThe shelf teaches you to stay standing"
	},
	{
		"id": "drowned_cut",
		"name": "The Drowned Cut",
		"flavor": "Something older moved through here. The water still keeps its shape.",
		"tag": "RESONANT",
		"modifier": {"type": "starting_support_charge", "value": 30.0},
		"modifier_label": "Bond starts 30% charged\nRequires a bonded creature to answer"
	}
]
