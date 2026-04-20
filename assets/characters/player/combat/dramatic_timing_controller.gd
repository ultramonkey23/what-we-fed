extends Node
class_name DramaticTimingController

# Dramatic timing and cool factor optimization for power fantasy animations
enum TimingStyle {
	POSTER_FRAME,        # Dramatic poses with maximum cool factor
	ANIME_STYLE,         # Anime-inspired timing with dramatic pauses
	CINEMATIC,           # Movie-quality timing with emphasis
	OVER_THE_TOP         # Maximum spectacle with extended dramatic moments
}

@export var timing_style: TimingStyle = TimingStyle.POSTER_FRAME
@export var dramatic_pause_multiplier: float = 1.5
@export var cool_factor_boost: float = 1.2

# Animation timing components
@onready var animation_player: AnimationPlayer
@onready var sprite_2d: Sprite2D
@onready var timing_effects: Node2D = $TimingEffects

# Dramatic timing parameters
var base_attack_duration: float = 0.4
var base_parry_duration: float = 0.5
var base_idle_duration: float = 1.2
var base_hurt_duration: float = 0.3

# Cool factor tracking
var current_cool_factor: float = 1.0
var dramatic_moments_active: int = 0

func _ready():
	setup_dramatic_timing()

func setup_dramatic_timing():
	match timing_style:
		TimingStyle.POSTER_FRAME:
			setup_poster_frame_timing()
		TimingStyle.ANIME_STYLE:
			setup_anime_style_timing()
		TimingStyle.CINEMATIC:
			setup_cinematic_timing()
		TimingStyle.OVER_THE_TOP:
			setup_over_the_top_timing()

func setup_poster_frame_timing():
	# Maximum cool factor with dramatic poses
	base_attack_duration = 0.6
	base_parry_duration = 0.8
	base_idle_duration = 1.8
	base_hurt_duration = 0.5
	
	dramatic_pause_multiplier = 2.0
	cool_factor_boost = 1.5

func setup_anime_style_timing():
	# Anime-inspired with dramatic pauses
	base_attack_duration = 0.5
	base_parry_duration = 0.7
	base_idle_duration = 1.5
	base_hurt_duration = 0.4
	
	dramatic_pause_multiplier = 1.8
	cool_factor_boost = 1.3

func setup_cinematic_timing():
	# Movie-quality with emphasis
	base_attack_duration = 0.4
	base_parry_duration = 0.6
	base_idle_duration = 1.3
	base_hurt_duration = 0.35
	
	dramatic_pause_multiplier = 1.5
	cool_factor_boost = 1.2

func setup_over_the_top_timing():
	# Maximum spectacle
	base_attack_duration = 0.8
	base_parry_duration = 1.0
	base_idle_duration = 2.0
	base_hurt_duration = 0.6
	
	dramatic_pause_multiplier = 2.5
	cool_factor_boost = 2.0

func play_dramatic_attack(attack_type: String = "light"):
	# Cool attack with dramatic timing
	var attack_duration = get_dramatic_attack_duration(attack_type)
	
	# Create dramatic buildup
	await create_dramatic_buildup(attack_duration * 0.3)
	
	# Execute attack with maximum impact
	execute_dramatic_attack(attack_type, attack_duration * 0.4)
	
	# Dramatic followthrough
	await create_dramatic_followthrough(attack_duration * 0.3)

func get_dramatic_attack_duration(attack_type: String) -> float:
	var duration = base_attack_duration
	
	match attack_type:
		"light":
			duration *= 1.0
		"heavy":
			duration *= 1.5
		"perfect":
			duration *= 2.0
		"ultimate":
			duration *= 3.0
	
	return duration * dramatic_pause_multiplier

func create_dramatic_buildup(duration: float):
	# Dramatic anticipation with visual buildup
	create_anticipation_particles()
	apply_dramatic_screen_effect("buildup", duration)
	
	# Dramatic pose before attack
	if sprite_2d:
		var tween = create_tween()
		tween.tween_property(sprite_2d, "scale", Vector2(1.1, 1.1), duration * 0.5)
		tween.tween_property(sprite_2d, "scale", Vector2(1.0, 1.0), duration * 0.5)
	
	await get_tree().create_timer(duration).timeout

func execute_dramatic_attack(attack_type: String, duration: float):
	# Maximum impact attack execution
	dramatic_moments_active += 1
	
	# Screen impact effects
	apply_dramatic_screen_effect("impact", duration)
	
	# Cool attack animation
	if animation_player:
		var anim_name = "%s_attack_dramatic" % attack_type
		if animation_player.has_animation(anim_name):
			animation_player.play(anim_name)
		else:
			play_default_dramatic_attack(attack_type)
	
	# Dramatic sound and visual feedback
	create_dramatic_impact_effects(attack_type)
	
	await get_tree().create_timer(duration).timeout
	dramatic_moments_active -= 1

func play_default_dramatic_attack(_attack_type: String):
	# Create dramatic attack animation on the fly
	var dramatic_attack = Animation.new()
	var duration = base_attack_duration * dramatic_pause_multiplier
	dramatic_attack.length = duration
	
	var track_index = dramatic_attack.add_track(Animation.TYPE_VALUE)
	dramatic_attack.track_set_path(track_index, NodePath("%s:frame" % sprite_2d.get_path()))
	
	# Dramatic frame timing with emphasis
	var frame_count = 8
	var emphasis_frames = [2, 4, 6] # Dramatic impact frames
	
	for i in range(frame_count):
		var time = (i / float(frame_count)) * duration
		
		# Add dramatic pause on emphasis frames
		if i in emphasis_frames:
			time += duration * 0.1
		
		dramatic_attack.track_insert_key(track_index, time, i)
	
	animation_player.add_animation("dramatic_attack_default", dramatic_attack)
	animation_player.play("dramatic_attack_default")

func create_dramatic_followthrough(duration: float):
	# Dramatic recovery with cool poses
	create_followthrough_particles()
	apply_dramatic_screen_effect("followthrough", duration)
	
	# Dramatic pose hold
	if sprite_2d:
		var tween = create_tween()
		tween.tween_property(sprite_2d, "modulate", Color.WHITE, duration * 0.3)
		tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 0.8), duration * 0.7)
	
	await get_tree().create_timer(duration).timeout

func play_dramatic_parry(perfect: bool = false):
	# Cool parry with dramatic time control
	var parry_duration = get_dramatic_parry_duration(perfect)
	
	# Dramatic anticipation
	await create_dramatic_anticipation(parry_duration * 0.4)
	
	# Time freeze moment
	if perfect:
		await create_perfect_time_freeze(parry_duration * 0.3)
	else:
		await create_dramatic_time_slow(parry_duration * 0.3)
	
	# Dramatic recovery
	await create_dramatic_recovery(parry_duration * 0.3)

func get_dramatic_parry_duration(perfect: bool) -> float:
	var duration = base_parry_duration
	
	if perfect:
		duration *= 2.0
	
	return duration * dramatic_pause_multiplier

func create_dramatic_anticipation(duration: float):
	# Dramatic anticipation with visual buildup
	dramatic_moments_active += 1
	
	create_anticipation_particles()
	apply_dramatic_screen_effect("anticipation", duration)
	
	# Slow motion buildup
	if animation_player:
		animation_player.playback_speed = 0.5
		animation_player.play("parry_anticipation")
	
	await get_tree().create_timer(duration).timeout

func create_perfect_time_freeze(duration: float):
	# Perfect parry with dramatic time freeze
	var time_freeze = get_tree().get_first_node_in_group("time_freeze")
	if time_freeze:
		time_freeze.activate(duration)
	
	# Dramatic visual effects
	create_perfect_parry_effects()
	apply_dramatic_screen_effect("perfect_parry", duration)
	
	# Dramatic pose hold
	if sprite_2d:
		var tween = create_tween()
		tween.tween_property(sprite_2d, "modulate", Color.CYAN, duration * 0.2)
		tween.tween_property(sprite_2d, "modulate", Color.WHITE, duration * 0.8)
	
	await get_tree().create_timer(duration).timeout

func create_dramatic_time_slow(duration: float):
	# Dramatic time slow for regular parry
	var time_freeze = get_tree().get_first_node_in_group("time_freeze")
	if time_freeze:
		time_freeze.activate(duration * 0.5)
	
	create_parry_effects()
	apply_dramatic_screen_effect("parry", duration)
	
	await get_tree().create_timer(duration).timeout

func create_dramatic_recovery(duration: float):
	# Dramatic recovery with cool poses
	if animation_player:
		animation_player.playback_speed = 1.0
		animation_player.play("parry_recovery")
	
	create_recovery_particles()
	apply_dramatic_screen_effect("recovery", duration)
	
	await get_tree().create_timer(duration).timeout
	dramatic_moments_active -= 1

func play_dramatic_hurt():
	# Cool hurt with dramatic recovery
	var hurt_duration = base_hurt_duration * dramatic_pause_multiplier
	
	# Dramatic impact
	await create_dramatic_hurt_impact(hurt_duration * 0.4)
	
	# Dramatic recoil
	await create_dramatic_recoil(hurt_duration * 0.3)
	
	# Cool recovery
	await create_cool_recovery(hurt_duration * 0.3)

func create_dramatic_hurt_impact(duration: float):
	dramatic_moments_active += 1
	
	# Dramatic damage flash
	if sprite_2d:
		var tween = create_tween()
		tween.tween_property(sprite_2d, "modulate", Color.RED, duration * 0.3)
		tween.tween_property(sprite_2d, "modulate", Color.WHITE, duration * 0.7)
	
	create_hurt_impact_effects()
	apply_dramatic_screen_effect("hurt", duration)
	
	await get_tree().create_timer(duration).timeout

func create_dramatic_recoil(duration: float):
	# Dramatic recoil with cool poses
	if animation_player:
		animation_player.play("hurt_recoil")
	
	create_recoil_particles()
	
	# Screen shake for impact
	var screen_shake = get_tree().get_first_node_in_group("screen_shake")
	if screen_shake:
		screen_shake.add_trauma(0.3)
	
	await get_tree().create_timer(duration).timeout

func create_cool_recovery(duration: float):
	# Cool recovery with dramatic pose
	if animation_player:
		animation_player.play("hurt_recovery")
	
	create_recovery_particles()
	apply_dramatic_screen_effect("recovery", duration)
	
	await get_tree().create_timer(duration).timeout
	dramatic_moments_active -= 1

func play_dramatic_idle():
	# Cool idle with dramatic poses
	var idle_duration = base_idle_duration * dramatic_pause_multiplier
	
	# Dramatic idle cycle
	await create_dramatic_idle_cycle(idle_duration)

func create_dramatic_idle_cycle(duration: float):
	# Dramatic idle with multiple cool poses
	if animation_player:
		animation_player.play("idle_dramatic")
	
	# Continuous cool effects
	create_idle_particles()
	
	# Dramatic pose emphasis
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_delay(duration * 0.7)
	tween.tween_property(sprite_2d, "scale", Vector2(1.05, 1.05), duration * 0.1)
	tween.tween_property(sprite_2d, "scale", Vector2(1.0, 1.0), duration * 0.2)

# Dramatic effect creation methods
func create_anticipation_particles():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 30
	particles.lifetime = 1.0
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 100.0
	process_material.initial_velocity_max = 200.0
	process_material.color = Color.CYAN
	process_material.emission = Color.WHITE
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func create_followthrough_particles():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 40
	particles.lifetime = 1.2
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 150.0
	process_material.initial_velocity_max = 300.0
	process_material.color = Color.ORANGE
	process_material.emission = Color.YELLOW
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(1.2).timeout
	particles.queue_free()

func create_perfect_parry_effects():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 80
	particles.lifetime = 1.5
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 200.0
	process_material.initial_velocity_max = 400.0
	process_material.color = Color.PURPLE
	process_material.emission = Color.CYAN
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(1.5).timeout
	particles.queue_free()

func create_parry_effects():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 50
	particles.lifetime = 1.0
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 150.0
	process_material.initial_velocity_max = 300.0
	process_material.color = Color.BLUE
	process_material.emission = Color.WHITE
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func create_recovery_particles():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 25
	particles.lifetime = 0.8
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 90.0
	process_material.initial_velocity_min = 80.0
	process_material.initial_velocity_max = 160.0
	process_material.color = Color.GREEN
	process_material.emission = Color.WHITE
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(0.8).timeout
	particles.queue_free()

func create_hurt_impact_effects():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 35
	particles.lifetime = 0.6
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 120.0
	process_material.initial_velocity_max = 240.0
	process_material.color = Color.RED
	process_material.emission = Color.ORANGE
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(0.6).timeout
	particles.queue_free()

func create_recoil_particles():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 20
	particles.lifetime = 0.5
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 120.0
	process_material.initial_velocity_min = 100.0
	process_material.initial_velocity_max = 200.0
	process_material.color = Color.DARK_GRAY
	process_material.emission = Color.RED
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()

func create_idle_particles():
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = 15
	particles.lifetime = 2.0
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 45.0
	process_material.initial_velocity_min = 50.0
	process_material.initial_velocity_max = 100.0
	process_material.color = Color.CYAN
	process_material.emission = Color.WHITE
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func create_dramatic_impact_effects(attack_type: String):
	var particle_count = 60
	var effect_color = Color.ORANGE
	
	match attack_type:
		"heavy":
			particle_count = 100
			effect_color = Color.RED
		"perfect":
			particle_count = 150
			effect_color = Color.GOLD
		"ultimate":
			particle_count = 300
			effect_color = Color.MAGENTA
	
	var particles = GPUParticles2D.new()
	particles.position = sprite_2d.global_position if sprite_2d else Vector2.ZERO
	particles.amount = particle_count
	particles.lifetime = 1.5
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 360.0
	process_material.initial_velocity_min = 200.0
	process_material.initial_velocity_max = 400.0
	process_material.color = effect_color
	process_material.emission = Color.WHITE
	
	particles.process_material = process_material
	
	get_tree().current_scene.add_child(particles)
	await get_tree().create_timer(1.5).timeout
	particles.queue_free()

func apply_dramatic_screen_effect(effect_type: String, duration: float):
	var screen_effect = get_tree().get_first_node_in_group("screen_effects")
	if screen_effect:
		screen_effect.apply_dramatic_effect(effect_type, duration)

func get_current_cool_factor() -> float:
	var base_cool = cool_factor_boost
	
	# Boost cool factor during dramatic moments
	if dramatic_moments_active > 0:
		base_cool *= (1.0 + dramatic_moments_active * 0.2)
	
	return base_cool

func is_dramatic_moment_active() -> bool:
	return dramatic_moments_active > 0

func set_timing_style(new_style: TimingStyle):
	timing_style = new_style
	setup_dramatic_timing()

func get_timing_style_name() -> String:
	match timing_style:
		TimingStyle.POSTER_FRAME:
			return "Poster Frame"
		TimingStyle.ANIME_STYLE:
			return "Anime Style"
		TimingStyle.CINEMATIC:
			return "Cinematic"
		TimingStyle.OVER_THE_TOP:
			return "Over The Top"
		_:
			return "Unknown"
