extends RefCounted

const BIOME_FEEDING_HOLLOW := {
	"name": "The Feeding Hollow",
	"subtitle": "The place remembers every mouth.",
	"background_color": Color(0.10, 0.05, 0.06, 1.0),
	"lane_color": Color(0.34, 0.24, 0.26, 1.0),
	"enemy_active_color": Color(0.76, 0.21, 0.21, 1.0),
	"enemy_inactive_color": Color(0.38, 0.18, 0.18, 0.55),
	"ring_active_color": Color(0.98, 0.93, 0.68, 1.0),
	"ring_inactive_color": Color(0.58, 0.52, 0.44, 0.45),
	"victory_text": "THE HOLLOW YIELDS",
	"defeat_text": "YOU FED THE HOLLOW"
}

const BIOME_PALE_SHELF := {
	"name": "The Pale Shelf",
	"subtitle": "Nothing hides here. Neither do you.",
	"background_color": Color(0.06, 0.06, 0.10, 1.0),
	"lane_color": Color(0.28, 0.28, 0.40, 1.0),
	"enemy_active_color": Color(0.58, 0.60, 0.82, 1.0),
	"enemy_inactive_color": Color(0.26, 0.27, 0.42, 0.55),
	"ring_active_color": Color(0.84, 0.90, 1.00, 1.0),
	"ring_inactive_color": Color(0.50, 0.52, 0.64, 0.45),
	"victory_text": "THE SHELF YIELDS",
	"defeat_text": "EXPOSED AND CONSUMED"
}

const BIOME_DROWNED_CUT := {
	"name": "The Drowned Cut",
	"subtitle": "The water still remembers its weight.",
	"background_color": Color(0.04, 0.07, 0.08, 1.0),
	"lane_color": Color(0.16, 0.28, 0.30, 1.0),
	"enemy_active_color": Color(0.28, 0.72, 0.62, 1.0),
	"enemy_inactive_color": Color(0.13, 0.34, 0.32, 0.55),
	"ring_active_color": Color(0.68, 0.98, 0.88, 1.0),
	"ring_inactive_color": Color(0.42, 0.58, 0.56, 0.45),
	"victory_text": "THE CUT REMEMBERS",
	"defeat_text": "DROWNED IN THE WEIGHT"
}

const BIOME_FEEDING_HOLLOW_BOSS := {
	"name": "The Feeding Hollow",
	"subtitle": "It was always here.",
	"background_color": Color(0.07, 0.04, 0.03, 1.0),
	"lane_color": Color(0.36, 0.24, 0.10, 1.0),
	"enemy_active_color": Color(0.86, 0.58, 0.14, 1.0),
	"enemy_inactive_color": Color(0.43, 0.29, 0.07, 0.55),
	"ring_active_color": Color(0.98, 0.93, 0.68, 1.0),
	"ring_inactive_color": Color(0.58, 0.52, 0.44, 0.45),
	"victory_text": "SOVEREIGN FELLED",
	"defeat_text": "THE HOLLOW CONSUMED YOU"
}

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
		"description": "Something that learned to cut before it learned to stop.",
		"dna_threshold": 8.0,
		"sprite_path": "res://assets/creatures/ashclaw/forms/ashclaw_baby.png",
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
		"quig_offer_text": "Quig watches the claws, not you.",
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
		"description": "It holds the shape of something that survived its own end.",
		"dna_threshold": 8.0,
		"eat_effect": {"type": "damage_flat", "value": 1.0},
		"bond_passive": {"type": "damage_reduction_pct", "value": 0.08},
		"support_role": {
			"readout_name": "Bond Remnant",
			"effect_id": "bond_remnant_mend",
			"trigger_on": ["damage_taken_when_ready"],
			"effect_value": 6.0,
			"feedback_text": "REMNANT"
		},
		"quig_offer_text": "Quig does not look at it directly.",
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
		"description": "It does not wait to be full. It eats until the hunger is someone else's problem.",
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
		"quig_offer_text": "Quig smells it before he sees it.",
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
		"description": "It only moves when you give it a reason. The reason never survives.",
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
		"quig_offer_text": "Quig says nothing. It is already watching him.",
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
		"description": "Every hit it lands opens something that does not close cleanly.",
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
		"quig_offer_text": "Quig keeps his hands where it can see them.",
		"wrong_detail": "spines still growing — some through the wrong layers"
	}
}

const ENCOUNTERS := {
	"feeding_hollow_01": {
		"id": "feeding_hollow_01",
		"title": "First Hunger",
		"biome": BIOME_FEEDING_HOLLOW,
		"reward_creature_pool": [CREATURES["ashclaw"], CREATURES["gruvek"]],
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
				{"id": 2, "type": "bond_reaper", "hp": 58.0, "damage": 13.0, "lane": 2}
			]
		]
	},
	"feeding_hollow_02": {
		"id": "feeding_hollow_02",
		"title": "Second Mouth",
		"biome": BIOME_FEEDING_HOLLOW,
		"reward_creature_pool": [CREATURES["bond_remnant"], CREATURES["veilskin"]],
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
		"reward_creature_pool": [CREATURES["thornback"]],
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
