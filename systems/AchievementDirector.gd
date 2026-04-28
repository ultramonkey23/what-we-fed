extends Node

# AchievementDirector.gd
# Monitors run stats and lifecycle events to trigger meta-persistence "Limit Breakers".
# Limit Breakers raise the maximum level cap of the Living Codex.

const DEVOURING_SCORE_THRESHOLD: int = 1200
const KILL_COUNT_LIMIT_BREAKER: int = 50
const DNA_GLUT_THRESHOLD: float = 2000.0
const PERFECT_PULSE_THRESHOLD: int = 50

var _achieved_this_run: Array[String] = []

func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_completed.connect(_on_run_completed)
	EventBus.boss_outcome_resolved.connect(_on_boss_outcome_resolved)


func _on_run_started(_run_number: int) -> void:
	_achieved_this_run.clear()


func _on_run_completed(success: bool) -> void:
	if not success:
		return
		
	# Check milestones via GameState.run_stats (if available) or by querying active systems.
	# We rely on the authoritative RunStats data.
	var run_stats = get_tree().root.find_child("RunStats", true, false)
	if run_stats == null:
		# Fallback: check if it's an autoload
		if get_tree().root.has_node("RunStats"):
			run_stats = get_tree().root.get_node("RunStats")
			
	if run_stats != null:
		_check_end_of_run_milestones(run_stats)


func _on_boss_outcome_resolved(outcome_id: String, _payload: Dictionary) -> void:
	if outcome_id == "boss_defeated" or outcome_id == "boss_consumed" or outcome_id == "boss_subjugated":
		_trigger_limit_breaker("apex_slayer")


func _check_end_of_run_milestones(stats: Node) -> void:
	var score: int = int(stats.get("run_score"))
	var kills: int = int(stats.get("kills"))
	var dna: float = float(stats.get("dna_gained"))
	var perfects: int = int(stats.get("perfect_attacks")) + int(stats.get("perfect_parries"))
	
	if score >= DEVOURING_SCORE_THRESHOLD:
		_trigger_limit_breaker("devouring_grade")
		
	if kills >= KILL_COUNT_LIMIT_BREAKER:
		_trigger_limit_breaker("mass_extinction")
		
	if dna >= DNA_GLUT_THRESHOLD:
		_trigger_limit_breaker("dna_glut")
		
	if perfects >= PERFECT_PULSE_THRESHOLD:
		_trigger_limit_breaker("perfect_pulse")


func _trigger_limit_breaker(achievement_id: String) -> void:
	# Persistent Check: Limit Breakers can only be earned once per profile.
	# We use a naming convention in GameState to track which ones are fired,
	# or we just rely on the count if they are repeatable (per doctrine, they shatter the cap).
	
	# For now, we'll allow them to be earned once per run if they haven't been triggered yet.
	if _achieved_this_run.has(achievement_id):
		return
		
	_achieved_this_run.append(achievement_id)
	
	# Increment the meta-stat in GameState
	if GameState.has_method("increment_meta_limit_breakers"):
		GameState.call("increment_meta_limit_breakers", achievement_id)
