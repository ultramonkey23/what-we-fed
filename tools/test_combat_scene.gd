extends SceneTree

func _init() -> void:
    print("Loading CombatScene...")
    var scene = preload("res://scenes/combat/CombatScene.tscn")
    if scene:
        print("Loaded successfully!")
    else:
        print("Failed to load CombatScene.")
    quit()
