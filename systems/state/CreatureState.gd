extends RefCounted
class_name CreatureState

var roster: Array[Dictionary] = []
var lair_roster: Array[Dictionary] = []
var active_lair_creature_id: String = ""
var archive_traits: Array[String] = [] # Traits extracted from Eaten creatures
var dna_by_species: Dictionary = {}
var predation_debt: Dictionary = {}
var _bond_order_counter: int = 0

func reset_run_state() -> void:
	roster.clear()
	_bond_order_counter = 0
	# Re-seed with selected lair creature
	if not active_lair_creature_id.is_empty():
		for entry in lair_roster:
			if String(entry.get("species_id", "")) == active_lair_creature_id:
				var seed_creature: Dictionary = entry.duplicate(true)
				seed_creature["bond_order"] = _bond_order_counter
				# Ensure spliced_traits exists
				if not seed_creature.has("spliced_traits"):
					seed_creature["spliced_traits"] = []
				roster.append(seed_creature)
				break

func add_dna(species_id: String, amount: float) -> void:
	if species_id.is_empty() or amount <= 0.0: return
	dna_by_species[species_id] = float(dna_by_species.get(species_id, 0.0)) + amount

func get_dna(species_id: String) -> float:
	return float(dna_by_species.get(species_id, 0.0))

func spend_dna(species_id: String, amount: float) -> void:
	var current: float = get_dna(species_id)
	dna_by_species[species_id] = max(current - amount, 0.0)

func spend_dna_any(amount: float) -> void:
	var remaining: float = amount
	var species_list: Array = dna_by_species.keys()
	# Sort species by DNA amount descending to spend from largest pools first
	species_list.sort_custom(func(a, b): return dna_by_species[a] > dna_by_species[b])
	
	for species_id in species_list:
		if remaining <= 0: break
		var current = dna_by_species[species_id]
		var spend = min(current, remaining)
		dna_by_species[species_id] -= spend
		remaining -= spend

func is_species_bonded(species_id: String) -> bool:
	for creature in roster:
		if String(creature.get("species_id", "")) == species_id: return true
	return false

func is_species_ever_bonded(species_id: String) -> bool:
	for entry in lair_roster:
		if String(entry.get("species_id", "")) == species_id: return true
	return false

func get_predation_debt(species_id: String) -> int:
	return int(predation_debt.get(species_id, 0))

func increment_predation_debt(species_id: String) -> void:
	predation_debt[species_id] = get_predation_debt(species_id) + 1
