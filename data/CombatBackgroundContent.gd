extends RefCounted

# PREMIUM BACKGROUND CONTENT DEFINITIONS
# Defines environments, their layers, atmospheric effects, and world-state reactions.
# Biome triplet / locked combat substrate art rules: res://assets/backgrounds/combat/premium_background_design_spec.md

const ENVIRONMENTS = {
	"predation_ground": {
		"id": "predation_ground",
		"display_name": "Predation Ground",
		"description": "Ancient hunting territory, marked by countless battles.",
		"base_color": Color(0.12, 0.08, 0.09, 1.0),
		"vignette_color": Color(0.01, 0.0, 0.01, 0.85),
		"haze_color": Color(0.15, 0.1, 0.12, 0.4),
		"ring_active_color": Color(1.0, 0.82, 0.45, 1.0), # Amber Gold
		"layers": [
			{
				"id": "base",
				"path": "res://assets/backgrounds/combat/Ruins_world.png",
				"parallax": Vector2(0.05, 0.02),
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 0)
			}
		]
	},
	"mutation_chamber": {
		"id": "mutation_chamber",
		"display_name": "Mutation Chamber",
		"description": "Biological transformation zone, unstable and dangerous.",
		"base_color": Color(0.08, 0.05, 0.1, 1.0),
		"vignette_color": Color(0.01, 0.0, 0.02, 0.88),
		"haze_color": Color(0.18, 0.12, 0.22, 0.35),
		"ring_active_color": Color(0.85, 0.45, 1.0, 1.0), # Pulsing Violet
		"layers": [
			{
				"id": "base",
				"path": "res://assets/backgrounds/combat/lightlycurrupted_world.png",
				"parallax": Vector2(0.05, 0.02),
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 0)
			}
		]
	},
	"ascendant_arena": {
		"id": "ascendant_arena",
		"display_name": "Ascendant Arena",
		"description": "Final proving ground, where monsters are forged.",
		"base_color": Color(0.05, 0.05, 0.08, 1.0),
		"vignette_color": Color(0.0, 0.0, 0.01, 0.92),
		"haze_color": Color(0.12, 0.08, 0.18, 0.45),
		"ring_active_color": Color(0.45, 0.85, 1.0, 1.0), # Arcane Cyan
		"layers": [
			{
				"id": "base",
				"path": "res://assets/backgrounds/combat/arcane_world.png",
				"parallax": Vector2(0.05, 0.02),
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 0)
			}
		]
	},
	"blue_hollow": {
		"id": "blue_hollow",
		"display_name": "Blue Hollow",
		"description": "A cold, resonant cavern echoing with the pulse.",
		"base_color": Color(0.05, 0.06, 0.12, 1.0),
		"vignette_color": Color(0.0, 0.0, 0.02, 0.9),
		"haze_color": Color(0.08, 0.1, 0.2, 0.4),
		"ring_active_color": Color(0.55, 0.75, 1.0, 1.0), # Crystal Blue
		"layers": [
			{
				"id": "base",
				"path": "res://assets/backgrounds/combat/blue_world.png",
				"parallax": Vector2(0.05, 0.02),
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 0)
			}
		]
	},
	"purple_nest": {
		"id": "purple_nest",
		"display_name": "Purple Nest",
		"description": "A dense, biological thicket of extracted data.",
		"base_color": Color(0.08, 0.04, 0.08, 1.0),
		"vignette_color": Color(0.01, 0.0, 0.01, 0.92),
		"haze_color": Color(0.2, 0.1, 0.22, 0.35),
		"ring_active_color": Color(0.9, 0.35, 0.95, 1.0), # Neon Magenta
		"layers": [
			{
				"id": "base",
				"path": "res://assets/backgrounds/combat/purple_world.png",
				"parallax": Vector2(0.05, 0.02),
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 0)
			}
		]
	},
	"gentle_void": {
		"id": "gentle_void",
		"display_name": "Gentle Void",
		"description": "A wrongly-peaceful pocket of the translation.",
		"base_color": Color(0.1, 0.1, 0.1, 1.0),
		"vignette_color": Color(0.02, 0.02, 0.02, 0.8),
		"haze_color": Color(0.15, 0.15, 0.15, 0.3),
		"ring_active_color": Color(0.95, 0.95, 0.95, 1.0), # Bone White
		"layers": [
			{
				"id": "base",
				"path": "res://assets/backgrounds/combat/gentle_world.png",
				"parallax": Vector2(0.05, 0.02),
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 0)
			}
		]
	},
	"dark_menace": {
		"id": "dark_menace",
		"display_name": "Dark Menace",
		"description": "The deepest layer of the interface wound.",
		"base_color": Color(0.02, 0.01, 0.02, 1.0),
		"vignette_color": Color(0.0, 0.0, 0.0, 1.0),
		"haze_color": Color(0.05, 0.02, 0.05, 0.5),
		"ring_active_color": Color(1.0, 0.22, 0.28, 1.0), # Blood Ember
		"layers": [
			{
				"id": "base",
				"path": "res://assets/backgrounds/combat/darkgentle_world.png",
				"parallax": Vector2(0.05, 0.02),
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 0)
			}
		]
	}
}

static func get_environment(env_id: String) -> Dictionary:
	if ENVIRONMENTS.has(env_id):
		return ENVIRONMENTS[env_id].duplicate(true)
	return ENVIRONMENTS["predation_ground"].duplicate(true)

static func get_random_environment() -> Dictionary:
	var keys = ENVIRONMENTS.keys()
	return get_environment(keys[randi() % keys.size()])
