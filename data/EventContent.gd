extends RefCounted

# EventContent.gd
# Definitions for non-combat narrative and trade events.

const EVENT_TYPES = {
	"NARRATIVE": "narrative",
	"TRADE": "trade"
}

const EVENTS: Dictionary = {
	"whisper_of_the_hollow": {
		"id": "whisper_of_the_hollow",
		"type": EVENT_TYPES.NARRATIVE,
		"title": "A Hollow Echo",
		"body": "The wind in the Feeding Hollow carry words you almost remember saying. The ground vibrates with a slow, rhythmic hunger.",
		"choices": [
			{
				"id": "listen",
				"label": "Listen to the resonance",
				"summary": "Deepen the Mythic alignment of the world.",
				"effect": {"type": "fate_shift", "fate_id": "mythic_hopeful", "amount": 0.12}
			},
			{
				"id": "consume",
				"label": "Feed the ground DNA",
				"summary": "Offer 25 Ashclaw DNA to quiet the echo.",
				"cost": {"type": "dna", "species": "ashclaw", "value": 25},
				"effect": {"type": "fate_shift", "fate_id": "predatory_brutal", "amount": 0.08}
			}
		]
	},
	"whisper_of_the_shelf": {
		"id": "whisper_of_the_shelf",
		"type": EVENT_TYPES.NARRATIVE,
		"title": "A Stillness on the Shelf",
		"body": "The wind stops. The bones below hum with a faint, expectant vibration. You feel the weight of every kill you've ever made.",
		"choices": [
			{
				"id": "meditate",
				"label": "Meditate on the loss",
				"summary": "Shift the world toward a Haunted ritual.",
				"effect": {"type": "fate_shift", "fate_id": "haunted_ritual", "amount": 0.15}
			},
			{
				"id": "extract",
				"label": "Extract bone marrow",
				"summary": "Heal 20 HP but shift toward a Predatory fate.",
				"effect": {"type": "multi", "effects": [
					{"type": "hp_restore", "value": 20},
					{"type": "fate_shift", "fate_id": "predatory_brutal", "amount": 0.10}
				]}
			}
		]
	},
	"exchange_remnant_merchant": {
		"id": "exchange_remnant_merchant",
		"type": EVENT_TYPES.TRADE,
		"title": "The Remnant Merchant",
		"body": "A malformed creature drags a pile of glistening junk. It gestures toward your stored DNA with a hungry, wet clicking sound.",
		"choices": [
			{
				"id": "trade_dna_for_hp",
				"label": "Trade DNA for Vitality",
				"summary": "Exchange 40 DNA for a full heal.",
				"cost": {"type": "dna_any", "value": 40},
				"effect": {"type": "hp_restore_percent", "value": 1.0}
			},
			{
				"id": "trade_dna_for_attack",
				"label": "Trade DNA for Edge",
				"summary": "Exchange 60 DNA for permanent +2 Attack Damage.",
				"cost": {"type": "dna_any", "value": 60},
				"effect": {"type": "permanent_stat_gain", "stat": "player_base_damage", "value": 2.0}
			},
			{
				"id": "leave",
				"label": "Leave the merchant",
				"summary": "Walk away with your current holdings.",
				"effect": {"type": "none"}
			}
		]
	},
	"the_feeding_ground": {
		"id": "the_feeding_ground",
		"type": EVENT_TYPES.NARRATIVE,
		"title": "The Feeding Ground",
		"body": "Something large ate here recently. The bones are still warm. You can almost taste the hierarchy that ended in this clearing.",
		"choices": [
			{
				"id": "claim_the_territory",
				"label": "Mark this as yours",
				"summary": "Assert apex standing. World shifts toward Predatory Brutal.",
				"effect": {"type": "fate_shift", "fate_id": "predatory_brutal", "amount": 0.14}
			},
			{
				"id": "study_the_remains",
				"label": "Study what was killed",
				"summary": "Learn from the kill pattern. Gain permanent +1 Attack Damage.",
				"effect": {"type": "permanent_stat_gain", "stat": "player_base_damage", "value": 1.0}
			}
		]
	},
	"the_cataloguers_post": {
		"id": "the_cataloguers_post",
		"type": EVENT_TYPES.NARRATIVE,
		"title": "The Cataloguer's Post",
		"body": "A lattice of wire and membrane stretches between two dead trees. Something has been counting passages through here. A small slot awaits an offering.",
		"choices": [
			{
				"id": "submit_sample",
				"label": "Submit 35 DNA as a sample",
				"summary": "Comply with the system. Receive 30 HP. World shifts toward Sterile.",
				"cost": {"type": "dna_any", "value": 35},
				"effect": {"type": "multi", "effects": [
					{"type": "fate_shift", "fate_id": "sterile_technocratic", "amount": 0.12},
					{"type": "hp_restore", "value": 30}
				]}
			},
			{
				"id": "dismantle_the_post",
				"label": "Tear the apparatus down",
				"summary": "Reject the Sterile order. World shifts Predatory.",
				"effect": {"type": "fate_shift", "fate_id": "predatory_brutal", "amount": 0.08}
			}
		]
	},
	"the_weight_of_sequence": {
		"id": "the_weight_of_sequence",
		"type": EVENT_TYPES.NARRATIVE,
		"title": "The Weight of Sequence",
		"body": "A creature you once ate speaks through the soil. Not words — just the shape of what it wanted before the end. The haunting is not a curse. It is a ledger.",
		"choices": [
			{
				"id": "acknowledge_the_debt",
				"label": "Acknowledge the debt",
				"summary": "Sit with the memory. Deepen the Haunted ritual. Restore 15 HP.",
				"effect": {"type": "multi", "effects": [
					{"type": "fate_shift", "fate_id": "haunted_ritual", "amount": 0.15},
					{"type": "hp_restore", "value": 15}
				]}
			},
			{
				"id": "silence_the_echo",
				"label": "Push the memory down",
				"summary": "Pay 20 DNA to quiet the echo. Shifts Predatory.",
				"cost": {"type": "dna_any", "value": 20},
				"effect": {"type": "fate_shift", "fate_id": "predatory_brutal", "amount": 0.09}
			}
		]
	},
	"the_pale_extrusion": {
		"id": "the_pale_extrusion",
		"type": EVENT_TYPES.TRADE,
		"title": "The Pale Extrusion",
		"body": "A bulbous, almost-white organism has pushed itself halfway through the ground. It extends one glistening limb holding something useful. It seems to want to be fed.",
		"choices": [
			{
				"id": "trade_for_vitality",
				"label": "Feed it 45 DNA — receive full heal",
				"summary": "Exchange 45 DNA for complete HP restoration.",
				"cost": {"type": "dna_any", "value": 45},
				"effect": {"type": "hp_restore_percent", "value": 1.0}
			},
			{
				"id": "trade_for_edge",
				"label": "Feed it 60 DNA — receive a permanent edge",
				"summary": "Exchange 60 DNA for permanent +2 Attack Damage.",
				"cost": {"type": "dna_any", "value": 60},
				"effect": {"type": "permanent_stat_gain", "stat": "player_base_damage", "value": 2.0}
			},
			{
				"id": "leave_it",
				"label": "Leave it in the ground",
				"summary": "Walk on.",
				"effect": {"type": "none"}
			}
		]
	}
}

static func get_event(event_id: String) -> Dictionary:
	return Dictionary(EVENTS.get(event_id, {})).duplicate(true)

static func get_random_event_id_for_type(type: String) -> String:
	var candidates: Array[String] = []
	for eid in EVENTS.keys():
		if EVENTS[eid].get("type") == type:
			candidates.append(eid)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]
