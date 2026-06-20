extends Node

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

# Blood-Ember / Bleed State
const BLEED_MAX_STACKS: int = 5
const BLEED_DAMAGE_AMP_PER_STACK: float = 0.10
var bleed_stacks: int = 0


func reset_to_base() -> void:
	# PERSISTENT TRUTH: Only Potential and Luck are Meta-Stats. 
	# They are preserved during this reset to allow for meta-progression impact.
	
	stat_vitality = 100.0 # Baseline for multiplicative scaling
	stat_power = BASE_DAMAGE
	stat_carapace = BASE_DEFENSE
	stat_endurance = 100.0
	stat_swiftness = 1.0
	stat_intelligence = 1.0
	stat_adaptability = 1.0
	bleed_stacks = 0
	
	recalculate_max_hp(0.0)
	hp = max_hp


func recalculate_max_hp(flat_bonus: float) -> void:
	# SOVEREIGN MATH: Max HP scales multiplicatively from a base of 100.
	# Vitality 100 = 100 HP. Vitality 200 = 200 HP.
	max_hp = BASE_MAX_HP * (stat_vitality / 100.0) + flat_bonus
	hp = min(hp, max_hp)


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


func get_bleed_vulnerability_multiplier() -> float:
	return 1.0 + (BLEED_DAMAGE_AMP_PER_STACK * bleed_stacks)


func _process(delta: float) -> void:
	# Flesh (Vitality) Passive Regeneration: 
	# Every 10 points above 100 base grants 0.5 HP/sec.
	# Optimization: Tick every 30 frames for non-combat background regen.
	# Since this is a core mechanic, we check CombatBus/GameState flags.
	if not RunState.is_in_combat and RunState.run_in_progress:
		if Engine.get_process_frames() % 30 == 0:
			if stat_vitality > 100.0:
				var regen_rate: float = (stat_vitality - 100.0) / 10.0 * 0.5
				if regen_rate > 0.0 and hp < max_hp:
					# Multiply by 30-frame delta equivalent
					hp = min(hp + regen_rate * delta * 30.0, max_hp)


func get_power_level() -> float:
	var base: float = 0.0
	base += stat_vitality * 1.2
	base += stat_power * 8.0
	base += stat_carapace * 12.0
	base += stat_endurance * 2.5
	var mult: float = 1.0
	mult += (stat_swiftness - 1.0) * 5.0
	mult += (stat_luck - 1.0) * 3.0
	mult += (stat_potential - 1.0) * 12.0
	mult += (stat_intelligence - 1.0) * 6.0
	mult += (stat_adaptability - 1.0) * 8.0
	var final_power: float = base * mult
	var flicker: float = 1.0 + (randf() * 0.03 - 0.015)
	return max(final_power * flicker, 0.0)

