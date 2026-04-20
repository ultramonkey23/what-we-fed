extends Node
class_name PowerFantasyEffectManager

# Central manager for all spectacular combat effects
@onready var light_attack_particles: GPUParticles2D = $LightAttackParticles
@onready var heavy_attack_particles: GPUParticles2D = $HeavyAttackParticles
@onready var perfect_attack_particles: GPUParticles2D = $PerfectAttackParticles
@onready var parry_particles: GPUParticles2D = $ParryParticles
@onready var perfect_parry_particles: GPUParticles2D = $PerfectParryParticles
@onready var ultimate_dominion_particles: GPUParticles2D = $UltimateDominionParticles
@onready var ultimate_ascension_particles: GPUParticles2D = $UltimateAscensionParticles

# Screen effects
@onready var screen_shake: Node = $ScreenShake
@onready var time_freeze: Node = $TimeFreezeEffect
@onready var color_grading: ColorRect = $ColorGrading

func trigger_light_attack(world_position: Vector2):
	light_attack_particles.trigger_effect(world_position, 1.0)
	screen_shake.add_trauma(0.1)

func trigger_heavy_attack(world_position: Vector2):
	heavy_attack_particles.trigger_effect(world_position, 1.0)
	screen_shake.add_trauma(0.3)
	
	# Add screen flash
	apply_screen_flash(Color.ORANGE_RED, 0.1)

func trigger_perfect_attack(world_position: Vector2):
	perfect_attack_particles.trigger_effect(world_position, 1.0)
	screen_shake.add_trauma(0.5)
	time_freeze.activate(0.2)
	
	# Add dramatic screen effects
	apply_screen_flash(Color.GOLD, 0.3)

func trigger_parry(world_position: Vector2):
	parry_particles.trigger_effect(world_position, 1.0)
	screen_shake.add_trauma(0.15)
	
	# Subtle time effect
	time_freeze.activate(0.1)

func trigger_perfect_parry(world_position: Vector2):
	perfect_parry_particles.trigger_effect(world_position, 1.0)
	screen_shake.add_trauma(0.4)
	time_freeze.activate(0.3)
	
	# Reality distortion effect
	apply_reality_distortion(Color.PURPLE, 0.4)

func trigger_ultimate_dominion(_world_position: Vector2):
	ultimate_dominion_particles.trigger_screen_filling_effect()
	screen_shake.add_trauma(0.8)
	time_freeze.activate(0.5)
	
	# World-breaking screen effects
	apply_screen_flash(Color.PURPLE, 0.6)
	apply_reality_distortion(Color.BLACK, 0.8)

func trigger_ultimate_ascension(_world_position: Vector2):
	ultimate_ascension_particles.trigger_screen_filling_effect()
	screen_shake.add_trauma(1.0)
	time_freeze.activate(1.0)
	
	# Transformation screen effects
	apply_transformation_effects()

func apply_screen_flash(color: Color, duration: float):
	var tween = create_tween()
	
	# Flash to white/color
	tween.parallel().tween_property(color_grading, "color", color, 0.1)
	tween.parallel().tween_property(color_grading, "modulate", Color.WHITE, 0.1)
	
	# Fade back to normal
	tween.tween_property(color_grading, "modulate", Color.TRANSPARENT, duration)
	tween.tween_property(color_grading, "color", Color.WHITE, 0.1)

func apply_reality_distortion(color: Color, _intensity: float):
	var tween = create_tween()
	
	# Distortion effect
	tween.parallel().tween_property(color_grading, "modulate", color, 0.2)
	tween.parallel().tween_property(color_grading, "self_modulate", color, 0.2)
	
	# Screen wave effect
	tween.tween_property(color_grading, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(color_grading, "scale", Vector2(1.0, 1.0), 0.3)

func apply_transformation_effects():
	var tween = create_tween()
	
	# Multiple color shifts for transformation
	var colors = [Color.MAGENTA, Color.GOLD, Color.CYAN, Color.WHITE]
	
	for i in range(colors.size()):
		tween.tween_property(color_grading, "modulate", colors[i], 0.2)
		tween.tween_property(color_grading, "modulate", Color.TRANSPARENT, 0.1)
	
	# Final transformation flash
	tween.tween_property(color_grading, "modulate", Color.WHITE, 0.3)
	tween.tween_property(color_grading, "modulate", Color.TRANSPARENT, 0.5)

# Performance optimization
func set_effect_quality(quality_level: int):
	match quality_level:
		0: # Low quality
			set_particle_amounts(0.5)
		1: # Medium quality  
			set_particle_amounts(0.75)
		2: # High quality
			set_particle_amounts(1.0)
		3: # Ultra quality
			set_particle_amounts(1.5)

func set_particle_amounts(multiplier: float):
	light_attack_particles.amount = int(60 * multiplier)
	heavy_attack_particles.amount = int(150 * multiplier)
	perfect_attack_particles.amount = int(300 * multiplier)
	parry_particles.amount = int(80 * multiplier)
	perfect_parry_particles.amount = int(120 * multiplier)
	ultimate_dominion_particles.amount = int(500 * multiplier)
	ultimate_ascension_particles.amount = int(800 * multiplier)
