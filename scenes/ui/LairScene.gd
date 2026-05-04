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
const CREATURE_TRAITS = preload("res://data/CreatureTraitContent.gd")
const LAIR_RESONANCE = preload("res://data/LairResonanceContent.gd")
const HUD_PANEL_ART = preload("res://systems/HUDPanelArt.gd")
const LAIR_BACKGROUND_PATH: String = "res://assets/backgrounds/combat/Ruins_world.png"

var _creature_cards: Array[Panel] = []
var _card_accents: Array[ColorRect] = []
var _card_index_labels: Array[Label] = []
var _active_pills: Array[Label] = []
var _card_global_indices: Array[int] = []
var _selected_index: int = -1
var _page_start: int = 0
var _can_input: bool = false
var _breath_time: float = 0.0

var _ui_layer: CanvasLayer
var _hub_solo_label: Label
var _hub_name: Label
var _hub_identity: Label
var _hub_support: Label
var _hub_bond_pot: Label
var _hub_dna_stat: Label
var _hub_detail_scroll: ScrollContainer
var _hub_detail_box: VBoxContainer

var _lair_action_primary: Label
var _lair_action_status: Label
var _lair_action_detail_scroll: ScrollContainer
var _lair_action_detail: Label
var _bottom_hint: Label
var _feedback_label: Label

var _archive_mode: bool = false
var _archive_trait_list: Array[String] = []
var _archive_selected_trait_index: int = -1

var _translation_jitter: Node2D
var _jitter_intensity: float = 0.0


func _ready() -> void:
	_sync_selection_index()
	_archive_trait_list = GameState.archive_traits
	UI_STYLE.apply_mythical_entrance(self)

	_translation_jitter = Node2D.new()
	_translation_jitter.name = "TranslationJitter"
	add_child(_translation_jitter)
	
	_build_ui()
	_build_mythical_atmosphere()

	# Translation Burst: high jitter that decays to subtle 'intrusion' hum	_jitter_intensity = 8.0
	var tween := create_tween()
	tween.tween_property(self, "_jitter_intensity", 0.15, 1.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(0.12).timeout
	_can_input = true


func _process(delta: float) -> void:
	if not _can_input:
		return
	
	_breath_time += delta
	_update_breathing(_breath_time)
	
	# Translation Jitter: eerie intrusion offset
	if is_instance_valid(_ui_layer) and _jitter_intensity > 0.05:
		var offset := Vector2(
			randf_range(-_jitter_intensity, _jitter_intensity),
			randf_range(-_jitter_intensity, _jitter_intensity)
		)
		_ui_layer.offset = offset
		

func _sync_selection_index() -> void:
	_selected_index = -1
	if GameState.active_lair_creature_id.is_empty():
		return
	var lair: Array = GameState.lair_roster
	for i in range(lair.size()):
		if String(lair[i].get("species_id", "")) == GameState.active_lair_creature_id:
			_selected_index = i
			_page_start = int(floor(float(i) / float(MAX_LAIR_DISPLAY))) * MAX_LAIR_DISPLAY
			return


func _unhandled_input(event: InputEvent) -> void:
	if not _can_input:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_TAB:
		_archive_mode = not _archive_mode
		_build_ui()
		get_viewport().set_input_as_handled()
		return

	var lair: Array = GameState.lair_roster
	var display_count: int = min(lair.size() - _page_start, MAX_LAIR_DISPLAY)

	var index: int = -1
	match key_event.keycode:
		KEY_1: index = 0
		KEY_2: index = 1
		KEY_3: index = 2
		KEY_H:
			get_tree().change_scene_to_file("res://scenes/ui/HeartrootChamber.tscn")
			return

	if index >= 0:
		if _archive_mode:
			if index < _archive_trait_list.size():
				_archive_selected_trait_index = index
				_refresh_active_support_panel()
		else:
			var global_index: int = _page_start + index
			if index < display_count and global_index < lair.size():
				_selected_index = global_index
				var species_id: String = String(lair[global_index].get("species_id", ""))
				if not GameState.toggle_active_lair_creature(species_id):
					_play_feedback("SUPPORT SLOTS FULL (%d)" % GameState.get_support_slot_count())
				_refresh_card_highlights()
				_refresh_active_support_panel()
				_refresh_bottom_bar()
				_breath_time = 0.0
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_BRACKETLEFT and not _archive_mode:
		if _page_start > 0:
			_page_start = maxi(0, _page_start - MAX_LAIR_DISPLAY)
			_build_creature_list(_ui_layer, GameState.lair_roster)
			_refresh_bottom_bar()
			get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_BRACKETRIGHT and not _archive_mode:
		if _page_start + MAX_LAIR_DISPLAY < lair.size():
			_page_start += MAX_LAIR_DISPLAY
			_build_creature_list(_ui_layer, GameState.lair_roster)
			_refresh_bottom_bar()
			get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_T:
		get_tree().change_scene_to_file("res://scenes/ui/HeartrootChamber.tscn")
		get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_S and _archive_mode:
		if _selected_index >= 0 and _archive_selected_trait_index >= 0:
			var sid: String = String(lair[_selected_index].get("species_id", ""))
			var tid: String = _archive_trait_list[_archive_selected_trait_index]
			if GameState.splice_trait_to_creature(sid, tid):
				_play_feedback("TRAIT SPLICED")
				_jitter_intensity = 6.0
				var tween := create_tween()
				tween.tween_property(self, "_jitter_intensity", 0.05, 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
				_refresh_active_support_panel()
				_build_creature_list(_ui_layer, GameState.lair_roster)
			else:
				_play_feedback(_splice_status_line(sid, tid, Dictionary(lair[_selected_index])))
			get_viewport().set_input_as_handled()
			return

	if key_event.keycode == KEY_A:
		if _selected_index >= 0 and _selected_index < lair.size():
			_play_feedback("ASCENSION BELONGS IN HEARTROOT")
			get_viewport().set_input_as_handled()
			return

	if key_event.keycode == KEY_X:
		if _selected_index >= 0 and _selected_index < lair.size():
			_play_feedback("ARCHIVE BOND PERSISTS")
			get_viewport().set_input_as_handled()
			return

	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		if GameState.is_intro_bond_choice_pending():
			get_tree().change_scene_to_file(INTRO_BOND_SCENE_PATH)
			return
		
		GameState.start_new_run()
		get_tree().change_scene_to_file("res://scenes/ui/TranslationScene.tscn")
		return

	if key_event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)
		return


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


func _build_mythical_atmosphere() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "AtmosphereLayer"
	canvas.layer = -1 # Behind UI but above backdrop
	add_child(canvas)
	
	# --- MYTHICAL BACKGROUND (RUINS) ---
	if ResourceLoader.exists(LAIR_BACKGROUND_PATH):
		var bg_tex := load(LAIR_BACKGROUND_PATH) as Texture2D
		if bg_tex:
			var bg_rect := TextureRect.new()
			bg_rect.texture = bg_tex
			bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg_rect.size = Vector2(1280.0, 720.0)
			bg_rect.modulate = Color(0.35, 0.32, 0.42, 0.28) # Heavy desaturation and darkness
			canvas.add_child(bg_rect)
	
	# --- SPIRIT PARTICLES (DESATURATED DUST) ---
	var particles := CPUParticles2D.new()
	particles.name = "SpiritParticles"
	particles.position = Vector2(640.0, 360.0)
	particles.amount = 40
	particles.lifetime = 6.0
	particles.preprocess = 4.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(700.0, 400.0)
	particles.gravity = Vector2(0, -10.0)
	particles.direction = Vector2(1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 15.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	
	# Use desaturated purple from ruins
	particles.color = Color(0.65, 0.58, 0.72, 0.12)
	
	canvas.add_child(particles)
	
	# --- SOUL MIST (LOW DRIFT) ---
	var mist := CPUParticles2D.new()
	mist.name = "SoulMist"
	mist.position = Vector2(640.0, 700.0)
	mist.amount = 8
	mist.lifetime = 12.0
	mist.preprocess = 10.0
	mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mist.emission_rect_extents = Vector2(640.0, 20.0)
	mist.gravity = Vector2(2, -3.0)
	mist.initial_velocity_min = 10.0
	mist.initial_velocity_max = 20.0
	mist.scale_amount_min = 80.0
	mist.scale_amount_max = 140.0
	mist.color = Color(0.12, 0.08, 0.15, 0.18) # Dark violet mist
	canvas.add_child(mist)
	
	# --- VIGNETTE SHADOWS ---
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0,0,0,0), Color(0.02, 0.01, 0.03, 0.45)])
	grad.offsets = PackedFloat32Array([0.35, 1.0])
	
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.3, 1.3)
	
	var tr := TextureRect.new()
	tr.texture = gt
	tr.size = Vector2(1280.0, 720.0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tr)


func _build_ui() -> void:
	if is_instance_valid(_ui_layer):
		_ui_layer.queue_free()
	
	UI_STYLE.attach_wound_backdrop(self)

	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	_build_lair_living_map(_ui_layer)

	var header: Label = Label.new()
	header.text = "INTERFACE WOUND" if not _archive_mode else "THE ARCHIVE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(1280.0, 58.0)
	header.position = Vector2(0.0, 36.0)
	UI_STYLE.apply_label(header, "mm_title")
	header.add_theme_font_size_override("font_size", 42)
	_ui_layer.add_child(header)

	var sub: Label = Label.new()
	sub.text = PRESENTATION_TEXT.LAIR_SUBTITLE if not _archive_mode else "Extracted traits can be spliced into active sequences."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(960.0, 34.0)
	sub.position = Vector2(160.0, 88.0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(sub, "mm_subtitle")
	sub.add_theme_font_size_override("font_size", 18)
	_ui_layer.add_child(sub)

	var lair: Array = GameState.lair_roster
	if lair.is_empty():
		_build_empty_state(_ui_layer)
		_clear_hub_refs()
	else:
		_build_den_sidebar(_ui_layer, lair)
		_build_lair_room_spine(_ui_layer)
		_build_creature_list(_ui_layer, lair)

	_build_bottom_bar(_ui_layer, lair)
	
	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.size = Vector2(LIST_W, 40.0)
	_feedback_label.position = Vector2(LIST_X, 582.0)
	_feedback_label.modulate.a = 0.0
	_feedback_label.pivot_offset = Vector2(LIST_W * 0.5, 20.0)
	UI_STYLE.apply_label(_feedback_label, "mm_choice_bond")
	_ui_layer.add_child(_feedback_label)


func _clear_hub_refs() -> void:
	_hub_solo_label = null
	_hub_name = null
	_hub_identity = null
	_hub_support = null
	_hub_bond_pot = null
	_hub_dna_stat = null
	_hub_detail_scroll = null
	_hub_detail_box = null
	_lair_action_primary = null
	_lair_action_status = null
	_lair_action_detail_scroll = null
	_lair_action_detail = null
	_bottom_hint = null
	_feedback_label = null


func _build_empty_state(canvas: CanvasLayer) -> void:
	var empty_label: Label = Label.new()
	empty_label.text = PRESENTATION_TEXT.LAIR_EMPTY
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.size = Vector2(1280.0, 80.0)
	empty_label.position = Vector2(0.0, 305.0)
	UI_STYLE.apply_label(empty_label, "subheading")
	canvas.add_child(empty_label)


func _build_lair_room_spine(canvas: CanvasLayer) -> void:
	var rooms := [
		{"label": "LINEAGE", "role": "mm_apex", "active": not _archive_mode},
		{"label": "HEARTROOT", "role": "mm_command", "active": false},
		{"label": "ARCHIVE", "role": "mm_mutation", "active": _archive_mode},
		{"label": "SEALED", "role": "lair_card", "active": false}
	]
	var x: float = LIST_X
	var y: float = 122.0
	var w: float = 190.0
	var h: float = 26.0
	var gap: float = 10.0
	for i in range(rooms.size()):
		var room: Dictionary = rooms[i]
		var tab := Panel.new()
		tab.position = Vector2(x + float(i) * (w + gap), y)
		tab.size = Vector2(w, h)
		UI_STYLE.apply_shell_style(tab, String(room.get("role", "lair_card")))
		_apply_lair_vein_panel(tab, 0.24 if bool(room.get("active", false)) else 0.05, _room_accent_color(String(room.get("label", ""))))
		tab.modulate.a = 1.0 if bool(room.get("active", false)) else 0.54
		canvas.add_child(tab)

		var label := Label.new()
		label.text = String(room.get("label", ""))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(0.0, 0.0)
		label.size = tab.size
		UI_STYLE.apply_label(label, "mm_caption")
		label.add_theme_font_size_override("font_size", 14)
		tab.add_child(label)


func _apply_lair_vein_panel(panel: Control, pulse: float, color: Color) -> void:
	if panel == null:
		return
	var ink := UI_STYLE.get_manga_color("ink_black")
	HUD_PANEL_ART.apply_panel_art(panel, "", Rect2(), "LairVeinArt", "LairVeinBacking", Color(ink.r, ink.g, ink.b, 0.34))
	HUD_PANEL_ART.set_vein_color(panel, color, "LairVeinBacking")
	HUD_PANEL_ART.set_vein_pulse(panel, pulse, "LairVeinBacking")


func _room_accent_color(room_label: String) -> Color:
	match room_label:
		"LINEAGE":
			return UI_STYLE.get_manga_color("blood_ember")
		"HEARTROOT":
			return UI_STYLE.get_manga_color("bond_teal")
		"ARCHIVE":
			return UI_STYLE.get_manga_color("mutation_magenta")
		_:
			return UI_STYLE.get_manga_color("paper")


func _build_den_sidebar(canvas: CanvasLayer, lair: Array) -> void:
	var slab: Panel = Panel.new()
	slab.position = Vector2(SIDEBAR_X - 6.0, 112.0)
	slab.size = Vector2(SIDEBAR_W + 12.0, 532.0)
	UI_STYLE.apply_shell_style(slab, "lair_sidebar")
	_apply_lair_vein_panel(slab, 0.22, UI_STYLE.get_manga_color("blood_ember"))
	canvas.add_child(slab)

	var den: Label = Label.new()
	den.text = PRESENTATION_TEXT.LAIR_DEN_LABEL if not _archive_mode else "Extracted Traits"
	den.position = Vector2(SIDEBAR_X + 10.0, 124.0)
	den.size = Vector2(SIDEBAR_W - 20.0, 28.0)
	UI_STYLE.apply_label(den, "mm_choice_consume")
	den.add_theme_font_size_override("font_size", 17)
	canvas.add_child(den)

	var blurb: Label = Label.new()
	blurb.text = PRESENTATION_TEXT.LAIR_DEN_BLURB if not _archive_mode else "Select a trait to view its effect and splice it onto your active sequence."
	blurb.position = Vector2(SIDEBAR_X + 10.0, 152.0)
	blurb.size = Vector2(SIDEBAR_W - 20.0, 64.0)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(blurb, "mm_dim")
	blurb.add_theme_font_size_override("font_size", 15)
	canvas.add_child(blurb)

	if _archive_mode:
		_build_archive_trait_list_sidebar(canvas)
	else:
		var act_head: Label = Label.new()
		act_head.text = PRESENTATION_TEXT.LAIR_ACTIVE_HEAD
		act_head.position = Vector2(SIDEBAR_X + 10.0, 226.0)
		act_head.size = Vector2(SIDEBAR_W - 20.0, 26.0)
		UI_STYLE.apply_label(act_head, "mm_choice_bond")
		act_head.add_theme_font_size_override("font_size", 21)
		canvas.add_child(act_head)

		var panel: ColorRect = ColorRect.new()
		panel.color = UI_STYLE.get_manga_color("ink_black")
		panel.color.a = 0.88
		panel.position = Vector2(SIDEBAR_X + 8.0, 258.0)
		panel.size = Vector2(SIDEBAR_W - 16.0, 244.0)
		_apply_lair_vein_panel(panel, 0.10, UI_STYLE.get_manga_color("alert_gold"))
		canvas.add_child(panel)

		var inset: ColorRect = ColorRect.new()
		inset.color = UI_STYLE.get_manga_color("alert_gold")
		inset.color.a = 0.24
		inset.position = Vector2(SIDEBAR_X + 8.0, 258.0)
		inset.size = Vector2(3.0, 244.0)
		canvas.add_child(inset)

		_hub_solo_label = Label.new()
		_hub_solo_label.text = PRESENTATION_TEXT.LAIR_ACTIVE_SOLO
		_hub_solo_label.custom_minimum_size = Vector2(SIDEBAR_W - 52.0, 190.0)
		_hub_solo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_solo_label, "mm_body")
		_hub_solo_label.add_theme_font_size_override("font_size", 17)

		_hub_detail_scroll = ScrollContainer.new()
		_hub_detail_scroll.position = Vector2(SIDEBAR_X + 20.0, 270.0)
		_hub_detail_scroll.size = Vector2(SIDEBAR_W - 44.0, 218.0)
		_hub_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_hub_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_hub_detail_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		canvas.add_child(_hub_detail_scroll)

		_hub_detail_box = VBoxContainer.new()
		_hub_detail_box.position = Vector2.ZERO
		_hub_detail_box.custom_minimum_size.x = SIDEBAR_W - 52.0
		_hub_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_hub_detail_box.add_theme_constant_override("separation", 7)
		_hub_detail_scroll.add_child(_hub_detail_box)
		_hub_detail_box.add_child(_hub_solo_label)

		_hub_name = Label.new()
		_hub_name.custom_minimum_size = Vector2(SIDEBAR_W - 52.0, 34.0)
		_hub_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_name, "mm_stat_primary")
		_hub_name.add_theme_font_size_override("font_size", 22)
		_hub_detail_box.add_child(_hub_name)

		_hub_identity = Label.new()
		_hub_identity.custom_minimum_size = Vector2(SIDEBAR_W - 52.0, 22.0)
		_hub_identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_identity, "mm_dim")
		_hub_identity.add_theme_font_size_override("font_size", 15)
		_hub_detail_box.add_child(_hub_identity)
		
		_hub_dna_stat = Label.new()
		_hub_dna_stat.custom_minimum_size = Vector2(SIDEBAR_W - 52.0, 40.0)
		_hub_dna_stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_dna_stat, "mm_choice_bond")
		_hub_dna_stat.add_theme_font_size_override("font_size", 18)
		_hub_detail_box.add_child(_hub_dna_stat)

		_hub_support = Label.new()
		_hub_support.custom_minimum_size = Vector2(SIDEBAR_W - 52.0, 54.0)
		_hub_support.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_support, "mm_caption")
		_hub_support.add_theme_font_size_override("font_size", 15)
		_hub_detail_box.add_child(_hub_support)

		_hub_bond_pot = Label.new()
		_hub_bond_pot.custom_minimum_size = Vector2(SIDEBAR_W - 52.0, 84.0)
		_hub_bond_pot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(_hub_bond_pot, "mm_stat_secondary")
		_hub_bond_pot.add_theme_font_size_override("font_size", 16)
		_hub_detail_box.add_child(_hub_bond_pot)

	_lair_action_primary = Label.new()
	_lair_action_primary.position = Vector2(SIDEBAR_X + 18.0, 508.0)
	_lair_action_primary.size = Vector2(SIDEBAR_W - 44.0, 30.0)
	UI_STYLE.apply_label(_lair_action_primary, "mm_caption")
	_lair_action_primary.add_theme_font_size_override("font_size", 16)
	canvas.add_child(_lair_action_primary)

	_lair_action_status = Label.new()
	_lair_action_status.position = Vector2(SIDEBAR_X + 18.0, 540.0)
	_lair_action_status.size = Vector2(SIDEBAR_W - 44.0, 30.0)
	UI_STYLE.apply_label(_lair_action_status, "mm_caption")
	_lair_action_status.add_theme_font_size_override("font_size", 16)
	canvas.add_child(_lair_action_status)

	_lair_action_detail_scroll = ScrollContainer.new()
	_lair_action_detail_scroll.position = Vector2(SIDEBAR_X + 18.0, 572.0)
	_lair_action_detail_scroll.size = Vector2(SIDEBAR_W - 44.0, 70.0)
	_lair_action_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_lair_action_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_lair_action_detail_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_lair_scroll_gutter(_lair_action_detail_scroll, UI_STYLE.get_manga_color("bond_teal"))
	canvas.add_child(_lair_action_detail_scroll)

	_lair_action_detail = Label.new()
	_lair_action_detail.position = Vector2.ZERO
	_lair_action_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lair_action_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI_STYLE.apply_label(_lair_action_detail, "mm_dim")
	_lair_action_detail.add_theme_font_size_override("font_size", 15)
	_lair_action_detail_scroll.add_child(_lair_action_detail)

	_refresh_active_support_panel()


func _build_lair_living_map(canvas: CanvasLayer) -> void:
	var map := Node2D.new()
	map.name = "LairLivingMap"
	canvas.add_child(map)

	var floor_shadow := Polygon2D.new()
	floor_shadow.polygon = PackedVector2Array([
		Vector2(58.0, 672.0),
		Vector2(146.0, 574.0),
		Vector2(330.0, 530.0),
		Vector2(498.0, 552.0),
		Vector2(686.0, 504.0),
		Vector2(906.0, 526.0),
		Vector2(1190.0, 458.0),
		Vector2(1238.0, 662.0)
	])
	floor_shadow.color = Color(UI_STYLE.get_manga_color("ink_black"), 0.42)
	map.add_child(floor_shadow)

	_add_lair_root_line(map, PackedVector2Array([
		Vector2(198.0, 628.0), Vector2(326.0, 570.0), Vector2(424.0, 456.0),
		Vector2(608.0, 414.0), Vector2(844.0, 386.0), Vector2(1166.0, 318.0)
	]), Color(UI_STYLE.get_manga_color("blood_ember"), 0.20), 6.0)
	_add_lair_root_line(map, PackedVector2Array([
		Vector2(186.0, 168.0), Vector2(344.0, 254.0), Vector2(492.0, 286.0),
		Vector2(692.0, 256.0), Vector2(1014.0, 178.0), Vector2(1230.0, 222.0)
	]), Color(UI_STYLE.get_manga_color("bond_teal"), 0.15), 3.0)
	_add_lair_root_line(map, PackedVector2Array([
		Vector2(758.0, 132.0), Vector2(706.0, 254.0), Vector2(678.0, 410.0),
		Vector2(710.0, 570.0), Vector2(754.0, 690.0)
	]), Color(UI_STYLE.get_manga_color("mutation_magenta"), 0.13), 3.0)

	var rooms := [
		{"name": "LINEAGE", "pos": Vector2(412.0, 320.0), "size": Vector2(170.0, 60.0), "color": UI_STYLE.get_manga_color("blood_ember")},
		{"name": "HEARTROOT", "pos": Vector2(620.0, 278.0), "size": Vector2(190.0, 72.0), "color": UI_STYLE.get_manga_color("bond_teal")},
		{"name": "ARCHIVE", "pos": Vector2(856.0, 330.0), "size": Vector2(160.0, 58.0), "color": UI_STYLE.get_manga_color("mutation_magenta")},
		{"name": "SEALED", "pos": Vector2(1042.0, 250.0), "size": Vector2(132.0, 46.0), "color": UI_STYLE.get_manga_color("paper")}
	]
	for room in rooms:
		var room_name: String = String(room.get("name", ""))
		var room_pos: Vector2 = room.get("pos", Vector2.ZERO)
		var room_size: Vector2 = room.get("size", Vector2.ZERO)
		var room_color: Color = room.get("color", UI_STYLE.get_manga_color("paper"))
		var glow := ColorRect.new()
		glow.position = room_pos
		glow.size = room_size
		var c: Color = room_color
		c.a = 0.075 if room_name != "SEALED" else 0.035
		glow.color = c
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(glow)

		var rim := ColorRect.new()
		rim.position = room_pos
		rim.size = Vector2(room_size.x, 2.0)
		var rc: Color = room_color
		rc.a = 0.20
		rim.color = rc
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(rim)


func _add_lair_root_line(parent: Node, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(line)


func _apply_lair_scroll_gutter(scroll: ScrollContainer, color: Color) -> void:
	if scroll == null:
		return
	var gutter := ColorRect.new()
	gutter.name = "ScrollRootGutter"
	gutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gutter.position = Vector2(scroll.size.x - 4.0, 0.0)
	gutter.size = Vector2(2.0, scroll.size.y)
	var c := color
	c.a = 0.20
	gutter.color = c
	scroll.add_child(gutter)
	scroll.move_child(gutter, 0)


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
	_card_global_indices.clear()

	var card_width: float = LIST_W
	var card_height: float = 138.0
	var card_gap: float = 8.0
	var card_x: float = LIST_X
	var list_start_y: float = 158.0

	_page_start = clampi(_page_start, 0, maxi(lair.size() - 1, 0))
	_page_start = int(floor(float(_page_start) / float(MAX_LAIR_DISPLAY))) * MAX_LAIR_DISPLAY
	var count: int = min(lair.size() - _page_start, MAX_LAIR_DISPLAY)
	for i in range(count):
		var global_index: int = _page_start + i
		var card_y: float = list_start_y + i * (card_height + card_gap)
		_build_creature_card(canvas, lair[global_index], i, card_x, card_y, card_width, card_height)
		_card_global_indices.append(global_index)

	_refresh_card_highlights()


func _build_creature_card(canvas: CanvasLayer, creature: Dictionary, index: int, x: float, y: float, w: float, h: float) -> void:
	var card: Panel = Panel.new()
	card.size = Vector2(w, h)
	card.position = Vector2(x, y)
	UI_STYLE.apply_shell_style(card, "lair_card")
	_apply_lair_vein_panel(card, 0.05, UI_STYLE.get_manga_color("blood_ember"))
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
	name_label.add_theme_font_size_override("font_size", 24)
	card.add_child(name_label)

	var id_label: Label = Label.new()
	id_label.text = _identity_line(creature, species_id)
	id_label.position = Vector2(50.0, 44.0)
	id_label.size = Vector2(w - 90.0, 22.0)
	UI_STYLE.apply_label(id_label, "mm_dim")
	id_label.add_theme_font_size_override("font_size", 16)
	card.add_child(id_label)

	var bond_level: int = int(creature.get("bond_level", 1))
	var potential_label: String = _get_potential_label_for_species(species_id)
	var bl_label: Label = Label.new()
	bl_label.text = "Bond %d  ·  Potential cap %s" % [bond_level, potential_label]
	bl_label.position = Vector2(50.0, 68.0)
	bl_label.size = Vector2(w - 100.0, 22.0)
	UI_STYLE.apply_label(bl_label, "mm_stat_secondary")
	bl_label.add_theme_font_size_override("font_size", 18)
	card.add_child(bl_label)

	var support_line: String = _support_one_liner(creature, species_id)
	if not support_line.is_empty():
		var sup_label: Label = Label.new()
		sup_label.text = support_line
		sup_label.position = Vector2(50.0, 94.0)
		sup_label.size = Vector2(w - 100.0, 22.0)
		UI_STYLE.apply_label(sup_label, "mm_caption")
		sup_label.add_theme_font_size_override("font_size", 16)
		card.add_child(sup_label)

	var desc: String = String(creature.get("description", ""))
	if not desc.is_empty():
		var desc_scroll := ScrollContainer.new()
		desc_scroll.position = Vector2(50.0, 118.0)
		desc_scroll.size = Vector2(w - 70.0, 18.0)
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
		desc_label.add_theme_font_size_override("font_size", 15)
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
	note.size = Vector2(LIST_W, 30.0)
	note.position = Vector2(LIST_X, 612.0)
	UI_STYLE.apply_label(note, "mm_dim")
	canvas.add_child(note)

	_bottom_hint = Label.new()
	_bottom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bottom_hint.size = Vector2(1280.0, 28.0)
	_bottom_hint.position = Vector2(0.0, 652.0)
	UI_STYLE.apply_label(_bottom_hint, "mm_hint")
	_bottom_hint.add_theme_font_size_override("font_size", 17)
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
		var page_count: int = int(ceil(float(lair.size()) / float(MAX_LAIR_DISPLAY)))
		var cur_page: int = int(floor(float(_page_start) / float(MAX_LAIR_DISPLAY))) + 1
		hint_text = "1/2/3 — toggle support (%d slots)  |  [/] page %d/%d  |  TAB archive  |  H heartroot  |  ENTER continue" % [
			GameState.get_support_slot_count(),
			cur_page,
			maxi(page_count, 1)
		]

	_bottom_hint.text = hint_text


func _refresh_card_highlights() -> void:
	for i in range(_creature_cards.size()):
		if not is_instance_valid(_creature_cards[i]):
			continue
		var global_index: int = _card_global_indices[i] if i < _card_global_indices.size() else i
		var lair: Array = GameState.lair_roster
		var species_id: String = ""
		if global_index >= 0 and global_index < lair.size():
			species_id = String(lair[global_index].get("species_id", ""))
		var is_selected: bool = GameState.active_lair_creature_ids.has(species_id)

		if is_selected:
			UI_STYLE.apply_shell_style(_creature_cards[i], "mm_apex")
			_apply_lair_vein_panel(_creature_cards[i], 0.42, UI_STYLE.get_manga_color("blood_ember"))
		else:
			UI_STYLE.apply_shell_style(_creature_cards[i], "lair_card")
			_apply_lair_vein_panel(_creature_cards[i], 0.06, UI_STYLE.get_manga_color("paper"))

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
	
	_lair_action_primary.visible = has
	_lair_action_status.visible = has
	_lair_action_detail_scroll.visible = has
	_lair_action_detail.visible = has
	
	if not has:
		return
	var c: Dictionary = lair[_selected_index]
	var species_id: String = String(c.get("species_id", ""))
	
	if not _archive_mode:
		_hub_name.text = String(c.get("display_name", "Unknown"))
		_fit_label_to_bounds(_hub_name)
		_hub_identity.text = _identity_line(c, species_id)
		_fit_label_to_bounds(_hub_identity)
		
		_hub_dna_stat.text = PRESENTATION_TEXT.dna_status_line(species_id)
		_fit_label_to_bounds(_hub_dna_stat)
		
		var role: Dictionary = COMBAT_DATA.get_support_role(species_id)
		if role.is_empty():
			role = c.get("support_role", {})
		var trig_hint: String = String(role.get("hud_trigger_hint", "")).strip_edges()
		var readout: String = String(role.get("readout_name", c.get("display_name", ""))).strip_edges()
		if trig_hint.is_empty():
			_hub_support.text = readout
		else:
			_hub_support.text = "%s\n%s" % [readout, PRESENTATION_TEXT.support_trigger_line(trig_hint)]
		_fit_label_to_bounds(_hub_support)
		
		var bond_level: int = int(c.get("bond_level", 1))
		var stats: Dictionary = GameState.get_bond_level_stats_readout(bond_level)
		var pot: String = _get_potential_label_for_species(species_id)
		
		var cur_pct: int = int((stats.current_mult - 1.0) * 100.0)
		var next_pct: int = int((stats.next_mult - 1.0) * 100.0)
		
		var is_ascended = bool(c.get("is_ascended", false))
		var bond_text: String = "Sequence %d %s · Potential %s\n" % [bond_level, "[ASCENDED]" if is_ascended else "", pot]
		bond_text += "Now +%d%%\n" % cur_pct
		if not stats.is_max:
			bond_text += "Next +%d%% in Heartroot" % next_pct
		else:
			if not is_ascended:
				bond_text += "Heartroot ascension ready"
			else:
				bond_text += "Sovereign form reached"
		
		_hub_bond_pot.text = bond_text
		_fit_label_to_bounds(_hub_bond_pot)
	
	var player_dna_actual = GameState.get_dna(species_id)
	if _archive_mode:
		var has_trait = _archive_selected_trait_index >= 0 and _archive_selected_trait_index < _archive_trait_list.size()
		if has_trait:
			var tid = _archive_trait_list[_archive_selected_trait_index]
			var trait_data = CREATURE_TRAITS.get_trait(tid)
			var splice_cost: float = _trait_splicing_cost(species_id)
			var already_spliced: bool = Array(c.get("spliced_traits", [])).has(tid)
			_lair_action_primary.text = "S - Splice Trait (%.0f DNA)" % splice_cost
			if already_spliced:
				_lair_action_primary.text = "S - Trait already spliced"
			UI_STYLE.apply_label(_lair_action_primary, "mm_choice_bond" if player_dna_actual >= splice_cost and not already_spliced else "mm_dim")
			_lair_action_status.text = trait_data.get("display_name", tid).to_upper()
			UI_STYLE.apply_label(_lair_action_status, "mm_stat_primary")
			_set_lair_action_detail_text(_trait_archive_detail(tid, species_id, c))
		else:
			_lair_action_primary.text = "Select a trait (1-3) to splice"
			_lair_action_status.text = ""
			_set_lair_action_detail_text("")
	else:
		_lair_action_primary.text = PRESENTATION_TEXT.LAIR_ACTION_TRAIN_LABEL
		UI_STYLE.apply_label(_lair_action_primary, "mm_choice_bond")
		_lair_action_status.text = PRESENTATION_TEXT.LAIR_ACTION_TETHER_LOCKED
		UI_STYLE.apply_label(_lair_action_status, "mm_dim")
		
		_set_lair_action_detail_text(_lair_selected_creature_detail(species_id, c))


func _trait_splicing_cost(species_id: String) -> float:
	return GameState.get_trait_splicing_cost(species_id)


func _set_lair_action_detail_text(text: String) -> void:
	if not is_instance_valid(_lair_action_detail) or not is_instance_valid(_lair_action_detail_scroll):
		return
	_lair_action_detail.text = text
	var inner_w: float = maxf(1.0, _lair_action_detail_scroll.size.x - 6.0)
	_lair_action_detail.custom_minimum_size.x = inner_w
	var content_h: float = _lair_action_detail.get_minimum_size().y
	_lair_action_detail.custom_minimum_size.y = maxf(_lair_action_detail_scroll.size.y, content_h)


func _fit_label_to_bounds(label: Label) -> void:
	if not is_instance_valid(label):
		return
	label.custom_minimum_size.x = maxf(1.0, label.size.x)


func _get_ascension_status(species_id: String) -> Dictionary:
	return GameState.get_ascension_status(species_id)


func _ascension_status_line(species_id: String) -> String:
	var status: Dictionary = _get_ascension_status(species_id)
	return str(status.get("reason", "ASCENSION DENIED")).to_upper()


func _splice_status_line(species_id: String, trait_id: String, creature: Dictionary) -> String:
	if trait_id.is_empty():
		return "SELECT A TRAIT"
	if Array(creature.get("spliced_traits", [])).has(trait_id):
		return "TRAIT ALREADY SPLICED"
	var cost: float = _trait_splicing_cost(species_id)
	var current_dna: float = GameState.get_dna(species_id)
	if current_dna < cost:
		return "NEED %.0f MORE DNA" % (cost - current_dna)
	return "SPLICE DENIED"


func _creature_display_name(species_id: String) -> String:
	if species_id.is_empty():
		return "unknown"
	var creature_data: Dictionary = COMBAT_DATA.get_creature(species_id)
	if creature_data.is_empty():
		return species_id
	return str(creature_data.get("display_name", species_id))


func _lair_selected_creature_detail(species_id: String, creature: Dictionary) -> String:
	var lines: Array[String] = []
	var resonance: Dictionary = GameState.get_current_resonance_perk()
	var resonance_name: String = str(resonance.get("display_name", "Unclaimed Resonance"))
	var current_fate: String = GameState.world_dominant_fate.replace("_", " ").capitalize()
	lines.append(PRESENTATION_TEXT.LAIR_ACTION_TETHER_HINT)
	lines.append("Resonance  |  %s (%s)" % [resonance_name, current_fate])
	var spliced: Array = Array(creature.get("spliced_traits", []))
	if spliced.is_empty():
		lines.append("Splices  |  none")
	else:
		var trait_names: Array[String] = []
		for trait_id in spliced:
			var trait_data: Dictionary = CREATURE_TRAITS.get_trait(str(trait_id))
			trait_names.append(str(trait_data.get("display_name", trait_id)))
		lines.append("Splices  |  " + ", ".join(PackedStringArray(trait_names)))
	var status: Dictionary = _get_ascension_status(species_id)
	var required_fate: String = str(status.get("required_fate", "unclaimed")).replace("_", " ").capitalize()
	var mastery: Dictionary = Dictionary(status.get("mastery", {}))
	var mastery_title: String = str(mastery.get("title", "Unknown Mastery"))
	var mastery_desc: String = str(mastery.get("description", "No mastery record yet."))
	lines.append("Gate  |  %s" % str(status.get("reason", "Unknown")))
	lines.append("Need  |  Bond 5, %.0f DNA, %s" % [float(status.get("cost", LAIR_RESONANCE.ASCENSION_DNA_COST)), required_fate])
	lines.append("Mastery  |  %s: %s" % [mastery_title, mastery_desc])
	return _compact_lair_detail(lines, 4)


func _trait_archive_detail(trait_id: String, species_id: String, creature: Dictionary) -> String:
	var trait_data: Dictionary = CREATURE_TRAITS.get_trait(trait_id)
	var lines: Array[String] = []
	lines.append(str(trait_data.get("description", "")))
	var synergy: String = str(trait_data.get("synergy_bonus", "")).strip_edges()
	if not synergy.is_empty():
		lines.append("Synergy  |  " + synergy)
	var cost: float = _trait_splicing_cost(species_id)
	lines.append("Cost  |  %.0f %s DNA" % [cost, _creature_display_name(species_id)])
	if Array(creature.get("spliced_traits", [])).has(trait_id):
		lines.append("Status  |  already inside this sequence")
	else:
		lines.append("Status  |  %s" % ("ready" if GameState.get_dna(species_id) >= cost else "needs more lineage DNA"))
	return _compact_lair_detail(lines, 4)


func _compact_lair_detail(lines: Array[String], max_lines: int) -> String:
	if lines.size() <= max_lines:
		return "\n".join(PackedStringArray(lines))
	var kept: Array[String] = []
	for i in range(maxi(max_lines - 1, 0)):
		kept.append(lines[i])
	kept.append("+%d more detail in this sequence." % (lines.size() - kept.size()))
	return "\n".join(PackedStringArray(kept))
