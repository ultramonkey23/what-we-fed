extends RefCounted

var _flash_overlay: ColorRect
var _camera_2d: Camera2D
var _timing_circle_container: Node2D
var _attack_fx_container: Node2D
var _player_combat: Node2D
var _lane_manager: Node
var _enemy_markers_by_id: Dictionary
var _ring_highlight_timers: Array[float]
var _bg_sprite: TextureRect = null
var _flash_tween: Tween = null


func _init(
	flash_overlay: ColorRect,
	camera_2d: Camera2D,
	timing_circle_container: Node2D,
	attack_fx_container: Node2D,
	player_combat: Node2D,
	lane_manager: Node,
	enemy_markers_by_id: Dictionary,
	ring_highlight_timers: Array[float],
	bg_sprite: TextureRect = null
) -> void:
	_flash_overlay = flash_overlay
	_camera_2d = camera_2d
	_timing_circle_container = timing_circle_container
	_attack_fx_container = attack_fx_container
	_player_combat = player_combat
	_lane_manager = lane_manager
	_enemy_markers_by_id = enemy_markers_by_id
	_ring_highlight_timers = ring_highlight_timers
	_bg_sprite = bg_sprite


func _get_enemy_marker_root(enemy_id: int) -> Node2D:
	var marker: Node2D = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
		return null
	return marker


func _get_enemy_marker_body(marker: Node2D) -> ColorRect:
	if marker == null:
		return null
	return marker.get_node_or_null("Body") as ColorRect


func _get_enemy_marker_center(marker: Node2D) -> Vector2:
	var body: ColorRect = _get_enemy_marker_body(marker)
	if body == null:
		return marker.position
	return marker.position + body.position + body.size * 0.5


func on_screen_flash(color: Color, duration: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	
	_flash_overlay.color = color
	_flash_tween = _flash_overlay.create_tween()
	_flash_tween.tween_property(_flash_overlay, "color:a", color.a, 0.03)
	
	# Simulated chromatic shift jitter: brief camera offset at the peak of the flash.
	if color.a > 0.10:
		var jitter_offset := Vector2(randf_range(-3.0, 3.0), randf_range(-1.0, 1.0))
		var original_cam_offset: Vector2 = _camera_2d.offset
		_camera_2d.offset += jitter_offset
		_flash_tween.parallel().tween_property(_camera_2d, "offset", original_cam_offset, 0.08).set_delay(0.04)

	_flash_tween.tween_interval(duration)
	_flash_tween.tween_property(_flash_overlay, "color:a", 0.0, 0.12)


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
		tween.tween_property(_camera_2d, "offset", original_offset, half * 0.4)

	tween.tween_callback(func() -> void:
		_camera_2d.offset = original_offset
	)


func on_timing_ring_pressed(lane: int) -> void:
	animate_timing_ring_press(lane)
	spawn_attack_silhouette_to_lane(lane, Color(1.0, 1.0, 1.0, 0.18), 5.0, 0.08, 0.72)


func on_beat_pulse(quality: String, strength: float) -> void:
	if _bg_sprite == null or not is_instance_valid(_bg_sprite):
		return

	var original_modulate: Color = _bg_sprite.modulate
	var pulse_color: Color = original_modulate
	
	match quality:
		"perfect":
			pulse_color = original_modulate.lightened(0.12)
		"good":
			pulse_color = original_modulate.lightened(0.06)
	
	var tween := _bg_sprite.create_tween()
	tween.tween_property(_bg_sprite, "modulate", pulse_color, 0.05)
	tween.tween_property(_bg_sprite, "modulate", original_modulate, 0.15)


func highlight_timing_ring(lane: int, color: Color, width: float = 4.0) -> void:
	var group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_%d" % lane)
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
	var group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_%d" % lane)
	if group == null:
		return

	var original_position: Vector2 = group.position
	var original_scale: Vector2 = group.scale

	group.scale = Vector2(0.92, 0.92)
	group.position += Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))

	var tween := group.create_tween()
	tween.tween_property(group, "scale", original_scale, 0.06)
	tween.parallel().tween_property(group, "position", original_position, 0.06)


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
	var end_point: Vector2 = Vector2(
		_lane_manager.get_hit_zone_x() + 8.0,
		_lane_manager.get_lane_y(lane)
	)
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

	var tex: Texture2D = load(texture_path)
	if tex == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.modulate = tint
	sprite.modulate.a = 0.0
	
	# Start slightly behind the player, leaning into the field.
	var start_pos: Vector2 = _player_combat.position + Vector2(-40.0, -12.0)
	var end_pos: Vector2 = Vector2(
		_lane_manager.get_hit_zone_x() - 20.0,
		_lane_manager.get_lane_y(lane)
	)
	
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

	var hitstop_scale: float = float(profile.get("hitstop_scale", 1.0))
	if hitstop_scale > 0.0 and hitstop_scale < 0.999:
		EventBus.emit_signal("slow_motion", hitstop_scale, float(profile.get("hitstop_duration", 0.03)))

	if lane >= 0:
		var ring_width: float = float(profile.get("ring_width", 0.0))
		if ring_width > 0.0:
			var burst_color: Color = profile.get("burst_color", Color(1.0, 1.0, 1.0, 0.35))
			highlight_timing_ring(lane, burst_color, ring_width)

	if enemy_id >= 0:
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
