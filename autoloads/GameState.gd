extends Node

# Persistent run-level state. This is intentionally small for prototype scope.
# It supports current combat plus the first post-fight reward choice.

var run_number: int = 1

var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_base_damage: float = 15.0
var taken_upgrades: Array[String] = []

# Each absorbed type is stored as:
# { "type": String, "eat_type": String, "source_species_id": String,
#   "damage_bonus": float }  -- or "heal_applied": float for hp_restore eat types
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

var _bond_order_counter: int = 0


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
	_bond_order_counter += 1

	for i in range(roster.size()):
		var creature: Dictionary = roster[i]
		if String(creature.get("species_id", "")) == species_id:
			var current_bond: int = int(creature.get("bond_level", 0))
			creature["bond_level"] = min(current_bond + 1, 5)
			creature["bond_order"] = _bond_order_counter
			roster[i] = creature
			return creature

	var new_creature: Dictionary = creature_data.duplicate(true)
	new_creature["bond_level"] = int(new_creature.get("bond_level", 1))
	if int(new_creature["bond_level"]) <= 0:
		new_creature["bond_level"] = 1
	new_creature["bond_order"] = _bond_order_counter

	roster.append(new_creature)
	return new_creature


func absorb_creature_type(creature_data: Dictionary) -> Dictionary:
	# Eat reward effect: branches on eat_effect.type.
	# hp_restore: heals immediately, stores heal_applied (no permanent damage bonus).
	# damage_flat: grants permanent attack damage as before.
	var eat_effect: Dictionary = creature_data.get("eat_effect", {})
	var eat_type: String = String(eat_effect.get("type", "damage_flat"))
	var value: float = float(eat_effect.get("value", 1.0))

	var entry: Dictionary = {
		"type": String(creature_data.get("primary_type", "unknown")),
		"eat_type": eat_type,
		"source_species_id": String(creature_data.get("species_id", "unknown"))
	}

	if eat_type == "hp_restore":
		var healed: float = heal_player(value)
		entry["heal_applied"] = healed
		entry["damage_bonus"] = 0.0
	else:
		entry["damage_bonus"] = value

	absorbed_types.append(entry)
	return entry


func add_upgrade(upgrade_id: String) -> void:
	if upgrade_id.is_empty() or taken_upgrades.has(upgrade_id):
		return

	taken_upgrades.append(upgrade_id)


func has_upgrade(upgrade_id: String) -> bool:
	return taken_upgrades.has(upgrade_id)


func heal_player(amount: float) -> float:
	if amount <= 0.0:
		return 0.0

	var before: float = player_hp
	player_hp = min(player_hp + amount, player_max_hp)
	return player_hp - before


func get_active_bonded_creature() -> Dictionary:
	var best_creature: Dictionary = {}
	var best_bond: int = -1
	var best_order: int = -1

	for creature in roster:
		var bond_level: int = int(creature.get("bond_level", 0))
		var bond_order: int = int(creature.get("bond_order", 0))
		if bond_level > best_bond:
			best_creature = creature
			best_bond = bond_level
			best_order = bond_order
		elif bond_level == best_bond and bond_order > best_order:
			best_creature = creature
			best_order = bond_order

	return best_creature


func reset_run_state() -> void:
	# Keeps persistent prototype progression small and explicit.
	# Roster clears on full run restart — bonded creatures are per-run, not permanent.
	player_hp = player_max_hp
	absorbed_types.clear()
	roster.clear()
	taken_upgrades.clear()
	_bond_order_counter = 0
