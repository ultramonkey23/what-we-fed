extends Node

# Persistent run-level state. Modularized for v2.0 Architecture.
const RITUAL_CONTENT = preload("res://data/RitualConsumableContent.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const CREATURE_TRAITS = preload("res://data/CreatureTraitContent.gd")
const COLLAR_CONTENT = preload("res://data/CollarContent.gd")
const LAIR_RESONANCE = preload("res://data/LairResonanceContent.gd")

# Sub-state Components
var player := PlayerState.new()
var creatures := CreatureState.new()
var rewards := RewardState.new()
var world_fate := WorldFateState.new()
var run := RunState.new()

var collar_inventory: Array[String] = []
var equipped_collar_id: String = ""

# API Proxies for backward compatibility
var run_number: int:
	get: return run.run_number
	set(v): run.run_number = v
var run_in_progress: bool:
	get: return run.run_in_progress
	set(v): run.run_in_progress = v
var player_hp: float:
	get: return player.hp
	set(v): player.hp = v
var player_max_hp: float:
	get: return player.max_hp
	set(v): player.max_hp = v
var player_base_damage: float:
	get: return player.base_damage
	set(v): player.base_damage = v
var player_defense: float:
	get: return player.defense
	set(v): player.defense = v

# Ecosystem Stats Proxies
var stat_vitality: float:
	get: return player.stat_vitality
	set(v): player.stat_vitality = v
var stat_power: float:
	get: return player.stat_power
	set(v): player.stat_power = v
var stat_carapace: float:
	get: return player.stat_carapace
	set(v): player.stat_carapace = v
var stat_endurance: float:
	get: return player.stat_endurance
	set(v): player.stat_endurance = v
var stat_swiftness: float:
	get: return player.stat_swiftness
	set(v): player.stat_swiftness = v
var stat_luck: float:
	get: return player.stat_luck
	set(v): player.stat_luck = v
var stat_potential: float:
	get: return player.stat_potential
	set(v): player.stat_potential = v
var stat_intelligence: float:
	get: return player.stat_intelligence
	set(v): player.stat_intelligence = v
var stat_adaptability: float:
	get: return player.stat_adaptability
	set(v): player.stat_adaptability = v

var taken_upgrades: Array[String]:
	get: return player.taken_upgrades
	set(v): player.taken_upgrades = v

var is_in_combat: bool:
	get: return run.is_in_combat
	set(v): run.is_in_combat = v

var reward_loot_slots: Dictionary:
	get: return rewards.loot_slots
	set(v): rewards.loot_slots = v
var reward_artifact_slots: Dictionary:
	get: return rewards.artifact_slots
	set(v): rewards.artifact_slots = v
var reward_consumable_slots: Dictionary:
	get: return rewards.consumable_slots
	set(v): rewards.consumable_slots = v

var reward_bond_streak: int:
	get: return rewards.bond_streak
	set(v): rewards.bond_streak = v
var reward_eat_streak: int:
	get: return rewards.eat_streak
	set(v): rewards.eat_streak = v
var reward_bond_total: int:
	get: return rewards.bond_total
	set(v): rewards.bond_total = v
var reward_eat_total: int:
	get: return rewards.eat_total
	set(v): rewards.eat_total = v

var absorbed_types: Array[Dictionary]:
	get: return rewards.absorbed_types
	set(v): rewards.absorbed_types = v
var active_mutations: Array[Dictionary]:
	get: return rewards.active_mutations
	set(v): rewards.active_mutations = v

var last_beat_quality: String:
	get: return run.last_beat_quality
	set(v): run.last_beat_quality = v

var dna_by_species: Dictionary:
	get: return creatures.dna_by_species
	set(v): creatures.dna_by_species = v
var archive_traits: Array[String]:
	get: return creatures.archive_traits
	set(v): creatures.archive_traits = v
var predation_debt: Dictionary:
	get: return creatures.predation_debt
	set(v): creatures.predation_debt = v
var roster: Array[Dictionary]:
	get: return creatures.roster
	set(v): creatures.roster = v
var lair_roster: Array[Dictionary]:
	get: return creatures.lair_roster
	set(v): creatures.lair_roster = v
var active_lair_creature_id: String:
	get: return creatures.active_lair_creature_id
	set(v): creatures.active_lair_creature_id = v
var active_region: Dictionary:
	get: return run.active_region
	set(v): run.active_region = v
var run_path_plan: Array[Dictionary]:
	get: return run.path_plan
	set(v): run.path_plan = v
var run_path_chosen_ids: PackedStringArray:
	get: return run.path_chosen_ids
	set(v): run.path_chosen_ids = v
var growth_choice_intersection_payload: Dictionary:
	get: return run.growth_choice_intersection_payload
	set(v): run.growth_choice_intersection_payload = v

var world_fate_channels: Dictionary:
	get: return world_fate.channels
	set(v): world_fate.channels = v
var world_dominant_fate: String:
	get: return world_fate.dominant_fate
	set(v): world_fate.dominant_fate = v
var world_stain_fates: PackedStringArray:
	get: return world_fate.stain_fates
	set(v): world_fate.stain_fates = v
var world_fate_last_snapshot: Dictionary:
	get: return world_fate.last_snapshot
	set(v): world_fate.last_snapshot = v

# Constants (Moved to appropriate sub-states where needed, but kept here for easy access)
const WORLD_FATE_IDS = WorldFateState.WORLD_FATE_IDS
const REWARD_MUTATION_CAP: int = 3
const LOOT_SLOT_LIMITS = RewardState.LOOT_SLOT_LIMITS
const ARTIFACT_SLOT_LIMITS = RewardState.ARTIFACT_SLOT_LIMITS

const WORLD_FATE_PRIMARY_MIN: float = 0.12
const WORLD_FATE_SWITCH_MARGIN: float = 0.08
const WORLD_FATE_STAIN_THRESHOLD: float = 0.28
const WORLD_FATE_DELTA_CAP_PER_RUN: float = 0.24
const WORLD_FATE_DECAY_PER_RUN: float = 0.04

const BASE_MAX_HP = PlayerState.BASE_MAX_HP
const BASE_DAMAGE = PlayerState.BASE_DAMAGE
const BASE_DEFENSE = PlayerState.BASE_DEFENSE
const DEFENSE_DAMAGE_REDUCTION_PER_POINT = PlayerState.DEFENSE_DAMAGE_REDUCTION_PER_POINT
const DEFENSE_DAMAGE_REDUCTION_CAP = PlayerState.DEFENSE_DAMAGE_REDUCTION_CAP
const COMBINED_DAMAGE_REDUCTION_CAP: float = 0.45

# Internal state
var _bond_order_counter: int:
	get: return creatures._bond_order_counter
	set(v): creatures._bond_order_counter = v

var _world_run_bond_events: int:
	get: return world_fate.bond_events
	set(v): world_fate.bond_events = v
var _world_run_eat_events: int:
	get: return world_fate.eat_events
	set(v): world_fate.eat_events = v
var _world_pending_boss_events: Array[Dictionary]:
	get: return world_fate.pending_boss_events
	set(v): world_fate.pending_boss_events = v
var _world_run_tempo_counts: Dictionary:
	get: return world_fate.tempo_counts
	set(v): world_fate.tempo_counts = v
var _world_run_tempo_events: Array[Dictionary]:
	get: return world_fate.tempo_events
	set(v): world_fate.tempo_events = v


func _ready() -> void:
	if not EventBus.creature_bonded.is_connected(_on_creature_bonded_for_world):
		EventBus.creature_bonded.connect(_on_creature_bonded_for_world)
	if not EventBus.creature_eaten.is_connected(_on_creature_eaten_for_world):
		EventBus.creature_eaten.connect(_on_creature_eaten_for_world)
	if not EventBus.combat_started.is_connected(_on_combat_started):
		EventBus.combat_started.connect(_on_combat_started)
	if not EventBus.combat_ended.is_connected(_on_combat_ended):
		EventBus.combat_ended.connect(_on_combat_ended)


func _exit_tree() -> void:
	if EventBus.creature_bonded.is_connected(_on_creature_bonded_for_world):
		EventBus.creature_bonded.disconnect(_on_creature_bonded_for_world)
	if EventBus.creature_eaten.is_connected(_on_creature_eaten_for_world):
		EventBus.creature_eaten.disconnect(_on_creature_eaten_for_world)


func _on_combat_started(_enemy_data: Array) -> void:
	is_in_combat = true


func _on_combat_ended(_victory: bool) -> void:
	is_in_combat = false


func _process(delta: float) -> void:
	if not is_in_combat and run_in_progress:
		# Flesh (Vitality) Passive Regeneration: 
		# Every 10 points above 100 base grants 0.5 HP/sec.
		if stat_vitality > 100.0:
			var regen_rate: float = (stat_vitality - 100.0) / 10.0 * 0.5
			if regen_rate > 0.0 and player_hp < player_max_hp:
				player_hp = min(player_hp + regen_rate * delta, player_max_hp)


# --- Creature Logic ---

static func get_bond_level_mult(bond_level: int) -> float:
	return 1.0 + max(0, bond_level - 1) * 0.20


func get_creature_growth_stage(bond_level: int) -> String:
	if bond_level <= 1: return "baby"
	elif bond_level <= 3: return "teen"
	return "adult"


func get_bond_level_stats_readout(bond_level: int) -> Dictionary:
	var current_mult: float = get_bond_level_mult(bond_level)
	var next_mult: float = get_bond_level_mult(min(bond_level + 1, 5))
	return {
		"current_mult": current_mult,
		"next_mult": next_mult,
		"is_max": bond_level >= 5
	}


func is_species_bonded(species_id: String) -> bool:
	return creatures.is_species_bonded(species_id)


func get_bonded_creature(species_id: String) -> Dictionary:
	for creature in roster:
		if String(creature.get("species_id", "")) == species_id:
			return creature.duplicate(true)
	return {}


func add_bonded_creature(creature_data: Dictionary) -> Dictionary:
	var species_id: String = String(creature_data.get("species_id", ""))
	_bond_order_counter += 1

	for i in range(roster.size()):
		var creature: Dictionary = roster[i]
		if String(creature.get("species_id", "")) == species_id:
			var current_bond: int = int(creature.get("bond_level", 0))
			if current_bond >= 5:
				creature["is_exceptional"] = true
				creature["variant_id"] = "exceptional_alpha"
			else:
				creature["bond_level"] = current_bond + 1
			creature["bond_order"] = _bond_order_counter
			roster[i] = creature
			_sync_to_lair(creature)
			set_active_lair_creature(species_id)
			return creature

	var new_creature: Dictionary = creature_data.duplicate(true)
	new_creature["bond_level"] = int(new_creature.get("bond_level", 1))
	if int(new_creature["bond_level"]) <= 0:
		new_creature["bond_level"] = 1
	new_creature["bond_order"] = _bond_order_counter

	roster.append(new_creature)
	_sync_to_lair(new_creature)
	set_active_lair_creature(species_id)
	return new_creature


func set_active_lair_creature(species_id: String) -> void:
	active_lair_creature_id = species_id


func set_active_region(region: Dictionary) -> void:
	active_region = region.duplicate(true)


func _sync_to_lair(creature: Dictionary) -> void:
	var species_id: String = String(creature.get("species_id", ""))
	for i in range(lair_roster.size()):
		if String(lair_roster[i].get("species_id", "")) == species_id:
			var existing_level: int = int(lair_roster[i].get("bond_level", 1))
			var new_level: int = int(creature.get("bond_level", 1))
			lair_roster[i]["bond_level"] = max(existing_level, new_level)
			if creature.get("is_exceptional", false):
				lair_roster[i]["is_exceptional"] = true
				lair_roster[i]["variant_id"] = String(creature.get("variant_id", ""))
			return
	var lair_entry: Dictionary = creature.duplicate(true)
	lair_entry.erase("bond_order")
	lair_roster.append(lair_entry)


func is_species_ever_bonded(species_id: String) -> bool:
	return creatures.is_species_ever_bonded(species_id)


func get_creature_predation_debt(species_id: String) -> int:
	return creatures.get_predation_debt(species_id)


func get_effective_dna_threshold(species_id: String) -> float:
	var creature_data: Dictionary = COMBAT_CONTENT.get_creature(species_id)
	if creature_data.is_empty(): return 999.0
	var base_threshold: float = float(creature_data.get("dna_threshold", 999.0))
	var debt_mult: float = 1.0
	if not is_species_ever_bonded(species_id):
		debt_mult += get_creature_predation_debt(species_id) * 0.25
	return max((base_threshold * debt_mult) / stat_potential, 1.0)


# --- Stats & Helpers ---

func get_attack_damage() -> float:
	return player.get_attack_damage(absorbed_types)


func get_defense_damage_reduction() -> float:
	return player.get_defense_damage_reduction()


func get_hp_percent() -> float:
	return player.get_hp_percent()


func heal_player(amount: float) -> float:
	return player.heal(amount)


func get_power_level() -> float:
	var base: float = 0.0
	base += stat_vitality * 1.2
	base += stat_power * 8.0
	base += stat_carapace * 12.0
	base += stat_endurance * 2.5
	var mult: float = 1.0
	mult += (stat_swiftness - 1.0) * 5.0
	mult += (stat_luck - 1.0) * 3.0
	mult += (stat_potential - 1.0) * 12.0
	mult += (stat_intelligence - 1.0) * 6.0
	mult += (stat_adaptability - 1.0) * 8.0
	var final_power: float = base * mult
	var flicker: float = 1.0 + (randf() * 0.03 - 0.015)
	return max(final_power * flicker, 0.0)


# --- Rewards & Mutations ---

func absorb_creature_type(creature_data: Dictionary) -> Dictionary:
	var species_id: String = String(creature_data.get("species_id", "unknown"))
	if not is_species_ever_bonded(species_id):
		creatures.increment_predation_debt(species_id)

	# Trait Extraction (V2.1 Siralim Upgrade)
	var trait_id: String = String(creature_data.get("trait_id", ""))
	if not trait_id.is_empty() and not archive_traits.has(trait_id):
		archive_traits.append(trait_id)
		# Signal that a new trait was archived
		EventBus.emit_signal("proc_feedback_requested", "TRAIT EXTRACTED: " + trait_id.to_upper(), Color(0.85, 0.44, 0.18, 1.0))

	var eat_effect: Dictionary = creature_data.get("eat_effect", {})
	var eat_type: String = String(eat_effect.get("type", "damage_flat"))
	var value: float = float(eat_effect.get("value", 1.0))

	var entry: Dictionary = {
		"type": String(creature_data.get("primary_type", "unknown")),
		"eat_type": eat_type,
		"source_species_id": species_id
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
	
	var mutation: Dictionary = creature_data.get("mutation", {})
	if not mutation.is_empty():
		var active_entry: Dictionary = mutation.duplicate(true)
		var effect: Dictionary = active_entry.get("effect", {})
		active_entry["current_charges"] = int(effect.get("charges", 0))
		active_entry["feedback_fired"] = false
		active_entry["source_species_id"] = species_id
		active_mutations.append(active_entry)
		if active_mutations.size() > REWARD_MUTATION_CAP:
			active_mutations.pop_front()

	return entry


func get_current_resonance_perk() -> Dictionary:
	return LAIR_RESONANCE.get_resonance_perk(world_dominant_fate)


func splice_trait_to_creature(species_id: String, trait_id: String) -> bool:
	var base_cost: float = 250.0 # Standard splicing cost
	var perk: Dictionary = get_current_resonance_perk()
	var cost: float = base_cost * float(perk.get("splicing_cost_mult", 1.0))
	
	if not has_dna_for(species_id, cost): return false
	
	for i in range(lair_roster.size()):
		if String(lair_roster[i].get("species_id", "")) == species_id:
			var spliced: Array = lair_roster[i].get("spliced_traits", [])
			if spliced.has(trait_id): return false
			
			spend_dna(species_id, cost)
			spliced.append(trait_id)
			lair_roster[i]["spliced_traits"] = spliced
			
			# If this is the active creature, update the active roster too
			for j in range(roster.size()):
				if String(roster[j].get("species_id", "")) == species_id:
					roster[j]["spliced_traits"] = spliced
					break
			return true
	return false


func request_ascension(species_id: String) -> bool:
	var cost: float = LAIR_RESONANCE.ASCENSION_DNA_COST
	if not has_dna_for(species_id, cost): return false
	
	# World Fate Alignment Check
	var affinity: String = LAIR_RESONANCE.get_species_affinity(species_id)
	if world_dominant_fate != affinity:
		# Cannot ascend if world resonance does not match affinity
		return false
	
	for i in range(lair_roster.size()):
		if String(lair_roster[i].get("species_id", "")) == species_id:
			var bond: int = int(lair_roster[i].get("bond_level", 1))
			if bond < 5: return false # Must be max bond to ascend
			if bool(lair_roster[i].get("is_ascended", false)): return false
			
			spend_dna(species_id, cost)
			lair_roster[i]["is_ascended"] = true
			lair_roster[i]["is_exceptional"] = true # Ascended are always exceptional
			lair_roster[i]["variant_id"] = "ascended_sovereign"
			
			# Mastery Trait Integration
			var mastery: Dictionary = LAIR_RESONANCE.get_mastery_trait(species_id)
			lair_roster[i]["mastery_trait_id"] = String(mastery.get("id", ""))
			
			# If this is the active creature, update the active roster too
			for j in range(roster.size()):
				if String(roster[j].get("species_id", "")) == species_id:
					roster[j]["is_ascended"] = true
					roster[j]["is_exceptional"] = true
					roster[j]["variant_id"] = "ascended_sovereign"
					roster[j]["mastery_trait_id"] = String(mastery.get("id", ""))
					break
			
			EventBus.emit_signal("creature_ascended", {"species_id": species_id, "fate_id": world_dominant_fate})
			return true
	return false


func get_active_mutations_of_type(effect_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for mut in active_mutations:
		var effect: Dictionary = mut.get("effect", {})
		if String(effect.get("type", "")) == effect_type:
			result.append(mut)
	return result


func consume_mutation_charge(mutation_id: String, amount: int = 1) -> void:
	for i in range(active_mutations.size()):
		if String(active_mutations[i].get("id", "")) == mutation_id:
			var charges: int = int(active_mutations[i].get("current_charges", 0))
			if charges > 0:
				active_mutations[i]["current_charges"] = max(0, charges - amount)
				return


func restore_mutation_charges(mutation_id: String, amount: int) -> void:
	if mutation_id.is_empty() or amount <= 0: return
	for i in range(active_mutations.size()):
		if String(active_mutations[i].get("id", "")) != mutation_id: continue
		var effect: Dictionary = active_mutations[i].get("effect", {})
		var cap: int = int(effect.get("charges", 0))
		var cur: int = int(active_mutations[i].get("current_charges", 0))
		var next_charges: int = cur + amount
		if cap > 0: next_charges = mini(next_charges, cap)
		active_mutations[i]["current_charges"] = next_charges
		return


func set_mutation_flag(mutation_id: String, flag: String, value: bool) -> void:
	for i in range(active_mutations.size()):
		if String(active_mutations[i].get("id", "")) == mutation_id:
			active_mutations[i][flag] = value
			return


func add_upgrade(upgrade_id: String) -> void:
	if upgrade_id.is_empty() or taken_upgrades.has(upgrade_id): return
	taken_upgrades.append(upgrade_id)


func has_upgrade(upgrade_id: String) -> bool:
	return taken_upgrades.has(upgrade_id)


func register_growth_choice(choice_id: String) -> void:
	rewards.register_choice(choice_id)


func get_reward_weight_profile() -> Dictionary:
	return rewards.get_weight_profile()


func is_reward_offer_eligible(reward_data: Dictionary) -> bool:
	return rewards.is_reward_offer_eligible(reward_data)


func add_reward_to_ecology(reward_data: Dictionary) -> Dictionary:
	return rewards.add_reward(reward_data)


func add_ritual_consumable(reward_data: Dictionary) -> Dictionary:
	return rewards.add_ritual_consumable(reward_data)


func consume_prepared_ritual() -> Dictionary:
	return rewards.consume_prepared_ritual()


func get_reward_ecology_snapshot() -> Dictionary:
	return rewards.get_snapshot()


func set_reward_slot_primary(lane: String, slot: String, reward_id: String) -> bool:
	return rewards.set_slot_primary(lane, slot, reward_id)


func salvage_reward_from_slot(lane: String, slot: String, reward_id: String) -> bool:
	return rewards.salvage_from_slot(lane, slot, reward_id)


func get_reward_ecology_summary_lines() -> Array[String]:
	return rewards.get_summary_lines()


func get_reward_ecology_slot_alerts() -> Array[String]:
	return rewards.get_slot_alerts()


# --- Beat Logic ---

func set_last_beat_quality(quality: String) -> void:
	last_beat_quality = quality


func is_beat_active() -> bool:
	return run.is_beat_active()


# --- DNA & Roster ---

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
	creatures.add_dna(species_id, amount)


func get_dna(species_id: String) -> float:
	return creatures.get_dna(species_id)


func spend_dna(species_id: String, amount: float) -> void:
	creatures.spend_dna(species_id, amount)


func spend_dna_any(amount: float) -> void:
	creatures.spend_dna_any(amount)


func has_dna_for(species_id: String, threshold: float) -> bool:
	if threshold <= 0.0: return true
	return get_dna(species_id) >= threshold


func unlock_collar(collar_id: String) -> bool:
	if collar_id.is_empty() or collar_inventory.has(collar_id):
		return false
	var collar_data: Dictionary = COLLAR_CONTENT.get_collar(collar_id)
	if collar_data.is_empty():
		return false
	var cost: Dictionary = Dictionary(collar_data.get("dna_unlock_cost", {}))
	for species_id in cost.keys():
		if not has_dna_for(String(species_id), float(cost[species_id])):
			return false
	for species_id in cost.keys():
		spend_dna(String(species_id), float(cost[species_id]))
	collar_inventory.append(collar_id)
	if equipped_collar_id.is_empty():
		equipped_collar_id = collar_id
	EventBus.emit_signal("proc_feedback_requested", "COLLAR UNLOCKED: " + String(collar_data.get("title", collar_id)).to_upper(), Color(0.72, 0.88, 1.0, 1.0))
	return true


func equip_collar(collar_id: String) -> bool:
	if collar_id.is_empty() or not collar_inventory.has(collar_id):
		return false
	if COLLAR_CONTENT.get_collar(collar_id).is_empty():
		return false
	equipped_collar_id = collar_id
	return true


func get_equipped_collar() -> Dictionary:
	if equipped_collar_id.is_empty():
		return {}
	return COLLAR_CONTENT.get_collar(equipped_collar_id)


func get_collar_inventory() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for collar_id in collar_inventory:
		var collar_data: Dictionary = COLLAR_CONTENT.get_collar(collar_id)
		if not collar_data.is_empty():
			rows.append(collar_data)
	return rows


func set_growth_choice_intersection_payload(payload: Dictionary) -> void:
	growth_choice_intersection_payload = payload.duplicate(true)


func clear_growth_choice_intersection_payload() -> void:
	growth_choice_intersection_payload.clear()


# --- Ranch Logic ---

func get_lair_training_cost(species_id: String) -> int:
	for entry in lair_roster:
		if String(entry.get("species_id", "")) == species_id:
			var bond: int = int(entry.get("bond_level", 1))
			return bond * 100
	return 0


func get_lair_release_refund(species_id: String) -> int:
	for entry in lair_roster:
		if String(entry.get("species_id", "")) == species_id:
			var bond: int = int(entry.get("bond_level", 1))
			return (bond - 1) * 50 + 100
	return 0


func train_lair_creature(species_id: String) -> bool:
	var cost: int = get_lair_training_cost(species_id)
	if not has_dna_for(species_id, float(cost)): return false
	for i in range(lair_roster.size()):
		if String(lair_roster[i].get("species_id", "")) == species_id:
			var cur_bond: int = int(lair_roster[i].get("bond_level", 1))
			if cur_bond >= 5: return false
			spend_dna(species_id, float(cost))
			lair_roster[i]["bond_level"] = cur_bond + 1
			return true
	return false


func release_lair_creature(species_id: String) -> void:
	var refund: int = get_lair_release_refund(species_id)
	add_dna(species_id, float(refund))
	for i in range(lair_roster.size()):
		if String(lair_roster[i].get("species_id", "")) == species_id:
			lair_roster.remove_at(i)
			break
	if active_lair_creature_id == species_id:
		active_lair_creature_id = ""


func reset_run_state() -> void:
	player.reset_to_base()
	rewards.reset_run_state()
	creatures.reset_run_state()
	run.reset_run_state()

	var modifier: Dictionary = active_region.get("modifier", {})
	match modifier.get("type", ""):
		"attack_bonus": player_base_damage += float(modifier.get("value", 0.0))
		"max_hp_bonus": player_max_hp += float(modifier.get("value", 0.0))
	player_hp = player_max_hp

	_world_reset_run_trackers()


# --- World Fate Logic ---

func register_world_boss_outcome(outcome_id: String, payload: Dictionary = {}) -> void:
	if outcome_id.is_empty(): return
	_world_pending_boss_events.append({"id": outcome_id, "payload": payload.duplicate(true)})
	EventBus.emit_signal("boss_outcome_resolved", outcome_id, payload.duplicate(true))


func register_tempo_event(family: String, event_id: String, payload: Dictionary = {}) -> void:
	var family_id: String = family.to_lower()
	if family_id != "puncture" and family_id != "void" and family_id != "decree": return
	_world_run_tempo_counts[family_id] = int(_world_run_tempo_counts.get(family_id, 0)) + 1
	if _world_run_tempo_events.size() >= 24: _world_run_tempo_events.pop_front()
	_world_run_tempo_events.append({
		"family": family_id,
		"event_id": event_id,
		"run_number": run_number,
		"payload": payload.duplicate(true)
	})


func get_run_tempo_snapshot() -> Dictionary:
	return world_fate.get_tempo_snapshot()


func resolve_world_fate_for_run(run_result: Dictionary) -> Dictionary:
	var deltas: Dictionary = _build_world_fate_run_deltas(run_result)
	_apply_world_fate_deltas(deltas)
	_resolve_world_fate_dominance()
	world_fate_last_snapshot = _build_world_fate_snapshot(run_result, deltas)
	_world_reset_run_trackers()
	EventBus.emit_signal("world_fate_changed", world_fate_last_snapshot.duplicate(true))
	return world_fate_last_snapshot.duplicate(true)


func get_world_fate_snapshot() -> Dictionary:
	if world_fate_last_snapshot.is_empty():
		return _build_world_fate_snapshot({}, {})
	return world_fate_last_snapshot.duplicate(true)


func get_world_presentation_tags() -> Dictionary:
	return _world_presentation_tags().duplicate(true)


func _build_world_fate_run_deltas(run_result: Dictionary) -> Dictionary:
	var deltas: Dictionary = _world_zeroed_channels()
	var tendency_snapshot: Dictionary = Dictionary(run_result.get("tendency_snapshot", {}))
	var tendency_levels: Dictionary = Dictionary(tendency_snapshot.get("levels", {}))
	var tendency_points: Dictionary = Dictionary(tendency_snapshot.get("points", {}))
	var aggression_signal: float = _world_tendency_signal("aggression", tendency_levels, tendency_points)
	var cadence_signal: float = _world_tendency_signal("cadence", tendency_levels, tendency_points)
	var guard_signal: float = _world_tendency_signal("guard", tendency_levels, tendency_points)
	var bond_signal: float = _world_tendency_signal("bond", tendency_levels, tendency_points)

	deltas["predatory_brutal"] += aggression_signal * 0.11
	deltas["haunted_ritual"] += aggression_signal * 0.03
	deltas["sterile_technocratic"] += cadence_signal * 0.07
	deltas["haunted_ritual"] += cadence_signal * 0.06
	deltas["mythic_hopeful"] += guard_signal * 0.09
	deltas["mythic_hopeful"] += bond_signal * 0.12
	deltas["sterile_technocratic"] += max(cadence_signal - bond_signal, 0.0) * 0.05

	var total_choices: int = maxi(_world_run_bond_events + _world_run_eat_events, 1)
	var bond_eat_bias: float = float(_world_run_bond_events - _world_run_eat_events) / float(total_choices)
	if bond_eat_bias >= 0.0: deltas["mythic_hopeful"] += bond_eat_bias * 0.16
	else: deltas["predatory_brutal"] += -bond_eat_bias * 0.16

	if _world_run_bond_events > 0 and _world_run_eat_events > 0 and absf(bond_eat_bias) <= 0.25:
		deltas["haunted_ritual"] += 0.09
	if _world_run_bond_events > 0 and _world_run_eat_events > 0 and cadence_signal >= 0.45 and absf(bond_eat_bias) <= 0.35:
		deltas["sterile_technocratic"] += 0.08
	if _world_run_eat_events >= 3 and _world_run_bond_events == 0:
		deltas["predatory_brutal"] += 0.07
	if _world_run_bond_events >= 2 and _world_run_eat_events == 0:
		deltas["mythic_hopeful"] += 0.06

	for boss_event in _world_pending_boss_events:
		var outcome_id: String = String(boss_event.get("id", ""))
		var boss_delta: Dictionary = _world_boss_outcome_delta(outcome_id)
		for fate_id in WORLD_FATE_IDS:
			deltas[fate_id] += float(boss_delta.get(fate_id, 0.0))

	if not bool(run_result.get("victory", true)): deltas["haunted_ritual"] += 0.03
	var run_count: int = int(run_result.get("run_number", run_number))
	var run_pressure: float = clampf(float(maxi(run_count - 1, 0)) / 12.0, 0.0, 1.0)
	if world_dominant_fate != "unclaimed" and world_fate_channels.has(world_dominant_fate):
		deltas[world_dominant_fate] += 0.05 * run_pressure
	if run_count <= 2: deltas["mythic_hopeful"] += 0.02
	for fate_id in WORLD_FATE_IDS: deltas[fate_id] = clampf(deltas[fate_id], 0.0, WORLD_FATE_DELTA_CAP_PER_RUN)
	return deltas


func _apply_world_fate_deltas(deltas: Dictionary) -> void:
	for fate_id in WORLD_FATE_IDS:
		var current: float = float(world_fate_channels.get(fate_id, 0.0))
		current = max(current - WORLD_FATE_DECAY_PER_RUN, 0.0)
		current = clampf(current + float(deltas.get(fate_id, 0.0)), 0.0, 1.0)
		world_fate_channels[fate_id] = current


func _resolve_world_fate_dominance() -> void:
	var old_fate: String = world_dominant_fate
	var ranked: Array[Dictionary] = _world_sorted_fates_by_score()
	if ranked.is_empty():
		world_dominant_fate = "unclaimed"
		world_stain_fates = PackedStringArray()
	else:
		var candidate_id: String = String(ranked[0].get("id", ""))
		var candidate_score: float = float(ranked[0].get("score", 0.0))
		if candidate_score < WORLD_FATE_PRIMARY_MIN:
			world_dominant_fate = "unclaimed"
		else:
			if world_dominant_fate == "unclaimed" or not world_fate_channels.has(world_dominant_fate):
				world_dominant_fate = candidate_id
			else:
				var current_score: float = float(world_fate_channels.get(world_dominant_fate, 0.0))
				if candidate_id == world_dominant_fate or candidate_score >= current_score + WORLD_FATE_SWITCH_MARGIN:
					world_dominant_fate = candidate_id
	
	if old_fate != world_dominant_fate:
		EventBus.emit_signal("world_fate_shifted", world_dominant_fate, old_fate)
	
	var next_stains: PackedStringArray = PackedStringArray()
	for row in ranked:
		var fate_id: String = String(row.get("id", ""))
		if fate_id == world_dominant_fate: continue
		if float(row.get("score", 0.0)) < WORLD_FATE_STAIN_THRESHOLD: continue
		next_stains.append(fate_id)
		if next_stains.size() >= 2: break
	world_stain_fates = next_stains


func _world_sorted_fates_by_score() -> Array[Dictionary]:
	var ranked: Array[Dictionary] = []
	for fate_id in WORLD_FATE_IDS:
		ranked.append({"id": fate_id, "score": float(world_fate_channels.get(fate_id, 0.0))})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return ranked


func _world_tendency_signal(tendency_id: String, levels: Dictionary, points: Dictionary) -> float:
	var tendency_level: float = float(levels.get(tendency_id, 0))
	var tendency_points_value: float = float(points.get(tendency_id, 0.0))
	return clampf(tendency_level * 0.18 + tendency_points_value * 0.03, 0.0, 1.0)


func _world_boss_outcome_delta(outcome_id: String) -> Dictionary:
	var delta: Dictionary = _world_zeroed_channels()
	match outcome_id:
		"boss_defeated":
			delta["predatory_brutal"] = 0.05
			delta["mythic_hopeful"] = 0.04
			delta["haunted_ritual"] = 0.02
		"boss_survived_song":
			delta["haunted_ritual"] = 0.12
			delta["predatory_brutal"] = 0.04
		"boss_stabilized": delta["mythic_hopeful"] = 0.15
		"boss_consumed":
			delta["predatory_brutal"] = 0.16
			delta["haunted_ritual"] = 0.05
		"boss_subjugated":
			delta["sterile_technocratic"] = 0.15
			delta["predatory_brutal"] = 0.05
		"boss_released":
			delta["haunted_ritual"] = 0.16
			delta["mythic_hopeful"] = 0.03
	return delta


func _world_zeroed_channels() -> Dictionary:
	return {"predatory_brutal": 0.0, "mythic_hopeful": 0.0, "sterile_technocratic": 0.0, "haunted_ritual": 0.0}


func _build_world_fate_snapshot(run_result: Dictionary, deltas: Dictionary) -> Dictionary:
	return {
		"run_number": int(run_result.get("run_number", run_number)),
		"dominant_fate": world_dominant_fate,
		"stain_fates": Array(world_stain_fates),
		"channels": world_fate_channels.duplicate(true),
		"run_deltas": deltas.duplicate(true),
		"tempo_seed": get_run_tempo_snapshot(),
		"presentation": _world_presentation_tags()
	}


func _world_presentation_tags() -> Dictionary:
	var fate_map: Dictionary = {
		"predatory_brutal": {
			"background_bias": "torn_predation", "route_tone": "carrion_omen", "lair_tone": "trophy_maw",
			"quig_tone": "teeth_law", "boss_mood": "apex_hunger"
		},
		"mythic_hopeful": {
			"background_bias": "relic_awe", "route_tone": "oath_pressure", "lair_tone": "reliquary_den",
			"quig_tone": "vow_witness", "boss_mood": "sacred_duel"
		},
		"sterile_technocratic": {
			"background_bias": "grid_takeover", "route_tone": "audit_forecast", "lair_tone": "lab_annex",
			"quig_tone": "cold_directive", "boss_mood": "compliance_crush"
		},
		"haunted_ritual": {
			"background_bias": "echo_ritual", "route_tone": "debt_whisper", "lair_tone": "seance_attic",
			"quig_tone": "echo_prophecy", "boss_mood": "memory_reckoning"
		},
		"unclaimed": {
			"background_bias": "uneasy_wonder", "route_tone": "uneasy_wonder", "lair_tone": "wild_sanctum",
			"quig_tone": "first_hunger", "boss_mood": "untaken_apex"
		}
	}
	var primary: Dictionary = Dictionary(fate_map.get(world_dominant_fate, fate_map.get("unclaimed", {})))
	return {
		"dominant_fate": world_dominant_fate,
		"stain_fates": Array(world_stain_fates),
		"background_bias": String(primary.get("background_bias", "uneasy_wonder")),
		"route_tone": String(primary.get("route_tone", "uneasy_wonder")),
		"lair_tone": String(primary.get("lair_tone", "wild_sanctum")),
		"quig_tone": String(primary.get("quig_tone", "first_hunger")),
		"boss_mood": String(primary.get("boss_mood", "untaken_apex"))
	}


func _world_reset_run_trackers() -> void:
	world_fate.reset_run_trackers()


func _on_creature_bonded_for_world(_creature_data: Dictionary) -> void:
	_world_run_bond_events += 1


func _on_creature_eaten_for_world(_creature_data: Dictionary) -> void:
	_world_run_eat_events += 1
