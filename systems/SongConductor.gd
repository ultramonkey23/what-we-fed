extends Node

# SongConductor v1 — music-driven combat pressure layer.
#
# Usage:
#   var conductor = SongConductorScript.new()
#   add_child(conductor)
#   conductor.section_changed.connect(_on_section_changed)
#   conductor.final_movement_reached.connect(_on_final_movement)
#   conductor.start(TrickySongMap)
#
# The conductor plays the song asset, tracks its position, and emits
# section_changed as authored section boundaries are crossed.
# CombatScene uses section_changed to drive _enter_song_phase() and to
# apply the section's spawn_interval_mult on top of the region phase baseline.
# final_movement_reached replaces the old SONG_CONTENT.SONG_DURATION clock check
# so the boss always triggers at the musically authored climax point.
#
# V1 limits (known, acceptable):
# - No waveform beat detection — sections are authored by fraction; beat quality uses authored BPM.
# - CombatScene owns higher-level handoff and restart state.
#   Routine reward and growth flow should stay live and not pause the conductor.
# - One song map active at a time — no crossfade or layering.

signal section_changed(section_id: String, data: Dictionary)
signal final_movement_reached()

# Public readable state — safe to poll from CombatScene each frame.
var current_intensity: float = 0.0
var current_spawn_mult: float = 1.0
var current_section_id: String = ""

var _stream_player: AudioStreamPlayer = null
var _sections: Array = []          # sections with computed absolute start_time
var _current_section_idx: int = -1
var _final_movement_time: float = 9999.0
var _final_triggered: bool = false
var _song_duration: float = 0.0
var _running: bool = false

# Beat tracking — populated from the song map's BPM constant if present.
# Used by CombatScene to evaluate whether a player action landed on-beat.
# BEAT_PERFECT_WINDOW: within ±65 ms of a beat = "perfect"
# BEAT_GOOD_WINDOW:    within ±130 ms of a beat = "good"
const BEAT_PERFECT_WINDOW: float = 0.065
const BEAT_GOOD_WINDOW: float    = 0.130
var _beat_interval: float = 0.0  # seconds per beat; 0 = no BPM defined for this map


func start(song_map_script) -> void:
	# song_map_script — a preloaded RefCounted script with SONG_PATH, SECTIONS,
	# and FINAL_MOVEMENT_FRACTION constants (see data/song_maps/tricky_songmap.gd).

	# Clean up any previous player.
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.queue_free()
		_stream_player = null

	var song_path: String = String(song_map_script.SONG_PATH)
	var stream: AudioStream = load(song_path)
	if stream == null:
		push_error("SongConductor: failed to load audio stream: " + song_path)
		return

	_stream_player = AudioStreamPlayer.new()
	_stream_player.name = "MusicPlayer"
	_stream_player.stream = stream
	_stream_player.volume_db = 0.0
	add_child(_stream_player)

	_song_duration = stream.get_length()
	if _song_duration <= 0.0:
		push_error("SongConductor: stream reports zero length for " + song_path)
		_song_duration = 240.0  # fallback so fractions still produce usable times

	var final_fraction: float = float(song_map_script.FINAL_MOVEMENT_FRACTION)
	_final_movement_time = final_fraction * _song_duration

	# Build sections with absolute start_time computed from fractions.
	_sections = []
	for raw in song_map_script.SECTIONS:
		var s: Dictionary = raw.duplicate(true)
		s["start_time"] = float(s.get("start_fraction", 0.0)) * _song_duration
		_sections.append(s)

	_current_section_idx = -1
	_final_triggered = false
	current_intensity = 0.0
	current_spawn_mult = 1.0
	current_section_id = ""

	# Beat interval from the song map's BPM constant, if defined.
	_beat_interval = 0.0
	if "BPM" in song_map_script:
		var bpm: float = float(song_map_script.BPM)
		if bpm > 0.0:
			_beat_interval = 60.0 / bpm

	_running = true
	_stream_player.play()


func pause() -> void:
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.stream_paused = true
	_running = false


func resume() -> void:
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.stream_paused = false
	_running = true


func stop() -> void:
	_running = false
	if _stream_player != null and is_instance_valid(_stream_player):
		_stream_player.stop()


func get_song_time() -> float:
	if _stream_player == null or not is_instance_valid(_stream_player):
		return 0.0
	return _stream_player.get_playback_position()


func get_song_duration() -> float:
	return _song_duration


func get_final_movement_time() -> float:
	return _final_movement_time


func is_beat_active() -> bool:
	# True when beat tracking is available and the conductor is playing.
	return _running and _beat_interval > 0.0


func get_beat_phase() -> float:
	# Returns 0.0-1.0 through the current beat period.
	# 0.0 = a beat just fired; approaches 1.0 at the next beat.
	# Returns 0.0 when beat tracking is inactive.
	if not is_beat_active():
		return 0.0
	return fmod(get_song_time(), _beat_interval) / _beat_interval


func get_beat_quality() -> String:
	# Evaluates how close the current moment is to a beat.
	# Returns "perfect", "good", or "off".
	# "perfect" = within ±65 ms, "good" = within ±130 ms.
	if not is_beat_active():
		return "off"
	var phase: float = get_beat_phase()
	# Phase > 0.5 means we are closer to the NEXT beat than the last.
	var dist_phase: float = phase if phase <= 0.5 else 1.0 - phase
	var dist_seconds: float = dist_phase * _beat_interval
	if dist_seconds <= BEAT_PERFECT_WINDOW:
		return "perfect"
	if dist_seconds <= BEAT_GOOD_WINDOW:
		return "good"
	return "off"


func _process(_delta: float) -> void:
	if not _running or _stream_player == null:
		return

	var t: float = _stream_player.get_playback_position()

	# Section transition check — advance one at a time so no section is skipped.
	var next_idx: int = _current_section_idx + 1
	if next_idx < _sections.size():
		var next_section: Dictionary = _sections[next_idx]
		if t >= float(next_section.get("start_time", 9999.0)):
			_current_section_idx = next_idx
			current_intensity = float(next_section.get("intensity", 0.0))
			current_spawn_mult = float(next_section.get("spawn_interval_mult", 1.0))
			current_section_id = String(next_section.get("id", ""))
			section_changed.emit(current_section_id, next_section)

	# Final movement trigger — fires once.
	if not _final_triggered and t >= _final_movement_time:
		_final_triggered = true
		final_movement_reached.emit()
