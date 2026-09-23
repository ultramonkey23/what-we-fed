extends SceneTree

# Elite/boss marker identity must come from the enemy, not from marker size.
# Every ordinary enemy is drawn at 42.0, and `marker_size >= 40.0` used to mark
# all of them as bosses, so the elite frame, HP fill and threat tint were
# universal and elites were unreadable.
#
# The controller references the EventBus autoload, so it is loaded in
# _initialize (after autoloads register) rather than preloaded at parse time.

const ORDINARY_FRAME := Color(0.0, 0.0, 0.0, 0.50)
const ELITE_FRAME := Color(0.18, 0.05, 0.03, 0.78)
const ELITE_HP_FILL := Color(0.84, 0.21, 0.16, 0.96)
const ORDINARY_HP_FILL := Color(0.68, 0.16, 0.18, 0.92)

var _failures: Array[String] = []


func _initialize() -> void:
	var controller_script: GDScript = load("res://systems/CombatPresentationController.gd")
	var controller: Node = controller_script.new()
	root.add_child(controller)

	var cases: Array[Dictionary] = [
		{"label": "mature", "enemy": {"grade": "mature", "type": "drone", "behaviour_tags": []}, "elite": false},
		{"label": "alpha", "enemy": {"grade": "alpha", "type": "drone", "behaviour_tags": []}, "elite": true},
		{"label": "tagged elite", "enemy": {"grade": "mature", "type": "drone", "behaviour_tags": ["elite"]}, "elite": true},
		{"label": "sovereign", "enemy": {"grade": "mature", "type": "sovereign", "behaviour_tags": []}, "elite": true},
		{"label": "boss encounter", "enemy": {"grade": "mature", "type": "drone", "behaviour_tags": [], "is_boss": true}, "elite": true},
	]
	var enemy_id := 1
	for c in cases:
		# 42.0 is the size every ordinary enemy is drawn at: the defect's trigger.
		var marker: Dictionary = controller._build_enemy_marker(
			enemy_id, 0, c["enemy"], 42.0, Color(0.4, 0.2, 0.2, 0.5), null, {})
		enemy_id += 1
		var marker_root: Node2D = marker.get("root")
		if marker_root == null:
			_failures.append("%s: marker has no root" % c["label"])
			continue
		_expect_style(c["label"], marker_root, bool(c["elite"]))
		marker_root.free()

	controller.free()
	if _failures.is_empty():
		print("[PASS] enemy marker elite identity (5 cases)")
		quit(0)
	else:
		for f in _failures:
			printerr("[FAIL] " + f)
		quit(1)


func _expect_style(label: String, marker_root: Node2D, elite: bool) -> void:
	var frame: ColorRect = marker_root.get_node_or_null("Frame")
	var hp_fill: ColorRect = marker_root.find_child("HpFill", true, false)
	var threat: Label = marker_root.find_child("ThreatLabel", true, false)
	if frame == null or hp_fill == null or threat == null:
		_failures.append("%s: missing Frame/HpFill/ThreatLabel" % label)
		return
	var want_frame := ELITE_FRAME if elite else ORDINARY_FRAME
	var want_fill := ELITE_HP_FILL if elite else ORDINARY_HP_FILL
	if not frame.color.is_equal_approx(want_frame):
		_failures.append("%s: frame %s, want %s" % [label, frame.color, want_frame])
	if not hp_fill.color.is_equal_approx(want_fill):
		_failures.append("%s: hp fill %s, want %s" % [label, hp_fill.color, want_fill])
	var tinted := threat.modulate.is_equal_approx(Color(1.0, 0.64, 0.34, 1.0))
	if tinted != elite:
		_failures.append("%s: threat label tint %s, elite=%s" % [label, threat.modulate, elite])
