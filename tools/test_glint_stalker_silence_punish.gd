extends SceneTree

# tools/test_glint_stalker_silence_punish.gd
# Headless regression probe for the Glintstalker "Silence Punish" species
# behavior: a distinct, gameplay-affecting combat identity for
# pale_shelf_precision_stalker (Glintstalker) wired through the production
# fire path (ZoneManager.start_combat -> ZoneManager.execute_fire ->
# EnemyStriker -> Projectile.tscn), plus the readability cues that ride with
# the punished shot.
#
# Contract under test:
#   1. SILENCE PUNISH IS A REAL BEHAVIOR: when the player's attack cadence
#      goes silent for >= EnemyStriker.GLINT_SILENCE_GAP, the Glintstalker's
#      next spawned projectile is a Glint Shot (damage x GLINT_DAMAGE_MULT,
#      speed x GLINT_SPEED_MULT, telegraph_profile["glint_punish"] set, a
#      raised warning_bias) through the same _fire_striker path CombatScene
#      uses. It is not cosmetic-only: the shot is faster and heavier.
#   2. ONE PUNISH PER GAP: the punish is consumed when the shot spawns; a
#      follow-up shot in the same silence is an ordinary precision shot.
#   3. THE PLAYER'S PULSE DISARMS IT: EventBus.player_attacked resets the
#      cadence clock (ZoneManager wiring), and the punish only re-arms after
#      a fresh widened gap. A short gap never arms it.
#   4. IDENTITY IS SPECIES-SPECIFIC: no other species (e.g. the Shardhulk,
#      pale_shelf_shardshroud_sentinel) fires Glint Shots whatever the
#      cadence, and the Glintstalker species id is authored in live data.
#   5. READABILITY CUES RIDE WITH THE PUNISH: proc_feedback_requested and
#      screen_flash fire exactly on Glint Shots (both consumed by CombatScene).
#
# Runs through project autoloads (EventBus, PlayerState) like the other
# tools/test_*.gd probes. Fails before the Silence Punish wiring; passes after.

const ZONE_MANAGER_SCRIPT_PATH: String = "res://scenes/combat/ZoneManager.gd"

const GLINT_SPECIES_ID: String = "pale_shelf_precision_stalker"
const SHARD_SPECIES_ID: String = "pale_shelf_shardshroud_sentinel"
const GLINT_ENEMY_ID: int = 9101
const SHARD_ENEMY_ID: int = 9202
const GLINT_BASE_DAMAGE: float = 10.0
const GLINT_BASE_SPEED: float = 430.0

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
	print("=== test_glint_stalker_silence_punish: Glintstalker Silence Punish identity ===")
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

	_check_silence_punish_is_real(zone_manager)
	_check_punish_is_consumed_once_per_gap(zone_manager)
	_check_player_pulse_disarms(zone_manager)
	_check_species_identity_is_specific(zone_manager)
	_check_player_attacked_wiring(zone_manager)
	_check_species_is_authored_in_live_data()
	_check_mutation_one_punish_per_episode_and_ordinary_purity(zone_manager)

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


func _glint_enemy() -> Dictionary:
	return {
		"id": GLINT_ENEMY_ID,
		"species_id": GLINT_SPECIES_ID,
		"type": "dreg",
		"hp": 30.0,
		"damage": GLINT_BASE_DAMAGE,
		"projectile_speed": GLINT_BASE_SPEED
	}


func _shard_enemy() -> Dictionary:
	return {
		"id": SHARD_ENEMY_ID,
		"species_id": SHARD_SPECIES_ID,
		"type": "dreg",
		"hp": 38.0,
		"damage": GLINT_BASE_DAMAGE,
		"projectile_speed": 286.0
	}


func _drain_active(zone_manager: Node, id: int) -> void:
	# The production fire director may spawn a cycle shot during start_combat.
	# Resolve it so each probe fire is the only projectile in flight.
	var projectile: Variant = zone_manager.call("get_projectile_by_id", id)
	if projectile != null and is_instance_valid(projectile) and not bool(projectile.is_resolved):
		projectile.call("resolve", "probe_drain")


func _widen_silence(seconds: float = 5.0) -> void:
	# Backdate the cadence clock. Engine uptime can be young enough that the
	# backdated timestamp goes negative; -1 is the "now" sentinel, so nudge it.
	var at: int = Time.get_ticks_msec() - int(seconds * 1000.0)
	if at == -1:
		at = -2
	_striker_cls.call("note_player_attack", at)


func _silence_gap() -> float:
	return float(_striker_cls.call("silence_gap"))


func _glint_const(const_name: String) -> float:
	return float(_striker_consts.get(const_name, 0.0))


func _check_silence_punish_is_real(zone_manager: Node) -> void:
	zone_manager.call("start_combat", [_glint_enemy()])
	_drain_active(zone_manager, GLINT_ENEMY_ID)
	_widen_silence(5.0)
	_record(_silence_gap() >= _glint_const("GLINT_SILENCE_GAP"),
		"probe setup: silence gap did not widen past threshold")
	_feedback_events.clear()
	_flash_events = 0
	_record(bool(zone_manager.call("execute_fire", GLINT_ENEMY_ID)), "glint shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", GLINT_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "glint projectile missing after fire")
	if projectile == null or not is_instance_valid(projectile):
		return
	_record(bool(projectile.telegraph_profile.get("glint_punish", false)),
		"armed silence did not produce a flagged Glint Shot")
	_record(is_equal_approx(float(projectile.damage), GLINT_BASE_DAMAGE * _glint_const("GLINT_DAMAGE_MULT")),
		"Glint Shot damage %.2f != %.2f" % [float(projectile.damage), GLINT_BASE_DAMAGE * _glint_const("GLINT_DAMAGE_MULT")])
	_record(is_equal_approx(float(projectile.speed), GLINT_BASE_SPEED * _glint_const("GLINT_SPEED_MULT")),
		"Glint Shot speed %.2f != %.2f" % [float(projectile.speed), GLINT_BASE_SPEED * _glint_const("GLINT_SPEED_MULT")])
	_record(float(projectile.telegraph_profile.get("warning_bias", 0.0)) > 1.2,
		"Glint Shot telegraph warning_bias was not raised for readability")
	# Readability cues ride with the punished shot only.
	_record(_feedback_events.size() == 1 and String(_feedback_events[0]).contains("SILENCE"),
		"glint proc feedback banner missing or duplicated: %s" % str(_feedback_events))
	_record(_flash_events == 1, "glint screen flash missing or duplicated: %d" % _flash_events)
	projectile.call("resolve", "probe_hit")


func _check_punish_is_consumed_once_per_gap(zone_manager: Node) -> void:
	_drain_active(zone_manager, GLINT_ENEMY_ID)
	_feedback_events.clear()
	_flash_events = 0
	_record(bool(zone_manager.call("execute_fire", GLINT_ENEMY_ID)), "follow-up shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", GLINT_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "follow-up projectile missing")
	if projectile == null or not is_instance_valid(projectile):
		return
	_record(not bool(projectile.telegraph_profile.get("glint_punish", false)),
		"Glint Shot chained twice inside one silence gap")
	_record(is_equal_approx(float(projectile.damage), GLINT_BASE_DAMAGE),
		"follow-up damage %.2f != base %.2f" % [float(projectile.damage), GLINT_BASE_DAMAGE])
	_record(_feedback_events.is_empty() and _flash_events == 0,
		"glint readability cues fired on a non-punished shot")
	projectile.call("resolve", "probe_done")


func _check_player_pulse_disarms(zone_manager: Node) -> void:
	# A fresh player pulse (short gap) must keep the Glintstalker passive.
	_bus.emit_signal("player_attacked", 0, 1.0, true, Vector2.RIGHT)
	_record(_silence_gap() < _glint_const("GLINT_SILENCE_GAP"),
		"player pulse did not reset the silence clock")
	_drain_active(zone_manager, GLINT_ENEMY_ID)
	_record(bool(zone_manager.call("execute_fire", GLINT_ENEMY_ID)), "post-pulse shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", GLINT_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("glint_punish", false)),
			"Glint Shot fired on a fresh player pulse (short gap)")
		projectile.call("resolve", "probe_done")
	# The next widened gap must re-arm the punish.
	_widen_silence(5.0)
	_drain_active(zone_manager, GLINT_ENEMY_ID)
	_record(bool(zone_manager.call("execute_fire", GLINT_ENEMY_ID)), "re-armed shot did not spawn")
	projectile = zone_manager.call("get_projectile_by_id", GLINT_ENEMY_ID)
	if projectile != null and is_instance_valid(projectile):
		_record(bool(projectile.telegraph_profile.get("glint_punish", false)),
			"punish did not re-arm after a fresh widened gap")
		projectile.call("resolve", "probe_done")


func _check_species_identity_is_specific(zone_manager: Node) -> void:
	zone_manager.call("start_combat", [_shard_enemy()])
	_drain_active(zone_manager, SHARD_ENEMY_ID)
	_widen_silence(6.0)
	_record(bool(zone_manager.call("execute_fire", SHARD_ENEMY_ID)), "shard shot did not spawn")
	var projectile: Variant = zone_manager.call("get_projectile_by_id", SHARD_ENEMY_ID)
	_record(projectile != null and is_instance_valid(projectile), "shard projectile missing")
	if projectile != null and is_instance_valid(projectile):
		_record(not bool(projectile.telegraph_profile.get("glint_punish", false)),
			"non-Glintstalker species fired a Glint Shot")
		projectile.call("resolve", "probe_done")


func _check_player_attacked_wiring(zone_manager: Node) -> void:
	# ZoneManager._ready must connect EventBus.player_attacked to the cadence
	# clock (signal emitted AND connected).
	zone_manager.call("start_combat", [_glint_enemy()])
	_drain_active(zone_manager, GLINT_ENEMY_ID)
	_widen_silence(6.0)
	_bus.emit_signal("player_attacked", 1, 2.0, false, Vector2.LEFT)
	_record(_silence_gap() < _glint_const("GLINT_SILENCE_GAP"),
		"EventBus.player_attacked is not connected to the cadence clock in ZoneManager")


func _check_species_is_authored_in_live_data() -> void:
	var creatures: Dictionary = COMBAT_CONTENT.CREATURES
	_record(creatures.has(GLINT_SPECIES_ID), "Glintstalker species missing from COMBAT_CONTENT.CREATURES")
	var profile: Variant = CreatureLocomotionDirector.LOCOM_PROFILES.get(GLINT_SPECIES_ID, {})
	_record(profile is Dictionary and not (profile as Dictionary).is_empty(),
		"Glintstalker lost its live locomotion profile (identity seam)")


# MUTATION CONTROL (independent authorship): within ONE widened silence gap
# the episode carries exactly one punish. Shot 3 of the same gap must still be
# ordinary, so this fails if the one-punish-per-episode bound regresses (two
# per gap, alternating punish/ordinary, ...) or if an unarmed/ordinary shot
# can carry the species punish marker, its stats, its raised telegraph bias,
# or its readability cues.
func _check_mutation_one_punish_per_episode_and_ordinary_purity(zone_manager: Node) -> void:
	zone_manager.call("start_combat", [_glint_enemy()])
	_drain_active(zone_manager, GLINT_ENEMY_ID)
	_widen_silence(6.0)
	_feedback_events.clear()
	_flash_events = 0
	_record(bool(zone_manager.call("execute_fire", GLINT_ENEMY_ID)), "episode shot 1 did not spawn")
	var shot1: Variant = zone_manager.call("get_projectile_by_id", GLINT_ENEMY_ID)
	_record(shot1 != null and is_instance_valid(shot1), "episode shot 1 missing")
	if shot1 == null or not is_instance_valid(shot1):
		return
	_record(bool(shot1.telegraph_profile.get("glint_punish", false)),
		"episode shot 1 must be the episode's single punish")
	shot1.call("resolve", "probe_done")
	_feedback_events.clear()
	_flash_events = 0
	for n in [2, 3]:
		_drain_active(zone_manager, GLINT_ENEMY_ID)
		_record(bool(zone_manager.call("execute_fire", GLINT_ENEMY_ID)), "episode shot %d did not spawn" % n)
		var shot: Variant = zone_manager.call("get_projectile_by_id", GLINT_ENEMY_ID)
		_record(shot != null and is_instance_valid(shot), "episode shot %d missing" % n)
		if shot == null or not is_instance_valid(shot):
			continue
		_record(not bool(shot.telegraph_profile.get("glint_punish", false)),
			"one-punish-per-episode bound regressed: episode shot %d carried the punish marker" % n)
		_record(is_equal_approx(float(shot.damage), GLINT_BASE_DAMAGE)
			and is_equal_approx(float(shot.speed), GLINT_BASE_SPEED),
			"ordinary shot %d inherited punish stats (d=%.2f s=%.2f)" % [n, float(shot.damage), float(shot.speed)])
		_record(float(shot.telegraph_profile.get("warning_bias", 0.0)) <= 1.2,
			"ordinary shot %d leaked the raised punish warning_bias" % n)
		_record(_feedback_events.is_empty() and _flash_events == 0,
			"ordinary shot %d leaked punish readability cues" % n)
		shot.call("resolve", "probe_done")
