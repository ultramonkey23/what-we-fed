extends SceneTree

func _init() -> void:
	# Workaround for standalone script: load EventBus and GameState manually
	var EventBusScript = load("res://autoloads/EventBus.gd")
	var EventBus = EventBusScript.new()
	root.add_child(EventBus)
	
	var GameStateScript = load("res://autoloads/GameState.gd")
	var GameState = GameStateScript.new()
	root.add_child(GameState)
	
	print("[TEST] Starting State Persistence Test")
	
	# Verify Initial State
	if GameState.player_hp != 100.0:
		print("[FAIL] Initial player_hp should be 100.0, got ", GameState.player_hp)
		quit(1)
		return

	# Modify State
	print("[TEST] Modifying state...")
	GameState.player_hp = 50.0
	GameState.add_dna("ashclaw", 15.0)
	GameState.add_bonded_creature({"species_id": "ashclaw", "bond_level": 1})
	
	# Verify Modification
	if GameState.player_hp != 50.0:
		print("[FAIL] player_hp should be 50.0, got ", GameState.player_hp)
		quit(1)
		return
	if GameState.get_dna("ashclaw") != 15.0:
		print("[FAIL] DNA for ashclaw should be 15.0, got ", GameState.get_dna("ashclaw"))
		quit(1)
		return
	if not GameState.is_species_bonded("ashclaw"):
		print("[FAIL] ashclaw should be bonded")
		quit(1)
		return
		
	# Test Run Reset
	print("[TEST] Resetting run state...")
	GameState.reset_run_state()
	
	# Verify Persistence (DNA and Lair should persist, run-roster and HP should reset)
	if GameState.player_hp != 100.0:
		print("[FAIL] player_hp should be reset to 100.0, got ", GameState.player_hp)
		quit(1)
		return
	if GameState.get_dna("ashclaw") != 15.0:
		print("[FAIL] DNA for ashclaw should persist, got ", GameState.get_dna("ashclaw"))
		quit(1)
		return
	if GameState.is_species_ever_bonded("ashclaw") == false:
		print("[FAIL] ashclaw should persist in lair_roster")
		quit(1)
		return
	if GameState.roster.size() != 0:
		# Wait, if ashclaw was bonded, and reset_run_state is called, does it re-seed?
		# reset_run_state seeds from active_lair_creature_id.
		# ashclaw was added to roster but not set as active_lair_creature_id.
		if GameState.roster.size() != 0:
			print("[FAIL] Run roster should be empty after reset, got size ", GameState.roster.size())
			quit(1)
			return

	print("[SUCCESS] State Persistence Test Passed!")
	quit(0)
