extends SceneTree

func _initialize() -> void:
	# CombatScene depends on registered autoload identifiers. A script preloaded
	# at SceneTree construction sees none of them, so exercise the actual
	# project load order after the autoloads are ready.
	call_deferred(&"_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/combat/CombatScene.tscn") as PackedScene
	if scene == null:
		printerr("[FAIL] CombatScene failed to load after autoload initialization")
		quit(1)
		return
	print("[PASS] CombatScene loads after project autoload initialization")
	quit(0)
