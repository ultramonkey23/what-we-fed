extends RefCounted

## Normalizes output from `examples/demo_encounter_stack/EncounterGenerator.gd` into the
## dictionary shape expected by `CombatScene._load_encounter_payload` (hp/damage, biome,
## boss labels, reward pool). Used only from debug harness paths.

const COMBAT_DATA = preload("res://data/CombatContent.gd")


static func normalize_for_combat_scene(raw: Dictionary, region_id: String, is_boss: bool) -> Dictionary:
	var out: Dictionary = raw.duplicate(true)
	_resolve_biome(out, region_id, is_boss)
	_normalize_phases(out)
	if is_boss:
		_apply_boss_fields(out)
	_sanitize_reward_pool(out)
	return out


static func _resolve_biome(encounter: Dictionary, region_id: String, is_boss: bool) -> void:
	var biome: Dictionary = Dictionary(encounter.get("biome", {}))
	if not biome.is_empty() and biome.has("background_color"):
		return
	match region_id:
		"pale_shelf":
			encounter["biome"] = COMBAT_DATA.BIOME_PALE_SHELF.duplicate(true)
		"drowned_cut":
			encounter["biome"] = COMBAT_DATA.BIOME_DROWNED_CUT.duplicate(true)
		_:
			if is_boss:
				encounter["biome"] = COMBAT_DATA.BIOME_FEEDING_HOLLOW_BOSS.duplicate(true)
			else:
				encounter["biome"] = COMBAT_DATA.BIOME_FEEDING_HOLLOW.duplicate(true)


static func _normalize_phases(encounter: Dictionary) -> void:
	var phases: Array = encounter.get("phases", [])
	for pi in range(phases.size()):
		var phase: Array = phases[pi]
		for ei in range(phase.size()):
			var e: Dictionary = Dictionary(phase[ei]).duplicate(true)
			if not e.has("hp") or float(e.get("hp", 0.0)) <= 0.0:
				e["hp"] = float(e.get("base_hp", 1.0))
			if not e.has("damage"):
				e["damage"] = float(e.get("base_damage", 1.0))
			phase[ei] = e
		phases[pi] = phase
	encounter["phases"] = phases


static func _apply_boss_fields(encounter: Dictionary) -> void:
	encounter["is_boss"] = true
	if String(encounter.get("boss_name", "")).is_empty():
		encounter["boss_name"] = String(encounter.get("title", "GENERATED BOSS"))
	if String(encounter.get("boss_subtitle", "")).is_empty():
		encounter["boss_subtitle"] = "DEBUG GENERATED PAYLOAD"


static func _sanitize_reward_pool(encounter: Dictionary) -> void:
	var pool_variant: Variant = encounter.get("reward_creature_pool", [])
	if pool_variant is Array:
		var pool: Array = pool_variant
		var cleaned: Array = []
		for item in pool:
			if item is Dictionary and not (item as Dictionary).is_empty():
				cleaned.append((item as Dictionary).duplicate(true))
		if cleaned.is_empty():
			var fallback: Dictionary = COMBAT_DATA.get_creature("thornback")
			if not fallback.is_empty():
				cleaned.append(fallback)
		encounter["reward_creature_pool"] = cleaned
	else:
		var fb: Dictionary = COMBAT_DATA.get_creature("thornback")
		encounter["reward_creature_pool"] = [] if fb.is_empty() else [fb]
