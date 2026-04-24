extends Node2D

signal event_completed(outcome_payload: Dictionary)

const UI_STYLE = preload("res://systems/UIStyle.gd")
const EVENT_CONTENT = preload("res://data/EventContent.gd")

var _current_event: Dictionary = {}
var _can_input: bool = false
var _selected_choice_index: int = 0
var _canvas: CanvasLayer = null

var _panel: ColorRect
var _title_label: Label
var _body_label: Label
var _choice_container: Control
var _choice_cards: Array[ColorRect] = []


func _ready() -> void:
	_build_ui()
	hide()


func present_event(event_id: String) -> void:
	_current_event = EVENT_CONTENT.get_event(event_id)
	if _current_event.is_empty():
		emit_signal("event_completed", {})
		return
	
	_selected_choice_index = 0
	_refresh_event_content()
	_refresh_choice_highlights()
	
	show()
	if _canvas != null:
		_canvas.visible = true
	
	_can_input = false
	await get_tree().create_timer(0.2).timeout
	_can_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _can_input:
		return
	
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	
	var key_event: InputEventKey = event
	var choice_count: int = _current_event.get("choices", []).size()
	
	match key_event.keycode:
		KEY_1, KEY_2, KEY_3:
			var idx: int = -1
			if key_event.keycode == KEY_1: idx = 0
			elif key_event.keycode == KEY_2: idx = 1
			elif key_event.keycode == KEY_3: idx = 2
			
			if idx >= 0 and idx < choice_count:
				_selected_choice_index = idx
				_refresh_choice_highlights()
				_commit_choice()
		KEY_SPACE, KEY_ENTER:
			_commit_choice()


func _commit_choice() -> void:
	_can_input = false
	var choices: Array = _current_event.get("choices", [])
	if _selected_choice_index < 0 or _selected_choice_index >= choices.size():
		_close_event({})
		return
	
	var choice: Dictionary = choices[_selected_choice_index]
	_close_event(choice)


func _close_event(choice: Dictionary) -> void:
	hide()
	if _canvas != null:
		_canvas.visible = false
	emit_signal("event_completed", choice)


func _refresh_event_content() -> void:
	if _title_label != null:
		_title_label.text = String(_current_event.get("title", "Event"))
	if _body_label != null:
		_body_label.text = String(_current_event.get("body", ""))
	
	var choices: Array = _current_event.get("choices", [])
	for i in range(_choice_cards.size()):
		if i < choices.size():
			_choice_cards[i].visible = true
			var c = choices[i]
			_choice_cards[i].get_node("Label").text = String(c.get("label", ""))
			_choice_cards[i].get_node("Summary").text = String(c.get("summary", ""))
			
			var cost: Dictionary = Dictionary(c.get("cost", {}))
			var cost_label = _choice_cards[i].get_node("Cost")
			if not cost.is_empty():
				cost_label.visible = true
				cost_label.text = "COST: %s" % _get_cost_text(cost)
			else:
				cost_label.visible = false
		else:
			_choice_cards[i].visible = false


func _get_cost_text(cost: Dictionary) -> String:
	var type = String(cost.get("type", ""))
	var val = float(cost.get("value", 0))
	if type == "dna":
		return "%.0f %s DNA" % [val, String(cost.get("species", ""))]
	if type == "dna_any":
		return "%.0f DNA (any)" % val
	return "%.0f" % val


func _refresh_choice_highlights() -> void:
	for i in range(_choice_cards.size()):
		var is_sel = (i == _selected_choice_index)
		_choice_cards[i].color = UI_STYLE.get_manga_color("blood_ember") if is_sel else UI_STYLE.get_manga_color("deep_violet")
		_choice_cards[i].color.a = 0.45 if is_sel else 0.85


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)
	
	_panel = ColorRect.new()
	_panel.color = Color(0.02, 0.02, 0.03, 0.92)
	_panel.size = Vector2(1000, 500)
	_panel.position = Vector2(140, 110)
	UI_STYLE.apply_shell_style(_panel, "run_overlay")
	_canvas.add_child(_panel)
	
	_title_label = Label.new()
	_title_label.position = Vector2(40, 30)
	_title_label.size = Vector2(920, 40)
	UI_STYLE.apply_label(_title_label, "overlay_title", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_title_label)
	
	var sep = ColorRect.new()
	sep.color = UI_STYLE.get_manga_color("blood_ember")
	sep.size = Vector2(920, 2)
	sep.position = Vector2(40, 80)
	_panel.add_child(sep)
	
	_body_label = Label.new()
	_body_label.position = Vector2(60, 100)
	_body_label.size = Vector2(880, 160)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_body_label, "overlay_body")
	_panel.add_child(_body_label)
	
	_choice_container = Control.new()
	_choice_container.position = Vector2(0, 280)
	_choice_container.size = Vector2(1000, 200)
	_panel.add_child(_choice_container)
	
	var card_w = 300
	var card_h = 160
	var gap = 20
	var start_x = (1000 - (card_w * 3 + gap * 2)) / 2
	
	for i in range(3):
		var card = ColorRect.new()
		card.size = Vector2(card_w, card_h)
		card.position = Vector2(start_x + i * (card_w + gap), 0)
		_choice_container.add_child(card)
		_choice_cards.append(card)
		
		var num = Label.new()
		num.text = str(i + 1)
		num.position = Vector2(10, 10)
		UI_STYLE.apply_label(num, "mm_caption")
		card.add_child(num)
		
		var lab = Label.new()
		lab.name = "Label"
		lab.position = Vector2(10, 30)
		lab.size = Vector2(card_w - 20, 30)
		UI_STYLE.apply_label(lab, "mm_choice_bond")
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(lab)
		
		var sum = Label.new()
		sum.name = "Summary"
		sum.position = Vector2(10, 65)
		sum.size = Vector2(card_w - 20, 60)
		UI_STYLE.apply_label(sum, "mm_dim")
		sum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sum.add_theme_font_size_override("font_size", 12)
		card.add_child(sum)
		
		var cost = Label.new()
		cost.name = "Cost"
		cost.position = Vector2(10, 130)
		cost.size = Vector2(card_w - 20, 20)
		UI_STYLE.apply_label(cost, "mm_caption")
		cost.add_theme_color_override("font_color", UI_STYLE.get_manga_color("blood_ember"))
		card.add_child(cost)
