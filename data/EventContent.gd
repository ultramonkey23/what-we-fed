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
