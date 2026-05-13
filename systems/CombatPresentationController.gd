extends Node

const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
const COMBAT_BG_CONTENT = preload("res://data/CombatBackgroundContent.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")
const HUD_PANEL_ART = preload("res://systems/HUDPanelArt.gd")

const PLAYER_SIGIL_OUTER_RADIUS: float = COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS * COMBAT_FEEL_CONTENT.RING_VISUAL_SCALE
const PLAYER_SIGIL_INNER_RADIUS: float = COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS * COMBAT_FEEL_CONTENT.RING_VISUAL_SCALE
const SIGIL_FOLLOW_LERP: float = 0.12 # Subtle follow speed

var _active_bg_env: Dictionary = {}
var _shared_noise_tex: NoiseTexture2D = null
var _vessel_vibe_color: Color = Color(1.0, 0.95, 0.55, 1.0) # Default Amber
var _primary_grave_threat_key: int = -1
## Optional `CombatVisualRig` (or compatible Node) parented under CombatScene for editor anchors.
var _combat_visual_rig: Node2D = null


func set_combat_visual_rig(rig: Node2D) -> void:
	_combat_visual_rig = rig


func _apply_visual_rig_enemy_present_pos(lane: int, baseline: Vector2, zone_manager: Node) -> Vector2:
	if _combat_visual_rig == null or not is_instance_valid(_combat_visual_rig):
		return baseline
	return _combat_visual_rig.resolve_enemy_marker_world_pos(lane, baseline, zone_manager)


func _get_shared_noise_tex() -> NoiseTexture2D:
	if _shared_noise_tex != null:
		return _shared_noise_tex
		
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.08
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	
	_shared_noise_tex = NoiseTexture2D.new()
	# PREMIUM: Increased resolution to stop "blocky" shimmer distortion
	_shared_noise_tex.width = 1024
	_shared_noise_tex.height = 256
	_shared_noise_tex.seamless = true
	_shared_noise_tex.noise = noise
	return _shared_noise_tex


func set_shell_treatment(shell: ColorRect, color: Color, border_color: Color) -> void:
	if shell == null:
		return
	UI_STYLE.apply_shell_style(shell, "", "", color, border_color)


func apply_text_role(label: Label, role: String, align: int = -1) -> void:
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
	bg_sprite: Control,
	battlefield_panel: Control
) -> Dictionary:
	background.z_index = -10
	background.color = UI_STYLE.get_manga_color("ink_black")

	bg_sprite = apply_combat_background(host, background, flash_overlay, bg_sprite)

	# Keep combat lanes clear from HUD intrusions by shrinking the visual battlefield band.
	var field_rect := Rect2(104.0, 112.0, 1024.0, 464.0)

	battlefield_panel = ColorRect.new()
	battlefield_panel.name = "BattlefieldPanel"
	battlefield_panel.position = field_rect.position
	battlefield_panel.size = field_rect.size
	battlefield_panel.color = Color(0.0, 0.0, 0.0, 0.0)
	battlefield_panel.z_index = -7
	host.add_child(battlefield_panel)

	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_overlay.z_index = 100
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	sync_fullscreen_underlay_controls(host, background, flash_overlay, bg_sprite)
	return {
		"bg_sprite": bg_sprite,
		"battlefield_panel": battlefield_panel
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
	# PREMIUM: Manga-style transition for background swaps
	if bg_sprite != null and is_instance_valid(bg_sprite):
		# If we're swapping, trigger a high-contrast transition
		EventBus.emit_signal("screen_flash", Color(0.92, 0.86, 0.74, 0.20), 0.10)
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
		
		# Premium: Inject atmospheric haze after the sky layer
		if layer_data.id == "sky":
			var haze_container := Control.new()
			haze_container.name = "AtmosphericHaze"
			haze_container.set_anchors_preset(Control.PRESET_FULL_RECT)
			haze_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg_sprite.add_child(haze_container)
			
			var haze_base := ColorRect.new()
			haze_base.name = "HazeBase"
			haze_base.set_anchors_preset(Control.PRESET_FULL_RECT)
			haze_base.color = env.get("haze_color", Color(0.0, 0.0, 0.0, 0.3))
			haze_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
			haze_container.add_child(haze_base)
			
			# PREMIUM: Kinetic haze drift using a shader for silky smoothness
			var haze_drift := TextureRect.new()
			haze_drift.name = "HazeDrift"
			haze_drift.set_anchors_preset(Control.PRESET_FULL_RECT)
			haze_drift.texture = _get_shared_noise_tex()
			haze_drift.stretch_mode = TextureRect.STRETCH_TILE
			haze_drift.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Applying the drift shader
			var haze_mat := ShaderMaterial.new()
			haze_mat.shader = load("res://assets/ui/shaders/haze_drift.gdshader")
			haze_mat.set_shader_parameter("scroll_speed", Vector2(0.05, 0.03))
			haze_mat.set_shader_parameter("noise_intensity", 0.08)
			haze_drift.material = haze_mat
			
			haze_container.add_child(haze_drift)

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


func update_background_parallax(bg_sprite: Control, focus_pos: Vector2, pulse_scale: float = 1.0) -> void:
	if bg_sprite == null or not is_instance_valid(bg_sprite) or _active_bg_env.is_empty():
		return
	
	var vp: Vector2 = bg_sprite.size
	var center: Vector2 = vp * 0.5
	var offset: Vector2 = focus_pos - center
	
	# Music Reactivity: Get beat phase from GameState if available
	var beat_pulse: float = 0.0
	if GameState.is_beat_active():
		# We'll use a simple sine wave pulse based on time if we don't have a direct phase
		beat_pulse = abs(sin(Time.get_ticks_msec() * 0.008)) * 0.04
	beat_pulse *= clampf(pulse_scale, 0.45, 1.0)
	
	# PREMIUM: Kinetic Haze Drift Reaction
	for child in bg_sprite.get_children():
		if child.name == "AtmosphericHaze":
			var drift: TextureRect = child.get_node_or_null("HazeDrift")
			if drift != null and drift.material is ShaderMaterial:
				# React to beat by intensifying the noise via shader
				var mat: ShaderMaterial = drift.material as ShaderMaterial
				mat.set_shader_parameter("noise_intensity", 0.08 + (beat_pulse * 0.5))
	
	# SIGNAL: Pulse the Living Restraint HUD panels on beat
	# This syncs the biological HUD to the project's Timing Truth pulse.
	HUD_PANEL_ART.pulse_registered_panels(beat_pulse * 15.0)

	for child in bg_sprite.get_children():
		if child is TextureRect:
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
			
			# Apply parallax + subtle beat scale pulse
			child.position = base_pos + offset * p_factor
			if layer_id == "sky": # Farthest layer pulses most for depth
				child.scale = layer_data.get("scale", Vector2.ONE) * (1.0 + beat_pulse)
		elif child is CPUParticles2D:
			# Particles react to beat by speeding up slightly
			child.speed_scale = 0.5 + (beat_pulse * 2.0)


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


func on_combat_event(bg_sprite: Control, event_type: String) -> void:
	if bg_sprite == null or not is_instance_valid(bg_sprite):
		return
	
	if event_type == "perfect":
		# PREMIUM: Reactive Vignette Punch-in
		var host: Node2D = bg_sprite.get_parent()
		if is_instance_valid(host):
			var vignette: TextureRect = host.get_node_or_null("CombatVignette")
			if vignette != null:
				var v_tween = vignette.create_tween()
				vignette.scale = Vector2(1.15, 1.15) # Punch in
				vignette.pivot_offset = vignette.size * 0.5
				v_tween.tween_property(vignette, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
		
		# Kinetic particles reaction
		for child in bg_sprite.get_children():
			if child is CPUParticles2D:
				var original_speed = child.speed_scale
				var tween = child.create_tween()
				tween.tween_property(child, "speed_scale", original_speed * 4.0, 0.1)
				tween.tween_property(child, "speed_scale", original_speed, 0.6)


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
	zone_manager: Node,
	player_combat: Node2D
) -> void:
	for child in timing_circle_container.get_children():
		timing_circle_container.remove_child(child)
		child.free()
	timing_rings_cache.clear()

	var biome: Dictionary = active_encounter.get("biome", {})
	var active_color: Color = biome.get("ring_active_color", Color(1.0, 0.95, 0.55, 1.0))

	# 1. CORE SIGIL: The Heartbeat (Central feedback only)
	var sigil_group := Node2D.new()
	sigil_group.name = "TimingRing_Core"
	if player_combat != null:
		sigil_group.position = player_combat.position
	
	var receiver_fill := _make_disc_polygon(PLAYER_SIGIL_OUTER_RADIUS + 4.0, Color(active_color, 0.07), 2.5)
	receiver_fill.name = "ReceiverFill"
	sigil_group.add_child(receiver_fill)
	
	var good_ring := _make_anomaly_sigil_ring(PLAYER_SIGIL_OUTER_RADIUS, Color(active_color, 0.52), 1.8, 2.5)
	good_ring.name = "Good"
	sigil_group.add_child(good_ring)

	var perfect_ring := _make_anomaly_sigil_ring(PLAYER_SIGIL_INNER_RADIUS, active_color.lightened(0.20), 3.0, 1.6)
	perfect_ring.name = "Perfect"
	sigil_group.add_child(perfect_ring)
	
	# Secondary outer scribble ring for depth
	var scribble := _make_anomaly_sigil_ring(PLAYER_SIGIL_OUTER_RADIUS + 7.0, Color(active_color, 0.12), 1.0, 4.5)
	scribble.name = "Scribble"
	sigil_group.add_child(scribble)
	
	timing_circle_container.add_child(sigil_group)

	# 2. GRAVE RINGS (Directional Threat Indicators: 'Manga Shards')
	for i in range(zone_manager.THREAT_COUNT if zone_manager else 8):
		var grave_ring := Node2D.new()
		grave_ring.name = "GraveRing_%d" % i
		grave_ring.visible = false
		
		# Fragmented Bone Shards: A cluster of splinters instead of one shape
		for j in range(3):
			var splinter := Polygon2D.new()
			splinter.name = "Splinter_%d" % j
			var s_pts := PackedVector2Array([
				Vector2(randf_range(-2, 2), randf_range(-6, -9)),
				Vector2(randf_range(6, 9), randf_range(-2, 2)),
				Vector2(randf_range(-2, 2), randf_range(6, 9)),
				Vector2(randf_range(-6, -9), randf_range(-2, 2))
			])
			splinter.polygon = s_pts
			splinter.color = Color(active_color, 0.15)
			var init_pos := Vector2(randf_range(5, 15), randf_range(-10, 10))
			splinter.position = init_pos
			splinter.set_meta("base_pos", init_pos)
			grave_ring.add_child(splinter)
			
			var outline := Line2D.new()
			outline.name = "Outline"
			outline.points = s_pts
			outline.closed = true
			outline.width = 1.4
			outline.default_color = Color(active_color, 0.65)
			splinter.add_child(outline)
		
		# Inner Marrow is kept as a dormant compatibility child; active threat
		# readability now comes from the outer splinters only.
		var marrow := Polygon2D.new()
		marrow.name = "Marrow"
		marrow.polygon = PackedVector2Array([
			Vector2(4, 0),
			Vector2(14, -12),
			Vector2(24, 0),
			Vector2(14, 12)
		])
		marrow.color = Color.BLACK
		marrow.color.a = 0.0
		marrow.visible = false
		grave_ring.add_child(marrow)
		
		timing_circle_container.add_child(grave_ring)

	# 3. GHOST THREADS (Visual tether from player to threat)
	for i in range(zone_manager.THREAT_COUNT if zone_manager else 8):
		var glow := Line2D.new()
		glow.name = "GlowThread_%d" % i
		glow.width = 4.5
		glow.default_color = Color(0.6, 0.1, 0.9, 0.0) # Purple Glow, hidden
		glow.joint_mode = Line2D.LINE_JOINT_ROUND
		glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
		glow.end_cap_mode = Line2D.LINE_CAP_ROUND
		timing_circle_container.add_child(glow)

		var thread := Line2D.new()
		thread.name = "GhostThread_%d" % i
		thread.width = 1.2
		thread.default_color = Color(active_color, 0.0) # Invisible by default
		thread.joint_mode = Line2D.LINE_JOINT_ROUND
		thread.begin_cap_mode = Line2D.LINE_CAP_ROUND
		thread.end_cap_mode = Line2D.LINE_CAP_ROUND
		timing_circle_container.add_child(thread)
		
	timing_rings_cache.append({
		"root": sigil_group,
		"outer": good_ring,
		"perfect": perfect_ring,
		"fill": receiver_fill
	})


func refresh_vessel_vibe(class_data: Dictionary, timing_rings_cache: Array[Dictionary]) -> void:
	if class_data.is_empty():
		return
		
	var vibe_color: Color = class_data.get("vibe_color", Color.WHITE)
	_vessel_vibe_color = vibe_color
	var style: Dictionary = class_data.get("visual_style", {})
	var jitter: float = float(style.get("jitter", 0.0))
	var width_mult: float = float(style.get("width_mult", 1.0))
	var pulse_speed: float = float(style.get("aura_pulse_speed", 1.0))
	var aura_alpha: float = float(style.get("aura_alpha", 0.2))
	
	for ring_data in timing_rings_cache:
		var root: Node2D = ring_data.get("root")
		if not is_instance_valid(root):
			continue
			
		var tween = root.create_tween().set_parallel(true)
		
		# Transition main sigil rings
		var perfect_ring: Line2D = ring_data.get("perfect")
		if is_instance_valid(perfect_ring):
			tween.tween_property(perfect_ring, "default_color", vibe_color.lightened(0.32), 0.45)
			tween.tween_property(perfect_ring, "width", 2.0 * width_mult, 0.4)
			# Apply manga jitter if supported by the line shader/logic
			if perfect_ring.has_meta("base_jitter"):
				tween.tween_method(func(v): perfect_ring.set_meta("current_jitter", v), 0.0, jitter, 0.5)
			
		var outer_ring: Line2D = ring_data.get("outer")
		if is_instance_valid(outer_ring):
			tween.tween_property(outer_ring, "default_color", Color(vibe_color, 0.52), 0.6)
			tween.tween_property(outer_ring, "width", 1.0 * width_mult, 0.6)
			
		var fill: Polygon2D = ring_data.get("fill")
		if is_instance_valid(fill):
			tween.tween_property(fill, "color", Color(vibe_color, 0.08), 0.8)
			
		# Enhanced pulsing aura for the vessel
		var glow: Polygon2D = ring_data.get("glow")
		if is_instance_valid(glow):
			glow.color = Color(vibe_color, 0.0)
			# Kill previous aura tweens if they exist
			var old_tweens = glow.get_tree().get_processed_tweens().filter(func(t): return t.is_valid() and t.get_meta("vessel_aura", false))
			for t in old_tweens: t.kill()
			
			var glow_tween = glow.create_tween().set_loops()
			glow_tween.set_meta("vessel_aura", true)
			var duration: float = 1.2 / pulse_speed
			glow_tween.tween_property(glow, "color:a", aura_alpha, duration).set_trans(Tween.TRANS_SINE)
			glow_tween.tween_property(glow, "color:a", aura_alpha * 0.4, duration).set_trans(Tween.TRANS_SINE)


func _make_anomaly_sigil_ring(radius: float, color: Color, width: float, jitter: float) -> Line2D:
	var line := Line2D.new()
	line.default_color = color
	line.width = width
	line.closed = true
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var points: PackedVector2Array = PackedVector2Array()
	var sides := 64
	for i in range(sides):
		var a: float = (float(i) / float(sides)) * TAU
		# Multi-octave jitter for an organic, sketched feel
		var noise: float = sin(float(i) * 2.31) * jitter
		noise += cos(float(i) * 0.84) * (jitter * 0.5)
		if i % 8 == 0:
			noise -= jitter * 1.8 # Deeper notches
		
		points.append(Vector2(cos(a), sin(a)) * (radius + noise))
	line.points = points
	return line


func _make_disc_polygon(radius: float, color: Color, jitter: float = 0.0) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	var points: PackedVector2Array = PackedVector2Array()
	var sides := 48
	for i in range(sides):
		var a: float = (float(i) / float(sides)) * TAU
		var noise := randf_range(-jitter, jitter) if jitter > 0.0 else 0.0
		points.append(Vector2(cos(a), sin(a)) * (radius + noise))
	poly.polygon = points
	return poly


func _get_threat_marker_key(threat: Node) -> int:
	if threat == null or not is_instance_valid(threat):
		return -1
	var enemy_id: int = int(threat.get("enemy_id")) if "enemy_id" in threat else -1
	return enemy_id if enemy_id >= 0 else int(threat.get_instance_id())


func _is_valid_grave_threat(threat: Node) -> bool:
	if threat == null or not is_instance_valid(threat):
		return false
	if bool(threat.get("is_resolved")):
		return false
	if "is_reflected" in threat and bool(threat.get("is_reflected")):
		return false
	if threat.has_method("time_until_hit_zone"):
		return float(threat.call("time_until_hit_zone")) >= 0.0
	return true


func _build_grave_threat_data(threat: Node, player_pos: Vector2) -> Dictionary:
	var threat_node: Node2D = threat as Node2D
	var threat_pos: Vector2 = threat_node.global_position if threat_node != null else player_pos
	var eta: float = INF
	var has_eta: bool = false
	if threat.has_method("time_until_hit_zone"):
		eta = float(threat.call("time_until_hit_zone"))
		has_eta = eta >= 0.0
	var distance_sq: float = threat_pos.distance_squared_to(player_pos)
	return {
		"node": threat,
		"key": _get_threat_marker_key(threat),
		"lane": int(threat.get("lane")) if "lane" in threat else -1,
		"eta": eta,
		"has_eta": has_eta,
		"distance_sq": distance_sq,
		"stable_id": _get_threat_marker_key(threat)
	}


func _find_primary_grave_threat(zone_manager: Node, player_pos: Vector2) -> Dictionary:
	if zone_manager == null or not is_instance_valid(zone_manager):
		_primary_grave_threat_key = -1
		return {}
	if not zone_manager.has_method("get_all_active_projectiles"):
		_primary_grave_threat_key = -1
		return {}

	var active_threats: Array = zone_manager.call("get_all_active_projectiles")
	var current_data: Dictionary = {}
	var candidates: Array[Dictionary] = []
	for threat_variant in active_threats:
		var threat: Node = threat_variant as Node
		if not _is_valid_grave_threat(threat):
			continue
		var data: Dictionary = _build_grave_threat_data(threat, player_pos)
		if int(data.get("key", -1)) == _primary_grave_threat_key:
			current_data = data
		candidates.append(data)

	if not current_data.is_empty():
		return current_data
	if candidates.is_empty():
		_primary_grave_threat_key = -1
		return {}

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_has_eta: bool = bool(a.get("has_eta", false))
		var b_has_eta: bool = bool(b.get("has_eta", false))
		if a_has_eta != b_has_eta:
			return a_has_eta
		if a_has_eta:
			var eta_a: float = float(a.get("eta", INF))
			var eta_b: float = float(b.get("eta", INF))
			if not is_equal_approx(eta_a, eta_b):
				return eta_a < eta_b
		var dist_a: float = float(a.get("distance_sq", INF))
		var dist_b: float = float(b.get("distance_sq", INF))
		if not is_equal_approx(dist_a, dist_b):
			return dist_a < dist_b
		return int(a.get("stable_id", 999999999)) < int(b.get("stable_id", 999999999))
	)
	var selected: Dictionary = candidates[0]
	_primary_grave_threat_key = int(selected.get("key", -1))
	return selected


func update_timing_ring_proximity(
	active_encounter: Dictionary,
	zone_manager: Node,
	player_combat: Node2D,
	song_conductor: Node,
	timing_rings_cache: Array[Dictionary],
	ring_highlight_timers: Array[float],
	surge_window_timer: float,
	surge_window_tendency: String,
	delta: float
) -> void:
	if timing_rings_cache.is_empty() or player_combat == null:
		return

	var biome: Dictionary = active_encounter.get("biome", {})
	var ring_palette: Dictionary = UI_STYLE.get_combat_ring_palette()
	var base_active: Color = biome.get("ring_active_color", ring_palette.get("active", Color(1.0, 0.95, 0.55, 1.0)))
	
	# Sovereign Pulse Blend: Prioritize player color but keep biome undertones
	var active_color: Color = base_active.lerp(_vessel_vibe_color, 0.65).lightened(0.22)
	active_color.a = 1.0

	var cache: Dictionary = timing_rings_cache[0]
	var root: Node2D = cache["root"]
	var receiver_fill: Polygon2D = cache["fill"]
	var perfect_ring: Line2D = cache["perfect"]
	var good_ring: Line2D = cache.get("outer", null) as Line2D
	var scribble_ring: Line2D = root.get_node_or_null("Scribble")

	# 1. CORE SIGIL: Heartbeat and Follow
	root.position = root.position.lerp(player_combat.global_position, SIGIL_FOLLOW_LERP * (delta * 60.0))
	
	var beat_pulse: float = 0.0
	if song_conductor != null and is_instance_valid(song_conductor) and song_conductor.is_beat_active():
		var bp: float = song_conductor.get_beat_phase()
		if bp < 0.18: beat_pulse = (1.0 - bp / 0.18) * 0.15
	
	perfect_ring.width = 3.0 + beat_pulse * 3.4
	if good_ring:
		good_ring.width = 1.8 + beat_pulse * 2.2
		good_ring.default_color = Color(active_color, 0.45 + beat_pulse * 1.8)
	receiver_fill.color.a = 0.07 + beat_pulse * 0.16
	if scribble_ring:
		scribble_ring.width = 1.0 + beat_pulse * 6.5
		scribble_ring.rotation += delta * 0.8 # Slow erratic spin

	# 2. GRAVE SHARDS & GHOST THREADS:
	# Grave/Splinter visuals are incoming threat truth only.
	# Glow/Ghost threads remain player lock-on truth only.
	var primary_target: Dictionary = {}
	primary_target = player_combat.get_primary_action_target()
	var attack_lock_targets: Array = []
	attack_lock_targets = player_combat.get_attack_lock_targets()
	var player_pos: Vector2 = player_combat.global_position
	var primary_grave_threat: Dictionary = _find_primary_grave_threat(zone_manager, player_pos)
	var primary_grave_threat_node: Node = primary_grave_threat.get("node", null) as Node
	var primary_grave_threat_lane: int = int(primary_grave_threat.get("lane", -1))
	var primary_grave_threat_key: int = int(primary_grave_threat.get("key", -1))

	for i in range(zone_manager.THREAT_COUNT if zone_manager else 8):
		var grave_node: Node2D = root.get_parent().get_node_or_null("GraveRing_%d" % i)
		var thread_node: Line2D = root.get_parent().get_node_or_null("GhostThread_%d" % i)
		var glow_node: Line2D = root.get_parent().get_node_or_null("GlowThread_%d" % i)
		
		# Only the global primary incoming threat gets a Grave/Splinter marker.
		var proj: Node = primary_grave_threat_node if i == primary_grave_threat_lane else null
		var is_threat: bool = (
			proj != null
			and _get_threat_marker_key(proj) == primary_grave_threat_key
			and _is_valid_grave_threat(proj)
		)
		
		var lock_target: Dictionary = {}
		if i < attack_lock_targets.size():
			lock_target = Dictionary(attack_lock_targets[i])
		var has_lock_target: bool = not lock_target.is_empty()
		var is_singular_target: bool = has_lock_target and bool(lock_target.get("is_primary", false))
		var primary_precision: float = float(lock_target.get("precision", primary_target.get("precision", 0.0)))
		
		var threat_dir: Vector2 = Vector2.ZERO
		var threat_pos: Vector2 = Vector2.ZERO
		var threat_progress: float = 0.0
		if is_threat:
			var threat_node: Node2D = proj as Node2D
			threat_pos = threat_node.global_position if threat_node != null else player_pos
			threat_progress = float(proj.get("progress"))
			threat_dir = threat_pos - player_pos
			if threat_dir.length_squared() < 0.001:
				var sector_angle: float = (float(i) / float(zone_manager.THREAT_COUNT if zone_manager else 8)) * TAU - PI / 2.0
				threat_dir = Vector2(cos(sector_angle), sin(sector_angle))
			else:
				threat_dir = threat_dir.normalized()
		
		if not is_threat:
			if grave_node: grave_node.visible = false
		elif grave_node:
			grave_node.visible = true
		
		# MAPPING TRUTH: Intercardinal vs Cardinal weights
		var is_intercardinal: bool = (i % 2 != 0)
		
		# Position Grave Shard from incoming threat only.
		if is_threat and grave_node:
			var threat_color: Color = Color(1.0, 0.45, 0.2, 1.0)
			var threat_fill_color: Color = Color(0.9, 0.1, 0.1, 1.0)
			var ring_radius: float = 110.0 if not is_intercardinal else 102.0
			grave_node.position = player_pos + threat_dir * ring_radius
			grave_node.rotation = threat_dir.angle()
			
			var marrow: Polygon2D = grave_node.get_node_or_null("Marrow")
			if marrow:
				marrow.visible = false
				marrow.color.a = 0.0
			var alpha_base: float = 0.62 + beat_pulse * 0.22
			
			var urgency_scale: float = 1.0 + clampf((threat_progress - 0.6) / 0.4, 0.0, 1.0) * 0.82
			
			# Handle Splinter cluster
			for j in range(3):
				var splinter: Polygon2D = grave_node.get_node_or_null("Splinter_%d" % j)
				if splinter:
					splinter.color = Color(threat_fill_color, alpha_base * 0.55)
					
					# Near-impact emphasis: single smooth pulse (avoid high-frequency flicker).
					if urgency_scale > 1.65:
						var pulse_t: float = Time.get_ticks_msec() * 0.0045
						splinter.color.a *= 0.82 + 0.18 * sin(pulse_t)
					
					var outline: Line2D = splinter.get_node_or_null("Outline")
					if outline:
						outline.default_color = threat_color
						outline.default_color.a = alpha_base
						outline.width = 1.2 + beat_pulse * 0.9
					
					# Stable splinter drift: no random per-frame retargeting or glitch offset.
					var base_pos: Vector2 = splinter.get_meta("base_pos", Vector2.ZERO)
					var time_sec: float = Time.get_ticks_msec() * 0.001
					var drift_angle: float = time_sec * 0.55 + float(j) * 2.1
					var drift: Vector2 = Vector2(cos(drift_angle), sin(drift_angle)) * 1.15
					splinter.position = base_pos + drift
					
					# Intercardinal shards are "sharper" (thinner)
					var shard_scale: float = urgency_scale * 0.62 + beat_pulse * 0.10
					splinter.scale = Vector2(shard_scale * 1.2, shard_scale * 0.6) if is_intercardinal else Vector2(shard_scale, shard_scale)
					
			grave_node.scale = Vector2.ONE * (0.95 + beat_pulse * 0.12)
					
		# Update Predatory Tether (Dual-Layer Electric Pulse)
		if thread_node and glow_node:
			var tether_visible: bool = has_lock_target
			
			if not tether_visible:
				thread_node.default_color.a = 0.0
				glow_node.default_color.a = 0.0
			else:
				var target_pos: Vector2 = Vector2(lock_target.get("pos", player_pos))
				var dir_to_target: Vector2 = target_pos - player_pos
				if dir_to_target.length_squared() < 0.001:
					dir_to_target = Vector2.RIGHT
				else:
					dir_to_target = dir_to_target.normalized()
				var target_color: Color = Color(0.2, 0.85, 1.0, 1.0)
				var glow_color: Color = Color(0.6, 0.1, 0.9, 1.0)
				var lock_mult: float = clampf(primary_precision / 1.65, 0.72, 1.18) if is_singular_target else 1.0
				var urgency_mult: float = 1.2 * lock_mult
				var target_alpha_mult: float = 1.0 if is_singular_target else 0.6
				
				var thread_alpha: float = (0.45 + beat_pulse * 0.4) * urgency_mult * target_alpha_mult
				var glow_alpha: float = (0.22 + beat_pulse * 0.45) * urgency_mult * target_alpha_mult
				
				thread_node.default_color = Color(target_color, thread_alpha)
				glow_node.default_color = Color(glow_color, glow_alpha)
				
				thread_node.width = (1.4 + beat_pulse * 1.5) * urgency_mult * (1.0 if not is_intercardinal else 0.75)
				glow_node.width = (4.5 + beat_pulse * 5.0) * urgency_mult * (1.0 if not is_intercardinal else 0.75)
				
				# GENERATE NERVE POINTS (Electric Crackle)
				var start := player_pos + dir_to_target * 18.0
				var end := target_pos - dir_to_target * 24.0
				var pts := PackedVector2Array()
				var segments := 8 if is_singular_target else 5
				for j in range(segments + 1):
					var t_lerp: float = float(j) / float(segments)
					var p_base := start.lerp(end, t_lerp)
					if j > 0 and j < segments:
						# Progress-based jitter amplification
						var jitter_amount: float = (5.0 + beat_pulse * 24.0) * urgency_mult
						if is_intercardinal: jitter_amount *= 0.7 # Smoother intercardinal tethers
						var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * jitter_amount
						pts.append(p_base + offset)
					else:
						pts.append(p_base)
				
				thread_node.points = pts
				glow_node.points = pts


func build_arena_visuals(
	host: Node2D,
	active_encounter: Dictionary,
	zone_manager: Node,
	player_combat: Node2D,
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

	for lane in range(zone_manager.THREAT_COUNT):
		var lane_group := Node2D.new()
		lane_group.name = "LaneGroup_%d" % lane
		lane_marker_container.add_child(lane_group)

		var lane_strip := TextureRect.new()
		lane_strip.name = "Strip"
		lane_strip.size = Vector2(_lane_intercept_distance(zone_manager, lane, player_combat), COMBAT_FEEL_CONTENT.LANE_BAND_HEIGHT)
		lane_strip.position = _radial_lane_strip_position(zone_manager, lane, lane_strip.size, player_combat)
		lane_strip.rotation = _lane_direction(zone_manager, lane, player_combat).angle()
		lane_strip.pivot_offset = lane_strip.size * 0.5
		lane_strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lane_strip.stretch_mode = TextureRect.STRETCH_SCALE

		var ribbon_grad := Gradient.new()
		# Keep lane guidance legible without the old white slab look.
		ribbon_grad.colors = [
			Color(0.10, 0.12, 0.14, 0.10),
			Color(0.18, 0.22, 0.28, 0.24),
			Color(0.10, 0.12, 0.14, 0.10)
		]
		ribbon_grad.offsets = [0.0, 0.5, 1.0]
		
		var ribbon_tex := GradientTexture2D.new()
		ribbon_tex.gradient = ribbon_grad
		ribbon_tex.fill_from = Vector2(0.5, 0.0)
		ribbon_tex.fill_to = Vector2(0.5, 1.0)
		ribbon_tex.width = 16
		ribbon_tex.height = 32
		
		# Combine gradient with noise for "material seams"
		lane_strip.texture = ribbon_tex
		
		# SIGNAL: Lane Recoil Shudder logic
		# We're making the lane itself a living participant in Timing Truth.
		var shudder_mat := ShaderMaterial.new()
		var shudder_sh := Shader.new()
		shudder_sh.code = """
shader_type canvas_item;
uniform float shudder_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;

void fragment() {
	vec2 uv = UV;
	float t = TIME + time_offset;
	
	// Tactical Grid: Micro-Glitch Scanlines
	float scanline = sin(uv.x * 240.0 + t * 4.0) * 0.05;
	float drift = sin((uv.y * 12.0) + t * 25.0) * shudder_intensity * 0.06;
	
	uv.x += drift + (shudder_intensity * scanline);
	
	vec4 color = texture(TEXTURE, uv);
	
	// Scan Pulse: A vertical line sweeping the lane substrate
	float pulse = smoothstep(0.03, 0.0, abs(uv.x - fract(t * 0.35)));
	color.rgb = mix(color.rgb, color.rgb * 1.6, pulse * 0.25);
	
	// Flash only nudges value now; avoid full white bars during hits.
	color.rgb = mix(color.rgb, color.rgb * 1.25, shudder_intensity * 0.22);
	
	// Add micro-noise for grain
	float noise = fract(sin(dot(uv, vec2(12.9898, 78.233) * t)) * 43758.5453);
	color.rgb += noise * 0.03 * shudder_intensity;
	
	COLOR = color;
}
"""
		shudder_mat.shader = shudder_sh
		shudder_mat.set_shader_parameter("time_offset", randf() * 10.0)
		lane_strip.material = shudder_mat

		# PREMIUM: Procedural material rhythm to ground the lane substrate
		# Using shared noise texture to prevent redundant allocations
		var substrate_rhythm := TextureRect.new()
		substrate_rhythm.name = "SubstrateRhythm"
		substrate_rhythm.set_anchors_preset(Control.PRESET_FULL_RECT)
		substrate_rhythm.texture = _get_shared_noise_tex()
		substrate_rhythm.modulate = Color(0.45, 0.50, 0.56, 0.08)
		substrate_rhythm.stretch_mode = TextureRect.STRETCH_TILE
		lane_strip.add_child(substrate_rhythm)

		var tuned_lane_alpha: float = minf(COMBAT_FEEL_CONTENT.LANE_IDLE_ALPHA, 0.34)
		lane_strip.modulate = Color(lane_color.r, lane_color.g, lane_color.b, tuned_lane_alpha)
		lane_group.add_child(lane_strip)
		lane_strips[lane] = lane_strip

		var strip_top := ColorRect.new()
		strip_top.size = Vector2(lane_strip.size.x, 1.0)
		strip_top.color = Color(lane_color.r, lane_color.g, lane_color.b, 0.06)
		lane_strip.add_child(strip_top)

		var strip_bottom := ColorRect.new()
		strip_bottom.size = Vector2(lane_strip.size.x, 1.0)
		strip_bottom.position = Vector2(0.0, lane_strip.size.y - 1.0)
		strip_bottom.color = Color(lane_color.r, lane_color.g, lane_color.b, 0.06)
		lane_strip.add_child(strip_bottom)

		var focal_root := Node2D.new()
		focal_root.name = "FocalMarker_%d" % lane
		focal_root.position = _lane_hit_zone_pos(zone_manager, lane, player_combat)
		focal_root.rotation = _lane_direction(zone_manager, lane, player_combat).angle()
		lane_marker_container.add_child(focal_root)
		lane_hit_focus[lane] = focal_root

	for enemy_id in all_enemies_by_id.keys():
		var enemy: Dictionary = all_enemies_by_id[enemy_id]
		var lane_enemy: int = int(enemy.get("lane", 0))
		var marker_size_enemy: float = 22.0 if is_boss_encounter else 14.0
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
					zone_manager,
					texture_cache,
					player_combat
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
				zone_manager,
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
		var marker_root = marker_data.get("root")
		if is_instance_valid(marker_root):
			marker_root.visible = true
		var body_node = marker_data.get("body")
		if not is_instance_valid(body_node):
			continue
		var marker_body: ColorRect = body_node
		var enemy_phase: int = int(enemy_phase_by_id.get(enemy_id, -1))
		# Dynamic/song-escalated enemies may not have authored phase mapping (-1).
		# Treat them as active so enemy presence remains readable.
		if enemy_phase == current_phase_index or enemy_phase < 0:
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
	zone_manager: Node,
	texture_cache: Dictionary,
	player_node: Node2D = null
) -> Dictionary:
	var telegraph_profile: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
	var marker_half: float = marker_size * 0.5
	var grade_id: String = String(enemy.get("grade", "mature"))
	var grade_label_text: String = String(enemy.get("grade_label", grade_id.to_upper()))
	var enemy_type: String = String(enemy.get("type", ""))
	var tags_value: Variant = enemy.get("behaviour_tags", [])
	var is_tagged_elite: bool = tags_value is Array and (tags_value as Array).has("elite")
	var is_boss_marker: bool = marker_size >= 40.0 or enemy_type == "sovereign"
	var is_elite_marker: bool = is_boss_marker or grade_id == "alpha" or is_tagged_elite
	var marker_root := Node2D.new()
	marker_root.name = "Enemy_%d" % enemy_id
	marker_root.position = _lane_enemy_pos(zone_manager, lane, player_node)

	# GROUND SHADOW: Ground the smaller enemy marker
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.z_index = -1
	var s_pts := PackedVector2Array()
	var rx := marker_half * 0.8
	var ry := marker_half * 0.25
	for i in range(16):
		var a := (float(i) / 16.0) * TAU
		s_pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	shadow.polygon = s_pts
	shadow.color = Color(0.0, 0.0, 0.0, 0.22)
	shadow.position = Vector2(0, marker_half * 0.75)
	marker_root.add_child(shadow)

	var has_real_sprite: bool = false
	var species_id: String = String(enemy.get("species_id", ""))
	if not species_id.is_empty():
		var sprite_path: String = COMBAT_CONTENT.get_creature_art_path(species_id, "battlefield")
		if not sprite_path.is_empty():
			has_real_sprite = true

	var frame := ColorRect.new()
	frame.name = "Frame"
	frame.size = Vector2(marker_size + 4.0, marker_size + 4.0)
	frame.position = Vector2(-marker_half - 2.0, -marker_half - 2.0)
	frame.color = Color(0.0, 0.0, 0.0, 0.50)
	marker_root.add_child(frame)
	if is_elite_marker:
		frame.color = Color(0.18, 0.05, 0.03, 0.78)
	if has_real_sprite:
		frame.visible = false

	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(marker_size, marker_size)
	body.position = Vector2(-marker_half, -marker_half)
	body.color = base_color
	body.modulate = enemy.get("marker_modulate", Color(1.0, 1.0, 1.0, 1.0))
	marker_root.add_child(body)
	if has_real_sprite: body.visible = false

	var core := ColorRect.new()
	core.name = "Core"
	core.size = Vector2(marker_size - 12.0, marker_size - 12.0)
	core.position = Vector2(-(core.size.x * 0.5), -(core.size.y * 0.5))
	core.color = Color(0.0, 0.0, 0.0, 0.12)
	marker_root.add_child(core)
	if has_real_sprite: core.visible = false

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
	
	if has_real_sprite:
		accent.visible = false
		sigil.visible = false

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
				
				# Handle animation strips (assume square frames)
				var h_frames: int = clampi(int(float(tex.get_width()) / tex.get_height()), 1, 64)
				sprite.hframes = h_frames
				sprite.frame = 0
				
				var render: Dictionary = COMBAT_CONTENT.get_creature_combat_render(species_id)
				var marker_modulate: Color = Color(render.get("marker_modulate", base_color.darkened(0.4)))
				sprite.modulate = _tune_enemy_silhouette_color(marker_modulate, base_color)
				sprite.modulate.a = 1.0
				var silhouette_mult: float = 0.74
				
				# DYNAMIC GROWTH SCALING: Apply age-specific scale from content data
				var age_scales: Dictionary = render.get("age_scales", {})
				var base_scale: float = float(age_scales.get("adult", render.get("scale", 0.052)))
				
				sprite.scale = Vector2.ONE * base_scale * (marker_size / 42.0) * silhouette_mult
				sprite.position = Vector2(0.0, -2.0)
				marker_root.add_child(sprite)
				marker_root.move_child(sprite, 3)
				
				# Remove placeholder box visual if we have a real sprite
				body.visible = false
				core.visible = false
				frame.visible = false
				accent.visible = false
				sigil.visible = false

	var readout_width: float = marker_size + (28.0 if is_boss_marker else 18.0)
	var hp_bar_height: float = 7.0 if is_boss_marker else 5.0
	var hp_track := ColorRect.new()
	hp_track.name = "HpTrack"
	hp_track.size = Vector2(readout_width, hp_bar_height)
	hp_track.position = Vector2(-readout_width * 0.5, marker_half + 6.0)
	hp_track.color = Color(0.03, 0.02, 0.02, 0.88)
	marker_root.add_child(hp_track)

	var hp_fill := ColorRect.new()
	hp_fill.name = "HpFill"
	hp_fill.size = hp_track.size
	hp_fill.position = Vector2.ZERO
	hp_fill.color = Color(0.84, 0.21, 0.16, 0.96) if is_elite_marker else Color(0.68, 0.16, 0.18, 0.92)
	hp_track.add_child(hp_fill)

	var hp_label := Label.new()
	hp_label.name = "HpLabel"
	hp_label.text = "HP %.0f/%.0f" % [float(enemy.get("hp", 0.0)), float(enemy.get("hp", 0.0))]
	hp_label.position = Vector2(-readout_width * 0.5, marker_half + 10.0)
	hp_label.size = Vector2(readout_width, 16.0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	apply_text_role(hp_label, "hud_meta", HORIZONTAL_ALIGNMENT_CENTER)
	hp_label.add_theme_font_size_override("font_size", 11 if is_boss_marker else 9)
	hp_label.add_theme_constant_override("outline_size", 2)
	marker_root.add_child(hp_label)

	var threat_label := Label.new()
	threat_label.name = "ThreatLabel"
	threat_label.text = grade_label_text
	threat_label.position = Vector2(-readout_width * 0.5, -marker_half - (20.0 if is_boss_marker else 16.0))
	threat_label.size = Vector2(readout_width, 17.0)
	threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	threat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	apply_text_role(threat_label, "hud_meta", HORIZONTAL_ALIGNMENT_CENTER)
	threat_label.add_theme_font_size_override("font_size", 12 if is_boss_marker else 10)
	threat_label.add_theme_constant_override("outline_size", 3)
	if is_elite_marker:
		threat_label.modulate = Color(1.0, 0.64, 0.34, 1.0)
	marker_root.add_child(threat_label)

	# --- MAW MARKER (v2.3.1.8) ---
	# Enemies that yield DNA/Rewards are marked with the MAW sigil.
	var creature_info: Dictionary = COMBAT_CONTENT.get_creature(species_id)
	var has_maw: bool = float(creature_info.get("dna_threshold", 0.0)) > 0.0
	if has_maw:
		var maw_label := Label.new()
		maw_label.name = "MawLabel"
		maw_label.text = "MAW"
		# Positioned above the threat label
		maw_label.position = Vector2(-readout_width * 0.5, -marker_half - (38.0 if is_boss_marker else 32.0))
		maw_label.size = Vector2(readout_width, 17.0)
		maw_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		maw_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		apply_text_role(maw_label, "hud_title", HORIZONTAL_ALIGNMENT_CENTER)
		maw_label.modulate = Color(1.0, 0.2, 0.15, 0.95) # Intense Maw Red
		maw_label.add_theme_font_size_override("font_size", 13 if is_boss_marker else 11)
		maw_label.add_theme_constant_override("outline_size", 4)
		maw_label.add_theme_color_override("font_outline_color", Color(0.4, 0.05, 0.05, 0.8))
		marker_root.add_child(maw_label)
		
		# Pulsate effect for high-urgency visibility
		var t := maw_label.create_tween().set_loops()
		t.tween_property(maw_label, "modulate:a", 0.45, 0.6)
		t.tween_property(maw_label, "modulate:a", 0.95, 0.4)

	return {
		"root": marker_root,
		"species_id": species_id,
		"body": body,
		"core": core,
		"edge": edge,
		"accent": accent,
		"sigil": sigil,
		"hp_track": hp_track,
		"hp_fill": hp_fill,
		"hp_label": hp_label,
		"threat_label": threat_label
	}


func _lane_enemy_pos(zone_manager: Node, lane: int, player_node: Node2D = null) -> Vector2:
	var baseline: Vector2 = Vector2.ZERO
	if zone_manager != null:
		var enemy_id: int = -1
		if zone_manager != null:
			var enemy_data: Variant = zone_manager.get_enemy(lane)
			if enemy_data is Dictionary:
				enemy_id = int(enemy_data.get("id", -1))
		if enemy_id >= 0:
			baseline = zone_manager.get_enemy_pos(enemy_id)
			return _apply_visual_rig_enemy_present_pos(lane, baseline, zone_manager)
	if zone_manager != null:
		baseline = zone_manager.get_threat_spawn_pos(lane)
		return _apply_visual_rig_enemy_present_pos(lane, baseline, zone_manager)
	
	var p_pos: Vector2 = player_node.position if player_node != null else _lane_player_pos(zone_manager)
	baseline = p_pos + _lane_direction_fallback(lane) * 260.0
	return _apply_visual_rig_enemy_present_pos(lane, baseline, zone_manager)


func _lane_hit_zone_pos(zone_manager: Node, lane: int, player_node: Node2D = null) -> Vector2:
	if zone_manager != null:
		return zone_manager.get_threat_hit_zone_pos(lane)
	
	var p_pos: Vector2 = player_node.position if player_node != null else _lane_player_pos(zone_manager)
	return p_pos + _lane_direction_fallback(lane) * 110.0


func _lane_player_pos(zone_manager: Node) -> Vector2:
	if zone_manager != null:
		return zone_manager.get_player_pos()
	return Vector2.ZERO


func _lane_direction(zone_manager: Node, lane: int, player_node: Node2D = null) -> Vector2:
	var p_pos: Vector2 = player_node.position if player_node != null else _lane_player_pos(zone_manager)
	var dir: Vector2 = _lane_hit_zone_pos(zone_manager, lane, player_node) - p_pos
	if dir.length_squared() < 1.0:
		return _lane_direction_fallback(lane)
	return dir.normalized()


func _lane_direction_fallback(lane: int) -> Vector2:
	# Fallback to the 8-directional mathematical layout if zone_manager is absent
	var threat_count: float = 8.0
	var angle: float = (float(lane) / threat_count) * TAU - PI/2.0
	return Vector2(cos(angle), sin(angle))


func _lane_intercept_distance(zone_manager: Node, lane: int, player_node: Node2D = null) -> float:
	return maxf(_lane_enemy_pos(zone_manager, lane, player_node).distance_to(_lane_hit_zone_pos(zone_manager, lane, player_node)), 1.0)


func _radial_lane_strip_position(zone_manager: Node, lane: int, strip_size: Vector2, player_node: Node2D = null) -> Vector2:
	var hit_zone: Vector2 = _lane_hit_zone_pos(zone_manager, lane, player_node)
	var enemy_pos: Vector2 = _lane_enemy_pos(zone_manager, lane, player_node)
	var midpoint: Vector2 = hit_zone.lerp(enemy_pos, 0.5)
	return midpoint - Vector2(strip_size.x * 0.5, strip_size.y * 0.5)


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
	zone_manager: Node
) -> void:
	for enemy_id in enemy_markers_by_id.keys():
		var marker_data: Dictionary = enemy_markers_by_id[enemy_id]
		var marker_root = marker_data.get("root")
		if not is_instance_valid(marker_root):
			continue
		
		var resolved_lane: int = _resolve_live_lane_for_enemy(zone_manager, enemy_id)
		
		# UPDATE POSITION: LaneManager gameplay truth + optional CombatVisualRig presentation anchors.
		if zone_manager != null:
			var baseline: Vector2 = zone_manager.get_enemy_pos(enemy_id)
			marker_root.position = _apply_visual_rig_enemy_present_pos(resolved_lane, baseline, zone_manager)

		# DYNAMIC FACING: All enemies face the Vessel (Player)
		if zone_manager != null:
			var player_pos: Vector2 = zone_manager.get_player_pos()
			var angle_to_player: float = (player_pos - marker_root.global_position).angle()
			marker_root.rotation = angle_to_player - PI/2 # Align sprite 'up' to player
		var enemy: Dictionary = all_enemies_by_id.get(enemy_id, {})
		var lane_for_threat: int = resolved_lane
		if lane_for_threat < 0:
			lane_for_threat = int(enemy.get("lane", -1))
		
		# For markers in orbit (no lane), we just show them as idle.
		# Threat visuals (pressure/imminent) only apply if they are in a lane and attacking.
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
		
		if lane_for_threat >= 0:
			var projectile = zone_manager.get_projectile(lane_for_threat)
			if projectile != null and not projectile.is_resolved and not projectile.is_reflected and int(projectile.enemy_id) == enemy_id:
				var telegraph_profile: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
				var warning_bias: float = max(float(telegraph_profile.get("warning_bias", 1.0)), 0.84)
				pressure = clamp(((projectile.progress - 0.70) / 0.30) * warning_bias, 0.0, 1.0)
				imminent = clamp((projectile.progress - 0.96) / 0.08, 0.0, 1.0)

		var telegraph_profile_base: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
		var threat_color: Color = Color(telegraph_profile_base.get("projectile_color", Color.WHITE))
		var accent_color: Color = Color(telegraph_profile_base.get("accent_color", threat_color.lightened(0.18)))
		var marker_color: Color = Color(telegraph_profile_base.get("marker_color", accent_color))
		edge.color = Color(threat_color.r, threat_color.g, threat_color.b, pressure * 0.12 + imminent * 0.24)
		accent.color = Color(marker_color.r, marker_color.g, marker_color.b, 0.18 + pressure * 0.30 + imminent * 0.14)
		sigil.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.22 + pressure * 0.34 + imminent * 0.18)
		core.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.08 + pressure * 0.08 + imminent * 0.06)


func _resolve_live_lane_for_enemy(zone_manager: Node, enemy_id: int) -> int:
	if zone_manager == null or not zone_manager != null:
		return -1
	var lane_count: int = int(zone_manager.get("THREAT_COUNT")) if "THREAT_COUNT" in zone_manager else 8
	for lane in range(lane_count):
		var enemy_v: Variant = zone_manager.get_enemy(lane)
		if not (enemy_v is Dictionary):
			continue
		var enemy: Dictionary = enemy_v
		if enemy.is_empty():
			continue
		if int(enemy.get("id", -1)) == enemy_id:
			return lane
	return -1


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
	set_shell_treatment(reward_panel, Color(0.09, 0.07, 0.08, 0.86), Color(0.26, 0.20, 0.18, 0.42))
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
	apply_text_role(reward_creature_tag_label, "caption_strong")
	reward_panel.add_child(reward_creature_tag_label)

	var reward_title_label := Label.new()
	reward_title_label.name = "RewardTitle"
	reward_title_label.position = Vector2(204.0, 40.0)
	reward_title_label.size = Vector2(250.0, 56.0)
	apply_text_role(reward_title_label, "heading")
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
	apply_text_role(reward_body_label, "body")
	reward_body_scroll.add_child(reward_body_label)

	var reward_bond_card := ColorRect.new()
	reward_bond_card.name = "RewardBondCard"
	reward_bond_card.position = Vector2(468.0, 54.0)
	reward_bond_card.size = Vector2(206.0, 244.0)
	set_shell_treatment(reward_bond_card, Color(0.09, 0.10, 0.09, 0.96), Color(0.24, 0.31, 0.25, 0.88))
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
	apply_text_role(reward_bond_label, "bond_heading")
	reward_bond_card.add_child(reward_bond_label)

	var reward_dna_label := Label.new()
	reward_dna_label.name = "RewardDNALabel"
	reward_dna_label.position = Vector2(18.0, 42.0)
	reward_dna_label.size = Vector2(168.0, 18.0)
	apply_text_role(reward_dna_label, "hud_meta")
	reward_bond_card.add_child(reward_dna_label)

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
	apply_text_role(reward_bond_effect_label, "body")
	reward_bond_effect_scroll.add_child(reward_bond_effect_label)

	var reward_eat_card := ColorRect.new()
	reward_eat_card.name = "RewardEatCard"
	reward_eat_card.position = Vector2(694.0, 54.0)
	reward_eat_card.size = Vector2(206.0, 244.0)
	set_shell_treatment(reward_eat_card, Color(0.11, 0.08, 0.07, 0.96), Color(0.36, 0.24, 0.20, 0.92))
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
	apply_text_role(reward_eat_label, "eat_heading")
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
	apply_text_role(reward_eat_effect_label, "body")
	reward_eat_effect_scroll.add_child(reward_eat_effect_label)

	var reward_quig_label := Label.new()
	reward_quig_label.name = "RewardQuig"
	reward_quig_label.position = Vector2(84.0, 316.0)
	reward_quig_label.size = Vector2(818.0, 32.0)
	apply_text_role(reward_quig_label, "hint")
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
	apply_text_role(reward_hint_label, "hint")
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
		"reward_dna_label": reward_dna_label,
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
	apply_text_role(live_reward_title_label, "subheading")
	live_reward_title_label.add_theme_font_size_override("font_size", 16)
	reward_body.add_child(live_reward_title_label)

	var live_reward_body_label := Label.new()
	live_reward_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_reward_body_label.custom_minimum_size = Vector2(0.0, 22.0)
	live_reward_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	apply_text_role(live_reward_body_label, "body")
	live_reward_body_label.add_theme_font_size_override("font_size", 13)
	reward_body.add_child(live_reward_body_label)

	var live_reward_dna_label := Label.new()
	live_reward_dna_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_reward_dna_label.custom_minimum_size = Vector2(0.0, 18.0)
	apply_text_role(live_reward_dna_label, "hud_meta")
	live_reward_dna_label.add_theme_font_size_override("font_size", 12)
	reward_body.add_child(live_reward_dna_label)

	var live_reward_hint_label := Label.new()
	live_reward_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_reward_hint_label.custom_minimum_size = Vector2(0.0, 18.0)
	apply_text_role(live_reward_hint_label, "hint")
	live_reward_hint_label.add_theme_font_size_override("font_size", 12)
	reward_body.add_child(live_reward_hint_label)

	return {
		"live_reward_shell": live_reward_shell,
		"live_reward_title_label": live_reward_title_label,
		"live_reward_body_label": live_reward_body_label,
		"live_reward_dna_label": live_reward_dna_label,
		"live_reward_hint_label": live_reward_hint_label
	}


func sync_compact_transient_hud_layout(
	hud_top_left_panel: Control,
	live_reward_shell: PanelContainer,
	performance_hud: Control
) -> void:
	enforce_top_left_panel_rect(hud_top_left_panel)
	if live_reward_shell != null and is_instance_valid(live_reward_shell):
		var vp: Vector2 = Vector2(1280, 720)
		if hud_top_left_panel != null and hud_top_left_panel.is_inside_tree():
			vp = hud_top_left_panel.get_viewport_rect().size
		else:
			vp = Vector2(DisplayServer.window_get_size())
			
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


func _build_strip_sprite(
	sprite_name: String,
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
		var cols: int = maxi(1, int(floor(float(src.get_width()) / float(frame_size.x))))
		var idx: int = maxi(0, frame_index)
		var x: int = (idx % cols) * frame_size.x
		var y: int = int(floor(float(idx) / float(cols))) * frame_size.y
		atlas.region = Rect2(Vector2(float(x), float(y)), Vector2(float(frame_size.x), float(frame_size.y)))
		tex = atlas

	var r := TextureRect.new()
	r.name = sprite_name
	r.texture = tex
	r.position = position
	r.size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _hud_attach_combat_panel_art(panel: Control, texture_path: String, region: Rect2) -> void:
	HUD_PANEL_ART.apply_panel_art(panel, texture_path, region, "Art", "Backing", Color(0.0, 0.0, 0.0, 0.0))


## Premium Menace — scales a subtle ember "interface wound" rim on HUD shells with combo pressure.
func update_hud_interface_wound_glow(top_left: Control, top_right: Control, combo_normalized: float) -> void:
	var t: float = clampf(combo_normalized, 0.0, 1.0)
	HUD_PANEL_ART.set_interface_wound_intensity(top_left, t)
	HUD_PANEL_ART.set_interface_wound_intensity(top_right, t)
