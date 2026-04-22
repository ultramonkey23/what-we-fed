extends RefCounted

const CARRY_LIMIT: int = 2
const PREPARED_LIMIT: int = 1

const RITUAL_ORDER: Array[String] = [
	"blood_overclock",
	"iron_veil",
	"cadence_incense",
	"hollow_oath",
	"gorge_feast",
	"void_salve"
]

const RITUALS := {
	"blood_overclock": {
		"id": "blood_overclock",
		"lane": "consumable",
		"lane_slot": "carry",
		"category": "ritual",
		"title": "Blood Overclock",
		"tag": "RITUAL • OFFENSE",
		"summary": "Next encounter: instant +42 support charge.",
		"claim_text": "OVERCLOCKED",
		"power_tier": 2,
		"family_bias": ["flesh", "gorge"],
		"path_bias": "eat",
		"tendency_bias": ["aggression"],
		"effect": {
			"type": "encounter_start_support_charge",
			"value": 42.0
		}
	},
	"iron_veil": {
		"id": "iron_veil",
		"lane": "consumable",
		"lane_slot": "carry",
		"category": "ritual",
		"title": "Iron Veil",
		"tag": "RITUAL • GUARD",
		"summary": "Next encounter: guard surge for 2 hits.",
		"claim_text": "VEIL RAISED",
		"power_tier": 2,
		"family_bias": ["guard", "hollow"],
		"path_bias": "bond",
		"tendency_bias": ["guard"],
		"effect": {
			"type": "encounter_start_guard_surge",
			"value": 2.0
		}
	},
	"cadence_incense": {
		"id": "cadence_incense",
		"lane": "consumable",
		"lane_slot": "carry",
		"category": "ritual",
		"title": "Cadence Incense",
		"tag": "RITUAL • CADENCE",
		"summary": "Next encounter: flow surge for 12s.",
		"claim_text": "FLOW SET",
		"power_tier": 2,
		"family_bias": ["cadence", "reflex"],
		"path_bias": "neutral",
		"tendency_bias": ["cadence"],
		"effect": {
			"type": "encounter_start_cadence_surge",
			"value": 12.0
		}
	},
	"hollow_oath": {
		"id": "hollow_oath",
		"lane": "consumable",
		"lane_slot": "carry",
		"category": "ritual",
		"title": "Hollow Oath",
		"tag": "RITUAL • BOND",
		"summary": "Next encounter: mend 12 + support +22.",
		"claim_text": "OATH TAKEN",
		"power_tier": 3,
		"family_bias": ["hollow", "guard", "hush"],
		"path_bias": "bond",
		"tendency_bias": ["bond", "guard"],
		"effect": {
			"type": "encounter_start_mend_and_charge",
			"heal_value": 12.0,
			"support_charge": 22.0
		}
	},
	"gorge_feast": {
		"id": "gorge_feast",
		"lane": "consumable",
		"lane_slot": "carry",
		"category": "ritual",
		"title": "Gorge Feast",
		"tag": "RITUAL • PREDATION",
		"summary": "Next encounter: aggression surge for 3 hits.",
		"claim_text": "FEAST MARKED",
		"power_tier": 3,
		"family_bias": ["gorge", "flesh"],
		"path_bias": "eat",
		"tendency_bias": ["aggression"],
		"effect": {
			"type": "encounter_start_aggression_surge",
			"value": 3.0
		}
	},
	"void_salve": {
		"id": "void_salve",
		"lane": "consumable",
		"lane_slot": "carry",
		"category": "ritual",
		"title": "Void Salve",
		"tag": "RITUAL • RECOVERY",
		"summary": "Next encounter: clutch heal triggers once immediately.",
		"claim_text": "SALVE APPLIED",
		"power_tier": 2,
		"family_bias": ["guard", "hollow", "hush"],
		"path_bias": "bond",
		"tendency_bias": ["guard", "bond"],
		"effect": {
			"type": "encounter_start_clutch_mend",
			"value": 10.0
		}
	}
}


static func get_ritual(ritual_id: String) -> Dictionary:
	if not RITUALS.has(ritual_id):
		return {}
	return RITUALS[ritual_id].duplicate(true)


static func get_all_rituals() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for ritual_id in RITUAL_ORDER:
		rows.append(get_ritual(ritual_id))
	return rows
