extends Node
class_name EnvironmentalImpactSystem
const UI_STYLE = preload("res://systems/UIStyle.gd")

# World reaction system that responds to player's growing power
@export var damage_threshold: float = 0.1
@export var max_destruction_radius: float = 300.0

# Environmental components
@onready var terrain_deformation: Node2D = $TerrainDeformation
@onready var weather_effects: Node = $WeatherEffects
@onready var world_state: Node = $WorldState

# Power progression tracking
var current_power_level: float = 0.0
var environmental_damage: float = 0.0
var world_transformation_progress: float = 0.0

func _ready():
	setup_environmental_systems()

func setup_environmental_systems():
	# Initialize all environmental response systems
	if terrain_deformation:
		terrain_deformation.deformation_intensity = 0.0
	
	if weather_effects:
		weather_effects.storm_intensity = 0.0
	
	if world_state:
		world_state.transformation_level = 0

func register_power_impact(impact_position: Vector2, impact_power: float, impact_type: String):
	# Register a power impact on the environment
	current_power_level = impact_power
	
	# Calculate environmental damage based on power
	environmental_damage = min(impact_power * damage_threshold, 1.0)
	
	# Apply environmental effects based on impact type and power
	match impact_type:
		"light_attack":
			apply_light_environmental_damage(impact_position)
		"heavy_attack":
			apply_heavy_environmental_damage(impact_position)
		"perfect_attack":
			apply_perfect_environmental_damage(impact_position)
		"ultimate":
			apply_ultimate_environmental_damage(impact_position)
		"creature_support":
			apply_creature_environmental_damage(impact_position)
	
	# Update world transformation progress
	update_world_transformation()

func apply_light_environmental_damage(position: Vector2):
	# Small scorch marks and minor terrain damage
	var damage_radius = 30.0 * current_power_level
	
	if terrain_deformation:
		terrain_deformation.create_scorch_marks(position, damage_radius)
		terrain_deformation.add_cracks(position, damage_radius * 0.5)
	
	# Minor air disturbance
	if weather_effects:
		weather_effects.create_air_burst(position, damage_radius)

func apply_heavy_environmental_damage(position: Vector2):
	# Significant terrain damage and environmental effects
	var damage_radius = 80.0 * current_power_level
	
	if terrain_deformation:
		terrain_deformation.create_crater(position, damage_radius)
		terrain_deformation.add_fractures(position, damage_radius * 1.5)
		terrain_deformation.deform_terrain(position, damage_radius)
	
	# Weather disturbance
	if weather_effects:
		weather_effects.create_pressure_wave(position, damage_radius)
		weather_effects.intensify_local_storm(position, current_power_level)
	
	# Environmental particles
	create_destruction_particles(position, damage_radius, 50)

func apply_perfect_environmental_damage(position: Vector2):
	# Major environmental transformation
	var damage_radius = 150.0 * current_power_level
	
	if terrain_deformation:
		terrain_deformation.create_major_crater(position, damage_radius)
		terrain_deformation.terrain_melting(position, damage_radius * 0.8)
		terrain_deformation.reality_fractures(position, damage_radius * 1.2)
	
	# Significant weather effects
	if weather_effects:
		weather_effects.create_lightning_storm(position, damage_radius)
		weather_effects.atmospheric_disturbance(position, current_power_level)
	
	# World reaction effects
	trigger_world_reaction(position, damage_radius)
	
	# Major destruction particles
	create_destruction_particles(position, damage_radius, 150)

func apply_ultimate_environmental_damage(position: Vector2):
	# World-altering environmental cataclysm
	var damage_radius = max_destruction_radius * current_power_level
	
	if terrain_deformation:
		terrain_deformation.world_shattering_impact(position, damage_radius)
		terrain_deformation.reality_reshaping(position, damage_radius)
		terrain_deformation.permanent_terrain_change(position, damage_radius)
	
	# Cataclysmic weather effects
	if weather_effects:
		weather_effects.create_cataclysm(position, damage_radius)
		weather_effects.permanent_weather_change(current_power_level)
	
	# World transformation
	advance_world_transformation(damage_radius)
	
	# Screen-filling destruction particles
	create_destruction_particles(position, damage_radius, 500)

func apply_creature_environmental_damage(position: Vector2):
	# Creature-specific environmental effects
	var damage_radius = 40.0 * current_power_level
	
	if terrain_deformation:
		terrain_deformation.creature_terrain_scarring(position, damage_radius)
		terrain_deformation.bio_organic_growth(position, damage_radius * 0.6)
	
	# Creature weather effects
	if weather_effects:
		weather_effects.creature_aura_effects(position, damage_radius)
		weather_effects.bio_atmospheric_changes(position, current_power_level)

func create_destruction_particles(position: Vector2, radius: float, particle_count: int):
	var destruction_particles = GPUParticles2D.new()
	destruction_particles.position = position
	destruction_particles.amount = particle_count
	destruction_particles.lifetime = 3.0
	destruction_particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = radius * 2.0
	process_material.initial_velocity_max = radius * 4.0
	process_material.gravity = Vector3(0, -196, 0)
	process_material.scale_min = 0.5
	process_material.scale_max = 3.0
	process_material.color = UI_STYLE.get_manga_color("blood_ember")
	process_material.emission = UI_STYLE.get_manga_color("alert_gold")
	
	destruction_particles.process_material = process_material
	
	get_tree().current_scene.add_child(destruction_particles)
	await get_tree().create_timer(3.0).timeout
	destruction_particles.queue_free()

func trigger_world_reaction(position: Vector2, radius: float):
	# Environmental objects react to power
	var space_state = get_viewport().get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	query.shape = circle_shape
	query.transform = Transform2D(0, position)
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result.collider
		if collider.has_method("react_to_power"):
			collider.react_to_power(current_power_level, position)
		elif collider.has_method("take_environmental_damage"):
			collider.take_environmental_damage(environmental_damage)

func update_world_transformation():
	# Update overall world transformation progress
	world_transformation_progress = min(world_transformation_progress + environmental_damage * 0.01, 1.0)
	
	if world_state:
		world_state.update_transformation(world_transformation_progress)
	
	# Apply progressive world changes based on transformation level
	apply_progressive_world_changes()

func advance_world_transformation(radius: float):
	# Major leap in world transformation
	world_transformation_progress = min(world_transformation_progress + 0.2, 1.0)
	
	if world_state:
		world_state.major_transformation_event(radius)
	
	# Create world transformation effects
	create_world_transformation_effects(radius)

func apply_progressive_world_changes():
	# Apply environmental changes based on transformation progress
	var transformation_level = int(world_transformation_progress * 4) + 1
	
	match transformation_level:
		1:
			apply_stage_1_changes()
		2:
			apply_stage_2_changes()
		3:
			apply_stage_3_changes()
		4:
			apply_stage_4_changes()

func apply_stage_1_changes():
	# Early transformation: minor environmental changes
	if weather_effects:
		weather_effects.set_base_weather_intensity(0.2)
		weather_effects.add_permanent_wind_pattern()
	
	if terrain_deformation:
		terrain_deformation.set_permanent_deformation(0.1)

func apply_stage_2_changes():
	# Mid transformation: significant environmental changes
	if weather_effects:
		weather_effects.set_base_weather_intensity(0.5)
		weather_effects.add_storm_systems()
	
	if terrain_deformation:
		terrain_deformation.set_permanent_deformation(0.3)
		terrain_deformation.add_permanent_cracks()

func apply_stage_3_changes():
	# Advanced transformation: major environmental changes
	if weather_effects:
		weather_effects.set_base_weather_intensity(0.8)
		weather_effects.add_permanent_lightning()
	
	if terrain_deformation:
		terrain_deformation.set_permanent_deformation(0.6)
		terrain_deformation.add_permanent_craters()

func apply_stage_4_changes():
	# Ultimate transformation: world-altering changes
	if weather_effects:
		weather_effects.set_base_weather_intensity(1.0)
		weather_effects.permanent_weather_cataclysm()
	
	if terrain_deformation:
		terrain_deformation.set_permanent_deformation(1.0)
		terrain_deformation.permanent_terrain_reshaping()

func create_world_transformation_effects(_radius: float):
	# Spectacular world transformation visual effects
	var transform_particles = GPUParticles2D.new()
	transform_particles.position = get_viewport().get_visible_rect().size / 2.0
	transform_particles.amount = 800
	transform_particles.lifetime = 5.0
	transform_particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 400.0
	process_material.initial_velocity_max = 800.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 2.0
	process_material.scale_max = 6.0
	process_material.color = UI_STYLE.get_manga_color("mutation_magenta")
	process_material.emission = UI_STYLE.get_manga_color("bond_teal")
	
	transform_particles.process_material = process_material
	
	get_tree().current_scene.add_child(transform_particles)
	await get_tree().create_timer(5.0).timeout
	transform_particles.queue_free()
	
	# Screen-wide transformation effect
	var screen_effect = create_screen_transformation_effect()
	await get_tree().create_timer(3.0).timeout
	screen_effect.queue_free()

func create_screen_transformation_effect() -> ColorRect:
	var screen_effect = ColorRect.new()
	screen_effect.size = get_viewport().get_visible_rect().size
	screen_effect.position = Vector2.ZERO
	screen_effect.color = UI_STYLE.get_manga_color("deep_violet")
	screen_effect.modulate = Color(1, 1, 1, 0.7)
	
	get_tree().current_scene.add_child(screen_effect)
	
	var tween = create_tween()
	tween.tween_property(screen_effect, "modulate", Color.TRANSPARENT, 3.0)
	
	return screen_effect

func get_environmental_state() -> Dictionary:
	return {
		"power_level": current_power_level,
		"environmental_damage": environmental_damage,
		"transformation_progress": world_transformation_progress,
		"deformation_level": terrain_deformation.deformation_intensity if terrain_deformation else 0.0,
		"weather_intensity": weather_effects.storm_intensity if weather_effects else 0.0,
		"world_state": world_state.transformation_level if world_state else 0
	}

func reset_environmental_damage():
	# Reset for new combat encounter
	environmental_damage = 0.0
	current_power_level = 0.0
	
	# Don't reset world transformation - that's permanent

func get_destruction_radius() -> float:
	return max_destruction_radius * current_power_level

# Environmental query methods
func is_environment_damaged() -> bool:
	return environmental_damage > 0.1

func get_transformation_stage() -> int:
	return int(world_transformation_progress * 4) + 1

func should_trigger_cataclysm() -> bool:
	return world_transformation_progress > 0.75

func get_weather_intensity() -> float:
	return weather_effects.storm_intensity if weather_effects else 0.0

func get_terrain_deformation() -> float:
	return terrain_deformation.deformation_intensity if terrain_deformation else 0.0
