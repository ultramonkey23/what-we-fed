extends Node

signal song_started(song_state: Dictionary)
signal transport_state_changed(is_running: bool, song_time: float)
signal section_changed(section_id: String, data: Dictionary)
signal beat_pulse(beat_index: int, quality: String, intensity: float, song_time: float)
signal final_movement_reached()
signal accent_fired()

# Public readable state — safe for polling.
var current_song_id: String = ""
var current_bpm: float = 0.0
var current_intensity: float = 0.0
var current_spawn_mult: float = 1.0
var current_section_id: String = ""
var current_cadence_window: String = ""

var beat_perfect_window: float = 0.065
var beat_good_window: float = 0.130

const DEFAULT_CADENCE_WINDOW_RULES: Array = [
	{"window": "surge", "section_ids": ["final"], "intensity_gte": 0.85},
	{"window": "drive", "section_ids": ["chorus"], "intensity_gte": 0.62}
]

var _stream_player: AudioStreamPlayer = null
var _sections: Array = []
var _current_section_idx: int = -1
var _final_movement_time: float = 9999.0
var _window_start_time: float = 0.0
var _window_end_time: float = 9999.0
var _final_triggered: bool = false
var _song_duration: float = 0.0
var _running: bool = false
var _song_path: String = ""

var _beat_interval: float = 0.0
var _last_emitted_beat: int = -1
var _cadence_window_rules: Array = DEFAULT_CADENCE_WINDOW_RULES.duplicate(true)

var _analyzer: AudioEffectSpectrumAnalyzerInstance = null
var _bus_index: int = -1
var _low_pass_idx: int = -1
var _accent_threshold: float = 0.5
var _accent_cooldown: float = 0.0


func _exit_tree() -> void:
	_stop_and_release_player()
	_release_analysis_bus()


func start(song_map_script, start_time: float = 0.0, window_end_time: float = -1.0, silent: bool = false, options: Dictionary = {}) -> void:
	_stop_and_release_player()
	_analyzer = null

	current_song_id = String(options.get("song_id", ""))
	_song_path = String(song_map_script.SONG_PATH)
	var stream: AudioStream = ResourceLoader.load(_song_path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
	if stream == null:
		push_error("SongConductor: failed to load audio stream: " + _song_path)
		return

	_ensure_analysis_bus()
	_attach_player(stream, silent)

	_song_duration = stream.get_length()
	if _song_duration <= 0.0:
		push_error("SongConductor: stream reports zero length for " + _song_path)
		_song_duration = 240.0

	var final_fraction: float = float(song_map_script.FINAL_MOVEMENT_FRACTION)
	_final_movement_time = final_fraction * _song_duration

	var profile_accent_threshold: float = float(options.get("accent_threshold", -1.0))
	if profile_accent_threshold >= 0.0:
		_accent_threshold = profile_accent_threshold
	elif "BASS_ACCENT_THRESHOLD" in song_map_script:
		_accent_threshold = float(song_map_script.BASS_ACCENT_THRESHOLD)
	else:
		_accent_threshold = 0.5

	_sections = []
	for raw in song_map_script.SECTIONS:
		var section_data: Dictionary = Dictionary(raw).duplicate(true)
		section_data["start_time"] = float(section_data.get("start_fraction", 0.0)) * _song_duration
		_sections.append(section_data)

	_cadence_window_rules = Array(options.get("cadence_window_rules", DEFAULT_CADENCE_WINDOW_RULES)).duplicate(true)
	if _cadence_window_rules.is_empty():
		_cadence_window_rules = DEFAULT_CADENCE_WINDOW_RULES.duplicate(true)

	var clamped_start_time: float = clampf(start_time, 0.0, max(_song_duration - 0.05, 0.0))
	_window_start_time = clamped_start_time
	_window_end_time = _final_movement_time
	if window_end_time > 0.0:
		_window_end_time = clampf(window_end_time, _window_start_time + 0.05, _song_duration)
	_current_section_idx = -1
	_final_triggered = false
	_last_emitted_beat = -1
	current_intensity = 0.0
	current_spawn_mult = 1.0
	current_section_id = ""
	for i in range(_sections.size()):
		if clamped_start_time >= float(_sections[i].get("start_time", 0.0)):
			_current_section_idx = i
			current_intensity = float(_sections[i].get("intensity", 0.0))
			current_spawn_mult = float(_sections[i].get("spawn_interval_mult", 1.0))
			current_section_id = String(_sections[i].get("id", ""))
		else:
			break
	current_cadence_window = resolve_cadence_window(current_section_id, current_intensity)

	_beat_interval = 0.0
	current_bpm = 0.0
	if "BPM" in song_map_script:
		current_bpm = float(song_map_script.BPM)
		if current_bpm > 0.0:
			_beat_interval = 60.0 / current_bpm

	_running = true
	_stream_player.play(clamped_start_time)

	var initial_beat: int = get_beat_count()
	_last_emitted_beat = initial_beat - 1
	song_started.emit(build_song_state())
	transport_state_changed.emit(true, clamped_start_time)


func set_void_filter(active: bool) -> void:
	if _bus_index == -1 or _low_pass_idx == -1:
		return
	var lp: AudioEffectLowPassFilter = AudioServer.get_bus_effect(_bus_index, _low_pass_idx) as AudioEffectLowPassFilter
	if lp != null:
		lp.cutoff_hz = 1200.0 if active else 20000.0


func pause() -> void:
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.stream_paused = true
	_running = false
	transport_state_changed.emit(false, get_song_time())


func resume() -> void:
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.stream_paused = false
	_running = true
	transport_state_changed.emit(true, get_song_time())


func stop() -> void:
	_running = false
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.stop()
	_analyzer = null
	transport_state_changed.emit(false, get_song_time())


func get_song_time() -> float:
	if _stream_player == null or not is_instance_valid(_stream_player):
		return 0.0
	var playback_position: float = _stream_player.get_playback_position()
	if not _running or not _stream_player.playing:
		return playback_position
	return playback_position + AudioServer.get_time_since_last_mix()


func get_song_duration() -> float:
	return _song_duration


func get_final_movement_time() -> float:
	return _window_end_time


func is_beat_active() -> bool:
	return _running and _beat_interval > 0.0


func get_beat_count() -> int:
	if not is_beat_active():
		return 0
	return int(floor(get_song_time() / _beat_interval))


func get_beat_phase() -> float:
	if not is_beat_active():
		return 0.0
	return fmod(get_song_time(), _beat_interval) / _beat_interval


func get_beat_quality() -> String:
	if not is_beat_active():
		return "off"
	var phase: float = get_beat_phase()
	
	# Timing Truth: dist_seconds is the absolute distance to the nearest beat.
	var dist_phase: float = phase if phase <= 0.5 else 1.0 - phase
	var dist_seconds: float = dist_phase * _beat_interval
	
	if dist_seconds <= beat_perfect_window:
		return "perfect"
	
	# Coyote Beat: provide leniency for slightly LATE inputs.
	# Inputs just after the beat (phase < 0.2) get the coyote window.
	var late_leniency: float = 0.0
	if phase > 0.0 and phase < 0.2:
		late_leniency = 0.045 # The Coyote Beat window.
		
	if dist_seconds <= (beat_good_window + late_leniency):
		return "good"
		
	return "off"


func get_bass_magnitude() -> float:
	if _analyzer == null:
		return 0.0
	var mag: float = _analyzer.get_magnitude_for_frequency_range(20, 200).length()
	return clampf(mag * 2.0, 0.0, 1.0)


func get_mid_magnitude() -> float:
	if _analyzer == null:
		return 0.0
	var mag: float = _analyzer.get_magnitude_for_frequency_range(200, 2000).length()
	return clampf(mag * 2.0, 0.0, 1.0)


func resolve_cadence_window(section_id: String, intensity: float) -> String:
	for raw_rule in _cadence_window_rules:
		var rule: Dictionary = Dictionary(raw_rule)
		var required_sections: Array = Array(rule.get("section_ids", []))
		if not required_sections.is_empty() and not required_sections.has(section_id):
			continue
		if intensity < float(rule.get("intensity_gte", 0.0)):
			continue
		var window_id: String = String(rule.get("window", ""))
		if not window_id.is_empty():
			return window_id
	return ""


func build_song_state() -> Dictionary:
	return {
		"song_id": current_song_id,
		"song_path": _song_path,
		"bpm": current_bpm,
		"song_time": get_song_time(),
		"song_duration": _song_duration,
		"window_start_time": _window_start_time,
		"window_end_time": _window_end_time,
		"section_id": current_section_id,
		"section_intensity": current_intensity,
		"spawn_interval_mult": current_spawn_mult,
		"cadence_window": current_cadence_window
	}


func _process(delta: float) -> void:
	if not _running or _stream_player == null:
		return

	var song_time: float = get_song_time()
	_update_section_state(song_time)
	_emit_beat_events(song_time)
	_handle_final_movement(song_time)
	_update_accent_state(delta)


func _update_section_state(song_time: float) -> void:
	var next_idx: int = _current_section_idx + 1
	while next_idx < _sections.size():
		var next_section: Dictionary = Dictionary(_sections[next_idx])
		if song_time >= float(next_section.get("start_time", 9999.0)):
			_current_section_idx = next_idx
			current_intensity = float(next_section.get("intensity", 0.0))
			current_spawn_mult = float(next_section.get("spawn_interval_mult", 1.0))
			current_section_id = String(next_section.get("id", ""))
			current_cadence_window = resolve_cadence_window(current_section_id, current_intensity)
			section_changed.emit(current_section_id, next_section)
			next_idx += 1
		else:
			break


func _emit_beat_events(song_time: float) -> void:
	if not is_beat_active():
		return
	var current_beat: int = get_beat_count()
	if current_beat < _last_emitted_beat:
		_last_emitted_beat = current_beat
		return
	while _last_emitted_beat < current_beat:
		_last_emitted_beat += 1
		var quality: String = get_beat_quality()
		beat_pulse.emit(_last_emitted_beat, quality, clampf(current_intensity, 0.0, 1.0), song_time)


func _handle_final_movement(song_time: float) -> void:
	if not _final_triggered and song_time >= _window_end_time:
		_final_triggered = true
		final_movement_reached.emit()


func _update_accent_state(delta: float) -> void:
	if _accent_cooldown > 0.0:
		_accent_cooldown -= delta

	if is_beat_active() and _accent_cooldown <= 0.0:
		var bass: float = get_bass_magnitude()
		if bass >= _accent_threshold:
			accent_fired.emit()
			_accent_cooldown = _beat_interval * 0.5


func _ensure_analysis_bus() -> void:
	var bus_name: String = "MusicAnalysis"
	_bus_index = AudioServer.get_bus_index(bus_name)
	if _bus_index == -1:
		_bus_index = AudioServer.bus_count
		AudioServer.add_bus(_bus_index)
		AudioServer.set_bus_name(_bus_index, bus_name)
		AudioServer.set_bus_send(_bus_index, "Master")

	var spectrum_idx: int = -1
	_low_pass_idx = -1
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		var effect: AudioEffect = AudioServer.get_bus_effect(_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_idx = i
		elif effect is AudioEffectLowPassFilter:
			_low_pass_idx = i

	if spectrum_idx == -1:
		AudioServer.add_bus_effect(_bus_index, AudioEffectSpectrumAnalyzer.new())
		spectrum_idx = AudioServer.get_bus_effect_count(_bus_index) - 1

	if _low_pass_idx == -1:
		var low_pass: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
		low_pass.cutoff_hz = 20000.0
		AudioServer.add_bus_effect(_bus_index, low_pass)
		_low_pass_idx = AudioServer.get_bus_effect_count(_bus_index) - 1

	_analyzer = AudioServer.get_bus_effect_instance(_bus_index, spectrum_idx)


func _attach_player(stream: AudioStream, silent: bool) -> void:
	_stream_player = AudioStreamPlayer.new()
	_stream_player.name = "MusicPlayer"
	_stream_player.stream = stream
	_stream_player.bus = "MusicAnalysis"
	_stream_player.volume_db = -80.0 if silent else 0.0
	add_child(_stream_player)


func _stop_and_release_player() -> void:
	_running = false
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.stop()
		_stream_player.stream = null
		_stream_player.queue_free()
	_stream_player = null


func _release_analysis_bus() -> void:
	_analyzer = null
	if _bus_index < 0 or _bus_index >= AudioServer.bus_count:
		_bus_index = -1
		_low_pass_idx = -1
		return
	if AudioServer.get_bus_name(_bus_index) == "MusicAnalysis":
		AudioServer.remove_bus(_bus_index)
	_bus_index = -1
	_low_pass_idx = -1
