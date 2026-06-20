extends Node

const PASSIVE_REGEN_PER_SEC: float = 4.0
const STAMINA_ATTACK_GAIN: float = 8.0
const STAMINA_DODGE_COST: float = 16.0
const STAMINA_PARRY_COST: float = 40.0
const STAMINA_DAMAGE_TAKEN_LOSS: float = 5.0

const ULTIMATE_THRESHOLD: int = 20

const TIER_STIRRING: String = "stirring"
const TIER_HUNTING: String = "hunting"
const TIER_RAMPAGE: String = "rampage"
const TIER_APEX: String = "apex"
const TIER_SOVEREIGN: String = "sovereign"

const MULT_STIRRING: float = 1.00
const MULT_HUNTING: float = 1.15
const MULT_RAMPAGE: float = 1.30
const MULT_APEX: float = 1.50
const MULT_SOVEREIGN: float = 1.85

var combo_count: int = 0
var style_score: float = 0.0
var stamina: float = 100.0
var stamina_max: float = 100.0:
	get:
		# Always fetch from GameState to ensure real-time scaling
		return PlayerState.stat_endurance
var phrase_count: int = 0  # consecutive quality actions without a break

var _ultimate_announced: bool = false
var _last_tier: String = ""  # tracks tier for change detection

# Change-detection cache so we don't flood EventBus + HUD on signal storms.
var _last_emitted_combo: int = -1
var _last_emitted_style_bucket: int = -1
var _last_emitted_stamina_bucket: int = -1
var _last_emitted_stamina_max_bucket: int = -1


func _ready() -> void:
	_emit_stamina_changed(true)
	EventBus.emit_signal("combo_changed", combo_count, _current_tier())
	EventBus.emit_signal("style_changed", style_score, _current_tier())
	_last_emitted_combo = combo_count
	_last_emitted_style_bucket = int(style_score)


func _process(delta: float) -> void:
	if stamina < stamina_max:
		stamina = min(stamina + PASSIVE_REGEN_PER_SEC * delta, stamina_max)
		_emit_stamina_changed()
	else:
		set_process(false)


func _emit_stamina_changed(force: bool = false) -> void:
	# Bucket by integer to skip 60Hz emissions when only sub-unit drift changes.
	var cur_b: int = int(stamina)
	var max_b: int = int(stamina_max)
	if not force and cur_b == _last_emitted_stamina_bucket and max_b == _last_emitted_stamina_max_bucket:
		return
	_last_emitted_stamina_bucket = cur_b
	_last_emitted_stamina_max_bucket = max_b
	EventBus.emit_signal("stamina_changed", stamina, stamina_max)


func can_parry() -> bool:
	return stamina >= STAMINA_PARRY_COST


func can_dodge() -> bool:
	return stamina >= STAMINA_DODGE_COST


func spend_stamina_for_parry() -> bool:
	if not can_parry():
		EventBus.emit_signal("player_no_stamina")
		return false

	stamina = max(stamina - STAMINA_PARRY_COST, 0.0)
	_emit_stamina_changed(true)
	set_process(true)
	return true


func spend_stamina_for_dodge() -> bool:
	if not can_dodge():
		EventBus.emit_signal("player_no_stamina")
		return false

	stamina = max(stamina - STAMINA_DODGE_COST, 0.0)
	_emit_stamina_changed(true)
	set_process(true)
	return true


func is_ultimate_available() -> bool:
	return combo_count >= ULTIMATE_THRESHOLD


func consume_ultimate() -> float:
	if not is_ultimate_available():
		return 0.0

	var power: float = damage_multiplier() + 0.75
	reset()
	EventBus.emit_signal("ultimate_fired", power)
	return power


func record_attack() -> void:
	combo_count += 2
	style_score += 8.0
	_gain_stamina(STAMINA_ATTACK_GAIN)
	_emit_meter_state()


func record_timed_attack() -> void:
	combo_count += 2
	style_score += 14.0
	_gain_stamina(STAMINA_ATTACK_GAIN)
	_emit_meter_state()


func record_parry(quality: String) -> void:
	match quality:
		"perfect":
			combo_count += 3
			style_score += 18.0
		"good":
			combo_count += 1
			style_score += 10.0
		_:
			style_score += 2.0

	_emit_meter_state()


func record_dodge() -> void:
	combo_count += 1
	style_score += 6.0
	_emit_meter_state()


func record_bad_timing() -> void:
	if combo_count > 0:
		EventBus.emit_signal("combo_broken", combo_count)

	combo_count = 0
	style_score = max(style_score - 10.0, 0.0)
	stamina = max(stamina - STAMINA_DAMAGE_TAKEN_LOSS, 0.0)
	_emit_stamina_changed(true)
	set_process(true)
	break_phrase()
	_emit_meter_state()


func record_lane_read() -> void:
	style_score += 4.0
	_emit_meter_state()


func damage_multiplier() -> float:
	match _current_tier():
		TIER_SOVEREIGN:
			return MULT_SOVEREIGN
		TIER_APEX:
			return MULT_APEX
		TIER_RAMPAGE:
			return MULT_RAMPAGE
		TIER_HUNTING:
			return MULT_HUNTING
		_:
			return MULT_STIRRING


func dna_multiplier() -> float:
	match _current_tier():
		TIER_SOVEREIGN:
			return 2.5
		TIER_APEX:
			return 1.8
		TIER_RAMPAGE:
			return 1.4
		TIER_HUNTING:
			return 1.2
		_:
			return 1.0


func reset() -> void:
	if combo_count > 0:
		EventBus.emit_signal("combo_broken", combo_count)

	combo_count = 0
	style_score = 0.0
	phrase_count = 0
	_ultimate_announced = false
	_emit_meter_state()


func restore_stamina(amount: float) -> void:
	_gain_stamina(amount)


func gain_ultimate_power(amount: float) -> void:
	# amount is 0.0 to 1.0 (percent of threshold)
	var combo_gain: int = int(amount * float(ULTIMATE_THRESHOLD))
	combo_count += combo_gain
	_emit_meter_state()


func record_phrase_action(quality: String) -> void:
	# Call this after any good/perfect action to advance the phrase chain.
	# quality: "perfect", "good" — anything else is ignored (does not break).
	if quality != "perfect" and quality != "good":
		return
	phrase_count += 1
	# Emit milestones at 3, 5, 8+ (each threshold fires only once per streak).
	if phrase_count == 3 or phrase_count == 5 or phrase_count == 8:
		EventBus.emit_signal("phrase_milestone", phrase_count)
	elif phrase_count > 8 and (phrase_count - 8) % 4 == 0:
		# Keep emitting every 4 actions past 8 for extended flow state.
		EventBus.emit_signal("phrase_milestone", phrase_count)


func break_phrase() -> void:
	phrase_count = 0


func get_phrase_bonus() -> float:
	# Returns a damage multiplier bonus: 0.0 at no chain, up to +0.25 at 8+.
	if phrase_count < 3:
		return 0.0
	if phrase_count < 5:
		return 0.08
	if phrase_count < 8:
		return 0.16
	return 0.25


func is_in_flow() -> bool:
	return phrase_count >= 3


func get_current_tier() -> String:
	return _current_tier()


func _gain_stamina(amount: float) -> void:
	stamina = min(stamina + amount, stamina_max)
	_emit_stamina_changed(true)


func _current_tier() -> String:
	if combo_count >= 35:
		return TIER_SOVEREIGN
	if combo_count >= 20:
		return TIER_APEX
	if combo_count >= 10:
		return TIER_RAMPAGE
	if combo_count >= 5:
		return TIER_HUNTING
	return TIER_STIRRING


func _emit_meter_state() -> void:
	var tier: String = _current_tier()
	var tier_changed: bool = tier != _last_tier
	if tier_changed and _last_tier != "":
		EventBus.emit_signal("tier_changed", tier, _last_tier)
	_last_tier = tier

	if combo_count != _last_emitted_combo or tier_changed:
		_last_emitted_combo = combo_count
		EventBus.emit_signal("combo_changed", combo_count, tier)

	var style_bucket: int = int(style_score)
	if style_bucket != _last_emitted_style_bucket or tier_changed:
		_last_emitted_style_bucket = style_bucket
		EventBus.emit_signal("style_changed", style_score, tier)

	if tier_changed and tier == TIER_SOVEREIGN:
		EventBus.emit_signal("sovereign_reached")

	if is_ultimate_available():
		if not _ultimate_announced:
			_ultimate_announced = true
			EventBus.emit_signal("ultimate_available")
	else:
		_ultimate_announced = false
