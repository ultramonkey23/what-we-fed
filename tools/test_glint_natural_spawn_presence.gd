extends SceneTree

# tools/test_glint_natural_spawn_presence.gd
# Deterministic measurement probe for the gen-1 UNKNOWN: how often do natural
# (non-harness) encounters field Glintstalkers? It reads the authored spawn
# weights in data/RegionSongContent.gd (the live enemy_pool tables every
# natural encounter draws from), computes the Glintstalker's weight share per
# phase pool, and confirms the shares with a seeded Monte Carlo through the
# codebase's weighted picker (EncounterIdentityRuntime.pick_weighted_enemy —
# the same weight/total algorithm the production picker
# EncounterEscalationDirector._roll_weighted_entry uses at its base).
#
# Measured facts print as SPAWN_WEIGHT_FACT / SPAWN_MONTE_CARLO lines for the
# receipt. Assertions fail if the data stops fielding Glintstalkers or
# Shardhulk naturally, if a pool entry loses its weight, or if the measured
# Monte Carlo share drifts away from the authored share.
#
# Note on production pickers (recorded so the numbers are read correctly):
#   - EncounterEscalationDirector._pick_pressure_aware_enemy (live natural
#     spawns) rolls the authored `weight` values with grade/pressure
#     multipliers; the authored share below is the unmodulated base.
#   - CombatScene._rehydrate_song_pressure_after_reward (reward-flow only)
#     picks uniformly; its per-pick probability is printed as uniform_pick.
#   - EncounterIdentityRuntime.pick_weighted_enemy is the pure weighted
#     owner used for the Monte Carlo here.

const REGION_SONG_PATH: String = "res://data/RegionSongContent.gd"
const IDENTITY_RUNTIME_PATH: String = "res://systems/EncounterIdentityRuntime.gd"
const GLINT_SPECIES_ID: String = "pale_shelf_precision_stalker"
const SHARD_SPECIES_ID: String = "pale_shelf_shardshroud_sentinel"
const MONTE_CARLO_ROLLS: int = 2000
const MONTE_CARLO_TOLERANCE: float = 0.06
const MONTE_CARLO_SEED: int = 20261123

var _failures: Array[String] = []
var _checks: int = 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	print("=== test_glint_natural_spawn_presence: natural Glintstalker spawn weight ===")
	var region_song: Variant = load(REGION_SONG_PATH)
	_record(region_song is GDScript, "RegionSongContent script did not load")
	if not (region_song is GDScript):
		_finish()
		return
	var constants: Dictionary = (region_song as GDScript).get_script_constant_map()
	var pools_by_region: Variant = constants.get("SONG_PHASES_BY_REGION", {})
	_record(pools_by_region is Dictionary and not (pools_by_region as Dictionary).is_empty(),
		"SONG_PHASES_BY_REGION missing from RegionSongContent")
	if not (pools_by_region is Dictionary):
		_finish()
		return

	var identity_runtime: Variant = load(IDENTITY_RUNTIME_PATH)
	_record(identity_runtime is GDScript, "EncounterIdentityRuntime script did not load")

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = MONTE_CARLO_SEED

	var total_phases: int = 0
	var phases_with_glint: int = 0
	var phases_with_shard: int = 0
	var glint_weight_sum: float = 0.0
	var pool_weight_sum: float = 0.0

	var region_ids: Array = (pools_by_region as Dictionary).keys()
	region_ids.sort()
	for region_id in region_ids:
		var phases: Array = Array((pools_by_region as Dictionary)[region_id])
		var region_phases: int = 0
		var region_glint_phases: int = 0
		for phase_idx in range(phases.size()):
			var phase: Dictionary = Dictionary(phases[phase_idx])
			var pool: Array = Array(phase.get("enemy_pool", []))
			if pool.is_empty():
				continue
			region_phases += 1
			total_phases += 1
			var pool_weight: float = 0.0
			var glint_weight: float = 0.0
			var shard_weight: float = 0.0
			for entry in pool:
				var e: Dictionary = Dictionary(entry)
				var w: float = float(e.get("weight", 0.0))
				_record(w > 0.0, "pool entry without positive weight: %s/%s %s" % [
					str(region_id), String(phase.get("id", "?")), String(e.get("species_id", "?"))])
				pool_weight += w
				if String(e.get("species_id", "")) == GLINT_SPECIES_ID:
					glint_weight += w
				if String(e.get("species_id", "")) == SHARD_SPECIES_ID:
					shard_weight += w
			_record(pool_weight > 0.0, "pool with zero total weight: %s/%s" % [str(region_id), String(phase.get("id", "?"))])
			glint_weight_sum += glint_weight
			pool_weight_sum += pool_weight
			if glint_weight > 0.0:
				region_glint_phases += 1
				phases_with_glint += 1
			if shard_weight > 0.0:
				phases_with_shard += 1
			var share: float = glint_weight / pool_weight if pool_weight > 0.0 else 0.0
			print("SPAWN_WEIGHT_FACT region=%s phase=%s pool_size=%d glint_weight=%.2f pool_weight_total=%.2f glint_share=%.2f%% uniform_pick=%.2f%% shard_weight=%.2f" % [
				str(region_id),
				String(phase.get("id", phase_idx)),
				pool.size(),
				glint_weight,
				pool_weight,
				share * 100.0,
				(1.0 / float(pool.size())) * 100.0 if glint_weight > 0.0 else 0.0,
				shard_weight
			])
			if glint_weight > 0.0 and identity_runtime is GDScript:
				_monte_carlo(identity_runtime, phase, share, rng)
		print("SPAWN_WEIGHT_FACT region=%s phases_with_glint=%d/%d" % [str(region_id), region_glint_phases, region_phases])

	print("SPAWN_WEIGHT_FACT total phases_with_glint=%d/%d glint_weight_share_all_pools=%.2f%%" % [
		phases_with_glint, total_phases,
		(glint_weight_sum / pool_weight_sum * 100.0) if pool_weight_sum > 0.0 else 0.0
	])
	print("SPAWN_WEIGHT_FACT total phases_with_shard=%d/%d" % [phases_with_shard, total_phases])

	_record(phases_with_glint > 0, "no authored natural pool fields Glintstalkers")
	_record(phases_with_shard > 0, "no authored natural pool fields Shardhulk")
	_finish()


func _monte_carlo(identity_runtime: GDScript, phase: Dictionary, analytic_share: float, rng: RandomNumberGenerator) -> void:
	# Seeded rolls through the production weighted-pick owner must reproduce
	# the authored weight share.
	var glint_picks: int = 0
	for _i in range(MONTE_CARLO_ROLLS):
		var picked: Dictionary = Dictionary(identity_runtime.call("pick_weighted_enemy", phase, rng))
		if String(picked.get("species_id", "")) == GLINT_SPECIES_ID:
			glint_picks += 1
	var measured: float = float(glint_picks) / float(MONTE_CARLO_ROLLS)
	print("SPAWN_MONTE_CARLO phase=%s rolls=%d glint_picks=%d measured=%.2f%% analytic=%.2f%%" % [
		String(phase.get("id", "?")), MONTE_CARLO_ROLLS, glint_picks, measured * 100.0, analytic_share * 100.0
	])
	_record(absf(measured - analytic_share) <= MONTE_CARLO_TOLERANCE,
		"measured spawn share %.2f%% drifted from authored %.2f%% in phase %s" % [
			measured * 100.0, analytic_share * 100.0, String(phase.get("id", "?"))])


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)


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
