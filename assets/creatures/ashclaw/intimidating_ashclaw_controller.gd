extends Node
class_name IntimidatingAshclawController

# Intimidating Ashclaw evolution system for power fantasy
enum AshclawStage {
	BABY_DEADLY,    # 64x64, already dangerous
	TEEN_THREAT,    # 96x96, unstable aggression  
	ADULT_APEX      # 128x128, terrifying presence
}

@export var current_stage: AshclawStage = AshclawStage.BABY_DEADLY
@export var animated_sprite: AnimatedSprite2D
@export var ember_particles: GPUParticles2D
@export var intimidation_aura: GPUParticles2D

# Combat coordination with player
@export var coordination_cooldown: float = 2.0
@export var support_damage_multiplier: float = 1.0

# Visual intimidation factors
@export var screen_shake_intensity: float = 0.2
@export var environmental_damage: float = 0.1

func _ready():
	setup_ashclaw_stage()
	play_idle_animation()

func setup_ashclaw_stage():
	match current_stage:
		AshclawStage.BABY_DEADLY:
			setup_baby_deadly()
		AshclawStage.TEEN_THREAT:
			setup_teen_threat()
		AshclawStage.ADULT_APEX:
			setup_adult_apex()

func setup_baby_deadly():
	# Baby: "Deadly Progeny" - already dangerous, no cuteness
	if animated_sprite:
		animated_sprite.sprite_frames = load_baby_frames()
		animated_sprite.speed_scale = 1.2
	
	if ember_particles:
		ember_particles.amount = 30
		ember_particles.lifetime = 1.0
	
	if intimidation_aura:
		intimidation_aura.amount = 20
		intimidation_aura.lifetime = 0.8
	
	support_damage_multiplier = 0.5
	screen_shake_intensity = 0.1
	environmental_damage = 0.05

func setup_teen_threat():
	# Teen: "Rising Threat" - unstable aggression, overgrown weapons
	if animated_sprite:
		animated_sprite.sprite_frames = load_teen_frames()
		animated_sprite.speed_scale = 1.0
	
	if ember_particles:
		ember_particles.amount = 60
		ember_particles.lifetime = 1.5
		# Unstable energy pattern
		ember_particles.process_material.set("emission_shape", 0) # EMISSION_SHAPE_SPHERE
	
	if intimidation_aura:
		intimidation_aura.amount = 45
		intimidation_aura.lifetime = 1.2
	
	support_damage_multiplier = 0.75
	screen_shake_intensity = 0.3
	environmental_damage = 0.15

func setup_adult_apex():
	# Adult: "Apex Dominator" - terrifying presence, world-shaking
	if animated_sprite:
		animated_sprite.sprite_frames = load_adult_frames()
		animated_sprite.speed_scale = 0.8
	
	if ember_particles:
		ember_particles.amount = 120
		ember_particles.lifetime = 2.0
		# Overwhelming ember field
		ember_particles.process_material.set("emission_shape", 0) # EMISSION_SHAPE_SPHERE
		ember_particles.process_material.set("emission_sphere_radius", 50.0)
	
	if intimidation_aura:
		intimidation_aura.amount = 80
		intimidation_aura.lifetime = 1.8
	
	support_damage_multiplier = 1.0
	screen_shake_intensity = 0.5
	environmental_damage = 0.3

func load_baby_frames() -> SpriteFrames:
	var frames = SpriteFrames.new()
	# Load baby frames (6 idle, 4 attack, 3 support)
	frames.add_animation("idle")
	frames.add_animation("attack")
	frames.add_animation("support")
	frames.add_animation("ultimate")
	
	# Set frame counts and durations
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 6.0) # 6 frames, 1.0s loop
	
	frames.set_animation_loop("attack", false)
	frames.set_animation_speed("attack", 10.0) # 4 frames, 0.4s total
	
	frames.set_animation_loop("support", false)
	frames.set_animation_speed("support", 6.0) # 3 frames, 0.5s total
	
	return frames

func load_teen_frames() -> SpriteFrames:
	var frames = SpriteFrames.new()
	# Load teen frames (8 idle, 6 attack, 4 support)
	frames.add_animation("idle")
	frames.add_animation("attack")
	frames.add_animation("support")
	frames.add_animation("ultimate")
	
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 8.0) # 8 frames, 1.0s loop
	
	frames.set_animation_loop("attack", false)
	frames.set_animation_speed("attack", 12.0) # 6 frames, 0.5s total
	
	frames.set_animation_loop("support", false)
	frames.set_animation_speed("support", 8.0) # 4 frames, 0.5s total
	
	return frames

func load_adult_frames() -> SpriteFrames:
	var frames = SpriteFrames.new()
	# Load adult frames (10 idle, 8 attack, 4 support, 3 ultimate)
	frames.add_animation("idle")
	frames.add_animation("attack")
	frames.add_animation("support")
	frames.add_animation("ultimate")
	
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 10.0) # 10 frames, 1.0s loop
	
	frames.set_animation_loop("attack", false)
	frames.set_animation_speed("attack", 16.0) # 8 frames, 0.5s total
	
	frames.set_animation_loop("support", false)
	frames.set_animation_speed("support", 8.0) # 4 frames, 0.5s total
	
	frames.set_animation_loop("ultimate", false)
	frames.set_animation_speed("ultimate", 6.0) # 3 frames, 0.5s total
	
	return frames

func play_idle_animation():
	if animated_sprite:
		animated_sprite.play("idle")
		
		# Start ember effects
		if ember_particles:
			ember_particles.emitting = true
		
		# Start intimidation aura
		if intimidation_aura:
			intimidation_aura.emitting = true

func coordinated_attack(player_position: Vector2, target_position: Vector2):
	# Cool coordination with player
	if animated_sprite:
		animated_sprite.play("attack")
	
	# Visual coordination effects
	show_coordination_signal(player_position)
	
	# Wait for attack timing
	await animated_sprite.animation_finished
	
	# Execute attack with visual impact
	execute_support_strike(target_position)

func show_coordination_signal(player_position: Vector2):
	# Eye contact and energy sync
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		# Create visual connection between Ashclaw and player
		create_energy_link(player_position, position)
		
		# Both characters' energy fields pulse together
		pulse_energy_fields()

func pulse_energy_fields():
	if ember_particles:
		var original_amount = ember_particles.amount
		ember_particles.amount = original_amount * 2
		await get_tree().create_timer(0.3).timeout
		ember_particles.amount = original_amount

func create_energy_link(start_pos: Vector2, end_pos: Vector2):
	# Create visual energy connection between player and Ashclaw
	var energy_line = Line2D.new()
	energy_line.width = 3.0
	energy_line.default_color = Color.ORANGE_RED
	energy_line.add_point(start_pos)
	energy_line.add_point(end_pos)
	
	get_tree().current_scene.add_child(energy_line)
	
	# Animate energy line
	var tween = create_tween()
	tween.tween_property(energy_line, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(energy_line.queue_free)

func execute_support_strike(target_position: Vector2):
	# Spectacular support strike with screen impact
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		screen_shake.add_trauma(screen_shake_intensity)
	
	# Create ember explosion at target
	create_ember_explosion(target_position)
	
	# Apply environmental damage
	apply_environmental_damage(target_position)

func create_ember_explosion(position: Vector2):
	var explosion = GPUParticles2D.new()
	explosion.position = position
	explosion.amount = 40
	explosion.lifetime = 1.0
	explosion.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 200.0
	process_material.initial_velocity_max = 400.0
	process_material.color = Color.ORANGE_RED
	process_material.emission = Color.YELLOW
	
	explosion.process_material = process_material
	
	get_tree().current_scene.add_child(explosion)
	await get_tree().create_timer(1.0).timeout
	explosion.queue_free()

func apply_environmental_damage(position: Vector2):
	# Create environmental scorch marks and damage
	var damage_radius = 50.0 * environmental_damage
	
	# Find environmental objects in radius
	var space_state = get_world_2d(self).direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = damage_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, position)
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result.collider
		if collider.has_method("take_environmental_damage"):
			collider.take_environmental_damage(environmental_damage)

func evolve_to_stage(new_stage: AshclawStage):
	current_stage = new_stage
	setup_ashclaw_stage()
	
	# Play transformation animation
	play_transformation_sequence()

func play_transformation_sequence():
	# Spectacular evolution with screen effects
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		screen_shake.add_trauma(0.6)
	
	# Create transformation particles
	create_transformation_particles()
	
	# Flash screen with evolution color
	flash_evolution_color()
	
	# Update visual appearance
	await get_tree().create_timer(2.0).timeout
	play_idle_animation()

func create_transformation_particles():
	var transform_particles = GPUParticles2D.new()
	transform_particles.position = position
	transform_particles.amount = 100
	transform_particles.lifetime = 2.0
	transform_particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 300.0
	process_material.initial_velocity_max = 600.0
	process_material.color = Color.MAGENTA
	process_material.emission = Color.CYAN
	
	transform_particles.process_material = process_material
	
	get_tree().current_scene.add_child(transform_particles)
	await get_tree().create_timer(2.0).timeout
	transform_particles.queue_free()

func flash_evolution_color():
	var color_rect = ColorRect.new()
	color_rect.color = Color.MAGENTA
	color_rect.modulate = Color(1, 1, 1, 0.7)
	color_rect.size = get_viewport().get_visible_rect().size
	color_rect.position = Vector2.ZERO
	
	get_tree().current_scene.add_child(color_rect)
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate", Color.TRANSPARENT, 1.5)
	tween.tween_callback(color_rect.queue_free)

func get_intimidation_level() -> float:
	match current_stage:
		AshclawStage.BABY_DEADLY:
			return 0.3
		AshclawStage.TEEN_THREAT:
			return 0.6
		AshclawStage.ADULT_APEX:
			return 1.0
		_:
			return 0.0

func get_support_damage() -> float:
	return support_damage_multiplier

# Cool factor methods
func is_intimidating() -> bool:
	return true # All stages are intimidating

func get_threat_level() -> String:
	match current_stage:
		AshclawStage.BABY_DEADLY:
			return "Deadly Potential"
		AshclawStage.TEEN_THREAT:
			return "Growing Threat"
		AshclawStage.ADULT_APEX:
			return "Apex Predator"
		_:
			return "Unknown"
