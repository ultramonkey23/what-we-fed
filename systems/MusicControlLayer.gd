extends RefCounted
class_name MusicControlLayer

# MusicControlLayer (v1)
# Converts raw song + phrase events into bounded combat-facing music state.

const ACCENT_WINDOW_SECONDS: float = 0.95
const ESCALATION_WINDOW_SECONDS: float = 5.0
const DEFAULT_CADENCE_WINDOW_RULES: Array = [
	{"window": "surge", "section_ids": ["final"], "intensity_gte": 0.85},
	{"window": "drive", "section_ids": ["chorus"], "intensity_gte": 0.62}
]

var _bpm: float = 120.0
var _section_id: String = "opening"
var _section_intensity: float = 0.0
var _phrase_count: int = 0
var _accent_window: float = 0.0
var _escalation_window: float = 0.0
var _cadence_window_rules: Array = DEFAULT_CADENCE_WINDOW_RULES.duplicate(true)


func reset() -> void:
	_bpm = 120.0
	_section_id = "opening"
	_section_intensity = 0.0
	_phrase_count = 0
	_accent_window = 0.0
	_escalation_window = 0.0
	_cadence_window_rules = DEFAULT_CADENCE_WINDOW_RULES.duplicate(true)


func configure(song_profile: Dictionary) -> void:
	var contract: Dictionary = Dictionary(song_profile.get("conductor_contract", {}))
	var rules: Array = Array(contract.get("cadence_window_rules", []))
	if rules.is_empty():
		_cadence_window_rules = DEFAULT_CADENCE_WINDOW_RULES.duplicate(true)
	else:
		_cadence_window_rules = rules.duplicate(true)


func set_bpm(bpm: float) -> void:
	_bpm = maxf(bpm, 1.0)


func notify_section(section_id: String, data: Dictionary) -> void:
	_section_id = section_id
	_section_intensity = clampf(float(data.get("intensity", 0.0)), 0.0, 1.0)
	if section_id == "chorus" or section_id == "final":
		_escalation_window = maxf(_escalation_window, ESCALATION_WINDOW_SECONDS)


func notify_phrase_marker(count: int) -> void:
	_phrase_count = maxi(count, 0)
	if _phrase_count >= 5:
		_escalation_window = maxf(_escalation_window, 2.2)


func notify_accent() -> void:
	_accent_window = ACCENT_WINDOW_SECONDS
	if _section_intensity >= 0.70 or _phrase_count >= 5:
		_escalation_window = maxf(_escalation_window, 1.4)


func process_tick(delta: float) -> void:
	_accent_window = maxf(_accent_window - delta, 0.0)
	_escalation_window = maxf(_escalation_window - delta, 0.0)


func build_state() -> Dictionary:
	return {
		"tempo_band": _resolve_tempo_band(_bpm),
		"bpm": _bpm,
		"phrase_intensity": clampf(float(_phrase_count) / 8.0, 0.0, 1.0),
		"section_mood": _resolve_section_mood(_section_id, _section_intensity),
		"cadence_window": resolve_cadence_window(),
		"section_id": _section_id,
		"section_intensity": _section_intensity,
		"accent_window": clampf(_accent_window / ACCENT_WINDOW_SECONDS, 0.0, 1.0),
		"escalation_window": clampf(_escalation_window / ESCALATION_WINDOW_SECONDS, 0.0, 1.0)
	}


func _resolve_tempo_band(bpm: float) -> String:
	if bpm >= 138.0:
		return "fast"
	if bpm >= 108.0:
		return "mid"
	return "slow"


func _resolve_section_mood(section_id: String, intensity: float) -> String:
	if section_id == "final":
		return "surge"
	if section_id == "chorus":
		return "drive"
	if section_id == "breakdown":
		return "lull"
	if intensity >= 0.70:
		return "surge"
	if intensity >= 0.45:
		return "build"
	return "steady"


func resolve_cadence_window() -> String:
	for rule in _cadence_window_rules:
		var entry: Dictionary = Dictionary(rule)
		var required_sections: Array = Array(entry.get("section_ids", []))
		if not required_sections.is_empty() and not required_sections.has(_section_id):
			continue
		if _section_intensity < float(entry.get("intensity_gte", 0.0)):
			continue
		var window_id: String = String(entry.get("window", ""))
		if not window_id.is_empty():
			return window_id
	return ""
