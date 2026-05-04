extends Control

const UI_STYLE = preload("res://systems/UIStyle.gd")
const HUD_PANEL_ART = preload("res://systems/HUDPanelArt.gd")

@onready var _backdrop_host: Node2D = $BackdropHost
@onready var _shaker: Control = $Shaker
@onready var _stats_wound_frame: Panel = $Shaker/StatsWoundFrame
@onready var _dna_info: Label = $Shaker/StatsWoundFrame/MarginC/StatsContainer/DNAInfo
@onready var _fang_level: Label = $Shaker/StatsWoundFrame/MarginC/StatsContainer/FangStatFrame/FangStat/Level
@onready var _fang_cost: Label = $Shaker/StatsWoundFrame/MarginC/StatsContainer/FangStatFrame/FangStat/Cost
@onready var _nerve_level: Label = $Shaker/StatsWoundFrame/MarginC/StatsContainer/NerveStatFrame/NerveStat/Level
@onready var _nerve_cost: Label = $Shaker/StatsWoundFrame/MarginC/StatsContainer/NerveStatFrame/NerveStat/Cost
@onready var _bond_level: Label = $Shaker/StatsWoundFrame/MarginC/StatsContainer/BondStatFrame/BondStat/Level
@onready var _bond_cost: Label = $Shaker/StatsWoundFrame/MarginC/StatsContainer/BondStatFrame/BondStat/Cost
@onready var _title: Label = $Shaker/Title
@onready var _controls: Label = $Shaker/Controls
@onready var _proc_toast: Label = $Shaker/ProcToast

func _ready() -> void:
	_apply_fable_ink_chrome()
	_rebuild_wound_backdrop()
	_build_lair_chamber_chrome()
	_refresh_ui()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	call_deferred("_rebuild_wound_backdrop")


func _apply_fable_ink_chrome() -> void:
	UI_STYLE.apply_label(_title, "mm_title", HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_font_size_override("font_size", 40)
	UI_STYLE.apply_label(_dna_info, "mm_stat_primary", HORIZONTAL_ALIGNMENT_CENTER)
	UI_STYLE.apply_label(_controls, "mm_subtitle", HORIZONTAL_ALIGNMENT_CENTER)
	_controls.add_theme_font_size_override("font_size", 18)

	var ink := UI_STYLE.get_manga_color("ink_black")
	HUD_PANEL_ART.apply_panel_art(_stats_wound_frame, "", Rect2(), "HudPanelArt", "HudPanelBacking", Color(ink.r, ink.g, ink.b, 0.78))
	HUD_PANEL_ART.set_vein_pulse(_stats_wound_frame, 0.35)

	_style_stat_row_shell($Shaker/StatsWoundFrame/MarginC/StatsContainer/FangStatFrame, "mm_apex")
	_style_stat_row_shell($Shaker/StatsWoundFrame/MarginC/StatsContainer/NerveStatFrame, "mm_command")
	_style_stat_row_shell($Shaker/StatsWoundFrame/MarginC/StatsContainer/BondStatFrame, "mm_mutation")

	_style_stat_labels($Shaker/StatsWoundFrame/MarginC/StatsContainer/FangStatFrame/FangStat)
	_style_stat_labels($Shaker/StatsWoundFrame/MarginC/StatsContainer/NerveStatFrame/NerveStat)
	_style_stat_labels($Shaker/StatsWoundFrame/MarginC/StatsContainer/BondStatFrame/BondStat)

	UI_STYLE.apply_label(_proc_toast, "mm_monster_alert", HORIZONTAL_ALIGNMENT_CENTER)
	_proc_toast.add_theme_font_size_override("font_size", 22)


func _build_lair_chamber_chrome() -> void:
	_title.text = "HEARTROOT CHAMBER"
	_controls.text = "[1] Fang  [2] Nerve  [3] Bond  [B] Lair"

	_build_heartroot_organism_map()

	var chamber_note := Label.new()
	chamber_note.text = "Meta growth lives here. Lineage selection remains in the Lair."
	chamber_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chamber_note.position = Vector2(220.0, 92.0)
	chamber_note.size = Vector2(840.0, 30.0)
	UI_STYLE.apply_label(chamber_note, "mm_subtitle")
	chamber_note.add_theme_font_size_override("font_size", 18)
	_shaker.add_child(chamber_note)

	_build_room_spine()
	_build_side_wound()


func _build_heartroot_organism_map() -> void:
	var root_map := Node2D.new()
	root_map.name = "HeartrootOrganismMap"
	_shaker.add_child(root_map)
	_shaker.move_child(root_map, 0)

	var root_shadow := Polygon2D.new()
	root_shadow.polygon = PackedVector2Array([
		Vector2(294.0, 612.0),
		Vector2(372.0, 374.0),
		Vector2(526.0, 226.0),
		Vector2(682.0, 184.0),
		Vector2(846.0, 230.0),
		Vector2(976.0, 392.0),
		Vector2(1054.0, 620.0),
		Vector2(830.0, 662.0),
		Vector2(652.0, 632.0),
		Vector2(476.0, 662.0)
	])
	root_shadow.color = Color(UI_STYLE.get_manga_color("ink_black"), 0.50)
	root_map.add_child(root_shadow)

	_add_heartroot_line(root_map, PackedVector2Array([
		Vector2(654.0, 176.0), Vector2(642.0, 270.0), Vector2(640.0, 392.0),
		Vector2(646.0, 520.0), Vector2(632.0, 682.0)
	]), Color(UI_STYLE.get_manga_color("bond_teal"), 0.26), 8.0)
	_add_heartroot_line(root_map, PackedVector2Array([
		Vector2(646.0, 370.0), Vector2(522.0, 312.0), Vector2(404.0, 256.0),
		Vector2(284.0, 220.0)
	]), Color(UI_STYLE.get_manga_color("blood_ember"), 0.18), 4.0)
	_add_heartroot_line(root_map, PackedVector2Array([
		Vector2(650.0, 386.0), Vector2(790.0, 320.0), Vector2(948.0, 292.0),
		Vector2(1148.0, 338.0)
	]), Color(UI_STYLE.get_manga_color("mutation_magenta"), 0.17), 4.0)
	_add_heartroot_line(root_map, PackedVector2Array([
		Vector2(634.0, 538.0), Vector2(510.0, 594.0), Vector2(384.0, 650.0)
	]), Color(UI_STYLE.get_manga_color("alert_gold"), 0.13), 3.0)
	_add_heartroot_line(root_map, PackedVector2Array([
		Vector2(660.0, 536.0), Vector2(812.0, 600.0), Vector2(1010.0, 646.0)
	]), Color(UI_STYLE.get_manga_color("paper"), 0.10), 3.0)

	for i in range(3):
		var rib := Polygon2D.new()
		var x := 430.0 + float(i) * 155.0
		rib.polygon = PackedVector2Array([
			Vector2(x, 150.0),
			Vector2(x + 80.0, 178.0),
			Vector2(x + 34.0, 252.0),
			Vector2(x - 34.0, 226.0)
		])
		rib.color = Color(UI_STYLE.get_manga_color("paper"), 0.035)
		root_map.add_child(rib)


func _add_heartroot_line(parent: Node, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(line)


func _build_room_spine() -> void:
	var rooms := [
		{"label": "LINEAGE", "role": "mm_apex", "active": false},
		{"label": "HEARTROOT", "role": "mm_command", "active": true},
		{"label": "ARCHIVE", "role": "mm_mutation", "active": false},
		{"label": "SEALED", "role": "lair_card", "active": false}
	]
	var x: float = 250.0
	var y: float = 124.0
	var w: float = 190.0
	var h: float = 26.0
	var gap: float = 10.0
	for i in range(rooms.size()):
		var room: Dictionary = rooms[i]
		var tab := Panel.new()
		tab.position = Vector2(x + float(i) * (w + gap), y)
		tab.size = Vector2(w, h)
		UI_STYLE.apply_shell_style(tab, String(room.get("role", "lair_card")))
		_apply_heartroot_vein_panel(tab, 0.35 if bool(room.get("active", false)) else 0.05, _room_accent_color(String(room.get("label", ""))))
		tab.modulate.a = 1.0 if bool(room.get("active", false)) else 0.54
		_shaker.add_child(tab)

		var label := Label.new()
		label.text = String(room.get("label", ""))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = tab.size
		UI_STYLE.apply_label(label, "mm_caption")
		label.add_theme_font_size_override("font_size", 14)
		tab.add_child(label)


func _build_side_wound() -> void:
	var side := Panel.new()
	side.position = Vector2(40.0, 164.0)
	side.size = Vector2(260.0, 346.0)
	UI_STYLE.apply_shell_style(side, "lair_sidebar")
	_apply_heartroot_vein_panel(side, 0.24, UI_STYLE.get_manga_color("bond_teal"))
	_shaker.add_child(side)

	var title := Label.new()
	title.text = "HEARTROOT"
	title.position = Vector2(58.0, 184.0)
	title.size = Vector2(224.0, 28.0)
	UI_STYLE.apply_label(title, "mm_choice_bond")
	title.add_theme_font_size_override("font_size", 20)
	_shaker.add_child(title)

	var body := Label.new()
	body.text = "Inner Lair root.\n\nFed DNA becomes vessel pressure here.\n\nLineage bonds remain in the outer archive."
	body.position = Vector2(58.0, 224.0)
	body.size = Vector2(224.0, 166.0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(body, "mm_body")
	body.add_theme_font_size_override("font_size", 17)
	_shaker.add_child(body)


func _apply_heartroot_vein_panel(panel: Control, pulse: float, color: Color) -> void:
	if panel == null:
		return
	var ink := UI_STYLE.get_manga_color("ink_black")
	HUD_PANEL_ART.apply_panel_art(panel, "", Rect2(), "HeartrootVeinArt", "HeartrootVeinBacking", Color(ink.r, ink.g, ink.b, 0.34))
	HUD_PANEL_ART.set_vein_color(panel, color, "HeartrootVeinBacking")
	HUD_PANEL_ART.set_vein_pulse(panel, pulse, "HeartrootVeinBacking")


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


func _style_stat_row_shell(panel: Panel, shell_role: String) -> void:
	if panel == null:
		return
	UI_STYLE.apply_shell_style(panel, shell_role)
	var accent := UI_STYLE.get_manga_color("paper")
	match shell_role:
		"mm_apex":
			accent = UI_STYLE.get_manga_color("blood_ember")
		"mm_command":
			accent = UI_STYLE.get_manga_color("bond_teal")
		"mm_mutation":
			accent = UI_STYLE.get_manga_color("mutation_magenta")
	_apply_heartroot_vein_panel(panel, 0.18, accent)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _style_stat_labels(row: HBoxContainer) -> void:
	if row == null:
		return
	for c in row.get_children():
		if c is Label:
			var lab: Label = c as Label
			if lab.name == "Cost":
				UI_STYLE.apply_label(lab, "mm_stat_secondary")
			else:
				UI_STYLE.apply_label(lab, "mm_stat_primary")


func _rebuild_wound_backdrop() -> void:
	if _backdrop_host == null or not is_instance_valid(_backdrop_host):
		return
	var existing: Node = _backdrop_host.get_node_or_null("ShellBackdrop")
	if existing != null:
		_backdrop_host.remove_child(existing)
		existing.free()
	var sz: Vector2 = get_viewport().get_visible_rect().size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = Vector2(1280.0, 720.0)
	UI_STYLE.attach_wound_backdrop(_backdrop_host, sz)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_upgrade_stat("fang")
			KEY_2:
				_upgrade_stat("nerve")
			KEY_3:
				_upgrade_stat("bond")
			KEY_B:
				get_tree().change_scene_to_file("res://scenes/ui/LairScene.tscn")


func _refresh_ui() -> void:
	var total_dna := 0.0
	for species_id in GameState.dna_by_species.keys():
		total_dna += GameState.get_dna(species_id)

	_dna_info.text = "FED DNA IN ROOT: %d" % int(total_dna)

	_fang_level.text = "Root %d" % GameState.meta_fang_level
	_fang_cost.text = "[%d DNA]" % _get_cost(GameState.meta_fang_level)

	_nerve_level.text = "Root %d" % GameState.meta_nerve_level
	_nerve_cost.text = "[%d DNA]" % _get_cost(GameState.meta_nerve_level)

	_bond_level.text = "Root %d" % GameState.meta_bond_level
	_bond_cost.text = "[%d DNA]" % _get_cost(GameState.meta_bond_level)


func _get_cost(level: int) -> int:
	return 100 + (level * 100)


func _upgrade_stat(stat_id: String) -> void:
	var current_level := 0
	match stat_id:
		"fang":
			current_level = GameState.meta_fang_level
		"nerve":
			current_level = GameState.meta_nerve_level
		"bond":
			current_level = GameState.meta_bond_level

	var cost := _get_cost(current_level)

	var total_dna := 0.0
	for species_id in GameState.dna_by_species.keys():
		total_dna += GameState.get_dna(species_id)

	if total_dna >= float(cost):
		GameState.spend_dna_any(float(cost))
		match stat_id:
			"fang":
				GameState.meta_fang_level += 1
			"nerve":
				GameState.meta_nerve_level += 1
			"bond":
				GameState.meta_bond_level += 1
		_refresh_ui()
		var msg := "HEARTROOT RESONANCE: " + stat_id.to_upper()
		var col := UI_STYLE.get_manga_color("bond_teal")
		EventBus.emit_signal("proc_feedback_requested", msg, col)
		_show_proc_toast(msg, col)
		_play_manga_impact(true, col)
	else:
		var fail_msg := "INSUFFICIENT DNA"
		var col := UI_STYLE.get_manga_color("blood_ember")
		EventBus.emit_signal("proc_feedback_requested", fail_msg, col)
		_show_proc_toast(fail_msg, col)
		_play_manga_impact(false, col)


func _show_proc_toast(text: String, color: Color) -> void:
	_proc_toast.text = text
	_proc_toast.add_theme_color_override("font_color", color)
	_proc_toast.visible = true
	_proc_toast.modulate.a = 1.0
	_proc_toast.scale = Vector2.ONE * 1.08
	var tw := create_tween()
	tw.tween_property(_proc_toast, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.85)
	tw.tween_property(_proc_toast, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func() -> void:
		_proc_toast.visible = false
	)


func _play_manga_impact(success: bool, accent: Color) -> void:
	HUD_PANEL_ART.set_vein_pulse(_stats_wound_frame, 1.0 if success else 0.72)
	HUD_PANEL_ART.set_vein_color(_stats_wound_frame, accent)
	var v_from: float = 1.0 if success else 0.72
	var decay := create_tween()
	decay.tween_method(
		func(v: float) -> void:
			HUD_PANEL_ART.set_vein_pulse(_stats_wound_frame, v),
		v_from,
		0.28,
		0.55 if success else 0.42
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var base_pos := _shaker.position
	var shake_n := 7
	var tw := create_tween()
	for i in shake_n:
		var amp := (6.0 - float(i) * 0.55) if success else (4.0 - float(i) * 0.35)
		var p := Vector2(randf_range(-amp, amp), randf_range(-amp * 0.7, amp * 0.7))
		tw.tween_property(_shaker, "position", base_pos + p, 0.018)
	tw.tween_property(_shaker, "position", base_pos, 0.06).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var saved_ts := Engine.time_scale
	var target_ts := 0.14 if success else 0.28
	Engine.time_scale = target_ts
	var real_wait := 0.055 if success else 0.038
	var t: SceneTreeTimer = get_tree().create_timer(real_wait, false, true, false)
	t.timeout.connect(func() -> void:
		Engine.time_scale = saved_ts
	)


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)
	if Engine.time_scale < 0.45:
		Engine.time_scale = 1.0
