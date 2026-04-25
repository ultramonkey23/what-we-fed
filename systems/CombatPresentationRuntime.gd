extends RefCounted

const MOTION_JUICE = preload("res://systems/MotionJuice.gd")
const HUD_PANEL_ART = preload("res://systems/HUDPanelArt.gd")
const BLACK_SIGNAL_SHADER = preload("res://art/vfx/black_signal_combat.gdshader")
const ENEMY_BEAT_PULSE_INTENSITY: float = 0.03

var _flash_overlay: ColorRect
var _camera_2d: Camera2D
var _timing_circle_container: Node2D
var _attack_fx_container: Node2D
var _player_combat: Node2D
var _lane_manager: Node
var _ui_layer: CanvasLayer # New field
var _enemy_markers_by_id: Dictionary
var _ring_highlight_timers: Array[float]
var _bg_sprite: Control = null
var _bg_pulse_targets: Array[CanvasItem] = []
var _flash_tween: Tween = null
var _enemy_shader_material_by_id: Dictionary = {}
var _enemy_flash_tweens_by_id: Dictionary = {}
## 0..1 from CombatScene critical threat; dampens low-authority screen flashes only.
var _readability_stress: float = 0.0

# Sigil heartbeat overlay state — created lazily inside the TimingRing_Core sigil group.
# Communicates input-heard / recovery-clock / result-emphasis. Never names a verb.
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
	lane_manager: Node,
	ui_layer: CanvasLayer, # New parameter
	enemy_markers_by_id: Dictionary,
	ring_highlight_timers: Array[float],
	bg_sprite: Control = null
) -> void:
	_flash_overlay = flash_overlay
	_camera_2d = camera_2d
	_timing_circle_container = timing_circle_container
	_attack_fx_container = attack_fx_container
	_player_combat = player_combat
	_lane_manager = lane_manager
	_ui_layer = ui_layer # Set field
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
	if not is_instance_valid(root):
		return null
	
	return root as Node2D


func _get_enemy_marker_body(marker: Node2D) -> ColorRect:
	if not is_instance_valid(marker):
		return null
	
	# Since we pass markers around, we might have the root node directly.
	# But in our system, marker_data contains the pre-cached Body.
	# We search for the ID to use the cache if possible.
	for enemy_id in _enemy_markers_by_id:
		var marker_data = _enemy_markers_by_id[enemy_id]
		if not marker_data is Dictionary:
			continue
			
		var root = marker_data.get("root")
		if is_instance_valid(root) and root == marker:
			var body = marker_data.get("body")
			if is_instance_valid(body):
				return body as ColorRect
			
	return marker.get_node_or_null("Body") as ColorRect


func _get_enemy_marker_center(marker: Node2D) -> Vector2:
	var body: ColorRect = _get_enemy_marker_body(marker)
	if body == null:
		return marker.position
	return marker.position + body.position + body.size * 0.5


func on_song_beat_pulse(_beat_index: int, intensity: float, quality: String) -> void:
	_pulse_active_enemy_markers(intensity)
	on_beat_pulse(quality, intensity)


func _pulse_active_enemy_markers(_intensity: float) -> void:
	for enemy_id_variant in _enemy_markers_by_id.keys():
		var enemy_id: int = int(enemy_id_variant)
		if not _is_enemy_id_active(enemy_id):
			continue
		_ensure_enemy_shader_material(enemy_id)
		var pulse_target: CanvasItem = _resolve_enemy_visual_target(enemy_id)
		if pulse_target == null:
			continue
		MOTION_JUICE.beat_pulse(pulse_target, ENEMY_BEAT_PULSE_INTENSITY)


func _is_enemy_id_active(enemy_id: int) -> bool:
	if _lane_manager == null or not _lane_manager.has_method("get_enemy"):
		return true
	for lane in range(_lane_manager.THREAT_COUNT if _lane_manager else 4):
		var lane_enemy_v: Variant = _lane_manager.call("get_enemy", lane)
		if not lane_enemy_v is Dictionary:
			continue
		var lane_enemy: Dictionary = lane_enemy_v
		if lane_enemy.is_empty():
			continue
		if float(lane_enemy.get("hp", 0.0)) <= 0.0:
			continue
		if int(lane_enemy.get("id", -1)) == enemy_id:
			return true
	return false


func _resolve_enemy_visual_target(enemy_id: int) -> CanvasItem:
	var marker_data_v: Variant = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data_v == null or not marker_data_v is Dictionary:
		return null
	var marker_data: Dictionary = marker_data_v

	var root_v: Variant = marker_data.get("root", null)
	if is_instance_valid(root_v) and root_v is Node2D:
		var root: Node2D = root_v
		var silhouette: Node = root.get_node_or_null("CreatureSilhouette")
		if is_instance_valid(silhouette) and silhouette is CanvasItem:
			return silhouette as CanvasItem

	var body_v: Variant = marker_data.get("body", null)
	if is_instance_valid(body_v) and body_v is CanvasItem:
		return body_v as CanvasItem

	if is_instance_valid(root_v) and root_v is CanvasItem:
		return root_v as CanvasItem
	return null


func _bind_enemy_visual_materials() -> void:
	for enemy_id_variant in _enemy_markers_by_id.keys():
		_ensure_enemy_shader_material(int(enemy_id_variant))


func _get_enemy_shader_material(enemy_id: int) -> ShaderMaterial:
	var existing_v: Variant = _enemy_shader_material_by_id.get(enemy_id, null)
	if existing_v is ShaderMaterial and is_instance_valid(existing_v):
		return existing_v as ShaderMaterial
	return _ensure_enemy_shader_material(enemy_id)


func _ensure_enemy_shader_material(enemy_id: int) -> ShaderMaterial:
	var target: CanvasItem = _resolve_enemy_visual_target(enemy_id)
	if target == null:
		_enemy_shader_material_by_id.erase(enemy_id)
		return null

	var shader_material: ShaderMaterial = null
	if target.material is ShaderMaterial:
		var existing: ShaderMaterial = target.material as ShaderMaterial
		if existing != null and existing.shader == BLACK_SIGNAL_SHADER:
			shader_material = existing

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
	if shader_material == null:
		return

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
	if target == null or not target is Node:
		return

	_kill_enemy_flash_tween(enemy_id)
	var tween: Tween = (target as Node).create_tween()
	_enemy_flash_tweens_by_id[enemy_id] = tween
	tween.tween_method(func(value: float) -> void:
		shader_material.set_shader_parameter("hit_flash_intensity", value)
	, 1.0, 0.0, 0.10)
	tween.parallel().tween_method(func(value: float) -> void:
		shader_material.set_shader_parameter("chromatic_aberration", value)
	, chroma, 0.0, 0.10)
	tween.finished.connect(func() -> void:
		if _enemy_flash_tweens_by_id.get(enemy_id, null) == tween:
			_enemy_flash_tweens_by_id.erase(enemy_id)
	)


func _kill_enemy_flash_tween(enemy_id: int) -> void:
	var tween_v: Variant = _enemy_flash_tweens_by_id.get(enemy_id, null)
	if tween_v == null:
		return
	var tween: Tween = tween_v as Tween
	if tween != null and is_instance_valid(tween):
		tween.kill()
	_enemy_flash_tweens_by_id.erase(enemy_id)


func on_screen_flash(color: Color, duration: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	
	var flash_color: Color = color
	# Under imminent threat, soften small tap flashes so defense/damage reads stay dominant.
	if _readability_stress > 0.62 and flash_color.a > 0.0 and flash_color.a < 0.22:
		var damp: float = lerpf(1.0, 0.58, clampf((_readability_stress - 0.62) / 0.38, 0.0, 1.0))
		flash_color.a *= damp
	
	_flash_overlay.color = flash_color
	_flash_tween = _flash_overlay.create_tween()
	
	# Manga Inversion: 0.99 alpha is our signal for a sharp white-to-black inversion.
	var is_manga_inversion: bool = flash_color.a > 0.985
	if is_manga_inversion:
		_flash_overlay.color = Color.WHITE
		_flash_overlay.color.a = 1.0
		# Flash white instantly, then snap to black, then fade out.
		_flash_tween.tween_interval(0.015)
		_flash_tween.tween_property(_flash_overlay, "color", Color.BLACK, 0.01)
		_flash_tween.tween_interval(duration)
		_flash_tween.tween_property(_flash_overlay, "color:a", 0.0, 0.15)
	else:
		_flash_tween.tween_property(_flash_overlay, "color:a", flash_color.a, 0.03)
		_flash_tween.tween_interval(duration)
		_flash_tween.tween_property(_flash_overlay, "color:a", 0.0, 0.12)
	
	# Simulated chromatic shift jitter for high-authority hits.
	if flash_color.a > 0.10:
		var jitter_offset := Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
		var original_cam_offset: Vector2 = _camera_2d.offset
		_camera_2d.offset += jitter_offset
		_flash_tween.parallel().tween_property(_camera_2d, "offset", original_cam_offset, 0.10).set_delay(0.02)


func on_dna_resonated(color: Color, intensity: float) -> void:
	if _ui_layer == null:
		return
	
	# Apply recursive pulse/color shift to all HUD panels
	HUD_PANEL_ART.pulse_recursive(_ui_layer, intensity, color)
	
	# Fade back to default predatory red over time
	var tween := _ui_layer.create_tween()
	tween.tween_interval(0.12)
	tween.tween_method(func(val: float) -> void:
		var current_color: Color = color.lerp(Color(0.8, 0.1, 0.15), val)
		var current_pulse: float = lerpf(intensity, 0.0, val)
		HUD_PANEL_ART.pulse_recursive(_ui_layer, current_pulse, current_color)
	, 0.0, 1.0, 0.45)


func on_screen_shake(intensity: float, duration: float) -> void:
	# Multi-step shake with a small Y component for dimensional feel.
	# Heavier shakes (intensity >= 2.0) use three reversals instead of one.
	var original_offset: Vector2 = _camera_2d.offset
	var tween := _camera_2d.create_tween()
	var y_factor: float = intensity * 0.28

	if intensity >= 2.0:
		var step: float = duration / 6.0
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(intensity, y_factor), step)
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(-intensity * 0.75, -y_factor * 0.6), step)
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(intensity * 0.50, y_factor * 0.4), step)
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(-intensity * 0.30, -y_factor * 0.2), step)
		tween.tween_property(_camera_2d, "offset", original_offset, step * 2.0)
	else:
		var half: float = duration * 0.5
		tween.tween_property(_camera_2d, "offset", original_offset + Vector2(intensity, y_factor), half)
		tween.tween_property(_camera_2d, "offset", original_offset - Vector2(intensity * 0.5, y_factor * 0.4), half * 0.6)
		tween.tween_property(_camera_2d, "offset", original_offset, half)


func on_ui_shake(intensity: float, duration: float) -> void:
	if _ui_layer == null:
		return
	
	var high_impact: bool = intensity >= 1.2
	
	# Shake all direct control children of the UI layer
	for child in _ui_layer.get_children():
		if child is Control:
			var original_pos: Vector2 = child.position
			var tween := child.create_tween()
			var step: float = duration / (4.0 if high_impact else 2.0)
			
			if high_impact:
				# Sharp, jagged shake for heavy hits
				tween.tween_property(child, "position", original_pos + Vector2(intensity * 1.5, -intensity), step)
				tween.tween_property(child, "position", original_pos + Vector2(-intensity, intensity * 1.2), step)
				tween.tween_property(child, "position", original_pos + Vector2(intensity * 0.5, intensity * 0.5), step)
				tween.tween_property(child, "position", original_pos, step)
				
				# If it's a label, add a brief "digital jitter" color shift
				if child is Label:
					var original_color: Color = child.modulate
					var jitter_tween := child.create_tween()
					jitter_tween.tween_property(child, "modulate", Color(1.5, 0.5, 0.5, 1.0), 0.04)
					jitter_tween.tween_property(child, "modulate", original_color, 0.08)
			else:
				# Smooth bounce for light hits
				tween.tween_property(child, "position", original_pos + Vector2(intensity, intensity * 0.5), step)
				tween.tween_property(child, "position", original_pos, step)


func on_timing_ring_pressed(lane: int) -> void:
	animate_timing_ring_press(lane)
	spawn_attack_silhouette_to_lane(lane, Color(1.0, 1.0, 1.0, 0.18), 5.0, 0.08, 0.72)


func on_beat_pulse(quality: String, strength: float) -> void:
	if _bg_pulse_targets.is_empty():
		# If the background was swapped/late-loaded, try one re-cache.
		_cache_bg_pulse_targets()
		if _bg_pulse_targets.is_empty():
			return

	var stress_damp: float = lerpf(1.0, 0.72, clampf((_readability_stress - 0.55) / 0.45, 0.0, 1.0))
	var eff_strength: float = strength * stress_damp

	for child in _bg_pulse_targets:
		if not is_instance_valid(child):
			continue
			
		var original_modulate: Color = child.modulate
		var pulse_color: Color = original_modulate
		
		match quality:
			"accent":
				pulse_color = original_modulate.lightened(0.18 * eff_strength)
			"perfect":
				pulse_color = original_modulate.lightened(0.12 * eff_strength)
			"good":
				pulse_color = original_modulate.lightened(0.06 * eff_strength)
		
		var tween := child.create_tween()
		tween.tween_property(child, "modulate", pulse_color, 0.05)
		tween.tween_property(child, "modulate", original_modulate, 0.15)


func highlight_timing_ring(lane: int, color: Color, width: float = 4.0) -> void:
	var group: Node2D = _get_timing_receiver(lane)
	if group == null:
		return

	_ring_highlight_timers[lane] = 0.20

	for child in group.get_children():
		if child is Line2D:
			var ring := child as Line2D
			if ring.name == "BeatMark":
				continue
			ring.default_color = color
			ring.width = width if ring.name == "Perfect" else max(width - 1.2, 1.8)
		elif child is Polygon2D and child.name == "ReceiverFill":
			# Brief fill flash — conveys impact through the timing ring interior.
			var fill := child as Polygon2D
			var original_alpha: float = fill.color.a
			var flash_color: Color = Color(color.r, color.g, color.b, 0.28)
			fill.color = flash_color
			var tween := fill.create_tween()
			tween.tween_property(fill, "color:a", original_alpha, 0.22)


func animate_timing_ring_press(lane: int) -> void:
	var group: Node2D = _get_timing_receiver(lane)
	if group == null:
		return

	var original_position: Vector2 = group.position
	var original_scale: Vector2 = group.scale

	group.scale = Vector2(0.92, 0.92)
	group.position += Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))

	var tween := group.create_tween()
	tween.tween_property(group, "scale", original_scale, 0.06)
	tween.parallel().tween_property(group, "position", original_position, 0.06)


func _get_timing_receiver(lane: int) -> Node2D:
	if _timing_circle_container == null:
		return null

	var group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_%d" % lane)
	if group != null:
		return group

	return _timing_circle_container.get_node_or_null("TimingRing_Core")


func spawn_attack_silhouette_to_lane(
	lane: int,
	color: Color,
	thickness: float,
	lifetime: float,
	reach_scale: float
) -> void:
	if _player_combat == null or _lane_manager == null:
		return

	var start_point: Vector2 = _player_combat.position + Vector2(10.0, -6.0)
	var end_point: Vector2 = _lane_manager.get_threat_hit_zone_pos(lane)
	# Add a small outward offset for the slash tip
	var dir_vec: Vector2 = (end_point - _lane_manager.get_player_pos()).normalized()
	end_point += dir_vec * 8.0
	
	var delta: Vector2 = (end_point - start_point) * reach_scale
	var length: float = max(delta.length(), 10.0)
	var angle: float = delta.angle()

	var slash := Polygon2D.new()
	slash.color = color
	slash.position = start_point
	slash.rotation = angle
	slash.scale = Vector2(0.18, 1.0)
	slash.polygon = PackedVector2Array([
		Vector2(0.0, -thickness * 0.5),
		Vector2(length, -thickness * 0.5),
		Vector2(length, thickness * 0.5),
		Vector2(0.0, thickness * 0.5)
	])
	_attack_fx_container.add_child(slash)

	var tween := _attack_fx_container.create_tween()
	tween.tween_property(slash, "scale:x", 1.0, 0.04)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, lifetime)
	tween.tween_callback(func() -> void:
		if is_instance_valid(slash):
			slash.queue_free()
	)


func spawn_creature_intervention(
	lane: int,
	texture_path: String,
	tint: Color,
	lifetime: float = 0.45
) -> void:
	if texture_path.is_empty() or _player_combat == null or _lane_manager == null:
		return

	var tex: Texture2D = load(texture_path) as Texture2D
	if tex == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.modulate = tint
	sprite.modulate.a = 0.0
	
	# Start slightly behind the player, leaning into the field.
	var start_pos: Vector2 = _player_combat.position + Vector2(-40.0, -12.0)
	var end_pos: Vector2 = _lane_manager.get_threat_hit_zone_pos(lane)
	# Inset slightly toward player from hit zone
	var dir_vec: Vector2 = (end_pos - _lane_manager.get_player_pos()).normalized()
	end_pos -= dir_vec * 20.0
	
	sprite.position = start_pos
	# Intervention scale: start large and slightly transparent, punch in.
	sprite.scale = Vector2(0.045, 0.045)
	sprite.z_index = 20 # High visibility
	
	_attack_fx_container.add_child(sprite)

	var tween := sprite.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	
	# Brief punch-in animation: silhouette appears, moves to lane, then fades.
	tween.tween_property(sprite, "modulate:a", tint.a, 0.08)
	tween.parallel().tween_property(sprite, "position", end_pos, 0.12)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.052, 0.052), 0.12)
	
	tween.tween_interval(lifetime - 0.20)
	
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.058, 0.058), 0.12)
	tween.parallel().tween_property(sprite, "position", end_pos + Vector2(25.0, 0.0), 0.12)
	
	tween.tween_callback(func() -> void:
		if is_instance_valid(sprite):
			sprite.queue_free()
	)


func apply_impact_profile(profile: Dictionary, lane: int = -1, enemy_id: int = -1) -> void:
	if profile.is_empty():
		return

	var flash_color: Color = profile.get("flash_color", Color.TRANSPARENT)
	if flash_color.a > 0.0:
		EventBus.emit_signal("screen_flash", flash_color, float(profile.get("flash_duration", 0.05)))

	var shake_intensity: float = float(profile.get("shake_intensity", 0.0))
	if shake_intensity > 0.0:
		EventBus.emit_signal("screen_shake", shake_intensity, float(profile.get("shake_duration", 0.08)))
		# Premium: heavy hits also shake the UI slightly
		if shake_intensity >= 0.8:
			EventBus.emit_signal("ui_shake", shake_intensity * 0.5, float(profile.get("shake_duration", 0.08)) * 1.5)

	var hitstop_scale: float = float(profile.get("hitstop_scale", 1.0))
	if hitstop_scale > 0.0 and hitstop_scale < 0.999:
		EventBus.emit_signal("slow_motion", hitstop_scale, float(profile.get("hitstop_duration", 0.03)))

	if lane >= 0:
		var ring_width: float = float(profile.get("ring_width", 0.0))
		if ring_width > 0.0:
			var burst_color: Color = profile.get("burst_color", Color(1.0, 1.0, 1.0, 0.35))
			highlight_timing_ring(lane, burst_color, ring_width)

	if enemy_id >= 0:
		flash_enemy_damage(enemy_id, profile)
		animate_enemy_damage(enemy_id, profile)
		var burst_color: Color = profile.get("burst_color", Color(1.0, 0.55, 0.35, 0.32))
		var b_scale: float = float(profile.get("burst_scale", 1.0))
		spawn_enemy_impact_burst(
			enemy_id,
			burst_color,
			b_scale,
			float(profile.get("burst_lifetime", 0.14))
		)
		# For strong hits (burst_scale >= 1.3) spawn manga-style impact lines.
		if b_scale >= 1.3:
			var marker: Node2D = _get_enemy_marker_root(enemy_id)
			if marker != null:
				var impact_center: Vector2 = _get_enemy_marker_center(marker)
				var line_color: Color = Color(burst_color.r, burst_color.g, burst_color.b, burst_color.a * 0.55)
				var line_count: int = 8 if b_scale >= 1.4 else 5
				spawn_impact_lines(impact_center, line_color, line_count, 26.0, 0.13)

	play_combat_sfx(String(profile.get("sfx_cue", "")))


func play_combat_sfx(cue_id: String) -> void:
	if cue_id.is_empty():
		return
	EventBus.emit_signal("play_sfx", cue_id)


func animate_enemy_damage(enemy_id: int, profile: Dictionary = {}) -> void:
	var marker: Node2D = _get_enemy_marker_root(enemy_id)
	if marker == null:
		return

	var original_position: Vector2 = marker.position
	var original_scale: Vector2 = marker.scale
	var original_modulate: Color = marker.modulate
	var push: float = float(profile.get("enemy_push", 6.0))
	var peak_scale: Vector2 = profile.get("enemy_scale", Vector2(1.12, 0.88))
	var rebound_scale: Vector2 = Vector2(
		max(0.92, 2.0 - peak_scale.x),
		min(1.10, 2.0 - peak_scale.y)
	)
	var hit_tint: Color = profile.get("enemy_tint", Color(1.0, 0.85, 0.85, 1.0))

	marker.modulate = hit_tint

	var tween := marker.create_tween()
	tween.tween_property(marker, "position", original_position + Vector2(-push, 0.0), 0.03)
	tween.parallel().tween_property(marker, "scale", peak_scale, 0.03)
	tween.tween_property(marker, "position", original_position + Vector2(push * 0.66, 0.0), 0.04)
	tween.parallel().tween_property(marker, "scale", rebound_scale, 0.04)
	tween.tween_property(marker, "position", original_position, 0.05)
	tween.parallel().tween_property(marker, "scale", original_scale, 0.05)
	tween.parallel().tween_property(marker, "modulate", original_modulate, 0.10)


func spawn_enemy_impact_burst(enemy_id: int, color: Color, burst_scale: float, lifetime: float) -> void:
	var marker: Node2D = _get_enemy_marker_root(enemy_id)
	if marker == null:
		return

	var center: Vector2 = _get_enemy_marker_center(marker)

	# Spike star — 8 alternating long/short points for sharper manga-style impact reads.
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
	tween.tween_callback(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


func spawn_impact_lines(center: Vector2, color: Color, count: int, length: float, lifetime: float) -> void:
	# Radial impact lines — manga-style concentrated force lines from the impact point.
	# Used for strong hits (burst_scale >= 1.3) to convey force without particle clutter.
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
		tween.tween_callback(func() -> void:
			if is_instance_valid(line):
				line.queue_free()
		)


# --- Sigil heartbeat: input echo / recovery sweep / result snap ----------------------------
# These overlays sit inside the TimingRing_Core sigil group and reflect combat *state* only:
# input was heard, recovery is ticking, a clean exchange just landed. They never tell the
# player which verb to press and never gate inputs to the beat — the sigil stays a heartbeat.

func _ensure_sigil_overlay_nodes() -> void:
	if _sigil_overlay_ready and is_instance_valid(_input_echo_line) \
			and is_instance_valid(_recovery_arc_line) and is_instance_valid(_ready_pulse_line):
		return
	if _timing_circle_container == null:
		return
	var sigil_group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_Core")
	if sigil_group == null:
		return

	var outer_r: float = 96.0
	var perfect_inner_r: float = 72.0
	var perfect_outer_r: float = 110.0
	var existing_outer: Node = sigil_group.get_node_or_null("Outer")
	if existing_outer is Line2D and (existing_outer as Line2D).points.size() > 0:
		outer_r = (existing_outer as Line2D).points[0].length()
	var existing_perfect_inner: Node = sigil_group.get_node_or_null("PerfectInnerGuide")
	if existing_perfect_inner is Line2D and (existing_perfect_inner as Line2D).points.size() > 0:
		perfect_inner_r = (existing_perfect_inner as Line2D).points[0].length()
	var existing_perfect_outer: Node = sigil_group.get_node_or_null("PerfectOuterGuide")
	if existing_perfect_outer is Line2D and (existing_perfect_outer as Line2D).points.size() > 0:
		perfect_outer_r = (existing_perfect_outer as Line2D).points[0].length()

	if not is_instance_valid(_input_echo_line):
		_input_echo_line = Line2D.new()
		_input_echo_line.name = "InputEcho"
		_input_echo_line.closed = true
		_input_echo_line.joint_mode = Line2D.LINE_JOINT_ROUND
		_input_echo_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_input_echo_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		_input_echo_line.default_color = Color(1.0, 1.0, 1.0, 0.0)
		_input_echo_line.width = 2.4
		var ep := PackedVector2Array()
		for i in range(48):
			var a: float = (float(i) / 48.0) * TAU
			ep.append(Vector2(cos(a), sin(a)) * (outer_r + 4.0))
		_input_echo_line.points = ep
		sigil_group.add_child(_input_echo_line)

	if not is_instance_valid(_recovery_arc_line):
		_recovery_arc_line = Line2D.new()
		_recovery_arc_line.name = "RecoveryArc"
		_recovery_arc_line.closed = false
		_recovery_arc_line.joint_mode = Line2D.LINE_JOINT_ROUND
		_recovery_arc_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_recovery_arc_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		_recovery_arc_line.default_color = Color(0.92, 0.66, 0.32, 0.0)
		_recovery_arc_line.width = 2.4
		_recovery_arc_line.set_meta("radius", (perfect_inner_r + perfect_outer_r) * 0.5 - 6.0)
		sigil_group.add_child(_recovery_arc_line)

	if not is_instance_valid(_ready_pulse_line):
		_ready_pulse_line = Line2D.new()
		_ready_pulse_line.name = "ReadyPulse"
		_ready_pulse_line.closed = true
		_ready_pulse_line.joint_mode = Line2D.LINE_JOINT_ROUND
		_ready_pulse_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_ready_pulse_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		_ready_pulse_line.default_color = Color(0.85, 0.96, 1.0, 0.0)
		_ready_pulse_line.width = 1.8
		var rp := PackedVector2Array()
		for i in range(48):
			var a: float = (float(i) / 48.0) * TAU
			rp.append(Vector2(cos(a), sin(a)) * max(perfect_inner_r - 4.0, 12.0))
		_ready_pulse_line.points = rp
		sigil_group.add_child(_ready_pulse_line)

	_sigil_overlay_ready = true


func pulse_sigil_input_echo(action: String, accepted: bool, buffered: bool, reason: String) -> void:
	# State-only feedback that the input was heard. Color codes resolution (accepted /
	# buffered / rejected) without naming a verb. Keeps the sigil a heartbeat, not a prompt.
	_ensure_sigil_overlay_nodes()
	if not is_instance_valid(_input_echo_line):
		return

	var tint: Color
	var fade: float
	if accepted:
		tint = Color(1.0, 0.98, 0.92, 0.46)
		fade = 0.22
	elif buffered:
		tint = Color(0.66, 0.86, 1.0, 0.42)
		fade = 0.20
	else:
		match reason:
			"no_stamina":
				tint = Color(1.0, 0.45, 0.45, 0.40)
			"no_charge":
				tint = Color(1.0, 0.62, 0.30, 0.38)
			"locked":
				tint = Color(1.0, 0.78, 0.42, 0.38)
			_:
				tint = Color(1.0, 0.55, 0.48, 0.36)
		fade = 0.18

	_input_echo_line.default_color = tint
	_input_echo_line.width = 3.2 if accepted else (2.4 if buffered else 2.0)

	if _input_echo_tween != null and is_instance_valid(_input_echo_tween):
		_input_echo_tween.kill()
	_input_echo_tween = _input_echo_line.create_tween()
	_input_echo_tween.tween_property(_input_echo_line, "default_color:a", 0.0, fade)
	# Suppress unused-arg warning while keeping the public contract self-documenting.
	if action.is_empty():
		pass


func tick_sigil_recovery(player_combat: Node2D, _delta: float) -> void:
	# Polled per frame from CombatScene._update_presentation_layers. Reads the player's
	# action_lock_timer and visualizes the shrinking recovery arc, then fires a "ready"
	# pulse on the lock→unlock transition. Tells the player WHEN they can act again.
	_ensure_sigil_overlay_nodes()
	if not is_instance_valid(_recovery_arc_line) or player_combat == null:
		return

	var lock_now: float = float(player_combat.get("action_lock_timer"))
	var state_now: String = String(player_combat.get("current_action_state"))

	if lock_now > 0.0:
		if not _recovery_was_locked or lock_now > _recovery_initial:
			_recovery_initial = max(lock_now, 0.001)
			_recovery_state = state_now
		var t: float = clamp(lock_now / _recovery_initial, 0.0, 1.0)
		_draw_recovery_arc(t, _recovery_state)
		_recovery_was_locked = true
	else:
		if _recovery_was_locked:
			_emit_ready_pulse(_recovery_state)
			_recovery_arc_line.points = PackedVector2Array()
			_recovery_arc_line.default_color.a = 0.0
		_recovery_was_locked = false
		_recovery_initial = 0.0
		_recovery_state = ""


func _draw_recovery_arc(progress: float, state: String) -> void:
	if not is_instance_valid(_recovery_arc_line):
		return
	var radius: float = float(_recovery_arc_line.get_meta("radius", 80.0))
	var arc_color: Color = _recovery_arc_color_for_state(state)
	arc_color.a = lerpf(0.18, 0.62, clampf(progress, 0.0, 1.0))
	_recovery_arc_line.default_color = arc_color

	# Sweep clockwise from the top (-PI/2) so a fixed anchor reads like a clock hand.
	var start_angle: float = -PI * 0.5
	var sweep: float = TAU * progress
	var seg_count: int = 36
	var pts := PackedVector2Array()
	for i in range(seg_count + 1):
		var f: float = float(i) / float(seg_count)
		var a: float = start_angle + sweep * f
		pts.append(Vector2(cos(a), sin(a)) * radius)
	_recovery_arc_line.points = pts


func _recovery_arc_color_for_state(state: String) -> Color:
	match state:
		"parry", "failed_parry", "parry_followup":
			return Color(0.55, 0.92, 0.74, 1.0)
		"dodge":
			return Color(0.62, 0.84, 1.0, 1.0)
		"ultimate":
			return Color(1.0, 0.78, 0.32, 1.0)
		"early_attack", "late_attack":
			return Color(1.0, 0.55, 0.36, 1.0)
		_:
			return Color(0.95, 0.78, 0.42, 1.0)


func _emit_ready_pulse(prev_state: String) -> void:
	if not is_instance_valid(_ready_pulse_line):
		return
	var pulse_color: Color = _recovery_arc_color_for_state(prev_state)
	pulse_color.a = 0.62
	_ready_pulse_line.default_color = pulse_color
	_ready_pulse_line.width = 2.2
	_ready_pulse_line.scale = Vector2.ONE

	if _ready_pulse_tween != null and is_instance_valid(_ready_pulse_tween):
		_ready_pulse_tween.kill()
	_ready_pulse_tween = _ready_pulse_line.create_tween().set_parallel(true)
	_ready_pulse_tween.tween_property(_ready_pulse_line, "scale", Vector2(1.18, 1.18), 0.22) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_ready_pulse_tween.tween_property(_ready_pulse_line, "default_color:a", 0.0, 0.22)


func pulse_sigil_result_snap(quality: String, _family: String) -> void:
	# Briefly snaps the sigil's fault lines outward on a clean exchange. Amplifies the
	# chunky read of a good/perfect resolve. State-feedback only — never names the verb.
	if quality != "perfect" and quality != "good":
		return
	if _timing_circle_container == null:
		return
	var sigil_group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_Core")
	if sigil_group == null:
		return
	var fault_lines: Node = sigil_group.get_node_or_null("FaultLines")
	if not (fault_lines is Line2D):
		return
	var line := fault_lines as Line2D

	var snap_scale: float = 1.18 if quality == "perfect" else 1.10
	var hold: float = 0.06 if quality == "perfect" else 0.04
	var release: float = 0.22 if quality == "perfect" else 0.16

	if _result_snap_tween != null and is_instance_valid(_result_snap_tween):
		_result_snap_tween.kill()
	line.scale = Vector2.ONE
	_result_snap_tween = line.create_tween()
	_result_snap_tween.tween_property(line, "scale", Vector2(snap_scale, snap_scale), hold) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_result_snap_tween.tween_property(line, "scale", Vector2.ONE, release) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
