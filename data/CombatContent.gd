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
	   "potential_max_grade": "alpha",
	   "base_hp": 60.0,
	   "base_damage": 10.0,
	   "base_defense": 2.0,
	   "description": "It learned to cut before it learned the cost of stopping.",
	   "dna_threshold": 8.0,
	   "sprite_path": "res://assets/creatures/ashclaw/forms/ashclaw_baby.png",
	   "reward_portrait_path": "res://assets/creatures/ashclaw/forms/ashclaw_baby.png",
	   "support_portrait_path": "res://assets/creatures/ashclaw/forms/ashclaw_teen.png",
	   "battlefield_sprite_path": "res://assets/creatures/ashclaw/forms/ashclaw_adult.png",
	   "combat_render": {
		   "scale": 0.22,
		   "world_offset": Vector2(-116.0, 82.0),
		   "z_index": 6,
		   "modulate": Color(0.92, 0.91, 0.88, 0.90),
		   "marker_modulate": Color(0.96, 0.93, 0.88, 0.94)
	   },
	   "eat_effect": {"type": "damage_flat", "value": 2.0},
	   "mutation": {
		   "id": "ashclaw_frenzy",
		   "display_name": "Ashclaw's Frenzy",
		   "summary": "Next 12 timed hits deal +4 damage",
		   "effect": {"type": "timed_damage_flat", "value": 4.0, "charges": 12}
	   },
	   "bond_passive": {"type": "damage_on_ultimate", "value": 5.0},
	   "support_role": {
		   "readout_name": "Ashclaw",
		   "effect_id": "ashclaw_strike",
		   "trigger_on": ["perfect_parry", "perfect_timed_attack"],
		   "effect_value": 10.0,
		   "feedback_text": "ASHCLAW",
		   "hud_trigger_hint": "Parry/timed hit"
	   },
	   "quig_offer_text": "Quig: \"Mind the claws. It reads fear as a cue.\"",
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
		   "potential_max_grade": "mature",
		   "base_hp": 52.0,
		   "base_damage": 7.0,
		   "base_defense": 3.0,
		   "description": "It holds the shape of something that stayed after its body did not.",
		   "dna_threshold": 8.0,
		   "sprite_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_idle.png",
		   "reward_portrait_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_idle.png",
		   "support_portrait_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_adult.png",
		   "battlefield_sprite_path": "res://assets/creatures/bond_remnant/forms/bond_remnant_adult.png",
		   "combat_render": {
			   "scale": 0.22,
			   "world_offset": Vector2(-124.0, 88.0),
			   "z_index": 6,
			   "modulate": Color(0.84, 0.88, 1.0, 0.85),
			   "marker_modulate": Color(0.88, 0.92, 1.0, 0.93)
		   },
		   "eat_effect": {"type": "damage_flat", "value": 1.0},
		   "mutation": {
			   "id": "remnant_mend",
			   "display_name": "Remnant's Mend",
			   "summary": "Next 4 hits taken partially mend themselves",
			   "effect": {"type": "heal_on_hit_taken", "value": 6.0, "charges": 4}
		   },
		   "bond_passive": {"type": "damage_reduction_pct", "value": 0.08},
		   "support_role": {
			   "readout_name": "Bond Remnant",
			   "effect_id": "bond_remnant_mend",
			   "trigger_on": ["damage_taken_when_ready"],
			   "effect_value": 6.0,
			   "feedback_text": "REMNANT",
			   "hud_trigger_hint": "Hit when charged"
		   },
		   "quig_offer_text": "Quig: \"Do not stare. It notices memory pressure.\"",
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
		"mutation": {
			"id": "gruvek_gorge",
			"display_name": "Gruvek's Gorge",
			"summary": "Next 6 kills grant double support charge",
			"effect": {"type": "support_charge_mult_on_kill", "value": 2.0, "charges": 6}
		},
		"bond_passive": {"type": "hp_on_kill", "value": 3.0},
		"support_role": {
			"readout_name": "Gruvek",
			"effect_id": "gruvek_gorge",
			"trigger_on": ["enemy_defeated"],
			"effect_value": 10.0,
			"feedback_text": "GORGE",
			"hud_trigger_hint": "Kill: gorge all"
		},
		"quig_offer_text": "Quig: \"You smell that first. Keep your lane clean.\"",
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
		"mutation": {
			"id": "veilskin_phase",
			"display_name": "Veilskin's Phase",
			"summary": "Next 6 perfect parries grant full stamina",
			"effect": {"type": "stamina_on_perfect_parry", "value": 100.0, "charges": 6}
		},
		"bond_passive": {"type": "parry_reflect_mult", "value": 0.40},
		"support_role": {
			"readout_name": "Veilskin",
			"effect_id": "veilskin_phase",
			"trigger_on": ["perfect_parry"],
			"effect_value": 12.0,
			"feedback_text": "PHASE",
			"hud_trigger_hint": "Perf.parry: phase"
		},
		"quig_offer_text": "Quig: \"If it blinks, your read was late.\"",
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
		"mutation": {
			"id": "thornback_rend",
			"display_name": "Thornback's Rend",
			"summary": "Next 8 timed attacks apply extra bleed (Rend)",
			"effect": {"type": "rend_on_hit", "charges": 3, "use_charges": 8}
		},
		"bond_passive": {"type": "timed_damage_flat", "value": 3.0},
		"support_role": {
			"readout_name": "Thornback",
			"effect_id": "thornback_rend",
			"trigger_on": ["perfect_timed_attack"],
			"effect_value": 20.0,
			"feedback_text": "REND",
			"hud_trigger_hint": "Perf.timed: rend"
		},
		"quig_offer_text": "Quig: \"Keep your hands visible. It counts movement.\"",
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
		"mutation": {
			"id": "knell_resonance",
			"display_name": "Knell's Resonance",
			"summary": "Next 10 hits on-beat grant +2 support charge",
			"effect": {"type": "support_charge_on_beat", "value": 2.0, "charges": 10}
		},
		"bond_passive": {"type": "timed_damage_flat", "value": 2.0},
		"support_role": {
			"readout_name": "Knellspine",
			"effect_id": "knellspine_peal",
			"trigger_on": ["good_timed_attack", "perfect_timed_attack"],
			"effect_value": 8.0,
			"feedback_text": "PEAL",
			"hud_trigger_hint": "Good+perf.timed"
		},
		"quig_offer_text": "Quig: \"When it starts singing, cut the rhythm first.\"",
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
		"mutation": {
			"id": "marrow_ward",
			"display_name": "Marrow's Ward",
			"summary": "Next 3 hits taken deal 0 damage",
			"effect": {"type": "invuln_hits", "charges": 3}
		},
		"bond_passive": {"type": "damage_reduction_pct", "value": 0.06},
		"support_role": {
			"readout_name": "Marrowward",
			"effect_id": "marrowward_ward",
			"trigger_on": ["player_dodged"],
			"effect_value": 8.0,
			"feedback_text": "WARD",
			"hud_trigger_hint": "Dodge: bone ward"
		},
		"quig_offer_text": "Quig: \"Its shelter is a mouth. Move early.\"",
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
		"mutation": {
			"id": "gore_frenzy",
			"display_name": "Gorefane's Frenzy",
			"summary": "Next 5 kills grant 25% ultimate power",
			"effect": {"type": "ultimate_on_kill", "value": 0.25, "charges": 5}
		},
		"bond_passive": {"type": "hp_on_kill", "value": 2.5},
		"support_role": {
			"readout_name": "Gorefane",
			"effect_id": "gorefane_maul",
			"trigger_on": ["ultimate_fired"],
			"effect_value": 14.0,
			"feedback_text": "MAUL",
			"hud_trigger_hint": "Ultimate: maul"
		},
		"quig_offer_text": "Quig: \"It commits before the wound speaks. Respect that.\"",
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
		"mutation": {
			"id": "hush_coil",
			"display_name": "Hushcoil's Lull",
			"summary": "Next 6 parries apply 'Pale' to all lanes",
			"effect": {"type": "pale_on_parry", "charges": 6}
		},
		"bond_passive": {"type": "parry_reflect_mult", "value": 0.25},
		"support_role": {
			"readout_name": "Hushcoil",
			"effect_id": "hushcoil_lull",
			"trigger_on": ["perfect_parry"],
			"effect_value": 7.0,
			"feedback_text": "LULL",
			"hud_trigger_hint": "Perf.parry: hush"
		},
		"quig_offer_text": "Quig: \"Keep your voice down. It hunts the first panic.\"",
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
		"mutation": {
			"id": "cold_expose",
			"display_name": "Coldvein's Exposure",
			"summary": "Next 4 perfect parries apply 'Expose' to all lanes",
			"effect": {"type": "expose_all_on_perfect_parry", "duration": 4.0, "charges": 4}
		},
		"bond_passive": {"type": "timed_damage_flat", "value": 2.5},
		"support_role": {
			"readout_name": "Coldvein",
			"effect_id": "coldvein_expose",
			"trigger_on": ["perfect_parry"],
			"effect_value": 11.0,
			"feedback_text": "EXPOSE",
			"hud_trigger_hint": "Perf.parry: seam"
		},
		"quig_offer_text": "Quig: \"Still enough to fool you. It is watching.\"",
		"wrong_detail": "pupils gone but something colder left behind in their place"
	},
	"pale_shelf_precision_stalker": {
		"species_id": "pale_shelf_precision_stalker",
		"display_name": "Glintstalker",
		"base_hp": 30.0,
		"base_damage": 10.0,
		"base_defense": 1.0,
		"dna_threshold": 9.0,
		"description": "It counts the silence between your pulses. When the gap widens, it stops being a shadow.",
		"sprite_path": "res://assets/creatures/pale_shelf/enemies/pale_shelf_precision_stalker.png",
		"battlefield_sprite_path": "res://assets/creatures/pale_shelf/enemies/pale_shelf_precision_stalker.png",
		"combat_render": {
			"scale": 0.052,
			"world_offset": Vector2(-108.0, 74.0),
			"z_index": 5,
			"modulate": Color(0.84, 0.96, 1.0, 0.88),
			"marker_modulate": Color(0.82, 0.96, 1.0, 0.92)
		},
		"wrong_detail": "joints clicking like frozen glass but leaving no tracks in the frost"
	},
	"pale_shelf_shardshroud_sentinel": {
		"species_id": "pale_shelf_shardshroud_sentinel",
		"display_name": "Shardhulk",
		"base_hp": 38.0,
		"base_damage": 10.0,
		"base_defense": 2.0,
		"dna_threshold": 8.0,
		"description": "A plated weight that expects you to panic. It closes the lane with the cold patience of a glacier.",
		"sprite_path": "res://assets/creatures/pale_shelf/enemies/pale_shelf_shardshroud_sentinel.png",
		"battlefield_sprite_path": "res://assets/creatures/pale_shelf/enemies/pale_shelf_shardshroud_sentinel.png",
		"combat_render": {
			"scale": 0.054,
			"world_offset": Vector2(-108.0, 74.0),
			"z_index": 5,
			"modulate": Color(0.86, 0.92, 0.88, 0.88),
			"marker_modulate": Color(0.88, 0.95, 0.90, 0.94)
		},
		"wrong_detail": "eyes frosted over but somehow focusing on your heat"
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
		"potential_max_grade": "brood",
		"description": "It waits below where the kills land. Something in the current marks the spot.",
		"dna_threshold": 11.0,
		"eat_effect": {"type": "damage_flat", "value": 2.5},
		"mutation": {
			"id": "silt_drag",
			"display_name": "Siltgrip's Drag",
			"summary": "Next 8 timed hits heal for 4",
			"effect": {"type": "heal_on_hit", "value": 4.0, "charges": 8}
		},
		"bond_passive": {"type": "hp_on_kill", "value": 3.5},
		"support_role": {
			"readout_name": "Siltgrip",
			"effect_id": "siltgrip_drag",
			"trigger_on": ["enemy_defeated"],
			"effect_value": 9.0,
			"feedback_text": "DRAG",
			"hud_trigger_hint": "Kill: heal+rend"
		},
		"quig_offer_text": "Quig: \"If your kill rhythm drops, it notices. Keep pressure.\"",
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

# Song section → shot modifier preset (Projectile: overlay texture shot1–6 + trail/glow tuning).
# Enemy-specific art lives under res://assets/sprites/projectile_bodies/<species_id or type>.png
const SECTION_SHOT_MODIFIER := {
	"opening": "fang",
	"intro": "fang",
	"verse": "needle",
	"verse_1": "needle",
	"verse_2": "needle",
	"rising": "mass",
	"pre_chorus": "needle",
	"pre_chorus_1": "needle",
	"pre_chorus_2": "needle",
	"chorus": "chorus",
	"chorus_1": "chorus",
	"chorus_2": "chorus",
	"final_chorus": "chorus",
	"boss_chorus": "chorus",
	"bridge": "veil",
	"breakdown": "veil",
	"final": "sovereign",
	"full_song": "sovereign"
}

const DEFAULT_PROJECTILE_BODY_PATH: String = "res://assets/sprites/projectile_bodies/dreg.png"
const PROJECTILE_BODY_ALIASES := {
	"pale_shelf_precision_stalker": "veilskin",
	"pale_shelf_shardshroud_sentinel": "marrowward"
}


static func get_shot_modifier_for_section(section_id: String) -> String:
	if section_id.is_empty():
		return "fang"
	if SECTION_SHOT_MODIFIER.has(section_id):
		return String(SECTION_SHOT_MODIFIER[section_id])
	return "fang"


static func get_projectile_body_resource_path(enemy: Dictionary) -> String:
	var key: String = String(enemy.get("species_id", ""))
	if key.is_empty():
		key = String(enemy.get("type", "dreg"))
	if key.is_empty():
		key = "dreg"
	var path: String = "res://assets/sprites/projectile_bodies/%s.png" % key
	if ResourceLoader.exists(path):
		return path
	var lower: String = key.to_lower()
	if lower != key:
		path = "res://assets/sprites/projectile_bodies/%s.png" % lower
		if ResourceLoader.exists(path):
			return path
	if PROJECTILE_BODY_ALIASES.has(key):
		var alias_key: String = String(PROJECTILE_BODY_ALIASES[key])
		path = "res://assets/sprites/projectile_bodies/%s.png" % alias_key
		if ResourceLoader.exists(path):
			return path
	return DEFAULT_PROJECTILE_BODY_PATH


const ENEMY_TELEGRAPH_PROFILES := {
	"dreg": {
		"family": "fang",
		"projectile_color": Color(0.92, 0.54, 0.18, 1.0),
		"accent_color": Color(0.98, 0.76, 0.42, 1.0),
		"lane_color": Color(0.88, 0.40, 0.18, 1.0),
		"marker_color": Color(0.98, 0.72, 0.44, 1.0),
		"reflected_color": Color(0.52, 0.98, 0.76, 1.0),
		"warning_bias": 1.0,
		"ring_thickness_base": 1.0
	},
	"bond_reaper": {
		"family": "needle",
		"species_shot_modifier": "needle",
		"projectile_color": Color(0.82, 0.88, 0.98, 1.0),
		"accent_color": Color(0.62, 0.76, 1.0, 1.0),
		"lane_color": Color(0.70, 0.80, 0.98, 1.0),
		"marker_color": Color(0.76, 0.88, 1.0, 1.0),
		"reflected_color": Color(0.46, 0.92, 1.0, 1.0),
		"warning_bias": 1.14,
		"ring_thickness_base": 0.85
	},
	"sovereign": {
		"family": "sovereign",
		"species_shot_modifier": "sovereign",
		"projectile_color": Color(0.98, 0.68, 0.16, 1.0),
		"accent_color": Color(1.0, 0.88, 0.50, 1.0),
		"lane_color": Color(0.96, 0.54, 0.16, 1.0),
		"marker_color": Color(1.0, 0.82, 0.42, 1.0),
		"reflected_color": Color(0.78, 1.0, 0.58, 1.0),
		"warning_bias": 1.18,
		"ring_thickness_base": 1.45
	},
	"ashclaw": {
		"family": "fang",
		"species_shot_modifier": "fang",
		# Ash-forward ember: reads as claw/forge grit, not generic orange bolt.
		"projectile_color": Color(0.90, 0.66, 0.50, 1.0),
		"accent_color": Color(0.98, 0.82, 0.58, 1.0),
		"lane_color": Color(0.82, 0.48, 0.28, 1.0),
		"marker_color": Color(0.94, 0.76, 0.52, 1.0),
		"reflected_color": Color(0.60, 0.98, 0.64, 1.0),
		"warning_bias": 1.04,
		"ring_thickness_base": 1.1
	},
	"bond_remnant": {
		"family": "veil",
		"species_shot_modifier": "veil",
		"projectile_color": Color(0.80, 0.84, 0.96, 1.0),
		"accent_color": Color(0.66, 0.78, 1.0, 1.0),
		"lane_color": Color(0.60, 0.68, 0.94, 1.0),
		"marker_color": Color(0.80, 0.88, 1.0, 1.0),
		"reflected_color": Color(0.50, 0.88, 1.0, 1.0),
		"warning_bias": 0.98,
		"ring_thickness_base": 0.9
	},
	"gruvek": {
		"family": "mass",
		"species_shot_modifier": "mass",
		"projectile_color": Color(0.90, 0.58, 0.24, 1.0),
		"accent_color": Color(0.98, 0.78, 0.46, 1.0),
		"lane_color": Color(0.80, 0.42, 0.14, 1.0),
		"marker_color": Color(0.94, 0.72, 0.44, 1.0),
		"reflected_color": Color(0.72, 1.0, 0.56, 1.0),
		"warning_bias": 0.90,
		"ring_thickness_base": 1.35
	},
	"veilskin": {
		"family": "needle",
		"species_shot_modifier": "needle",
		"projectile_color": Color(0.74, 0.92, 1.0, 1.0),
		"accent_color": Color(0.84, 0.96, 1.0, 1.0),
		"lane_color": Color(0.62, 0.88, 1.0, 1.0),
		"marker_color": Color(0.82, 0.96, 1.0, 1.0),
		"reflected_color": Color(0.42, 0.94, 1.0, 1.0),
		"warning_bias": 1.20,
		"ring_thickness_base": 0.8
	},
	"thornback": {
		"family": "fang",
		"species_shot_modifier": "needle",
		# Spine-bite: hotter and more crimson than Ashclaw's ash-ember lane read.
		"projectile_color": Color(0.96, 0.42, 0.34, 1.0),
		"accent_color": Color(1.0, 0.68, 0.48, 1.0),
		"lane_color": Color(0.88, 0.28, 0.22, 1.0),
		"marker_color": Color(0.98, 0.56, 0.44, 1.0),
		"reflected_color": Color(0.88, 1.0, 0.52, 1.0),
		"warning_bias": 1.08,
		"ring_thickness_base": 1.25
	},
	"knellspine": {
		"family": "chorus",
		"species_shot_modifier": "chorus",
		"projectile_color": Color(0.96, 0.86, 0.42, 1.0),
		"accent_color": Color(1.0, 0.94, 0.62, 1.0),
		"lane_color": Color(0.92, 0.76, 0.24, 1.0),
		"marker_color": Color(1.0, 0.90, 0.56, 1.0),
		"reflected_color": Color(0.92, 0.96, 0.52, 1.0),
		"warning_bias": 1.06,
		"ring_thickness_base": 1.15
	},
	"marrowward": {
		"family": "mass",
		"species_shot_modifier": "mass",
		"projectile_color": Color(0.74, 0.86, 0.76, 1.0),
		"accent_color": Color(0.88, 0.96, 0.86, 1.0),
		"lane_color": Color(0.52, 0.74, 0.62, 1.0),
		"marker_color": Color(0.82, 0.92, 0.84, 1.0),
		"reflected_color": Color(0.58, 1.0, 0.80, 1.0),
		"warning_bias": 0.94,
		"ring_thickness_base": 1.4
	},
	"gorefane": {
		"family": "fang",
		"species_shot_modifier": "mass",
		# Wet gore weight: heavier silhouette (mass) + saturated arterial read.
		"projectile_color": Color(0.98, 0.38, 0.26, 1.0),
		"accent_color": Color(1.0, 0.62, 0.46, 1.0),
		"lane_color": Color(0.92, 0.22, 0.14, 1.0),
		"marker_color": Color(0.98, 0.50, 0.36, 1.0),
		"reflected_color": Color(0.68, 1.0, 0.60, 1.0),
		"warning_bias": 1.10,
		"ring_thickness_base": 1.3
	},
	"hushcoil": {
		"family": "veil",
		"species_shot_modifier": "veil",
		"projectile_color": Color(0.62, 0.86, 0.78, 1.0),
		"accent_color": Color(0.82, 0.94, 0.88, 1.0),
		"lane_color": Color(0.42, 0.70, 0.62, 1.0),
		"marker_color": Color(0.76, 0.92, 0.86, 1.0),
		"reflected_color": Color(0.54, 0.86, 1.0, 1.0),
		"warning_bias": 0.92,
		"ring_thickness_base": 0.95
	},
	"coldvein": {
		"family": "needle",
		"species_shot_modifier": "needle",
		"projectile_color": Color(0.72, 0.88, 1.0, 1.0),
		"accent_color": Color(0.90, 0.96, 1.0, 1.0),
		"lane_color": Color(0.54, 0.82, 1.0, 1.0),
		"marker_color": Color(0.84, 0.94, 1.0, 1.0),
		"reflected_color": Color(0.44, 0.92, 1.0, 1.0),
		"warning_bias": 1.18,
		"ring_thickness_base": 0.85
	},
	"pale_shelf_precision_stalker": {
		"family": "needle",
		"species_shot_modifier": "needle",
		"projectile_color": Color(0.76, 0.90, 1.0, 1.0),
		"accent_color": Color(0.92, 0.98, 1.0, 1.0),
		"lane_color": Color(0.58, 0.84, 1.0, 1.0),
		"marker_color": Color(0.86, 0.96, 1.0, 1.0),
		"reflected_color": Color(0.48, 0.90, 1.0, 1.0),
		"warning_bias": 1.20,
		"ring_thickness_base": 0.85
	},
	"pale_shelf_shardshroud_sentinel": {
		"family": "mass",
		"species_shot_modifier": "mass",
		"projectile_color": Color(0.72, 0.84, 0.78, 1.0),
		"accent_color": Color(0.86, 0.94, 0.88, 1.0),
		"lane_color": Color(0.50, 0.72, 0.64, 1.0),
		"marker_color": Color(0.80, 0.90, 0.84, 1.0),
		"reflected_color": Color(0.56, 1.0, 0.78, 1.0),
		"warning_bias": 0.96,
		"ring_thickness_base": 1.4
	},
	"siltgrip": {
		"family": "mass",
		"species_shot_modifier": "mass",
		"projectile_color": Color(0.54, 0.78, 0.66, 1.0),
		"accent_color": Color(0.74, 0.90, 0.82, 1.0),
		"lane_color": Color(0.32, 0.64, 0.54, 1.0),
		"marker_color": Color(0.64, 0.86, 0.78, 1.0),
		"reflected_color": Color(0.48, 0.90, 0.80, 1.0),
		"warning_bias": 0.88,
		"ring_thickness_base": 1.3
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
	"pale_shelf_precision_stalker": {
		"projectile_speed": 430.0,
		"dna_reward": 2.75,
		"marker_modulate": Color(0.82, 0.94, 1.0, 0.98),
		"status_flags": {"expose_duration_mult": 0.55},
		"encounter_summary": "Predatory precision that counts the silence between your pulses."
	},
	"pale_shelf_shardshroud_sentinel": {
		"projectile_speed": 286.0,
		"dna_reward": 2.75,
		"marker_modulate": Color(0.84, 0.90, 0.86, 0.96),
		"encounter_summary": "Lane anchor that waits for panic with the cold patience of a glacier."
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
		"boss_subtitle": "THIS GROUND DOES NOT SHARE APEX",
		"biome": BIOME_FEEDING_HOLLOW_BOSS,
		"phase_intro_texts": [
			"It was always here.",
			"The hollow does not share apex."
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
	# Use explicit encounter values if present, otherwise fall back to CREATURES base stat fields.
	var base_hp = float(creature.get("base_hp", 28.0))
	var base_damage = float(creature.get("base_damage", 8.0))
	var base_defense = float(creature.get("base_defense", 0.0))

	enemy["hp"] = float(enemy.get("hp", base_hp)) * float(grade.get("hp_mult", 1.0))
	enemy["damage"] = float(enemy.get("damage", base_damage)) * float(grade.get("damage_mult", 1.0))
	enemy["defense"] = float(enemy.get("defense", base_defense))
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


static func get_creature_art_path(species_id: String, context: String = "default", stage: String = "baby") -> String:
	var creature: Dictionary = get_creature(species_id)
	if creature.is_empty():
		return ""

	var fallback_portrait: String = "res://assets/creatures/portraits/%s_portrait.png" % species_id
	var has_fallback_portrait: bool = ResourceLoader.exists(fallback_portrait)

	match context:
		"reward":
			var reward_path: String = String(creature.get("reward_portrait_path", creature.get("sprite_path", "")))
			if reward_path.is_empty() and has_fallback_portrait:
				return fallback_portrait
			return reward_path
		"support":
			if stage == "teen" or stage == "adult":
				var support_path: String = String(creature.get("support_portrait_path", creature.get("sprite_path", "")))
				if support_path.is_empty() and has_fallback_portrait:
					return fallback_portrait
				return support_path
			var sprite_path: String = String(creature.get("sprite_path", ""))
			if sprite_path.is_empty() and has_fallback_portrait:
				return fallback_portrait
			return sprite_path
		"battlefield":
			if stage == "adult":
				return String(creature.get("battlefield_sprite_path", creature.get("sprite_path", "")))
			if stage == "teen":
				return String(creature.get("support_portrait_path", creature.get("sprite_path", "")))
			return String(creature.get("sprite_path", ""))
		_:
			var default_path: String = String(creature.get("sprite_path", ""))
			if default_path.is_empty() and has_fallback_portrait:
				return fallback_portrait
			return default_path


static func get_creature_combat_render(species_id: String) -> Dictionary:
	var creature: Dictionary = get_creature(species_id)
	if creature.is_empty():
		return {}

	var render: Dictionary = {
		"scale": 0.18,
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
