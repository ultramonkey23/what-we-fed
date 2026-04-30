extends Node

# VictoryRewardDirector - Manages the orchestration of creature rewards (Bond vs Eat)
# Extracted from CombatScene.gd to adhere to the "Combat-Clean, Management-Rich" mandate.

const COMBAT_DATA = preload("res://data/CombatContent.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")

const EAT_DNA_GAIN: float = 12.5

signal offer_started(creature_data: Dictionary, is_live: bool, is_dna_locked: bool, timer: float)
signal offer_ended()
signal choice_resolved(choice_id: String, creature_data: Dictionary)
signal queue_updated(size: int)

var _pending_creature: Dictionary = {}
var _reward_queue: Array[Dictionary] = []
var _is_awaiting_choice: bool = false
var _choice_made: bool = false
var _is_dna_locked: bool = false
var _offer_timer: float = 0.0
var _is_live_offer: bool = false

func offer_creature(creature_data: Dictionary, is_live: bool, timer: float = 0.0) -> void:
	if _is_awaiting_choice and not _choice_made:
		var queue_entry: Dictionary = creature_data.duplicate(true)
		queue_entry["_is_live"] = is_live
		queue_entry["_timer"] = timer
		_reward_queue.append(queue_entry)
		emit_signal("queue_updated", _reward_queue.size())
		return

	_pending_creature = creature_data.duplicate(true)
	var species_id: String = String(_pending_creature.get("species_id", ""))
	var bond_cost: float = _get_bond_cost(species_id)
	_is_dna_locked = bond_cost > 0.0 and not GameState.has_dna_for(species_id, bond_cost)
	
	_is_awaiting_choice = true
	_choice_made = false
	_is_live_offer = is_live
	_offer_timer = timer

	emit_signal("offer_started", _pending_creature, _is_live_offer, _is_dna_locked, _offer_timer)

func process_tick(delta: float) -> void:
	if not _is_awaiting_choice or _choice_made or _offer_timer <= 0.0:
		return
		
	_offer_timer = max(_offer_timer - delta, 0.0)
	if _offer_timer <= 0.0:
		expire_offer()

func resolve_choice(choice_id: String) -> bool:
	if not _is_awaiting_choice or _choice_made:
		return false
	
	if choice_id == "pass":
		return _apply_pass()
		
	if choice_id != "bond" and choice_id != "eat":
		return false

	var species_id: String = String(_pending_creature.get("species_id", ""))
	
	if choice_id == "bond":
		var bond_cost: float = _get_bond_cost(species_id)
		if bond_cost > 0.0 and not GameState.has_dna_for(species_id, bond_cost):
			EventBus.emit_signal("dna_lock_denied", species_id, GameState.get_dna(species_id), bond_cost)
			return false

	_choice_made = true
	_is_awaiting_choice = false
	
	if choice_id == "bond":
		var bond_cost: float = _get_bond_cost(species_id)
		var updated_creature: Dictionary = GameState.add_bonded_creature(_pending_creature)
		if GameState.has_method("register_growth_choice"):
			GameState.register_growth_choice("bond")
		if bond_cost > 0.0:
			GameState.spend_dna(species_id, bond_cost)
		EventBus.emit_signal("creature_bonded", updated_creature)
	else:
		var _absorbed: Dictionary = GameState.absorb_creature_type(_pending_creature)
		if GameState.has_method("register_growth_choice"):
			GameState.register_growth_choice("eat")
		
		# Predatory Gain: Award lineage DNA for consumption.
		# A Hunt Offer 'Eat' is a significant predation event (5x standard kill).
		GameState.add_dna(species_id, EAT_DNA_GAIN)
		
		EventBus.emit_signal("creature_eaten", _pending_creature)

	emit_signal("choice_resolved", choice_id, _pending_creature)
	_check_next_offer()
	return true

func expire_offer() -> void:
	if not _is_awaiting_choice or _choice_made:
		return
	
	_choice_made = true
	_is_awaiting_choice = false
	emit_signal("offer_ended")
	_check_next_offer()

func _apply_pass() -> bool:
	_choice_made = true
	_is_awaiting_choice = false
	emit_signal("choice_resolved", "pass", _pending_creature)
	_check_next_offer()
	return true

func _check_next_offer() -> void:
	if _reward_queue.is_empty():
		_pending_creature = {}
		return
		
	var next: Dictionary = _reward_queue.pop_front()
	emit_signal("queue_updated", _reward_queue.size())
	
	var is_live: bool = bool(next.get("_is_live", false))
	var timer: float = float(next.get("_timer", 0.0))
	
	# Clean up internal keys before offering
	next.erase("_is_live")
	next.erase("_timer")
	
	offer_creature(next, is_live, timer)

func get_pending_creature() -> Dictionary:
	return _pending_creature.duplicate(true)

func is_awaiting_choice() -> bool:
	return _is_awaiting_choice and not _choice_made

func is_dna_locked() -> bool:
	if not _pending_creature.is_empty():
		var species_id: String = String(_pending_creature.get("species_id", ""))
		var bond_cost: float = _get_bond_cost(species_id)
		_is_dna_locked = bond_cost > 0.0 and not GameState.has_dna_for(species_id, bond_cost)
	return _is_dna_locked

func get_offer_timer() -> float:
	return _offer_timer


func reset() -> void:
	_pending_creature = {}
	_reward_queue.clear()
	_is_awaiting_choice = false
	_choice_made = false
	_is_dna_locked = false
	_offer_timer = 0.0
	_is_live_offer = false
	emit_signal("queue_updated", 0)


func _get_bond_cost(species_id: String) -> float:
	if species_id.is_empty():
		return 999.0
	if GameState.is_species_ever_bonded(species_id):
		return 0.0
	return GameState.get_effective_dna_threshold(species_id)
