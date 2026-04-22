extends RefCounted

const HUD_PANEL_VISIBLE_ALPHA_THRESHOLD: float = 0.08

static var _visible_region_cache: Dictionary = {}


static func clear_cache() -> void:
	_visible_region_cache.clear()


static func apply_panel_art(panel: Control, texture_path: String, requested_region: Rect2, art_name: String = "HudPanelArt", backing_name: String = "HudPanelBacking", backing_color: Color = Color(0.03, 0.03, 0.04, 0.72)) -> void:
	if panel == null or texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return

	var src: Texture2D = load(texture_path) as Texture2D
	if src == null:
		src = ResourceLoader.load(texture_path, "", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if src == null:
		return

	var existing_backing: Node = panel.get_node_or_null(backing_name)
	if existing_backing != null:
		existing_backing.queue_free()
	var existing_art: Node = panel.get_node_or_null(art_name)
	if existing_art != null:
		existing_art.queue_free()

	var backing := ColorRect.new()
	backing.name = backing_name
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.color = backing_color
	backing.anchor_left = 0.0
	backing.anchor_top = 0.0
	backing.anchor_right = 1.0
	backing.anchor_bottom = 1.0
	backing.offset_left = 0.0
	backing.offset_top = 0.0
	backing.offset_right = 0.0
	backing.offset_bottom = 0.0
	panel.add_child(backing)

	var art := TextureRect.new()
	art.name = art_name
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.ignore_texture_size = true
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.anchor_left = 0.0
	art.anchor_top = 0.0
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0
	art.offset_left = 0.0
	art.offset_top = 0.0
	art.offset_right = 0.0
	art.offset_bottom = 0.0

	var resolved_region: Rect2 = resolve_visible_region(src, requested_region, texture_path)
	if resolved_region.size.x > 0.0 and resolved_region.size.y > 0.0:
		var atlas := AtlasTexture.new()
		atlas.atlas = src
		atlas.region = resolved_region
		art.texture = atlas
	else:
		art.texture = src

	panel.add_child(art)
	panel.move_child(backing, 0)
	panel.move_child(art, 1)


static func resolve_visible_region(texture: Texture2D, requested_region: Rect2, texture_path: String) -> Rect2:
	if texture == null:
		return Rect2()
	var cache_key: String = "%s|%s|%s|%s|%s" % [
		texture_path,
		str(requested_region.position.x),
		str(requested_region.position.y),
		str(requested_region.size.x),
		str(requested_region.size.y)
	]
	if _visible_region_cache.has(cache_key):
		return _visible_region_cache[cache_key]

	var tex_bounds := Rect2(Vector2.ZERO, texture.get_size())
	var sample_region: Rect2 = requested_region
	if sample_region.size.x <= 0.0 or sample_region.size.y <= 0.0:
		sample_region = tex_bounds
	else:
		sample_region = sample_region.intersection(tex_bounds)
		if sample_region.size.x <= 0.0 or sample_region.size.y <= 0.0:
			sample_region = tex_bounds

	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		_visible_region_cache[cache_key] = sample_region
		return sample_region

	var min_x: int = int(floor(sample_region.position.x))
	var min_y: int = int(floor(sample_region.position.y))
	var max_x: int = int(ceil(sample_region.end.x))
	var max_y: int = int(ceil(sample_region.end.y))

	var found: bool = false
	var tight_min_x: int = max_x
	var tight_min_y: int = max_y
	var tight_max_x: int = min_x
	var tight_max_y: int = min_y
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var a: float = image.get_pixel(x, y).a
			if a < HUD_PANEL_VISIBLE_ALPHA_THRESHOLD:
				continue
			found = true
			if x < tight_min_x:
				tight_min_x = x
			if y < tight_min_y:
				tight_min_y = y
			if x > tight_max_x:
				tight_max_x = x
			if y > tight_max_y:
				tight_max_y = y

	var resolved: Rect2 = sample_region
	if found:
		resolved = Rect2(
			Vector2(float(tight_min_x), float(tight_min_y)),
			Vector2(float(tight_max_x - tight_min_x + 1), float(tight_max_y - tight_min_y + 1))
		)
	_visible_region_cache[cache_key] = resolved
	return resolved
