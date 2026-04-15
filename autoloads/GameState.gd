extends Node

# Persistent run-level state. This is intentionally small for prototype scope.
# It supports current combat plus the first post-fight reward choice.

var run_number: int = 1
var rebirth_count: int = 0

var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_base_damage: float = 15.0

# Each absorbed type is stored as:
# { "type": String, "damage_bonus": float, "source_species_id": String }
var absorbed_types: Array[Dictionary] = []

# Each roster creature is stored as:
# {
#   "species_id": String,
#   "primary_type": String,
#   "secondary_type": String,
#   "bond_level": int,
#   ...
# }
var roster: Array[Dictionary] = []

var current_map_seed: int = 0


func get_attack_damage() -> float:
	# Base prototype damage plus any absorbed type bonuses.
	var total_damage: float = player_base_damage

	for entry in absorbed_types:
		if entry.has("damage_bonus"):
			total_damage += float(entry["damage_bonus"])

	return total_damage


func get_hp_percent() -> float:
	if player_max_hp <= 0.0:
		return 0.0

	return player_hp / player_max_hp


func add_bonded_creature(creature_data: Dictionary) -> Dictionary:
	# Adds a new bonded creature to the roster, or increases bond level if the species already exists.
	var species_id: String = String(creature_data.get("species_id", ""))

	for i in range(roster.size()):
		var creature: Dictionary = roster[i]
		if String(creature.get("species_id", "")) == species_id:
			var current_bond: int = int(creature.get("bond_level", 0))
			creature["bond_level"] = min(current_bond + 1, 5)
			roster[i] = creature
			return creature

	var new_creature: Dictionary = creature_data.duplicate(true)
	new_creature["bond_level"] = int(new_creature.get("bond_level", 1))
	if int(new_creature["bond_level"]) <= 0:
		new_creature["bond_level"] = 1

	roster.append(new_creature)
	return new_creature


func absorb_creature_type(creature_data: Dictionary) -> Dictionary:
	# Eat reward effect: damage bonus is now read from eat_effect.value in creature data.
	# Falls back to 1.0 so creatures without eat_effect still work during transition.
	var eat_effect: Dictionary = creature_data.get("eat_effect", {})
	var bonus: float = float(eat_effect.get("value", 1.0))

	var entry: Dictionary = {
		"type": String(creature_data.get("primary_type", "unknown")),
		"damage_bonus": bonus,
		"source_species_id": String(creature_data.get("species_id", "unknown"))
	}

	absorbed_types.append(entry)
	return entry


func reset_run_state() -> void:
	# Keeps persistent prototype progression small and explicit.
	# Roster clears on full run restart — bonded creatures are per-run, not permanent.
	player_hp = player_max_hp
	absorbed_types.clear()
	roster.clear()
