extends Node

# Dynamic Encounter Generator - Creates encounters using templates and pools
# This system replaces hardcoded encounter data with procedural generation

const ENEMY_TEMPLATES = preload("res://data/EnemyTemplates.gd")
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")

signal encounter_generated(encounter_data: Dictionary)

# Generation parameters
var region_id: String = "feeding_hollow"
var difficulty: String = "medium"
var run_progress: float = 0.0  # 0.0 to 1.0
var encounter_index: int = 0

# Encounter generation history for variety
var used_patterns: Array[String] = []
var used_enemy_combinations: Array[Array] = []

func generate_encounter(encounter_type: String = "standard", custom_params: Dictionary = {}) -> Dictionary:
	var encounter_data: Dictionary = _base_encounter_structure()
	
	match encounter_type:
		"standard":
			encounter_data = _generate_standard_encounter(encounter_data, custom_params)
		"boss":
			encounter_data = _generate_boss_encounter(encounter_data, custom_params)
		"elite":
			encounter_data = _generate_elite_encounter(encounter_data, custom_params)
		"custom":
			encounter_data = _generate_custom_encounter(encounter_data, custom_params)
		_:
			encounter_data = _generate_standard_encounter(encounter_data, custom_params)
	
	# Apply biome and visual styling
	encounter_data = _apply_biome_styling(encounter_data)
	
	# Track generation history
	_track_generation(encounter_data)
	
	encounter_generated.emit(encounter_data)
	return encounter_data

func _base_encounter_structure() -> Dictionary:
	return {
		"id": "generated_" + str(encounter_index),
		"title": "Generated Encounter",
		"is_boss": false,
		"biome": {},
		"reward_creature_pool": [],
		"escalation_profile": "standard",
		"phase_intro_texts": [],
		"phases": [],
		"generation_metadata": {
			"region": region_id,
			"difficulty": difficulty,
			"run_progress": run_progress,
			"encounter_index": encounter_index
		}
	}

func _generate_standard_encounter(encounter_data: Dictionary, params: Dictionary) -> Dictionary:
	var pattern_id: String = params.get("pattern", _select_pattern_for_difficulty())
	var pattern: Dictionary = ENEMY_TEMPLATES.get_encounter_pattern(pattern_id)
	
	encounter_data["title"] = _generate_encounter_title(pattern_id)
	encounter_data["phase_intro_texts"] = _generate_phase_texts(pattern["phases"])
	encounter_data["phases"] = _generate_phases_from_pattern(pattern, params)
	
	return encounter_data

func _generate_boss_encounter(encounter_data: Dictionary, params: Dictionary) -> Dictionary:
	encounter_data["is_boss"] = true
	encounter_data["title"] = _generate_boss_title()
	encounter_data["escalation_profile"] = "boss"
	
	# Boss encounters always use the boss_assault pattern
	var pattern: Dictionary = ENEMY_TEMPLATES.get_encounter_pattern("boss_assault")
	encounter_data["phase_intro_texts"] = _generate_boss_phase_texts()
	encounter_data["phases"] = _generate_boss_phases(pattern, params)
	
	return encounter_data

func _generate_elite_encounter(encounter_data: Dictionary, params: Dictionary) -> Dictionary:
	encounter_data["title"] = _generate_elite_title()
	encounter_data["escalation_profile"] = "elite"
	
	# Elite encounters use pressure_build pattern with higher difficulty
	var pattern: Dictionary = ENEMY_TEMPLATES.get_encounter_pattern("pressure_build")
	var elite_params: Dictionary = params.duplicate(true)
	elite_params["difficulty_override"] = "hard"
	encounter_data["phase_intro_texts"] = _generate_elite_phase_texts()
	encounter_data["phases"] = _generate_phases_from_pattern(pattern, elite_params)
	
	return encounter_data

func _generate_custom_encounter(encounter_data: Dictionary, params: Dictionary) -> Dictionary:
	# Custom encounters allow full specification
	var phases: Array = params.get("phases", [])
	var phase_texts: Array = params.get("phase_texts", [])
	
	if phases.is_empty():
		# Fallback to standard generation
		return _generate_standard_encounter(encounter_data, params)
	
	encounter_data["title"] = params.get("title", "Custom Encounter")
	encounter_data["phase_intro_texts"] = phase_texts
	encounter_data["phases"] = phases
	
	return encounter_data

func _select_pattern_for_difficulty() -> String:
	var available_patterns: Array[String] = ["single_wave", "dual_wave", "pressure_build"]
	
	# Remove recently used patterns for variety
	var filtered_patterns: Array[String] = []
	for pattern in available_patterns:
		if not pattern in used_patterns:
			filtered_patterns.append(pattern)
	
	if filtered_patterns.is_empty():
		# Reset if all patterns have been used
		used_patterns.clear()
		filtered_patterns = available_patterns.duplicate()
	
	# Bias toward simpler patterns at lower difficulty
	match difficulty:
		"easy":
			return filtered_patterns.pick_random() if randf() > 0.7 else "single_wave"
		"medium":
			return filtered_patterns.pick_random()
		"hard":
			return filtered_patterns.pick_random() if randf() > 0.3 else "pressure_build"
		_:
			return filtered_patterns.pick_random()

func _generate_encounter_title(pattern_id: String) -> String:
	var titles: Dictionary = {
		"single_wave": ["First Warning", "Lone Hunter", "Single Strike"],
		"dual_wave": ["Flanking Attack", "Coordinated Strike", "Pincer Movement"],
		"pressure_build": ["Escalating Threat", "Growing Hunger", "Rising Pressure"]
	}
	
	var pattern_titles: Array = titles.get(pattern_id, ["Generated Encounter"])
	var base_title: String = pattern_titles.pick_random()
	
	# Add region-specific flavor
	var region_flavor: String = ""
	match region_id:
		"feeding_hollow":
			region_flavor = ["of the Hollow", "from the Depths", "of Hunger"].pick_random()
		"pale_shelf":
			region_flavor = ["of the Shelf", "from the Expanse", "of Stillness"].pick_random()
		"drowned_cut":
			region_flavor = ["of the Cut", "from the Depths", "of the Waters"].pick_random()
	
	return base_title + " " + region_flavor

func _generate_boss_title() -> String:
	var boss_names: Array = [
		"SOVEREIGN OF THE " + region_id.to_upper(),
		"APEX PREDATOR",
		"FINAL HUNGER",
		"ANCIENT TERROR"
	]
	return boss_names.pick_random()

func _generate_elite_title() -> String:
	var elite_names: Array = [
		"Elite Hunter",
		"Veteran Threat",
		"Alpha Predator",
		"Elite Guard"
	]
	return elite_names.pick_random()

func _generate_phase_texts(phase_count: int) -> Array[String]:
	var texts: Array[String] = []
	
	var openers: Array = ["Something stirs", "A presence emerges", "The ground shifts"]
	var mids: Array = ["It learns your rhythm", "The pressure builds", "It adapts to you"]
	var closers: Array = ["The final strike", "All or nothing", "The climax approaches"]
	
	for i in range(phase_count):
		if i == 0:
			texts.append(openers.pick_random())
		elif i == phase_count - 1:
			texts.append(closers.pick_random())
		else:
			texts.append(mids.pick_random())
	
	return texts

func _generate_boss_phase_texts() -> Array[String]:
	return [
		"The ancient presence awakens",
		"SOVEREIGN ASSAULT BEGINS"
	]

func _generate_elite_phase_texts() -> Array[String]:
	return [
		"An elite hunter appears",
		"It knows your tricks",
		"The true test begins"
	]

func _generate_phases_from_pattern(pattern: Dictionary, params: Dictionary) -> Array:
	var phases: Array = []
	var enemy_id_counter: int = 100 + encounter_index * 10
	
	var effective_difficulty: String = params.get("difficulty_override", difficulty)
	var occupied_lanes: Array[int] = []
	
	for phase_idx in range(pattern["phases"]):
		var phase_enemies: Array = []
		var enemies_in_phase: int = pattern["enemies_per_phase"][phase_idx]
		var lane_dist: String = pattern["lane_distribution"][phase_idx]
		
		occupied_lanes.clear()
		
		for enemy_idx in range(enemies_in_phase):
			var lane: int = _assign_lane_for_distribution(lane_dist, occupied_lanes, enemy_idx, enemies_in_phase)
			occupied_lanes.append(lane)
			
			var enemy_selection: Dictionary = ENEMY_TEMPLATES.select_random_enemy_from_pool(region_id, effective_difficulty)
			var template_id: String = enemy_selection.get("template", "dreg")
			
			var enemy: Dictionary = ENEMY_TEMPLATES.generate_enemy_from_template(template_id, effective_difficulty, enemy_id_counter)
			enemy["lane"] = lane
			enemy_id_counter += 1
			
			phase_enemies.append(enemy)
		
		phases.append(phase_enemies)
	
	return phases

func _generate_boss_phases(_pattern: Dictionary, _params: Dictionary) -> Array:
	var phases: Array = []
	var enemy_id_counter: int = 900 + encounter_index * 10
	
	# Phase 1: Single boss
	var boss_enemy: Dictionary = ENEMY_TEMPLATES.generate_enemy_from_template("sovereign", "hard", enemy_id_counter)
	boss_enemy["lane"] = 1
	enemy_id_counter += 1
	phases.append([boss_enemy])
	
	# Phase 2: Multiple boss enemies
	var multi_boss_phase: Array = []
	for lane in [0, 1, 2]:
		var boss_minion: Dictionary = ENEMY_TEMPLATES.generate_enemy_from_template("sovereign", "medium", enemy_id_counter)
		boss_minion["lane"] = lane
		boss_minion["base_hp"] *= 0.375  # 37.5% of boss HP
		boss_minion["base_damage"] *= 0.89  # 89% of boss damage
		enemy_id_counter += 1
		multi_boss_phase.append(boss_minion)
	
	phases.append(multi_boss_phase)
	
	return phases

func _assign_lane_for_distribution(distribution: String, occupied: Array[int], enemy_idx: int, _total_enemies: int) -> int:
	var dist_type: String = distribution
	match dist_type:
		"single":
			return 1  # Always center
		"edges":
			if enemy_idx == 0:
				return 0  # First enemy goes left
			else:
				return 2  # Second enemy goes right
		"all":
			# Distribute across all lanes
			for lane in [0, 1, 2]:
				if not lane in occupied:
					return lane
			return 0  # Fallback
		"center":
			return 1
		_:
			# Any available lane
			for lane in [0, 1, 2]:
				if not lane in occupied:
					return lane
			return 0

func _apply_biome_styling(encounter_data: Dictionary) -> Dictionary:
	# Get biome data from CombatContent
	var biome_id: String = region_id + "_boss" if encounter_data.get("is_boss", false) else region_id
	var biome: Dictionary = COMBAT_CONTENT.get_biome(biome_id)
	
	encounter_data["biome"] = biome
	
	# Generate reward creature pool based on region and difficulty
	var pool_size: int = 3
	if difficulty == "hard":
		pool_size = 4
	elif difficulty == "easy":
		pool_size = 2
	
	encounter_data["reward_creature_pool"] = _generate_reward_pool(pool_size)
	
	return encounter_data

func _generate_reward_pool(size: int) -> Array:
	# Get creatures appropriate for this region
	var region_creatures: Array = []
	
	# This would ideally be data-driven based on region affinity
	var all_creatures: Dictionary = COMBAT_CONTENT.CREATURES
	for creature_id in all_creatures:
		var creature: Dictionary = all_creatures[creature_id]
		# Simple region affinity check (could be more sophisticated)
		if randf() > 0.5:  # 50% chance for now
			region_creatures.append(creature)
	
	# Select random creatures for the pool
	var pool: Array = []
	var available_creatures: Array = region_creatures.duplicate()
	
	for i in range(min(size, available_creatures.size())):
		var index: int = randi() % available_creatures.size()
		pool.append(available_creatures[index])
		available_creatures.remove_at(index)
	
	return pool

func _track_generation(encounter_data: Dictionary) -> void:
	# Track used patterns for variety
	var phases: Array = encounter_data.get("phases", [])
	var pattern_id: String = "single_wave"  # Default fallback
	
	if phases.size() == 1 and phases[0].size() == 1:
		pattern_id = "single_wave"
	elif phases.size() == 2 and phases[0].size() == 1 and phases[1].size() == 2:
		pattern_id = "dual_wave"
	elif phases.size() == 3:
		pattern_id = "pressure_build"
	elif phases.size() == 2 and encounter_data.get("is_boss", false):
		pattern_id = "boss_assault"
	
	if not pattern_id in used_patterns:
		used_patterns.append(pattern_id)
	
	# Track enemy combinations for variety
	var enemy_combo: Array = []
	for phase in phases:
		var phase_types: Array = []
		for enemy in phase:
			phase_types.append(enemy.get("template", "unknown"))
		enemy_combo.append(phase_types)
	
	if not enemy_combo in used_enemy_combinations:
		used_enemy_combinations.append(enemy_combo)
	
	encounter_index += 1

func set_generation_params(region: String, diff: String, progress: float) -> void:
	region_id = region
	difficulty = diff
	run_progress = progress

func reset_history() -> void:
	used_patterns.clear()
	used_enemy_combinations.clear()
	encounter_index = 0
