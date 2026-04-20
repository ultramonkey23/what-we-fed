@tool
extends Node2D
## Debug calibration system for timing truth verification.
##
## This system displays timing zone boundaries as a projectile approaches the hit zone.
## Enable DEBUG_TIMING_CALIBRATION to render zone bands and progress indicators.
## 
## Shown zones (progress value):
## - 0.88–0.96: Approach (yellow)
## - 0.96–1.04: Good zone (cyan)
## - 0.98–1.02: Perfect zone (bright green)
## - 1.00: Beat mark center (white vertical line)
##
## No gameplay impact. Disable before shipping.

const DEBUG_TIMING_CALIBRATION: bool = false

var enabled: bool = false
var _overlay: CanvasLayer = null
var _zone_markers: Array[Line2D] = []


func _ready() -> void:
	if not DEBUG_TIMING_CALIBRATION:
		return
	
	enabled = true
	_setup_debug_overlay()


func _setup_debug_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "TimingDebugOverlay"
	_overlay.layer = 200  # High layer to show on top of everything
	add_child(_overlay)
	
	# Draw static zone indicators as reference grid.
	# These show the timing bands as vertical zones from top to bottom of viewport.
	_draw_static_zone_grid()


func _draw_static_zone_grid() -> void:
	if _overlay == null:
		return
	
	# Get viewport dimensions.
	var vp_size: Vector2 = get_viewport_rect().size
	var vp_height: float = vp_size.y
	
	# Timing zone reference bands.
	var zones: Array = [
		{"progress": 0.88, "label": "APP", "color": Color(1.0, 1.0, 0.0, 0.08)},
		{"progress": 0.96, "label": "GOOD", "color": Color(0.0, 1.0, 1.0, 0.12)},
		{"progress": 0.98, "label": "PERF", "color": Color(0.0, 1.0, 0.0, 0.16)},
		{"progress": 1.00, "label": "BEAT", "color": Color(1.0, 1.0, 1.0, 0.20)},
		{"progress": 1.02, "label": "PERF", "color": Color(0.0, 1.0, 0.0, 0.16)},
		{"progress": 1.04, "label": "GOOD", "color": Color(0.0, 1.0, 1.0, 0.12)},
	]
	
	for zone in zones:
		var p: float = zone.get("progress", 0.5)
		var x_pos: float = lerp(0.0, vp_size.x * 0.3, p)
		
		# Draw vertical line for zone marker.
		var marker_line := Line2D.new()
		marker_line.name = "Zone_%.2f" % p
		marker_line.add_point(Vector2(x_pos, 0.0))
		marker_line.add_point(Vector2(x_pos, vp_height))
		marker_line.width = 1.5
		marker_line.default_color = zone.get("color", Color.WHITE)
		marker_line.z_index = 200
		_overlay.add_child(marker_line)
		
		# Add zone label every other marker.
		if fmod(p, 0.02) < 0.01 or p == 1.0:
			var label := Label.new()
			label.name = "Label_%.2f" % p
			label.text = zone.get("label", "")
			label.add_theme_font_size_override("font_size", 10)
			label.position = Vector2(x_pos + 4.0, 8.0)
			label.add_theme_color_override("font_color", zone.get("color", Color.WHITE))
			_overlay.add_child(label)


func show_calibration() -> void:
	if _overlay != null:
		_overlay.visible = true
	enabled = true


func hide_calibration() -> void:
	if _overlay != null:
		_overlay.visible = false
	enabled = false
