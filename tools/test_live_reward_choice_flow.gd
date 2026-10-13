extends SceneTree

# Exercises the live CombatScene path rather than calling VictoryRewardDirector
# in isolation: DevHarness boots song mode, CombatScene opens a live offer,
# the actual scene input handler receives E, and the scene restores realtime
# runtime.

const OFFER_SPECIES_ID: String = "gorefane"
const EAT_DNA_GAIN: float = 12.5
const MAX_BOOT_FRAMES: int = 120

var _game_state: Node = null
var _dev_harness: Node = null
var _combat_scene: Node = null
var _failures: Array[String] = []


func _initialize() -> void:
	# CombatScene depends on the registered project autoload graph, so create it
	# only after that graph is live.
	call_deferred(&"_run")


func _run() -> void:
	_game_state = root.get_node_or_null(^"GameState")
	_dev_harness = root.get_node_or_null(^"DevHarness")
	if _game_state == null or _dev_harness == null:
		_failures.append("project GameState/DevHarness autoloads were not registered")
		_finish()
		return

	_game_state.reset_profile_progression_state()
	_dev_harness.clear_request()
	_dev_harness.queue_request({
		"start_mode": "song",
		"support_species_id": "knellspine",
		"support_bond_level": 2,
		"dna_seed": {OFFER_SPECIES_ID: 0.0},
	})

	var combat_scene: PackedScene = load("res://scenes/combat/CombatScene.tscn") as PackedScene
	_assert(combat_scene != null, "CombatScene should load after project autoload initialization")
	if combat_scene == null:
		_finish()
		return
	_combat_scene = combat_scene.instantiate()
	root.add_child(_combat_scene)
	# Match the game transition contract: real unhandled input is routed to the
	# active scene, not an arbitrary sibling attached under the root viewport.
	current_scene = _combat_scene

	var director: Node = await _await_live_reward_director()
	_assert(director != null, "CombatScene should expose its live reward director")
	if director == null:
		_finish()
		return
	# Let the scene's normal song boot settle, then establish one deliberately
	# isolated live offer. This avoids a concurrent performance queue obscuring
	# the decision and continuation being proved here.
	director.reset()
	var combat_data: GDScript = load("res://data/CombatContent.gd") as GDScript
	_assert(combat_data != null, "combat content should load for the live reward offer")
	if combat_data == null:
		_finish()
		return
	_combat_scene.call("_show_live_reward_offer", combat_data.get_creature(OFFER_SPECIES_ID))

	var reward_shell: Control = _get_live_reward_shell()
	_assert(director.is_awaiting_choice(), "CombatScene should open the isolated live reward offer")
	_assert(String(director.get_pending_creature().get("species_id", "")) == OFFER_SPECIES_ID, "isolated live reward should offer the requested species")
	_assert(bool(_combat_scene.get("_song_mode")), "live offer should run inside song mode")
	_assert(bool(_combat_scene.get("_song_reward_pending")), "live offer should mark song reward pending")
	_assert(String(_combat_scene.get("_active_reward_runtime")) == "song_live", "live offer should own the song-live runtime")
	_assert(reward_shell != null and reward_shell.visible, "live offer should make the reward shell visible")
	var translation_overlay: Control = _combat_scene.get("_translation_overlay") as Control
	_assert(translation_overlay == null or not translation_overlay.visible, "live reward should not be preempted by a level-transition overlay")
	_assert(not bool(_combat_scene.call("_is_growth_choice_active")), "live reward should not compete with a growth choice")
	var ui_builder: Object = _combat_scene.get("_ui_builder") as Object
	_assert(ui_builder != null and not bool(ui_builder.get("_reward_choice_made")), "live reward should accept a fresh decision")

	var dna_before: float = _game_state.get_dna(OFFER_SPECIES_ID)
	var resolution: Dictionary = {}
	director.choice_resolved.connect(func(choice_id: String, _creature_data: Dictionary) -> void:
		resolution["choice_id"] = choice_id
	)
	var eat_input := InputEventKey.new()
	eat_input.keycode = KEY_E
	eat_input.pressed = true
	# Route through the engine's normal viewport input dispatch; CombatScene
	# receives it through its production unhandled-input callback.
	root.push_input(eat_input)

	_assert(String(resolution.get("choice_id", "")) == "eat", "E should reach the live reward choice handler as eat")
	_assert(not director.is_awaiting_choice(), "E should resolve the scene's pending live offer")
	var dna_after: float = _game_state.get_dna(OFFER_SPECIES_ID)
	_assert(is_equal_approx(dna_after, dna_before + EAT_DNA_GAIN), "E should award the offered species' eat DNA through GameState (before %.2f, after %.2f)" % [dna_before, dna_after])
	_assert(not bool(_combat_scene.get("_song_reward_pending")), "resolved live offer should clear song reward pending")
	_assert(String(_combat_scene.get("_active_reward_runtime")) == "none", "resolved live offer should release song-live runtime authority")
	_assert(not bool(_combat_scene.call("is_song_paused")), "resolved live offer should leave realtime song transport unpaused")
	_assert(reward_shell != null and not reward_shell.visible, "resolved live offer should hide the transient reward shell")

	var zone_manager: Node = _combat_scene.get("zone_manager") as Node
	_assert(zone_manager != null and zone_manager.is_combat_running(), "resolved live offer should leave the combat fire cycle running")
	_finish()


func _await_live_reward_director() -> Node:
	for _frame in range(MAX_BOOT_FRAMES):
		var director: Node = _combat_scene.get("_victory_reward_director") as Node
		if director != null:
			return director
		await process_frame
	return null


func _get_live_reward_shell() -> Control:
	var ui_builder: Object = _combat_scene.get("_ui_builder") as Object
	if ui_builder == null:
		return null
	return ui_builder.get("_live_reward_shell") as Control


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _dev_harness != null:
		_dev_harness.clear_request()
	if is_instance_valid(_combat_scene):
		if current_scene == _combat_scene:
			current_scene = null
		_combat_scene.queue_free()
	call_deferred(&"_complete_finish")


func _complete_finish() -> void:
	# Let CombatScene dispose its conductor, UI and child directors before the
	# test tree quits, so a passing decision flow has a clean native exit too.
	await process_frame
	await process_frame
	await process_frame
	if _game_state != null:
		_game_state.reset_profile_progression_state()
	if _failures.is_empty():
		print("[PASS] CombatScene live reward E input resolves DNA and resumes song runtime")
		quit(0)
		return
	for failure: String in _failures:
		printerr("[FAIL] " + failure)
	quit(1)
