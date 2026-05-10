extends Node

const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")

# CombatFireDirector
# ZoneManager is the spatial executor: enemy positions, projectile spawning, active-projectile tracking.
# LaneManager keeps compatibility wrappers that delegate here so all call sites are unchanged.
#
# Responsibility split:
#   CombatFireDirector — WHEN and WHO fires (timing loop, cycle interval, authority scoring, stagger)
#   ZoneManager        — HOW it fires (spawn position, projectile scene, song sync, ETA collision guard)

var fire_stagger: float = COMBAT_FEEL_CONTENT.DEFAULT_FIRE_STAGGER
var cycle_interval: float = COMBAT_FEEL_CONTENT.DEFAULT_FIRE_CYCLE_INTERVAL
var attack_authority_budget: int = COMBAT_FEEL_CONTENT.DEFAULT_ATTACK_AUTHORITY_BUDGET

# ZoneManager reference set via init() after add_child.
var _zone_manager: Node = null

var _combat_running: bool = false
var _song_mode: bool = false
var _cycle_stalled: bool = false
var _cycle_task_id: int = 0

var _fire_cycle_index: int = 0
var _enemy_authority_debt: Dictionary = {}
var _enemy_last_fired_cycle: Dictionary = {}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func init(zone_manager: Node) -> void:
	_zone_manager = zone_manager


# ── Public control ────────────────────────────────────────────────────────────

func start(song_mode: bool) -> void:
	# Starts a fresh attack loop. Called by ZoneManager.start_combat().
	_song_mode = song_mode
	_combat_running = true
	_cycle_stalled = false
	_cycle_task_id += 1
	reset_authority_state()
	_run_fire_cycle(_cycle_task_id)


func start_song_cycle() -> void:
	# Restarts the fire loop for song-mode level transitions without resetting enemy data.
	_combat_running = true
	_cycle_stalled = false
	_cycle_task_id += 1
	_run_fire_cycle(_cycle_task_id)


func resume_stalled_cycle() -> void:
	# Resumes a stalled cycle when an enemy is added while the field was empty (song mode).
	if not _cycle_stalled:
		return
	_cycle_stalled = false
	_run_fire_cycle(_cycle_task_id)


func stop() -> void:
	_combat_running = false
	_cycle_task_id += 1
	_cycle_stalled = false
	reset_authority_state()


func reset_authority_state() -> void:
	_enemy_authority_debt.clear()
	_enemy_last_fired_cycle.clear()
	_fire_cycle_index = 0


func set_combat_running(running: bool) -> void:
	_combat_running = running


func set_song_mode(enabled: bool) -> void:
	_song_mode = enabled


func set_cycle_interval(interval: float) -> void:
	cycle_interval = max(0.3, interval)


func set_fire_stagger(stagger: float) -> void:
	# Clamp to safe range: lower bound respects MIN_IMPACT_SEPARATION so
	# sequential same-speed enemies always clear the ETA proximity check.
	fire_stagger = clamp(
		stagger,
		COMBAT_FEEL_CONTENT.FIRE_STAGGER_AUTHORED_MIN,
		COMBAT_FEEL_CONTENT.FIRE_STAGGER_AUTHORED_MAX
	)


func set_attack_authority_budget(budget: int) -> void:
	attack_authority_budget = clampi(budget, 1, 16)


func is_running() -> bool:
	return _combat_running


func is_stalled() -> bool:
	return _cycle_stalled


func trigger_accent_burst() -> void:
	# Forces an immediate fire cycle with tight stagger to create a chord or cluster feel.
	if not _combat_running or _cycle_stalled:
		return
	var original_stagger: float = fire_stagger
	fire_stagger = 0.42
	_cycle_task_id += 1
	_run_fire_cycle(_cycle_task_id)
	get_tree().create_timer(cycle_interval * 0.5).timeout.connect(
		func(): fire_stagger = original_stagger
	)


# ── Fire loop ─────────────────────────────────────────────────────────────────

func _run_fire_cycle(task_id: int) -> void:
	if not _combat_running or task_id != _cycle_task_id:
		return

	_cycle_stalled = false

	var paused: bool = false
	if _song_mode and _zone_manager != null and _zone_manager.combat_scene != null:
		if _zone_manager.combat_scene.has_method("is_song_paused"):
			paused = _zone_manager.combat_scene.is_song_paused()

	if not paused:
		var ids_to_fire: Array[int] = _resolve_authorized_strikers()
		for i in range(ids_to_fire.size()):
			if not _combat_running or task_id != _cycle_task_id:
				return

			var id: int = ids_to_fire[i]
			_zone_manager.notify_enemy_approaching(id)
			if _zone_manager.execute_fire(id):
				_enemy_authority_debt[id] = maxf(_enemy_authority_debt.get(id, 0.0) - 2.0, 0.0)
				_enemy_last_fired_cycle[id] = _fire_cycle_index

			if i < ids_to_fire.size() - 1:
				var offset_timer: SceneTreeTimer = get_tree().create_timer(fire_stagger)
				await offset_timer.timeout

	if not _combat_running or task_id != _cycle_task_id:
		return

	if _zone_manager != null and _zone_manager.alive_count() <= 0 and not paused:
		if _song_mode:
			_cycle_stalled = true
		return

	var cycle_timer: SceneTreeTimer = get_tree().create_timer(cycle_interval)
	await cycle_timer.timeout

	if _combat_running and task_id == _cycle_task_id:
		_run_fire_cycle(task_id)


# ── Striker selection ─────────────────────────────────────────────────────────

func _resolve_authorized_strikers() -> Array[int]:
	_fire_cycle_index += 1

	# Promote waiting enemies from orbit before scoring candidates.
	_zone_manager.promote_orbiting(attack_authority_budget)

	var strikers: Dictionary = _zone_manager.get_all_strikers()
	var all_enemies: Dictionary = _zone_manager.get_all_enemies()

	var candidates: Array = []
	for id in strikers:
		var enemy: Dictionary = all_enemies.get(id, {})
		if enemy.is_empty():
			continue
		if _zone_manager.has_active_projectile(id):
			continue

		_enemy_authority_debt[id] = minf(_enemy_authority_debt.get(id, 0.0) + 1.0, 8.0)

		var cycles_since_last: int = _fire_cycle_index - int(_enemy_last_fired_cycle.get(id, -999))
		var cooldown_cycles: int = int(enemy.get("cooldown_cycles", 0))
		if cooldown_cycles > 0 and cycles_since_last < cooldown_cycles:
			continue

		var damage_score: float = clampf(float(enemy.get("damage", 8.0)) / 10.0, 0.60, 1.80)
		var speed_score: float = clampf(_zone_manager.get_effective_projectile_speed(id) / 320.0, 0.70, 1.70)
		var age_bonus: float = clampf(float(cycles_since_last) / 4.0, 0.0, 1.4)
		var jitter: float = _rng.randf() * 0.08
		var score: float = _enemy_authority_debt[id] * 1.35 + age_bonus + damage_score * 0.35 + speed_score * 0.25 + jitter

		# Bloodscent: Ashclaw is more aggressive if the player is bleeding.
		if enemy.get("species_id") == "ashclaw":
			score += float(GameState.player_bleed_stacks) * 2.0

		candidates.append({"id": id, "score": score})

	if candidates.is_empty():
		return []

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var budget: int = clampi(attack_authority_budget, 1, 16)
	var selected_count: int = mini(budget, candidates.size())
	var selected_ids: Array[int] = []
	for i in range(selected_count):
		selected_ids.append(int(candidates[i]["id"]))
	return selected_ids
