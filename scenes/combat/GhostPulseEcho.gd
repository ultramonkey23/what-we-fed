class_name GhostPulseEcho
extends Node2D

## "The Ghost Pulse" — the Metrist's one-warning telegraph (pale_shelf_offbeat_lector).
## Canon [P]: "the echo fires in the gap, not on the beat."
##
## A pale after-image of the player's own most recent shot that ignites in the
## empty slot between two beats, one beat before the Downbeat lands. The echo
## itself is never damage and never moves: it is the readable mark of the gap
## slot the strike is aiming at. Scheduling math lives in MetristDirector —
## this node only renders the ignition it is told about.

signal ghost_ignited(echo: GhostPulseEcho)

# Pale shelf ink: after-image white-blue, readable against the pale ground.
const ECHO_CORE_COLOR: Color = Color(0.92, 0.97, 1.0, 1.0)
const ECHO_BODY_COLOR: Color = Color(0.72, 0.88, 1.0, 1.0)
const ECHO_GLOW_COLOR: Color = Color(0.58, 0.80, 1.0, 1.0)
const IGNITE_RAMP_SEC: float = 0.12

var ignited: bool = false
var scheduled_ignite_msec: float = -1.0
var ignite_delay_sec: float = 0.0
var visible_duration_sec: float = 1.8

var _elapsed_sec: float = 0.0
var _age_sec: float = -1.0 # seconds since ignition; negative until ignited


func setup(p_ignite_delay_sec: float, p_visible_duration_sec: float, p_heading: Vector2, p_scheduled_ignite_msec: float) -> void:
	ignite_delay_sec = maxf(p_ignite_delay_sec, 0.0)
	visible_duration_sec = maxf(p_visible_duration_sec, 0.4)
	scheduled_ignite_msec = p_scheduled_ignite_msec
	if p_heading.length_squared() > 0.01:
		rotation = p_heading.angle()
	visible = false
	z_index = 8


func reschedule(p_ignite_delay_sec: float, p_scheduled_ignite_msec: float) -> void:
	# Pattern-break slip: the echo SNAPS into the gap slot before the slipped
	# landing. Once ignited it stays where it fired — in a gap.
	if ignited:
		return
	ignite_delay_sec = maxf(p_ignite_delay_sec, 0.0)
	scheduled_ignite_msec = p_scheduled_ignite_msec
	_elapsed_sec = 0.0


func _process(delta: float) -> void:
	_elapsed_sec += delta
	if not ignited:
		if _elapsed_sec >= ignite_delay_sec:
			ignited = true
			_age_sec = 0.0
			visible = true
			# Runtime evidence: only the Ghost Pulse path prints this line.
			print("GHOST_PULSE_IGNITE scheduled_ignite_msec=%.1f gap_slot=true" % scheduled_ignite_msec)
			ghost_ignited.emit(self)
			queue_redraw()
		return
	_age_sec += delta
	if _age_sec >= visible_duration_sec:
		queue_free()
		return
	queue_redraw()


func _alpha() -> float:
	if not ignited:
		return 0.0
	if _age_sec < IGNITE_RAMP_SEC:
		return clampf(_age_sec / IGNITE_RAMP_SEC, 0.0, 1.0) * 0.92
	var fade_start: float = visible_duration_sec * 0.55
	if _age_sec <= fade_start:
		return 0.92
	return clampf(1.0 - (_age_sec - fade_start) / maxf(visible_duration_sec - fade_start, 0.01), 0.0, 1.0) * 0.92


func _draw() -> void:
	var alpha: float = _alpha()
	if alpha <= 0.003:
		return
	# Pale after-image of a player shot: an elongated needle along +X with a
	# soft glow diamond and an ignition ring marking the gap slot.
	var glow: Color = Color(ECHO_GLOW_COLOR.r, ECHO_GLOW_COLOR.g, ECHO_GLOW_COLOR.b, alpha * 0.30)
	var body: Color = Color(ECHO_BODY_COLOR.r, ECHO_BODY_COLOR.g, ECHO_BODY_COLOR.b, alpha * 0.80)
	var core: Color = Color(ECHO_CORE_COLOR.r, ECHO_CORE_COLOR.g, ECHO_CORE_COLOR.b, alpha)
	draw_colored_polygon(PackedVector2Array([
		Vector2(30.0, 0.0), Vector2(8.0, -13.0), Vector2(-20.0, -10.0),
		Vector2(-27.0, 0.0), Vector2(-20.0, 10.0), Vector2(8.0, 13.0)
	]), glow)
	draw_colored_polygon(PackedVector2Array([
		Vector2(24.0, 0.0), Vector2(6.0, -7.0), Vector2(-15.0, -5.0),
		Vector2(-19.0, 0.0), Vector2(-15.0, 5.0), Vector2(6.0, 7.0)
	]), body)
	draw_line(Vector2(-13.0, 0.0), Vector2(21.0, 0.0), core, 4.0, true)
	draw_circle(Vector2(21.0, 0.0), 3.0, core)
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, Color(core.r, core.g, core.b, alpha * 0.55), 2.0, true)
