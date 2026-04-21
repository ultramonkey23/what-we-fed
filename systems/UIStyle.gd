extends RefCounted

const DISPLAY_FONT = preload("res://assets/fonts/display/This Night.ttf")
const UI_FONT = preload("res://assets/fonts/ui/WereWolf.ttf")
const MM_INK_BLACK = Color(0.03, 0.02, 0.04, 1.0)
const MM_DEEP_VIOLET = Color(0.14, 0.08, 0.20, 1.0)
const MM_BLOOD_EMBER = Color(0.90, 0.32, 0.15, 1.0)
const MM_MUTATION_MAGENTA = Color(0.82, 0.16, 0.74, 1.0)
const MM_BOND_TEAL = Color(0.24, 0.86, 0.74, 1.0)
const MM_ALERT_GOLD = Color(0.96, 0.78, 0.30, 1.0)
const MM_PAPER = Color(0.96, 0.94, 0.90, 1.0)


## Full-screen menu shell: subtle vertical gradient plus a thin warm frame (matches HUD border tones).
static func attach_shell_backdrop(root: Node2D, size: Vector2 = Vector2(1280.0, 720.0)) -> void:
	if root == null:
		return

	var layer := Node2D.new()
	layer.name = "ShellBackdrop"
	root.add_child(layer)
	root.move_child(layer, 0)

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.038, 0.018, 0.026, 1.0),
		Color(0.052, 0.026, 0.034, 1.0),
		Color(0.078, 0.034, 0.048, 1.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.52, 1.0])

	var gt := GradientTexture2D.new()
	gt.gradient = gradient
	gt.width = 8
	gt.height = 512
	gt.fill = GradientTexture2D.FILL_LINEAR
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)

	var bg := TextureRect.new()
	bg.texture = gt
	bg.position = Vector2.ZERO
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	layer.add_child(bg)

	var edge := Color(0.34, 0.26, 0.20, 0.55)
	var t := 2
	var top := ColorRect.new()
	top.color = edge
	top.position = Vector2.ZERO
	top.size = Vector2(size.x, float(t))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)

	var bottom := ColorRect.new()
	bottom.color = edge
	bottom.position = Vector2(0.0, size.y - float(t))
	bottom.size = Vector2(size.x, float(t))
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bottom)

	var left := ColorRect.new()
	left.color = edge
	left.position = Vector2.ZERO
	left.size = Vector2(float(t), size.y)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(left)

	var right := ColorRect.new()
	right.color = edge
	right.position = Vector2(size.x - float(t), 0.0)
	right.size = Vector2(float(t), size.y)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(right)


static func apply_shell_style(
	control: Control,
	role: String,
	texture_path: String = "",
	override_bg: Color = Color(0.0, 0.0, 0.0, 0.0),
	override_border: Color = Color(0.0, 0.0, 0.0, 0.0),
	texture_region: Rect2 = Rect2(),
	texture_expand_margin: Vector4 = Vector4.ZERO,
	shell_content_margin: Vector4 = Vector4.ZERO,
	texture_modulate: Color = Color(0.0, 0.0, 0.0, 0.0),
	flat_transparent_center: bool = false
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
		var panel_tex := _stylebox_texture_from_source(
			texture,
			texture_region,
			texture_expand_margin,
			shell_content_margin,
			texture_modulate if texture_modulate.a > 0.0 else Color(0.96, 0.94, 0.92, 1.0)
		)
		control.add_theme_stylebox_override("panel", panel_tex)
		control.add_theme_stylebox_override("background", panel_tex)
		control.add_theme_stylebox_override("fill", panel_tex)
		if control is ColorRect:
			(control as ColorRect).color = Color(1.0, 1.0, 1.0, 1.0)
		return

	var panel := StyleBoxFlat.new()
	if flat_transparent_center:
		panel.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		panel.shadow_size = 0
	else:
		panel.bg_color = bg_color
		if shadow_size > 0:
			panel.shadow_color = shadow_color
			panel.shadow_size = shadow_size
			panel.shadow_offset = Vector2.ZERO
	panel.corner_radius_top_left = corner_radius
	panel.corner_radius_top_right = corner_radius
	panel.corner_radius_bottom_left = corner_radius
	panel.corner_radius_bottom_right = corner_radius
	panel.border_width_left = border_width
	panel.border_width_top = border_width
	panel.border_width_right = border_width
	panel.border_width_bottom = border_width
	panel.border_color = border_color
	control.add_theme_stylebox_override("panel", panel)
	control.add_theme_stylebox_override("background", panel)
	if control is ColorRect:
		(control as ColorRect).color = panel.bg_color


static func apply_bar_style(
	bar: ProgressBar,
	role: String,
	background_texture_path: String = "",
	fill_texture_path: String = "",
	background_texture_region: Rect2 = Rect2(),
	background_expand_margin: Vector4 = Vector4.ZERO
) -> void:
	if bar == null:
		return

	var palette: Dictionary = _bar_palette_for_role(role)
	var under := _make_box_or_texture(
		background_texture_path,
		Color(palette.get("under_color", Color(0.08, 0.08, 0.09, 0.90))),
		Color(palette.get("border_color", Color(0.22, 0.20, 0.18, 0.94))),
		int(palette.get("corner_radius", 5)),
		int(palette.get("border_width", 1)),
		background_texture_region,
		background_expand_margin
	)
	var fill := _make_box_or_texture(
		fill_texture_path,
		Color(palette.get("fill_color", Color(0.80, 0.62, 0.28, 0.98))),
		Color(palette.get("fill_border_color", Color(0.0, 0.0, 0.0, 0.0))),
		int(palette.get("corner_radius", 5)),
		0,
		Rect2(),
		Vector4.ZERO
	)

	bar.add_theme_stylebox_override("background", under)
	bar.add_theme_stylebox_override("fill", fill)


static func _make_box_or_texture(
	texture_path: String,
	bg_color: Color,
	border_color: Color,
	corner_radius: int,
	border_width: int,
	texture_region: Rect2 = Rect2(),
	texture_expand_margin: Vector4 = Vector4.ZERO
) -> StyleBox:
	var texture: Texture2D = _load_texture(texture_path)
	if texture != null:
		var mod: Color = Color(1.0, 1.0, 1.0, 1.0)
		return _stylebox_texture_from_source(texture, texture_region, texture_expand_margin, Vector4.ZERO, mod)

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


static func _stylebox_texture_from_source(
	source: Texture2D,
	texture_region: Rect2,
	texture_expand_margin: Vector4,
	shell_content_margin: Vector4,
	modulate: Color
) -> StyleBoxTexture:
	var panel_tex := StyleBoxTexture.new()
	panel_tex.texture = source
	panel_tex.modulate_color = modulate
	panel_tex.draw_center = true
	panel_tex.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	panel_tex.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	if texture_region.size.x > 0.0 and texture_region.size.y > 0.0:
		panel_tex.region_rect = texture_region
	if texture_expand_margin != Vector4.ZERO:
		panel_tex.expand_margin_left = texture_expand_margin.x
		panel_tex.expand_margin_top = texture_expand_margin.y
		panel_tex.expand_margin_right = texture_expand_margin.z
		panel_tex.expand_margin_bottom = texture_expand_margin.w
	if shell_content_margin != Vector4.ZERO:
		panel_tex.content_margin_left = shell_content_margin.x
		panel_tex.content_margin_top = shell_content_margin.y
		panel_tex.content_margin_right = shell_content_margin.z
		panel_tex.content_margin_bottom = shell_content_margin.w
	return panel_tex


static func stylebox_texture_from_path(
	texture_path: String,
	texture_region: Rect2 = Rect2(),
	texture_expand_margin: Vector4 = Vector4.ZERO,
	shell_content_margin: Vector4 = Vector4.ZERO,
	modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
) -> Variant:
	var texture: Texture2D = _load_texture(texture_path)
	if texture == null:
		return null
	return _stylebox_texture_from_source(
		texture, texture_region, texture_expand_margin, shell_content_margin, modulate
	)


static func _load_texture(texture_path: String) -> Texture2D:
	if texture_path.is_empty():
		return null
	if ResourceLoader.exists(texture_path):
		var loaded: Texture2D = load(texture_path) as Texture2D
		if loaded != null:
			return loaded
	var abs_path: String = ProjectSettings.globalize_path(texture_path)
	if FileAccess.file_exists(abs_path):
		return ResourceLoader.load(texture_path, "", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	return null


static func get_manga_color(role: String) -> Color:
	match role:
		"ink_black":
			return MM_INK_BLACK
		"deep_violet":
			return MM_DEEP_VIOLET
		"blood_ember":
			return MM_BLOOD_EMBER
		"mutation_magenta":
			return MM_MUTATION_MAGENTA
		"bond_teal":
			return MM_BOND_TEAL
		"alert_gold":
			return MM_ALERT_GOLD
		"paper":
			return MM_PAPER
		_:
			return MM_PAPER


static func get_quality_feedback_color(quality: String) -> Color:
	match quality:
		"perfect":
			return Color(0.40, 1.0, 0.72, 0.86)
		"good":
			return Color(1.0, 0.90, 0.44, 0.78)
		"slip":
			return Color(1.0, 0.60, 0.42, 0.78)
		_:
			return Color(0.92, 0.92, 0.92, 0.44)


static func get_tendency_surge_color(tendency: String) -> Color:
	match tendency:
		"aggression":
			return MM_BLOOD_EMBER
		"cadence":
			return MM_ALERT_GOLD
		"guard":
			return Color(0.46, 0.70, 1.0, 1.0)
		"bond":
			return MM_BOND_TEAL
		_:
			return MM_PAPER


static func get_combat_ring_palette() -> Dictionary:
	return {
		"active": Color(1.0, 0.95, 0.55, 1.0),
		"inactive": Color(0.7, 0.7, 0.8, 0.45),
		"lane": Color(0.30, 0.30, 0.35, 1.0)
	}


static func _shell_palette_for_role(role: String) -> Dictionary:
	match role:
		"mm_command":
			return {
				"bg_color": Color(0.08, 0.05, 0.08, 0.96),
				"border_color": Color(0.64, 0.30, 0.20, 0.96),
				"corner_radius": 8,
				"border_width": 2,
				"shadow_color": Color(0.06, 0.02, 0.03, 0.34),
				"shadow_size": 2
			}
		"mm_alert":
			return {
				"bg_color": Color(0.10, 0.06, 0.04, 0.96),
				"border_color": MM_ALERT_GOLD,
				"corner_radius": 8,
				"border_width": 2,
				"shadow_color": Color(0.18, 0.10, 0.02, 0.30),
				"shadow_size": 2
			}
		"mm_mutation":
			return {
				"bg_color": Color(0.10, 0.04, 0.10, 0.96),
				"border_color": MM_MUTATION_MAGENTA,
				"corner_radius": 8,
				"border_width": 2,
				"shadow_color": Color(0.12, 0.02, 0.14, 0.34),
				"shadow_size": 2
			}
		"mm_apex":
			return {
				"bg_color": Color(0.12, 0.05, 0.03, 0.98),
				"border_color": MM_BLOOD_EMBER,
				"corner_radius": 8,
				"border_width": 2,
				"shadow_color": Color(0.20, 0.05, 0.02, 0.36),
				"shadow_size": 2
			}
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
		"mm_offer":
			return {
				"under_color": Color(0.10, 0.05, 0.11, 0.96),
				"fill_color": MM_MUTATION_MAGENTA,
				"border_color": Color(0.34, 0.16, 0.34, 0.92),
				"corner_radius": 6,
				"border_width": 1
			}
		"mm_ultimate":
			return {
				"under_color": Color(0.12, 0.06, 0.04, 0.98),
				"fill_color": MM_BLOOD_EMBER,
				"border_color": MM_ALERT_GOLD,
				"corner_radius": 6,
				"border_width": 1
			}
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
		"mm_title":
			return {
				"font": DISPLAY_FONT,
				"size": 50,
				"color": MM_PAPER,
				"outline_size": 3,
				"outline_color": MM_INK_BLACK,
				"shadow_color": Color(0.0, 0.0, 0.0, 0.44),
				"shadow_x": 2,
				"shadow_y": 3
			}
		"mm_subtitle":
			return {
				"font": UI_FONT,
				"size": 18,
				"color": Color(0.72, 0.67, 0.74, 0.98),
				"outline_size": 2,
				"outline_color": MM_INK_BLACK
			}
		"mm_stat_primary":
			return {
				"font": UI_FONT,
				"size": 20,
				"color": MM_PAPER,
				"outline_size": 2,
				"outline_color": MM_INK_BLACK
			}
		"mm_stat_secondary":
			return {
				"font": UI_FONT,
				"size": 17,
				"color": Color(0.84, 0.78, 0.86, 0.98),
				"outline_size": 2,
				"outline_color": MM_INK_BLACK
			}
		"mm_choice_bond":
			return {
				"font": DISPLAY_FONT,
				"size": 20,
				"color": MM_BOND_TEAL,
				"outline_size": 2,
				"outline_color": MM_INK_BLACK
			}
		"mm_choice_consume":
			return {
				"font": DISPLAY_FONT,
				"size": 20,
				"color": MM_BLOOD_EMBER,
				"outline_size": 2,
				"outline_color": MM_INK_BLACK
			}
		"mm_monster_alert":
			return {
				"font": DISPLAY_FONT,
				"size": 24,
				"color": MM_ALERT_GOLD,
				"outline_size": 2,
				"outline_color": MM_INK_BLACK,
				"shadow_color": Color(0.0, 0.0, 0.0, 0.36),
				"shadow_x": 1,
				"shadow_y": 2
			}
		"mm_caption":
			return {
				"font": UI_FONT,
				"size": 14,
				"color": Color(0.80, 0.74, 0.82, 0.96),
				"outline_size": 1,
				"outline_color": MM_INK_BLACK
			}
		"mm_body":
			return {
				"font": UI_FONT,
				"size": 16,
				"color": Color(0.90, 0.88, 0.92, 0.98),
				"outline_size": 1,
				"outline_color": MM_INK_BLACK,
				"line_spacing": 1
			}
		"mm_hint":
			return {
				"font": UI_FONT,
				"size": 16,
				"color": Color(0.88, 0.78, 0.66, 0.98),
				"outline_size": 2,
				"outline_color": MM_INK_BLACK
			}
		"mm_dim":
			return {
				"font": UI_FONT,
				"size": 14,
				"color": Color(0.60, 0.54, 0.62, 0.92),
				"outline_size": 1,
				"outline_color": MM_INK_BLACK
			}
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
