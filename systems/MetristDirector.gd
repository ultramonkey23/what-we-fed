class_name MetristDirector
extends RefCounted

## Metrist (pale_shelf_offbeat_lector) rhythm engine — the "Downbeat" species
## identity. Canon [P]: "It keeps the beat you never meant to teach it."
##
## Design source: docs/ai/evolution_proposals/2026-11-23_metrist_alternative_third_species.md
##
## 1. TRIGGER — rhythmic regularity, measured as jitter over recent inter-pulse
##    intervals. The trigger is comfort (a groove you stop thinking about).
##    Silence and bursts are irrelevant as triggers: only regularity matters,
##    at any tempo. High jitter / deliberate rubato breaks the lock.
## 2. RESPONSE — TIMING DISPLACEMENT only, never speed scaling (orbit speed and
##    projectile speed are never touched; SovereignDamageCalculator stays the
##    damage authority). While locked, the signature strike "the Downbeat"
##    lands one OFFBEAT past the player's pulse — inside the rhythm's own
##    "safe" gap. When the player breaks pattern, the strike slips ONTO the
##    nearest reachable player pulse slot (readable trade + parry window).
## 3. TELEGRAPH — "the Ghost Pulse": a pale after-image of the player's own
##    most recent shot ignites in the empty slot between two beats, one beat
##    early. Readable rule: "the echo fires in the gap, not on the beat."
##
## All slot math here is pure functions of tracked pulse timestamps — the
## probe suite asserts it deterministically. The engine owns no visuals and
## reads no autoloads (safe to reference from EnemyStriker at compile time).

const SPECIES_ID: StringName = &"pale_shelf_offbeat_lector"

# ── Rhythm lock tuning ───────────────────────────────────────────────────────
# Jitter = normalized mean absolute deviation of the inter-pulse window.
const RHYTHM_WINDOW: int = 6
const MIN_INTERVALS_TO_LOCK: int = 4
const LOCK_JITTER_MAX: float = 0.12
const MIN_INTERVAL_MSEC: float = 120.0

# ── Plan keys (StringName per Typed Instruction Mandate) ────────────────────
const KEY_INTERVAL_MSEC: StringName = &"interval_msec"
const KEY_ANCHOR_MSEC: StringName = &"anchor_msec"
const KEY_NATURAL_ARRIVAL_MSEC: StringName = &"natural_arrival_msec"
const KEY_PULSE_SLOT_MSEC: StringName = &"pulse_slot_msec"
const KEY_LANDING_MSEC: StringName = &"landing_msec"
const KEY_GHOST_IGNITE_MSEC: StringName = &"ghost_ignite_msec"
const KEY_HOLD_MSEC: StringName = &"hold_msec"
const KEY_SLOT: StringName = &"slot"
const KEY_SLIPPED: StringName = &"slipped"

const SLOT_OFFBEAT: StringName = &"offbeat"
const SLOT_PULSE: StringName = &"pulse"

# ── Shared rhythm state (one player, one groove) ────────────────────────────
static var _intervals_msec: Array[int] = []
static var _last_pulse_msec: int = -1 # -1 = never pulsed (EnemyStriker sentinel convention)
static var _locked: bool = false
static var _downbeat_spent: bool = false
static var _last_shot_heading: Vector2 = Vector2.RIGHT
static var _active_plan: Dictionary = {}
static var _active_projectile: WeakRef = WeakRef.new()
static var _active_ghost: WeakRef = WeakRef.new()


static func mark_combat_start() -> void:
	# Silence is irrelevant to the Metrist: no pulse, no interval, no lock.
	_intervals_msec.clear()
	_last_pulse_msec = -1
	_locked = false
	_downbeat_spent = false
	_active_plan = {}
	_active_projectile = WeakRef.new()
	_active_ghost = WeakRef.new()


static func note_player_attack(at_msec: int = -1, shot_heading: Vector2 = Vector2.ZERO) -> void:
	# One player pulse on the shared cadence clock. The -1 sentinel means
	# "now"; any other value is a literal timestamp (probes backdate into
	# negative engine-uptime values, so only -1 is special).
	var at: int = Time.get_ticks_msec() if at_msec == -1 else at_msec
	if shot_heading != Vector2.ZERO:
		_last_shot_heading = shot_heading
	if _last_pulse_msec != -1:
		var interval: int = maxi(at - _last_pulse_msec, 0)
		_intervals_msec.append(interval)
		if _intervals_msec.size() > RHYTHM_WINDOW:
			_intervals_msec.pop_front()
	_last_pulse_msec = at
	_refresh_lock(Time.get_ticks_msec())


static func note_player_shot(heading: Vector2) -> void:
	# The Ghost Pulse is an after-image of the player's own most recent shot.
	if heading != Vector2.ZERO:
		_last_shot_heading = heading


static func last_shot_heading() -> Vector2:
	return _last_shot_heading


static func mean_interval_msec() -> float:
	if _intervals_msec.is_empty():
		return 0.0
	var total: float = 0.0
	for interval in _intervals_msec:
		total += float(interval)
	return total / float(_intervals_msec.size())


static func jitter() -> float:
	# Normalized mean absolute deviation of the recent inter-pulse window.
	# 0.0 = a perfect machine groove; >= LOCK_JITTER_MAX breaks the lock.
	# Without at least two intervals there is no rhythm to read (report worst).
	if _intervals_msec.size() < 2:
		return 1.0
	var mean: float = mean_interval_msec()
	if mean <= 0.0:
		return 1.0
	var deviation: float = 0.0
	for interval in _intervals_msec:
		deviation += absf(float(interval) - mean)
	return deviation / float(_intervals_msec.size()) / mean


static func is_locked() -> bool:
	return _locked


static func downbeat_armed() -> bool:
	# One Downbeat per lock: armed while the lock holds and the lock has not
	# spent its strike yet. A fresh lock (unlocked -> locked) re-arms it.
	return _locked and not _downbeat_spent


static func consume_downbeat() -> bool:
	# Consumed only when the strike is guaranteed to spawn (ZoneManager calls
	# at the same guarantee point as the Glint/Close consumption), so failed
	# scheduling attempts never burn the Downbeat.
	if not downbeat_armed():
		return false
	_downbeat_spent = true
	return true


static func active_plan() -> Dictionary:
	return _active_plan.duplicate(true)


static func active_projectile() -> Node:
	var ref: Variant = _active_projectile.get_ref()
	if ref is Node and is_instance_valid(ref):
		return ref
	return null


static func active_ghost() -> Node:
	var ref: Variant = _active_ghost.get_ref()
	if ref is Node and is_instance_valid(ref):
		return ref
	return null


# ── Slot math (pure, deterministic) ─────────────────────────────────────────

static func plan_downbeat(now_msec: int, travel_time_msec: int) -> Dictionary:
	# The Downbeat aims at the empty slot one offbeat PAST the player's next
	# predicted pulse: landing = pulse_slot + half interval. The pulse grid is
	# anchored on the last real pulse and spaced by the mean inter-pulse
	# interval. The strike physically cannot land before now + travel, so the
	# pulse slot used is the first one strictly after natural arrival.
	if _last_pulse_msec == -1 or _intervals_msec.is_empty():
		return {}
	var interval: float = mean_interval_msec()
	if interval < MIN_INTERVAL_MSEC:
		return {}
	var anchor: float = float(_last_pulse_msec)
	var natural_arrival: float = float(now_msec) + float(travel_time_msec)
	var pulse_slot: float = _first_slot_at_or_after(anchor, interval, natural_arrival)
	var landing: float = pulse_slot + interval * 0.5
	return {
		KEY_INTERVAL_MSEC: interval,
		KEY_ANCHOR_MSEC: anchor,
		KEY_NATURAL_ARRIVAL_MSEC: natural_arrival,
		KEY_PULSE_SLOT_MSEC: pulse_slot,
		KEY_LANDING_MSEC: landing,
		KEY_GHOST_IGNITE_MSEC: landing - interval,
		KEY_HOLD_MSEC: landing - natural_arrival,
		KEY_SLOT: SLOT_OFFBEAT,
		KEY_SLIPPED: false
	}


static func slip_plan(plan: Dictionary, now_msec: int, remaining_flight_msec: float) -> Dictionary:
	# Pattern-break slip: the strike re-anchors ONTO the nearest player pulse
	# slot it can physically reach (never speed-scaled: remaining flight time
	# is fixed, only the launch-phase displacement changes). The Ghost Pulse
	# snaps into the gap slot immediately before the slipped landing — the
	# echo always fires in the gap, never on the beat.
	var slipped: Dictionary = plan.duplicate(true)
	if plan.is_empty():
		return slipped
	var interval: float = float(plan[KEY_INTERVAL_MSEC])
	if interval <= 0.0:
		return slipped
	var anchor: float = float(plan[KEY_ANCHOR_MSEC])
	var earliest: float = float(now_msec) + maxf(remaining_flight_msec, 0.0)
	var landing: float = _first_slot_at_or_after(anchor, interval, earliest)
	slipped[KEY_PULSE_SLOT_MSEC] = landing
	slipped[KEY_LANDING_MSEC] = landing
	slipped[KEY_GHOST_IGNITE_MSEC] = landing - interval * 0.5
	slipped[KEY_HOLD_MSEC] = maxf(landing - earliest, 0.0)
	slipped[KEY_SLOT] = SLOT_PULSE
	slipped[KEY_SLIPPED] = true
	return slipped


static func _first_slot_at_or_after(anchor: float, interval: float, threshold: float) -> float:
	# Smallest pulse-grid slot (anchor + n * interval) at or after threshold.
	if interval <= 0.0:
		return threshold
	var n: float = ceil((threshold - anchor) / interval)
	var slot: float = anchor + n * interval
	if slot < threshold:
		slot += interval
	return slot


# ── In-flight bookkeeping ───────────────────────────────────────────────────

static func register_downbeat(projectile: Node, plan: Dictionary) -> void:
	_active_projectile = weakref(projectile)
	_active_plan = plan.duplicate(true)


static func register_ghost(ghost: Node) -> void:
	_active_ghost = weakref(ghost)


static func _refresh_lock(now_msec: int) -> void:
	var was_locked: bool = _locked
	var regular: bool = _intervals_msec.size() >= MIN_INTERVALS_TO_LOCK \
		and mean_interval_msec() >= MIN_INTERVAL_MSEC \
		and jitter() <= LOCK_JITTER_MAX
	_locked = regular
	if _locked and not was_locked:
		# A fresh lock arms its one Downbeat.
		_downbeat_spent = false
	if was_locked and not _locked:
		_on_pattern_break(now_msec)


static func _on_pattern_break(now_msec: int) -> void:
	# The strike slips ONTO the player's pulse slot. The slip is available as
	# long as the strike is still in flight.
	var projectile: Node = active_projectile()
	if projectile == null or _active_plan.is_empty():
		return
	if not _active_plan.has(KEY_NATURAL_ARRIVAL_MSEC):
		return
	var flight_remaining: float = 0.0
	if projectile.has_method("time_until_hit_zone") and projectile.has_method("timing_displacement_remaining"):
		flight_remaining = maxf(
			float(projectile.call("time_until_hit_zone"))
			- float(projectile.call("timing_displacement_remaining")),
			0.0
		)
	var updated: Dictionary = slip_plan(_active_plan, now_msec, flight_remaining)
	_active_plan = updated
	if projectile.has_method("set_timing_displacement"):
		projectile.call("set_timing_displacement", float(updated[KEY_HOLD_MSEC]) / 1000.0)
	var ghost: Node = active_ghost()
	if ghost != null and ghost.has_method("reschedule"):
		ghost.call(
			"reschedule",
			maxf(float(updated[KEY_GHOST_IGNITE_MSEC]) - float(now_msec), 0.0) / 1000.0,
			float(updated[KEY_GHOST_IGNITE_MSEC])
		)
