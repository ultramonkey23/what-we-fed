extends RefCounted

const DISPLAY_FONT = preload("res://assets/fonts/display/This Night.ttf")
const UI_FONT = preload("res://assets/fonts/ui/WereWolf.ttf")


static func apply_label(label: Label, role: String, align: int = -1) -> void:
	if label == null:
		return

	var style: Dictionary = _style_for_role(role)
	label.add_theme_font_override("font", style.get("font", UI_FONT))
	label.add_theme_font_size_override("font_size", int(style.get("size", 14)))
	label.add_theme_color_override("font_color", style.get("color", Color(1.0, 1.0, 1.0, 1.0)))
	label.add_theme_color_override("font_outline_color", style.get("outline_color", Color(0.02, 0.02, 0.03, 0.95)))
	label.add_theme_constant_override("outline_size", int(style.get("outline_size", 0)))
	label.add_theme_color_override("font_shadow_color", style.get("shadow_color", Color(0.0, 0.0, 0.0, 0.0)))
	label.add_theme_constant_override("shadow_offset_x", int(style.get("shadow_x", 0)))
	label.add_theme_constant_override("shadow_offset_y", int(style.get("shadow_y", 0)))
	label.add_theme_constant_override("line_spacing", int(style.get("line_spacing", 0)))

	if align >= 0:
		label.horizontal_alignment = align


static func _style_for_role(role: String) -> Dictionary:
	match role:
		"caption":
			return {
				"font": UI_FONT,
				"size": 10,
				"color": Color(0.66, 0.62, 0.58, 0.80),
				"outline_size": 1,
				"outline_color": Color(0.03, 0.03, 0.04, 0.94)
			}
		"caption_strong":
			return {
				"font": UI_FONT,
				"size": 11,
				"color": Color(0.76, 0.71, 0.64, 0.94),
				"outline_size": 1,
				"outline_color": Color(0.03, 0.03, 0.04, 0.96)
			}
		"primary_value":
			return {
				"font": UI_FONT,
				"size": 20,
				"color": Color(0.96, 0.93, 0.88, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.96)
			}
		"secondary_value":
			return {
				"font": UI_FONT,
				"size": 15,
				"color": Color(0.94, 0.91, 0.86, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.94)
			}
		"warm_value":
			return {
				"font": UI_FONT,
				"size": 18,
				"color": Color(0.98, 0.90, 0.76, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.05, 0.03, 0.02, 0.95)
			}
		"cool_value":
			return {
				"font": UI_FONT,
				"size": 15,
				"color": Color(0.80, 0.92, 0.88, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.03, 0.03, 0.95)
			}
		"heading":
			return {
				"font": DISPLAY_FONT,
				"size": 28,
				"color": Color(0.96, 0.92, 0.84, 1.0),
				"outline_size": 2,
				"outline_color": Color(0.02, 0.02, 0.03, 0.96),
				"shadow_color": Color(0.0, 0.0, 0.0, 0.35),
				"shadow_x": 1,
				"shadow_y": 2
			}
		"subheading":
			return {
				"font": DISPLAY_FONT,
				"size": 20,
				"color": Color(0.96, 0.92, 0.84, 0.98),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.95)
			}
		"body":
			return {
				"font": UI_FONT,
				"size": 15,
				"color": Color(0.84, 0.80, 0.75, 0.98),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.90),
				"line_spacing": 1
			}
		"hint":
			return {
				"font": UI_FONT,
				"size": 12,
				"color": Color(0.74, 0.70, 0.64, 0.90),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.84)
			}
		"dim":
			return {
				"font": UI_FONT,
				"size": 11,
				"color": Color(0.58, 0.54, 0.49, 0.78),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.82)
			}
		"feedback":
			return {
				"font": DISPLAY_FONT,
				"size": 22,
				"color": Color(0.98, 0.95, 0.88, 1.0),
				"outline_size": 2,
				"outline_color": Color(0.02, 0.02, 0.03, 0.98),
				"shadow_color": Color(0.0, 0.0, 0.0, 0.36),
				"shadow_x": 1,
				"shadow_y": 2
			}
		"bond_heading":
			return {
				"font": DISPLAY_FONT,
				"size": 20,
				"color": Color(0.78, 0.90, 0.82, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.03, 0.04, 0.03, 0.94)
			}
		"eat_heading":
			return {
				"font": DISPLAY_FONT,
				"size": 20,
				"color": Color(0.95, 0.74, 0.62, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.05, 0.03, 0.03, 0.95)
			}
		"boss":
			return {
				"font": DISPLAY_FONT,
				"size": 16,
				"color": Color(0.90, 0.66, 0.20, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.05, 0.03, 0.02, 0.96)
			}
		"front_title":
			return {
				"font": DISPLAY_FONT,
				"size": 82,
				"color": Color(0.96, 0.91, 0.84, 1.0),
				"outline_size": 2,
				"outline_color": Color(0.02, 0.02, 0.03, 0.98),
				"shadow_color": Color(0.0, 0.0, 0.0, 0.42),
				"shadow_x": 2,
				"shadow_y": 3
			}
		"screen_title":
			return {
				"font": DISPLAY_FONT,
				"size": 44,
				"color": Color(0.95, 0.90, 0.82, 1.0),
				"outline_size": 2,
				"outline_color": Color(0.02, 0.02, 0.03, 0.98)
			}
		"screen_subtitle":
			return {
				"font": UI_FONT,
				"size": 18,
				"color": Color(0.62, 0.56, 0.50, 0.95),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.84)
			}
		"prompt":
			return {
				"font": UI_FONT,
				"size": 18,
				"color": Color(0.80, 0.74, 0.66, 0.92),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.88)
			}
		"card_index":
			return {
				"font": UI_FONT,
				"size": 18,
				"color": Color(0.48, 0.42, 0.36, 0.72),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.78)
			}
		"card_tag":
			return {
				"font": UI_FONT,
				"size": 12,
				"color": Color(0.84, 0.62, 0.30, 0.92),
				"outline_size": 1,
				"outline_color": Color(0.05, 0.03, 0.02, 0.88)
			}
		"card_title":
			return {
				"font": DISPLAY_FONT,
				"size": 24,
				"color": Color(0.94, 0.89, 0.80, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.96)
			}
		"card_body":
			return {
				"font": UI_FONT,
				"size": 14,
				"color": Color(0.62, 0.56, 0.50, 0.92),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.80),
				"line_spacing": 1
			}
		"card_metric":
			return {
				"font": UI_FONT,
				"size": 13,
				"color": Color(0.64, 0.76, 0.52, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.03, 0.04, 0.03, 0.86)
			}
		"note":
			return {
				"font": UI_FONT,
				"size": 13,
				"color": Color(0.54, 0.49, 0.44, 0.80),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.80)
			}
		_:
			return {
				"font": UI_FONT,
				"size": 14,
				"color": Color(0.94, 0.91, 0.86, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.90)
			}
