extends RefCounted

const MOTION_JUICE = preload("res://systems/MotionJuice.gd")
const HUD_PANEL_ART = preload("res://systems/HUDPanelArt.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const BLACK_SIGNAL_SHADER = preload("res://art/vfx/black_signal_combat.gdshader")
const ENEMY_BEAT_PULSE_INTENSITY: float = 0.03

var _flash_overlay: ColorRect
var _camera_2d: Camera2D
var _timing_circle_container: Node2D
var _attack_fx_container: Node2D
var _player_combat: Node2D
var _zone_manager: Node
var _ui_layer: CanvasLayer
var _battlefield_panel: Control
var _enemy_markers_by_id: Dictionary
var _ring_highlight_timers: Array[float]
var _bg_sprite: Control = null
var _bg_pulse_targets: Array[CanvasItem] = []
var _flash_tween: Tween = null
var _enemy_shader_material_by_id: Dictionary = {}
var _enemy_flash_tweens_by_id: Dictionary = {}
var _readability_stress: float = 0.0

var _sigil_overlay_ready: bool = false
var _input_echo_line: Line2D = null
var _recovery_arc_line: Line2D = null
var _ready_pulse_line: Line2D = null
var _input_echo_tween: Tween = null
var _ready_pulse_tween: Tween = null
var _result_snap_tween: Tween = null
var _recovery_initial: float = 0.0
var _recovery_state: String = ""
var _recovery_was_locked: bool = false


func _init(
	flash_overlay: ColorRect,
	camera_2d: Camera2D,
	timing_circle_container: Node2D,
	attack_fx_container: Node2D,
	player_combat: Node2D,
	zone_manager: Node,
	ui_layer: CanvasLayer,
	enemy_markers_by_id: Dictionary,
	ring_highlight_timers: Array[float],
	battlefield_panel: Control,
	bg_sprite: Control
) -> void:
	_flash_overlay = flash_overlay
	_camera_2d = camera_2d
	_timing_circle_container = timing_circle_container
	_attack_fx_container = attack_fx_container
	_player_combat = player_combat
	_zone_manager = zone_manager
	_ui_layer = ui_layer
	_battlefield_panel = battlefield_panel
	_enemy_markers_by_id = enemy_markers_by_id
	_ring_highlight_timers = ring_highlight_timers
	_bg_sprite = bg_sprite
	
	_cache_bg_pulse_targets()
	_bind_enemy_visual_materials()


func set_readability_stress(stress: float) -> void:
	_readability_stress = clampf(stress, 0.0, 1.0)


func _cache_bg_pulse_targets() -> void:
	_bg_pulse_targets.clear()
	if _bg_sprite == null or not is_instance_valid(_bg_sprite):
		return
		
	for child in _bg_sprite.get_children():
		if not child is CanvasItem:
			continue
			
		var layer_name: String = child.name.to_lower()
		if layer_name.contains("sky") or layer_name.contains("midground") or layer_name.contains("haze"):
			_bg_pulse_targets.append(child as CanvasItem)


func _get_enemy_marker_root(enemy_id: int) -> Node2D:
	var marker_data = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null or not marker_data is Dictionary:
		return null
	var root = marker_data.get("root")
	return root as Node2D if is_instance_valid(root) else null


func _get_enemy_marker_body(marker: Node2D) -> ColorRect:
	if not is_instance_valid(marker): return null
	for enemy_id in _enemy_markers_by_id:
		var marker_data = _enemy_markers_by_id[enemy_id]
		if not marker_data is Dictionary: continue
		var root = marker_data.get("root")
		if is_instance_valid(root) and root == marker:
			var body = marker_data.get("body")
			if is_instance_valid(body): return body as ColorRect
	return marker.get_node_or_null("Body") as ColorRect


func _get_enemy_marker_center(marker: Node2D) -> Vector2:
	var body: ColorRect = _get_enemy_marker_body(marker)
	if body == null: return marker.position
	return marker.position + body.position + body.size * 0.5


func on_song_beat_pulse(_beat_index: int, intensity: float, quality: String) -> void:
	_pulse_active_enemy_markers(intensity)
	on_beat_pulse(quality, intensity)
	
	# Atmosphere: Jitter shader aberration on the beat
	if _flash_overlay.material is ShaderMaterial:
		var sm = _flash_overlay.material as ShaderMaterial
		var target_chroma: float = 0.002 + intensity * 0.015
		var t := _flash_overlay.create_tween()
		t.tween_method(func(v): sm.set_shader_parameter("chromatic_aberration", v), target_chroma, 0.0, 0.15)


func _pulse_active_enemy_markers(intensity: float) -> void:
	for enemy_id_variant in _enemy_markers_by_id.keys():
		var enemy_id: int = int(enemy_id_variant)
		if not _is_enemy_id_active(enemy_id): continue
		_ensure_enemy_shader_material(enemy_id)
		var pulse_target: CanvasItem = _resolve_enemy_visual_target(enemy_id)
		if pulse_target:
			MOTION_JUICE.beat_pulse(pulse_target, ENEMY_BEAT_PULSE_INTENSITY * (1.0 + intensity))


func _is_enemy_id_active(enemy_id: int) -> bool:
	if _zone_manager == null or not _zone_manager.has_method("get_enemy"): return true
	for lane in range(_zone_manager.THREAT_COUNT if _zone_manager else 4):
		var lane_enemy_v: Variant = _zone_manager.call("get_enemy", lane)
		if not lane_enemy_v is Dictionary: continue
		var lane_enemy: Dictionary = lane_enemy_v
		if not lane_enemy.is_empty() and float(lane_enemy.get("hp", 0.0)) > 0.0 and int(lane_enemy.get("id", -1)) == enemy_id:
			return true
	return false


func _resolve_enemy_visual_target(enemy_id: int) -> CanvasItem:
	var marker_data_v: Variant = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data_v == null or not marker_data_v is Dictionary: return null
	var marker_data: Dictionary = marker_data_v
	var root_v: Variant = marker_data.get("root", null)
	if is_instance_valid(root_v):
		var silhouette: Node = (root_v as Node).get_node_or_null("CreatureSilhouette")
		if is_instance_valid(silhouette) and silhouette is CanvasItem: return silhouette as CanvasItem
	var body_v: Variant = marker_data.get("body", null)
	if is_instance_valid(body_v) and body_v is CanvasItem: return body_v as CanvasItem
	return root_v as CanvasItem if is_instance_valid(root_v) and root_v is CanvasItem else null


func _bind_enemy_visual_materials() -> void:
	for enemy_id_variant in _enemy_markers_by_id.keys():
		_ensure_enemy_shader_material(int(enemy_id_variant))


func _get_enemy_shader_material(enemy_id: int) -> ShaderMaterial:
	var existing_v: Variant = _enemy_shader_material_by_id.get(enemy_id, null)
	if existing_v is ShaderMaterial and is_instance_valid(existing_v): return existing_v as ShaderMaterial
	return _ensure_enemy_shader_material(enemy_id)


func _ensure_enemy_shader_material(enemy_id: int) -> ShaderMaterial:
	var target: CanvasItem = _resolve_enemy_visual_target(enemy_id)
	if target == null:
		_enemy_shader_material_by_id.erase(enemy_id)
		return null
	var shader_material: ShaderMaterial = null
	if target.material is ShaderMaterial and (target.material as ShaderMaterial).shader == BLACK_SIGNAL_SHADER:
		shader_material = target.material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = BLACK_SIGNAL_SHADER
		target.material = shader_material
		var defaults: Dictionary = MOTION_JUICE.build_black_signal_uniforms(0.45)
		shader_material.set_shader_parameter("hit_flash_color", defaults.get("hit_flash_color", Color(1.0, 0.92, 0.88, 1.0)))
		shader_material.set_shader_parameter("hit_flash_intensity", 0.0)
		shader_material.set_shader_parameter("corruption_amount", defaults.get("corruption_amount", 0.24))
		shader_material.set_shader_parameter("chromatic_aberration", 0.0)
	_enemy_shader_material_by_id[enemy_id] = shader_material
	return shader_material


func flash_enemy_damage(enemy_id: int, profile: Dictionary = {}) -> void:
	var shader_material: ShaderMaterial = _get_enemy_shader_material(enemy_id)
	if shader_material == null: return
	var burst_scale: float = float(profile.get("burst_scale", 1.0))
	var juice: float = clampf((burst_scale - 0.8) * 1.6, 0.0, 2.0)
	var uniforms: Dictionary = MOTION_JUICE.build_black_signal_uniforms(juice)
	var flash_color: Color = profile.get("hit_flash_color", uniforms.get("hit_flash_color", Color(1.0, 0.92, 0.88, 1.0)))
	var corruption: float = clampf(float(uniforms.get("corruption_amount", 0.22)), 0.0, 1.0)
	var chroma: float = clampf(float(uniforms.get("chromatic_aberration", 0.01)), 0.0, 0.1)
	shader_material.set_shader_parameter("hit_flash_color", flash_color)
	shader_material.set_shader_parameter("corruption_amount", corruption)
	shader_material.set_shader_parameter("chromatic_aberration", chroma)
	shader_material.set_shader_parameter("hit_flash_intensity", 1.0)
	var target: CanvasItem = _resolve_enemy_visual_target(enemy_id)
	if not target: return
	_kill_enemy_flash_tween(enemy_id)
	var tween: Tween = (target as Node).create_tween()
	_enemy_flash_tweens_by_id[enemy_id] = tween
	tween.tween_method(func(v: float): shader_material.set_shader_parameter("hit_flash_intensity", v), 1.0, 0.0, 0.10)
	tween.parallel().tween_method(func(v: float): shader_material.set_shader_parameter("chromatic_aberration", v), chroma, 0.0, 0.10)
	tween.finished.connect(_on_enemy_flash_finished.bind(enemy_id, tween))


func _on_enemy_flash_finished(enemy_id: int, tween: Tween) -> void:
	if _enemy_flash_tweens_by_id.get(enemy_id) == tween:
		_enemy_flash_tweens_by_id.erase(enemy_id)


func _kill_enemy_flash_tween(enemy_id: int) -> void:
	var tween: Variant = _enemy_flash_tweens_by_id.get(enemy_id)
	if tween is Tween and is_instance_valid(tween): tween.kill()
	_enemy_flash_tweens_by_id.erase(enemy_id)


func on_screen_flash(color: Color, duration: float) -> void:
	if _flash_tween: _flash_tween.kill()
	var flash_color: Color = color
	if _readability_stress > 0.62 and flash_color.a > 0.0 and flash_color.a < 0.22:
		flash_color.a *= lerpf(1.0, 0.58, clampf((_readability_stress - 0.62) / 0.38, 0.0, 1.0))
	_flash_overlay.color = flash_color
	_flash_tween = _flash_overlay.create_tween()
	if flash_color.a > 0.985: # Manga Inversion
		_flash_overlay.color = Color.WHITE
		_flash_overlay.color.a = 1.0
		_flash_tween.tween_interval(0.015)
		_flash_tween.tween_property(_flash_overlay, "color", Color.BLACK, 0.01)
		_flash_tween.tween_interval(duration)
		_flash_tween.tween_property(_flash_overlay, "color:a", 0.0, 0.15)
	else:
		_flash_tween.tween_property(_flash_overlay, "color:a", flash_color.a, 0.03)
		_flash_tween.tween_interval(duration)
		_flash_tween.tween_property(_flash_overlay, "color:a", 0.0, 0.12)
	if flash_color.a > 0.10:
		var original_cam_offset: Vector2 = _camera_2d.offset
		_camera_2d.offset += Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
		_flash_tween.parallel().tween_property(_camera_2d, "offset", original_cam_offset, 0.10).set_delay(0.02)


func on_dna_resonated(color: Color, intensity: float) -> void:
	if not _ui_layer: return
	HUD_PANEL_ART.pulse_recursive(_ui_layer, intensity, color)
	var tween := _ui_layer.create_tween()
	tween.tween_interval(0.12)
	tween.tween_method(func(val: float):
		HUD_PANEL_ART.pulse_recursive(_ui_layer, lerpf(intensity, 0.0, val), color.lerp(Color(0.8, 0.1, 0.15), val))
	, 0.0, 1.0, 0.45)


func on_screen_shake(intensity: float, duration: float) -> void:
	var original_offset: Vector2 = _camera_2d.offset
	var tween := _camera_2d.create_tween()
	var y_f: float = intensity * 0.28
	if intensity >= 2.0:
		var s: float = duration / 6.0
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(intensity, y_f), s)
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(-intensity * 0.75, -y_f * 0.6), s)
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(intensity * 0.50, y_f * 0.4), s)
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(-intensity * 0.30, -y_f * 0.2), s)
		tween.tween_property(_camera_2d, "offset", original_offset, s * 2.0)
	else:
		var h: float = duration * 0.5
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(intensity, y_f), h)
		tween.tween_property(_camera_2d, "offset", original_offset - Vector2(intensity * 0.5, y_f * 0.4), h * 0.6)
		tween.tween_property(_camera_2d, "offset", original_offset, h)


func on_ui_shake(intensity: float, duration: float) -> void:
	if not _ui_layer: return
	var high: bool = intensity >= 1.2
	for child in _ui_layer.get_children():
		if child is Control:
			var orig: Vector2 = child.position
			var tween := child.create_tween()
			var step: float = duration / (4.0 if high else 2.0)
			if high:
				tween.tween_property(child, "position", orig + Vector2(intensity * 1.5, -intensity), step)
				tween.tween_property(child, "position", orig + Vector2(-intensity, intensity * 1.2), step)
				tween.tween_property(child, "position", orig + Vector2(intensity * 0.5, intensity * 0.5), step)
				tween.tween_property(child, "position", orig, step)
				if child is Label:
					var oc: Color = child.modulate
					var j_t := child.create_tween()
					j_t.tween_property(child, "modulate", Color(1.5, 0.5, 0.5, 1.0), 0.04)
					j_t.tween_property(child, "modulate", oc, 0.08)
			else:
				tween.tween_property(child, "position", orig + Vector2(intensity, intensity * 0.5), step)
				tween.tween_property(child, "position", orig, step)


func on_timing_ring_pressed(sector: int) -> void:
	animate_timing_ring_press(sector)


func on_projectile_fired(_sector: int, enemy_id: int) -> void:
	_swap_enemy_texture(enemy_id, "attack", 0.35)


func on_beat_pulse(quality: String, strength: float) -> void:
	if _bg_pulse_targets.is_empty():
		_cache_bg_pulse_targets()
		if _bg_pulse_targets.is_empty(): return
	var eff: float = strength * lerpf(1.0, 0.72, clampf((_readability_stress - 0.55) / 0.45, 0.0, 1.0))
	for child in _bg_pulse_targets:
		if not is_instance_valid(child): continue
		var orig: Color = child.modulate
		var pulse: Color = orig.lightened(0.18 * eff) if quality == "accent" else orig.lightened(0.12 * eff if quality == "perfect" else 0.06 * eff)
		var tween := child.create_tween()
		tween.tween_property(child, "modulate", pulse, 0.05)
		tween.tween_property(child, "modulate", orig, 0.15)


func on_enemy_defeated(enemy_id: int) -> void:
	var pos: Vector2 = _get_impact_spawn_pos(-1, enemy_id)
	_spawn_ink_splatter(pos, Color.BLACK)


func tick_sigil_recovery(player: Node2D, _delta: float) -> void:
	if not _sigil_overlay_ready:
		_setup_sigil_visual_nodes()
		
	var recovery_v = player.get("action_lock_timer")
	var recovery: float = float(recovery_v) if recovery_v != null else 0.0
	
	var state_v = player.get("current_action_state")
	var state: String = String(state_v) if state_v != null else "idle"
	
	if recovery <= 0.0:
		if _recovery_was_locked:
			_pulse_sigil_ready()
		_recovery_was_locked = false
		if _recovery_arc_line: _recovery_arc_line.visible = false
		return

	if not _recovery_was_locked or state != _recovery_state:
		_recovery_initial = recovery
		_recovery_state = state
		_recovery_was_locked = true

	# Update Recovery Arc
	if _recovery_arc_line:
		_recovery_arc_line.visible = true
		_recovery_arc_line.global_position = player.global_position
		
		var progress: float = clampf(recovery / _recovery_initial, 0.0, 1.0)
		var color: Color = Color.WHITE
		match state:
			"parry": color = Color(0.4, 0.7, 1.0, 0.8)
			"dodge": color = Color(0.6, 0.9, 1.0, 0.6)
			_: color = Color(0.9, 0.3, 0.2, 0.8)
		
		_recovery_arc_line.default_color = color
		
		# Draw a simple arc
		var pts := PackedVector2Array()
		var sides := 24
		var radius := 34.0
		var max_angle := TAU * progress
		for i in range(sides + 1):
			var a := (float(i) / float(sides)) * max_angle - PI * 0.5
			pts.append(Vector2(cos(a), sin(a)) * radius)
		_recovery_arc_line.points = pts


func pulse_sigil_input_echo(action: String, accepted: bool, buffered: bool, reason: String) -> void:
	if not _sigil_overlay_ready: _setup_sigil_visual_nodes()
	if not _input_echo_line: return
	
	var color := Color.WHITE
	if not accepted:
		color = Color(1.0, 0.4, 0.4, 0.8)
	elif buffered:
		color = Color(0.4, 0.8, 1.0, 0.6)
	
	_input_echo_line.default_color = color
	_input_echo_line.modulate.a = 1.0
	_input_echo_line.scale = Vector2.ONE * 0.8
	
	if _input_echo_tween: _input_echo_tween.kill()
	_input_echo_tween = _input_echo_line.create_tween()
	_input_echo_tween.tween_property(_input_echo_line, "scale", Vector2.ONE * 1.5, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_input_echo_tween.parallel().tween_property(_input_echo_line, "modulate:a", 0.0, 0.14)


func pulse_sigil_result_snap(quality: String, _type: String) -> void:
	if not _sigil_overlay_ready: _setup_sigil_visual_nodes()
	var ring = _timing_circle_container.get_node_or_null("TimingRing_Core/Perfect")
	if not ring: return
	
	var color = Color.WHITE
	match quality:
		"perfect": color = Color(1.0, 0.95, 0.4, 1.0)
		"good": color = Color(0.8, 1.0, 0.8, 0.8)
		_: color = Color(1.0, 0.4, 0.4, 0.6)
		
	if _result_snap_tween: _result_snap_tween.kill()
	_result_snap_tween = ring.create_tween()
	var orig_scale = ring.scale
	ring.scale = Vector2.ONE * 1.4
	ring.modulate = color
	_result_snap_tween.tween_property(ring, "scale", orig_scale, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_result_snap_tween.parallel().tween_property(ring, "modulate", Color.WHITE, 0.24)


func _setup_sigil_visual_nodes() -> void:
	_sigil_overlay_ready = true
	
	# Recovery Arc
	_recovery_arc_line = Line2D.new()
	_recovery_arc_line.width = 3.0
	_recovery_arc_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_recovery_arc_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_recovery_arc_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_battlefield_panel.add_child(_recovery_arc_line)
	
	# Input Echo
	_input_echo_line = Line2D.new()
	_input_echo_line.width = 2.0
	var echo_pts := PackedVector2Array()
	for i in range(33):
		var a := (float(i) / 32.0) * TAU
		echo_pts.append(Vector2(cos(a), sin(a)) * 42.0)
	_input_echo_line.points = echo_pts
	_input_echo_line.closed = true
	_input_echo_line.modulate.a = 0.0
	_battlefield_panel.add_child(_input_echo_line)


func _pulse_sigil_ready() -> void:
	# Subtle bloom when recovery ends
	var ring = _timing_circle_container.get_node_or_null("TimingRing_Core/Perfect")
	if not ring: return
	var t = ring.create_tween()
	t.tween_property(ring, "width", 8.0, 0.06)
	t.tween_property(ring, "width", 3.2, 0.12)


func highlight_timing_ring(lane: int, color: Color, width: float = 4.0) -> void:
	var group: Node2D = _get_timing_receiver(lane)
	if not group: return
	_ring_highlight_timers[lane] = 0.15
	for child in group.get_children():
		if child is Line2D:
			var ring := child as Line2D
			if ring.name == "BeatMark": continue
			ring.default_color = color
			ring.width = width if ring.name == "Perfect" else max(width - 1.2, 1.8)
		elif child is Polygon2D and child.name == "ReceiverFill":
			var fill := child as Polygon2D
			var orig_a: float = fill.color.a
			fill.color = Color(color.r, color.g, color.b, 0.28)
			fill.create_tween().tween_property(fill, "color:a", orig_a, 0.15)


func animate_timing_ring_press(lane: int) -> void:
	var group: Node2D = _get_timing_receiver(lane)
	if not group: return
	var orig_p: Vector2 = group.position
	var orig_s: Vector2 = group.scale
	group.scale = Vector2(0.88, 0.88)
	group.position += Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
	var tween := group.create_tween()
	tween.tween_property(group, "scale", orig_s, 0.04)
	tween.parallel().tween_property(group, "position", orig_p, 0.04)


func _get_timing_receiver(lane: int) -> Node2D:
	if not _timing_circle_container: return null
	var group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_%d" % lane)
	return group if group else _timing_circle_container.get_node_or_null("TimingRing_Core")


func spawn_attack_silhouette_to_lane(lane: int, color: Color, thickness: float, lifetime: float, _reach_scale: float) -> void:
	if _timing_circle_container == null: return
	
	# Find the active tether points
	var tether: Line2D = _timing_circle_container.get_node_or_null("GhostThread_%d" % lane)
	if tether == null or tether.points.size() < 2:
		_spawn_fallback_slash(lane, color, thickness, lifetime)
		return
		
	# THE PATH-TRACED STRIKE: Traveling Sprite along the tether
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/characters/player/combat/player_atkeffect.png")
	sprite.modulate = color
	sprite.modulate.a = 0.8
	sprite.scale = Vector2.ZERO # Start scale
	sprite.rotation = (tether.points[1] - tether.points[0]).angle()
	_attack_fx_container.add_child(sprite)
	
	# Animate the sprite sequentially through the points
	var tween := _attack_fx_container.create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE * 0.45, 0.02) # Scale up fast
	
	var total_time: float = 0.08
	var time_per_segment: float = total_time / float(tether.points.size() - 1)
	
	for i in range(1, tether.points.size()):
		var target_pos = tether.points[i]
		tween.tween_property(sprite, "global_position", target_pos, time_per_segment).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, lifetime)
	tween.tween_callback(sprite.queue_free)
	
	# Also spawn the Surge Bolt (Line2D) for extra spectacular punch
	var bolt := Line2D.new()
	bolt.points = tether.points
	bolt.width = thickness * 1.5
	bolt.default_color = Color.WHITE
	bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	_attack_fx_container.add_child(bolt)
	var bolt_tween := bolt.create_tween()
	bolt_tween.tween_property(bolt, "modulate:a", 0.0, lifetime)
	bolt_tween.tween_callback(bolt.queue_free)


func _spawn_fallback_slash(lane: int, color: Color, thickness: float, lifetime: float) -> void:
	if not _player_combat or not _zone_manager: return
	var start: Vector2 = _player_combat.position + Vector2(10.0, -6.0)
	var end: Vector2 = _zone_manager.call("get_threat_hit_zone_pos", lane)
	var dir: Vector2 = (end - _zone_manager.call("get_player_pos")).normalized()
	end += dir * 8.0
	var delta: Vector2 = (end - start)
	var slash := Polygon2D.new()
	slash.color = color
	slash.position = start
	slash.rotation = delta.angle()
	slash.scale = Vector2(0.18, 1.0)
	slash.polygon = PackedVector2Array([Vector2(0, -thickness*0.5), Vector2(delta.length(), -thickness*0.5), Vector2(delta.length(), thickness*0.5), Vector2(0, thickness*0.5)])
	_attack_fx_container.add_child(slash)
	var tween := _attack_fx_container.create_tween()
	tween.tween_property(slash, "scale:x", 1.0, 0.04)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, lifetime)
	tween.tween_callback(slash.queue_free)


func apply_impact_profile(profile: Dictionary, lane: int = -1, enemy_id: int = -1) -> void:
	if profile.is_empty(): return
	var pos: Vector2 = _get_impact_spawn_pos(lane, enemy_id)
	if profile.has("ring_width"): _spawn_manga_ring_burst(pos, profile.get("ring_width", 2.0), profile.get("burst_color", Color.WHITE))
	var flash: Color = profile.get("flash_color", Color.TRANSPARENT)
	if flash.a > 0.0: EventBus.emit_signal("screen_flash", flash, float(profile.get("flash_duration", 0.05)))
	var intensity: float = float(profile.get("shake_intensity", 0.0))
	if intensity > 0.0:
		EventBus.emit_signal("screen_shake", intensity, float(profile.get("shake_duration", 0.08)))
		EventBus.emit_signal("ui_shake", intensity * 0.75, float(profile.get("shake_duration", 0.08)) * 1.25)
	var hs: float = float(profile.get("hitstop_scale", 1.0))
	if hs > 0.0 and hs < 0.999: EventBus.emit_signal("slow_motion", hs, float(profile.get("hitstop_duration", 0.10)))
	if enemy_id >= 0:
		flash_enemy_damage(enemy_id, profile)
		animate_enemy_damage(enemy_id, profile)
		var bc: Color = profile.get("burst_color", Color(1.0, 0.55, 0.35, 0.32))
		var bs: float = float(profile.get("burst_scale", 1.0))
		spawn_enemy_impact_burst(enemy_id, bc, bs, float(profile.get("burst_lifetime", 0.14)))
		if bs >= 1.3:
			var m = _get_enemy_marker_root(enemy_id)
			if m: spawn_impact_lines(_get_enemy_marker_center(m), Color(bc.r, bc.g, bc.b, bc.a * 0.55), 8 if bs >= 1.4 else 5, 26.0, 0.13)
	play_combat_sfx(String(profile.get("sfx_cue", "")))


func spawn_enemy_impact_burst(enemy_id: int, color: Color, burst_scale: float, lifetime: float) -> void:
	var marker: Node2D = _get_enemy_marker_root(enemy_id)
	if marker == null: return
	var center: Vector2 = _get_enemy_marker_center(marker)
	var burst := Polygon2D.new()
	burst.color = color
	burst.position = center
	burst.scale = Vector2(0.32, 0.32) * burst_scale
	var spike_points := PackedVector2Array()
	for i in range(16):
		var angle: float = (float(i) / 16.0) * TAU - PI * 0.5
		var radius: float = 24.0 if i % 2 == 0 else 10.0
		spike_points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	burst.polygon = spike_points
	_attack_fx_container.add_child(burst)
	var tween := _attack_fx_container.create_tween()
	tween.tween_property(burst, "scale", Vector2.ONE * burst_scale, 0.05)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, lifetime)
	tween.tween_callback(burst.queue_free)


func spawn_impact_lines(center: Vector2, color: Color, count: int, length: float, lifetime: float) -> void:
	for i in range(count):
		var angle: float = (float(i) / count) * TAU + randf_range(-0.28, 0.28)
		var line := Polygon2D.new()
		line.color = color
		line.position = center
		line.rotation = angle
		var half_w: float = randf_range(0.6, 1.5)
		var line_length: float = length * randf_range(0.55, 1.0)
		var start_offset: float = 5.0
		line.polygon = PackedVector2Array([
			Vector2(start_offset, -half_w),
			Vector2(line_length, -half_w * 0.25),
			Vector2(line_length, half_w * 0.25),
			Vector2(start_offset, half_w)
		])
		_attack_fx_container.add_child(line)
		var tween := _attack_fx_container.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, lifetime * randf_range(0.65, 1.0))
		tween.tween_callback(line.queue_free)


func play_combat_sfx(cue_id: String) -> void:
	if not cue_id.is_empty(): EventBus.emit_signal("play_sfx", cue_id)


func _spawn_manga_ring_burst(pos: Vector2, width: float, color: Color) -> void:
	var ring := Line2D.new()
	if _battlefield_panel: _battlefield_panel.add_child(ring)
	else: EventBus.get_parent().add_child(ring)
	ring.global_position = pos
	var pts := PackedVector2Array()
	for i in range(33):
		var a := (float(i) / 32.0) * TAU
		pts.append(Vector2(cos(a), sin(a)) * 24.0)
	ring.points = pts
	ring.closed = true
	ring.width = width
	ring.default_color = color
	ring.scale = Vector2.ZERO
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * 2.8, 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "width", 0.0, 0.28)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.28)
	tween.tween_callback(ring.queue_free)
	if width > 4.0: _spawn_manga_action_lines(pos, color)


func _spawn_manga_action_lines(pos: Vector2, color: Color) -> void:
	var container := Node2D.new()
	if _battlefield_panel: _battlefield_panel.add_child(container)
	else: EventBus.get_parent().add_child(container)
	container.global_position = pos
	for i in range(12):
		var line := Line2D.new()
		container.add_child(line)
		var angle := randf() * TAU
		var length := randf_range(40.0, 180.0)
		var dir := Vector2(cos(angle), sin(angle))
		line.points = PackedVector2Array([Vector2.ZERO, dir * length])
		line.width = randf_range(1.0, 3.5)
		line.default_color = color
		line.modulate.a = randf_range(0.6, 1.0)
		var twn := line.create_tween()
		twn.tween_property(line, "points", PackedVector2Array([dir * length * 0.8, dir * (length * 1.4)]), 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		twn.parallel().tween_property(line, "modulate:a", 0.0, 0.18)
	container.get_tree().create_timer(0.2).timeout.connect(container.queue_free)


func _spawn_ink_splatter(pos: Vector2, color: Color) -> void:
	var container := Node2D.new()
	if _battlefield_panel: _battlefield_panel.add_child(container)
	else: EventBus.get_parent().add_child(container)
	container.global_position = pos
	for i in range(8):
		var blob := Polygon2D.new()
		container.add_child(blob)
		var pts := PackedVector2Array()
		var sides := 6 + randi() % 4
		for j in range(sides): pts.append(Vector2(cos((float(j)/sides)*TAU), sin((float(j)/sides)*TAU)) * randf_range(4.0, 12.0))
		blob.polygon = pts
		blob.color = color
		var target := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * randf_range(100.0, 300.0)
		var twn := blob.create_tween()
		twn.tween_property(blob, "position", target * 0.25, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		twn.parallel().tween_property(blob, "scale", Vector2.ZERO, 0.25).set_delay(0.1)
		twn.parallel().tween_property(blob, "modulate:a", 0.0, 0.25)
	container.get_tree().create_timer(0.3).timeout.connect(container.queue_free)


func _get_impact_spawn_pos(lane: int, enemy_id: int) -> Vector2:
	if enemy_id >= 0 and _zone_manager != null and is_instance_valid(_zone_manager):
		if _zone_manager.has_method("get_enemy_pos"): return _zone_manager.call("get_enemy_pos", enemy_id)
	if lane >= 0 and _zone_manager != null and is_instance_valid(_zone_manager):
		if _zone_manager.has_method("get_threat_spawn_pos"): return _zone_manager.call("get_threat_spawn_pos", lane)
	if _player_combat != null and is_instance_valid(_player_combat): return _player_combat.global_position
	return Vector2(640, 360)


func _swap_enemy_texture(enemy_id: int, context: String, duration: float) -> void:
	var marker_data_v = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data_v == null or not marker_data_v is Dictionary: return
	var marker_data: Dictionary = marker_data_v
	var species_id: String = String(marker_data.get("species_id", ""))
	if species_id.is_empty(): return
	
	var silhouette: Sprite2D = _resolve_enemy_visual_target(enemy_id) as Sprite2D
	if not is_instance_valid(silhouette): return
	
	var path: String = COMBAT_CONTENT.get_creature_art_path(species_id, context, "adult")
	if path.is_empty() or not ResourceLoader.exists(path): return
	
	var tex: Texture2D = load(path) as Texture2D
	if tex == null: return
	
	var old_tex: Texture2D = silhouette.texture
	silhouette.texture = tex
	silhouette.hframes = clampi(int(float(tex.get_width()) / tex.get_height()), 1, 64)
	silhouette.frame = 0
	
	# Swap back after duration
	var tree = silhouette.get_tree()
	if tree == null: return
	
	var t := tree.create_timer(duration)
	t.timeout.connect(_restore_enemy_texture.bind(silhouette, old_tex))


func _restore_enemy_texture(silhouette: Variant, old_tex: Texture2D) -> void:
	if is_instance_valid(silhouette) and silhouette is Sprite2D:
		var s := silhouette as Sprite2D
		s.texture = old_tex
		s.hframes = clampi(int(float(old_tex.get_width()) / old_tex.get_height()), 1, 64)
		s.frame = 0


func animate_enemy_damage(enemy_id: int, profile: Dictionary = {}) -> void:
	var marker: Node2D = _get_enemy_marker_root(enemy_id)
	if marker == null: return
	
	_swap_enemy_texture(enemy_id, "hurt", 0.30)
	
	var orig_p: Vector2 = marker.position
	var orig_s: Vector2 = marker.scale
	var orig_m: Color = marker.modulate
	var push: float = float(profile.get("enemy_push", 6.0))
	var peak: Vector2 = profile.get("enemy_scale", Vector2(1.12, 0.88))
	var rebound: Vector2 = Vector2(max(0.92, 2.0 - peak.x), min(1.10, 2.0 - peak.y))
	var tint: Color = profile.get("enemy_tint", Color(1.0, 0.85, 0.85, 1.0))
	marker.modulate = tint
	var tween := marker.create_tween()
	tween.tween_property(marker, "position", orig_p + Vector2(-push, 0.0), 0.03)
	tween.parallel().tween_property(marker, "scale", peak, 0.03)
	tween.tween_property(marker, "position", orig_p + Vector2(push * 0.66, 0.0), 0.04)
	tween.parallel().tween_property(marker, "scale", rebound, 0.04)
	tween.tween_property(marker, "position", orig_p, 0.05)
	tween.parallel().tween_property(marker, "scale", orig_s, 0.05)
	tween.parallel().tween_property(marker, "modulate", orig_m, 0.10)
