extends Node

const PERFORMANCE_REWARD_CONTENT = preload("res://data/PerformanceRewardContent.gd")
const RITUAL_CONTENT = preload("res://data/RitualConsumableContent.gd")
const PREDATION_POOL = preload("res://systems/PredationPool.gd")
const WOUND_HUNGER_COOLDOWN: float = 1.25
const WEIGHT_PERFORMANCE: float = 0.40
const WEIGHT_KILL_PRESSURE: float = 0.20
const WEIGHT_FAMILY_AFFINITY: float = 0.20
const WEIGHT_BOND_EAT: float = 0.15
const WEIGHT_TENDENCY: float = 0.05
const VERDICT_CONTROLLED_SCORE: int = 300
const VERDICT_DOMINANT_SCORE: int = 700
const VERDICT_DEVOURING_SCORE: int = 1200
const VERDICT_PREDATION_KILLS: int = 7
const VERDICT_ELITE_KILLS: int = 10
const VERDICT_CLEAN_HIT_LIMIT: int = 3
const LEVEL_COMPLETION_MIN_CHOICES: int = 1
const LEVEL_COMPLETION_MAX_CHOICES: int = 3
const CHOICE_POWER_STEP: float = 180.0
const CHOICE_SCORE_STEP: int = 450
const HUNT_MOMENTUM_MAX: float = 100.0
const HUNT_MOMENTUM_DECAY_PER_SEC: float = 7.5
const HUNT_MOMENTUM_KILL_GAIN: float = 13.0
const HUNT_MOMENTUM_PERFECT_GAIN: float = 6.0
const HUNT_MOMENTUM_PARRY_GAIN: float = 9.0
const HUNT_MOMENTUM_DODGE_GAIN: float = 5.0
const HUNT_MOMENTUM_HIT_LOSS: float = 28.0
const HUNT_MOMENTUM_LOW_HP_CAP: float = 42.0
const HUNT_MOMENTUM_RECENT_HIT_CAP: float = 34.0
const HUNT_MOMENTUM_RECENT_HIT_SECONDS: float = 2.0
const HUNT_PRESSURE_SPAWN_MIN: float = 0.88
const HUNT_PRESSURE_SPAWN_MAX: float = 1.12
const HUNT_PRESSURE_SCORE_WEIGHT: float = 0.45
const HUNT_PRESSURE_STREAK_WEIGHT: float = 0.35
const HUNT_PRESSURE_CLEAN_WEIGHT: float = 0.20
const HUNT_STREAK_SCORE_CAP: int = 10
const HUNT_CLEAN_HIT_SOFT_LIMIT: int = 3
const KILL_STREAK_PROGRESS_BONUS: float = 12.0
const PERFECT_STREAK_PROGRESS_BONUS: float = 10.0
const PARRY_STREAK_PROGRESS_BONUS: float = 12.0
const DODGE_STREAK_PROGRESS_BONUS: float = 8.0
const DODGE_STREAK_SUPPORT_CHARGE: float = 4.0
const KILL_STREAK_SUPPORT_CHARGE: float = 5.0

# Predatory Tempo Architecture v1 mapping:
# - puncture: micro-time combat punctuation
# - void: Suspension (slowed high-value choices under pressure)
# - decree: boss/world law shifts
const TEMPO_MASTERY_PER_PHASE_CAP: Dictionary = {
	"puncture": 3,
	"void": 2,
	"decree": 2
}
const TEMPO_MASTERY_POINTS: Dictionary = {
	"puncture": {
		"perfect_hit": 1.0,
		"perfect_parry": 1.25
	},
	"void": {
		"choice_commit": 0.0,
		"choice_timeout": 0.0
	},
	"decree": {
		"law_response": 1.5
	}
}

signal state_changed()
signal offer_started(reward_data: Dictionary)
signal offer_ended()
signal reward_claimed(reward_data: Dictionary, source: String)
signal proc_feedback(text: String, color: Color)
signal pressure_bias_changed(snapshot: Dictionary)

var _combat_meter: CombatMeter = null

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

var offers_enabled: bool = false
var banked_reward_count: int = 0
var _is_level_completion_choice: bool = false
var _level_completion_context: Dictionary = {}
var _predation_pool_pending: bool = false

var _active_offer: Dictionary = {}
var _offer_timer: float = 0.0
var _queued_offer_ids: Array[String] = []
var _stored_reward_ids: Array[String] = []
var _reserved_reward_ids: Array[String] = []
var _claimed_reward_ids: Array[String] = []
var _claimed_rewards: Array[Dictionary] = []
var _claimed_ritual_ids: Array[String] = []
var _runtime_effects: Dictionary = {}
var _kill_chain_count: int = 0
var _kill_chain_heavy_count: int = 0
var _perfect_strike_streak: int = 0
var _kill_streak: int = 0
var _parry_streak: int = 0
var _dodge_streak: int = 0
var _hunt_momentum: float = 0.0
var _recent_hit_timer: float = 0.0
var _last_pressure_snapshot: Dictionary = {}
var _eat_ratchet_stacks: int = 0
var _wound_hunger_cooldown: float = 0.0
var _reward_pressure_band: Dictionary = {
	"offer_decay_mult": 1.0,
	"level_choice_delta": 0
}
var _tempo_mastery_claimed_per_phase: Dictionary = {
	"puncture": 0,
	"void": 0,
	"decree": 0
}
var _tempo_decree_event_claims: Dictionary = {}


func bind_runtime(combat_meter_ref: CombatMeter, _run_growth_ref: Node = null, _run_stats_ref: Node = null) -> void:
	_combat_meter = combat_meter_ref
	_connect_eventbus()
	_connect_run_stats()


func set_difficulty_modifiers(mods: Dictionary) -> void:
	_reward_pressure_band = {
		"offer_decay_mult": 1.0,
		"level_choice_delta": 0
	}
	if mods.is_empty():
		return
	var reward_pressure: Dictionary = Dictionary(mods.get("reward_pressure", {}))
	_reward_pressure_band["offer_decay_mult"] = clampf(float(reward_pressure.get("offer_decay_mult", 1.0)), 0.7, 1.5)
	_reward_pressure_band["level_choice_delta"] = clampi(int(reward_pressure.get("level_choice_delta", 0)), -2, 1)


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
	_stored_reward_ids.clear()
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
	_kill_streak = 0
	_parry_streak = 0
	_dodge_streak = 0
	_hunt_momentum = 0.0
	_recent_hit_timer = 0.0
	_last_pressure_snapshot.clear()
	_eat_ratchet_stacks = 0
	_wound_hunger_cooldown = 0.0
	_tempo_mastery_claimed_per_phase = {
		"puncture": 0,
		"void": 0,
		"decree": 0
	}
	_tempo_decree_event_claims.clear()
	_emit_state_changed()


func reset_full_run_data() -> void:
	_reserved_reward_ids.clear()
	_stored_reward_ids.clear()
	_claimed_reward_ids.clear()
	_claimed_rewards.clear()
	_claimed_ritual_ids.clear()
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
	_tempo_mastery_claimed_per_phase = {
		"puncture": 0,
		"void": 0,
		"decree": 0
	}
	_emit_state_changed()


func process_tick(delta: float) -> void:
	_wound_hunger_cooldown = max(_wound_hunger_cooldown - delta, 0.0)
	_recent_hit_timer = max(_recent_hit_timer - delta, 0.0)
	if _hunt_momentum > 0.0:
		_hunt_momentum = maxf(_hunt_momentum - HUNT_MOMENTUM_DECAY_PER_SEC * delta, 0.0)
	_emit_pressure_bias_if_changed()
	if _active_offer.is_empty():
		return
	var decay_mult: float = float(_reward_pressure_band.get("offer_decay_mult", 1.0))
	_offer_timer = max(_offer_timer - (delta * decay_mult), 0.0)
	if _offer_timer <= 0.0:
		claim_active_offer("auto")


func has_active_offer() -> bool:
	return not _active_offer.is_empty()


func claim_active_offer(source: String = "manual") -> void:
	if _active_offer.is_empty():
		return
	var reward_data: Dictionary = _active_offer.duplicate(true)
	var lane: String = String(reward_data.get("lane", ""))
	var reward_id: String = String(reward_data.get("id", ""))
	var ecology_result: Dictionary = {"accepted": true}
	if GameState.has_method("add_reward_to_ecology"):
		ecology_result = GameState.add_reward_to_ecology(reward_data)
	if not bool(ecology_result.get("accepted", true)):
		_active_offer.clear()
		_offer_timer = 0.0
		emit_signal("proc_feedback", "SLOTS SEALED", Color(0.86, 0.58, 0.58, 1.0))
		_emit_state_changed()
		emit_signal("offer_ended")
		_show_next_queued_offer()
		return

	var effect: Dictionary = reward_data.get("effect", {})
	var effect_type: String = String(effect.get("type", ""))
	if lane != "consumable" and not effect_type.is_empty():
		_runtime_effects[effect_type] = effect.duplicate(true)
	if not reward_id.is_empty():
		_stored_reward_ids.erase(reward_id)
		_refresh_banked_reward_count_from_stored()
		if lane == "consumable":
			if not _claimed_ritual_ids.has(reward_id):
				_claimed_ritual_ids.append(reward_id)
		elif not _claimed_reward_ids.has(reward_id):
			_claimed_reward_ids.append(reward_id)
	if lane != "consumable":
		_claimed_rewards.append(reward_data)
	_active_offer.clear()
	_offer_timer = 0.0
	_is_level_completion_choice = false
	emit_signal("reward_claimed", reward_data, source)
	emit_signal("proc_feedback", String(reward_data.get("claim_text", "TAKEN")), reward_data.get("feedback_color", Color(0.92, 0.76, 0.42, 1.0)))
	_emit_state_changed()
	emit_signal("offer_ended")
	_show_next_queued_offer()


func sync_from_reward_state() -> void:
	# Restores runtime effects and claimed status from RewardState and legacy upgrades.
	# Essential for multi-level runs where the director is re-instantiated.
	
	# Primary: Build from structured RewardState
	var snapshot: Dictionary = GameState.get_reward_ecology_snapshot()
	var loot: Dictionary = snapshot.get("loot", {})
	var artifacts: Dictionary = snapshot.get("artifact", {})
	
	for slot in loot:
		for reward_id in loot[slot]:
			_register_synced_reward(reward_id)
			
	for slot in artifacts:
		for reward_id in artifacts[slot]:
			_register_synced_reward(reward_id)
	
	_emit_state_changed()


func _register_synced_reward(reward_id: String) -> void:
	var reward_data: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(reward_id)
	if reward_data.is_empty():
		return
	var effect: Dictionary = reward_data.get("effect", {})
	var effect_type: String = String(effect.get("type", ""))
	if not effect_type.is_empty():
		_runtime_effects[effect_type] = effect.duplicate(true)
	if not _claimed_reward_ids.has(reward_id):
		_claimed_reward_ids.append(reward_id)
	if not _reserved_reward_ids.has(reward_id):
		_reserved_reward_ids.append(reward_id)
	if not _claimed_rewards.has(reward_data):
		_claimed_rewards.append(reward_data)


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
	if RunStats.has_method("get_grade"):
		score_grade = String(RunStats.get_grade())
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
		"exhausted": _is_reward_pack_exhausted(),
		"pressure_bias": get_pressure_bias_snapshot()
	}


func get_pressure_bias_snapshot() -> Dictionary:
	var momentum_ratio: float = _resolve_effective_hunt_momentum_ratio()
	var streak_ratio: float = clampf(float(maxi(_kill_streak, maxi(_perfect_strike_streak, maxi(_parry_streak, _dodge_streak)))) / float(HUNT_STREAK_SCORE_CAP), 0.0, 1.0)
	var clean_ratio: float = 1.0
	clean_ratio = 1.0 - clampf(float(RunStats.get("times_hit")) / float(HUNT_CLEAN_HIT_SOFT_LIMIT), 0.0, 1.0)
	var pressure_ratio: float = clampf(
		momentum_ratio * HUNT_PRESSURE_SCORE_WEIGHT +
		streak_ratio * HUNT_PRESSURE_STREAK_WEIGHT +
		clean_ratio * HUNT_PRESSURE_CLEAN_WEIGHT,
		0.0,
		1.0
	)
	var spawn_mult: float = lerpf(HUNT_PRESSURE_SPAWN_MAX, HUNT_PRESSURE_SPAWN_MIN, pressure_ratio)
	if _recent_hit_timer > 0.0 or (GameState.has_method("get_hp_percent") and GameState.get_hp_percent() <= 0.35):
		spawn_mult = maxf(spawn_mult, 1.0)
	return {
		"momentum": _hunt_momentum,
		"momentum_ratio": momentum_ratio,
		"pressure_ratio": pressure_ratio,
		"spawn_interval_mult": spawn_mult,
		"kill_streak": _kill_streak,
		"perfect_streak": _perfect_strike_streak,
		"parry_streak": _parry_streak,
		"dodge_streak": _dodge_streak,
		"recent_hit_timer": _recent_hit_timer
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
	if not EventBus.player_dodged.is_connected(_on_player_dodged):
		EventBus.player_dodged.connect(_on_player_dodged)
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
	if EventBus.player_dodged.is_connected(_on_player_dodged):
		EventBus.player_dodged.disconnect(_on_player_dodged)
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
	
	if RunStats.has_signal("score_changed") and RunStats.score_changed.is_connected(_on_run_score_changed):
		RunStats.score_changed.disconnect(_on_run_score_changed)


func _connect_run_stats() -> void:
	if not RunStats.score_changed.is_connected(_on_run_score_changed):
		RunStats.score_changed.connect(_on_run_score_changed)
	if RunStats.has_method("reset"):
		_last_run_score = int(RunStats.get("run_score"))
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


func _add_hunt_momentum(amount: float) -> void:
	if amount <= 0.0:
		return
	_hunt_momentum = minf(_hunt_momentum + amount, HUNT_MOMENTUM_MAX)
	_emit_pressure_bias_if_changed()


func _resolve_effective_hunt_momentum_ratio() -> float:
	var effective_momentum: float = _hunt_momentum
	if GameState.has_method("get_hp_percent") and GameState.get_hp_percent() <= 0.35:
		effective_momentum = minf(effective_momentum, HUNT_MOMENTUM_LOW_HP_CAP)
	if _recent_hit_timer > 0.0:
		effective_momentum = minf(effective_momentum, HUNT_MOMENTUM_RECENT_HIT_CAP)
	return clampf(effective_momentum / HUNT_MOMENTUM_MAX, 0.0, 1.0)


func _emit_pressure_bias_if_changed() -> void:
	var snapshot: Dictionary = get_pressure_bias_snapshot()
	if snapshot == _last_pressure_snapshot:
		return
	_last_pressure_snapshot = snapshot.duplicate(true)
	emit_signal("pressure_bias_changed", snapshot)


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
	var reward_id: String = _pick_next_reward_id()
	if reward_id.is_empty():
		if not _exhaustion_announced:
			_exhaustion_announced = true
			emit_signal("proc_feedback", "PACK SEALED", Color(0.76, 0.76, 0.80, 1.0))
		return
	_reserved_reward_ids.append(reward_id)
	if not offers_enabled:
		_stored_reward_ids.append(reward_id)
		_refresh_banked_reward_count_from_stored()
		emit_signal("proc_feedback", "REWARD STORED", Color(0.92, 0.76, 0.42, 1.0))
		_emit_state_changed()
		return
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
	
	for i in range(min(count, pool.size())):
		choices.append(PERFORMANCE_REWARD_CONTENT.get_reward(pool[i]))

	var ritual_offer: Dictionary = _pick_ritual_offer(context)
	if not ritual_offer.is_empty():
		if choices.size() >= count and count > 0:
			choices[count - 1] = ritual_offer
		else:
			choices.append(ritual_offer)

	if bool(context.get("elite_reward_tier", false)):
		_promote_elite_choice(choices, pool)

	return choices


func get_level_completion_choices(count: int = 3) -> Array[Dictionary]:
	_is_level_completion_choice = true
	var context: Dictionary = _build_completion_context_with_performance_verdict()
	var resolved_count: int = _resolve_level_completion_choice_count(count, context)
	_predation_pool_pending = bool(context.get("predation_pool", false)) and _has_predation_offers_available()
	var had_stored_rewards: bool = not _stored_reward_ids.is_empty()
	var stored_choices: Array[Dictionary] = _build_stored_reward_choices(resolved_count)
	if stored_choices.size() >= resolved_count:
		_finalize_stored_reward_choices(had_stored_rewards, stored_choices)
		return stored_choices
	var fallback_choices: Array[Dictionary] = _build_upgrade_choices_for_context(resolved_count, context)
	for choice in fallback_choices:
		if stored_choices.size() >= resolved_count:
			break
		var choice_id: String = String(choice.get("id", ""))
		var already_present: bool = false
		for stored_choice in stored_choices:
			if String(stored_choice.get("id", "")) == choice_id:
				already_present = true
				break
		if not already_present:
			stored_choices.append(choice)
	_finalize_stored_reward_choices(had_stored_rewards, stored_choices)
	return stored_choices


func _resolve_level_completion_choice_count(requested_count: int, context: Dictionary) -> int:
	var score: int = int(context.get("performance_score", 0))
	var kills: int = int(context.get("performance_kills", 0))
	var hits_taken: int = int(context.get("performance_hits_taken", 99))
	var level_index: int = int(context.get("regular_level_index", 0))
	var growth_level: int = int(context.get("growth_level", 1))
	var power_level: float = float(context.get("power_level", 0.0))
	if power_level <= 0.0 and GameState.has_method("get_power_level"):
		power_level = GameState.get_power_level()

	var choice_count: int = LEVEL_COMPLETION_MIN_CHOICES
	if score >= VERDICT_CONTROLLED_SCORE or kills >= 4:
		choice_count += 1
	if score >= VERDICT_DOMINANT_SCORE or kills >= VERDICT_PREDATION_KILLS:
		choice_count += 1
	if score >= VERDICT_DEVOURING_SCORE and hits_taken <= VERDICT_CLEAN_HIT_LIMIT:
		choice_count += 1

	choice_count += int(floor(power_level / CHOICE_POWER_STEP))
	choice_count += int(floor(float(growth_level - 1) / 3.0))
	choice_count += int(floor(float(max(score - VERDICT_CONTROLLED_SCORE, 0)) / float(CHOICE_SCORE_STEP)))

	var early_run_cap: int = 1 + clampi(level_index, 0, 2)
	var requested_cap: int = max(requested_count, LEVEL_COMPLETION_MIN_CHOICES)
	var hard_cap: int = mini(LEVEL_COMPLETION_MAX_CHOICES, requested_cap)
	return clampi(choice_count, LEVEL_COMPLETION_MIN_CHOICES, mini(hard_cap, early_run_cap))


func _finalize_stored_reward_choices(had_stored_rewards: bool, choices: Array[Dictionary]) -> void:
	if not had_stored_rewards:
		return
	for choice in choices:
		var reward_id: String = String(choice.get("id", ""))
		if not reward_id.is_empty():
			_stored_reward_ids.erase(reward_id)
	_refresh_banked_reward_count_from_stored()


func _refresh_banked_reward_count_from_stored() -> void:
	banked_reward_count = _stored_reward_ids.size()


func _build_stored_reward_choices(count: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for reward_id in _stored_reward_ids:
		if choices.size() >= count:
			break
		var reward_data: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(reward_id)
		if reward_data.is_empty():
			continue
		if GameState.has_method("is_reward_offer_eligible") and not GameState.is_reward_offer_eligible(reward_data):
			continue
		choices.append(reward_data)
	return choices


func _has_predation_offers_available() -> bool:
	return not PREDATION_POOL.build_offers(1).is_empty()


func _build_completion_context_with_performance_verdict() -> Dictionary:
	var context: Dictionary = _level_completion_context.duplicate(true)
	
	var score: int = int(RunStats.get("run_score"))
	var kills: int = int(RunStats.get("kills"))
	var hits_taken: int = int(RunStats.get("times_hit"))
	var perfects: int = int(RunStats.get("perfect_attacks")) + int(RunStats.get("perfect_parries"))
	var support_triggers: int = int(RunStats.get("support_triggers"))
	var bonds: int = int(RunStats.get("bonds"))
	var eats: int = int(RunStats.get("eats"))
	var grade: String = _get_score_grade_for_verdict(score)
	var clean_hunt: bool = hits_taken <= VERDICT_CLEAN_HIT_LIMIT

	context["performance_verdict"] = grade
	context["performance_score"] = score
	context["performance_kills"] = kills
	context["performance_hits_taken"] = hits_taken

	if score >= VERDICT_DOMINANT_SCORE and kills >= VERDICT_PREDATION_KILLS:
		context["predation_pool"] = true

	if score >= VERDICT_DEVOURING_SCORE or (score >= VERDICT_DOMINANT_SCORE and kills >= VERDICT_ELITE_KILLS and clean_hunt):
		context["elite_reward_tier"] = true

	if bonds > eats or (support_triggers >= 2 and perfects >= 4 and clean_hunt):
		context["bond_flavored"] = true

	return context


func _get_score_grade_for_verdict(score: int) -> String:
	if score >= VERDICT_DEVOURING_SCORE:
		return "DEVOURING"
	if score >= VERDICT_DOMINANT_SCORE:
		return "DOMINANT"
	if score >= VERDICT_CONTROLLED_SCORE:
		return "CONTROLLED"
	return "BARELY HELD"


func consume_banked_reward() -> void:
	if _is_level_completion_choice:
		# Structural rewards do not consume banked performance rewards.
		return
	banked_reward_count = max(banked_reward_count - 1, 0)


func _build_pool_for_context(context: Dictionary) -> Array[String]:
	var scored_pool: Array[Dictionary] = []
	var active_affinity: String = _get_active_affinity()
	var tendency_id: String = _get_leading_tendency_id()
	var weight_profile: Dictionary = GameState.get_reward_weight_profile() if GameState.has_method("get_reward_weight_profile") else {}
	for id in PERFORMANCE_REWARD_CONTENT.REWARD_ORDER:
		if _claimed_reward_ids.has(id):
			continue
		var reward_data: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(id)
		if reward_data.is_empty():
			continue
		if GameState.has_method("is_reward_offer_eligible") and not GameState.is_reward_offer_eligible(reward_data):
			continue
		var score: float = _score_offer(
			reward_data,
			active_affinity,
			tendency_id,
			weight_profile,
			context
		)
		scored_pool.append({
			"id": id,
			"score": score
		})

	scored_pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	var pool: Array[String] = []
	for row in scored_pool:
		pool.append(String(row.get("id", "")))
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


func _pick_ritual_offer(context: Dictionary) -> Dictionary:
	if bool(context.get("predation_pool", false)):
		return {}
	if not _should_offer_ritual():
		return {}
	var active_affinity: String = _get_active_affinity()
	var tendency_id: String = _get_leading_tendency_id()
	var weight_profile: Dictionary = GameState.get_reward_weight_profile() if GameState.has_method("get_reward_weight_profile") else {}
	var candidate_rows: Array[Dictionary] = []
	for ritual in RITUAL_CONTENT.get_all_rituals():
		var ritual_id: String = String(ritual.get("id", ""))
		if _claimed_ritual_ids.has(ritual_id):
			continue
		if GameState.has_method("is_reward_offer_eligible") and not GameState.is_reward_offer_eligible(ritual):
			continue
		var score: float = _score_offer(ritual, active_affinity, tendency_id, weight_profile, context)
		candidate_rows.append({
			"ritual": ritual,
			"score": score
		})
	if candidate_rows.is_empty():
		return {}
	candidate_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return Dictionary(candidate_rows[0].get("ritual", {})).duplicate(true)


func _should_offer_ritual() -> bool:
	var score_ratio: float = clampf(_run_progress / 1100.0, 0.0, 1.0)
	var threshold: float = 0.35 - 0.20 * score_ratio
	var kills: int = int(RunStats.get("kills"))
	if kills >= 8:
		threshold -= 0.08
	var roll: float = randf()
	return roll <= clampf(threshold, 0.10, 0.40)


func _score_offer(
	offer_data: Dictionary,
	active_affinity: String,
	tendency_id: String,
	weight_profile: Dictionary,
	context: Dictionary
) -> float:
	var performance_score: float = clampf(_run_progress / 1200.0, 0.0, 1.0)
	var kill_pressure: float = 0.0
	kill_pressure = clampf(float(RunStats.get("kills")) / 25.0, 0.0, 1.0)

	var family_affinity: float = 0.35
	var family_bias: Array = offer_data.get("family_bias", [])
	if not active_affinity.is_empty():
		for family in family_bias:
			if String(family) == active_affinity:
				family_affinity = 1.0
				break

	var bond_eat_alignment: float = 0.5
	var path_bias: String = String(offer_data.get("path_bias", "neutral"))
	var bond_streak: int = int(weight_profile.get("bond_streak", 0))
	var eat_streak: int = int(weight_profile.get("eat_streak", 0))
	if path_bias == "bond":
		bond_eat_alignment = clampf(0.35 + float(bond_streak) * 0.25, 0.0, 1.0)
	elif path_bias == "eat":
		bond_eat_alignment = clampf(0.35 + float(eat_streak) * 0.25, 0.0, 1.0)
	else:
		bond_eat_alignment = 0.55

	var tendency_alignment: float = 0.35
	var tendency_bias: Array = offer_data.get("tendency_bias", [])
	for tendency in tendency_bias:
		if String(tendency) == tendency_id:
			tendency_alignment = 1.0
			break

	var phase_bonus: float = 0.0
	var offer_id: String = String(offer_data.get("id", ""))
	if _phase_reward_mix.has(offer_id):
		phase_bonus += 0.12
	if bool(context.get("bond_flavored", false)) and path_bias == "bond":
		phase_bonus += 0.12
	if bool(context.get("elite_reward_tier", false)):
		phase_bonus += 0.08 * float(offer_data.get("power_tier", 1))

	return (
		WEIGHT_PERFORMANCE * performance_score +
		WEIGHT_KILL_PRESSURE * kill_pressure +
		WEIGHT_FAMILY_AFFINITY * family_affinity +
		WEIGHT_BOND_EAT * bond_eat_alignment +
		WEIGHT_TENDENCY * tendency_alignment +
		phase_bonus
	)


func _get_active_affinity() -> String:
	var bonded: Dictionary = GameState.get_active_bonded_creature()
	return String(bonded.get("affinity", ""))


func _get_leading_tendency_id() -> String:
	if not RunGrowth.has_method("get_tendency_snapshot"):
		return ""
	var snapshot: Dictionary = RunGrowth.get_tendency_snapshot()
	var points: Dictionary = snapshot.get("points", {})
	var levels: Dictionary = snapshot.get("levels", {})
	var best_id: String = ""
	var best_score: float = -1.0
	for tendency_id in points.keys():
		var score: float = float(points.get(tendency_id, 0.0)) + float(levels.get(tendency_id, 0)) * 2.0
		if score > best_score:
			best_score = score
			best_id = String(tendency_id)
	return best_id


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


func notify_tempo_mastery(family: String, event_id: String, payload: Dictionary = {}) -> void:
	if not _song_started or _phase_index < 0:
		return
	var family_id: String = family.to_lower()
	if not TEMPO_MASTERY_PER_PHASE_CAP.has(family_id):
		return
	var cap: int = int(TEMPO_MASTERY_PER_PHASE_CAP.get(family_id, 0))
	var claimed: int = int(_tempo_mastery_claimed_per_phase.get(family_id, 0))
	if claimed >= cap:
		return
	var points: float = _resolve_tempo_mastery_points(family_id, event_id, payload)
	if points <= 0.0:
		return
	if family_id == "decree":
		var decree_key: String = "%s|%s|%s" % [event_id, String(payload.get("response", "")), String(payload.get("quality", ""))]
		if _tempo_decree_event_claims.get(decree_key, false):
			return
		_tempo_decree_event_claims[decree_key] = true
	_tempo_mastery_claimed_per_phase[family_id] = claimed + 1
	_add_bonus_progress(points)
	match family_id:
		"puncture":
			emit_signal("proc_feedback", "TEMPO REND", Color(0.98, 0.80, 0.42, 1.0))
		"void":
			emit_signal("proc_feedback", "TEMPO CHOICE", Color(0.72, 0.92, 1.0, 1.0))
		"decree":
			emit_signal("proc_feedback", "DECREE ANSWERED", Color(0.98, 0.56, 0.24, 1.0))


func _resolve_tempo_mastery_points(family_id: String, event_id: String, payload: Dictionary) -> float:
	if family_id == "void":
		if event_id != "choice_commit":
			return 0.0
		var choice_id: String = String(payload.get("choice", ""))
		var elapsed_seconds: float = maxf(float(payload.get("elapsed_seconds", 99.0)), 0.0)
		if choice_id == "pass":
			return 0.0
		if elapsed_seconds <= 1.4:
			return 1.45
		if elapsed_seconds <= 2.6:
			return 1.10
		if elapsed_seconds <= 4.0:
			return 0.75
		return 0.5
	var family_points: Dictionary = Dictionary(TEMPO_MASTERY_POINTS.get(family_id, {}))
	if not family_points.has(event_id):
		return 0.0
	var base_points: float = float(family_points.get(event_id, 0.0))
	if family_id == "puncture":
		var beat_quality: String = String(payload.get("beat_quality", "off"))
		if beat_quality != "perfect" and beat_quality != "good":
			return 0.0
	if family_id == "decree":
		var quality: String = String(payload.get("quality", "off"))
		if quality == "perfect":
			base_points += 0.5
		elif quality == "good":
			base_points += 0.2
	return base_points


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
	_kill_streak += 1
	_add_hunt_momentum(HUNT_MOMENTUM_KILL_GAIN)
	if _kill_streak > 0 and _kill_streak % 4 == 0:
		_add_bonus_progress(KILL_STREAK_PROGRESS_BONUS)
		if RunGrowth.has_method("gain_reward_support_charge"):
			RunGrowth.gain_reward_support_charge(KILL_STREAK_SUPPORT_CHARGE)
		emit_signal("proc_feedback", "HUNT SURGES", Color(0.92, 0.50, 0.26, 1.0))

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
			if RunGrowth.has_method("gain_reward_support_charge"):
				RunGrowth.gain_reward_support_charge(float(pulse_effect.get("support_charge", 0.0)))
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
			if RunGrowth.has_method("gain_reward_support_charge"):
				RunGrowth.gain_reward_support_charge(float(heavy_effect.get("support_charge", 0.0)))
			emit_signal("proc_feedback", "VESSEL FEEDS", Color(0.96, 0.48, 0.28, 1.0))


func _on_timed_attack_resolved(_lane: int, quality: String, _damage: float, _enemy_id: int) -> void:
	# Veilstrike Chain: 3 perfect attacks in a row → charge 20
	var chain_effect: Dictionary = get_runtime_effect("perfect_strike_chain")
	if quality == "perfect":
		_perfect_strike_streak += 1
		_add_hunt_momentum(HUNT_MOMENTUM_PERFECT_GAIN)
		if _perfect_strike_streak > 0 and _perfect_strike_streak % 3 == 0:
			_add_bonus_progress(PERFECT_STREAK_PROGRESS_BONUS)
			emit_signal("proc_feedback", "PERFECT FEEDS", Color(0.78, 0.94, 0.62, 1.0))
	elif quality == "good":
		_add_hunt_momentum(HUNT_MOMENTUM_PERFECT_GAIN * 0.45)
	else:
		_perfect_strike_streak = 0
	if not chain_effect.is_empty():
		if quality == "perfect":
			var streak_required: int = int(chain_effect.get("streak_required", 3))
			if _perfect_strike_streak >= streak_required:
				_perfect_strike_streak = 0
				if RunGrowth.has_method("gain_reward_support_charge"):
					RunGrowth.gain_reward_support_charge(float(chain_effect.get("support_charge", 0.0)))
				emit_signal("proc_feedback", "CHAIN FIRES", Color(0.78, 0.94, 0.62, 1.0))


func _on_player_parried(_lane: int, quality: String, _reflect_damage: float) -> void:
	match quality:
		"perfect":
			_parry_streak += 1
			_add_hunt_momentum(HUNT_MOMENTUM_PARRY_GAIN)
			if _parry_streak > 0 and _parry_streak % 2 == 0:
				_add_bonus_progress(PARRY_STREAK_PROGRESS_BONUS)
			var support_effect: Dictionary = get_runtime_effect("perfect_parry_support_charge")
			if not support_effect.is_empty() and RunGrowth.has_method("gain_reward_support_charge"):
				RunGrowth.gain_reward_support_charge(float(support_effect.get("value", 0.0)))
				emit_signal("proc_feedback", "HOOK PRIES OPEN", Color(0.86, 0.88, 0.40, 1.0))
		"good":
			_parry_streak = 0
			_add_hunt_momentum(HUNT_MOMENTUM_PARRY_GAIN * 0.45)
		_:
			_parry_streak = 0


func _on_player_took_damage(_amount: float, _source_lane: int) -> void:
	_kill_streak = 0
	_perfect_strike_streak = 0
	_parry_streak = 0
	_dodge_streak = 0
	_recent_hit_timer = HUNT_MOMENTUM_RECENT_HIT_SECONDS
	_hunt_momentum = maxf(_hunt_momentum - HUNT_MOMENTUM_HIT_LOSS, 0.0)
	_emit_pressure_bias_if_changed()

	# Graveslip Tendons: low HP clutch heal + stamina
	var clutch_effect: Dictionary = get_runtime_effect("low_hp_clutch")
	if not clutch_effect.is_empty() and not _phase_clutch_spent:
		var hp_threshold: float = float(clutch_effect.get("hp_threshold", 0.45))
		if GameState.get_hp_percent() <= hp_threshold:
			_phase_clutch_spent = true
			var healed: float = GameState.heal_player(float(clutch_effect.get("heal_value", 0.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			if _combat_meter != null and is_instance_valid(_combat_meter):
				_combat_meter.restore_stamina(float(clutch_effect.get("stamina_value", 0.0)))
			emit_signal("proc_feedback", "GRAVESLIP HOLDS", Color(0.62, 0.86, 1.0, 1.0))
	# Wound Hunger: every hit taken → support charge
	var wound_effect: Dictionary = get_runtime_effect("damage_to_charge")
	if not wound_effect.is_empty() and _wound_hunger_cooldown <= 0.0:
		_wound_hunger_cooldown = WOUND_HUNGER_COOLDOWN
		if RunGrowth.has_method("gain_reward_support_charge"):
			RunGrowth.gain_reward_support_charge(float(wound_effect.get("value", 0.0)))
		emit_signal("proc_feedback", "HUNGER RISES", Color(0.92, 0.40, 0.36, 1.0))


func _on_player_dodged(_from_lane: int, _to_lane: int) -> void:
	_dodge_streak += 1
	_add_hunt_momentum(HUNT_MOMENTUM_DODGE_GAIN)


func notify_dodge_timing_quality(_from_lane: int, _to_lane: int, quality: String) -> void:
	if not _song_started or _phase_index < 0:
		return
	if quality == "perfect":
		_add_hunt_momentum(HUNT_MOMENTUM_DODGE_GAIN)
		if _dodge_streak > 0 and _dodge_streak % 3 == 0:
			_add_bonus_progress(DODGE_STREAK_PROGRESS_BONUS)
			if RunGrowth.has_method("gain_reward_support_charge"):
				RunGrowth.gain_reward_support_charge(DODGE_STREAK_SUPPORT_CHARGE)
			emit_signal("proc_feedback", "SLIP FEEDS", Color(0.58, 0.80, 1.0, 1.0))
	elif quality != "good":
		_dodge_streak = 0


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
	if RunGrowth.has_method("gain_reward_support_charge"):
		RunGrowth.gain_reward_support_charge(float(pact_effect.get("support_charge", 0.0)))
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
	if not _stored_reward_ids.is_empty():
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
