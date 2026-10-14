extends SceneTree

# tools/test_enemy_pressure_spread.gd
# Headless regression probe for the Current Demo Gap: 'Enemy variety needs more
# readable species identity and pressure spread.'
#
# Contract under test (interface seam ZoneManager.start_combat -> CreatureLocomotionDirector.on_enemy_added):
#   1. SPECIES IDENTITY IS READABLE THROUGH THE LOCOMOTION PROFILE: every species
#      present in data/ enemy definitions must expose a locomotion profile keyed by
#      species_id (not merely a type fallback), so on_enemy_added resolves a real
#      species profile instead of the default.
#   2. PRESSURE SPREAD IS DISTINCT: species must not collapse onto identical
#      pressure. The normalized pressure tuple (orbit_speed_mult, approach_lean,
#      recoil_push, can_flank) must produce a minimum count of distinct tuples and
#      the orbit_speed/approach_lean spread must exceed a floor, so the player can
#      read different species as different pressure across a run.
#
# Runs through project autoloads (EventBus, RunState, etc.) like the other
# tools/test_*.gd probes. Fails before the pressure-spread change; passes after.

# The data/ scripts that author species_id (grep '"species_id"' data/*.gd).
const ENEMY_DEFINITION_SCRIPTS: Array[String] = [
	"res://data/CombatContent.gd", "res://data/RegionSongContent.gd"
]

const SPECIES_LOCOM_REQUIRED_KEYS: Array[String] = [
	"orbit_speed_mult", "approach_lean", "recoil_push", "can_flank"
]

# Minimum readable spread asserted for the demo gap. Pre-change the species
# tuple set collapses (identity/pressure collapsed), so this probe fails.
const MIN_DISTINCT_SPECIES_TUPLES: int = 8
const MIN_ORBIT_SPREAD: float = 0.45
const MIN_APPROACH_SPREAD: float = 0.15

var _failures: Array[String] = []
var _checks: int = 0


func _init() -> void:
	_run()


func _run() -> void:
	print("=== test_enemy_pressure_spread: species identity + pressure spread ===")
	_check_species_profiles_are_readable()
	_check_pressure_spread_is_distinct()
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


func _collect_data_species_ids() -> Array[String]:
	# Enumerate species_id values authored in the data/ enemy definitions.
	# Only the enemy-definition owners: loading every data/ script pulled in
	# DynamicDifficulty.gd / PresentationTextContent.gd, which do not compile from
	# a bare SceneTree, and the harness fails any run whose log has ERROR lines.
	var ids: Array[String] = []
	for path in ENEMY_DEFINITION_SCRIPTS:
		var script: Variant = load(path)
		_record(script is GDScript, "enemy definition script %s did not load" % path)
		if script is GDScript:
			var consts: Dictionary = (script as GDScript).get_script_constant_map()
			for key in consts.keys():
				var value: Variant = consts[key]
				if value is Array:
					for entry in value:
						if entry is Dictionary:
							var sid := String(entry.get("species_id", ""))
							if not sid.is_empty() and not ids.has(sid):
								ids.append(sid)
				elif value is Dictionary:
					for sub in value.values():
						if sub is Dictionary:
							var sid2 := String(sub.get("species_id", ""))
							if not sid2.is_empty() and not ids.has(sid2):
								ids.append(sid2)
	ids.sort()
	return ids


func _check_species_profiles_are_readable() -> void:
	var species_ids := _collect_data_species_ids()
	_record(not species_ids.is_empty(), "no species_id found in data/ enemy definitions")
	for sid in species_ids:
		var profile: Variant = CreatureLocomotionDirector.LOCOM_PROFILES.get(sid, {})
		var ok: bool = (profile is Dictionary) and not (profile as Dictionary).is_empty()
		if ok:
			for k in SPECIES_LOCOM_REQUIRED_KEYS:
				if not (profile as Dictionary).has(k):
					ok = false
		_record(ok, "species '%s' has no readable LOCOM_PROFILE keyed by species_id" % sid)


func _check_pressure_spread_is_distinct() -> void:
	var species_ids := _collect_data_species_ids()
	var tuples: Dictionary = {}
	var orbit_vals: Array[float] = []
	var approach_vals: Array[float] = []
	for sid in species_ids:
		var p: Variant = CreatureLocomotionDirector.LOCOM_PROFILES.get(sid, {})
		if not (p is Dictionary) or (p as Dictionary).is_empty():
			continue
		var pd: Dictionary = p as Dictionary
		var t: String = "%s|%s|%s|%s" % [pd.get("orbit_speed_mult"), pd.get("approach_lean"), pd.get("recoil_push"), pd.get("can_flank")]
		tuples[t] = true
		orbit_vals.append(float(pd.get("orbit_speed_mult", 1.0)))
		approach_vals.append(float(pd.get("approach_lean", 0.82)))
	_record(tuples.size() >= MIN_DISTINCT_SPECIES_TUPLES, "distinct species pressure tuples %d < %d" % [tuples.size(), MIN_DISTINCT_SPECIES_TUPLES])
	if orbit_vals.size() >= 2:
		orbit_vals.sort()
		_record(orbit_vals[orbit_vals.size() - 1] - orbit_vals[0] >= MIN_ORBIT_SPREAD, "orbit_speed_mult spread %.3f < %.3f" % [orbit_vals[orbit_vals.size() - 1] - orbit_vals[0], MIN_ORBIT_SPREAD])
	if approach_vals.size() >= 2:
		approach_vals.sort()
		_record(approach_vals[approach_vals.size() - 1] - approach_vals[0] >= MIN_APPROACH_SPREAD, "approach_lean spread %.3f < %.3f" % [approach_vals[approach_vals.size() - 1] - approach_vals[0], MIN_APPROACH_SPREAD])
