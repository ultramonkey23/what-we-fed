extends Node

const SONG_COMBAT_PROFILE_CONTENT = preload("res://data/SongCombatProfileContent.gd")
const OUTPUT_DIR: String = "res://docs/ai/visual_audits/pending"
const SCHEMA_VERSION: String = "visual_audit_capture.v2"
const MANUAL_KEY: Key = KEY_F12
const AUTO_CAPTURE_COOLDOWN_SECONDS: float = 0.75

@export var auto_capture_enabled: bool = true
@export var manual_capture_enabled: bool = true
@export var capture_player_damage: bool = true
@export var capture_timed_attacks: bool = false
@export var capture_parries: bool = false
@export var capture_dodges: bool = false
@export var capture_support: bool = true
@export var capture_ultimate: bool = true

var _last_auto_capture_msec: int = 0
var _last_support_species_id: String = "unknown"
var _last_support_effect_id: String = "unknown"
var _last_support_lane: int = -1
var _last_damage_lane: int = -1


func _ready() -> void:
	_ensure_output_dir()
	_connect_eventbus()


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
	await RenderingServer.frame_post_draw

	var timestamp: String = Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace("T", "_")
	var moment_id: String = _slug(String(context.get("moment_id", capture_source)))
	var base_name: String = "%s_%s" % [timestamp, moment_id]
	var png_path: String = "%s/%s.png" % [OUTPUT_DIR, base_name]
	var json_path: String = "%s/%s.json" % [OUTPUT_DIR, base_name]
	var absolute_png_path: String = ProjectSettings.globalize_path(png_path)
	var absolute_json_path: String = ProjectSettings.globalize_path(json_path)

	var image: Image = get_viewport().get_texture().get_image()
	var png_error: Error = image.save_png(absolute_png_path)
	var metadata: Dictionary = _build_metadata(capture_source, context, png_path, json_path, png_error)
	var json_text: String = JSON.stringify(metadata, "\t")
	var file := FileAccess.open(absolute_json_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_text)
		file.close()
	else:
		metadata["metadata_write_error"] = "Could not open JSON output path."

	print("[VISUAL_AUDIT] capture=", png_path, " metadata=", json_path, " png_error=", png_error)
	return metadata


func _connect_eventbus() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if capture_player_damage and not bus.player_took_damage.is_connected(_on_player_took_damage):
		bus.player_took_damage.connect(_on_player_took_damage)
	if capture_timed_attacks and not bus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		bus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	if capture_parries and not bus.player_parried.is_connected(_on_player_parried):
		bus.player_parried.connect(_on_player_parried)
	if capture_dodges and not bus.player_dodged.is_connected(_on_player_dodged):
		bus.player_dodged.connect(_on_player_dodged)
	if capture_support and not bus.bonded_support_triggered.is_connected(_on_bonded_support_triggered):
		bus.bonded_support_triggered.connect(_on_bonded_support_triggered)
	if capture_ultimate and not bus.ultimate_fired.is_connected(_on_ultimate_fired):
		bus.ultimate_fired.connect(_on_ultimate_fired)


func _disconnect_eventbus() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if bus.player_took_damage.is_connected(_on_player_took_damage):
		bus.player_took_damage.disconnect(_on_player_took_damage)
	if bus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		bus.timed_attack_resolved.disconnect(_on_timed_attack_resolved)
	if bus.player_parried.is_connected(_on_player_parried):
		bus.player_parried.disconnect(_on_player_parried)
	if bus.player_dodged.is_connected(_on_player_dodged):
		bus.player_dodged.disconnect(_on_player_dodged)
	if bus.bonded_support_triggered.is_connected(_on_bonded_support_triggered):
		bus.bonded_support_triggered.disconnect(_on_bonded_support_triggered)
	if bus.ultimate_fired.is_connected(_on_ultimate_fired):
		bus.ultimate_fired.disconnect(_on_ultimate_fired)


func _on_player_took_damage(amount: float, source_lane: int) -> void:
	_last_damage_lane = source_lane
	_auto_capture("player_took_damage", {"amount": amount, "source_lane": source_lane})


func _on_timed_attack_resolved(lane: int, quality: String, damage: float) -> void:
	_auto_capture("timed_attack_%s" % quality, {"lane": lane, "quality": quality, "damage": damage})


func _on_player_parried(lane: int, quality: String, reflect_damage: float) -> void:
	_auto_capture("player_parried_%s" % quality, {"lane": lane, "quality": quality, "reflect_damage": reflect_damage})


func _on_player_dodged(from_lane: int, to_lane: int) -> void:
	_auto_capture("player_dodged", {"from_lane": from_lane, "to_lane": to_lane})


func _on_bonded_support_triggered(species_id: String, lane: int, effect_id: String) -> void:
	_last_support_species_id = species_id
	_last_support_effect_id = effect_id
	_last_support_lane = lane
	_auto_capture("bonded_support_triggered", {"species_id": species_id, "lane": lane, "effect_id": effect_id})


func _on_ultimate_fired(power: float) -> void:
	_auto_capture("ultimate_fired", {"power": power})


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
	var lane_manager: Node = _find_node_by_name(scene, "LaneManager")
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
		"lane": _lane_metadata(lane_manager, player_combat, context),
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
	active_lane = int(_get_object_property(player_combat, "current_lane", -1))
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


func _lane_metadata(lane_manager: Node, player_combat: Node, context: Dictionary) -> Dictionary:
	var cardinal_positions: Array[Dictionary] = []
	if lane_manager != null and lane_manager.has_method("get_threat_spawn_pos") and lane_manager.has_method("get_threat_hit_zone_pos"):
		for lane in range(4):
			var spawn_pos: Vector2 = lane_manager.call("get_threat_spawn_pos", lane)
			var hit_pos: Vector2 = lane_manager.call("get_threat_hit_zone_pos", lane)
			cardinal_positions.append({
				"lane": lane,
				"spawn": spawn_pos,
				"hit_zone": hit_pos
			})
	var active_lane: int = -1
	active_lane = int(_get_object_property(player_combat, "current_lane", -1))
	return {
		"active": active_lane,
		"source": int(context.get("source_lane", context.get("lane", _last_damage_lane))),
		"support": int(context.get("lane", _last_support_lane)),
		"cardinal_positions": cardinal_positions
	}


func _support_metadata(game_state: Node, run_growth: Node, context: Dictionary) -> Dictionary:
	var active_species_id: String = String(context.get("species_id", _last_support_species_id))
	var support_charge: float = -1.0
	if game_state != null and game_state.has_method("get_active_bonded_creature"):
		var active_creature: Dictionary = Dictionary(game_state.call("get_active_bonded_creature"))
		active_species_id = String(active_creature.get("species_id", active_species_id))
	support_charge = float(_get_object_property(run_growth, "support_charge", -1.0))
	return {
		"species_id": active_species_id,
		"charge": support_charge,
		"effect_id": String(context.get("effect_id", _last_support_effect_id))
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
