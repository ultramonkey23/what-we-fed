extends RefCounted

# SupportEffectResolver v2
# Extracts creature-specific support resolution from CombatScene.
# Uses signals for feedback and interventions to maintain a clean interface.

const COMBAT_DATA = preload("res://data/CombatContent.gd")
const COMBAT_IMPACT_FEEDBACK = preload("res://systems/CombatImpactFeedback.gd")

signal feedback_requested(text, color, duration)
signal flash_requested(color, duration)
signal intervention_requested(species_id, sector, tint)
signal heal_requested(amount)
signal stamina_requested(amount)
signal support_charge_requested(amount)
signal highlight_ring_requested(sector, color, duration)

func resolve(ctx: Dictionary) -> void:
	var species_id: String = String(ctx.get("species_id", ""))
	var sector: int = int(ctx.get("sector", ctx.get("lane", -1)))
	var effect_id: String = String(ctx.get("effect_id", ""))
	var combo_mult: float = float(ctx.get("combo_mult", 1.0))
	var bond_mult: float = float(ctx.get("bond_mult", 1.0))
	var surge_mult: float = float(ctx.get("surge_mult", 1.0))
	var mastery: String = String(ctx.get("mastery_window", ""))
	var cadence_surge: bool = bool(ctx.get("cadence_surge", false))
	var bond_surge: bool = bool(ctx.get("bond_surge", false))
	var is_hollow_active: bool = bool(ctx.get("is_hollow_active", false))
	
	var zone_manager: Node = ctx.get("zone_manager")
	var combat_meter: Node = ctx.get("combat_meter")
	var game_state: Node = ctx.get("game_state")
	var collar_mod: Dictionary = Dictionary(ctx.get("collar_mod", {}))
	
	if species_id.is_empty() or zone_manager == null:
		return
	if bool(collar_mod.get("suppress_support", false)):
		_apply_collar_behavior(ctx, collar_mod)
		return

	var support_role: Dictionary = COMBAT_DATA.get_support_role(species_id)
	if support_role.is_empty():
		return

	var vulnerability_duration: float = 3.0 if is_hollow_active else 2.5

	match effect_id:
		"ashclaw_strike":
			# BLOOD-EMBER REDESIGN: Applies stacks globally, triggers Rupture chain.
			# Using positional/ID based lookup (Spawn Zone Manager doctrine).
			var all_enemies: Dictionary = zone_manager.call("get_all_enemies")
			var triggered_rupture: bool = false
			var base_val: float = float(support_role.get("effect_value", 10.0))
			
			for id in all_enemies.keys():
				var current_stacks: int = int(zone_manager.call("get_enemy_bleed_stacks", id))
				var added_stacks: int = 3
				if cadence_surge: added_stacks = 4
				
				if (current_stacks + added_stacks) >= 5:
					# Rupture!
					zone_manager.call("clear_enemy_status_by_id", id)
					var rupture_dmg: float = base_val * 2.2 * bond_mult * surge_mult
					zone_manager.call("damage_enemy_by_id", id, rupture_dmg)
					
					# Global Cleave (Sector-wide impact)
					for aoe_id in all_enemies.keys():
						if aoe_id != id:
							zone_manager.call("damage_enemy_by_id", aoe_id, rupture_dmg * 0.45)
					
					EventBus.enemy_ruptured.emit(id, rupture_dmg)
					triggered_rupture = true
				else:
					for s in range(added_stacks):
						zone_manager.call("apply_status_by_id", id, "bleed", {})
			
			if triggered_rupture:
				feedback_requested.emit("ASHCLAW RUPTURE", Color(1.0, 0.25, 0.15, 1.0), 0.48)
				flash_requested.emit(Color(0.35, 0.12, 0.10, 0.96), 0.12)
			else:
				feedback_requested.emit("BLOOD SCENT", Color(0.95, 0.45, 0.35, 1.0), 0.38)
				flash_requested.emit(Color(0.22, 0.10, 0.08, 0.88), 0.10)
			
			highlight_ring_requested.emit(sector, Color(0.92, 0.56, 0.38, 1.0), 7.0)
			intervention_requested.emit(species_id, sector, Color(0.95, 0.60, 0.42, 0.72))

		"bond_remnant_mend":
			var base_heal: float = float(support_role.get("effect_value", 6.0)) * bond_mult * surge_mult
			var heal_amount: float = base_heal
			var stamina_restore: float = 0.0
			var mend_text: String = String(support_role.get("feedback_text", "REMNANT"))
			var mend_color: Color = Color(0.72, 0.96, 0.88, 1.0)
			
			if cadence_surge:
				heal_amount = base_heal * 1.85
				stamina_restore = 28.0
				mend_text = "SURGE MEND"
				mend_color = Color(0.64, 1.0, 0.86, 1.0)
			elif mastery == "flow_state":
				heal_amount = base_heal * 1.5
				stamina_restore = 20.0
				mend_text = "DEEP MEND"
				mend_color = Color(0.60, 1.0, 0.82, 1.0)
			elif mastery == "in_pocket":
				stamina_restore = 12.0
				mend_text = "MEND PULSE"
				mend_color = Color(0.66, 0.98, 0.86, 1.0)
				
			heal_requested.emit(heal_amount)
			if stamina_restore > 0.0:
				stamina_requested.emit(stamina_restore)
				
			feedback_requested.emit(mend_text, mend_color, 0.28)
			highlight_ring_requested.emit(sector, Color(0.68, 0.94, 0.84, 1.0), 4.8)
			intervention_requested.emit(species_id, sector, Color(0.72, 0.96, 0.88, 0.62))
			flash_requested.emit(Color(0.12, 0.22, 0.18, 0.92), 0.10)

		"gruvek_gorge":
			var gorge_damage: float = float(support_role.get("effect_value", 10.0)) * combo_mult * bond_mult * surge_mult
			if cadence_surge:
				gorge_damage *= 1.18
			
			var all_enemies: Dictionary = zone_manager.call("get_all_enemies")
			for id in all_enemies.keys():
				zone_manager.call("damage_enemy_by_id", id, gorge_damage)
				var surviving: Dictionary = zone_manager.call("get_enemy_by_id", id)
				if not surviving.is_empty() and float(surviving.get("hp", 0.0)) > 0.0:
					zone_manager.call("apply_status_by_id", id, "gorge_mark", {})
					
			if cadence_surge:
				heal_requested.emit(6.0 * bond_mult * surge_mult)
				feedback_requested.emit("FEAST WAVE", Color(0.94, 0.58, 0.18, 1.0), 0.42)
			else:
				feedback_requested.emit(String(support_role.get("feedback_text", "GORGE")), Color(0.90, 0.52, 0.22, 1.0), 0.38)
				
			var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
			for check_sector in range(threat_count):
				highlight_ring_requested.emit(check_sector, Color(0.88, 0.50, 0.20, 1.0), 6.0)
				intervention_requested.emit(species_id, check_sector, Color(0.90, 0.52, 0.22, 0.55))
			flash_requested.emit(Color(0.28, 0.14, 0.08, 0.92), 0.12)

		"veilskin_phase":
			var phase_damage: float = float(support_role.get("effect_value", 12.0)) * bond_mult * surge_mult
			if cadence_surge:
				phase_damage *= 1.20
			
			var enemies: Array = ctx.get("targets", {}).get("enemies", [])
			if not enemies.is_empty():
				for e_data in enemies:
					zone_manager.call("damage_enemy_by_id", int(e_data.ref), phase_damage)
					zone_manager.call("apply_status_by_id", int(e_data.ref), "pale", {})
			
			var stamina_amount: float = 25.0
			var phase_text: String = String(support_role.get("feedback_text", "PHASE"))
			var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
			
			if cadence_surge:
				for pale_sector in range(threat_count):
					var id: int = _find_enemy_id_in_sector(zone_manager, pale_sector)
					if id != -1: zone_manager.call("apply_status_by_id", id, "pale", {})
				stamina_amount = 40.0
				phase_text = "VEIL CASCADE"
			elif mastery == "flow_state":
				for pale_sector in range(threat_count):
					var id: int = _find_enemy_id_in_sector(zone_manager, pale_sector)
					if id != -1: zone_manager.call("apply_status_by_id", id, "pale", {})
				stamina_amount = 35.0
				phase_text = "FULL PHASE"
			elif mastery == "in_pocket":
				stamina_amount = 32.0
				phase_text = "CLEAN PHASE"
				
			stamina_requested.emit(stamina_amount)
			feedback_requested.emit(phase_text, Color(0.78, 0.92, 1.0, 1.0), 0.36)
			for ring_sector in range(threat_count):
				highlight_ring_requested.emit(ring_sector, Color(0.72, 0.88, 1.0, 1.0), 5.5)
				intervention_requested.emit(species_id, ring_sector, Color(0.72, 0.88, 1.0, 0.55))
			flash_requested.emit(Color(0.10, 0.18, 0.26, 0.92), 0.10)

		"knellspine_peal":
			var peal_damage: float = float(support_role.get("effect_value", 8.0)) * combo_mult * bond_mult * surge_mult
			var charge_return: float = 18.0
			var peal_text: String = String(support_role.get("feedback_text", "PEAL"))
			
			var enemies: Array = ctx.get("targets", {}).get("enemies", [])
			if not enemies.is_empty():
				for e_data in enemies:
					zone_manager.call("damage_enemy_by_id", int(e_data.ref), peal_damage)
					if cadence_surge:
						zone_manager.call("apply_status_by_id", int(e_data.ref), "expose", {"duration": 3.0})
					elif mastery == "flow_state":
						zone_manager.call("apply_status_by_id", int(e_data.ref), "expose", {"duration": 2.5})

			if cadence_surge:
				peal_damage *= 1.25
				charge_return = 28.0
				peal_text = "SURGE PEAL"
			elif mastery == "flow_state":
				charge_return = 24.0
				peal_text = "DEEP PEAL"
			
			support_charge_requested.emit(charge_return)
				
			feedback_requested.emit(peal_text, Color(0.98, 0.82, 0.34, 1.0), 0.34)
			highlight_ring_requested.emit(sector, Color(1.0, 0.84, 0.42, 1.0), 6.2)
			intervention_requested.emit(species_id, sector, Color(0.98, 0.82, 0.34, 0.68))
			flash_requested.emit(Color(0.24, 0.18, 0.08, 0.92), 0.10)

		"marrowward_ward":
			var ward_heal: float = float(support_role.get("effect_value", 8.0)) * bond_mult * surge_mult
			var ward_stamina: float = 18.0
			var ward_text: String = String(support_role.get("feedback_text", "WARD"))
			var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
			
			for pale_sector in range(threat_count):
				var id: int = _find_enemy_id_in_sector(zone_manager, pale_sector)
				if id != -1: zone_manager.call("apply_status_by_id", id, "pale", {})
			if cadence_surge:
				ward_heal *= 1.5
				ward_stamina = 32.0
				ward_text = "FULL WARD"
			elif mastery == "flow_state":
				ward_heal *= 1.25
				ward_stamina = 24.0
				ward_text = "BONE WARD"
				
			heal_requested.emit(ward_heal)
			stamina_requested.emit(ward_stamina)
			feedback_requested.emit(ward_text, Color(0.78, 0.92, 0.82, 1.0), 0.34)
			for ring_sector in range(threat_count):
				highlight_ring_requested.emit(ring_sector, Color(0.78, 0.92, 0.82, 1.0), 5.4)
				intervention_requested.emit(species_id, ring_sector, Color(0.78, 0.92, 0.82, 0.55))
			flash_requested.emit(Color(0.12, 0.18, 0.14, 0.92), 0.10)

		"gorefane_maul":
			var maul_damage: float = float(support_role.get("effect_value", 14.0)) * combo_mult * bond_mult * surge_mult
			var maul_stacks: int = 1
			var maul_text: String = String(support_role.get("feedback_text", "MAUL"))
			if cadence_surge:
				maul_damage *= 1.22
				maul_stacks = 3
				maul_text = "FEAST MAUL"
			elif mastery == "flow_state":
				maul_stacks = 2
				maul_text = "RIP MAUL"
			
			var enemies: Array = ctx.get("targets", {}).get("enemies", [])
			if not enemies.is_empty():
				for e_data in enemies:
					zone_manager.call("damage_enemy_by_id", int(e_data.ref), maul_damage)
					for i in range(maul_stacks):
						zone_manager.call("apply_status_by_id", int(e_data.ref), "bleed", {})
					
			feedback_requested.emit(maul_text, Color(0.96, 0.44, 0.20, 1.0), 0.40)
			var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
			for check_sector in range(threat_count):
				highlight_ring_requested.emit(check_sector, Color(0.98, 0.48, 0.22, 1.0), 6.8)
				intervention_requested.emit(species_id, check_sector, Color(0.96, 0.44, 0.20, 0.62))
			flash_requested.emit(Color(0.30, 0.12, 0.08, 0.92), 0.12)

		"hushcoil_lull":
			var lull_damage: float = float(support_role.get("effect_value", 7.0)) * combo_mult * bond_mult * surge_mult
			var lull_text: String = String(support_role.get("feedback_text", "LULL"))
			var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
			
			var enemies: Array = ctx.get("targets", {}).get("enemies", [])
			if not enemies.is_empty():
				for e_data in enemies:
					zone_manager.call("damage_enemy_by_id", int(e_data.ref), lull_damage)
					if cadence_surge:
						zone_manager.call("apply_status_by_id", int(e_data.ref), "expose", {"duration": 3.0})
					elif mastery == "flow_state":
						zone_manager.call("apply_status_by_id", int(e_data.ref), "expose", {"duration": 2.5})

			for pale_sector in range(threat_count):
				var id: int = _find_enemy_id_in_sector(zone_manager, pale_sector)
				if id != -1: zone_manager.call("apply_status_by_id", id, "pale", {})

			if cadence_surge:
				stamina_requested.emit(18.0)
				lull_text = "DEAD LULL"
			elif mastery == "flow_state":
				lull_text = "DEEP LULL"
				
			feedback_requested.emit(lull_text, Color(0.72, 0.82, 0.98, 1.0), 0.34)
			for ring_sector in range(threat_count):
				highlight_ring_requested.emit(ring_sector, Color(0.68, 0.80, 0.98, 1.0), 5.8)
				intervention_requested.emit(species_id, ring_sector, Color(0.68, 0.80, 0.98, 0.55))
			flash_requested.emit(Color(0.10, 0.14, 0.24, 0.92), 0.10)

		"thornback_bleed":
			var bleed_damage: float = float(support_role.get("effect_value", 20.0)) * combo_mult * bond_mult * surge_mult
			if cadence_surge:
				bleed_damage *= 1.25
			
			var mastery_stacks: int = 1
			var bleed_text: String = "BLEED"
			var bleed_color: Color = Color(0.96, 0.75, 0.38, 1.0)
			if cadence_surge:
				mastery_stacks = 4
				bleed_text = "THORNBURST"
				bleed_color = Color(1.0, 0.84, 0.24, 1.0)
			elif mastery == "flow_state":
				mastery_stacks = 3
				bleed_text = "BLEED SURGE"
				bleed_color = Color(1.0, 0.82, 0.28, 1.0)
			elif mastery == "in_pocket":
				mastery_stacks = 2
				bleed_text = "DEEP BLEED"
				bleed_color = Color(0.98, 0.78, 0.32, 1.0)
			
			var enemies: Array = ctx.get("targets", {}).get("enemies", [])
			if not enemies.is_empty():
				for e_data in enemies:
					zone_manager.call("damage_enemy_by_id", int(e_data.ref), bleed_damage)
					for i in range(mastery_stacks):
						zone_manager.call("apply_status_by_id", int(e_data.ref), "bleed", {})
				
			feedback_requested.emit(bleed_text, bleed_color, 0.36)
			highlight_ring_requested.emit(sector, Color(0.94, 0.72, 0.34, 1.0), 7.5)
			intervention_requested.emit(species_id, sector, Color(0.96, 0.75, 0.38, 0.78))
			flash_requested.emit(Color(0.28, 0.16, 0.08, 0.92), 0.10)

		"coldvein_expose":
			var cold_damage: float = float(support_role.get("effect_value", 11.0)) * bond_mult * surge_mult
			var cold_text: String = String(support_role.get("feedback_text", "EXPOSE"))
			var cold_expose_time: float = vulnerability_duration
			if cadence_surge:
				cold_damage *= 1.22
				cold_expose_time += 1.0
			
			var enemies: Array = ctx.get("targets", {}).get("enemies", [])
			if not enemies.is_empty():
				for e_data in enemies:
					zone_manager.call("damage_enemy_by_id", int(e_data.ref), cold_damage)
					zone_manager.call("apply_status_by_id", int(e_data.ref), "expose", {"duration": cold_expose_time})
					if mastery == "flow_state":
						zone_manager.call("apply_status_by_id", int(e_data.ref), "pale", {})
			
			if cadence_surge:
				var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
				for cold_sector in range(threat_count):
					var id: int = _find_enemy_id_in_sector(zone_manager, cold_sector)
					if id != -1: zone_manager.call("apply_status_by_id", id, "pale", {})
				cold_text = "COLD CASCADE"
				feedback_requested.emit(cold_text, Color(0.72, 0.94, 1.0, 1.0), 0.42)
			else:
				feedback_requested.emit(cold_text, Color(0.80, 0.94, 1.0, 1.0), 0.32)
			
			highlight_ring_requested.emit(sector, Color(0.74, 0.92, 1.0, 1.0), 5.8)
			intervention_requested.emit(species_id, sector, Color(0.78, 0.90, 1.0, 0.62))
			flash_requested.emit(Color(0.08, 0.14, 0.24, 0.92), 0.10)

		"siltgrip_drag":
			var silt_heal: float = float(support_role.get("effect_value", 9.0)) * bond_mult * surge_mult
			var silt_text: String = String(support_role.get("feedback_text", "DRAG"))
			var silt_stacks: int = 1
			if cadence_surge:
				silt_heal *= 1.35
				silt_stacks = 2
				silt_text = "SILTGRIP SURGE"
			elif mastery == "flow_state":
				silt_stacks = 2
				silt_text = "DEEP DRAG"
			
			heal_requested.emit(silt_heal)
			
			var enemies: Array = ctx.get("targets", {}).get("enemies", [])
			if not enemies.is_empty():
				for e_data in enemies:
					# Apply Bleed stacks instead of Rend
					for i in range(silt_stacks):
						zone_manager.call("apply_status_by_id", int(e_data.ref), "bleed", {})
			
			if cadence_surge:
				feedback_requested.emit(silt_text, Color(0.44, 0.84, 0.66, 1.0), 0.42)
			else:
				feedback_requested.emit(silt_text, Color(0.38, 0.78, 0.60, 1.0), 0.34)
				
			var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
			for silt_ring in range(threat_count):
				highlight_ring_requested.emit(silt_ring, Color(0.36, 0.74, 0.58, 1.0), 5.2)
				intervention_requested.emit(species_id, silt_ring, Color(0.36, 0.74, 0.58, 0.55))
			flash_requested.emit(Color(0.06, 0.16, 0.14, 0.92), 0.10)

	_apply_collar_behavior(ctx, collar_mod)


func _apply_collar_behavior(ctx: Dictionary, collar_mod: Dictionary) -> void:
	if collar_mod.is_empty():
		return
	var zone_manager: Node = ctx.get("zone_manager")
	var satisfied: bool = bool(collar_mod.get("satisfied", false))
	var text: String = String(collar_mod.get("feedback_text", "COLLAR"))

	if bool(collar_mod.get("suppress_support", false)) and not satisfied:
		feedback_requested.emit("COLLAR REFUSES", Color(0.62, 0.72, 0.86, 1.0), 0.28)
		return

	if bool(collar_mod.get("echo_charge_only", false)) and satisfied:
		support_charge_requested.emit(float(collar_mod.get("support_charge_on_success", 0.0)))
		feedback_requested.emit(text, Color(0.72, 0.88, 1.0, 1.0), 0.32)
		return

	if not satisfied:
		return

	var heal_amount: float = float(collar_mod.get("heal_on_success", 0.0))
	if heal_amount > 0.0:
		heal_requested.emit(heal_amount)

	var charge_amount: float = float(collar_mod.get("support_charge_on_success", 0.0))
	if charge_amount > 0.0:
		support_charge_requested.emit(charge_amount)

	var status_id: String = String(collar_mod.get("status_on_success", ""))
	if not status_id.is_empty() and zone_manager != null:
		var enemies: Array = ctx.get("targets", {}).get("enemies", [])
		for e_data in enemies:
			zone_manager.call("apply_status_by_id", int(e_data.ref), status_id, {})

	feedback_requested.emit(text, Color(0.72, 0.88, 1.0, 1.0), 0.32)


func _find_enemy_id_in_sector(zone_manager: Node, sector: int) -> int:
	var enemy: Dictionary = zone_manager.call("get_enemy", sector)
	return int(enemy.get("id", -1)) if not enemy.is_empty() else -1


func build_mastery_context(
	effect_id: String,
	sector: int,
	phrase_window: String,
	cadence_window: String,
	last_mastery_context: Dictionary,
	timeout: float
) -> Dictionary:
	var context: Dictionary = {
		"source_event": "",
		"sector": sector,
		"action_quality": "",
		"beat_quality": "off",
		"phrase_window": phrase_window,
		"cadence_window": cadence_window,
		"is_recent": false,
		"window_id": ""
	}
	
	if not last_mastery_context.is_empty():
		var now: float = Time.get_ticks_msec() / 1000.0
		var age: float = now - float(last_mastery_context.get("timestamp", -999.0))
		if age <= timeout:
			context["source_event"] = str(last_mastery_context.get("event_id", ""))
			context["sector"] = int(last_mastery_context.get("sector", sector))
			context["action_quality"] = str(last_mastery_context.get("action_quality", ""))
			context["beat_quality"] = str(last_mastery_context.get("beat_quality", "off"))
			context["phrase_window"] = str(last_mastery_context.get("phrase_window", context["phrase_window"]))
			context["cadence_window"] = str(last_mastery_context.get("cadence_window", context["cadence_window"]))
			context["is_recent"] = true

	var action_quality: String = str(context.get("action_quality", ""))
	var beat_quality: String = str(context.get("beat_quality", "off"))
	var precision: bool = action_quality == "perfect" and (beat_quality == "perfect" or beat_quality == "good")

	if precision and cadence_window == "surge" and (phrase_window == "flow_state" or phrase_window == "in_pocket"):
		context["window_id"] = "cadence_surge"
	elif phrase_window == "flow_state":
		context["window_id"] = "flow_state"
	elif phrase_window == "in_pocket":
		context["window_id"] = "in_pocket"
	elif precision and cadence_window == "drive" and (effect_id == "thornback_bleed" or effect_id == "thornback_rend"):
		context["window_id"] = "in_pocket"

	return context


func apply_collar_logic(ctx: Dictionary, collar_data: Dictionary, combat_meter_node: Node) -> Dictionary:
	var collar_mod: Dictionary = {}
	if collar_data.is_empty():
		return collar_mod
		
	var mod: Dictionary = Dictionary(collar_data.get("mod", {}))
	collar_mod = mod.duplicate(true)
	collar_mod["feedback_text"] = String(collar_data.get("title", "COLLAR")).to_upper()
	collar_mod["satisfied"] = true
	
	if mod.has("support_impact_mult"):
		ctx["surge_mult"] = float(ctx.get("surge_mult", 1.0)) * float(mod["support_impact_mult"])
	
	if mod.has("stamina_cost_mult"):
		var cost: float = 25.0 * float(mod["stamina_cost_mult"])
		if combat_meter_node != null:
			var current_stamina: float = float(combat_meter_node.get("stamina"))
			if current_stamina >= cost:
				stamina_requested.emit(-cost)
			else:
				collar_mod["satisfied"] = false
				collar_mod["suppress_support"] = true
				
	return collar_mod
