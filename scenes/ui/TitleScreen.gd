extends Node2D

const LAIR_SCENE_PATH: String = "res://scenes/ui/LairScene.tscn"
const UI_STYLE = preload("res://systems/UIStyle.gd")

var _controls_panel: ColorRect = null
var _controls_visible: bool = false
var _can_start: bool = false


func _ready() -> void:
	_build_ui()
	# Defer enabling start-input slightly so any key held during scene transition
	# does not immediately launch the run before the title has rendered.
	await get_tree().create_timer(0.15).timeout
	_can_start = true


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_H:
		_toggle_controls_panel()
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_ESCAPE:
		if _controls_visible:
			_set_controls_panel_visible(false)
			get_viewport().set_input_as_handled()
		return

	if not _can_start:
		return
	if _controls_visible:
		return

	get_tree().change_scene_to_file(LAIR_SCENE_PATH)


func _toggle_controls_panel() -> void:
	_set_controls_panel_visible(not _controls_visible)


func _set_controls_panel_visible(visible_state: bool) -> void:
	_controls_visible = visible_state
	if _controls_panel != null:
		_controls_panel.visible = visible_state


func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.06, 0.03, 0.04, 1.0)
	bg.size = Vector2(1280.0, 720.0)
	bg.position = Vector2.ZERO
	add_child(bg)

	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var title_label: Label = Label.new()
	title_label.text = "WHAT WE FED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size = Vector2(1280.0, 100.0)
	title_label.position = Vector2(0.0, 224.0)
	UI_STYLE.apply_label(title_label, "front_title")
	canvas.add_child(title_label)

	var sub_label: Label = Label.new()
	sub_label.text = "The hollow remembers."
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.size = Vector2(1280.0, 40.0)
	sub_label.position = Vector2(0.0, 328.0)
	UI_STYLE.apply_label(sub_label, "screen_subtitle")
	canvas.add_child(sub_label)

	var prompt_label: Label = Label.new()
	prompt_label.text = "Press any key to begin"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size = Vector2(1280.0, 40.0)
	prompt_label.position = Vector2(0.0, 434.0)
	UI_STYLE.apply_label(prompt_label, "prompt")
	canvas.add_child(prompt_label)

	var hint_label: Label = Label.new()
	hint_label.text = "H - how to play"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size = Vector2(1280.0, 30.0)
	hint_label.position = Vector2(0.0, 660.0)
	UI_STYLE.apply_label(hint_label, "hint")
	canvas.add_child(hint_label)

	_controls_panel = ColorRect.new()
	_controls_panel.color = Color(0.10, 0.06, 0.06, 0.97)
	_controls_panel.size = Vector2(580.0, 370.0)
	_controls_panel.position = Vector2(350.0, 155.0)
	_controls_panel.visible = false
	canvas.add_child(_controls_panel)

	var border: ColorRect = ColorRect.new()
	border.color = Color(0.34, 0.24, 0.20, 1.0)
	border.size = Vector2(580.0, 370.0)
	border.position = Vector2.ZERO
	_controls_panel.add_child(border)

	var inner_bg: ColorRect = ColorRect.new()
	inner_bg.color = Color(0.10, 0.06, 0.06, 1.0)
	inner_bg.size = Vector2(574.0, 364.0)
	inner_bg.position = Vector2(3.0, 3.0)
	_controls_panel.add_child(inner_bg)

	var controls_text: String = (
		"How to play\n\n"
		+ "A / S / D               Attack lane 1 / 2 / 3\n"
		+ "Left Arrow + A/S/D      Parry incoming attack\n"
		+ "Right Arrow + A/S/D     Dodge to adjacent lane\n"
		+ "R                       Ultimate attack\n"
		+ "\n"
		+ "- During overlays -\n"
		+ "B / E                   Bond or Eat creature\n"
		+ "C                       Continue to next encounter\n"
		+ "1 / 2 / 3               Choose mutation\n"
		+ "R                       Restart run\n"
		+ "T                       Return to lair"
	)

	var controls_label: Label = Label.new()
	controls_label.text = controls_text
	controls_label.position = Vector2(34.0, 28.0)
	controls_label.size = Vector2(520.0, 300.0)
	UI_STYLE.apply_label(controls_label, "body")
	_controls_panel.add_child(controls_label)

	var close_hint: Label = Label.new()
	close_hint.text = "H or ESC - close"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.size = Vector2(574.0, 26.0)
	close_hint.position = Vector2(3.0, 334.0)
	UI_STYLE.apply_label(close_hint, "hint")
	_controls_panel.add_child(close_hint)
