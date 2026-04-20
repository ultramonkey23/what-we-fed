extends RefCounted

const DISPLAY_FONT = preload("res://assets/fonts/display/This Night.ttf")
const UI_FONT = preload("res://assets/fonts/ui/WereWolf.ttf")


static func apply_shell_style(
	control: Control,
	role: String,
	texture_path: String = "",
	override_bg: Color = Color(0.0, 0.0, 0.0, 0.0),
	override_border: Color = Color(0.0, 0.0, 0.0, 0.0)
) -> void:
	if control == null:
		return

	var palette: Dictionary = _shell_palette_for_role(role)
	var bg_color: Color = override_bg if override_bg.a > 0.0 else Color(palette.get("bg_color", Color(0.08, 0.08, 0.09, 0.84)))
	var border_color: Color = override_border if override_border.a > 0.0 else Color(palette.get("border_color", Color(0.24, 0.22, 0.20, 0.88)))
	var corner_radius: int = int(palette.get("corner_radius", 6))
	var border_width: int = int(palette.get("border_width", 1))
	var shadow_color: Color = Color(palette.get("shadow_color", Color(0.0, 0.0, 0.0, 0.0)))
	var shadow_size: int = int(palette.get("shadow_size", 0))

	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texture: Texture2D = _load_texture(texture_path)
	if texture != null:
		var panel_tex := StyleBoxTexture.new()
		panel_tex.texture = texture
		panel_tex.modulate_color = bg_color
		control.add_theme_stylebox_override("panel", panel_tex)
		control.add_theme_stylebox_override("background", panel_tex)
		control.add_theme_stylebox_override("fill", panel_tex)
		if control is ColorRect:
			(control as ColorRect).color = Color(1.0, 1.0, 1.0, 1.0)
		return

	var panel := StyleBoxFlat.new()
	panel.bg_color = bg_color
	panel.corner_radius_top_left = corner_radius
	panel.corner_radius_top_right = corner_radius
	panel.corner_radius_bottom_left = corner_radius
	panel.corner_radius_bottom_right = corner_radius
	panel.border_width_left = border_width
	panel.border_width_top = border_width
	panel.border_width_right = border_width
	panel.border_width_bottom = border_width
	panel.border_color = border_color
	if shadow_size > 0:
		panel.shadow_color = shadow_color
		panel.shadow_size = shadow_size
		panel.shadow_offset = Vector2.ZERO
	control.add_theme_stylebox_override("panel", panel)
	control.add_theme_stylebox_override("background", panel)
	if control is ColorRect:
		(control as ColorRect).color = bg_color


static func apply_bar_style(
	bar: ProgressBar,
	role: String,
	background_texture_path: String = "",
	fill_texture_path: String = ""
) -> void:
	if bar == null:
		return

	var palette: Dictionary = _bar_palette_for_role(role)
	var under := _make_box_or_texture(
		background_texture_path,
		Color(palette.get("under_color", Color(0.08, 0.08, 0.09, 0.90))),
		Color(palette.get("border_color", Color(0.22, 0.20, 0.18, 0.94))),
		int(palette.get("corner_radius", 5)),
		int(palette.get("border_width", 1))
	)
	var fill := _make_box_or_texture(
		fill_texture_path,
		Color(palette.get("fill_color", Color(0.80, 0.62, 0.28, 0.98))),
		Color(palette.get("fill_border_color", Color(0.0, 0.0, 0.0, 0.0))),
		int(palette.get("corner_radius", 5)),
		0
	)

	bar.add_theme_stylebox_override("background", under)
	bar.add_theme_stylebox_override("fill", fill)


static func _make_box_or_texture(
	texture_path: String,
	bg_color: Color,
	border_color: Color,
	corner_radius: int,
	border_width: int
) -> StyleBox:
	var texture: Texture2D = _load_texture(texture_path)
	if texture != null:
		var panel_tex := StyleBoxTexture.new()
		panel_tex.texture = texture
		panel_tex.modulate_color = bg_color
		return panel_tex

	var panel := StyleBoxFlat.new()
	panel.bg_color = bg_color
	panel.corner_radius_top_left = corner_radius
	panel.corner_radius_top_right = corner_radius
	panel.corner_radius_bottom_left = corner_radius
	panel.corner_radius_bottom_right = corner_radius
	if border_width > 0:
		panel.border_width_left = border_width
		panel.border_width_top = border_width
		panel.border_width_right = border_width
		panel.border_width_bottom = border_width
		panel.border_color = border_color
	return panel


static func _load_texture(texture_path: String) -> Texture2D:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D


static func _shell_palette_for_role(role: String) -> Dictionary:
	match role:
		"hud_left":
			return {
				"bg_color": Color(0.06, 0.06, 0.07, 0.92),
				"border_color": Color(0.34, 0.26, 0.20, 0.96),
				"corner_radius": 7,
				"border_width": 2,
				"shadow_color": Color(0.0, 0.0, 0.0, 0.22),
				"shadow_size": 1
			}
		"hud_right":
			return {
				"bg_color": Color(0.05, 0.05, 0.06, 0.94),
				"border_color": Color(0.38, 0.29, 0.20, 0.98),
				"corner_radius": 7,
				"border_width": 2,
				"shadow_color": Color(0.0, 0.0, 0.0, 0.24),
				"shadow_size": 1
			}
		"hud_accent":
			return {
				"bg_color": Color(0.14, 0.10, 0.08, 0.42),
				"border_color": Color(0.44, 0.30, 0.18, 0.66),
				"corner_radius": 5,
				"border_width": 1
			}
		"support_idle":
			return {
				"bg_color": Color(0.06, 0.07, 0.08, 0.92),
				"border_color": Color(0.26, 0.34, 0.28, 0.92),
				"corner_radius": 7,
				"border_width": 2
			}
		"support_ready":
			return {
				"bg_color": Color(0.09, 0.13, 0.10, 0.98),
				"border_color": Color(0.84, 0.72, 0.26, 1.0),
				"corner_radius": 7,
				"border_width": 2,
				"shadow_color": Color(0.22, 0.16, 0.04, 0.34),
				"shadow_size": 2
			}
		"run_build":
			return {
				"bg_color": Color(0.05, 0.06, 0.07, 0.88),
				"border_color": Color(0.28, 0.28, 0.24, 0.88),
				"corner_radius": 7,
				"border_width": 1
			}
		"dna":
			return {
				"bg_color": Color(0.05, 0.06, 0.07, 0.90),
				"border_color": Color(0.26, 0.34, 0.28, 0.88),
				"corner_radius": 7,
				"border_width": 1
			}
		"boss_shell":
			return {
				"bg_color": Color(0.10, 0.04, 0.03, 0.96),
				"border_color": Color(0.64, 0.28, 0.12, 0.98),
				"corner_radius": 8,
				"border_width": 2,
				"shadow_color": Color(0.18, 0.04, 0.02, 0.28),
				"shadow_size": 1
			}
		"live_reward":
			return {
				"bg_color": Color(0.09, 0.06, 0.05, 0.94),
				"border_color": Color(0.66, 0.44, 0.18, 0.98),
				"corner_radius": 8,
				"border_width": 2
			}
		"feedback_backing":
			return {
				"bg_color": Color(0.03, 0.02, 0.02, 0.94),
				"border_color": Color(0.52, 0.30, 0.16, 0.96),
				"corner_radius": 6,
				"border_width": 2
			}
		_:
			return {
				"bg_color": Color(0.08, 0.08, 0.09, 0.84),
				"border_color": Color(0.24, 0.22, 0.20, 0.88),
				"corner_radius": 6,
				"border_width": 1
			}


static func _bar_palette_for_role(role: String) -> Dictionary:
	match role:
		"support_idle":
			return {
				"under_color": Color(0.05, 0.06, 0.07, 0.96),
				"fill_color": Color(0.56, 0.78, 0.66, 1.0),
				"border_color": Color(0.22, 0.28, 0.24, 0.94),
				"corner_radius": 6,
				"border_width": 1
			}
		"support_ready":
			return {
				"under_color": Color(0.07, 0.07, 0.06, 0.98),
				"fill_color": Color(0.86, 0.76, 0.32, 1.0),
				"border_color": Color(0.42, 0.34, 0.18, 0.96),
				"corner_radius": 6,
				"border_width": 1
			}
		"boss":
			return {
				"under_color": Color(0.12, 0.04, 0.03, 0.98),
				"fill_color": Color(0.88, 0.34, 0.14, 1.0),
				"border_color": Color(0.40, 0.14, 0.08, 0.98),
				"corner_radius": 6,
				"border_width": 1
			}
		_:
			return {
				"under_color": Color(0.08, 0.08, 0.09, 0.90),
				"fill_color": Color(0.80, 0.62, 0.28, 0.98),
				"border_color": Color(0.22, 0.20, 0.18, 0.94),
				"corner_radius": 5,
				"border_width": 1
			}


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
		label.horizontal_alignment = align as HorizontalAlignment


static func _style_for_role(role: String) -> Dictionary:
	match role:
		"caption":
			return {
				"font": UI_FONT,
				"size": 15,
				"color": Color(0.74, 0.70, 0.64, 0.90),
				"outline_size": 1,
				"outline_color": Color(0.03, 0.03, 0.04, 0.94)
			}
		"caption_strong":
			return {
				"font": UI_FONT,
				"size": 16,
				"color": Color(0.84, 0.79, 0.70, 0.98),
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
				"size": 19,
				"color": Color(0.95, 0.92, 0.88, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.94)
			}
		"warm_value":
			return {
				"font": UI_FONT,
				"size": 19,
				"color": Color(0.98, 0.90, 0.76, 1.0),
				"outline_size": 1,
				"outline_color": Color(0.05, 0.03, 0.02, 0.95)
			}
		"cool_value":
			return {
				"font": UI_FONT,
				"size": 18,
				"color": Color(0.80, 0.92, 0.88, 1.0),
				"outline_size": 2,
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
				"size": 22,
				"color": Color(0.96, 0.92, 0.84, 0.98),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.95)
			}
		"body":
			return {
				"font": UI_FONT,
				"size": 17,
				"color": Color(0.90, 0.86, 0.80, 0.99),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.90),
				"line_spacing": 1
			}
		"hint":
			return {
				"font": UI_FONT,
				"size": 17,
				"color": Color(0.80, 0.75, 0.68, 0.96),
				"outline_size": 2,
				"outline_color": Color(0.02, 0.02, 0.03, 0.92)
			}
		"dim":
			return {
				"font": UI_FONT,
				"size": 15,
				"color": Color(0.74, 0.69, 0.63, 0.90),
				"outline_size": 1,
				"outline_color": Color(0.02, 0.02, 0.03, 0.82)
			}
		"feedback":
			return {
				"font": DISPLAY_FONT,
				"size": 30,
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
				"size": 18,
				"color": Color(0.95, 0.73, 0.28, 1.0),
				"outline_size": 2,
				"outline_color": Color(0.05, 0.03, 0.02, 0.96)
			}
		"alert_value":
			return {
				"font": UI_FONT,
				"size": 18,
				"color": Color(0.98, 0.82, 0.58, 1.0),
				"outline_size": 2,
				"outline_color": Color(0.05, 0.03, 0.02, 0.95)
			}
		"status_line":
			return {
				"font": UI_FONT,
				"size": 17,
				"color": Color(0.84, 0.78, 0.72, 0.98),
				"outline_size": 2,
				"outline_color": Color(0.02, 0.02, 0.03, 0.92)
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


static func get_tier_color(tier_id: String) -> Color:
	match tier_id:
		"stirring": return Color(0.82, 0.82, 0.84, 0.90)
		"hunting": return Color(0.56, 0.78, 0.66, 0.95)
		"rampage": return Color(0.86, 0.76, 0.32, 1.0)
		"apex": return Color(0.92, 0.42, 0.12, 1.0)
		"sovereign": return Color(0.84, 0.18, 0.14, 1.0)
		_: return Color.WHITE


static func get_tier_label(tier_id: String) -> String:
	match tier_id:
		"stirring": return "STIRRING"
		"hunting": return "HUNTING"
		"rampage": return "RAMPAGE"
		"apex": return "APEX"
		"sovereign": return "SOVEREIGN"
		_: return tier_id.to_upper()
