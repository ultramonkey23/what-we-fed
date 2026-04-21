extends Node
class_name UltimateAbilitiesSystem
const UI_STYLE = preload("res://systems/UIStyle.gd")

# World-breaking ultimate abilities for power fantasy
enum UltimateType {
	PREDATOR_DOMINION,    # Screen-filling energy domination
	MONSTER_ASCENSION    # Epic transformation sequence
}

@export var current_ultimate: UltimateType = UltimateType.PREDATOR_DOMINION
@export var ultimate_cooldown: float = 30.0
@export var ultimate_duration: float = 3.0

# Visual components
@onready var screen_overlay: ColorRect = $ScreenOverlay
@onready var world_particles: GPUParticles2D = $WorldParticles
@onready var reality_distortion: ShaderMaterial = $RealityDistortion.material
@onready var time_freeze: Node = $TimeFreezeEffect

# Ultimate state
var is_ultimate_active: bool = false
var ultimate_timer: float = 0.0
var cooldown_timer: float = 0.0

func _ready():
	setup_ultimate_effects()

func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if is_ultimate_active:
		ultimate_timer -= delta
		if ultimate_timer <= 0:
			deactivate_ultimate()

func setup_ultimate_effects():
	# Initialize screen overlay for world-breaking effects
	if screen_overlay:
		screen_overlay.color = Color.TRANSPARENT
		screen_overlay.size = get_viewport().get_visible_rect().size
		screen_overlay.position = Vector2.ZERO
	
	if world_particles:
		world_particles.emitting = false

func can_activate_ultimate() -> bool:
	return cooldown_timer <= 0 and not is_ultimate_active

func activate_ultimate(ultimate_type: UltimateType):
	if not can_activate_ultimate():
		return false
	
	current_ultimate = ultimate_type
	is_ultimate_active = true
	ultimate_timer = ultimate_duration
	
	match ultimate_type:
		UltimateType.PREDATOR_DOMINION:
			activate_predator_dominion()
		UltimateType.MONSTER_ASCENSION:
			activate_monster_ascension()
	
	return true

func activate_predator_dominion():
	# World-breaking energy domination
	print("ACTIVATING PREDATOR'S DOMINION - WORLD BREAKING POWER")
	
	# Screen-filling energy explosion
	create_world_energy_explosion()
	
	# Reality distortion effects
	activate_reality_distortion(UI_STYLE.get_manga_color("deep_violet"), 0.8)
	
	# Time manipulation
	time_freeze.activate(0.5)
	
	# Screen domination effects
	dominate_screen_with_power()
	
	# Environmental destruction
	cause_environmental_cataclysm()

func create_world_energy_explosion():
	if world_particles:
		world_particles.amount = 800
		world_particles.lifetime = 3.0
		world_particles.emitting = true
		
		# Create world-breaking particle pattern
		var process_material = ParticleProcessMaterial.new()
		process_material.direction = Vector3(0, 1, 0)
		process_material.spread = 360.0 # Full sphere explosion
		process_material.initial_velocity_min = 800.0
		process_material.initial_velocity_max = 1500.0
		process_material.gravity = Vector3.ZERO
		process_material.scale_min = 4.0
		process_material.scale_max = 12.0
		process_material.color = UI_STYLE.get_manga_color("mutation_magenta")
		process_material.emission = UI_STYLE.get_manga_color("ink_black")
		
		world_particles.process_material = process_material

func activate_reality_distortion(distortion_color: Color, intensity: float):
	if reality_distortion:
		reality_distortion.set_shader_parameter("distortion_color", distortion_color)
		reality_distortion.set_shader_parameter("distortion_intensity", intensity)
		reality_distortion.set_shader_parameter("time", 0.0)
	
	# Animate reality distortion
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_method(func(t): 
		if reality_distortion:
			reality_distortion.set_shader_parameter("time", t)
	, 0.0, 3.0, 3.0)
	
	tween.tween_property(screen_overlay, "modulate", distortion_color * intensity, 0.5)
	tween.tween_property(screen_overlay, "modulate", Color.TRANSPARENT, 2.5)

func dominate_screen_with_power():
	# Screen-filling power effects
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Screen shake escalation
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		tween.tween_method(func(trauma): screen_shake.add_trauma(trauma), 0.2, 1.0, 1.0)
	
	# Screen color domination
	tween.tween_property(screen_overlay, "color", UI_STYLE.get_manga_color("deep_violet"), 0.3)
	tween.tween_property(screen_overlay, "modulate", Color(1, 1, 1, 0.9), 0.3)
	
	# Screen pulse effects
	for i in range(3):
		tween.tween_property(screen_overlay, "scale", Vector2(1.1, 1.1), 0.2)
		tween.tween_property(screen_overlay, "scale", Vector2(1.0, 1.0), 0.2)

func cause_environmental_cataclysm():
	# World-altering environmental effects
	var environment = get_tree().get_first_node_in_group("environment")
	if environment:
		if environment.has_method("trigger_cataclysm"):
			environment.trigger_cataclysm()
	
	# Create screen-wide destruction effects
	create_destruction_waves()

func create_destruction_waves():
	# Multiple waves of destruction emanating from center
	var center = get_viewport().get_visible_rect().size / 2
	
	for i in range(5):
		var wave_timer = i * 0.3
		await get_tree().create_timer(wave_timer).timeout
		
		create_destruction_wave(center, i + 1)

func create_destruction_wave(center: Vector2, wave_number: int):
	var wave = GPUParticles2D.new()
	wave.position = center
	wave.amount = 100 * wave_number
	wave.lifetime = 2.0
	wave.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 400.0 * wave_number
	process_material.initial_velocity_max = 800.0 * wave_number
	process_material.color = UI_STYLE.get_manga_color("blood_ember")
	process_material.emission = UI_STYLE.get_manga_color("alert_gold")
	
	wave.process_material = process_material
	
	get_tree().current_scene.add_child(wave)
	await get_tree().create_timer(2.0).timeout
	wave.queue_free()

func activate_monster_ascension():
	# Epic transformation sequence
	print("ACTIVATING MONSTER ASCENSION - EPIC TRANSFORMATION")
	
	# Transformation DNA helix effects
	create_dna_helix_effect()
	
	# Reality-bending transformation
	activate_reality_distortion(UI_STYLE.get_manga_color("mutation_magenta"), 1.0)
	
	# Epic time freeze
	time_freeze.activate(1.0)
	
	# Transformation sequence
	play_transformation_sequence()
	
	# Final ascension reveal
	reveal_ultimate_form()

func create_dna_helix_effect():
	if world_particles:
		world_particles.amount = 1000
		world_particles.lifetime = 4.0
		world_particles.emitting = true
		
		# DNA helix particle pattern
		var process_material = ParticleProcessMaterial.new()
		process_material.direction = Vector3(0, 1, 0)
		process_material.spread = 360.0
		process_material.initial_velocity_min = 600.0
		process_material.initial_velocity_max = 1200.0
		process_material.gravity = Vector3.ZERO
		process_material.scale_min = 2.0
		process_material.scale_max = 8.0
		process_material.color = UI_STYLE.get_manga_color("mutation_magenta")
		process_material.emission = UI_STYLE.get_manga_color("bond_teal")
		
		world_particles.process_material = process_material
	
	# Create DNA helix visual
	create_dna_helix_visual()

func create_dna_helix_visual():
	var helix = Line2D.new()
	helix.width = 5.0
	helix.default_color = UI_STYLE.get_manga_color("bond_teal")
	
	# Create helix pattern
	var center = get_viewport().get_visible_rect().size / 2
	var radius = 200.0
	var points = []
	
	for i in range(100):
		var angle = (i / 100.0) * TAU * 3 # 3 rotations
		var height = (i / 100.0) * 400.0 - 200.0
		var x = center.x + cos(angle) * radius
		var y = center.y + height
		points.append(Vector2(x, y))
	
	helix.points = points
	get_tree().current_scene.add_child(helix)
	
	# Animate helix
	var tween = create_tween()
	tween.tween_property(helix, "modulate", Color.TRANSPARENT, 4.0)
	tween.tween_callback(helix.queue_free)

func play_transformation_sequence():
	# Multi-stage transformation with dramatic visual progression
	var stages = [
		{"color": UI_STYLE.get_manga_color("mutation_magenta"), "duration": 0.8, "effect": "Initial mutation"},
		{"color": UI_STYLE.get_manga_color("blood_ember"), "duration": 0.8, "effect": "Power surge"},
		{"color": UI_STYLE.get_manga_color("bond_teal"), "duration": 0.8, "effect": "Final transformation"},
		{"color": UI_STYLE.get_manga_color("paper"), "duration": 0.6, "effect": "Ascension complete"}
	]
	
	for stage in stages:
		await play_transformation_stage(stage)

func play_transformation_stage(stage: Dictionary):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Screen color transformation
	tween.tween_property(screen_overlay, "color", stage.color, 0.3)
	tween.tween_property(screen_overlay, "modulate", Color(1, 1, 1, 0.8), 0.3)
	
	# Screen pulse
	tween.tween_property(screen_overlay, "scale", Vector2(1.2, 1.2), 0.4)
	tween.tween_property(screen_overlay, "scale", Vector2(1.0, 1.0), 0.4)
	
	# Screen shake
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		screen_shake.add_trauma(0.6)
	
	await get_tree().create_timer(stage.duration).timeout

func reveal_ultimate_form():
	# Dramatic final transformation reveal
	var tween = create_tween()
	
	# Flash to white
	tween.tween_property(screen_overlay, "color", Color.WHITE, 0.2)
	tween.tween_property(screen_overlay, "modulate", Color.WHITE, 0.2)
	
	# Hold white flash
	await get_tree().create_timer(0.3).timeout
	
	# Fade to reveal ultimate form
	tween.tween_property(screen_overlay, "modulate", Color.TRANSPARENT, 1.0)
	
	# Create ultimate aura
	create_ultimate_aura()

func create_ultimate_aura():
	var aura = GPUParticles2D.new()
	aura.position = get_viewport().get_visible_rect().size / 2
	aura.amount = 600
	aura.lifetime = 5.0
	aura.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 200.0
	process_material.initial_velocity_max = 400.0
	process_material.gravity = Vector3(0, -98, 0)
	process_material.scale_min = 3.0
	process_material.scale_max = 8.0
	process_material.color = UI_STYLE.get_manga_color("alert_gold")
	process_material.emission = UI_STYLE.get_manga_color("paper")
	
	aura.process_material = process_material
	
	get_tree().current_scene.add_child(aura)
	await get_tree().create_timer(5.0).timeout
	aura.queue_free()

func deactivate_ultimate():
	is_ultimate_active = false
	ultimate_timer = 0.0
	cooldown_timer = ultimate_cooldown
	
	# Clean up effects
	if world_particles:
		world_particles.emitting = false
	
	if screen_overlay:
		screen_overlay.color = Color.TRANSPARENT
		screen_overlay.modulate = Color.WHITE
		screen_overlay.scale = Vector2.ONE
	
	if reality_distortion:
		reality_distortion.set_shader_parameter("distortion_intensity", 0.0)
	
	print("ULTIMATE DEACTIVATED - Cooldown started")

func get_ultimate_progress() -> float:
	if cooldown_timer <= 0:
		return 1.0
	return 1.0 - (cooldown_timer / ultimate_cooldown)

func get_ultimate_name() -> String:
	match current_ultimate:
		UltimateType.PREDATOR_DOMINION:
			return "Predator's Dominion"
		UltimateType.MONSTER_ASCENSION:
			return "Monster Ascension"
		_:
			return "Unknown Ultimate"

func get_ultimate_description() -> String:
	match current_ultimate:
		UltimateType.PREDATOR_DOMINION:
			return "World-breaking energy domination that shatters reality"
		UltimateType.MONSTER_ASCENSION:
			return "Epic transformation into ultimate monster form"
		_:
			return "Unknown ultimate ability"
