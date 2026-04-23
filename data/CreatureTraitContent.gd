extends RefCounted

# Siralim-style Trait Content
# Each creature lineage has a unique "System-Lit" trait that can be extracted and spliced.

const TRAITS: Dictionary = {
	"ashclaw_cleave": {
		"id": "ashclaw_cleave",
		"display_name": "Ashclaw Cleave",
		"description": "Perfect hits on the center lane trigger a blood-soaked shockwave in adjacent lanes.",
		"genre_affinity": "punk",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Funk trait: Shockwaves also slow enemy movement."
	},
	"void_leech_drain": {
		"id": "void_leech_drain",
		"display_name": "Void Leech Drain",
		"description": "Weak hits heal for 5% of damage dealt, but increase lane-switch cooldown.",
		"genre_affinity": "psych_rock",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Hip Hop trait: Healing is doubled during the drop."
	},
	"iron_shaper_plating": {
		"id": "iron_shaper_plating",
		"display_name": "Iron Shaper Plating",
		"description": "Every 4th beat, gain a temporary Parry Shield that absorbs one hit.",
		"genre_affinity": "prog_metal",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Funk trait: Shields explode on depletion, dealing massive damage."
	},
	"static_weaver_pulse": {
		"id": "static_weaver_pulse",
		"display_name": "Static Weaver Pulse",
		"description": "Successful lane switches emit a static pulse that interrupts enemy telegraphs.",
		"genre_affinity": "funk",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Punk trait: Pulse also damages enemies in the new lane."
	},
	"swamp_drifter_slow": {
		"id": "swamp_drifter_slow",
		"display_name": "Swamp Drifter Slow",
		"description": "While on the side lanes, incoming projectile speed is reduced by 15%.",
		"genre_affinity": "southern_rock",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Doom trait: Reducer effect is doubled."
	},
	"prism_shifter_echo": {
		"id": "prism_shifter_echo",
		"display_name": "Prism Shifter Echo",
		"description": "Perfect hits create a temporary 'Echo' note that grants bonus damage on the next hit.",
		"genre_affinity": "psychedelic_rock",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Black Metal trait: Echoes also grant a temporary parry shield."
	},
	"hollow_heart_surge": {
		"id": "hollow_heart_surge",
		"display_name": "Hollow Heart Surge",
		"description": "Taking damage triggers a 3-beat 'Emotional Surge', increasing attack speed by 50%.",
		"genre_affinity": "emo",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Grindcore trait: Surge also makes the player invulnerable for the first beat."
	},
	"venomous_sting_v22": {
		"id": "venomous_sting_v22",
		"display_name": "Venomous Sting",
		"description": "Perfect hits apply a 'Venom' debuff that deals 10% damage over 4 beats.",
		"genre_affinity": "grindcore",
		"synergy_bonus": "Triggers 'System Breach' if paired with a Sludge Doom trait: Venom duration is doubled and slows enemy movement."
	}
}

static func get_trait(trait_id: String) -> Dictionary:
	return TRAITS.get(trait_id, {}).duplicate(true)
