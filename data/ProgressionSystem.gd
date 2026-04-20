extends RefCounted

# Progression System - Handles save/load and player progression tracking
# This system integrates with all existing systems without breaking them

# Save data structure
const SAVE_VERSION: String = "1.0"
const SAVE_FORMAT: Dictionary = {
	"version": SAVE_VERSION,
	"timestamp": 0,
	"player_data": {},
	"run_history": [],
	"unlocked_content": {},
	"achievements": [],
	"statistics": {},
	"settings": {}
}

# Player progression data
static func create_default_player_data() -> Dictionary:
	return {
		"current_level": 1,
		"current_run": {},
		"total_runs_completed": 0,
		"total_levels_completed": 0,
		"total_playtime": 0.0,
		"creatures_unlocked": [],
		"upgrades_purchased": [],
		"highest_level_reached": 1,
		"current_streak": 0,
		"best_streak": 0,
		"total_damage_dealt": 0.0,
		"total_enemies_defeated": 0,
		"total_rewards_collected": []
	}

# Run data structure
static func create_run_data() -> Dictionary:
	return {
		"run_id": "",
		"start_time": 0,
		"end_time": 0,
		"levels_completed": [],
		"rewards_earned": [],
		"performance_data": {},
		"difficulty_settings": {},
		"variations_used": [],
		"final_score": 0.0,
		"completed": false
	}

# Save current game state
static func save_game(
	player_data: Dictionary,
	current_run: Dictionary,
	slot: int = 0
) -> bool:
	var save_data = SAVE_FORMAT.duplicate(true)
	
	# Update save data
	save_data["timestamp"] = Time.get_unix_time_from_system()
	save_data["player_data"] = player_data.duplicate(true)
	save_data["current_run"] = current_run.duplicate(true)
	
	# Add to run history if run is completed
	if current_run.get("completed", false):
		var run_history = save_data["run_history"]
		run_history.append(current_run.duplicate(true))
		
		# Keep only last 50 runs
		if run_history.size() > 50:
			run_history = run_history.slice(-50)
		save_data["run_history"] = run_history
	
	# Save to file
	var save_path = "user://save_slot_" + str(slot) + ".json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to open save file: " + save_path)
		return false
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	
	return true

# Load game state
static func load_game(slot: int = 0) -> Dictionary:
	var save_path = "user://save_slot_" + str(slot) + ".json"
	var file = FileAccess.open(save_path, FileAccess.READ)
	
	if file == null:
		print("No save file found at slot " + str(slot))
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse save file")
		return {}
	
	var save_data = json.data
	
	# Validate save version
	if not save_data.has("version") or save_data["version"] != SAVE_VERSION:
		print("Save version mismatch, attempting migration")
		save_data = _migrate_save_data(save_data)
	
	return save_data

# Create new game
static func create_new_game(slot: int = 0) -> Dictionary:
	var player_data = create_default_player_data()
	var current_run = create_run_data()
	
	# Generate unique run ID
	current_run["run_id"] = _generate_run_id()
	current_run["start_time"] = Time.get_unix_time_from_system()
	
	# Save initial state
	if save_game(player_data, current_run, slot):
		return {
			"player_data": player_data,
			"current_run": current_run,
			"load_success": true
		}
	else:
		return {"load_success": false}

# Update player progress after level completion
static func update_level_progress(
	player_data: Dictionary,
	current_run: Dictionary,
	level_number: int,
	performance_data: Dictionary,
	rewards_earned: Array[Dictionary]
) -> Dictionary:
	# Update run data
	current_run["levels_completed"].append(level_number)
	current_run["rewards_earned"].append_array(rewards_earned)
	current_run["performance_data"][str(level_number)] = performance_data
	
	# Update player data
	player_data["current_level"] = level_number + 1
	player_data["total_levels_completed"] += 1
	
	# Add rewards to collection
	for reward in rewards_earned:
		if not reward["id"] in player_data["total_rewards_collected"]:
			player_data["total_rewards_collected"].append(reward["id"])
	
	# Update statistics
	player_data["total_damage_dealt"] += performance_data.get("damage_dealt", 0.0)
	player_data["total_enemies_defeated"] += performance_data.get("enemies_defeated", 0)
	
	# Check for new unlocks
	var unlocks = _check_unlocks(player_data, current_run)
	
	return {
		"player_data": player_data,
		"current_run": current_run,
		"new_unlocks": unlocks
	}

# Complete run and calculate final score
static func complete_run(
	player_data: Dictionary,
	current_run: Dictionary,
	final_performance: Dictionary
) -> Dictionary:
	# Update run completion data
	current_run["end_time"] = Time.get_unix_time_from_system()
	current_run["completed"] = true
	current_run["final_performance"] = final_performance
	
	# Calculate final score
	var score = _calculate_run_score(current_run)
	current_run["final_score"] = score
	
	# Update player statistics
	player_data["total_runs_completed"] += 1
	player_data["total_playtime"] += current_run["end_time"] - current_run["start_time"]
	
	# Update streak
	if score > 0.7:  # Good performance
		player_data["current_streak"] += 1
		player_data["best_streak"] = max(player_data["best_streak"], player_data["current_streak"])
	else:
		player_data["current_streak"] = 0
	
	# Update highest level reached
	var levels_completed = current_run["levels_completed"].size()
	if levels_completed > 0:
		player_data["highest_level_reached"] = max(
			player_data["highest_level_reached"],
			levels_completed
		)
	
	# Check for achievements
	var new_achievements = _check_achievements(player_data, current_run)
	
	return {
		"player_data": player_data,
		"current_run": current_run,
		"final_score": score,
		"new_achievements": new_achievements
	}

# Get progression statistics
static func get_progression_statistics(player_data: Dictionary, run_history: Array) -> Dictionary:
	var stats = {}
	
	# Basic stats
	stats["total_runs"] = player_data.get("total_runs_completed", 0)
	stats["total_levels"] = player_data.get("total_levels_completed", 0)
	stats["total_playtime"] = player_data.get("total_playtime", 0.0)
	stats["highest_level"] = player_data.get("highest_level_reached", 1)
	stats["current_streak"] = player_data.get("current_streak", 0)
	stats["best_streak"] = player_data.get("best_streak", 0)
	
	# Run statistics
	if not run_history.is_empty():
		var scores = run_history.map(func(run): return run.get("final_score", 0.0))
		var durations = run_history.map(func(run): return run.get("end_time", 0) - run.get("start_time", 0))
		
		stats["average_score"] = _calculate_average(scores)
		stats["best_score"] = scores.max() if not scores.is_empty() else 0.0
		stats["average_run_duration"] = _calculate_average(durations)
		stats["completion_rate"] = float(run_history.filter(func(run): return run.get("completed", false)).size()) / float(run_history.size())
	
	# Reward statistics
	var all_rewards = player_data.get("total_rewards_collected", [])
	stats["unique_rewards"] = all_rewards.size()
	stats["reward_completion_rate"] = float(all_rewards.size()) / float(_get_total_possible_rewards())
	
	# Performance trends
	if run_history.size() >= 5:
		var recent_runs = run_history.slice(-5)
		var recent_scores = recent_runs.map(func(run): return run.get("final_score", 0.0))
		stats["recent_performance"] = _calculate_average(recent_scores)
		stats["performance_trend"] = _calculate_performance_trend(run_history)
	
	return stats

# Export save data for backup
static func export_save_data(slot: int = 0) -> String:
	var save_data = load_game(slot)
	return JSON.stringify(save_data)

# Import save data from backup
static func import_save_data(json_string: String, slot: int = 0) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse import data")
		return false
	
	var save_data = json.data
	
	# Validate and migrate if needed
	if not save_data.has("version") or save_data["version"] != SAVE_VERSION:
		save_data = _migrate_save_data(save_data)
	
	# Save imported data
	var save_path = "user://save_slot_" + str(slot) + ".json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to write imported save file")
		return false
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	
	return true

# Private helper functions

static func _generate_run_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random = randi() % 10000
	return "run_" + str(timestamp) + "_" + str(random)

static func _migrate_save_data(old_data: Dictionary) -> Dictionary:
	# Handle save data migration between versions
	var new_data = SAVE_FORMAT.duplicate(true)
	
	# Copy compatible data
	if old_data.has("player_data"):
		new_data["player_data"] = old_data["player_data"]
	
	if old_data.has("run_history"):
		new_data["run_history"] = old_data["run_history"]
	
	# Add migration-specific logic here as needed
	
	return new_data

static func _check_unlocks(player_data: Dictionary, current_run: Dictionary) -> Array[String]:
	var unlocks: Array[String] = []
	
	# Check for creature unlocks
	var creatures_unlocked = player_data.get("creatures_unlocked", [])
	var rewards_collected = player_data.get("total_rewards_collected", [])
	
	var creature_rewards = ["ashclaw", "gruvek", "bond_remnant", "veilskin"]
	for creature in creature_rewards:
		if creature in rewards_collected and not creature in creatures_unlocked:
			creatures_unlocked.append(creature)
			unlocks.append("creature_" + creature)
	
	player_data["creatures_unlocked"] = creatures_unlocked
	
	return unlocks

static func _calculate_run_score(run_data: Dictionary) -> float:
	var score = 0.0
	
	# Base score from levels completed
	var levels_completed = run_data.get("levels_completed", []).size()
	score += float(levels_completed) * 0.1  # 10% per level
	
	# Performance bonus
	var performance_data = run_data.get("performance_data", {})
	for level_data in performance_data.values():
		var level_score = _calculate_level_performance_score(level_data)
		score += level_score * 0.05  # 5% per level performance
	
	# Completion bonus
	if run_data.get("completed", false):
		score += 0.3  # 30% for completing the run
	
	# Difficulty bonus
	var difficulty_settings = run_data.get("difficulty_settings", {})
	var difficulty_multiplier = difficulty_settings.get("multiplier", 1.0)
	score *= min(difficulty_multiplier, 1.5)  # Cap at 50% bonus
	
	# Time bonus (faster completion = higher score)
	var duration = run_data.get("end_time", 0) - run_data.get("start_time", 0)
	var expected_duration = 1200.0  # 20 minutes expected
	if duration > 0 and duration < expected_duration:
		var time_bonus = (expected_duration - duration) / expected_duration * 0.2
		score += time_bonus
	
	return min(score, 1.0)  # Cap at 100%

static func _calculate_level_performance_score(performance_data: Dictionary) -> float:
	var score = 0.0
	
	# Damage dealt (higher is better)
	var damage_dealt = performance_data.get("damage_dealt", 0.0)
	score += min(damage_dealt / 1000.0, 0.3)  # Cap at 30%
	
	# Enemies defeated (higher is better)
	var enemies_defeated = performance_data.get("enemies_defeated", 0)
	score += min(float(enemies_defeated) / 50.0, 0.3)  # Cap at 30%
	
	# Accuracy (higher is better)
	var accuracy = performance_data.get("accuracy", 0.0)
	score += accuracy * 0.2  # 20%
	
	# Time survived (higher is better)
	var time_survived = performance_data.get("time_survived", 0.0)
	score += min(time_survived / 120.0, 0.2)  # Cap at 20%
	
	return min(score, 1.0)

static func _check_achievements(player_data: Dictionary, current_run: Dictionary) -> Array[String]:
	var achievements: Array[String] = []
	
	# First run completion
	if player_data.get("total_runs_completed", 0) == 1:
		achievements.append("first_run_complete")
	
	# Level milestones
	var total_levels = player_data.get("total_levels_completed", 0)
	if total_levels >= 10:
		achievements.append("level_master_10")
	if total_levels >= 50:
		achievements.append("level_master_50")
	
	# Streak achievements
	var best_streak = player_data.get("best_streak", 0)
	if best_streak >= 3:
		achievements.append("victory_streak_3")
	if best_streak >= 5:
		achievements.append("victory_streak_5")
	
	# Score achievements
	var run_score = current_run.get("final_score", 0.0)
	if run_score >= 0.8:
		achievements.append("excellent_run")
	if run_score >= 0.9:
		achievements.append("perfect_run")
	
	# Collection achievements
	var rewards_collected = player_data.get("total_rewards_collected", []).size()
	var total_rewards = _get_total_possible_rewards()
	if rewards_collected >= total_rewards * 0.5:
		achievements.append("collector_half")
	if rewards_collected >= total_rewards:
		achievements.append("collector_complete")
	
	return achievements

static func _get_total_possible_rewards() -> int:
	# Count all possible rewards in the game
	var creature_rewards = 4  # ashclaw, gruvek, bond_remnant, veilskin
	var item_rewards = 10  # Various potions and upgrades
	return creature_rewards + item_rewards

static func _calculate_average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var total = 0.0
	for value in values:
		total += float(value)
	
	return total / float(values.size())

static func _calculate_performance_trend(run_history: Array) -> String:
	if run_history.size() < 3:
		return "insufficient_data"
	
	var recent_scores = []
	for i in range(max(0, run_history.size() - 5), run_history.size()):
		recent_scores.append(run_history[i].get("final_score", 0.0))
	
	if recent_scores.size() < 2:
		return "insufficient_data"
	
	var first_half = recent_scores.slice(0, recent_scores.size() / 2)
	var second_half = recent_scores.slice(recent_scores.size() / 2)
	
	var first_avg = _calculate_average(first_half)
	var second_avg = _calculate_average(second_half)
	
	var difference = second_avg - first_avg
	
	if difference > 0.1:
		return "improving"
	elif difference < -0.1:
		return "declining"
	else:
		return "stable"
