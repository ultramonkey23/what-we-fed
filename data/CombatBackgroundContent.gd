extends RefCounted

# PREMIUM BACKGROUND CONTENT DEFINITIONS
# Defines environments, their layers, atmospheric effects, and world-state reactions.

const ENVIRONMENTS = {
	"predation_ground": {
		"id": "predation_ground",
		"display_name": "Predation Ground",
		"description": "Ancient hunting territory, marked by countless battles.",
		"base_color": Color(0.10, 0.05, 0.06, 1.0),
		"vignette_color": Color(0.02, 0.01, 0.01, 0.72),
		"layers": [
			{
				"id": "sky",
				"path": "res://assets/backgrounds/combat/cbg1.png",
				"parallax": Vector2(0.02, 0.01),
				"modulate": Color(0.4, 0.3, 0.3, 1.0),
				"scale": Vector2(1.2, 1.2),
				"offset": Vector2(0, -50)
			},
			{
				"id": "midground",
				"path": "res://assets/backgrounds/combat/cbg1.png",
				"parallax": Vector2(0.1, 0.05),
				"modulate": Color(0.7, 0.6, 0.6, 0.8),
				"scale": Vector2(1.1, 1.1),
				"offset": Vector2(0, 0)
			},
			{
				"id": "foreground",
				"path": "res://assets/backgrounds/combat/cbg1.png",
				"parallax": Vector2(0.25, 0.12),
				"modulate": Color(1.0, 1.0, 1.0, 0.6),
				"scale": Vector2(1.0, 1.0),
				"offset": Vector2(0, 50)
			}
		],
		"particles": [
			{
				"id": "ash",
				"type": "drift",
				"color": Color(0.8, 0.7, 0.7, 0.4),
				"amount": 40,
				"velocity": Vector2(-20, 10)
			}
		],
		"tendency_reactions": {
			"aggression": { "modulate": Color(1.3, 0.7, 0.7, 1.0), "particle_speed_mult": 2.0 },
			"bond": { "modulate": Color(0.7, 1.1, 1.2, 1.0), "particle_speed_mult": 0.5 }
		}
	},
	"mutation_chamber": {
		"id": "mutation_chamber",
		"display_name": "Mutation Chamber",
		"description": "Biological transformation zone, unstable and dangerous.",
		"base_color": Color(0.06, 0.06, 0.10, 1.0),
		"vignette_color": Color(0.01, 0.01, 0.02, 0.75),
		"layers": [
			{
				"id": "sky",
				"path": "res://assets/backgrounds/combat/cbg2.png",
				"parallax": Vector2(0.03, 0.02),
				"modulate": Color(0.3, 0.3, 0.5, 1.0),
				"scale": Vector2(1.2, 1.2),
				"offset": Vector2(0, -30)
			},
			{
				"id": "midground",
				"path": "res://assets/backgrounds/combat/cbg2.png",
				"parallax": Vector2(0.12, 0.06),
				"modulate": Color(0.6, 0.6, 0.8, 0.8),
				"scale": Vector2(1.1, 1.1),
				"offset": Vector2(0, 0)
			}
		],
		"particles": [
			{
				"id": "spores",
				"type": "float",
				"color": Color(0.6, 0.9, 0.6, 0.3),
				"amount": 60,
				"velocity": Vector2(5, -15)
			}
		],
		"tendency_reactions": {
			"aggression": { "modulate": Color(1.1, 0.6, 1.2, 1.0), "pulse_intensity": 1.5 },
			"bond": { "modulate": Color(0.6, 1.3, 0.8, 1.0), "pulse_intensity": 0.4 }
		}
	},
	"ascendant_arena": {
		"id": "ascendant_arena",
		"display_name": "Ascendant Arena",
		"description": "Final proving ground, where monsters are forged.",
		"base_color": Color(0.04, 0.07, 0.08, 1.0),
		"vignette_color": Color(0.01, 0.02, 0.02, 0.80),
		"layers": [
			{
				"id": "sky",
				"path": "res://assets/backgrounds/combat/cbg3.png",
				"parallax": Vector2(0.01, 0.01),
				"modulate": Color(0.2, 0.4, 0.4, 1.0),
				"scale": Vector2(1.3, 1.3),
				"offset": Vector2(0, -60)
			},
			{
				"id": "arena",
				"path": "res://assets/backgrounds/combat/cbg3.png",
				"parallax": Vector2(0.08, 0.04),
				"modulate": Color(0.5, 0.8, 0.8, 0.9),
				"scale": Vector2(1.1, 1.1),
				"offset": Vector2(0, 0)
			}
		],
		"particles": [
			{
				"id": "energy_sparks",
				"type": "spark",
				"color": Color(1.0, 0.9, 0.5, 0.5),
				"amount": 25,
				"velocity": Vector2(0, -40)
			}
		],
		"tendency_reactions": {
			"aggression": { "modulate": Color(1.4, 1.2, 0.6, 1.0), "energy_flow_speed": 2.0 },
			"bond": { "modulate": Color(0.5, 0.9, 1.4, 1.0), "energy_flow_speed": 0.5 }
		}
	}
}

static func get_environment(env_id: String) -> Dictionary:
	if ENVIRONMENTS.has(env_id):
		return ENVIRONMENTS[env_id].duplicate(true)
	return ENVIRONMENTS["predation_ground"].duplicate(true)

static func get_random_environment() -> Dictionary:
	var keys = ENVIRONMENTS.keys()
	return get_environment(keys[randi() % keys.size()])
