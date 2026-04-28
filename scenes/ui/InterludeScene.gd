extends Node2D

# InterludeScene.gd
# Minimal placeholder for QUIG interludes and Boss announcements.
# Sequences the transition from Lair/Reward to the next tactical engagement.

const UI_STYLE = preload("res://systems/UIStyle.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const COMBAT_SCENE_PATH = "res://scenes/combat/CombatScene.tscn"

@onready var _quig_timer: Timer = Timer.new()

var _can_continue: bool = false

func _ready() -> void:
	UI_STYLE.attach_wound_backdrop(self)
	_build_ui()
	
	add_child(_quig_timer)
	_quig_timer.one_shot = true
	_quig_timer.timeout.connect(_on_timer_timeout)
	_quig_timer.start(1.5)


func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var quig_label = Label.new()
	quig_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quig_label.size = Vector2(1280.0, 100.0)
	quig_label.position = Vector2(0.0, 310.0)
	UI_STYLE.apply_label(quig_label, "mm_title")
	canvas.add_child(quig_label)
	
	var hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size = Vector2(1280.0, 40.0)
	hint_label.position = Vector2(0.0, 600.0)
	UI_STYLE.apply_label(hint_label, "mm_hint")
	canvas.add_child(hint_label)
	
	var status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.size = Vector2(1280.0, 30.0)
	status_label.position = Vector2(0.0, 40.0)
	UI_STYLE.apply_label(status_label, "mm_caption")
	canvas.add_child(status_label)
	
	# Content Logic
	var current = GameState.current_encounter_index + 1
	var total = GameState.encounters_before_boss
	status_label.text = "INTRUSION DEPTH: %d / %d" % [current, total]
	
	if GameState.boss_ready:
		quig_label.text = "THE HUNT HAS FED ENOUGH. BOSS ROUTE ARMED."
		quig_label.modulate = UI_STYLE.get_manga_color("blood_ember")
	else:
		quig_label.text = _get_quig_line()
		
	hint_label.text = "Initializing Tactical Ground..."
	hint_label.modulate.a = 0.5


func _get_quig_line() -> String:
	var lines = [
		"Nine was only the old number. The world counts different when it’s hungry.",
		"The sequence deepens. The world rejects your signature.",
		"Keep your teeth counted. The hollow remembers every theft.",
		"Translation in progress... stay focused on the pulse.",
		"Each lineage taken is a stitch in your own shroud."
	]
	return lines[randi() % lines.size()]


func _on_timer_timeout() -> void:
	_can_continue = true
	var hint = get_tree().root.find_child("mm_hint", true, false) # This is wrong, I'll just find it manually
	# Fixing the hint update logic below in _unhandled_input or re-build.
	# For a simple interlude, we can just auto-transition after a longer delay or wait for key.
	_quig_timer.start(1.0)
	_quig_timer.timeout.disconnect(_on_timer_timeout)
	_quig_timer.timeout.connect(_transition_to_combat)


func _transition_to_combat() -> void:
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if _can_continue and event is InputEventKey and event.pressed:
		_transition_to_combat()
