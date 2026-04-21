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
		"potential_max_grade": "alpha",
		"modifier": {"type": "attack_bonus", "value": 3.0},
		"modifier_label": "+3 attack damage\nThe hollow answers force with force"
	},
	{
		"id": "pale_shelf",
		"name": "The Pale Shelf",
		"flavor": "Nothing hides here. Loss stays in plain sight.",
		"tag": "EXPOSED",
		"potential_max_grade": "alpha",
		"modifier": {"type": "max_hp_bonus", "value": 20.0},
		"modifier_label": "+20 max HP\nThe shelf teaches you to stay standing"
	},
	{
		"id": "drowned_cut",
		"name": "The Drowned Cut",
		"flavor": "Something older moved through here. The water still keeps its shape.",
		"tag": "RESONANT",
		"potential_max_grade": "alpha",
		"modifier": {"type": "starting_support_charge", "value": 30.0},
		"modifier_label": "Bond starts 30% charged\nRequires a bonded creature to answer"
	},
	{
		"id": "echoing_chasm",
		"name": "The Echoing Chasm",
		"flavor": "Every sound here is a memory of a sound that never stopped.",
		"tag": "AMPLIFIED",
		"potential_max_grade": "alpha",
		"modifier": {"type": "attack_bonus", "value": 5.0},
		"modifier_label": "+5 attack damage\nThe chasm multiplies your voice"
	},
	{
		"id": "crystalline_spire",
		"name": "The Crystalline Spire",
		"flavor": "Light bends wrong here. The crystals remember being alive.",
		"tag": "REFRACTIVE",
		"potential_max_grade": "alpha",
		"modifier": {"type": "max_hp_bonus", "value": 35.0},
		"modifier_label": "+35 max HP\nThe spire teaches you to endure"
	},
	{
		"id": "whispering_marsh",
		"name": "The Whispering Marsh",
		"flavor": "The fog carries words you almost remember saying.",
		"tag": "HAUNTED",
		"potential_max_grade": "alpha",
		"modifier": {"type": "starting_support_charge", "value": 45.0},
		"modifier_label": "Bond starts 45% charged\nThe marsh remembers your promises"
	},
	{
		"id": "iron_boneyard",
		"name": "The Iron Boneyard",
		"flavor": "Metal still dreams of being weapons. The ground remembers impact.",
		"tag": "FORGED",
		"potential_max_grade": "alpha",
		"modifier": {"type": "attack_bonus", "value": 4.0},
		"modifier_label": "+4 attack damage\nThe boneyard sharpens your edge"
	},
	{
		"id": "sunken_library",
		"name": "The Sunken Library",
		"flavor": "Books float like jellyfish. Knowledge dissolves in water.",
		"tag": "DISSOLVED",
		"potential_max_grade": "alpha",
		"modifier": {"type": "max_hp_bonus", "value": 25.0},
		"modifier_label": "+25 max HP\nThe library preserves what matters"
	}
]
