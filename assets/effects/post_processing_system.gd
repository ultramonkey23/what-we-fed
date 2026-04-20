extends Node
class_name PostProcessingSystem

# Advanced post-processing for maximum visual impact and cinematic quality
enum PostProcessingStyle {
	PREMIUM_CINEMATIC,    # High-quality cinematic effects
	POWER_FANTASY,       # Power-focused visual enhancement
	OVER_THE_TOP,        # Maximum spectacle and cool factor
	ULTIMATE_DOMINANCE   # God-tier visual presentation
}

@export var current_style: PostProcessingStyle = PostProcessingStyle.POWER_FANTASY
@export var processing_intensity: float = 1.0

# Post-processing components
@onready var viewport_container: SubViewportContainer = $ViewportContainer
@onready var effect_viewport: SubViewport = $ViewportContainer/SubViewport
@onready var post_process_canvas: ColorRect = $PostProcessCanvas
@onready var shader_material: ShaderMaterial = $PostProcessCanvas.material

# Visual enhancement layers
@onready var bloom_layer: ColorRect = $BloomLayer
@onready var vignette_layer: ColorRect = $VignetteLayer
@onready var chromatic_aberration_layer: ColorRect = $ChromaticAberrationLayer
@onready var motion_blur_layer: ColorRect = $MotionBlurLayer

# Power fantasy specific effects
var power_glow_intensity: float = 0.0
var screen_dominance_factor: float = 0.0
var cool_factor_multiplier: float = 1.0

func _ready():
	setup_post_processing_pipeline()

func setup_post_processing_pipeline():
	# Initialize full post-processing pipeline
	match current_style:
		PostProcessingStyle.PREMIUM_CINEMATIC:
			setup_cinematic_pipeline()
		PostProcessingStyle.POWER_FANTASY:
			setup_power_fantasy_pipeline()
		PostProcessingStyle.OVER_THE_TOP:
			setup_over_the_top_pipeline()
		PostProcessingStyle.ULTIMATE_DOMINANCE:
			setup_ultimate_dominance_pipeline()

func setup_cinematic_pipeline():
	# High-quality cinematic post-processing
	processing_intensity = 0.8
	cool_factor_multiplier = 1.0
	
	if shader_material:
		shader_material.set_shader_parameter("bloom_intensity", 0.6)
		shader_material.set_shader_parameter("vignette_strength", 0.3)
		shader_material.set_shader_parameter("contrast_boost", 1.1)
		shader_material.set_shader_parameter("saturation_enhancement", 1.2)

func setup_power_fantasy_pipeline():
	# Power-focused visual enhancement
	processing_intensity = 1.0
	cool_factor_multiplier = 1.3
	
	if shader_material:
		shader_material.set_shader_parameter("bloom_intensity", 0.8)
		shader_material.set_shader_parameter("vignette_strength", 0.4)
		shader_material.set_shader_parameter("contrast_boost", 1.2)
		shader_material.set_shader_parameter("saturation_enhancement", 1.4)
		shader_material.set_shader_parameter("power_glow", 0.3)

func setup_over_the_top_pipeline():
	# Maximum spectacle post-processing
	processing_intensity = 1.5
	cool_factor_multiplier = 1.8
	
	if shader_material:
		shader_material.set_shader_parameter("bloom_intensity", 1.2)
		shader_material.set_shader_parameter("vignette_strength", 0.5)
		shader_material.set_shader_parameter("contrast_boost", 1.4)
		shader_material.set_shader_parameter("saturation_enhancement", 1.6)
		shader_material.set_shader_parameter("power_glow", 0.6)
		shader_material.set_shader_parameter("screen_dominance", 0.4)

func setup_ultimate_dominance_pipeline():
	# God-tier visual presentation
	processing_intensity = 2.0
	cool_factor_multiplier = 2.5
	
	if shader_material:
		shader_material.set_shader_parameter("bloom_intensity", 1.8)
		shader_material.set_shader_parameter("vignette_strength", 0.6)
		shader_material.set_shader_parameter("contrast_boost", 1.6)
		shader_material.set_shader_parameter("saturation_enhancement", 2.0)
		shader_material.set_shader_parameter("power_glow", 1.0)
		shader_material.set_shader_parameter("screen_dominance", 0.8)
		shader_material.set_shader_parameter("ultimate_effects", 1.0)

func apply_combat_post_processing(intensity: float, combat_type: String):
	# Dynamic post-processing based on combat intensity
	var adjusted_intensity = intensity * processing_intensity * cool_factor_multiplier
	
	match combat_type:
		"light_attack":
			apply_light_attack_effects(adjusted_intensity)
		"heavy_attack":
			apply_heavy_attack_effects(adjusted_intensity)
		"perfect_attack":
			apply_perfect_attack_effects(adjusted_intensity)
		"parry":
			apply_parry_effects(adjusted_intensity)
		"perfect_parry":
			apply_perfect_parry_effects(adjusted_intensity)
		"ultimate":
			apply_ultimate_effects(adjusted_intensity)

func apply_light_attack_effects(intensity: float):
	# Subtle enhancement for light attacks
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 0.8 * intensity, 0.2)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.2 * intensity, 0.2)
		
		# Quick fade back
		tween.tween_delay(0.3)
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 0.6, 0.3)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.1, 0.3)

func apply_heavy_attack_effects(intensity: float):
	# More dramatic enhancement for heavy attacks
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 1.2 * intensity, 0.3)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.5 * intensity, 0.3)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 1.6 * intensity, 0.3)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.4 * intensity, 0.3)
		
		# Gradual recovery
		tween.tween_delay(0.5)
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 0.8, 0.5)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.4, 0.5)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 1.4, 0.5)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.3, 0.5)

func apply_perfect_attack_effects(intensity: float):
	# Spectacular enhancement for perfect attacks
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 1.8 * intensity, 0.4)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.6 * intensity, 0.4)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 2.0 * intensity, 0.4)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.8 * intensity, 0.4)
		tween.tween_property(shader_material, "shader_parameter/screen_dominance", 0.5 * intensity, 0.4)
		
		# Slow recovery for dramatic effect
		tween.tween_delay(0.8)
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 1.2, 0.8)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.5, 0.8)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 1.6, 0.8)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.6, 0.8)
		tween.tween_property(shader_material, "shader_parameter/screen_dominance", 0.4, 0.8)

func apply_parry_effects(intensity: float):
	# Cool enhancement for parry
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 1.0 * intensity, 0.2)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.3 * intensity, 0.2)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", 0.2 * intensity, 0.2)
		
		# Quick recovery
		tween.tween_delay(0.2)
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 0.8, 0.2)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.2, 0.2)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", 0.1, 0.2)

func apply_perfect_parry_effects(intensity: float):
	# Dramatic enhancement for perfect parry
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 1.5 * intensity, 0.3)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.5 * intensity, 0.3)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", 0.4 * intensity, 0.3)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.6 * intensity, 0.3)
		tween.tween_property(shader_material, "shader_parameter/time_freeze_effect", 0.8 * intensity, 0.3)
		
		# Dramatic recovery
		tween.tween_delay(0.6)
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 1.0, 0.6)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.3, 0.6)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", 0.2, 0.6)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.4, 0.6)
		tween.tween_property(shader_material, "shader_parameter/time_freeze_effect", 0.3, 0.6)

func apply_ultimate_effects(intensity: float):
	# God-tier enhancement for ultimate abilities
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 2.5 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.8 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 2.0 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 2.5 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 1.5 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/screen_dominance", 1.0 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/ultimate_effects", 1.0 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", 0.6 * intensity, 0.5)
		tween.tween_property(shader_material, "shader_parameter/motion_blur", 0.4 * intensity, 0.5)
		
		# Very slow recovery for ultimate impact
		tween.tween_delay(1.5)
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 1.8, 1.5)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.6, 1.5)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.6, 1.5)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 2.0, 1.5)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 1.0, 1.5)
		tween.tween_property(shader_material, "shader_parameter/screen_dominance", 0.8, 1.5)
		tween.tween_property(shader_material, "shader_parameter/ultimate_effects", 0.6, 1.5)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", 0.3, 1.5)
		tween.tween_property(shader_material, "shader_parameter/motion_blur", 0.2, 1.5)

func apply_power_progression_effects(power_level: float):
	# Progressive visual enhancement based on power level
	var progression_intensity = power_level * processing_intensity
	
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Progressive enhancement
		tween.tween_property(shader_material, "shader_parameter/power_glow", progression_intensity, 1.0)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.0 + progression_intensity * 0.6, 1.0)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 1.0 + progression_intensity * 1.0, 1.0)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.3 + progression_intensity * 0.3, 1.0)

func apply_environmental_effects(environment_intensity: float):
	# Environmental impact on visual presentation
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Environmental color shifts and effects
		tween.tween_property(shader_material, "shader_parameter/environmental_tint", Color(0.8, 0.6, 0.4), 0.5)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.0 + environment_intensity * 0.3, 0.5)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 1.0 + environment_intensity * 0.2, 0.5)

func apply_cinematic_effects(cinematic_intensity: float):
	# Cinematic quality enhancements
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Film-like effects
		tween.tween_property(shader_material, "shader_parameter/film_grain", cinematic_intensity * 0.1, 0.3)
		tween.tween_property(shader_material, "shader_parameter/color_grading", Color(1.05, 1.02, 0.98), 0.3)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.0 + cinematic_intensity * 0.2, 0.3)

func apply_screen_dominance_effects(dominance_level: float):
	# Screen-dominating visual effects for maximum impact
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Screen dominance parameters
		tween.tween_property(shader_material, "shader_parameter/screen_dominance", dominance_level, 0.4)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.4 + dominance_level * 0.4, 0.4)
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 0.8 + dominance_level * 1.2, 0.4)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.3 + dominance_level * 0.7, 0.4)

func apply_time_effects(time_intensity: float):
	# Time-related visual effects (slow motion, time freeze)
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Time manipulation effects
		tween.tween_property(shader_material, "shader_parameter/time_freeze_effect", time_intensity, 0.2)
		tween.tween_property(shader_material, "shader_parameter/motion_blur", time_intensity * 0.6, 0.2)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", time_intensity * 0.3, 0.2)

func reset_post_processing():
	# Reset all post-processing effects to baseline
	if shader_material:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(shader_material, "shader_parameter/bloom_intensity", 0.8, 0.5)
		tween.tween_property(shader_material, "shader_parameter/vignette_strength", 0.4, 0.5)
		tween.tween_property(shader_material, "shader_parameter/contrast_boost", 1.2, 0.5)
		tween.tween_property(shader_material, "shader_parameter/saturation_enhancement", 1.4, 0.5)
		tween.tween_property(shader_material, "shader_parameter/power_glow", 0.3, 0.5)
		tween.tween_property(shader_material, "shader_parameter/screen_dominance", 0.4, 0.5)
		tween.tween_property(shader_material, "shader_parameter/chromatic_aberration", 0.1, 0.5)
		tween.tween_property(shader_material, "shader_parameter/motion_blur", 0.0, 0.5)
		tween.tween_property(shader_material, "shader_parameter/time_freeze_effect", 0.0, 0.5)
		tween.tween_property(shader_material, "shader_parameter/ultimate_effects", 0.0, 0.5)

func set_post_processing_style(new_style: PostProcessingStyle):
	current_style = new_style
	setup_post_processing_pipeline()

func get_current_intensity() -> float:
	return processing_intensity * cool_factor_multiplier

func get_cool_factor_level() -> float:
	return cool_factor_multiplier

func is_power_fantasy_active() -> bool:
	return current_style == PostProcessingStyle.POWER_FANTASY or current_style == PostProcessingStyle.OVER_THE_TOP or current_style == PostProcessingStyle.ULTIMATE_DOMINANCE

func get_style_name() -> String:
	match current_style:
		PostProcessingStyle.PREMIUM_CINEMATIC:
			return "Premium Cinematic"
		PostProcessingStyle.POWER_FANTASY:
			return "Power Fantasy"
		PostProcessingStyle.OVER_THE_TOP:
			return "Over The Top"
		PostProcessingStyle.ULTIMATE_DOMINANCE:
			return "Ultimate Dominance"
		_:
			return "Unknown Style"

# Performance optimization
func set_quality_level(quality: int):
	match quality:
		0: # Low quality
			processing_intensity = 0.5
			cool_factor_multiplier = 0.8
		1: # Medium quality
			processing_intensity = 0.8
			cool_factor_multiplier = 1.0
		2: # High quality
			processing_intensity = 1.0
			cool_factor_multiplier = 1.2
		3: # Ultra quality
			processing_intensity = 1.5
			cool_factor_multiplier = 1.5
	
	setup_post_processing_pipeline()

func get_performance_metrics() -> Dictionary:
	return {
		"current_style": get_style_name(),
		"processing_intensity": processing_intensity,
		"cool_factor": cool_factor_multiplier,
		"power_glow": power_glow_intensity,
		"screen_dominance": screen_dominance_factor,
		"is_power_fantasy": is_power_fantasy_active()
	}
