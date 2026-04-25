extends Node

# VesselModifierDirector.gd
# Orchestrates "Player as Vessel" logic.
# Provides both static calculation methods and a runtime instance for signal-driven effects.

const VESSEL_CLASS_CONTENT = preload("res://data/VesselClassContent.gd")

var _active_class_data: Dictionary = {}
var _lane_manager: Node = null

# --- Static API (Used by CombatScene and HUD) ---

static func get_modifier_readout(species_id: String) -> Dictionary:
	var data: Dictionary = VESSEL_CLASS_CONTENT.get_class_data(species_id)
	if data.is_empty():
		return {}
	return {
		"hud_readout": data.get("vessel_trait", ""),
		"vibe_color": data.get("vibe_color", Color.WHITE)
	}


static func build_perfect_plan(species_id: String, origin_lane: int, origin_damage: float) -> Dictionary:
	var data: Dictionary = VESSEL_CLASS_CONTENT.get_class_data(species_id)
	if data.is_empty():
		return {}
		
	var mod: Dictionary = data.get("attack_modifier", {})
	if mod.is_empty() or mod.get("effect_id", "") != "vessel_cleave":
		return {}
		
	var mult: float = float(mod.get("adjacent_damage_mult", 0.4))
	var targets: Array = []
	for adj in [origin_lane - 1, origin_lane + 1]:
		if adj >= 0 and adj < 4:
			targets.append(adj)
			
	return {
		"targets": targets,
		"damage": origin_damage * mult,
		"label": data.get("vessel_trait", "CLEAVE").to_upper(),
		"color": data.get("vibe_color", Color.WHITE),
		"silhouette_color": Color(data.get("vibe_color", Color.WHITE), 0.35),
		"label_duration": 0.32
	}


# --- Runtime Instance API ---

func bind_runtime(lane_manager_ref: Node) -> void:
	_lane_manager = lane_manager_ref
	_connect_eventbus()
	# Ensure we initialize state immediately
	_refresh_active_vessel()


func _connect_eventbus() -> void:
	if not EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	if not EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.connect(_on_player_parried)
	if not EventBus.player_dodged.is_connected(_on_player_dodged):
		EventBus.player_dodged.connect(_on_player_dodged)
	if not EventBus.creature_bonded.is_connected(_on_creature_changed):
		EventBus.creature_bonded.connect(_on_creature_changed)
	if not EventBus.creature_eaten.is_connected(_on_creature_changed):
		EventBus.creature_eaten.connect(_on_creature_changed)


func _on_creature_changed(_data: Dictionary) -> void:
	call_deferred("_refresh_active_vessel")


func _refresh_active_vessel() -> void:
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	var species_id: String = String(active_creature.get("species_id", ""))
	
	var new_class_data: Dictionary = VESSEL_CLASS_CONTENT.get_class_data(species_id)
	if new_class_data != _active_class_data:
		_active_class_data = new_class_data
		EventBus.vessel_shifted.emit(_active_class_data)
		if not _active_class_data.is_empty():
			EventBus.proc_feedback_requested.emit("VESSEL SHIFT: " + _active_class_data.get("display_name", "").to_upper(), _active_class_data.get("vibe_color", Color.WHITE))


func _on_timed_attack_resolved(lane: int, quality: String, damage: float) -> void:
	if _active_class_data.is_empty() or _lane_manager == null:
		return
		
	var mod: Dictionary = _active_class_data.get("attack_modifier", {})
	if mod.is_empty():
		return
		
	# Special handling: vessel_cleave is often handled by CombatScene via build_perfect_plan,
	# but we keep it here for any other signal-driven visual logic.
	# For "Player as Vessel", we might want to move it all here eventually.
	
	var trigger: String = String(mod.get("on_quality", ""))
	var valid: bool = false
	if trigger == "perfect" and quality == "perfect":
		valid = true
	elif trigger == "any_timed" and (quality == "perfect" or quality == "good"):
		valid = true
		
	if valid and mod.get("effect_id", "") != "vessel_cleave": # Avoid double-dipping if CombatScene handles cleave
		_apply_vessel_effect(mod, {"lane": lane, "damage": damage, "quality": quality})


func _on_player_parried(lane: int, quality: String, reflect_damage: float) -> void:
	if _active_class_data.is_empty():
		return
		
	var mod: Dictionary = _active_class_data.get("parry_modifier", {})
	if mod.is_empty():
		return
		
	if String(mod.get("on_quality", "")) == quality:
		_apply_vessel_effect(mod, {"lane": lane, "reflect_damage": reflect_damage})


func _on_player_dodged(from_lane: int, to_lane: int) -> void:
	if _active_class_data.is_empty():
		return
		
	var mod: Dictionary = _active_class_data.get("movement_modifier", {})
	if not mod.is_empty():
		_apply_vessel_effect(mod, {"from": from_lane, "to": to_lane})


func _apply_vessel_effect(mod: Dictionary, context: Dictionary) -> void:
	var effect_id: String = String(mod.get("effect_id", ""))
	var vibe_color: Color = _active_class_data.get("vibe_color", Color.WHITE)
	
	match effect_id:
		"vessel_siphon":
			var heal_val: float = float(mod.get("heal_value", 1.0))
			var healed: float = GameState.heal_player(heal_val)
			if healed > 0.0:
				EventBus.player_healed.emit(healed)
				EventBus.play_sfx.emit("void_siphon")

		"vessel_plating":
			var bonus: float = float(mod.get("reduction_bonus", 1.0))
			GameState.player_defense += bonus
			EventBus.proc_feedback_requested.emit("IRON PLATING +", vibe_color)
			EventBus.play_sfx.emit("iron_plating")

		"vessel_pulse":
			# LaneManager has no "stun" status today — map to "slow" so the static-weaver
			# Vessel actually interrupts on dodge instead of silently no-op'ing.
			var to_lane: int = int(context.get("to", -1))
			var stun_dur: float = float(mod.get("stun_duration", 0.5))
			if to_lane >= 0 and _lane_manager != null:
				_lane_manager.apply_status(to_lane, "slow", {"duration": stun_dur})
				EventBus.play_sfx.emit("static_pulse")
