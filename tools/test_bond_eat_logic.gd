extends SceneTree

const COMBAT_DATA = preload("res://data/CombatContent.gd")

var _bond_events: int = 0
var _eat_events: int = 0
var _deny_events: int = 0
var _event_bus: Node = null
var _game_state: Node = null
var _failures: Array[String] = []


func _initialize() -> void:
	# GameState and VictoryRewardDirector use registered autoload identifiers.
	# Load the production director after project autoload initialization instead of
	# creating a second, incomplete autoload graph inside this probe.
	call_deferred(&"_run")


func _run() -> void:
	_event_bus = root.get_node_or_null(^"EventBus")
	_game_state = root.get_node_or_null(^"GameState")
	if _event_bus == null or _game_state == null:
		_failures.append("project EventBus/GameState autoloads were not registered")
		_finish()
		return
	var director_script: GDScript = load("res://systems/VictoryRewardDirector.gd")
	if director_script == null or not director_script.can_instantiate():
		_failures.append("VictoryRewardDirector failed to load after autoload initialization")
		_finish()
		return

	_event_bus.creature_bonded.connect(func(_creature_data: Dictionary) -> void: _bond_events += 1)
	_event_bus.creature_eaten.connect(func(_creature_data: Dictionary) -> void: _eat_events += 1)
	_event_bus.dna_lock_denied.connect(func(_species_id: String, _current: float, _required: float) -> void: _deny_events += 1)

	_game_state.reset_profile_progression_state()

	var director: Node = director_script.new()
	root.add_child(director)

	_verify_first_bond_costs_dna(director)
	_verify_archived_bond_is_free_tether(director)
	_verify_locked_first_bond_denies(director)
	_verify_eat_gains_lineage_and_debt(director)

	director.free()
	_finish()


func _verify_first_bond_costs_dna(director: Node) -> void:
	var creature: Dictionary = COMBAT_DATA.get_creature("ashclaw")
	_game_state.add_dna("ashclaw", 8.0)

	director.offer_creature(creature, false)
	_assert(not director.is_dna_locked(), "first bond should open when exact species DNA is available")
	_assert(director.resolve_choice("bond"), "first bond should resolve")
	_assert(is_equal_approx(_game_state.get_dna("ashclaw"), 0.0), "first bond should spend the species DNA threshold")
	_assert(_game_state.is_species_ever_bonded("ashclaw"), "first bond should enter the archive")
	_assert(_bond_events == 1, "first bond should emit creature_bonded once")


func _verify_archived_bond_is_free_tether(director: Node) -> void:
	var creature: Dictionary = COMBAT_DATA.get_creature("ashclaw")

	director.offer_creature(creature, false)
	_assert(not director.is_dna_locked(), "archived species should not be DNA locked in combat")
	_assert(director.resolve_choice("bond"), "archived species should re-tether")
	_assert(is_equal_approx(_game_state.get_dna("ashclaw"), 0.0), "archived re-tether should not spend DNA")
	_assert(_bond_events == 2, "archived re-tether should still emit creature_bonded")


func _verify_locked_first_bond_denies(director: Node) -> void:
	var creature: Dictionary = COMBAT_DATA.get_creature("knellspine")

	director.offer_creature(creature, false)
	_assert(director.is_dna_locked(), "new species with no DNA should be bond locked")
	_assert(not director.resolve_choice("bond"), "locked first bond should not resolve")
	_assert(_deny_events == 1, "locked first bond should emit dna_lock_denied")
	_assert(not _game_state.is_species_ever_bonded("knellspine"), "locked first bond should not enter archive")
	director.resolve_choice("pass")


func _verify_eat_gains_lineage_and_debt(director: Node) -> void:
	var creature: Dictionary = COMBAT_DATA.get_creature("hushcoil")

	director.offer_creature(creature, false)
	_assert(director.resolve_choice("eat"), "eat should resolve without DNA")
	_assert(is_equal_approx(_game_state.get_dna("hushcoil"), 12.5), "eat should grant lineage DNA")
	_assert(_game_state.get_creature_predation_debt("hushcoil") == 1, "eating an unbonded species should add predation debt")
	var extracted_mutations: Array[Dictionary] = _game_state.get_active_mutations_of_type("pale_on_parry")
	_assert(extracted_mutations.size() == 1, "eat should register Hushcoil's mutation in the active combat state")
	_assert(_eat_events == 1, "eat should emit creature_eaten once")


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)


func _finish() -> void:
	if _game_state != null:
		_game_state.reset_profile_progression_state()
	if _failures.is_empty():
		print("[PASS] production Bond/Eat contract (first bond, re-tether, lock, eat)")
		quit(0)
		return
	for failure: String in _failures:
		printerr("[FAIL] " + failure)
	quit(1)
