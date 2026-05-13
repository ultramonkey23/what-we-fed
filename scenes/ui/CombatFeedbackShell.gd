extends RefCounted

const FEEDBACK_PRIORITY_LOW: int = 0
const FEEDBACK_PRIORITY_MEDIUM: int = 1
const FEEDBACK_PRIORITY_HIGH: int = 2
const LOW_FEEDBACK_MIN_INTERVAL_MS: int = 260
const URGENT_FEEDBACK_HOLD_MS: int = 320

var _ui_style: GDScript
var _combat_feel_content: GDScript
var _tween_owner: Node
var _apply_text_role: Callable

var _feedback_label: Label = null
var _feedback_backing: ColorRect = null
var _title_card: Label = null
var _subtitle_card: Label = null

var _feedback_tween: Tween = null
var _feedback_active_priority: int = FEEDBACK_PRIORITY_LOW
var _feedback_active_until_ms: int = 0
var _feedback_last_low_ms: int = 0
var _feedback_block_low_until_ms: int = 0


func _init(ui_style: GDScript, combat_feel_content: GDScript, tween_owner: Node, apply_text_role: Callable) -> void:
	_ui_style = ui_style
	_combat_feel_content = combat_feel_content
	_tween_owner = tween_owner
	_apply_text_role = apply_text_role


func create_feedback_nodes(hud_overlay_layer: Control, ui_layer: CanvasLayer) -> void:
	if _feedback_label != null and is_instance_valid(_feedback_label):
		return

	var half_w: float = _combat_feel_content.HUD_COMBAT_FEEDBACK_HALF_WIDTH
	var fy: float = _combat_feel_content.HUD_COMBAT_FEEDBACK_Y
	var fh: float = _combat_feel_content.HUD_COMBAT_FEEDBACK_HEIGHT
	var parent: Node = null
	if hud_overlay_layer != null:
		parent = hud_overlay_layer
	else:
		parent = ui_layer
	if parent == null:
		return

	_feedback_backing = ColorRect.new()
	_feedback_backing.name = "FeedbackBacking"
	_feedback_backing.visible = false
	_feedback_backing.z_index = 89
	_feedback_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_backing.anchor_left = 0.5
	_feedback_backing.anchor_top = 0.0
	_feedback_backing.anchor_right = 0.5
	_feedback_backing.anchor_bottom = 0.0
	_feedback_backing.offset_left = -half_w
	_feedback_backing.offset_top = fy
	_feedback_backing.offset_right = half_w
	_feedback_backing.offset_bottom = fy + fh
	_ui_style.apply_shell_style(_feedback_backing, "feedback_backing")
	parent.add_child(_feedback_backing)

	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.visible = false
	_feedback_label.z_index = 90
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_label.anchor_left = 0.5
	_feedback_label.anchor_top = 0.0
	_feedback_label.anchor_right = 0.5
	_feedback_label.anchor_bottom = 0.0
	_feedback_label.offset_left = -half_w + 8.0
	_feedback_label.offset_top = fy + 2.0
	_feedback_label.offset_right = half_w - 8.0
	_feedback_label.offset_bottom = fy + fh - 2.0
	_feedback_label.pivot_offset = Vector2(half_w - 8.0, (fh - 4.0) * 0.5)
	_apply_text_role.call(_feedback_label, "feedback", HORIZONTAL_ALIGNMENT_CENTER)
	_feedback_label.add_theme_font_size_override("font_size", _combat_feel_content.HUD_COMBAT_FEEDBACK_FONT_SIZE)
	parent.add_child(_feedback_label)


func create_title_cards(title_host: Node) -> void:
	if _title_card != null and is_instance_valid(_title_card):
		return
	if title_host == null:
		return

	_title_card = Label.new()
	_title_card.name = "BiomeTitleCard"
	_title_card.visible = false
	_title_card.z_index = 95
	_title_card.position = Vector2(420.0, 110.0)
	_title_card.size = Vector2(480.0, 34.0)
	_apply_text_role.call(_title_card, "heading", HORIZONTAL_ALIGNMENT_CENTER)
	title_host.add_child(_title_card)

	_subtitle_card = Label.new()
	_subtitle_card.name = "BiomeSubtitleCard"
	_subtitle_card.visible = false
	_subtitle_card.z_index = 95
	_subtitle_card.position = Vector2(420.0, 140.0)
	_subtitle_card.size = Vector2(480.0, 26.0)
	_apply_text_role.call(_subtitle_card, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	title_host.add_child(_subtitle_card)


func show_title_card(title_text: String, subtitle_text: String) -> void:
	if _title_card == null or _subtitle_card == null:
		return

	_title_card.text = title_text
	_title_card.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_title_card.visible = true

	_subtitle_card.text = subtitle_text
	_subtitle_card.modulate = Color(0.85, 0.85, 0.85, 1.0)
	_subtitle_card.visible = true

	var tween: Tween = _make_tween()
	if tween == null:
		return
	tween.tween_interval(0.65)
	tween.tween_property(_title_card, "modulate:a", 0.0, 0.40)
	tween.parallel().tween_property(_subtitle_card, "modulate:a", 0.0, 0.40)
	tween.tween_callback(func() -> void:
		if _title_card != null and is_instance_valid(_title_card):
			_title_card.visible = false
			_title_card.modulate.a = 1.0
		if _subtitle_card != null and is_instance_valid(_subtitle_card):
			_subtitle_card.visible = false
			_subtitle_card.modulate.a = 1.0
	)


func show_feedback(text: String, color: Color, lifetime: float, critical_threat_pressure: float) -> void:
	if _feedback_label == null or not is_instance_valid(_feedback_label):
		return

	var display_text: String = _readability_compact_feedback_text(text)
	var now_ms: int = Time.get_ticks_msec()
	var priority: int = _feedback_priority_for_text(display_text)
	if priority == FEEDBACK_PRIORITY_LOW:
		if now_ms < _feedback_block_low_until_ms:
			return
		var low_gap_ms: int = LOW_FEEDBACK_MIN_INTERVAL_MS
		if critical_threat_pressure > 0.68:
			low_gap_ms += int(lerpf(0.0, 420.0, clampf((critical_threat_pressure - 0.68) / 0.32, 0.0, 1.0)))
		if now_ms - _feedback_last_low_ms < low_gap_ms:
			return
		_feedback_last_low_ms = now_ms
	if priority < _feedback_active_priority and now_ms < _feedback_active_until_ms:
		return
	if _feedback_tween != null and is_instance_valid(_feedback_tween):
		_feedback_tween.kill()

	if priority >= FEEDBACK_PRIORITY_HIGH:
		_feedback_block_low_until_ms = now_ms + URGENT_FEEDBACK_HOLD_MS
	_feedback_active_priority = priority
	_feedback_active_until_ms = now_ms + URGENT_FEEDBACK_HOLD_MS

	var punch: float = _combat_feel_content.HUD_COMBAT_FEEDBACK_PUNCH_SCALE
	_feedback_label.text = display_text
	_feedback_label.modulate = color
	_feedback_label.visible = true
	if _feedback_backing != null and is_instance_valid(_feedback_backing):
		_feedback_backing.visible = true
		_feedback_backing.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_feedback_backing.scale = Vector2(punch, punch)
	_feedback_label.scale = Vector2(punch, punch)

	_feedback_tween = _make_tween()
	if _feedback_tween == null:
		return
	_feedback_tween.tween_property(_feedback_label, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if _feedback_backing != null and is_instance_valid(_feedback_backing):
		_feedback_tween.parallel().tween_property(_feedback_backing, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_interval(max(lifetime, _combat_feel_content.COMBAT_FEEDBACK_MIN_LIFETIME))
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, _combat_feel_content.COMBAT_FEEDBACK_FADE_TIME)
	if _feedback_backing != null and is_instance_valid(_feedback_backing):
		_feedback_tween.parallel().tween_property(_feedback_backing, "modulate:a", 0.0, _combat_feel_content.COMBAT_FEEDBACK_FADE_TIME)
	_feedback_tween.tween_callback(func() -> void:
		_feedback_label.visible = false
		_feedback_label.modulate.a = 1.0
		_feedback_label.scale = Vector2.ONE
		if _feedback_backing != null and is_instance_valid(_feedback_backing):
			_feedback_backing.visible = false
			_feedback_backing.modulate.a = 1.0
			_feedback_backing.scale = Vector2.ONE
	)


func get_title_card() -> Label:
	return _title_card


func get_subtitle_card() -> Label:
	return _subtitle_card


func _make_tween() -> Tween:
	if _tween_owner != null and is_instance_valid(_tween_owner):
		return _tween_owner.create_tween()
	if _feedback_label != null and is_instance_valid(_feedback_label):
		return _feedback_label.create_tween()
	return null


func _readability_compact_feedback_text(text: String) -> String:
	var raw: String = text.strip_edges()
	var u: String = raw.to_upper()
	if u == "NOT READY":
		return "NO CHARGE"
	if u == "WRONG LANE":
		return "BAD ANGLE"
	if u == "THREAT CLOSE":
		return "THREAT"
	return raw


func _feedback_priority_for_text(text: String) -> int:
	var token: String = text.to_upper().strip_edges()
	if token.find("NO STAMINA") >= 0 or token.find("NO CHARGE") >= 0 or token.find("RECOVERING") >= 0 or token.find("BAD ANGLE") >= 0 or token.find("DENIED") >= 0:
		return FEEDBACK_PRIORITY_HIGH
	if token.find("STRUCK") >= 0 or token.find("EXPOSED") >= 0 or token.find("PARRY") >= 0 or token.find("DODGE") >= 0 or token.begins_with("THREAT"):
		return FEEDBACK_PRIORITY_HIGH
	if token.find("TIMED") >= 0 or token.find("HIT") >= 0 or token.find("DEFEATED") >= 0 or token.find("BROKEN") >= 0:
		return FEEDBACK_PRIORITY_MEDIUM
	if token.find("QUEUE") >= 0:
		return FEEDBACK_PRIORITY_LOW
	return FEEDBACK_PRIORITY_LOW
