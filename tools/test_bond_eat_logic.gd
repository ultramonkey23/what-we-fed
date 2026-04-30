extends SceneTree

const COMBAT_DATA = preload("res://data/CombatContent.gd")
const VICTORY_REWARD_DIRECTOR = preload("res://systems/VictoryRewardDirector.gd")

var _bond_events: int = 0
var _eat_events: int = 0
var _deny_events: int = 0
var _event_bus: Node = null
var _game_state: Node = null


func _init() -> void:
	var event_bus_script = load("res://autoloads/EventBus.gd")
	var event_bus = event_bus_script.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)
	_event_bus = event_bus

	var game_state_script = load("res://autoloads/GameState.gd")
	var game_state = game_state_script.new()
	game_state.name = "GameState"
	root.add_child(game_state)
	_game_state = game_state

	_event_bus.creature_bonded.connect(func(_creature_data: Dictionary) -> void: _bond_events += 1)
	_event_bus.creature_eaten.connect(func(_creature_data: Dictionary) -> void: _eat_events += 1)
	_event_bus.dna_lock_denied.connect(func(_species_id: String, _current: float, _required: float) -> void: _deny_events += 1)

	_game_state.reset_profile_progression_state()

	var director = VICTORY_REWARD_DIRECTOR.new()
	root.add_child(director)

	_verify_first_bond_costs_dna(director)
	_verify_archived_bond_is_free_tether(director)
	_verify_locked_first_bond_denies(director)
	_verify_eat_gains_lineage_and_debt(director)

	print("[SUCCESS] Bond/Eat logic contract passed")
	quit(0)


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
	_assert(_game_state.absorbed_types.size() == 1, "eat should record an absorbed type")
	_assert(_eat_events == 1, "eat should emit creature_eaten once")


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[FAIL] " + message)
	quit(1)
