extends RefCounted
class_name CreatureRegistry

# Lightweight registry for per-creature definition files.
#
# Usage:
#   var def := CreatureRegistry.get_definition("ashclaw")
#   def.get_species_trait()          -> { "name", "summary", "trigger", ... }
#   def.get_display_name()           -> "Ashclaw"
#   def.get_dna_echo()               -> { "name", "summary", "effect_type", "value", ... }
#   CreatureRegistry.has_definition("ashclaw")   -> true
#   CreatureRegistry.get_all_defined_ids()       -> ["ashclaw"]
#
# Returns a base CreatureDefinition (all empty defaults) for unknown species.
# This is safe — callers get empty dicts/strings instead of null crashes.
#
# To add a new creature:
#   1. Create data/creatures/<species_id>_definition.gd (extends CreatureDefinition)
#   2. Add one match arm in _build()
#   3. Add the id string to get_all_defined_ids()

static var _cache: Dictionary = {}


static func get_definition(species_id: String) -> CreatureDefinition:
	if _cache.has(species_id):
		return _cache[species_id]
	var def: CreatureDefinition = _build(species_id)
	_cache[species_id] = def
	return def


static func has_definition(species_id: String) -> bool:
	match species_id:
		"ashclaw":
			return true
	return false


static func get_all_defined_ids() -> Array[String]:
	return ["ashclaw"]


static func _build(species_id: String) -> CreatureDefinition:
	match species_id:
		"ashclaw":
			return AshclawDefinition.new()
	return CreatureDefinition.new()
