extends RefCounted

const PATH_CONTENT = preload("res://data/PathContent.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const RUN_PACING_CONTENT = preload("res://data/RunPacingContent.gd")

const BOND_NODE_IDS: Array[String] = ["bond_rite"]

const BRANCH_TEMPLATE_SETS: Array[Array] = [
	["elite_hunt", "bond_rite"],
	["elite_hunt", "predation_pool"],
	["bond_rite", "predation_pool"]
]


static func build_plan(_region_id: String = "", level_count: int = 0) -> Array[Dictionary]:
	var resolved_level_count: int = level_count
	if resolved_level_count <= 0:
		resolved_level_count = int(RUN_PACING_CONTENT.REGULAR_LEVEL_COUNT)
	resolved_level_count = max(resolved_level_count, 1)
	var branch_slots: Array[int] = _resolve_branch_slots(resolved_level_count)
	var plan: Array[Dictionary] = []
	for i in range(resolved_level_count):
		var branch_candidates: Array[Dictionary] = []
		var branch_idx: int = branch_slots.find(i)
		if branch_idx >= 0 and branch_idx < BRANCH_TEMPLATE_SETS.size():
			branch_candidates = _build_candidates_from_template(BRANCH_TEMPLATE_SETS[branch_idx])
		var is_branch: bool = not branch_candidates.is_empty()
		plan.append({
			"level_index": i,
			"node_id": PATH_CONTENT.DEFAULT_NODE_ID,
			"is_branch_slot": is_branch,
			"branch_candidates": branch_candidates
		})
	return plan


static func _build_candidates_from_template(node_ids: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for raw_id in node_ids:
		out.append(PATH_CONTENT.get_node(String(raw_id)))
	return out


static func _resolve_branch_slots(level_count: int) -> Array[int]:
	# Live build currently runs 3 regular levels.
	# For this case, branch before L2 and L3 (indices 1 and 2).
	var max_index: int = max(level_count - 1, 0)
	if level_count <= 1:
		return []
	if level_count <= 3:
		return _unique_valid_slots([1, max_index], max_index)
	# Medium runs: keep two earlier commitments plus one final commit.
	if level_count <= 6:
		return _unique_valid_slots([2, 4, max_index], max_index)
	# Long runs: preserve original 9-level intent shape.
	return _unique_valid_slots([3, 6, max_index], max_index)


static func _unique_valid_slots(raw_slots: Array[int], max_index: int) -> Array[int]:
	var out: Array[int] = []
	for slot in raw_slots:
		var clamped_slot: int = clampi(slot, 1, max_index)
		if not out.has(clamped_slot):
			out.append(clamped_slot)
	return out


static func is_branch_slot(plan: Array[Dictionary], level_index: int) -> bool:
	var level_plan: Dictionary = get_level_plan(plan, level_index)
	if level_plan.is_empty():
		return false
	return bool(level_plan.get("is_branch_slot", false))


static func get_branch_candidates(plan: Array[Dictionary], level_index: int) -> Array[Dictionary]:
	var level_plan: Dictionary = get_level_plan(plan, level_index)
	if level_plan.is_empty():
		return []
	var result: Array[Dictionary] = []
	for node in level_plan.get("branch_candidates", []):
		result.append(Dictionary(node).duplicate(true))
	return result


static func get_level_plan(plan: Array[Dictionary], level_index: int) -> Dictionary:
	if level_index < 0 or level_index >= plan.size():
		return {}
	return Dictionary(plan[level_index]).duplicate(true)


static func get_level_node(plan: Array[Dictionary], level_index: int) -> Dictionary:
	var level_plan: Dictionary = get_level_plan(plan, level_index)
	if level_plan.is_empty():
		return PATH_CONTENT.get_node(PATH_CONTENT.DEFAULT_NODE_ID)
	return PATH_CONTENT.get_node(String(level_plan.get("node_id", PATH_CONTENT.DEFAULT_NODE_ID)))


static func apply_branch_choice(plan: Array[Dictionary], level_index: int, node_id: String) -> Array[Dictionary]:
	var updated: Array[Dictionary] = []
	for entry in plan:
		updated.append(Dictionary(entry).duplicate(true))
	if level_index < 0 or level_index >= updated.size():
		return updated

	var level_plan: Dictionary = Dictionary(updated[level_index]).duplicate(true)
	var candidate_ids: PackedStringArray = PackedStringArray()
	for candidate in level_plan.get("branch_candidates", []):
		candidate_ids.append(String(Dictionary(candidate).get("id", "")))
	if candidate_ids.has(node_id):
		level_plan["node_id"] = node_id
	else:
		level_plan["node_id"] = PATH_CONTENT.DEFAULT_NODE_ID
	updated[level_index] = level_plan
	return updated


static func apply_node_effects(node: Dictionary, state: Node, run_growth: Node, reward_director: Node) -> Dictionary:
	var node_id: String = String(node.get("id", PATH_CONTENT.DEFAULT_NODE_ID))
	var encounter_options: Dictionary = Dictionary(node.get("encounter_options", {})).duplicate(true)
	var reward_context: Dictionary = Dictionary(node.get("reward_context", {})).duplicate(true)

	if BOND_NODE_IDS.has(node_id):
		_apply_bond_rite_entry(state, run_growth, node)

	if reward_director != null and is_instance_valid(reward_director):
		if reward_director.has_method("set_level_completion_context"):
			reward_director.call("set_level_completion_context", reward_context)

	return {
		"node_id": node_id,
		"display_name": String(node.get("display_name", "Prey")),
		"encounter_options": encounter_options,
		"reward_context": reward_context
	}


static func _apply_bond_rite_entry(state: Node, run_growth: Node, node: Dictionary) -> void:
	if state == null or not is_instance_valid(state):
		return
	var effects: Dictionary = Dictionary(node.get("entry_effects", {}))
	var gain: int = max(int(effects.get("bond_level_gain", 0)), 0)
	if gain > 0:
		_raise_active_bond_level(gain)

	var support_floor: float = float(effects.get("support_floor", 0.0))
	if support_floor > 0.0 and run_growth != null and is_instance_valid(run_growth):
		var current: float = float(run_growth.get("support_charge"))
		if current < support_floor and run_growth.has_method("gain_support_charge_direct"):
			run_growth.call("gain_support_charge_direct", support_floor - current)


static func _raise_active_bond_level(gain: int) -> void:
	if gain <= 0:
		return
	var active: Dictionary = GameState.get_active_bonded_creature()
	var species_id: String = String(active.get("species_id", ""))
	if species_id.is_empty():
		return
	var base_creature: Dictionary = COMBAT_CONTENT.get_creature(species_id)
	if base_creature.is_empty():
		return
	for _i in range(gain):
		GameState.add_bonded_creature(base_creature)
