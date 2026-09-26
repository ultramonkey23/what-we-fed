extends SceneTree

var _failures: Array[String] = []
var _feedback: Array[String] = []
var _bus: Node
var _state: Node
var _director_script: GDScript
var _content_script: GDScript
var _completed_cases: int = 0
var _checks: int = 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_bus = root.get_node("EventBus")
	_state = root.get_node("GameState")
	_director_script = load("res://systems/PerformanceRewardDirector.gd")
	_content_script = load("res://data/PerformanceRewardContent.gd")
	if _director_script == null or not _director_script.can_instantiate() or _content_script == null or not _content_script.can_instantiate():
		printerr("[FAIL] production scripts could not load after autoload initialization")
		quit(1)
		return
	_verify_sequence(false)
	_verify_sequence(true)
	if _completed_cases != 2 or _checks != 18:
		_failures.append("probe incomplete: cases=%d/2 checks=%d/18" % [_completed_cases, _checks])
	if _failures.is_empty():
		print("[PASS] production EventBus perfect attack sequence (with and without Veilstrike Chain)")
		quit(0)
	else:
		for failure: String in _failures:
			printerr("[FAIL] " + failure)
		quit(1)


func _verify_sequence(with_chain: bool) -> void:
	var rewards: Node = _state.get("rewards")
	rewards.reset_run_state()
	var director: Node = _director_script.new()
	root.add_child(director)
	director.bind_runtime(null)
	director.start_song_run([])
	director.enter_song_phase(0, {})
	if with_chain:
		var accepted: Dictionary = _state.add_reward_to_ecology(_content_script.get_reward("veilstrike_chain"))
		_check(bool(accepted.get("accepted", false)), "Veilstrike Chain must equip through live reward ecology")
		director.sync_from_reward_state()
		_check(not director.get_runtime_effect("perfect_strike_chain").is_empty(), "equipped artifact must reach director")
	_feedback.clear()
	director.proc_feedback.connect(_on_feedback)
	_emit_attack("perfect")
	_emit_attack("perfect")
	var momentum_before_good: float = float(director.get_pressure_bias_snapshot().get("momentum", 0.0))
	_emit_attack("good")
	_check(float(director.get_pressure_bias_snapshot().get("momentum", 0.0)) > momentum_before_good, "good timing must still earn hunt momentum")
	_emit_attack("perfect")
	_check(is_zero_approx(float(director.get_status_snapshot().get("bonus_progress", -1.0))), "interrupted perfect sequence must not earn bonus; chain=%s" % with_chain)
	_check(not _feedback.has("PERFECT FEEDS"), "interrupted perfect sequence must not announce payoff")
	_check(not _feedback.has("CHAIN FIRES"), "interrupted perfect sequence must not fire artifact")
	_emit_attack("perfect")
	_emit_attack("perfect")
	_check(is_equal_approx(float(director.get_status_snapshot().get("bonus_progress", 0.0)), 10.0), "three subsequent perfect attacks must earn bonus; chain=%s" % with_chain)
	_check(_feedback.count("PERFECT FEEDS") == 1, "three subsequent perfect attacks must announce exactly one payoff")
	_check(_feedback.count("CHAIN FIRES") == (1 if with_chain else 0), "artifact fires exactly once only when equipped")
	# Off timing must also break the next sequence, preserving existing behavior.
	_emit_attack("perfect")
	_emit_attack("off")
	_emit_attack("perfect")
	_emit_attack("perfect")
	_check(is_equal_approx(float(director.get_status_snapshot().get("bonus_progress", 0.0)), 10.0), "off timing must break perfect sequence")
	director.free()
	rewards.reset_run_state()
	_completed_cases += 1


func _emit_attack(quality: String) -> void:
	_bus.emit_signal(&"timed_attack_resolved", 0, quality, 1.0, -1)


func _on_feedback(text: String, _color: Color) -> void:
	_feedback.append(text)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
