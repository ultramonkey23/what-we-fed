extends Node2D

signal growth_choice_selected(choice_id: String)

const UI_STYLE = preload("res://systems/UIStyle.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")

var _canvas: CanvasLayer = null
var _panel: ColorRect = null
var _header_label: Label = null
var _subtitle_label: Label = null
var _summary_label: Label = null
var _creature_label: Label = null
var _bond_label: Label = null
var _eat_label: Label = null
var _hint_label: Label = null
var _fail_safe_pass_allowed: bool = false

var _choice_locked: bool = false
var _bond_enabled: bool = true
var _eat_enabled: bool = true


func _ready() -> void:
	_build_ui()
	hide_surface()


func present() -> void:
	var payload: Dictionary = GameState.growth_choice_intersection_payload
	if payload.is_empty():
		hide_surface()
		return

	var creature: Dictionary = Dictionary(payload.get("creature", {}))
	var perf: Dictionary = Dictionary(payload.get("performance", {}))
	_fail_safe_pass_allowed = bool(payload.get("fail_safe_pass_allowed", false))
	_choice_locked = false

	_bond_enabled = bool(payload.get("bond_available", true))
	_eat_enabled = bool(payload.get("eat_available", true))
	if not _bond_enabled and not _eat_enabled:
		_fail_safe_pass_allowed = true

	_header_label.text = "GROWTH INTERSECTION"
	_subtitle_label.text = "Bond or consume. Decide what this hunt means."
	_summary_label.text = _build_summary_text(perf)
	_creature_label.text = _build_creature_line(creature)
	_bond_label.text = _build_bond_line(creature)
	_eat_label.text = _build_eat_line(creature)
	_hint_label.text = _build_hint_text()

	visible = true
	if _canvas != null:
		_canvas.visible = true


func hide_surface() -> void:
	visible = false
	if _canvas != null:
		_canvas.visible = false
	_choice_locked = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _choice_locked:
		return
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

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


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.01, 0.01, 0.02, 0.93)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(backdrop)

	_panel = ColorRect.new()
	_panel.position = Vector2(128.0, 86.0)
	_panel.size = Vector2(1024.0, 548.0)
	UI_STYLE.apply_shell_style(_panel, "mm_command")
	_canvas.add_child(_panel)

	_header_label = Label.new()
	_header_label.position = Vector2(0.0, 18.0)
	_header_label.size = Vector2(1024.0, 42.0)
	UI_STYLE.apply_label(_header_label, "mm_title", HORIZONTAL_ALIGNMENT_CENTER)
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
	UI_STYLE.apply_label(_summary_label, "mm_body", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_summary_label)

	_creature_label = Label.new()
	_creature_label.position = Vector2(42.0, 206.0)
	_creature_label.size = Vector2(940.0, 64.0)
	_creature_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_creature_label, "mm_stat_primary", HORIZONTAL_ALIGNMENT_CENTER)
	_panel.add_child(_creature_label)

	_bond_label = Label.new()
	_bond_label.position = Vector2(64.0, 286.0)
	_bond_label.size = Vector2(420.0, 178.0)
	_bond_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_bond_label, "mm_choice_bond")
	_panel.add_child(_bond_label)

	_eat_label = Label.new()
	_eat_label.position = Vector2(540.0, 286.0)
	_eat_label.size = Vector2(420.0, 178.0)
	_eat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_eat_label, "mm_choice_consume")
	_panel.add_child(_eat_label)

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
	var threshold: float = float(creature.get("dna_threshold", 0.0))
	var dna_now: float = GameState.get_dna(species_id)
	var dna_line: String = "DNA %.0f / %.0f" % [dna_now, threshold]
	return "%s\n%s" % [creature_name, dna_line]


func _build_bond_line(creature: Dictionary) -> String:
	var bond_text: String = "BOND [B]\n"
	if not _bond_enabled:
		return bond_text + "Unavailable"

	var bond_level: int = int(creature.get("bond_level", 1))
	@warning_ignore("static_called_on_instance")
	var level_mult: float = GameState.get_bond_level_mult(bond_level)
	var passive: String = String(creature.get("bond_passive", {}).get("summary", "Strengthen creature support."))
	return "%s%s\nPower %.2fx" % [bond_text, passive, level_mult]


func _build_eat_line(creature: Dictionary) -> String:
	var eat_text: String = "EAT [E]\n"
	if not _eat_enabled:
		return eat_text + "Unavailable"

	var eat_effect: Dictionary = Dictionary(creature.get("eat_effect", {}))
	var eat_type: String = String(eat_effect.get("type", "damage_flat"))
	var eat_value: float = float(eat_effect.get("value", 0.0))
	var mutation_summary: String = String(creature.get("mutation", {}).get("summary", ""))
	var effect_line: String = "%s %.1f" % [eat_type, eat_value]
	if mutation_summary.is_empty():
		return eat_text + effect_line
	return eat_text + effect_line + "\nMutation: " + mutation_summary


func _build_hint_text() -> String:
	if _bond_enabled and _eat_enabled:
		return "B - Bond    |    E - Eat"
	if _fail_safe_pass_allowed:
		return "N - Fail-safe pass (no valid DNA spend path)"
	return "Awaiting valid growth choice"
