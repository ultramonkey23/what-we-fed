extends RefCounted

# Procedural Level Generator - Creates varied levels using existing structure
# This system generates new level configurations while maintaining compatibility

# Generation parameters
const GENERATION_PARAMS: Dictionary = {
	"phase_count_range": [2, 4],  # Number of phases per level
	"enemy_types_per_phase": [1, 3],  # Different enemy types per phase
	"difficulty_variance": 0.3,  # How much difficulty can vary
	"special_chance": 0.2,  # Chance for special phase patterns
	"boss_phase_count": 5,  # Fixed for boss levels
	"synergy_bonus": 0.15  # Bonus for synergistic enemy combinations
}

# Phase pattern templates
const PHASE_PATTERNS: Dictionary = {
	"wave_assault": {
		"description": "Sequential waves of increasing intensity",
		"structure": "progressive_waves",
		"difficulty_curve": "rising"
	},
	"chaos_spam": {
		"description": "Random enemies with high spawn rate",
		"structure": "random_spam",
		"difficulty_curve": "flat"
	},
	"boss_preview": {
		"description": "Mini-boss with supporting enemies",
		"structure": "elite_plus_support",
		"difficulty_curve": "spiked"
	},
	"stealth_ambush": {
		"description": "Enemies appear suddenly from stealth",
		"structure": "ambush_pattern",
		"difficulty_curve": "variable"
	},
	"defensive_hold": {
		"description": "Few tough enemies that require strategy",
		"structure": "tank_brawl",
		"difficulty_curve": "plateau"
	},
	"speed_run": {
		"description": "Many weak enemies with fast timing",
		"structure": "swarm_pattern",
		"difficulty_curve": "accelerating"
	}
}

# Enemy combination synergies
const ENEMY_SYNERGIES: Dictionary = {
	"dreg_skitterer": {
		"name": "Swarm Foundation",
		"description": "Basic swarm with speed variety",
		"synergy_bonus": 0.1,
		"recommended_pattern": "wave_assault"
	},
	"dreg_bond_reaper": {
		"name": "Balanced Threat",
		"description": "Mix of basic and elite enemies",
		"synergy_bonus": 0.15,
		"recommended_pattern": "boss_preview"
	},
	"bond_reaper_phantom": {
		"name": "Ethereal Assault",
		"description": "Elite enemies with evasion",
		"synergy_bonus": 0.2,
		"recommended_pattern": "stealth_ambush"
	},
	"brute_warden": {
		"name": "Fortress Defense",
		"description": "High defense, high health enemies",
		"synergy_bonus": 0.25,
		"recommended_pattern": "defensive_hold"
	},
	"spitter_void_stalker": {
		"name": "Area Denial",
		"description": "Area damage with high mobility",
		"synergy_bonus": 0.2,
		"recommended_pattern": "chaos_spam"
	}
}

# Generate a complete procedural level
static func generate_procedural_level(
	level_number: int,
	seed_value: int = 0,
	difficulty_modifier: float = 1.0,
	theme: String = "default"
) -> Dictionary:
	# Set seed for reproducible generation
	if seed_value != 0:
		seed(seed_value)
	
	var is_boss = level_number >= 10
	var level_data = _create_base_level_structure(level_number, is_boss)
	
	# Generate phases
	var phases = _generate_phases(level_number, is_boss, difficulty_modifier, theme)
	level_data["phases"] = phases
	
	# Add procedural metadata
	level_data["procedural"] = {
		"seed": seed_value,
		"difficulty_modifier": difficulty_modifier,
		"theme": theme,
		"generation_timestamp": Time.get_unix_time_from_system()
	}
	
	return level_data

# Generate phases for a level
static func _generate_phases(
	level_number: int,
	is_boss: bool,
	difficulty_modifier: float,
	theme: String
) -> Array[Dictionary]:
	var phases: Array[Dictionary] = []
	var phase_count = _determine_phase_count(is_boss)
	var available_enemies = _get_available_enemies(level_number)
	var total_duration = 240.0 if is_boss else 120.0
	
	for phase_index in range(phase_count):
		var phase_start = (float(phase_index) / float(phase_count)) * total_duration
		var phase_duration = total_duration / float(phase_count)
		
		var phase = _generate_phase(
			phase_index,
			phase_start,
			phase_duration,
			level_number,
			available_enemies,
			difficulty_modifier,
			theme
		)
		
		phases.append(phase)
	
	return phases

# Generate individual phase
static func _generate_phase(
	phase_index: int,
	start_time: float,
	duration: float,
	level_number: int,
	available_enemies: Array[String],
	difficulty_modifier: float,
	theme: String
) -> Dictionary:
	# Choose phase pattern
	var pattern = _choose_phase_pattern(phase_index, level_number)
	var pattern_data = PHASE_PATTERNS[pattern]
	
	# Determine enemy composition
	var enemy_composition = _generate_enemy_composition(
		available_enemies,
		pattern,
		phase_index,
		level_number
	)
	
	# Calculate phase parameters
	var cycle_interval = _calculate_cycle_interval(pattern, level_number, phase_index)
	var max_threats = _calculate_max_threats(pattern, level_number, phase_index)
	
	# Apply difficulty modifier
	cycle_interval /= difficulty_modifier
	max_threats = int(max_threats * difficulty_modifier)
	
	# Create phase data
	var phase = {
		"id": "procedural_phase_" + str(phase_index),
		"label": _generate_phase_label(pattern, phase_index),
		"start_time": start_time,
		"cycle_interval": cycle_interval,
		"max_active_threats": max_threats,
		"enemy_pool": enemy_composition,
		"intro_text": _generate_intro_text(pattern, phase_index),
		"pattern": pattern,
		"theme": theme
	}
	
	# Add pattern-specific properties
	_add_pattern_properties(phase, pattern, level_number)
	
	return phase

# Generate enemy composition for a phase
static func _generate_enemy_composition(
	available_enemies: Array[String],
	pattern: String,
	phase_index: int,
	level_number: int
) -> Array[Dictionary]:
	var composition: Array[Dictionary] = []
	var enemy_count = randi_range(1, min(3, available_enemies.size()))
	
	# Select enemies based on pattern requirements
	var selected_enemies = _select_enemies_for_pattern(available_enemies, pattern, enemy_count)
	
	# Generate enemy data with procedural stats
	for i in range(selected_enemies.size()):
		var enemy_type = selected_enemies[i]
		var enemy_data = _generate_procedural_enemy(enemy_type, level_number, phase_index)
		
		# Calculate weight based on enemy type and pattern
		var weight = _calculate_enemy_weight(enemy_type, pattern, i)
		enemy_data["weight"] = weight
		
		composition.append(enemy_data)
	
	# Normalize weights
	_normalize_enemy_weights(composition)
	
	return composition

# Generate procedural enemy stats
static func _generate_procedural_enemy(
	enemy_type: String,
	level_number: int,
	phase_index: int
) -> Dictionary:
	# Get base template
	var base_template = _get_enemy_template(enemy_type)
	
	# Apply procedural variations
	var hp_variation = randf_range(0.8, 1.2)
	var damage_variation = randf_range(0.9, 1.1)
	var speed_variation = randf_range(0.95, 1.05)
	
	# Scale based on level and phase
	var level_scale = 1.0 + (float(level_number - 1) * 0.1)
	var phase_scale = 1.0 + (float(phase_index) * 0.05)
	
	return {
		"type": enemy_type,
		"hp": base_template["hp"] * hp_variation * level_scale * phase_scale,
		"damage": base_template["damage"] * damage_variation * level_scale * phase_scale,
		"speed": base_template.get("speed", 1.0) * speed_variation,
		"defense": base_template.get("defense", 0.0),
		"special_properties": _generate_special_properties(enemy_type, level_number)
	}

# Choose phase pattern based on level and position
static func _choose_phase_pattern(phase_index: int, level_number: int) -> String:
	var available_patterns = PHASE_PATTERNS.keys()
	
	# Early levels: simpler patterns
	if level_number <= 3:
		available_patterns = ["wave_assault", "chaos_spam"]
	# Mid levels: more variety
	elif level_number <= 6:
		available_patterns = ["wave_assault", "chaos_spam", "boss_preview", "stealth_ambush"]
	# Late levels: all patterns
	else:
		available_patterns = PHASE_PATTERNS.keys()
	
	# Special chance for complex patterns
	if randf() < GENERATION_PARAMS["special_chance"]:
		available_patterns = ["boss_preview", "stealth_ambush", "defensive_hold", "speed_run"]
	
	return available_patterns[randi() % available_patterns.size()]

# Generate themed levels
static func generate_themed_level(theme: String, level_number: int) -> Dictionary:
	var theme_params = _get_theme_parameters(theme)
	var seed_value = hash(theme + str(level_number) + str(Time.get_unix_time_from_system()))
	
	return generate_procedural_level(
		level_number,
		seed_value,
		theme_params.get("difficulty_modifier", 1.0),
		theme
	)

# Get available themes
static func get_available_themes() -> Array[String]:
	return [
		"fire_and_ice",
		"nature_chaos",
		"tech_mayhem",
		"cosmic_horror",
		"shadow_realm",
		"crystal_dreams",
		"toxic_wasteland",
		"electric_storm"
	]

# Validate generated level
static func validate_procedural_level(level_data: Dictionary) -> Dictionary:
	var validation_result = {
		"valid": true,
		"issues": [],
		"warnings": [],
		"stats": {}
	}
	
	# Check basic structure
	if not level_data.has("phases"):
		validation_result["valid"] = false
		validation_result["issues"].append("Missing phases")
		return validation_result
	
	var phases = level_data["phases"]
	validation_result["stats"]["phase_count"] = phases.size()
	
	# Check phase timing
	var total_duration = 0.0
	for phase in phases:
		if not phase.has("start_time") or not phase.has("cycle_interval"):
			validation_result["issues"].append("Invalid phase timing")
			continue
		
		total_duration += phase.get("duration", 60.0)
	
	validation_result["stats"]["total_duration"] = total_duration
	
	# Check enemy balance
	var total_threats = 0
	for phase in phases:
		if phase.has("max_active_threats"):
			total_threats += phase["max_active_threats"]
	
	validation_result["stats"]["total_threats"] = total_threats
	
	# Check for reasonable values
	if total_threats > 50:
		validation_result["warnings"].append("Very high threat count")
	
	if total_duration > 300 or total_duration < 60:
		validation_result["warnings"].append("Unusual duration")
	
	return validation_result

# Private helper functions

static func _create_base_level_structure(level_number: int, is_boss: bool) -> Dictionary:
	return {
		"level_number": level_number,
		"is_boss": is_boss,
		"duration": 240.0 if is_boss else 120.0,
		"difficulty_tier": _get_difficulty_tier(level_number),
		"reward_tier": _get_reward_tier(level_number)
	}

static func _determine_phase_count(is_boss: bool) -> int:
	if is_boss:
		return GENERATION_PARAMS["boss_phase_count"]
	else:
		return randi_range(
			GENERATION_PARAMS["phase_count_range"][0],
			GENERATION_PARAMS["phase_count_range"][1]
		)

static func _get_available_enemies(level_number: int) -> Array[String]:
	var all_enemies = ["dreg", "skitterer", "bond_reaper", "spitter", "phantom", "brute", "warden", "void_stalker", "sovereign"]
	var available = []
	
	# Progressive enemy unlocking
	var unlock_schedule = [
		["dreg"],  # Level 1
		["dreg", "skitterer"],  # Level 2
		["dreg", "skitterer", "bond_reaper"],  # Level 3
		["dreg", "skitterer", "bond_reaper", "spitter"],  # Level 4
		["dreg", "skitterer", "bond_reaper", "spitter", "phantom"],  # Level 5
		["dreg", "skitterer", "bond_reaper", "spitter", "phantom", "brute"],  # Level 6
		["dreg", "skitterer", "bond_reaper", "spitter", "phantom", "brute", "warden"],  # Level 7
		["dreg", "skitterer", "bond_reaper", "spitter", "phantom", "brute", "warden", "void_stalker"],  # Level 8+
		["dreg", "skitterer", "bond_reaper", "spitter", "phantom", "brute", "warden", "void_stalker", "sovereign"]  # Boss
	]
	
	var schedule_index = min(level_number - 1, unlock_schedule.size() - 1)
	return unlock_schedule[schedule_index]

static func _get_enemy_template(enemy_type: String) -> Dictionary:
	# Simplified enemy templates (would normally reference EnemyTemplates.gd)
	var templates = {
		"dreg": {"hp": 30.0, "damage": 8.0, "speed": 1.0},
		"skitterer": {"hp": 22.0, "damage": 5.0, "speed": 1.3},
		"bond_reaper": {"hp": 60.0, "damage": 14.0, "speed": 0.9},
		"spitter": {"hp": 30.0, "damage": 6.0, "speed": 1.0},
		"phantom": {"hp": 35.0, "damage": 9.0, "speed": 1.1},
		"brute": {"hp": 85.0, "damage": 12.0, "speed": 0.8},
		"warden": {"hp": 120.0, "damage": 14.0, "speed": 0.7},
		"void_stalker": {"hp": 50.0, "damage": 16.0, "speed": 1.2},
		"sovereign": {"hp": 160.0, "damage": 18.0, "speed": 0.6}
	}
	
	return templates.get(enemy_type, templates["dreg"])

static func _select_enemies_for_pattern(
	available_enemies: Array[String],
	pattern: String,
	count: int
) -> Array[String]:
	var selected = []
	var enemies_copy = available_enemies.duplicate()
	
	# Pattern-specific enemy selection
	match pattern:
		"wave_assault":
			# Progressive enemies - start with weakest
			enemies_copy.sort()
		"chaos_spam":
			# Random selection
			enemies_copy.shuffle()
		"boss_preview":
			# Include at least one tough enemy
			var tough_enemies = enemies_copy.filter(func(e): return e in ["brute", "warden", "void_stalker", "sovereign"])
			if not tough_enemies.is_empty():
				selected.append(tough_enemies[0])
				enemies_copy.erase(tough_enemies[0])
		"stealth_ambush":
			# Prefer fast/stealthy enemies
			var stealth_enemies = enemies_copy.filter(func(e): return e in ["skitterer", "phantom", "void_stalker"])
			if not stealth_enemies.is_empty():
				selected.append(stealth_enemies[0])
				enemies_copy.erase(stealth_enemies[0])
	
	# Fill remaining slots
	while selected.size() < count and not enemies_copy.is_empty():
		var enemy = enemies_copy[randi() % enemies_copy.size()]
		selected.append(enemy)
		enemies_copy.erase(enemy)
	
	return selected

static func _calculate_enemy_weight(enemy_type: String, pattern: String, index: int) -> float:
	var base_weight = 1.0
	
	# Pattern adjustments
	match pattern:
		"wave_assault":
			base_weight = 1.0 + (float(index) * 0.2)  # Later enemies more common
		"chaos_spam":
			base_weight = randf_range(0.5, 1.5)  # Random weights
		"boss_preview":
			base_weight = 0.8 if index == 0 else 1.2  # Boss enemy less common
		"stealth_ambush":
			base_weight = 1.3  # Higher spawn rate for ambush
		"defensive_hold":
			base_weight = 0.7  # Lower spawn rate, tougher enemies
		"speed_run":
			base_weight = 1.5  # High spawn rate
	
	return base_weight

static func _normalize_enemy_weights(enemies: Array[Dictionary]) -> void:
	var total_weight = 0.0
	for enemy in enemies:
		total_weight += enemy["weight"]
	
	if total_weight > 0:
		for enemy in enemies:
			enemy["weight"] /= total_weight

static func _calculate_cycle_interval(pattern: String, level_number: int, phase_index: int) -> float:
	var base_interval = 2.0
	
	# Pattern adjustments
	match pattern:
		"wave_assault":
			base_interval = 2.5 - (float(phase_index) * 0.3)
		"chaos_spam":
			base_interval = 1.2
		"boss_preview":
			base_interval = 2.0
		"stealth_ambush":
			base_interval = 1.8
		"defensive_hold":
			base_interval = 3.0
		"speed_run":
			base_interval = 0.8
	
	# Level scaling
	base_interval *= (1.0 - (float(level_number - 1) * 0.05))
	
	return max(0.5, base_interval)

static func _calculate_max_threats(pattern: String, level_number: int, phase_index: int) -> int:
	var base_threats = 2
	
	# Pattern adjustments
	match pattern:
		"wave_assault":
			base_threats = 2 + phase_index
		"chaos_spam":
			base_threats = 5
		"boss_preview":
			base_threats = 3
		"stealth_ambush":
			base_threats = 4
		"defensive_hold":
			base_threats = 2
		"speed_run":
			base_threats = 6
	
	# Level scaling
	base_threats += int(level_number / 3.0)
	
	return min(base_threats, 8)

static func _generate_phase_label(pattern: String, phase_index: int) -> String:
	var pattern_names = {
		"wave_assault": "Wave " + str(phase_index + 1),
		"chaos_spam": "Chaos " + str(phase_index + 1),
		"boss_preview": "Elite Assault " + str(phase_index + 1),
		"stealth_ambush": "Ambush " + str(phase_index + 1),
		"defensive_hold": "Defense " + str(phase_index + 1),
		"speed_run": "Speed Run " + str(phase_index + 1)
	}
	
	return pattern_names.get(pattern, "Phase " + str(phase_index + 1))

static func _generate_intro_text(pattern: String, phase_index: int) -> String:
	var intros = {
		"wave_assault": [
			"The first wave approaches.",
			"They come in greater numbers.",
			"The assault intensifies.",
			"All hell breaks loose."
		],
		"chaos_spam": [
			"Chaos erupts!",
			"More chaos incoming!",
			"Pure madness!",
			"Total pandemonium!"
		],
		"boss_preview": [
			"A mini-boss appears.",
			"Elite forces incoming.",
			"The champions arrive.",
			"The ultimate test."
		],
		"stealth_ambush": [
			"They strike from the shadows.",
			"Hidden dangers lurk.",
			"Invisible threats.",
			"Death from nowhere."
		],
		"defensive_hold": [
			"Fortify your position.",
			"The walls hold for now.",
			"Stand your ground.",
			"The final defense."
		],
		"speed_run": [
			"Fast and furious!",
			"Lightning fast!",
			"Blinding speed!",
			"Hypersonic assault!"
		]
	}
	
	var pattern_intros = intros.get(pattern, ["A new challenge begins."])
	var index = min(phase_index, pattern_intros.size() - 1)
	return pattern_intros[index]

static func _add_pattern_properties(phase: Dictionary, pattern: String, level_number: int) -> void:
	match pattern:
		"stealth_ambush":
			phase["stealth_chance"] = 0.4
			phase["surprise_bonus"] = 1.2
		"boss_preview":
			phase["elite_enemy"] = true
			phase["support_enemies"] = true
		"speed_run":
			phase["speed_multiplier"] = 1.5
			phase["time_pressure"] = true
		"defensive_hold":
			phase["armor_bonus"] = 1.3
			phase["strategic_required"] = true

static func _generate_special_properties(enemy_type: String, level_number: int) -> Dictionary:
	var properties = {}
	
	# Level-based special properties
	if level_number >= 5:
		properties["enhanced_ai"] = true
	if level_number >= 7:
		properties["coordinated_attacks"] = true
	if level_number >= 9:
		properties["adaptive_behavior"] = true
	
	# Enemy-type specific properties
	match enemy_type:
		"void_stalker":
			properties["phase_shift"] = true
		"phantom":
			properties["invisibility"] = true
		"sovereign":
			properties["multi_attack"] = true
			properties["area_damage"] = true
	
	return properties

static func _get_theme_parameters(theme: String) -> Dictionary:
	var themes = {
		"fire_and_ice": {"difficulty_modifier": 1.1, "enemy_focus": ["brute", "warden"]},
		"nature_chaos": {"difficulty_modifier": 1.0, "enemy_focus": ["skitterer", "spitter"]},
		"tech_mayhem": {"difficulty_modifier": 1.2, "enemy_focus": ["void_stalker", "sovereign"]},
		"cosmic_horror": {"difficulty_modifier": 1.3, "enemy_focus": ["phantom", "void_stalker"]},
		"shadow_realm": {"difficulty_modifier": 1.15, "enemy_focus": ["phantom", "bond_reaper"]},
		"crystal_dreams": {"difficulty_modifier": 0.9, "enemy_focus": ["warden", "spitter"]},
		"toxic_wasteland": {"difficulty_modifier": 1.05, "enemy_focus": ["spitter", "brute"]},
		"electric_storm": {"difficulty_modifier": 1.1, "enemy_focus": ["skitterer", "void_stalker"]}
	}
	
	return themes.get(theme, {"difficulty_modifier": 1.0, "enemy_focus": []})

static func _get_difficulty_tier(level_number: int) -> String:
	if level_number <= 2:
		return "easy"
	elif level_number <= 4:
		return "medium"
	elif level_number <= 6:
		return "hard"
	elif level_number <= 8:
		return "very_hard"
	else:
		return "extreme"

static func _get_reward_tier(level_number: int) -> String:
	if level_number <= 2:
		return "common"
	elif level_number <= 4:
		return "uncommon"
	elif level_number <= 6:
		return "rare"
	elif level_number <= 8:
		return "epic"
	else:
		return "legendary"
