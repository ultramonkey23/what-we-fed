extends Node2D

const LAIR_SCENE_PATH: String = "res://scenes/ui/LairScene.tscn"
const INTRO_BOND_SCENE_PATH: String = "res://scenes/ui/IntroBondChoiceScene.tscn"
const UI_STYLE = preload("res://systems/UIStyle.gd")
const HUD_PANEL_ART = preload("res://systems/HUDPanelArt.gd")
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

	_build_title_lair_silhouette(canvas)

	var title_rail := Panel.new()
	title_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_rail.position = Vector2(200.0, 198.0)
	title_rail.size = Vector2(880.0, 188.0)
	UI_STYLE.apply_shell_style(title_rail, "mm_command")
	_apply_title_vein_panel(title_rail, 0.28, UI_STYLE.get_manga_color("bond_teal"))
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
	sub_label.text = PRESENTATION_TEXT.title_subtitle()
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.size = Vector2(1120.0, 48.0)
	sub_label.position = Vector2(80.0, 318.0)
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(sub_label, "mm_subtitle")
	sub_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(sub_label)

	var prompt_label: Label = Label.new()
	prompt_label.text = PRESENTATION_TEXT.title_prompt()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size = Vector2(1280.0, 58.0)
	prompt_label.position = Vector2(0.0, 416.0)
	UI_STYLE.apply_label(prompt_label, "mm_stat_primary")
	prompt_label.add_theme_font_size_override("font_size", 30)
	canvas.add_child(prompt_label)

	var prompt_slash := ColorRect.new()
	prompt_slash.color = UI_STYLE.get_manga_color("blood_ember")
	prompt_slash.color.a = 0.72
	prompt_slash.position = Vector2(490.0, 408.0)
	prompt_slash.size = Vector2(284.0, 2.0)
	canvas.add_child(prompt_slash)

	var hint_label: Label = Label.new()
	hint_label.text = PRESENTATION_TEXT.title_hint()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size = Vector2(1280.0, 30.0)
	hint_label.position = Vector2(0.0, 660.0)
	UI_STYLE.apply_label(hint_label, "mm_hint")
	hint_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(hint_label)

	_controls_panel = ColorRect.new()
	_controls_panel.size = Vector2(580.0, 370.0)
	_controls_panel.position = Vector2(350.0, 155.0)
	_controls_panel.visible = false
	UI_STYLE.apply_shell_style(_controls_panel, "mm_alert")
	HUD_PANEL_ART.apply_panel_art(_controls_panel, "", Rect2(), "ControlVeinArt", "ControlVeinBacking")
	HUD_PANEL_ART.set_vein_color(_controls_panel, UI_STYLE.get_manga_color("blood_ember"))
	HUD_PANEL_ART.set_vein_pulse(_controls_panel, 0.22)
	canvas.add_child(_controls_panel)

	var controls_text: String = (		PRESENTATION_TEXT.TITLE_HELP_HEADER + "\n\n"
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


func _build_title_lair_silhouette(canvas: CanvasLayer) -> void:
	var root := Node2D.new()
	root.name = "TitleLairSilhouette"
	canvas.add_child(root)

	var chamber_color := UI_STYLE.get_manga_color("ink_black")
	chamber_color.a = 0.58
	var rim_blood := UI_STYLE.get_manga_color("blood_ember")
	rim_blood.a = 0.18
	var rim_bond := UI_STYLE.get_manga_color("bond_teal")
	rim_bond.a = 0.16

	var throat := Polygon2D.new()
	throat.polygon = PackedVector2Array([
		Vector2(140.0, 610.0),
		Vector2(252.0, 470.0),
		Vector2(386.0, 432.0),
		Vector2(584.0, 390.0),
		Vector2(728.0, 408.0),
		Vector2(1026.0, 348.0),
		Vector2(1168.0, 454.0),
		Vector2(1120.0, 648.0),
		Vector2(850.0, 612.0),
		Vector2(638.0, 670.0),
		Vector2(404.0, 604.0)
	])
	throat.color = chamber_color
	root.add_child(throat)

	_add_title_root_line(root, PackedVector2Array([
		Vector2(82.0, 584.0), Vector2(252.0, 512.0), Vector2(446.0, 468.0), Vector2(644.0, 454.0),
		Vector2(842.0, 420.0), Vector2(1128.0, 462.0)
	]), rim_blood, 5.0)
	_add_title_root_line(root, PackedVector2Array([
		Vector2(230.0, 168.0), Vector2(404.0, 238.0), Vector2(580.0, 292.0), Vector2(826.0, 284.0),
		Vector2(1056.0, 208.0)
	]), rim_bond, 3.0)
	_add_title_root_line(root, PackedVector2Array([
		Vector2(626.0, 92.0), Vector2(646.0, 218.0), Vector2(638.0, 384.0), Vector2(638.0, 656.0)
	]), Color(UI_STYLE.get_manga_color("alert_gold"), 0.12), 2.0)

	for i in range(5):
		var tooth := Polygon2D.new()
		var x := 210.0 + float(i) * 212.0
		tooth.polygon = PackedVector2Array([
			Vector2(x, 0.0),
			Vector2(x + 52.0, 0.0),
			Vector2(x + 16.0, 102.0)
		])
		tooth.color = Color(UI_STYLE.get_manga_color("paper"), 0.045)
		root.add_child(tooth)


func _add_title_root_line(parent: Node, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(line)


func _apply_title_vein_panel(panel: Control, pulse: float, color: Color) -> void:
	if panel == null:
		return
	var ink := UI_STYLE.get_manga_color("ink_black")
	HUD_PANEL_ART.apply_panel_art(panel, "", Rect2(), "TitleVeinArt", "TitleVeinBacking", Color(ink.r, ink.g, ink.b, 0.42))
	HUD_PANEL_ART.set_vein_color(panel, color, "TitleVeinBacking")
	HUD_PANEL_ART.set_vein_pulse(panel, pulse, "TitleVeinBacking")
