extends Node2D

const ROUTE_CONTENT = preload("res://data/RouteContent.gd")
const COMBAT_SCENE_PATH: String = "res://scenes/combat/CombatScene.tscn"
const LAIR_SCENE_PATH: String = "res://scenes/ui/LairScene.tscn"
const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")

const CARD_WIDTH: float = 348.0
const CARD_HEIGHT: float = 336.0
const CARD_GAP: float = 24.0
const CARD_ROW_Y: float = 128.0

var _region_cards: Array[ColorRect] = []
var _card_accents: Array[ColorRect] = []
var _selected_index: int = 0
var _can_input: bool = false


func _ready() -> void:
	_sync_selection_from_gamestate()
	_build_ui()
	await get_tree().create_timer(0.12).timeout
	_can_input = true


func _sync_selection_from_gamestate() -> void:
	var current_id: String = String(GameState.active_region.get("id", ""))
	if current_id.is_empty():
		_selected_index = 0
		return
	var regions: Array = ROUTE_CONTENT.REGIONS
	for i in range(regions.size()):
		if String(regions[i].get("id", "")) == current_id:
			_selected_index = i
			return
	_selected_index = 0


func _unhandled_input(event: InputEvent) -> void:
	if not _can_input:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var region_count: int = ROUTE_CONTENT.REGIONS.size()
	var index: int = -1
	match key_event.keycode:
		KEY_1: index = 0
		KEY_2: index = 1
		KEY_3: index = 2

	if index >= 0 and index < region_count:
		_selected_index = index
		_refresh_card_highlights()
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		GameState.set_active_region(ROUTE_CONTENT.REGIONS[_selected_index])
		get_tree().change_scene_to_file(COMBAT_SCENE_PATH)
		return

	if key_event.keycode == KEY_ESCAPE:
		GameState.run_in_progress = false
		get_tree().change_scene_to_file(LAIR_SCENE_PATH)
		return


func _build_ui() -> void:
	UI_STYLE.attach_shell_backdrop(self)

	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var header: Label = Label.new()
	header.text = PRESENTATION_TEXT.ROUTE_HEADER
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(1280.0, 52.0)
	header.position = Vector2(0.0, 38.0)
	UI_STYLE.apply_label(header, "screen_title")
	canvas.add_child(header)

	var sub: Label = Label.new()
	sub.text = PRESENTATION_TEXT.ROUTE_SUBTITLE
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1280.0, 26.0)
	sub.position = Vector2(0.0, 90.0)
	UI_STYLE.apply_label(sub, "screen_subtitle")
	canvas.add_child(sub)

	_build_region_cards(canvas)
	_build_bottom_bar(canvas)
	_refresh_card_highlights()


func _build_region_cards(canvas: CanvasLayer) -> void:
	_region_cards.clear()
	_card_accents.clear()

	var regions: Array = ROUTE_CONTENT.REGIONS
	var total_width: float = CARD_WIDTH * regions.size() + CARD_GAP * (regions.size() - 1)
	var start_x: float = (1280.0 - total_width) * 0.5

	for i in range(regions.size()):
		var card_x: float = start_x + i * (CARD_WIDTH + CARD_GAP)
		_build_region_card(canvas, regions[i], i, card_x, CARD_ROW_Y)


func _build_region_card(canvas: CanvasLayer, region: Dictionary, index: int, x: float, y: float) -> void:
	var card: ColorRect = ColorRect.new()
	card.color = Color(0.12, 0.07, 0.07, 1.0)
	card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card.position = Vector2(x, y)
	canvas.add_child(card)

	var accent: ColorRect = ColorRect.new()
	accent.color = Color(0.0, 0.0, 0.0, 0.0)
	accent.size = Vector2(CARD_WIDTH, 4.0)
	accent.position = Vector2.ZERO
	card.add_child(accent)

	var num_label: Label = Label.new()
	num_label.text = str(index + 1)
	num_label.position = Vector2(14.0, 14.0)
	num_label.size = Vector2(24.0, 24.0)
	UI_STYLE.apply_label(num_label, "card_index")
	card.add_child(num_label)

	var tag_label: Label = Label.new()
	tag_label.text = String(region.get("tag", ""))
	tag_label.position = Vector2(14.0, 46.0)
	tag_label.size = Vector2(CARD_WIDTH - 28.0, 20.0)
	UI_STYLE.apply_label(tag_label, "card_tag")
	card.add_child(tag_label)

	var name_label: Label = Label.new()
	name_label.text = String(region.get("name", ""))
	name_label.position = Vector2(14.0, 68.0)
	name_label.size = Vector2(CARD_WIDTH - 28.0, 36.0)
	UI_STYLE.apply_label(name_label, "card_title")
	card.add_child(name_label)

	var sep: ColorRect = ColorRect.new()
	sep.color = Color(0.28, 0.18, 0.14, 0.50)
	sep.size = Vector2(CARD_WIDTH - 28.0, 1.0)
	sep.position = Vector2(14.0, 112.0)
	card.add_child(sep)

	var flavor_scroll := ScrollContainer.new()
	flavor_scroll.position = Vector2(14.0, 126.0)
	flavor_scroll.size = Vector2(CARD_WIDTH - 28.0, 110.0)
	flavor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	flavor_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	flavor_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_child(flavor_scroll)

	var flavor_label: Label = Label.new()
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_label.text = String(region.get("flavor", ""))
	flavor_label.position = Vector2.ZERO
	flavor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_STYLE.apply_label(flavor_label, "card_body")
	flavor_scroll.add_child(flavor_label)
	_reflow_route_scroll(flavor_scroll, flavor_label)

	var mod_bg: ColorRect = ColorRect.new()
	mod_bg.color = Color(0.16, 0.10, 0.06, 1.0)
	mod_bg.size = Vector2(CARD_WIDTH - 28.0, 72.0)
	mod_bg.position = Vector2(14.0, CARD_HEIGHT - 88.0)
	card.add_child(mod_bg)

	var mod_scroll := ScrollContainer.new()
	mod_scroll.position = Vector2(24.0, CARD_HEIGHT - 82.0)
	mod_scroll.size = Vector2(CARD_WIDTH - 40.0, 64.0)
	mod_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mod_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	mod_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_child(mod_scroll)

	var mod_label: Label = Label.new()
	mod_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mod_label.text = String(region.get("modifier_label", ""))
	mod_label.position = Vector2.ZERO
	mod_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_STYLE.apply_label(mod_label, "body")
	mod_scroll.add_child(mod_label)
	_reflow_route_scroll(mod_scroll, mod_label)

	_region_cards.append(card)
	_card_accents.append(accent)


func _build_bottom_bar(canvas: CanvasLayer) -> void:
	var hint: Label = Label.new()
	hint.text = "1 / 2 / 3 - select  |  SPACE / ENTER - enter run  |  ESC - lair"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1280.0, 28.0)
	hint.position = Vector2(0.0, 660.0)
	UI_STYLE.apply_label(hint, "hint")
	canvas.add_child(hint)


func _reflow_route_scroll(scroll: ScrollContainer, label: Label) -> void:
	if scroll == null or label == null:
		return
	var inner_w: float = maxf(1.0, scroll.size.x - 10.0)
	label.custom_minimum_size.x = inner_w
	var content_h: float = label.get_content_height()
	label.custom_minimum_size.y = maxf(scroll.size.y, content_h)


func _refresh_card_highlights() -> void:
	for i in range(_region_cards.size()):
		if not is_instance_valid(_region_cards[i]):
			continue
		var is_selected: bool = (i == _selected_index)
		_region_cards[i].color = Color(0.20, 0.13, 0.08, 1.0) if is_selected else Color(0.12, 0.07, 0.07, 1.0)
		if i < _card_accents.size() and is_instance_valid(_card_accents[i]):
			_card_accents[i].color = Color(0.86, 0.60, 0.24, 1.0) if is_selected else Color(0.0, 0.0, 0.0, 0.0)
