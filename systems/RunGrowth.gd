extends Node

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")
const COMBAT_DATA = preload("res://data/CombatContent.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")

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

var _encounter_style_tiers_awarded: Dictionary = {}
var _encounter_survival_spent: bool = false
var _encounter_pressure_mend_spent: bool = false
var _level_bonus_base_damage: float = 0.0
var _level_bonus_max_hp: float = 0.0
var _level_bonus_defense: float = 0.0
var _gains_this_combat: Array[Dictionary] = []


func _ready() -> void:
	if not EventBus.run_started.is_connected(_on_run_started):
		EventBus.run_started.connect(_on_run_started)
	if not EventBus.combat_started.is_connected(_on_combat_started):
		EventBus.combat_started.connect(_on_combat_started)
	if not EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.connect(_on_enemy_defeated)
	if not EventBus.phrase_milestone.is_connected(_on_phrase_milestone):
		EventBus.phrase_milestone.connect(_on_phrase_milestone)
	if not EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	if not EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.connect(_on_player_parried)
	if not EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.connect(_on_ultimate_fired)
	if not EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.connect(_on_player_took_damage)
	if not EventBus.creature_bonded.is_connected(_on_creature_bonded):
		EventBus.creature_bonded.connect(_on_creature_bonded)
	if not EventBus.creature_eaten.is_connected(_on_creature_eaten):
		EventBus.creature_eaten.connect(_on_creature_eaten)


func _exit_tree() -> void:
	if EventBus.run_started.is_connected(_on_run_started):
		EventBus.run_started.disconnect(_on_run_started)
	if EventBus.combat_started.is_connected(_on_combat_started):
		EventBus.combat_started.disconnect(_on_combat_started)
	if EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.disconnect(_on_enemy_defeated)
	if EventBus.phrase_milestone.is_connected(_on_phrase_milestone):
		EventBus.phrase_milestone.disconnect(_on_phrase_milestone)
	if EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.disconnect(_on_timed_attack_resolved)
	if EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.disconnect(_on_player_parried)
	if EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.disconnect(_on_ultimate_fired)
	if EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.disconnect(_on_player_took_damage)
	if EventBus.creature_bonded.is_connected(_on_creature_bonded):
		EventBus.creature_bonded.disconnect(_on_creature_bonded)
	if EventBus.creature_eaten.is_connected(_on_creature_eaten):
		EventBus.creature_eaten.disconnect(_on_creature_eaten)
	if EventBus.support_manual_activation_requested.is_connected(_on_support_activation_requested):
		EventBus.support_manual_activation_requested.disconnect(_on_support_activation_requested)


func get_runtime_effect(type: String) -> Dictionary:
	# Tendency surges take absolute precedence
	if active_surges.get(type, 0.0) > 0.0:
		return {"active": true, "type": type, "value": GROWTH_CONTENT.get_surge_value(type), "label": "SURGE"}
	
	# Future-proofing: return first matching mutation effect
	for mut in mutations:
		if mut.get("type") == type:
			return mut
			
	return {}


func get_mutation_bonus(type: String, context: Dictionary = {}) -> float:
	var total: float = 0.0
	for mut in mutations:
		if mut.get("type") == type:
			var ok: bool = true
			if context.has("quality") and mut.has("quality_required"):
				if str(context["quality"]) != str(mut["quality_required"]): ok = false
			
			if ok:
				total += float(mut.get("value", 0.0))
	return total


func consume_mutation_charges(type: String, amount: int = 1, context: Dictionary = {}) -> void:
	for mut in mutations:
		if mut.get("type") == type:
			var ok: bool = true
			if context.has("quality") and mut.has("quality_required"):
				if str(context["quality"]) != str(mut["quality_required"]): ok = false
			
			if ok:
				var charges: int = int(mut.get("charges", 0))
				if charges > 0:
					mut["charges"] = max(charges - amount, 0)
					if int(mut["charges"]) <= 0:
						mutations.erase(mut)
						_emit_growth_state()
					break


func apply_debug_state(state: Dictionary) -> void:
	level = int(state.get("level", level))
	current_exp = float(state.get("current_exp", current_exp))
	exp_to_next = float(state.get("exp_to_next", exp_to_next))
	support_charge = float(state.get("support_charge", support_charge))
	
	if state.has("points"):
		var p = state.get("points", {})
		for k in p.keys(): tendencies.points[k] = float(p[k])
	
	if state.has("levels"):
		var lvls = state.get("levels", {})
		for k in lvls.keys(): tendencies.levels[k] = int(lvls[k])
		
	_emit_growth_state(); _emit_support_state()


func get_growth_snapshot() -> Dictionary:
	return {
		"level": level,
		"current_exp": current_exp,
		"exp_to_next": exp_to_next,
		"tendency_points": tendencies.points.duplicate(),
		"tendency_levels": tendencies.levels.duplicate(),
		"active_surges": tendencies.active_surges.duplicate(),
		"mutations_count": mutations.size(),
		"player_hp": GameState.player_hp,
		"player_max_hp": GameState.player_max_hp,
		"attack_damage": GameState.get_attack_damage(),
		"player_defense": GameState.player_defense
	}


func get_tendency_snapshot() -> Dictionary:
	return {
		"levels": tendencies.levels.duplicate(),
		"points": tendencies.points.duplicate(),
		"active_surges": tendencies.active_surges.duplicate()
	}


func get_active_species_id() -> String:
	var active = GameState.get_active_bonded_creature()
	return String(active.get("species_id", ""))


func get_active_display_name() -> String:
	var active = GameState.get_active_bonded_creature()
	return String(active.get("display_name", "None"))


func toggle_dna_routing_preference() -> void:
	if dna_routing_preference == "bond":
		dna_routing_preference = "exp"
	else:
		dna_routing_preference = "bond"
	_emit_dna_routing_state()


func get_dna_routing_label() -> String:
	return "Body (EXP)" if dna_routing_preference == "exp" else "Pact (BOND)"


func get_leading_tendency_id() -> String:
	return tendencies.get_leading_id(!get_active_species_id().is_empty())


func process_dna_gain(species_id: String, amount: float) -> Dictionary:
	if dna_routing_preference == "exp":
		var exp_gain: float = amount * GROWTH_CONTENT.EXP_PER_DNA_POINT
		_grant_exp(exp_gain)
		_grant_tendency("aggression", amount * GROWTH_CONTENT.DNA_AGGRESSION_TENDENCY_PER_POINT)
		return {"species_id": species_id, "amount": amount, "banked": false, "total": GameState.get_dna(species_id), "route_id": "exp", "exp_gained": exp_gain, "bond_ready": false}
	
	var bond_ready: bool = GameState.add_dna(species_id, amount)
	_grant_tendency("bond", amount * GROWTH_CONTENT.DNA_BOND_TENDENCY_PER_POINT)
	return {"species_id": species_id, "amount": amount, "banked": true, "total": GameState.get_dna(species_id), "route_id": dna_routing_preference, "exp_gained": 0.0, "bond_ready": bond_ready}


func get_gains_this_combat() -> Array[Dictionary]:
	return _gains_this_combat


func clear_combat_gains() -> void:
	_gains_this_combat.clear()
	tendencies.clear_points()
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


func _on_run_started(_run_number: int) -> void:
	progression.reset()
	support.reset()
	mutations.clear()
	pending_bonds.clear()
	_level_bonus_base_damage = 0.0
	_level_bonus_max_hp = 0.0
	_level_bonus_defense = 0.0
	_gains_this_combat.clear()
	_on_combat_started([])


func _on_combat_started(_enemy_data: Array) -> void:
	clear_combat_gains()
	_encounter_style_tiers_awarded.clear()
	_encounter_survival_spent = false
	_encounter_pressure_mend_spent = false
	_consume_prepared_ritual_on_encounter_start()


func _on_enemy_defeated(_enemy_id: int) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_KILL)
	
	var active_species_id: String = get_active_species_id()
	if not active_species_id.is_empty():
		var creature_levels_gained: int = GameState.grant_creature_exp(active_species_id, GROWTH_CONTENT.EXP_CREATURE_KILL)
		if creature_levels_gained > 0:
			var creature_name: String = get_active_display_name()
			EventBus.proc_feedback_requested.emit(creature_name.to_upper() + " CALIBRATED", Color(0.44, 0.92, 1.0, 1.0))

	var kill_charge: float = GROWTH_CONTENT.CHARGE_ENEMY_DEFEAT
	var charge_mult: float = get_mutation_bonus("support_charge_mult_on_kill")
	if charge_mult > 0.0:
		kill_charge *= charge_mult
	
	_gain_support_charge(kill_charge)
	
	_grant_tendency("aggression", 1.25)
	
	# Support kill passive: Mend
	var mend: float = get_mutation_bonus("hp_on_kill")
	if mend > 0.0:
		var healed: float = GameState.heal_player(mend)
		if healed > 0.0:
			EventBus.player_healed.emit(healed)
	
	# Vessel kill passive: Base damage
	var v_dmg: float = get_mutation_bonus("base_damage_on_kill")
	if v_dmg > 0.0:
		_level_bonus_base_damage += v_dmg
		_refresh_primary_combat_stats(0.0)


func _on_phrase_milestone(count: int) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_PHRASE_COMPLETE)
	_gain_support_charge(GROWTH_CONTENT.CHARGE_PHRASE_COMPLETE)
	
	# Mastery passive: every 8 phrases -> major charge
	if count > 0 and count % 8 == 0:
		_gain_support_charge(30.0)
	
	# Tendency passive: every phrase -> points
	_grant_tendency("cadence", 1.5)


func _on_timed_attack_resolved(_lane: int, quality: String, _damage: float, _enemy_id: int) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_TIMED_ATTACK)
	_gain_support_charge(GROWTH_CONTENT.get_charge_timed_attack(quality))
	
	if quality == "perfect":
		_grant_tendency("cadence", 0.75)
		_grant_tendency("aggression", 0.50)
	else:
		_grant_tendency("aggression", 0.25)


func _on_player_parried(_lane: int, quality: String, _reflect_damage: float, _heading: Vector2) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_PARRY)
	_gain_support_charge(GROWTH_CONTENT.get_charge_parry(quality))
	_grant_tendency("guard", 1.5 if quality == "perfect" else 0.75)


func _on_ultimate_fired(_power: float) -> void:
	# Resets all surges on ultimate
	tendencies.active_surges["aggression"] = 0.0
	tendencies.active_surges["cadence"] = 0.0
	tendencies.active_surges["guard"] = 0.0
	_emit_growth_state()


func _on_player_took_damage(amount: float, _source_lane: int) -> void:
	_grant_tendency("guard", 0.45)
	
	# Survival passive: once per encounter, ignore hit that would kill
	var death_guard: float = get_mutation_bonus("ignore_death_hit")
	if death_guard > 0.0 and amount >= GameState.player_hp and not _encounter_survival_spent:
		_encounter_survival_spent = true
		GameState.player_hp = 1.0
		EventBus.proc_feedback_requested.emit("SURVIVAL", Color(0.95, 0.85, 0.40, 1.0))
		# consume_mutation_charges is NOT called here because it's a passive buff, 
		# we just use a per-encounter flag.
	
	# Pressure passive: every 15 damage taken -> mend 10 (once per encounter)
	var pressure_mend: float = get_mutation_bonus("mend_on_pressure")
	if pressure_mend > 0.0 and amount >= 15.0 and not _encounter_pressure_mend_spent:
		_encounter_pressure_mend_spent = true
		var h: float = GameState.heal_player(pressure_mend)
		if h > 0.0: EventBus.player_healed.emit(h)


func _on_creature_bonded(creature_data: Dictionary) -> void:
	var species_id: String = String(creature_data.get("species_id", ""))
	if not species_id.is_empty():
		_gain_support_charge(25.0)
		_grant_tendency("bond", 4.0)


func _on_creature_eaten(_creature_data: Dictionary) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_EAT)
	_grant_tendency("aggression", 3.0)
	_gain_support_charge(15.0)


func _on_support_activation_requested(sector: int, quality: String) -> void:
	if not support.is_ready():
		return
	
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	if active_creature.is_empty():
		return
		
	var species_id: String = String(active_creature.get("species_id", ""))
	var support_role: Dictionary = COMBAT_DATA.get_support_role(species_id)
	var effect_id: String = String(support_role.get("effect_id", ""))
	
	if effect_id.is_empty():
		return
		
	support.consume()
	_emit_support_state()
	
	EventBus.bonded_support_triggered.emit(species_id, sector, effect_id)
	# Also record the quality for performance rewards if needed
	if quality == "perfect":
		_grant_tendency("bond", 1.5)
	else:
		_grant_tendency("bond", 0.75)


func _grant_exp(amount: float) -> void:
	var levels_gained: int = progression.grant_exp(amount, GameState.stat_potential)
	for i in range(levels_gained):
		_apply_real_time_growth_pulse()
	_emit_growth_state()


func _gain_support_charge(amount: float) -> void:
	var mult: float = 1.0 + (progression.level * 0.02)
	# Support synergy: every active surge adds 10% charge gain
	for tid in active_surges:
		if active_surges[tid] > 0.0: mult += 0.10
	
	support.gain_charge(amount, mult)
	_emit_support_state()


func gain_support_charge_direct(amount: float) -> void:
	_gain_support_charge(amount)


func gain_reward_support_charge(amount: float) -> void:
	_gain_support_charge(amount)


func _grant_tendency(id: String, amount: float) -> void:
	tendencies.grant_points(id, amount, GameState.stat_potential)
	_emit_growth_state()


func _apply_real_time_growth_pulse() -> void:
	var id: String = tendencies.get_leading_id(!get_active_species_id().is_empty())
	if id.is_empty(): id = "aggression"
	var new_lvl: int = int(tendency_levels.get(id, 0)) + 1
	tendency_levels[id] = new_lvl
	tendency_points[id] = max(float(tendency_points.get(id, 0.0)) - 4.0, 0.0)
	var res: Dictionary = _resolve_tendency_level_up(id, new_lvl)
	if res.is_empty(): return
	
	_gains_this_combat.append(res)
	
	_emit_growth_state(); _emit_support_state()
	EventBus.run_growth_level_resolved.emit(res)
	EventBus.tendency_growth_resolved.emit(id, String(res.get("title", "")), String(res.get("summary", "")))


func _resolve_tendency_level_up(id: String, lvl: int) -> Dictionary:
	var out: Dictionary = GROWTH_CONTENT.TENDENCY_LEVEL_UP_OUTCOMES.get(id, {})
	if out.is_empty(): return {}
	
	var changes: Array[Dictionary] = []
	
	# RESOLUTION TRUTH: Deterministic Behavior-Shaped Growth.
	# We no longer roll random dice. Your playstyle (Tendency) dictates your stats.
	for stat_def in out.get("stats", []):
		changes.append(_apply_surge_stat_gain(String(stat_def.get("type", ""))))
	
	# Every level up also grants global stat gains (e.g. Adaptability)
	for global_stat in GROWTH_CONTENT.GLOBAL_LEVEL_UP_STATS:
		changes.append(_apply_surge_stat_gain(String(global_stat.get("type", ""))))

	for eff in out.get("effects", []):
		var applied: Dictionary = _apply_level_up_effect(eff, lvl)
		if not applied.is_empty(): changes.append(applied)
		
	var res: Dictionary = {
		"level": level, 
		"tendency_id": id, 
		"tendency_level": lvl, 
		"title": String(out.get("title", id.to_upper())), 
		"readout_label": String(out.get("readout_label", id.capitalize())), 
		"changes": changes, 
		"snapshot": get_growth_snapshot()
	}
	res["summary"] = PRESENTATION_TEXT.tendency_level_up_summary(res)
	return res


func _apply_surge_stat_gain(sid: String) -> Dictionary:
	var label: String = sid.replace("stat_", "").to_upper(); var val: float = 0.0
	
	# Find the value in TENDENCY_LEVEL_UP_OUTCOMES or GLOBAL_LEVEL_UP_STATS
	for tid in GROWTH_CONTENT.TENDENCY_LEVEL_UP_OUTCOMES.keys():
		var tout = GROWTH_CONTENT.TENDENCY_LEVEL_UP_OUTCOMES[tid]
		for sdef in tout.get("stats", []):
			if sdef.get("type") == sid:
				val = float(sdef.get("value", 0.0))
				break
		if val != 0.0: break
	
	if val == 0.0:
		for gstat in GROWTH_CONTENT.GLOBAL_LEVEL_UP_STATS:
			if gstat.get("type") == sid:
				val = float(gstat.get("value", 0.0))
				break

	match sid:
		"stat_vitality": 
			GameState.stat_vitality += val
			var h: float = _refresh_primary_combat_stats(val)
			if h > 0.0: EventBus.player_healed.emit(h)
		"stat_power": 
			GameState.stat_power += val
			_refresh_primary_combat_stats(0.0)
		"stat_carapace": 
			GameState.stat_carapace += val
			_refresh_primary_combat_stats(0.0)
		"stat_endurance": 
			GameState.stat_endurance += val
		"stat_swiftness": 
			GameState.stat_swiftness += val
		"stat_luck": 
			GameState.stat_luck += val
		"stat_potential": 
			GameState.stat_potential += val
		"stat_intelligence": 
			GameState.stat_intelligence += val
		"stat_adaptability": 
			GameState.stat_adaptability += val
		_: return {}
	return {"type": sid, "applied_value": val, "label": label}


func _apply_level_up_effect(eff: Dictionary, _lvl: int) -> Dictionary:
	var type: String = String(eff.get("type", "")); var val: float = float(eff.get("value", 0.0))
	match type:
		"base_damage_flat": _level_bonus_base_damage += val; _refresh_primary_combat_stats(0.0)
		"defense_flat": _level_bonus_defense += val; _refresh_primary_combat_stats(0.0)
		"max_hp_flat": _level_bonus_max_hp += val; _refresh_primary_combat_stats(val)
		"support_charge_now": support_charge = clamp(support_charge + val, 0.0, GROWTH_CONTENT.SUPPORT_MAX); _emit_support_state()
		"surge_aggression", "surge_cadence", "surge_guard", "surge_bond":
			var sid: String = type.replace("surge_", "")
			tendencies.active_surges[sid] = 4.0 # 4 beats of surge
		_: pass
	return {"type": type, "value": val, "label": type.replace("_", " ").capitalize()}


func _refresh_primary_combat_stats(heal_amount: float) -> float:
	var old_max: float = GameState.player_max_hp
	var bonus_max: float = _level_bonus_max_hp + get_mutation_bonus("max_hp_flat")
	
	# SOVEREIGN TRUTH: PlayerState is the single authority for HP math.
	GameState.player.recalculate_max_hp(bonus_max)
	
	if heal_amount > 0.0:
		return GameState.heal_player(heal_amount)
	elif GameState.player_max_hp > old_max:
		# Auto-heal the difference on max HP gain
		return GameState.heal_player(GameState.player_max_hp - old_max)
	
	GameState.player_defense = GameState.stat_carapace * 2.0 + _level_bonus_defense + get_mutation_bonus("defense_flat")
	return 0.0


func _consume_prepared_ritual_on_encounter_start() -> void:
	var rituals = GameState.get_active_mutations_of_type("prepared_ritual")
	for rit in rituals:
		# Rituals usually apply a 'surge' or 'bomb' at start
		var eff = rit.get("effect", {})
		if not eff.is_empty():
			_apply_level_up_effect(Dictionary(eff), 1)
		# Consumed
		mutations.erase(rit)
	if not rituals.is_empty(): _emit_growth_state()


func _emit_growth_state() -> void:
	EventBus.run_growth_changed.emit(level, current_exp, exp_to_next)


func _emit_support_state() -> void:
	EventBus.support_charge_changed.emit(support.charge, GROWTH_CONTENT.SUPPORT_MAX, get_active_species_id())


func _emit_dna_routing_state() -> void:
	EventBus.dna_routing_changed.emit(dna_routing_preference, get_dna_routing_label())
