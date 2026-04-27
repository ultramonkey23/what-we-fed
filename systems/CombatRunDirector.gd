extends Node

# Combat Run Director - Manages the high-level orchestration of a combat run
# Extracting this logic from CombatScene.gd to reduce structural bloat.

const AUDIO_CONTENT = preload("res://data/AudioContent.gd")
const SONG_LIBRARY = preload("res://data/SongLibraryContent.gd")
const SONG_COMBAT_PROFILE_CONTENT = preload("res://data/SongCombatProfileContent.gd")
const RUN_PACING_CONTENT = preload("res://data/RunPacingContent.gd")
const PATH_RUN_PLAN = preload("res://systems/PathRunPlan.gd")
const ENCOUNTER_IDENTITY_RUNTIME = preload("res://systems/EncounterIdentityRuntime.gd")
const POTENTIAL_GATE = preload("res://systems/PotentialGate.gd")

signal run_started(run_number: int)
signal level_started(level_index: int, level_data: Dictionary)
signal level_completed(level_index: int)
signal void_entered()
signal drop_scheduled(target_time: float)
signal run_completed(success: bool)

var region_id: String = "feeding_hollow"
var active_song_data: Dictionary = {}
var active_song_profile: Dictionary = {}
var active_song_map: GDScript = null
var regular_level_windows: Array = []
var regular_level_playlist: Array = []
var regular_level_index: int = 0
var song_level_start_time: float = 0.0
var song_level_end_time: float = 0.0
var in_void: bool = false

var active_path_context: Dictionary = {}
var base_difficulty_modifiers: Dictionary = {}
var _song_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func initialize_run(region: String, dev_harness_request: Dictionary = {}) -> void:
	_test_collar_mechanics()
	region_id = region if not region.is_empty() else "feeding_hollow"
	in_void = false
	
	if not GameState.run_in_progress:
		GameState.run_number += 1
		if GameState.has_method("reset_run_state"):
			GameState.reset_run_state()
		GameState.run_in_progress = true

	_song_rng.randomize()
	var region_song_id: String = SONG_COMBAT_PROFILE_CONTENT.get_regular_song_id_for_region(region_id)
	active_song_data = SONG_LIBRARY.get_song(region_song_id)
	if active_song_data.is_empty():
		active_song_data = AUDIO_CONTENT.get_region_main_run_song(region_id)
	active_song_profile = SONG_COMBAT_PROFILE_CONTENT.get_profile(String(active_song_data.get("id", "")))
	active_song_map = AUDIO_CONTENT.get_song_map(active_song_data)
	
	var song_duration: float = _resolve_song_duration()
	regular_level_windows = RUN_PACING_CONTENT.build_regular_level_windows(region_id, song_duration)
	regular_level_playlist = SONG_COMBAT_PROFILE_CONTENT.get_playlist_for_region(RUN_PACING_CONTENT.REGULAR_LEVEL_COUNT, region_id, _song_rng)
	if regular_level_playlist.is_empty():
		regular_level_playlist = [active_song_data.duplicate(true)]
	
	regular_level_index = clampi(int(dev_harness_request.get("regular_level_index", 0)), 0, max(regular_level_playlist.size() - 1, 0))
	var level_count: int = regular_level_playlist.size()
	
	if GameState.run_path_plan.is_empty() or GameState.run_path_plan.size() != level_count:
		GameState.run_path_plan = PATH_RUN_PLAN.build_plan(region_id, level_count)
	
	prepare_path_context_for_level(regular_level_index)
	emit_signal("run_started", int(GameState.run_number))
	EventBus.emit_signal("run_started", int(GameState.run_number))

func start_next_level(reset_hp: bool = false) -> Dictionary:
	return start_level(regular_level_index, reset_hp)

func start_level(level_idx: int, _reset_hp: bool = false) -> Dictionary:
	in_void = false
	if level_idx < 0 or level_idx >= regular_level_playlist.size():
		return {"is_boss_trigger": true}

	regular_level_index = level_idx
	prepare_path_context_for_level(regular_level_index)
	active_song_data = _get_song_for_level(regular_level_index)
	active_song_profile = SONG_COMBAT_PROFILE_CONTENT.get_profile(String(active_song_data.get("id", "")))
	active_song_map = AUDIO_CONTENT.get_song_map(active_song_data)
	var song_windows: Array = _build_level_windows_for_song(active_song_data)
	var level_window: Dictionary = song_windows[regular_level_index] if regular_level_index < song_windows.size() else {}
	song_level_start_time = float(level_window.get("start_time", 0.0))
	song_level_end_time = float(level_window.get("end_time", 0.0))
	
	var encounter_options: Dictionary = Dictionary(active_path_context.get("encounter_options", {})).duplicate(true)
	base_difficulty_modifiers = SONG_COMBAT_PROFILE_CONTENT.build_level_difficulty_modifiers(
		region_id,
		regular_level_index,
		encounter_options,
		active_song_profile
	)
	encounter_options["difficulty_modifiers"] = base_difficulty_modifiers.duplicate(true)
	
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	var grade_ceiling_id: String = POTENTIAL_GATE.resolve_grade_ceiling(
		active_creature,
		GameState.active_region,
		int(GameState.run_number),
		regular_level_index,
		bool(encounter_options.get("elite", false))
	)
	encounter_options["grade_ceiling_id"] = grade_ceiling_id
	
	var level_duration: float = max(song_level_end_time - song_level_start_time, 20.0)
	var song_run: Dictionary = ENCOUNTER_IDENTITY_RUNTIME.build_song_run(region_id, regular_level_index, level_duration, encounter_options)
	
	var level_data: Dictionary = {
		"index": regular_level_index,
		"song_data": active_song_data.duplicate(true),
		"song_map": active_song_map,
		"song_run": song_run,
		"start_time": song_level_start_time,
		"end_time": song_level_end_time,
		"difficulty_modifiers": base_difficulty_modifiers,
		"song_display_name": String(active_song_data.get("display_name", ""))
	}
	
	emit_signal("level_started", regular_level_index, level_data)
	return level_data

func complete_level() -> void:
	emit_signal("level_completed", regular_level_index)
	regular_level_index += 1

func enter_void() -> void:
	in_void = true
	emit_signal("void_entered")
	EventBus.emit_signal("tempo_state_entered", "void")

func request_drop(song_conductor: Node) -> void:
	if not in_void: return
	
	# Logic to find the next drop (next phrase start or 8-bar boundary)
	var current_time: float = song_conductor.get_song_time()
	var bpm: float = song_conductor.current_bpm
	var beat_duration: float = 60.0 / bpm if bpm > 0 else 0.5
	var bars_8_duration: float = beat_duration * 32.0 # 4 beats * 8 bars
	
	# Find next 8-bar boundary for a satisfying drop
	var next_drop_time: float = ceil(current_time / bars_8_duration) * bars_8_duration
	
	# If too close (less than 1 bar), push to next boundary
	if next_drop_time - current_time < beat_duration * 4.0:
		next_drop_time += bars_8_duration
		
	emit_signal("drop_scheduled", next_drop_time)

func finish_run(success: bool) -> void:
	GameState.run_in_progress = false
	emit_signal("run_completed", success)
	EventBus.emit_signal("run_completed", success)

func get_active_song_data() -> Dictionary:
	return active_song_data

func get_active_song_profile() -> Dictionary:
	return active_song_profile.duplicate(true)

func get_active_song_map() -> GDScript:
	return active_song_map

func _resolve_song_duration() -> float:
	var song_path: String = String(active_song_data.get("file_path", ""))
	if song_path.is_empty():
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	var stream: AudioStream = ResourceLoader.load(song_path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
	if stream == null:
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	var stream_duration: float = stream.get_length()
	return stream_duration if stream_duration > 0.0 else RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS

func _get_song_for_level(level_idx: int) -> Dictionary:
	if level_idx >= 0 and level_idx < regular_level_playlist.size():
		return Dictionary(regular_level_playlist[level_idx]).duplicate(true)
	return AUDIO_CONTENT.get_region_main_run_song(region_id)

func _build_level_windows_for_song(song_data: Dictionary) -> Array:
	var previous_song: Dictionary = active_song_data
	active_song_data = song_data
	var song_duration: float = _resolve_song_duration()
	active_song_data = previous_song
	var built_windows: Array = RUN_PACING_CONTENT.build_regular_level_windows(region_id, song_duration)
	if built_windows.size() >= RUN_PACING_CONTENT.REGULAR_LEVEL_COUNT:
		return built_windows
	return regular_level_windows

func prepare_path_context_for_level(level_idx: int) -> void:
	var node: Dictionary = PATH_RUN_PLAN.get_level_node(GameState.run_path_plan, level_idx)
	# Mock objects for director compatibility if needed, but PathRunPlan mostly needs references.
	active_path_context = PATH_RUN_PLAN.apply_node_effects(node, self, null, null, false)

func _test_collar_mechanics() -> void:
	print("--- TEST SUPPORT COLLAR MECHANICS ---")
	var og_collar = GameState.get("equipped_collar_id")
	GameState.set("equipped_collar_id", "iron_doctrine")
	var collar_data = GameState.call("get_equipped_collar")
	print("Equipped Collar: ", collar_data.get("title", ""))
	
	var ctx: Dictionary = {
		"species_id": "ashclaw",
		"lane": 0,
		"effect_id": "ashclaw_strike",
		"combo_mult": 1.0,
		"bond_mult": 1.0,
		"surge_mult": 1.0,
		"combat_meter": null,
		"game_state": GameState
	}
	
	var CollarDirector = preload("res://systems/CollarDirector.gd").new()
	ctx = CollarDirector.apply_to_support_context(ctx, GameState)
	
	print("Collar Mod Output: ", ctx.get("collar_mod", {}))
	print("New Surge Mult: ", ctx.get("surge_mult", 1.0))
	if float(ctx.get("surge_mult", 1.0)) > 1.0:
		print("Test Passed: Support Impact Mult successfully applied!")
	else:
		print("Test Failed: Surge mult not increased.")
		
	GameState.set("equipped_collar_id", og_collar)
	print("--- TEST END ---")
