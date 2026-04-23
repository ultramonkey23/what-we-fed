extends RefCounted

# Analytics System - Comprehensive performance tracking and analysis
# This system provides insights without interfering with gameplay

# Analytics data structure
const ANALYTICS_VERSION: String = "1.0"

# Performance metrics tracking
static func create_performance_tracker() -> Dictionary:
	return {
		"session_start_time": Time.get_unix_time_from_system(),
		"level_start_time": 0.0,
		"metrics": {
			"damage_dealt": 0.0,
			"damage_taken": 0.0,
			"enemies_defeated": 0,
			"enemies_spawned": 0,
			"projectiles_fired": 0,
			"projectiles_hit": 0,
			"powers_used": 0,
			"perfect_phases": 0,
			"total_phases": 0,
			"damage_per_second": 0.0,
			"accuracy": 0.0,
			"efficiency": 0.0,
			"survival_time": 0.0,
			"score": 0.0
		},
		"events": [],
		"phase_data": []
	}

# Start tracking a level
static func start_level_tracking(tracker: Dictionary, level_number: int) -> void:
	tracker["level_start_time"] = Time.get_unix_time_from_system()
	tracker["current_level"] = level_number
	tracker["phase_data"] = []

# Start tracking a phase
static func start_phase_tracking(tracker: Dictionary, phase_id: String) -> void:
	var phase_data = {
		"phase_id": phase_id,
		"start_time": Time.get_unix_time_from_system(),
		"start_metrics": tracker["metrics"].duplicate(true),
		"events": []
	}
	tracker["phase_data"].append(phase_data)

# End tracking a phase
static func end_phase_tracking(tracker: Dictionary, phase_id: String) -> void:
	for phase_data in tracker["phase_data"]:
		if phase_data["phase_id"] == phase_id:
			phase_data["end_time"] = Time.get_unix_time_from_system()
			phase_data["end_metrics"] = tracker["metrics"].duplicate(true)
			phase_data["duration"] = phase_data["end_time"] - phase_data["start_time"]
			
			# Calculate phase performance
			phase_data["performance"] = _calculate_phase_performance(phase_data)
			break

# Record an event during gameplay
static func record_event(tracker: Dictionary, event_type: String, data: Dictionary = {}) -> void:
	var event = {
		"timestamp": Time.get_unix_time_from_system(),
		"type": event_type,
		"data": data
	}
	tracker["events"].append(event)
	
	# Also add to current phase if tracking
	if not tracker["phase_data"].is_empty():
		var current_phase = tracker["phase_data"][-1]
		current_phase["events"].append(event)

# Update metrics during gameplay
static func update_metrics(tracker: Dictionary, metric_updates: Dictionary) -> void:
	var metrics = tracker["metrics"]
	
	for key in metric_updates.keys():
		if metrics.has(key):
			metrics[key] += metric_updates[key]
		else:
			metrics[key] = metric_updates[key]
	
	# Calculate derived metrics
	_calculate_derived_metrics(tracker)

# Calculate derived metrics
static func _calculate_derived_metrics(tracker: Dictionary) -> void:
	var metrics = tracker["metrics"]
	var current_time = Time.get_unix_time_from_system()
	var session_duration = current_time - tracker["session_start_time"]
	
	# Accuracy
	if metrics["projectiles_fired"] > 0:
		metrics["accuracy"] = float(metrics["projectiles_hit"]) / float(metrics["projectiles_fired"])
	
	# Damage per second
	if session_duration > 0:
		metrics["damage_per_second"] = metrics["damage_dealt"] / float(session_duration)
	
	# Efficiency (damage per projectile)
	if metrics["projectiles_fired"] > 0:
		metrics["efficiency"] = metrics["damage_dealt"] / float(metrics["projectiles_fired"])
	
	# Survival time
	metrics["survival_time"] = session_duration
	
	# Score calculation
	metrics["score"] = _calculate_performance_score(metrics)

# Calculate phase performance
static func _calculate_phase_performance(phase_data: Dictionary) -> Dictionary:
	var start_metrics = phase_data["start_metrics"]
	var end_metrics = phase_data["end_metrics"]
	var duration = phase_data["duration"]
	
	var performance = {
		"damage_dealt": end_metrics["damage_dealt"] - start_metrics["damage_dealt"],
		"damage_taken": end_metrics["damage_taken"] - start_metrics["damage_taken"],
		"enemies_defeated": end_metrics["enemies_defeated"] - start_metrics["enemies_defeated"],
		"projectiles_fired": end_metrics["projectiles_fired"] - start_metrics["projectiles_fired"],
		"projectiles_hit": end_metrics["projectiles_hit"] - start_metrics["projectiles_hit"],
		"duration": duration,
		"damage_per_second": 0.0,
		"accuracy": 0.0,
		"rating": "normal"
	}
	
	# Calculate phase-specific metrics
	if duration > 0:
		performance["damage_per_second"] = performance["damage_dealt"] / float(duration)
	
	if performance["projectiles_fired"] > 0:
		performance["accuracy"] = float(performance["projectiles_hit"]) / float(performance["projectiles_fired"])
	
	# Rate performance
	performance["rating"] = _rate_performance(performance)
	
	return performance

# Rate performance
static func _rate_performance(performance: Dictionary) -> String:
	var score = 0.0
	
	# Damage dealing (40% weight)
	score += min(performance["damage_dealt"] / 100.0, 0.4)
	
	# Accuracy (30% weight)
	score += performance["accuracy"] * 0.3
	
	# Efficiency (20% weight)
	var efficiency = performance["damage_dealt"] / max(1, performance["projectiles_fired"])
	score += min(efficiency / 10.0, 0.2)
	
	# Survival (10% weight)
	if performance["duration"] > 0:
		score += min(performance["duration"] / 60.0, 0.1)  # 1 minute = full points
	
	# Convert to rating
	if score >= 0.9:
		return "excellent"
	elif score >= 0.75:
		return "good"
	elif score >= 0.5:
		return "normal"
	elif score >= 0.25:
		return "poor"
	else:
		return "terrible"

# Calculate overall performance score
static func _calculate_performance_score(metrics: Dictionary) -> float:
	var score = 0.0
	
	# Damage contribution (30%)
	score += min(metrics["damage_dealt"] / 1000.0, 0.3)
	
	# Accuracy contribution (25%)
	score += metrics["accuracy"] * 0.25
	
	# Efficiency contribution (20%)
	score += min(metrics["efficiency"] / 20.0, 0.2)
	
	# Survival contribution (15%)
	score += min(metrics["survival_time"] / 300.0, 0.15)  # 5 minutes = full points
	
	# Enemy defeats contribution (10%)
	score += min(float(metrics["enemies_defeated"]) / 100.0, 0.1)
	
	return min(score, 1.0)

# Generate analytics report
static func generate_analytics_report(tracker: Dictionary) -> Dictionary:
	var report = {}
	
	# Basic metrics
	report["session_duration"] = Time.get_unix_time_from_system() - tracker["session_start_time"]
	report["total_metrics"] = tracker["metrics"]
	report["event_count"] = tracker["events"].size()
	report["phase_count"] = tracker["phase_data"].size()
	
	# Phase analysis
	if not tracker["phase_data"].is_empty():
		report["phase_analysis"] = _analyze_phases(tracker["phase_data"])
	
	# Event analysis
	if not tracker["events"].is_empty():
		report["event_analysis"] = _analyze_events(tracker["events"])
	
	# Performance trends
	report["performance_trends"] = _analyze_performance_trends(tracker)
	
	# Recommendations
	report["recommendations"] = _generate_recommendations(tracker)
	
	return report

# Analyze phase data
static func _analyze_phases(phase_data: Array) -> Dictionary:
	var analysis = {
		"phase_count": phase_data.size(),
		"average_duration": 0.0,
		"performance_ratings": {},
		"best_phase": "",
		"worst_phase": "",
		"improvement_trend": "stable"
	}
	
	if phase_data.is_empty():
		return analysis
	
	var total_duration = 0.0
	var ratings = []
	var best_score = -1.0
	var worst_score = 2.0
	
	for phase in phase_data:
		if phase.has("duration"):
			total_duration += phase["duration"]
		
		if phase.has("performance"):
			var perf = phase["performance"]
			var rating = perf.get("rating", "normal")
			ratings.append(rating)
			
			# Calculate numeric score for comparison
			var score = _rating_to_score(rating)
			if score > best_score:
				best_score = score
				analysis["best_phase"] = phase["phase_id"]
			if score < worst_score:
				worst_score = score
				analysis["worst_phase"] = phase["phase_id"]
	
	analysis["average_duration"] = total_duration / float(phase_data.size())
	
	# Count ratings
	var rating_counts = {}
	for rating in ratings:
		rating_counts[rating] = rating_counts.get(rating, 0) + 1
	analysis["performance_ratings"] = rating_counts
	
	# Determine trend
	if ratings.size() >= 3:
		var early_ratings = ratings.slice(0, ratings.size() >> 1)
		var late_ratings = ratings.slice(ratings.size() >> 1)
		
		var early_avg = _average_rating_score(early_ratings)
		var late_avg = _average_rating_score(late_ratings)
		
		if late_avg > early_avg + 0.2:
			analysis["improvement_trend"] = "improving"
		elif late_avg < early_avg - 0.2:
			analysis["improvement_trend"] = "declining"
		else:
			analysis["improvement_trend"] = "stable"
	
	return analysis

# Analyze events
static func _analyze_events(events: Array) -> Dictionary:
	var analysis = {
		"total_events": events.size(),
		"event_types": {},
		"event_frequency": {},
		"critical_events": []
	}
	
	var type_counts = {}
	var time_intervals = []
	var last_time = events[0]["timestamp"] if not events.is_empty() else 0
	
	for event in events:
		var event_type = event["type"]
		type_counts[event_type] = type_counts.get(event_type, 0) + 1
		
		# Calculate time intervals
		var current_time = event["timestamp"]
		if last_time > 0:
			time_intervals.append(current_time - last_time)
		last_time = current_time
		
		# Identify critical events
		if _is_critical_event(event):
			analysis["critical_events"].append(event)
	
	analysis["event_types"] = type_counts
	
	# Calculate event frequency
	if time_intervals.size() > 0:
		var total_interval = 0
		for interval in time_intervals:
			total_interval += interval
		analysis["event_frequency"] = {
			"average_interval": total_interval / float(time_intervals.size()),
			"events_per_minute": 60.0 / (total_interval / float(time_intervals.size()))
		}
	
	return analysis

# Analyze performance trends
static func _analyze_performance_trends(tracker: Dictionary) -> Dictionary:
	var trends = {
		"overall_trend": "stable",
		"damage_trend": "stable",
		"accuracy_trend": "stable",
		"efficiency_trend": "stable"
	}
	
	if tracker["phase_data"].size() < 3:
		return trends
	
	var phase_performances = []
	for phase in tracker["phase_data"]:
		if phase.has("performance"):
			phase_performances.append(phase["performance"])
	
	if phase_performances.size() < 3:
		return trends
	
	# Analyze different metrics over phases
	var damage_values = []
	var accuracy_values = []
	var efficiency_values = []
	
	for perf in phase_performances:
		damage_values.append(perf.get("damage_dealt", 0.0))
		accuracy_values.append(perf.get("accuracy", 0.0))
		efficiency_values.append(perf.get("damage_dealt", 0.0) / max(1, perf.get("projectiles_fired", 1)))
	
	trends["damage_trend"] = _calculate_trend(damage_values)
	trends["accuracy_trend"] = _calculate_trend(accuracy_values)
	trends["efficiency_trend"] = _calculate_trend(efficiency_values)
	
	# Overall trend
	var trend_scores = [
		_trend_to_score(trends["damage_trend"]),
		_trend_to_score(trends["accuracy_trend"]),
		_trend_to_score(trends["efficiency_trend"])
	]
	var avg_trend_score = 0.0
	for score in trend_scores:
		avg_trend_score += score
	avg_trend_score /= float(trend_scores.size())
	
	trends["overall_trend"] = _score_to_trend(avg_trend_score)
	
	return trends

# Generate recommendations
static func _generate_recommendations(tracker: Dictionary) -> Array[String]:
	var recommendations = []
	var metrics = tracker["metrics"]
	
	# Accuracy recommendations
	if metrics["accuracy"] < 0.5:
		recommendations.append("Focus on improving aim - try leading targets more")
	elif metrics["accuracy"] < 0.7:
		recommendations.append("Good accuracy, but room for improvement")
	
	# Efficiency recommendations
	if metrics["projectiles_fired"] > 0:
		var efficiency = metrics["damage_dealt"] / float(metrics["projectiles_fired"])
		if efficiency < 10.0:
			recommendations.append("Consider using more powerful attacks or aiming for weak spots")
	
	# Damage recommendations
	if metrics["damage_dealt"] < 200.0:
		recommendations.append("Try to deal more damage - use abilities more frequently")
	
	# Survival recommendations
	if metrics["damage_taken"] > metrics["damage_dealt"] * 0.5:
		recommendations.append("Focus on dodging and positioning to reduce damage taken")
	
	# Phase performance recommendations
	if not tracker["phase_data"].is_empty():
		var phase_analysis = _analyze_phases(tracker["phase_data"])
		if phase_analysis.get("improvement_trend") == "declining":
			recommendations.append("Performance is declining over time - try to maintain focus")
		elif phase_analysis.get("improvement_trend") == "improving":
			recommendations.append("Great improvement! Keep up the momentum")
	
	# Event-based recommendations
	if not tracker["events"].is_empty():
		var event_analysis = _analyze_events(tracker["events"])
		var critical_count = event_analysis.get("critical_events", []).size()
		if critical_count > 5:
			recommendations.append("Many critical events - consider more defensive positioning")
	
	return recommendations

# Export analytics data
static func export_analytics(tracker: Dictionary) -> String:
	var export_data = {
		"version": ANALYTICS_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"tracker": tracker,
		"report": generate_analytics_report(tracker)
	}
	
	return JSON.stringify(export_data, "\t")

# Private helper functions

static func _is_critical_event(event: Dictionary) -> bool:
	var critical_types = ["player_damaged", "low_health", "enemy_boss_spawn", "phase_failure"]
	return critical_types.has(event["type"])

static func _rating_to_score(rating: String) -> float:
	match rating:
		"excellent":
			return 1.0
		"good":
			return 0.75
		"normal":
			return 0.5
		"poor":
			return 0.25
		"terrible":
			return 0.0
		_:
			return 0.5

static func _average_rating_score(ratings: Array[String]) -> float:
	if ratings.is_empty():
		return 0.5
	
	var total = 0.0
	for rating in ratings:
		total += _rating_to_score(rating)
	
	return total / float(ratings.size())

static func _calculate_trend(values: Array) -> String:
	if values.size() < 2:
		return "stable"
	
	var first_half = values.slice(0, values.size() >> 1)
	var second_half = values.slice(values.size() >> 1)
	
	var first_avg = 0.0
	for val in first_half:
		first_avg += float(val)
	first_avg /= float(first_half.size())
	
	var second_avg = 0.0
	for val in second_half:
		second_avg += float(val)
	second_avg /= float(second_half.size())
	
	var difference = second_avg - first_avg
	var threshold = first_avg * 0.1  # 10% change threshold
	
	if difference > threshold:
		return "improving"
	elif difference < -threshold:
		return "declining"
	else:
		return "stable"

static func _trend_to_score(trend: String) -> float:
	match trend:
		"improving":
			return 1.0
		"stable":
			return 0.5
		"declining":
			return 0.0
		_:
			return 0.5

static func _score_to_trend(score: float) -> String:
	if score > 0.66:
		return "improving"
	elif score < 0.33:
		return "declining"
	else:
		return "stable"
