extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	var bus: Node = root.get_node("EventBus")
	var meter_script: GDScript = load("res://systems/CombatMeter.gd")
	var meter: Node = meter_script.new()
	root.add_child(meter)

	var combo_broken_emissions: Array = []
	var ultimate_fired_emissions: Array = []

	bus.combo_broken.connect(func(lost_count: int) -> void:
		combo_broken_emissions.append(lost_count)
	)
	bus.ultimate_fired.connect(func(power: float) -> void:
		ultimate_fired_emissions.append(power)
	)

	# (a) consume_ultimate() at combo >= 20
	meter.combo_count = 20
	combo_broken_emissions.clear()
	ultimate_fired_emissions.clear()
	var power: float = meter.consume_ultimate()
	if power == 0.0:
		_failures.append("test (a): consume_ultimate() returned 0.0 at combo 20")
	if meter.combo_count != 0:
		_failures.append("test (a): combo_count is %d after consume_ultimate(), expected 0" % meter.combo_count)
	if ultimate_fired_emissions.is_empty():
		_failures.append("test (a): ultimate_fired not emitted")
	if not combo_broken_emissions.is_empty():
		_failures.append("test (a): combo_broken emitted with count %d when it should not" % combo_broken_emissions[0])

	# (b) reset() with combo > 0
	meter.combo_count = 10
	combo_broken_emissions.clear()
	meter.reset()
	if meter.combo_count != 0:
		_failures.append("test (b): combo_count is %d after reset(), expected 0" % meter.combo_count)
	if not combo_broken_emissions.is_empty():
		_failures.append("test (b): combo_broken emitted with count %d when it should not" % combo_broken_emissions[0])

	# (c) record_bad_timing() with combo > 0
	meter.combo_count = 15
	combo_broken_emissions.clear()
	meter.record_bad_timing()
	if meter.combo_count != 0:
		_failures.append("test (c): combo_count is %d after record_bad_timing(), expected 0" % meter.combo_count)
	if combo_broken_emissions.is_empty():
		_failures.append("test (c): combo_broken not emitted by record_bad_timing()")
	elif combo_broken_emissions[0] != 15:
		_failures.append("test (c): combo_broken emitted with count %d, expected 15" % combo_broken_emissions[0])

	meter.free()
	if _failures.is_empty():
		print("[PASS] combat meter resets are not breaks (3 cases)")
		quit(0)
	else:
		for f in _failures:
			printerr("[FAIL] " + f)
		quit(1)
