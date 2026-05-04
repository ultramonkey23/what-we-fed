extends RefCounted
class_name CreatureState

var roster: Array[Dictionary] = []
var lair_roster: Array[Dictionary] = []
var active_lair_creature_id: String = ""
var active_lair_creature_ids: Array[String] = []
var archive_traits: Array[String] = [] # Traits extracted from Eaten creatures
var dna_by_species: Dictionary = {}
var predation_debt: Dictionary = {}
var _bond_order_counter: int = 0

func reset_run_state(active_support_slots: int = 1) -> void:
	roster.clear()
	_bond_order_counter = 0
	ensure_active_lair_creatures(active_support_slots)
	# Re-seed with selected lair creatures.
	for selected_species_id in active_lair_creature_ids:
		for entry in lair_roster:
			if String(entry.get("species_id", "")) == selected_species_id:
				var seed_creature: Dictionary = entry.duplicate(true)
				_bond_order_counter += 1
				seed_creature["bond_order"] = _bond_order_counter
				# Ensure spliced_traits exists
				if not seed_creature.has("spliced_traits"):
					seed_creature["spliced_traits"] = []
				roster.append(seed_creature)
				break


func ensure_active_lair_creature() -> String:
	ensure_active_lair_creatures(1)
	return active_lair_creature_id


func ensure_active_lair_creatures(active_support_slots: int = 1) -> Array[String]:
	var slot_count: int = maxi(active_support_slots, 1)
	if lair_roster.is_empty():
		active_lair_creature_id = ""
		active_lair_creature_ids.clear()
		return active_lair_creature_ids
	var valid_ids: Array[String] = []
	for raw_id in active_lair_creature_ids:
		var species_id: String = String(raw_id)
		if _has_lair_species(species_id) and not valid_ids.has(species_id):
			valid_ids.append(species_id)
	if _has_lair_species(active_lair_creature_id) and not valid_ids.has(active_lair_creature_id):
		valid_ids.insert(0, active_lair_creature_id)
	while valid_ids.size() > slot_count:
		valid_ids.pop_back()
	var sorted_lair: Array[Dictionary] = lair_roster.duplicate(true)
	sorted_lair.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("bond_level", 1)) > int(b.get("bond_level", 1))
	)
	for entry in sorted_lair:
		if valid_ids.size() >= slot_count:
			break
		var species_id: String = String(entry.get("species_id", ""))
		if not species_id.is_empty() and not valid_ids.has(species_id):
			valid_ids.append(species_id)
	active_lair_creature_ids = valid_ids
	active_lair_creature_id = active_lair_creature_ids[0] if not active_lair_creature_ids.is_empty() else ""
	return active_lair_creature_ids


func _has_lair_species(species_id: String) -> bool:
	if species_id.is_empty():
		return false
	for entry in lair_roster:
		if String(entry.get("species_id", "")) == species_id:
			return true
	return false

func add_dna(species_id: String, amount: float) -> bool:
	if species_id.is_empty() or amount <= 0.0: return false
	var current: float = float(dna_by_species.get(species_id, 0.0))
	dna_by_species[species_id] = current + amount
	return (current + amount) >= 20.0 and current < 20.0

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


func reset_profile_progression() -> void:
	roster.clear()
	lair_roster.clear()
	active_lair_creature_id = ""
	active_lair_creature_ids.clear()
	archive_traits.clear()
	dna_by_species.clear()
	predation_debt.clear()
	_bond_order_counter = 0
