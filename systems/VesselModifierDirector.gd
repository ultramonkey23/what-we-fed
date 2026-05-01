extends Node

# VesselModifierDirector.gd
# Orchestrates "Player as Vessel" logic.
# Provides both static calculation methods and a runtime instance for signal-driven effects.

const VESSEL_CLASS_CONTENT = preload("res://data/VesselClassContent.gd")
const SOVEREIGN_DAMAGE_CALCULATOR = preload("res://systems/SovereignDamageCalculator.gd")

var _zone_manager: Node = null
var _active_class_data: Dictionary = {}

# ── Static ───────────────────────────────────────────────────────────────────

## Calculates the potential impact of a "Perfect" strike based on the current Vessel.
## Returns a profile describing visual targets, bonus damage, and descriptive labels.
static func build_perfect_plan(species_id: String, origin_sector: int, origin_damage: float) -> Dictionary:
	var data: Dictionary = VESSEL_CLASS_CONTENT.get_class_data(species_id)
	if data.is_empty():
		return {}
		
	var mod: Dictionary = data.get("attack_modifier", {})
	if mod.is_empty():
		return {}
		
	var effect_id: String = String(mod.get("effect_id", ""))
	if effect_id != "vessel_rupture":
		return {}
		
	# Bond-trait expression: scaling via Sovereign Stats Engine.
	var bond_scaled_trait_mult: float = SOVEREIGN_DAMAGE_CALCULATOR.get_vessel_trait_multiplier(species_id)
	
	var targets: Array = []
	var label: String = data.get("vessel_trait", "RUPTURE").to_upper()
	var mult: float = 1.0

	if effect_id == "vessel_rupture":
		# Only show rupture preview if the target is primed (5 stacks)
		# NOTE: Static check here is difficult as we don't have zone_manager state in static call.
		# For now, we show a 'priming' feel or just the potential AoE.
		mult = float(mod.get("rupture_damage_mult", 2.5)) * bond_scaled_trait_mult
		label = "RUPTURE"
		targets = [0, 1, 2, 3] # Global AoE (Legacy sector indices for now)
			
	return {
		"targets": targets,
		"damage": origin_damage * mult,
		"label": label,
		"color": data.get("vibe_color", Color.WHITE),
		"silhouette_color": Color(data.get("vibe_color", Color.WHITE), 0.35),
		"label_duration": 0.32
	}


static func get_modifier_readout(species_id: String) -> Dictionary:
	var data: Dictionary = VESSEL_CLASS_CONTENT.get_class_data(species_id)
	if data.is_empty():
		return {}
		
	var mod: Dictionary = data.get("attack_modifier", {})
	if mod.is_empty():
		mod = data.get("parry_modifier", {})
	if mod.is_empty():
		mod = data.get("dodge_modifier", {})
		
	var trait_mult: float = SOVEREIGN_DAMAGE_CALCULATOR.get_vessel_trait_multiplier(species_id)
	
	return {
		"id": String(mod.get("effect_id", "unknown")),
		"name": String(data.get("vessel_trait", "Trait")),
		"multiplier": trait_mult,
		"color": data.get("vibe_color", Color.WHITE)
	}


# ── Runtime ──────────────────────────────────────────────────────────────────

func bind_runtime(zone_manager_ref: Node) -> void:
	_zone_manager = zone_manager_ref
	
	if not EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	if not EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.connect(_on_player_parried)
	if not EventBus.player_dodged.is_connected(_on_player_dodged):
		EventBus.player_dodged.connect(_on_player_dodged)
		
	# Initial class sync
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


func _on_timed_attack_resolved(sector: int, quality: String, damage: float, enemy_id: int) -> void:
	if _active_class_data.is_empty() or _zone_manager == null:
		return
		
	var mod: Dictionary = _active_class_data.get("attack_modifier", {})
	if mod.is_empty():
		return
	
	var trigger: String = String(mod.get("on_quality", ""))
	var valid: bool = false
	if trigger == "perfect" and quality == "perfect":
		valid = true
	elif trigger == "any_timed" and (quality == "perfect" or quality == "good"):
		valid = true
		
	if valid:
		_apply_vessel_effect(mod, {"sector": sector, "damage": damage, "quality": quality, "enemy_id": enemy_id})


func _on_player_parried(sector: int, quality: String, reflect_damage: float) -> void:
	if _active_class_data.is_empty():
		return
		
	var mod: Dictionary = _active_class_data.get("parry_modifier", {})
	if mod.is_empty():
		return
		
	if String(mod.get("on_quality", "")) == quality:
		_apply_vessel_effect(mod, {"sector": sector, "reflect_damage": reflect_damage})


func _on_player_dodged(from_sector: int, to_sector: int) -> void:
	if _active_class_data.is_empty():
		return
		
	var mod: Dictionary = _active_class_data.get("dodge_modifier", {})
	if mod.is_empty():
		return
		
	_apply_vessel_effect(mod, {"from": from_sector, "to": to_sector})


func _apply_vessel_effect(mod: Dictionary, context: Dictionary) -> void:
	var effect_id: String = String(mod.get("effect_id", ""))
	var vibe_color: Color = _active_class_data.get("vibe_color", Color.WHITE)

	match effect_id:
		"vessel_siphon":
			var heal_val: float = float(mod.get("heal_value", 1.0))
			var healed: float = GameState.heal_player(heal_val)
			if healed > 0.0:
				EventBus.player_healed.emit(healed)
				EventBus.proc_feedback_requested.emit("SIPHON", vibe_color)
				EventBus.play_sfx.emit("vessel_heal")

		"vessel_pulse":
			# SpawnZoneManager has no "stun" status today — map to "slow" so the static-weaver
			# Vessel actually interrupts on dodge instead of silently no-op'ing.
			var to_sector: int = int(context.get("to", -1))
			var stun_dur: float = float(mod.get("stun_duration", 0.5))
			if to_sector >= 0 and _zone_manager != null:
				var enemy: Dictionary = _zone_manager.call("get_enemy", to_sector)
				if not enemy.is_empty():
					_zone_manager.call("apply_status_by_id", int(enemy.get("id", -1)), "slow", {"duration": stun_dur})
				EventBus.play_sfx.emit("static_pulse")

		"vessel_rupture":
			var enemy_id: int = int(context.get("enemy_id", -1))
			var damage: float = float(context.get("damage", 0.0))
			if enemy_id != -1 and _zone_manager != null:
				var current_stacks: int = int(_zone_manager.call("get_enemy_bleed_stacks", enemy_id))
				
				if current_stacks >= 5: # BLEED_MAX_STACKS
					# Rupture!
					_zone_manager.call("clear_enemy_status_by_id", enemy_id)
					var mult: float = float(mod.get("rupture_damage_mult", 2.5))
					var aoe_damage: float = damage * mult
					
					# Global AoE (Sector-independent ID-based loop)
					var all_enemies: Dictionary = _zone_manager.call("get_all_enemies")
					for id in all_enemies.keys():
						_zone_manager.call("damage_enemy_by_id", id, aoe_damage)
					
					EventBus.enemy_ruptured.emit(enemy_id, aoe_damage)
					EventBus.proc_feedback_requested.emit("RUPTURE", Color(1.0, 0.22, 0.14, 1.0))
					EventBus.play_sfx.emit("rupture_burst")
				else:
					# Apply Bleed stack (ID based application)
					_zone_manager.call("apply_status_by_id", enemy_id, "bleed", {})
