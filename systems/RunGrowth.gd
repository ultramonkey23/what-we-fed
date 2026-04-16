extends Node

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")

var level: int = 1
var exp: float = 0.0
var exp_to_next: float = GROWTH_CONTENT.LEVEL_THRESHOLDS[0]
var support_charge: float = 0.0

var _pending_upgrade_offers: Array = []
var _encounter_style_tiers_awarded: Dictionary = {}
var _encounter_survival_spent: bool = false
var _encounter_pressure_mend_spent: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if not EventBus.run_started.is_connected(_on_run_started):
		EventBus.run_started.connect(_on_run_started)
	if not EventBus.combat_started.is_connected(_on_combat_started):
		EventBus.combat_started.connect(_on_combat_started)
	if not EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.connect(_on_enemy_defeated)
	if not EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	if not EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.connect(_on_player_parried)
	if not EventBus.combo_changed.is_connected(_on_combo_changed):
		EventBus.combo_changed.connect(_on_combo_changed)
	if not EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.connect(_on_ultimate_fired)
	if not EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.connect(_on_player_took_damage)
	if not EventBus.creature_bonded.is_connected(_on_creature_changed):
		EventBus.creature_bonded.connect(_on_creature_changed)
	if not EventBus.creature_eaten.is_connected(_on_creature_changed):
		EventBus.creature_eaten.connect(_on_creature_changed)
	if not EventBus.enemy_status_applied.is_connected(_on_enemy_status_applied):
		EventBus.enemy_status_applied.connect(_on_enemy_status_applied)
	_emit_growth_state()
	_emit_support_state()


func has_pending_level_up_offer() -> bool:
	return not _pending_upgrade_offers.is_empty()


func consume_pending_level_up_offer() -> Array:
	if _pending_upgrade_offers.is_empty():
		return []
	return _pending_upgrade_offers.pop_front()


func choose_upgrade(upgrade_id: String) -> Dictionary:
	for upgrade in GROWTH_CONTENT.UPGRADE_POOL:
		if String(upgrade.get("id", "")) == upgrade_id:
			GameState.add_upgrade(upgrade_id)
			EventBus.emit_signal("run_upgrade_taken", upgrade_id)
			_emit_growth_state()
			_emit_support_state()
			return upgrade
	return {}


func get_active_species_id() -> String:
	var creature: Dictionary = GameState.get_active_bonded_creature()
	return String(creature.get("species_id", ""))


func get_active_display_name() -> String:
	var creature: Dictionary = GameState.get_active_bonded_creature()
	if creature.is_empty():
		return "No Bond"
	var support_role: Dictionary = creature.get("support_role", {})
	return String(support_role.get("readout_name", creature.get("display_name", "No Bond")))


func _on_run_started(_run_number: int) -> void:
	level = 1
	exp = 0.0
	exp_to_next = GROWTH_CONTENT.LEVEL_THRESHOLDS[0]
	support_charge = 0.0
	# Apply starting_support_charge region modifier if the Drowned Cut is active.
	var region_mod: Dictionary = GameState.active_region.get("modifier", {})
	if region_mod.get("type", "") == "starting_support_charge":
		support_charge = clamp(float(region_mod.get("value", 0.0)), 0.0, GROWTH_CONTENT.SUPPORT_MAX)
	_pending_upgrade_offers.clear()
	_encounter_style_tiers_awarded.clear()
	_encounter_survival_spent = false
	_encounter_pressure_mend_spent = false
	_emit_growth_state()
	_emit_support_state()


func _on_combat_started(_enemy_data: Array) -> void:
	_encounter_style_tiers_awarded.clear()
	_encounter_survival_spent = false
	_encounter_pressure_mend_spent = false


func _on_enemy_defeated(_enemy_id: int) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_KILL)
	_gain_support_charge(GROWTH_CONTENT.CHARGE_ENEMY_DEFEAT)
	_trigger_active_support_for_event("enemy_defeated", 1)
	_apply_hp_on_kill_passive()


func _on_timed_attack_resolved(lane: int, quality: String, _damage: float) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_TIMED_ATTACK)
	_gain_support_charge(GROWTH_CONTENT.CHARGE_TIMED_ATTACK)

	if quality == "perfect":
		_apply_upgrade_effect_on_event("perfect_timing")
		_apply_upgrade_effect_on_event("perfect_timed_heal")
		_trigger_active_support_for_event("perfect_timed_attack", lane)


func _on_player_parried(lane: int, quality: String, _reflect_damage: float) -> void:
	match quality:
		"perfect":
			_grant_exp(GROWTH_CONTENT.EXP_PERFECT_PARRY)
			_gain_support_charge(GROWTH_CONTENT.CHARGE_PERFECT_PARRY)
			_apply_upgrade_effect_on_event("perfect_timing")
			_trigger_active_support_for_event("perfect_parry", lane)
		"good":
			_grant_exp(GROWTH_CONTENT.EXP_GOOD_PARRY)
			_gain_support_charge(GROWTH_CONTENT.CHARGE_GOOD_PARRY)


func _on_combo_changed(_count: int, tier: String) -> void:
	if tier == "stirring":
		return
	if _encounter_style_tiers_awarded.has(tier):
		return

	_encounter_style_tiers_awarded[tier] = true
	_grant_exp(GROWTH_CONTENT.EXP_STYLE_MILESTONE)


func _on_ultimate_fired(_power: float) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_ULTIMATE)
	_apply_upgrade_effect_on_event("ultimate_fired")


func _on_player_took_damage(_amount: float, source_lane: int) -> void:
	if not _encounter_survival_spent and _apply_upgrade_effect_on_event("first_damage_taken"):
		_encounter_survival_spent = true

	if not _encounter_pressure_mend_spent and GameState.get_hp_percent() < 0.50:
		if _apply_upgrade_effect_on_event("low_hp_first_hit"):
			_encounter_pressure_mend_spent = true

	_trigger_active_support_for_event("damage_taken_when_ready", source_lane)


func _on_creature_changed(_creature_data: Dictionary) -> void:
	_emit_support_state()


func _on_enemy_status_applied(_lane: int, status_id: String) -> void:
	# GORGE-MARK triggered: a marked enemy was defeated. Grant bonus support charge
	# (on top of the base CHARGE_ENEMY_DEFEAT already granted via enemy_defeated).
	if status_id == "gorge_mark_triggered":
		_gain_support_charge(GROWTH_CONTENT.GORGE_MARK_BONUS_CHARGE)


func _grant_exp(amount: float) -> void:
	if amount <= 0.0:
		return

	exp += amount
	while level - 1 < GROWTH_CONTENT.LEVEL_THRESHOLDS.size() and exp >= exp_to_next:
		exp -= exp_to_next
		level += 1
		_queue_upgrade_offer()
		if level - 1 < GROWTH_CONTENT.LEVEL_THRESHOLDS.size():
			exp_to_next = GROWTH_CONTENT.LEVEL_THRESHOLDS[level - 1]
		else:
			exp_to_next = GROWTH_CONTENT.LEVEL_THRESHOLDS[GROWTH_CONTENT.LEVEL_THRESHOLDS.size() - 1] + 70.0

	_emit_growth_state()


func _gain_support_charge(amount: float) -> void:
	if amount <= 0.0:
		return

	if get_active_species_id().is_empty():
		_emit_support_state()
		return

	var gain_mult: float = 1.0
	var gain_effect: Dictionary = _get_upgrade_effect("support_charge_gain_mult")
	if not gain_effect.is_empty():
		gain_mult = float(gain_effect.get("value", 1.0))

	var flat_bonus: float = 0.0
	var depth_effect: Dictionary = _get_upgrade_effect("support_charge_flat_bonus")
	if not depth_effect.is_empty():
		flat_bonus = float(depth_effect.get("value", 0.0))

	support_charge = clamp(support_charge + (amount + flat_bonus) * gain_mult, 0.0, GROWTH_CONTENT.SUPPORT_MAX)
	_emit_support_state()


func _trigger_support(species_id: String, lane: int, effect_id: String) -> void:
	if species_id.is_empty():
		return

	support_charge = 0.0
	_emit_support_state()
	EventBus.emit_signal("bonded_support_triggered", species_id, lane, effect_id)


func _is_support_ready() -> bool:
	return support_charge >= GROWTH_CONTENT.SUPPORT_MAX


func _trigger_active_support_for_event(event_id: String, lane: int) -> void:
	if not _is_support_ready():
		return

	var species_id: String = get_active_species_id()
	if species_id.is_empty():
		return

	var support_role: Dictionary = COMBAT_CONTENT.get_support_role(species_id)
	if support_role.is_empty():
		return

	var trigger_on: Array = support_role.get("trigger_on", [])
	if not trigger_on.has(event_id):
		return

	_trigger_support(species_id, lane, String(support_role.get("effect_id", "")))


func _queue_upgrade_offer() -> void:
	var offer: Array = _roll_upgrade_offer()
	if not offer.is_empty():
		_pending_upgrade_offers.append(offer)


func _roll_upgrade_offer() -> Array:
	var available: Array[Dictionary] = []
	for upgrade in GROWTH_CONTENT.UPGRADE_POOL:
		var upgrade_id: String = String(upgrade.get("id", ""))
		if not GameState.has_upgrade(upgrade_id):
			available.append(upgrade)

	var picks: Array = []
	while picks.size() < min(3, available.size()):
		var picked_upgrade: Dictionary = _pick_weighted_upgrade(available)
		if picked_upgrade.is_empty():
			break
		picks.append(picked_upgrade)

		for i in range(available.size()):
			if String(available[i].get("id", "")) == String(picked_upgrade.get("id", "")):
				available.remove_at(i)
				break

	return picks


func _pick_weighted_upgrade(candidates: Array[Dictionary]) -> Dictionary:
	if candidates.is_empty():
		return {}

	var total_weight: float = 0.0
	var weighted: Array[Dictionary] = []
	for upgrade in candidates:
		var category: String = String(upgrade.get("category", ""))
		var upgrade_id: String = String(upgrade.get("id", ""))
		var weight: float = 1.0
		if category == "Bond" and not GameState.roster.is_empty():
			weight += 0.35
		if category == "Flesh" and not GameState.absorbed_types.is_empty():
			weight += 0.35
		# Creature-synergy boosts: surface the upgrade most relevant to the active bond.
		var active: Dictionary = GameState.get_active_bonded_creature()
		var active_id: String = String(active.get("species_id", ""))
		if upgrade_id == "flesh_devour_warmth" and active_id == "gruvek":
			weight += 0.40
		if upgrade_id == "flesh_ravage" and active_id == "thornback":
			weight += 0.40
		if upgrade_id == "cadence_knife_between_beats" and active_id == "veilskin":
			weight += 0.40
		if upgrade_id == "flesh_bloodrite" and active_id == "thornback":
			weight += 0.40
		if upgrade_id == "flesh_hollow_feed" and active_id == "gruvek":
			weight += 0.40
		if upgrade_id == "bond_pack_signal" and (active_id == "veilskin" or active_id == "ashclaw"):
			weight += 0.40
		if upgrade_id == "bond_depth_pulse" and active_id == "bond_remnant":
			weight += 0.40

		total_weight += weight
		weighted.append({"upgrade": upgrade, "weight": weight})

	var roll: float = _rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for entry in weighted:
		cursor += float(entry.get("weight", 0.0))
		if roll <= cursor:
			return entry.get("upgrade", {})

	return weighted.back().get("upgrade", {})


func _get_upgrade_effect(effect_type: String) -> Dictionary:
	for upgrade in GROWTH_CONTENT.UPGRADE_POOL:
		var upgrade_id: String = String(upgrade.get("id", ""))
		if not GameState.has_upgrade(upgrade_id):
			continue

		var effect: Dictionary = upgrade.get("effect", {})
		if String(effect.get("type", "")) == effect_type:
			return effect

	return {}


func _apply_upgrade_effect_on_event(event_id: String) -> bool:
	match event_id:
		"perfect_timing":
			var cadence_effect: Dictionary = _get_upgrade_effect("perfect_bonus_exp_and_charge")
			if cadence_effect.is_empty():
				return false
			_grant_exp(float(cadence_effect.get("exp_value", 0.0)))
			_gain_support_charge(float(cadence_effect.get("charge_value", 0.0)))
			return true
		"ultimate_fired":
			var surge_effect: Dictionary = _get_upgrade_effect("support_charge_on_ultimate")
			if surge_effect.is_empty():
				return false
			_gain_support_charge(float(surge_effect.get("value", 0.0)))
			return true
		"first_damage_taken":
			var survival_effect: Dictionary = _get_upgrade_effect("first_hit_recovery")
			if survival_effect.is_empty():
				return false
			var healed: float = GameState.heal_player(float(survival_effect.get("heal_value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			_gain_support_charge(float(survival_effect.get("charge_value", 0.0)))
			return true
		"perfect_timed_heal":
			var bloodrite_effect: Dictionary = _get_upgrade_effect("hp_on_perfect_timed")
			if bloodrite_effect.is_empty():
				return false
			var healed: float = GameState.heal_player(float(bloodrite_effect.get("value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			return true
		"low_hp_first_hit":
			var mend_effect: Dictionary = _get_upgrade_effect("low_hp_first_damage_heal")
			if mend_effect.is_empty():
				return false
			var healed: float = GameState.heal_player(float(mend_effect.get("value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			return true
		_:
			return false


func _apply_hp_on_kill_passive() -> void:
	var creature: Dictionary = GameState.get_active_bonded_creature()
	if creature.is_empty():
		return
	var passive: Dictionary = creature.get("bond_passive", {})
	if passive.get("type", "") != "hp_on_kill":
		return
	var bond_mult: float = GameState.get_bond_level_mult(int(creature.get("bond_level", 1)))
	var healed: float = GameState.heal_player(float(passive.get("value", 0.0)) * bond_mult)
	if healed > 0.0:
		EventBus.emit_signal("player_healed", healed)


func _emit_growth_state() -> void:
	EventBus.emit_signal("run_growth_changed", level, exp, exp_to_next)


func _emit_support_state() -> void:
	EventBus.emit_signal("support_charge_changed", support_charge, GROWTH_CONTENT.SUPPORT_MAX, get_active_species_id())
