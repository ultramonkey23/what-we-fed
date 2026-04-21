extends RefCounted

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")

const GRADE_BROOD: String = "brood"
const GRADE_MATURE: String = "mature"
const GRADE_ALPHA: String = "alpha"

const GRADE_ORDER: Array[String] = [
	GRADE_BROOD,
	GRADE_MATURE,
	GRADE_ALPHA
]


static func resolve_grade_ceiling(
	active_creature: Dictionary,
	region: Dictionary,
	run_number: int,
	level_index: int,
	path_elite: bool
) -> String:
	var creature_ceiling: String = resolve_creature_grade_ceiling(active_creature)
	var world_ceiling: String = resolve_world_grade_ceiling(region)
	var run_ceiling: String = resolve_run_grade_ceiling(run_number, level_index, path_elite)
	return min_grade_id(creature_ceiling, world_ceiling, run_ceiling)


static func resolve_creature_grade_ceiling(active_creature: Dictionary) -> String:
	var species_id: String = String(active_creature.get("species_id", ""))
	if species_id.is_empty():
		return GRADE_ALPHA
	var template: Dictionary = COMBAT_CONTENT.get_creature(species_id)
	if template.is_empty():
		return GRADE_ALPHA
	return normalize_grade_id(String(template.get("potential_max_grade", GRADE_ALPHA)))


static func resolve_world_grade_ceiling(region: Dictionary) -> String:
	return normalize_grade_id(String(region.get("potential_max_grade", GRADE_ALPHA)))


static func resolve_run_grade_ceiling(_run_number: int, _level_index: int, _path_elite: bool) -> String:
	# V1 keeps run-derived ceiling neutral while establishing explicit ownership.
	return GRADE_ALPHA


static func clamp_grade_id(grade_id: String, ceiling_id: String) -> String:
	var resolved_grade: String = normalize_grade_id(grade_id)
	var resolved_ceiling: String = normalize_grade_id(ceiling_id)
	if grade_rank(resolved_grade) <= grade_rank(resolved_ceiling):
		return resolved_grade
	return resolved_ceiling


static func min_grade_id(a: String, b: String, c: String) -> String:
	var out: String = normalize_grade_id(a)
	var b_id: String = normalize_grade_id(b)
	var c_id: String = normalize_grade_id(c)
	if grade_rank(b_id) < grade_rank(out):
		out = b_id
	if grade_rank(c_id) < grade_rank(out):
		out = c_id
	return out


static func normalize_grade_id(raw_id: String) -> String:
	var grade_id: String = raw_id.to_lower()
	if GRADE_ORDER.has(grade_id):
		return grade_id
	return GRADE_ALPHA


static func grade_rank(grade_id: String) -> int:
	var normalized: String = normalize_grade_id(grade_id)
	var idx: int = GRADE_ORDER.find(normalized)
	if idx < 0:
		return GRADE_ORDER.size() - 1
	return idx
