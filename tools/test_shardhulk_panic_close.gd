extends SceneTree

# tools/test_shardhulk_panic_close.gd
# Headless regression probe for the Shardhulk "Panic Close" species behavior:
# a distinct, gameplay-affecting combat identity for
# pale_shelf_shardshroud_sentinel (Shardhulk) wired through the production
# fire path (ZoneManager.start_combat -> ZoneManager.execute_fire ->
# EnemyStriker -> Projectile.tscn), plus the readability cues that ride with
# the lane-close shot.
#
# Contract under test (canon: "A plated weight that expects you to panic. It
# closes the lane with the cold patience of a glacier." / "Its plates click
# once before it fires. The click is the only warning."):
#   1. PANIC CLOSE IS A REAL BEHAVIOR: when the player's attack cadence turns
#      into a panic burst (>= EnemyStriker.SHARD_PANIC_BURST pulses each
#      within SHARD_PANIC_GAP of the last), the Shardhulk's next spawned
#      projectile is a Lane Close (damage x SHARD_CLOSE_DAMAGE_MULT, speed x
#      SHARD_CLOSE_SPEED_MULT — slower, it closes the lane — plus
#      telegraph_profile["shard_panic_close"] and a raised warning_bias)
#      through the same _fire_striker path CombatScene uses. It is not
#      cosmetic-only: the shot is heavier and glacially slow.
#   2. ONE CLOSE PER PANIC EPISODE: the close is consumed when the shot
#      spawns; a follow-up shot inside the same episode is ordinary. Further
#      spam inside the same episode does not re-arm it.
#   3. A CALM PULSE DISARMS, A FRESH BURST RE-ARMS: a pulse after a calm gap
#      (>= SHARD_PANIC_GAP) resets the burst count so the Shardhulk is
#      passive; only a new rapid burst re-arms the close.
#   4. IDENTITY IS SPECIES-SPECIFIC AND DISTINCT: the Glintstalker never
#      fires Lane Close shots whatever the cadence, and the Shardhulk still
#      never fires Glint Shots (the gen-1 invariant, asserted from the other
#      side). The two rules are opposites: silence -> faster shot vs panic ->
#      slower shot.
#   5. READABILITY CUES RIDE WITH THE CLOSE: proc_feedback_requested
#      ("PLATES CLICK") and screen_flash fire exactly on Lane Close shots.
#   6. THE SPECIES IS AUTHORED IN LIVE DATA (species + locomotion identity).
#
# Runs through project autoloads (EventBus, PlayerState) like the other
# tools/test_*.gd probes. Fails before the Panic Close wiring; passes after.
# Never weakens tools/test_glint_stalker_silence_punish.gd — that suite's
# expectations are re-asserted here from the Shardhulk side only.

const ZONE_MANAGER_SCRIPT_PATH: String = "res://scenes/combat/ZoneManager.gd"

const GLINT_SPECIES_ID: String = "pale_shelf_precision_stalker"
const SHARD_SPECIES_ID: String = "pale_shelf_shardshroud_sentinel"
const SHARD_ENEMY_ID: int = 9303
const GLINT_ENEMY_ID: int = 9404
const SHARD_BASE_DAMAGE: float = 10.0
const SHARD_BASE_SPEED: float = 286.0
const GLINT_BASE_DAMAGE: float = 10.0

var _failures: Array[String] = []
var _checks: int = 0
var _feedback_events: Array[String] = []
var _flash_events: int = 0
# Autoload identifiers do not compile into a `-s` main script; fetch by node
# path like the other tools/test_*.gd probes. Likewise, EnemyStriker.gd reads
# the PlayerState autoload, so referencing its class_name at compile time here
# would compile it before autoloads register and poison it; load it at runtime
# and dispatch its statics dynamically instead.
var _bus: Node = null
var _striker_cls: Variant = null
var _striker_consts: Dictionary = {}


func _initialize() -> void:
	# Load after project autoloads are registered (see test_combat_scene.gd).
	call_deferred(&"_run")


func _run() -> void:
	print("=== test_shardhulk_panic_close: Shardhulk Panic Close identity ===")
	_bus = root.get_node("EventBus")
	_bus.proc_feedback_requested.connect(_on_proc_feedback)
	_bus.screen_flash.connect(_on_screen_flash)
	_striker_cls = load("res://scenes/combat/EnemyStriker.gd")
	_record(_striker_cls is GDScript, "EnemyStriker script did not load at runtime")
	if _striker_cls is GDScript:
		_striker_consts = (_striker_cls as GDScript).get_script_constant_map()

	var zone_manager_script: Variant = load(ZONE_MANAGER_SCRIPT_PATH)
	_record(zone_manager_script is Script, "ZoneManager script did not load")
	if not (zone_manager_script is Script):
		_finish()
		return

	var zone_manager: Node = (zone_manager_script as Script).new()
	root.add_child(zone_manager)
	zone_manager.setup_layout(Vector2(1280.0, 720.0))
	_record(bool(zone_manager.call("load_scene")), "ZoneManager.load_scene() failed")

	_check_panic_close_is_real(zone_manager)
	_check_close_is_consumed_once_per_episode(zone_manager)
	_check_calm_pulse_disarms_and_fresh_burst_rearms(zone_manager)
	_check_species_identity_is_specific(zone_manager)
	_check_player_attacked_wiring(zone_manager)
	_check_species_is_authored_in_live_data()

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

func _on_proc_feedback(text: String, _color: Color) -> void:
	_feedback_events.append(text)

func _on_screen_flash(_color: Color, _duration: float) -> void:
	_flash_events += 1

func _shard_enemy() -> Dictionary:
	return {
		"id": SHARD_ENEMY_ID,
		"species_id": SHARD_SPECIES_ID,
		"type": "dreg",
		"hp": 38.0,
		"damage": SHARD_BASE_DAMAGE,
		"projectile_speed": SHARD_BASE_SPEED
	}

func _glint_enemy() -> Dictionary:
	return {
		"id": GLINT_ENEMY_ID,
		"species_id": GLINT_SPECIES_ID,
		"type": "dreg",
		"hp": 30.0,
		"damage": GLINT_BASE_DAMAGE,
		"projectile_speed": 430.0
	}

func _drain_active(zone_manager: Node, id: int) -> void:
	# The production fire director may spawn a cycle shot during start_combat.
	# Resolve it so each probe fire is the only projectile in flight.
	var projectile: Variant = zone_manager.call("get_projectile_by_id", id)
	if projectile != null and is_instance_valid(projectile) and not bool(projectile.is_resolved):
		projectile.call("resolve", "probe_drain")

func _stamp(at: int) -> int:
	# Engine uptime can be young enough that a backdated timestamp goes
	# negative; -1 is the "now" sentinel in note_player_attack, so nudge it.
	if at == -1:
		return -2
	return at

## A deterministic panic burst: combat start resets the cadence clock, then
## SHARD_PANIC_BURST pulses land 200ms apart (all gaps < SHARD_PANIC_GAP).
func _fire_panic_burst(times: int = -1) -> void:
	var burst: int = int(_striker_consts.get("SHARD_PANIC_BURST", 3)) if times <= 0 else times
	_striker_cls.call("mark_combat_start")
	var at: int = Time.get_ticks_msec() - burst * 200
	for i in range(burst):
		_striker_cls.call("note_player_attack", _stamp(at + i * 200))

## One pulse after a calm gap (>= SHARD_PANIC_GAP): resets the burst count.
func _calm_pulse() -> void:
	_striker_cls.call("mark_combat_start")
	_striker_cls.call("note_player_attack", _stamp(Time.get_ticks_msec() - 4000))

func _widen_silence(seconds: float = 5.0) -> void:
	_striker_cls.call("note_player_attack", _stamp(Time.get_ticks_msec() - int(seconds * 1000.0)))

func _shard_const(const_name: String) -> float:
	return float(_striker_consts.get(const_name, 0.0))

func _shard_int_const(const_name: String) -> int:
	return int(_striker_consts.get(const_name, 0))

func _panic_count() -> int:
	return int(_striker_cls.call("panic_burst_count"))

func _check_panic_close_is_real(zone_manager: Node) -> void:
	zone_manager.call("start_combat", [_shard_enemy()])
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	_fire_panic_burst()
	_record(_panic_count() >= _shard_int_const("SHARD_PANIC_BURST"),
		"probe setup: panic burst did not reach the burst threshold")
	_feedback_events.clear()
	_flash_events = 0
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "lane close did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "shard projectile missing after fire")
	if projectile == null or not is_instance_valid(projectile):
		return
	_record(bool(projectile.telegraph_profile.get("shard_panic_close", false)),
		"armed panic burst did not produce a flagged Lane Close")
	_record(not bool(projectile.telegraph_profile.get("glint_punish", false)),
		"Shardhulk Lane Close carried a Glint Shot flag (identity bleed)")
	_record(is_equal_approx(float(projectile.damage), SHARD_BASE_DAMAGE * _shard_const("SHARD_CLOSE_DAMAGE_MULT")),
		"Lane Close damage %.2f != %.2f" % [float(projectile.damage), SHARD_BASE_DAMAGE * _shard_const("SHARD_CLOSE_DAMAGE_MULT")])
	_record(is_equal_approx(float(projectile.speed), SHARD_BASE_SPEED * _shard_const("SHARD_CLOSE_SPEED_MULT")),
		"Lane Close speed %.2f != %.2f" % [float(projectile.speed), SHARD_BASE_SPEED * _shard_const("SHARD_CLOSE_SPEED_MULT")])
	_record(float(projectile.speed) < SHARD_BASE_SPEED,
		"Lane Close must be slower than base (glacial close), got %.2f" % float(projectile.speed))
	_record(float(projectile.telegraph_profile.get("warning_bias", 0.0)) > 1.2,
		"Lane Close telegraph warning_bias was not raised for the plate-click warning")
	# Readability cues ride with the close only.
	_record(_feedback_events.size() == 1 and String(_feedback_events[0]).contains("PLATES"),
		"shard proc feedback banner missing or duplicated: %s" % str(_feedback_events))
	_record(_flash_events == 1, "shard screen flash missing or duplicated: %d" % _flash_events)
	projectile.call("resolve", "probe_hit")

func _check_close_is_consumed_once_per_episode(zone_manager: Node) -> void:
	# Same panic episode as _check_panic_close_is_real (no fresh burst): the
	# close is spent, so this follow-up must be an ordinary shard shot.
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	_feedback_events.clear()
	_flash_events = 0
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "follow-up shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "follow-up projectile missing")
	if projectile == null or not is_instance_valid(projectile):
		return
	_record(not bool(projectile.telegraph_profile.get("shard_panic_close", false)),
		"Lane Close chained twice inside one panic episode")
	_record(is_equal_approx(float(projectile.damage), SHARD_BASE_DAMAGE),
		"follow-up damage %.2f != base %.2f" % [float(projectile.damage), SHARD_BASE_DAMAGE])
	_record(_feedback_events.is_empty() and _flash_events == 0,
		"shard readability cues fired on a non-close shot")
	projectile.call("resolve", "probe_done")

func _check_calm_pulse_disarms_and_fresh_burst_rearms(zone_manager: Node) -> void:
	# A calm-spaced pulse resets the burst count: Shardhulk passive.
	_calm_pulse()
	_record(_panic_count() < _shard_int_const("SHARD_PANIC_BURST"),
		"calm pulse did not reset the panic burst count")
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "post-calm shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("shard_panic_close", false)),
			"Lane Close fired after a calm pulse (no panic burst)")
		projectile.call("resolve", "probe_done")
	# A fresh panic burst must re-arm the close.
	_fire_panic_burst()
	_record(_panic_count() >= _shard_int_const("SHARD_PANIC_BURST"),
		"fresh panic burst did not reach the burst threshold")
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "re-armed shot did not spawn")
	projectile = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(bool(projectile.telegraph_profile.get("shard_panic_close", false)),
			"close did not re-arm after a fresh panic burst")
		projectile.call("resolve", "probe_done")

func _check_species_identity_is_specific(zone_manager: Node) -> void:
	# The Glintstalker never fires Lane Close shots whatever the cadence...
	zone_manager.call("start_combat", [_glint_enemy()])
	_drain_active(zone_manager, GLINT_ENEMY_ID)
	_fire_panic_burst()
	_record(bool(zone_manager.call("execute_fire", GLINT_ENEMY_ID)), "glint shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", GLINT_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "glint projectile missing")
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("shard_panic_close", false)),
			"non-Shardhulk species fired a Lane Close")
		_record(is_equal_approx(float(projectile.damage), GLINT_BASE_DAMAGE),
			"glint species damage changed by the panic rule: %.2f" % float(projectile.damage))
		projectile.call("resolve", "probe_done")
	# ...and the Shardhulk still never fires Glint Shots (gen-1 invariant),
	# even with a widened silence gap on the shared clock.
	zone_manager.call("start_combat", [_shard_enemy()])
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	_widen_silence(6.0)
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "shard shot did not spawn")
	projectile = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "shard projectile missing")
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("glint_punish", false)),
			"non-Glintstalker species fired a Glint Shot")
		_record(not bool(projectile.telegraph_profile.get("shard_panic_close", false)),
			"Lane Close fired on a widened silence gap (that is the Glintstalker's rule)")
		projectile.call("resolve", "probe_done")

func _check_player_attacked_wiring(zone_manager: Node) -> void:
	# ZoneManager._ready must connect EventBus.player_attacked to the cadence
	# clock: three real signal emissions must build the panic burst.
	zone_manager.call("start_combat", [_shard_enemy()])
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	for _i in 3:
		_bus.emit_signal("player_attacked", 0, 1.0, true, Vector2.RIGHT)
	_record(_panic_count() >= _shard_int_const("SHARD_PANIC_BURST"),
		"EventBus.player_attacked is not connected to the panic clock in ZoneManager")
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "signal-built burst shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(bool(projectile.telegraph_profile.get("shard_panic_close", false)),
			"panic burst built from real signals did not arm the close")
		projectile.call("resolve", "probe_done")

func _check_species_is_authored_in_live_data() -> void:
	var creatures: Dictionary = COMBAT_CONTENT.CREATURES
	_record(creatures.has(SHARD_SPECIES_ID), "Shardhulk species missing from COMBAT_CONTENT.CREATURES")
	var profile: Variant = CreatureLocomotionDirector.LOCOM_PROFILES.get(SHARD_SPECIES_ID, {})
	_record(profile is Dictionary and not (profile as Dictionary).is_empty(),
		"Shardhulk lost its live locomotion profile (identity seam)")
	if creatures.has(SHARD_SPECIES_ID):
		var shard: Dictionary = creatures[SHARD_SPECIES_ID]
		_record(String(shard.get("description", "")).length() > 0 and String(shard.get("signal_flavor", "")).length() > 0,
			"Shardhulk canon fields missing from live data")
