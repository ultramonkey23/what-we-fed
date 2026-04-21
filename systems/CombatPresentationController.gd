extends Node

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
const COMBAT_BG_CONTENT = preload("res://data/CombatBackgroundContent.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")

const HUD_PANEL_VISIBLE_ALPHA_THRESHOLD: float = 0.08

var _hud_visible_region_cache: Dictionary = {}
var _active_bg_env: Dictionary = {}


func _set_shell_treatment(shell: ColorRect, color: Color, border_color: Color) -> void:
	if shell == null:
		return
	UI_STYLE.apply_shell_style(shell, "", "", color, border_color)


func _apply_text_role(label: Label, role: String, align: int = -1) -> void:
	UI_STYLE.apply_label(label, role, align)


func _apply_wrapper_safe_zone(body: MarginContainer, safe_margin: Vector4, fallback_margin: Vector4) -> void:
	var margins: Vector4 = fallback_margin
	if safe_margin != Vector4.ZERO:
		margins = safe_margin
	body.offset_left = margins.x
	body.offset_top = margins.y
	body.offset_right = -margins.z
	body.offset_bottom = -margins.w


func _reflow_scroll_label_pair(scroll: ScrollContainer, label: Label) -> void:
	if scroll == null or label == null:
		return
	var inner_w: float = maxf(1.0, scroll.size.x - 10.0)
	label.custom_minimum_size.x = inner_w
	var content_h: float = label.get_minimum_size().y
	label.custom_minimum_size.y = maxf(scroll.size.y, content_h)


func setup_visuals(
	host: Node2D,
	background: ColorRect,
	flash_overlay: ColorRect,
	bg_sprite: Control, # Changed from TextureRect to Control
	battlefield_panel: ColorRect,
	battlefield_left_shade: ColorRect,
	battlefield_right_shade: ColorRect,
	battlefield_top_trim: ColorRect,
	battlefield_bottom_trim: ColorRect
) -> Dictionary:
	background.z_index = -10
	background.color = UI_STYLE.get_manga_color("ink_black")

	bg_sprite = apply_combat_background(host, background, flash_overlay, bg_sprite)

	var field_rect := Rect2(104.0, 112.0, 1060.0, 464.0)

	battlefield_panel = ColorRect.new()
	battlefield_panel.name = "BattlefieldPanel"
	battlefield_panel.position = field_rect.position
	battlefield_panel.size = field_rect.size
	battlefield_panel.color = Color(0.0, 0.0, 0.0, 0.0)
	battlefield_panel.z_index = -7
	host.add_child(battlefield_panel)

	battlefield_left_shade = ColorRect.new()
	battlefield_left_shade.name = "BattlefieldLeftShade"
	battlefield_left_shade.position = Vector2(field_rect.position.x + 6.0, field_rect.position.y + 20.0)
	battlefield_left_shade.size = Vector2(86.0, field_rect.size.y - 40.0)
	battlefield_left_shade.color = Color(0.02, 0.02, 0.03, 0.16)
	battlefield_left_shade.z_index = -5
	host.add_child(battlefield_left_shade)

	battlefield_right_shade = ColorRect.new()
	battlefield_right_shade.name = "BattlefieldRightShade"
	battlefield_right_shade.position = Vector2(field_rect.end.x - 92.0, field_rect.position.y + 20.0)
	battlefield_right_shade.size = Vector2(86.0, field_rect.size.y - 40.0)
	battlefield_right_shade.color = Color(0.08, 0.04, 0.10, 0.12)
	battlefield_right_shade.z_index = -5
	host.add_child(battlefield_right_shade)

	battlefield_top_trim = ColorRect.new()
	battlefield_top_trim.name = "BattlefieldTopTrim"
	battlefield_top_trim.position = field_rect.position + Vector2(76.0, 8.0)
	battlefield_top_trim.size = Vector2(field_rect.size.x - 152.0, 2.0)
	var top_trim_color: Color = UI_STYLE.get_manga_color("alert_gold")
	battlefield_top_trim.color = Color(top_trim_color.r, top_trim_color.g, top_trim_color.b, 0.24)
	battlefield_top_trim.z_index = -5
	host.add_child(battlefield_top_trim)

	battlefield_bottom_trim = ColorRect.new()
	battlefield_bottom_trim.name = "BattlefieldBottomTrim"
	battlefield_bottom_trim.position = Vector2(field_rect.position.x + 96.0, field_rect.end.y - 10.0)
	battlefield_bottom_trim.size = Vector2(field_rect.size.x - 192.0, 1.0)
	var bottom_trim_color: Color = UI_STYLE.get_manga_color("blood_ember")
	battlefield_bottom_trim.color = Color(bottom_trim_color.r, bottom_trim_color.g, bottom_trim_color.b, 0.18)
	battlefield_bottom_trim.z_index = -5
	host.add_child(battlefield_bottom_trim)

	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_overlay.z_index = 100
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	sync_fullscreen_underlay_controls(host, background, flash_overlay, bg_sprite)
	return {
		"bg_sprite": bg_sprite,
		"battlefield_panel": battlefield_panel,
		"battlefield_left_shade": battlefield_left_shade,
		"battlefield_right_shade": battlefield_right_shade,
		"battlefield_top_trim": battlefield_top_trim,
		"battlefield_bottom_trim": battlefield_bottom_trim
	}


func sync_fullscreen_underlay_controls(
	host: Node2D,
	background: ColorRect,
	flash_overlay: ColorRect,
	bg_sprite: Control
) -> void:
	var vp: Vector2 = host.get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	if is_instance_valid(background):
		background.set_anchors_preset(Control.PRESET_TOP_LEFT)
		background.position = Vector2.ZERO
		background.size = vp
	if is_instance_valid(flash_overlay):
		flash_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
		flash_overlay.position = Vector2.ZERO
		flash_overlay.size = vp
	if bg_sprite != null and is_instance_valid(bg_sprite):
		bg_sprite.position = Vector2.ZERO
		bg_sprite.size = vp
		# Update layers within the container
		for child in bg_sprite.get_children():
			if child is TextureRect:
				var layer_id = child.name
				var layer_data = {}
				for l in _active_bg_env.get("layers", []):
					if l.id == layer_id:
						layer_data = l
						break
				
				var scale_f: Vector2 = layer_data.get("scale", Vector2.ONE)
				child.size = vp * scale_f
				child.position = (vp - child.size) * 0.5 + layer_data.get("offset", Vector2.ZERO)
			elif child is CPUParticles2D:
				child.position = vp * 0.5
				child.emission_rect_extents = Vector2(vp.x * 0.5, vp.y * 0.5)

	var vignette: Node = host.get_node_or_null("CombatVignette")
	if vignette is TextureRect and is_instance_valid(vignette):
		(vignette as TextureRect).position = Vector2.ZERO
		(vignette as TextureRect).size = vp


func apply_combat_background(
	host: Node2D,
	background: ColorRect,
	flash_overlay: ColorRect,
	bg_sprite: Control,
	override_env_id: String = ""
) -> Control:
	if bg_sprite != null and is_instance_valid(bg_sprite):
		bg_sprite.queue_free()
		bg_sprite = null

	var old_vignette = host.get_node_or_null("CombatVignette")
	if is_instance_valid(old_vignette):
		old_vignette.queue_free()

	var env: Dictionary = {}
	if not override_env_id.is_empty():
		env = COMBAT_BG_CONTENT.get_environment(override_env_id)
	else:
		env = COMBAT_BG_CONTENT.get_random_environment()
	
	_active_bg_env = env

	# Create main container
	bg_sprite = Control.new()
	bg_sprite.name = "CombatBgContainer"
	bg_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_sprite.z_index = -9
	host.add_child(bg_sprite)

	var vp: Vector2 = host.get_viewport_rect().size
	bg_sprite.size = vp

	# Apply base color to background ColorRect
	background.color = env.get("base_color", Color(0.05, 0.04, 0.05, 1.0))

	# Create layers
	for layer_data in env.get("layers", []):
		var layer := TextureRect.new()
		layer.name = layer_data.id
		layer.texture = load(layer_data.path)
		layer.modulate = layer_data.get("modulate", Color.WHITE)
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var scale_f: Vector2 = layer_data.get("scale", Vector2.ONE)
		layer.size = vp * scale_f
		layer.position = (vp - layer.size) * 0.5 + layer_data.get("offset", Vector2.ZERO)
		
		bg_sprite.add_child(layer)

	# Create particles
	for part_data in env.get("particles", []):
		var particles = _create_particles(part_data, vp)
		bg_sprite.add_child(particles)

	# Create vignette
	var vignette := TextureRect.new()
	vignette.name = "CombatVignette"
	vignette.position = Vector2.ZERO
	vignette.size = vp
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.z_index = -8
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var v_color: Color = env.get("vignette_color", Color(0.02, 0.02, 0.03, 0.62))
	var grad := Gradient.new()
	grad.colors = [Color(0.0, 0.0, 0.0, 0.0), v_color]
	grad.offsets = [0.42, 1.0]

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 1.0)
	grad_tex.width = 512
	grad_tex.height = 512
	vignette.texture = grad_tex
	host.add_child(vignette)

	sync_fullscreen_underlay_controls(host, background, flash_overlay, bg_sprite)
	return bg_sprite


func _create_particles(data: Dictionary, vp: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "BackgroundParticles_" + data.id
	p.amount = data.get("amount", 20)
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.speed_scale = 0.5
	p.explosiveness = 0.0
	p.randomness = 0.5
	p.direction = data.get("velocity", Vector2(-1, 0.5)).normalized()
	p.spread = 20.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.color = data.get("color", Color.WHITE)
	p.position = vp * 0.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.5, vp.y * 0.5)
	
	# Create a simple dot texture if needed, or just use points
	# For now, we'll use a small white square as the default particle
	return p


func update_background_parallax(bg_sprite: Control, focus_pos: Vector2) -> void:
	if bg_sprite == null or not is_instance_valid(bg_sprite) or _active_bg_env.is_empty():
		return
	
	var vp: Vector2 = bg_sprite.size
	var center: Vector2 = vp * 0.5
	var offset: Vector2 = focus_pos - center
	
	for child in bg_sprite.get_children():
		if not child is TextureRect:
			continue
			
		var layer_id = child.name
		var layer_data = {}
		for l in _active_bg_env.get("layers", []):
			if l.id == layer_id:
				layer_data = l
				break
		
		if layer_data.is_empty():
			continue
			
		var p_factor: Vector2 = layer_data.get("parallax", Vector2.ZERO)
		var base_pos: Vector2 = (vp - child.size) * 0.5 + layer_data.get("offset", Vector2.ZERO)
		child.position = base_pos + offset * p_factor


func update_background_tendency_reaction(bg_sprite: Control, leading_tendency: String) -> void:
	if bg_sprite == null or not is_instance_valid(bg_sprite) or _active_bg_env.is_empty():
		return
	
	var reactions: Dictionary = _active_bg_env.get("tendency_reactions", {})
	if not reactions.has(leading_tendency):
		# Reset to base if no specific reaction
		for child in bg_sprite.get_children():
			if child is TextureRect:
				var layer_id = child.name
				for l in _active_bg_env.get("layers", []):
					if l.id == layer_id:
						child.modulate = l.get("modulate", Color.WHITE)
						break
			elif child is CPUParticles2D:
				child.speed_scale = 0.5
		return
	
	var reaction: Dictionary = reactions[leading_tendency]
	var target_modulate: Color = reaction.get("modulate", Color.WHITE)
	var speed_mult: float = reaction.get("particle_speed_mult", 1.0)
	
	for child in bg_sprite.get_children():
		if child is TextureRect:
			# Smoothly transition modulate
			var tween = child.create_tween()
			tween.tween_property(child, "modulate", target_modulate, 2.0).set_trans(Tween.TRANS_SINE)
		elif child is CPUParticles2D:
			child.speed_scale = 0.5 * speed_mult


func create_timing_circle_container(host: Node2D) -> Node2D:
	var timing_circle_container := Node2D.new()
	timing_circle_container.name = "TimingCircles"
	timing_circle_container.z_index = 20
	host.add_child(timing_circle_container)
	return timing_circle_container


func create_attack_fx_container(host: Node2D) -> Node2D:
	var attack_fx_container := Node2D.new()
	attack_fx_container.name = "AttackFX"
	attack_fx_container.z_index = 30
	host.add_child(attack_fx_container)
	return attack_fx_container


func draw_timing_circles(
	timing_circle_container: Node2D,
	timing_rings_cache: Array[Dictionary],
	active_encounter: Dictionary,
	lane_manager: Node,
	player_combat: Node2D
) -> void:
	for child in timing_circle_container.get_children():
		child.queue_free()
	timing_rings_cache.clear()

	var biome: Dictionary = active_encounter.get("biome", {})
	var active_color: Color = biome.get("ring_active_color", Color(1.0, 0.95, 0.55, 1.0))
	var inactive_color: Color = biome.get("ring_inactive_color", Color(0.7, 0.7, 0.8, 0.45))

	for lane in range(3):
		var lane_group := Node2D.new()
		lane_group.name = "TimingRing_%d" % lane
		lane_group.position = Vector2(
			lane_manager.get_hit_zone_x(),
			lane_manager.get_lane_y(lane)
		)

		var player_current_lane: int = int(player_combat.get("current_lane"))
		var is_active_lane: bool = lane == player_current_lane
		var base_color: Color = active_color if is_active_lane else inactive_color

		var receiver_glow := _make_disc_polygon(
			COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS + 6.0,
			Color(base_color.r, base_color.g, base_color.b, 0.0)
		)
		receiver_glow.name = "ReceiverGlow"

		var fill_alpha: float = 0.07 if is_active_lane else 0.03
		var receiver_fill := _make_disc_polygon(
			COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS + 9.0,
			Color(base_color.r, base_color.g, base_color.b, fill_alpha)
		)
		receiver_fill.name = "ReceiverFill"

		var outer_ring := _make_ring_line(
			COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS,
			Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.45),
			2.2
		)
		outer_ring.name = "Outer"

		var perfect_ring := _make_ring_line(
			COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS,
			base_color.lightened(0.32),
			4.2
		)
		perfect_ring.name = "Perfect"

		var edge_ring := _make_ring_line(
			COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS + 4.0,
			Color(base_color.r, base_color.g, base_color.b, 0.0),
			1.0
		)
		edge_ring.name = "Edge"

		var beat_mark := Line2D.new()
		beat_mark.name = "BeatMark"
		beat_mark.default_color = Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.55)
		beat_mark.width = 1.2
		beat_mark.add_point(Vector2(0.0, -COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS))
		beat_mark.add_point(Vector2(0.0, COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS))

		lane_group.add_child(receiver_glow)
		lane_group.add_child(receiver_fill)
		lane_group.add_child(edge_ring)
		lane_group.add_child(outer_ring)
		lane_group.add_child(perfect_ring)
		lane_group.add_child(beat_mark)
		timing_circle_container.add_child(lane_group)

		timing_rings_cache.append({
			"root": lane_group,
			"outer": outer_ring,
			"perfect": perfect_ring,
			"fill": receiver_fill,
			"glow": receiver_glow,
			"edge": edge_ring,
			"beat": beat_mark
		})


func _make_ring_line(radius: float, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.default_color = color
	line.width = width
	line.closed = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(72):
		var a: float = (float(i) / 72.0) * TAU
		points.append(Vector2(cos(a), sin(a)) * radius)
	line.points = points
	return line


func _make_disc_polygon(radius: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(36):
		var a: float = (float(i) / 36.0) * TAU
		points.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = points
	return poly


func update_timing_ring_proximity(
	active_encounter: Dictionary,
	lane_manager: Node,
	player_combat: Node2D,
	song_conductor: Node,
	timing_rings_cache: Array[Dictionary],
	ring_highlight_timers: Array[float],
	surge_window_timer: float,
	surge_window_tendency: String
) -> void:
	var biome: Dictionary = active_encounter.get("biome", {})
	var ring_palette: Dictionary = UI_STYLE.get_combat_ring_palette()
	var active_color: Color = biome.get("ring_active_color", ring_palette.get("active", Color(1.0, 0.95, 0.55, 1.0)))
	var inactive_color: Color = biome.get("ring_inactive_color", ring_palette.get("inactive", Color(0.7, 0.7, 0.8, 0.45)))

	var intercept_dist: float = lane_manager.get_enemy_x() - lane_manager.get_hit_zone_x()
	if intercept_dist <= 0.0:
		return

	var outer_entry: float = 1.0 - COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS / intercept_dist
	var outer_exit: float = 1.0 + COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS / intercept_dist
	var perfect_entry: float = 1.0 - COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS / intercept_dist
	var perfect_exit: float = 1.0 + COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS / intercept_dist
	var approach_start: float = outer_entry - 0.08

	# Beat pulse — brief alpha boost on all receivers each beat.
	# Phase 0 = beat fired, decays quickly; small anticipation rise near phase 1.
	# This gives the player a visual metronome without relying on a projectile.
	var beat_pulse: float = 0.0
	var bass_throb: float = 0.0
	if song_conductor != null and is_instance_valid(song_conductor) and song_conductor.is_beat_active():
		var bp: float = song_conductor.get_beat_phase()
		if bp < 0.18:
			beat_pulse = (1.0 - bp / 0.18) * 0.13
		elif bp > 0.88:
			beat_pulse = ((bp - 0.88) / 0.12) * 0.06
		# V1 Reactive Layer: let the bass frequency add a secondary layer of visual throb.
		if song_conductor.has_method("get_bass_magnitude"):
			bass_throb = song_conductor.get_bass_magnitude() * 0.15

	beat_pulse = clampf(beat_pulse + bass_throb, 0.0, 0.35)

	# Pre-compute surge window fade factor once — used inside the per-lane loop.
	var surge_wf: float = clamp(surge_window_timer / 4.0, 0.0, 1.0) if surge_window_timer > 0.0 else 0.0

	for lane in range(min(3, timing_rings_cache.size())):
		if ring_highlight_timers[lane] > 0.0:
			continue

		var cache: Dictionary = timing_rings_cache[lane]
		var outer_ring: Line2D = cache["outer"]
		var perfect_ring: Line2D = cache["perfect"]
		var receiver_fill: Polygon2D = cache["fill"]
		var receiver_glow: Polygon2D = cache["glow"]
		var edge_ring: Line2D = cache["edge"]
		var beat_mark: Line2D = cache["beat"]

		var base_color: Color = active_color if lane == player_combat.current_lane else inactive_color
		var outer_color: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.45)
		var perfect_color: Color = base_color.lightened(0.32)
		var outer_width: float = 2.2
		var perfect_width: float = 4.2
		var receiver_alpha: float = 0.10 if lane == player_combat.current_lane else 0.05
		var receiver_glow_alpha: float = 0.0
		var edge_alpha: float = 0.0
		var beat_color: Color = base_color.lightened(0.06)

		var proj = lane_manager.get_projectile(lane)
		if proj != null and not proj.is_resolved and not proj.is_reflected:
			var p: float = proj.progress
			var telegraph_profile: Dictionary = proj.telegraph_profile
			var threat_color: Color = Color(telegraph_profile.get("lane_color", active_color))
			var accent_color: Color = Color(telegraph_profile.get("accent_color", threat_color.lightened(0.18)))
			var warning_bias: float = max(float(telegraph_profile.get("warning_bias", 1.0)), 0.84)

			if p >= approach_start and p < outer_entry:
				# Projectile is approaching - fade the receiver into focus gradually.
				var t: float = clamp(((p - approach_start) / (outer_entry - approach_start)) * warning_bias, 0.0, 1.0)
				outer_color = outer_color.lerp(threat_color, t)
				receiver_alpha = lerp(receiver_alpha, 0.18, t)
				receiver_glow_alpha = lerp(0.0, 0.10, t)
				beat_color = beat_color.lerp(accent_color, t * 0.55)

			elif p >= outer_entry and p <= outer_exit:
				# Projectile is inside the outer ring - active threat and edge pressure.
				outer_color = threat_color.lightened(0.08)
				receiver_alpha = 0.22
				receiver_glow_alpha = 0.16
				beat_color = accent_color.lightened(0.18)

				if p >= perfect_entry and p <= perfect_exit:
					# Projectile is inside the perfect ring - sharpen the inner receiver truth.
					perfect_color = accent_color.lightened(0.26)
					perfect_width = 4.4
					receiver_alpha = 0.34
					receiver_glow_alpha = 0.22
					beat_color = accent_color.lightened(0.34)

				var edge_distance: float = min(abs(p - outer_entry), abs(p - outer_exit))
				if edge_distance <= COMBAT_FEEL_CONTENT.EDGE_STATE_WIDTH:
					var edge_t: float = 1.0 - clamp(edge_distance / COMBAT_FEEL_CONTENT.EDGE_STATE_WIDTH, 0.0, 1.0)
					edge_alpha = 0.20 + (0.30 * edge_t)
					outer_width = lerp(outer_width, 3.0, edge_t)

		# Apply beat pulse on top of proximity-driven alpha.
		# The pulse is identical across all lanes — it is a global metronome, not lane-specific.
		receiver_alpha = minf(receiver_alpha + beat_pulse, 0.52)
		if beat_pulse > 0.03:
			beat_color = beat_color.lerp(active_color.lightened(0.38), beat_pulse / 0.13)

		# ── Surge identity window ──────────────────────────────────────────────
		# After a tendency surge, tint the timing rings toward the tendency's
		# identity color for 4 s. Fades out linearly via surge_wf.
		# This presses the run's active character into the most-watched surface
		# without touching hitbox, timing windows, or lane readability.
		if surge_wf > 0.0:
			match surge_window_tendency:
				"aggression":
					# Perfect ring warms to orange-red — attack authority cue.
					var aggression_color: Color = UI_STYLE.get_tendency_surge_color("aggression")
					perfect_color = perfect_color.lerp(Color(aggression_color.r, aggression_color.g, aggression_color.b, perfect_color.a), surge_wf * 0.28)
					perfect_width = minf(perfect_width + surge_wf * 0.8, 6.2)
				"cadence":
					# Beat mark brightens to gold — rhythm clarity cue.
					var cadence_color: Color = UI_STYLE.get_tendency_surge_color("cadence")
					beat_color = beat_color.lerp(Color(cadence_color.r, cadence_color.g, cadence_color.b, beat_color.a), surge_wf * 0.42)
					receiver_alpha = minf(receiver_alpha + surge_wf * 0.04, 0.52)
				"guard":
					# Receiver fill gets a faint blue wash — defensive awareness cue.
					# Color applied below at the receiver_fill assignment step.
					receiver_alpha = minf(receiver_alpha + surge_wf * 0.04, 0.52)
				"bond":
					# Beat mark shifts teal — bond partner resonance cue.
					var bond_color: Color = UI_STYLE.get_tendency_surge_color("bond")
					beat_color = beat_color.lerp(Color(bond_color.r, bond_color.g, bond_color.b, beat_color.a), surge_wf * 0.38)
					receiver_alpha = minf(receiver_alpha + surge_wf * 0.03, 0.52)

		var rf_color: Color = Color(active_color.r, active_color.g, active_color.b, receiver_alpha)
		if proj != null and not proj.is_resolved and not proj.is_reflected:
			var telegraph_profile2: Dictionary = proj.telegraph_profile
			var threat_color2: Color = Color(telegraph_profile2.get("lane_color", active_color))
			rf_color = Color(threat_color2.r, threat_color2.g, threat_color2.b, receiver_alpha)
		if surge_wf > 0.0 and surge_window_tendency == "guard":
			var guard_color: Color = UI_STYLE.get_tendency_surge_color("guard")
			rf_color = rf_color.lerp(Color(guard_color.r, guard_color.g, guard_color.b, receiver_alpha), surge_wf * 0.20)
		receiver_fill.color = rf_color
		receiver_glow.color = Color(rf_color.r, rf_color.g, rf_color.b, receiver_glow_alpha)
		edge_ring.default_color = Color(rf_color.r, rf_color.g, rf_color.b, edge_alpha)
		beat_mark.default_color = beat_color

		outer_ring.default_color = outer_color
		outer_ring.width = outer_width
		perfect_ring.default_color = perfect_color
		perfect_ring.width = perfect_width


func build_arena_visuals(
	host: Node2D,
	active_encounter: Dictionary,
	lane_manager: Node,
	all_enemies_by_id: Dictionary,
	enemy_phase_by_id: Dictionary,
	enemy_markers_by_id: Dictionary,
	enemy_max_hp: Dictionary,
	lane_strips: Dictionary,
	lane_hit_focus: Dictionary,
	status_marker_overrides: Dictionary,
	current_phase_index: int,
	is_boss_encounter: bool,
	texture_cache: Dictionary,
	lane_marker_container: Node2D,
	enemy_marker_container: Node2D
) -> Dictionary:
	if not active_encounter.get("phases", []).is_empty():
		enemy_markers_by_id.clear()

	enemy_max_hp.clear()
	lane_strips.clear()
	lane_hit_focus.clear()

	if lane_marker_container != null:
		lane_marker_container.queue_free()
	if enemy_marker_container != null:
		enemy_marker_container.queue_free()

	lane_marker_container = Node2D.new()
	lane_marker_container.name = "LaneMarkers"
	host.add_child(lane_marker_container)

	enemy_marker_container = Node2D.new()
	enemy_marker_container.name = "EnemyMarkers"
	host.add_child(enemy_marker_container)

	var biome: Dictionary = active_encounter.get("biome", {})
	var lane_color: Color = biome.get("lane_color", Color(0.30, 0.30, 0.35, 1.0))
	var inactive_enemy_color: Color = biome.get("enemy_inactive_color", Color(0.40, 0.20, 0.20, 0.5))

	for lane in range(3):
		var lane_group := Node2D.new()
		lane_group.name = "LaneGroup_%d" % lane
		lane_marker_container.add_child(lane_group)

		var lane_strip := TextureRect.new()
		lane_strip.name = "Strip"
		lane_strip.size = Vector2(760.0, COMBAT_FEEL_CONTENT.LANE_BAND_HEIGHT)
		lane_strip.position = Vector2(208.0, lane_manager.get_lane_y(lane) - COMBAT_FEEL_CONTENT.LANE_BAND_HEIGHT * 0.5)
		lane_strip.pivot_offset = lane_strip.size * 0.5
		lane_strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lane_strip.stretch_mode = TextureRect.STRETCH_SCALE

		var ribbon_grad := Gradient.new()
		ribbon_grad.colors = [Color(1.0, 1.0, 1.0, 0.42), Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.42)]
		ribbon_grad.offsets = [0.0, 0.5, 1.0]
		var ribbon_tex := GradientTexture2D.new()
		ribbon_tex.gradient = ribbon_grad
		ribbon_tex.fill_from = Vector2(0.5, 0.0)
		ribbon_tex.fill_to = Vector2(0.5, 1.0)
		ribbon_tex.width = 16
		ribbon_tex.height = 32
		lane_strip.texture = ribbon_tex

		lane_strip.modulate = Color(lane_color.r, lane_color.g, lane_color.b, COMBAT_FEEL_CONTENT.LANE_IDLE_ALPHA)
		lane_group.add_child(lane_strip)
		lane_strips[lane] = lane_strip

		var strip_top := ColorRect.new()
		strip_top.size = Vector2(lane_strip.size.x, 1.0)
		strip_top.color = Color(lane_color.r, lane_color.g, lane_color.b, 0.12)
		lane_strip.add_child(strip_top)

		var strip_bottom := ColorRect.new()
		strip_bottom.size = Vector2(lane_strip.size.x, 1.0)
		strip_bottom.position = Vector2(0.0, lane_strip.size.y - 1.0)
		strip_bottom.color = Color(lane_color.r, lane_color.g, lane_color.b, 0.12)
		lane_strip.add_child(strip_bottom)

		var focal_root := Node2D.new()
		focal_root.name = "FocalMarker_%d" % lane
		focal_root.position = Vector2(lane_manager.get_hit_zone_x(), lane_manager.get_lane_y(lane))
		lane_marker_container.add_child(focal_root)
		lane_hit_focus[lane] = focal_root

		var marker_size: Vector2 = COMBAT_FEEL_CONTENT.FOCAL_MARKER_SIZE
		var half: Vector2 = marker_size * 0.5
		var bracket_len: float = 14.0
		var tick_len: float = 4.0
		var marker_color: Color = COMBAT_FEEL_CONTENT.FOCAL_MARKER_COLOR

		for quadrant in range(4):
			var bracket := Line2D.new()
			bracket.width = COMBAT_FEEL_CONTENT.FOCAL_MARKER_WIDTH
			bracket.default_color = marker_color
			bracket.begin_cap_mode = Line2D.LINE_CAP_ROUND
			bracket.end_cap_mode = Line2D.LINE_CAP_ROUND

			var x_sign: float = -1.0 if quadrant % 2 == 0 else 1.0
			var y_sign: float = -1.0 if quadrant < 2 else 1.0

			bracket.add_point(Vector2(x_sign * half.x, y_sign * (half.y - bracket_len)))
			bracket.add_point(Vector2(x_sign * half.x, y_sign * half.y))
			bracket.add_point(Vector2(x_sign * (half.x - bracket_len), y_sign * half.y))
			focal_root.add_child(bracket)

		for i in range(2):
			var tick := Line2D.new()
			tick.width = COMBAT_FEEL_CONTENT.FOCAL_MARKER_WIDTH
			tick.default_color = marker_color
			var y_sign_tick: float = -1.0 if i == 0 else 1.0
			tick.add_point(Vector2(0.0, y_sign_tick * half.y))
			tick.add_point(Vector2(0.0, y_sign_tick * (half.y - tick_len)))
			focal_root.add_child(tick)

	for enemy_id in all_enemies_by_id.keys():
		var enemy: Dictionary = all_enemies_by_id[enemy_id]
		var lane_enemy: int = int(enemy.get("lane", 0))
		var marker_size_enemy: float = 64.0 if is_boss_encounter else 42.0
		var marker_data: Dictionary

		if enemy_markers_by_id.has(enemy_id):
			marker_data = enemy_markers_by_id[enemy_id]
			var root = marker_data.get("root")
			if is_instance_valid(root):
				if root.get_parent() == null:
					enemy_marker_container.add_child(root)
			else:
				marker_data = _build_enemy_marker(
					enemy_id,
					lane_enemy,
					enemy,
					marker_size_enemy,
					inactive_enemy_color,
					lane_manager,
					texture_cache
				)
				enemy_marker_container.add_child(marker_data["root"])
				enemy_markers_by_id[enemy_id] = marker_data
		else:
			marker_data = _build_enemy_marker(
				enemy_id,
				lane_enemy,
				enemy,
				marker_size_enemy,
				inactive_enemy_color,
				lane_manager,
				texture_cache
			)
			enemy_marker_container.add_child(marker_data["root"])
			enemy_markers_by_id[enemy_id] = marker_data

		enemy_max_hp[enemy_id] = float(enemy.get("hp", 1))

	refresh_enemy_marker_states(
		active_encounter,
		enemy_markers_by_id,
		enemy_phase_by_id,
		status_marker_overrides,
		current_phase_index
	)

	return {
		"lane_marker_container": lane_marker_container,
		"enemy_marker_container": enemy_marker_container
	}


func refresh_enemy_marker_states(
	active_encounter: Dictionary,
	enemy_markers_by_id: Dictionary,
	enemy_phase_by_id: Dictionary,
	status_marker_overrides: Dictionary,
	current_phase_index: int
) -> void:
	var biome: Dictionary = active_encounter.get("biome", {})
	var active_color: Color = biome.get("enemy_active_color", Color(0.76, 0.21, 0.21, 1.0))
	var inactive_color: Color = biome.get("enemy_inactive_color", Color(0.38, 0.18, 0.18, 0.55))

	for enemy_id in enemy_markers_by_id.keys():
		var marker_data: Dictionary = enemy_markers_by_id[enemy_id]
		var body_node = marker_data.get("body")
		if not is_instance_valid(body_node):
			continue
		var marker_body: ColorRect = body_node
		var enemy_phase: int = int(enemy_phase_by_id.get(enemy_id, -1))
		if enemy_phase == current_phase_index:
			marker_body.color = active_color
		else:
			marker_body.color = inactive_color
		if status_marker_overrides.has(enemy_id):
			marker_body.color = status_marker_overrides[enemy_id]


func _build_enemy_marker(
	enemy_id: int,
	lane: int,
	enemy: Dictionary,
	marker_size: float,
	base_color: Color,
	lane_manager: Node,
	texture_cache: Dictionary
) -> Dictionary:
	var telegraph_profile: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
	var marker_half: float = marker_size * 0.5
	var marker_root := Node2D.new()
	marker_root.name = "Enemy_%d" % enemy_id
	marker_root.position = Vector2(lane_manager.get_enemy_x(), lane_manager.get_lane_y(lane))

	var frame := ColorRect.new()
	frame.name = "Frame"
	frame.size = Vector2(marker_size + 4.0, marker_size + 4.0)
	frame.position = Vector2(-marker_half - 2.0, -marker_half - 2.0)
	frame.color = Color(0.0, 0.0, 0.0, 0.50)
	marker_root.add_child(frame)

	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(marker_size, marker_size)
	body.position = Vector2(-marker_half, -marker_half)
	body.color = base_color
	body.modulate = enemy.get("marker_modulate", Color(1.0, 1.0, 1.0, 1.0))
	marker_root.add_child(body)

	var core := ColorRect.new()
	core.name = "Core"
	core.size = Vector2(marker_size - 12.0, marker_size - 12.0)
	core.position = Vector2(-(core.size.x * 0.5), -(core.size.y * 0.5))
	core.color = Color(0.0, 0.0, 0.0, 0.12)
	marker_root.add_child(core)

	var edge := ColorRect.new()
	edge.name = "Edge"
	edge.size = Vector2(marker_size - 4.0, marker_size - 4.0)
	edge.position = Vector2(-(edge.size.x * 0.5), -(edge.size.y * 0.5))
	edge.color = Color(telegraph_profile.get("projectile_color", Color.WHITE))
	edge.color.a = 0.0
	marker_root.add_child(edge)

	var accent := ColorRect.new()
	accent.name = "Accent"
	accent.color = Color(telegraph_profile.get("marker_color", Color.WHITE))
	var sigil := ColorRect.new()
	sigil.name = "Sigil"
	sigil.color = Color(telegraph_profile.get("accent_color", Color.WHITE))
	_configure_enemy_marker_shape(accent, sigil, marker_size, String(telegraph_profile.get("family", "fang")))
	marker_root.add_child(accent)
	marker_root.add_child(sigil)

	var species_id: String = String(enemy.get("species_id", ""))
	if not species_id.is_empty():
		var sprite_path: String = COMBAT_CONTENT.get_creature_art_path(species_id, "battlefield")
		if not sprite_path.is_empty():
			var tex: Texture2D = null
			if texture_cache.has(sprite_path):
				tex = texture_cache[sprite_path]
			else:
				tex = load(sprite_path) as Texture2D
				texture_cache[sprite_path] = tex

			if tex != null:
				var sprite := Sprite2D.new()
				sprite.texture = tex
				sprite.name = "CreatureSilhouette"
				var render: Dictionary = COMBAT_CONTENT.get_creature_combat_render(species_id)
				var marker_modulate: Color = Color(render.get("marker_modulate", base_color.darkened(0.4)))
				sprite.modulate = _tune_enemy_silhouette_color(marker_modulate, base_color)
				sprite.modulate.a = 1.0
				sprite.scale = Vector2(render.get("scale", 0.052), render.get("scale", 0.052)) * (marker_size / 42.0)
				sprite.position = Vector2(0.0, -2.0)
				marker_root.add_child(sprite)
				marker_root.move_child(sprite, 3)

	return {
		"root": marker_root,
		"body": body,
		"core": core,
		"edge": edge,
		"accent": accent,
		"sigil": sigil
	}


func _configure_enemy_marker_shape(accent: ColorRect, sigil: ColorRect, marker_size: float, family: String) -> void:
	var half: float = marker_size * 0.5
	match family:
		"mass":
			accent.size = Vector2(marker_size - 10.0, 6.0)
			accent.position = Vector2(-half + 5.0, -half + 5.0)
			sigil.size = Vector2(10.0, 10.0)
			sigil.position = Vector2(-5.0, 6.0)
		"needle":
			accent.size = Vector2(5.0, marker_size - 10.0)
			accent.position = Vector2(-2.5, -half + 5.0)
			sigil.size = Vector2(marker_size - 12.0, 4.0)
			sigil.position = Vector2(-half + 6.0, -half + 7.0)
		"veil":
			accent.size = Vector2(marker_size - 8.0, 4.0)
			accent.position = Vector2(-half + 4.0, -2.0)
			sigil.size = Vector2(6.0, marker_size - 16.0)
			sigil.position = Vector2(-half + 8.0, -half + 8.0)
		"chorus":
			accent.size = Vector2(marker_size - 12.0, 4.0)
			accent.position = Vector2(-half + 6.0, -half + 7.0)
			sigil.size = Vector2(marker_size - 16.0, 4.0)
			sigil.position = Vector2(-half + 8.0, half - 11.0)
		"sovereign":
			accent.size = Vector2(marker_size - 10.0, 6.0)
			accent.position = Vector2(-half + 5.0, -half + 5.0)
			sigil.size = Vector2(6.0, marker_size - 12.0)
			sigil.position = Vector2(-3.0, -half + 6.0)
		_:
			accent.size = Vector2(marker_size * 0.42, 5.0)
			accent.position = Vector2(half - accent.size.x - 6.0, half - 10.0)
			sigil.size = Vector2(5.0, marker_size * 0.52)
			sigil.position = Vector2(-half + 7.0, -half + 6.0)
	accent.color.a = 0.18
	sigil.color.a = 0.22


func _tune_enemy_silhouette_color(requested: Color, body_color: Color) -> Color:
	var tuned: Color = requested
	var body_luma: float = body_color.get_luminance()
	var tuned_luma: float = tuned.get_luminance()
	if tuned_luma < 0.34:
		tuned = tuned.lightened(min((0.34 - tuned_luma) * 1.15, 0.28))
	elif tuned_luma > 0.78:
		tuned = tuned.darkened(min((tuned_luma - 0.78) * 1.35, 0.30))
	tuned_luma = tuned.get_luminance()
	var luma_delta: float = abs(tuned_luma - body_luma)
	if luma_delta < 0.16:
		var push: float = min((0.16 - luma_delta) + 0.06, 0.24)
		if body_luma >= 0.50:
			tuned = tuned.darkened(push)
		else:
			tuned = tuned.lightened(push)
	return tuned


func update_enemy_marker_threat_states(
	enemy_markers_by_id: Dictionary,
	all_enemies_by_id: Dictionary,
	lane_manager: Node
) -> void:
	for enemy_id in enemy_markers_by_id.keys():
		var marker_data: Dictionary = enemy_markers_by_id[enemy_id]
		var marker_root = marker_data.get("root")
		if not is_instance_valid(marker_root):
			continue
		var enemy: Dictionary = all_enemies_by_id.get(enemy_id, {})
		var lane: int = int(enemy.get("lane", -1))
		if lane < 0:
			continue
		var telegraph_profile: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
		var edge_node = marker_data.get("edge")
		var accent_node = marker_data.get("accent")
		var sigil_node = marker_data.get("sigil")
		var core_node = marker_data.get("core")
		if not is_instance_valid(edge_node) or not is_instance_valid(accent_node) or not is_instance_valid(sigil_node) or not is_instance_valid(core_node):
			continue
		var edge: ColorRect = edge_node
		var accent: ColorRect = accent_node
		var sigil: ColorRect = sigil_node
		var core: ColorRect = core_node
		var pressure: float = 0.0
		var imminent: float = 0.0
		var projectile = lane_manager.get_projectile(lane)
		if projectile != null and not projectile.is_resolved and not projectile.is_reflected and int(projectile.enemy_id) == enemy_id:
			var warning_bias: float = max(float(telegraph_profile.get("warning_bias", 1.0)), 0.84)
			pressure = clamp(((projectile.progress - 0.70) / 0.30) * warning_bias, 0.0, 1.0)
			imminent = clamp((projectile.progress - 0.96) / 0.08, 0.0, 1.0)

		var threat_color: Color = Color(telegraph_profile.get("projectile_color", Color.WHITE))
		var accent_color: Color = Color(telegraph_profile.get("accent_color", threat_color.lightened(0.18)))
		var marker_color: Color = Color(telegraph_profile.get("marker_color", accent_color))
		edge.color = Color(threat_color.r, threat_color.g, threat_color.b, pressure * 0.12 + imminent * 0.24)
		accent.color = Color(marker_color.r, marker_color.g, marker_color.b, 0.18 + pressure * 0.30 + imminent * 0.14)
		sigil.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.22 + pressure * 0.34 + imminent * 0.18)
		core.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.08 + pressure * 0.08 + imminent * 0.06)


func create_reward_overlay(ui_layer: CanvasLayer) -> Dictionary:
	var reward_overlay := ColorRect.new()
	reward_overlay.name = "RewardOverlay"
	reward_overlay.visible = false
	reward_overlay.color = Color(0.01, 0.01, 0.02, 0.88)
	reward_overlay.anchor_right = 1.0
	reward_overlay.anchor_bottom = 1.0
	reward_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(reward_overlay)

	var reward_wrapper_shell := PanelContainer.new()
	reward_wrapper_shell.name = "RewardWrapperShell"
	reward_wrapper_shell.position = Vector2(160.0, 88.0)
	reward_wrapper_shell.size = Vector2(960.0, 452.0)
	var reward_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_reward_panel_path()
	if reward_tex.is_empty():
		UI_STYLE.apply_shell_style(reward_wrapper_shell, "live_reward")
	else:
		UI_STYLE.apply_shell_style(
			reward_wrapper_shell,
			"live_reward",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(reward_wrapper_shell, reward_tex, COMBAT_FEEL_CONTENT.hud_reward_texture_region())
	reward_overlay.add_child(reward_wrapper_shell)

	var reward_safe_body := MarginContainer.new()
	reward_safe_body.name = "RewardSafeBody"
	reward_safe_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(
		reward_safe_body,
		COMBAT_FEEL_CONTENT.HUD_REWARD_CONTENT_MARGIN,
		Vector4(0.0, 0.0, 0.0, 0.0)
	)
	reward_wrapper_shell.add_child(reward_safe_body)

	var reward_panel := ColorRect.new()
	reward_panel.name = "RewardPanel"
	_set_shell_treatment(reward_panel, Color(0.09, 0.07, 0.08, 0.86), Color(0.26, 0.20, 0.18, 0.42))
	reward_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	reward_safe_body.add_child(reward_panel)

	var reward_creature_portrait := TextureRect.new()
	reward_creature_portrait.name = "CreaturePortrait"
	reward_creature_portrait.position = Vector2(42.0, 50.0)
	reward_creature_portrait.size = Vector2(152.0, 240.0)
	reward_creature_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_creature_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_creature_portrait.visible = false
	reward_panel.add_child(reward_creature_portrait)

	var reward_creature_tag_label := Label.new()
	reward_creature_tag_label.name = "RewardTag"
	reward_creature_tag_label.position = Vector2(204.0, 18.0)
	reward_creature_tag_label.size = Vector2(250.0, 18.0)
	_apply_text_role(reward_creature_tag_label, "caption_strong")
	reward_panel.add_child(reward_creature_tag_label)

	var reward_title_label := Label.new()
	reward_title_label.name = "RewardTitle"
	reward_title_label.position = Vector2(204.0, 40.0)
	reward_title_label.size = Vector2(250.0, 56.0)
	_apply_text_role(reward_title_label, "heading")
	reward_panel.add_child(reward_title_label)

	var reward_body_scroll := ScrollContainer.new()
	reward_body_scroll.name = "RewardBodyScroll"
	reward_body_scroll.position = Vector2(204.0, 98.0)
	reward_body_scroll.size = Vector2(250.0, 150.0)
	reward_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reward_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	reward_body_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_panel.add_child(reward_body_scroll)

	var reward_body_label := Label.new()
	reward_body_label.name = "RewardBody"
	reward_body_label.position = Vector2.ZERO
	reward_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(reward_body_label, "body")
	reward_body_scroll.add_child(reward_body_label)

	var reward_bond_card := ColorRect.new()
	reward_bond_card.name = "RewardBondCard"
	reward_bond_card.position = Vector2(468.0, 54.0)
	reward_bond_card.size = Vector2(206.0, 244.0)
	_set_shell_treatment(reward_bond_card, Color(0.09, 0.10, 0.09, 0.96), Color(0.24, 0.31, 0.25, 0.88))
	reward_panel.add_child(reward_bond_card)

	var bond_accent := ColorRect.new()
	bond_accent.name = "BondAccent"
	bond_accent.size = Vector2(206.0, 4.0)
	bond_accent.position = Vector2.ZERO
	bond_accent.color = Color(0.80, 0.60, 0.24, 0.90)
	reward_bond_card.add_child(bond_accent)

	var reward_bond_label := Label.new()
	reward_bond_label.name = "RewardBondLabel"
	reward_bond_label.position = Vector2(18.0, 18.0)
	reward_bond_label.size = Vector2(168.0, 26.0)
	_apply_text_role(reward_bond_label, "bond_heading")
	reward_bond_card.add_child(reward_bond_label)

	var reward_bond_effect_scroll := ScrollContainer.new()
	reward_bond_effect_scroll.name = "RewardBondEffectScroll"
	reward_bond_effect_scroll.position = Vector2(18.0, 56.0)
	reward_bond_effect_scroll.size = Vector2(170.0, 154.0)
	reward_bond_effect_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reward_bond_effect_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	reward_bond_effect_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_bond_card.add_child(reward_bond_effect_scroll)

	var reward_bond_effect_label := Label.new()
	reward_bond_effect_label.name = "RewardBondEffect"
	reward_bond_effect_label.position = Vector2.ZERO
	reward_bond_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_bond_effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(reward_bond_effect_label, "body")
	reward_bond_effect_scroll.add_child(reward_bond_effect_label)

	var reward_eat_card := ColorRect.new()
	reward_eat_card.name = "RewardEatCard"
	reward_eat_card.position = Vector2(694.0, 54.0)
	reward_eat_card.size = Vector2(206.0, 244.0)
	_set_shell_treatment(reward_eat_card, Color(0.11, 0.08, 0.07, 0.96), Color(0.36, 0.24, 0.20, 0.92))
	reward_panel.add_child(reward_eat_card)

	var eat_accent := ColorRect.new()
	eat_accent.name = "EatAccent"
	eat_accent.size = Vector2(206.0, 4.0)
	eat_accent.position = Vector2.ZERO
	eat_accent.color = Color(0.72, 0.22, 0.18, 0.90)
	reward_eat_card.add_child(eat_accent)

	var reward_eat_label := Label.new()
	reward_eat_label.name = "RewardEatLabel"
	reward_eat_label.position = Vector2(18.0, 18.0)
	reward_eat_label.size = Vector2(168.0, 26.0)
	_apply_text_role(reward_eat_label, "eat_heading")
	reward_eat_card.add_child(reward_eat_label)

	var reward_eat_effect_scroll := ScrollContainer.new()
	reward_eat_effect_scroll.name = "RewardEatEffectScroll"
	reward_eat_effect_scroll.position = Vector2(18.0, 56.0)
	reward_eat_effect_scroll.size = Vector2(170.0, 154.0)
	reward_eat_effect_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reward_eat_effect_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	reward_eat_effect_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_eat_card.add_child(reward_eat_effect_scroll)

	var reward_eat_effect_label := Label.new()
	reward_eat_effect_label.name = "RewardEatEffect"
	reward_eat_effect_label.position = Vector2.ZERO
	reward_eat_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_eat_effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(reward_eat_effect_label, "body")
	reward_eat_effect_scroll.add_child(reward_eat_effect_label)

	var reward_quig_label := Label.new()
	reward_quig_label.name = "RewardQuig"
	reward_quig_label.position = Vector2(84.0, 316.0)
	reward_quig_label.size = Vector2(818.0, 32.0)
	_apply_text_role(reward_quig_label, "hint")
	reward_panel.add_child(reward_quig_label)

	var reward_quig_sprite: TextureRect = _build_strip_sprite(
		"RewardQuigSprite",
		COMBAT_FEEL_CONTENT.QUIG_SPRITE_PATH,
		COMBAT_FEEL_CONTENT.QUIG_FRAME_SIZE,
		0,
		Vector2(42.0, 312.0),
		Vector2(32.0, 32.0)
	)
	if reward_quig_sprite != null:
		reward_quig_sprite.visible = false
		reward_panel.add_child(reward_quig_sprite)

	var reward_hint_label := Label.new()
	reward_hint_label.name = "RewardHint"
	reward_hint_label.position = Vector2(42.0, 382.0)
	reward_hint_label.size = Vector2(860.0, 26.0)
	_apply_text_role(reward_hint_label, "hint")
	reward_panel.add_child(reward_hint_label)

	return {
		"reward_overlay": reward_overlay,
		"reward_wrapper_shell": reward_wrapper_shell,
		"reward_panel": reward_panel,
		"reward_title_label": reward_title_label,
		"reward_body_label": reward_body_label,
		"reward_quig_label": reward_quig_label,
		"reward_quig_sprite": reward_quig_sprite,
		"reward_hint_label": reward_hint_label,
		"reward_bond_card": reward_bond_card,
		"reward_eat_card": reward_eat_card,
		"reward_bond_label": reward_bond_label,
		"reward_eat_label": reward_eat_label,
		"reward_bond_effect_label": reward_bond_effect_label,
		"reward_eat_effect_label": reward_eat_effect_label,
		"reward_creature_tag_label": reward_creature_tag_label,
		"reward_creature_portrait": reward_creature_portrait,
		"reward_body_scroll": reward_body_scroll,
		"reward_bond_effect_scroll": reward_bond_effect_scroll,
		"reward_eat_effect_scroll": reward_eat_effect_scroll
	}


func schedule_reward_scroll_reflow(host: Node) -> void:
	host.call_deferred("_reflow_reward_scroll_labels")


func reflow_reward_scroll_labels(
	reward_body_scroll: ScrollContainer,
	reward_body_label: Label,
	reward_bond_effect_scroll: ScrollContainer,
	reward_bond_effect_label: Label,
	reward_eat_effect_scroll: ScrollContainer,
	reward_eat_effect_label: Label
) -> void:
	_reflow_scroll_label_pair(reward_body_scroll, reward_body_label)
	_reflow_scroll_label_pair(reward_bond_effect_scroll, reward_bond_effect_label)
	_reflow_scroll_label_pair(reward_eat_effect_scroll, reward_eat_effect_label)


func create_live_reward_shell(ui_layer: CanvasLayer) -> Dictionary:
	var live_reward_shell := PanelContainer.new()
	live_reward_shell.name = "LiveRewardShell"
	live_reward_shell.visible = false
	live_reward_shell.z_index = 38
	live_reward_shell.clip_contents = true
	live_reward_shell.anchor_left = 0.0
	live_reward_shell.anchor_top = 0.0
	live_reward_shell.anchor_right = 0.0
	live_reward_shell.anchor_bottom = 0.0
	var vp0: Vector2 = ui_layer.get_viewport().get_visible_rect().size
	live_reward_shell.position = COMBAT_FEEL_CONTENT.compact_live_reward_position_for_viewport(vp0)
	live_reward_shell.size = COMBAT_FEEL_CONTENT.compact_live_reward_size()
	var reward_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_reward_panel_path()
	if reward_tex.is_empty():
		UI_STYLE.apply_shell_style(live_reward_shell, "live_reward")
	else:
		UI_STYLE.apply_shell_style(
			live_reward_shell,
			"live_reward",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(live_reward_shell, reward_tex, COMBAT_FEEL_CONTENT.hud_reward_texture_region())
	ui_layer.add_child(live_reward_shell)

	var live_reward_safe_body := MarginContainer.new()
	live_reward_safe_body.name = "LiveRewardSafeBody"
	live_reward_safe_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(
		live_reward_safe_body,
		COMBAT_FEEL_CONTENT.HUD_REWARD_COMPACT_CONTENT_MARGIN,
		Vector4(12.0, 8.0, 12.0, 10.0)
	)
	live_reward_shell.add_child(live_reward_safe_body)

	var reward_body := VBoxContainer.new()
	reward_body.name = "LiveRewardVBox"
	reward_body.add_theme_constant_override("separation", 4)
	reward_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	live_reward_safe_body.add_child(reward_body)

	var live_reward_title_label := Label.new()
	live_reward_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_reward_title_label.custom_minimum_size = Vector2(0.0, 22.0)
	_apply_text_role(live_reward_title_label, "subheading")
	live_reward_title_label.add_theme_font_size_override("font_size", 16)
	reward_body.add_child(live_reward_title_label)

	var live_reward_body_label := Label.new()
	live_reward_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_reward_body_label.custom_minimum_size = Vector2(0.0, 22.0)
	live_reward_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_role(live_reward_body_label, "body")
	live_reward_body_label.add_theme_font_size_override("font_size", 13)
	reward_body.add_child(live_reward_body_label)

	var live_reward_hint_label := Label.new()
	live_reward_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_reward_hint_label.custom_minimum_size = Vector2(0.0, 18.0)
	_apply_text_role(live_reward_hint_label, "hint")
	live_reward_hint_label.add_theme_font_size_override("font_size", 12)
	reward_body.add_child(live_reward_hint_label)

	return {
		"live_reward_shell": live_reward_shell,
		"live_reward_title_label": live_reward_title_label,
		"live_reward_body_label": live_reward_body_label,
		"live_reward_hint_label": live_reward_hint_label
	}


func sync_compact_transient_hud_layout(
	hud_top_left_panel: Control,
	live_reward_shell: PanelContainer,
	performance_hud: Control
) -> void:
	enforce_top_left_panel_rect(hud_top_left_panel)
	if live_reward_shell != null and is_instance_valid(live_reward_shell):
		var vp: Vector2 = get_viewport().get_visible_rect().size
		live_reward_shell.position = COMBAT_FEEL_CONTENT.compact_live_reward_position_for_viewport(vp)
		live_reward_shell.size = COMBAT_FEEL_CONTENT.compact_live_reward_size()
	sync_message_lane_ownership(live_reward_shell, performance_hud)


func sync_message_lane_ownership(live_reward_shell: PanelContainer, performance_hud: Control) -> void:
	var live_lane_active: bool = live_reward_shell != null and is_instance_valid(live_reward_shell) and live_reward_shell.visible
	if is_instance_valid(performance_hud) and performance_hud.has_method("set_message_lane_blocked"):
		performance_hud.call("set_message_lane_blocked", live_lane_active)
	center_performance_offer_shell(live_reward_shell, performance_hud)


func center_performance_offer_shell(live_reward_shell: PanelContainer, performance_hud: Control) -> void:
	if not is_instance_valid(performance_hud):
		return
	var offer_shell: Control = performance_hud.get_node_or_null("%OfferShell") as Control
	if offer_shell == null:
		return
	if live_reward_shell != null and is_instance_valid(live_reward_shell) and live_reward_shell.visible:
		offer_shell.visible = false
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var sz: Vector2 = COMBAT_FEEL_CONTENT.compact_live_reward_size()
	offer_shell.size = sz
	offer_shell.global_position = COMBAT_FEEL_CONTENT.compact_live_reward_position_for_viewport(vp)


func enforce_top_left_panel_rect(hud_top_left_panel: Control) -> void:
	if hud_top_left_panel == null or not is_instance_valid(hud_top_left_panel):
		return
	var hud_m: float = COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN
	var hud_ty: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y
	var hud_tl_w: float = COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH
	var hud_th: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_HEIGHT
	hud_top_left_panel.custom_minimum_size = Vector2(hud_tl_w, hud_th)
	hud_top_left_panel.position = Vector2(hud_m, hud_ty)
	hud_top_left_panel.size = Vector2(hud_tl_w, hud_th)


func _create_panel_backing(panel: Control, panel_name: String = "Backing") -> ColorRect:
	var backing := panel.get_node_or_null(panel_name) as ColorRect
	if backing == null:
		backing = ColorRect.new()
		backing.name = panel_name
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backing.color = Color(0.0, 0.0, 0.0, 0.0)
		backing.anchor_left = 0.0
		backing.anchor_top = 0.0
		backing.anchor_right = 1.0
		backing.anchor_bottom = 1.0
		backing.offset_left = 0.0
		backing.offset_top = 0.0
		backing.offset_right = 0.0
		backing.offset_bottom = 0.0
		panel.add_child(backing)
	return backing


func _build_strip_sprite(
	name: String,
	texture_path: String,
	frame_size: Vector2i,
	frame_index: int,
	position: Vector2,
	size: Vector2
) -> TextureRect:
	if texture_path.is_empty():
		return null
	if not ResourceLoader.exists(texture_path):
		return null
	var src: Texture2D = load(texture_path) as Texture2D
	if src == null:
		return null
	var tex: Texture2D = src
	if frame_size.x > 0 and frame_size.y > 0:
		var atlas := AtlasTexture.new()
		atlas.atlas = src
		var cols: int = maxi(1, src.get_width() / frame_size.x)
		var idx: int = maxi(0, frame_index)
		var x: int = (idx % cols) * frame_size.x
		var y: int = (idx / cols) * frame_size.y
		atlas.region = Rect2(Vector2(float(x), float(y)), Vector2(float(frame_size.x), float(frame_size.y)))
		tex = atlas

	var r := TextureRect.new()
	r.name = name
	r.texture = tex
	r.position = position
	r.size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _hud_attach_combat_panel_art(panel: Control, texture_path: String, region: Rect2) -> void:
	if panel == null or texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return

	var src: Texture2D = load(texture_path) as Texture2D
	if src == null:
		return

	var backing: ColorRect = _create_panel_backing(panel, "Backing")
	var old_art: TextureRect = panel.get_node_or_null("Art") as TextureRect
	if old_art != null:
		old_art.queue_free()

	var art := TextureRect.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var resolved_region: Rect2 = _resolve_visible_panel_region(src, region, texture_path)
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


func _resolve_visible_panel_region(texture: Texture2D, requested_region: Rect2, texture_path: String) -> Rect2:
	if texture == null:
		return Rect2()
	var cache_key: String = "%s|%s|%s|%s|%s" % [
		texture_path,
		str(requested_region.position.x),
		str(requested_region.position.y),
		str(requested_region.size.x),
		str(requested_region.size.y)
	]
	if _hud_visible_region_cache.has(cache_key):
		return _hud_visible_region_cache[cache_key]

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
		_hud_visible_region_cache[cache_key] = sample_region
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
	_hud_visible_region_cache[cache_key] = resolved
	return resolved
