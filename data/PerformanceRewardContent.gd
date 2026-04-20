extends RefCounted

const RUN_THRESHOLDS: Array[float] = [180.0, 430.0, 770.0, 1150.0]
const OFFER_DURATION: float = 9.5
const PHRASE_PROGRESS_BONUS := {
	3: 8.0,
	5: 14.0,
	8: 22.0
}
const EXTENDED_PHRASE_PROGRESS_BONUS: float = 10.0
const TIER_PROGRESS_BONUS := {
	"stirring": 0.0,
	"hunting": 6.0,
	"rampage": 10.0,
	"apex": 16.0,
	"sovereign": 24.0
}
const BOSS_PROGRESS_BONUS: float = 24.0
const REWARD_ORDER: Array[String] = [
	"graveslip_tendons",
	"bond_echo",
	"wound_hunger",
	"razor_wiring",
	"carrion_brand",
	"veilstrike_chain",
	"choir_hook",
	"flayed_vessel",
	"hollow_pact",
	"predators_debt"
]
const PHASE_REWARD_MIXES: Array[Array] = [
	["graveslip_tendons", "bond_echo", "wound_hunger"],
	["razor_wiring", "veilstrike_chain", "carrion_brand"],
	["choir_hook", "hollow_pact", "predators_debt"]
]

# Per-affinity phase reward biases.
# Each entry maps a creature affinity → 3-phase preferred reward sequence.
# Phase 0 = early run, phase 1 = mid, phase 2 = late.
# These are priority hints: the director tries the listed rewards first,
# then falls back to REWARD_ORDER for anything not yet offered.
# All 10 rewards remain available across a full run regardless of affinity.
const AFFINITY_PHASE_MIXES: Dictionary = {
	# flesh (Ashclaw, Thornback, Gorefane): aggressive, damage-forward, kill-driven
	"flesh": [
		["wound_hunger", "carrion_brand", "graveslip_tendons"],
		["razor_wiring", "flayed_vessel", "veilstrike_chain"],
		["predators_debt", "choir_hook", "hollow_pact"]
	],
	# hollow (Bond Remnant): bond-forward, defensive, sustained support
	"hollow": [
		["bond_echo", "graveslip_tendons", "hollow_pact"],
		["choir_hook", "wound_hunger", "carrion_brand"],
		["razor_wiring", "veilstrike_chain", "predators_debt"]
	],
	# gorge (Gruvek, Siltgrip): kill-chain predation, feed-forward economy
	"gorge": [
		["carrion_brand", "wound_hunger", "graveslip_tendons"],
		["flayed_vessel", "razor_wiring", "bond_echo"],
		["predators_debt", "choir_hook", "hollow_pact"]
	],
	# reflex (Veilskin): parry-precision, counter-strike timing
	"reflex": [
		["graveslip_tendons", "veilstrike_chain", "choir_hook"],
		["razor_wiring", "wound_hunger", "bond_echo"],
		["flayed_vessel", "carrion_brand", "predators_debt"]
	],
	# cadence (Knellspine, Coldvein): timing mastery, on-beat momentum
	"cadence": [
		["veilstrike_chain", "graveslip_tendons", "bond_echo"],
		["choir_hook", "razor_wiring", "wound_hunger"],
		["hollow_pact", "carrion_brand", "predators_debt"]
	],
	# guard (Marrowward): survival-forward, dodge-reactive, bond-sustained
	"guard": [
		["graveslip_tendons", "bond_echo", "hollow_pact"],
		["choir_hook", "wound_hunger", "carrion_brand"],
		["razor_wiring", "veilstrike_chain", "flayed_vessel"]
	],
	# hush (Hushcoil): control, suppression, parry-adjacent bond payoff
	"hush": [
		["bond_echo", "choir_hook", "graveslip_tendons"],
		["hollow_pact", "veilstrike_chain", "wound_hunger"],
		["razor_wiring", "carrion_brand", "predators_debt"]
	]
}

const REWARDS := {
	# ── existing 4 ───────────────────────────────────────────────────────
	"razor_wiring": {
		"id": "razor_wiring",
		"category": "weapon",
		"title": "Razor Wiring",
		"tag": "WEAPON",
		"summary": "Timed hit +6",
		"readout": "Timed +6",
		"claim_text": "RAZOR WIRING",
		"feedback_color": Color(0.98, 0.70, 0.34, 1.0),
		"effect": {
			"type": "timed_attack_bonus_flat",
			"value": 6.0
		}
	},
	"carrion_brand": {
		"id": "carrion_brand",
		"category": "artifact",
		"title": "Carrion Brand",
		"tag": "ARTIFACT",
		"summary": "3 kills: mend + charge",
		"readout": "3 kills mend",
		"claim_text": "CARRION BRAND",
		"feedback_color": Color(0.90, 0.58, 0.30, 1.0),
		"effect": {
			"type": "kill_chain_pulse",
			"kills_required": 3,
			"heal_value": 4.0,
			"support_charge": 12.0
		}
	},
	"graveslip_tendons": {
		"id": "graveslip_tendons",
		"category": "utility",
		"title": "Graveslip Tendons",
		"tag": "UTILITY",
		"summary": "Low HP hit: mend +18 stamina",
		"readout": "Clutch mend",
		"claim_text": "GRAVESLIP",
		"feedback_color": Color(0.60, 0.84, 1.0, 1.0),
		"effect": {
			"type": "low_hp_clutch",
			"hp_threshold": 0.45,
			"heal_value": 5.0,
			"stamina_value": 18.0
		}
	},
	"choir_hook": {
		"id": "choir_hook",
		"category": "artifact",
		"title": "Choir Hook",
		"tag": "ARTIFACT",
		"summary": "Perfect parry +16 support",
		"readout": "Parry +16 sup",
		"claim_text": "CHOIR HOOK",
		"feedback_color": Color(0.86, 0.88, 0.40, 1.0),
		"effect": {
			"type": "perfect_parry_support_charge",
			"value": 16.0
		}
	},
	# ── 6 new rewards ────────────────────────────────────────────────────
	# Flesh / aggression: heavy kill-chain burst — rewards relentless offense
	"flayed_vessel": {
		"id": "flayed_vessel",
		"category": "weapon",
		"title": "Flayed Vessel",
		"tag": "FLESH",
		"summary": "5 kills: mend 8 + charge 25",
		"readout": "5 kills surge",
		"claim_text": "VESSEL FEEDS",
		"feedback_color": Color(0.96, 0.48, 0.28, 1.0),
		"effect": {
			"type": "kill_chain_heavy",
			"kills_required": 5,
			"heal_value": 8.0,
			"support_charge": 25.0
		}
	},
	# Flesh / aggression: wound-to-power — taking damage fuels the bond charge
	"wound_hunger": {
		"id": "wound_hunger",
		"category": "weapon",
		"title": "Wound Hunger",
		"tag": "FLESH",
		"summary": "Hit taken: +8 support charge",
		"readout": "Wound feeds",
		"claim_text": "HUNGER RISES",
		"feedback_color": Color(0.92, 0.40, 0.36, 1.0),
		"effect": {
			"type": "damage_to_charge",
			"value": 8.0
		}
	},
	# Bond / support: support echo — bonded creature trigger heals the player
	"bond_echo": {
		"id": "bond_echo",
		"category": "artifact",
		"title": "Bond Echo",
		"tag": "BOND",
		"summary": "Support trigger: mend 5",
		"readout": "Support mend 5",
		"claim_text": "BOND ANSWERS",
		"feedback_color": Color(0.58, 0.82, 0.92, 1.0),
		"effect": {
			"type": "support_trigger_heal",
			"value": 5.0
		}
	},
	# Bond / support + bond-eat consequence: pact pulse — bond kept gives encounter-start burst
	"hollow_pact": {
		"id": "hollow_pact",
		"category": "artifact",
		"title": "Hollow Pact",
		"tag": "BOND",
		"summary": "Bond kept: encounter start mend 8 + charge 15",
		"readout": "Bond entry pulse",
		"claim_text": "PACT HOLDS",
		"feedback_color": Color(0.62, 0.78, 0.98, 1.0),
		"effect": {
			"type": "bond_entry_pulse",
			"heal_value": 8.0,
			"support_charge": 15.0
		}
	},
	# Cadence / precision: perfect-attack streak — 3 perfect attacks in a row → charge burst
	"veilstrike_chain": {
		"id": "veilstrike_chain",
		"category": "artifact",
		"title": "Veilstrike Chain",
		"tag": "CADENCE",
		"summary": "3 perfect attacks in sequence: charge 20",
		"readout": "3 perfect chain",
		"claim_text": "CHAIN FIRES",
		"feedback_color": Color(0.78, 0.94, 0.62, 1.0),
		"effect": {
			"type": "perfect_strike_chain",
			"streak_required": 3,
			"support_charge": 20.0
		}
	},
	# DNA / species-aware + eat consequence: ratchet — each eat this run grants permanent +2 damage
	"predators_debt": {
		"id": "predators_debt",
		"category": "weapon",
		"title": "Predator's Debt",
		"tag": "FLESH",
		"summary": "Eat this run: damage +2 (max 3 stacks)",
		"readout": "Eat +dmg ratchet",
		"claim_text": "DEBT CLAIMED",
		"feedback_color": Color(0.88, 0.56, 0.72, 1.0),
		"effect": {
			"type": "eat_damage_ratchet",
			"damage_per_eat": 2.0,
			"max_stacks": 3
		}
	}
}


static func get_reward(reward_id: String) -> Dictionary:
	if not REWARDS.has(reward_id):
		return {}
	return REWARDS[reward_id].duplicate(true)


static func get_phase_mix(phase_index: int) -> Array[String]:
	if PHASE_REWARD_MIXES.is_empty():
		return REWARD_ORDER.duplicate()
	var clamped_index: int = clampi(phase_index, 0, PHASE_REWARD_MIXES.size() - 1)
	var mix: Array[String] = []
	for reward_id in PHASE_REWARD_MIXES[clamped_index]:
		mix.append(String(reward_id))
	return mix


# Returns an affinity-biased phase mix for the given creature affinity and phase.
# Falls back to the neutral PHASE_REWARD_MIXES when no affinity is active.
static func get_phase_mix_for_affinity(affinity: String, phase_index: int) -> Array[String]:
	var source_mixes: Array = AFFINITY_PHASE_MIXES.get(affinity, []) if not affinity.is_empty() else []
	if source_mixes.is_empty():
		return get_phase_mix(phase_index)
	var clamped_index: int = clampi(phase_index, 0, source_mixes.size() - 1)
	var mix: Array[String] = []
	for reward_id in source_mixes[clamped_index]:
		mix.append(String(reward_id))
	return mix
