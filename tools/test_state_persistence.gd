extends SceneTree

# This probe exercises the registered state autoloads. Loading it through
# `-s` happens before those identifiers can be compiled into this script, so
# production state owners are resolved from the initialized scene tree.

var _game_state: Node = null
var _player_state: Node = null
var _creature_state: Node = null
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_game_state = root.get_node_or_null(^"GameState")
	_player_state = root.get_node_or_null(^"PlayerState")
	_creature_state = root.get_node_or_null(^"CreatureState")
	if _game_state == null or _player_state == null or _creature_state == null:
		_failures.append("GameState, PlayerState, and CreatureState autoloads must be registered")
		_finish()
		return

	# Begin from an explicit, repo-local baseline so another headless probe
	# cannot decide this test's result through persisted state.
	_game_state.reset_profile_progression_state()
	_assert(is_equal_approx(float(_player_state.get("hp")), 100.0), "initial player HP should be 100")

	_player_state.set("hp", 50.0)
	_game_state.add_dna("ashclaw", 15.0)
	_game_state.add_bonded_creature({"species_id": "ashclaw", "bond_level": 1})

	_assert(is_equal_approx(float(_player_state.get("hp")), 50.0), "player HP should retain in-run mutation before reset")
	_assert(is_equal_approx(_game_state.get_dna("ashclaw"), 15.0), "DNA should be stored before reset")
	_assert(_game_state.is_species_bonded("ashclaw"), "ashclaw should be bonded before reset")

	_game_state.reset_run_state()

	# Run reset restores vessel state and re-seeds the selected lair support.
	_assert(is_equal_approx(float(_player_state.get("hp")), 100.0), "run reset should restore player HP")
	_assert(is_equal_approx(_game_state.get_dna("ashclaw"), 15.0), "DNA should persist across run reset")
	_assert(_game_state.is_species_ever_bonded("ashclaw"), "lair bond should persist across run reset")
	var run_roster: Array = _creature_state.get("roster")
	_assert(run_roster.size() == 1, "run reset should seed the active lair creature into the run roster")
	if run_roster.size() == 1:
		_assert(String(Dictionary(run_roster[0]).get("species_id", "")) == "ashclaw", "run reset should seed the selected ashclaw")

	_finish()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _game_state != null:
		_game_state.reset_profile_progression_state()
	if _failures.is_empty():
		print("[PASS] production state persistence contract")
		quit(0)
		return
	for failure: String in _failures:
		printerr("[FAIL] " + failure)
	quit(1)
