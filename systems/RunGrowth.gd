extends Node

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")

@onready var growth_stats: GrowthStats = preload("res://data/GrowthStats.gd").new()

# Modular Managers
var progression := ProgressionManager.new()
var tendencies := TendencyManager.new()
var support := SupportManager.new()

# API Proxies
var level: int:
	get: return progression.level
	set(v): progression.level = v
var current_exp: float:
	get: return progression.current_exp
	set(v): progression.current_exp = v
var exp_to_next: float:
	get: return progression.exp_to_next
	set(v): progression.exp_to_next = v
var support_charge: float:
	get: return support.charge
	set(v): support.charge = v
var tendency_points: Dictionary:
	get: return tendencies.points
	set(v): tendencies.points = v
var tendency_levels: Dictionary:
	get: return tendencies.levels
	set(v): tendencies.levels = v
var dna_routing_preference: String:
	get: return progression.dna_routing_preference
	set(v): progression.dna_routing_preference = v

var active_surges: Dictionary:
	get: return tendencies.active_surges
	set(v): tendencies.active_surges = v

var mutations: Array[Dictionary] = []
var pending_bonds: Array[String] = []

var _encounter_style_tiers_awarded: Dictionary[String, bool] = {}
var _encounter_survival_spent: bool = false
var _encounter_pressure_mend_spent: bool = false
var _level_bonus_base_damage: float = 0.0
var _level_bonus_max_hp: float = 0.0
var _level_bonus_defense: float = 0.0


func _ready() -> void:
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
	if not EventBus.creature_bonded.is_connected(_on_creature_bonded):
		EventBus.creature_bonded.connect(_on_creature_bonded)
	if not EventBus.creature_eaten.is_connected(_on_creature_changed):
		EventBus.creature_eaten.connect(_on_creature_changed)
	if not EventBus.enemy_status_applied.is_connected(_on_enemy_status_applied):
		EventBus.enemy_status_applied.connect(_on_enemy_status_applied)
	if not EventBus.player_dodged.is_connected(_on_player_dodged):
		EventBus.player_dodged.connect(_on_player_dodged)
	if not EventBus.bonded_support_triggered.is_connected(_on_bonded_support_triggered):
		EventBus.bonded_support_triggered.connect(_on_bonded_support_triggered)
	_emit_growth_state()
	_emit_support_state()
	_emit_dna_routing_state()
	_reset_tendencies()


func _exit_tree() -> void:
	# Cleanup connections...
	pass


func _process(delta: float) -> void:
	tendencies.process_surges(delta)


func get_active_species_id() -> String:
	var creature: Dictionary = GameState.get_active_bonded_creature()
	return String(creature.get("species_id", ""))


func get_active_display_name() -> String:
	var creature: Dictionary = GameState.get_active_bonded_creature()
	if creature.is_empty():
		return PRESENTATION_TEXT.SUPPORT_EMPTY_NAME
	var support_role: Dictionary = creature.get("support_role", {})
	return String(support_role.get("readout_name", creature.get("display_name", PRESENTATION_TEXT.SUPPORT_EMPTY_NAME)))


func get_tendency_summary() -> String:
	var tendency_tokens: Array[String] = []
	for surge_id in active_surges.keys():
		if active_surges[surge_id] > 0.0:
			var label: String = ""
			match surge_id:
				"aggression": label = "VENGEANCE"
				"cadence": label = "FLOW"
				"guard": label = "IRON"
				"bond": label = "SYNC"
			tendency_tokens.append(label)

	var ordered_ids: Array[String] = _sorted_tendency_ids_by_level()
	for i in range(min(2, ordered_ids.size())):
		var tendency_id: String = ordered_ids[i]
		var tendency_level: int = int(tendency_levels.get(tendency_id, 0))
		if tendency_level > 0:
			tendency_tokens.append("%s %d" % [_tendency_short_name(tendency_id), tendency_level])

	if not tendency_tokens.is_empty():
		return " | ".join(PackedStringArray(tendency_tokens))

	var lead_id: String = _get_leading_tendency_id()
	if lead_id.is_empty(): return "--"
	return _tendency_short_name(lead_id)


func get_runtime_effect(effect_type: String) -> Dictionary:
	match effect_type:
		"timed_attack_bonus_damage":
			var aggression_level: int = int(tendency_levels.get("aggression", 0))
			var surge_bonus: float = 0.25 if has_surge("aggression") else 0.0
			if aggression_level > 0 or surge_bonus > 0.0:
				return {"type": effect_type, "value": 0.12 * aggression_level + surge_bonus}
		"good_timed_bonus_damage":
			var cadence_level: int = int(tendency_levels.get("cadence", 0))
			if cadence_level > 0:
				return {"type": effect_type, "value": 0.12 * cadence_level}
		"support_charge_gain_mult":
			var bond_level: int = int(tendency_levels.get("bond", 0))
			var surge_mult: float = 2.0 if has_surge("cadence") else 1.0
			if bond_level > 0 or surge_mult > 1.0:
				return {"type": effect_type, "value": (1.0 + 0.12 * bond_level) * surge_mult}
		"guard_damage_reduction":
			if has_surge("guard"): return {"type": effect_type, "value": 0.50}
		"bond_trigger_mult":
			if has_surge("bond"): return {"type": effect_type, "value": 2.0}
	return {}


func get_growth_effect(effect_type: String) -> Dictionary:
	return _get_growth_effect(effect_type)


func has_surge(surge_type: String) -> bool:
	return active_surges.get(surge_type, 0.0) > 0.0


func get_mutation_bonus(effect_type: String, context: Dictionary = {}) -> float:
	var total: float = 0.0
	var mutations_list: Array[Dictionary] = GameState.get_active_mutations_of_type(effect_type)
	for mut in mutations_list:
		var charges: int = int(mut.get("current_charges", 0))
		if charges <= 0: continue
		var effect: Dictionary = mut.get("effect", {})
		var req_quality: String = String(effect.get("required_quality", ""))
		if not req_quality.is_empty() and context.get("quality", "") != req_quality: continue
		total += float(effect.get("value", 0.0))
	return total


func consume_mutation_charges(effect_type: String, amount: int = 1, context: Dictionary = {}) -> void:
	var mutations_list: Array[Dictionary] = GameState.get_active_mutations_of_type(effect_type)
	for mut in mutations_list:
		var charges: int = int(mut.get("current_charges", 0))
		if charges <= 0: continue
		var effect: Dictionary = mut.get("effect", {})
		var req_quality: String = String(effect.get("required_quality", ""))
		if not req_quality.is_empty() and context.get("quality", "") != req_quality: continue
		var mut_id: String = String(mut.get("id", ""))
		if not bool(mut.get("feedback_fired", false)):
			EventBus.proc_feedback_requested.emit( mut.get("display_name", "MUTATION"), Color(0.85, 0.44, 0.18, 1.0))
			GameState.set_mutation_flag(mut_id, "feedback_fired", true)
		GameState.consume_mutation_charge(mut_id, amount)


func consume_surge_hit(surge_type: String) -> void:
	tendencies.consume_surge_hit(surge_type)


func get_growth_snapshot() -> Dictionary:
	var cadence_level: int = int(tendency_levels.get("cadence", 0))
	var bond_level: int = int(tendency_levels.get("bond", 0))
	return {
		"level": level, "exp": current_exp, "exp_to_next": exp_to_next,
		"base_damage": GameState.player_base_damage, "attack_damage": GameState.get_attack_damage(),
		"player_defense": GameState.player_defense, "player_defense_reduction": GameState.get_defense_damage_reduction(),
		"player_hp": GameState.player_hp, "player_max_hp": GameState.player_max_hp,
		"support_charge": support_charge, "support_max": GROWTH_CONTENT.SUPPORT_MAX,
		"dna_routing_preference": dna_routing_preference,
		"good_timed_bonus_damage_mult": 0.12 * cadence_level,
		"support_charge_gain_mult": 1.0 + 0.12 * bond_level
	}


func get_tendency_snapshot() -> Dictionary:
	return {
		"levels": tendency_levels.duplicate(true),
		"points": tendency_points.duplicate(true),
		"dna_routing_preference": dna_routing_preference
	}


func get_dna_routing_label() -> String:
	return PRESENTATION_TEXT.DNA_ROUTE_EXP_LABEL if dna_routing_preference == "exp" else PRESENTATION_TEXT.DNA_ROUTE_BOND_LABEL


func toggle_dna_routing_preference() -> String:
	dna_routing_preference = "exp" if dna_routing_preference == "bond" else "bond"
	_emit_dna_routing_state()
	return dna_routing_preference


func process_dna_gain(species_id: String, amount: float) -> Dictionary:
	if species_id.is_empty() or amount <= 0.0:
		return {"species_id": species_id, "amount": 0.0, "banked": false, "total": GameState.get_dna(species_id), "route_id": dna_routing_preference, "exp_gained": 0.0}

	if dna_routing_preference == "exp":
		var exp_gained: float = amount * GROWTH_CONTENT.DNA_EXP_PER_POINT
		_grant_exp(exp_gained)
		return {"species_id": species_id, "amount": amount, "banked": false, "total": GameState.get_dna(species_id), "route_id": dna_routing_preference, "exp_gained": exp_gained}

	GameState.add_dna(species_id, amount)
	var effective_threshold: float = GameState.get_effective_dna_threshold(species_id)
	var bond_ready: bool = false
	if not GameState.is_species_bonded(species_id) and GameState.get_dna(species_id) >= effective_threshold:
		if not pending_bonds.has(species_id):
			pending_bonds.append(species_id)
			EventBus.proc_feedback_requested.emit("BOND READY", Color(0.60, 0.84, 1.0, 1.0))
		bond_ready = true
		_grant_tendency("bond", 1.0)
	_gain_support_charge(amount * GROWTH_CONTENT.DNA_BOND_SUPPORT_CHARGE_PER_POINT)
	_grant_tendency("bond", amount * GROWTH_CONTENT.DNA_BOND_TENDENCY_PER_POINT)
	return {"species_id": species_id, "amount": amount, "banked": true, "total": GameState.get_dna(species_id), "route_id": dna_routing_preference, "exp_gained": 0.0, "bond_ready": bond_ready}


func _on_run_started(_run_number: int) -> void:
	progression.reset()
	support.reset()
	mutations.clear()
	pending_bonds.clear()
	_level_bonus_base_damage = 0.0
	_level_bonus_max_hp = 0.0
	_level_bonus_defense = 0.0
	tendencies.reset(growth_stats.default_surges)
	_refresh_primary_combat_stats(0.0)
	var region_mod: Dictionary = GameState.active_region.get("modifier", {})
	if region_mod.get("type", "") == "starting_support_charge":
		support_charge = clamp(float(region_mod.get("value", 0.0)), 0.0, GROWTH_CONTENT.SUPPORT_MAX)
	_encounter_style_tiers_awarded.clear()
	_encounter_survival_spent = false
	_encounter_pressure_mend_spent = false
	_emit_growth_state()
	_emit_support_state()
	_emit_dna_routing_state()


func _on_combat_started(_enemy_data: Array) -> void:
	_encounter_style_tiers_awarded.clear()
	_encounter_survival_spent = false
	_encounter_pressure_mend_spent = false
	_consume_prepared_ritual_on_encounter_start()


func _on_enemy_defeated(_enemy_id: int) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_KILL)
	var kill_charge: float = GROWTH_CONTENT.CHARGE_ENEMY_DEFEAT
	var charge_mult: float = get_mutation_bonus("support_charge_mult_on_kill")
	if charge_mult > 0.0:
		kill_charge *= charge_mult
		consume_mutation_charges("support_charge_mult_on_kill", 1)
	_gain_support_charge(kill_charge)
	var ult_gain: float = get_mutation_bonus("ultimate_on_kill")
	if ult_gain > 0.0:
		EventBus.ultimate_power_granted.emit(ult_gain)
		consume_mutation_charges("ultimate_on_kill", 1)
	if has_surge("aggression"):
		var healed: float = GameState.heal_player(4.0)
		if healed > 0.0: EventBus.player_healed.emit(healed)
	if GameState.active_region.get("id", "") == "drowned_cut":
		_gain_support_charge(GROWTH_CONTENT.CHARGE_ENEMY_DEFEAT * 0.75)
	_trigger_active_support_for_event("enemy_defeated", 1)
	_apply_hp_on_kill_passive()
	_grant_tendency("aggression", 1.0)


func _on_timed_attack_resolved(lane: int, quality: String, _damage: float) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_TIMED_ATTACK)
	_gain_support_charge(GROWTH_CONTENT.CHARGE_TIMED_ATTACK)
	var rend_charges: float = get_mutation_bonus("rend_on_hit", {"quality": quality})
	if rend_charges > 0.0:
		EventBus.enemy_status_applied_requested.emit(lane, "rend", {"charges": int(rend_charges)})
		consume_mutation_charges("rend_on_hit", 1, {"quality": quality})
	var heal_val: float = get_mutation_bonus("heal_on_hit", {"quality": quality})
	if heal_val > 0.0:
		var healed: float = GameState.heal_player(heal_val)
		if healed > 0.0: EventBus.player_healed.emit(healed)
		consume_mutation_charges("heal_on_hit", 1, {"quality": quality})
	if GameState.is_beat_active():
		var beat_charge: float = get_mutation_bonus("support_charge_on_beat")
		if beat_charge > 0.0:
			_gain_support_charge(beat_charge)
			consume_mutation_charges("support_charge_on_beat", 1)
	if has_surge("aggression"): consume_surge_hit("aggression")
	var cadence_gain: float = 0.5
	if quality == "good": cadence_gain = 1.0
	elif quality == "perfect": cadence_gain = 1.4
	_grant_tendency("cadence", cadence_gain)
	if quality == "perfect":
		_apply_upgrade_effect_on_event("perfect_timing")
		_apply_upgrade_effect_on_event("perfect_timed_heal")
		_trigger_active_support_for_event("perfect_timed_attack", lane)
	elif quality == "good": _trigger_active_support_for_event("good_timed_attack", lane)


func _on_player_parried(lane: int, quality: String, _reflect_damage: float) -> void:
	match quality:
		"perfect":
			_grant_exp(GROWTH_CONTENT.EXP_PERFECT_PARRY)
			_gain_support_charge(GROWTH_CONTENT.CHARGE_PERFECT_PARRY)
			_grant_tendency("guard", 1.2)
			_grant_tendency("cadence", 0.5)
			_apply_upgrade_effect_on_event("perfect_timing")
			_trigger_active_support_for_event("perfect_parry", lane)
		"good":
			_grant_exp(GROWTH_CONTENT.EXP_GOOD_PARRY)
			_gain_support_charge(GROWTH_CONTENT.CHARGE_GOOD_PARRY)
			_grant_tendency("guard", 0.8)


func _on_combo_changed(_count: int, tier: String) -> void:
	if tier == "stirring" or _encounter_style_tiers_awarded.has(tier): return
	_encounter_style_tiers_awarded[tier] = true
	_grant_exp(GROWTH_CONTENT.EXP_STYLE_MILESTONE)
	_grant_tendency("aggression", 0.4)
	_grant_tendency("cadence", 0.6)


func _on_ultimate_fired(_power: float) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_ULTIMATE)
	_apply_upgrade_effect_on_event("ultimate_fired")
	_trigger_active_support_for_event("ultimate_fired", 1)
	_grant_tendency("aggression", 1.4)


func _on_player_took_damage(_amount: float, source_lane: int) -> void:
	if has_surge("guard"): consume_surge_hit("guard")
	if not _encounter_survival_spent and _apply_upgrade_effect_on_event("first_damage_taken"): _encounter_survival_spent = true
	if not _encounter_pressure_mend_spent and GameState.get_hp_percent() < 0.50:
		if _apply_upgrade_effect_on_event("low_hp_first_hit"): _encounter_pressure_mend_spent = true
	_trigger_active_support_for_event("damage_taken_when_ready", source_lane)
	_grant_tendency("guard", 0.25)


func _on_creature_changed(creature_data: Dictionary) -> void:
	if not creature_data.get("eat_effect", {}).is_empty():
		mutations.append(creature_data)
		EventBus.emit_signal("screen_flash", Color(0.85, 0.22, 0.14, 0.08), 0.10)
	_emit_support_state()


func _on_creature_bonded(_creature_data: Dictionary) -> void:
	_emit_support_state()
	_grant_tendency("bond", 1.6)


func _on_enemy_status_applied(_lane: int, status_id: String) -> void:
	if status_id == "gorge_mark_triggered": _gain_support_charge(GROWTH_CONTENT.GORGE_MARK_BONUS_CHARGE)


func _on_player_dodged(_from_lane: int, _to_lane: int) -> void:
	_grant_tendency("guard", 0.55)
	_trigger_active_support_for_event("player_dodged", _to_lane)


func _on_bonded_support_triggered(_species_id: String, _lane: int, _effect_id: String) -> void:
	if has_surge("bond"): consume_surge_hit("bond")
	_grant_tendency("bond", 1.25)


func _grant_exp(amount: float) -> void:
	if progression.grant_exp(amount, GameState.stat_potential):
		_apply_real_time_growth_pulse()
	_emit_growth_state()


func _gain_support_charge(amount: float) -> void:
	if amount <= 0.0 or get_active_species_id().is_empty(): return
	var gain_mult: float = 1.0 * GameState.stat_intelligence
	var gain_effect: Dictionary = _get_growth_effect("support_charge_gain_mult")
	if not gain_effect.is_empty(): gain_mult *= float(gain_effect.get("value", 1.0))
	var synergy_bonus: float = 1.0
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	if not active_creature.is_empty():
		var p_type: String = String(active_creature.get("primary_type", ""))
		for eaten in GameState.absorbed_types:
			if String(eaten.get("type", "")) == p_type: synergy_bonus = 1.25; break
	var flat: float = float(_get_growth_effect("support_charge_flat_bonus").get("value", 0.0))
	support.gain_charge(amount + flat, gain_mult * synergy_bonus)
	_emit_support_state()


func _trigger_support(species_id: String, lane: int, effect_id: String) -> void:
	if species_id.is_empty(): return
	support.consume()
	_emit_support_state()
	EventBus.bonded_support_triggered.emit( species_id, lane, effect_id)


func _trigger_active_support_for_event(event_id: String, lane: int) -> void:
	if not support.is_ready(): return
	var species_id: String = get_active_species_id()
	if species_id.is_empty(): return
	var role: Dictionary = COMBAT_CONTENT.get_support_role(species_id)
	if role.is_empty() or not role.get("trigger_on", []).has(event_id): return
	_trigger_support(species_id, lane, String(role.get("effect_id", "")))


func _get_growth_effect(effect_type: String) -> Dictionary:
	var runtime: Dictionary = get_runtime_effect(effect_type)
	if not runtime.is_empty(): return runtime
	for upgrade in GROWTH_CONTENT.UPGRADE_POOL:
		if GameState.has_upgrade(String(upgrade.get("id", ""))) and String(upgrade.get("effect", {}).get("type", "")) == effect_type:
			return upgrade.get("effect", {})
	return {}


func _apply_upgrade_effect_on_event(event_id: String) -> bool:
	match event_id:
		"perfect_timing":
			var eff: Dictionary = _get_growth_effect("perfect_bonus_exp_and_charge")
			if eff.is_empty(): return false
			_grant_exp(float(eff.get("exp_value", 0.0)))
			_gain_support_charge(float(eff.get("charge_value", 0.0)))
			return true
		"ultimate_fired":
			var eff: Dictionary = _get_growth_effect("support_charge_on_ultimate")
			if eff.is_empty(): return false
			_gain_support_charge(float(eff.get("value", 0.0)))
			return true
		"first_damage_taken":
			var eff: Dictionary = _get_growth_effect("first_hit_recovery")
			if eff.is_empty(): return false
			var healed: float = GameState.heal_player(float(eff.get("heal_value", 0.0)))
			if healed > 0.0: EventBus.player_healed.emit(healed)
			_gain_support_charge(float(eff.get("charge_value", 0.0)))
			return true
		"perfect_timed_heal":
			var eff: Dictionary = _get_growth_effect("hp_on_perfect_timed")
			if eff.is_empty(): return false
			var healed: float = GameState.heal_player(float(eff.get("value", 0.0)))
			if healed > 0.0: EventBus.player_healed.emit(healed)
			return true
		"low_hp_first_hit":
			var eff: Dictionary = _get_growth_effect("low_hp_first_damage_heal")
			if eff.is_empty(): return false
			var healed: float = GameState.heal_player(float(eff.get("value", 0.0)))
			if healed > 0.0: EventBus.player_healed.emit(healed)
			return true
	return false


func _apply_hp_on_kill_passive() -> void:
	var creature: Dictionary = GameState.get_active_bonded_creature()
	if creature.is_empty(): return
	var passive: Dictionary = creature.get("bond_passive", {})
	if passive.get("type", "") != "hp_on_kill": return
	var mult: float = 1.0 + max(0, int(creature.get("bond_level", 1)) - 1) * 0.20
	var healed: float = GameState.heal_player(float(passive.get("value", 0.0)) * mult)
	if healed > 0.0: EventBus.player_healed.emit(healed)


func _emit_growth_state() -> void: EventBus.run_growth_changed.emit(level, current_exp, exp_to_next)
func _emit_support_state() -> void: EventBus.support_charge_changed.emit(support_charge, GROWTH_CONTENT.SUPPORT_MAX, get_active_species_id())
func _emit_dna_routing_state() -> void: EventBus.dna_routing_changed.emit(dna_routing_preference, get_dna_routing_label())


func gain_support_charge_direct(amount: float) -> void:
	support.gain_charge(amount, 1.0)
	_emit_support_state()


func gain_reward_support_charge(amount: float) -> void:
	_gain_support_charge(amount)


func apply_debug_state(state: Dictionary) -> void:
	if state.is_empty(): return
	print("[DEBUG] Applying debug state: ", state)
	level = max(int(state.get("level", level)), 1)
	current_exp = max(float(state.get("exp", current_exp)), 0.0)
	exp_to_next = progression.get_exp_threshold(level)
	for k in tendency_points.keys(): tendency_points[k] = float(state.get("tendency_points", {}).get(k, 0.0))
	for k in tendency_levels.keys(): tendency_levels[k] = max(int(state.get("tendency_levels", {}).get(k, 0)), 0)
	if state.has("support_charge"): support_charge = clamp(float(state.get("support_charge", support_charge)), 0.0, GROWTH_CONTENT.SUPPORT_MAX)
	_emit_growth_state(); _emit_support_state()
	print("[DEBUG] Applied state: level=", level, " exp=", current_exp, " support=", support_charge)


func _reset_tendencies() -> void: tendencies.reset(growth_stats.default_surges)
func _grant_tendency(id: String, amt: float) -> void: tendencies.grant_points(id, amt, GameState.stat_potential)
func _get_leading_tendency_id() -> String: return tendencies.get_leading_id(!get_active_species_id().is_empty())
func _sorted_tendency_ids_by_level() -> Array[String]: return tendencies.get_sorted_ids()


func _apply_real_time_growth_pulse() -> void:
	var id: String = _get_leading_tendency_id()
	if id.is_empty(): id = "aggression"
	var new_lvl: int = int(tendency_levels.get(id, 0)) + 1
	tendency_levels[id] = new_lvl
	tendency_points[id] = max(float(tendency_points.get(id, 0.0)) - 4.0, 0.0)
	var res: Dictionary = _resolve_tendency_level_up(id, new_lvl)
	if res.is_empty(): return
	_emit_growth_state(); _emit_support_state()
	EventBus.run_growth_level_resolved.emit(res)
	EventBus.tendency_growth_resolved.emit(id, String(res.get("title", "")), String(res.get("summary", "")))


func _resolve_tendency_level_up(id: String, lvl: int) -> Dictionary:
	var out: Dictionary = GROWTH_CONTENT.TENDENCY_LEVEL_UP_OUTCOMES.get(id, {})
	if out.is_empty(): return {}
	var changes: Array[Dictionary] = []
	var creature: Dictionary = GameState.get_active_bonded_creature()
	var weights: Dictionary = {"stat_potential": 10} if creature.is_empty() else {}
	if not creature.is_empty():
		var p_w: Dictionary = growth_stats.genetic_weights.get(creature.get("primary_type", ""), {})
		var s_w: Dictionary = growth_stats.genetic_weights.get(creature.get("secondary_type", ""), {})
		for k in p_w.keys(): weights[k] = weights.get(k, 0) + p_w[k]
		for k in s_w.keys(): weights[k] = weights.get(k, 0) + s_w[k]
	if weights.is_empty(): weights = {"stat_potential": 10}
	var keys: Array = weights.keys(); var total: int = 0
	for v in weights.values(): total += int(v)
	for i in range(3):
		var roll: int = randi() % total; var cur: int = 0
		for sid in keys:
			cur += int(weights[sid])
			if roll < cur: var gain: Dictionary = _apply_surge_stat_gain(sid); if not gain.is_empty(): changes.append(gain); break
	for eff in out.get("effects", []):
		var applied: Dictionary = _apply_level_up_effect(eff, lvl)
		if not applied.is_empty(): changes.append(applied)
	var res: Dictionary = {"level": level, "tendency_id": id, "tendency_level": lvl, "title": String(out.get("title", id.to_upper())), "readout_label": String(out.get("readout_label", id.capitalize())), "changes": changes, "snapshot": get_growth_snapshot()}
	res["summary"] = PRESENTATION_TEXT.tendency_level_up_summary(res)
	return res


func _apply_surge_stat_gain(sid: String) -> Dictionary:
	var label: String = sid.replace("stat_", "").to_upper(); var val: float = 0.0
	match sid:
		"stat_vitality": val = 10.0; GameState.stat_vitality += val; var h: float = _refresh_primary_combat_stats(val); if h > 0.0: EventBus.player_healed.emit(h)
		"stat_power": val = 2.0; GameState.stat_power += val; _refresh_primary_combat_stats(0.0)
		"stat_carapace": val = 1.0; GameState.stat_carapace += val; _refresh_primary_combat_stats(0.0)
		"stat_endurance": val = 15.0; GameState.stat_endurance += val
		"stat_swiftness": val = 0.04; GameState.stat_swiftness += val
		"stat_luck": val = 0.02; GameState.stat_luck += val
		"stat_potential": val = 0.05; GameState.stat_potential += val
		"stat_intelligence": val = 0.06; GameState.stat_intelligence += val
		"stat_adaptability": val = 0.04; GameState.stat_adaptability += val
		_: return {}
	return {"type": sid, "applied_value": val, "label": label}


func _apply_level_up_effect(eff: Dictionary, lvl: int) -> Dictionary:
	var type: String = String(eff.get("type", "")); var base: float = float(eff.get("value", 0.0))
	match type:
		"base_damage_flat": _level_bonus_base_damage += base; _refresh_primary_combat_stats(0.0); return {"type": type, "applied_value": base}
		"max_hp_flat": _level_bonus_max_hp += base; var h: float = _refresh_primary_combat_stats(base * 0.5); if h > 0.0: EventBus.player_healed.emit(h); return {"type": type, "applied_value": base}
		"defense_flat": _level_bonus_defense += base; _refresh_primary_combat_stats(0.0); return {"type": type, "applied_value": base}
		"heal_now": var h: float = GameState.heal_player(base); if h > 0.0: EventBus.player_healed.emit(h); return {"type": type, "applied_value": h}
		"support_charge_now": var b: float = support_charge; _gain_support_charge(base); return {"type": type, "applied_value": support_charge - b}
		"good_timed_bonus_damage_per_level", "support_charge_gain_mult_per_level": return {"type": type, "applied_value": base * lvl}
		"surge_aggression", "surge_cadence", "surge_guard", "surge_bond": active_surges[type.replace("surge_", "")] = base; return {"type": type, "applied_value": base}
	return {}


func _tendency_short_name(id: String) -> String:
	match id:
		"aggression": return "AGGR"
		"cadence": return "CAD"
		"guard": return "GUARD"
		"bond": return "BOND"
	return id.to_upper()


func _refresh_primary_combat_stats(heal_amt: float) -> float:
	var h_b: float = GameState.player_hp
	GameState.player_base_damage = GameState.stat_power + _level_bonus_base_damage
	GameState.player_defense = GameState.stat_carapace + _level_bonus_defense
	GameState.player_max_hp = GameState.stat_vitality + _level_bonus_max_hp
	GameState.player_hp = clampf(h_b + maxf(heal_amt, 0.0), 0.0, GameState.player_max_hp)
	return GameState.player_hp - h_b


func _consume_prepared_ritual_on_encounter_start() -> void:
	var ritual: Dictionary = GameState.consume_prepared_ritual()
	if ritual.is_empty(): return
	var eff: Dictionary = ritual.get("effect", {})
	match String(eff.get("type", "")):
		"encounter_start_support_charge": _gain_support_charge(float(eff.get("value", 0.0)))
		"encounter_start_guard_surge", "encounter_start_cadence_surge", "encounter_start_aggression_surge":
			var s_id: String = String(eff.get("type", "")).replace("encounter_start_", "").replace("_surge", "")
			active_surges[s_id] = max(active_surges.get(s_id, 0.0), float(eff.get("value", 0.0)))
		"encounter_start_mend_and_charge":
			var h: float = GameState.heal_player(float(eff.get("heal_value", 0.0)))
			if h > 0.0: EventBus.player_healed.emit(h)
			_gain_support_charge(float(eff.get("support_charge", 0.0)))
		"encounter_start_clutch_mend":
			var h: float = GameState.heal_player(float(eff.get("value", 0.0)))
			if h > 0.0: EventBus.player_healed.emit(h)
	EventBus.proc_feedback_requested.emit( String(ritual.get("claim_text", "RITUAL")), Color(0.86, 0.62, 0.96, 1.0))
