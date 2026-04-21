extends Node2D

const ROUTE_CONTENT = preload("res://data/RouteContent.gd")
const COMBAT_SCENE_PATH: String = "res://scenes/combat/CombatScene.tscn"
const LAIR_SCENE_PATH: String = "res://scenes/ui/LairScene.tscn"
const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")

const CARDS_PER_PAGE: int = 3
const VIEWPORT_W: float = 1280.0
const CARD_WIDTH: float = 348.0
const CARD_HEIGHT: float = 336.0
const CARD_GAP: float = 24.0
const CARD_ROW_Y: float = 128.0

var _slot_cards: Array[ColorRect] = []
var _slot_accents: Array[ColorRect] = []
var _slot_controls: Array[Dictionary] = []
var _footer_hint: Label

var _page_start: int = 0
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
		_align_page_to_selection()
		return
	var regions: Array = ROUTE_CONTENT.REGIONS
	for i in range(regions.size()):
		if String(regions[i].get("id", "")) == current_id:
			_selected_index = i
			_align_page_to_selection()
			return
	_selected_index = 0
	_align_page_to_selection()


func _align_page_to_selection() -> void:
	var n: int = ROUTE_CONTENT.REGIONS.size()
	if n <= 0:
		_page_start = 0
		return
	_selected_index = clampi(_selected_index, 0, n - 1)
	_page_start = int(_selected_index / CARDS_PER_PAGE) * CARDS_PER_PAGE
	var max_page_start: int = int((n - 1) / CARDS_PER_PAGE) * CARDS_PER_PAGE
	_page_start = clampi(_page_start, 0, max_page_start)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_input:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var regions: Array = ROUTE_CONTENT.REGIONS
	var region_count: int = regions.size()
	if region_count <= 0:
		return

	var slot_index: int = -1
	match key_event.keycode:
		KEY_1:
			slot_index = 0
		KEY_2:
			slot_index = 1
		KEY_3:
			slot_index = 2

	if slot_index >= 0:
		var global_i: int = _page_start + slot_index
		if global_i < region_count:
			_selected_index = global_i
			_refresh_card_highlights()
			get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_BRACKETLEFT:
		if _page_start > 0:
			_page_start = maxi(0, _page_start - CARDS_PER_PAGE)
			_clamp_selection_to_visible_page(region_count)
			_apply_route_page()
			_refresh_card_highlights()
			_update_footer_hint()
			get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_BRACKETRIGHT:
		if _page_start + CARDS_PER_PAGE < region_count:
			_page_start += CARDS_PER_PAGE
			_clamp_selection_to_visible_page(region_count)
			_apply_route_page()
			_refresh_card_highlights()
			_update_footer_hint()
			get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		GameState.set_active_region(regions[_selected_index])
		get_tree().change_scene_to_file(COMBAT_SCENE_PATH)
		return

	if key_event.keycode == KEY_ESCAPE:
		GameState.run_in_progress = false
		get_tree().change_scene_to_file(LAIR_SCENE_PATH)
		return


func _clamp_selection_to_visible_page(region_count: int) -> void:
	var last_on_page: int = mini(_page_start + CARDS_PER_PAGE - 1, region_count - 1)
	if _selected_index < _page_start:
		_selected_index = _page_start
	elif _selected_index > last_on_page:
		_selected_index = last_on_page


func _build_ui() -> void:
	UI_STYLE.attach_shell_backdrop(self)

	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var header: Label = Label.new()
	header.text = PRESENTATION_TEXT.ROUTE_HEADER
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(VIEWPORT_W, 52.0)
	header.position = Vector2(0.0, 38.0)
	UI_STYLE.apply_label(header, "screen_title")
	canvas.add_child(header)

	var sub: Label = Label.new()
	sub.text = PRESENTATION_TEXT.ROUTE_SUBTITLE
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(VIEWPORT_W, 26.0)
	sub.position = Vector2(0.0, 90.0)
	UI_STYLE.apply_label(sub, "screen_subtitle")
	canvas.add_child(sub)

	_build_region_slots(canvas)
	_build_bottom_bar(canvas)
	_apply_route_page()
	_update_footer_hint()
	_refresh_card_highlights()


func _build_region_slots(canvas: CanvasLayer) -> void:
	_slot_cards.clear()
	_slot_accents.clear()
	_slot_controls.clear()

	for slot in range(CARDS_PER_PAGE):
		var controls: Dictionary = _create_route_slot(canvas, slot)
		_slot_controls.append(controls)


func _create_route_slot(canvas: CanvasLayer, slot_index: int) -> Dictionary:
	var card: ColorRect = ColorRect.new()
	card.color = Color(0.12, 0.07, 0.07, 1.0)
	card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card.position = Vector2.ZERO
	card.visible = false
	canvas.add_child(card)
	_slot_cards.append(card)

	var accent: ColorRect = ColorRect.new()
	accent.color = Color(0.0, 0.0, 0.0, 0.0)
	accent.size = Vector2(CARD_WIDTH, 4.0)
	accent.position = Vector2.ZERO
	card.add_child(accent)
	_slot_accents.append(accent)

	var num_label: Label = Label.new()
	num_label.text = str(slot_index + 1)
	num_label.position = Vector2(14.0, 14.0)
	num_label.size = Vector2(24.0, 24.0)
	UI_STYLE.apply_label(num_label, "card_index")
	card.add_child(num_label)

	var tag_label: Label = Label.new()
	tag_label.position = Vector2(14.0, 46.0)
	tag_label.size = Vector2(CARD_WIDTH - 28.0, 20.0)
	UI_STYLE.apply_label(tag_label, "card_tag")
	card.add_child(tag_label)

	var name_label: Label = Label.new()
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
	flavor_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	flavor_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_child(flavor_scroll)

	var flavor_label: Label = Label.new()
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_label.position = Vector2.ZERO
	flavor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_STYLE.apply_label(flavor_label, "card_body")
	flavor_scroll.add_child(flavor_label)

	var mod_bg: ColorRect = ColorRect.new()
	mod_bg.color = Color(0.16, 0.10, 0.06, 1.0)
	mod_bg.size = Vector2(CARD_WIDTH - 28.0, 72.0)
	mod_bg.position = Vector2(14.0, CARD_HEIGHT - 88.0)
	card.add_child(mod_bg)

	var mod_scroll := ScrollContainer.new()
	mod_scroll.position = Vector2(24.0, CARD_HEIGHT - 82.0)
	mod_scroll.size = Vector2(CARD_WIDTH - 40.0, 64.0)
	mod_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mod_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	mod_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_child(mod_scroll)

	var mod_label: Label = Label.new()
	mod_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mod_label.position = Vector2.ZERO
	mod_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_STYLE.apply_label(mod_label, "body")
	mod_scroll.add_child(mod_label)

	return {
		"num_label": num_label,
		"tag_label": tag_label,
		"name_label": name_label,
		"flavor_scroll": flavor_scroll,
		"flavor_label": flavor_label,
		"mod_scroll": mod_scroll,
		"mod_label": mod_label,
	}


func _apply_route_page() -> void:
	var regions: Array = ROUTE_CONTENT.REGIONS
	var n: int = regions.size()
	if n <= 0:
		return

	var count_on_page: int = mini(CARDS_PER_PAGE, n - _page_start)
	var gap_count: int = maxi(0, count_on_page - 1)
	var total_width: float = CARD_WIDTH * float(count_on_page) + CARD_GAP * float(gap_count)
	var start_x: float = (VIEWPORT_W - total_width) * 0.5

	for slot in range(CARDS_PER_PAGE):
		var card: ColorRect = _slot_cards[slot]
		var controls: Dictionary = _slot_controls[slot]
		var global_i: int = _page_start + slot

		if slot >= count_on_page or global_i >= n:
			card.visible = false
			continue

		card.visible = true
		card.position = Vector2(start_x + float(slot) * (CARD_WIDTH + CARD_GAP), CARD_ROW_Y)

		var region: Dictionary = regions[global_i]
		controls["num_label"].text = str(slot + 1)
		controls["tag_label"].text = String(region.get("tag", ""))
		controls["name_label"].text = String(region.get("name", ""))
		controls["flavor_label"].text = String(region.get("flavor", ""))
		controls["mod_label"].text = String(region.get("modifier_label", ""))

		_reflow_route_scroll(controls["flavor_scroll"], controls["flavor_label"])
		_reflow_route_scroll(controls["mod_scroll"], controls["mod_label"])


func _build_bottom_bar(canvas: CanvasLayer) -> void:
	_footer_hint = Label.new()
	_footer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_hint.size = Vector2(VIEWPORT_W, 28.0)
	_footer_hint.position = Vector2(0.0, 660.0)
	UI_STYLE.apply_label(_footer_hint, "hint")
	canvas.add_child(_footer_hint)


func _update_footer_hint() -> void:
	if _footer_hint == null:
		return
	var n: int = ROUTE_CONTENT.REGIONS.size()
	var parts: PackedStringArray = PackedStringArray(["1 / 2 / 3 - select"])
	if n > CARDS_PER_PAGE:
		var page_count: int = (n + CARDS_PER_PAGE - 1) / CARDS_PER_PAGE
		var cur_page: int = _page_start / CARDS_PER_PAGE + 1
		parts.append("[ / ] - more regions (%d / %d)" % [cur_page, page_count])
	parts.append("SPACE / ENTER - enter run")
	parts.append("ESC - lair")
	_footer_hint.text = "  |  ".join(parts)


func _reflow_route_scroll(scroll: ScrollContainer, label: Label) -> void:
	if scroll == null or label == null:
		return
	var inner_w: float = maxf(1.0, scroll.size.x - 10.0)
	label.custom_minimum_size.x = inner_w
	var content_h: float = label.get_minimum_size().y
	label.custom_minimum_size.y = maxf(scroll.size.y, content_h)


func _refresh_card_highlights() -> void:
	var n: int = ROUTE_CONTENT.REGIONS.size()
	for slot in range(_slot_cards.size()):
		if not is_instance_valid(_slot_cards[slot]):
			continue
		if not _slot_cards[slot].visible:
			continue
		var global_i: int = _page_start + slot
		if global_i >= n:
			continue
		var is_selected: bool = (global_i == _selected_index)
		_slot_cards[slot].color = Color(0.20, 0.13, 0.08, 1.0) if is_selected else Color(0.12, 0.07, 0.07, 1.0)
		if slot < _slot_accents.size() and is_instance_valid(_slot_accents[slot]):
			_slot_accents[slot].color = Color(0.86, 0.60, 0.24, 1.0) if is_selected else Color(0.0, 0.0, 0.0, 0.0)
