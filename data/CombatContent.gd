extends RefCounted

const BIOME_FEEDING_HOLLOW := {
	"name": "The Feeding Hollow",
	"subtitle": "The place remembers every mouth it kept.",
	"background_color": Color(0.10, 0.05, 0.06, 1.0),
	"lane_color": Color(0.34, 0.24, 0.26, 1.0),
	"enemy_active_color": Color(0.76, 0.21, 0.21, 1.0),
	"enemy_inactive_color": Color(0.38, 0.18, 0.18, 0.55),
	"ring_active_color": Color(0.98, 0.93, 0.68, 1.0),
	"ring_inactive_color": Color(0.58, 0.52, 0.44, 0.45),
	"victory_text": "THE HOLLOW BOWS",
	"defeat_text": "YOU FED IT"
}

const BIOME_PALE_SHELF := {
	"name": "The Pale Shelf",
	"subtitle": "Nothing hides here. Not even what is missing.",
	"background_color": Color(0.06, 0.06, 0.10, 1.0),
	"lane_color": Color(0.28, 0.28, 0.40, 1.0),
	"enemy_active_color": Color(0.58, 0.60, 0.82, 1.0),
	"enemy_inactive_color": Color(0.26, 0.27, 0.42, 0.55),
	"ring_active_color": Color(0.84, 0.90, 1.00, 1.0),
	"ring_inactive_color": Color(0.50, 0.52, 0.64, 0.45),
	"victory_text": "THE SHELF RELENTS",
	"defeat_text": "EXPOSED AND TAKEN"
}

const BIOME_DROWNED_CUT := {
	"name": "The Drowned Cut",
	"subtitle": "The water remembers what sank and what fed.",
	"background_color": Color(0.04, 0.07, 0.08, 1.0),
	"lane_color": Color(0.16, 0.28, 0.30, 1.0),
	"enemy_active_color": Color(0.28, 0.72, 0.62, 1.0),
	"enemy_inactive_color": Color(0.13, 0.34, 0.32, 0.55),
	"ring_active_color": Color(0.68, 0.98, 0.88, 1.0),
	"ring_inactive_color": Color(0.42, 0.58, 0.56, 0.45),
	"victory_text": "THE CUT REMEMBERS YOU",
	"defeat_text": "PULLED UNDER"
}

const BIOME_FEEDING_HOLLOW_BOSS := {
	"name": "The Feeding Hollow",
	"subtitle": "It was always waiting for a stronger mouth.",
	"background_color": Color(0.07, 0.04, 0.03, 1.0),
	"lane_color": Color(0.36, 0.24, 0.10, 1.0),
	"enemy_active_color": Color(0.86, 0.58, 0.14, 1.0),
	"enemy_inactive_color": Color(0.43, 0.29, 0.07, 0.55),
	"ring_active_color": Color(0.98, 0.93, 0.68, 1.0),
	"ring_inactive_color": Color(0.58, 0.52, 0.44, 0.45),
	"victory_text": "SOVEREIGN FELLED",
	"defeat_text": "THE HOLLOW TOOK YOU"
}

const CLUTCH_SPECIES := ["gruvek", "siltgrip"] # Species that help player recover when low HP

const CREATURES := {
	"ashclaw": {
		"species_id": "ashclaw",
		"display_name": "Ashclaw",
		"primary_type": "predator",
		"secondary_type": "grit",
		"affinity": "flesh",
		"archetypes": ["guardian", "berserker"],
		"capture_threshold": 0.30,
		"bond_level": 1,
		"description": "It learned to cut before it learned the cost of stopping.",
		"dna_threshold": 8.0,
		"sprite_path": "res://assets/creatures/ashclaw/forms/ashclaw_baby.png",
		"reward_portrait_path": "res://assets/creatures/ashclaw/forms/ashclaw_baby.png",
		"support_portrait_path": "res://assets/creatures/ashclaw/forms/ashclaw_teen.png",
		"battlefield_sprite_path": "res://assets/creatures/ashclaw/forms/ashclaw_adult.png",
		"combat_render": {
			"scale": 0.058,
			"world_offset": Vector2(-116.0, 82.0),
			"z_index": 6,
			"modulate": Color(0.92, 0.91, 0.88, 0.90)
		},
		"eat_effect": {"type": "damage_flat", "value": 2.0},
		"bond_passive": {"type": "damage_on_ultimate", "value": 5.0},
		"support_role": {
			"readout_name": "Ashclaw",
			"effect_id": "ashclaw_strike",
			"trigger_on": ["perfect_parry", "perfect_timed_attack"],
			"effect_value": 10.0,
			"feedback_text": "ASHCLAW"
		},
		"quig_offer_text": "Quig: \"Mind the claws. It only knows the part after fear.\"",
		"wrong_detail": "claws worn completely flat but still cutting"
	},
	"bond_remnant": {
		"species_id": "bond_remnant",
		"display_name": "Bond Remnant",
		"primary_type": "bond",
		"secondary_type": "hollow",
		"affinity": "hollow",
		"archetypes": ["phantom", "anchor"],
		"capture_threshold": 0.25,
		"bond_level": 1,
		"description": "It holds the shape of something that stayed after its body did not.",
		"dna_threshold": 8.0,
		"sprite_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_idle.png",
		"reward_portrait_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_idle.png",
		"support_portrait_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_adult.png",
		"battlefield_sprite_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_adult.png",
		"combat_render": {
			"scale": 0.062,
			"world_offset": Vector2(-124.0, 88.0),
			"z_index": 6,
			"modulate": Color(0.84, 0.88, 1.0, 0.85)
		},
		"eat_effect": {"type": "damage_flat", "value": 1.0},
		"bond_passive": {"type": "damage_reduction_pct", "value": 0.08},
		"support_role": {
			"readout_name": "Bond Remnant",
			"effect_id": "bond_remnant_mend",
			"trigger_on": ["damage_taken_when_ready"],
			"effect_value": 6.0,
			"feedback_text": "REMNANT"
		},
		"quig_offer_text": "Quig: \"Do not stare. It notices being remembered.\"",
		"wrong_detail": "teeth set in a jaw that never learned to close"
	},
	"gruvek": {
		"species_id": "gruvek",
		"display_name": "Gruvek",
		"primary_type": "predator",
		"secondary_type": "gorge",
		"affinity": "gorge",
		"archetypes": ["carrion", "glutton"],
		"capture_threshold": 0.30,
		"bond_level": 1,
		"description": "It keeps eating until the hunger belongs to whoever is left nearby.",
		"dna_threshold": 10.0,
		"eat_effect": {"type": "hp_restore", "value": 18.0},
		"bond_passive": {"type": "hp_on_kill", "value": 3.0},
		"support_role": {
			"readout_name": "Gruvek",
			"effect_id": "gruvek_gorge",
			"trigger_on": ["enemy_defeated"],
			"effect_value": 10.0,
			"feedback_text": "GORGE"
		},
		"quig_offer_text": "Quig: \"You smell that first. Better than feeling it first.\"",
		"wrong_detail": "jaw unhinged past any angle that should work"
	},
	"veilskin": {
		"species_id": "veilskin",
		"display_name": "Veilskin",
		"primary_type": "predator",
		"secondary_type": "reflex",
		"affinity": "reflex",
		"archetypes": ["phantom", "counter"],
		"capture_threshold": 0.20,
		"bond_level": 1,
		"description": "It waits for one clean reason to move. The reason never survives it.",
		"dna_threshold": 10.0,
		"eat_effect": {"type": "damage_flat", "value": 1.0},
		"bond_passive": {"type": "parry_reflect_mult", "value": 0.40},
		"support_role": {
			"readout_name": "Veilskin",
			"effect_id": "veilskin_phase",
			"trigger_on": ["perfect_parry"],
			"effect_value": 12.0,
			"feedback_text": "PHASE"
		},
		"quig_offer_text": "Quig: \"If it blinks, we both missed it.\"",
		"wrong_detail": "no visible eyes but something tracks every movement"
	},
	"thornback": {
		"species_id": "thornback",
		"display_name": "Thornback",
		"primary_type": "predator",
		"secondary_type": "grit",
		"affinity": "flesh",
		"archetypes": ["berserker", "ravager"],
		"capture_threshold": 0.35,
		"bond_level": 1,
		"description": "Every wound it opens stays interested in widening.",
		"dna_threshold": 12.0,
		"eat_effect": {"type": "damage_flat", "value": 3.0},
		"bond_passive": {"type": "timed_damage_flat", "value": 3.0},
		"support_role": {
			"readout_name": "Thornback",
			"effect_id": "thornback_rend",
			"trigger_on": ["perfect_timed_attack"],
			"effect_value": 20.0,
			"feedback_text": "REND"
		},
		"quig_offer_text": "Quig: \"Keep your hands where it can count them.\"",
		"wrong_detail": "spines still growing — some through the wrong layers"
	},
	"knellspine": {
		"species_id": "knellspine",
		"display_name": "Knellspine",
		"primary_type": "cadence",
		"secondary_type": "spine",
		"affinity": "cadence",
		"archetypes": ["chorister", "razor"],
		"capture_threshold": 0.22,
		"bond_level": 1,
		"description": "Its ribs ring when your timing is true. The note cuts after the sound is done.",
		"dna_threshold": 6.0,
		"eat_effect": {"type": "support_charge", "value": 35.0},
		"bond_passive": {"type": "timed_damage_flat", "value": 2.0},
		"support_role": {
			"readout_name": "Knellspine",
			"effect_id": "knellspine_peal",
			"trigger_on": ["good_timed_attack", "perfect_timed_attack"],
			"effect_value": 8.0,
			"feedback_text": "PEAL"
		},
		"quig_offer_text": "Quig: \"When it starts singing, strike first.\"",
		"wrong_detail": "vertebrae tuned like bells and filed to a point"
	},
	"marrowward": {
		"species_id": "marrowward",
		"display_name": "Marrowward",
		"primary_type": "guard",
		"secondary_type": "bone",
		"affinity": "guard",
		"archetypes": ["anchor", "ward"],
		"capture_threshold": 0.28,
		"bond_level": 1,
		"description": "It protects what it keeps only so the feeding can last longer.",
		"dna_threshold": 8.0,
		"eat_effect": {"type": "max_hp_flat", "value": 12.0},
		"bond_passive": {"type": "damage_reduction_pct", "value": 0.06},
		"support_role": {
			"readout_name": "Marrowward",
			"effect_id": "marrowward_ward",
			"trigger_on": ["player_dodged"],
			"effect_value": 8.0,
			"feedback_text": "WARD"
		},
		"quig_offer_text": "Quig: \"Even its shelter looks hungry.\"",
		"wrong_detail": "bone plates growing inward as if trying to cage the heart"
	},
	"gorefane": {
		"species_id": "gorefane",
		"display_name": "Gorefane",
		"primary_type": "predator",
		"secondary_type": "flesh",
		"affinity": "flesh",
		"archetypes": ["mauler", "carrion"],
		"capture_threshold": 0.33,
		"bond_level": 1,
		"description": "It lives in the instant after the wound opens and before the body agrees.",
		"dna_threshold": 10.0,
		"eat_effect": {"type": "damage_flat", "value": 3.0},
		"bond_passive": {"type": "hp_on_kill", "value": 2.5},
		"support_role": {
			"readout_name": "Gorefane",
			"effect_id": "gorefane_maul",
			"trigger_on": ["ultimate_fired"],
			"effect_value": 14.0,
			"feedback_text": "MAUL"
		},
		"quig_offer_text": "Quig: \"It smiles before the wound learns its name.\"",
		"wrong_detail": "second jaw folding out from under the first"
	},
	"hushcoil": {
		"species_id": "hushcoil",
		"display_name": "Hushcoil",
		"primary_type": "veil",
		"secondary_type": "pressure",
		"affinity": "hush",
		"archetypes": ["suppressor", "serpent"],
		"capture_threshold": 0.24,
		"bond_level": 1,
		"description": "When it tightens, the field goes quiet enough to hear what is still hunting.",
		"dna_threshold": 9.0,
		"eat_effect": {"type": "hp_restore", "value": 12.0},
		"bond_passive": {"type": "parry_reflect_mult", "value": 0.25},
		"support_role": {
			"readout_name": "Hushcoil",
			"effect_id": "hushcoil_lull",
			"trigger_on": ["perfect_parry"],
			"effect_value": 7.0,
			"feedback_text": "LULL"
		},
		"quig_offer_text": "Quig: \"Keep your voice down. It likes the part before panic.\"",
		"wrong_detail": "throat lined with soft tissue that dampens every sound except yours"
	},
	"coldvein": {
		"species_id": "coldvein",
		"display_name": "Coldvein",
		"primary_type": "cadence",
		"secondary_type": "edge",
		"affinity": "cadence",
		"archetypes": ["counter", "razor"],
		"capture_threshold": 0.23,
		"bond_level": 1,
		"description": "It holds still through your opening. The stillness moves after.",
		"dna_threshold": 9.0,
		"eat_effect": {"type": "max_hp_flat", "value": 14.0},
		"bond_passive": {"type": "timed_damage_flat", "value": 2.5},
		"support_role": {
			"readout_name": "Coldvein",
			"effect_id": "coldvein_expose",
			"trigger_on": ["perfect_parry"],
			"effect_value": 11.0,
			"feedback_text": "EXPOSE"
		},
		"quig_offer_text": "Quig: \"Still enough you'll think it isn't watching. It is. You can't fix that now.\"",
		"wrong_detail": "pupils gone but something colder left behind in their place"
	},
	"siltgrip": {
		"species_id": "siltgrip",
		"display_name": "Siltgrip",
		"primary_type": "predator",
		"secondary_type": "gorge",
		"affinity": "gorge",
		"archetypes": ["lurker", "carrion"],
		"capture_threshold": 0.28,
		"bond_level": 1,
		"description": "It waits below where the kills land. Something in the current marks the spot.",
		"dna_threshold": 11.0,
		"eat_effect": {"type": "damage_flat", "value": 2.5},
		"bond_passive": {"type": "hp_on_kill", "value": 3.5},
		"support_role": {
			"readout_name": "Siltgrip",
			"effect_id": "siltgrip_drag",
			"trigger_on": ["enemy_defeated"],
			"effect_value": 9.0,
			"feedback_text": "DRAG"
		},
		"quig_offer_text": "Quig: \"If you stop killing, it notices the rhythm change. Don't stop.\"",
		"wrong_detail": "claws shaped for closing and not opening again"
	}
}

const ESCALATION_PROFILES := {
	"surge": {
		"cycle_interval": 0.72,
		"fire_stagger": 0.18,
		"desc": "Aggressive, fast, high pressure."
	},
	"bulwark": {
		"cycle_interval": 1.18,
		"fire_stagger": 0.38,
		"desc": "Defensive, slow, more time to read."
	},
	"cascade": {
		"cycle_interval": 0.92,
		"fire_stagger": 0.26,
		"desc": "Rising, wave-like escalation."
	}
}

const ENCOUNTER_GRADES := {
	"brood": {
		"label": "BROOD",
		"hp_mult": 0.90,
		"damage_mult": 0.92,
		"dna_mult": 0.85
	},
	"mature": {
		"label": "MATURE",
		"hp_mult": 1.0,
		"damage_mult": 1.0,
		"dna_mult": 1.0
	},
	"alpha": {
		"label": "ALPHA",
		"hp_mult": 1.18,
		"damage_mult": 1.15,
		"dna_mult": 1.25
	}
}

const DEFAULT_ENEMY_TELEGRAPH_PROFILE := {
	"family": "fang",
	"projectile_color": Color(0.95, 0.58, 0.22, 1.0),
	"accent_color": Color(1.0, 0.84, 0.58, 1.0),
	"lane_color": Color(0.92, 0.58, 0.20, 1.0),
	"marker_color": Color(0.96, 0.78, 0.48, 1.0),
	"warning_bias": 1.0
}

const ENEMY_TELEGRAPH_PROFILES := {
	"dreg": {
		"family": "fang",
		"projectile_color": Color(0.92, 0.54, 0.18, 1.0),
		"accent_color": Color(0.98, 0.76, 0.42, 1.0),
		"lane_color": Color(0.88, 0.40, 0.18, 1.0),
		"marker_color": Color(0.98, 0.72, 0.44, 1.0),
		"warning_bias": 1.0
	},
	"bond_reaper": {
		"family": "needle",
		"projectile_color": Color(0.82, 0.88, 0.98, 1.0),
		"accent_color": Color(0.62, 0.76, 1.0, 1.0),
		"lane_color": Color(0.70, 0.80, 0.98, 1.0),
		"marker_color": Color(0.76, 0.88, 1.0, 1.0),
		"warning_bias": 1.14
	},
	"sovereign": {
		"family": "sovereign",
		"projectile_color": Color(0.98, 0.68, 0.16, 1.0),
		"accent_color": Color(1.0, 0.88, 0.50, 1.0),
		"lane_color": Color(0.96, 0.54, 0.16, 1.0),
		"marker_color": Color(1.0, 0.82, 0.42, 1.0),
		"warning_bias": 1.18
	},
	"ashclaw": {
		"family": "fang",
		"projectile_color": Color(0.96, 0.62, 0.26, 1.0),
		"accent_color": Color(1.0, 0.84, 0.56, 1.0),
		"lane_color": Color(0.92, 0.42, 0.20, 1.0),
		"marker_color": Color(0.98, 0.74, 0.46, 1.0),
		"warning_bias": 1.04
	},
	"bond_remnant": {
		"family": "veil",
		"projectile_color": Color(0.80, 0.84, 0.96, 1.0),
		"accent_color": Color(0.66, 0.78, 1.0, 1.0),
		"lane_color": Color(0.60, 0.68, 0.94, 1.0),
		"marker_color": Color(0.80, 0.88, 1.0, 1.0),
		"warning_bias": 0.98
	},
	"gruvek": {
		"family": "mass",
		"projectile_color": Color(0.90, 0.58, 0.24, 1.0),
		"accent_color": Color(0.98, 0.78, 0.46, 1.0),
		"lane_color": Color(0.80, 0.42, 0.14, 1.0),
		"marker_color": Color(0.94, 0.72, 0.44, 1.0),
		"warning_bias": 0.90
	},
	"veilskin": {
		"family": "needle",
		"projectile_color": Color(0.74, 0.92, 1.0, 1.0),
		"accent_color": Color(0.84, 0.96, 1.0, 1.0),
		"lane_color": Color(0.62, 0.88, 1.0, 1.0),
		"marker_color": Color(0.82, 0.96, 1.0, 1.0),
		"warning_bias": 1.20
	},
	"thornback": {
		"family": "fang",
		"projectile_color": Color(0.94, 0.48, 0.30, 1.0),
		"accent_color": Color(1.0, 0.72, 0.52, 1.0),
		"lane_color": Color(0.90, 0.34, 0.22, 1.0),
		"marker_color": Color(0.98, 0.64, 0.52, 1.0),
		"warning_bias": 1.08
	},
	"knellspine": {
		"family": "chorus",
		"projectile_color": Color(0.96, 0.86, 0.42, 1.0),
		"accent_color": Color(1.0, 0.94, 0.62, 1.0),
		"lane_color": Color(0.92, 0.76, 0.24, 1.0),
		"marker_color": Color(1.0, 0.90, 0.56, 1.0),
		"warning_bias": 1.06
	},
	"marrowward": {
		"family": "mass",
		"projectile_color": Color(0.74, 0.86, 0.76, 1.0),
		"accent_color": Color(0.88, 0.96, 0.86, 1.0),
		"lane_color": Color(0.52, 0.74, 0.62, 1.0),
		"marker_color": Color(0.82, 0.92, 0.84, 1.0),
		"warning_bias": 0.94
	},
	"gorefane": {
		"family": "fang",
		"projectile_color": Color(0.98, 0.52, 0.30, 1.0),
		"accent_color": Color(1.0, 0.78, 0.58, 1.0),
		"lane_color": Color(0.94, 0.30, 0.18, 1.0),
		"marker_color": Color(0.98, 0.70, 0.52, 1.0),
		"warning_bias": 1.10
	},
	"hushcoil": {
		"family": "veil",
		"projectile_color": Color(0.62, 0.86, 0.78, 1.0),
		"accent_color": Color(0.82, 0.94, 0.88, 1.0),
		"lane_color": Color(0.42, 0.70, 0.62, 1.0),
		"marker_color": Color(0.76, 0.92, 0.86, 1.0),
		"warning_bias": 0.92
	},
	"coldvein": {
		"family": "needle",
		"projectile_color": Color(0.72, 0.88, 1.0, 1.0),
		"accent_color": Color(0.90, 0.96, 1.0, 1.0),
		"lane_color": Color(0.54, 0.82, 1.0, 1.0),
		"marker_color": Color(0.84, 0.94, 1.0, 1.0),
		"warning_bias": 1.18
	},
	"siltgrip": {
		"family": "mass",
		"projectile_color": Color(0.54, 0.78, 0.66, 1.0),
		"accent_color": Color(0.74, 0.90, 0.82, 1.0),
		"lane_color": Color(0.32, 0.64, 0.54, 1.0),
		"marker_color": Color(0.64, 0.86, 0.78, 1.0),
		"warning_bias": 0.88
	}
}

const CREATURE_ENCOUNTER_PROFILES := {
	"ashclaw": {
		"projectile_speed": 300.0,
		"dna_reward": 2.5,
		"marker_modulate": Color(0.96, 0.89, 0.82, 0.96),
		"encounter_summary": "Tracks your lane and punishes slack fear."
	},
	"bond_remnant": {
		"projectile_speed": 330.0,
		"dna_reward": 2.75,
		"marker_modulate": Color(0.84, 0.88, 0.98, 0.96),
		"status_flags": {"expose_duration_mult": 0.75},
		"encounter_summary": "Anchors pressure and steals the window you thought was yours."
	},
	"gruvek": {
		"projectile_speed": 248.0,
		"dna_reward": 3.0,
		"marker_modulate": Color(0.92, 0.72, 0.52, 0.96),
		"encounter_summary": "Slow weight that turns one mistake into a full meal."
	},
	"veilskin": {
		"projectile_speed": 450.0,
		"dna_reward": 3.0,
		"marker_modulate": Color(0.84, 0.96, 1.0, 0.98),
		"status_flags": {"expose_duration_mult": 0.60},
		"encounter_summary": "Precision pressure with almost nothing to read first."
	},
	"thornback": {
		"projectile_speed": 308.0,
		"dna_reward": 3.25,
		"marker_modulate": Color(0.96, 0.78, 0.70, 0.96),
		"encounter_summary": "Brutal follow-through that keeps wounds open."
	},
	"knellspine": {
		"projectile_speed": 365.0,
		"dna_reward": 2.25,
		"marker_modulate": Color(0.94, 0.88, 0.68, 0.96),
		"encounter_summary": "Keeps time against you and cuts when your rhythm grieves."
	},
	"marrowward": {
		"projectile_speed": 282.0,
		"dna_reward": 2.75,
		"marker_modulate": Color(0.84, 0.90, 0.84, 0.96),
		"encounter_summary": "Durable pressure that punishes hesitation more than panic."
	},
	"gorefane": {
		"projectile_speed": 332.0,
		"dna_reward": 3.0,
		"marker_modulate": Color(0.98, 0.78, 0.72, 0.96),
		"encounter_summary": "Finishes wounded lanes before they remember how to stand."
	},
	"hushcoil": {
		"projectile_speed": 272.0,
		"dna_reward": 2.75,
		"marker_modulate": Color(0.78, 0.92, 0.86, 0.96),
		"encounter_summary": "Suppresses pace and forces cleaner reads in the dark."
	},
	"coldvein": {
		"projectile_speed": 415.0,
		"dna_reward": 2.75,
		"marker_modulate": Color(0.78, 0.90, 1.0, 0.98),
		"status_flags": {"expose_duration_mult": 0.55},
		"encounter_summary": "Cold and still until the moment opens. The moment does not re-open."
	},
	"siltgrip": {
		"projectile_speed": 258.0,
		"dna_reward": 3.0,
		"marker_modulate": Color(0.52, 0.82, 0.72, 0.96),
		"encounter_summary": "Slow and patient — waits below the kill pace and drags what's left under."
	}
}

const ENCOUNTERS := {
   "feeding_hollow_01": {
	   "id": "feeding_hollow_01",
	   "title": "First Hunger",
	   "biome": BIOME_FEEDING_HOLLOW,
	   "reward_creature_pool": [CREATURES["ashclaw"], CREATURES["gruvek"], CREATURES["gorefane"]],
	   "escalation_profile": "surge",
	   "phase_intro_texts": [
		   "Something stirs above.",
		   "It learns your rhythm.",
		   "The hunger reveals itself."
	   ],
	   "phases": [
		   [
			   {"id": 0, "type": "dreg", "hp": 28.0, "damage": 7.0, "lane": 0}
		   ],
		   [
			   {"id": 1, "type": "dreg", "hp": 32.0, "damage": 8.0, "lane": 1}
		   ],
		   [
			   {"id": 2, "type": "dreg", "hp": 58.0, "damage": 13.0, "lane": 2}
		   ]
	   ]
   },
   "feeding_hollow_02": {
		"id": "feeding_hollow_02",
		"title": "Second Mouth",
		"biome": BIOME_FEEDING_HOLLOW,
		"reward_creature_pool": [CREATURES["bond_remnant"], CREATURES["veilskin"], CREATURES["marrowward"], CREATURES["hushcoil"]],
		"phase_intro_texts": [
			"It no longer waits for you.",
			"The flanks open.",
			"The hollow chooses a mouth."
		],
		"phases": [
			[
				{"id": 10, "type": "dreg", "hp": 32.0, "damage": 8.0, "lane": 1}
			],
			[
				{"id": 11, "type": "dreg", "hp": 24.0, "damage": 7.0, "lane": 0},
				{"id": 12, "type": "dreg", "hp": 24.0, "damage": 7.0, "lane": 2}
			],
			[
				{"id": 13, "type": "bond_reaper", "hp": 64.0, "damage": 15.0, "lane": 1}
			]
		]
	},
	"feeding_hollow_03": {
		"id": "feeding_hollow_03",
		"title": "Aftertaste",
		"biome": BIOME_FEEDING_HOLLOW,
		"reward_creature_pool": [CREATURES["thornback"], CREATURES["knellspine"]],
		"phase_intro_texts": [
			"It follows what you kept.",
			"The hollow presses the wound.",
			"One last mouth tests the bond."
		],
		"phases": [
			[
				{"id": 20, "type": "dreg", "hp": 28.0, "damage": 8.0, "lane": 0},
				{"id": 21, "type": "dreg", "hp": 28.0, "damage": 8.0, "lane": 2}
			],
			[
				{"id": 22, "type": "dreg", "hp": 26.0, "damage": 8.0, "lane": 1}
			],
			[
				{"id": 23, "type": "bond_reaper", "hp": 58.0, "damage": 14.0, "lane": 1}
			]
		]
	},
	"feeding_hollow_boss": {
		"id": "feeding_hollow_boss",
		"title": "THE HOLLOW SOVEREIGN",
		"is_boss": true,
		"boss_name": "THE HOLLOW SOVEREIGN",
		"boss_subtitle": "APEX OF THE HOLLOW",
		"biome": BIOME_FEEDING_HOLLOW_BOSS,
		"phase_intro_texts": [
			"It was always here.",
			"THE HOLLOW OPENS ITS FULL MOUTH."
		],
		"phases": [
			[
				{"id": 30, "type": "sovereign", "hp": 160.0, "damage": 18.0, "lane": 1}
			],
			[
				{"id": 31, "type": "sovereign", "hp": 60.0, "damage": 16.0, "lane": 0},
				{"id": 32, "type": "sovereign", "hp": 60.0, "damage": 16.0, "lane": 1},
				{"id": 33, "type": "sovereign", "hp": 60.0, "damage": 16.0, "lane": 2}
			]
		]
	}
}


static func get_biome(biome_id: String) -> Dictionary:
	match biome_id:
		"feeding_hollow":
			return BIOME_FEEDING_HOLLOW.duplicate(true)
		"pale_shelf":
			return BIOME_PALE_SHELF.duplicate(true)
		"drowned_cut":
			return BIOME_DROWNED_CUT.duplicate(true)
		_:
			return {}


static func get_creature(species_id: String) -> Dictionary:
	if not CREATURES.has(species_id):
		return {}
	return CREATURES[species_id].duplicate(true)


static func get_creature_encounter_summary(species_id: String) -> String:
	var profile: Dictionary = CREATURE_ENCOUNTER_PROFILES.get(species_id, {})
	return String(profile.get("encounter_summary", ""))


static func get_enemy_telegraph_profile(enemy: Dictionary) -> Dictionary:
	var merged: Dictionary = DEFAULT_ENEMY_TELEGRAPH_PROFILE.duplicate(true)
	var type_id: String = String(enemy.get("type", ""))
	var species_id: String = String(enemy.get("species_id", ""))

	if species_id != "" and ENEMY_TELEGRAPH_PROFILES.has(species_id):
		for key in ENEMY_TELEGRAPH_PROFILES[species_id].keys():
			merged[key] = ENEMY_TELEGRAPH_PROFILES[species_id][key]
	elif type_id != "" and ENEMY_TELEGRAPH_PROFILES.has(type_id):
		for key in ENEMY_TELEGRAPH_PROFILES[type_id].keys():
			merged[key] = ENEMY_TELEGRAPH_PROFILES[type_id][key]

	var explicit_profile: Dictionary = enemy.get("telegraph_profile", {})
	for key in explicit_profile.keys():
		merged[key] = explicit_profile[key]

	return merged


static func build_creature_enemy(entry: Dictionary) -> Dictionary:
	var species_id: String = String(entry.get("species_id", ""))
	var creature: Dictionary = get_creature(species_id)
	if creature.is_empty():
		return entry.duplicate(true)

	var enemy: Dictionary = entry.duplicate(true)
	var profile: Dictionary = CREATURE_ENCOUNTER_PROFILES.get(species_id, {})
	var grade_id: String = String(enemy.get("grade", "mature"))
	var grade: Dictionary = ENCOUNTER_GRADES.get(grade_id, ENCOUNTER_GRADES["mature"])
	var profile_flags: Dictionary = profile.get("status_flags", {})
	var entry_flags: Dictionary = enemy.get("status_flags", {})
	var merged_flags: Dictionary = profile_flags.duplicate(true)
	for key in entry_flags.keys():
		merged_flags[key] = entry_flags[key]

	enemy["species_id"] = species_id
	enemy["reward_species_id"] = String(enemy.get("reward_species_id", species_id))
	enemy["type"] = String(enemy.get("type", species_id))
	enemy["display_name"] = String(creature.get("display_name", species_id))
	enemy["projectile_speed"] = float(enemy.get("projectile_speed", profile.get("projectile_speed", 265.0)))
	enemy["marker_modulate"] = enemy.get("marker_modulate", profile.get("marker_modulate", Color(1.0, 1.0, 1.0, 1.0)))
	enemy["telegraph_profile"] = get_enemy_telegraph_profile(enemy)
	enemy["status_flags"] = merged_flags
	enemy["encounter_summary"] = String(profile.get("encounter_summary", ""))
	enemy["grade"] = grade_id
	enemy["grade_label"] = String(grade.get("label", "MATURE"))
	enemy["hp"] = float(enemy.get("hp", 28.0)) * float(grade.get("hp_mult", 1.0))
	enemy["damage"] = float(enemy.get("damage", 8.0)) * float(grade.get("damage_mult", 1.0))
	enemy["dna_reward"] = float(enemy.get("dna_reward", profile.get("dna_reward", 2.5))) * float(grade.get("dna_mult", 1.0))
	return enemy


static func get_support_role(species_id: String) -> Dictionary:
	var creature: Dictionary = get_creature(species_id)
	if creature.is_empty():
		return {}
	return creature.get("support_role", {}).duplicate(true)


static func get_creature_sprite_path(species_id: String) -> String:
	var creature: Dictionary = get_creature(species_id)
	if creature.is_empty():
		return ""
	return String(creature.get("sprite_path", ""))


static func get_creature_art_path(species_id: String, context: String = "default") -> String:
	var creature: Dictionary = get_creature(species_id)
	if creature.is_empty():
		return ""

	match context:
		"reward":
			return String(creature.get("reward_portrait_path", creature.get("sprite_path", "")))
		"support":
			return String(creature.get("support_portrait_path", creature.get("sprite_path", "")))
		"battlefield":
			return String(creature.get("battlefield_sprite_path", creature.get("sprite_path", "")))
		_:
			return String(creature.get("sprite_path", ""))


static func get_creature_combat_render(species_id: String) -> Dictionary:
	var creature: Dictionary = get_creature(species_id)
	if creature.is_empty():
		return {}

	var render: Dictionary = {
		"scale": 0.052,
		"world_offset": Vector2(-108.0, 74.0),
		"z_index": 5,
		"modulate": Color(0.90, 0.89, 0.86, 0.86)
	}
	var creature_render: Dictionary = creature.get("combat_render", {})
	for key in creature_render.keys():
		render[key] = creature_render[key]
	return render


static func get_encounter(encounter_id: String) -> Dictionary:
	if not ENCOUNTERS.has(encounter_id):
		return {}
	return ENCOUNTERS[encounter_id].duplicate(true)


static func build_mini_run_queue() -> Array:
	return [
		get_encounter("feeding_hollow_01"),
		get_encounter("feeding_hollow_02"),
		get_encounter("feeding_hollow_03"),
		get_encounter("feeding_hollow_boss")
	]
