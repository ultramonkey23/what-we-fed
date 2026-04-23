extends Node

func _ready() -> void:
	print("[TEST] Starting Architecture Verification...")
	
	# Test GameState modularization
	print("[TEST] Verifying GameState proxies...")
	GameState.player_hp = 42.0
	if GameState.player.hp != 42.0:
		print("[FAIL] GameState proxy for player_hp failed")
		get_tree().quit(1)
		return
	
	GameState.add_dna("gruvek", 10.0)
	if GameState.creatures.get_dna("gruvek") != 10.0:
		print("[FAIL] GameState proxy for DNA failed")
		get_tree().quit(1)
		return

	# Test RunGrowth modularization
	print("[TEST] Verifying RunGrowth managers...")
	var run_growth = get_node("/root/RunGrowth")
	if not run_growth:
		print("[FAIL] RunGrowth autoload not found")
		get_tree().quit(1)
		return
	
	run_growth.level = 10
	if run_growth.progression.level != 10:
		print("[FAIL] RunGrowth proxy for level failed")
		get_tree().quit(1)
		return

	print("[SUCCESS] Architecture Verification Passed!")
	get_tree().quit(0)
