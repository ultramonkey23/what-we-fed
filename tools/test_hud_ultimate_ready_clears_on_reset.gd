extends SceneTree

# An unspent ultimate must not stay "READY" after the combo is reset.
# The HUD's ready state used to be cleared by combo_broken, which reset() fired.
# reset() (encounter start) is not a break and no longer emits combo_broken, so
# the ready state must follow the combo itself. Loaded in _initialize so the
# EventBus autoload is registered.

var _failures: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	var bus: Node = root.get_node("EventBus")
	var hud: Node = (load("res://scenes/ui/CombatPerformanceHUD.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var meter: Node = (load("res://systems/CombatMeter.gd") as GDScript).new()
	root.add_child(meter)
	# The HUD connects its EventBus listeners in _ready, which runs on the tree.
	await process_frame

	meter.combo_count = 24
	bus.emit_signal("ultimate_available")
	if not bool(hud.get("_ultimate_ready")):
		_failures.append("setup: HUD did not become ultimate-ready")

	meter.reset()
	if bool(hud.get("_ultimate_ready")):
		_failures.append("HUD still ultimate-ready after reset() zeroed the combo")
	var label: Label = hud.get("_ultimate_label")
	if label != null and label.text == "READY":
		_failures.append("ultimate label still reads READY after reset()")

	meter.free()
	hud.free()
	if _failures.is_empty():
		print("[PASS] HUD ultimate readiness follows the combo through reset()")
		quit(0)
	else:
		for f in _failures:
			printerr("[FAIL] " + f)
		quit(1)
