extends Node

# Combat Feedback Director
# Centralizes all "Juice" (Screenshake, Hit-stop, Flashes) to ensure consistent feel.
# Following industry best practices for Action-RPG weight and impact.
# AESTHETIC: Manga Monstrosity / Premium Menace (high contrast, visceral impact)

const SHAKE_INTENSITY_WEAK: float = 2.0
const SHAKE_INTENSITY_NORMAL: float = 5.0
const SHAKE_INTENSITY_HEAVY: float = 9.5
const SHAKE_INTENSITY_SOVEREIGN: float = 14.0

const SHAKE_DURATION_SHORT: float = 0.08
const SHAKE_DURATION_LONG: float = 0.16
const SHAKE_DURATION_SOVEREIGN: float = 0.25

# Manga Colors
const COLOR_BLOOD_EMBER = Color(0.90, 0.28, 0.28, 0.45)
const COLOR_BONE_WHITE = Color(0.95, 0.95, 0.92, 0.35)
const COLOR_INK_BLACK = Color(0.12, 0.12, 0.14, 0.50)

func _ready() -> void:
	# Register for impact signals
	if not EventBus.timed_attack_resolved.is_connected(_on_impact):
		EventBus.timed_attack_resolved.connect(_on_impact)
	if not EventBus.player_took_damage.is_connected(_on_player_hit):
		EventBus.player_took_damage.connect(_on_player_hit)
	if not EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.connect(_on_player_parried)
	if not EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.connect(_on_ultimate_fired)

func _on_impact(_lane: int, quality: String, _damage: float, _enemy_id: int) -> void:
	match quality:
		"perfect":
			trigger_hit_stop(0.04, 0.10)
			trigger_shake(SHAKE_INTENSITY_HEAVY, SHAKE_DURATION_LONG)
			EventBus.emit_signal("screen_flash", COLOR_BONE_WHITE, 0.10)
		"good":
			trigger_shake(SHAKE_INTENSITY_NORMAL, SHAKE_DURATION_SHORT)
			EventBus.emit_signal("screen_flash", Color(0.95, 0.95, 0.92, 0.15), 0.08)
		_:
			trigger_shake(SHAKE_INTENSITY_WEAK, 0.05)

func _on_player_hit(_amount: float, _source_lane: int) -> void:
	trigger_hit_stop(0.15, 0.15)
	trigger_shake(SHAKE_INTENSITY_HEAVY, SHAKE_DURATION_LONG)
	EventBus.emit_signal("screen_flash", COLOR_BLOOD_EMBER, 0.18)

func _on_player_parried(_lane: int, quality: String, _reflect_damage: float) -> void:
	if quality == "perfect":
		trigger_hit_stop(0.02, 0.12)
		trigger_shake(SHAKE_INTENSITY_SOVEREIGN, SHAKE_DURATION_SOVEREIGN)
		EventBus.emit_signal("screen_flash", COLOR_INK_BLACK, 0.12)
	elif quality == "good":
		trigger_shake(SHAKE_INTENSITY_NORMAL, SHAKE_DURATION_LONG)
		EventBus.emit_signal("screen_flash", COLOR_BONE_WHITE, 0.08)

func _on_ultimate_fired(_power: float) -> void:
	trigger_hit_stop(0.01, 0.20)
	trigger_shake(SHAKE_INTENSITY_SOVEREIGN, SHAKE_DURATION_SOVEREIGN)
	EventBus.emit_signal("screen_flash", COLOR_BLOOD_EMBER, 0.25)

func trigger_shake(intensity: float, duration: float) -> void:
	EventBus.emit_signal("screen_shake", intensity, duration)

func trigger_hit_stop(scale: float, duration: float) -> void:
	# Using the slow_motion channel to protect audio sync
	EventBus.emit_signal("slow_motion", scale, duration)
