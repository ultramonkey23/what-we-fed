extends Node

# New Systems Demo - Shows how to use the upgraded encounter and mutation systems
# This script demonstrates the practical usage of the new data-driven systems

signal demo_completed(results: Dictionary)

# System references
var combat_integration: Node
var demo_encounter_data: Dictionary = {}
var demo_results: Dictionary = {}

func _ready() -> void:
	# Initialize the combat integration system
	combat_integration = preload("res://examples/demo_encounter_stack/CombatSystemIntegration.gd").new()
	add_child(combat_integration)
	
	# Wait for systems to be ready
	combat_integration.integration_complete.connect(_run_demo)
	
	print("New Systems Demo: Waiting for systems to initialize...")

func _run_demo() -> void:
	print("New Systems Demo: Systems ready, starting demonstration...")
	
	# Demo 1: Generate dynamic encounters
	_demo_encounter_generation()
	
	# Demo 2: Test mutation tracking
	_demo_mutation_tracking()
	
	# Demo 3: Show combat feel constants usage
	_demo_combat_feel_constants()
	
	# Demo 4: Demonstrate integration benefits
	_demo_integration_benefits()
	
	# Complete demo
	_complete_demo()

func _demo_encounter_generation() -> void:
	print("\n=== DEMO 1: Dynamic Encounter Generation ===")
	
	# Generate encounters for different regions and difficulties
	var test_cases: Array[Dictionary] = [
		{"region": "feeding_hollow", "difficulty": "easy", "type": "standard"},
		{"region": "pale_shelf", "difficulty": "medium", "type": "standard"},
		{"region": "drowned_cut", "difficulty": "hard", "type": "elite"},
		{"region": "feeding_hollow", "difficulty": "medium", "type": "boss"}
	]
	
	for i in range(test_cases.size()):
		var test_case: Dictionary = test_cases[i]
		var encounter: Dictionary = combat_integration.generate_encounter(
			test_case["region"],
			test_case["difficulty"],
			test_case["type"]
		)
		
		print("Encounter %d: %s (%s, %s)" % [
			i + 1,
			encounter.get("title", "Unknown"),
			test_case["region"],
			test_case["difficulty"]
		])
		
		# Show encounter structure
		var phases: Array = encounter.get("phases", [])
		print("  Phases: %d" % phases.size())
		for phase_idx in range(phases.size()):
			var enemies: Array = phases[phase_idx]
			print("    Phase %d: %d enemies" % [phase_idx + 1, enemies.size()])
		
		demo_results["encounter_" + str(i)] = encounter

func _demo_mutation_tracking() -> void:
	print("\n=== DEMO 2: Enhanced Mutation Tracking ===")
	
	# Create test creature data with mutations
	var test_creatures: Array[Dictionary] = [
		{
			"species_id": "ashclaw",
			"mutation": {
				"id": "ashclaw_frenzy",
				"display_name": "Ashclaw's Frenzy",
				"summary": "Next 12 timed hits deal +4 damage",
				"effect": {"type": "timed_damage_flat", "value": 4.0, "charges": 12}
			}
		},
		{
			"species_id": "bond_remnant",
			"mutation": {
				"id": "remnant_mend",
				"display_name": "Remnant's Mend",
				"summary": "Next 4 hits taken partially mend themselves",
				"effect": {"type": "heal_on_hit_taken", "value": 6.0, "charges": 4}
			}
		}
	]
	
	# Add mutations to tracker
	for creature in test_creatures:
		combat_integration.add_mutation_from_creature(creature)
		print("Added mutation: %s" % creature["mutation"]["display_name"])
	
	# Simulate mutation usage
	var mutation_tracker = combat_integration.get_mutation_tracker()
	if mutation_tracker:
		# Consume some charges
		print("Simulating mutation usage...")
		combat_integration.consume_mutation_charge("ashclaw_frenzy", 3, "perfect_timing")
		combat_integration.consume_mutation_charge("remnant_mend", 1, "damage_taken")
		
		# Get mutation statistics
		var stats: Dictionary = combat_integration.get_mutation_statistics()
		print("Mutation Statistics:")
		print("  Total mutations: %d" % stats["total_mutations"])
		print("  Active mutations: %d" % stats["active_mutations"])
		print("  Total charges consumed: %d" % stats["total_charges_consumed"])
		print("  Most used mutation: %s" % stats["most_used_mutation"])
		
		# Get UI data for display
		var ui_data: Dictionary = combat_integration.get_mutation_ui_data()
		print("UI Data available for %d mutations" % ui_data.size())
		
		demo_results["mutation_stats"] = stats
		demo_results["mutation_ui_data"] = ui_data

func _demo_combat_feel_constants() -> void:
	print("\n=== DEMO 3: Combat Feel Constants ===")
	
	const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
	
	# Demonstrate getting various combat feel parameters
	var test_params: Array[String] = [
		"perfect_parry", "light_hit", "heavy_damage", "ultimate_activation"
	]
	
	for param in test_params:
		var slow_mo: float = COMBAT_FEEL_CONTENT.get_slow_motion_duration(param)
		var hit_stop: float = COMBAT_FEEL_CONTENT.get_hit_stop_duration(param)
		var camera_shake: Dictionary = COMBAT_FEEL_CONTENT.get_camera_shake_params(param)
		var _screen_flash: Dictionary = COMBAT_FEEL_CONTENT.get_screen_flash_params(param)
		
		print("Combat Feel - %s:" % param)
		print("  Slow Motion: %.2fs" % slow_mo)
		print("  Hit Stop: %.2fs" % hit_stop)
		print("  Camera Shake: intensity=%.1f, duration=%.2fs" % [
			camera_shake.get("intensity", 0.0),
			camera_shake.get("duration", 0.0)
		])
	
	# Demonstrate difficulty scaling
	var base_value: float = 1.0
	print("\nDifficulty Scaling Example (base value: %.1f):" % base_value)
	var difficulties: Array[String] = ["easy", "medium", "hard", "extreme"]
	for diff in difficulties:
		var scaled_damage: float = COMBAT_FEEL_CONTENT.apply_difficulty_scaling(base_value, diff, "damage")
		var scaled_timing: float = COMBAT_FEEL_CONTENT.apply_difficulty_scaling(base_value, diff, "timing")
		print("  %s: damage=%.2f, timing=%.2f" % [diff, scaled_damage, scaled_timing])
	
	demo_results["combat_feel_demo"] = "completed"

func _demo_integration_benefits() -> void:
	print("\n=== DEMO 4: Integration Benefits ===")
	
	# Show how the systems work together
	var integration_status: Dictionary = combat_integration.get_integration_status()
	print("Integration Status:")
	for key in integration_status:
		print("  %s: %s" % [key, integration_status[key]])
	
	# Demonstrate recommended encounter generation
	var recommended: Dictionary = combat_integration.get_recommended_encounter_for_region("feeding_hollow", 0.5)
	print("\nRecommended Encounter (feeding_hollow, 50% progress):")
	print("  Title: %s" % recommended.get("title", "Unknown"))
	print("  Type: %s" % ("Boss" if recommended.get("is_boss", false) else "Standard"))
	
	# Show active synergies if any
	var synergies: Array[Dictionary] = combat_integration.get_active_synergies()
	print("\nActive Synergies: %d" % synergies.size())
	for synergy in synergies:
		print("  %s" % synergy.get("name", "Unknown"))
	
	demo_results["integration_benefits"] = {
		"status": integration_status,
		"recommended_encounter": recommended,
		"synergies": synergies
	}

func _complete_demo() -> void:
	print("\n=== DEMO COMPLETED ===")
	print("All new systems have been demonstrated successfully!")
	print("\nKey Benefits Achieved:")
	print("1. Data-driven encounter generation with variety and scaling")
	print("2. Enhanced mutation tracking with UI feedback and synergies")
	print("3. Centralized combat feel constants for consistent experience")
	print("4. Clean integration layer preserving existing functionality")
	print("5. Easy content addition without code changes")
	
	demo_results["demo_completed"] = true
	demo_results["timestamp"] = Time.get_unix_time_from_system()
	
	demo_completed.emit(demo_results)

# Utility function for testing in isolation
func run_quick_test() -> void:
	print("Running quick test of new systems...")
	
	# Test encounter generation
	var encounter: Dictionary = combat_integration.generate_encounter("feeding_hollow", "medium")
	print("Generated encounter: %s" % encounter.get("title", "Unknown"))
	
	# Test mutation addition
	var test_mutation: Dictionary = {
		"species_id": "test_creature",
		"mutation": {
			"id": "test_mutation",
			"display_name": "Test Mutation",
			"summary": "Test mutation for demo",
			"effect": {"type": "test_effect", "value": 1.0, "charges": 5}
		}
	}
	combat_integration.add_mutation_from_creature(test_mutation)
	print("Added test mutation")
	
	# Test combat feel constants
	const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
	var shake_params: Dictionary = COMBAT_FEEL_CONTENT.get_camera_shake_params("perfect_parry")
	print("Camera shake params: intensity=%.1f, duration=%.2f" % [
		shake_params.get("intensity", 0.0),
		shake_params.get("duration", 0.0)
	])
	
	print("Quick test completed successfully!")
