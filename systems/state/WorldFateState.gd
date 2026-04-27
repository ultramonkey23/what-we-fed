extends RefCounted
class_name WorldFateState

const WORLD_FATE_IDS: Array[String] = [
	"predatory_brutal",
	"mythic_hopeful",
	"sterile_technocratic",
	"haunted_ritual"
]

var channels: Dictionary = {
	"predatory_brutal": 0.0,
	"mythic_hopeful": 0.0,
	"sterile_technocratic": 0.0,
	"haunted_ritual": 0.0
}
var dominant_fate: String = "unclaimed"
var stain_fates: PackedStringArray = PackedStringArray()
var last_snapshot: Dictionary = {}

var bond_events: int = 0
var eat_events: int = 0
var pending_boss_events: Array[Dictionary] = []
var tempo_counts: Dictionary = {
	"puncture": 0,
	"void": 0,
	"decree": 0
}
var tempo_events: Array[Dictionary] = []

func reset_run_trackers() -> void:
	bond_events = 0
	eat_events = 0
	pending_boss_events.clear()
	tempo_counts = {
		"puncture": 0,
		"void": 0,
		"decree": 0
	}
	tempo_events.clear()

func get_tempo_snapshot() -> Dictionary:
	return {
		"counts": tempo_counts.duplicate(true),
		"recent_events": tempo_events.duplicate(true)
	}


func reset_profile_progression() -> void:
	for fate_id in WORLD_FATE_IDS:
		channels[fate_id] = 0.0
	dominant_fate = "unclaimed"
	stain_fates = PackedStringArray()
	last_snapshot = {}
	reset_run_trackers()
