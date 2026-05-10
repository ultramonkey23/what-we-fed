extends Node

# TempoDirector v1.0
# Extracted from CombatScene.

const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")

var _song_conductor: Node = null
var _boss_music_player: Node = null
var _performance_reward_director: Node = null

var _base_time_scale: float = 1.0
var _tempo_state_family: StringName = &"none"
var _tempo_state_id: StringName = &""
var _tempo_state_until_ms: int = 0
var _tempo_state_started_ms: int = 0
var _tempo_recovery_start_ms: int = 0
var _tempo_recovery_duration_ms: int = 0
var _tempo_recovery_from_scale: float = 1.0
var _tempo_puncture_cooldown_until_ms: int = 0
var _tempo_stretch_cooldown_until_ms: int = 0
var _tempo_distortion_window: Array[Dictionary] = []
var _tempo_telemetry_counts: Dictionary = {}

func setup(perf_rewards: Node) -> void:
	_performance_reward_director = perf_rewards
	if not EventBus.slow_motion.is_connected(_on_slow_motion):
		EventBus.slow_motion.connect(_on_slow_motion)

func set_song_conductor(conductor: Node) -> void:
	_song_conductor = conductor

func set_boss_music_player(player: Node) -> void:
	_boss_music_player = player

func process_tempo(_delta: float) -> void:
	pass

func _on_slow_motion(_requested_scale: float, _duration: float) -> void:
	pass

func enter_tempo_state(family: StringName, _event_id: StringName, _tempo_scale_value: float, _duration: float = 0.0, _payload: Dictionary = {}) -> bool:
	_tempo_state_family = family
	return true

func get_family() -> StringName:
	return _tempo_state_family

func is_void_active() -> bool:
	return _tempo_state_family == &"void"

func resolve_void_timer_delta(delta: float) -> float:
	return delta

func track_tempo_event(_family: StringName, _event_id: StringName, _payload: Dictionary = {}) -> void:
	pass

func trigger_decree(_event_id: StringName, _duration: float, _payload: Dictionary = {}) -> void:
	pass

func begin_void(_event_id: StringName, _payload: Dictionary = {}) -> void:
	pass

func end_void(_event_id: StringName) -> void:
	pass

func reset_tempo_state() -> void:
	pass

func apply_tempo_time_scale(_tempo_scale_value: float) -> void:
	pass

func kill_tempo_recovery_tween() -> void:
	pass

func notify_tempo_mastery(_family: StringName, _event_id: StringName, _payload: Dictionary = {}) -> void:
	pass

func get_current_void_elapsed_seconds() -> float:
	return 0.0

func cleanup() -> void:
	if EventBus.slow_motion.is_connected(_on_slow_motion):
		EventBus.slow_motion.disconnect(_on_slow_motion)
