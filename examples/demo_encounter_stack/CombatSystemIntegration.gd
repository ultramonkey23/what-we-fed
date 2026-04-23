extends Node

# Demo-only: not used by CombatScene, CombatRunDirector, or autoloads. Entry: examples/NewSystemsDemo.gd.
# Combat System Integration - Connects new systems with existing CombatScene
# Provides a clean interface for using the new encounter generation and mutation tracking systems

signal encounter_generated(encounter_data: Dictionary)
signal mutation_system_ready(tracker: Node)
signal integration_complete()

# System references
var encounter_generator: Node
var mutation_tracker: Node
var combat_scene: Node

# Integration state
var is_initialized: bool = false
var use_dynamic_encounters: bool = true
var use_enhanced_mutations: bool = true

func _ready() -> void:
	# Initialize systems when ready
	call_deferred("_initialize_systems")

func _initialize_systems() -> void:
	# Create and initialize the encounter generator
	encounter_generator = preload("res://examples/demo_encounter_stack/EncounterGenerator.gd").new()
	add_child(encounter_generator)
	encounter_generator.encounter_generated.connect(_on_encounter_generated)
	
	# Create and initialize the mutation tracker
	mutation_tracker = preload("res://examples/demo_encounter_stack/MutationTracker.gd").new()
	add_child(mutation_tracker)
	mutation_tracker.mutation_activated.connect(_on_mutation_activated)
	mutation_tracker.mutation_charge_consumed.connect(_on_mutation_charge_consumed)
	mutation_tracker.mutation_depleted.connect(_on_mutation_depleted)
	mutation_tracker.mutation_synergy_detected.connect(_on_mutation_synergy_detected)
	mutation_tracker.mutation_feedback_requested.connect(_on_mutation_feedback_requested)
	
	# Connect to EventBus for combat events
	_connect_to_event_bus()
	
	is_initialized = true
	integration_complete.emit()
	mutation_system_ready.emit(mutation_tracker)

func _connect_to_event_bus() -> void:
	# Connect to relevant combat events
	if not EventBus.combat_started.is_connected(_on_combat_started):
		EventBus.combat_started.connect(_on_combat_started)
	if not EventBus.combat_ended.is_connected(_on_combat_ended):
		EventBus.combat_ended.connect(_on_combat_ended)
	if not EventBus.creature_eaten.is_connected(_on_creature_eaten):
		EventBus.creature_eaten.connect(_on_creature_eaten)

func generate_encounter(region: String, difficulty: String = "medium", encounter_type: String = "standard", custom_params: Dictionary = {}) -> Dictionary:
	if not is_initialized:
		push_error("CombatSystemIntegration not initialized")
		return {}
	
	# Set generation parameters
	var run_progress: float = 0.0  # Default progress if GameState doesn't have it
	if GameState.has_method("get_run_progress"):
		run_progress = GameState.get_run_progress()
	encounter_generator.set_generation_params(region, difficulty, run_progress)
	
	# Generate encounter
	var encounter_data: Dictionary = encounter_generator.generate_encounter(encounter_type, custom_params)
	
	return encounter_data

func generate_boss_encounter(region: String, difficulty: String = "medium", custom_params: Dictionary = {}) -> Dictionary:
	return generate_encounter(region, difficulty, "boss", custom_params)

func generate_elite_encounter(region: String, difficulty: String = "medium", custom_params: Dictionary = {}) -> Dictionary:
	return generate_encounter(region, difficulty, "elite", custom_params)

func add_mutation_from_creature(creature_data: Dictionary) -> void:
	if not is_initialized or not use_enhanced_mutations:
		return
	
	var mutation_data: Dictionary = creature_data.get("mutation", {})
	if not mutation_data.is_empty():
		# Add source information
		mutation_data["source_species"] = creature_data.get("species_id", "unknown")
		mutation_tracker.add_mutation(mutation_data)

func consume_mutation_charge(mutation_id: String, amount: int = 1, context: String = "") -> bool:
	if not is_initialized or not use_enhanced_mutations:
		return false
	
	return mutation_tracker.consume_mutation_charge(mutation_id, amount, context)

func get_mutation_ui_data() -> Dictionary:
	if not is_initialized or not use_enhanced_mutations:
		return {}
	
	return mutation_tracker.get_all_mutation_ui_data()

func get_mutation_statistics() -> Dictionary:
	if not is_initialized or not use_enhanced_mutations:
		return {}
	
	return mutation_tracker.get_mutation_statistics()

func get_active_synergies() -> Array[Dictionary]:
	if not is_initialized or not use_enhanced_mutations:
		return []
	
	return mutation_tracker.get_active_synergies()

# Event handlers
func _on_encounter_generated(encounter_data: Dictionary) -> void:
	encounter_generated.emit(encounter_data)

func _on_mutation_activated(_mutation_data: Dictionary) -> void:
	# Forward mutation activation to existing systems if needed
	pass

func _on_mutation_charge_consumed(_mutation_id: String, _charges_remaining: int) -> void:
	# Update UI or other systems that track mutation charges
	pass

func _on_mutation_depleted(_mutation_id: String) -> void:
	# Handle mutation depletion (remove from UI, etc.)
	pass

func _on_mutation_synergy_detected(_synergy_data: Dictionary) -> void:
	# Handle synergy activation (special effects, UI updates, etc.)
	pass

func _on_mutation_feedback_requested(text: String, color: Color) -> void:
	# Forward mutation feedback to the presentation system
	EventBus.proc_feedback_requested.emit(text, color)

func _on_combat_started(_enemy_data: Array) -> void:
	# Reset mutation tracker for new combat
	if use_enhanced_mutations and mutation_tracker:
		mutation_tracker.reset_mutations()

func _on_combat_ended(_victory: bool) -> void:
	# Handle combat end cleanup if needed
	pass

func _on_creature_eaten(creature_data: Dictionary) -> void:
	# Add mutations from eaten creatures
	add_mutation_from_creature(creature_data)

# Configuration methods
func set_dynamic_encounters_enabled(enabled: bool) -> void:
	use_dynamic_encounters = enabled

func set_enhanced_mutations_enabled(enabled: bool) -> void:
	use_enhanced_mutations = enabled

func set_encounter_generator_params(region: String, difficulty: String, progress: float) -> void:
	if encounter_generator:
		encounter_generator.set_generation_params(region, difficulty, progress)

# Utility methods
func get_encounter_generator() -> Node:
	return encounter_generator

func get_mutation_tracker() -> Node:
	return mutation_tracker

func is_system_ready() -> bool:
	return is_initialized

func get_integration_status() -> Dictionary:
	return {
		"initialized": is_initialized,
		"dynamic_encounters_enabled": use_dynamic_encounters,
		"enhanced_mutations_enabled": use_enhanced_mutations,
		"encounter_generator_available": encounter_generator != null,
		"mutation_tracker_available": mutation_tracker != null
	}

# Migration helpers for existing code
func migrate_existing_encounter(old_encounter_data: Dictionary) -> Dictionary:
	# Convert old encounter format to new format if needed
	# This helps with gradual migration
	return old_encounter_data.duplicate(true)

func get_recommended_encounter_for_region(region: String, run_progress: float) -> Dictionary:
	var difficulty: String = "medium"
	
	# Adjust difficulty based on run progress
	if run_progress < 0.3:
		difficulty = "easy"
	elif run_progress > 0.7:
		difficulty = "hard"
	
	# Determine encounter type
	var encounter_type: String = "standard"
	if run_progress > 0.8:
		encounter_type = "boss"
	elif run_progress > 0.6:
		encounter_type = "elite"
	
	return generate_encounter(region, difficulty, encounter_type)
