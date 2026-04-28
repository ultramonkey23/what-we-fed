extends Node2D

const LAIR_SCENE_PATH: String = "res://scenes/ui/LairScene.tscn"
const INTRO_BOND_SCENE_PATH: String = "res://scenes/ui/IntroBondChoiceScene.tscn"
const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const TITLE_SIGIL_PATH: String = "res://assets/ui/shell/title_sigil.png"

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

	if key_event.keycode == KEY_N and key_event.ctrl_pressed and key_event.shift_pressed:
		GameState.reset_profile_progression_state()
		EventBus.emit_signal("proc_feedback_requested", "NEW PROFILE — PROGRESSION CLEARED", Color(0.72, 0.88, 1.0, 1.0))
		get_viewport().set_input_as_handled()
		return

	if not _can_start:
		return
	if _controls_visible:
		return

	if GameState.is_intro_bond_choice_pending():
		get_tree().change_scene_to_file(INTRO_BOND_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(LAIR_SCENE_PATH)


func _toggle_controls_panel() -> void:
	_set_controls_panel_visible(not _controls_visible)


func _set_controls_panel_visible(visible_state: bool) -> void:
	_controls_visible = visible_state
	if _controls_panel != null:
		_controls_panel.visible = visible_state


func _build_ui() -> void:
	UI_STYLE.attach_shell_backdrop(self)

	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var title_rail := Panel.new()
	title_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_rail.position = Vector2(200.0, 198.0)
	title_rail.size = Vector2(880.0, 188.0)
	UI_STYLE.apply_shell_style(title_rail, "mm_command")
	canvas.add_child(title_rail)

	var title_label: Label = Label.new()
	title_label.text = "WHAT WE FED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size = Vector2(1280.0, 100.0)
	title_label.position = Vector2(0.0, 224.0)
	UI_STYLE.apply_label(title_label, "mm_title")
	canvas.add_child(title_label)

	var sigil_tex: Texture2D = null
	if ResourceLoader.exists(TITLE_SIGIL_PATH):
		sigil_tex = load(TITLE_SIGIL_PATH) as Texture2D
	if sigil_tex != null:
		var sigil := TextureRect.new()
		sigil.texture = sigil_tex
		sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sigil.position = Vector2(486.0, 78.0)
		sigil.size = Vector2(308.0, 308.0)
		sigil.modulate = Color(1.0, 0.95, 0.92, 0.34)
		sigil.stretch_mode = TextureRect.STRETCH_SCALE
		canvas.add_child(sigil)
		canvas.move_child(sigil, 0)

	var sub_label: Label = Label.new()
	sub_label.text = PRESENTATION_TEXT.TITLE_SUBTITLE
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.size = Vector2(1280.0, 40.0)
	sub_label.position = Vector2(0.0, 328.0)
	UI_STYLE.apply_label(sub_label, "mm_subtitle")
	canvas.add_child(sub_label)

	var prompt_label: Label = Label.new()
	prompt_label.text = PRESENTATION_TEXT.TITLE_PROMPT
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size = Vector2(1280.0, 40.0)
	prompt_label.position = Vector2(0.0, 434.0)
	UI_STYLE.apply_label(prompt_label, "mm_stat_primary")
	canvas.add_child(prompt_label)

	var hint_label: Label = Label.new()
	hint_label.text = PRESENTATION_TEXT.TITLE_HINT
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size = Vector2(1280.0, 30.0)
	hint_label.position = Vector2(0.0, 660.0)
	UI_STYLE.apply_label(hint_label, "mm_hint")
	canvas.add_child(hint_label)

	_controls_panel = ColorRect.new()
	_controls_panel.color = UI_STYLE.get_manga_color("deep_violet")
	_controls_panel.color.a = 0.97
	_controls_panel.size = Vector2(580.0, 370.0)
	_controls_panel.position = Vector2(350.0, 155.0)
	_controls_panel.visible = false
	canvas.add_child(_controls_panel)

	var border: ColorRect = ColorRect.new()
	border.color = UI_STYLE.get_manga_color("blood_ember")
	border.size = Vector2(580.0, 370.0)
	border.position = Vector2.ZERO
	_controls_panel.add_child(border)

	var inner_bg: ColorRect = ColorRect.new()
	inner_bg.color = UI_STYLE.get_manga_color("ink_black")
	inner_bg.size = Vector2(574.0, 364.0)
	inner_bg.position = Vector2(3.0, 3.0)
	_controls_panel.add_child(inner_bg)

	var controls_text: String = (
		PRESENTATION_TEXT.TITLE_HELP_HEADER + "\n\n"
		+ "WASD / ARROWS          Free Movement & Aim\n"
		+ "SPACE / LEFT CLICK     Extract / Attack Sector\n"
		+ "Z / RIGHT CLICK        Stitch / Parry Sector\n"
		+ "SHIFT                  Evasion / Dodge\n"
		+ "C / R                  Ultimate Collapse\n"
		+ "X / F                  Creature Support\n"
		+ "\n"
		+ "- Management -\n"
		+ "B / E                  Bond or Eat (Claim Offer)\n"
		+ "N                      Pass (Reject Offer)\n"
		+ "T                      Recall to Lair"
	)

	var controls_label: Label = Label.new()
	controls_label.text = controls_text
	controls_label.position = Vector2(34.0, 28.0)
	controls_label.size = Vector2(520.0, 300.0)
	UI_STYLE.apply_label(controls_label, "mm_body")
	_controls_panel.add_child(controls_label)

	var close_hint: Label = Label.new()
	close_hint.text = "H or ESC - close"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.size = Vector2(574.0, 26.0)
	close_hint.position = Vector2(3.0, 334.0)
	UI_STYLE.apply_label(close_hint, "mm_hint")
	_controls_panel.add_child(close_hint)
