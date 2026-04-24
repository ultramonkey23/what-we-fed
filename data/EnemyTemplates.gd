extends RefCounted

# Enemy Templates - Modular enemy definitions with scaling and behavior patterns
# This system allows for easy creation of varied encounters without hardcoded data

# === EXPANDED ENEMY TEMPLATES ===
# Additional templates for more encounter variety

const ENEMY_TEMPLATES := {
	"dreg": {
		"base_hp": 28.0,
		"base_damage": 7.0,
		"base_defense": 0.0,
		"projectile_speed": 300.0,
		"attack_pattern": "single_shot",
		"telegraph_duration": 0.8,
		"expose_duration": 1.2,
		"spawn_weight": 1.0,
		"difficulty_tier": 1,
		"behaviour_tags": ["basic", "single_lane"]
	},
	"bond_reaper": {
		"base_hp": 64.0,
		"base_damage": 15.0,
		"base_defense": 2.0,
		"projectile_speed": 280.0,
		"attack_pattern": "charged_shot",
		"telegraph_duration": 1.2,
		"expose_duration": 1.0,
		"spawn_weight": 0.6,
		"difficulty_tier": 2,
		"behaviour_tags": ["elite", "pressure"]
	},
	"sovereign": {
		"base_hp": 160.0,
		"base_damage": 18.0,
		"base_defense": 4.0,
		"projectile_speed": 250.0,
		"attack_pattern": "multi_shot",
		"telegraph_duration": 1.5,
		"expose_duration": 0.8,
		"spawn_weight": 0.2,
		"difficulty_tier": 3,
		"behaviour_tags": ["boss", "multi_lane", "elite"]
	},
	# New enemy templates for variety
	"skitterer": {
		"base_hp": 22.0,
		"base_damage": 5.0,
		"base_defense": 0.0,
		"projectile_speed": 400.0,
		"attack_pattern": "rapid_shot",
		"telegraph_duration": 0.4,
		"expose_duration": 1.6,
		"spawn_weight": 0.8,
		"difficulty_tier": 1,
		"behaviour_tags": ["fast", "swarm", "basic"]
	},
	"brute": {
		"base_hp": 85.0,
		"base_damage": 12.0,
		"base_defense": 3.0,
		"projectile_speed": 200.0,
		"attack_pattern": "heavy_shot",
		"telegraph_duration": 1.8,
		"expose_duration": 0.6,
		"spawn_weight": 0.4,
		"difficulty_tier": 2,
		"behaviour_tags": ["tank", "slow", "pressure"]
	},
	"phantom": {
		"base_hp": 35.0,
		"base_damage": 9.0,
		"base_defense": 1.0,
		"projectile_speed": 350.0,
		"attack_pattern": "phase_shot",
		"telegraph_duration": 0.6,
		"expose_duration": 1.0,
		"spawn_weight": 0.5,
		"difficulty_tier": 2,
		"behaviour_tags": ["evasive", "tricky", "elite"]
	},
	"spitter": {
		"base_hp": 30.0,
		"base_damage": 6.0,
		"base_defense": 0.0,
		"projectile_speed": 320.0,
		"attack_pattern": "spread_shot",
		"telegraph_duration": 0.8,
		"expose_duration": 1.2,
		"spawn_weight": 0.6,
		"difficulty_tier": 1,
		"behaviour_tags": ["area", "crowd_control", "basic"]
	},
	"warden": {
		"base_hp": 120.0,
		"base_damage": 14.0,
		"base_defense": 5.0,
		"projectile_speed": 240.0,
		"attack_pattern": "guardian_shot",
		"telegraph_duration": 1.4,
		"expose_duration": 0.9,
		"spawn_weight": 0.3,
		"difficulty_tier": 2,
		"behaviour_tags": ["defensive", "support", "elite"]
	},
	"void_stalker": {
		"base_hp": 48.0,
		"base_damage": 16.0,
		"base_defense": 1.0,
		"projectile_speed": 380.0,
		"attack_pattern": "void_shot",
		"telegraph_duration": 0.7,
		"expose_duration": 1.1,
		"spawn_weight": 0.25,
		"difficulty_tier": 3,
		"behaviour_tags": ["elite", "fast", "late_game"]
	},
	"stalker": {
		"base_hp": 52.0,
		"base_damage": 14.0,
		"base_defense": 2.0,
		"approach_speed": 80.0,
		"spawn_weight": 0.45,
		"difficulty_tier": 2,
		"behaviour_tags": ["melee", "approach"]
	}
}

# Encounter Pools - Region-specific enemy combinations with difficulty scaling
const ENCOUNTER_POOLS := {
	"feeding_hollow": {
		"easy": [
			{"template": "dreg", "weight": 1.0, "lane_preference": "any"}
		],
		"medium": [
			{"template": "dreg", "weight": 0.7, "lane_preference": "any"},
			{"template": "bond_reaper", "weight": 0.3, "lane_preference": "center"}
		],
		"hard": [
			{"template": "dreg", "weight": 0.4, "lane_preference": "any"},
			{"template": "bond_reaper", "weight": 0.5, "lane_preference": "center"},
			{"template": "sovereign", "weight": 0.1, "lane_preference": "center"}
		]
	},
	"pale_shelf": {
		"easy": [
			{"template": "dreg", "weight": 1.0, "lane_preference": "edges"}
		],
		"medium": [
			{"template": "dreg", "weight": 0.6, "lane_preference": "edges"},
			{"template": "bond_reaper", "weight": 0.4, "lane_preference": "any"}
		],
		"hard": [
			{"template": "dreg", "weight": 0.3, "lane_preference": "edges"},
			{"template": "bond_reaper", "weight": 0.5, "lane_preference": "any"},
			{"template": "sovereign", "weight": 0.2, "lane_preference": "center"}
		]
	},
	"drowned_cut": {
		"easy": [
			{"template": "dreg", "weight": 1.0, "lane_preference": "center"}
		],
		"medium": [
			{"template": "dreg", "weight": 0.8, "lane_preference": "center"},
			{"template": "bond_reaper", "weight": 0.2, "lane_preference": "any"}
		],
		"hard": [
			{"template": "dreg", "weight": 0.5, "lane_preference": "center"},
			{"template": "bond_reaper", "weight": 0.3, "lane_preference": "any"},
			{"template": "sovereign", "weight": 0.2, "lane_preference": "center"}
		]
	}
}

# Encounter Patterns - Predefined phase structures for different encounter types
const ENCOUNTER_PATTERNS := {
	"single_wave": {
		"phases": 1,
		"enemies_per_phase": [1],
		"lane_distribution": ["single"],
		"description": "Single enemy in one lane"
	},
	"dual_wave": {
		"phases": 2,
		"enemies_per_phase": [1, 2],
		"lane_distribution": ["single", "edges"],
		"description": "One enemy, then two on edges"
	},
	"pressure_build": {
		"phases": 3,
		"enemies_per_phase": [1, 2, 1],
		"lane_distribution": ["single", "all", "center"],
		"description": "Build pressure with increasing complexity"
	},
	"boss_assault": {
		"phases": 2,
		"enemies_per_phase": [1, 3],
		"lane_distribution": ["center", "all"],
		"description": "Boss encounter with multi-phase assault"
	},
	# Additional encounter patterns for variety
	"swarm": {
		"phases": 3,
		"enemies_per_phase": [2, 3, 2],
		"lane_distribution": ["all", "all", "edges"],
		"description": "Swarm of weaker enemies with overwhelming numbers"
	},
	"pincer": {
		"phases": 2,
		"enemies_per_phase": [2, 1],
		"lane_distribution": ["edges", "center"],
		"description": "Pincer attack with flanking enemies"
	},
	"gauntlet": {
		"phases": 4,
		"enemies_per_phase": [1, 1, 2, 1],
		"lane_distribution": ["single", "center", "all", "single"],
		"description": "Progressive challenge with increasing difficulty"
	},
	"chaos": {
		"phases": 3,
		"enemies_per_phase": [1, 2, 3],
		"lane_distribution": ["random", "random", "random"],
		"description": "Unpredictable encounter with random lane distribution"
	},
	"fortress": {
		"phases": 2,
		"enemies_per_phase": [1, 2],
		"lane_distribution": ["center", "edges"],
		"description": "Defensive encounter with tanky enemies"
	},
	"ambush": {
		"phases": 1,
		"enemies_per_phase": [3],
		"lane_distribution": ["all"],
		"description": "Sudden ambush with multiple enemies"
	}
}

# Scaling modifiers for difficulty progression
const DIFFICULTY_SCALING := {
	"hp_mult": {
		"easy": 0.8,
		"medium": 1.0,
		"hard": 1.3,
		"extreme": 1.6
	},
	"damage_mult": {
		"easy": 0.9,
		"medium": 1.0,
		"hard": 1.2,
		"extreme": 1.4
	},
	"speed_mult": {
		"easy": 0.9,
		"medium": 1.0,
		"hard": 1.1,
		"extreme": 1.2
	}
}

# Utility functions for template-based enemy generation
static func get_template(template_id: String) -> Dictionary:
	if not ENEMY_TEMPLATES.has(template_id):
		push_error("Enemy template not found: " + template_id)
		return {}
	return ENEMY_TEMPLATES[template_id].duplicate(true)

static func get_encounter_pool(region: String, difficulty: String) -> Array:
	var pools: Dictionary = ENCOUNTER_POOLS.get(region, {})
	return pools.get(difficulty, [])

static func get_encounter_pattern(pattern_id: String) -> Dictionary:
	if not ENCOUNTER_PATTERNS.has(pattern_id):
		push_error("Encounter pattern not found: " + pattern_id)
		return {}
	return ENCOUNTER_PATTERNS[pattern_id].duplicate(true)

static func apply_scaling(base_stats: Dictionary, difficulty: String) -> Dictionary:
	var scaled: Dictionary = base_stats.duplicate(true)
	var scaling: Dictionary = DIFFICULTY_SCALING
	
	if scaling.has("hp_mult") and scaling["hp_mult"].has(difficulty):
		scaled["base_hp"] *= scaling["hp_mult"][difficulty]
	
	if scaling.has("damage_mult") and scaling["damage_mult"].has(difficulty):
		scaled["base_damage"] *= scaling["damage_mult"][difficulty]
	
	if scaling.has("speed_mult") and scaling["speed_mult"].has(difficulty):
		scaled["projectile_speed"] *= scaling["speed_mult"][difficulty]
	
	return scaled

static func generate_enemy_from_template(template_id: String, difficulty: String, enemy_id: int) -> Dictionary:
	var template: Dictionary = get_template(template_id)
	if template.is_empty():
		return {}
	
	var enemy: Dictionary = apply_scaling(template, difficulty)
	enemy["id"] = enemy_id
	enemy["type"] = template_id
	enemy["template_id"] = template_id
	
	return enemy

static func select_random_enemy_from_pool(region: String, difficulty: String) -> Dictionary:
	var pool: Array = get_encounter_pool(region, difficulty)
	if pool.is_empty():
		return {}
	
	# Weighted random selection
	var total_weight: float = 0.0
	for entry in pool:
		total_weight += float(entry.get("weight", 1.0))
	
	var roll: float = randf() * total_weight
	var current_weight: float = 0.0
	
	for entry in pool:
		current_weight += float(entry.get("weight", 1.0))
		if roll <= current_weight:
			var template_id: String = String(entry.get("template", "dreg"))
			return {"template": template_id, "lane_preference": entry.get("lane_preference", "any")}
	
	# Fallback
	return {"template": "dreg", "lane_preference": "any"}

static func assign_lane(preference: String, occupied_lanes: Array[int]) -> int:
	match preference:
		"center":
			if not 1 in occupied_lanes:
				return 1
		"edges":
			for lane in [0, 2]:
				if not lane in occupied_lanes:
					return lane
		"any":
			for lane in [0, 1, 2]:
				if not lane in occupied_lanes:
					return lane
	return 0  # Fallback
