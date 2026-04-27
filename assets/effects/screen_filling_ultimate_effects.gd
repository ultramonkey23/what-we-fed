extends Node
class_name ScreenFillingUltimateEffects

# Screen-filling ultimate effects for maximum power fantasy impact
enum UltimateEffectType {
	WORLD_SHATTERING_EXPLOSION,    # Full-screen explosive energy
	REALITY_BENDING_TRANSFORMATION, # Screen-wide reality distortion
	COSMIC_POWER_SURGE,            # Universe-level energy cascade
	VOID_DOMINANCE                 # Screen-consuming void energy
}

@export var current_effect_type: UltimateEffectType = UltimateEffectType.WORLD_SHATTERING_EXPLOSION
@export var screen_coverage: float = 1.0 # Full screen coverage
@export var effect_duration: float = 4.0

# Screen-filling components
@onready var screen_canvas: ColorRect = $ScreenCanvas
@onready var effect_layers: Array[Node2D] = [$EffectLayer1, $EffectLayer2, $EffectLayer3]
@onready var distortion_shader: ShaderMaterial = $DistortionShader.material
@onready var post_process: ColorRect = $PostProcess

# Effect state
var is_effect_active: bool = false
var effect_timer: float = 0.0
var current_intensity: float = 0.0

func _ready():
	setup_screen_filling_canvas()

func setup_screen_filling_canvas():
	# Initialize full-screen canvas for effects
	if screen_canvas:
		screen_canvas.size = get_viewport().get_visible_rect().size
		screen_canvas.position = Vector2.ZERO
		screen_canvas.color = Color.TRANSPARENT
		screen_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if post_process:
		post_process.size = get_viewport().get_visible_rect().size
		post_process.position = Vector2.ZERO
		post_process.color = Color.TRANSPARENT

func trigger_screen_filling_effect(effect_type: UltimateEffectType, intensity: float = 1.0):
	if is_effect_active:
		return
	
	current_effect_type = effect_type
	current_intensity = intensity
	is_effect_active = true
	effect_timer = effect_duration
	
	match effect_type:
		UltimateEffectType.WORLD_SHATTERING_EXPLOSION:
			trigger_world_shattering_explosion()
		UltimateEffectType.REALITY_BENDING_TRANSFORMATION:
			trigger_reality_bending_transformation()
		UltimateEffectType.COSMIC_POWER_SURGE:
			trigger_cosmic_power_surge()
		UltimateEffectType.VOID_DOMINANCE:
			trigger_void_dominance()

func trigger_world_shattering_explosion():
	print("TRIGGERING WORLD-SHATTERING EXPLOSION - FULL SCREEN DOMINATION")
	
	# Create concentric explosion waves covering entire screen
	create_concentric_explosion_waves()
	
	# Screen-shattering visual distortion
	activate_screen_shattering()
	
	# Full-screen particle cascade
	create_screen_particle_cascade()
	
	# Screen color domination
	dominate_screen_with_explosion_colors()
	
	# World-shaking impact
	apply_world_shaking_impact()

func create_concentric_explosion_waves():
	# Multiple waves expanding from center to cover entire screen
	var center = get_viewport().get_visible_rect().size / 2.0
	var max_radius = max(center.x, center.y) * 1.5
	
	for i in range(8):
		var wave_delay = i * 0.15
		var wave_radius = max_radius * (1.0 - i * 0.1)
		
		await get_tree().create_timer(wave_delay).timeout
		create_explosion_wave(center, wave_radius, i + 1)

func create_explosion_wave(center: Vector2, radius: float, wave_number: int):
	var wave = GPUParticles2D.new()
	wave.position = center
	wave.amount = 200 * wave_number
	wave.lifetime = 2.0
	wave.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = radius * 0.8
	process_material.initial_velocity_max = radius * 1.2
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 2.0
	process_material.scale_max = 6.0
	process_material.color = Color.ORANGE_RED
	process_material.emission = Color.YELLOW
	
	wave.process_material = process_material
	
	get_tree().current_scene.add_child(wave)
	await get_tree().create_timer(2.0).timeout
	wave.queue_free()

func activate_screen_shattering():
	if distortion_shader:
		distortion_shader.set_shader_parameter("shatter_intensity", 0.0)
		distortion_shader.set_shader_parameter("crack_density", 100.0)
		distortion_shader.set_shader_parameter("time", 0.0)
	
	# Animate screen shattering effect
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("shatter_intensity", t)
	, 0.0, 1.0, 2.0)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("time", t)
	, 0.0, 4.0, 4.0)

func create_screen_particle_cascade():
	# Full-screen particle cascade
	for layer in effect_layers:
		if layer:
			create_layer_particle_cascade(layer)

func create_layer_particle_cascade(layer: Node2D):
	var cascade_particles = GPUParticles2D.new()
	cascade_particles.position = get_viewport().get_visible_rect().size / 2.0
	cascade_particles.amount = 1000
	cascade_particles.lifetime = 3.0
	cascade_particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 600.0
	process_material.initial_velocity_max = 1200.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 1.0
	process_material.scale_max = 4.0
	process_material.color = Color.ORANGE_RED
	process_material.emission = Color.WHITE
	
	cascade_particles.process_material = process_material
	
	layer.add_child(cascade_particles)
	await get_tree().create_timer(3.0).timeout
	cascade_particles.queue_free()

func dominate_screen_with_explosion_colors():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Screen color explosion sequence
	var colors = [Color.ORANGE_RED, Color.YELLOW, Color.WHITE, Color.TRANSPARENT]
	
	for i in range(colors.size()):
		var delay = i * 0.8
		tween.tween_delay(delay)
		tween.tween_property(screen_canvas, "color", colors[i], 0.4)
		tween.tween_property(screen_canvas, "modulate", Color.WHITE, 0.4)
	
	# Screen pulse effects
	for i in range(6):
		tween.tween_delay(i * 0.3)
		tween.tween_property(screen_canvas, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(screen_canvas, "scale", Vector2(1.0, 1.0), 0.2)

func apply_world_shaking_impact():
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		# Escalating screen shake
		var tween = create_tween()
		tween.tween_method(func(trauma): screen_shake.add_trauma(trauma), 0.3, 1.0, 2.0)

func trigger_reality_bending_transformation():
	print("TRIGGERING REALITY-BENDING TRANSFORMATION - SCREEN-WARPING POWER")
	
	# Reality distortion waves across entire screen
	create_reality_distortion_waves()
	
	# Screen-warping visual effects
	activate_screen_warping()
	
	# Transformation particle helix
	create_transformation_helix()
	
	# Reality color shifts
	shift_reality_colors()
	
	# Space-time distortion
	distort_space_time()

func create_reality_distortion_waves():
	# Waves of reality distortion covering screen
	var screen_size = get_viewport().get_visible_rect().size
	
	for i in range(6):
		var wave_delay = i * 0.4
		await get_tree().create_timer(wave_delay).timeout
		
		var distortion_wave = GPUParticles2D.new()
		distortion_wave.position = Vector2(screen_size.x / 2.0, screen_size.y * (i + 1) / 7.0)
		distortion_wave.amount = 300
		distortion_wave.lifetime = 2.5
		distortion_wave.emitting = true
		
		var process_material = ParticleProcessMaterial.new()
		process_material.direction = Vector3(1, 0, 0)
		process_material.spread = 180.0
		process_material.initial_velocity_min = 400.0
		process_material.initial_velocity_max = 800.0
		process_material.gravity = Vector3.ZERO
		process_material.scale_min = 2.0
		process_material.scale_max = 5.0
		process_material.color = Color.PURPLE
		process_material.emission = Color.CYAN
		
		distortion_wave.process_material = process_material
		
		get_tree().current_scene.add_child(distortion_wave)
		await get_tree().create_timer(2.5).timeout
		distortion_wave.queue_free()

func activate_screen_warping():
	if distortion_shader:
		distortion_shader.set_shader_parameter("warp_intensity", 0.0)
		distortion_shader.set_shader_parameter("wave_frequency", 10.0)
		distortion_shader.set_shader_parameter("time", 0.0)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("warp_intensity", t)
	, 0.0, 1.0, 3.0)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("time", t)
	, 0.0, 6.0, 6.0)

func create_transformation_helix():
	# Screen-spanning DNA helix effect
	var screen_size = get_viewport().get_visible_rect().size
	var center = screen_size / 2.0
	
	var helix = Line2D.new()
	helix.width = 8.0
	helix.default_color = Color.CYAN
	
	var points = []
	var helix_radius = min(screen_size.x, screen_size.y) * 0.4
	
	for i in range(200):
		var angle = (i / 200.0) * TAU * 4 # 4 rotations
		var height = (i / 200.0) * screen_size.y
		var x = center.x + cos(angle) * helix_radius
		var y = height
		points.append(Vector2(x, y))
	
	helix.points = points
	get_tree().current_scene.add_child(helix)
	
	# Animate helix
	var tween = create_tween()
	tween.tween_property(helix, "modulate", Color.TRANSPARENT, 4.0)
	tween.tween_callback(helix.queue_free)

func shift_reality_colors():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Reality color transformation sequence
	var reality_colors = [
		Color.PURPLE,    # Initial reality shift
		Color.MAGENTA,   # Deep transformation
		Color.CYAN,      # Reality reconstruction
		Color.WHITE,     # Reality stabilization
		Color.TRANSPARENT # Return to normal
	]
	
	for i in range(reality_colors.size()):
		var delay = i * 0.8
		tween.tween_delay(delay)
		tween.tween_property(screen_canvas, "color", reality_colors[i], 0.6)
		tween.tween_property(screen_canvas, "modulate", Color.WHITE, 0.6)

func distort_space_time():
	var time_freeze = get_tree().get_first_node_in_group("time_freeze")
	if time_freeze:
		time_freeze.activate(1.5) # Extended time freeze for reality transformation
	
	# Screen distortion effects
	var tween = create_tween()
	tween.set_parallel(true)
	
	for i in range(4):
		tween.tween_delay(i * 0.5)
		tween.tween_property(screen_canvas, "scale", Vector2(1.3, 1.3), 0.3)
		tween.tween_property(screen_canvas, "scale", Vector2(0.7, 0.7), 0.3)
		tween.tween_property(screen_canvas, "scale", Vector2(1.0, 1.0), 0.3)

func trigger_cosmic_power_surge():
	print("TRIGGERING COSMIC POWER SURGE - UNIVERSE-LEVEL ENERGY")
	
	# Cosmic energy waves from screen edges
	create_cosmic_energy_waves()
	
	# Universe-level visual effects
	activate_universe_effects()
	
	# Star field particle explosion
	create_star_field_explosion()
	
	# Cosmic color domination
	dominate_screen_with_cosmic_colors()
	
	# Universal tremor
	apply_universal_tremor()

func create_cosmic_energy_waves():
	var screen_size = get_viewport().get_visible_rect().size
	var edges = [
		Vector2(0, screen_size.y / 2.0),           # Left edge
		Vector2(screen_size.x, screen_size.y / 2.0), # Right edge
		Vector2(screen_size.x / 2.0, 0),           # Top edge
		Vector2(screen_size.x / 2.0, screen_size.y)  # Bottom edge
	]
	
	for i in range(edges.size()):
		await get_tree().create_timer(i * 0.3).timeout
		create_cosmic_wave_from_edge(edges[i])

func create_cosmic_wave_from_edge(edge_position: Vector2):
	var cosmic_wave = GPUParticles2D.new()
	cosmic_wave.position = edge_position
	cosmic_wave.amount = 400
	cosmic_wave.lifetime = 3.0
	cosmic_wave.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 500.0
	process_material.initial_velocity_max = 1000.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 1.5
	process_material.scale_max = 4.0
	process_material.color = Color.GOLD
	process_material.emission = Color.CYAN
	
	cosmic_wave.process_material = process_material
	
	get_tree().current_scene.add_child(cosmic_wave)
	await get_tree().create_timer(3.0).timeout
	cosmic_wave.queue_free()

func activate_universe_effects():
	if distortion_shader:
		distortion_shader.set_shader_parameter("cosmic_intensity", 0.0)
		distortion_shader.set_shader_parameter("star_density", 1000.0)
		distortion_shader.set_shader_parameter("time", 0.0)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("cosmic_intensity", t)
	, 0.0, 1.0, 3.0)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("time", t)
	, 0.0, 6.0, 6.0)

func create_star_field_explosion():
	var star_field = GPUParticles2D.new()
	star_field.position = get_viewport().get_visible_rect().size / 2.0
	star_field.amount = 2000
	star_field.lifetime = 4.0
	star_field.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 800.0
	process_material.initial_velocity_max = 1600.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 0.5
	process_material.scale_max = 3.0
	process_material.color = Color.GOLD
	process_material.emission = Color.WHITE
	
	star_field.process_material = process_material
	
	get_tree().current_scene.add_child(star_field)
	await get_tree().create_timer(4.0).timeout
	star_field.queue_free()

func dominate_screen_with_cosmic_colors():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Cosmic color sequence
	var cosmic_colors = [
		Color.GOLD,     # Initial cosmic energy
		Color.CYAN,     # Cosmic expansion
		Color.MAGENTA,  # Cosmic power
		Color.WHITE,    # Cosmic climax
		Color.TRANSPARENT # Return to normal
	]
	
	for i in range(cosmic_colors.size()):
		var delay = i * 0.8
		tween.tween_delay(delay)
		tween.tween_property(screen_canvas, "color", cosmic_colors[i], 0.6)
		tween.tween_property(screen_canvas, "modulate", Color.WHITE, 0.6)

func apply_universal_tremor():
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		# Universal tremor pattern
		var tween = create_tween()
		tween.tween_method(func(trauma): screen_shake.add_trauma(trauma), 0.4, 1.2, 3.0)

func trigger_void_dominance():
	print("TRIGGERING VOID DOMINANCE - SCREEN-CONSUMING POWER")
	
	# Void energy consuming screen from edges
	create_void_consumption()
	
	# Screen-consuming visual effects
	activate_void_consumption()
	
	# Void particle field
	create_void_particle_field()
	
	# Void color domination
	dominate_screen_with_void_colors()
	
	# Existential tremor
	apply_existential_tremor()

func create_void_consumption():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Void consumes screen from all edges simultaneously
	var void_waves = []
	for i in range(12):
		var angle = (i / 12.0) * TAU
		var edge_pos = Vector2(
			screen_size.x / 2.0 + cos(angle) * max(screen_size.x, screen_size.y),
			screen_size.y / 2.0 + sin(angle) * max(screen_size.x, screen_size.y)
		)
		void_waves.append(edge_pos)
	
	for i in range(void_waves.size()):
		await get_tree().create_timer(i * 0.1).timeout
		create_void_wave(void_waves[i])

func create_void_wave(start_position: Vector2):
	var void_wave = GPUParticles2D.new()
	void_wave.position = start_position
	void_wave.amount = 300
	void_wave.lifetime = 3.5
	void_wave.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 400.0
	process_material.initial_velocity_max = 800.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 2.0
	process_material.scale_max = 6.0
	process_material.color = Color.BLACK
	process_material.emission = Color.PURPLE
	
	void_wave.process_material = process_material
	
	get_tree().current_scene.add_child(void_wave)
	await get_tree().create_timer(3.5).timeout
	void_wave.queue_free()

func activate_void_consumption():
	if distortion_shader:
		distortion_shader.set_shader_parameter("void_intensity", 0.0)
		distortion_shader.set_shader_parameter("consumption_rate", 1.0)
		distortion_shader.set_shader_parameter("time", 0.0)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("void_intensity", t)
	, 0.0, 1.0, 3.5)
	
	tween.tween_method(func(t): 
		if distortion_shader:
			distortion_shader.set_shader_parameter("time", t)
	, 0.0, 7.0, 7.0)

func create_void_particle_field():
	var void_field = GPUParticles2D.new()
	void_field.position = get_viewport().get_visible_rect().size / 2.0
	void_field.amount = 1500
	void_field.lifetime = 4.0
	void_field.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 600.0
	process_material.initial_velocity_max = 1200.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 1.0
	process_material.scale_max = 5.0
	process_material.color = Color.BLACK
	process_material.emission = Color.PURPLE
	
	void_field.process_material = process_material
	
	get_tree().current_scene.add_child(void_field)
	await get_tree().create_timer(4.0).timeout
	void_field.queue_free()

func dominate_screen_with_void_colors():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Void color consumption sequence
	var void_colors = [
		Color.PURPLE,   # Initial void energy
		Color.BLACK,    # Void consumption
		Color.DARK_GRAY, # Void dominance
		Color.BLACK,    # Complete void
		Color.TRANSPARENT # Return to normal
	]
	
	for i in range(void_colors.size()):
		var delay = i * 0.8
		tween.tween_delay(delay)
		tween.tween_property(screen_canvas, "color", void_colors[i], 0.7)
		tween.tween_property(screen_canvas, "modulate", Color.WHITE, 0.7)

func apply_existential_tremor():
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		# Existential tremor - deeper than physical
		var tween = create_tween()
		tween.tween_method(func(trauma): screen_shake.add_trauma(trauma), 0.5, 1.5, 3.5)

func _process(delta):
	if is_effect_active:
		effect_timer -= delta
		if effect_timer <= 0:
			deactivate_screen_filling_effect()

func deactivate_screen_filling_effect():
	is_effect_active = false
	effect_timer = 0.0
	
	# Clean up all effects
	if screen_canvas:
		screen_canvas.color = Color.TRANSPARENT
		screen_canvas.modulate = Color.WHITE
		screen_canvas.scale = Vector2.ONE
	
	if distortion_shader:
		distortion_shader.set_shader_parameter("shatter_intensity", 0.0)
		distortion_shader.set_shader_parameter("warp_intensity", 0.0)
		distortion_shader.set_shader_parameter("cosmic_intensity", 0.0)
		distortion_shader.set_shader_parameter("void_intensity", 0.0)
	
	# Clear effect layers
	for layer in effect_layers:
		if layer:
			for child in layer.get_children():
				child.queue_free()
	
	print("SCREEN-FILLING EFFECT DEACTIVATED")

func get_effect_name() -> String:
	match current_effect_type:
		UltimateEffectType.WORLD_SHATTERING_EXPLOSION:
			return "World-Shattering Explosion"
		UltimateEffectType.REALITY_BENDING_TRANSFORMATION:
			return "Reality-Bending Transformation"
		UltimateEffectType.COSMIC_POWER_SURGE:
			return "Cosmic Power Surge"
		UltimateEffectType.VOID_DOMINANCE:
			return "Void Dominance"
		_:
			return "Unknown Screen-Filling Effect"
