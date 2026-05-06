extends Node

## QUIG NARRATIVE SYSTEM
## Reactive narrative guide that comments on combat performance and choices.

const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const INPUT_HELPER = preload("res://systems/InputHelper.gd")

var _last_line_time: float = -99.0
var _cooldown: float = 12.0 # Standard cooldown to prevent narrative sludge
var _rng := RandomNumberGenerator.new()
var _is_sovereign_active: bool = false

func _ready() -> void:
	_rng.randomize()
	_connect_signals()


func _input(event: InputEvent) -> void:
	INPUT_HELPER.mark_device_from_event(event)


func _connect_signals() -> void:
	var has_sovereign_reached := EventBus.has_signal("sovereign_reached")
	EventBus.tempo_state_entered.connect(_on_tempo_state_entered)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	EventBus.creature_bonded.connect(_on_creature_bonded)
	EventBus.creature_eaten.connect(_on_creature_eaten)
	EventBus.player_took_damage.connect(_on_player_took_damage)
	if has_sovereign_reached:
		EventBus.sovereign_reached.connect(_on_sovereign_reached)
	EventBus.sovereign_threshold_reached.connect(_on_sovereign_threshold_reached)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.world_fate_shifted.connect(_on_world_fate_shifted)
	EventBus.creature_ascended.connect(_on_creature_ascended)


func _on_world_fate_shifted(new_fate_id: String, _old_fate_id: String) -> void:
	if new_fate_id != "unclaimed":
		_trigger_line("world_fate", new_fate_id, 0.0)


func _on_creature_ascended(_data: Dictionary) -> void:
	_trigger_line("ascension", "success", 0.0)


func _on_tempo_state_entered(state_id: String) -> void:
	if state_id == "puncture":
		_trigger_line("timing", "puncture")


func _on_player_parried(_lane: int, quality: String, _damage: float) -> void:
	if quality == "perfect":
		_trigger_line("timing", "perfect_parry")


func _on_timed_attack_resolved(_lane: int, quality: String, _damage: float, _enemy_id: int) -> void:
	if quality == "perfect":
		_trigger_line("timing", "perfect_timed_attack")


func _on_creature_bonded(_creature_data: Dictionary) -> void:
	# Rewards often happen in VOID time; we use a shorter cooldown.
	_trigger_line("bond_eat", "bond", 1.5)


func _on_creature_eaten(_creature_data: Dictionary) -> void:
	_trigger_line("bond_eat", "eat", 1.5)


func _on_player_took_damage(_amount: float, _source_lane: int) -> void:
	if GameState.get_hp_percent() < 0.35:
		# Urgency lines have a very short internal cooldown to ensure they fire.
		_trigger_line("urgency", "low_hp", 2.0)


func _on_sovereign_reached() -> void:
	_is_sovereign_active = true
	_trigger_line("urgency", "sovereign_reach", 0.0)


func _on_sovereign_threshold_reached(threshold: float) -> void:
	_is_sovereign_active = true
	if threshold <= 0.5:
		_trigger_line("urgency", "sovereign_low_hp", 0.0)


func _on_combat_ended(_victory: bool) -> void:
	_is_sovereign_active = false


func _trigger_line(category: String, subcategory: String, override_cooldown: float = -1.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var effective_cooldown = override_cooldown if override_cooldown >= 0 else _cooldown

	if now - _last_line_time < effective_cooldown:
		return

	var pool: Array = PRESENTATION_TEXT.QUIG_REACTIVE_LINES.get(category, {}).get(subcategory, [])
	if pool.is_empty():
		return

	var line: String = pool[_rng.randi_range(0, pool.size() - 1)]
	_last_line_time = now

	EventBus.emit_signal("quig_narrative_triggered", "Quig: \"" + line + "\"", 3.5)


func trigger_tutorial_line(subcategory: String) -> void:
	var pool: Array = PRESENTATION_TEXT.QUIG_REACTIVE_LINES.get("tutorials", {}).get(subcategory, [])
	if pool.is_empty():
		return
	var line: String = pool[_rng.randi_range(0, pool.size() - 1)]
	EventBus.emit_signal("quig_narrative_triggered", _resolve_tokens(line), 3.5)


func _resolve_tokens(text: String) -> String:
	return text \
		.replace("[ATTACK]", INPUT_HELPER.get_label_for_action(&"action_attack")) \
		.replace("[PARRY]", INPUT_HELPER.get_label_for_action(&"action_parry")) \
		.replace("[DODGE]", INPUT_HELPER.get_label_for_action(&"action_dodge")) \
		.replace("[SUPPORT]", INPUT_HELPER.get_label_for_action(&"action_support")) \
		.replace("[ULTIMATE]", INPUT_HELPER.get_label_for_action(&"action_ultimate")) \
		.replace("[MOVE]", INPUT_HELPER.get_label_for_action(&"mod_left"))
