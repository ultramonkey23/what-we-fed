class_name EnemyStriker
extends RefCounted

## Owns attack-execution logic for one enemy in the ZoneManager.
## ZoneManager decides WHEN and WHO fires; this class owns HOW:
## damage scaling, speed scaling, Bloodscent, and telegraph profile.

const PALE_DAMAGE_MULT: float = 0.50

# ── Silence Punish (Glintstalker species identity) ────────────────────────────
# Canon: "It counts the silence between your pulses. When the gap widens, it
# stops being a shadow." The Glintstalker reads the PLAYER's attack cadence:
# while the player keeps a pulse, it fires ordinary precision shots. When the
# silence between player attacks widens past GLINT_SILENCE_GAP, its next shot
# becomes a Glint Shot — faster, heavier, and warned with a brighter glint
# telegraph. One punish per silence gap; a fresh player attack restarts the
# count. Reactive encounter dynamics, distinct from its locomotion profile.
const GLINT_STALKER_SPECIES: String = "pale_shelf_precision_stalker"
const GLINT_SILENCE_GAP: float = 4.0
const GLINT_DAMAGE_MULT: float = 1.35
const GLINT_SPEED_MULT: float = 1.25
const GLINT_PROJECTILE_COLOR: Color = Color(0.70, 0.93, 1.0, 1.0)
const GLINT_ACCENT_COLOR: Color = Color(0.84, 0.97, 1.0, 1.0)
const GLINT_GLOW_ALPHA: float = 0.22

# ── Panic Close (Shardhulk species identity) ─────────────────────────────────
# Canon: "A plated weight that expects you to panic. It closes the lane with
# the cold patience of a glacier." / "Its plates click once before it fires.
# The click is the only warning." The Shardhulk reads the PLAYER's attack
# cadence for panic: a burst of rapid pulses (>= SHARD_PANIC_BURST attacks,
# each within SHARD_PANIC_GAP of the last) is the panic it expects. Its next
# shot becomes a Lane Close — heavier and glacially slow (it closes the lane
# instead of chasing a timing window), telegraphed by a raised plate-click
# warning. One close per panic episode; a pulse after a calm gap starts a
# fresh count and only a new burst re-arms the close. Distinct from the
# Glintstalker's silence punish: opposite trigger (panic vs silence) and
# opposite speed response (slower vs faster).
const SHARDHULK_SPECIES: String = "pale_shelf_shardshroud_sentinel"
const SHARD_PANIC_BURST: int = 3
const SHARD_PANIC_GAP: float = 1.0
const SHARD_CLOSE_DAMAGE_MULT: float = 1.5
const SHARD_CLOSE_SPEED_MULT: float = 0.72
const SHARD_CLOSE_PROJECTILE_COLOR: Color = Color(0.72, 0.84, 0.78, 1.0)
const SHARD_CLOSE_ACCENT_COLOR: Color = Color(0.86, 0.94, 0.88, 1.0)
const SHARD_CLOSE_GLOW_ALPHA: float = 0.26

# ── Downbeat (Metrist species identity) ─────────────────────────────────────
# Canon [P]: "It keeps the beat you never meant to teach it." The Metrist
# reads the PLAYER's attack cadence for RHYTHMIC REGULARITY — a low-jitter
# groove is the comfort it punishes (silence and bursts are irrelevant as
# triggers). Its response is TIMING DISPLACEMENT only: while locked, the
# signature strike "the Downbeat" lands one offbeat past the player's pulse
# (inside the rhythm's own safe gap); when the player breaks pattern, the
# strike slips ONTO the nearest reachable player pulse slot (readable trade +
# parry window). Damage and projectile speed are never touched — the
# SovereignDamageCalculator stays damage authority and the flight speed is
# fixed. The rhythm lock, slot math and Ghost Pulse telegraph live in
# systems/MetristDirector.gd (this class only bridges the shared cadence
# clock and the fire path, per the species-framework pattern).
const METRIST_SPECIES: String = "pale_shelf_offbeat_lector"

# Shared combat-cadence clock (all strikers read the same player pulse).
static var _last_player_attack_msec: int = -1
static var _glint_punish_spent: bool = false
static var _panic_burst_count: int = 0
static var _shard_close_spent: bool = false

var enemy: Dictionary = {}
var projectile_scene: PackedScene = null
var species_id: String = ""


static func mark_combat_start() -> void:
	# Silence counts from combat start until the player's first pulse.
	_last_player_attack_msec = Time.get_ticks_msec()
	_glint_punish_spent = false
	_panic_burst_count = 0
	_shard_close_spent = false
	MetristDirector.mark_combat_start()


static func note_player_attack(at_msec: int = -1, shot_heading: Vector2 = Vector2.ZERO) -> void:
	# Called on EventBus.player_attacked. A player pulse resets the silence
	# count and re-arms the punish for the next widened gap. The -1 sentinel
	# means "now"; any other value is a literal timestamp (probes backdate into
	# negative engine-uptime values, so only -1 is special). The same pulse
	# feeds the Metrist rhythm engine (shot_heading feeds its Ghost Pulse).
	var at: int = Time.get_ticks_msec() if at_msec == -1 else at_msec
	MetristDirector.note_player_attack(at, shot_heading)
	# Panic bookkeeping: pulses inside SHARD_PANIC_GAP accumulate a burst; a
	# calm-spaced pulse starts a fresh count. Crossing the burst threshold is
	# a new panic episode and re-arms the close — further spam inside the same
	# episode does not re-arm it.
	if _last_player_attack_msec == -1:
		_panic_burst_count = 1
	else:
		var gap: float = maxf(float(at - _last_player_attack_msec) / 1000.0, 0.0)
		if gap >= SHARD_PANIC_GAP:
			_panic_burst_count = 1
		else:
			_panic_burst_count += 1
			if _panic_burst_count == SHARD_PANIC_BURST:
				_shard_close_spent = false
	_last_player_attack_msec = at
	_glint_punish_spent = false


static func silence_gap() -> float:
	if _last_player_attack_msec == -1:
		return 0.0
	return maxf(float(Time.get_ticks_msec() - _last_player_attack_msec) / 1000.0, 0.0)


static func panic_burst_count() -> int:
	return _panic_burst_count


func setup(p_enemy: Dictionary, p_scene: PackedScene) -> void:
	enemy = p_enemy
	projectile_scene = p_scene
	species_id = String(enemy.get("species_id", ""))


func is_melee() -> bool:
	var tags: Variant = enemy.get("behaviour_tags", [])
	return tags is Array and (tags as Array).has("melee")


func is_glint_stalker() -> bool:
	return species_id == GLINT_STALKER_SPECIES


func glint_punish_armed() -> bool:
	return is_glint_stalker() and not _glint_punish_spent and silence_gap() >= GLINT_SILENCE_GAP


func consume_glint_punish() -> bool:
	# One Glint Shot per silence gap. Called only when a shot actually spawns,
	# so failed scheduling attempts never burn the punish.
	if not glint_punish_armed():
		return false
	_glint_punish_spent = true
	return true


func is_shardhulk() -> bool:
	return species_id == SHARDHULK_SPECIES


func shard_panic_armed() -> bool:
	return is_shardhulk() and not _shard_close_spent and _panic_burst_count >= SHARD_PANIC_BURST


func consume_shard_panic_close() -> bool:
	# One Lane Close per panic episode. Called only when a shot actually
	# spawns, so failed scheduling attempts never burn the close.
	if not shard_panic_armed():
		return false
	_shard_close_spent = true
	return true


func is_metrist() -> bool:
	return species_id == METRIST_SPECIES


func metrist_downbeat_armed() -> bool:
	# Armed AND locked: the Downbeat fires only out of an active rhythm lock.
	return is_metrist() and MetristDirector.downbeat_armed()


func consume_metrist_downbeat() -> bool:
	# One Downbeat per lock. Called only when the shot is guaranteed to spawn,
	# so failed scheduling attempts never burn the Downbeat.
	if not metrist_downbeat_armed():
		return false
	return MetristDirector.consume_downbeat()


func compute_projectile_damage(punish_mult: float, pale_active: bool, glint_active: bool = false, shard_active: bool = false) -> float:
	var dmg: float = float(enemy.get("damage", 8.0)) * punish_mult
	if species_id == "ashclaw":
		var bleed: int = PlayerState.bleed_stacks
		if bleed > 0:
			dmg *= 1.0 + 0.10 * float(bleed)
	if pale_active:
		dmg *= PALE_DAMAGE_MULT
	if glint_active:
		dmg *= GLINT_DAMAGE_MULT
	if shard_active:
		dmg *= SHARD_CLOSE_DAMAGE_MULT
	return dmg


func compute_projectile_speed(base_speed: float, glint_active: bool = false, shard_active: bool = false) -> float:
	var speed: float = base_speed
	if species_id == "ashclaw":
		var bleed: int = PlayerState.bleed_stacks
		if bleed > 0:
			speed = base_speed * (1.0 + 0.15 * float(bleed))
	if glint_active:
		speed *= GLINT_SPEED_MULT
	if shard_active:
		speed *= SHARD_CLOSE_SPEED_MULT
	return speed


func compute_melee_damage(punish_mult: float) -> float:
	var dmg: float = float(enemy.get("damage", 14.0)) * punish_mult
	if species_id == "ashclaw":
		var bleed: int = PlayerState.bleed_stacks
		if bleed > 0:
			dmg *= 1.0 + 0.10 * float(bleed)
	return dmg


func compute_approach_speed() -> float:
	var speed: float = float(enemy.get("approach_speed", 80.0))
	if species_id == "ashclaw":
		var bleed: int = PlayerState.bleed_stacks
		if bleed > 0:
			speed *= 1.0 + 0.15 * float(bleed)
	return speed


func build_telegraph_profile(section_id: String, glint_active: bool = false, shard_active: bool = false, metrist_active: bool = false) -> Dictionary:
	var profile: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
	profile["projectile_body_path"] = COMBAT_CONTENT.get_projectile_body_resource_path(enemy)
	var section_mod: String = COMBAT_CONTENT.get_shot_modifier_for_section(section_id)
	var species_mod: String = String(profile.get("species_shot_modifier", "")).strip_edges()
	if not species_mod.is_empty():
		profile["shot_modifier"] = species_mod
	else:
		profile["shot_modifier"] = section_mod
	profile.erase("species_shot_modifier")
	if glint_active:
		# Glint Shot identity: brighter pale-cyan needle with a stronger warning
		# pulse (warning_bias feeds the live lane warning in CombatScene) so the
		# punished shot reads as distinct pressure before impact.
		profile["glint_punish"] = true
		profile["projectile_color"] = GLINT_PROJECTILE_COLOR
		profile["accent_color"] = GLINT_ACCENT_COLOR
		profile["glow_alpha"] = GLINT_GLOW_ALPHA
		profile["warning_bias"] = float(profile.get("warning_bias", 1.0)) + 0.35
	if shard_active:
		# Lane Close identity: a heavy glacial slab with the plate-click
		# warning raised ("The click is the only warning"), so the closing
		# shot reads as distinct pressure before impact.
		profile["shard_panic_close"] = true
		profile["projectile_color"] = SHARD_CLOSE_PROJECTILE_COLOR
		profile["accent_color"] = SHARD_CLOSE_ACCENT_COLOR
		profile["glow_alpha"] = SHARD_CLOSE_GLOW_ALPHA
		profile["warning_bias"] = float(profile.get("warning_bias", 1.0)) + 0.45
	if metrist_active:
		# Downbeat identity: timing displacement only — no damage or speed
		# keys are touched (SovereignDamageCalculator and the base speed path
		# stay authoritative). The raised warning bias is the same readability
		# channel the other species use; the Ghost Pulse echo is the signature
		# telegraph and rides alongside this flag.
		profile["metrist_downbeat"] = true
		profile["warning_bias"] = float(profile.get("warning_bias", 1.0)) + 0.30
	return profile
