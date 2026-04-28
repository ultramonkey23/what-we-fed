extends Node

# Combat Feedback Director
# Centralizes all "Juice" (Screenshake, Hit-stop, Flashes) to ensure consistent feel.
# Following industry best practices for Action-RPG weight and impact.

const SHAKE_INTENSITY_WEAK: float = 2.0
const SHAKE_INTENSITY_NORMAL: float = 4.5
const SHAKE_INTENSITY_HEAVY: float = 8.0
const SHAKE_DURATION_SHORT: float = 0.08
const SHAKE_DURATION_LONG: float = 0.14

func _ready() -> void:
	# Register for impact signals
	if not EventBus.timed_attack_resolved.is_connected(_on_impact):
		EventBus.timed_attack_resolved.connect(_on_impact)
	if not EventBus.player_took_damage.is_connected(_on_player_hit):
		EventBus.player_took_damage.connect(_on_player_hit)

func _on_impact(lane: int, quality: String, damage: float, enemy_id: int) -> void:
	match quality:
		"perfect":
			trigger_hit_stop(0.05, 0.08)
			trigger_shake(SHAKE_INTENSITY_HEAVY, SHAKE_DURATION_LONG)
			EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.65, 0.22), 0.08)
		"good":
			trigger_shake(SHAKE_INTENSITY_NORMAL, SHAKE_DURATION_SHORT)
			EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.55, 0.12), 0.07)
		_:
			trigger_shake(SHAKE_INTENSITY_WEAK, 0.05)

func _on_player_hit(amount: float, source_lane: int) -> void:
	trigger_shake(SHAKE_INTENSITY_HEAVY, SHAKE_DURATION_LONG)
	# Heavy chromatic aberration or directional flash can be added here.

func trigger_shake(intensity: float, duration: float) -> void:
	EventBus.emit_signal("screen_shake", intensity, duration)

func trigger_hit_stop(scale: float, duration: float) -> void:
	# Using the slow_motion channel to protect audio sync
	EventBus.emit_signal("slow_motion", scale, duration)
