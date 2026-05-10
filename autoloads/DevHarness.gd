extends Node

## SOVEREIGN DIAGNOSTIC HUB (v3.0)
## High-authority monitoring for Signal Purity, Pulse Alignment, and Soul Integrity.

var soul_manifest: Dictionary = {}

# --- METRICS ---
var _pulse_deltas: Array[float] = []
var _signal_fractures: Array[Dictionary] = []
var _pending_request: Dictionary = {}
var _start_time_msec: int = 0

# --- CONFIG ---
const PULSE_HISTORY_LIMIT: int = 60
const FRACTURE_LIMIT: int = 100

func _ready() -> void:
	_start_time_msec = Time.get_ticks_msec()
	
	if FileAccess.file_exists("res://docs/ai/SOUL_MANIFEST.json"):
		var file = FileAccess.open("res://docs/ai/SOUL_MANIFEST.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				soul_manifest = json.data
	
	_connect_monitoring()
	print("[SOVEREIGN] Diagnostic Hub v3.0 Initialized.")


func _connect_monitoring() -> void:
	# Listen to core signals to track "Pulse Alignment" (Timing accuracy)
	if EventBus.has_signal("combat_input_resolved"):
		EventBus.combat_input_resolved.connect(_monitor_input_timing)
	if EventBus.has_signal("song_beat_pulse"):
		EventBus.song_beat_pulse.connect(_monitor_beat_alignment)


# --- PULSE MONITORING ---
func _monitor_input_timing(action: String, sector: int, accepted: bool, _buffered: bool, reason: String, _state: String, _cooldowns: Dictionary) -> void:
	if not accepted and reason != "no_stamina":
		_record_fracture("INPUT_REJECTION", {"action": action, "lane": sector, "reason": reason})


func _monitor_beat_alignment(_beat_index: int, intensity: float, quality: String) -> void:
	# Records the "Soul Pulse" strength
	if quality == "perfect":
		_pulse_deltas.append(intensity)
		if _pulse_deltas.size() > PULSE_HISTORY_LIMIT:
			_pulse_deltas.remove_at(0)


# --- FRACTURE TRACKING ---
func _record_fracture(type: String, data: Dictionary) -> void:
	var entry := {
		"timestamp": (Time.get_ticks_msec() - _start_time_msec) / 1000.0,
		"type": type,
		"data": data,
		"scene": str(get_tree().current_scene.name) if get_tree() != null and get_tree().current_scene != null else "UNKNOWN"
	}
	_signal_fractures.append(entry)
	if _signal_fractures.size() > FRACTURE_LIMIT:
		_signal_fractures.remove_at(0)
	
	print("[SOVEREIGN FRACTURE] %s: %s" % [type, JSON.stringify(data)])


# --- PUBLIC API (FOR AGENTS) ---

func get_diagnostic_report() -> Dictionary:
	return {
		"session_uptime": (Time.get_ticks_msec() - _start_time_msec) / 1000.0,
		"pulse_avg_intensity": _get_avg_pulse(),
		"fracture_count": _signal_fractures.size(),
		"recent_fractures": _signal_fractures.slice(-5),
		"state_consistency": _verify_state_consistency()
	}


func _get_avg_pulse() -> float:
	if _pulse_deltas.is_empty(): return 0.0
	var sum: float = 0.0
	for d in _pulse_deltas: sum += d
	return sum / _pulse_deltas.size()


func _verify_state_consistency() -> String:
	if GameState == null: return "STALE: GameState Missing"
	if GameState.player_hp <= 0 and GameState.run_in_progress:
		return "FRACTURE: Ghost Run Detected (Dead player in active run)"
	return "STABLE"


# --- LEGACY HARNESS API ---

func queue_request(request: Dictionary) -> void:
	_pending_request = request.duplicate(true)


func has_pending_request() -> bool:
	return not _pending_request.is_empty()


func get_pending_request() -> Dictionary:
	return _pending_request.duplicate(true)


func clear_request() -> void:
	_pending_request.clear()
