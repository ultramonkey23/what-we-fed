extends RefCounted
class_name RunState

var run_number: int = 1
var run_in_progress: bool = false
var is_in_combat: bool = false
var last_beat_quality: String = "off"

var active_region: Dictionary = {}
var current_encounter_index: int = 0
var encounters_before_boss: int = 9
var boss_ready: bool = false
var selected_difficulty_key: String = "STANDARD"
var world_state_key: String = "DEFAULT"

var path_plan: Array[Dictionary] = []
var path_chosen_ids: PackedStringArray = PackedStringArray()
var growth_choice_intersection_payload: Dictionary = {}

func reset_run_state() -> void:
	current_encounter_index = 0
	boss_ready = false
	path_plan.clear()
	path_chosen_ids.clear()
	growth_choice_intersection_payload.clear()


func reset_profile_progression() -> void:
	run_number = 1
	run_in_progress = false
	is_in_combat = false
	last_beat_quality = "off"
	active_region = {}
	selected_difficulty_key = "STANDARD"
	world_state_key = "DEFAULT"
	reset_run_state()

func is_beat_active() -> bool:
	return last_beat_quality == "perfect" or last_beat_quality == "good"
