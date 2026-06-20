extends RefCounted
class_name CombatUIBuilder

var scene: Node

var _hud_top_left_container: VBoxContainer
var _hud_top_left_panel: Control
var _hud_top_right_container: VBoxContainer
var _hud_top_right_panel: PanelContainer
var _hud_top_right_accent_host: Control
var _hud_right_stack: VBoxContainer
var _hud_bottom_container: HBoxContainer
var _hud_root: Control
var _hud_decor_layer: Control
var _hud_primary_layer: Control
var _hud_secondary_layer: Control
var _hud_overlay_layer: Control
var _timing_circle_container: Node2D
var _attack_fx_container: Node2D
var _combo_shell: ColorRect
var _style_shell: ColorRect
var _resource_shell: ColorRect
var _support_shell: ColorRect
var _support_bar: ProgressBar
var _support_value_label: Label
var _support_name_label: Label
var _run_build_shell: ColorRect
var _eaten_value_label: Label
var _upgrade_value_label: Label
var _bond_value_label: Label
var _support_trigger_label: Label
var _atk_value_label: Label
var _def_value_label: Label
var _hp_value_label: Label
var _exp_value_label: Label
var _dna_route_label: Label
var _dna_route_shell: ColorRect
var _mutation_value_label: Label
var _run_score_label: Label
var _dna_shell: ColorRect
var _dna_emblem: TextureRect
var _hud_presenter: RefCounted
var _scouter_shell: Panel
var _power_scouter_label: Label
var _reward_overlay: ColorRect
var _reward_wrapper_shell: PanelContainer
var _reward_panel: ColorRect
var _reward_title_label: Label
var _reward_body_label: Label
var _reward_quig_label: Label
var _reward_quig_sprite: TextureRect
var _reward_hint_label: Label
var _reward_bond_card: ColorRect
var _reward_eat_card: ColorRect
var _reward_bond_label: Label
var _reward_dna_label: Label
var _reward_eat_label: Label
var _reward_bond_effect_label: Label
var _reward_eat_effect_label: Label
var _reward_creature_tag_label: Label
var _reward_creature_portrait: TextureRect
var _reward_body_scroll: ScrollContainer
var _reward_bond_effect_scroll: ScrollContainer
var _reward_eat_effect_scroll: ScrollContainer
var _upgrade_overlay: ColorRect
var _upgrade_panel: ColorRect
var _live_reward_shell: PanelContainer
var _live_reward_title_label: Label
var _live_reward_body_label: Label
var _live_reward_dna_label: Label
var _live_reward_hint_label: Label
var _reward_choice_made: bool
var _live_reward_offer_timer: float
var _boss_hp_shell: ColorRect
var _boss_hp_bar: ProgressBar
var _boss_name_label: Label
var _boss_state_label: Label
var _song_timer_label: Label
var _song_phase_label: Label
var _beat_feedback_label: Label
var ui_layer: CanvasLayer
var combo_label: Label
var style_label: Label
var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var ultimate_label: Label
var controls_label: Label
var flash_overlay: ColorRect
var _feedback_shell: RefCounted
var _title_card: Control
var _subtitle_card: Control
var _timing_rings_cache: Array[Dictionary]
var _upgrade_card_nodes: Array
var result_label: Label
var _end_stats_label: Label
var PRESENTATION_TEXT: GDScript:
	get: return scene.PRESENTATION_TEXT
	set(v): scene.PRESENTATION_TEXT = v
var HUD_PANEL_ART: GDScript:
	get: return scene.HUD_PANEL_ART
	set(v): scene.HUD_PANEL_ART = v
var combat_meter: Node
var COMBAT_METER_SCRIPT: GDScript:
	get: return scene.COMBAT_METER_SCRIPT
	set(v): scene.COMBAT_METER_SCRIPT = v
var _bonded_creature_sprite: Sprite2D
var _quig_shell: Control
var _quig_anchor_sprite: TextureRect
var _timing_debug_label: Label
var _quig_anchor_label: Label
var _dna_slot_labels: Array
var DNA_HUD_VISIBLE_SLOTS: int:
	get: return scene.DNA_HUD_VISIBLE_SLOTS
	set(v): scene.DNA_HUD_VISIBLE_SLOTS = v
var UI_STYLE: GDScript:
	get: return scene.UI_STYLE
var COMBAT_FEEL_CONTENT: GDScript:
	get: return scene.COMBAT_FEEL_CONTENT
var _presentation_controller: Node
var COMBAT_HUD_ROOT_SCENE: PackedScene:
	get: return scene.COMBAT_HUD_ROOT_SCENE
var LIVE_REWARD_WINDOW: float:
	get: return scene.LIVE_REWARD_WINDOW
var IMPACT_FX_RUNTIME_SCENE: PackedScene:
	get: return scene.IMPACT_FX_RUNTIME_SCENE

func build_all() -> void:
	_build_dna_shell()
	_build_hud_containers()
	_build_meter_shell()
	_build_quig_anchor()
	_build_song_hud()
	_create_attack_fx_container()
	_create_feedback_label()
	_create_impact_fx_runtime()
	_create_live_reward_shell()
	_create_reward_overlay()
	_create_timing_circle_container()
	_create_title_cards()
	_create_upgrade_overlay()
	_ensure_hud_root()
	_setup_ui()

func _ensure_hud_root() -> void:
	if _hud_root != null and is_instance_valid(_hud_root):
		return
	if COMBAT_HUD_ROOT_SCENE == null:
		return
	var inst: Node = COMBAT_HUD_ROOT_SCENE.instantiate()
	if inst == null or not (inst is Control):
		if inst != null:
			inst.queue_free()
		return
	_hud_root = inst as Control
	_hud_root.name = "CombatHudRoot"
	ui_layer.add_child(_hud_root)
	_hud_decor_layer = _hud_root.get_node_or_null("DecorLayer") as Control
	_hud_primary_layer = _hud_root.get_node_or_null("PrimaryLayer") as Control
	_hud_secondary_layer = _hud_root.get_node_or_null("SecondaryLayer") as Control
	_hud_overlay_layer = _hud_root.get_node_or_null("OverlayLayer") as Control


func _setup_ui() -> void:
	ui_layer = scene.get_node("UI")
	combo_label = scene.get_node("UI/ComboLabel")
	style_label = scene.get_node("UI/StyleLabel")
	hp_bar = scene.get_node("UI/HPBar")
	stamina_bar = scene.get_node("UI/StaminaBar")
	ultimate_label = scene.get_node("UI/UltimateLabel")
	controls_label = scene.get_node("UI/ControlsLabel")
	result_label = scene.get_node("UI/ResultLabel")
	flash_overlay = scene.get_node("FlashOverlay")
	combat_meter = scene.get_node("CombatMeter")

	_build_hud_containers()
	_build_meter_shell()
	combo_label.reparent(_hud_top_right_container)
	combo_label.text = "0"
	combo_label.visible = false # Hidden in favor of performance HUD
	combo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(combo_label, "hud_metric_value", HORIZONTAL_ALIGNMENT_RIGHT)
	combo_label.add_theme_font_size_override("font_size", 26)

	style_label.reparent(_hud_top_right_container)
	style_label.text = "Stirring"
	style_label.visible = false # Hidden in favor of performance HUD
	style_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(style_label, "hud_meta", HORIZONTAL_ALIGNMENT_RIGHT)
	style_label.add_theme_font_size_override("font_size", 15)

	var hp_row := HBoxContainer.new()
	hp_row.name = "HpRow"
	hp_row.custom_minimum_size = Vector2(0.0, 22.0)
	hp_row.add_theme_constant_override("separation", 6)
	_hud_top_left_container.add_child(hp_row)

	var hp_caption := Label.new()
	hp_caption.text = "Health"
	hp_caption.custom_minimum_size = Vector2(64.0, 0.0)
	_presentation_controller.apply_text_role(hp_caption, "hud_metric_title")
	hp_caption.add_theme_font_size_override("font_size", 14)
	hp_row.add_child(hp_caption)

	_hp_value_label = Label.new()
	_hp_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(_hp_value_label, "hud_metric_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_value_label.add_theme_font_size_override("font_size", 22)
	hp_row.add_child(_hp_value_label)

	hp_bar.reparent(_hud_top_left_container)
	hp_bar.min_value = 0.0
	hp_bar.max_value = PlayerState.max_hp
	hp_bar.value = PlayerState.hp
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(0.0, 14.0)
	hp_bar.show_percentage = false

	var stamina_row := HBoxContainer.new()
	stamina_row.name = "StaminaRow"
	stamina_row.custom_minimum_size = Vector2(0.0, 22.0)
	stamina_row.add_theme_constant_override("separation", 6)
	_hud_top_left_container.add_child(stamina_row)

	var stamina_caption := Label.new()
	stamina_caption.text = "Stamina"
	stamina_caption.custom_minimum_size = Vector2(64.0, 0.0)
	_presentation_controller.apply_text_role(stamina_caption, "hud_metric_title")
	stamina_caption.add_theme_font_size_override("font_size", 14)
	stamina_row.add_child(stamina_caption)

	stamina_bar.reparent(stamina_row)
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	stamina_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamina_bar.custom_minimum_size = Vector2(0.0, 11.0)
	stamina_bar.show_percentage = false

	# Dedicated Biomass Power Scouter (Diegetic Element)
	_scouter_shell = Panel.new()
	_scouter_shell.name = "ScouterShell"
	_scouter_shell.custom_minimum_size = Vector2(210.0, 32.0)
	UI_STYLE.apply_shell_style(_scouter_shell, "hud_accent")
	_hud_top_left_container.add_child(_scouter_shell)

	_power_scouter_label = Label.new()
	_power_scouter_label.name = "PowerScouterLabel"
	_power_scouter_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_power_scouter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power_scouter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_presentation_controller.apply_text_role(_power_scouter_label, "scouter")
	_power_scouter_label.text = "POWER LEVEL: 0"
	_scouter_shell.add_child(_power_scouter_label)

	ultimate_label.reparent(_hud_top_right_container)
	ultimate_label.text = "0%"
	ultimate_label.visible = false # Hidden in favor of performance HUD
	ultimate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(ultimate_label, "hud_meta", HORIZONTAL_ALIGNMENT_RIGHT)
	ultimate_label.add_theme_font_size_override("font_size", 16)	
	result_label.visible = false
	result_label.text = ""
	result_label.position = Vector2(320.0, 290.0)
	result_label.size = Vector2(640.0, 72.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	controls_label.visible = false # Hidden in favor of performance HUD framing
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_presentation_controller.apply_text_role(result_label, "screen_title")

	_end_stats_label = Label.new()
	_end_stats_label.name = "EndStatsLabel"
	_end_stats_label.position = Vector2(380.0, 370.0)
	_end_stats_label.size = Vector2(520.0, 160.0)
	_end_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end_stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_end_stats_label.visible = false
	_presentation_controller.apply_text_role(_end_stats_label, "secondary_value")
	_end_stats_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(_end_stats_label)

	controls_label.reparent(_hud_bottom_container)
	controls_label.text = PRESENTATION_TEXT.COMBAT_CONTROLS
	controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(controls_label, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	controls_label.add_theme_font_size_override("font_size", 16)

	_build_quig_anchor()
	_build_dna_shell()
	_build_song_hud()
	var stats_row_node: Node = _hud_top_left_container.get_node_or_null("StatsRow")
	if stats_row_node != null:
		_hud_top_left_container.move_child(stats_row_node, _hud_top_left_container.get_child_count() - 1)


func _hud_attach_combat_panel_art(panel: Control, texture_path: String, region: Rect2) -> void:
	HUD_PANEL_ART.apply_panel_art(panel, texture_path, region)


func _apply_wrapper_safe_zone(body: MarginContainer, safe_margin: Vector4, fallback_margin: Vector4) -> void:
	var margins: Vector4 = fallback_margin
	if safe_margin != Vector4.ZERO:
		margins = safe_margin
	body.offset_left = margins.x
	body.offset_top = margins.y
	body.offset_right = -margins.z
	body.offset_bottom = -margins.w


func _safe_inner_width(outer_width: float, margin: Vector4, fallback_margin: Vector4, min_width: float = 32.0) -> float:
	var margins: Vector4 = fallback_margin
	if margin != Vector4.ZERO:
		margins = margin
	return maxf(min_width, outer_width - margins.x - margins.z)


func _build_hud_containers() -> void:
	var hud_m: float = COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN
	var hud_ty: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y
	var hud_th: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_HEIGHT
	var hud_tl_w: float = COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH
	var hud_tr_w: float = COMBAT_FEEL_CONTENT.HUD_TOP_RIGHT_PANEL_WIDTH
	var right_stack_min_h: float = COMBAT_FEEL_CONTENT.HUD_RIGHT_STACK_MIN_HEIGHT
	var tr_height: float = hud_th + COMBAT_FEEL_CONTENT.HUD_GAP_BELOW_TOP_BAND + right_stack_min_h
	# Top Left Stack
	var tl_panel := Panel.new()
	_hud_top_left_panel = tl_panel
	tl_panel.name = "TopLeftPanel"
	tl_panel.z_index = 40
	tl_panel.clip_contents = true
	tl_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tl_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tl_panel.position = Vector2(hud_m, hud_ty)
	tl_panel.size = Vector2(hud_tl_w, hud_th)
	tl_panel.custom_minimum_size = Vector2(hud_tl_w, hud_th)
	var tl_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_top_left_panel_path()
	if tl_tex.is_empty():
		UI_STYLE.apply_shell_style(tl_panel, "hud_left", "")
	else:
		UI_STYLE.apply_shell_style(
			tl_panel,
			"hud_left",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(tl_panel, tl_tex, COMBAT_FEEL_CONTENT.hud_top_left_texture_region())
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(tl_panel)
	else:
		ui_layer.add_child(tl_panel)
	_enforce_top_left_panel_rect()

	var tl_body := MarginContainer.new()
	tl_body.name = "TopLeftBody"
	tl_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(tl_body, COMBAT_FEEL_CONTENT.HUD_TOP_LEFT_CONTENT_MARGIN, Vector4(14.0, 8.0, 12.0, 6.0))
	tl_panel.add_child(tl_body)

	_hud_top_left_container = VBoxContainer.new()
	_hud_top_left_container.name = "TopLeftVBox"
	_hud_top_left_container.add_theme_constant_override("separation", 10)
	_hud_top_left_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_top_left_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tl_body.add_child(_hud_top_left_container)

	# Top Right Stack wrapper now owns both top metrics and persistent right-column readouts.
	var tr_panel := PanelContainer.new()
	_hud_top_right_panel = tr_panel
	tr_panel.name = "TopRightPanel"
	tr_panel.z_index = 40
	tr_panel.clip_contents = true
	tr_panel.position = Vector2(COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - hud_m - hud_tr_w, hud_ty)
	tr_panel.size = Vector2(hud_tr_w, tr_height)
	tr_panel.custom_minimum_size = Vector2(hud_tr_w, tr_height)
	var tr_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_top_right_panel_path()
	if tr_tex.is_empty():
		UI_STYLE.apply_shell_style(tr_panel, "hud_right", "")
	else:
		UI_STYLE.apply_shell_style(
			tr_panel,
			"hud_right",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(tr_panel, tr_tex, COMBAT_FEEL_CONTENT.hud_top_right_texture_region())
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(tr_panel)
	else:
		ui_layer.add_child(tr_panel)

	var tr_body := MarginContainer.new()
	tr_body.name = "TopRightBody"
	tr_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(tr_body, COMBAT_FEEL_CONTENT.HUD_TOP_RIGHT_CONTENT_MARGIN, Vector4(12.0, 8.0, 14.0, 6.0))
	tr_panel.add_child(tr_body)

	var accent_host := Control.new()
	accent_host.name = "RightHudAccentHost"
	accent_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	accent_host.offset_left = 0.0
	accent_host.offset_top = 0.0
	accent_host.offset_right = 0.0
	accent_host.offset_bottom = 0.0
	accent_host.z_index = 4
	_hud_top_right_accent_host = accent_host
	tr_panel.add_child(accent_host)

	var tr_stack := VBoxContainer.new()
	tr_stack.name = "TopRightStack"
	tr_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tr_stack.add_theme_constant_override("separation", int(COMBAT_FEEL_CONTENT.HUD_GAP_BELOW_TOP_BAND))
	tr_body.add_child(tr_stack)

	_hud_top_right_container = VBoxContainer.new()
	_hud_top_right_container.name = "TopRightVBox"
	_hud_top_right_container.add_theme_constant_override("separation", 10)
	_hud_top_right_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_top_right_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tr_stack.add_child(_hud_top_right_container)

	_hud_right_stack = VBoxContainer.new()
	_hud_right_stack.name = "RightStackContainer"
	_hud_right_stack.custom_minimum_size = Vector2(0.0, right_stack_min_h)
	_hud_right_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_right_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hud_right_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_right_stack.add_theme_constant_override("separation", 6)
	tr_stack.add_child(_hud_right_stack)

	var bottom_panel := PanelContainer.new()
	bottom_panel.name = "BottomHudPanel"
	bottom_panel.z_index = 40
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = hud_m
	bottom_panel.offset_right = -hud_m
	bottom_panel.offset_top = -(COMBAT_FEEL_CONTENT.HUD_BOTTOM_STRIP_HEIGHT + COMBAT_FEEL_CONTENT.HUD_BOTTOM_OUTER_MARGIN)
	bottom_panel.offset_bottom = -COMBAT_FEEL_CONTENT.HUD_BOTTOM_OUTER_MARGIN
	var bottom_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_bottom_panel_path()
	if bottom_tex.is_empty():
		UI_STYLE.apply_shell_style(bottom_panel, "hud_accent")
	else:
		UI_STYLE.apply_shell_style(
			bottom_panel,
			"hud_left",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(bottom_panel, bottom_tex, COMBAT_FEEL_CONTENT.hud_bottom_texture_region())
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(bottom_panel)
	else:
		ui_layer.add_child(bottom_panel)

	var bottom_body := MarginContainer.new()
	bottom_body.name = "BottomBody"
	bottom_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(
		bottom_body,
		COMBAT_FEEL_CONTENT.HUD_BOTTOM_CONTENT_MARGIN,
		Vector4(10.0, 4.0, 10.0, 4.0)
	)
	bottom_panel.add_child(bottom_body)

	_hud_bottom_container = HBoxContainer.new()
	_hud_bottom_container.name = "BottomContainer"
	_hud_bottom_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_bottom_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hud_bottom_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_bottom_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_body.add_child(_hud_bottom_container)


func _enforce_top_left_panel_rect() -> void:
	if _hud_top_left_panel == null or not is_instance_valid(_hud_top_left_panel):
		return
	var hud_m: float = COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN
	var hud_ty: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y
	var hud_tl_w: float = COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH
	var hud_th: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_HEIGHT
	_hud_top_left_panel.custom_minimum_size = Vector2(hud_tl_w, hud_th)
	_hud_top_left_panel.position = Vector2(hud_m, hud_ty)
	_hud_top_left_panel.size = Vector2(hud_tl_w, hud_th)


func _sync_hud_shell_interface_wound_glow() -> void:
	if _presentation_controller == null or not is_instance_valid(_presentation_controller):
		return
	var c: int = 0
	if combat_meter != null and is_instance_valid(combat_meter):
		c = int(combat_meter.combo_count)
	var norm: float = clampf(float(c) / float(COMBAT_METER_SCRIPT.ULTIMATE_THRESHOLD), 0.0, 1.0)
	_presentation_controller.update_hud_interface_wound_glow(_hud_top_left_panel, _hud_top_right_panel, norm)


func _build_meter_shell() -> void:
	_resource_shell = ColorRect.new()
	_resource_shell.name = "RightHudAccent"
	_resource_shell.z_index = 42
	_resource_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_shell.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_resource_shell.anchor_left = 1.0
	_resource_shell.anchor_top = 0.0
	_resource_shell.anchor_right = 1.0
	_resource_shell.anchor_bottom = 0.0
	_resource_shell.offset_left = -52.0
	_resource_shell.offset_top = 6.0
	_resource_shell.offset_right = -8.0
	_resource_shell.offset_bottom = 20.0
	UI_STYLE.apply_shell_style(_resource_shell, "hud_accent")
	_resource_shell.color = Color(0.16, 0.10, 0.08, 0.07)
	if _hud_top_right_accent_host != null:
		_hud_top_right_accent_host.add_child(_resource_shell)
	elif _hud_top_right_panel != null:
		_hud_top_right_panel.add_child(_resource_shell)
	else:
		_resource_shell.position = Vector2(
			COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN - 52.0,
			COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y + 6.0
		)
		_resource_shell.size = Vector2(44.0, 14.0)
		if _hud_secondary_layer != null:
			_hud_secondary_layer.add_child(_resource_shell)
		else:
			ui_layer.add_child(_resource_shell)

	_support_shell = ColorRect.new()
	_support_shell.name = "SupportShell"
	_support_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 64.0)
	UI_STYLE.apply_shell_style(_support_shell, "support_idle")
	_hud_right_stack.add_child(_support_shell)

	var support_body := MarginContainer.new()
	support_body.name = "SupportBody"
	support_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	support_body.offset_left = 8.0
	support_body.offset_top = 4.0
	support_body.offset_right = -8.0
	support_body.offset_bottom = -6.0
	_support_shell.add_child(support_body)

	var support_vbox := VBoxContainer.new()
	support_vbox.name = "SupportVBox"
	support_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	support_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	support_vbox.add_theme_constant_override("separation", 3)
	support_body.add_child(support_vbox)

	var support_header := HBoxContainer.new()
	support_header.name = "SupportHeader"
	support_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	support_header.add_theme_constant_override("separation", 4)
	support_vbox.add_child(support_header)

	_support_name_label = Label.new()
	_support_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_support_name_label.custom_minimum_size = Vector2(0.0, 20.0)
	_support_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_support_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_support_name_label.clip_text = true
	_support_name_label.text = PRESENTATION_TEXT.SUPPORT_EMPTY_NAME
	_presentation_controller.apply_text_role(_support_name_label, "secondary_value")
	_support_name_label.add_theme_font_size_override("font_size", 15)
	support_header.add_child(_support_name_label)

	_support_value_label = Label.new()
	_support_value_label.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_ROW_WIDTH + 12.0, 22.0)
	_support_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_support_value_label.text = "--"
	_presentation_controller.apply_text_role(_support_value_label, "alert_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_support_value_label.add_theme_font_size_override("font_size", 16)
	support_header.add_child(_support_value_label)

	_support_bar = ProgressBar.new()
	_support_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_support_bar.custom_minimum_size = Vector2(0.0, 13.0)
	_support_bar.min_value = 0.0
	_support_bar.max_value = 100.0
	_support_bar.value = 0.0
	_support_bar.show_percentage = false
	support_vbox.add_child(_support_bar)
	UI_STYLE.apply_bar_style(_support_bar, "support_idle")

	_support_trigger_label = Label.new()
	_support_trigger_label.name = "SupportTriggerHint"
	_support_trigger_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_support_trigger_label.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_TEXT_WIDTH, 18.0)
	_support_trigger_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_support_trigger_label.clip_text = true
	_support_trigger_label.text = ""
	_presentation_controller.apply_text_role(_support_trigger_label, "status_line")
	_support_trigger_label.add_theme_font_size_override("font_size", 13)
	support_vbox.add_child(_support_trigger_label)

	_run_build_shell = ColorRect.new()
	_run_build_shell.name = "RunBuildShell"
	_run_build_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 56.0)
	UI_STYLE.apply_shell_style(_run_build_shell, "run_build")
	_run_build_shell.visible = false
	_hud_right_stack.add_child(_run_build_shell)

	var run_build_body := MarginContainer.new()
	run_build_body.name = "RunBuildBody"
	run_build_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	run_build_body.offset_left = 8.0
	run_build_body.offset_top = 4.0
	run_build_body.offset_right = -8.0
	run_build_body.offset_bottom = -4.0
	_run_build_shell.add_child(run_build_body)

	var run_build_vbox := VBoxContainer.new()
	run_build_vbox.name = "RunBuildVBox"
	run_build_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_build_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	run_build_vbox.add_theme_constant_override("separation", 1)
	run_build_body.add_child(run_build_vbox)

	var eaten_row := HBoxContainer.new()
	eaten_row.name = "EatenRow"
	eaten_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eaten_row.add_theme_constant_override("separation", 4)
	run_build_vbox.add_child(eaten_row)

	var eaten_caption := Label.new()
	eaten_caption.custom_minimum_size = Vector2(34.0, 16.0)
	eaten_caption.text = PRESENTATION_TEXT.RUN_BUILD_EATEN_CAPTION
	_presentation_controller.apply_text_role(eaten_caption, "caption_strong")
	eaten_caption.visible = false
	eaten_row.add_child(eaten_caption)

	_eaten_value_label = Label.new()
	_eaten_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_eaten_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_eaten_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_eaten_value_label.text = "--"
	_presentation_controller.apply_text_role(_eaten_value_label, "status_line")
	_eaten_value_label.add_theme_font_size_override("font_size", 16)
	_eaten_value_label.visible = false
	eaten_row.add_child(_eaten_value_label)

	var upgrade_row := HBoxContainer.new()
	upgrade_row.name = "UpgradeRow"
	upgrade_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_row.add_theme_constant_override("separation", 4)
	run_build_vbox.add_child(upgrade_row)

	var upgrade_caption := Label.new()
	upgrade_caption.custom_minimum_size = Vector2(34.0, 16.0)
	upgrade_caption.text = PRESENTATION_TEXT.RUN_BUILD_TENDENCY_CAPTION
	_presentation_controller.apply_text_role(upgrade_caption, "caption_strong")
	upgrade_caption.visible = false
	upgrade_row.add_child(upgrade_caption)

	_upgrade_value_label = Label.new()
	_upgrade_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_upgrade_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_upgrade_value_label.text = "--"
	_presentation_controller.apply_text_role(_upgrade_value_label, "alert_value")
	_upgrade_value_label.add_theme_font_size_override("font_size", 16)
	_upgrade_value_label.visible = false
	upgrade_row.add_child(_upgrade_value_label)

	var bond_row := HBoxContainer.new()
	bond_row.name = "BondRow"
	bond_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_row.add_theme_constant_override("separation", 4)
	run_build_vbox.add_child(bond_row)

	var bond_caption := Label.new()
	bond_caption.custom_minimum_size = Vector2(34.0, 16.0)
	bond_caption.text = PRESENTATION_TEXT.RUN_BUILD_BOND_CAPTION
	_presentation_controller.apply_text_role(bond_caption, "caption_strong")
	bond_caption.visible = false
	bond_row.add_child(bond_caption)

	_bond_value_label = Label.new()
	_bond_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bond_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_bond_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bond_value_label.text = "--"
	_presentation_controller.apply_text_role(_bond_value_label, "cool_value")
	_bond_value_label.add_theme_font_size_override("font_size", 16)
	_bond_value_label.visible = false
	bond_row.add_child(_bond_value_label)

	# Top-left sub-container for secondary stats (EXP, Def, Atk) — moved to bottom of column in _setup_ui
	var stats_row := HBoxContainer.new()
	stats_row.name = "StatsRow"
	stats_row.custom_minimum_size = Vector2(
		_safe_inner_width(
			COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH,
			COMBAT_FEEL_CONTENT.HUD_TOP_LEFT_CONTENT_MARGIN,
			Vector4(14.0, 8.0, 12.0, 6.0)
		),
		18.0
	)
	stats_row.visible = false
	_hud_top_left_container.add_child(stats_row)

	var exp_caption := Label.new()
	exp_caption.text = "EXP"
	_presentation_controller.apply_text_role(exp_caption, "caption")
	exp_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(exp_caption)

	_exp_value_label = Label.new()
	_exp_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(_exp_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_LEFT)
	_exp_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_exp_value_label)

	var def_caption := Label.new()
	def_caption.text = "Def"
	_presentation_controller.apply_text_role(def_caption, "caption")
	def_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(def_caption)

	_def_value_label = Label.new()
	_def_value_label.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(_def_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_def_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_def_value_label)

	var atk_caption := Label.new()
	atk_caption.text = "Atk"
	_presentation_controller.apply_text_role(atk_caption, "caption")
	atk_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(atk_caption)

	_atk_value_label = Label.new()
	_atk_value_label.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(_atk_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_atk_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_atk_value_label)

	# Top-Right sub-containers for readouts
	var ult_row := HBoxContainer.new()
	ult_row.alignment = BoxContainer.ALIGNMENT_END
	ult_row.custom_minimum_size = Vector2(0.0, 22.0)
	ult_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(ult_row)
	
	var ultimate_caption := Label.new()
	ultimate_caption.text = "ULT"
	ultimate_caption.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(ultimate_caption, "caption_strong")
	ultimate_caption.add_theme_font_size_override("font_size", 14)
	ult_row.add_child(ultimate_caption)
	ultimate_label.reparent(ult_row)
	ultimate_label.custom_minimum_size = Vector2(0.0, 0.0)
	ultimate_label.clip_text = true

	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_END
	score_row.custom_minimum_size = Vector2(0.0, 22.0)
	score_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(score_row)

	var score_caption := Label.new()
	score_caption.text = "CMB"
	score_caption.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(score_caption, "caption_strong")
	score_caption.add_theme_font_size_override("font_size", 14)
	score_row.add_child(score_caption)
	combo_label.reparent(score_row)
	combo_label.custom_minimum_size = Vector2(0.0, 0.0)
	combo_label.clip_text = true

	var style_row := HBoxContainer.new()
	style_row.alignment = BoxContainer.ALIGNMENT_END
	style_row.custom_minimum_size = Vector2(0.0, 22.0)
	style_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(style_row)

	var style_caption := Label.new()
	style_caption.text = "STY"
	style_caption.custom_minimum_size = Vector2(24.0, 0.0)
	_presentation_controller.apply_text_role(style_caption, "caption_strong")
	style_caption.add_theme_font_size_override("font_size", 14)
	style_row.add_child(style_caption)
	style_label.reparent(style_row)
	style_label.custom_minimum_size = Vector2(0.0, 0.0)
	style_label.clip_text = true

	_dna_route_shell = ColorRect.new()
	_dna_route_shell.name = "DnaRouteShell"
	_dna_route_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 38.0)
	UI_STYLE.apply_shell_style(_dna_route_shell, "hud_right")
	_hud_right_stack.add_child(_dna_route_shell)

	var dna_route_body := MarginContainer.new()
	dna_route_body.name = "DnaRouteBody"
	dna_route_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	dna_route_body.offset_left = 8.0
	dna_route_body.offset_top = 3.0
	dna_route_body.offset_right = -8.0
	dna_route_body.offset_bottom = -3.0
	_dna_route_shell.add_child(dna_route_body)

	var dna_route_vbox := VBoxContainer.new()
	dna_route_vbox.name = "DnaRouteVBox"
	dna_route_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_route_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dna_route_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dna_route_vbox.add_theme_constant_override("separation", 1)
	dna_route_body.add_child(dna_route_vbox)

	_dna_route_label = Label.new()
	_dna_route_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dna_route_label.custom_minimum_size = Vector2(0.0, 22.0)
	_dna_route_label.text = PRESENTATION_TEXT.DNA_ROUTE_BOND_LABEL
	_presentation_controller.apply_text_role(_dna_route_label, "status_line", HORIZONTAL_ALIGNMENT_CENTER)
	_dna_route_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dna_route_label.add_theme_font_size_override("font_size", 15)
	dna_route_vbox.add_child(_dna_route_label)

	# Initialize mutation value label (for enhanced mutation system)
	_mutation_value_label = Label.new()
	_mutation_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mutation_value_label.custom_minimum_size = Vector2(0.0, 18.0)
	_mutation_value_label.text = ""
	_presentation_controller.apply_text_role(_mutation_value_label, "status_line", HORIZONTAL_ALIGNMENT_CENTER)
	_mutation_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mutation_value_label.add_theme_font_size_override("font_size", 15)
	_mutation_value_label.visible = false
	dna_route_vbox.add_child(_mutation_value_label)

	var run_score_row := HBoxContainer.new()
	run_score_row.alignment = BoxContainer.ALIGNMENT_END
	run_score_row.custom_minimum_size = Vector2(0.0, 22.0)
	run_score_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(run_score_row)

	var run_score_caption := Label.new()
	run_score_caption.text = "Run"
	run_score_caption.custom_minimum_size = Vector2(44.0, 0.0)
	_presentation_controller.apply_text_role(run_score_caption, "caption_strong")
	run_score_caption.add_theme_font_size_override("font_size", 14)
	run_score_row.add_child(run_score_caption)

	_run_score_label = Label.new()
	_run_score_label.name = "RunScoreLabel"
	_run_score_label.text = "0"
	_presentation_controller.apply_text_role(_run_score_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_run_score_label.add_theme_font_size_override("font_size", 13)
	_run_score_label.custom_minimum_size = Vector2(80.0, 0.0)
	run_score_row.add_child(_run_score_label)

	_bonded_creature_sprite = Sprite2D.new()
	_bonded_creature_sprite.name = "BondedCreatureSprite"
	_bonded_creature_sprite.visible = false
	_bonded_creature_sprite.centered = true
	_bonded_creature_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scene.add_child(_bonded_creature_sprite)

	# Boss HP bar — centered between top corner panels, below top band (hidden until boss).
	var boss_x: float = COMBAT_FEEL_CONTENT.HUD_BOSS_BLOCK_X
	var boss_y: float = COMBAT_FEEL_CONTENT.HUD_BOSS_BLOCK_Y
	var boss_w: float = COMBAT_FEEL_CONTENT.HUD_BOSS_BLOCK_WIDTH
	_boss_hp_shell = ColorRect.new()
	_boss_hp_shell.name = "BossHpShell"
	_boss_hp_shell.position = Vector2(boss_x, boss_y)
	_boss_hp_shell.size = Vector2(boss_w, 52.0)
	_boss_hp_shell.z_index = 38
	UI_STYLE.apply_shell_style(_boss_hp_shell, "boss_shell")
	_boss_hp_shell.visible = false
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(_boss_hp_shell)
	else:
		ui_layer.add_child(_boss_hp_shell)

	var boss_body := MarginContainer.new()
	boss_body.name = "BossBody"
	boss_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_body.offset_left = 12.0
	boss_body.offset_top = 3.0
	boss_body.offset_right = -12.0
	boss_body.offset_bottom = -3.0
	_boss_hp_shell.add_child(boss_body)

	var boss_vbox := VBoxContainer.new()
	boss_vbox.name = "BossVBox"
	boss_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	boss_vbox.add_theme_constant_override("separation", 1)
	boss_body.add_child(boss_vbox)

	_boss_name_label = Label.new()
	_boss_name_label.name = "BossNameLabel"
	_boss_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_name_label.custom_minimum_size = Vector2(0.0, 22.0)
	_boss_name_label.text = ""
	_presentation_controller.apply_text_role(_boss_name_label, "boss", HORIZONTAL_ALIGNMENT_CENTER)
	_boss_name_label.add_theme_font_size_override("font_size", 26)
	_boss_name_label.visible = false
	boss_vbox.add_child(_boss_name_label)

	_boss_state_label = Label.new()
	_boss_state_label.name = "BossStateLabel"
	_boss_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_state_label.custom_minimum_size = Vector2(0.0, 14.0)
	_boss_state_label.text = ""
	_presentation_controller.apply_text_role(_boss_state_label, "body", HORIZONTAL_ALIGNMENT_CENTER)
	_boss_state_label.add_theme_font_size_override("font_size", 14)
	_boss_state_label.add_theme_color_override("font_color", UI_STYLE.get_manga_color("alert_gold"))
	_boss_state_label.visible = false
	boss_vbox.add_child(_boss_state_label)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.name = "BossHpBar"
	_boss_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_hp_bar.custom_minimum_size = Vector2(0.0, 12.0)
	_boss_hp_bar.min_value = 0.0
	_boss_hp_bar.max_value = 100.0
	_boss_hp_bar.value = 100.0
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.visible = false
	boss_vbox.add_child(_boss_hp_bar)
	UI_STYLE.apply_bar_style(_boss_hp_bar, "boss")


func _create_panel_backing(
	node_name: String,
	texture_path: String,
	region: Rect2,
	node_position: Vector2,
	node_size: Vector2,
	node_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
) -> TextureRect:
	if not ResourceLoader.exists(texture_path):
		return null

	var source_texture: Texture2D = load(texture_path) as Texture2D
	if source_texture == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = region

	var backing := TextureRect.new()
	backing.name = node_name
	backing.texture = atlas
	backing.position = node_position
	backing.size = node_size
	backing.stretch_mode = TextureRect.STRETCH_SCALE
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.modulate = node_modulate
	ui_layer.add_child(backing)
	return backing


func _build_strip_sprite(
	node_name: String,
	texture_path: String,
	frame_size: Vector2i,
	initial_frame: int,
	node_position: Vector2,
	node_size: Vector2
) -> TextureRect:
	if not ResourceLoader.exists(texture_path):
		return null

	var source_texture: Texture2D = load(texture_path) as Texture2D
	if source_texture == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = Rect2(
		Vector2(frame_size.x * initial_frame, 0.0),
		Vector2(frame_size.x, frame_size.y)
	)

	var sprite := TextureRect.new()
	sprite.name = node_name
	sprite.texture = atlas
	sprite.position = node_position
	sprite.size = node_size
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite


func _build_song_hud() -> void:
	var hud_m: float = COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN
	var hud_ty: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y
	# Song phase label — top-center, dim (above corner art).
	_song_phase_label = Label.new()
	_song_phase_label.name = "SongPhaseLabel"
	_song_phase_label.text = ""
	_presentation_controller.apply_text_role(_song_phase_label, "dim", HORIZONTAL_ALIGNMENT_CENTER)
	_song_phase_label.size = Vector2(300.0, 18.0)
	_song_phase_label.position = Vector2((COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - 300.0) * 0.5, hud_ty + 4.0)
	_song_phase_label.z_index = 45
	_song_phase_label.visible = false
	if _hud_secondary_layer != null:
		_hud_secondary_layer.add_child(_song_phase_label)
	else:
		ui_layer.add_child(_song_phase_label)

	# Song timer label — upper-right, aligned with top band (above corner panels).
	_song_timer_label = Label.new()
	_song_timer_label.name = "SongTimerLabel"
	_song_timer_label.text = ""
	_presentation_controller.apply_text_role(_song_timer_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_song_timer_label.size = Vector2(52.0, 18.0)
	_song_timer_label.position = Vector2(COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - hud_m - 56.0, hud_ty + 26.0)
	_song_timer_label.z_index = 45
	_song_timer_label.visible = false
	if _hud_secondary_layer != null:
		_hud_secondary_layer.add_child(_song_timer_label)
	else:
		ui_layer.add_child(_song_timer_label)

	# Beat feedback label — appears near the timing rings briefly when the player
	# lands a combat action on-beat (IN SYNC / ON BEAT / LOCKED IN / SLIP).
	# Position is tunable; currently centered on the hit zone area.
	_beat_feedback_label = Label.new()
	_beat_feedback_label.name = "BeatFeedbackLabel"
	_beat_feedback_label.text = ""
	_beat_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_beat_feedback_label.custom_minimum_size = Vector2(0.0, 20.0)
	_presentation_controller.apply_text_role(_beat_feedback_label, "alert_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_beat_feedback_label.add_theme_font_size_override("font_size", 16)
	_beat_feedback_label.visible = false
	_hud_top_left_container.add_child(_beat_feedback_label)

	_sync_hud_shell_interface_wound_glow()


func _build_quig_anchor() -> void:
	var quig_shell := ColorRect.new()
	_quig_shell = quig_shell
	quig_shell.name = "QuigShell"
	quig_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 24.0)
	quig_shell.color = Color(0.0, 0.0, 0.0, 0.0)
	quig_shell.visible = false
	_hud_right_stack.add_child(quig_shell)

	_quig_anchor_sprite = _build_strip_sprite(
		"QuigAnchorSprite",
		COMBAT_FEEL_CONTENT.QUIG_SPRITE_PATH,
		COMBAT_FEEL_CONTENT.QUIG_FRAME_SIZE,
		0,
		Vector2(2.0, 2.0),
		Vector2(24.0, 24.0)
	)
	if _quig_anchor_sprite != null:
		_quig_anchor_sprite.visible = false
		quig_shell.add_child(_quig_anchor_sprite)

		if OS.is_debug_build():
			_timing_debug_label = Label.new()
			_timing_debug_label.position = Vector2(10.0, 116.0)
			_timing_debug_label.size = Vector2(240.0, 24.0)
			_timing_debug_label.add_theme_font_size_override("font_size", 13)
			_timing_debug_label.modulate = UI_STYLE.get_quality_feedback_color("idle")
			# Keep debug builds visually clean unless explicitly enabled.
			_timing_debug_label.visible = false
			ui_layer.add_child(_timing_debug_label)

	_quig_anchor_label = Label.new()
	_quig_anchor_label.name = "QuigAnchor"
	_quig_anchor_label.visible = false
	_quig_anchor_label.position = Vector2(28.0, 0.0)
	_quig_anchor_label.size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH - 28.0, 28.0)
	_quig_anchor_label.text = ""
	_presentation_controller.apply_text_role(_quig_anchor_label, "dim")
	_quig_anchor_label.add_theme_font_size_override("font_size", 13)
	quig_shell.add_child(_quig_anchor_label)


func _build_dna_shell() -> void:
	_dna_shell = ColorRect.new()
	_dna_shell.name = "DnaShell"
	_dna_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 46.0)
	UI_STYLE.apply_shell_style(_dna_shell, "dna")
	_dna_shell.visible = false
	_hud_right_stack.add_child(_dna_shell)

	var dna_body := MarginContainer.new()
	dna_body.name = "DnaBody"
	dna_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	dna_body.offset_left = 8.0
	dna_body.offset_top = 5.0
	dna_body.offset_right = -8.0
	dna_body.offset_bottom = -5.0
	_dna_shell.add_child(dna_body)

	var dna_vbox := VBoxContainer.new()
	dna_vbox.name = "DnaVBox"
	dna_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dna_vbox.add_theme_constant_override("separation", 1)
	dna_body.add_child(dna_vbox)

	var dna_header := HBoxContainer.new()
	dna_header.name = "DnaHeader"
	dna_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_header.add_theme_constant_override("separation", 3)
	dna_vbox.add_child(dna_header)

	var dna_caption := Label.new()
	dna_caption.custom_minimum_size = Vector2(42.0, 16.0)
	dna_caption.text = "DNA"
	_presentation_controller.apply_text_role(dna_caption, "caption_strong")
	dna_caption.add_theme_font_size_override("font_size", 16)
	dna_header.add_child(dna_caption)

	var dna_header_spacer := Control.new()
	dna_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_header.add_child(dna_header_spacer)

	_dna_emblem = _build_strip_sprite(
		"DnaEmblem",
		COMBAT_FEEL_CONTENT.DNA_SPRITE_PATH,
		COMBAT_FEEL_CONTENT.DNA_FRAME_SIZE,
		0,
		Vector2.ZERO,
		Vector2(16.0, 16.0)
	)
	if _dna_emblem != null:
		_dna_emblem.modulate = Color(1.0, 1.0, 1.0, 0.82)
		dna_header.add_child(_dna_emblem)

	_dna_slot_labels.clear()
	for i in range(DNA_HUD_VISIBLE_SLOTS):
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(0.0, 14.0)
		label.text = "--"
		_presentation_controller.apply_text_role(label, "secondary_value")
		label.add_theme_font_size_override("font_size", 14)
		dna_vbox.add_child(label)
		_dna_slot_labels.append(label)


func _create_feedback_label() -> void:
	if _feedback_shell == null:
		return
	_feedback_shell.create_feedback_nodes(_hud_overlay_layer, ui_layer)


func _create_title_cards() -> void:
	if _feedback_shell == null:
		return
	_feedback_shell.create_title_cards(self)
	_title_card = _feedback_shell.get_title_card()
	_subtitle_card = _feedback_shell.get_subtitle_card()


func _create_timing_circle_container() -> void:
	_timing_circle_container = _presentation_controller.create_timing_circle_container(scene)
	_timing_rings_cache.clear()


func _create_attack_fx_container() -> void:
	_attack_fx_container = _presentation_controller.create_attack_fx_container(scene)


func _create_impact_fx_runtime() -> void:
	if scene.get_node_or_null("ImpactFxRuntime") != null:
		return
	var ifx: Node = IMPACT_FX_RUNTIME_SCENE.instantiate()
	ifx.name = "ImpactFxRuntime"
	scene.add_child(ifx)


func _create_reward_overlay() -> void:
	var nodes: Dictionary = _presentation_controller.create_reward_overlay(ui_layer)
	_reward_overlay = nodes.get("reward_overlay")
	_reward_wrapper_shell = nodes.get("reward_wrapper_shell")
	_reward_panel = nodes.get("reward_panel")
	_reward_title_label = nodes.get("reward_title_label")
	_reward_body_label = nodes.get("reward_body_label")
	_reward_quig_label = nodes.get("reward_quig_label")
	_reward_quig_sprite = nodes.get("reward_quig_sprite")
	_reward_hint_label = nodes.get("reward_hint_label")
	_reward_bond_card = nodes.get("reward_bond_card")
	_reward_eat_card = nodes.get("reward_eat_card")
	_reward_bond_label = nodes.get("reward_bond_label")
	_reward_dna_label = nodes.get("reward_dna_label")
	_reward_eat_label = nodes.get("reward_eat_label")
	_reward_bond_effect_label = nodes.get("reward_bond_effect_label")
	_reward_eat_effect_label = nodes.get("reward_eat_effect_label")
	_reward_creature_tag_label = nodes.get("reward_creature_tag_label")
	_reward_creature_portrait = nodes.get("reward_creature_portrait")
	_reward_body_scroll = nodes.get("reward_body_scroll")
	_reward_bond_effect_scroll = nodes.get("reward_bond_effect_scroll")
	_reward_eat_effect_scroll = nodes.get("reward_eat_effect_scroll")


func _create_upgrade_overlay() -> void:
	_upgrade_overlay = ColorRect.new()
	_upgrade_overlay.name = "UpgradeOverlay"
	_upgrade_overlay.visible = false
	_upgrade_overlay.color = Color(0.01, 0.01, 0.02, 0.90)
	_upgrade_overlay.anchor_right = 1.0
	_upgrade_overlay.anchor_bottom = 1.0
	_upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_upgrade_overlay)

	_upgrade_panel = ColorRect.new()
	_upgrade_panel.name = "UpgradePanel"
	_presentation_controller.set_shell_treatment(_upgrade_panel, Color(0.08, 0.06, 0.07, 0.98), Color(0.24, 0.18, 0.16, 0.94))
	_upgrade_panel.position = Vector2(120.0, 140.0)
	_upgrade_panel.size = Vector2(1040.0, 440.0)
	_upgrade_overlay.add_child(_upgrade_panel)

	var header := Label.new()
	header.text = "CHOOSE YOUR GROWTH"
	header.position = Vector2(0.0, 24.0)
	header.size = Vector2(1040.0, 40.0)
	_presentation_controller.apply_text_role(header, "heading", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(header)

	var sub := Label.new()
	sub.text = "Select one evolution to anchor before the next leg"
	sub.position = Vector2(0.0, 68.0)
	sub.size = Vector2(1040.0, 24.0)
	_presentation_controller.apply_text_role(sub, "screen_subtitle", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(sub)

	var card_w: float = 300.0
	var card_h: float = 280.0
	var gap: float = 32.0
	var start_x: float = (1040.0 - (card_w * 3 + gap * 2)) * 0.5

	for i in range(3):
		var card := ColorRect.new()
		card.name = "UpgradeCard_%d" % i
		card.position = Vector2(start_x + i * (card_w + gap), 110.0)
		card.size = Vector2(card_w, card_h)
		_presentation_controller.set_shell_treatment(card, Color(0.12, 0.09, 0.10, 0.96), Color(0.30, 0.22, 0.20, 0.88))
		_upgrade_panel.add_child(card)
		_upgrade_card_nodes.append(card)

		var index_label := Label.new()
		index_label.text = str(i + 1)
		index_label.position = Vector2(14.0, 14.0)
		index_label.size = Vector2(24.0, 24.0)
		_presentation_controller.apply_text_role(index_label, "card_index")
		card.add_child(index_label)

		var cat_label := Label.new()
		cat_label.name = "Category"
		cat_label.position = Vector2(14.0, 42.0)
		cat_label.size = Vector2(card_w - 28.0, 18.0)
		_presentation_controller.apply_text_role(cat_label, "caption_strong")
		card.add_child(cat_label)

		var title_label := Label.new()
		title_label.name = "Title"
		title_label.position = Vector2(14.0, 64.0)
		title_label.size = Vector2(card_w - 28.0, 48.0)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_presentation_controller.apply_text_role(title_label, "card_title")
		card.add_child(title_label)

		var sep := ColorRect.new()
		sep.position = Vector2(14.0, 120.0)
		sep.size = Vector2(card_w - 28.0, 1.0)
		sep.color = Color(0.28, 0.20, 0.18, 0.50)
		card.add_child(sep)

		var body_label := Label.new()
		body_label.name = "Body"
		body_label.position = Vector2(14.0, 134.0)
		body_label.size = Vector2(card_w - 28.0, 120.0)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_presentation_controller.apply_text_role(body_label, "body")
		card.add_child(body_label)

	var hint := Label.new()
	hint.text = "1 / 2 / 3 - Select Upgrade"
	hint.position = Vector2(0.0, 400.0)
	hint.size = Vector2(1040.0, 24.0)
	_presentation_controller.apply_text_role(hint, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(hint)


func _create_live_reward_shell() -> void:
	var nodes: Dictionary = _presentation_controller.create_live_reward_shell(ui_layer)
	_live_reward_shell = nodes.get("live_reward_shell")
	_live_reward_title_label = nodes.get("live_reward_title_label")
	_live_reward_body_label = nodes.get("live_reward_body_label")
	_live_reward_dna_label = nodes.get("live_reward_dna_label")
	_live_reward_hint_label = nodes.get("live_reward_hint_label")


