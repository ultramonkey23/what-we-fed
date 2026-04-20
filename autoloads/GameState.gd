extends Node

# Persistent run-level state. This is intentionally small for prototype scope.
# It supports current combat plus the first post-fight reward choice.

var run_number: int = 1

var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_base_damage: float = 15.0
var player_defense: float = 0.0
var taken_upgrades: Array[String] = []

# Each absorbed type is stored as:
# { "type": String, "eat_type": String, "source_species_id": String,
#   "damage_bonus": float }  -- or "heal_applied": float for hp_restore eat types
var absorbed_types: Array[Dictionary] = []

# Per-species DNA accumulated during the current run.
# Creature-specific — keys are species_id strings, values are accumulated float amounts.
# Bond/eat now requires spending dna_threshold DNA for the offered creature's species.
# Excess DNA past the threshold persists on the species entry (not removed until spent).
# Will feed metaprogression in a future pass.
var dna_by_species: Dictionary = {}

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

# Persistent creature storage — survives between runs.
var lair_roster: Array[Dictionary] = []
# The species_id of the creature the player has selected as starting support.
# Empty string means no pre-bonded creature at run start.
var active_lair_creature_id: String = ""

# The region the player selected before the current run. Persists between runs.
var active_region: Dictionary = {}

# Base stat values. reset_run_state() resets player_max_hp and player_base_damage
# to these constants before applying a region modifier, so bonuses never accumulate.
const BASE_MAX_HP: float = 100.0
const BASE_DAMAGE: float = 15.0
const BASE_DEFENSE: float = 0.0
const DEFENSE_DAMAGE_REDUCTION_PER_POINT: float = 0.02
const DEFENSE_DAMAGE_REDUCTION_CAP: float = 0.30
const COMBINED_DAMAGE_REDUCTION_CAP: float = 0.45


static func get_bond_level_mult(bond_level: int) -> float:
	# Returns a damage/heal multiplier based on bond level.
	# Level 1 = 1.0x, level 2 = 1.2x, level 3 = 1.4x, level 4 = 1.6x, level 5 = 1.8x.
	return 1.0 + max(0, bond_level - 1) * 0.20


func get_attack_damage() -> float:
	# Base prototype damage plus any absorbed type bonuses.
	var total_damage: float = player_base_damage

	for entry in absorbed_types:
		if entry.has("damage_bonus"):
			total_damage += float(entry["damage_bonus"])

	return total_damage


func get_defense_damage_reduction() -> float:
	if player_defense <= 0.0:
		return 0.0
	return min(player_defense * DEFENSE_DAMAGE_REDUCTION_PER_POINT, DEFENSE_DAMAGE_REDUCTION_CAP)


func get_hp_percent() -> float:
	if player_max_hp <= 0.0:
		return 0.0

	return player_hp / player_max_hp


func is_species_bonded(species_id: String) -> bool:
	for creature in roster:
		if String(creature.get("species_id", "")) == species_id:
			return true
	return false


func get_bonded_creature(species_id: String) -> Dictionary:
	for creature in roster:
		if String(creature.get("species_id", "")) == species_id:
			return creature.duplicate(true)
	return {}


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
			_sync_to_lair(creature)
			return creature

	var new_creature: Dictionary = creature_data.duplicate(true)
	new_creature["bond_level"] = int(new_creature.get("bond_level", 1))
	if int(new_creature["bond_level"]) <= 0:
		new_creature["bond_level"] = 1
	new_creature["bond_order"] = _bond_order_counter

	roster.append(new_creature)
	_sync_to_lair(new_creature)
	return new_creature


func set_active_lair_creature(species_id: String) -> void:
	active_lair_creature_id = species_id


func set_active_region(region: Dictionary) -> void:
	active_region = region.duplicate(true)


func _sync_to_lair(creature: Dictionary) -> void:
	# Mirrors a bonded or re-bonded creature into the persistent lair_roster.
	# If the species already exists in the lair, only updates bond_level upward.
	var species_id: String = String(creature.get("species_id", ""))
	for i in range(lair_roster.size()):
		if String(lair_roster[i].get("species_id", "")) == species_id:
			var existing_level: int = int(lair_roster[i].get("bond_level", 1))
			var new_level: int = int(creature.get("bond_level", 1))
			lair_roster[i]["bond_level"] = max(existing_level, new_level)
			return
	# First time this species reaches the lair — store a clean copy without bond_order.
	var lair_entry: Dictionary = creature.duplicate(true)
	lair_entry.erase("bond_order")
	lair_roster.append(lair_entry)


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
	elif eat_type == "max_hp_flat":
		player_max_hp += value
		var hp_before: float = player_hp
		player_hp = min(player_hp + value, player_max_hp)
		entry["max_hp_bonus"] = value
		entry["heal_applied"] = player_hp - hp_before
		entry["damage_bonus"] = 0.0
	elif eat_type == "support_charge":
		entry["support_charge_bonus"] = value
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


func add_dna(species_id: String, amount: float) -> void:
	if species_id.is_empty() or amount <= 0.0:
		return
	dna_by_species[species_id] = float(dna_by_species.get(species_id, 0.0)) + amount


func get_dna(species_id: String) -> float:
	return float(dna_by_species.get(species_id, 0.0))


func spend_dna(species_id: String, amount: float) -> void:
	var current: float = float(dna_by_species.get(species_id, 0.0))
	dna_by_species[species_id] = max(current - amount, 0.0)


func has_dna_for(species_id: String, threshold: float) -> bool:
	if threshold <= 0.0:
		return true
	return get_dna(species_id) >= threshold


func reset_run_state() -> void:
	# Resets per-run state. Base stats are restored from constants before region modifiers
	# are applied, so bonuses never accumulate across repeated runs.
	player_max_hp = BASE_MAX_HP
	player_base_damage = BASE_DAMAGE
	player_defense = BASE_DEFENSE
	var modifier: Dictionary = active_region.get("modifier", {})
	match modifier.get("type", ""):
		"attack_bonus":
			player_base_damage += float(modifier.get("value", 0.0))
		"max_hp_bonus":
			player_max_hp += float(modifier.get("value", 0.0))
	player_hp = player_max_hp
	absorbed_types.clear()
	dna_by_species.clear()
	roster.clear()
	taken_upgrades.clear()
	_bond_order_counter = 0
	# Re-seed the run roster with the player's selected lair creature, if any.
	if not active_lair_creature_id.is_empty():
		for entry in lair_roster:
			if String(entry.get("species_id", "")) == active_lair_creature_id:
				var seed_creature: Dictionary = entry.duplicate(true)
				seed_creature["bond_order"] = _bond_order_counter
				roster.append(seed_creature)
				break
