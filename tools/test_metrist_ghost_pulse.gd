extends SceneTree

# tools/test_metrist_ghost_pulse.gd
# Headless regression probe for the Metrist "Downbeat / Ghost Pulse" species
# behavior (pale_shelf_offbeat_lector), the alternative third-species design
# filed in docs/ai/evolution_proposals/2026-11-23_metrist_alternative_third_species.md.
#
# Contract under test (canon [P]: "It keeps the beat you never meant to teach
# it." / "the echo fires in the gap, not on the beat"):
#   1. TRIGGER = RHYTHMIC REGULARITY: the lock engages on a low-jitter pulse
#      groove (jitter = normalized MAD over recent inter-pulse intervals) at
#      any tempo; silence and bursts are irrelevant as triggers; irregular
#      input NEVER locks; high jitter / rubato breaks the lock.
#   2. RESPONSE = TIMING DISPLACEMENT ONLY: the armed locked strike ("the
#      Downbeat") lands exactly one OFFBEAT past the player's pulse
#      (landing = pulse_slot + half interval) via a launch-phase hold —
#      projectile damage and speed are NEVER changed (SovereignDamageCalculator
#      stays damage authority; flight speed fixed; timing windows unaltered).
#   3. COUNTERPLAY = SLIP: when the player breaks pattern while the strike is
#      in flight, it slips ONTO the nearest reachable player pulse slot
#      (landing == pulse slot, reachable: never faster than the fixed flight).
#   4. TELEGRAPH = GHOST PULSE: a pale after-image of the player's own most
#      recent shot ignites in the EMPTY SLOT between two beats, one beat early
#      (ghost = landing - mean interval; always a gap slot — "the echo fires
#      in the gap, not on the beat"), and snaps onto a gap again after a slip.
#   5. ONE DOWNBEAT PER LOCK: consumed when the strike spawns; re-armed only
#      by a fresh lock (unlocked -> locked).
#   6. CAUSAL MARKER [metrist_downbeat] fires exactly on armed locked strikes
#      (the telegraph_profile["metrist_downbeat"] flag asserts the same
#      condition in-process; the marker line itself is witnessed in the
#      runtime logs of the debug harness / windowed run).
#   7. SPATIAL PURITY: lane, spawn position and hit-zone geometry are exactly
#      the ordinary fire-path geometry.
#   8. SPECIES IDENTITY IS SPECIES-SPECIFIC: the Glintstalker and Shardhulk
#      never fire Downbeats whatever the cadence, and the Metrist never fires
#      Glint Shots or Lane Closes.
#   9. DETERMINISM: seeded rhythm trains produce identical lock outcomes and
#      identical plans across runs.
#  10. THE SPECIES IS LIVE IN DATA: authored in COMBAT_CONTENT.CREATURES with
#      canon fields, has a locomotion profile, and carries NONZERO spawn
#      weight in the real natural-spawn data path (RegionSongContent pools,
#      reproduced by a seeded Monte Carlo through the production weighted
#      picker — the gen-1 spawn-presence pattern).
#
# Runs through project autoloads (EventBus, PlayerState) like the other
# tools/test_*.gd probes. Fails before the Metrist wiring; passes after.
# Never weakens tools/test_glint_stalker_silence_punish.gd or
# tools/test_shardhulk_panic_close.gd — those suites' invariants are
# re-asserted here only from the Metrist side.

const ZONE_MANAGER_SCRIPT_PATH: String = "res://scenes/combat/ZoneManager.gd"
const METRIST_DIRECTOR_PATH: String = "res://systems/MetristDirector.gd"
const GHOST_PULSE_PATH: String = "res://scenes/combat/GhostPulseEcho.gd"
const REGION_SONG_PATH: String = "res://data/RegionSongContent.gd"
const IDENTITY_RUNTIME_PATH: String = "res://systems/EncounterIdentityRuntime.gd"

const METRIST_SPECIES_ID: String = "pale_shelf_offbeat_lector"
const GLINT_SPECIES_ID: String = "pale_shelf_precision_stalker"
const SHARD_SPECIES_ID: String = "pale_shelf_shardshroud_sentinel"
const METRIST_ENEMY_ID: int = 9707
const GLINT_ENEMY_ID: int = 9808
const SHARD_ENEMY_ID: int = 9909
const BASE_DAMAGE: float = 10.0
const BASE_SPEED: float = 330.0
const PULSE_INTERVAL_MSEC: int = 400
const MONTE_CARLO_ROLLS: int = 2000
const MONTE_CARLO_TOLERANCE: float = 0.06
const MONTE_CARLO_SEED: int = 20261123

var _failures: Array[String] = []
var _checks: int = 0
var _bus: Node = null
var _striker_cls: Variant = null
var _director_cls: Variant = null
var _director_consts: Dictionary = {}
var _last_probe_pulse_at: int = -1000000


func _initialize() -> void:
	# Load after project autoloads are registered (see test_combat_scene.gd).
	call_deferred(&"_run")


func _run() -> void:
	print("=== test_metrist_ghost_pulse: Metrist Downbeat / Ghost Pulse identity ===")
	_bus = root.get_node("EventBus")
	_striker_cls = load("res://scenes/combat/EnemyStriker.gd")
	_record(_striker_cls is GDScript, "EnemyStriker script did not load at runtime")
	_director_cls = load(METRIST_DIRECTOR_PATH)
	_record(_director_cls is GDScript, "MetristDirector script did not load at runtime")
	if _director_cls is GDScript:
		_director_consts = (_director_cls as GDScript).get_script_constant_map()
	var zone_manager_script: Variant = load(ZONE_MANAGER_SCRIPT_PATH)
	_record(zone_manager_script is Script, "ZoneManager script did not load")
	if not (_striker_cls is GDScript) or not (_director_cls is GDScript) or not (zone_manager_script is Script):
		_finish()
		return

	var zone_manager: Node = (zone_manager_script as Script).new()
	zone_manager.name = "ZoneManager"
	root.add_child(zone_manager)
	zone_manager.setup_layout(Vector2(1280.0, 720.0))
	_record(bool(zone_manager.call("load_scene")), "ZoneManager.load_scene() failed")

	_check_rhythm_lock_lifecycle()
	_check_downbeat_plan_is_one_offbeat_past_the_pulse()
	_check_ghost_pulse_snaps_to_the_gap()
	_check_one_downbeat_per_lock()
	_check_irregular_input_never_locks()
	_check_deterministic_seeded_runs()
	_check_slip_plan_lands_on_the_pulse_slot()
	_check_downbeat_is_real_through_the_production_fire_path()
	_check_followup_shot_is_ordinary()
	_check_ghost_echo_is_wired_to_the_plan()
	_check_downbeat_is_timing_only()
	_check_unlocked_shot_is_ordinary()
	_check_pattern_break_slips_in_flight()
	_check_species_identity_is_specific(zone_manager)
	_check_spatial_purity(zone_manager)
	_check_player_attacked_wiring()
	_check_species_is_authored_in_live_data()
	_check_spawn_weight_wiring_is_live()
	_check_mutation_one_downbeat_per_lock_never_rearms()
	_check_negative_slip_lands_on_reachable_pulse_slot_timing_only()

	_finish()


func _finish() -> void:
	print("----------------------------------------------------------------")
	print("checks run: %d   failures: %d" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: " + f)
		print("RESULT: FAIL")
		quit(1)


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)


# ── Helpers (same probe conventions as the gen-1/gen-2 suites) ──────────────

func _stamp(at: int) -> int:
	# Engine uptime can be young enough that a backdated timestamp goes
	# negative; -1 is the "now" sentinel in note_player_attack, so nudge it.
	if at == -1:
		return -2
	return at


func _reset() -> void:
	_director_cls.call("mark_combat_start")


func _pulse(at_msec: int) -> void:
	_last_probe_pulse_at = at_msec
	_striker_cls.call("note_player_attack", _stamp(at_msec))


## A steady groove: `count` pulses spaced exactly `interval` msec apart,
## ending one interval before `last_at_msec`.
func _steady_train(count: int, last_at_msec: int, interval: int = PULSE_INTERVAL_MSEC) -> void:
	for i in range(count):
		_pulse(last_at_msec - (count - 1 - i) * interval)


## One rubato pulse 50ms after the previous probe pulse (a jitter spike).
func _rubato_pulse() -> void:
	_pulse(_last_probe_pulse_at + 50)


func _mean_interval() -> float:
	return float(_director_cls.call("mean_interval_msec"))


func _jitter() -> float:
	return float(_director_cls.call("jitter"))


func _is_locked() -> bool:
	return bool(_director_cls.call("is_locked"))


func _downbeat_armed() -> bool:
	return bool(_director_cls.call("downbeat_armed"))


func _plan() -> Dictionary:
	return Dictionary(_director_cls.call("active_plan"))


func _const_float(const_name: String) -> float:
	return float(_director_consts.get(const_name, 0.0))


func _const_int(const_name: String) -> int:
	return int(_director_consts.get(const_name, 0))


func _metrist_enemy() -> Dictionary:
	return {
		"id": METRIST_ENEMY_ID,
		"species_id": METRIST_SPECIES_ID,
		"type": "dreg",
		"hp": 32.0,
		"damage": BASE_DAMAGE,
		"projectile_speed": BASE_SPEED
	}


func _glint_enemy() -> Dictionary:
	return {
		"id": GLINT_ENEMY_ID,
		"species_id": GLINT_SPECIES_ID,
		"type": "dreg",
		"hp": 30.0,
		"damage": BASE_DAMAGE,
		"projectile_speed": 430.0
	}


func _shard_enemy() -> Dictionary:
	return {
		"id": SHARD_ENEMY_ID,
		"species_id": SHARD_SPECIES_ID,
		"type": "dreg",
		"hp": 38.0,
		"damage": BASE_DAMAGE,
		"projectile_speed": 286.0
	}


func _drain_active(zone_manager: Node, id: int) -> void:
	# The production fire director may spawn a cycle shot during start_combat.
	# Resolve it so each probe fire is the only projectile in flight.
	var projectile: Variant = zone_manager.call("get_projectile_by_id", id)
	if projectile != null and is_instance_valid(projectile) and not bool(projectile.is_resolved):
		projectile.call("resolve", "probe_drain")


func _on_grid(value: float, anchor: float, interval: float) -> bool:
	# True when value sits exactly on the pulse grid (anchor + n * interval).
	if interval <= 0.0:
		return false
	var offset: float = absf(value - anchor) / interval
	return absf(offset - roundf(offset)) < 0.001


# ── A. Rhythm engine (deterministic, pure) ─────────────────────────────────

func _check_rhythm_lock_lifecycle() -> void:
	_reset()
	_record(not _is_locked(), "engine locked with no pulses")
	_record(not _downbeat_armed(), "downbeat armed with no rhythm")
	# Not enough intervals yet: two pulses give one interval.
	_pulse(-500000)
	_pulse(-500000 + PULSE_INTERVAL_MSEC)
	_record(not _is_locked(), "lock engaged below the minimum interval count")
	# A steady groove locks and reports its beat.
	_reset()
	_steady_train(7, -500000 + 7 * PULSE_INTERVAL_MSEC)
	_record(_is_locked(), "steady groove did not lock")
	_record(_jitter() <= _const_float("LOCK_JITTER_MAX"),
		"steady groove jitter %.3f exceeded the lock threshold" % _jitter())
	_record(absf(_mean_interval() - float(PULSE_INTERVAL_MSEC)) < 1.0,
		"mean interval %.1f != authored pulse spacing %d" % [_mean_interval(), PULSE_INTERVAL_MSEC])
	_record(_downbeat_armed(), "fresh lock did not arm the Downbeat")
	# Rubato breaks the lock.
	_rubato_pulse()
	_record(not _is_locked(), "high-jitter pulse did not break the lock")
	_record(not _downbeat_armed(), "Downbeat stayed armed after the lock broke")


func _check_downbeat_plan_is_one_offbeat_past_the_pulse() -> void:
	_reset()
	_steady_train(7, -500000 + 7 * PULSE_INTERVAL_MSEC)
	_record(_is_locked(), "probe setup: steady groove did not lock")
	var now_msec: int = 100000
	var travel_msec: int = 600
	var plan: Dictionary = Dictionary(_director_cls.call("plan_downbeat", now_msec, travel_msec))
	_record(not plan.is_empty(), "locked plan_downbeat returned empty")
	if plan.is_empty():
		return
	var interval: float = float(plan["interval_msec"])
	var anchor: float = float(plan["anchor_msec"])
	var natural: float = float(plan["natural_arrival_msec"])
	var pulse_slot: float = float(plan["pulse_slot_msec"])
	var landing: float = float(plan["landing_msec"])
	var ghost: float = float(plan["ghost_ignite_msec"])
	var hold: float = float(plan["hold_msec"])
	_record(is_equal_approx(natural, float(now_msec + travel_msec)),
		"natural arrival %.1f != now + travel %d" % [natural, now_msec + travel_msec])
	_record(pulse_slot >= natural and _on_grid(pulse_slot, anchor, interval),
		"pulse slot %.1f is not the first reachable grid slot after natural arrival %.1f" % [pulse_slot, natural])
	_record(is_equal_approx(landing, pulse_slot + interval * 0.5),
		"landing %.1f is not one offbeat past the pulse slot %.1f (interval %.1f)" % [landing, pulse_slot, interval])
	_record(not _on_grid(landing, anchor, interval),
		"locked landing %.1f sat ON a beat instead of in the gap" % landing)
	_record(is_equal_approx(hold, landing - natural) and hold >= 0.0,
		"hold %.2f != landing - natural %.2f" % [hold, landing - natural])
	_record(String(plan["slot"]) == "offbeat" and not bool(plan["slipped"]),
		"fresh plan is not marked as an unslipped offbeat landing")


func _check_ghost_pulse_snaps_to_the_gap() -> void:
	_reset()
	_steady_train(7, -500000 + 7 * PULSE_INTERVAL_MSEC)
	var plan: Dictionary = Dictionary(_director_cls.call("plan_downbeat", 100000, 600))
	if plan.is_empty():
		_record(false, "probe setup: no plan for ghost timing")
		return
	var interval: float = float(plan["interval_msec"])
	var anchor: float = float(plan["anchor_msec"])
	var landing: float = float(plan["landing_msec"])
	var ghost: float = float(plan["ghost_ignite_msec"])
	_record(is_equal_approx(ghost, landing - interval),
		"ghost ignition %.1f is not exactly one beat (%.1f) before landing %.1f" % [ghost, interval, landing])
	_record(not _on_grid(ghost, anchor, interval),
		"ghost ignition %.1f fired ON a beat instead of in the gap" % ghost)
	# The echo node itself must carry the same scheduled snap.
	var echo_script: Variant = load(GHOST_PULSE_PATH)
	_record(echo_script is Script, "GhostPulseEcho script did not load")
	if echo_script is Script:
		var echo: Node2D = (echo_script as Script).new() as Node2D
		root.add_child(echo)
		echo.call("setup", 0.05, 1.0, Vector2.RIGHT, ghost)
		_record(is_equal_approx(float(echo.get("scheduled_ignite_msec")), ghost),
			"ghost echo node does not carry the plan's gap-slot ignition time")
		echo.call("reschedule", 0.05, ghost)
		_record(bool(echo.get("ignited")) == false, "ghost echo ignited before its slot")
		echo.queue_free()


func _check_one_downbeat_per_lock() -> void:
	_reset()
	_steady_train(7, -500000 + 7 * PULSE_INTERVAL_MSEC)
	_record(_downbeat_armed(), "probe setup: lock did not arm the Downbeat")
	_record(bool(_director_cls.call("consume_downbeat")), "armed Downbeat did not consume")
	_record(not bool(_director_cls.call("consume_downbeat")), "Downbeat chained twice inside one lock")
	_record(not _downbeat_armed(), "Downbeat still armed after consumption")
	# A fresh lock re-arms; silence alone never does.
	_rubato_pulse()
	_record(not _downbeat_armed(), "Downbeat re-armed without a fresh lock")
	_steady_train(7, -500000 + 16 * PULSE_INTERVAL_MSEC)
	_record(_is_locked() and _downbeat_armed(), "fresh lock did not re-arm the Downbeat")


func _check_irregular_input_never_locks() -> void:
	# Seeded rubato train: wide interval spread must never lock or arm.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = MONTE_CARLO_SEED
	for _run_i in 2:
		_reset()
		var at: int = -500000
		for _i in 10:
			at += 200 + rng.randi_range(0, 700)
			_pulse(at)
		_record(not _is_locked(), "irregular seeded train locked the rhythm")
		_record(not _downbeat_armed(), "irregular seeded train armed the Downbeat")


func _check_deterministic_seeded_runs() -> void:
	var first: Dictionary = _seeded_outcome(4242)
	var second: Dictionary = _seeded_outcome(4242)
	_record(bool(first["locked"]) == bool(second["locked"]),
		"seeded runs disagreed on the lock outcome")
	_record(is_equal_approx(float(first["jitter"]), float(second["jitter"])),
		"seeded runs disagreed on jitter (%.6f vs %.6f)" % [float(first["jitter"]), float(second["jitter"])])
	_record(str(first["plan"]) == str(second["plan"]),
		"seeded runs produced different Downbeat plans")
	_record(bool(first["locked"]), "gentle seeded jitter train failed to lock")


func _seeded_outcome(seed_v: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_v
	_reset()
	var at: int = -500000
	for _i in 8:
		at += PULSE_INTERVAL_MSEC + rng.randi_range(-20, 20)
		_pulse(at)
	var out: Dictionary = {
		"locked": _is_locked(),
		"jitter": _jitter(),
		"plan": {}
	}
	if _is_locked():
		out["plan"] = Dictionary(_director_cls.call("plan_downbeat", 0, 500))
	return out


# ── B. Slip math (pure, deterministic) ─────────────────────────────────────

func _check_slip_plan_lands_on_the_pulse_slot() -> void:
	_reset()
	_steady_train(7, -500000 + 7 * PULSE_INTERVAL_MSEC)
	var plan: Dictionary = Dictionary(_director_cls.call("plan_downbeat", 100000, 600))
	_record(not plan.is_empty(), "probe setup: no plan to slip")
	if plan.is_empty():
		return
	# Early break: the strike pulls back onto the trailing pulse slot.
	var early: Dictionary = Dictionary(_director_cls.call("slip_plan", plan, 100000, 600.0))
	var interval: float = float(plan["interval_msec"])
	var anchor: float = float(plan["anchor_msec"])
	_record(bool(early["slipped"]) and String(early["slot"]) == "pulse",
		"slipped plan is not marked as a pulse-slot landing")
	_record(_on_grid(float(early["landing_msec"]), anchor, interval),
		"slipped landing %.1f is not on the player's pulse grid" % float(early["landing_msec"]))
	_record(float(early["landing_msec"]) >= 100000.0 + 600.0 - 0.001,
		"slipped landing %.1f is unreachable (before earliest arrival %.1f)" % [float(early["landing_msec"]), 160100.0])
	_record(is_equal_approx(float(early["hold_msec"]), float(early["landing_msec"]) - 100600.0),
		"slipped hold %.2f != landing - earliest %.2f" % [float(early["hold_msec"]), float(early["landing_msec"]) - 100600.0])
	_record(float(early["landing_msec"]) <= float(plan["landing_msec"]),
		"early break should pull the strike back, not push it later")
	# Ghost snap after the slip: still a gap slot, immediately before the beat.
	_record(_on_grid(float(early["ghost_ignite_msec"]) + interval * 0.5, anchor, interval),
		"slipped ghost ignition %.1f snapped back ONTO a beat" % float(early["ghost_ignite_msec"]))
	# Late break: earliest arrival past the trailing slot -> the NEXT slot.
	var late: Dictionary = Dictionary(_director_cls.call("slip_plan", plan, 100000, float(plan["landing_msec"]) - 100000.0))
	_record(_on_grid(float(late["landing_msec"]), anchor, interval)
		and float(late["landing_msec"]) >= float(plan["landing_msec"]) - 0.001,
		"late break landing %.1f is not the next reachable pulse slot" % float(late["landing_msec"]))


# ── C. Production fire path (ZoneManager.start_combat -> execute_fire) ─────

var _zone: Node = null


func _start_metrist(zone_manager: Node) -> void:
	_zone = zone_manager
	zone_manager.call("start_combat", [_metrist_enemy()])
	_drain_active(zone_manager, METRIST_ENEMY_ID)


func _check_downbeat_is_real_through_the_production_fire_path() -> void:
	var zone_manager: Node = root.get_node("ZoneManager")
	_reset()
	_start_metrist(zone_manager)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC)
	_record(_is_locked() and _downbeat_armed(), "probe setup: production lock did not arm")
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "Downbeat did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "Downbeat projectile missing after fire")
	if projectile == null or not is_instance_valid(projectile):
		return
	_record(bool(projectile.telegraph_profile.get("metrist_downbeat", false)),
		"armed locked strike did not carry the Downbeat flag (the [metrist_downbeat] marker condition)")
	_record(float(projectile.telegraph_profile.get("warning_bias", 0.0)) > 1.2,
		"Downbeat telegraph warning_bias was not raised for readability")
	_record(float(projectile.call("timing_displacement_remaining")) > 0.0,
		"Downbeat spawned without its timing displacement (hold)")
	# The hold must equal the plan's displacement exactly (same frame).
	var plan: Dictionary = _plan()
	_record(not plan.is_empty() and is_equal_approx(
		float(projectile.call("timing_displacement_remaining")), float(plan["hold_msec"]) / 1000.0),
		"projectile hold != plan hold (%.3f vs %.3f)" % [
			float(projectile.call("timing_displacement_remaining")), float(plan["hold_msec"]) / 1000.0])
	projectile.call("resolve", "probe_hit")


func _check_downbeat_is_timing_only() -> void:
	var zone_manager: Node = root.get_node("ZoneManager")
	_reset()
	_start_metrist(zone_manager)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC)
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "timing-only check: Downbeat did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(is_equal_approx(float(projectile.get("damage")), BASE_DAMAGE),
			"Downbeat changed damage (%.2f != base %.2f) — SovereignDamageCalculator stays the damage authority" % [
				float(projectile.get("damage")), BASE_DAMAGE])
		_record(is_equal_approx(float(projectile.get("speed")), BASE_SPEED),
			"Downbeat changed projectile speed (%.2f != base %.2f) — timing displacement only, never speed scaling" % [
				float(projectile.get("speed")), BASE_SPEED])
		projectile.call("resolve", "probe_hit")
	else:
		_record(false, "timing-only check: projectile missing")
	var echo: Node = _director_cls.call("active_ghost")
	if echo != null and is_instance_valid(echo):
		echo.call("queue_free")


func _check_ghost_echo_is_wired_to_the_plan() -> void:
	var plan: Dictionary = _plan()
	_record(not plan.is_empty(), "probe setup: no active plan after the Downbeat")
	var echo: Node = _director_cls.call("active_ghost")
	_record(echo != null and is_instance_valid(echo), "no Ghost Pulse echo was spawned for the Downbeat")
	if echo != null and is_instance_valid(echo):
		_record(is_equal_approx(float(echo.get("scheduled_ignite_msec")), float(plan["ghost_ignite_msec"])),
			"ghost echo ignition %.1f != plan gap slot %.1f" % [
				float(echo.get("scheduled_ignite_msec")), float(plan["ghost_ignite_msec"])])
		echo.queue_free()


func _check_followup_shot_is_ordinary() -> void:
	var zone_manager: Node = root.get_node("ZoneManager")
	_drain_active(zone_manager, METRIST_ENEMY_ID)
	_record(_is_locked(), "probe setup: lock unexpectedly lost before the follow-up")
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "follow-up shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "follow-up projectile missing")
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("metrist_downbeat", false)),
			"Downbeat chained twice inside one lock")
		_record(float(projectile.call("timing_displacement_remaining")) == 0.0,
			"ordinary shot carried a timing displacement")
		projectile.call("resolve", "probe_done")


func _check_unlocked_shot_is_ordinary() -> void:
	var zone_manager: Node = root.get_node("ZoneManager")
	_reset()
	_start_metrist(zone_manager)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC * 2)
	_rubato_pulse()
	_record(not _is_locked(), "probe setup: rubato pulse did not unlock")
	_drain_active(zone_manager, METRIST_ENEMY_ID)
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "unlocked shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("metrist_downbeat", false)),
			"unlocked (armed-less) shot fired a Downbeat")
		_record(float(projectile.call("timing_displacement_remaining")) == 0.0,
			"unlocked shot carried a timing displacement")
		projectile.call("resolve", "probe_done")
	else:
		_record(false, "unlocked shot projectile missing")


func _check_pattern_break_slips_in_flight() -> void:
	var zone_manager: Node = root.get_node("ZoneManager")
	_reset()
	_start_metrist(zone_manager)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC)
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "slip check: Downbeat did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "slip check: projectile missing")
	if projectile == null or not is_instance_valid(projectile):
		return
	var hold_before: float = float(projectile.call("timing_displacement_remaining"))
	# One rubato pulse breaks the pattern while the strike is in flight.
	_rubato_pulse()
	_record(not _is_locked(), "slip check: rubato pulse did not break the lock")
	var plan: Dictionary = _plan()
	_record(bool(plan.get("slipped", false)), "pattern break did not mark the strike as slipped")
	_record(String(plan.get("slot", "")) == "pulse",
		"slipped strike slot is %s, not the player's pulse slot" % String(plan.get("slot", "")))
	var interval: float = float(plan.get("interval_msec", 0.0))
	var anchor: float = float(plan.get("anchor_msec", 0.0))
	_record(interval > 0.0 and _on_grid(float(plan.get("landing_msec", 0.0)), anchor, interval),
		"slipped landing %.1f is not on the pulse grid" % float(plan.get("landing_msec", 0.0)))
	var hold_after: float = float(projectile.call("timing_displacement_remaining"))
	# Reachable at the fixed flight speed: the landing is at or after the
	# strike's earliest physically possible arrival (now + remaining flight;
	# 50ms slack covers the read-back delay in this synchronous probe).
	var flight_remaining: float = maxf(
		float(projectile.call("time_until_hit_zone")) - hold_after, 0.0)
	var earliest_arrival: float = float(Time.get_ticks_msec()) + flight_remaining
	_record(float(plan.get("landing_msec", 0.0)) >= earliest_arrival - 50.0,
		"slipped landing %.1f is unreachable (before earliest arrival %.1f)" % [
			float(plan.get("landing_msec", 0.0)), earliest_arrival])
	_record(not is_equal_approx(hold_before, hold_after),
		"pattern break left the strike's displacement unchanged (%.3f)" % hold_after)
	_record(is_equal_approx(hold_after, float(plan.get("hold_msec", 0.0)) / 1000.0),
		"projectile hold %.3f != slipped plan hold %.3f" % [hold_after, float(plan.get("hold_msec", 0.0)) / 1000.0])
	# Ghost snap through the live path: the echo stays in a gap.
	var echo: Node = _director_cls.call("active_ghost")
	if echo != null and is_instance_valid(echo):
		var ignite: float = float(echo.get("scheduled_ignite_msec"))
		_record(_on_grid(ignite + interval * 0.5, anchor, interval),
			"ghost echo snapped ONTO a beat after the slip (%.1f)" % ignite)
		echo.call("queue_free")
	projectile.call("resolve", "probe_slip")


func _check_species_identity_is_specific(zone_manager: Node) -> void:
	# A steady groove must never arm another species' strike...
	_reset()
	zone_manager.call("start_combat", [_shard_enemy()])
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC)
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "shard shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("metrist_downbeat", false)),
			"non-Metrist species fired a Downbeat")
		projectile.call("resolve", "probe_done")
	# ...and the Metrist never fires the other species' signatures, even under
	# their trigger conditions on the shared cadence clock: a widened silence
	# gap (the Glintstalker's trigger) and a panic burst (the Shardhulk's
	# trigger) must leave its shot without either flag — and neither trigger
	# earns a Downbeat (silence and bursts are irrelevant; only regularity
	# locks).
	_reset()
	zone_manager.call("start_combat", [_metrist_enemy()])
	_drain_active(zone_manager, METRIST_ENEMY_ID)
	# Glintstalker trigger on the shared clock: silence widened past its gap.
	_pulse(Time.get_ticks_msec() - 6000)
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "metrist identity check: silence shot did not spawn")
	projectile = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("glint_punish", false)),
			"Metrist fired a Glint Shot (identity bleed)")
		_record(not bool(projectile.telegraph_profile.get("metrist_downbeat", false)),
			"Metrist fired a Downbeat out of a silence gap (that is the Glintstalker's trigger)")
		projectile.call("resolve", "probe_done")
	else:
		_record(false, "metrist identity check: silence projectile missing")
	_drain_active(zone_manager, METRIST_ENEMY_ID)
	# Shardhulk trigger on the shared clock: a rapid panic burst.
	var burst_at: int = Time.get_ticks_msec() - 600
	for _burst_i in 3:
		_pulse(burst_at)
		burst_at += 200
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "metrist identity check: burst shot did not spawn")
	projectile = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("shard_panic_close", false)),
			"Metrist fired a Lane Close (identity bleed)")
		_record(not bool(projectile.telegraph_profile.get("metrist_downbeat", false)),
			"Metrist fired a Downbeat out of a panic burst (irregular input never locks)")
		projectile.call("resolve", "probe_done")
	else:
		_record(false, "metrist identity check: burst projectile missing")


func _check_spatial_purity(zone_manager: Node) -> void:
	# The Downbeat must ride exactly the ordinary fire-path geometry: same
	# lane, same spawn position, same hit zone.
	_reset()
	_start_metrist(zone_manager)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC)
	_rubato_pulse()
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "spatial check: ordinary shot did not spawn")
	var ordinary: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	_record(ordinary != null and is_instance_valid(ordinary), "spatial check: ordinary projectile missing")
	if ordinary == null or not is_instance_valid(ordinary):
		return
	var ordinary_lane: int = int(ordinary.get("lane"))
	var ordinary_spawn: Vector2 = Vector2(ordinary.get("enemy_pos"))
	var ordinary_hit: Vector2 = Vector2(ordinary.get("hit_zone_pos"))
	ordinary.call("resolve", "probe_done")
	_reset()
	_start_metrist(zone_manager)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC)
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "spatial check: Downbeat did not spawn")
	var downbeat: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	if downbeat != null and is_instance_valid(downbeat):
		_record(int(downbeat.get("lane")) == ordinary_lane,
			"Downbeat changed the lane (%d != %d)" % [int(downbeat.get("lane")), ordinary_lane])
		_record(Vector2(downbeat.get("enemy_pos")).is_equal_approx(ordinary_spawn)
			and Vector2(downbeat.get("hit_zone_pos")).is_equal_approx(ordinary_hit),
			"Downbeat changed spawn/hit-zone geometry")
		downbeat.call("resolve", "probe_done")
	else:
		_record(false, "spatial check: Downbeat projectile missing")
	var echo: Node = _director_cls.call("active_ghost")
	if echo != null and is_instance_valid(echo):
		echo.call("queue_free")


func _check_player_attacked_wiring() -> void:
	# ZoneManager._ready must connect EventBus.player_attacked to the shared
	# cadence clock: real signal emissions feed the Metrist engine (the shot
	# heading reaches the Ghost Pulse after-image source).
	_reset()
	_bus.emit_signal("player_attacked", 2, 1.0, true, Vector2(0.25, -1.0))
	_bus.emit_signal("player_attacked", 2, 1.0, true, Vector2(0.25, -1.0))
	_record(Vector2(_director_cls.call("last_shot_heading")).is_equal_approx(Vector2(0.25, -1.0)),
		"EventBus.player_attacked heading did not reach the Metrist Ghost Pulse source")


# ── D. Live data + spawn-weight wiring ─────────────────────────────────────

func _check_species_is_authored_in_live_data() -> void:
	var creatures: Dictionary = COMBAT_CONTENT.CREATURES
	_record(creatures.has(METRIST_SPECIES_ID), "Metrist species missing from COMBAT_CONTENT.CREATURES")
	if creatures.has(METRIST_SPECIES_ID):
		var metrist: Dictionary = creatures[METRIST_SPECIES_ID]
		_record(String(metrist.get("description", "")).length() > 0
			and String(metrist.get("signal_flavor", "")).length() > 0,
			"Metrist canon fields missing from live data")
	var profile: Variant = CreatureLocomotionDirector.LOCOM_PROFILES.get(METRIST_SPECIES_ID, {})
	_record(profile is Dictionary and not (profile as Dictionary).is_empty(),
		"Metrist lost its live locomotion profile (identity seam)")
	if profile is Dictionary:
		for key in ["orbit_speed_mult", "approach_lean", "recoil_push", "can_flank"]:
			_record((profile as Dictionary).has(key), "Metrist locomotion profile missing key: %s" % key)


func _check_spawn_weight_wiring_is_live() -> void:
	# The real natural-spawn data path: RegionSongContent enemy_pool weights
	# (the base of EncounterEscalationDirector._roll_weighted_entry). The
	# Metrist must be fielded alongside Glintstalker and Shardhulk with a
	# nonzero weight, and the production weighted picker must reproduce its
	# authored share under a seeded Monte Carlo.
	var region_song: Variant = load(REGION_SONG_PATH)
	_record(region_song is GDScript, "RegionSongContent script did not load")
	if not (region_song is GDScript):
		return
	var constants: Dictionary = (region_song as GDScript).get_script_constant_map()
	var pools_by_region: Variant = constants.get("SONG_PHASES_BY_REGION", {})
	_record(pools_by_region is Dictionary and (pools_by_region as Dictionary).has("pale_shelf"),
		"pale_shelf phase pools missing from RegionSongContent")
	if not (pools_by_region is Dictionary):
		return
	var phases_with_metrist: int = 0
	var metrist_weight: float = 0.0
	var pool_weight: float = 0.0
	for phase in Array((pools_by_region as Dictionary).get("pale_shelf", [])):
		var pool: Array = Array(Dictionary(phase).get("enemy_pool", []))
		for entry in pool:
			var e: Dictionary = Dictionary(entry)
			var w: float = float(e.get("weight", 0.0))
			pool_weight += w
			if String(e.get("species_id", "")) == METRIST_SPECIES_ID:
				metrist_weight += w
				phases_with_metrist += 1
				_record(w > 0.0, "Metrist pool entry without positive weight in phase %s" % String(phase.get("id", "?")))
	print("SPAWN_WEIGHT_FACT metrist phases_with_metrist=%d metrist_weight_sum=%.2f pool_weight_sum=%.2f share=%.2f%%" % [
		phases_with_metrist, metrist_weight, pool_weight,
		(metrist_weight / pool_weight * 100.0) if pool_weight > 0.0 else 0.0])
	_record(phases_with_metrist >= 4,
		"Metrist is fielded in only %d pale_shelf phase pools (expected >= 4)" % phases_with_metrist)
	# Seeded Monte Carlo through the pure weighted picker owner.
	var identity_runtime: Variant = load(IDENTITY_RUNTIME_PATH)
	_record(identity_runtime is GDScript, "EncounterIdentityRuntime script did not load")
	if not (identity_runtime is GDScript):
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = MONTE_CARLO_SEED
	var target_phase: Dictionary = {}
	for phase in Array((pools_by_region as Dictionary).get("pale_shelf", [])):
		if String(Dictionary(phase).get("id", "")) == "opening":
			target_phase = Dictionary(phase)
	var target_pool: Array = Array(target_phase.get("enemy_pool", []))
	var analytic: float = 0.0
	var total: float = 0.0
	for entry in target_pool:
		var e: Dictionary = Dictionary(entry)
		total += float(e.get("weight", 0.0))
		if String(e.get("species_id", "")) == METRIST_SPECIES_ID:
			analytic += float(e.get("weight", 0.0))
	analytic = analytic / total if total > 0.0 else 0.0
	var picks: int = 0
	for _i in range(MONTE_CARLO_ROLLS):
		var picked: Dictionary = Dictionary(identity_runtime.call("pick_weighted_enemy", target_phase, rng))
		if String(picked.get("species_id", "")) == METRIST_SPECIES_ID:
			picks += 1
	var measured: float = float(picks) / float(MONTE_CARLO_ROLLS)
	print("SPAWN_MONTE_CARLO phase=opening rolls=%d metrist_picks=%d measured=%.2f%% analytic=%.2f%%" % [
		MONTE_CARLO_ROLLS, picks, measured * 100.0, analytic * 100.0])
	_record(analytic > 0.0, "Metrist authored share is zero in the opening pale_shelf pool")
	_record(picks > 0, "production weighted picker never rolled a Metrist in %d seeded draws" % MONTE_CARLO_ROLLS)
	_record(absf(measured - analytic) <= MONTE_CARLO_TOLERANCE,
		"measured Metrist spawn share %.2f%% drifted from authored %.2f%%" % [measured * 100.0, analytic * 100.0])


# ── E. Independent authorship controls ─────────────────────────────────────

# MUTATION CONTROL (independent authorship): the one-Downbeat-per-lock bound
# is an EDGE law - the Downbeat is armed only by the unlock -> locked
# transition and consumed at spawn. A second armed Downbeat must never exist
# inside one lock (two-per-lock AND alternating both trip here), continuing
# pulses that keep the lock must never re-arm it, and an unarmed strike must
# never carry the [metrist_downbeat] marker.
func _check_mutation_one_downbeat_per_lock_never_rearms() -> void:
	# Engine layer: re-arm only on the unlock -> locked edge.
	_reset()
	_steady_train(7, -500000 + 7 * PULSE_INTERVAL_MSEC)
	_record(_is_locked() and _downbeat_armed(), "probe setup: lock did not arm")
	_record(bool(_director_cls.call("consume_downbeat")), "probe setup: armed Downbeat did not consume")
	# More pulses of the SAME groove: the lock never breaks, so the edge
	# never fires - a re-arm here is the regression.
	_steady_train(7, -500000 + 14 * PULSE_INTERVAL_MSEC)
	_record(_is_locked(), "probe setup: continuing the groove must keep the lock")
	_record(not _downbeat_armed(), "Downbeat re-armed inside one lock (edge law regressed)")
	_record(not bool(_director_cls.call("consume_downbeat")), "a second Downbeat armed inside one lock")
	# Production layer: three shots inside ONE lock - exactly the first is a
	# Downbeat; the unarmed follow-ups must stay ordinary (marker-free).
	var zone_manager: Node = root.get_node("ZoneManager")
	_reset()
	_start_metrist(zone_manager)
	_steady_train(7, Time.get_ticks_msec() - PULSE_INTERVAL_MSEC)
	_record(_is_locked() and _downbeat_armed(), "probe setup: production lock did not arm")
	for n in [1, 2, 3]:
		_drain_active(zone_manager, METRIST_ENEMY_ID)
		_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "lock shot %d did not spawn" % n)
		var shot: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
		_record(shot != null and is_instance_valid(shot), "lock shot %d missing" % n)
		if shot == null or not is_instance_valid(shot):
			continue
		var marked: bool = bool(shot.telegraph_profile.get("metrist_downbeat", false))
		if n == 1:
			_record(marked, "probe setup: the first armed locked strike must carry the marker")
			_record(float(shot.call("timing_displacement_remaining")) > 0.0,
				"probe setup: the armed locked strike must carry its hold")
		else:
			_record(not _downbeat_armed(),
				"lock shot %d found a re-armed Downbeat inside one lock" % n)
			_record(not marked,
				"unarmed strike %d carried the [metrist_downbeat] marker" % n)
			_record(float(shot.call("timing_displacement_remaining")) == 0.0,
				"unarmed strike %d carried a timing displacement" % n)
		shot.call("resolve", "probe_done")
	var echo: Node = _director_cls.call("active_ghost")
	if echo != null and is_instance_valid(echo):
		echo.call("queue_free")


# NEGATIVE CONTROL (independent authorship): the slip counterplay retargets
# TIME ONLY. When the player's pattern breaks, the strike must land ON a
# reachable player pulse slot - exactly one of the rhythm slots defined by
# the pulse timestamps this probe itself sent (never an arbitrary time, never
# the unslipped offbeat) - reachable at the FIXED flight (never faster), while
# damage and speed stay byte-identical (SovereignDamageCalculator stays the
# damage authority; the slip may move when, never what).
func _check_negative_slip_lands_on_reachable_pulse_slot_timing_only() -> void:
	var zone_manager: Node = root.get_node("ZoneManager")
	_reset()
	_start_metrist(zone_manager)
	# A steady groove with KNOWN probe pulse times: the rhythm grid below is
	# derived from the pulses this probe actually sent, independently of the
	# plan's own anchor.
	var last_at: int = Time.get_ticks_msec() - PULSE_INTERVAL_MSEC
	_steady_train(7, last_at)
	_record(_is_locked() and _downbeat_armed(), "probe setup: lock did not arm")
	_record(bool(zone_manager.call("execute_fire", METRIST_ENEMY_ID)), "slip negative: Downbeat did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", METRIST_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "slip negative: projectile missing")
	if projectile == null or not is_instance_valid(projectile):
		return
	var damage_before: float = float(projectile.get("damage"))
	var speed_before: float = float(projectile.get("speed"))
	var hold_before: float = float(projectile.call("timing_displacement_remaining"))
	var plan_before: Dictionary = _plan()
	# The pattern breaks while the strike is in flight.
	_rubato_pulse()
	var plan: Dictionary = _plan()
	_record(bool(plan.get("slipped", false)), "slip negative: pattern break did not slip the strike")
	_record(String(plan.get("slot", "")) == "pulse",
		"slip negative: slipped slot is %s, not the player's pulse slot" % String(plan.get("slot", "")))
	var interval: float = float(plan.get("interval_msec", 0.0))
	var anchor: float = float(plan.get("anchor_msec", 0.0))
	var landing: float = float(plan.get("landing_msec", 0.0))
	# NEVER an arbitrary time: the landing sits exactly on the pulse grid
	# anchored at the probe's own sent pulse timestamps.
	_record(interval > 0.0 and _on_grid(landing, float(last_at), float(PULSE_INTERVAL_MSEC)),
		"slip negative: landing %.1f is not on the probe-sent pulse grid (arbitrary time)" % landing)
	# ...and on the plan's own grid, but OFF the unslipped offbeat: the
	# retarget moved the landing onto a slot.
	_record(_on_grid(landing, anchor, interval),
		"slip negative: landing %.1f is not on the measured rhythm grid" % landing)
	_record(not is_equal_approx(landing, float(plan_before.get("landing_msec", -1.0))),
		"slip negative: the pattern break did not move the landing off the offbeat")
	# Reachable at the fixed flight: never faster than the strike can travel.
	var hold_after: float = float(projectile.call("timing_displacement_remaining"))
	var flight_remaining: float = maxf(
		float(projectile.call("time_until_hit_zone")) - hold_after, 0.0)
	var earliest_arrival: float = float(Time.get_ticks_msec()) + flight_remaining
	_record(landing >= earliest_arrival - 50.0,
		"slip negative: landing %.1f is unreachable (before earliest arrival %.1f)" % [
			landing, earliest_arrival])
	# TIMING-ONLY: the slip may move when, never what.
	var damage_after: float = float(projectile.get("damage"))
	var speed_after: float = float(projectile.get("speed"))
	_record(is_equal_approx(damage_after, damage_before) and is_equal_approx(damage_after, BASE_DAMAGE),
		"slip negative: the retarget changed damage (%.2f -> %.2f) - SovereignDamageCalculator stays the damage authority" % [
			damage_before, damage_after])
	_record(is_equal_approx(speed_after, speed_before) and is_equal_approx(speed_after, BASE_SPEED),
		"slip negative: the retarget changed flight speed (%.1f -> %.1f) - timing displacement only, never speed scaling" % [
			speed_before, speed_after])
	_record(not is_equal_approx(hold_before, hold_after),
		"slip negative: the pattern break left the strike's timing untouched")
	var echo: Node = _director_cls.call("active_ghost")
	if echo != null and is_instance_valid(echo):
		echo.call("queue_free")
	projectile.call("resolve", "probe_slip")
