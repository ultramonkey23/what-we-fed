extends Node2D
class_name GrowthChoiceIntersection

signal growth_choice_selected(choice_id: String)

const UI_STYLE = preload("res://systems/UIStyle.gd")
const COMBAT_DATA = preload("res://data/CombatContent.gd")
const GROWTH_STATS = preload("res://data/GrowthStats.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const INPUT_HELPER = preload("res://systems/InputHelper.gd")

var _canvas: CanvasLayer = null
var _panel: ColorRect = null
var _header_label: Label = null
var _subtitle_label: Label = null
var _summary_label: Label = null
var _creature_label: Label = null
var _bond_label: Label = null
var _eat_label: Label = null
var _stat_preview_label: Label = null
var _hint_label: Label = null
var _silhouette_rect: TextureRect = null
var _fail_safe_pass_allowed: bool = false

var _choice_locked: bool = false
var _bond_enabled: bool = true
var _eat_enabled: bool = true
var _growth_stats_ref: GrowthStats = GROWTH_STATS.new()

var _current_creature: Dictionary = {}
var _current_perf: Dictionary = {}


func _ready() -> void:
	_build_ui()
	hide_surface()


func present() -> void:
	var payload: Dictionary = RunState.growth_choice_intersection_payload
	if payload.is_empty():
		hide_surface()
		return

	_current_creature = Dictionary(payload.get("creature", {}))
	_current_perf = Dictionary(payload.get("performance", {}))
	_fail_safe_pass_allowed = bool(payload.get("fail_safe_pass_allowed", false))
	_choice_locked = false

	_bond_enabled = bool(payload.get("bond_available", true))
	_eat_enabled = bool(payload.get("eat_available", true))
	if not _bond_enabled and not _eat_enabled:
		_fail_safe_pass_allowed = true

	var species_id: String = String(_current_creature.get("species_id", ""))
	var path: String = "res://assets/sprites/silhouettes/" + species_id
	var bonded: Dictionary = GameState.get_bonded_creature(species_id)
	var creature_level: int = int(bonded.get("creature_level", 1))
	var grade_cap: int = GameState.get_creature_level_cap(species_id)
	# Adult silhouette once past teen threshold (>62% of grade cap)
	var teen_thresh: int = maxi(2, ceili(float(grade_cap) * 0.625))
	if creature_level > teen_thresh:
		path += "_adult_silhouette.png"
	else:
		path += "_baby_silhouette.png"

	if _silhouette_rect != null:
		if ResourceLoader.exists(path):
			_silhouette_rect.texture = load(path)
			_silhouette_rect.visible = true
			_silhouette_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
			_silhouette_rect.scale = Vector2(0.9, 0.9)
			_silhouette_rect.pivot_offset = _silhouette_rect.size / 2.0
			var tween: Tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(_silhouette_rect, "modulate", Color(1.0, 1.0, 1.0, 0.18), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(_silhouette_rect, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			_silhouette_rect.visible = false

	_refresh_ui_texts()

	visible = true
	if _canvas != null:
		_canvas.visible = true


func _refresh_ui_texts() -> void:
	if _current_creature.is_empty():
		return
	_header_label.text = "GROWTH INTERSECTION"
	_subtitle_label.text = "Bond or consume. Decide what this hunt means."
	_summary_label.text = _build_summary_text(_current_perf)
	_creature_label.text = _build_creature_line(_current_creature)
	_bond_label.text = _build_bond_line(_current_creature)
	_eat_label.text = _build_eat_line(_current_creature)
	_stat_preview_label.text = _build_stat_preview(_current_creature)
	_hint_label.text = _build_hint_text()


func hide_surface() -> void:
	visible = false
	if _canvas != null:
		_canvas.visible = false
	_choice_locked = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _choice_locked:
		return

	var was_joypad = INPUT_HELPER.is_joypad()
	INPUT_HELPER.mark_device_from_event(event)
	if was_joypad != INPUT_HELPER.is_joypad():
		_refresh_ui_texts()

	if event is InputEventJoypadButton and event.pressed:
		var joy_btn = event as InputEventJoypadButton
		
		# A Button (0) - Bond
		if joy_btn.button_index == JOY_BUTTON_A and _bond_enabled:
			_choice_locked = true
			emit_signal("growth_choice_selected", "bond")
			get_viewport().set_input_as_handled()
			return
			
		# X Button (2) - Eat
		if joy_btn.button_index == JOY_BUTTON_X and _eat_enabled:
			_choice_locked = true
			emit_signal("growth_choice_selected", "eat")
			get_viewport().set_input_as_handled()
			return
			
		# B Button (1) - Pass
		if joy_btn.button_index == JOY_BUTTON_B and _fail_safe_pass_allowed:
			_choice_locked = true
			emit_signal("growth_choice_selected", "pass")
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_B and _bond_enabled:
				_choice_locked = true
				emit_signal("growth_choice_selected", "bond")
				get_viewport().set_input_as_handled()
				return

			if key_event.keycode == KEY_E and _eat_enabled:
				_choice_locked = true
				emit_signal("growth_choice_selected", "eat")
				get_viewport().set_input_as_handled()
				return

			if key_event.keycode == KEY_N and _fail_safe_pass_allowed:
				_choice_locked = true
				emit_signal("growth_choice_selected", "pass")
				get_viewport().set_input_as_handled()
				return


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.01, 0.01, 0.02, 0.86)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(backdrop)

	_panel = ColorRect.new()
	_panel.position = Vector2(128.0, 86.0)
	_panel.size = Vector2(1024.0, 548.0)
	UI_STYLE.apply_shell_style(_panel, "run_overlay")
	_canvas.add_child(_panel)

	_silhouette_rect = TextureRect.new()
	_silhouette_rect.size = Vector2(300.0, 300.0)
	_silhouette_rect.position = Vector2((1024.0 - 300.0) / 2.0, 120.0)
	_silhouette_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_silhouette_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_silhouette_rect.modulate = Color(1.0, 1.0, 1.0, 0.18)
	_silhouette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_silhouette_rect)

	_header_label = Label.new()
	_header_label.position = Vector2(0.0, 18.0)
	_header_label.size = Vector2(1024.0, 42.0)
	UI_STYLE.apply_label(_header_label, "overlay_title", HORIZONTAL_ALIGNMENT_CENTER)
	_header_label.add_theme_font_size_override("font_size", 40)
	_panel.add_child(_header_label)

	_subtitle_label = Label.new()
	_subtitle_label.position = Vector2(0.0, 58.0)
	_subtitle_label.size = Vector2(1024.0, 24.0)
	UI_STYLE.apply_label(_subtitle_label, "mm_subtitle", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_subtitle_label)

	_summary_label = Label.new()
	_summary_label.position = Vector2(42.0, 104.0)
	_summary_label.size = Vector2(940.0, 96.0)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_summary_label, "overlay_body", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_summary_label)

	_creature_label = Label.new()
	_creature_label.position = Vector2(42.0, 206.0)
	_creature_label.size = Vector2(940.0, 64.0)
	_creature_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_creature_label, "hud_metric_value", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_creature_label)

	_bond_label = Label.new()
	_bond_label.position = Vector2(64.0, 286.0)
	_bond_label.size = Vector2(420.0, 138.0)
	_bond_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_bond_label, "overlay_body")
	_bond_label.add_theme_color_override("font_color", UI_STYLE.get_manga_color("bond_teal"))
	_panel.add_child(_bond_label)

	_eat_label = Label.new()
	_eat_label.position = Vector2(540.0, 286.0)
	_eat_label.size = Vector2(420.0, 138.0)
	_eat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_eat_label, "overlay_body")
	_eat_label.add_theme_color_override("font_color", UI_STYLE.get_manga_color("blood_ember"))
	_panel.add_child(_eat_label)
	
	_stat_preview_label = Label.new()
	_stat_preview_label.position = Vector2(64.0, 436.0)
	_stat_preview_label.size = Vector2(896.0, 48.0)
	_stat_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_stat_preview_label, "mm_caption", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_stat_preview_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(0.0, 486.0)
	_hint_label.size = Vector2(1024.0, 42.0)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_hint_label, "mm_hint", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_hint_label)


func _build_summary_text(perf: Dictionary) -> String:
	return "Grade %s   |   Score %d\nKills %d   |   Hits %d   |   Perfects %d   |   Support %d" % [
		String(perf.get("grade", "BARELY HELD")),
		int(perf.get("score", 0)),
		int(perf.get("kills", 0)),
		int(perf.get("hits", 0)),
		int(perf.get("perfects", 0)),
		int(perf.get("support_triggers", 0))
	]


func _build_creature_line(creature: Dictionary) -> String:
	var creature_name: String = String(creature.get("display_name", "Unknown Creature"))
	var species_id: String = String(creature.get("species_id", ""))
	var threshold: float = GameState.get_effective_dna_threshold(species_id)
	var dna_now: float = GameState.get_dna(species_id)
	var dna_line: String = "DNA %.0f / %.0f" % [dna_now, threshold]
	return "%s\n%s" % [creature_name, dna_line]


func _build_bond_line(creature: Dictionary) -> String:
	var bond_btn: String = "[A BUTTON]" if INPUT_HELPER.is_joypad() else "[B]"
	var bond_text: String = "BOND " + bond_btn + "\n"
	var species_id: String = String(creature.get("species_id", ""))

	if not _bond_enabled:
		var threshold: float = GameState.get_effective_dna_threshold(species_id)
		var missing: float = maxf(threshold - GameState.get_dna(species_id), 0.0)
		return bond_text + "Need %.0f more DNA.\nEating stays available." % missing

	var bonded: Dictionary = GameState.get_bonded_creature(species_id)
	var current_level: int = int(bonded.get("bond_level", 0))
	var next_level: int = clampi(current_level + 1, 1, 5)
	@warning_ignore("static_called_on_instance")
	var level_mult: float = GameState.get_bond_level_mult(next_level)
	var passive: String = String(creature.get("bond_passive", {}).get("summary", "Strengthen creature support."))
	var action_line: String = "New support L1" if current_level <= 0 else "Deepen to L%d" % next_level
	return "%s%s\n%s\nPower %.2fx" % [bond_text, action_line, passive, level_mult]


func _build_eat_line(creature: Dictionary) -> String:
	var eat_btn: String = "[X BUTTON]" if INPUT_HELPER.is_joypad() else "[E]"
	var eat_text: String = "EAT " + eat_btn + "\n"
	if not _eat_enabled:
		return eat_text + "Unavailable"

	var eat_effect: Dictionary = Dictionary(creature.get("eat_effect", {}))
	var mutation_summary: String = String(creature.get("mutation", {}).get("summary", ""))
	var effect_line: String = PRESENTATION_TEXT.format_eat_effect(eat_effect)
	if mutation_summary.is_empty():
		return eat_text + effect_line
	return eat_text + effect_line + "\nMutation: " + mutation_summary


func _build_stat_preview(creature: Dictionary) -> String:
	var p_type: String = String(creature.get("primary_type", "")).to_lower()
	var s_type: String = String(creature.get("secondary_type", "")).to_lower()
	
	var weights = {}
	var p_w = _growth_stats_ref.genetic_weights.get(p_type, {})
	var s_w = _growth_stats_ref.genetic_weights.get(s_type, {})
	
	for k in p_w.keys(): weights[k] = weights.get(k, 0) + p_w[k]
	for k in s_w.keys(): weights[k] = weights.get(k, 0) + s_w[k]
	
	var lines = []
	if not weights.is_empty():
		var sorted_keys = weights.keys()
		sorted_keys.sort_custom(func(a, b): return weights[a] > weights[b])
		var bias_parts = []
		for k in sorted_keys:
			bias_parts.append(k.replace("stat_", "").to_upper())
		lines.append("BOND BIAS: +Next level favors " + " · ".join(bias_parts))
	
	var eat_effect = creature.get("eat_effect", {})
	lines.append("EAT GAIN: " + PRESENTATION_TEXT.format_eat_effect(eat_effect))
	
	return "\n".join(lines)


func _build_hint_text() -> String:
	var is_pad: bool = INPUT_HELPER.is_joypad()
	var btn_bond: String = "A Button" if is_pad else "B"
	var btn_eat: String = "X Button" if is_pad else "E"
	var btn_pass: String = "B Button" if is_pad else "N"

	if _bond_enabled and _eat_enabled:
		return btn_bond + " - Bond    |    " + btn_eat + " - Eat"
	if _eat_enabled:
		var bond_lock_label = "A Button locked by DNA" if is_pad else "B locked by DNA"
		return bond_lock_label + "    |    " + btn_eat + " - Eat    |    " + btn_pass + " - Pass"
	if _fail_safe_pass_allowed:
		return btn_pass + " - Fail-safe pass (no valid DNA spend path)"
	return "Awaiting valid growth choice"
