extends RefCounted

# VesselClassContent.gd
# Defines how each creature species modifies the Player's core "Vessel" kit.

const CLASSES: Dictionary = {
	"ashclaw": {
		"id": "ashclaw",
		"display_name": "ASHCLAW VESSEL",
		"vibe_color": Color(0.95, 0.42, 0.18, 1.0), # Ember
		"vessel_trait": "Rupture",
		"visual_style": {
			"jitter": 4.5,
			"width_mult": 1.2,
			"aura_pulse_speed": 2.4,
			"aura_alpha": 0.25
		},
		"description": "Timed hits apply Blood-Ember. Hitting an enemy with 5 stacks causes a Rupture (AoE burst).",
		"attack_modifier": {
			"on_quality": "any_timed",
			"effect_id": "vessel_rupture",
			"rupture_damage_mult": 2.5
		},
		"hud_sigil_override": "ashclaw_sigil"
	},
	"void_leech": {
		"id": "void_leech",
		"display_name": "VOID VESSEL",
		"vibe_color": Color(0.85, 0.18, 0.95, 1.0), # Mutation Magenta
		"vessel_trait": "Siphon",
		"visual_style": {
			"jitter": 1.2,
			"width_mult": 0.8,
			"aura_pulse_speed": 0.8,
			"aura_alpha": 0.4
		},
		"description": "Timed hits siphon small amounts of HP from the target.",
		"attack_modifier": {
			"on_quality": "any_timed",
			"effect_id": "vessel_siphon",
			"heal_value": 1.5
		},
		"hud_sigil_override": "void_sigil"
	},
	"iron_shaper": {
		"id": "iron_shaper",
		"display_name": "IRON VESSEL",
		"vibe_color": Color(0.95, 0.85, 0.32, 1.0), # Gold
		"vessel_trait": "Plating",
		"visual_style": {
			"jitter": 0.0,
			"width_mult": 2.2,
			"aura_pulse_speed": 0.4,
			"aura_alpha": 0.15
		},
		"description": "Parries grant a stack of Iron Plating (flat damage reduction).",
		"parry_modifier": {
			"on_quality": "perfect",
			"effect_id": "vessel_plating",
			"reduction_bonus": 2.0
		},
		"hud_sigil_override": "iron_sigil"
	},
	"static_weaver": {
		"id": "static_weaver",
		"display_name": "STATIC VESSEL",
		"vibe_color": Color(0.22, 0.88, 0.92, 1.0), # Bond Teal
		"vessel_trait": "Pulse",
		"visual_style": {
			"jitter": 8.0,
			"width_mult": 1.0,
			"aura_pulse_speed": 4.0,
			"aura_alpha": 0.3
		},
		"description": "Successful sector switches emit an electric pulse that interrupts enemies.",
		"movement_modifier": {
			"effect_id": "vessel_pulse",
			"stun_duration": 0.5
		},
		"hud_sigil_override": "static_weaver_sigil"
	}
}

static func get_class_data(species_id: String) -> Dictionary:
	return CLASSES.get(species_id, {}).duplicate(true)
