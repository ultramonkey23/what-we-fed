extends SceneTree

func _init() -> void:
	print("--- TEST SUPPORT COLLAR ---")
	
	# Mocks
	var GameStateMock = preload("res://autoloads/GameState.gd").new()
	var CombatMeterMock = preload("res://systems/CombatMeter.gd").new()
	var SupportEffectResolver = preload("res://systems/SupportEffectResolver.gd").new()
	
	# Mock data
	GameStateMock.equipped_collar_id = "iron_doctrine"
	CombatMeterMock.stamina = 100.0
	CombatMeterMock.stamina_max = 100.0
	
	var collar_data = GameStateMock.get_equipped_collar()
	print("Equipped Collar: ", collar_data.get("title", ""))
	
	var ctx: Dictionary = {
		"species_id": "ashclaw",
		"lane": 0,
		"effect_id": "ashclaw_strike",
		"combo_mult": 1.0,
		"bond_mult": 1.0,
		"surge_mult": 1.0,
		"combat_meter": CombatMeterMock,
		"game_state": GameStateMock
	}
	
	var collar_mod: Dictionary = {}
	if not collar_data.is_empty():
		var mod: Dictionary = Dictionary(collar_data.get("mod", {}))
		collar_mod = mod.duplicate(true)
		collar_mod["feedback_text"] = String(collar_data.get("title", "COLLAR")).to_upper()
		collar_mod["satisfied"] = true
		
		if mod.has("support_impact_mult"):
			ctx["surge_mult"] = float(ctx.get("surge_mult", 1.0)) * float(mod["support_impact_mult"])
		
		if mod.has("stamina_cost_mult"):
			var cost: float = 25.0 * float(mod["stamina_cost_mult"])
			var current_stamina: float = float(CombatMeterMock.stamina)
			if current_stamina >= cost:
				CombatMeterMock.stamina = max(current_stamina - cost, 0.0)
				print("Stamina deducted! New Stamina: ", CombatMeterMock.stamina)
			else:
				collar_mod["satisfied"] = false
				collar_mod["suppress_support"] = true
				print("Not enough stamina! Support suppressed.")
	
	ctx["collar_mod"] = collar_mod
	print("Surge Mult applied: ", ctx["surge_mult"])
	print("Collar Mod Content: ", ctx["collar_mod"])
	print("--- TEST END ---")
	
	quit()
