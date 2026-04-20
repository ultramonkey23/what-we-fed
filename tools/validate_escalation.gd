extends SceneTree

# Headless validation for EncounterEscalationDirector logic.
# Run with: godot --headless -s tools/validate_escalation.gd

const DIRECTOR_SCRIPT = preload("res://systems/EncounterEscalationDirector.gd")

func _init():
	print("--- VALIDATING ESCALATION DIRECTOR ---")
	
	var director = DIRECTOR_SCRIPT.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	var phases = [
		{"id": "p1", "start_time": 0.0, "max_active_threats": 2, "enemy_pool": [{"species_id": "ashclaw", "weight": 1.0}]},
		{"id": "p2", "start_time": 10.0, "max_active_threats": 3, "enemy_pool": [{"species_id": "gruvek", "weight": 1.0}]}
	]
	
	director.setup("feeding_hollow", phases, rng)
	
	# Test start
	director.start(0.0)
	if director.get_current_phase_index() != 0:
		_fail("Phase 0 should be active on start")
		
	# Test phase transition
	director.update_song_time(11.0)
	if director.get_current_phase_index() != 1:
		_fail("Phase 1 should be active after 11s")
		
	# Test HP notification
	director.notify_player_hp_changed(0.2)
	if director._player_hp_ratio != 0.2:
		_fail("Player HP ratio not updated")
		
	# Test Boss escalation trigger
	director.notify_boss_hp_changed(0.4)
	if not director._boss_escalation_fired:
		_fail("Boss escalation should have fired at 0.4 HP")

	print("--- ESCALATION DIRECTOR VALIDATION PASSED ---")
	quit(0)

func _fail(msg: String):
	print("FAILED: ", msg)
	quit(1)
