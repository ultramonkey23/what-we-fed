extends RefCounted
class_name RunState

var run_number: int = 1
var run_in_progress: bool = false
var is_in_combat: bool = false
var last_beat_quality: String = "off"

var active_region: Dictionary = {}
var path_plan: Array[Dictionary] = []
var path_chosen_ids: PackedStringArray = PackedStringArray()
var growth_choice_intersection_payload: Dictionary = {}

func reset_run_state() -> void:
	path_plan.clear()
	path_chosen_ids.clear()
	growth_choice_intersection_payload.clear()

func is_beat_active() -> bool:
	return last_beat_quality == "perfect" or last_beat_quality == "good"
