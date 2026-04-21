extends Node

const PERFORMANCE_REWARD_CONTENT = preload("res://data/PerformanceRewardContent.gd")
const PREDATION_POOL = preload("res://systems/PredationPool.gd")
const WOUND_HUNGER_COOLDOWN: float = 1.25

signal state_changed()
signal offer_started(reward_data: Dictionary)
signal offer_ended()
signal reward_claimed(reward_data: Dictionary, source: String)
signal proc_feedback(text: String, color: Color)

var _combat_meter: Node = null
var _run_growth: Node = null
var _run_stats: Node = null

var _song_started: bool = false
var _phase_index: int = -1
var _run_progress: float = 0.0
var _bonus_progress: float = 0.0
var _last_run_score: int = 0
var _phase_claimed: int = 0
var _run_thresholds: Array[float] = []
var _phase_reward_mix: Array[String] = []
var _next_threshold_index: int = 0
var _tier_awards_this_phase: Dictionary = {}
var _boss_awards_fired: Dictionary = {}
var _phase_clutch_spent: bool = false
var _exhaustion_announced: bool = false

var offers_enabled: bool = true
var banked_reward_count: int = 0
var _is_level_completion_choice: bool = false
var _level_completion_context: Dictionary = {}
var _predation_pool_pending: bool = false

var _active_offer: Dictionary = {}
var _offer_timer: float = 0.0
var _queued_offer_ids: Array[String] = []
var _reserved_reward_ids: Array[String] = []
var _claimed_reward_ids: Array[String] = []
var _claimed_rewards: Array[Dictionary] = []
var _runtime_effects: Dictionary = {}
var _kill_chain_count: int = 0
var _kill_chain_heavy_count: int = 0
var _perfect_strike_streak: int = 0
var _eat_ratchet_stacks: int = 0
var _wound_hunger_cooldown: float = 0.0


func bind_runtime(combat_meter_ref: Node, run_growth_ref: Node, run_stats_ref: Node = null) -> void:
	_combat_meter = combat_meter_ref
	_run_growth = run_growth_ref
	_run_stats = run_stats_ref
	_connect_eventbus()
	_connect_run_stats()


func start_song_run(_phases: Array) -> void:
	_song_started = true
	_phase_index = -1
	_run_progress = 0.0
	_bonus_progress = 0.0
	_last_run_score = 0
	_phase_claimed = 0
	_run_thresholds = PERFORMANCE_REWARD_CONTENT.RUN_THRESHOLDS.duplicate()
	_phase_reward_mix = []
	_next_threshold_index = 0
	_tier_awards_this_phase.clear()
	_boss_awards_fired.clear()
	_phase_clutch_spent = false
	_exhaustion_announced = false
	_active_offer.clear()
	_offer_timer = 0.0
	_queued_offer_ids.clear()
	_is_level_completion_choice = false
	
	# These now persist across levels in a multi-level run.
	# Call reset_full_run_data() to clear them.
	# _reserved_reward_ids.clear()
	# _claimed_reward_ids.clear()
	# _claimed_rewards.clear()
	# _runtime_effects.clear()
	
	_kill_chain_count = 0
	_kill_chain_heavy_count = 0
	_perfect_strike_streak = 0
	_eat_ratchet_stacks = 0
	_wound_hunger_cooldown = 0.0
	_emit_state_changed()


func reset_full_run_data() -> void:
	_reserved_reward_ids.clear()
	_claimed_reward_ids.clear()
	_claimed_rewards.clear()
	_runtime_effects.clear()
	banked_reward_count = 0
	_is_level_completion_choice = false
	_level_completion_context.clear()
	_predation_pool_pending = false


func enter_song_phase(index: int, _phase_data: Dictionary) -> void:
	if not _song_started:
		return
	_phase_index = index
	_phase_claimed = 0
	# Re-evaluate affinity at each phase boundary so mid-run bonding decisions
	# immediately shape the upcoming phase's reward priority.
	var bonded: Dictionary = GameState.get_active_bonded_creature()
	var affinity: String = String(bonded.get("affinity", ""))
	_phase_reward_mix = PERFORMANCE_REWARD_CONTENT.get_phase_mix_for_affinity(affinity, index)
	_tier_awards_this_phase.clear()
	_phase_clutch_spent = false
	_emit_state_changed()


func process_tick(delta: float) -> void:
	_wound_hunger_cooldown = max(_wound_hunger_cooldown - delta, 0.0)
	if _active_offer.is_empty():
		return
	_offer_timer = max(_offer_timer - delta, 0.0)
	if _offer_timer <= 0.0:
		claim_active_offer("auto")


func has_active_offer() -> bool:
	return not _active_offer.is_empty()


func claim_active_offer(source: String = "manual") -> void:
	if _active_offer.is_empty():
		return
	var reward_data: Dictionary = _active_offer.duplicate(true)
	var effect: Dictionary = reward_data.get("effect", {})
	var effect_type: String = String(effect.get("type", ""))
	if not effect_type.is_empty():
		_runtime_effects[effect_type] = effect.duplicate(true)
	var reward_id: String = String(reward_data.get("id", ""))
	if not reward_id.is_empty():
		if GameState.has_method("add_upgrade"):
			GameState.add_upgrade(reward_id)
		if not _claimed_reward_ids.has(reward_id):
			_claimed_reward_ids.append(reward_id)
	_claimed_rewards.append(reward_data)
	_active_offer.clear()
	_offer_timer = 0.0
	_is_level_completion_choice = false
	emit_signal("reward_claimed", reward_data, source)
	emit_signal("proc_feedback", String(reward_data.get("claim_text", "TAKEN")), reward_data.get("feedback_color", Color(0.92, 0.76, 0.42, 1.0)))
	_emit_state_changed()
	emit_signal("offer_ended")
	_show_next_queued_offer()


func sync_from_gamestate() -> void:
	# Restores runtime effects and claimed status from persistent GameState upgrades.
	# Essential for multi-level runs where the director is re-instantiated.
	if not GameState.has_method("has_upgrade"):
		return
		
	for reward_id in PERFORMANCE_REWARD_CONTENT.REWARD_ORDER:
		if GameState.call("has_upgrade", reward_id):
			var reward_data: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(reward_id)
			if not reward_data.is_empty():
				var effect: Dictionary = reward_data.get("effect", {})
				var effect_type: String = String(effect.get("type", ""))
				if not effect_type.is_empty():
					_runtime_effects[effect_type] = effect.duplicate(true)
				if not _claimed_reward_ids.has(reward_id):
					_claimed_reward_ids.append(reward_id)
				if not _reserved_reward_ids.has(reward_id):
					_reserved_reward_ids.append(reward_id)
	_emit_state_changed()


func get_active_offer() -> Dictionary:
	return _active_offer.duplicate(true)


func get_active_offer_time_left() -> float:
	return _offer_timer


func get_runtime_effect(effect_type: String) -> Dictionary:
	if not _runtime_effects.has(effect_type):
		return {}
	return Dictionary(_runtime_effects[effect_type]).duplicate(true)


func get_status_snapshot() -> Dictionary:
	var next_threshold: float = 0.0
	if _next_threshold_index < _run_thresholds.size():
		next_threshold = float(_run_thresholds[_next_threshold_index])
	var rewards_remaining: int = PERFORMANCE_REWARD_CONTENT.REWARD_ORDER.size() - _claimed_reward_ids.size()
	var claimed_tags: Array[String] = []
	for reward in _claimed_rewards:
		claimed_tags.append(String(reward.get("readout", reward.get("title", ""))))
	var score_grade: String = "--"
	if _run_stats != null and is_instance_valid(_run_stats) and _run_stats.has_method("get_grade"):
		score_grade = String(_run_stats.call("get_grade"))
	return {
		"phase_index": _phase_index,
		"run_progress": _run_progress,
		"run_score": _last_run_score,
		"bonus_progress": _bonus_progress,
		"next_threshold": next_threshold,
		"phase_claimed": _phase_claimed,
		"total_claimed": _claimed_rewards.size(),
		"rewards_remaining": max(rewards_remaining, 0),
		"claimed_tags": claimed_tags,
		"phase_mix": _phase_reward_mix.duplicate(),
		"offer_active": not _active_offer.is_empty(),
		"offer_time_left": _offer_timer,
		"score_grade": score_grade,
		"exhausted": _is_reward_pack_exhausted()
	}


func _connect_eventbus() -> void:
	if not EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.connect(_on_enemy_defeated)
	if not EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	if not EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.connect(_on_player_parried)
	if not EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.connect(_on_player_took_damage)
	if not EventBus.combat_started.is_connected(_on_combat_started):
		EventBus.combat_started.connect(_on_combat_started)
	if not EventBus.phrase_milestone.is_connected(_on_phrase_milestone):
		EventBus.phrase_milestone.connect(_on_phrase_milestone)
	if not EventBus.tier_changed.is_connected(_on_tier_changed):
		EventBus.tier_changed.connect(_on_tier_changed)
	if not EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.connect(_on_ultimate_fired)
	if not EventBus.creature_eaten.is_connected(_on_creature_eaten):
		EventBus.creature_eaten.connect(_on_creature_eaten)
	if not EventBus.bonded_support_triggered.is_connected(_on_bonded_support_triggered):
		EventBus.bonded_support_triggered.connect(_on_bonded_support_triggered)


func _exit_tree() -> void:
	if EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.disconnect(_on_enemy_defeated)
	if EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.disconnect(_on_timed_attack_resolved)
	if EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.disconnect(_on_player_parried)
	if EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.disconnect(_on_player_took_damage)
	if EventBus.combat_started.is_connected(_on_combat_started):
		EventBus.combat_started.disconnect(_on_combat_started)
	if EventBus.phrase_milestone.is_connected(_on_phrase_milestone):
		EventBus.phrase_milestone.disconnect(_on_phrase_milestone)
	if EventBus.tier_changed.is_connected(_on_tier_changed):
		EventBus.tier_changed.disconnect(_on_tier_changed)
	if EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.disconnect(_on_ultimate_fired)
	if EventBus.creature_eaten.is_connected(_on_creature_eaten):
		EventBus.creature_eaten.disconnect(_on_creature_eaten)
	if EventBus.bonded_support_triggered.is_connected(_on_bonded_support_triggered):
		EventBus.bonded_support_triggered.disconnect(_on_bonded_support_triggered)
	
	if _run_stats != null and is_instance_valid(_run_stats):
		if _run_stats.has_signal("score_changed") and _run_stats.score_changed.is_connected(_on_run_score_changed):
			_run_stats.score_changed.disconnect(_on_run_score_changed)


func _connect_run_stats() -> void:
	if _run_stats == null or not is_instance_valid(_run_stats):
		return
	if _run_stats.has_signal("score_changed") and not _run_stats.score_changed.is_connected(_on_run_score_changed):
		_run_stats.score_changed.connect(_on_run_score_changed)
	if _run_stats.has_method("reset"):
		_last_run_score = int(_run_stats.get("run_score"))
		_refresh_run_progress()


func _emit_state_changed() -> void:
	emit_signal("state_changed")


func _add_bonus_progress(amount: float) -> void:
	if not _song_started or _phase_index < 0 or amount <= 0.0:
		return
	_bonus_progress += amount
	_refresh_run_progress()
	_check_thresholds()


func _refresh_run_progress() -> void:
	_run_progress = float(_last_run_score) + _bonus_progress
	_emit_state_changed()


func _check_thresholds() -> void:
	while _next_threshold_index < _run_thresholds.size() and _run_progress >= float(_run_thresholds[_next_threshold_index]):
		_next_threshold_index += 1
		_phase_claimed += 1
		_queue_reward_offer()
	if _is_reward_pack_exhausted() and not _exhaustion_announced:
		_exhaustion_announced = true
		emit_signal("proc_feedback", "PACK FED", Color(0.90, 0.80, 0.44, 1.0))
	_emit_state_changed()


func _queue_reward_offer() -> void:
	if not offers_enabled:
		banked_reward_count += 1
		return
		
	var reward_id: String = _pick_next_reward_id()
	if reward_id.is_empty():
		if not _exhaustion_announced:
			_exhaustion_announced = true
			emit_signal("proc_feedback", "PACK SEALED", Color(0.76, 0.76, 0.80, 1.0))
		return
	_reserved_reward_ids.append(reward_id)
	if _active_offer.is_empty():
		_start_offer(reward_id)
	else:
		_queued_offer_ids.append(reward_id)


func get_upgrade_choices(count: int = 3) -> Array[Dictionary]:
	return _build_upgrade_choices_for_context(count, {})


func set_level_completion_context(context: Dictionary) -> void:
	_level_completion_context = context.duplicate(true)
	_predation_pool_pending = false


func get_level_completion_context() -> Dictionary:
	return _level_completion_context.duplicate(true)


func consume_pending_predation_offers(max_offers: int = 2) -> Array[Dictionary]:
	if not _predation_pool_pending:
		return []
	_predation_pool_pending = false
	return PREDATION_POOL.build_offers(max_offers)


func _build_upgrade_choices_for_context(count: int, context: Dictionary) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var pool: Array[String] = _build_pool_for_context(context)
	
	# Pick top N
	for i in range(min(count, pool.size())):
		choices.append(PERFORMANCE_REWARD_CONTENT.get_reward(pool[i]))
		
	if bool(context.get("elite_reward_tier", false)):
		_promote_elite_choice(choices, pool)

	return choices


func get_level_completion_choices(count: int = 3) -> Array[Dictionary]:
	_is_level_completion_choice = true
	var context: Dictionary = _level_completion_context.duplicate(true)
	var resolved_count: int = count
	if bool(context.get("predation_pool", false)):
		resolved_count = 1
	_predation_pool_pending = bool(context.get("predation_pool", false))
	return _build_upgrade_choices_for_context(resolved_count, context)


func consume_banked_reward() -> void:
	if _is_level_completion_choice:
		# Structural rewards do not consume banked performance rewards.
		return
	banked_reward_count = max(banked_reward_count - 1, 0)


func _build_pool_for_context(context: Dictionary) -> Array[String]:
	var pool: Array[String] = []
	if bool(context.get("bond_flavored", false)):
		var bond_priority: Array[String] = ["bond_echo", "hollow_pact", "choir_hook", "graveslip_tendons"]
		for reward_id in bond_priority:
			if not _claimed_reward_ids.has(reward_id):
				pool.append(reward_id)
	for id in _phase_reward_mix:
		if not _claimed_reward_ids.has(id) and not pool.has(id):
			pool.append(id)
	for id in PERFORMANCE_REWARD_CONTENT.REWARD_ORDER:
		if not _claimed_reward_ids.has(id) and not pool.has(id):
			pool.append(id)
	return pool


func _promote_elite_choice(choices: Array[Dictionary], pool: Array[String]) -> void:
	if choices.size() <= 0:
		return
	var elite_priority: Array[String] = ["flayed_vessel", "predators_debt", "hollow_pact"]
	for reward_id in elite_priority:
		if not pool.has(reward_id):
			continue
		var elite_reward: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(reward_id)
		if elite_reward.is_empty():
			continue
		var already_present: bool = false
		for existing in choices:
			if String(existing.get("id", "")) == reward_id:
				already_present = true
				break
		if already_present:
			return
		choices[0] = elite_reward
		return


func _pick_next_reward_id() -> String:
	for reward_id in _phase_reward_mix:
		if not _reserved_reward_ids.has(reward_id):
			return reward_id
	for reward_id in PERFORMANCE_REWARD_CONTENT.REWARD_ORDER:
		if not _reserved_reward_ids.has(reward_id):
			return reward_id
	return ""


func notify_boss_threshold(threshold_id: String, points: float, feedback_text: String) -> void:
	if not _song_started or threshold_id.is_empty():
		return
	if _boss_awards_fired.get(threshold_id, false):
		return
	_boss_awards_fired[threshold_id] = true
	var bonus_points: float = max(points, PERFORMANCE_REWARD_CONTENT.BOSS_PROGRESS_BONUS)
	_add_bonus_progress(bonus_points)
	if not feedback_text.is_empty():
		emit_signal("proc_feedback", feedback_text, Color(0.94, 0.56, 0.18, 1.0))


func _start_offer(reward_id: String) -> void:
	var reward_data: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(reward_id)
	if reward_data.is_empty():
		return
	reward_data["phase_index"] = _phase_index
	reward_data["threshold_index"] = max(_phase_claimed - 1, 0)
	_active_offer = reward_data
	_offer_timer = PERFORMANCE_REWARD_CONTENT.OFFER_DURATION
	emit_signal("offer_started", reward_data)
	_emit_state_changed()


func _show_next_queued_offer() -> void:
	if _queued_offer_ids.is_empty():
		if _is_reward_pack_exhausted() and not _exhaustion_announced:
			_exhaustion_announced = true
			emit_signal("proc_feedback", "PACK FED", Color(0.90, 0.80, 0.44, 1.0))
		return
	var next_reward_id: String = _queued_offer_ids.pop_front()
	_start_offer(next_reward_id)


func _on_enemy_defeated(_enemy_id: int) -> void:
	# Carrion Brand: 3 kills → mend + charge
	var pulse_effect: Dictionary = get_runtime_effect("kill_chain_pulse")
	if not pulse_effect.is_empty():
		_kill_chain_count += 1
		var kills_required: int = int(pulse_effect.get("kills_required", 3))
		if kills_required > 0 and _kill_chain_count >= kills_required:
			_kill_chain_count = 0
			var healed: float = GameState.heal_player(float(pulse_effect.get("heal_value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_reward_support_charge"):
				_run_growth.call("gain_reward_support_charge", float(pulse_effect.get("support_charge", 0.0)))
			emit_signal("proc_feedback", "BRAND FEEDS", Color(0.92, 0.58, 0.30, 1.0))
	# Flayed Vessel: 5 kills → mend 8 + charge 25
	var heavy_effect: Dictionary = get_runtime_effect("kill_chain_heavy")
	if not heavy_effect.is_empty():
		_kill_chain_heavy_count += 1
		var heavy_required: int = int(heavy_effect.get("kills_required", 5))
		if heavy_required > 0 and _kill_chain_heavy_count >= heavy_required:
			_kill_chain_heavy_count = 0
			var healed: float = GameState.heal_player(float(heavy_effect.get("heal_value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_reward_support_charge"):
				_run_growth.call("gain_reward_support_charge", float(heavy_effect.get("support_charge", 0.0)))
			emit_signal("proc_feedback", "VESSEL FEEDS", Color(0.96, 0.48, 0.28, 1.0))


func _on_timed_attack_resolved(_lane: int, quality: String, _damage: float) -> void:
	# Veilstrike Chain: 3 perfect attacks in a row → charge 20
	var chain_effect: Dictionary = get_runtime_effect("perfect_strike_chain")
	if not chain_effect.is_empty():
		if quality == "perfect":
			_perfect_strike_streak += 1
			var streak_required: int = int(chain_effect.get("streak_required", 3))
			if _perfect_strike_streak >= streak_required:
				_perfect_strike_streak = 0
				if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_reward_support_charge"):
					_run_growth.call("gain_reward_support_charge", float(chain_effect.get("support_charge", 0.0)))
				emit_signal("proc_feedback", "CHAIN FIRES", Color(0.78, 0.94, 0.62, 1.0))
		elif quality != "perfect":
			_perfect_strike_streak = 0


func _on_player_parried(_lane: int, quality: String, _reflect_damage: float) -> void:
	match quality:
		"perfect":
			var support_effect: Dictionary = get_runtime_effect("perfect_parry_support_charge")
			if not support_effect.is_empty() and _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_reward_support_charge"):
				_run_growth.call("gain_reward_support_charge", float(support_effect.get("value", 0.0)))
				emit_signal("proc_feedback", "HOOK PRIES OPEN", Color(0.86, 0.88, 0.40, 1.0))


func _on_player_took_damage(_amount: float, _source_lane: int) -> void:
	# Graveslip Tendons: low HP clutch heal + stamina
	var clutch_effect: Dictionary = get_runtime_effect("low_hp_clutch")
	if not clutch_effect.is_empty() and not _phase_clutch_spent:
		var hp_threshold: float = float(clutch_effect.get("hp_threshold", 0.45))
		if GameState.get_hp_percent() <= hp_threshold:
			_phase_clutch_spent = true
			var healed: float = GameState.heal_player(float(clutch_effect.get("heal_value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			if _combat_meter != null and is_instance_valid(_combat_meter) and _combat_meter.has_method("restore_stamina"):
				_combat_meter.call("restore_stamina", float(clutch_effect.get("stamina_value", 0.0)))
			emit_signal("proc_feedback", "GRAVESLIP HOLDS", Color(0.62, 0.86, 1.0, 1.0))
	# Wound Hunger: every hit taken → support charge
	var wound_effect: Dictionary = get_runtime_effect("damage_to_charge")
	if not wound_effect.is_empty() and _wound_hunger_cooldown <= 0.0:
		_wound_hunger_cooldown = WOUND_HUNGER_COOLDOWN
		if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_reward_support_charge"):
			_run_growth.call("gain_reward_support_charge", float(wound_effect.get("value", 0.0)))
		emit_signal("proc_feedback", "HUNGER RISES", Color(0.92, 0.40, 0.36, 1.0))


func _on_bonded_support_triggered(_species_id: String, _lane: int, _effect_id: String) -> void:
	var bond_effect: Dictionary = get_runtime_effect("support_trigger_heal")
	if bond_effect.is_empty():
		return
	var healed: float = GameState.heal_player(float(bond_effect.get("value", 0.0)))
	if healed > 0.0:
		EventBus.emit_signal("player_healed", healed)
	emit_signal("proc_feedback", "BOND ANSWERS", Color(0.58, 0.82, 0.92, 1.0))


func _on_combat_started(_enemy_data: Array) -> void:
	_phase_clutch_spent = false
	# Hollow Pact: bond kept → mend 8 + charge 15 on each encounter start
	var pact_effect: Dictionary = get_runtime_effect("bond_entry_pulse")
	if pact_effect.is_empty():
		return
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	if active_creature.is_empty():
		return
	var healed: float = GameState.heal_player(float(pact_effect.get("heal_value", 0.0)))
	if healed > 0.0:
		EventBus.emit_signal("player_healed", healed)
	if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_reward_support_charge"):
		_run_growth.call("gain_reward_support_charge", float(pact_effect.get("support_charge", 0.0)))
	emit_signal("proc_feedback", "PACT HOLDS", Color(0.62, 0.78, 0.98, 1.0))


func _on_phrase_milestone(count: int) -> void:
	if count > 8:
		_add_bonus_progress(PERFORMANCE_REWARD_CONTENT.EXTENDED_PHRASE_PROGRESS_BONUS)
	elif count == 8:
		_add_bonus_progress(float(PERFORMANCE_REWARD_CONTENT.PHRASE_PROGRESS_BONUS.get(8, 0.0)))
	elif count >= 5:
		_add_bonus_progress(float(PERFORMANCE_REWARD_CONTENT.PHRASE_PROGRESS_BONUS.get(5, 0.0)))
	elif count >= 3:
		_add_bonus_progress(float(PERFORMANCE_REWARD_CONTENT.PHRASE_PROGRESS_BONUS.get(3, 0.0)))


func _on_tier_changed(new_tier: String, _old_tier: String) -> void:
	if not _song_started or _phase_index < 0:
		return
	if _tier_awards_this_phase.get(new_tier, false):
		return
	var points: float = float(PERFORMANCE_REWARD_CONTENT.TIER_PROGRESS_BONUS.get(new_tier, 0.0))
	if points <= 0.0:
		return
	_tier_awards_this_phase[new_tier] = true
	_add_bonus_progress(points)


func _on_ultimate_fired(_power: float) -> void:
	pass


func _on_creature_eaten(_creature_data: Dictionary) -> void:
	# Predator's Debt: each eat this run → +2 damage, up to 3 stacks
	var ratchet_effect: Dictionary = get_runtime_effect("eat_damage_ratchet")
	if ratchet_effect.is_empty():
		return
	var max_stacks: int = int(ratchet_effect.get("max_stacks", 3))
	if _eat_ratchet_stacks >= max_stacks:
		return
	_eat_ratchet_stacks += 1
	GameState.player_base_damage += float(ratchet_effect.get("damage_per_eat", 2.0))
	emit_signal("proc_feedback", "DEBT PAID  +%d" % _eat_ratchet_stacks, Color(0.88, 0.56, 0.72, 1.0))


func _is_reward_pack_exhausted() -> bool:
	if _next_threshold_index < _run_thresholds.size():
		return false
	if not _active_offer.is_empty():
		return false
	if not _queued_offer_ids.is_empty():
		return false
	return _pick_next_reward_id().is_empty()


func _on_run_score_changed(score: int) -> void:
	if not _song_started:
		_last_run_score = score
		return
	if score < _last_run_score:
		_bonus_progress = 0.0
	_last_run_score = score
	_refresh_run_progress()
	_check_thresholds()
