extends Node2D

const LAIR_SCENE_PATH: String = "res://scenes/ui/LairScene.tscn"

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

	# H toggles the controls panel. Must not also start the run.
	if key_event.keycode == KEY_H:
		_toggle_controls_panel()
		get_viewport().set_input_as_handled()
		return

	# Escape closes the controls panel only. Does not start the run.
	if key_event.keycode == KEY_ESCAPE:
		if _controls_visible:
			_set_controls_panel_visible(false)
			get_viewport().set_input_as_handled()
		return

	# All other keys: start the run, but only if the controls panel is closed.
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
	# Full-screen dark background.
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.06, 0.03, 0.04, 1.0)
	bg.size = Vector2(1280.0, 720.0)
	bg.position = Vector2.ZERO
	add_child(bg)

	# CanvasLayer so UI nodes render on top regardless of world-space ordering.
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	# Title.
	var title_label: Label = Label.new()
	title_label.text = "WHAT WE FED"
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size = Vector2(1280.0, 100.0)
	title_label.position = Vector2(0.0, 230.0)
	canvas.add_child(title_label)

	# Subtitle.
	var sub_label: Label = Label.new()
	sub_label.text = "The hollow remembers."
	sub_label.add_theme_font_size_override("font_size", 22)
	sub_label.add_theme_color_override("font_color", Color(0.58, 0.48, 0.42, 1.0))
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.size = Vector2(1280.0, 40.0)
	sub_label.position = Vector2(0.0, 322.0)
	canvas.add_child(sub_label)

	# Press any key prompt.
	var prompt_label: Label = Label.new()
	prompt_label.text = "PRESS ANY KEY TO BEGIN"
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color(0.70, 0.65, 0.56, 0.80))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size = Vector2(1280.0, 40.0)
	prompt_label.position = Vector2(0.0, 430.0)
	canvas.add_child(prompt_label)

	# H hint at bottom.
	var hint_label: Label = Label.new()
	hint_label.text = "H — how to play"
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color(0.44, 0.40, 0.36, 0.75))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size = Vector2(1280.0, 30.0)
	hint_label.position = Vector2(0.0, 660.0)
	canvas.add_child(hint_label)

	# Controls panel — hidden by default.
	_controls_panel = ColorRect.new()
	_controls_panel.color = Color(0.10, 0.06, 0.06, 0.97)
	_controls_panel.size = Vector2(580.0, 370.0)
	_controls_panel.position = Vector2(350.0, 155.0)
	_controls_panel.visible = false
	canvas.add_child(_controls_panel)

	# Thin border frame inside the panel.
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

	# Controls text.
	var controls_text: String = (
		"HOW TO PLAY\n\n"
		+ "A / S / D               Attack lane 1 / 2 / 3\n"
		+ "Left Arrow + A/S/D      Parry incoming attack\n"
		+ "Right Arrow + A/S/D     Dodge to adjacent lane\n"
		+ "R                       Ultimate attack\n"
		+ "\n"
		+ "— DURING OVERLAYS —\n"
		+ "B / E                   Bond or Eat creature (reward)\n"
		+ "C                       Continue to next encounter\n"
		+ "1 / 2 / 3               Choose upgrade (level up)\n"
		+ "R                       Restart run\n"
		+ "T                       Return to title"
	)

	var controls_label: Label = Label.new()
	controls_label.text = controls_text
	controls_label.add_theme_font_size_override("font_size", 16)
	controls_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.70, 1.0))
	controls_label.position = Vector2(34.0, 28.0)
	controls_label.size = Vector2(520.0, 300.0)
	_controls_panel.add_child(controls_label)

	# Close hint at bottom of controls panel.
	var close_hint: Label = Label.new()
	close_hint.text = "H or ESC — close"
	close_hint.add_theme_font_size_override("font_size", 14)
	close_hint.add_theme_color_override("font_color", Color(0.44, 0.40, 0.36, 0.75))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.size = Vector2(574.0, 26.0)
	close_hint.position = Vector2(3.0, 334.0)
	_controls_panel.add_child(close_hint)
