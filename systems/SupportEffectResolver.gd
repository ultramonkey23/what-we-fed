extends RefCounted

# SupportEffectResolver v2
# Extracts creature-specific support resolution from CombatScene.
# Uses signals for feedback and interventions to maintain a clean interface.

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const COMBAT_IMPACT_FEEDBACK = preload("res://systems/CombatImpactFeedback.gd")

signal feedback_requested(text, color, duration)
signal flash_requested(color, duration)
signal intervention_requested(species_id, lane, tint)
signal heal_requested(amount)
signal stamina_requested(amount)
signal support_charge_requested(amount)
signal highlight_ring_requested(lane, color, duration)

func resolve(ctx: Dictionary) -> void:
	var species_id: String = String(ctx.get("species_id", ""))
	var lane: int = int(ctx.get("lane", -1))
	var effect_id: String = String(ctx.get("effect_id", ""))
	var combo_mult: float = float(ctx.get("combo_mult", 1.0))
	var bond_mult: float = float(ctx.get("bond_mult", 1.0))
	var surge_mult: float = float(ctx.get("surge_mult", 1.0))
	var mastery: String = String(ctx.get("mastery_window", ""))
	var cadence_surge: bool = bool(ctx.get("cadence_surge", false))
	var bond_surge: bool = bool(ctx.get("bond_surge", false))
	var is_hollow_active: bool = bool(ctx.get("is_hollow_active", false))
	
	var lane_manager: Node = ctx.get("lane_manager")
	var combat_meter: Node = ctx.get("combat_meter")
	var game_state: Node = ctx.get("game_state")
	var collar_mod: Dictionary = Dictionary(ctx.get("collar_mod", {}))
	
	if species_id.is_empty() or lane_manager == null:
		return
	if bool(collar_mod.get("suppress_support", false)):
		_apply_collar_behavior(ctx, collar_mod)
		return

	var support_role: Dictionary = COMBAT_CONTENT.get_support_role(species_id)
	if support_role.is_empty():
		return

	var rend_charges: int = 4 if is_hollow_active else 3
	var expose_duration: float = 3.0 if is_hollow_active else 2.5

	match effect_id:
		"ashclaw_strike":
			var strike_damage: float = float(support_role.get("effect_value", 10.0)) * combo_mult * bond_mult * surge_mult
			var expose_time: float = expose_duration
			if cadence_surge:
				strike_damage *= 1.35
				expose_time += 1.0
			lane_manager.damage_enemy(lane, strike_damage)
			lane_manager.apply_status(lane, "expose", {"duration": expose_time})
			
			if cadence_surge:
				lane_manager.apply_status(lane, "rend", {"charges": rend_charges + 1})
				feedback_requested.emit("ASHCLAW SURGE", Color(1.0, 0.58, 0.18, 1.0), 0.46)
			elif mastery == "flow_state":
				lane_manager.apply_status(lane, "rend", {"charges": rend_charges - 1})
				feedback_requested.emit("ASHCLAW REND", Color(1.0, 0.52, 0.22, 1.0), 0.44)
			elif mastery == "in_pocket":
				lane_manager.apply_status(lane, "rend", {"charges": 1})
				feedback_requested.emit("ASHCLAW TEARS", Color(0.98, 0.56, 0.30, 1.0), 0.40)
			else:
				feedback_requested.emit(String(support_role.get("feedback_text", "ASHCLAW")), Color(0.95, 0.60, 0.42, 1.0), 0.36)
			
			highlight_ring_requested.emit(lane, Color(0.92, 0.56, 0.38, 1.0), 7.0)
			intervention_requested.emit(species_id, lane, Color(0.95, 0.60, 0.42, 0.72))
			flash_requested.emit(Color(0.25, 0.12, 0.10, 0.92), 0.10)

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
			highlight_ring_requested.emit(lane, Color(0.68, 0.94, 0.84, 1.0), 4.8)
			intervention_requested.emit(species_id, lane, Color(0.72, 0.96, 0.88, 0.62))
			flash_requested.emit(Color(0.12, 0.22, 0.18, 0.92), 0.10)

		"gruvek_gorge":
			var gorge_damage: float = float(support_role.get("effect_value", 10.0)) * combo_mult * bond_mult * surge_mult
			if cadence_surge:
				gorge_damage *= 1.18
			for check_lane in range(lane_manager.THREAT_COUNT):
				lane_manager.damage_enemy(check_lane, gorge_damage)
				var surviving: Dictionary = lane_manager.get_enemy(check_lane)
				if surviving.has("hp") and float(surviving["hp"]) > 0.0:
					lane_manager.apply_status(check_lane, "gorge_mark", {})
					
			if cadence_surge:
				heal_requested.emit(6.0 * bond_mult * surge_mult)
				feedback_requested.emit("FEAST WAVE", Color(0.94, 0.58, 0.18, 1.0), 0.42)
			else:
				feedback_requested.emit(String(support_role.get("feedback_text", "GORGE")), Color(0.90, 0.52, 0.22, 1.0), 0.38)
				
			for check_lane in range(lane_manager.THREAT_COUNT):
				highlight_ring_requested.emit(check_lane, Color(0.88, 0.50, 0.20, 1.0), 6.0)
				intervention_requested.emit(species_id, check_lane, Color(0.90, 0.52, 0.22, 0.55))
			flash_requested.emit(Color(0.28, 0.14, 0.08, 0.92), 0.12)

		"veilskin_phase":
			var phase_damage: float = float(support_role.get("effect_value", 12.0)) * bond_mult * surge_mult
			if cadence_surge:
				phase_damage *= 1.20
			lane_manager.damage_enemy(lane, phase_damage)
			
			var stamina_amount: float = 25.0
			var phase_text: String = String(support_role.get("feedback_text", "PHASE"))
			if cadence_surge:
				for pale_lane in range(lane_manager.THREAT_COUNT):
					lane_manager.apply_status(pale_lane, "pale", {})
				stamina_amount = 40.0
				phase_text = "VEIL CASCADE"
			elif mastery == "flow_state":
				for pale_lane in range(lane_manager.THREAT_COUNT):
					lane_manager.apply_status(pale_lane, "pale", {})
				stamina_amount = 35.0
				phase_text = "FULL PHASE"
			elif mastery == "in_pocket":
				lane_manager.apply_status(lane, "pale", {})
				stamina_amount = 32.0
				phase_text = "CLEAN PHASE"
			else:
				lane_manager.apply_status(lane, "pale", {})
				
			stamina_requested.emit(stamina_amount)
			feedback_requested.emit(phase_text, Color(0.78, 0.92, 1.0, 1.0), 0.36)
			for ring_lane in range(4):
				highlight_ring_requested.emit(ring_lane, Color(0.72, 0.88, 1.0, 1.0), 5.5)
				intervention_requested.emit(species_id, ring_lane, Color(0.72, 0.88, 1.0, 0.55))
			flash_requested.emit(Color(0.10, 0.18, 0.26, 0.92), 0.10)

		"knellspine_peal":
			var peal_damage: float = float(support_role.get("effect_value", 8.0)) * combo_mult * bond_mult * surge_mult
			var charge_return: float = 18.0
			var peal_text: String = String(support_role.get("feedback_text", "PEAL"))
			if cadence_surge:
				peal_damage *= 1.25
				charge_return = 28.0
				lane_manager.apply_status(lane, "expose", {"duration": 3.0})
				peal_text = "SURGE PEAL"
			elif mastery == "flow_state":
				charge_return = 24.0
				lane_manager.apply_status(lane, "expose", {"duration": 2.5})
				peal_text = "DEEP PEAL"
			
			lane_manager.damage_enemy(lane, peal_damage)
			support_charge_requested.emit(charge_return)
				
			feedback_requested.emit(peal_text, Color(0.98, 0.82, 0.34, 1.0), 0.34)
			highlight_ring_requested.emit(lane, Color(1.0, 0.84, 0.42, 1.0), 6.2)
			intervention_requested.emit(species_id, lane, Color(0.98, 0.82, 0.34, 0.68))
			flash_requested.emit(Color(0.24, 0.18, 0.08, 0.92), 0.10)

		"marrowward_ward":
			var ward_heal: float = float(support_role.get("effect_value", 8.0)) * bond_mult * surge_mult
			var ward_stamina: float = 18.0
			var ward_text: String = String(support_role.get("feedback_text", "WARD"))
			for pale_lane in range(lane_manager.THREAT_COUNT):
				lane_manager.apply_status(pale_lane, "pale", {})
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
			for ring_lane in range(4):
				highlight_ring_requested.emit(ring_lane, Color(0.78, 0.92, 0.82, 1.0), 5.4)
				intervention_requested.emit(species_id, ring_lane, Color(0.78, 0.92, 0.82, 0.55))
			flash_requested.emit(Color(0.12, 0.18, 0.14, 0.92), 0.10)

		"gorefane_maul":
			var maul_damage: float = float(support_role.get("effect_value", 14.0)) * combo_mult * bond_mult * surge_mult
			var maul_charges: int = 1
			var maul_text: String = String(support_role.get("feedback_text", "MAUL"))
			if cadence_surge:
				maul_damage *= 1.22
				maul_charges = 3
				maul_text = "FEAST MAUL"
			elif mastery == "flow_state":
				maul_charges = 2
				maul_text = "RIP MAUL"
			for check_lane in range(lane_manager.THREAT_COUNT):
				lane_manager.damage_enemy(check_lane, maul_damage)
				var maul_enemy: Dictionary = lane_manager.get_enemy(check_lane)
				if maul_enemy.has("hp") and float(maul_enemy["hp"]) > 0.0:
					lane_manager.apply_status(check_lane, "rend", {"charges": maul_charges})
					
			feedback_requested.emit(maul_text, Color(0.96, 0.44, 0.20, 1.0), 0.40)
			for check_lane in range(lane_manager.THREAT_COUNT):
				highlight_ring_requested.emit(check_lane, Color(0.98, 0.48, 0.22, 1.0), 6.8)
				intervention_requested.emit(species_id, check_lane, Color(0.96, 0.44, 0.20, 0.62))
			flash_requested.emit(Color(0.30, 0.12, 0.08, 0.92), 0.12)

		"hushcoil_lull":
			var lull_damage: float = float(support_role.get("effect_value", 7.0)) * combo_mult * bond_mult * surge_mult
			var lull_text: String = String(support_role.get("feedback_text", "LULL"))
			lane_manager.damage_enemy(lane, lull_damage)
			for pale_lane in range(lane_manager.THREAT_COUNT):
				lane_manager.apply_status(pale_lane, "pale", {})
			if cadence_surge:
				lane_manager.apply_status(lane, "expose", {"duration": 3.0})
				stamina_requested.emit(18.0)
				lull_text = "DEAD LULL"
			elif mastery == "flow_state":
				lane_manager.apply_status(lane, "expose", {"duration": 2.5})
				lull_text = "DEEP LULL"
				
			feedback_requested.emit(lull_text, Color(0.72, 0.82, 0.98, 1.0), 0.34)
			for ring_lane in range(4):
				highlight_ring_requested.emit(ring_lane, Color(0.68, 0.80, 0.98, 1.0), 5.8)
				intervention_requested.emit(species_id, ring_lane, Color(0.68, 0.80, 0.98, 0.55))
			flash_requested.emit(Color(0.10, 0.14, 0.24, 0.92), 0.10)

		"thornback_rend":
			var rend_damage: float = float(support_role.get("effect_value", 20.0)) * combo_mult * bond_mult * surge_mult
			if cadence_surge:
				rend_damage *= 1.25
			lane_manager.damage_enemy(lane, rend_damage)
			
			var mastery_charges: int = rend_charges
			var rend_text: String = String(support_role.get("feedback_text", "REND"))
			var rend_color: Color = Color(0.96, 0.75, 0.38, 1.0)
			if cadence_surge:
				mastery_charges = rend_charges + 3
				rend_text = "THORNBURST"
				rend_color = Color(1.0, 0.84, 0.24, 1.0)
			elif mastery == "flow_state":
				mastery_charges = rend_charges + 2
				rend_text = "REND SURGE"
				rend_color = Color(1.0, 0.82, 0.28, 1.0)
			elif mastery == "in_pocket":
				mastery_charges = rend_charges + 1
				rend_text = "DEEP REND"
				rend_color = Color(0.98, 0.78, 0.32, 1.0)
				
			lane_manager.apply_status(lane, "rend", {"charges": mastery_charges})
			feedback_requested.emit(rend_text, rend_color, 0.36)
			highlight_ring_requested.emit(lane, Color(0.94, 0.72, 0.34, 1.0), 7.5)
			intervention_requested.emit(species_id, lane, Color(0.96, 0.75, 0.38, 0.78))
			flash_requested.emit(Color(0.28, 0.16, 0.08, 0.92), 0.10)

		"coldvein_expose":
			var cold_damage: float = float(support_role.get("effect_value", 11.0)) * bond_mult * surge_mult
			var cold_text: String = String(support_role.get("feedback_text", "EXPOSE"))
			var cold_expose_time: float = expose_duration
			if cadence_surge:
				cold_damage *= 1.22
				cold_expose_time += 1.0
			lane_manager.damage_enemy(lane, cold_damage)
			lane_manager.apply_status(lane, "expose", {"duration": cold_expose_time})
			
			if cadence_surge:
				for cold_lane: int in range(4):
					if cold_lane != lane:
						lane_manager.apply_status(cold_lane, "pale", {})
				cold_text = "COLD CASCADE"
				feedback_requested.emit(cold_text, Color(0.72, 0.94, 1.0, 1.0), 0.42)
			elif mastery == "flow_state":
				lane_manager.apply_status(lane, "pale", {})
				feedback_requested.emit("COLD SEAM", Color(0.76, 0.96, 1.0, 1.0), 0.36)
			else:
				feedback_requested.emit(cold_text, Color(0.80, 0.94, 1.0, 1.0), 0.32)
			
			highlight_ring_requested.emit(lane, Color(0.74, 0.92, 1.0, 1.0), 5.8)
			intervention_requested.emit(species_id, lane, Color(0.78, 0.90, 1.0, 0.62))
			flash_requested.emit(Color(0.08, 0.14, 0.24, 0.92), 0.10)

		"siltgrip_drag":
			var silt_heal: float = float(support_role.get("effect_value", 9.0)) * bond_mult * surge_mult
			var silt_text: String = String(support_role.get("feedback_text", "DRAG"))
			var silt_charges: int = 1
			if cadence_surge:
				silt_heal *= 1.35
				silt_charges = 2
				silt_text = "SILTGRIP SURGE"
			elif mastery == "flow_state":
				silt_charges = 2
				silt_text = "DEEP DRAG"
			
			heal_requested.emit(silt_heal)
			for silt_lane: int in range(4):
				var silt_enemy: Dictionary = lane_manager.get_enemy(silt_lane)
				if silt_enemy.has("hp") and float(silt_enemy["hp"]) > 0.0:
					lane_manager.apply_status(silt_lane, "rend", {"charges": silt_charges})
			
			if cadence_surge:
				feedback_requested.emit(silt_text, Color(0.44, 0.84, 0.66, 1.0), 0.42)
			else:
				feedback_requested.emit(silt_text, Color(0.38, 0.78, 0.60, 1.0), 0.34)
				
			for silt_ring: int in range(4):
				highlight_ring_requested.emit(silt_ring, Color(0.36, 0.74, 0.58, 1.0), 5.2)
				intervention_requested.emit(species_id, silt_ring, Color(0.36, 0.74, 0.58, 0.55))
			flash_requested.emit(Color(0.06, 0.16, 0.14, 0.92), 0.10)

	_apply_collar_behavior(ctx, collar_mod)


func _apply_collar_behavior(ctx: Dictionary, collar_mod: Dictionary) -> void:
	if collar_mod.is_empty():
		return
	var lane: int = int(ctx.get("lane", -1))
	var lane_manager: Node = ctx.get("lane_manager")
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
	if not status_id.is_empty() and lane_manager != null and lane >= 0:
		lane_manager.apply_status(lane, status_id, {})

	if collar_mod.has("redirected_lane") and lane_manager != null and lane >= 0:
		for neighbor_lane in range(4):
			if neighbor_lane != lane:
				lane_manager.apply_status(neighbor_lane, "pale", {})

	feedback_requested.emit(text, Color(0.72, 0.88, 1.0, 1.0), 0.32)
