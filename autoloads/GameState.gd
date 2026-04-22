extends Node

# Persistent run-level state. This is intentionally small for prototype scope.
# It supports current combat plus the first post-fight reward choice.
const RITUAL_CONTENT = preload("res://data/RitualConsumableContent.gd")
const REWARD_MUTATION_CAP: int = 3
const LOOT_SLOT_LIMITS: Dictionary = {
	"offense": 2,
	"defense": 1,
	"utility": 1
}
const ARTIFACT_SLOT_LIMITS: Dictionary = {
	"major": 1,
	"minor": 1
}

var run_number: int = 1
var run_in_progress: bool = false

const WORLD_FATE_IDS: Array[String] = [
	"predatory_brutal",
	"mythic_hopeful",
	"sterile_technocratic",
	"haunted_ritual"
]
const WORLD_FATE_PRIMARY_MIN: float = 0.12
const WORLD_FATE_SWITCH_MARGIN: float = 0.08
const WORLD_FATE_STAIN_THRESHOLD: float = 0.28
const WORLD_FATE_DELTA_CAP_PER_RUN: float = 0.24
const WORLD_FATE_DECAY_PER_RUN: float = 0.04

var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_base_damage: float = 15.0
var player_defense: float = 0.0

# 9 Ecosystem Stats (Biomass Surge)
var stat_vitality: float = 100.0       # Flesh: Max HP
var stat_power: float = 15.0           # Maw: Base Damage
var stat_carapace: float = 0.0         # Bone: Defense
var stat_endurance: float = 100.0      # Lung: Max Stamina
var stat_swiftness: float = 1.0        # Nerve: Action Recovery Speed Mult (1.0 = normal)
var stat_luck: float = 1.0             # Omen: Reward/Anomaly Rarity Mult
var stat_potential: float = 1.0        # Hollow: EXP/Tendency/DNA Efficiency Mult
var stat_intelligence: float = 1.0     # Eye: Support Charge & Telegraph Read Mult
var stat_adaptability: float = 1.0     # Form: Timed Attack & Combo Armor Mult

var taken_upgrades: Array[String] = []
var is_in_combat: bool = false


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

var reward_loot_slots: Dictionary = {
	"offense": [],
	"defense": [],
	"utility": []
}
var reward_artifact_slots: Dictionary = {
	"major": [],
	"minor": []
}
var reward_consumable_slots: Dictionary = {
	"carry": [],
	"prepared": []
}
var reward_bond_streak: int = 0
var reward_eat_streak: int = 0
var reward_bond_total: int = 0
var reward_eat_total: int = 0

# Each absorbed type is stored as:
# { "type": String, "eat_type": String, "source_species_id": String,
#   "damage_bonus": float }  -- or "heal_applied": float for hp_restore eat types
var absorbed_types: Array[Dictionary] = []

# Mutations gained by eating creatures.
# Each entry is a duplicate of the 'mutation' block from CombatContent.
# Plus a 'current_charges' field to track usage.
var active_mutations: Array[Dictionary] = []

# Global beat quality for the current tick.
var last_beat_quality: String = "off"

# Per-species DNA accumulated during the current run.
# Creature-specific — keys are species_id strings, values are accumulated float amounts.
# Bond/eat now requires spending dna_threshold DNA for the offered creature's species.
# Excess DNA past the threshold persists on the species entry (not removed until spent).
# Will feed metaprogression in a future pass.
var dna_by_species: Dictionary = {}

# Per-species count of how many times it was eaten before its first successful bond.
# This creates species memory/debt that makes future bonding harder.
var predation_debt: Dictionary = {}

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

# Run path plan for regular levels.
# Each entry:
# {
#   "level_index": int,
#   "node_id": String,
#   "is_branch_slot": bool,
#   "branch_candidates": Array[Dictionary]
# }
var run_path_plan: Array[Dictionary] = []
var run_path_chosen_ids: PackedStringArray = PackedStringArray()

# Between-level growth interstitial staging payload.
# Shape (minimal): {
#   "source_flow": String,            # "legacy" | "song"
#   "advance_target": String,         # "route" | "run_spine"
#   "advance_to_boss": bool,
#   "creature": Dictionary,
#   "performance": Dictionary,
#   "fail_safe_pass_allowed": bool
# }
var growth_choice_intersection_payload: Dictionary = {}

# Cross-run world fate state (bounded v1).
var world_fate_channels: Dictionary = {
	"predatory_brutal": 0.0,
	"mythic_hopeful": 0.0,
	"sterile_technocratic": 0.0,
	"haunted_ritual": 0.0
}
var world_dominant_fate: String = "unclaimed"
var world_stain_fates: PackedStringArray = PackedStringArray()
var world_fate_last_snapshot: Dictionary = {}

var _world_run_bond_events: int = 0
var _world_run_eat_events: int = 0
var _world_pending_boss_events: Array[Dictionary] = []
var _world_run_tempo_counts: Dictionary = {
	"puncture": 0,
	"void": 0,
	"decree": 0
}
var _world_run_tempo_events: Array[Dictionary] = []

# Base stat values. reset_run_state() resets player_max_hp and player_base_damage
# to these constants before applying a region modifier, so bonuses never accumulate.
const BASE_MAX_HP: float = 100.0
const BASE_DAMAGE: float = 15.0
const BASE_DEFENSE: float = 0.0
const DEFENSE_DAMAGE_REDUCTION_PER_POINT: float = 0.02
const DEFENSE_DAMAGE_REDUCTION_CAP: float = 0.30
const COMBINED_DAMAGE_REDUCTION_CAP: float = 0.45


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


static func get_bond_level_mult(bond_level: int) -> float:
	# Returns a damage/heal multiplier based on bond level.
	# Level 1 = 1.0x, level 2 = 1.2x, level 3 = 1.4x, level 4 = 1.6x, level 5 = 1.8x.
	return 1.0 + max(0, bond_level - 1) * 0.20


func get_creature_growth_stage(bond_level: int) -> String:
	# Bond 1: Baby, Bond 2-3: Teen, Bond 4-5: Adult
	if bond_level <= 1:
		return "baby"
	elif bond_level <= 3:
		return "teen"
	return "adult"


func get_bond_level_stats_readout(bond_level: int) -> Dictionary:
	# Returns current and next level multipliers for "management-rich" display.
	var current_mult: float = get_bond_level_mult(bond_level)
	var next_mult: float = get_bond_level_mult(min(bond_level + 1, 5))
	return {
		"current_mult": current_mult,
		"next_mult": next_mult,
		"is_max": bond_level >= 5
	}


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
			
			# Post-max (Level 5+) becomes a rare "Exceptional Specimen" chase.
			if current_bond >= 5:
				creature["is_exceptional"] = true
				creature["variant_id"] = "exceptional_alpha"
			else:
				creature["bond_level"] = current_bond + 1
				
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
			
			if creature.get("is_exceptional", false):
				lair_roster[i]["is_exceptional"] = true
				lair_roster[i]["variant_id"] = String(creature.get("variant_id", ""))
			return
	# First time this species reaches the lair — store a clean copy without bond_order.
	var lair_entry: Dictionary = creature.duplicate(true)
	lair_entry.erase("bond_order")
	lair_roster.append(lair_entry)


func is_species_ever_bonded(species_id: String) -> bool:
	for entry in lair_roster:
		if String(entry.get("species_id", "")) == species_id:
			return true
	return false


func get_creature_predation_debt(species_id: String) -> int:
	return int(predation_debt.get(species_id, 0))


func get_effective_dna_threshold(species_id: String) -> float:
	var combat_content = preload("res://data/CombatContent.gd")
	var creature_data: Dictionary = combat_content.get_creature(species_id)
	if creature_data.is_empty():
		return 999.0
		
	var base_threshold: float = float(creature_data.get("dna_threshold", 999.0))
	
	# Predation Debt (Species Memory) increases the threshold before the first successful bond.
	var debt_mult: float = 1.0
	if not is_species_ever_bonded(species_id):
		debt_mult += get_creature_predation_debt(species_id) * 0.5 # +50% cost per eat
		
	# Hollow (Potential) reduces the DNA threshold required for bonding
	return max((base_threshold * debt_mult) / stat_potential, 1.0)


func absorb_creature_type(creature_data: Dictionary) -> Dictionary:
	# Eat reward effect: branches on eat_effect.type.
	var species_id: String = String(creature_data.get("species_id", "unknown"))
	
	# Predation Debt: if not ever bonded, eating it makes future bonding harder.
	if not is_species_ever_bonded(species_id):
		predation_debt[species_id] = get_creature_predation_debt(species_id) + 1

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
	
	# NEW: Identity Absorption - Gain unique run-local mutation
	var mutation: Dictionary = creature_data.get("mutation", {})
	if not mutation.is_empty():
		var active_entry: Dictionary = mutation.duplicate(true)
		var effect: Dictionary = active_entry.get("effect", {})
		active_entry["current_charges"] = int(effect.get("charges", 0))
		active_entry["feedback_fired"] = false
		active_entry["source_species_id"] = String(creature_data.get("species_id", ""))
		active_mutations.append(active_entry)
		if active_mutations.size() > REWARD_MUTATION_CAP:
			active_mutations.pop_front()

	return entry


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
	if mutation_id.is_empty() or amount <= 0:
		return
	for i in range(active_mutations.size()):
		if String(active_mutations[i].get("id", "")) != mutation_id:
			continue
		var effect: Dictionary = active_mutations[i].get("effect", {})
		var cap: int = int(effect.get("charges", 0))
		var cur: int = int(active_mutations[i].get("current_charges", 0))
		var next_charges: int = cur + amount
		if cap > 0:
			next_charges = mini(next_charges, cap)
		active_mutations[i]["current_charges"] = next_charges
		return


func set_mutation_flag(mutation_id: String, flag: String, value: bool) -> void:
	for i in range(active_mutations.size()):
		if String(active_mutations[i].get("id", "")) == mutation_id:
			active_mutations[i][flag] = value
			return


func add_upgrade(upgrade_id: String) -> void:
	if upgrade_id.is_empty() or taken_upgrades.has(upgrade_id):
		return

	taken_upgrades.append(upgrade_id)


func has_upgrade(upgrade_id: String) -> bool:
	return taken_upgrades.has(upgrade_id)


func register_growth_choice(choice_id: String) -> void:
	if choice_id == "bond":
		reward_bond_streak += 1
		reward_eat_streak = 0
		reward_bond_total += 1
	elif choice_id == "eat":
		reward_eat_streak += 1
		reward_bond_streak = 0
		reward_eat_total += 1


func get_reward_weight_profile() -> Dictionary:
	return {
		"bond_streak": reward_bond_streak,
		"eat_streak": reward_eat_streak,
		"bond_total": reward_bond_total,
		"eat_total": reward_eat_total
	}


func is_reward_offer_eligible(reward_data: Dictionary) -> bool:
	var lane: String = String(reward_data.get("lane", ""))
	var reward_id: String = String(reward_data.get("id", ""))
	if lane.is_empty() or reward_id.is_empty():
		return false
	if lane == "loot":
		var slot: String = String(reward_data.get("lane_slot", "utility"))
		if not reward_loot_slots.has(slot):
			slot = "utility"
		var target: Array = reward_loot_slots[slot]
		if target.has(reward_id):
			return true
		return target.size() < int(LOOT_SLOT_LIMITS.get(slot, 1))
	if lane == "artifact":
		var artifact_slot: String = String(reward_data.get("lane_slot", "minor"))
		if not reward_artifact_slots.has(artifact_slot):
			artifact_slot = "minor"
		var artifact_target: Array = reward_artifact_slots[artifact_slot]
		if artifact_target.has(reward_id):
			return true
		return artifact_target.size() < int(ARTIFACT_SLOT_LIMITS.get(artifact_slot, 1))
	if lane == "consumable":
		var prepared: Array = reward_consumable_slots["prepared"]
		var carry: Array = reward_consumable_slots["carry"]
		if prepared.has(reward_id) or carry.has(reward_id):
			return true
		if prepared.size() < RITUAL_CONTENT.PREPARED_LIMIT:
			return true
		return carry.size() < RITUAL_CONTENT.CARRY_LIMIT
	return false


func add_reward_to_ecology(reward_data: Dictionary) -> Dictionary:
	var lane: String = String(reward_data.get("lane", ""))
	var reward_id: String = String(reward_data.get("id", ""))
	if lane.is_empty() or reward_id.is_empty():
		return {"accepted": false, "evicted_id": ""}

	if lane == "loot":
		var slot: String = String(reward_data.get("lane_slot", "utility"))
		if not reward_loot_slots.has(slot):
			slot = "utility"
		var target: Array = reward_loot_slots[slot]
		var result: Dictionary = _insert_with_cap(target, reward_id, int(LOOT_SLOT_LIMITS.get(slot, 1)))
		reward_loot_slots[slot] = target
		return result

	if lane == "artifact":
		var artifact_slot: String = String(reward_data.get("lane_slot", "minor"))
		if not reward_artifact_slots.has(artifact_slot):
			artifact_slot = "minor"
		var artifact_target: Array = reward_artifact_slots[artifact_slot]
		var artifact_result: Dictionary = _insert_with_cap(artifact_target, reward_id, int(ARTIFACT_SLOT_LIMITS.get(artifact_slot, 1)))
		reward_artifact_slots[artifact_slot] = artifact_target
		return artifact_result

	if lane == "consumable":
		return add_ritual_consumable(reward_data)

	return {"accepted": false, "evicted_id": ""}


func add_ritual_consumable(reward_data: Dictionary) -> Dictionary:
	var reward_id: String = String(reward_data.get("id", ""))
	if reward_id.is_empty():
		return {"accepted": false, "evicted_id": ""}

	var prepared: Array = reward_consumable_slots["prepared"]
	var carry: Array = reward_consumable_slots["carry"]
	var evicted_id: String = ""

	if not prepared.has(reward_id) and prepared.is_empty():
		prepared.append(reward_id)
		reward_consumable_slots["prepared"] = prepared
		return {"accepted": true, "evicted_id": evicted_id}

	if carry.has(reward_id):
		return {"accepted": true, "evicted_id": ""}
	if carry.size() >= RITUAL_CONTENT.CARRY_LIMIT:
		return {"accepted": false, "evicted_id": ""}
	carry.append(reward_id)
	reward_consumable_slots["carry"] = carry
	return {"accepted": true, "evicted_id": evicted_id}


func consume_prepared_ritual() -> Dictionary:
	var prepared: Array = reward_consumable_slots["prepared"]
	if prepared.is_empty():
		return {}
	var ritual_id: String = String(prepared.pop_front())
	reward_consumable_slots["prepared"] = prepared
	var carry: Array = reward_consumable_slots["carry"]
	if prepared.is_empty() and not carry.is_empty():
		prepared.append(String(carry.pop_front()))
		reward_consumable_slots["prepared"] = prepared
		reward_consumable_slots["carry"] = carry
	return RITUAL_CONTENT.get_ritual(ritual_id)


func get_reward_ecology_snapshot() -> Dictionary:
	return {
		"loot": reward_loot_slots.duplicate(true),
		"artifact": reward_artifact_slots.duplicate(true),
		"consumable": reward_consumable_slots.duplicate(true),
		"weight_profile": get_reward_weight_profile()
	}


func set_reward_slot_primary(lane: String, slot: String, reward_id: String) -> bool:
	var id: String = reward_id.strip_edges()
	if id.is_empty():
		return false
	match lane:
		"loot":
			if not reward_loot_slots.has(slot):
				return false
			var loot_target: Array = reward_loot_slots[slot]
			var loot_idx: int = loot_target.find(id)
			if loot_idx < 0:
				return false
			if loot_idx > 0:
				loot_target.remove_at(loot_idx)
				loot_target.insert(0, id)
				reward_loot_slots[slot] = loot_target
			return true
		"artifact":
			if not reward_artifact_slots.has(slot):
				return false
			var artifact_target: Array = reward_artifact_slots[slot]
			var artifact_idx: int = artifact_target.find(id)
			if artifact_idx < 0:
				return false
			if artifact_idx > 0:
				artifact_target.remove_at(artifact_idx)
				artifact_target.insert(0, id)
				reward_artifact_slots[slot] = artifact_target
			return true
		"consumable":
			var prepared: Array = reward_consumable_slots["prepared"]
			var carry: Array = reward_consumable_slots["carry"]
			if prepared.has(id):
				return true
			if not carry.has(id):
				return false
			carry.erase(id)
			if prepared.is_empty():
				prepared.insert(0, id)
			else:
				var displaced: String = String(prepared.pop_front())
				prepared.insert(0, id)
				if not displaced.is_empty():
					carry.insert(0, displaced)
			while carry.size() > RITUAL_CONTENT.CARRY_LIMIT:
				carry.pop_back()
			reward_consumable_slots["prepared"] = prepared
			reward_consumable_slots["carry"] = carry
			return true
		_:
			return false


func salvage_reward_from_slot(lane: String, slot: String, reward_id: String) -> bool:
	var id: String = reward_id.strip_edges()
	if id.is_empty():
		return false
	match lane:
		"loot":
			if not reward_loot_slots.has(slot):
				return false
			var loot_target: Array = reward_loot_slots[slot]
			var loot_idx: int = loot_target.find(id)
			if loot_idx < 0:
				return false
			loot_target.remove_at(loot_idx)
			reward_loot_slots[slot] = loot_target
			return true
		"artifact":
			if not reward_artifact_slots.has(slot):
				return false
			var artifact_target: Array = reward_artifact_slots[slot]
			var artifact_idx: int = artifact_target.find(id)
			if artifact_idx < 0:
				return false
			artifact_target.remove_at(artifact_idx)
			reward_artifact_slots[slot] = artifact_target
			return true
		"consumable":
			var prepared: Array = reward_consumable_slots["prepared"]
			var carry: Array = reward_consumable_slots["carry"]
			var changed: bool = false
			if prepared.has(id):
				prepared.erase(id)
				changed = true
				if prepared.is_empty() and not carry.is_empty():
					prepared.append(String(carry.pop_front()))
			elif carry.has(id):
				carry.erase(id)
				changed = true
			if changed:
				reward_consumable_slots["prepared"] = prepared
				reward_consumable_slots["carry"] = carry
			return changed
		_:
			return false


func get_reward_ecology_summary_lines() -> Array[String]:
	var offense: Array = reward_loot_slots["offense"]
	var defense: Array = reward_loot_slots["defense"]
	var utility: Array = reward_loot_slots["utility"]
	var major: Array = reward_artifact_slots["major"]
	var minor: Array = reward_artifact_slots["minor"]
	var prepared: Array = reward_consumable_slots["prepared"]
	var carry: Array = reward_consumable_slots["carry"]
	return [
		"Loot  |  offense %d/%d  defense %d/%d  utility %d/%d" % [
			offense.size(), int(LOOT_SLOT_LIMITS["offense"]),
			defense.size(), int(LOOT_SLOT_LIMITS["defense"]),
			utility.size(), int(LOOT_SLOT_LIMITS["utility"])
		],
		"Artifacts  |  major %d/%d  minor %d/%d" % [
			major.size(), int(ARTIFACT_SLOT_LIMITS["major"]),
			minor.size(), int(ARTIFACT_SLOT_LIMITS["minor"])
		],
		"Rituals  |  prepared %d/%d  carry %d/%d" % [
			prepared.size(), RITUAL_CONTENT.PREPARED_LIMIT,
			carry.size(), RITUAL_CONTENT.CARRY_LIMIT
		],
		"Bond/Eat pressure  |  bond streak %d  eat streak %d" % [reward_bond_streak, reward_eat_streak]
	]


func get_reward_ecology_slot_alerts() -> Array[String]:
	var alerts: Array[String] = []
	var offense: Array = reward_loot_slots["offense"]
	var defense: Array = reward_loot_slots["defense"]
	var utility: Array = reward_loot_slots["utility"]
	var major: Array = reward_artifact_slots["major"]
	var minor: Array = reward_artifact_slots["minor"]
	var prepared: Array = reward_consumable_slots["prepared"]
	var carry: Array = reward_consumable_slots["carry"]

	if offense.size() >= int(LOOT_SLOT_LIMITS["offense"]):
		alerts.append("Loot offense slot sealed")
	if defense.size() >= int(LOOT_SLOT_LIMITS["defense"]):
		alerts.append("Loot defense slot sealed")
	if utility.size() >= int(LOOT_SLOT_LIMITS["utility"]):
		alerts.append("Loot utility slot sealed")
	if major.size() >= int(ARTIFACT_SLOT_LIMITS["major"]):
		alerts.append("Artifact major slot sealed")
	if minor.size() >= int(ARTIFACT_SLOT_LIMITS["minor"]):
		alerts.append("Artifact minor slot sealed")
	if prepared.size() >= RITUAL_CONTENT.PREPARED_LIMIT and carry.size() >= RITUAL_CONTENT.CARRY_LIMIT:
		alerts.append("Ritual slots sealed")
	elif carry.size() >= RITUAL_CONTENT.CARRY_LIMIT:
		alerts.append("Ritual carry slots sealed")

	return alerts


func _insert_with_cap(target: Array, reward_id: String, cap: int) -> Dictionary:
	if target.has(reward_id):
		return {"accepted": true, "evicted_id": ""}
	if target.size() >= max(cap, 1):
		return {"accepted": false, "evicted_id": ""}
	target.append(reward_id)
	return {"accepted": true, "evicted_id": ""}


func set_last_beat_quality(quality: String) -> void:
	last_beat_quality = quality


func is_beat_active() -> bool:
	return last_beat_quality == "perfect" or last_beat_quality == "good"


func get_power_level() -> float:
	# Diegetic Power Level (Scouter Reading)
	# Baseline is roughly 400-500.
	var base: float = 0.0
	base += stat_vitality * 1.2    # 120
	base += stat_power * 8.0       # 120
	base += stat_carapace * 12.0   # 0
	base += stat_endurance * 2.5   # 250
	# Total base ~ 490
	
	# Efficiency stats add massive "Biomass Pressure"
	var mult: float = 1.0
	mult += (stat_swiftness - 1.0) * 5.0
	mult += (stat_luck - 1.0) * 3.0
	mult += (stat_potential - 1.0) * 12.0 # Hollow adds the most potential power
	mult += (stat_intelligence - 1.0) * 6.0
	mult += (stat_adaptability - 1.0) * 8.0
	
	var final_power: float = base * mult
	
	# Add a "digital flicker" noise (±1.5%)
	var flicker: float = 1.0 + (randf() * 0.03 - 0.015)
	return max(final_power * flicker, 0.0)


func heal_player(amount: float) -> float:
	if amount <= 0.0:
		return 0.0

	var mended_amount: float = amount * stat_adaptability
	var before: float = player_hp
	player_hp = min(player_hp + mended_amount, player_max_hp)
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


func set_growth_choice_intersection_payload(payload: Dictionary) -> void:
	growth_choice_intersection_payload = payload.duplicate(true)


func clear_growth_choice_intersection_payload() -> void:
	growth_choice_intersection_payload.clear()


func get_lair_training_cost(species_id: String) -> int:
	for entry in lair_roster:
		if String(entry.get("species_id", "")) == species_id:
			var bond: int = int(entry.get("bond_level", 1))
			return bond * 100 # Increased cost for ranch progression
	return 0


func get_lair_release_refund(species_id: String) -> int:
	for entry in lair_roster:
		if String(entry.get("species_id", "")) == species_id:
			var bond: int = int(entry.get("bond_level", 1))
			return (bond - 1) * 50 + 100
	return 0


func train_lair_creature(species_id: String) -> bool:
	var cost: int = get_lair_training_cost(species_id)
	if not has_dna_for(species_id, float(cost)):
		return false
	
	for i in range(lair_roster.size()):
		if String(lair_roster[i].get("species_id", "")) == species_id:
			var cur_bond: int = int(lair_roster[i].get("bond_level", 1))
			if cur_bond >= 5:
				return false
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
	# Resets per-run state. Base stats are restored from constants before region modifiers
	# are applied, so bonuses never accumulate across repeated runs.
	stat_vitality = BASE_MAX_HP
	stat_power = BASE_DAMAGE
	stat_carapace = BASE_DEFENSE
	stat_endurance = 100.0
	stat_swiftness = 1.0
	stat_luck = 1.0
	stat_potential = 1.0
	stat_intelligence = 1.0
	stat_adaptability = 1.0

	player_max_hp = stat_vitality
	player_base_damage = stat_power
	player_defense = stat_carapace
	var modifier: Dictionary = active_region.get("modifier", {})
	match modifier.get("type", ""):
		"attack_bonus":
			player_base_damage += float(modifier.get("value", 0.0))
		"max_hp_bonus":
			player_max_hp += float(modifier.get("value", 0.0))
	player_hp = player_max_hp
	absorbed_types.clear()
	active_mutations.clear()
	# dna_by_species persists as it is creature-specific currency for metaprogression.
	roster.clear()
	taken_upgrades.clear()
	reward_loot_slots = {
		"offense": [],
		"defense": [],
		"utility": []
	}
	reward_artifact_slots = {
		"major": [],
		"minor": []
	}
	reward_consumable_slots = {
		"carry": [],
		"prepared": []
	}
	reward_bond_streak = 0
	reward_eat_streak = 0
	reward_bond_total = 0
	reward_eat_total = 0
	run_path_plan.clear()
	run_path_chosen_ids.clear()
	growth_choice_intersection_payload.clear()
	_world_reset_run_trackers()
	_bond_order_counter = 0
	# Re-seed the run roster with the player's selected lair creature, if any.
	if not active_lair_creature_id.is_empty():
		for entry in lair_roster:
			if String(entry.get("species_id", "")) == active_lair_creature_id:
				var seed_creature: Dictionary = entry.duplicate(true)
				seed_creature["bond_order"] = _bond_order_counter
				roster.append(seed_creature)
				break


func register_world_boss_outcome(outcome_id: String, payload: Dictionary = {}) -> void:
	if outcome_id.is_empty():
		return
	_world_pending_boss_events.append({
		"id": outcome_id,
		"payload": payload.duplicate(true)
	})
	EventBus.emit_signal("boss_outcome_resolved", outcome_id, payload.duplicate(true))


func register_tempo_event(family: String, event_id: String, payload: Dictionary = {}) -> void:
	var family_id: String = family.to_lower()
	if family_id != "puncture" and family_id != "void" and family_id != "decree":
		return
	_world_run_tempo_counts[family_id] = int(_world_run_tempo_counts.get(family_id, 0)) + 1
	if _world_run_tempo_events.size() >= 24:
		_world_run_tempo_events.pop_front()
	_world_run_tempo_events.append({
		"family": family_id,
		"event_id": event_id,
		"run_number": run_number,
		"payload": payload.duplicate(true)
	})


func get_run_tempo_snapshot() -> Dictionary:
	return {
		"counts": _world_run_tempo_counts.duplicate(true),
		"recent_events": _world_run_tempo_events.duplicate(true)
	}


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

	deltas["predatory_brutal"] = float(deltas["predatory_brutal"]) + aggression_signal * 0.11
	deltas["haunted_ritual"] = float(deltas["haunted_ritual"]) + aggression_signal * 0.03
	deltas["sterile_technocratic"] = float(deltas["sterile_technocratic"]) + cadence_signal * 0.07
	deltas["haunted_ritual"] = float(deltas["haunted_ritual"]) + cadence_signal * 0.06
	deltas["mythic_hopeful"] = float(deltas["mythic_hopeful"]) + guard_signal * 0.09
	deltas["mythic_hopeful"] = float(deltas["mythic_hopeful"]) + bond_signal * 0.12
	deltas["sterile_technocratic"] = float(deltas["sterile_technocratic"]) + max(cadence_signal - bond_signal, 0.0) * 0.05

	var total_choices: int = maxi(_world_run_bond_events + _world_run_eat_events, 1)
	var bond_eat_bias: float = float(_world_run_bond_events - _world_run_eat_events) / float(total_choices)
	if bond_eat_bias >= 0.0:
		deltas["mythic_hopeful"] = float(deltas["mythic_hopeful"]) + bond_eat_bias * 0.16
	else:
		deltas["predatory_brutal"] = float(deltas["predatory_brutal"]) + -bond_eat_bias * 0.16

	if _world_run_bond_events > 0 and _world_run_eat_events > 0 and absf(bond_eat_bias) <= 0.25:
		deltas["haunted_ritual"] = float(deltas["haunted_ritual"]) + 0.09
	if _world_run_bond_events > 0 and _world_run_eat_events > 0 and cadence_signal >= 0.45 and absf(bond_eat_bias) <= 0.35:
		deltas["sterile_technocratic"] = float(deltas["sterile_technocratic"]) + 0.08
	if _world_run_eat_events >= 3 and _world_run_bond_events == 0:
		deltas["predatory_brutal"] = float(deltas["predatory_brutal"]) + 0.07
	if _world_run_bond_events >= 2 and _world_run_eat_events == 0:
		deltas["mythic_hopeful"] = float(deltas["mythic_hopeful"]) + 0.06

	for boss_event in _world_pending_boss_events:
		var outcome_id: String = String(Dictionary(boss_event).get("id", ""))
		var boss_delta: Dictionary = _world_boss_outcome_delta(outcome_id)
		for fate_id in WORLD_FATE_IDS:
			deltas[fate_id] = float(deltas.get(fate_id, 0.0)) + float(boss_delta.get(fate_id, 0.0))

	if not bool(run_result.get("victory", true)):
		deltas["haunted_ritual"] = float(deltas["haunted_ritual"]) + 0.03

	var run_count: int = int(run_result.get("run_number", run_number))
	var run_pressure: float = clampf(float(maxi(run_count - 1, 0)) / 12.0, 0.0, 1.0)
	if world_dominant_fate != "unclaimed" and world_fate_channels.has(world_dominant_fate):
		deltas[world_dominant_fate] = float(deltas[world_dominant_fate]) + 0.05 * run_pressure
	if run_count <= 2:
		deltas["mythic_hopeful"] = float(deltas["mythic_hopeful"]) + 0.02

	for fate_id in WORLD_FATE_IDS:
		deltas[fate_id] = clampf(float(deltas.get(fate_id, 0.0)), 0.0, WORLD_FATE_DELTA_CAP_PER_RUN)
	return deltas


func _apply_world_fate_deltas(deltas: Dictionary) -> void:
	for fate_id in WORLD_FATE_IDS:
		var current: float = float(world_fate_channels.get(fate_id, 0.0))
		current = max(current - WORLD_FATE_DECAY_PER_RUN, 0.0)
		current = clampf(current + float(deltas.get(fate_id, 0.0)), 0.0, 1.0)
		world_fate_channels[fate_id] = current


func _resolve_world_fate_dominance() -> void:
	var ranked: Array[Dictionary] = _world_sorted_fates_by_score()
	if ranked.is_empty():
		world_dominant_fate = "unclaimed"
		world_stain_fates = PackedStringArray()
		return

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

	var next_stains: PackedStringArray = PackedStringArray()
	for row in ranked:
		var fate_id: String = String(row.get("id", ""))
		if fate_id == world_dominant_fate:
			continue
		if float(row.get("score", 0.0)) < WORLD_FATE_STAIN_THRESHOLD:
			continue
		next_stains.append(fate_id)
		if next_stains.size() >= 2:
			break
	world_stain_fates = next_stains


func _world_sorted_fates_by_score() -> Array[Dictionary]:
	var ranked: Array[Dictionary] = []
	for fate_id in WORLD_FATE_IDS:
		ranked.append({
			"id": fate_id,
			"score": float(world_fate_channels.get(fate_id, 0.0))
		})
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
		"boss_stabilized":
			delta["mythic_hopeful"] = 0.15
		"boss_consumed":
			delta["predatory_brutal"] = 0.16
			delta["haunted_ritual"] = 0.05
		"boss_subjugated":
			delta["sterile_technocratic"] = 0.15
			delta["predatory_brutal"] = 0.05
		"boss_released":
			delta["haunted_ritual"] = 0.16
			delta["mythic_hopeful"] = 0.03
		_:
			pass
	return delta


func _world_zeroed_channels() -> Dictionary:
	return {
		"predatory_brutal": 0.0,
		"mythic_hopeful": 0.0,
		"sterile_technocratic": 0.0,
		"haunted_ritual": 0.0
	}


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
			"background_bias": "torn_predation",
			"route_tone": "carrion_omen",
			"lair_tone": "trophy_maw",
			"quig_tone": "teeth_law",
			"boss_mood": "apex_hunger"
		},
		"mythic_hopeful": {
			"background_bias": "relic_awe",
			"route_tone": "oath_pressure",
			"lair_tone": "reliquary_den",
			"quig_tone": "vow_witness",
			"boss_mood": "sacred_duel"
		},
		"sterile_technocratic": {
			"background_bias": "grid_takeover",
			"route_tone": "audit_forecast",
			"lair_tone": "lab_annex",
			"quig_tone": "cold_directive",
			"boss_mood": "compliance_crush"
		},
		"haunted_ritual": {
			"background_bias": "echo_ritual",
			"route_tone": "debt_whisper",
			"lair_tone": "seance_attic",
			"quig_tone": "echo_prophecy",
			"boss_mood": "memory_reckoning"
		},
		"unclaimed": {
			"background_bias": "uneasy_wonder",
			"route_tone": "uneasy_wonder",
			"lair_tone": "wild_sanctum",
			"quig_tone": "first_hunger",
			"boss_mood": "untaken_apex"
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
	_world_run_bond_events = 0
	_world_run_eat_events = 0
	_world_pending_boss_events.clear()
	_world_run_tempo_counts = {
		"puncture": 0,
		"void": 0,
		"decree": 0
	}
	_world_run_tempo_events.clear()


func _on_creature_bonded_for_world(_creature_data: Dictionary) -> void:
	_world_run_bond_events += 1


func _on_creature_eaten_for_world(_creature_data: Dictionary) -> void:
	_world_run_eat_events += 1
