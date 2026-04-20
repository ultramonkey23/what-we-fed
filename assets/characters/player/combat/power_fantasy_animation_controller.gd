extends Node
class_name PowerFantasyAnimationController

# Animation states for power fantasy character
enum AnimationState {
	IDLE,
	ATTACK_LIGHT,
	ATTACK_HEAVY,
	PARRY,
	PARRY_PERFECT,
	HURT,
	TRANSFORM
}

# Mutation stages affecting animation
enum MutationStage {
	AWAKENING,    # Stage 1: Cyan energy
	MUTATION,     # Stage 2: Purple energy  
	PREDATORY,    # Stage 3: Red energy
	APEX          # Stage 4: Black energy
}

@export var animation_player: AnimationPlayer
@export var sprite_2d: Sprite2D
@export var current_mutation_stage: MutationStage = MutationStage.AWAKENING

# Animation timing for cool factor
@export var idle_loop_duration: float = 1.2
@export var attack_duration: float = 0.4
@export var parry_duration: float = 0.5
@export var hurt_duration: float = 0.3

# Energy effect controllers
@export var energy_aura: GPUParticles2D
@export var energy_trail: GPUParticles2D
@export var impact_effects: GPUParticles2D

# Screen effects
@export var screen_shake: Node
@export var time_freeze: Node

func _ready():
	setup_mutation_effects()
	play_idle_animation()

func setup_mutation_effects():
	match current_mutation_stage:
		MutationStage.AWAKENING:
			setup_awning_energy()
		MutationStage.MUTATION:
			setup_mutation_energy()
		MutationStage.PREDATORY:
			setup_predatory_energy()
		MutationStage.APEX:
			setup_apex_energy()

func setup_awning_energy():
	# Cyan energy, controlled patterns
	if energy_aura:
		energy_aura.process_material.cyan_energy()
		energy_aura.amount = 50
		energy_aura.lifetime = 2.0

func setup_mutation_energy():
	# Purple energy, unstable patterns
	if energy_aura:
		energy_aura.process_material.purple_energy()
		energy_aura.amount = 80
		energy_aura.lifetime = 1.5

func setup_predatory_energy():
	# Red energy, aggressive patterns
	if energy_aura:
		energy_aura.process_material.red_energy()
		energy_aura.amount = 120
		energy_aura.lifetime = 1.0

func setup_apex_energy():
	# Black energy with colored cores, overwhelming
	if energy_aura:
		energy_aura.process_material.black_energy()
		energy_aura.amount = 200
		energy_aura.lifetime = 0.8

func play_idle_animation():
	# 12-frame idle cycle with dramatic poses
	var idle_animation = Animation.new()
	
	# Frame timing for cool factor (dramatic pauses)
	var frame_durations = [100, 100, 150, 100, 100, 150, 100, 100, 150, 100, 100, 150] # milliseconds
	
	for i in range(12):
		var track_index = idle_animation.add_track(Animation.TYPE_VALUE)
		idle_animation.track_set_path(track_index, NodePath("%s:frame" % sprite_2d.get_path()))
		idle_animation.track_insert_key(track_index, 0.0, i)
		
		# Add dramatic pauses on key poses
		var time = 0.0
		for j in range(i + 1):
			time += frame_durations[j] / 1000.0
		
		if i == 2 or i == 5 or i == 8: # Dramatic pose frames
			time += 0.1 # Extra pause for cool factor
		
		idle_animation.track_insert_key(track_index, time, (i + 1) % 12)
	
	idle_animation.length = idle_loop_duration
	idle_animation.loop = true
	
	animation_player.add_animation("idle_power_fantasy", idle_animation)
	animation_player.play("idle_power_fantasy")

func play_attack_light():
	# 8-frame spectacular attack sequence
	var attack_animation = Animation.new()
	attack_animation.length = attack_duration
	
	var track_index = attack_animation.add_track(Animation.TYPE_VALUE)
	attack_animation.track_set_path(track_index, NodePath("%s:frame" % sprite_2d.get_path()))
	
	# Attack frame timing with dramatic impact
	var attack_frames = [0, 1, 2, 3, 4, 5, 6, 7]
	var frame_times = [0.0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35]
	
	for i in range(8):
		attack_animation.track_insert_key(track_index, frame_times[i], attack_frames[i])
	
	# Add energy trail effect
	setup_energy_trail()
	
	# Add screen shake on impact
	animation_player.animation_finished.connect(_on_attack_impact, CONNECT_ONE_SHOT)
	
	animation_player.add_animation("attack_light_power", attack_animation)
	animation_player.play("attack_light_power")

func play_attack_heavy():
	# 10-frame devastating attack with screen dominance
	var attack_animation = Animation.new()
	attack_animation.length = 0.6 # Longer for dramatic effect
	
	var track_index = attack_animation.add_track(Animation.TYPE_VALUE)
	attack_animation.track_set_path(track_index, str(sprite_2d.get_path()) + ":frame")
	
	# Heavy attack with dramatic pauses
	var frame_times = [0.0, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5]
	var attack_frames = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17] # Heavy attack frames
	
	for i in range(10):
		attack_animation.track_insert_key(track_index, frame_times[i], attack_frames[i])
	
	# Add screen-shaking impact
	setup_heavy_impact()
	
	animation_player.add_animation("attack_heavy_power", attack_animation)
	animation_player.play("attack_heavy_power")

func play_parry(perfect: bool = false):
	if perfect:
		play_perfect_parry()
		return
	
	# 7-frame time control parry
	var parry_animation = Animation.new()
	parry_animation.length = parry_duration
	
	var track_index = parry_animation.add_track(Animation.TYPE_VALUE)
	parry_animation.track_set_path(track_index, NodePath("%s:frame" % sprite_2d.get_path()))
	
	var frame_times = [0.0, 0.05, 0.15, 0.25, 0.35, 0.4, 0.45]
	var parry_frames = [18, 19, 20, 21, 22, 23, 24]
	
	for i in range(7):
		parry_animation.track_insert_key(track_index, frame_times[i], parry_frames[i])
	
	# Add time freeze effect
	setup_parry_effects()
	
	animation_player.add_animation("parry_power", parry_animation)
	animation_player.play("parry_power")

func play_perfect_parry():
	# Reality-bending perfect parry with time stop
	var perfect_parry_animation = Animation.new()
	perfect_parry_animation.length = 0.8
	
	var track_index = perfect_parry_animation.add_track(Animation.TYPE_VALUE)
	perfect_parry_animation.track_set_path(track_index, NodePath("%s:frame" % sprite_2d.get_path()))
	
	var frame_times = [0.0, 0.1, 0.3, 0.4, 0.5, 0.6, 0.7]
	var perfect_parry_frames = [25, 26, 27, 28, 29, 30, 31]
	
	for i in range(7):
		perfect_parry_animation.track_insert_key(track_index, frame_times[i], perfect_parry_frames[i])
	
	# Add reality distortion effects
	setup_perfect_parry_effects()
	
	animation_player.add_animation("parry_perfect_power", perfect_parry_animation)
	animation_player.play("parry_perfect_power")

func play_hurt():
	# 4-frame hurt with cool recovery
	var hurt_animation = Animation.new()
	hurt_animation.length = hurt_duration
	
	var track_index = hurt_animation.add_track(Animation.TYPE_VALUE)
	hurt_animation.track_set_path(track_index, NodePath("%s:frame" % sprite_2d.get_path()))
	
	var frame_times = [0.0, 0.05, 0.125, 0.2]
	var hurt_frames = [32, 33, 34, 35]
	
	for i in range(4):
		hurt_animation.track_insert_key(track_index, frame_times[i], hurt_frames[i])
	
	# Add damage flash and impact particles
	setup_hurt_effects()
	
	animation_player.add_animation("hurt_power", hurt_animation)
	animation_player.play("hurt_power")

func setup_energy_trail():
	if energy_trail:
		energy_trail.emitting = true
		await get_tree().create_timer(0.5).timeout
		energy_trail.emitting = false

func setup_heavy_impact():
	if impact_effects:
		impact_effects.emitting = true
		impact_effects.amount = 150
		await get_tree().create_timer(0.8).timeout
		impact_effects.emitting = false

func setup_parry_effects():
	if time_freeze:
		time_freeze.activate(0.15) # Brief time freeze
	
	if impact_effects:
		impact_effects.emitting = true
		impact_effects.amount = 80

func setup_perfect_parry_effects():
	if time_freeze:
		time_freeze.activate(0.3) # Longer time freeze for perfect parry
	
	if impact_effects:
		impact_effects.emitting = true
		impact_effects.amount = 120
	
	if screen_shake:
		screen_shake.add_trauma(0.3)

func setup_hurt_effects():
	if impact_effects:
		impact_effects.emitting = true
		impact_effects.amount = 40
	
	# Red damage flash
	if sprite_2d:
		sprite_2d.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		sprite_2d.modulate = Color.WHITE

func _on_attack_impact(anim_name: String):
	if anim_name == "attack_light_power":
		if screen_shake:
			screen_shake.add_trauma(0.1)
		if impact_effects:
			impact_effects.emitting = true
			impact_effects.amount = 60

func evolve_to_stage(new_stage: MutationStage):
	current_mutation_stage = new_stage
	setup_mutation_effects()
	
	# Play transformation animation
	play_transformation_animation()

func play_transformation_animation():
	# Spectacular transformation sequence
	var transform_animation = Animation.new()
	transform_animation.length = 2.0 # Epic transformation duration
	
	# Add transformation effects
	if impact_effects:
		impact_effects.emitting = true
		impact_effects.amount = 300
	
	if screen_shake:
		screen_shake.add_trauma(0.5)
	
	# Visual transformation logic here
	await get_tree().create_timer(2.0).timeout
