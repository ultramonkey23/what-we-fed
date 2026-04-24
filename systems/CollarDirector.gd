extends RefCounted

# CollarDirector.gd
# Orchestrates how equipped collars modify support context during combat.

func apply_to_support_context(ctx: Dictionary, game_state: Node) -> Dictionary:
	var collar_id: String = String(game_state.get("equipped_collar_id", ""))
	if collar_id.is_empty():
		return ctx

	var collar_data: Dictionary = game_state.call("get_equipped_collar")
	if collar_data.is_empty():
		return ctx

	var mod: Dictionary = Dictionary(collar_data.get("mod", {}))
	var result: Dictionary = ctx.duplicate(true)
	result["collar_mod"] = mod

	# Example modification logic
	if mod.has("support_impact_mult"):
		result["surge_mult"] = float(result.get("surge_mult", 1.0)) * float(mod["support_impact_mult"])
	
	return result
