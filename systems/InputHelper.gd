extends RefCounted

static var _last_device: String = "keyboard"

static func mark_device_from_event(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_last_device = "joypad"
	elif event is InputEventKey or event is InputEventMouseButton:
		_last_device = "keyboard"

static func is_joypad() -> bool:
	return _last_device == "joypad"

static func get_label_for_action(action_name: StringName) -> String:
	var pad := is_joypad()
	match action_name:
		&"action_attack":
			return "A BUTTON" if pad else "SPACE BAR"
		&"action_parry":
			return "B BUTTON" if pad else "RIGHT CLICK"
		&"action_dodge":
			return "X BUTTON" if pad else "SHIFT"
		&"action_support":
			return "Y BUTTON" if pad else "X KEY"
		&"action_ultimate":
			return "LB + RB" if pad else "C KEY"
		&"mod_left", &"mod_right", &"mod_up", &"mod_down":
			return "LEFT STICK" if pad else "ARROW KEYS"
		_:
			return String(action_name).to_upper().replace("_", " ")
