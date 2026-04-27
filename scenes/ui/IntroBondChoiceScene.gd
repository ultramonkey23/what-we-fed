extends Node2D

const ROUTE_SCENE_PATH: String = "res://scenes/ui/RouteScene.tscn"
const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const COMBAT_DATA = preload("res://data/CombatContent.gd")

const STARTER_SPECIES: Array[String] = ["ashclaw", "gruvek", "veilskin"]

const LIST_X: float = 120.0
const LIST_W: float = 1040.0
const CARD_HEIGHT: float = 132.0
const CARD_GAP: float = 10.0
const LIST_START_Y: float = 168.0

var _creature_cards: Array[Panel] = []
var _card_accents: Array[ColorRect] = []
var _selected_index: int = -1
var _can_input: bool = false
var _feedback_label: Label = null
var _ui_layer: CanvasLayer = null


func _ready() -> void:
	if not GameState.is_intro_bond_choice_pending():
		get_tree().change_scene_to_file(ROUTE_SCENE_PATH)
		return
	_build_ui()
	await get_tree().create_timer(0.12).timeout
	_can_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not _can_input:
		return
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var index: int = -1
	match key_event.keycode:
		KEY_1:
			index = 0
		KEY_2:
			index = 1
		KEY_3:
			index = 2

	if index >= 0 and index < STARTER_SPECIES.size():
		_selected_index = index
		_refresh_card_highlights()
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		_try_confirm_bond()
		return


func _try_confirm_bond() -> void:
	if _selected_index < 0 or _selected_index >= STARTER_SPECIES.size():
		_play_feedback(PRESENTATION_TEXT.INTRO_BOND_NEED_SELECTION)
		return
	var species_id: String = STARTER_SPECIES[_selected_index]
	var template: Dictionary = COMBAT_DATA.get_creature(species_id)
	if template.is_empty():
		_play_feedback("UNKNOWN SPECIES")
		return
	var bonded: Dictionary = GameState.add_bonded_creature(template.duplicate(true))
	GameState.mark_intro_bond_choice_completed(species_id)
	EventBus.emit_signal("creature_bonded", bonded)
	get_tree().change_scene_to_file(ROUTE_SCENE_PATH)


func _play_feedback(text: String) -> void:
	if not is_instance_valid(_feedback_label):
		return
	_feedback_label.text = text
	_feedback_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.1)
	tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.35)


func _build_ui() -> void:
	UI_STYLE.attach_shell_backdrop(self)
	if is_instance_valid(_ui_layer):
		_ui_layer.queue_free()
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	var header: Label = Label.new()
	header.text = PRESENTATION_TEXT.INTRO_BOND_HEADER
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(1280.0, 52.0)
	header.position = Vector2(0.0, 36.0)
	UI_STYLE.apply_label(header, "mm_title")
	header.add_theme_font_size_override("font_size", 40)
	_ui_layer.add_child(header)

	var sub: Label = Label.new()
	sub.text = PRESENTATION_TEXT.INTRO_BOND_SUBTITLE
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1120.0, 72.0)
	sub.position = Vector2(80.0, 92.0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(sub, "mm_subtitle")
	_ui_layer.add_child(sub)

	_creature_cards.clear()
	_card_accents.clear()
	for i in range(STARTER_SPECIES.size()):
		var card_y: float = LIST_START_Y + i * (CARD_HEIGHT + CARD_GAP)
		_build_creature_card(_ui_layer, i, LIST_X, card_y, LIST_W, CARD_HEIGHT)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.size = Vector2(1280.0, 36.0)
	_feedback_label.position = Vector2(0.0, 560.0)
	_feedback_label.modulate.a = 0.0
	UI_STYLE.apply_label(_feedback_label, "mm_choice_consume")
	_ui_layer.add_child(_feedback_label)

	var hint: Label = Label.new()
	hint.text = PRESENTATION_TEXT.INTRO_BOND_HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1280.0, 28.0)
	hint.position = Vector2(0.0, 648.0)
	UI_STYLE.apply_label(hint, "mm_hint")
	_ui_layer.add_child(hint)

	_refresh_card_highlights()


func _build_creature_card(canvas: CanvasLayer, index: int, x: float, y: float, w: float, h: float) -> void:
	var species_id: String = STARTER_SPECIES[index]
	var creature: Dictionary = COMBAT_DATA.get_creature(species_id)

	var card: Panel = Panel.new()
	card.size = Vector2(w, h)
	card.position = Vector2(x, y)
	UI_STYLE.apply_shell_style(card, "lair_card")
	canvas.add_child(card)

	var accent: ColorRect = ColorRect.new()
	accent.color = Color(0.0, 0.0, 0.0, 0.0)
	accent.size = Vector2(4.0, h - 4.0)
	accent.position = Vector2(2.0, 2.0)
	card.add_child(accent)

	var num_label: Label = Label.new()
	num_label.text = str(index + 1)
	num_label.position = Vector2(14.0, (h - 26.0) * 0.5)
	num_label.size = Vector2(26.0, 26.0)
	UI_STYLE.apply_label(num_label, "mm_caption")
	card.add_child(num_label)

	var display: String = String(creature.get("display_name", species_id))
	var name_label: Label = Label.new()
	name_label.text = display
	name_label.position = Vector2(50.0, 10.0)
	name_label.size = Vector2(w - 200.0, 30.0)
	UI_STYLE.apply_label(name_label, "mm_stat_primary")
	card.add_child(name_label)

	var id_label: Label = Label.new()
	id_label.text = species_id
	id_label.position = Vector2(50.0, 40.0)
	id_label.size = Vector2(w - 90.0, 22.0)
	UI_STYLE.apply_label(id_label, "mm_dim")
	card.add_child(id_label)

	var desc: String = String(creature.get("description", ""))
	if not desc.is_empty():
		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.position = Vector2(50.0, 64.0)
		desc_label.size = Vector2(w - 70.0, 56.0)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(desc_label, "mm_body")
		card.add_child(desc_label)

	_creature_cards.append(card)
	_card_accents.append(accent)


func _refresh_card_highlights() -> void:
	for i in range(_creature_cards.size()):
		if not is_instance_valid(_creature_cards[i]):
			continue
		var is_selected: bool = (i == _selected_index)
		if is_selected:
			UI_STYLE.apply_shell_style(_creature_cards[i], "mm_apex")
		else:
			UI_STYLE.apply_shell_style(_creature_cards[i], "lair_card")
		if i < _card_accents.size() and is_instance_valid(_card_accents[i]):
			_card_accents[i].color = UI_STYLE.get_manga_color("alert_gold") if is_selected else Color(0.0, 0.0, 0.0, 0.0)
			_card_accents[i].modulate.a = 1.0
