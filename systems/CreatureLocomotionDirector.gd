extends Node
class_name CreatureLocomotionDirector

# Owns per-enemy behavioral state and all orbital movement physics.
# ZoneManager delegates _process() enemy movement here and passes mutable dict refs at init().
#
# Responsibility split:
#   CreatureLocomotionDirector — HOW enemies move (species traits, behavioral states, orbit physics)
#   ZoneManager                — WHERE enemies are stored (position/angle registry, spatial queries)
#
# Orbit center is a weighted blend of arena center and player position so creatures
# have territorial gravity while still hunting the player. The blend is smoothed so
# movement displaces enemies with a short lag rather than an instant snap.

const BASE_ORBIT_SPEED: float = 0.35
const PLAYER_PULL_WEIGHT: float = 0.28
const ORBIT_CENTER_FOLLOW_SPEED: float = 1.5

const APPROACH_TIMEOUT: float = 3.5   # max APPROACH duration if fire never resolves
const RECOIL_DURATION: float = 0.92   # how long a creature pushes back after firing (slightly longer punish window)

const DEFAULT_APPROACH_LEAN: float = 0.82
const DEFAULT_RECOIL_PUSH: float = 0.06

# Species locomotion profiles keyed by species_id (checked first) then type (fallback).
# approach_lean  — target_radius multiplier during APPROACH (< 1.0 = closer to player)
# orbit_speed_mult — multiplier on BASE_ORBIT_SPEED
# recoil_push    — fraction of base_radius pushed outward immediately after firing; fades over RECOIL_DURATION
# can_flank      — true: creature uses FLANK state (high angular speed, directional preference)
static var LOCOM_PROFILES: Dictionary = {
	# by species_id ─────────────────────────────────────────────────────────────────────────────
	"ashclaw":     { "orbit_speed_mult": 1.30, "approach_lean": 0.70, "recoil_push": 0.09, "can_flank": false },
	"veilskin":    { "orbit_speed_mult": 1.50, "approach_lean": 0.80, "recoil_push": 0.07, "can_flank": true  },
	"marrowward":  { "orbit_speed_mult": 0.60, "approach_lean": 0.95, "recoil_push": 0.02, "can_flank": false },
	"knellspine":  { "orbit_speed_mult": 1.10, "approach_lean": 0.78, "recoil_push": 0.06, "can_flank": false },
	"thornback":   { "orbit_speed_mult": 1.25, "approach_lean": 0.68, "recoil_push": 0.12, "can_flank": false },
	"gorefane":    { "orbit_speed_mult": 1.25, "approach_lean": 0.72, "recoil_push": 0.10, "can_flank": false },
	"hushcoil":    { "orbit_speed_mult": 0.90, "approach_lean": 0.85, "recoil_push": 0.05, "can_flank": true  },
	"coldvein":    { "orbit_speed_mult": 1.30, "approach_lean": 0.82, "recoil_push": 0.08, "can_flank": true  },
	"gruvek":      { "orbit_speed_mult": 0.90, "approach_lean": 0.77, "recoil_push": 0.08, "can_flank": false },
	"bond_remnant":{ "orbit_speed_mult": 1.00, "approach_lean": 0.78, "recoil_push": 0.06, "can_flank": false },
	"siltgrip":    { "orbit_speed_mult": 1.10, "approach_lean": 0.75, "recoil_push": 0.07, "can_flank": false },
	# by type (fallback) ─────────────────────────────────────────────────────────────────────────
	"dreg":        { "orbit_speed_mult": 1.00, "approach_lean": 0.82, "recoil_push": 0.06, "can_flank": false },
	"bond_reaper": { "orbit_speed_mult": 1.40, "approach_lean": 0.75, "recoil_push": 0.10, "can_flank": false },
	"sovereign":   { "orbit_speed_mult": 0.80, "approach_lean": 0.90, "recoil_push": 0.04, "can_flank": false },
}

var _zone_manager: Node = null
var _orbit_center: Vector2 = Vector2.ZERO

# Shared mutable references from ZoneManager — writes here are immediately reflected there.
var _enemies: Dictionary = {}
var _enemy_positions: Dictionary = {}
var _orbit_angles: Dictionary = {}
var _orbit_radius_offsets: Dictionary = {}
var _strikers: Dictionary = {}

# Director-owned per-enemy locomotion state.
var _locom_states: Dictionary = {}     # id(int) -> StringName  (&"stalk" | &"approach" | &"recoil" | &"flank")
var _locom_timers: Dictionary = {}     # id(int) -> float  (seconds remaining for timed states)
var _flank_directions: Dictionary = {} # id(int) -> float  (+1.0 CW / -1.0 CCW angular preference)
var _orbit_drift_accum: Dictionary = {} # id(int) -> float  (sinusoidal radius breath accumulator)


func init(
		zone_manager: Node,
		enemies: Dictionary,
		positions: Dictionary,
		angles: Dictionary,
		offsets: Dictionary,
		strikers: Dictionary
) -> void:
	_zone_manager = zone_manager
	_enemies = enemies
	_enemy_positions = positions
	_orbit_angles = angles
	_orbit_radius_offsets = offsets
	_strikers = strikers
	_orbit_center = zone_manager.get_arena_center()


# ── Public lifecycle hooks ────────────────────────────────────────────────────

func on_enemy_added(id: int) -> void:
	var profile: Dictionary = _get_profile(id)
	if bool(profile.get("can_flank", false)):
		_locom_states[id] = &"flank"
		_flank_directions[id] = 1.0 if id % 2 == 0 else -1.0
	else:
		_locom_states[id] = &"stalk"


func on_enemy_removed(id: int) -> void:
	_locom_states.erase(id)
	_locom_timers.erase(id)
	_flank_directions.erase(id)
	_orbit_drift_accum.erase(id)


func on_enemy_approaching(id: int) -> void:
	# Called by ZoneManager just before execute_fire() for each selected striker.
	# Flankers keep their own movement pattern — fire happens from whatever angle they hold.
	var profile: Dictionary = _get_profile(id)
	if bool(profile.get("can_flank", false)):
		return
	_locom_states[id] = &"approach"
	_locom_timers[id] = APPROACH_TIMEOUT


func on_enemy_fired(id: int) -> void:
	# Called by ZoneManager after a successful projectile spawn — creature recoils.
	_locom_states[id] = &"recoil"
	_locom_timers[id] = RECOIL_DURATION


func clear() -> void:
	_locom_states.clear()
	_locom_timers.clear()
	_flank_directions.clear()
	_orbit_drift_accum.clear()


# ── Per-frame tick ────────────────────────────────────────────────────────────

func tick(delta: float) -> void:
	_update_orbit_center(delta)
	_step_all_enemies(delta)
	_tick_state_timers(delta)


func _update_orbit_center(delta: float) -> void:
	var arena_center: Vector2 = _zone_manager.get_arena_center()
	var player_pos: Vector2 = _zone_manager.get_player_pos()
	var weighted: Vector2 = arena_center.lerp(player_pos, PLAYER_PULL_WEIGHT)
	_orbit_center = _orbit_center.lerp(weighted, delta * ORBIT_CENTER_FOLLOW_SPEED)


func _step_all_enemies(delta: float) -> void:
	var base_radius: float = _zone_manager.get_spawn_distance()

	for id: int in _enemies.keys():
		if not _enemy_positions.has(id):
			continue

		var pos: Vector2 = _enemy_positions[id]
		var to_center: Vector2 = _orbit_center - pos
		var dist: float = to_center.length()
		if dist < 1.0:
			continue

		var dir: Vector2 = to_center / dist
		var state: StringName = StringName(_locom_states.get(id, &"stalk"))
		var profile: Dictionary = _get_profile(id)

		# Base radius with per-enemy jitter and sinusoidal breath.
		var drift_accum: float = float(_orbit_drift_accum.get(id, 0.0)) + delta * 0.4
		_orbit_drift_accum[id] = drift_accum
		var target_radius: float = (
			base_radius
			+ float(_orbit_radius_offsets.get(id, 0.0))
			+ sin(drift_accum) * 12.0
		)

		var orbit_speed_mult: float = float(profile.get("orbit_speed_mult", 1.0))

		match state:
			&"approach":
				target_radius *= float(profile.get("approach_lean", DEFAULT_APPROACH_LEAN))
				orbit_speed_mult *= 1.3
			&"recoil":
				var recoil_push: float = float(profile.get("recoil_push", DEFAULT_RECOIL_PUSH))
				var recoil_t: float = float(_locom_timers.get(id, 0.0)) / RECOIL_DURATION
				target_radius += base_radius * recoil_push * recoil_t
			_:
				pass

		# Radial correction (arrival steering toward target_radius).
		var radial_vel: float = (dist - target_radius) * 2.5

		# Angular velocity — orbital circulation.
		var tangent: Vector2 = Vector2(-dir.y, dir.x)
		var angular_speed: float = BASE_ORBIT_SPEED * orbit_speed_mult * target_radius

		if state == &"flank":
			# Flankers move faster with a species-specific directional lean,
			# creating a circling-behind pressure without needing player facing data.
			var flank_dir: float = float(_flank_directions.get(id, 1.0))
			angular_speed = BASE_ORBIT_SPEED * float(profile.get("orbit_speed_mult", 1.0)) * 1.8 * flank_dir * target_radius

		_enemy_positions[id] = pos + (dir * radial_vel + tangent * angular_speed) * delta

		# Sync angle for signal/lane compatibility (angle relative to orbit center, not player).
		var angle: float = (pos - _orbit_center).angle()
		_orbit_angles[id] = angle
		if _strikers.has(id):
			_strikers[id]["angle"] = angle


func _tick_state_timers(delta: float) -> void:
	var expired: Array[int] = []
	for id: int in _locom_timers.keys():
		_locom_timers[id] = maxf(float(_locom_timers[id]) - delta, 0.0)
		if float(_locom_timers[id]) <= 0.0:
			expired.append(id)
	for id: int in expired:
		_locom_timers.erase(id)
		if _locom_states.has(id):
			var profile: Dictionary = _get_profile(id)
			_locom_states[id] = &"flank" if bool(profile.get("can_flank", false)) else &"stalk"


func _get_profile(id: int) -> Dictionary:
	var enemy: Dictionary = _enemies.get(id, {})
	var species_id: String = String(enemy.get("species_id", ""))
	if not species_id.is_empty() and LOCOM_PROFILES.has(species_id):
		return LOCOM_PROFILES[species_id]
	var type_key: String = String(enemy.get("type", "dreg"))
	return Dictionary(LOCOM_PROFILES.get(type_key, {}))
