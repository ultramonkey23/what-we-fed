extends RefCounted
class_name SovereignDamageCalculator

# Sovereign Stats Engine: the single seam where 9-stat ecosystem (PlayerState) meets combat math.
# Each public function names the compound stat interaction it owns. Add a new interaction here, not in PlayerCombat.

const PLAYER_STATE = preload("res://systems/state/PlayerState.gd")

# Timed attack ratios (kept in lockstep with prior PlayerCombat names: PLAYER_DAMAGE_TO_TIMED_RATIO, TIMED_ATTACK_DAMAGE_RATIO).
const TIMED_PLAYER_POWER_RATIO: float = 0.68
const TIMED_PROJECTILE_DAMAGE_RATIO: float = 0.50
const IDLE_DAMAGE_RATIO: float = 0.35
const LATE_DAMAGE_RATIO: float = 0.18

const PERFECT_TIMING_MULT: float = 1.35
const GOOD_TIMING_MULT: float = 1.15

const CARAPACE_CHIP_REDUCTION_PER_POINT: float = 0.01
const CARAPACE_CHIP_REDUCTION_CAP: float = 0.20
const CARAPACE_PARRY_FORGIVENESS_PER_POINT: float = 2.5
const CARAPACE_PARRY_FORGIVENESS_CAP: float = 22.0

const NERVE_RECOVERY_MIN_MULT: float = 0.40
const NERVE_RECOVERY_MAX_MULT: float = 2.0
const NERVE_ATTACK_RANGE_BASE: float = 112.0
const NERVE_ATTACK_RANGE_PER_POINT: float = 16.0
const NERVE_ATTACK_RANGE_CAP: float = 168.0
const NERVE_LUNGE_RANGE_MULT: float = 2.90
const NERVE_LUNGE_RANGE_CAP: float = 360.0
const FORM_TARGET_CAP_STEP: float = 0.75
const FORM_TARGET_CAP_MAX: int = 4
const EYE_TELEGRAPH_BIAS_CAP: float = 0.5

const VESSEL_BOND_TRAIT_WEIGHT: float = 0.65


# Maw (stat_power) compounds across every player attack path. Returns 1.0 at base power so default feel is preserved.
static func _get_maw_multiplier() -> float:
	var base_power: float = maxf(PLAYER_STATE.BASE_DAMAGE, 1.0)
	return maxf(GameState.stat_power / base_power, 0.1)


# Timed attack: Maw (stat_power) compounds; Form (stat_adaptability) multiplies; growth/phrase/beat/combo stack.
static func get_timed_attack_damage(
	projectile_damage: float,
	combo_mult: float,
	phrase_bonus: float,
	quality: String,
	beat_quality: String,
	growth_mult: float,
	timed_damage_flat_bonus: float,
	mutation_bonus: float
) -> float:
	var beat_mult: float = 1.0
	if quality == "perfect" and beat_quality == "perfect":
		beat_mult = PERFECT_TIMING_MULT
	elif beat_quality == "perfect" or beat_quality == "good":
		beat_mult = GOOD_TIMING_MULT

	var player_attack: float = GameState.get_attack_damage()
	var maw_mult: float = _get_maw_multiplier()
	var raw_damage: float = ((projectile_damage * TIMED_PROJECTILE_DAMAGE_RATIO) + (player_attack * TIMED_PLAYER_POWER_RATIO))
	var total: float = raw_damage * combo_mult * (1.0 + phrase_bonus) * beat_mult * growth_mult * GameState.stat_adaptability * maw_mult
	total += timed_damage_flat_bonus + mutation_bonus
	return maxf(total, 0.0)


# Idle / proximity attack: Maw compounds.
static func get_idle_attack_damage(combo_mult: float) -> float:
	var maw_mult: float = _get_maw_multiplier()
	return maxf(GameState.get_attack_damage() * IDLE_DAMAGE_RATIO * combo_mult * maw_mult, 0.0)


# Late attack (timing punish): Maw compounds, ratio is the punish.
static func get_late_attack_damage(combo_mult: float) -> float:
	var maw_mult: float = _get_maw_multiplier()
	return maxf(GameState.get_attack_damage() * LATE_DAMAGE_RATIO * combo_mult * maw_mult, 0.0)


# Parry reflect: projectile damage reflected with combo + bonded reflect bonus; Maw compounds.
static func get_parry_reflect_damage(projectile_damage: float, reflect_mult: float, combo_mult: float, reflect_bonus: float) -> float:
	var maw_mult: float = _get_maw_multiplier()
	return maxf(projectile_damage * reflect_mult * combo_mult * (1.0 + reflect_bonus) * maw_mult, 0.0)


# Ultimate: Maw + Form (stat_adaptability) compound on top of beat bonus + bonded ultimate bonus.
static func get_ultimate_damage(multiplier: float, beat_quality: String, bonded_ultimate_bonus: float) -> float:
	var beat_mult: float = 1.0
	if beat_quality == "perfect":
		beat_mult = 1.20
	elif beat_quality == "good":
		beat_mult = 1.10
	var maw_mult: float = _get_maw_multiplier()
	var damage: float = GameState.get_attack_damage() * multiplier * beat_mult * GameState.stat_adaptability * maw_mult
	return maxf(damage + bonded_ultimate_bonus, 0.0)


# Bone (stat_carapace) chip reduction: stacks ON TOP of base defense_damage_reduction; combined cap applied in get_incoming_damage_after_reduction.
static func get_carapace_chip_reduction() -> float:
	return clampf(GameState.stat_carapace * CARAPACE_CHIP_REDUCTION_PER_POINT, 0.0, CARAPACE_CHIP_REDUCTION_CAP)


# Incoming damage: base DR (defense + bonded passives) + carapace chip, capped, then surge DR multiplies.
static func get_incoming_damage_after_reduction(raw_damage: float, base_damage_reduction: float, surge_damage_reduction: float) -> float:
	var chip_reduction: float = get_carapace_chip_reduction()
	var total_reduction: float = clampf(base_damage_reduction + chip_reduction, 0.0, GameState.COMBINED_DAMAGE_REDUCTION_CAP)
	var post_guard: float = raw_damage * (1.0 - total_reduction)
	return maxf(post_guard * (1.0 - surge_damage_reduction), 0.0)


# Bone (stat_carapace) → parry forgiveness: carapace buys timing radius. Defense compounds into reading the beat.
static func get_parry_forgiveness_radius_bonus() -> float:
	return clampf(GameState.stat_carapace * CARAPACE_PARRY_FORGIVENESS_PER_POINT, 0.0, CARAPACE_PARRY_FORGIVENESS_CAP)


# Nerve (stat_swiftness) → action recovery: higher swiftness shrinks lock duration. Clamped so very high or low values cannot trivialize timing.
static func get_action_recovery_mult() -> float:
	return clampf(1.0 / maxf(GameState.stat_swiftness, 0.1), NERVE_RECOVERY_MIN_MULT, NERVE_RECOVERY_MAX_MULT)


# Nerve (stat_swiftness) → melee reach: starts short and grows slowly so early combat stays close and honest.
static func get_attack_range() -> float:
	var nerve_over_base: float = maxf(GameState.stat_swiftness - 1.0, 0.0)
	return clampf(NERVE_ATTACK_RANGE_BASE + nerve_over_base * NERVE_ATTACK_RANGE_PER_POINT, NERVE_ATTACK_RANGE_BASE, NERVE_ATTACK_RANGE_CAP)


# Nerve (stat_swiftness) → predatory lunge reach: a controlled extension of the actual attack range, not a separate giant cone.
static func get_predatory_lunge_range() -> float:
	return minf(get_attack_range() * NERVE_LUNGE_RANGE_MULT, NERVE_LUNGE_RANGE_CAP)


# Form (stat_adaptability) → simultaneous enemy contact: base 1 target, +1 only after substantial form growth.
static func get_attack_target_cap() -> int:
	var form_over_base: float = maxf(GameState.stat_adaptability - 1.0, 0.0)
	return clampi(1 + int(floor(form_over_base / FORM_TARGET_CAP_STEP)), 1, FORM_TARGET_CAP_MAX)


# Eye (stat_intelligence) → telegraph read: pressure_start is pulled earlier (capped 0.5). Reading the beat is bought with insight.
static func get_telegraph_eye_bias() -> float:
	return clampf(GameState.stat_intelligence - 1.0, 0.0, EYE_TELEGRAPH_BIAS_CAP)


# Bond level → trait expression: bonded creatures' Vessel traits scale with bond level (weighted, so unbonded = 1.0 baseline).
static func get_vessel_trait_multiplier(species_id: String, explicit_bond_level: int = -1) -> float:
	var bond_level: int = explicit_bond_level
	if bond_level < 0:
		var bonded: Dictionary = GameState.get_bonded_creature(species_id)
		if not bonded.is_empty():
			bond_level = int(bonded.get("bond_level", 1))
		else:
			bond_level = 1
	var bond_mult: float = GameState.get_bond_level_mult(bond_level)
	return 1.0 + (bond_mult - 1.0) * VESSEL_BOND_TRAIT_WEIGHT
