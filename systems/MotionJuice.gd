extends RefCounted

const MIN_JUICE: float = 0.0
const MAX_JUICE: float = 2.0
const MIN_BEAT_INTENSITY: float = 0.005
const MAX_BEAT_INTENSITY: float = 0.18

static var _active_scale_tweens: Dictionary = {}


static func normalize_juice(raw_juice: float) -> float:
	return clampf(raw_juice, MIN_JUICE, MAX_JUICE)


static func beat_pulse(target: CanvasItem, intensity: float = 0.02) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target is Node:
		return

	var node: Node = target as Node
	var target_id: int = node.get_instance_id()
	_kill_active_scale_tween(target_id)

	var clamped_intensity: float = clampf(intensity, MIN_BEAT_INTENSITY, MAX_BEAT_INTENSITY)
	var base_scale: Vector2 = Vector2.ONE
	if target is Node2D:
		base_scale = (target as Node2D).scale
	elif target is Control:
		var ctrl: Control = target as Control
		ctrl.pivot_offset = Vector2(ctrl.size.x * 0.5, ctrl.size.y)
		base_scale = ctrl.scale
	else:
		return

	var beat_down_scale: Vector2 = base_scale * (1.0 - clamped_intensity)
	var tween: Tween = node.create_tween()
	_active_scale_tweens[target_id] = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if target is Node2D:
		var node2d: Node2D = target as Node2D
		tween.tween_property(node2d, "scale", beat_down_scale, 0.045)
		tween.tween_property(node2d, "scale", base_scale, 0.15)
	elif target is Control:
		var control: Control = target as Control
		tween.tween_property(control, "scale", beat_down_scale, 0.045)
		tween.tween_property(control, "scale", base_scale, 0.15)

	tween.finished.connect(func() -> void:
		if _active_scale_tweens.get(target_id, null) == tween:
			_active_scale_tweens.erase(target_id)
	)


static func build_hit_shake(raw_juice: float = 1.0) -> Dictionary:
	var juice: float = normalize_juice(raw_juice)
	return {
		"intensity": 0.45 + (0.55 * juice),
		"duration": max(0.025, 0.065 - (0.010 * juice)),
		"frequency": 24.0 + (12.0 * juice)
	}


static func build_black_signal_uniforms(raw_juice: float = 1.0) -> Dictionary:
	var juice: float = normalize_juice(raw_juice)
	return {
		"hit_flash_intensity": clampf(0.48 + (0.26 * juice), 0.0, 1.0),
		"corruption_amount": clampf(0.18 + (0.24 * juice), 0.0, 1.0),
		"chromatic_aberration": clampf(0.004 + (0.010 * juice), 0.0, 0.1),
		"hit_flash_color": Color(1.0, 0.92, 0.88, 1.0)
	}


static func _kill_active_scale_tween(target_id: int) -> void:
	var existing: Variant = _active_scale_tweens.get(target_id, null)
	if existing == null:
		return
	var tween: Tween = existing as Tween
	if tween != null and is_instance_valid(tween):
		tween.kill()
	_active_scale_tweens.erase(target_id)
