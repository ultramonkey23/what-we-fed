extends RefCounted

const SUPPORT_MAX: float = 100.0

const EXP_KILL: float = 10.0
const EXP_TIMED_ATTACK: float = 3.0
const EXP_GOOD_PARRY: float = 3.0
const EXP_PERFECT_PARRY: float = 6.0
const EXP_STYLE_MILESTONE: float = 5.0
const EXP_ULTIMATE: float = 4.0

const CHARGE_TIMED_ATTACK: float = 14.0
const CHARGE_GOOD_PARRY: float = 12.0
const CHARGE_PERFECT_PARRY: float = 24.0
const CHARGE_ENEMY_DEFEAT: float = 10.0
const GORGE_MARK_BONUS_CHARGE: float = 5.0  # Extra charge granted when a GORGE-MARK enemy is defeated
const CHARGE_ULTIMATE_SHARED_SURGE: float = 45.0
const CHARGE_CADENCE_BONUS: float = 15.0
const CHARGE_SURVIVAL_RECOVERY: float = 20.0

const LEVEL_THRESHOLDS: Array[float] = [40.0, 92.0, 150.0]

const UPGRADE_POOL: Array[Dictionary] = [
	{
		"id": "flesh_ravage",
		"title": "Ravage",
		"category": "Flesh",
		"summary": "Timed attacks rip the struck lane for bonus damage.",
		"effect": {"type": "timed_attack_bonus_damage", "value": 0.25}
	},
	{
		"id": "flesh_devour_warmth",
		"title": "Devour Warmth",
		"category": "Flesh",
		"summary": "Enemy defeats restore a little health.",
		"effect": {"type": "heal_on_kill", "value": 6.0}
	},
	{
		"id": "bond_surestep_pact",
		"title": "Surestep Pact",
		"category": "Bond",
		"summary": "Mastery actions fill support charge faster.",
		"effect": {"type": "support_charge_gain_mult", "value": 1.35}
	},
	{
		"id": "bond_shared_surge",
		"title": "Shared Surge",
		"category": "Bond",
		"summary": "Ultimate use feeds the bonded support meter.",
		"effect": {"type": "support_charge_on_ultimate", "value": 45.0}
	},
	{
		"id": "cadence_knife_between_beats",
		"title": "Knife Between Beats",
		"category": "Cadence",
		"summary": "Perfect timing grants bonus EXP and extra support charge.",
		"effect": {
			"type": "perfect_bonus_exp_and_charge",
			"exp_value": 3.0,
			"charge_value": 15.0
		}
	},
	{
		"id": "survival_hollow_shelter",
		"title": "Hollow Shelter",
		"category": "Survival",
		"summary": "The first hit each encounter partially mends itself and feeds support.",
		"effect": {
			"type": "first_hit_recovery",
			"heal_value": 6.0,
			"charge_value": 20.0
		}
	},
	{
		"id": "flesh_bloodrite",
		"title": "Bloodrite",
		"category": "Flesh",
		"summary": "Perfect timed attacks draw a fragment of life from the struck lane.",
		"effect": {"type": "hp_on_perfect_timed", "value": 2.0}
	},
	{
		"id": "flesh_hollow_feed",
		"title": "Hollow Feed",
		"category": "Flesh",
		"summary": "Consuming a creature feeds back into the flesh, restoring lost ground.",
		"effect": {"type": "eat_hp_restore", "value": 8.0}
	},
	{
		"id": "bond_pack_signal",
		"title": "Pack Signal",
		"category": "Bond",
		"summary": "Every bonded support activation restores a fragment of health.",
		"effect": {"type": "support_trigger_heal", "value": 10.0}
	},
	{
		"id": "bond_depth_pulse",
		"title": "Depth Pulse",
		"category": "Bond",
		"summary": "The bond runs deeper. Every mastery action sends a stronger signal.",
		"effect": {"type": "support_charge_flat_bonus", "value": 6.0}
	},
	{
		"id": "cadence_flow_state",
		"title": "Flow State",
		"category": "Cadence",
		"summary": "Consistent timing builds momentum. Good hits grow sharper.",
		"effect": {"type": "good_timed_bonus_damage", "value": 0.15}
	},
	{
		"id": "survival_pressure_mend",
		"title": "Pressure Mend",
		"category": "Survival",
		"summary": "The first wound taken while broken triggers a brief mending surge.",
		"effect": {"type": "low_hp_first_damage_heal", "value": 5.0}
	}
]
