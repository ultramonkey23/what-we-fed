extends RefCounted
class_name PlayerState

const BASE_MAX_HP: float = 100.0
const BASE_DAMAGE: float = 15.0
const BASE_DEFENSE: float = 0.0
const DEFENSE_DAMAGE_REDUCTION_PER_POINT: float = 0.02
const DEFENSE_DAMAGE_REDUCTION_CAP: float = 0.30

var hp: float = 100.0
var max_hp: float = 100.0
var base_damage: float = 15.0
var defense: float = 0.0

# 9 Ecosystem Stats (Biomass Surge)
var stat_vitality: float = 100.0       # Flesh: Max HP
var stat_power: float = 15.0           # Maw: Base Damage
var stat_carapace: float = 0.0         # Bone: Defense
var stat_endurance: float = 100.0      # Lung: Max Stamina
var stat_swiftness: float = 1.0        # Nerve: Action Recovery Speed Mult (1.0 = normal)
var stat_luck: float = 1.0             # Omen: Reward/Anomaly Rarity Mult
var stat_potential: float = 1.0        # Hollow: EXP/Tendency/DNA Efficiency Mult
var stat_intelligence: float = 1.0     # Eye: Support Charge & Telegraph Read Mult
var stat_adaptability: float = 1.0     # Form: Timed Attack & Combo Armor Mult


func reset_to_base() -> void:
	stat_vitality = BASE_MAX_HP
	stat_power = BASE_DAMAGE
	stat_carapace = BASE_DEFENSE
	stat_endurance = 100.0
	stat_swiftness = 1.0
	stat_luck = 1.0
	stat_potential = 1.0
	stat_intelligence = 1.0
	stat_adaptability = 1.0
	
	max_hp = stat_vitality
	base_damage = stat_power
	defense = stat_carapace
	hp = max_hp


func heal(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var mended_amount: float = amount * stat_adaptability
	var before: float = hp
	hp = min(hp + mended_amount, max_hp)
	return hp - before

func get_hp_percent() -> float:
	if max_hp <= 0.0: return 0.0
	return hp / max_hp

func get_defense_damage_reduction() -> float:
	if defense <= 0.0:
		return 0.0
	return min(defense * DEFENSE_DAMAGE_REDUCTION_PER_POINT, DEFENSE_DAMAGE_REDUCTION_CAP)

func get_attack_damage(absorbed_types: Array) -> float:
	var total_damage: float = base_damage
	for entry in absorbed_types:
		if entry.has("damage_bonus"):
			total_damage += float(entry["damage_bonus"])
	return total_damage
