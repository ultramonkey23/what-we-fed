extends Node2D

# TranslationScene.gd (Renamed from InterludeScene)
# Sovereign Translation Layer - Sequences the transition between tactical engagements.
# Shows "Lineage Extraction Summary" (Stats + Growth gains).

const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const COMBAT_SCENE_PATH = "res://scenes/combat/CombatScene.tscn"

@onready var _quig_timer: Timer = Timer.new()

var _can_continue: bool = false
var _scroll: ScrollContainer = null
var _body_label: Label = null

var RunStats: Node:
	get: return get_node_or_null("/root/RunStats")
var RunGrowth: Node:
	get: return get_node_or_null("/root/RunGrowth")

func _ready() -> void:
	UI_STYLE.attach_wound_backdrop(self)
	_build_ui()
	_populate_extraction_summary()
	
	add_child(_quig_timer)
	_quig_timer.one_shot = true
	_quig_timer.timeout.connect(_on_timer_timeout)
	_quig_timer.start(2.0)


func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var header = Label.new()
	header.text = "LINEAGE EXTRACTION COMPLETE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(1280.0, 60.0)
	header.position = Vector2(0.0, 80.0)
	UI_STYLE.apply_label(header, "mm_title")
	header.add_theme_color_override("font_color", UI_STYLE.get_manga_color("blood_ember"))
	canvas.add_child(header)
	
	var subtitle = Label.new()
	var current = GameState.current_encounter_index + 1
	var total = GameState.encounters_before_boss
	subtitle.text = "TRANSLATION DEPTH: %d / %d" % [current, total]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size = Vector2(1280.0, 30.0)
	subtitle.position = Vector2(0.0, 140.0)
	UI_STYLE.apply_label(subtitle, "mm_caption")
	canvas.add_child(subtitle)

	_scroll = ScrollContainer.new()
	_scroll.size = Vector2(800.0, 300.0)
	_scroll.position = Vector2(240.0, 220.0)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(_scroll)

	_body_label = Label.new()
	_body_label.custom_minimum_size = Vector2(800.0, 0.0)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_body_label, "mm_body")
	_body_label.add_theme_font_size_override("font_size", 14)
	_scroll.add_child(_body_label)
	
	var hint_label = Label.new()
	hint_label.name = "mm_hint"
	hint_label.text = "Synchronizing Pattern..."
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size = Vector2(1280.0, 40.0)
	hint_label.position = Vector2(0.0, 600.0)
	UI_STYLE.apply_label(hint_label, "mm_hint")
	hint_label.modulate.a = 0.5
	canvas.add_child(hint_label)


func _populate_extraction_summary() -> void:
	var lines: Array[String] = []
	
	if RunStats:
		lines.append("[ FEED PERFORMANCE ]")
		lines.append("- Marks Extracted: %d" % int(RunStats.combat_kills))
		lines.append("- Damage Output: %.0f" % float(RunStats.combat_damage))
		lines.append("- Perfect Syncs: %d" % int(RunStats.combat_perfects))
		if int(RunStats.combat_hits) == 0:
			lines.append("- Vessel Integrity: UNTOUCHED (+Bonus)")
		else:
			lines.append("- Vessel Breaches: %d" % int(RunStats.combat_hits))
		lines.append("")

	if RunGrowth:
		var gains = RunGrowth.get_gains_this_combat()
		if not gains.is_empty():
			lines.append("[ GROWTH EVOLVED ]")
			for gain in gains:
				var title = str(gain.get("title", "LEVEL UP"))
				var summary = str(gain.get("summary", ""))
				lines.append("- %s: %s" % [title, summary])
			lines.append("")
	
	if lines.is_empty():
		lines.append("No lineage data extracted.")
	
	_body_label.text = "\n".join(PackedStringArray(lines))


func _on_timer_timeout() -> void:
	_can_continue = true
	var hint = find_child("mm_hint", true, false)
	if hint:
		hint.text = "PRESS ANY KEY TO RE-INSTANTIATE"
		hint.modulate.a = 1.0


func _transition_to_combat() -> void:
	# Before leaving, clear the combat-specific gains
	if RunGrowth:
		RunGrowth.clear_combat_gains()
		
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if _can_continue and event is InputEventKey and event.pressed:
		_transition_to_combat()
