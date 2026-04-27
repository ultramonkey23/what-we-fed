extends Node2D

const ROUTE_SCENE_PATH: String = "res://scenes/ui/RouteScene.tscn"
const TITLE_SCENE_PATH: String = "res://scenes/ui/TitleScreen.tscn"
const INTRO_BOND_SCENE_PATH: String = "res://scenes/ui/IntroBondChoiceScene.tscn"
const MAX_LAIR_DISPLAY: int = 3
const SIDEBAR_X: float = 36.0
const SIDEBAR_W: float = 328.0
const LIST_X: float = 392.0
const LIST_W: float = 832.0
const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const COMBAT_DATA = preload("res://data/CombatContent.gd")
const POTENTIAL_GATE = preload("res://systems/PotentialGate.gd")
const GROWTH_STATS = preload("res://data/GrowthStats.gd")
const CREATURE_TRAITS = preload("res://data/CreatureTraitContent.gd")

const HOLD_RELEASE_TIME: float = 1.2

var _creature_cards: Array[Panel] = []
var _card_accents: Array[ColorRect] = []
var _card_index_labels: Array[Label] = []
var _active_pills: Array[Label] = []
var _selected_index: int = -1
var _can_input: bool = false
var _breath_time: float = 0.0

var _ui_layer: CanvasLayer
var _hub_solo_label: Label
var _hub_name: Label
var _hub_identity: Label
var _hub_support: Label
var _hub_bond_pot: Label
var _hub_dna_stat: Label

var _ranch_action_train: Label
var _ranch_action_release: Label
var _ranch_action_hint: Label
var _bottom_hint: Label
var _feedback_label: Label

var _vitals_labels: Dictionary = {}
var _bias_label: Label
var _archive_mode: bool = false
var _archive_trait_list: Array[String] = []
var _archive_selected_trait_index: int = -1

var _release_hold_current: float = 0.0
var _is_releasing: bool = false
var _growth_stats_ref: GrowthStats = GROWTH_STATS.new()


func _ready() -> void:
	_sync_selection_index()
	_archive_trait_list = GameState.archive_traits
	_build_ui()
	await get_tree().create_timer(0.12).timeout
	_can_input = true


func _process(delta: float) -> void:
	if not _can_input:
		return
	
	_breath_time += delta
	_update_breathing(_breath_time)
		
	if _is_releasing:
		if Input.is_key_pressed(KEY_X):
			_release_hold_current += delta
			var progress: float = clampf(_release_hold_current / HOLD_RELEASE_TIME, 0.0, 1.0)
			_update_release_feedback(progress)
			if _release_hold_current >= HOLD_RELEASE_TIME:
				_execute_release()
				_is_releasing = false
				_release_hold_current = 0.0
		else:
			_is_releasing = false
			_release_hold_current = 0.0
			_update_release_feedback(0.0)


func _sync_selection_index() -> void:
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
		if key_event.keycode == KEY_X and not key_event.pressed:
			_is_releasing = false
			_release_hold_current = 0.0
			_update_release_feedback(0.0)
		return

	if key_event.keycode == KEY_TAB:
		_archive_mode = not _archive_mode
		_build_ui()
		get_viewport().set_input_as_handled()
		return

	var lair: Array = GameState.lair_roster
	var display_count: int = min(lair.size(), MAX_LAIR_DISPLAY)

	var index: int = -1
	match key_event.keycode:
		KEY_1: index = 0
		KEY_2: index = 1
		KEY_3: index = 2

	if index >= 0:
		if _archive_mode:
			if index < _archive_trait_list.size():
				_archive_selected_trait_index = index
				_refresh_active_support_panel()
		else:
			if index < display_count:
				if _selected_index == index:
					_selected_index = -1
					GameState.set_active_lair_creature("")
				else:
					_selected_index = index
					GameState.set_active_lair_creature(String(lair[index].get("species_id", "")))
				_refresh_card_highlights()
				_refresh_active_support_panel()
				_refresh_bottom_bar()
				_breath_time = 0.0
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_T:
		if _selected_index >= 0 and _selected_index < lair.size():
			var sid: String = String(lair[_selected_index].get("species_id", ""))
			if GameState.train_lair_creature(sid):
				_play_feedback("BOND DEEPENED")
				_refresh_active_support_panel()
				_build_creature_list(_ui_layer, GameState.lair_roster)
			else:
				var cost: int = GameState.get_lair_training_cost(sid)
				var cur_bond: int = int(lair[_selected_index].get("bond_level", 1))
				if cur_bond >= 5:
					_play_feedback("MAX BOND REACHED")
				elif GameState.get_dna(sid) < cost:
					_play_feedback("NOT ENOUGH DNA (NEED %d)" % cost)
			get_viewport().set_input_as_handled()
			return

	if key_event.keycode == KEY_S and _archive_mode:
		if _selected_index >= 0 and _archive_selected_trait_index >= 0:
			var sid: String = String(lair[_selected_index].get("species_id", ""))
			var tid: String = _archive_trait_list[_archive_selected_trait_index]
			if GameState.splice_trait_to_creature(sid, tid):
				_play_feedback("TRAIT SPLICED")
				_refresh_active_support_panel()
				_build_creature_list(_ui_layer, GameState.lair_roster)
			get_viewport().set_input_as_handled()
			return

	if key_event.keycode == KEY_A:
		if _selected_index >= 0 and _selected_index < lair.size():
			var sid: String = String(lair[_selected_index].get("species_id", ""))
			if GameState.request_ascension(sid):
				_play_feedback("KAIJU ASCENSION")
				_build_ui() # Rebuild for new visual scale
			get_viewport().set_input_as_handled()
			return

	if key_event.keycode == KEY_X:
		if _selected_index >= 0 and _selected_index < lair.size():
			_is_releasing = true
			_release_hold_current = 0.0
			get_viewport().set_input_as_handled()
			return

	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		if GameState.is_intro_bond_choice_pending():
			get_tree().change_scene_to_file(INTRO_BOND_SCENE_PATH)
			return
		GameState.run_in_progress = false
		get_tree().change_scene_to_file(ROUTE_SCENE_PATH)
		return

	if key_event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)
		return


func _execute_release() -> void:
	var lair: Array = GameState.lair_roster
	if _selected_index >= 0 and _selected_index < lair.size():
		var sid: String = String(lair[_selected_index].get("species_id", ""))
		GameState.release_lair_creature(sid)
		_selected_index = -1
		_build_ui() # Full rebuild since roster count changed


func _update_release_feedback(progress: float) -> void:
	if not is_instance_valid(_ranch_action_release):
		return
	if progress <= 0.0:
		_refresh_active_support_panel() # Reset to normal
		return
	
	var pct: int = int(progress * 100.0)
	_ranch_action_release.text = "HOLD X TO RELEASE... %d%%" % pct
	_ranch_action_release.add_theme_color_override("font_color", UI_STYLE.get_manga_color("blood_ember").lerp(Color.WHITE, progress))


func _play_feedback(text: String) -> void:
	if not is_instance_valid(_feedback_label):
		return
	
	_feedback_label.text = text
	_feedback_label.modulate.a = 1.0
	_feedback_label.scale = Vector2.ONE * 1.2
	
	var tween := create_tween()
	tween.tween_property(_feedback_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.8)
	tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.24)


func _update_breathing(t: float) -> void:
	if _selected_index < 0 or _selected_index >= _creature_cards.size():
		return
	var accent := _card_accents[_selected_index]
	if is_instance_valid(accent):
		var pulse: float = (sin(t * 2.5) + 1.0) * 0.5
		accent.modulate.a = 0.4 + (pulse * 0.6)


func _build_ui() -> void:
	if is_instance_valid(_ui_layer):
		_ui_layer.queue_free()
	
	UI_STYLE.attach_shell_backdrop(self)

	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	var header: Label = Label.new()
	header.text = "THE LAIR" if not _archive_mode else "THE ARCHIVE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(1280.0, 58.0)
	header.position = Vector2(0.0, 36.0)
	UI_STYLE.apply_label(header, "mm_title")
	header.add_theme_font_size_override("font_size", 42)
	_ui_layer.add_child(header)

	var sub: Label = Label.new()
	sub.text = PRESENTATION_TEXT.LAIR_SUBTITLE if not _archive_mode else "Extracted traits can be spliced into active bonds."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(920.0, 48.0)
	sub.position = Vector2(180.0, 92.0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(sub, "mm_subtitle")
	_ui_layer.add_child(sub)

	var lair: Array = GameState.lair_roster
	if lair.is_empty():
		_build_empty_state(_ui_layer)
		_clear_hub_refs()
	else:
		_build_den_sidebar(_ui_layer, lair)
		_build_creature_list(_ui_layer, lair)
		_build_archive_vitals(_ui_layer)

	_build_bottom_bar(_ui_layer, lair)
	
	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.size = Vector2(SIDEBAR_W, 40.0)
	_feedback_label.position = Vector2(SIDEBAR_X, 430.0)
	_feedback_label.modulate.a = 0.0
	_feedback_label.pivot_offset = Vector2(SIDEBAR_W * 0.5, 20.0)
	UI_STYLE.apply_label(_feedback_label, "mm_choice_bond")
	_ui_layer.add_child(_feedback_label)


func _clear_hub_refs() -> void:
	_hub_solo_label = null
	_hub_name = null
	_hub_identity = null
	_hub_support = null
	_hub_bond_pot = null
	_hub_dna_stat = null
	_ranch_action_train = null
	_ranch_action_release = null
	_ranch_action_hint = null
	_bottom_hint = null
	_feedback_label = null
	_vitals_labels.clear()
	_bias_label = null


func _build_empty_state(canvas: CanvasLayer) -> void:
	var empty_label: Label = Label.new()
	empty_label.text = PRESENTATION_TEXT.LAIR_EMPTY
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.size = Vector2(1280.0, 80.0)
	empty_label.position = Vector2(0.0, 305.0)
	UI_STYLE.apply_label(empty_label, "subheading")
	canvas.add_child(empty_label)


func _build_den_sidebar(canvas: CanvasLayer, lair: Array) -> void:
	var slab: Panel = Panel.new()
	slab.position = Vector2(SIDEBAR_X - 6.0, 118.0)
	slab.size = Vector2(SIDEBAR_W + 12.0, 498.0)
	UI_STYLE.apply_shell_style(slab, "lair_sidebar")
	canvas.add_child(slab)

	var den: Label = Label.new()
	den.text = PRESENTATION_TEXT.LAIR_DEN_LABEL if not _archive_mode else "Extracted Traits"
	den.position = Vector2(SIDEBAR_X + 10.0, 128.0)
	den.size = Vector2(SIDEBAR_W - 20.0, 28.0)
	UI_STYLE.apply_label(den, "mm_choice_consume")
	den.add_theme_font_size_override("font_size", 15)
	canvas.add_child(den)

	var blurb: Label = Label.new()
	blurb.text = PRESENTATION_TEXT.LAIR_DEN_BLURB if not _archive_mode else "Select a trait to view its effect and splice it onto your active bond."
	blurb.position = Vector2(SIDEBAR_X + 10.0, 156.0)
	blurb.size = Vector2(SIDEBAR_W - 20.0, 56.0)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(blurb, "mm_dim")
	canvas.add_child(blurb)

	if _archive_mode:
		_build_archive_trait_list_sidebar(canvas)
	else:
		var act_head: Label = Label.new()
		act_head.text = PRESENTATION_TEXT.LAIR_ACTIVE_HEAD
		act_head.position = Vector2(SIDEBAR_X + 10.0, 224.0)
		act_head.size = Vector2(SIDEBAR_W - 20.0, 26.0)
		UI_STYLE.apply_label(act_head, "mm_choice_bond")
		act_head.add_theme_font_size_override("font_size", 18)
		canvas.add_child(act_head)

		var panel: ColorRect = ColorRect.new()
		panel.color = UI_STYLE.get_manga_color("ink_black")
		panel.color.a = 0.88
		panel.position = Vector2(SIDEBAR_X + 8.0, 254.0)
		panel.size = Vector2(SIDEBAR_W - 16.0, 188.0)
		canvas.add_child(panel)

		var inset: ColorRect = ColorRect.new()
		inset.color = UI_STYLE.get_manga_color("alert_gold")
		inset.color.a = 0.24
		inset.position = Vector2(SIDEBAR_X + 8.0, 254.0)
		inset.size = Vector2(3.0, 188.0)
		canvas.add_child(inset)

		_hub_solo_label = Label.new()
		_hub_solo_label.text = PRESENTATION_TEXT.LAIR_ACTIVE_SOLO
		_hub_solo_label.position = Vector2(SIDEBAR_X + 20.0, 264.0)
		_hub_solo_label.size = Vector2(SIDEBAR_W - 36.0, 168.0)
		_hub_solo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_solo_label, "mm_body")
		canvas.add_child(_hub_solo_label)

		_hub_name = Label.new()
		_hub_name.position = Vector2(SIDEBAR_X + 20.0, 262.0)
		_hub_name.size = Vector2(SIDEBAR_W - 36.0, 32.0)
		UI_STYLE.apply_label(_hub_name, "mm_stat_primary")
		canvas.add_child(_hub_name)

		_hub_identity = Label.new()
		_hub_identity.position = Vector2(SIDEBAR_X + 20.0, 296.0)
		_hub_identity.size = Vector2(SIDEBAR_W - 36.0, 22.0)
		UI_STYLE.apply_label(_hub_identity, "mm_dim")
		canvas.add_child(_hub_identity)
		
		_hub_dna_stat = Label.new()
		_hub_dna_stat.position = Vector2(SIDEBAR_X + 20.0, 316.0)
		_hub_dna_stat.size = Vector2(SIDEBAR_W - 36.0, 22.0)
		UI_STYLE.apply_label(_hub_dna_stat, "mm_choice_bond")
		_hub_dna_stat.add_theme_font_size_override("font_size", 14)
		canvas.add_child(_hub_dna_stat)

		_hub_support = Label.new()
		_hub_support.position = Vector2(SIDEBAR_X + 20.0, 342.0)
		_hub_support.size = Vector2(SIDEBAR_W - 36.0, 44.0)
		_hub_support.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_support, "mm_caption")
		canvas.add_child(_hub_support)

		_hub_bond_pot = Label.new()
		_hub_bond_pot.position = Vector2(SIDEBAR_X + 20.0, 386.0)
		_hub_bond_pot.size = Vector2(SIDEBAR_W - 36.0, 56.0)
		_hub_bond_pot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_bond_pot, "mm_stat_secondary")
		canvas.add_child(_hub_bond_pot)

	_ranch_action_train = Label.new()
	_ranch_action_train.position = Vector2(SIDEBAR_X + 10.0, 458.0)
	_ranch_action_train.size = Vector2(SIDEBAR_W - 20.0, 24.0)
	UI_STYLE.apply_label(_ranch_action_train, "mm_caption")
	canvas.add_child(_ranch_action_train)

	_ranch_action_release = Label.new()
	_ranch_action_release.position = Vector2(SIDEBAR_X + 10.0, 484.0)
	_ranch_action_release.size = Vector2(SIDEBAR_W - 20.0, 24.0)
	UI_STYLE.apply_label(_ranch_action_release, "mm_caption")
	canvas.add_child(_ranch_action_release)

	_ranch_action_hint = Label.new()
	_ranch_action_hint.position = Vector2(SIDEBAR_X + 10.0, 514.0)
	_ranch_action_hint.size = Vector2(SIDEBAR_W - 20.0, 80.0)
	_ranch_action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_ranch_action_hint, "mm_dim")
	canvas.add_child(_ranch_action_hint)

	_refresh_active_support_panel()


func _build_archive_trait_list_sidebar(canvas: CanvasLayer) -> void:
	var list_head: Label = Label.new()
	list_head.text = "TRAIT ARCHIVE"
	list_head.position = Vector2(SIDEBAR_X + 10.0, 224.0)
	list_head.size = Vector2(SIDEBAR_W - 20.0, 26.0)
	UI_STYLE.apply_label(list_head, "mm_choice_consume")
	list_head.add_theme_font_size_override("font_size", 18)
	canvas.add_child(list_head)

	var start_y: float = 254.0
	var item_h: float = 60.0
	var gap: float = 4.0

	for i in range(_archive_trait_list.size()):
		var tid: String = _archive_trait_list[i]
		var t_data: Dictionary = CREATURE_TRAITS.get_trait(tid)
		
		var panel: ColorRect = ColorRect.new()
		panel.color = UI_STYLE.get_manga_color("ink_black")
		panel.color.a = 0.88
		panel.position = Vector2(SIDEBAR_X + 8.0, start_y + i * (item_h + gap))
		panel.size = Vector2(SIDEBAR_W - 16.0, item_h)
		canvas.add_child(panel)

		var is_sel: bool = (i == _archive_selected_trait_index)
		var inset: ColorRect = ColorRect.new()
		inset.color = UI_STYLE.get_manga_color("alert_gold") if is_sel else UI_STYLE.get_manga_color("paper")
		inset.color.a = 0.6 if is_sel else 0.15
		inset.position = Vector2(SIDEBAR_X + 8.0, start_y + i * (item_h + gap))
		inset.size = Vector2(3.0, item_h)
		canvas.add_child(inset)

		var name_label: Label = Label.new()
		name_label.text = "%d. %s" % [i + 1, String(t_data.get("display_name", tid))]
		name_label.position = Vector2(SIDEBAR_X + 18.0, start_y + i * (item_h + gap) + 6.0)
		name_label.size = Vector2(SIDEBAR_W - 36.0, 24.0)
		UI_STYLE.apply_label(name_label, "mm_stat_primary" if is_sel else "mm_body")
		name_label.add_theme_font_size_override("font_size", 14)
		canvas.add_child(name_label)
		
		var desc_label: Label = Label.new()
		desc_label.text = String(t_data.get("description", ""))
		desc_label.position = Vector2(SIDEBAR_X + 18.0, start_y + i * (item_h + gap) + 30.0)
		desc_label.size = Vector2(SIDEBAR_W - 36.0, 24.0)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(desc_label, "mm_dim")
		desc_label.add_theme_font_size_override("font_size", 11)
		canvas.add_child(desc_label)


func _build_creature_list(canvas: CanvasLayer, lair: Array) -> void:
	# Clear existing cards if we're doing a partial update
	for card in _creature_cards:
		if is_instance_valid(card):
			card.queue_free()
	
	_creature_cards.clear()
	_card_accents.clear()
	_card_index_labels.clear()
	_active_pills.clear()

	var card_width: float = LIST_W
	var card_height: float = 128.0
	var card_gap: float = 8.0
	var card_x: float = LIST_X
	var list_start_y: float = 146.0

	var count: int = min(lair.size(), MAX_LAIR_DISPLAY)
	for i in range(count):
		var card_y: float = list_start_y + i * (card_height + card_gap)
		_build_creature_card(canvas, lair[i], i, card_x, card_y, card_width, card_height)

	_refresh_card_highlights()


func _build_creature_card(canvas: CanvasLayer, creature: Dictionary, index: int, x: float, y: float, w: float, h: float) -> void:
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
	_card_index_labels.append(num_label)

	var pill: Label = Label.new()
	pill.text = "ACTIVE"
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.position = Vector2(w - 118.0, 12.0)
	pill.size = Vector2(96.0, 22.0)
	UI_STYLE.apply_label(pill, "mm_choice_bond")
	pill.add_theme_font_size_override("font_size", 12)
	pill.visible = false
	card.add_child(pill)
	_active_pills.append(pill)

	var species_id: String = String(creature.get("species_id", ""))
	var display: String = String(creature.get("display_name", "Unknown"))

	var name_label: Label = Label.new()
	name_label.text = display
	name_label.position = Vector2(50.0, 10.0)
	name_label.size = Vector2(w - 200.0, 30.0)
	UI_STYLE.apply_label(name_label, "mm_stat_primary")
	card.add_child(name_label)

	var id_label: Label = Label.new()
	id_label.text = _identity_line(creature, species_id)
	id_label.position = Vector2(50.0, 40.0)
	id_label.size = Vector2(w - 90.0, 22.0)
	UI_STYLE.apply_label(id_label, "mm_dim")
	card.add_child(id_label)

	var bond_level: int = int(creature.get("bond_level", 1))
	var potential_label: String = _get_potential_label_for_species(species_id)
	var bl_label: Label = Label.new()
	bl_label.text = "Bond %d  ·  Potential cap %s" % [bond_level, potential_label]
	bl_label.position = Vector2(50.0, 62.0)
	bl_label.size = Vector2(w - 100.0, 22.0)
	UI_STYLE.apply_label(bl_label, "mm_stat_secondary")
	card.add_child(bl_label)

	var support_line: String = _support_one_liner(creature, species_id)
	if not support_line.is_empty():
		var sup_label: Label = Label.new()
		sup_label.text = support_line
		sup_label.position = Vector2(50.0, 84.0)
		sup_label.size = Vector2(w - 100.0, 22.0)
		UI_STYLE.apply_label(sup_label, "mm_caption")
		card.add_child(sup_label)

	var desc: String = String(creature.get("description", ""))
	if not desc.is_empty():
		var desc_scroll := ScrollContainer.new()
		desc_scroll.position = Vector2(50.0, 104.0)
		desc_scroll.size = Vector2(w - 70.0, 22.0)
		desc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		desc_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		desc_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		card.add_child(desc_scroll)

		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.position = Vector2.ZERO
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI_STYLE.apply_label(desc_label, "mm_body")
		desc_scroll.add_child(desc_label)
		_reflow_lair_desc_scroll(desc_scroll, desc_label)

	_creature_cards.append(card)
	_card_accents.append(accent)


func _identity_line(creature: Dictionary, species_id: String) -> String:
	var sid_show: String = species_id if not species_id.is_empty() else "—"
	var p: String = String(creature.get("primary_type", "—")).capitalize()
	var s: String = String(creature.get("secondary_type", "")).strip_edges()
	if s.is_empty():
		return "%s  ·  %s" % [sid_show, p]
	return "%s  ·  %s / %s" % [sid_show, p, s.capitalize()]


func _support_one_liner(creature: Dictionary, species_id: String) -> String:
	var role: Dictionary = COMBAT_DATA.get_support_role(species_id)
	if role.is_empty():
		role = creature.get("support_role", {})
	var readout: String = String(role.get("readout_name", creature.get("display_name", ""))).strip_edges()
	var hint: String = String(role.get("hud_trigger_hint", "")).strip_edges()
	if readout.is_empty():
		return hint
	if hint.is_empty():
		return readout
	return "%s  ·  %s" % [readout, hint]


func _reflow_lair_desc_scroll(scroll: ScrollContainer, label: Label) -> void:
	if scroll == null or label == null:
		return
	var inner_w: float = maxf(1.0, scroll.size.x - 4.0)
	label.custom_minimum_size.x = inner_w
	var content_h: float = label.get_minimum_size().y
	label.custom_minimum_size.y = maxf(scroll.size.y, content_h)


func _get_potential_label_for_species(species_id: String) -> String:
	if species_id.is_empty():
		return POTENTIAL_GATE.GRADE_ALPHA.to_upper()
	var creature_template: Dictionary = COMBAT_DATA.get_creature(species_id)
	var potential_grade: String = POTENTIAL_GATE.normalize_grade_id(
		String(creature_template.get("potential_max_grade", POTENTIAL_GATE.GRADE_ALPHA))
	)
	return potential_grade.to_upper()


func _build_bottom_bar(canvas: CanvasLayer, lair: Array) -> void:
	var note: Label = Label.new()
	note.text = PRESENTATION_TEXT.LAIR_NOTE
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.size = Vector2(1060.0, 30.0)
	note.position = Vector2(110.0, 612.0)
	UI_STYLE.apply_label(note, "mm_dim")
	canvas.add_child(note)

	_bottom_hint = Label.new()
	_bottom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bottom_hint.size = Vector2(1280.0, 28.0)
	_bottom_hint.position = Vector2(0.0, 652.0)
	UI_STYLE.apply_label(_bottom_hint, "mm_hint")
	canvas.add_child(_bottom_hint)
	
	_refresh_bottom_bar()


func _refresh_bottom_bar() -> void:
	if not is_instance_valid(_bottom_hint):
		return
	
	var lair: Array = GameState.lair_roster
	var count: int = min(lair.size(), MAX_LAIR_DISPLAY)
	var hint_text: String
	if count == 0:
		hint_text = "ENTER — begin entry  |  ESC — title"
	else:
		hint_text = "TAB — toggle Lair/Archive  |  ENTER — continue  |  ESC — title"

	_bottom_hint.text = hint_text


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
		if i < _active_pills.size() and is_instance_valid(_active_pills[i]):
			_active_pills[i].visible = is_selected
		if i < _card_index_labels.size() and is_instance_valid(_card_index_labels[i]):
			UI_STYLE.apply_label(_card_index_labels[i], "mm_choice_consume" if is_selected else "mm_caption")


func _refresh_active_support_panel() -> void:
	if _hub_solo_label == null and not _archive_mode:
		return
	var lair: Array = GameState.lair_roster
	var has: bool = _selected_index >= 0 and _selected_index < lair.size()
	
	if not _archive_mode:
		_hub_solo_label.visible = not has
		_hub_name.visible = has
		_hub_identity.visible = has
		_hub_dna_stat.visible = has
		_hub_support.visible = has
		_hub_bond_pot.visible = has
	
	_ranch_action_train.visible = has
	_ranch_action_release.visible = has
	_ranch_action_hint.visible = has
	
	_refresh_archive_vitals()
	
	if not has:
		return
	var c: Dictionary = lair[_selected_index]
	var species_id: String = String(c.get("species_id", ""))
	
	if not _archive_mode:
		_hub_name.text = String(c.get("display_name", "Unknown"))
		_hub_identity.text = _identity_line(c, species_id)
		
		_hub_dna_stat.text = PRESENTATION_TEXT.dna_status_line(species_id)
		
		var role: Dictionary = COMBAT_DATA.get_support_role(species_id)
		if role.is_empty():
			role = c.get("support_role", {})
		var trig_hint: String = String(role.get("hud_trigger_hint", "")).strip_edges()
		var readout: String = String(role.get("readout_name", c.get("display_name", ""))).strip_edges()
		if trig_hint.is_empty():
			_hub_support.text = readout
		else:
			_hub_support.text = "%s\n%s" % [readout, PRESENTATION_TEXT.support_trigger_line(trig_hint)]
		
		var bond_level: int = int(c.get("bond_level", 1))
		var stats: Dictionary = GameState.get_bond_level_stats_readout(bond_level)
		var pot: String = _get_potential_label_for_species(species_id)
		
		var cur_pct: int = int((stats.current_mult - 1.0) * 100.0)
		var next_pct: int = int((stats.next_mult - 1.0) * 100.0)
		
		var is_ascended = bool(c.get("is_ascended", false))
		var bond_text: String = "Bond depth %d %s · Potential %s\n" % [bond_level, "[ASCENDED]" if is_ascended else "", pot]
		bond_text += "Current Effect: +%d%%\n" % cur_pct
		if not stats.is_max:
			bond_text += "Next Level: +%d%%" % next_pct
		else:
			if not is_ascended:
				bond_text += "MAX LEVEL - READY FOR ASCENSION"
			else:
				bond_text += "SUPREME FORM REACHED"
		
		_hub_bond_pot.text = bond_text
	
	var player_dna_actual = GameState.get_dna(species_id)
	if _archive_mode:
		var has_trait = _archive_selected_trait_index >= 0 and _archive_selected_trait_index < _archive_trait_list.size()
		if has_trait:
			var tid = _archive_trait_list[_archive_selected_trait_index]
			var trait_data = CREATURE_TRAITS.get_trait(tid)
			_ranch_action_train.text = "S - Splice Trait (%d DNA)" % 250
			UI_STYLE.apply_label(_ranch_action_train, "mm_choice_bond" if player_dna_actual >= 250 else "mm_dim")
			_ranch_action_release.text = trait_data.get("display_name", tid).to_upper()
			UI_STYLE.apply_label(_ranch_action_release, "mm_stat_primary")
			_ranch_action_hint.text = trait_data.get("description", "")
		else:
			_ranch_action_train.text = "Select a trait (1-3) to splice"
			_ranch_action_release.text = ""
			_ranch_action_hint.text = ""
	else:
		var bond_level = int(c.get("bond_level", 1))
		var cost: int = GameState.get_lair_training_cost(species_id)
		var refund: int = GameState.get_lair_release_refund(species_id)
		
		_ranch_action_train.text = PRESENTATION_TEXT.LAIR_ACTION_TRAIN_LABEL
		if bond_level >= 5:
			var is_ascended = bool(c.get("is_ascended", false))
			if not is_ascended:
				_ranch_action_train.text = "A - Ascend (500 DNA)"
				UI_STYLE.apply_label(_ranch_action_train, "mm_choice_bond" if player_dna_actual >= 500 else "mm_dim")
			else:
				_ranch_action_train.text += " (SUPREME)"
				UI_STYLE.apply_label(_ranch_action_train, "mm_dim")
		else:
			var can_afford: bool = player_dna_actual >= cost
			_ranch_action_train.text += " - %d DNA" % cost
			UI_STYLE.apply_label(_ranch_action_train, "mm_choice_bond" if can_afford else "mm_choice_consume")
			if not can_afford:
				_ranch_action_train.add_theme_color_override("font_color", UI_STYLE.get_manga_color("blood_ember").lerp(Color.BLACK, 0.4))
			
		_ranch_action_release.text = PRESENTATION_TEXT.LAIR_ACTION_RELEASE_LABEL + " (+%d DNA)" % refund
		UI_STYLE.apply_label(_ranch_action_release, "mm_choice_consume")
		
		_ranch_action_hint.text = "Training deepens the bond. Ascension triggers Sovereign-scale growth."


func _build_archive_vitals(canvas: CanvasLayer) -> void:
	var v_panel := ColorRect.new()
	v_panel.color = UI_STYLE.get_manga_color("ink_black")
	v_panel.color.a = 0.82
	v_panel.position = Vector2(LIST_X, 558.0)
	v_panel.size = Vector2(LIST_W, 112.0)
	canvas.add_child(v_panel)
	
	var v_rim := ColorRect.new()
	v_rim.color = UI_STYLE.get_manga_color("blood_ember")
	v_rim.color.a = 0.4
	v_rim.position = Vector2(LIST_X, 558.0)
	v_rim.size = Vector2(LIST_W, 2.0)
	canvas.add_child(v_rim)
	
	var v_label := Label.new()
	v_label.text = "ARCHIVE VITALS"
	v_label.position = Vector2(LIST_X + 12.0, 532.0)
	v_label.size = Vector2(200.0, 24.0)
	UI_STYLE.apply_label(v_label, "mm_choice_bond")
	v_label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(v_label)
	
	var stats = [
		["stat_vitality", "FLESH"], ["stat_power", "MAW"], ["stat_carapace", "BONE"],
		["stat_endurance", "LUNG"], ["stat_swiftness", "NERVE"], ["stat_luck", "OMEN"],
		["stat_potential", "HOLLOW"], ["stat_intelligence", "EYE"], ["stat_adaptability", "FORM"]
	]
	
	var start_x = LIST_X + 24.0
	var start_y = 574.0
	var col_w = 200.0
	var row_h = 24.0
	
	for i in range(stats.size()):
		var col = floori(i / 3.0)
		var row = i % 3
		var s_data = stats[i]
		var s_key = s_data[0]
		# var s_name = s_data[1] # Unused but keeping for context
		
		var s_lab = Label.new()
		s_lab.position = Vector2(start_x + col * col_w, start_y + row * row_h)
		s_lab.size = Vector2(col_w - 20.0, row_h)
		UI_STYLE.apply_label(s_lab, "mm_body")
		s_lab.add_theme_font_size_override("font_size", 13)
		canvas.add_child(s_lab)
		_vitals_labels[s_key] = s_lab
		
	_bias_label = Label.new()
	_bias_label.position = Vector2(LIST_X + 600.0, 574.0)
	_bias_label.size = Vector2(210.0, 80.0)
	_bias_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_bias_label, "mm_caption")
	canvas.add_child(_bias_label)
	
	_refresh_archive_vitals()


func _refresh_archive_vitals() -> void:
	if _vitals_labels.is_empty():
		return
		
	var stats_map = {
		"stat_vitality": ["FLESH", GameState.stat_vitality],
		"stat_power": ["MAW", GameState.stat_power],
		"stat_carapace": ["BONE", GameState.stat_carapace],
		"stat_endurance": ["LUNG", GameState.stat_endurance],
		"stat_swiftness": ["NERVE", GameState.stat_swiftness],
		"stat_luck": ["OMEN", GameState.stat_luck],
		"stat_potential": ["HOLLOW", GameState.stat_potential],
		"stat_intelligence": ["EYE", GameState.stat_intelligence],
		"stat_adaptability": ["FORM", GameState.stat_adaptability]
	}
	
	for key in stats_map.keys():
		if _vitals_labels.has(key):
			var data = stats_map[key]
			_vitals_labels[key].text = "%s: %.1f" % [data[0], data[1]]
			
	if not is_instance_valid(_bias_label):
		return
		
	var lair: Array = GameState.lair_roster
	var has: bool = _selected_index >= 0 and _selected_index < lair.size()
	
	if not has:
		_bias_label.text = "GENETIC BIAS: NONE\n(Solo descent grants balanced growth)"
		return
		
	var c: Dictionary = lair[_selected_index]
	var p_type: String = String(c.get("primary_type", "")).to_lower()
	var s_type: String = String(c.get("secondary_type", "")).to_lower()
	
	var weights = {}
	var p_w = _growth_stats_ref.genetic_weights.get(p_type, {})
	var s_w = _growth_stats_ref.genetic_weights.get(s_type, {})
	
	for k in p_w.keys(): weights[k] = weights.get(k, 0) + p_w[k]
	for k in s_w.keys(): weights[k] = weights.get(k, 0) + s_w[k]
	
	if weights.is_empty():
		_bias_label.text = "GENETIC BIAS: STABLE"
	else:
		var bias_str = "GENETIC BIAS:\n"
		var sorted_keys = weights.keys()
		sorted_keys.sort_custom(func(a, b): return weights[a] > weights[b])
		
		var lines = []
		for k in sorted_keys:
			var lab = k.replace("stat_", "").to_upper()
			lines.append("%s (+%d)" % [lab, weights[k]])
		bias_str += " · ".join(lines)
		_bias_label.text = bias_str
