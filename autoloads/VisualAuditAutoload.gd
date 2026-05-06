extends Node

## VISUAL AUDIT AUTOLOAD (Law #6 Implementation)
## Automatically captures visual truth during high-value EventBus moments.
## PERFORMANCE: Uses WorkerThreadPool to offload disk I/O to background threads.

const SONG_COMBAT_PROFILE_CONTENT = preload("res://data/SongCombatProfileContent.gd")
const OUTPUT_DIR: String = "res://docs/ai/visual_audits/pending"
const MAX_SNAPSHOTS_TO_KEEP: int = 50
const SCHEMA_VERSION: String = "visual_audit_capture.v3"
const MANUAL_KEY: Key = KEY_F12
const AUTO_CAPTURE_COOLDOWN_SECONDS: float = 2.0

@export var auto_capture_enabled: bool = true
@export var manual_capture_enabled: bool = true

var _last_auto_capture_msec: int = 0


func _ready() -> void:
	_ensure_output_dir()
	_cleanup_old_captures()
	_connect_eventbus()
	print("[VISUAL_AUDIT] Autoload initialized. F12 for manual capture.")


func _exit_tree() -> void:
	_disconnect_eventbus()


func _unhandled_input(event: InputEvent) -> void:
	if not manual_capture_enabled:
		return
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == MANUAL_KEY:
		capture("manual_f12", {"moment_id": "manual_f12"})
		get_viewport().set_input_as_handled()


func capture(capture_source: String, context: Dictionary = {}) -> Dictionary:
	# PERFORMANCE: Capture viewport texture IMMEDIATELY on main thread (fast)
	# But wait for post_draw to ensure frame is complete.
	await RenderingServer.frame_post_draw

	var image: Image = get_viewport().get_texture().get_image()
	if image == null:
		return {"error": "Viewport image is null"}
	
	# Extract metadata on main thread where nodes are accessible
	var metadata: Dictionary = _build_metadata(capture_source, context, "", "", OK)
	
	# PERFORMANCE: Offload disk write to background thread
	WorkerThreadPool.add_task(_save_capture_threaded.bind(image, metadata))

	print("[VISUAL_AUDIT] Scheduled background capture for moment: ", metadata.get("moment_id"))
	return metadata


func _save_capture_threaded(image: Image, metadata: Dictionary) -> void:
	var timestamp: String = Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace("T", "_")
	var moment_id: String = _slug(metadata.get("moment_id", "unknown"))
	var base_name: String = "%s_%s" % [timestamp, moment_id]
	var png_path: String = "%s/%s.png" % [OUTPUT_DIR, base_name]
	var json_path: String = "%s/%s.json" % [OUTPUT_DIR, base_name]
	var absolute_png_path: String = ProjectSettings.globalize_path(png_path)
	var absolute_json_path: String = ProjectSettings.globalize_path(json_path)
	
	# Update paths in metadata before saving
	metadata["image_path"] = png_path
	metadata["metadata_path"] = json_path
	
	var png_error: Error = image.save_png(absolute_png_path)
	metadata["png_error"] = int(png_error)
	
	var json_text: String = JSON.stringify(metadata, "\t")
	var file := FileAccess.open(absolute_json_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_text)
		file.close()
	
	# Note: Do not print from background thread to avoid console race conditions in some Godot versions,
	# but it's generally safe in Godot 4.
	# print("[VISUAL_AUDIT] Saved background capture: ", png_path)


func _connect_eventbus() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	
	# BIG VISUAL CHANGES ONLY
	if not bus.combat_started.is_connected(_on_combat_started):
		bus.combat_started.connect(_on_combat_started)
	if not bus.combat_ended.is_connected(_on_combat_ended):
		bus.combat_ended.connect(_on_combat_ended)
	if not bus.boss_phase_transitioned.is_connected(_on_boss_phase_transitioned):
		bus.boss_phase_transitioned.connect(_on_boss_phase_transitioned)


func _disconnect_eventbus() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	
	if bus.combat_started.is_connected(_on_combat_started):
		bus.combat_started.disconnect(_on_combat_started)
	if bus.combat_ended.is_connected(_on_combat_ended):
		bus.combat_ended.disconnect(_on_combat_ended)
	if bus.boss_phase_transitioned.is_connected(_on_boss_phase_transitioned):
		bus.boss_phase_transitioned.disconnect(_on_boss_phase_transitioned)


func _on_combat_started(enemy_data: Array) -> void:
	_auto_capture("combat_started", {"enemy_count": enemy_data.size()})


func _on_combat_ended(victory: bool) -> void:
	_auto_capture("combat_ended", {"victory": victory})


func _on_boss_phase_transitioned(phase_index: int, phase_id: String) -> void:
	_auto_capture("boss_phase_%d" % phase_index, {"phase_id": phase_id})


func _auto_capture(moment_id: String, context: Dictionary) -> void:
	if not auto_capture_enabled:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_auto_capture_msec < int(AUTO_CAPTURE_COOLDOWN_SECONDS * 1000.0):
		return
	_last_auto_capture_msec = now
	context["moment_id"] = moment_id
	capture.call_deferred("eventbus_auto", context)


func _build_metadata(capture_source: String, context: Dictionary, png_path: String, json_path: String, png_error: Error) -> Dictionary:
	var scene: Node = get_tree().current_scene
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var camera: Camera2D = get_viewport().get_camera_2d()
	var combat_meter: Node = _find_node_by_name(scene, "CombatMeter")
	var zone_manager: Node = _find_node_by_name(scene, "ZoneManager")
	var player_combat: Node = _find_node_by_name(scene, "PlayerCombat")
	var game_state: Node = get_node_or_null("/root/GameState")
	var song_conductor: Node = _find_node_by_name(scene, "SongConductor")
	if song_conductor == null:
		song_conductor = _find_node_by_name(scene, "BossSongConductor")
	var run_growth: Node = _find_node_by_name(scene, "RunGrowth")

	return {
		"schema_version": SCHEMA_VERSION,
		"audit_id": _slug("%s_%s" % [Time.get_datetime_string_from_system(false, true), String(context.get("moment_id", capture_source))]),
		"capture_source": capture_source,
		"image_path": png_path,
		"metadata_path": json_path,
		"png_error": int(png_error),
		"moment_id": String(context.get("moment_id", capture_source)),
		"event_payload": context.duplicate(true),
		"scene": _scene_name(scene),
		"viewport": {"width": int(viewport_size.x), "height": int(viewport_size.y)},
		"camera": _camera_metadata(camera),
		"combat": _combat_metadata(combat_meter, player_combat),
		"song": _song_metadata(song_conductor, game_state, scene),
		"lane": _lane_metadata(zone_manager, player_combat, context),
		"support": _support_metadata(game_state, run_growth, context),
		"game_state": _game_state_metadata(game_state)
	}


func _camera_metadata(camera: Camera2D) -> Dictionary:
	if camera == null:
		return {"zoom": "unknown", "offset": "unknown", "global_position": "unknown"}
	return {
		"zoom": _vec2_dict(camera.zoom),
		"offset": _vec2_dict(camera.offset),
		"global_position": _vec2_dict(camera.global_position)
	}


func _combat_metadata(combat_meter: Node, player_combat: Node) -> Dictionary:
	var tier: String = "unknown"
	var combo_count: int = -1
	var style_score: float = -1.0
	if combat_meter != null:
		if combat_meter.has_method("get_current_tier"):
			tier = String(combat_meter.call("get_current_tier"))
		combo_count = int(_get_object_property(combat_meter, "combo_count", -1))
		style_score = float(_get_object_property(combat_meter, "style_score", -1.0))
	var active_lane: int = -1
	if player_combat != null and player_combat.has_method("get_active_focus_lane"):
		active_lane = int(player_combat.call("get_active_focus_lane"))
	return {"tier": tier, "combo_count": combo_count, "style_score": style_score, "active_lane": active_lane}


func _song_metadata(song_conductor: Node, game_state: Node, scene: Node) -> Dictionary:
	var beat_quality: String = "unknown"
	if _object_has_property(game_state, "last_beat_quality"):
		beat_quality = String(game_state.get("last_beat_quality"))
	var intensity: float = float(_get_object_property(song_conductor, "current_intensity", -1.0))
	var resonance: Dictionary = {}
	if intensity >= 0.0:
		resonance = SONG_COMBAT_PROFILE_CONTENT.resolve_resonance_tier(intensity)
	var song_id: String = "unknown"
	if _object_has_property(scene, "_active_song_data"):
		var active_song_data: Dictionary = Dictionary(scene.get("_active_song_data"))
		song_id = String(active_song_data.get("id", "unknown"))
	return {
		"id": song_id,
		"section_id": String(_get_object_property(song_conductor, "current_section_id", "unknown")),
		"beat_index": int(_get_object_property(song_conductor, "_last_emitted_beat", -1)),
		"beat_quality": beat_quality,
		"intensity": intensity,
		"resonance_tier": String(resonance.get("id", "unknown"))
	}


func _lane_metadata(zone_manager: Node, player_combat: Node, context: Dictionary) -> Dictionary:
	var cardinal_positions: Array[Dictionary] = []
	if zone_manager != null and zone_manager.has_method("get_threat_spawn_pos") and zone_manager.has_method("get_threat_hit_zone_pos"):
		for lane in range(4):
			var spawn_pos: Vector2 = zone_manager.call("get_threat_spawn_pos", lane)
			var hit_pos: Vector2 = zone_manager.call("get_threat_hit_zone_pos", lane)
			cardinal_positions.append({
				"lane": lane,
				"spawn": _vec2_dict(spawn_pos),
				"hit_zone": _vec2_dict(hit_pos)
			})
	var active_lane: int = -1
	if player_combat != null and player_combat.has_method("get_active_focus_lane"):
		active_lane = int(player_combat.call("get_active_focus_lane"))
	return {
		"active": active_lane,
		"source": int(context.get("source_lane", context.get("lane", -1))),
		"support": int(context.get("lane", -1)),
		"cardinal_positions": cardinal_positions
	}


func _support_metadata(game_state: Node, run_growth: Node, context: Dictionary) -> Dictionary:
	var active_species_id: String = String(context.get("species_id", "unknown"))
	var support_charge: float = -1.0
	if game_state != null and game_state.has_method("get_active_bonded_creature"):
		var active_creature: Dictionary = Dictionary(game_state.call("get_active_bonded_creature"))
		active_species_id = String(active_creature.get("species_id", active_species_id))
	support_charge = float(_get_object_property(run_growth, "support_charge", -1.0))
	return {
		"species_id": active_species_id,
		"charge": support_charge,
		"effect_id": String(context.get("effect_id", "unknown"))
	}


func _game_state_metadata(game_state: Node) -> Dictionary:
	if game_state == null:
		return {"available": false}
	var active_mutations: Array = []
	if _object_has_property(game_state, "active_mutations"):
		for entry in game_state.get("active_mutations"):
			if entry is Dictionary:
				active_mutations.append(String(entry.get("id", "unknown")))
	return {
		"available": true,
		"run_number": int(_get_object_property(game_state, "run_number", -1)),
		"in_combat": bool(_get_object_property(game_state, "is_in_combat", false)),
		"active_mutations": active_mutations
	}


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	return root_node.find_child(node_name, true, false)


func _scene_name(scene: Node) -> String:
	if scene == null:
		return "unknown"
	if scene.scene_file_path.is_empty():
		return scene.name
	return scene.scene_file_path


func _vec2_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _object_has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for property in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _get_object_property(object: Object, property_name: String, fallback: Variant) -> Variant:
	if not _object_has_property(object, property_name):
		return fallback
	return object.get(property_name)


func _slug(value: String) -> String:
	var result: String = value.to_lower()
	for token in [" ", "/", "\\", ":", ".", ",", ";", "(", ")", "[", "]", "_-_"]:
		result = result.replace(token, "_")
	return result


func _ensure_output_dir() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_path)


func _cleanup_old_captures() -> void:
	var absolute_dir: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir: DirAccess = DirAccess.open(absolute_dir)
	if dir == null:
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".json")):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Group by base name (timestamp_moment)
	var groups: Dictionary = {}
	for f in files:
		var base: String = f.get_basename()
		if not groups.has(base):
			groups[base] = []
		(groups[base] as Array).append(f)

	var base_names: Array = groups.keys()
	base_names.sort()

	if base_names.size() <= MAX_SNAPSHOTS_TO_KEEP:
		return

	var count_to_delete: int = base_names.size() - MAX_SNAPSHOTS_TO_KEEP
	print("[VISUAL_AUDIT] Cleaning up ", count_to_delete, " old snapshots.")
	for i in range(count_to_delete):
		var base: String = base_names[i]
		for entry in groups[base] as Array:
			var fname: String = String(entry)
			var rel: String = "%s/%s" % [OUTPUT_DIR, fname]
			var abs_fp: String = ProjectSettings.globalize_path(rel)
			DirAccess.remove_absolute(abs_fp)
