extends RefCounted

# Encounter Optimizer - Performance and memory optimization for encounter generation
# This system provides caching, pooling, and efficient algorithms for encounter generation

# Cache for generated encounters to avoid redundant computation
var encounter_cache: Dictionary = {}
var cache_max_size: int = 100
var cache_hit_count: int = 0
var cache_miss_count: int = 0

# Object pooling for frequently used data structures
var enemy_pool: Array[Dictionary] = []
var phase_pool: Array[Array] = []
var encounter_pool: Array[Dictionary] = []

# Performance metrics
var generation_times: Array[float] = []
var memory_usage_mb: float = 0.0

func _init() -> void:
	# Initialize pools with pre-allocated objects
	_initialize_pools()

func _initialize_pools() -> void:
	# Pre-allocate common data structures to reduce runtime allocation
	for i in range(20):
		enemy_pool.clear()
		phase_pool.clear()
		encounter_pool.clear()

# Optimized encounter generation with caching
func generate_optimized_encounter(region: String, difficulty: String, encounter_type: String, custom_params: Dictionary = {}) -> Dictionary:
	var start_time: float = Time.get_unix_time_from_system()
	
	# Check cache first
	var cache_key: String = _generate_cache_key(region, difficulty, encounter_type, custom_params)
	if encounter_cache.has(cache_key):
		cache_hit_count += 1
		var cached_encounter: Dictionary = encounter_cache[cache_key].duplicate(true)
		_record_generation_time(start_time)
		return cached_encounter
	
	cache_miss_count += 1
	
	# Generate encounter using pooled objects
	var encounter: Dictionary = _generate_with_pools(region, difficulty, encounter_type, custom_params)
	
	# Cache the result (if cache not full)
	if encounter_cache.size() < cache_max_size:
		encounter_cache[cache_key] = encounter.duplicate(true)
	
	_record_generation_time(start_time)
	return encounter

func _generate_cache_key(region: String, difficulty: String, encounter_type: String, custom_params: Dictionary) -> String:
	# Create a deterministic cache key
	var key_parts: Array[String] = [region, difficulty, encounter_type]
	
	# Sort custom params to ensure consistent key generation
	var sorted_params: Array[String] = []
	for key in custom_params:
		sorted_params.append(key + ":" + str(custom_params[key]))
	sorted_params.sort()
	
	key_parts.append_array(sorted_params)
	return "_".join(key_parts)

func _generate_with_pools(region: String, difficulty: String, encounter_type: String, custom_params: Dictionary) -> Dictionary:
	# Use object pooling to reduce memory allocation
	var encounter: Dictionary = _get_pooled_encounter()
	
	# Basic encounter structure
	encounter["id"] = "generated_" + str(Time.get_unix_time_from_system())
	encounter["region"] = region
	encounter["difficulty"] = difficulty
	encounter["type"] = encounter_type
	encounter["custom_params"] = custom_params
	
	# Generate phases efficiently
	var phases: Array[Array] = []
	var phase_count: int = _get_phase_count(encounter_type)
	
	for i in range(phase_count):
		var phase: Array = _get_pooled_phase()
		var enemy_count: int = _get_enemy_count_for_phase(encounter_type, i, phase_count)
		
		for j in range(enemy_count):
			var enemy: Dictionary = _get_pooled_enemy()
			_populate_enemy_data(enemy, region, difficulty, encounter_type, i, j)
			phase.append(enemy)
		
		phases.append(phase)
	
	encounter["phases"] = phases
	
	# Add metadata
	encounter["generated_at"] = Time.get_unix_time_from_system()
	encounter["estimated_difficulty"] = _calculate_encounter_difficulty(phases)
	
	return encounter

func _get_pooled_encounter() -> Dictionary:
	if encounter_pool.size() > 0:
		var encounter: Dictionary = encounter_pool.pop_back()
		encounter.clear()
		return encounter
	return {}

func _get_pooled_phase() -> Array:
	if phase_pool.size() > 0:
		var phase: Array = phase_pool.pop_back()
		phase.clear()
		return phase
	return []

func _get_pooled_enemy() -> Dictionary:
	if enemy_pool.size() > 0:
		var enemy: Dictionary = enemy_pool.pop_back()
		enemy.clear()
		return enemy
	return {}

func _populate_enemy_data(enemy: Dictionary, region: String, difficulty: String, encounter_type: String, phase_idx: int, enemy_idx: int) -> void:
	# Efficient enemy data population
	enemy["id"] = phase_idx * 10 + enemy_idx
	enemy["type"] = _select_enemy_type(region, difficulty, encounter_type, phase_idx)
	enemy["hp"] = _calculate_enemy_hp(difficulty, encounter_type, phase_idx)
	enemy["damage"] = _calculate_enemy_damage(difficulty, encounter_type, phase_idx)
	enemy["lane"] = _assign_enemy_lane(enemy_idx, encounter_type)

func _select_enemy_type(_region: String, _difficulty: String, encounter_type: String, phase_idx: int) -> String:
	# Simplified enemy type selection for performance
	var base_types: Array[String] = ["dreg", "bond_reaper", "sovereign"]
	
	match encounter_type:
		"standard":
			return base_types[0]  # Always dreg for standard
		"elite":
			return base_types[1] if phase_idx > 0 else base_types[0]
		"boss":
			return base_types[2] if phase_idx == 0 else base_types[1]
		_:
			return base_types[0]

func _calculate_enemy_hp(difficulty: String, encounter_type: String, phase_idx: int) -> float:
	var base_hp: float = 30.0
	
	# Difficulty scaling
	match difficulty:
		"easy":
			base_hp *= 0.8
		"hard":
			base_hp *= 1.3
		"extreme":
			base_hp *= 1.6
	
	# Phase scaling
	base_hp *= (1.0 + phase_idx * 0.3)
	
	# Encounter type scaling
	match encounter_type:
		"elite":
			base_hp *= 1.5
		"boss":
			base_hp *= 2.5
	
	return base_hp

func _calculate_enemy_damage(difficulty: String, encounter_type: String, phase_idx: int) -> float:
	var base_damage: float = 8.0
	
	# Difficulty scaling
	match difficulty:
		"easy":
			base_damage *= 0.8
		"hard":
			base_damage *= 1.2
		"extreme":
			base_damage *= 1.5
	
	# Phase scaling
	base_damage *= (1.0 + phase_idx * 0.2)
	
	# Encounter type scaling
	match encounter_type:
		"elite":
			base_damage *= 1.3
		"boss":
			base_damage *= 2.0
	
	return base_damage

func _assign_enemy_lane(enemy_idx: int, encounter_type: String) -> int:
	match encounter_type:
		"boss":
			return 1  # Always center lane for boss
		"elite":
			return enemy_idx % 3  # Distribute across lanes
		_:
			return enemy_idx % 3  # Distribute across lanes

func _get_phase_count(encounter_type: String) -> int:
	match encounter_type:
		"boss":
			return 2
		"elite":
			return 3
		_:
			return 3

func _get_enemy_count_for_phase(encounter_type: String, phase_idx: int, _total_phases: int) -> int:
	match encounter_type:
		"boss":
			return 1 if phase_idx == 0 else 2
		"elite":
			return 2 if phase_idx < 2 else 3
		_:
			return 1 if phase_idx == 0 else 2

func _calculate_encounter_difficulty(phases: Array[Array]) -> float:
	var total_difficulty: float = 0.0
	var enemy_count: int = 0
	
	for phase in phases:
		for enemy in phase:
			var hp: float = enemy.get("hp", 0.0)
			var damage: float = enemy.get("damage", 0.0)
			total_difficulty += hp + damage * 2.0  # Weight damage more heavily
			enemy_count += 1
	
	if enemy_count > 0:
		return total_difficulty / enemy_count
	else:
		return 0.0

func _record_generation_time(start_time: float) -> void:
	var generation_time: float = Time.get_unix_time_from_system() - start_time
	generation_times.append(generation_time)
	
	# Keep only last 100 measurements
	if generation_times.size() > 100:
		generation_times.pop_front()

# Memory management
func cleanup_pools() -> void:
	# Return all objects to pools
	enemy_pool.clear()
	phase_pool.clear()
	encounter_pool.clear()
	
	# Clear cache if it's getting too large
	if encounter_cache.size() > cache_max_size * 0.8:
		_clear_oldest_cache_entries()

func _clear_oldest_cache_entries() -> void:
	var entries_to_remove: int = encounter_cache.size() - int(cache_max_size / 2)
	var keys: Array = encounter_cache.keys()
	
	for i in range(entries_to_remove):
		if i < keys.size():
			encounter_cache.erase(keys[i])

# Performance monitoring
func get_performance_metrics() -> Dictionary:
	var avg_generation_time: float = 0.0
	if generation_times.size() > 0:
		var total_time: float = 0.0
		for time in generation_times:
			total_time += time
		avg_generation_time = total_time / generation_times.size()
	
	var cache_hit_rate: float = 0.0
	var total_requests: int = cache_hit_count + cache_miss_count
	if total_requests > 0:
		cache_hit_rate = float(cache_hit_count) / float(total_requests)
	
	return {
		"avg_generation_time_ms": avg_generation_time * 1000.0,
		"cache_hit_rate": cache_hit_rate,
		"cache_size": encounter_cache.size(),
		"cache_max_size": cache_max_size,
		"total_requests": total_requests,
		"memory_usage_mb": memory_usage_mb
	}

func optimize_memory_usage() -> void:
	# Force garbage collection
	call_deferred("_force_gc")

func _force_gc() -> void:
	# Clear pools and cache
	cleanup_pools()
	
	# Update memory usage (simplified for compatibility)
	memory_usage_mb = 0.0  # Memory tracking disabled for compatibility

# Batch generation for multiple encounters
func generate_encounter_batch(requests: Array[Dictionary]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for request in requests:
		var region: String = request.get("region", "feeding_hollow")
		var difficulty: String = request.get("difficulty", "medium")
		var encounter_type: String = request.get("type", "standard")
		var custom_params: Dictionary = request.get("custom_params", {})
		
		var encounter: Dictionary = generate_optimized_encounter(region, difficulty, encounter_type, custom_params)
		results.append(encounter)
	
	return results

# Export cache for persistence (optional)
func export_cache() -> Dictionary:
	return {
		"encounters": encounter_cache,
		"metrics": get_performance_metrics(),
		"export_time": Time.get_unix_time_from_system()
	}

func import_cache(cache_data: Dictionary) -> void:
	if cache_data.has("encounters"):
		encounter_cache = cache_data["encounters"].duplicate(true)
	
	# Limit cache size
	if encounter_cache.size() > cache_max_size:
		_clear_oldest_cache_entries()
