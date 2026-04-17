extends RefCounted

var _flash_overlay: ColorRect
var _camera_2d: Camera2D
var _timing_circle_container: Node2D
var _attack_fx_container: Node2D
var _player_combat: Node2D
var _lane_manager: Node
var _enemy_markers_by_id: Dictionary
var _ring_highlight_timers: Array[float]


func _init(
	flash_overlay: ColorRect,
	camera_2d: Camera2D,
	timing_circle_container: Node2D,
	attack_fx_container: Node2D,
	player_combat: Node2D,
	lane_manager: Node,
	enemy_markers_by_id: Dictionary,
	ring_highlight_timers: Array[float]
) -> void:
	_flash_overlay = flash_overlay
	_camera_2d = camera_2d
	_timing_circle_container = timing_circle_container
	_attack_fx_container = attack_fx_container
	_player_combat = player_combat
	_lane_manager = lane_manager
	_enemy_markers_by_id = enemy_markers_by_id
	_ring_highlight_timers = ring_highlight_timers


func on_screen_flash(color: Color, duration: float) -> void:
	_flash_overlay.color = color
	var tween := _flash_overlay.create_tween()
	tween.tween_property(_flash_overlay, "color:a", color.a, 0.03)
	tween.tween_interval(duration)
	tween.tween_property(_flash_overlay, "color:a", 0.0, 0.12)


func on_screen_shake(intensity: float, duration: float) -> void:
	var original_offset: Vector2 = _camera_2d.offset
	var half_duration: float = duration * 0.5
	var tween := _camera_2d.create_tween()
	tween.tween_property(_camera_2d, "offset", original_offset + Vector2(intensity, 0.0), half_duration)
	tween.tween_property(_camera_2d, "offset", original_offset - Vector2(intensity, 0.0), half_duration)
	tween.tween_callback(func() -> void:
		_camera_2d.offset = original_offset
	)


func on_timing_ring_pressed(lane: int) -> void:
	animate_timing_ring_press(lane)
	spawn_attack_silhouette_to_lane(lane, Color(1.0, 1.0, 1.0, 0.18), 5.0, 0.08, 0.72)


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
			ring.width = width if ring.name == "Good" else max(width - 1.0, 1.5)


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
		spawn_enemy_impact_burst(
			enemy_id,
			burst_color,
			float(profile.get("burst_scale", 1.0)),
			float(profile.get("burst_lifetime", 0.14))
		)

	play_combat_sfx(String(profile.get("sfx_cue", "")))


func play_combat_sfx(_cue_id: String) -> void:
	# No dedicated combat SFX assets are wired yet. Keep cue routing centralized
	# here so first real SFX intake can attach to existing impact events cleanly.
	pass


func animate_enemy_damage(enemy_id: int, profile: Dictionary = {}) -> void:
	var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
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
	var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
		return

	var center: Vector2 = marker.position + marker.size * 0.5
	var burst := Polygon2D.new()
	burst.color = color
	burst.position = center
	burst.scale = Vector2(0.35, 0.35) * burst_scale
	burst.polygon = PackedVector2Array([
		Vector2(0.0, -18.0),
		Vector2(8.0, -8.0),
		Vector2(18.0, 0.0),
		Vector2(8.0, 8.0),
		Vector2(0.0, 18.0),
		Vector2(-8.0, 8.0),
		Vector2(-18.0, 0.0),
		Vector2(-8.0, -8.0),
	])
	_attack_fx_container.add_child(burst)

	var tween := _attack_fx_container.create_tween()
	tween.tween_property(burst, "scale", Vector2.ONE * burst_scale, 0.04)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, lifetime)
	tween.tween_callback(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)
