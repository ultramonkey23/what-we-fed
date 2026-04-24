extends RefCounted

# Path map node definitions for between-level run authorship.
# Level indices are zero-based (0..8 regular levels).

const NODE_PREY: Dictionary = {
	"id": "prey",
	"display_name": "Prey",
	"tag": "BASELINE",
	"summary": "Baseline hunt pressure. No extra modifiers.",
	"entry_cost": {},
	"risk_modifier": {},
	"potential_reward_bias": "SAFE: low pressure, sparse reward",
	"encounter_options": {},
	"reward_context": {}
}

const NODE_ELITE_HUNT: Dictionary = {
	"id": "elite_hunt",
	"display_name": "Elite Hunt",
	"tag": "RISK",
	"summary": "Harder pressure profile, stronger evolution pull.",
	"entry_cost": {"type": "hp", "value": 15},
	"risk_modifier": {
		"id": "frenzied_spawns",
		"display_name": "HAUNTED",
		"summary": "Frenzied spawns press lanes sooner.",
		"difficulty_modifiers": {
			"threat_cadence": {"cycle_interval_mult": 0.94},
			"lane_pressure": {"respawn_delay_mult": 0.86, "max_active_threats_bonus": 1}
		}
	},
	"potential_reward_bias": "PREDATION: high Alpha sightings",
	"encounter_options": {
		"elite": true,
		"enemy_hp_mult": 1.18,
		"enemy_damage_mult": 1.12,
		"cycle_interval_mult": 0.92,
		"max_active_threats_bonus": 1
	},
	"reward_context": {
		"elite_reward_tier": true
	}
}

const NODE_BOND_RITE: Dictionary = {
	"id": "bond_rite",
	"display_name": "Bond Rite",
	"tag": "BOND",
	"summary": "Strengthen a kept bond and bias rewards toward support identity.",
	"entry_cost": {"type": "dna", "species": "ashclaw", "value": 50},
	"risk_modifier": {
		"id": "fog_blinded_lanes",
		"display_name": "FOG",
		"summary": "Lane tells arrive under muted visibility.",
		"difficulty_modifiers": {
			"punish_severity": {"projectile_damage_mult": 1.06}
		}
	},
	"potential_reward_bias": "BOND: support growth signal",
	"encounter_options": {},
	"reward_context": {
		"bond_flavored": true
	},
	"entry_effects": {
		"support_floor": 38.0,
		"bond_level_gain": 1
	}
}

const NODE_PREDATION_POOL: Dictionary = {
	"id": "predation_pool",
	"display_name": "Predation Pool",
	"tag": "DNA",
	"summary": "Route this level through DNA-authored predation offers.",
	"entry_cost": {"type": "hp", "value": 10},
	"risk_modifier": {
		"id": "blood_scent",
		"display_name": "SCENT",
		"summary": "Richer creature traces draw tougher bodies.",
		"difficulty_modifiers": {
			"threat_quality": {"high_grade_weight_mult": 1.16}
		}
	},
	"potential_reward_bias": "PREDATION: high DNA density",
	"encounter_options": {},
	"reward_context": {
		"predation_pool": true
	}
}

const NODE_BOSS: Dictionary = {
	"id": "boss",
	"display_name": "Boss",
	"tag": "APEX",
	"summary": "Terminal movement.",
	"entry_cost": {},
	"risk_modifier": {},
	"potential_reward_bias": "APEX: terminal claim",
	"encounter_options": {},
	"reward_context": {}
}

const NODE_WHISPER: Dictionary = {
	"id": "whisper",
	"display_name": "Whisper",
	"tag": "VOICE",
	"summary": "A moment of stillness. The world speaks directly to the Codex.",
	"entry_cost": {},
	"risk_modifier": {},
	"potential_reward_bias": "NARRATIVE: fate resonance",
	"encounter_options": {"is_event": true, "event_type": "narrative"},
	"reward_context": {"is_event": true}
}

const NODE_EXCHANGE: Dictionary = {
	"id": "exchange",
	"display_name": "Exchange",
	"tag": "TRADE",
	"summary": "A Remnant Merchant offers rare grafts for your stored DNA.",
	"entry_cost": {},
	"risk_modifier": {},
	"potential_reward_bias": "TRADE: graft/resource swap",
	"encounter_options": {"is_event": true, "event_type": "trade"},
	"reward_context": {"is_event": true}
}

const NODES_BY_ID: Dictionary = {
	"prey": NODE_PREY,
	"elite_hunt": NODE_ELITE_HUNT,
	"bond_rite": NODE_BOND_RITE,
	"predation_pool": NODE_PREDATION_POOL,
	"boss": NODE_BOSS,
	"whisper": NODE_WHISPER,
	"exchange": NODE_EXCHANGE
}

const DEFAULT_NODE_ID: String = "prey"

# Branch slot map:
# after L3 -> choose level index 3 (L4)
# after L6 -> choose level index 6 (L7)
# after L8 -> choose level index 8 (L9)
const BRANCH_CANDIDATES_BY_LEVEL_INDEX: Dictionary = {
	3: ["prey", "elite_hunt", "bond_rite"],
	6: ["prey", "elite_hunt", "predation_pool"],
	8: ["prey", "bond_rite", "predation_pool"]
}


static func get_node(node_id: String) -> Dictionary:
	var resolved_id: String = node_id if NODES_BY_ID.has(node_id) else DEFAULT_NODE_ID
	return Dictionary(NODES_BY_ID[resolved_id]).duplicate(true)


static func get_branch_candidates(level_index: int) -> Array[Dictionary]:
	if not BRANCH_CANDIDATES_BY_LEVEL_INDEX.has(level_index):
		return []
	var out: Array[Dictionary] = []
	var ids: Array = BRANCH_CANDIDATES_BY_LEVEL_INDEX[level_index]
	for raw_id in ids:
		var node_id: String = String(raw_id)
		out.append(get_node(node_id))
	return out
