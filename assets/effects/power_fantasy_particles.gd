extends GPUParticles2D
class_name PowerFantasyParticles

# SIGNAL: Manga-Ink Bloom + Black Signal Soul
# This replaces generic "power fantasy" with high-contrast predatory impact.
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
@export var screen_coverage: float = 0.3

func _ready():
	setup_effect_type()

func setup_effect_type():
	match effect_type:
		EffectType.LIGHT_ATTACK:
			setup_ink_slash(Color(0.8, 0.8, 0.9, 1.0), 0.4) # Cold Silver
		EffectType.HEAVY_ATTACK:
			setup_ink_bloom(Color(0.9, 0.2, 0.1, 1.0), 0.7) # Blood Ember
		EffectType.PERFECT_ATTACK:
			setup_ink_bloom(Color(1.0, 0.9, 0.3, 1.0), 1.0) # Alert Gold
		EffectType.PARRY:
			setup_ink_slash(Color(0.2, 0.6, 1.0, 1.0), 0.5) # Signal Blue
		EffectType.PERFECT_PARRY:
			setup_ink_shatter(Color(0.1, 0.05, 0.2, 1.0), 1.2) # Void Ink
		EffectType.ULTIMATE_DOMINION:
			setup_ink_shatter(Color(0.6, 0.1, 0.8, 1.0), 2.0) # Mutation Magenta
		EffectType.ULTIMATE_ASCENSION:
			setup_ink_bloom(Color(1.0, 1.0, 1.0, 1.0), 2.5) # Pure Signal

func setup_ink_slash(ink_color: Color, power: float):
	# Sharp, directional "Manga-Ink" slash. High contrast, fast decay.
	amount = int(40 * power)
	lifetime = 0.3
	explosiveness = 0.95
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 600.0 * power
	mat.initial_velocity_max = 900.0 * power
	mat.damping_min = 2000.0
	mat.damping_max = 3000.0
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	
	# Ink "Teeth" (Jagged Scaling)
	var scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1), 0, 0, Curve.TANGENT_FREE, Curve.TANGENT_FREE)
	curve.add_point(Vector2(0.2, 1.5), 0, 0, Curve.TANGENT_FREE, Curve.TANGENT_FREE)
	curve.add_point(Vector2(1, 0), -5.0, 0, Curve.TANGENT_FREE, Curve.TANGENT_FREE)
	scale_curve.curve = curve
	mat.scale_curve = scale_curve
	
	mat.color = ink_color
	# Inject Black Ink Seams
	mat.color_ramp = _make_ink_ramp(ink_color)
	
	self.process_material = mat

func setup_ink_bloom(ink_color: Color, power: float):
	# Visceral ink explosion. Manga-style "Impact Lines."
	amount = int(100 * power)
	lifetime = 0.5
	explosiveness = 1.0
	
	var mat = ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.gravity = Vector3(0, 0, 0)
	mat.initial_velocity_min = 400.0 * power
	mat.initial_velocity_max = 800.0 * power
	mat.damping_min = 1500.0
	mat.damping_max = 2000.0
	mat.scale_min = 3.0
	mat.scale_max = 8.0
	
	# Bloom scaling: snap-to-size then fade
	var scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.1, 2.0))
	curve.add_point(Vector2(1, 0))
	scale_curve.curve = curve
	mat.scale_curve = scale_curve
	
	mat.color_ramp = _make_ink_ramp(ink_color)
	self.process_material = mat

func setup_ink_shatter(ink_color: Color, power: float):
	# Reality-breaking Void Shatter. Jagged fragments of ink.
	amount = int(150 * power)
	lifetime = 0.8
	explosiveness = 0.8
	
	var mat = ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.gravity = Vector3(0, 500, 0) # Ink "dripping" down
	mat.initial_velocity_min = 200.0 * power
	mat.initial_velocity_max = 600.0 * power
	mat.scale_min = 4.0
	mat.scale_max = 12.0
	
	# Erratic shatter rotation
	mat.angle_min = -180.0
	mat.angle_max = 180.0
	mat.angular_velocity_min = 720.0
	mat.angular_velocity_max = 1440.0
	
	mat.color_ramp = _make_ink_ramp(ink_color, true)
	self.process_material = mat

func _make_ink_ramp(base: Color, is_void: bool = false) -> GradientTexture1D:
	var ramp = GradientTexture1D.new()
	var grad = Gradient.new()
	# Ink Truth: Start with pure Black/Void, then flash to color, then fade to Black
	var void_color = Color(0.01, 0.01, 0.02, 1.0) if not is_void else Color(0.0, 0.0, 0.0, 1.0)
	grad.offsets = [0.0, 0.1, 0.8, 1.0]
	grad.colors = [
		void_color,
		base,
		base.lerp(void_color, 0.5),
		Color(void_color.r, void_color.g, void_color.b, 0.0)
	]
	ramp.gradient = grad
	return ramp

func trigger_effect(effect_position: Vector2, intensity: float = 1.0):
	global_position = effect_position
	# SIGNAL: Avoid sludgy Clarification. Just act.
	emitting = true
	await get_tree().create_timer(lifetime).timeout
	emitting = false
