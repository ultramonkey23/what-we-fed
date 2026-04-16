extends Node

const PASSIVE_REGEN_PER_SEC: float = 4.0
const STAMINA_ATTACK_GAIN: float = 8.0
const STAMINA_DODGE_GAIN: float = 35.0
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
var stamina_max: float = 100.0

var _ultimate_announced: bool = false


func _ready() -> void:
	EventBus.emit_signal("stamina_changed", stamina, stamina_max)
	EventBus.emit_signal("combo_changed", combo_count, _current_tier())
	EventBus.emit_signal("style_changed", style_score, _current_tier())


func _process(delta: float) -> void:
	if stamina < stamina_max:
		stamina = min(stamina + PASSIVE_REGEN_PER_SEC * delta, stamina_max)
		EventBus.emit_signal("stamina_changed", stamina, stamina_max)


func can_parry() -> bool:
	return stamina >= STAMINA_PARRY_COST


func spend_stamina_for_parry() -> bool:
	if not can_parry():
		EventBus.emit_signal("player_no_stamina")
		return false

	stamina = max(stamina - STAMINA_PARRY_COST, 0.0)
	EventBus.emit_signal("stamina_changed", stamina, stamina_max)
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
	_gain_stamina(STAMINA_DODGE_GAIN)
	_emit_meter_state()


func record_bad_timing() -> void:
	if combo_count > 0:
		EventBus.emit_signal("combo_broken", combo_count)

	combo_count = 0
	style_score = max(style_score - 10.0, 0.0)
	stamina = max(stamina - STAMINA_DAMAGE_TAKEN_LOSS, 0.0)
	EventBus.emit_signal("stamina_changed", stamina, stamina_max)
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


func reset() -> void:
	if combo_count > 0:
		EventBus.emit_signal("combo_broken", combo_count)

	combo_count = 0
	style_score = 0.0
	_ultimate_announced = false
	_emit_meter_state()


func restore_stamina(amount: float) -> void:
	_gain_stamina(amount)


func _gain_stamina(amount: float) -> void:
	stamina = min(stamina + amount, stamina_max)
	EventBus.emit_signal("stamina_changed", stamina, stamina_max)


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

	EventBus.emit_signal("combo_changed", combo_count, tier)
	EventBus.emit_signal("style_changed", style_score, tier)

	if tier == TIER_SOVEREIGN:
		EventBus.emit_signal("sovereign_reached")

	if is_ultimate_available():
		if not _ultimate_announced:
			_ultimate_announced = true
			EventBus.emit_signal("ultimate_available")
	else:
		_ultimate_announced = false
