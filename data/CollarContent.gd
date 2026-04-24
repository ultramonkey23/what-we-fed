extends RefCounted

# CollarContent.gd
# Data definitions for ritual collars that shape support behavior.

const COLLARS := {
	"iron_doctrine": {
		"id": "iron_doctrine",
		"title": "Iron Doctrine",
		"description": "Increases support impact but doubles stamina cost.",
		"dna_unlock_cost": {"ashclaw": 50.0},
		"mod": {
			"support_impact_mult": 1.5,
			"stamina_cost_mult": 2.0
		}
	},
	"leash_of_mercy": {
		"id": "leash_of_mercy",
		"title": "Leash of Mercy",
		"description": "Support heal effects are 50% stronger.",
		"dna_unlock_cost": {"bond_remnant": 40.0},
		"mod": {
			"heal_mult": 1.5
		}
	},
	"predator_harness": {
		"id": "predator_harness",
		"title": "Predator Harness",
		"description": "Support attacks deal bonus damage to high-HP enemies.",
		"dna_unlock_cost": {"gruvek": 60.0},
		"mod": {
			"high_hp_bonus": 0.25
		}
	}
}

static func get_all_collars() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for id in COLLARS:
		list.append(COLLARS[id])
	return list

static func get_collar(collar_id: String) -> Dictionary:
	return COLLARS.get(collar_id, {})
