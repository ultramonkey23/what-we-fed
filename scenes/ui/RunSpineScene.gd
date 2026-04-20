extends Node2D

signal upgrade_selected(index: int)
signal predation_selected(index: int)
signal continue_requested(advance_to_boss: bool)

const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")

var _choices: Array[Dictionary] = []
var _run_growth: Node = null
var _advance_to_boss: bool = false
var _awaiting_upgrade_choice: bool = false
var _awaiting_continue: bool = false
## evolution → optional predation → review (continue)
var _shell_phase: String = "evolution"

var _canvas: CanvasLayer = null
var _panel: ColorRect = null
var _next_label: Label = null
var _prep_scroll: ScrollContainer = null
var _prep_body_label: Label = null
var _state_hint_label: Label = null
var _header_label: Label = null
var _subtitle_label: Label = null
var _choice_cards: Array[ColorRect] = []


func _ready() -> void:
	_build_ui()
	visible = false
	if _canvas != null:
		_canvas.visible = false


func present_level_completion(choices: Array[Dictionary], run_growth_ref: Node, advance_to_boss: bool) -> void:
	_shell_phase = "evolution"
	_choices.clear()
	for choice in choices:
		_choices.append(choice.duplicate(true))
	_run_growth = run_growth_ref
	_advance_to_boss = advance_to_boss
	_awaiting_upgrade_choice = not _choices.is_empty()
	_awaiting_continue = _choices.is_empty()
	_apply_shell_titles()
	_refresh_cards()
	_refresh_prep_body()
	_refresh_hint()
	if _canvas != null:
		_canvas.visible = true
	visible = true


func present_predation_pool(offers: Array[Dictionary]) -> void:
	if offers.is_empty():
		return
	_shell_phase = "predation"
	_choices.clear()
	for o in offers:
		_choices.append(o.duplicate(true))
	_awaiting_upgrade_choice = true
	_awaiting_continue = false
	_apply_shell_titles()
	_refresh_cards()
	_refresh_prep_body()
	_refresh_hint()


func notify_predation_committed(_selected_index: int) -> void:
	_shell_phase = "review"
	_awaiting_upgrade_choice = false
	_awaiting_continue = true
	_choices.clear()
	_apply_shell_titles()
	_refresh_cards()
	_refresh_prep_body()
	_refresh_hint()


func notify_upgrade_committed(_selected_index: int) -> void:
	_awaiting_upgrade_choice = false
	_awaiting_continue = true
	_refresh_prep_body()
	_refresh_hint()


func hide_surface() -> void:
	visible = false
	if _canvas != null:
		_canvas.visible = false
	_shell_phase = "evolution"
	_awaiting_upgrade_choice = false
	_awaiting_continue = false
	_choices.clear()
	_refresh_cards()


func refresh_prep_summary() -> void:
	if not visible:
		return
	_refresh_prep_body()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	if key_event.is_action_pressed("toggle_dna_route"):
		if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("toggle_dna_routing_preference"):
			_run_growth.call("toggle_dna_routing_preference")
		_refresh_prep_body()
		get_viewport().set_input_as_handled()
		return

	if _awaiting_upgrade_choice:
		var selected_index: int = -1
		match key_event.keycode:
			KEY_1:
				selected_index = 0
			KEY_2:
				selected_index = 1
			KEY_3:
				selected_index = 2
		if selected_index >= 0 and selected_index < _choices.size():
			if _shell_phase == "predation":
				emit_signal("predation_selected", selected_index)
			else:
				emit_signal("upgrade_selected", selected_index)
			get_viewport().set_input_as_handled()
		return

	if _awaiting_continue:
		if (
			key_event.keycode == KEY_SPACE
			or key_event.keycode == KEY_ENTER
			or key_event.keycode == KEY_KP_ENTER
		):
			emit_signal("continue_requested", _advance_to_boss)
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.01, 0.01, 0.02, 0.92)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(backdrop)

	_panel = ColorRect.new()
	_panel.position = Vector2(84.0, 56.0)
	_panel.size = Vector2(1112.0, 608.0)
	UI_STYLE.apply_shell_style(_panel, "", "", Color(0.07, 0.05, 0.06, 0.98), Color(0.22, 0.16, 0.14, 0.94))
	_canvas.add_child(_panel)

	_header_label = Label.new()
	_header_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_HEADER
	_header_label.position = Vector2(0.0, 14.0)
	_header_label.size = Vector2(1112.0, 36.0)
	UI_STYLE.apply_label(_header_label, "heading", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_header_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_SUBTITLE
	_subtitle_label.position = Vector2(0.0, 48.0)
	_subtitle_label.size = Vector2(1112.0, 22.0)
	UI_STYLE.apply_label(_subtitle_label, "screen_subtitle", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_subtitle_label)

	_next_label = Label.new()
	_next_label.position = Vector2(0.0, 72.0)
	_next_label.size = Vector2(1112.0, 22.0)
	UI_STYLE.apply_label(_next_label, "caption_strong", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_next_label)

	_build_choice_cards()

	_prep_scroll = ScrollContainer.new()
	_prep_scroll.position = Vector2(24.0, 332.0)
	_prep_scroll.size = Vector2(1064.0, 214.0)
	_prep_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_prep_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_prep_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(_prep_scroll)

	_prep_body_label = Label.new()
	_prep_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_prep_body_label, "body")
	_prep_scroll.add_child(_prep_body_label)

	_state_hint_label = Label.new()
	_state_hint_label.position = Vector2(0.0, 554.0)
	_state_hint_label.size = Vector2(1112.0, 44.0)
	_state_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_state_hint_label, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_state_hint_label)


func _build_choice_cards() -> void:
	_choice_cards.clear()
	var card_w: float = 340.0
	var card_h: float = 218.0
	var gap: float = 24.0
	var start_x: float = 32.0

	for i in range(3):
		var card: ColorRect = ColorRect.new()
		card.name = "RunSpineUpgradeCard_%d" % i
		card.position = Vector2(start_x + i * (card_w + gap), 104.0)
		card.size = Vector2(card_w, card_h)
		UI_STYLE.apply_shell_style(card, "", "", Color(0.12, 0.09, 0.10, 0.96), Color(0.30, 0.22, 0.20, 0.88))
		_panel.add_child(card)
		_choice_cards.append(card)

		var index_label: Label = Label.new()
		index_label.text = str(i + 1)
		index_label.position = Vector2(14.0, 14.0)
		index_label.size = Vector2(24.0, 24.0)
		UI_STYLE.apply_label(index_label, "card_index")
		card.add_child(index_label)

		var cat_label: Label = Label.new()
		cat_label.name = "Category"
		cat_label.position = Vector2(14.0, 42.0)
		cat_label.size = Vector2(card_w - 28.0, 18.0)
		UI_STYLE.apply_label(cat_label, "caption_strong")
		card.add_child(cat_label)

		var title_label: Label = Label.new()
		title_label.name = "Title"
		title_label.position = Vector2(14.0, 64.0)
		title_label.size = Vector2(card_w - 28.0, 54.0)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(title_label, "card_title")
		card.add_child(title_label)

		var separator: ColorRect = ColorRect.new()
		separator.position = Vector2(14.0, 124.0)
		separator.size = Vector2(card_w - 28.0, 1.0)
		separator.color = Color(0.28, 0.20, 0.18, 0.50)
		card.add_child(separator)

		var body_label: Label = Label.new()
		body_label.name = "Body"
		body_label.position = Vector2(14.0, 136.0)
		body_label.size = Vector2(card_w - 28.0, 70.0)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(body_label, "body")
		card.add_child(body_label)


func _refresh_cards() -> void:
	for i in range(_choice_cards.size()):
		var card: ColorRect = _choice_cards[i]
		if i < _choices.size():
			var choice: Dictionary = _choices[i]
			card.visible = true
			card.get_node("Category").text = String(choice.get("tag", "EVOLUTION"))
			card.get_node("Title").text = String(choice.get("title", "Unknown"))
			card.get_node("Body").text = String(choice.get("summary", ""))
		else:
			card.visible = false


func _apply_shell_titles() -> void:
	if _header_label == null or _subtitle_label == null:
		return
	match _shell_phase:
		"predation":
			_header_label.text = PRESENTATION_TEXT.RUN_SPINE_PREDATION_HEADER
			_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_PREDATION_SUBTITLE
		"review":
			_header_label.text = PRESENTATION_TEXT.RUN_SPINE_REVIEW_HEADER
			_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_REVIEW_SUBTITLE
		_:
			_header_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_HEADER
			_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_SUBTITLE


func _refresh_hint() -> void:
	_next_label.text = (
		PRESENTATION_TEXT.RUN_PREP_NEXT_BOSS
		if _advance_to_boss
		else PRESENTATION_TEXT.RUN_PREP_NEXT_REGULAR
	)
	if _awaiting_upgrade_choice:
		if _shell_phase == "predation":
			_state_hint_label.text = PRESENTATION_TEXT.RUN_SPINE_PREDATION_CONTROLS
		else:
			_state_hint_label.text = PRESENTATION_TEXT.RUN_SPINE_EVOLUTION_CONTROLS
		return
	if _awaiting_continue:
		_state_hint_label.text = PRESENTATION_TEXT.RUN_PREP_CONTROLS
		return
	_state_hint_label.text = ""


func _refresh_prep_body() -> void:
	if _prep_body_label == null or _prep_scroll == null:
		return
	_prep_body_label.text = _compose_run_prep_body()
	_reflow_scroll_label_pair(_prep_scroll, _prep_body_label)


func _creature_display_name(species_id: String) -> String:
	if species_id.is_empty():
		return "?"
	var creature: Dictionary = COMBAT_CONTENT.get_creature(species_id)
	if creature.is_empty():
		return species_id
	return String(creature.get("display_name", species_id))


func _compose_run_prep_body() -> String:
	var blocks: Array[String] = []

	var hp_line: String = "Vitals  |  HP %.0f / %.0f  |  ATK %.0f  |  DEF %.0f" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.get_attack_damage(),
		GameState.player_defense
	]
	blocks.append(hp_line)

	var growth_line: String = "Growth  |  —"
	if _run_growth != null and is_instance_valid(_run_growth):
		growth_line = "Growth  |  level %d  |  urge %.0f / %.0f" % [
			int(_run_growth.level),
			float(_run_growth.current_exp),
			float(_run_growth.exp_to_next)
		]
	blocks.append(growth_line)

	var route_line: String = "DNA harvest  |  %s" % PRESENTATION_TEXT.DNA_ROUTE_BOND_LABEL
	if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_dna_routing_label"):
		route_line = "DNA harvest  |  %s" % String(_run_growth.call("get_dna_routing_label"))
	blocks.append(route_line)

	if GameState.roster.is_empty():
		blocks.append("Bonds  |  none yet")
	else:
		var bond_lines: Array[String] = []
		for creature in GameState.roster:
			var sid: String = String(creature.get("species_id", ""))
			var bl: int = int(creature.get("bond_level", 1))
			bond_lines.append("%s  (bond L%d)" % [_creature_display_name(sid), bl])
		blocks.append("Bonds  |  " + "\n  ".join(PackedStringArray(bond_lines)))

	var dna_pairs: Array[Dictionary] = []
	for species_key in GameState.dna_by_species.keys():
		var sid2: String = String(species_key)
		var amt: float = GameState.get_dna(sid2)
		if amt <= 0.0001:
			continue
		dna_pairs.append({"id": sid2, "amt": amt})
	dna_pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["amt"]) > float(b["amt"]))

	if dna_pairs.is_empty():
		blocks.append("Stored DNA  |  none")
	else:
		var dna_lines: Array[String] = []
		var limit: int = min(dna_pairs.size(), 8)
		for i in range(limit):
			var row: Dictionary = dna_pairs[i]
			dna_lines.append("%s  × %.0f" % [_creature_display_name(String(row["id"])), float(row["amt"])])
		if dna_pairs.size() > limit:
			dna_lines.append("…  +%d more species" % (dna_pairs.size() - limit))
		blocks.append("Stored DNA  |  " + "\n  ".join(PackedStringArray(dna_lines)))

	if GameState.active_mutations.is_empty():
		blocks.append("Inner work  |  no mutations yet")
	else:
		var mut_lines: Array[String] = []
		for mut in GameState.active_mutations:
			var mid: String = String(mut.get("id", "mutation"))
			var charges: int = int(mut.get("current_charges", 0))
			var effect: Dictionary = mut.get("effect", {})
			var etype: String = String(effect.get("type", ""))
			var tail: String = ("  |  " + etype) if not etype.is_empty() else ""
			mut_lines.append("%s  —  %d charges%s" % [mid, charges, tail])
		blocks.append("Inner work  |  " + "\n  ".join(PackedStringArray(mut_lines)))

	if GameState.absorbed_types.is_empty():
		blocks.append("Digestions  |  none logged")
	else:
		var digest: Array[String] = []
		var cap: int = min(GameState.absorbed_types.size(), 6)
		for j in range(cap):
			var absorbed: Dictionary = GameState.absorbed_types[j]
			digest.append("%s from %s" % [
				String(absorbed.get("eat_type", "?")),
				_creature_display_name(String(absorbed.get("source_species_id", "")))
			])
		var more_count: int = GameState.absorbed_types.size() - cap
		if more_count > 0:
			digest.append("… +%d earlier" % more_count)
		blocks.append("Digestions  |  " + "\n  ".join(PackedStringArray(digest)))

	return "\n\n".join(PackedStringArray(blocks))


func _reflow_scroll_label_pair(scroll: ScrollContainer, label: Label) -> void:
	if scroll == null or label == null:
		return
	var inner_w: float = maxf(1.0, scroll.size.x - 10.0)
	label.custom_minimum_size.x = inner_w
	var content_h: float = label.get_minimum_size().y
	label.custom_minimum_size.y = maxf(scroll.size.y, content_h)
