extends Node2D

const ROUTE_SCENE_PATH: String = "res://scenes/ui/RouteScene.tscn"
const TITLE_SCENE_PATH: String = "res://scenes/ui/TitleScreen.tscn"
const MAX_LAIR_DISPLAY: int = 5

var _creature_cards: Array[ColorRect] = []
var _card_accents: Array[ColorRect] = []
var _selected_index: int = -1
var _can_input: bool = false


func _ready() -> void:
	_sync_selection_index()
	_build_ui()
	# Brief delay so a key held during scene transition doesn't immediately fire.
	await get_tree().create_timer(0.12).timeout
	_can_input = true


func _sync_selection_index() -> void:
	# Restore the visual selection to match GameState.active_lair_creature_id.
	_selected_index = -1
	if GameState.active_lair_creature_id.is_empty():
		return
	var lair: Array = GameState.lair_roster
	for i in range(min(lair.size(), MAX_LAIR_DISPLAY)):
		if String(lair[i].get("species_id", "")) == GameState.active_lair_creature_id:
			_selected_index = i
			return


func _unhandled_input(event: InputEvent) -> void:
	if not _can_input:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var lair: Array = GameState.lair_roster
	var display_count: int = min(lair.size(), MAX_LAIR_DISPLAY)

	# Number keys 1–5: select or toggle-off creature.
	var index: int = -1
	match key_event.keycode:
		KEY_1: index = 0
		KEY_2: index = 1
		KEY_3: index = 2
		KEY_4: index = 3
		KEY_5: index = 4

	if index >= 0 and index < display_count:
		if _selected_index == index:
			# Same key again — deselect (run will start with no pre-bonded creature).
			_selected_index = -1
			GameState.set_active_lair_creature("")
		else:
			_selected_index = index
			GameState.set_active_lair_creature(String(lair[index].get("species_id", "")))
		_refresh_card_highlights()
		get_viewport().set_input_as_handled()
		return

	# SPACE or ENTER: enter the run.
	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		get_tree().change_scene_to_file(ROUTE_SCENE_PATH)
		return

	# ESC: back to title.
	if key_event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)
		return


func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.06, 0.03, 0.04, 1.0)
	bg.size = Vector2(1280.0, 720.0)
	bg.position = Vector2.ZERO
	add_child(bg)

	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var header: Label = Label.new()
	header.text = "THE LAIR"
	header.add_theme_font_size_override("font_size", 42)
	header.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74, 1.0))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(1280.0, 58.0)
	header.position = Vector2(0.0, 42.0)
	canvas.add_child(header)

	var sub: Label = Label.new()
	sub.text = "Choose your starting support."
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.52, 0.44, 0.40, 1.0))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1280.0, 28.0)
	sub.position = Vector2(0.0, 98.0)
	canvas.add_child(sub)

	var lair: Array = GameState.lair_roster
	if lair.is_empty():
		_build_empty_state(canvas)
	else:
		_build_creature_list(canvas, lair)

	_build_bottom_bar(canvas, lair)


func _build_empty_state(canvas: CanvasLayer) -> void:
	var empty_label: Label = Label.new()
	empty_label.text = "No bonds yet.\nEnter the hollow and bring something back."
	empty_label.add_theme_font_size_override("font_size", 20)
	empty_label.add_theme_color_override("font_color", Color(0.48, 0.42, 0.38, 0.85))
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.size = Vector2(1280.0, 80.0)
	empty_label.position = Vector2(0.0, 305.0)
	canvas.add_child(empty_label)


func _build_creature_list(canvas: CanvasLayer, lair: Array) -> void:
	_creature_cards.clear()
	_card_accents.clear()

	var card_width: float = 820.0
	var card_height: float = 94.0
	var card_gap: float = 10.0
	var card_x: float = (1280.0 - card_width) * 0.5
	var list_start_y: float = 148.0

	var count: int = min(lair.size(), MAX_LAIR_DISPLAY)
	for i in range(count):
		var card_y: float = list_start_y + i * (card_height + card_gap)
		_build_creature_card(canvas, lair[i], i, card_x, card_y, card_width, card_height)

	_refresh_card_highlights()


func _build_creature_card(canvas: CanvasLayer, creature: Dictionary, index: int, x: float, y: float, w: float, h: float) -> void:
	var card: ColorRect = ColorRect.new()
	card.color = Color(0.12, 0.07, 0.07, 1.0)
	card.size = Vector2(w, h)
	card.position = Vector2(x, y)
	canvas.add_child(card)

	# Left-edge accent strip — highlighted when selected.
	var accent: ColorRect = ColorRect.new()
	accent.color = Color(0.0, 0.0, 0.0, 0.0)
	accent.size = Vector2(4.0, h)
	accent.position = Vector2.ZERO
	card.add_child(accent)

	# Number key indicator.
	var num_label: Label = Label.new()
	num_label.text = str(index + 1)
	num_label.add_theme_font_size_override("font_size", 20)
	num_label.add_theme_color_override("font_color", Color(0.46, 0.40, 0.34, 0.65))
	num_label.position = Vector2(14.0, (h - 26.0) * 0.5)
	num_label.size = Vector2(22.0, 26.0)
	card.add_child(num_label)

	# Display name.
	var name_label: Label = Label.new()
	name_label.text = String(creature.get("display_name", "Unknown"))
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_color_override("font_color", Color(0.90, 0.84, 0.72, 1.0))
	name_label.position = Vector2(50.0, 13.0)
	name_label.size = Vector2(240.0, 28.0)
	card.add_child(name_label)

	# Bond level.
	var bond_level: int = int(creature.get("bond_level", 1))
	var bl_label: Label = Label.new()
	bl_label.text = "BOND %d" % bond_level
	bl_label.add_theme_font_size_override("font_size", 13)
	bl_label.add_theme_color_override("font_color", Color(0.58, 0.72, 0.48, 1.0))
	bl_label.position = Vector2(50.0, 48.0)
	bl_label.size = Vector2(100.0, 20.0)
	card.add_child(bl_label)

	# Support feedback label (e.g. "REND", "GORGE", "PHASE").
	var support_role: Dictionary = creature.get("support_role", {})
	var feedback_text: String = String(support_role.get("feedback_text", ""))
	if not feedback_text.is_empty():
		var role_label: Label = Label.new()
		role_label.text = feedback_text
		role_label.add_theme_font_size_override("font_size", 13)
		role_label.add_theme_color_override("font_color", Color(0.80, 0.58, 0.30, 0.90))
		role_label.position = Vector2(162.0, 50.0)
		role_label.size = Vector2(160.0, 20.0)
		card.add_child(role_label)

	# Creature description.
	var desc: String = String(creature.get("description", ""))
	if not desc.is_empty():
		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.49, 0.44, 0.80))
		desc_label.position = Vector2(348.0, 14.0)
		desc_label.size = Vector2(456.0, 68.0)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc_label)

	_creature_cards.append(card)
	_card_accents.append(accent)


func _build_bottom_bar(canvas: CanvasLayer, lair: Array) -> void:
	# Clarification note about what the selection actually does.
	var note: Label = Label.new()
	note.text = "Selected creature starts bonded at its current bond level.  A creature bonded mid-run with a higher bond level will become the active support instead."
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.40, 0.36, 0.32, 0.72))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.size = Vector2(1060.0, 30.0)
	note.position = Vector2(110.0, 620.0)
	canvas.add_child(note)

	var count: int = min(lair.size(), MAX_LAIR_DISPLAY)
	var hint_text: String
	if count == 0:
		hint_text = "SPACE / ENTER — enter run  |  ESC — title"
	else:
		hint_text = "1–%d — select / deselect  |  SPACE / ENTER — enter run  |  ESC — title" % count

	var hint: Label = Label.new()
	hint.text = hint_text
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.44, 0.40, 0.36, 0.75))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1280.0, 28.0)
	hint.position = Vector2(0.0, 660.0)
	canvas.add_child(hint)


func _refresh_card_highlights() -> void:
	for i in range(_creature_cards.size()):
		if not is_instance_valid(_creature_cards[i]):
			continue
		var is_selected: bool = (i == _selected_index)
		_creature_cards[i].color = Color(0.20, 0.13, 0.08, 1.0) if is_selected else Color(0.12, 0.07, 0.07, 1.0)
		if i < _card_accents.size() and is_instance_valid(_card_accents[i]):
			_card_accents[i].color = Color(0.86, 0.60, 0.24, 1.0) if is_selected else Color(0.0, 0.0, 0.0, 0.0)
