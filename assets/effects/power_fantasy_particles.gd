extends GPUParticles2D
class_name PowerFantasyParticles

# Spectacular particle effects for power fantasy combat
enum EffectType {
	LIGHT_ATTACK,
	HEAVY_ATTACK,
	PERFECT_ATTACK,
	PARRY,
	PERFECT_PARRY,
	ULTIMATE_DOMINION,
	ULTIMATE_ASCENSION
}

@export var effect_type: EffectType = EffectType.LIGHT_ATTACK
@export var screen_coverage: float = 0.3 # Percentage of screen to cover

func _ready():
	setup_effect_type()

func setup_effect_type():
	match effect_type:
		EffectType.LIGHT_ATTACK:
			setup_light_attack()
		EffectType.HEAVY_ATTACK:
			setup_heavy_attack()
		EffectType.PERFECT_ATTACK:
			setup_perfect_attack()
		EffectType.PARRY:
			setup_parry()
		EffectType.PERFECT_PARRY:
			setup_perfect_parry()
		EffectType.ULTIMATE_DOMINION:
			setup_ultimate_dominion()
		EffectType.ULTIMATE_ASCENSION:
			setup_ultimate_ascension()

func setup_light_attack():
	# Sharp, clean, cyan-white energy particles
	amount = 60
	lifetime = 0.8
	explosiveness = 0.2
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 45.0
	particles_material.initial_velocity_min = 200.0
	particles_material.initial_velocity_max = 400.0
	particles_material.gravity = Vector3(0, -98, 0)
	particles_material.scale_min = 0.5
	particles_material.scale_max = 1.5
	particles_material.color = Color.CYAN
	particles_material.emission = Color.WHITE
	
	self.process_material = particles_material

func setup_heavy_attack():
	# Explosive, orange-red particles with screen dominance
	amount = 150
	lifetime = 1.2
	explosiveness = 0.4
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 90.0
	particles_material.initial_velocity_min = 300.0
	particles_material.initial_velocity_max = 600.0
	particles_material.gravity = Vector3(0, -196, 0)
	particles_material.scale_min = 1.0
	particles_material.scale_max = 3.0
	particles_material.color = Color.ORANGE_RED
	particles_material.emission = Color.YELLOW
	
	self.process_material = particles_material

func setup_perfect_attack():
	# Spectacular rainbow energy with screen dominance
	amount = 300
	lifetime = 1.5
	explosiveness = 0.6
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 120.0
	particles_material.initial_velocity_min = 400.0
	particles_material.initial_velocity_max = 800.0
	particles_material.gravity = Vector3(0, -98, 0)
	particles_material.scale_min = 1.5
	particles_material.scale_max = 4.0
	particles_material.color = Color.GOLD
	particles_material.emission = Color.MAGENTA
	
	self.process_material = particles_material

func setup_parry():
	# Blue-white time control particles
	amount = 80
	lifetime = 1.0
	explosiveness = 0.3
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 60.0
	particles_material.initial_velocity_min = 250.0
	particles_material.initial_velocity_max = 500.0
	particles_material.gravity = Vector3(0, -49, 0)
	particles_material.scale_min = 0.8
	particles_material.scale_max = 2.0
	particles_material.color = Color.DODGER_BLUE
	particles_material.emission = Color.WHITE
	
	self.process_material = particles_material

func setup_perfect_parry():
	# Reality-bending purple particles
	amount = 120
	lifetime = 1.8
	explosiveness = 0.5
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 180.0
	particles_material.initial_velocity_min = 350.0
	particles_material.initial_velocity_max = 700.0
	particles_material.gravity = Vector3(0, 0, 0) # No gravity for time freeze effect
	particles_material.scale_min = 1.0
	particles_material.scale_max = 3.5
	particles_material.color = Color.PURPLE
	particles_material.emission = Color.CYAN
	
	self.process_material = particles_material

func setup_ultimate_dominion():
	# World-breaking black-purple particles
	amount = 500
	lifetime = 2.5
	explosiveness = 0.8
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 360.0 # Full sphere
	particles_material.initial_velocity_min = 500.0
	particles_material.initial_velocity_max = 1000.0
	particles_material.gravity = Vector3(0, 0, 0)
	particles_material.scale_min = 2.0
	particles_material.scale_max = 6.0
	particles_material.color = Color.PURPLE
	particles_material.emission = Color.BLACK
	
	self.process_material = particles_material

func setup_ultimate_ascension():
	# Transformation DNA particles with screen filling
	amount = 800
	lifetime = 3.0
	explosiveness = 1.0
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 360.0
	particles_material.initial_velocity_min = 600.0
	particles_material.initial_velocity_max = 1200.0
	particles_material.gravity = Vector3(0, 0, 0)
	particles_material.scale_min = 3.0
	particles_material.scale_max = 8.0
	particles_material.color = Color.MAGENTA
	particles_material.emission = Color.GOLD
	
	self.process_material = particles_material

func trigger_effect(effect_position: Vector2, intensity: float = 1.0):
	global_position = effect_position
	
	# Scale particle count based on intensity
	amount = int(amount * intensity)
	
	# Adjust emission based on screen coverage
	var base_amount = amount
	amount = int(base_amount * (screen_coverage / 0.3)) # Scale from 30% base
	
	emitting = true
	
	# Auto-stop after lifetime
	await get_tree().create_timer(lifetime).timeout
	emitting = false

func trigger_screen_filling_effect():
	# Special method for ultimate abilities
	amount = int(amount * 2.0) # Double particles for screen filling
	emitting = true
	
	# Create screen shake effect
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		screen_shake.add_trauma(0.8)
	
	# Create time freeze effect
	var time_freeze = get_tree().get_first_node_in_group("time_freeze")
	if time_freeze:
		time_freeze.activate(0.5)
