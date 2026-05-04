extends Node2D
class_name RunSpineScene

signal upgrade_selected(index: int)
signal predation_selected(index: int)
signal continue_requested(advance_to_boss: bool)
signal path_node_selected(node_id: String)
signal management_action_requested(action_id: String, payload: Dictionary)

const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const COMBAT_DATA = preload("res://data/CombatContent.gd")
const PERFORMANCE_REWARD_CONTENT = preload("res://data/PerformanceRewardContent.gd")
const RITUAL_CONTENT = preload("res://data/RitualConsumableContent.gd")
const COLLAR_CONTENT = preload("res://data/CollarContent.gd")
const PATH_RUN_PLAN = preload("res://systems/PathRunPlan.gd")

var _choices: Array[Dictionary] = []
var _advance_to_boss: bool = false
var _awaiting_upgrade_choice: bool = false
var _awaiting_continue: bool = false
var _awaiting_path_choice: bool = false
var RunGrowth: Node:
	get: return get_node_or_null("/root/RunGrowth")
var RunStats: Node:
	get: return get_node_or_null("/root/RunStats")

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
var _management_sections: Array[Dictionary] = []
var _management_section_index: int = 0
var _management_item_index_by_section: Dictionary = {}
var _management_status_line: String = ""
var _collar_menu_open: bool = false
var _collar_menu_index: int = 0


func _ready() -> void:
	_build_ui()
	visible = false
	if _canvas != null:
		_canvas.visible = false


func present_level_completion(choices: Array[Dictionary], _rg_ref: Node, advance_to_boss: bool) -> void:
	_shell_phase = "evolution"
	_choices.clear()
	for choice in choices:
		_choices.append(choice.duplicate(true))
	_advance_to_boss = advance_to_boss
	_awaiting_upgrade_choice = not _choices.is_empty()
	_awaiting_continue = _choices.is_empty()
	_awaiting_path_choice = false
	_apply_shell_titles()
	_refresh_cards()
	_rebuild_management_sections()
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
	_awaiting_path_choice = false
	_apply_shell_titles()
	_refresh_cards()
	_refresh_card_layout()
	_rebuild_management_sections()
	_refresh_prep_body()
	_refresh_hint()


func present_path_choice(nodes: Array[Dictionary], advance_to_boss: bool) -> void:
	if nodes.is_empty():
		return
	_shell_phase = "path"
	_choices.clear()
	for node in nodes:
		_choices.append(node.duplicate(true))
	_advance_to_boss = advance_to_boss
	_awaiting_upgrade_choice = false
	_awaiting_path_choice = true
	_awaiting_continue = false
	_apply_shell_titles()
	_refresh_cards()
	_refresh_card_layout()
	_rebuild_management_sections()
	_refresh_prep_body()
	_refresh_hint()


func notify_predation_committed(_selected_index: int) -> void:
	_shell_phase = "review"
	_awaiting_upgrade_choice = false
	_awaiting_continue = true
	_choices.clear()
	_awaiting_path_choice = false
	_apply_shell_titles()
	_refresh_cards()
	_refresh_card_layout()
	_rebuild_management_sections()
	_refresh_prep_body()
	_refresh_hint()


func notify_path_committed(_node_id: String) -> void:
	_shell_phase = "review"
	_awaiting_upgrade_choice = false
	_awaiting_path_choice = false
	_awaiting_continue = true
	_apply_shell_titles()
	_rebuild_management_sections()
	_refresh_prep_body()
	_refresh_hint()


func notify_upgrade_committed(_selected_index: int) -> void:
	_shell_phase = "review"
	_awaiting_upgrade_choice = false
	_awaiting_continue = true
	_awaiting_path_choice = false
	_choices.clear()
	_apply_shell_titles()
	_refresh_cards()
	_refresh_card_layout()
	_rebuild_management_sections()
	_refresh_prep_body()
	_refresh_hint()


func hide_surface() -> void:
	visible = false
	if _canvas != null:
		_canvas.visible = false
	_shell_phase = "evolution"
	_awaiting_upgrade_choice = false
	_awaiting_continue = false
	_awaiting_path_choice = false
	_choices.clear()
	_refresh_cards()
	_refresh_card_layout()
	_management_sections.clear()
	_management_item_index_by_section.clear()
	_management_section_index = 0
	_management_status_line = ""
	_collar_menu_open = false
	_collar_menu_index = 0


func refresh_prep_summary() -> void:
	if not visible:
		return
	_rebuild_management_sections()
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
		RunGrowth.toggle_dna_routing_preference()
		_refresh_prep_body()
		get_viewport().set_input_as_handled()
		return

	if _handle_management_input(key_event):
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
			if get_viewport(): get_viewport().set_input_as_handled()
		return

	if _awaiting_path_choice:
		var path_index: int = -1
		match key_event.keycode:
			KEY_1:
				path_index = 0
			KEY_2:
				path_index = 1
			KEY_3:
				path_index = 2
		if path_index >= 0 and path_index < _choices.size():
			var node_id: String = str(_choices[path_index].get("id", ""))
			if not node_id.is_empty() and PATH_RUN_PLAN.validate_node_access(node_id, GameState):
				emit_signal("path_node_selected", node_id)
				if get_viewport(): get_viewport().set_input_as_handled()
		return

	if _awaiting_continue:
		if (
			key_event.keycode == KEY_SPACE
			or key_event.keycode == KEY_ENTER
			or key_event.keycode == KEY_KP_ENTER
		):
			emit_signal("continue_requested", _advance_to_boss)
			if get_viewport(): get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.01, 0.01, 0.02, 0.84)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(backdrop)

	_panel = ColorRect.new()
	_panel.position = Vector2(84.0, 56.0)
	_panel.size = Vector2(1112.0, 608.0)
	UI_STYLE.apply_shell_style(_panel, "run_overlay")
	_canvas.add_child(_panel)

	_header_label = Label.new()
	_header_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_HEADER
	_header_label.position = Vector2(0.0, 14.0)
	_header_label.size = Vector2(1112.0, 36.0)
	UI_STYLE.apply_label(_header_label, "overlay_title", HORIZONTAL_ALIGNMENT_CENTER)
	_header_label.add_theme_font_size_override("font_size", 38)
	_panel.add_child(_header_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_SUBTITLE
	_subtitle_label.position = Vector2(0.0, 48.0)
	_subtitle_label.size = Vector2(1112.0, 22.0)
	UI_STYLE.apply_label(_subtitle_label, "mm_hint", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_subtitle_label)

	_next_label = Label.new()
	_next_label.position = Vector2(0.0, 72.0)
	_next_label.size = Vector2(1112.0, 22.0)
	UI_STYLE.apply_label(_next_label, "mm_caption", HORIZONTAL_ALIGNMENT_CENTER)
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
	UI_STYLE.apply_label(_prep_body_label, "overlay_body")
	_prep_scroll.add_child(_prep_body_label)

	_state_hint_label = Label.new()
	_state_hint_label.position = Vector2(0.0, 554.0)
	_state_hint_label.size = Vector2(1112.0, 44.0)
	_state_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_state_hint_label, "mm_hint", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_state_hint_label)


func _build_choice_cards() -> void:
	_choice_cards.clear()
	var card_w: float = 254.0
	var card_h: float = 224.0
	var gap: float = 18.0
	var start_x: float = 20.0

	for i in range(4):
		var card: ColorRect = ColorRect.new()
		card.name = "RunSpineUpgradeCard_%d" % i
		card.position = Vector2(start_x + i * (card_w + gap), 104.0)
		card.size = Vector2(card_w, card_h)
		UI_STYLE.apply_shell_style(card, "hud_right")
		_panel.add_child(card)
		_choice_cards.append(card)

		var index_label: Label = Label.new()
		index_label.text = str(i + 1)
		index_label.position = Vector2(12.0, 10.0)
		index_label.size = Vector2(24.0, 24.0)
		UI_STYLE.apply_label(index_label, "mm_caption")
		card.add_child(index_label)

		var cat_label: Label = Label.new()
		cat_label.name = "Category"
		cat_label.position = Vector2(12.0, 38.0)
		cat_label.size = Vector2(card_w - 24.0, 18.0)
		UI_STYLE.apply_label(cat_label, "mm_choice_consume")
		cat_label.add_theme_font_size_override("font_size", 13)
		card.add_child(cat_label)

		var title_label: Label = Label.new()
		title_label.name = "Title"
		title_label.position = Vector2(12.0, 58.0)
		title_label.size = Vector2(card_w - 24.0, 58.0)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(title_label, "hud_metric_value")
		title_label.add_theme_font_size_override("font_size", 18)
		card.add_child(title_label)

		var separator: ColorRect = ColorRect.new()
		separator.position = Vector2(12.0, 120.0)
		separator.size = Vector2(card_w - 24.0, 1.0)
		separator.color = UI_STYLE.get_manga_color("mutation_magenta")
		separator.color.a = 0.48
		card.add_child(separator)

		var body_label: Label = Label.new()
		body_label.name = "Body"
		body_label.position = Vector2(12.0, 126.0)
		body_label.size = Vector2(card_w - 24.0, 50.0)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(body_label, "overlay_body")
		body_label.add_theme_font_size_override("font_size", 13)
		card.add_child(body_label)

		var cost_label: Label = Label.new()
		cost_label.name = "Cost"
		cost_label.position = Vector2(12.0, 178.0)
		cost_label.size = Vector2(card_w - 24.0, 15.0)
		UI_STYLE.apply_label(cost_label, "mm_caption")
		cost_label.add_theme_color_override("font_color", UI_STYLE.get_manga_color("blood_ember"))
		cost_label.add_theme_font_size_override("font_size", 12)
		card.add_child(cost_label)

		var risk_label: Label = Label.new()
		risk_label.name = "Risk"
		risk_label.position = Vector2(12.0, 193.0)
		risk_label.size = Vector2(card_w - 24.0, 15.0)
		UI_STYLE.apply_label(risk_label, "mm_caption")
		risk_label.add_theme_font_size_override("font_size", 11)
		card.add_child(risk_label)

		var reward_label: Label = Label.new()
		reward_label.name = "Reward"
		reward_label.position = Vector2(12.0, 208.0)
		reward_label.size = Vector2(card_w - 24.0, 15.0)
		UI_STYLE.apply_label(reward_label, "mm_caption")
		reward_label.add_theme_color_override("font_color", UI_STYLE.get_manga_color("alert_gold"))
		reward_label.add_theme_font_size_override("font_size", 11)
		card.add_child(reward_label)


func _refresh_cards() -> void:
	for i in range(_choice_cards.size()):
		var card: ColorRect = _choice_cards[i]
		if i < _choices.size():
			var choice: Dictionary = _choices[i]
			card.visible = true
			var is_locked: bool = _shell_phase == "path" and not PATH_RUN_PLAN.validate_node_access(str(choice.get("id", "")), GameState)
			card.modulate = Color(0.45, 0.45, 0.45, 0.76) if is_locked else Color.WHITE
			card.get_node("Category").text = str(choice.get("tag", "EVOLUTION"))
			card.get_node("Title").text = str(choice.get("display_name", choice.get("title", "Unknown")))
			card.get_node("Body").text = _compose_choice_body(choice, is_locked)
			card.get_node("Cost").visible = _shell_phase == "path"
			card.get_node("Risk").visible = _shell_phase == "path"
			card.get_node("Reward").visible = _shell_phase == "path"
			if _shell_phase == "path":
				var lock_prefix: String = "LOCKED  |  " if is_locked else ""
				card.get_node("Cost").text = "%sCOST  |  %s" % [lock_prefix, _entry_cost_text(Dictionary(choice.get("entry_cost", {})))]
				card.get_node("Risk").text = "PRESSURE  |  %s" % _path_pressure_text(choice)
				card.get_node("Reward").text = "PAYOFF  |  %s" % _path_payoff_text(choice)
		else:
			card.visible = false
	_refresh_card_layout()


func _refresh_card_layout() -> void:
	var visible_cards: Array[ColorRect] = []
	for card in _choice_cards:
		if card.visible:
			visible_cards.append(card)
	if visible_cards.is_empty():
		return
	var card_w: float = _choice_cards[0].size.x
	var gap: float = 24.0
	var total_w: float = card_w * float(visible_cards.size()) + gap * float(maxi(visible_cards.size() - 1, 0))
	var start_x: float = (_panel.size.x - total_w) * 0.5
	for i in range(visible_cards.size()):
		visible_cards[i].position.x = start_x + float(i) * (card_w + gap)


func _apply_shell_titles() -> void:
	if _header_label == null or _subtitle_label == null:
		return
	match _shell_phase:
		"predation":
			_header_label.text = PRESENTATION_TEXT.RUN_SPINE_PREDATION_HEADER
			_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_PREDATION_SUBTITLE
		"review":
			var resonance: Dictionary = GameState.get_current_resonance_perk()
			if resonance.get("id") != "unclaimed":
				_header_label.text = str(resonance.get("title", PRESENTATION_TEXT.RUN_SPINE_REVIEW_HEADER))
				_subtitle_label.text = str(resonance.get("flavor", PRESENTATION_TEXT.RUN_SPINE_REVIEW_SUBTITLE))
			else:
				_header_label.text = PRESENTATION_TEXT.RUN_SPINE_REVIEW_HEADER
				_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_REVIEW_SUBTITLE
		"path":
			_header_label.text = "CHOOSE THE NEXT HUNT"
			_subtitle_label.text = "Shape this run's creature path."
		_:
			_header_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_HEADER
			_subtitle_label.text = PRESENTATION_TEXT.RUN_SPINE_LEVEL_SUBTITLE


func _compose_choice_body(choice: Dictionary, is_locked: bool) -> String:
	if _shell_phase != "path":
		return str(choice.get("summary", ""))
	var lines: Array[String] = [str(choice.get("summary", ""))]
	var consequence: String = _path_consequence_text(choice)
	if not consequence.is_empty():
		lines.append(consequence)
	if is_locked:
		lines.append("Cannot pay entry.")
	return "\n".join(PackedStringArray(lines))


func _entry_cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "none"
	var value: float = float(cost.get("value", 0.0))
	match str(cost.get("type", "")):
		"hp":
			return "%.0f HP" % value
		"dna":
			return "%.0f %s DNA" % [value, _creature_display_name(str(cost.get("species", "")))]
		_:
			return "unknown"


func _risk_modifier_text(risk_modifier: Dictionary) -> String:
	if risk_modifier.is_empty():
		return "none"
	var label: String = str(risk_modifier.get("display_name", risk_modifier.get("id", "RISK"))).to_upper()
	var summary: String = str(risk_modifier.get("summary", ""))
	if summary.is_empty():
		return label
	return "%s: %s" % [label, summary]


func _path_pressure_text(choice: Dictionary) -> String:
	var encounter_options: Dictionary = Dictionary(choice.get("encounter_options", {}))
	if bool(encounter_options.get("is_event", false)):
		return str(encounter_options.get("event_type", "event")).capitalize()
	var risk_modifier: Dictionary = Dictionary(choice.get("risk_modifier", {}))
	if risk_modifier.is_empty():
		return "baseline"
	var label: String = str(risk_modifier.get("display_name", risk_modifier.get("id", "risk"))).to_upper()
	var summary: String = str(risk_modifier.get("summary", "")).strip_edges()
	if summary.is_empty():
		return label
	return "%s - %s" % [label, summary]


func _path_payoff_text(choice: Dictionary) -> String:
	var reward_context: Dictionary = Dictionary(choice.get("reward_context", {}))
	if bool(reward_context.get("is_event", false)):
		return str(choice.get("potential_reward_bias", "world consequence"))
	if bool(reward_context.get("predation_pool", false)):
		return "DNA offers"
	if bool(reward_context.get("elite_reward_tier", false)):
		return "elite reward pull"
	if bool(reward_context.get("bond_flavored", false)):
		return "bond/support bias"
	return str(choice.get("potential_reward_bias", "stable reward"))


func _path_consequence_text(choice: Dictionary) -> String:
	var node_id: String = str(choice.get("id", ""))
	var encounter_options: Dictionary = Dictionary(choice.get("encounter_options", {}))
	if bool(encounter_options.get("is_event", false)):
		return "Consequence: no combat slice; resolve the encounter."
	var entry_effects: Dictionary = Dictionary(choice.get("entry_effects", {}))
	var effect_lines: Array[String] = []
	var bond_gain: int = int(entry_effects.get("bond_level_gain", 0))
	if bond_gain > 0:
		effect_lines.append("+%d bond" % bond_gain)
	var support_floor: float = float(entry_effects.get("support_floor", 0.0))
	if support_floor > 0.0:
		effect_lines.append("support floor %.0f" % support_floor)
	if not effect_lines.is_empty():
		return "Consequence: " + ", ".join(PackedStringArray(effect_lines))
	var reward_context: Dictionary = Dictionary(choice.get("reward_context", {}))
	if bool(reward_context.get("predation_pool", false)):
		return "Consequence: predation offers can open."
	if bool(reward_context.get("elite_reward_tier", false)):
		return "Consequence: harder bodies, richer pull."
	if node_id == "prey":
		return "Consequence: stable hunt, low commitment."
	return ""


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
	if _awaiting_path_choice:
		_state_hint_label.text = "1 / 2 - choose next node"
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
	var creature: Dictionary = COMBAT_DATA.get_creature(species_id)
	if creature.is_empty():
		return species_id
	return str(creature.get("display_name", species_id))


func _compose_run_prep_body() -> String:
	var blocks: Array[String] = []
	var vessel_lines: Array[String] = []

	var hp_line: String = "Vitals  |  HP %.0f / %.0f  |  ATK %.0f  |  DEF %.0f" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.get_attack_damage(),
		GameState.player_defense
	]
	vessel_lines.append(hp_line)

	var growth_line: String = "Growth  |  —"
	if RunGrowth != null and is_instance_valid(RunGrowth):
		growth_line = "Growth  |  level %d  |  urge %.0f / %.0f" % [
			int(RunGrowth.level),
			float(RunGrowth.current_exp),
			float(RunGrowth.exp_to_next)
		]
	vessel_lines.append(growth_line)

	var route_line: String = "DNA harvest  |  %s" % RunGrowth.get_dna_routing_label()
	vessel_lines.append(route_line)
	
	var resonance: Dictionary = GameState.get_current_resonance_perk()
	if resonance.get("id") != "unclaimed":
		var res_line: String = "Resonance  |  %s: %s" % [resonance.get("perk_title"), resonance.get("perk_description")]
		vessel_lines.append(res_line)

	blocks.append(_compose_run_prep_section("VESSEL STATE", vessel_lines))

	var ecology_lines_out: Array[String] = []

	if GameState.has_method("get_reward_ecology_summary_lines"):
		var ecology_lines: Array = GameState.get_reward_ecology_summary_lines()
		for ecology_line in ecology_lines:
			ecology_lines_out.append(str(ecology_line))
	if GameState.has_method("get_reward_ecology_slot_alerts"):
		var ecology_alerts: Array = GameState.get_reward_ecology_slot_alerts()
		if not ecology_alerts.is_empty():
			ecology_lines_out.append("Ecology alerts  |  " + "\n  ".join(PackedStringArray(ecology_alerts)))
	blocks.append(_compose_run_prep_section("REWARD ECOLOGY", ecology_lines_out))

	blocks.append(_compose_run_prep_section("BUILD HAND", [_compose_management_digest_block()]))

	var bond_lines: Array[String] = []
	if GameState.roster.is_empty():
		bond_lines.append("none yet")
	else:
		for creature in GameState.roster:
			var sid: String = str(creature.get("species_id", ""))
			var bl: int = int(creature.get("bond_level", 1))
			var active_mark: String = "  |  support" if GameState.active_lair_creature_ids.has(sid) else ""
			bond_lines.append("%s  |  bond L%d%s" % [_creature_display_name(sid), bl, active_mark])
	blocks.append(_compose_run_prep_section("BONDED SEQUENCES", bond_lines))

	var dna_pairs: Array[Dictionary] = []
	for species_key in GameState.dna_by_species.keys():
		var sid2: String = str(species_key)
		var amt: float = GameState.get_dna(sid2)
		if amt <= 0.0001:
			continue
		dna_pairs.append({"id": sid2, "amt": amt})
	dna_pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["amt"]) > float(b["amt"]))

	var dna_lines: Array[String] = []
	if dna_pairs.is_empty():
		dna_lines.append("none")
	else:
		var limit: int = min(dna_pairs.size(), 8)
		for i in range(limit):
			var row: Dictionary = dna_pairs[i]
			dna_lines.append("%s  × %.0f" % [_creature_display_name(str(row["id"])), float(row["amt"])])
		if dna_pairs.size() > limit:
			dna_lines.append("…  +%d more species" % (dna_pairs.size() - limit))
	blocks.append(_compose_run_prep_section("LINEAGE DNA", dna_lines))

	var mut_lines: Array[String] = []
	if GameState.active_mutations.is_empty():
		mut_lines.append("no mutations yet")
	else:
		for mut in GameState.active_mutations:
			var mid: String = str(mut.get("id", "mutation"))
			var charges: int = int(mut.get("current_charges", 0))
			var effect: Dictionary = mut.get("effect", {})
			var etype: String = str(effect.get("type", ""))
			var tail: String = ("  |  " + etype) if not etype.is_empty() else ""
			mut_lines.append("%s  —  %d charges%s" % [mid, charges, tail])
	blocks.append(_compose_run_prep_section("INNER WORK", mut_lines))

	var digest: Array[String] = []
	if GameState.absorbed_types.is_empty():
		digest.append("none logged")
	else:
		var cap: int = min(GameState.absorbed_types.size(), 6)
		for j in range(cap):
			var absorbed: Dictionary = GameState.absorbed_types[j]
			digest.append("%s from %s" % [
				str(absorbed.get("eat_type", "?")),
				_creature_display_name(str(absorbed.get("source_species_id", "")))
			])
		var more_count: int = GameState.absorbed_types.size() - cap
		if more_count > 0:
			digest.append("… +%d earlier" % more_count)
	blocks.append(_compose_run_prep_section("DIGESTIONS", digest))

	return "\n\n".join(PackedStringArray(blocks))


func _compose_run_prep_section(title: String, lines: Array[String]) -> String:
	var cleaned: Array[String] = []
	for line in lines:
		var text: String = line.strip_edges()
		if text.is_empty():
			continue
		cleaned.append("  " + text.replace("\n", "\n  "))
	if cleaned.is_empty():
		cleaned.append("  none")
	return "%s\n%s" % [title, "\n".join(PackedStringArray(cleaned))]


func _handle_management_input(key_event: InputEventKey) -> bool:
	if _collar_menu_open:
		match key_event.keycode:
			KEY_C:
				_collar_menu_open = false
				_refresh_prep_body()
				return true
			KEY_A:
				_cycle_collar_item(-1)
				return true
			KEY_D:
				_cycle_collar_item(1)
				return true
			KEY_E:
				_commit_collar_action("equip")
				return true
			KEY_U:
				_commit_collar_action("unlock")
				return true
			KEY_TAB:
				_collar_menu_open = false
				_cycle_management_section(1)
				return true
		return false
	match key_event.keycode:
		KEY_TAB:
			_cycle_management_section(1)
			return true
		KEY_A:
			_cycle_management_item(-1)
			return true
		KEY_D:
			_cycle_management_item(1)
			return true
		KEY_E:
			_commit_management_action("equip")
			return true
		KEY_X:
			_commit_management_action("salvage")
			return true
		KEY_C:
			_collar_menu_open = true
			_collar_menu_index = clampi(_collar_menu_index, 0, max(_get_collar_menu_rows().size() - 1, 0))
			_refresh_prep_body()
			return true
	return false


func _compose_management_digest_block() -> String:
	if _collar_menu_open:
		return _compose_collar_menu_block()
	if _management_sections.is_empty():
		return "Management  |  no slotted loot/artifacts/rituals yet\n  Collar slot  |  C open collar inventory"
	var lines: Array[String] = []
	lines.append("Management  |  TAB slot  A/D item  E equip  X salvage  C collars")
	for i in range(_management_sections.size()):
		var section: Dictionary = _management_sections[i]
		var items: Array = section.get("items", [])
		var marker: String = ">" if i == _management_section_index else " "
		if items.is_empty():
			lines.append("%s %s  |  empty" % [marker, str(section.get("label", "Slot"))])
			continue
		var item_idx: int = int(_management_item_index_by_section.get(i, 0))
		item_idx = clampi(item_idx, 0, items.size() - 1)
		var item_id: String = str(items[item_idx])
		var item_name: String = _reward_title_from_id(item_id)
		lines.append("%s %s  |  %s  (%d/%d)" % [
			marker,
			str(section.get("label", "Slot")),
			item_name,
			item_idx + 1,
			items.size()
		])
		
		# Management-Rich Detail (surfaced for the active selection)
		if i == _management_section_index:
			lines.append("    " + _reward_detail_text(item_id))
			
	lines.append("  Collar slot  |  " + _equipped_collar_label())
	if not _management_status_line.is_empty():
		lines.append("  Last action  |  " + _management_status_line)
	return "\n".join(PackedStringArray(lines))


func _reward_detail_text(reward_id: String) -> String:
	var reward_data: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(reward_id)
	if reward_data.is_empty():
		reward_data = RITUAL_CONTENT.get_ritual(reward_id)
	
	if reward_data.is_empty():
		return "No detail available"
		
	var summary: String = str(reward_data.get("summary", ""))
	var tag: String = str(reward_data.get("tag", "ITEM"))
	var tier: int = int(reward_data.get("power_tier", 1))
	
	var detail: String = "[%s T%d] %s" % [tag, tier, summary]
	
	var effect: Dictionary = reward_data.get("effect", {})
	if not effect.is_empty():
		var _type: String = str(effect.get("type", "")).replace("_", " ")
		var stats: Array[String] = []
		for key in effect.keys():
			if key == "type": continue
			stats.append("%s: %s" % [key.replace("_", " "), str(effect[key])])
		
		if not stats.is_empty():
			detail += "\n    Stats  |  " + "  ".join(PackedStringArray(stats))
			
	return detail


func _compose_collar_menu_block() -> String:
	var rows: Array[Dictionary] = _get_collar_menu_rows()
	var lines: Array[String] = []
	lines.append("Collars  |  A/D choose  E equip unlocked  U unlock with species DNA  C close")
	if rows.is_empty():
		lines.append("  Inventory  |  none")
	else:
		_collar_menu_index = clampi(_collar_menu_index, 0, rows.size() - 1)
		for i in range(rows.size()):
			var row: Dictionary = rows[i]
			var collar_id: String = str(row.get("id", ""))
			var marker: String = ">" if i == _collar_menu_index else " "
			var equipped: String = "  [equipped]" if GameState.equipped_collar_id == collar_id else ""
			var lock_state: String = "unlocked" if bool(row.get("unlocked", false)) else _collar_cost_text(Dictionary(row.get("dna_unlock_cost", {})))
			lines.append("%s %s  |  %s%s" % [marker, str(row.get("title", collar_id)), lock_state, equipped])
			if i == _collar_menu_index:
				lines.append("  " + str(row.get("description", "")))
	if not _management_status_line.is_empty():
		lines.append("  Last action  |  " + _management_status_line)
	return "\n".join(PackedStringArray(lines))


func _get_collar_menu_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var all_collars: Array[Dictionary] = COLLAR_CONTENT.get_all_collars()
	for collar in all_collars:
		var row: Dictionary = collar.duplicate(true)
		row["unlocked"] = GameState.collar_inventory.has(str(row.get("id", "")))
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("unlocked", false)) != bool(b.get("unlocked", false)):
			return bool(a.get("unlocked", false))
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	return rows


func _cycle_collar_item(step: int) -> void:
	var rows: Array[Dictionary] = _get_collar_menu_rows()
	if rows.size() <= 1:
		return
	_collar_menu_index = posmod(_collar_menu_index + step, rows.size())
	_refresh_prep_body()


func _commit_collar_action(action_id: String) -> void:
	var rows: Array[Dictionary] = _get_collar_menu_rows()
	if rows.is_empty():
		_management_status_line = "No collar inventory"
		_refresh_prep_body()
		return
	_collar_menu_index = clampi(_collar_menu_index, 0, rows.size() - 1)
	var collar: Dictionary = rows[_collar_menu_index]
	var collar_id: String = str(collar.get("id", ""))
	var ok: bool = false
	if action_id == "unlock":
		ok = GameState.unlock_collar(collar_id)
	elif action_id == "equip":
		ok = GameState.equip_collar(collar_id)
	var status: String = "ok" if ok else "failed"
	_management_status_line = "%s collar: %s" % [action_id.capitalize(), str(collar.get("title", collar_id))]
	emit_signal("management_action_requested", "collar_" + action_id, {
		"status": status,
		"collar_id": collar_id
	})
	_refresh_prep_body()


func _equipped_collar_label() -> String:
	if GameState.equipped_collar_id.is_empty():
		return "none equipped"
	var collar: Dictionary = COLLAR_CONTENT.get_collar(GameState.equipped_collar_id)
	if collar.is_empty():
		return GameState.equipped_collar_id
	return str(collar.get("title", GameState.equipped_collar_id))


func _collar_cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "locked"
	var chunks: Array[String] = []
	for species_id in cost.keys():
		chunks.append("%s %.0f" % [_creature_display_name(str(species_id)), float(cost[species_id])])
	return "locked: " + ", ".join(PackedStringArray(chunks))


func _reward_title_from_id(reward_id: String) -> String:
	var reward_data: Dictionary = PERFORMANCE_REWARD_CONTENT.get_reward(reward_id)
	if not reward_data.is_empty():
		return str(reward_data.get("title", reward_id))
	var ritual_data: Dictionary = RITUAL_CONTENT.get_ritual(reward_id)
	if not ritual_data.is_empty():
		return str(ritual_data.get("title", reward_id))
	return reward_id


func _rebuild_management_sections() -> void:
	var sections: Array[Dictionary] = []
	var loot: Dictionary = GameState.reward_loot_slots
	var artifacts: Dictionary = GameState.reward_artifact_slots
	var consumables: Dictionary = GameState.reward_consumable_slots
	sections.append(_build_management_section("Loot offense", "loot", "offense", Array(loot.get("offense", []))))
	sections.append(_build_management_section("Loot defense", "loot", "defense", Array(loot.get("defense", []))))
	sections.append(_build_management_section("Loot utility", "loot", "utility", Array(loot.get("utility", []))))
	sections.append(_build_management_section("Artifact major", "artifact", "major", Array(artifacts.get("major", []))))
	sections.append(_build_management_section("Artifact minor", "artifact", "minor", Array(artifacts.get("minor", []))))
	sections.append(_build_management_section("Ritual prepared", "consumable", "prepared", Array(consumables.get("prepared", []))))
	sections.append(_build_management_section("Ritual carry", "consumable", "carry", Array(consumables.get("carry", []))))
	_management_sections = sections
	_management_section_index = clampi(_management_section_index, 0, max(_management_sections.size() - 1, 0))
	for i in range(_management_sections.size()):
		var section_items: Array = _management_sections[i].get("items", [])
		var idx: int = int(_management_item_index_by_section.get(i, 0))
		if section_items.is_empty():
			_management_item_index_by_section[i] = 0
		else:
			_management_item_index_by_section[i] = clampi(idx, 0, section_items.size() - 1)


func _build_management_section(label: String, lane: String, slot: String, items: Array) -> Dictionary:
	return {
		"label": label,
		"lane": lane,
		"slot": slot,
		"items": items.duplicate(true)
	}


func _cycle_management_section(step: int) -> void:
	if _management_sections.is_empty():
		return
	_management_section_index = posmod(_management_section_index + step, _management_sections.size())
	_refresh_prep_body()


func _cycle_management_item(step: int) -> void:
	if _management_sections.is_empty():
		return
	var section: Dictionary = _management_sections[_management_section_index]
	var items: Array = section.get("items", [])
	if items.size() <= 1:
		return
	var idx: int = int(_management_item_index_by_section.get(_management_section_index, 0))
	idx = posmod(idx + step, items.size())
	_management_item_index_by_section[_management_section_index] = idx
	_refresh_prep_body()


func _commit_management_action(action_id: String) -> void:
	_rebuild_management_sections()
	if _management_sections.is_empty():
		return
	var section: Dictionary = _management_sections[_management_section_index]
	var items: Array = section.get("items", [])
	if items.is_empty():
		_management_status_line = "%s: empty slot" % str(section.get("label", "Slot"))
		_refresh_prep_body()
		return
	var lane: String = str(section.get("lane", ""))
	var slot: String = str(section.get("slot", ""))
	var idx: int = int(_management_item_index_by_section.get(_management_section_index, 0))
	idx = clampi(idx, 0, items.size() - 1)
	var reward_id: String = str(items[idx])
	var ok: bool = false
	if action_id == "equip":
		ok = GameState.set_reward_slot_primary(lane, slot, reward_id)
	elif action_id == "salvage":
		ok = GameState.salvage_reward_from_slot(lane, slot, reward_id)
	if ok:
		_management_status_line = "%s %s -> %s" % [action_id.capitalize(), str(section.get("label", "slot")), _reward_title_from_id(reward_id)]
		emit_signal("management_action_requested", action_id, {
			"status": "ok",
			"lane": lane,
			"slot": slot,
			"reward_id": reward_id
		})
	else:
		_management_status_line = "%s failed on %s" % [action_id.capitalize(), str(section.get("label", "slot"))]
		emit_signal("management_action_requested", action_id, {
			"status": "failed",
			"lane": lane,
			"slot": slot,
			"reward_id": reward_id
		})
	_rebuild_management_sections()
	_refresh_prep_body()


func _reflow_scroll_label_pair(scroll: ScrollContainer, label: Label) -> void:
	if scroll == null or label == null:
		return
	var inner_w: float = maxf(1.0, scroll.size.x - 10.0)
	label.custom_minimum_size.x = inner_w
	var content_h: float = label.get_minimum_size().y
	label.custom_minimum_size.y = maxf(scroll.size.y, content_h)
