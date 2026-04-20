extends Node

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")

# Live run growth now resolves immediately through tendency surges.
# Legacy upgrade-pool effects remain only as a compatibility fallback for
# stale taken_upgrades data until that state is fully retired.

var level: int = 1
var exp: float = 0.0
var exp_to_next: float = GROWTH_CONTENT.LEVEL_THRESHOLDS[0]
var support_charge: float = 0.0
var tendency_points: Dictionary = {}
var tendency_levels: Dictionary = {}
var dna_routing_preference: String = "bond"

# Temporary surge buffs granted by tendency pulses.
var active_surges: Dictionary = {
	"aggression": 0.0, # hits remaining
	"cadence": 0.0,    # seconds remaining
	"guard": 0.0,      # hits remaining
	"bond": 0.0        # activations remaining
}

# Run-local passives granted by eating creatures.
var mutations: Array[Dictionary] = []


func _process(delta: float) -> void:
	if active_surges.get("cadence", 0.0) > 0.0:
		active_surges["cadence"] = max(active_surges["cadence"] - delta, 0.0)

var _encounter_style_tiers_awarded: Dictionary = {}
var _encounter_survival_spent: bool = false
var _encounter_pressure_mend_spent: bool = false


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
	
	# Priority: show active surges if any.
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
	if lead_id.is_empty():
		return "--"
	return _tendency_short_name(lead_id)


func get_runtime_effect(effect_type: String) -> Dictionary:
	match effect_type:
		"timed_attack_bonus_damage":
			var aggression_level: int = int(tendency_levels.get("aggression", 0))
			var surge_bonus: float = 0.0
			if active_surges.get("aggression", 0.0) > 0.0:
				surge_bonus = 0.25 # 25% extra damage during aggression surge

			if aggression_level > 0 or surge_bonus > 0.0:
				return {"type": effect_type, "value": 0.12 * aggression_level + surge_bonus}
		"good_timed_bonus_damage":
			var cadence_level: int = int(tendency_levels.get("cadence", 0))
			if cadence_level > 0:
				return {"type": effect_type, "value": 0.12 * cadence_level}
		"support_charge_gain_mult":
			var bond_level: int = int(tendency_levels.get("bond", 0))
			var surge_mult: float = 1.0
			if active_surges.get("cadence", 0.0) > 0.0:
				surge_mult = 2.0 # Double charge gain during cadence surge

			if bond_level > 0 or surge_mult > 1.0:
				return {"type": effect_type, "value": (1.0 + 0.12 * bond_level) * surge_mult}
		"guard_damage_reduction":
			if active_surges.get("guard", 0.0) > 0.0:
				return {"type": effect_type, "value": 0.50} # 50% damage reduction for 1 hit
		"bond_trigger_mult":
			if active_surges.get("bond", 0.0) > 0.0:
				return {"type": effect_type, "value": 2.0} # Double effectiveness for next support
		_:
			return {}
	return {}


func has_surge(surge_type: String) -> bool:
	return active_surges.get(surge_type, 0.0) > 0.0


func consume_surge_hit(surge_type: String) -> void:
	if active_surges.has(surge_type):
		active_surges[surge_type] = max(active_surges[surge_type] - 1.0, 0.0)


func get_growth_snapshot() -> Dictionary:
	var cadence_level: int = int(tendency_levels.get("cadence", 0))
	var bond_level: int = int(tendency_levels.get("bond", 0))
	return {
		"level": level,
		"exp": exp,
		"exp_to_next": exp_to_next,
		"base_damage": GameState.player_base_damage,
		"attack_damage": GameState.get_attack_damage(),
		"player_defense": GameState.player_defense,
		"player_defense_reduction": GameState.get_defense_damage_reduction(),
		"player_hp": GameState.player_hp,
		"player_max_hp": GameState.player_max_hp,
		"support_charge": support_charge,
		"support_max": GROWTH_CONTENT.SUPPORT_MAX,
		"dna_routing_preference": dna_routing_preference,
		"good_timed_bonus_damage_mult": 0.12 * cadence_level,
		"support_charge_gain_mult": 1.0 + 0.12 * bond_level
	}


func get_dna_routing_label() -> String:
	if dna_routing_preference == "exp":
		return PRESENTATION_TEXT.DNA_ROUTE_EXP_LABEL
	return PRESENTATION_TEXT.DNA_ROUTE_BOND_LABEL


func toggle_dna_routing_preference() -> String:
	dna_routing_preference = "exp" if dna_routing_preference == "bond" else "bond"
	_emit_dna_routing_state()
	return dna_routing_preference


func process_dna_gain(species_id: String, amount: float) -> Dictionary:
	if species_id.is_empty() or amount <= 0.0:
		return {
			"species_id": species_id,
			"amount": 0.0,
			"banked": false,
			"total": GameState.get_dna(species_id),
			"route_id": dna_routing_preference,
			"exp_gained": 0.0
		}

	if dna_routing_preference == "exp":
		var exp_gained: float = amount * GROWTH_CONTENT.DNA_EXP_PER_POINT
		_grant_exp(exp_gained)
		return {
			"species_id": species_id,
			"amount": amount,
			"banked": false,
			"total": GameState.get_dna(species_id),
			"route_id": dna_routing_preference,
			"exp_gained": exp_gained
		}

	GameState.add_dna(species_id, amount)
	var creature_data: Dictionary = COMBAT_CONTENT.get_creature(species_id)
	var threshold: float = float(creature_data.get("dna_threshold", 999.0))
	var current_total: float = GameState.get_dna(species_id)
	var auto_bonded: bool = false
	
	if not GameState.is_species_bonded(species_id) and current_total >= threshold:
		GameState.spend_dna(species_id, threshold)
		var updated_creature: Dictionary = GameState.add_bonded_creature(creature_data)
		EventBus.emit_signal("creature_bonded", updated_creature)
		auto_bonded = true
		_grant_tendency("bond", 3.0) # Bonus tendency for the breakthrough moment

	_gain_support_charge(amount * GROWTH_CONTENT.DNA_BOND_SUPPORT_CHARGE_PER_POINT)
	_grant_tendency("bond", amount * GROWTH_CONTENT.DNA_BOND_TENDENCY_PER_POINT)
	return {
		"species_id": species_id,
		"amount": amount,
		"banked": true,
		"total": GameState.get_dna(species_id),
		"route_id": dna_routing_preference,
		"exp_gained": 0.0,
		"auto_bonded": auto_bonded
	}


func _on_run_started(_run_number: int) -> void:
	level = 1
	exp = 0.0
	exp_to_next = GROWTH_CONTENT.LEVEL_THRESHOLDS[0]
	support_charge = 0.0
	dna_routing_preference = "bond"
	mutations.clear()
	for surge_id in active_surges.keys():
		active_surges[surge_id] = 0.0
	_reset_tendencies()
	# Apply starting_support_charge region modifier if the Drowned Cut is active.
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


func _on_enemy_defeated(_enemy_id: int) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_KILL)
	_gain_support_charge(GROWTH_CONTENT.CHARGE_ENEMY_DEFEAT)
	
	# Aggression Surge: heal on kill.
	if active_surges.get("aggression", 0.0) > 0.0:
		var healed: float = GameState.heal_player(4.0)
		if healed > 0.0:
			EventBus.emit_signal("player_healed", healed)

	# Drowned Cut: resonant volume identity — each kill charges the bond layer faster.
	# +75% of the base kill charge, so ~6 kills to fill instead of ~10.
	if GameState.active_region.get("id", "") == "drowned_cut":
		_gain_support_charge(GROWTH_CONTENT.CHARGE_ENEMY_DEFEAT * 0.75)
	_trigger_active_support_for_event("enemy_defeated", 1)
	_apply_hp_on_kill_passive()
	_grant_tendency("aggression", 1.0)


func _on_timed_attack_resolved(lane: int, quality: String, _damage: float) -> void:
	_grant_exp(GROWTH_CONTENT.EXP_TIMED_ATTACK)
	_gain_support_charge(GROWTH_CONTENT.CHARGE_TIMED_ATTACK)
	
	if active_surges.get("aggression", 0.0) > 0.0:
		consume_surge_hit("aggression")

	var cadence_gain: float = 0.5
	if quality == "good":
		cadence_gain = 1.0
	elif quality == "perfect":
		cadence_gain = 1.4
	_grant_tendency("cadence", cadence_gain)

	if quality == "perfect":
		_apply_upgrade_effect_on_event("perfect_timing")
		_apply_upgrade_effect_on_event("perfect_timed_heal")
		_trigger_active_support_for_event("perfect_timed_attack", lane)
	elif quality == "good":
		_trigger_active_support_for_event("good_timed_attack", lane)


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
	if tier == "stirring":
		return
	if _encounter_style_tiers_awarded.has(tier):
		return

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
	if active_surges.get("guard", 0.0) > 0.0:
		consume_surge_hit("guard")

	if not _encounter_survival_spent and _apply_upgrade_effect_on_event("first_damage_taken"):
		_encounter_survival_spent = true

	if not _encounter_pressure_mend_spent and GameState.get_hp_percent() < 0.50:
		if _apply_upgrade_effect_on_event("low_hp_first_hit"):
			_encounter_pressure_mend_spent = true

	_trigger_active_support_for_event("damage_taken_when_ready", source_lane)
	_grant_tendency("guard", 0.25)


func _on_creature_changed(creature_data: Dictionary) -> void:
	# Eating a creature adds its identity to the run mutations.
	var eat_effect: Dictionary = creature_data.get("eat_effect", {})
	if not eat_effect.is_empty():
		mutations.append(creature_data)
		EventBus.emit_signal("screen_flash", Color(0.85, 0.22, 0.14, 0.08), 0.10)
	
	_emit_support_state()


func _on_creature_bonded(_creature_data: Dictionary) -> void:
	_emit_support_state()
	_grant_tendency("bond", 1.6)


func _on_enemy_status_applied(_lane: int, status_id: String) -> void:
	# GORGE-MARK triggered: a marked enemy was defeated. Grant bonus support charge
	# (on top of the base CHARGE_ENEMY_DEFEAT already granted via enemy_defeated).
	if status_id == "gorge_mark_triggered":
		_gain_support_charge(GROWTH_CONTENT.GORGE_MARK_BONUS_CHARGE)


func _on_player_dodged(_from_lane: int, _to_lane: int) -> void:
	_grant_tendency("guard", 0.55)
	_trigger_active_support_for_event("player_dodged", _to_lane)


func _on_bonded_support_triggered(_species_id: String, _lane: int, _effect_id: String) -> void:
	if active_surges.get("bond", 0.0) > 0.0:
		consume_surge_hit("bond")
	_grant_tendency("bond", 1.25)


func _grant_exp(amount: float) -> void:
	if amount <= 0.0:
		return

	exp += amount
	while level - 1 < GROWTH_CONTENT.LEVEL_THRESHOLDS.size() and exp >= exp_to_next:
		exp -= exp_to_next
		level += 1
		_apply_real_time_growth_pulse()
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
	var gain_effect: Dictionary = _get_growth_effect("support_charge_gain_mult")
	if not gain_effect.is_empty():
		gain_mult = float(gain_effect.get("value", 1.0))

	var flat_bonus: float = 0.0
	var depth_effect: Dictionary = _get_growth_effect("support_charge_flat_bonus")
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


func _get_growth_effect(effect_type: String) -> Dictionary:
	var runtime_effect: Dictionary = get_runtime_effect(effect_type)
	if not runtime_effect.is_empty():
		return runtime_effect
	return _get_legacy_upgrade_effect(effect_type)


func _get_legacy_upgrade_effect(effect_type: String) -> Dictionary:
	# Deprecated compatibility path for stale taken_upgrades data.

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
			var cadence_effect: Dictionary = _get_growth_effect("perfect_bonus_exp_and_charge")
			if cadence_effect.is_empty():
				return false
			_grant_exp(float(cadence_effect.get("exp_value", 0.0)))
			_gain_support_charge(float(cadence_effect.get("charge_value", 0.0)))
			return true
		"ultimate_fired":
			var surge_effect: Dictionary = _get_growth_effect("support_charge_on_ultimate")
			if surge_effect.is_empty():
				return false
			_gain_support_charge(float(surge_effect.get("value", 0.0)))
			return true
		"first_damage_taken":
			var survival_effect: Dictionary = _get_growth_effect("first_hit_recovery")
			if survival_effect.is_empty():
				return false
			var healed: float = GameState.heal_player(float(survival_effect.get("heal_value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			_gain_support_charge(float(survival_effect.get("charge_value", 0.0)))
			return true
		"perfect_timed_heal":
			var bloodrite_effect: Dictionary = _get_growth_effect("hp_on_perfect_timed")
			if bloodrite_effect.is_empty():
				return false
			var healed: float = GameState.heal_player(float(bloodrite_effect.get("value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			return true
		"low_hp_first_hit":
			var mend_effect: Dictionary = _get_growth_effect("low_hp_first_damage_heal")
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


func _emit_dna_routing_state() -> void:
	EventBus.emit_signal("dna_routing_changed", dna_routing_preference, get_dna_routing_label())


func gain_support_charge_direct(amount: float) -> void:
	if amount <= 0.0:
		return
	support_charge = clamp(support_charge + amount, 0.0, GROWTH_CONTENT.SUPPORT_MAX)
	_emit_support_state()


func gain_reward_support_charge(amount: float) -> void:
	if amount <= 0.0:
		return

	if get_active_species_id().is_empty():
		_emit_support_state()
		return

	var gain_mult: float = 1.0
	var gain_effect: Dictionary = _get_growth_effect("support_charge_gain_mult")
	if not gain_effect.is_empty():
		gain_mult = float(gain_effect.get("value", 1.0))

	support_charge = clamp(support_charge + amount * gain_mult, 0.0, GROWTH_CONTENT.SUPPORT_MAX)
	_emit_support_state()


func apply_debug_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	level = max(int(state.get("level", level)), 1)
	exp = max(float(state.get("exp", exp)), 0.0)
	exp_to_next = _get_exp_threshold_for_level(level)

	var seeded_points: Dictionary = state.get("tendency_points", {})
	if not seeded_points.is_empty():
		for tendency_id in tendency_points.keys():
			tendency_points[tendency_id] = float(seeded_points.get(tendency_id, 0.0))

	var seeded_levels: Dictionary = state.get("tendency_levels", {})
	if not seeded_levels.is_empty():
		for tendency_id in tendency_levels.keys():
			tendency_levels[tendency_id] = max(int(seeded_levels.get(tendency_id, 0)), 0)

	if state.has("support_charge"):
		support_charge = clamp(float(state.get("support_charge", support_charge)), 0.0, GROWTH_CONTENT.SUPPORT_MAX)

	_emit_growth_state()
	_emit_support_state()


func _reset_tendencies() -> void:
	tendency_points = {
		"aggression": 0.0,
		"cadence": 0.0,
		"guard": 0.0,
		"bond": 0.0
	}
	tendency_levels = {
		"aggression": 0,
		"cadence": 0,
		"guard": 0,
		"bond": 0
	}


func _grant_tendency(tendency_id: String, amount: float) -> void:
	if amount <= 0.0 or not tendency_points.has(tendency_id):
		return
	tendency_points[tendency_id] = float(tendency_points.get(tendency_id, 0.0)) + amount


func _apply_real_time_growth_pulse() -> void:
	var tendency_id: String = _get_leading_tendency_id()
	if tendency_id.is_empty():
		tendency_id = "aggression"

	var new_level: int = int(tendency_levels.get(tendency_id, 0)) + 1
	tendency_levels[tendency_id] = new_level
	tendency_points[tendency_id] = max(float(tendency_points.get(tendency_id, 0.0)) - 4.0, 0.0)
	var result: Dictionary = _resolve_tendency_level_up(tendency_id, new_level)
	if result.is_empty():
		return

	_emit_growth_state()
	_emit_support_state()
	EventBus.emit_signal("run_growth_level_resolved", result)
	EventBus.emit_signal("tendency_growth_resolved", tendency_id, String(result.get("title", "")), String(result.get("summary", "")))


func _resolve_tendency_level_up(tendency_id: String, tendency_level: int) -> Dictionary:
	var outcome: Dictionary = GROWTH_CONTENT.TENDENCY_LEVEL_UP_OUTCOMES.get(tendency_id, {})
	if outcome.is_empty():
		return {}

	var changes: Array[Dictionary] = []
	for effect in outcome.get("effects", []):
		var effect_data: Dictionary = effect
		var applied_change: Dictionary = _apply_level_up_effect(effect_data, tendency_level)
		if not applied_change.is_empty():
			changes.append(applied_change)

	var result: Dictionary = {
		"level": level,
		"tendency_id": tendency_id,
		"tendency_level": tendency_level,
		"title": String(outcome.get("title", tendency_id.to_upper())),
		"readout_label": String(outcome.get("readout_label", tendency_id.capitalize())),
		"changes": changes,
		"snapshot": get_growth_snapshot()
	}
	result["summary"] = PRESENTATION_TEXT.tendency_level_up_summary(result)
	return result


func _apply_level_up_effect(effect_data: Dictionary, tendency_level: int) -> Dictionary:
	var effect_type: String = String(effect_data.get("type", ""))
	var base_value: float = float(effect_data.get("value", 0.0))
	match effect_type:
		"base_damage_flat":
			GameState.player_base_damage += base_value
			return {"type": effect_type, "applied_value": base_value}
		"max_hp_flat":
			var current_hp_before: float = GameState.player_hp
			GameState.player_max_hp += base_value
			var hp_gain: float = min(base_value * 0.5, GameState.player_max_hp - current_hp_before)
			GameState.player_hp = min(current_hp_before + hp_gain, GameState.player_max_hp)
			if GameState.player_hp > current_hp_before:
				EventBus.emit_signal("player_healed", GameState.player_hp - current_hp_before)
			return {"type": effect_type, "applied_value": base_value}
		"defense_flat":
			GameState.player_defense += base_value
			return {"type": effect_type, "applied_value": base_value}
		"heal_now":
			var healed: float = GameState.heal_player(base_value)
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			return {"type": effect_type, "applied_value": healed}
		"support_charge_now":
			var before_charge: float = support_charge
			_gain_support_charge(base_value)
			return {"type": effect_type, "applied_value": support_charge - before_charge}
		"good_timed_bonus_damage_per_level":
			return {"type": effect_type, "applied_value": base_value * tendency_level}
		"support_charge_gain_mult_per_level":
			return {"type": effect_type, "applied_value": base_value * tendency_level}
		"surge_aggression":
			active_surges["aggression"] = base_value
			return {"type": effect_type, "applied_value": base_value}
		"surge_cadence":
			active_surges["cadence"] = base_value
			return {"type": effect_type, "applied_value": base_value}
		"surge_guard":
			active_surges["guard"] = base_value
			return {"type": effect_type, "applied_value": base_value}
		"surge_bond":
			active_surges["bond"] = base_value
			return {"type": effect_type, "applied_value": base_value}
		_:
			return {}


func _get_leading_tendency_id() -> String:
	var best_id: String = ""
	var best_value: float = -1.0
	for tendency_id in tendency_points.keys():
		var value: float = float(tendency_points.get(tendency_id, 0.0))
		if tendency_id == "bond" and not get_active_species_id().is_empty():
			value += 0.35
		if value > best_value:
			best_value = value
			best_id = String(tendency_id)
	return best_id


func _sorted_tendency_ids_by_level() -> Array[String]:
	var ids: Array[String] = ["aggression", "cadence", "guard", "bond"]
	ids.sort_custom(func(a: String, b: String) -> bool:
		var a_level: int = int(tendency_levels.get(a, 0))
		var b_level: int = int(tendency_levels.get(b, 0))
		if a_level == b_level:
			return float(tendency_points.get(a, 0.0)) > float(tendency_points.get(b, 0.0))
		return a_level > b_level
	)
	return ids


func _tendency_short_name(tendency_id: String) -> String:
	match tendency_id:
		"aggression":
			return "AGGR"
		"cadence":
			return "CAD"
		"guard":
			return "GUARD"
		"bond":
			return "BOND"
		_:
			return tendency_id.to_upper()


func _get_exp_threshold_for_level(level_value: int) -> float:
	if level_value - 1 < GROWTH_CONTENT.LEVEL_THRESHOLDS.size():
		return GROWTH_CONTENT.LEVEL_THRESHOLDS[level_value - 1]
	return GROWTH_CONTENT.LEVEL_THRESHOLDS[GROWTH_CONTENT.LEVEL_THRESHOLDS.size() - 1] + 70.0
