extends SceneTree

# Renders the real enemy markers for each identity case side by side and saves
# a PNG, so marker readability is judged from pixels, not from code.
# Usage: godot --path . -s tools/capture_enemy_marker_identity.gd -- <out.png>

const CASES: Array[Dictionary] = [
	{"label": "mature", "enemy": {"grade": "mature", "grade_label": "MATURE", "type": "drone", "behaviour_tags": []}},
	{"label": "mature", "enemy": {"grade": "mature", "grade_label": "MATURE", "type": "drone", "behaviour_tags": []}},
	{"label": "alpha", "enemy": {"grade": "alpha", "grade_label": "ALPHA", "type": "drone", "behaviour_tags": []}},
	{"label": "tagged elite", "enemy": {"grade": "mature", "grade_label": "ELITE", "type": "drone", "behaviour_tags": ["elite"]}},
	{"label": "sovereign", "enemy": {"grade": "mature", "grade_label": "SOVEREIGN", "type": "sovereign", "behaviour_tags": []}},
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "user://enemy_marker_identity.png"
	root.size = Vector2i(760, 240)

	var scene_script: GDScript = load("res://scenes/combat/CombatScene.gd")
	print("CombatScene.gd compiles: %s" % (scene_script != null and scene_script.can_instantiate()))

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.09)
	bg.size = Vector2(760, 240)
	root.add_child(bg)
	var controller: Node = (load("res://systems/CombatPresentationController.gd") as GDScript).new()
	root.add_child(controller)
	var x := 90.0
	var id := 1
	for c in CASES:
		# Every ordinary enemy is drawn at 42.0: the size the defect keyed on.
		var marker: Dictionary = controller._build_enemy_marker(id, 0, c["enemy"], 42.0, Color(0.40, 0.20, 0.20, 0.5), null, {})
		var node: Node2D = marker["root"]
		node.position = Vector2(x, 130)
		root.add_child(node)
		var caption := Label.new()
		caption.text = c["label"]
		caption.position = Vector2(x - 45, 190)
		caption.size = Vector2(90, 20)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(caption)
		x += 145.0
		id += 1
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(out_path)
	print("saved %s (%s)" % [out_path, error_string(err)])
	quit(0 if err == OK else 1)
