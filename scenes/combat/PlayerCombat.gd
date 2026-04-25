extends Node2D

@onready var sprite: ColorRect = $Sprite
const COMBAT_FEEL_CONSTANTS = preload("res://data/CombatFeelConstants.gd")
const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")

# Combat result tuning.
const TIMED_ATTACK_DAMAGE_RATIO: float = 0.5
const PLAYER_DAMAGE_TO_TIMED_RATIO: float = 0.68
const LATE_ATTACK_PUNISH_RATIO: float = 0.18
const GOOD_PARRY_REFLECT_MULT: float = 1.2
const PERFECT_PARRY_REFLECT_MULT: float = 2.0
const IDLE_ATTACK_DAMAGE_RATIO: float = 0.14

# Recovery / anti-spam tuning.
const BASIC_ATTACK_RECOVERY: float = 0.28
const TIMED_ATTACK_RECOVERY: float = 0.14
const PERFECT_ATTACK_RECOVERY: float = 0.08
const EARLY_ATTACK_RECOVERY: float = 0.24
const LATE_ATTACK_RECOVERY: float = 0.32

const GOOD_PARRY_RECOVERY: float = 0.22
const PERFECT_PARRY_RECOVERY: float = 0.14
const FAILED_PARRY_RECOVERY: float = 0.32

const DODGE_RECOVERY: float = 0.30
const DODGE_GOOD_RECOVERY: float = 0.18
const DODGE_IFRAME_WINDOW: float = 0.11
const DODGE_IFRAME_WINDOW_ON_BEAT: float = 0.15
const ULTIMATE_RECOVERY: float = 0.45

const CHAIN_BYPASS_WINDOW: float = 0.60
const INPUT_BUFFER_WINDOW: float = 0.14

# Player sprite images.
const PLAYER_IDLE_PATH: String = "res://assets/characters/player/combat/player_idle.png"
const PLAYER_ATTACK_PATH: String = "res://assets/characters/player/combat/player_attack.png"
const PLAYER_PARRY_PATH: String = "res://assets/characters/player/combat/player_parry.png"
const PLAYER_HURT_PATH: String = "res://assets/characters/player/combat/player_hurt.png"
# Base display scale for the Sprite2D. 0.115 -> 512px image ~= 59px tall.
# Kept compact so the character reads as a focal point inside the timing sigil.
const PLAYER_SPRITE_SCALE_BASE: float = 0.115
# How long each temporary image holds before returning to idle (seconds).
const ATTACK_IMAGE_DURATION: float = 0.14
const PARRY_IMAGE_DURATION: float = 0.22
const HURT_IMAGE_DURATION: float = 0.30

# Cardinal focus rules.
# The player stays centered; direction input chooses the incoming lane focus that
# the next verb resolves against. current_lane remains the transient action lane
# for legacy event and motion compatibility.
const LANE_NORTH: int = 0
const LANE_SOUTH: int = 1
const LANE_EAST: int = 2
const LANE_WEST: int = 3
const DEFAULT_FOCUS_LANE: int = LANE_EAST

# Neutral stance rules.
# NEUTRAL_LANE is a core design rule: the player always returns here after every action.
# All action tweens return to this lane's Y position via _play_world_motion.
# Do not remove the return-to-center snap without updating every action state function.
const NEUTRAL_LANE: int = 1
const ATTACK_WORLD_X_OFFSET: float = 38.0
const PARRY_WORLD_X_OFFSET: float = -14.0
const DODGE_WORLD_X_OFFSET: float = -28.0
const HIT_WORLD_X_OFFSET: float = -22.0

# Sprite-local pose offsets. Neutral is centered on the logical origin so the
# character sits inside the timing sigil. Action offsets scale proportionally
# from the old values (~0.59× to match new 0.13 vs old 0.22 scale).
const NEUTRAL_SPRITE_POSITION := Vector2(0.0, -18.0)
const ATTACK_SPRITE_POSITION := Vector2(18.0, 2.0)
const PARRY_SPRITE_POSITION := Vector2(13.0, 3.0)
const DODGE_SPRITE_POSITION := Vector2(-4.0, 3.0)
const HIT_SPRITE_POSITION := Vector2(-6.0, 3.0)

const NEUTRAL_SPRITE_SCALE := Vector2(1.0, 1.0)
const ATTACK_SPRITE_SCALE := Vector2(1.14, 0.90)
const PARRY_SPRITE_SCALE := Vector2(1.02, 1.10)
const DODGE_SPRITE_SCALE := Vector2(0.88, 1.12)
const HIT_SPRITE_SCALE := Vector2(0.94, 1.0)

var lane_manager: Node = null
var combat_meter: Node = null
var _song_conductor: Node = null
var _run_growth: Node = null
var _sprite_color_tween: Tween = null

var current_lane: int = NEUTRAL_LANE
var parry_followup_active: bool = false
var parry_followup_timer: float = 0.0
var parry_followup_damage: float = 0.0

var action_lock_timer: float = 0.0
var current_action_state: String = "idle"
var dodge_invuln_timer: float = 0.0

var chain_bypass_available: bool = false
var chain_bypass_timer: float = 0.0
var combat_enabled: bool = true

var _sprite_pose_tween: Tween = null
var _world_motion_tween: Tween = null

var _player_sprite: Sprite2D = null
var _energy_aura: GPUParticles2D = null
var _idle_tex: Texture2D = null
var _attack_tex: Texture2D = null
var _parry_tex: Texture2D = null
var _hurt_tex: Texture2D = null
var _image_restore_tween: Tween = null
var _input_buffer: Dictionary = {}
var _last_input_report: Dictionary = {}
var active_focus_lane: int = DEFAULT_FOCUS_LANE


func _ready() -> void:
	sprite.visible = false  # hide placeholder ColorRect; Sprite2D takes over
	_setup_player_sprite()
	_setup_energy_aura()
	_return_to_neutral_state(true)


func _exit_tree() -> void:
	if EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.disconnect(_on_projectile_fired)


func _process(delta: float) -> void:
	if action_lock_timer > 0.0:
		action_lock_timer = max(action_lock_timer - delta, 0.0)
		if action_lock_timer <= 0.0:
			current_action_state = "idle"
			_check_input_buffer()
	
	if not _input_buffer.is_empty():
		_input_buffer["time_left"] -= delta
		if _input_buffer["time_left"] <= 0.0:
			_emit_input_report(
				String(_input_buffer.get("action", "")),
				int(_input_buffer.get("lane", active_focus_lane)),
				false,
				false,
				"buffer_expired"
			)
			_input_buffer.clear()

	if dodge_invuln_timer > 0.0:
		dodge_invuln_timer = max(dodge_invuln_timer - delta, 0.0)

	if parry_followup_active:
		parry_followup_timer -= delta
		if parry_followup_timer <= 0.0:
			parry_followup_active = false
			parry_followup_timer = 0.0
			parry_followup_damage = 0.0

	if chain_bypass_available:
		chain_bypass_timer -= delta
		if chain_bypass_timer <= 0.0:
			chain_bypass_available = false
			chain_bypass_timer = 0.0


func _unhandled_input(event: InputEvent) -> void:
	var focus_lane: int = _get_focus_lane_from_event(event)
	if focus_lane >= 0:
		_set_active_focus_lane(focus_lane)
		get_viewport().set_input_as_handled()
		return

	var action_type: String = _get_combat_action_from_event(event)
	if action_type.is_empty():
		return

	var target_dir: int = _get_target_direction()

	if not combat_enabled:
		_emit_input_report(action_type, target_dir, false, false, "combat_disabled")
		get_viewport().set_input_as_handled()
		return

	if lane_manager == null or combat_meter == null:
		_emit_input_report(action_type, target_dir, false, false, "missing_runtime")
		get_viewport().set_input_as_handled()
		return

	_handle_directional_action(target_dir, action_type)
	get_viewport().set_input_as_handled()


func _get_target_direction() -> int:
	var held_focus: int = _get_held_focus_lane()
	if held_focus >= 0:
		_set_active_focus_lane(held_focus, false)
	return active_focus_lane


func get_active_focus_lane() -> int:
	return active_focus_lane


func debug_force_focus_and_action(lane: int, action_type: String) -> bool:
	if not OS.is_debug_build():
		return false
	if lane_manager == null or combat_meter == null:
		return false
	_set_active_focus_lane(lane)
	return _handle_directional_action(active_focus_lane, action_type)


func _set_active_focus_lane(lane: int, show_ring_feedback: bool = true) -> void:
	lane = clampi(lane, 0, lane_manager.THREAT_COUNT - 1 if lane_manager != null else 3)
	if active_focus_lane == lane:
		return
	active_focus_lane = lane
	if show_ring_feedback:
		EventBus.emit_signal("timing_ring_pressed", active_focus_lane)


func _get_focus_lane_from_event(event: InputEvent) -> int:
	if _event_action_pressed(event, "lane_focus_north") or _event_action_pressed(event, "mod_up"):
		return LANE_NORTH
	if _event_action_pressed(event, "lane_focus_south") or _event_action_pressed(event, "mod_down"):
		return LANE_SOUTH
	if _event_action_pressed(event, "lane_focus_west") or _event_action_pressed(event, "mod_left"):
		return LANE_WEST
	if _event_action_pressed(event, "lane_focus_east") or _event_action_pressed(event, "mod_right"):
		return LANE_EAST
	return -1


func _get_held_focus_lane() -> int:
	if _is_action_pressed("lane_focus_north") or _is_action_pressed("mod_up"):
		return LANE_NORTH
	if _is_action_pressed("lane_focus_south") or _is_action_pressed("mod_down"):
		return LANE_SOUTH
	if _is_action_pressed("lane_focus_west") or _is_action_pressed("mod_left"):
		return LANE_WEST
	if _is_action_pressed("lane_focus_east") or _is_action_pressed("mod_right"):
		return LANE_EAST
	return -1


func _event_action_pressed(event: InputEvent, action_name: StringName) -> bool:
	return InputMap.has_action(action_name) and event.is_action_pressed(action_name)


func _is_action_pressed(action_name: StringName) -> bool:
	return InputMap.has_action(action_name) and Input.is_action_pressed(action_name)


func _get_combat_action_from_event(event: InputEvent) -> String:
	if event.is_action_pressed("action_attack"):
		return "attack"
	if event.is_action_pressed("action_parry"):
		return "parry"
	if event.is_action_pressed("action_dodge"):
		return "dodge"
	if event.is_action_pressed("action_ultimate"):
		return "ultimate"
	return ""


func _handle_directional_action(target_dir: int, action_type: String) -> bool:
	target_dir = clampi(target_dir, 0, lane_manager.THREAT_COUNT - 1 if lane_manager != null else 3)

	var immediate_reject: String = _get_immediate_rejection_reason(action_type)
	if not immediate_reject.is_empty():
		_emit_input_report(action_type, target_dir, false, false, immediate_reject)
		_emit_rejected_input_feedback(action_type, immediate_reject)
		return false

	if not _can_accept_action():
		_buffer_action(action_type, target_dir, "locked")
		return true

	_consume_chain_bypass_if_needed()
	EventBus.emit_signal("timing_ring_pressed", target_dir)
	
	match action_type:
		"attack":
			_select_action_lane(target_dir)
			_emit_input_report(action_type, target_dir, true, false, "accepted")
			_try_attack()
		"parry":
			_select_action_lane(target_dir)
			_emit_input_report(action_type, target_dir, true, false, "accepted")
			_try_parry()
		"dodge":
			_emit_input_report(action_type, target_dir, true, false, "accepted")
			_try_dodge_radial(target_dir)
		"ultimate":
			_emit_input_report(action_type, target_dir, true, false, "accepted")
			_try_ultimate()
		_:
			_emit_input_report(action_type, target_dir, false, false, "unknown_action")
			return false
	return true


func _buffer_action(action_type: String, target_dir: int, reason: String) -> void:
	_input_buffer = {
		"action": action_type,
		"lane": target_dir,
		"time_left": INPUT_BUFFER_WINDOW
	}
	_emit_input_report(action_type, target_dir, false, true, reason)
	EventBus.emit_signal("timing_ring_pressed", target_dir)


func _get_immediate_rejection_reason(action_type: String) -> String:
	if not combat_enabled:
		return "combat_disabled"
	if lane_manager == null or combat_meter == null:
		return "missing_runtime"
	match action_type:
		"parry":
			if not bool(combat_meter.call("can_parry")):
				return "no_stamina"
		"dodge":
			if not bool(combat_meter.call("can_dodge")):
				return "no_stamina"
		"ultimate":
			if not bool(combat_meter.call("is_ultimate_available")):
				return "no_charge"
		"attack":
			pass
		_:
			return "unknown_action"
	return ""


func _emit_rejected_input_feedback(action_type: String, reason: String) -> void:
	match reason:
		"no_stamina":
			EventBus.emit_signal("player_no_stamina")
		"no_charge":
			EventBus.emit_signal("proc_feedback_requested", "NOT READY", Color(1.0, 0.55, 0.28, 1.0))
			EventBus.emit_signal("screen_flash", Color(1.0, 0.32, 0.10, 0.06), 0.04)
		"combat_disabled", "missing_runtime":
			pass
		_:
			EventBus.emit_signal("proc_feedback_requested", action_type.to_upper() + " DENIED", Color(1.0, 0.45, 0.45, 1.0))


func _emit_input_report(action_type: String, lane: int, accepted: bool, buffered: bool, reason: String) -> void:
	var cooldowns: Dictionary = _build_input_cooldowns()
	_last_input_report = {
		"action": action_type,
		"lane": lane,
		"accepted": accepted,
		"buffered": buffered,
		"reason": reason,
		"state": current_action_state,
		"cooldowns": cooldowns
	}
	EventBus.emit_signal(
		"combat_input_resolved",
		action_type,
		lane,
		accepted,
		buffered,
		reason,
		current_action_state,
		cooldowns
	)


func _build_input_cooldowns() -> Dictionary:
	return {
		"action_lock": action_lock_timer,
		"dodge_iframe": dodge_invuln_timer,
		"chain_bypass": chain_bypass_timer if chain_bypass_available else 0.0,
		"parry_followup": parry_followup_timer if parry_followup_active else 0.0,
		"stamina": float(combat_meter.get("stamina")) if combat_meter != null else 0.0,
		"ultimate_ready": bool(combat_meter.call("is_ultimate_available")) if combat_meter != null else false
	}


func _try_dodge_radial(target_dir: int) -> void:
	# In radial combat, dodge moves the player "through" the threat or to the center.
	# For now, we reuse _try_dodge logic but map the target_dir correctly.
	_try_dodge(target_dir)

func setup(new_lane_manager: Node, new_combat_meter: Node) -> void:
	lane_manager = new_lane_manager
	combat_meter = new_combat_meter
	combat_enabled = true
	current_lane = NEUTRAL_LANE
	active_focus_lane = DEFAULT_FOCUS_LANE

	if not EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.connect(_on_projectile_fired)
	
	if not EventBus.combo_changed.is_connected(_on_combo_changed):
		EventBus.combo_changed.connect(_on_combo_changed)
	
	if not EventBus.song_beat_pulse.is_connected(_on_song_beat_pulse):
		EventBus.song_beat_pulse.connect(_on_song_beat_pulse)

	for lane in range(lane_manager.THREAT_COUNT if lane_manager else 4):
		var projectile: Projectile = lane_manager.get_projectile(lane) as Projectile
		if is_instance_valid(projectile):
			_connect_projectile_signals(projectile)

	_return_to_neutral_state(true)


func set_combat_enabled(enabled: bool) -> void:
	combat_enabled = enabled

	if not combat_enabled:
		action_lock_timer = 0.0
		current_action_state = "idle"
		dodge_invuln_timer = 0.0
		chain_bypass_available = false
		chain_bypass_timer = 0.0
		parry_followup_active = false
		parry_followup_timer = 0.0
		parry_followup_damage = 0.0
		_clear_buffered_dodge()
		_return_to_neutral_state(true)


func set_song_conductor(conductor: Node) -> void:
	_song_conductor = conductor


func set_run_growth(rg: Node) -> void:
	_run_growth = rg


func _get_beat_quality() -> String:
	if _song_conductor == null or not _song_conductor.has_method("get_beat_quality"):
		return "off"
	return String(_song_conductor.get_beat_quality())


func _get_phrase_window() -> String:
	if combat_meter == null:
		return ""
	var count: int = int(combat_meter.get("phrase_count"))
	if count >= 8:
		return "flow_state"
	if count >= 5:
		return "in_pocket"
	if count >= 3:
		return "phrase"
	return ""


func _get_cadence_window() -> String:
	if _song_conductor == null or not is_instance_valid(_song_conductor):
		return ""
	if _song_conductor.has_method("resolve_cadence_window"):
		return String(_song_conductor.resolve_cadence_window(
			String(_song_conductor.get("current_section_id")),
			float(_song_conductor.get("current_intensity"))
		))
	if "current_cadence_window" in _song_conductor:
		return String(_song_conductor.get("current_cadence_window"))
	return ""


func _emit_slowmo_context(context_id: String) -> void:
	var base_scale: float = COMBAT_FEEL_CONSTANTS.get_slow_motion_scale(context_id)
	var base_duration: float = COMBAT_FEEL_CONSTANTS.get_slow_motion_duration(context_id)
	
	var preset: Dictionary = COMBAT_FEEL_CONTENT.get_slowmo_preset(context_id, {
		"scale": base_scale,
		"duration": base_duration
	})
	EventBus.emit_signal("slow_motion", float(preset.get("scale", base_scale)), float(preset.get("duration", base_duration)))


func _emit_mastery_context(event_id: String, lane: int, action_quality: String, beat_quality: String) -> void:
	EventBus.emit_signal("mastery_context_updated", {
		"event_id": event_id,
		"lane": lane,
		"action_quality": action_quality,
		"beat_quality": beat_quality,
		"phrase_window": _get_phrase_window(),
		"cadence_window": _get_cadence_window(),
		"timestamp": Time.get_ticks_msec() / 1000.0
	})


func _clear_mastery_context(event_id: String, lane: int) -> void:
	EventBus.emit_signal("mastery_context_updated", {
		"event_id": event_id,
		"lane": lane,
		"action_quality": "",
		"beat_quality": "off",
		"phrase_window": "",
		"cadence_window": "",
		"timestamp": Time.get_ticks_msec() / 1000.0
	})


func _flash_sprite_color(tint: Color, duration: float) -> void:
	if _sprite_color_tween != null:
		_sprite_color_tween.kill()
	# Sprite2D uses modulate (not color). Base is Color.WHITE = no tint.
	var vis_node: CanvasItem = (_player_sprite as CanvasItem) if _player_sprite != null else (sprite as CanvasItem)
	var prop: String = "modulate" if _player_sprite != null else "color"
	var base: Color = Color.WHITE if _player_sprite != null else Color(0.25, 0.55, 0.95, 1.0)
	_sprite_color_tween = create_tween()
	_sprite_color_tween.tween_property(vis_node, prop, tint, 0.03)
	_sprite_color_tween.tween_property(vis_node, prop, base, duration)


func _can_accept_action() -> bool:
	if chain_bypass_available:
		return true
	return action_lock_timer <= 0.0


func _consume_chain_bypass_if_needed() -> void:
	if chain_bypass_available:
		chain_bypass_available = false
		chain_bypass_timer = 0.0
		action_lock_timer = 0.0
		current_action_state = "idle"


func _grant_chain_bypass() -> void:
	chain_bypass_available = true
	chain_bypass_timer = CHAIN_BYPASS_WINDOW


func _lock_action(duration: float, state: String) -> void:
	var nerve_mult: float = clampf(1.0 / maxf(GameState.stat_swiftness, 0.1), 0.40, 2.0)
	action_lock_timer = max(duration * nerve_mult, 0.0)
	current_action_state = state


func _select_action_lane(target_lane: int) -> void:
	var previous_lane: int = current_lane
	current_lane = target_lane

	if previous_lane != current_lane:
		EventBus.emit_signal("player_teleported", previous_lane, current_lane)


func _try_attack() -> void:
	_play_attack_state(current_lane)

	var projectile: Node2D = lane_manager.call("get_projectile", current_lane)
	var combo_mult: float = float(combat_meter.call("damage_multiplier")) if combat_meter else 1.0

	if parry_followup_active:
		_fire_parry_followup(combo_mult)
		return

	if not is_instance_valid(projectile):
		_idle_attack(combo_mult)
		return

	var quality: String = String(projectile.call("evaluate_attack_timing"))

	match quality:
		"good", "perfect":
			_resolve_timed_attack(projectile, combo_mult, quality)
		"early":
			_resolve_early_attack()
		"late":
			_resolve_late_attack(projectile)
		"miss":
			_idle_attack(combo_mult)
		_:
			_idle_attack(combo_mult)


func _try_parry() -> void:
	_play_parry_state(current_lane)

	var projectile: Node2D = lane_manager.call("get_projectile", current_lane)
	if not is_instance_valid(projectile):
		combat_meter.call("record_bad_timing")
		_clear_mastery_context("failed_parry", current_lane)
		_flash_sprite_color(Color(0.82, 0.24, 0.28, 1.0), 0.12)
		EventBus.emit_signal("proc_feedback_requested", "EMPTY PARRY", Color(1.0, 0.45, 0.45, 1.0))
		EventBus.emit_signal("screen_flash", Color(1.0, 0.2, 0.2, 0.06), 0.04)
		_lock_action(FAILED_PARRY_RECOVERY, "failed_parry")
		return

	if not combat_meter.call("can_parry"):
		EventBus.emit_signal("player_no_stamina")
		return

	if not combat_meter.call("spend_stamina_for_parry"):
		return

	var quality: String = String(projectile.call("evaluate_parry_timing"))

	if quality != "good" and quality != "perfect":
		combat_meter.call("record_bad_timing")
		_clear_mastery_context("failed_parry", current_lane)
		EventBus.emit_signal("screen_flash", Color(1.0, 0.2, 0.2, 0.08), 0.05)
		_lock_action(FAILED_PARRY_RECOVERY, "failed_parry")
		return

	var beat: String = _get_beat_quality()
	var combo_mult: float = float(combat_meter.call("damage_multiplier"))
	var reflect_mult: float = GOOD_PARRY_REFLECT_MULT
	var recovery: float = GOOD_PARRY_RECOVERY
	var followup_window: float = COMBAT_FEEL_CONTENT.PARRY_FOLLOWUP_WINDOW_BASE

	if quality == "perfect":
		reflect_mult = PERFECT_PARRY_REFLECT_MULT
		recovery = PERFECT_PARRY_RECOVERY

	# On-beat perfect: bonus reflect and extended counter window.
	if quality == "perfect" and (beat == "perfect" or beat == "good"):
		reflect_mult *= 1.25
		followup_window = COMBAT_FEEL_CONTENT.PARRY_FOLLOWUP_WINDOW_ON_BEAT

	# Mutation Pass: Parry
	if _run_growth != null:
		if quality == "perfect":
			var stamina_gain: float = _run_growth.get_mutation_bonus("stamina_on_perfect_parry")
			if stamina_gain > 0.0:
				combat_meter.call("restore_stamina", stamina_gain)
				_run_growth.consume_mutation_charges("stamina_on_perfect_parry", 1)
				
			var expose_all: float = _run_growth.get_mutation_bonus("expose_all_on_perfect_parry")
			if expose_all > 0.0:
				for ex_lane in range(lane_manager.THREAT_COUNT if lane_manager else 4):
					lane_manager.call("apply_status", ex_lane, "expose", {"duration": expose_all})
				_run_growth.consume_mutation_charges("expose_all_on_perfect_parry", 1)
		
		var pale_all: float = _run_growth.get_mutation_bonus("pale_on_parry")
		if pale_all > 0.0:
			for pa_lane in range(lane_manager.THREAT_COUNT if lane_manager else 4):
				lane_manager.call("apply_status", pa_lane, "pale", {})
			_run_growth.consume_mutation_charges("pale_on_parry", 1)

	var reflect_damage: float = float(projectile.get("damage")) * reflect_mult * combo_mult * (1.0 + _get_parry_reflect_bonus())

	projectile.call("reflect_to_enemy", reflect_damage)
	lane_manager.call("clear_slot", current_lane)
	combat_meter.call("record_parry", quality)
	combat_meter.call("record_phrase_action", quality)
	_show_parry_image(quality)
	_emit_mastery_context("parry", current_lane, quality, beat)

	# Trigger the new counter-warp v1 automatically on projectile parry.
	# This consolidates parry and counter into one aggressive motion.
	_trigger_parry_counter_warp(current_lane, reflect_damage, quality)

	EventBus.emit_signal("player_parried", current_lane, quality, reflect_damage)

	if quality == "perfect":
		_flash_sprite_color(Color(0.55, 1.0, 0.72, 1.0), 0.14)
		EventBus.emit_signal("screen_flash", Color(0.45, 1.0, 0.75, 0.16), 0.08)
		if beat == "perfect":
			_emit_slowmo_context("parry_perfect_beat_perfect")
		elif beat == "good":
			_emit_slowmo_context("parry_perfect_beat_good")
		else:
			_emit_slowmo_context("parry_perfect_offbeat")
	else:
		_flash_sprite_color(Color(0.45, 0.88, 0.62, 1.0), 0.10)
		EventBus.emit_signal("screen_flash", Color(0.45, 1.0, 0.75, 0.10), 0.06)

	_lock_action(recovery, "parry")


func _try_dodge(target_dir: int) -> void:
	# Clamping to valid threat indices.
	target_dir = clampi(target_dir, 0, 3)
	
	if not combat_meter.call("spend_stamina_for_dodge"):
		return

	# In centered combat, dodge is an iframe-dash toward the threat or to the center.
	# We snap the player toward the threat briefly and return to neutral.
	var from_pos: Vector2 = _neutral_world_position()
	var to_pos: Vector2 = lane_manager.get_threat_hit_zone_pos(target_dir)

	EventBus.emit_signal("player_teleported", current_lane, target_dir)
	_play_dodge_state_radial(target_dir, to_pos)

	# I-frames and masteries.
	var beat: String = _get_beat_quality()
	combat_meter.call("record_dodge")
	combat_meter.call("record_phrase_action", "good")
	_emit_mastery_context("dodge", target_dir, "good", beat)
	EventBus.emit_signal("player_dodged", current_lane, target_dir)
	dodge_invuln_timer = DODGE_IFRAME_WINDOW_ON_BEAT if (beat == "perfect" or beat == "good") else DODGE_IFRAME_WINDOW

	if beat == "perfect" or beat == "good":
		_flash_sprite_color(Color(0.55, 0.82, 1.0, 1.0), 0.10)
		EventBus.emit_signal("screen_flash", Color(0.55, 0.75, 1.0, 0.10), 0.06)
		_lock_action(DODGE_GOOD_RECOVERY, "dodge")
	else:
		EventBus.emit_signal("screen_flash", Color(0.65, 0.85, 1.0, 0.06), 0.05)
		_lock_action(DODGE_RECOVERY, "dodge")


func _play_dodge_state_radial(target_dir: int, target_pos: Vector2) -> void:
	_apply_sprite_facing(target_dir)
	_spawn_dodge_afterimage()
	_play_sprite_pose(DODGE_SPRITE_POSITION, DODGE_SPRITE_SCALE, 0.10)

	# Motion toward the threat hit-zone, then return to neutral center.
	if _world_motion_tween != null:
		_world_motion_tween.kill()

	_world_motion_tween = create_tween()
	_world_motion_tween.tween_property(self, "position", target_pos, 0.05) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	_world_motion_tween.tween_property(self, "position", _neutral_world_position(), 0.16) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_world_motion_tween.tween_callback(func() -> void:
		current_lane = NEUTRAL_LANE
	)


func _try_ultimate() -> void:
	if not combat_meter.call("is_ultimate_available"):
		return

	_show_player_image(_attack_tex, ULTIMATE_RECOVERY)
	_play_sprite_pose(ATTACK_SPRITE_POSITION, ATTACK_SPRITE_SCALE * 1.5, 0.4) # Dramatic pose
	_play_world_motion(
		_action_world_position(NEUTRAL_LANE, ATTACK_WORLD_X_OFFSET * 2.0),
		_neutral_world_position(),
		0.1,
		0.4
	)

	var beat: String = _get_beat_quality()
	var multiplier: float = float(combat_meter.call("consume_ultimate"))
	if multiplier <= 0.0:
		return

	# Beat bonus: on-beat perfect adds +20% damage to the ultimate.
	var beat_mult: float = 1.0
	if beat == "perfect":
		beat_mult = 1.20
	elif beat == "good":
		beat_mult = 1.10

	var total_damage: float = GameState.get_attack_damage() * multiplier * beat_mult * GameState.stat_adaptability
	total_damage += _get_creature_bonus()

	for lane in range(lane_manager.THREAT_COUNT if lane_manager else 4):
		lane_manager.call("damage_enemy", lane, total_damage)

	EventBus.emit_signal("screen_flash", Color(1.0, 0.75, 0.3, 0.16), 0.10)

	if beat == "perfect":
		_emit_slowmo_context("ultimate_perfect")
	elif beat == "good":
		_emit_slowmo_context("ultimate_good")
	else:
		_emit_slowmo_context("ultimate_base")

	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(ULTIMATE_RECOVERY, "ultimate")


func _idle_attack(combo_mult: float) -> void:
	var idle_damage: float = (GameState.get_attack_damage() * IDLE_ATTACK_DAMAGE_RATIO) * combo_mult
	lane_manager.call("damage_enemy", current_lane, idle_damage)
	combat_meter.call("record_attack")
	_clear_mastery_context("idle_attack", current_lane)
	EventBus.emit_signal("player_attacked", current_lane, idle_damage, false)
	EventBus.emit_signal("screen_flash", Color(0.85, 0.85, 0.85, 0.04), 0.03)

	_lock_action(BASIC_ATTACK_RECOVERY, "idle_attack")


func _resolve_timed_attack(projectile, combo_mult: float, quality: String) -> void:
	var beat: String = _get_beat_quality()
	var phrase_bonus: float = float(combat_meter.call("get_phrase_bonus"))

	# Beat bonus damage: +35% on perfect-quality + on-beat-perfect, +15% on on-beat-good.
	var beat_mult: float = 1.0
	if quality == "perfect" and beat == "perfect":
		beat_mult = 1.35
	elif beat == "perfect" or beat == "good":
		beat_mult = 1.15

	# Growth multiplier: aggression adds flat % to all timed hits;
	# cadence adds additional flat % to good and perfect hits only.
	# Resolve through RunGrowth's public effect bridge so legacy compatibility
	# and live surges share one authoritative source.
	var growth_mult: float = 1.0
	if _run_growth != null:
		var aggr_effect: Dictionary = {}
		if _run_growth.has_method("get_growth_effect"):
			aggr_effect = Dictionary(_run_growth.call("get_growth_effect", "timed_attack_bonus_damage"))
		elif _run_growth.has_method("get_runtime_effect"):
			aggr_effect = Dictionary(_run_growth.call("get_runtime_effect", "timed_attack_bonus_damage"))
		growth_mult += float(aggr_effect.get("value", 0.0))
		if quality == "good" or quality == "perfect":
			var cad_effect: Dictionary = {}
			if _run_growth.has_method("get_growth_effect"):
				cad_effect = Dictionary(_run_growth.call("get_growth_effect", "good_timed_bonus_damage"))
			elif _run_growth.has_method("get_runtime_effect"):
				cad_effect = Dictionary(_run_growth.call("get_runtime_effect", "good_timed_bonus_damage"))
			growth_mult += float(cad_effect.get("value", 0.0))

	# Player attack damage (base + absorbed) now cashes out directly in timed attacks.
	# combine the "reflected" projectile damage with a portion of the player's own power.
	var base_atk: float = GameState.get_attack_damage()

	# Mutation Pass: Timed Damage
	var mutation_bonus: float = 0.0
	if _run_growth != null:
		mutation_bonus = _run_growth.get_mutation_bonus("timed_damage_flat", {"quality": quality})
		if mutation_bonus > 0.0:
			_run_growth.consume_mutation_charges("timed_damage_flat", 1, {"quality": quality})

	var timed_damage: float = ((float(projectile.get("damage")) * TIMED_ATTACK_DAMAGE_RATIO) + (base_atk * PLAYER_DAMAGE_TO_TIMED_RATIO)) * combo_mult * (1.0 + phrase_bonus) * beat_mult * growth_mult * GameState.stat_adaptability + _get_timed_damage_bonus() + mutation_bonus
	var recovery: float = TIMED_ATTACK_RECOVERY


	projectile.call("resolve", "attack_%s" % quality)
	lane_manager.call("clear_slot", current_lane)
	lane_manager.call("damage_enemy", current_lane, timed_damage)
	combat_meter.call("record_timed_attack")
	combat_meter.call("record_phrase_action", quality)
	_emit_mastery_context("timed_attack", current_lane, quality, beat)

	EventBus.emit_signal("player_attacked", current_lane, timed_damage, true)
	EventBus.emit_signal("timed_attack_resolved", current_lane, quality, timed_damage)

	if quality == "perfect":
		_flash_sprite_color(Color(1.0, 0.75, 0.25, 1.0), 0.12)
		EventBus.emit_signal("screen_flash", Color(1.0, 0.85, 0.35, 0.14), 0.08)
		recovery = PERFECT_ATTACK_RECOVERY
		if beat == "perfect":
			_emit_slowmo_context("timed_attack_perfect_beat_perfect")
		else:
			_emit_slowmo_context("timed_attack_perfect_other")
	else:
		_flash_sprite_color(Color(0.95, 0.62, 0.18, 1.0), 0.10)
		EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.55, 0.12), 0.07)
		_emit_slowmo_context("timed_attack_good")

	_grant_chain_bypass()
	_lock_action(recovery, "timed_attack")


func _resolve_early_attack() -> void:
	var armor_chance: float = clamp(GameState.stat_adaptability - 1.0, 0.0, 0.85)
	if randf() < armor_chance:
		# Combo Armor triggered: do not call record_bad_timing
		EventBus.emit_signal("proc_feedback_requested", "FORM ARMOR", Color(0.42, 0.85, 0.72, 1.0))
	else:
		combat_meter.call("record_bad_timing")
		
	_clear_mastery_context("early_attack", current_lane)
	EventBus.emit_signal("attack_timing_early_resolved", current_lane)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.15, 0.15, 0.05), 0.04)
	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(EARLY_ATTACK_RECOVERY, "early_attack")


func _resolve_late_attack(projectile: Node) -> void:
	var punish_damage: float = float(projectile.get("damage")) * LATE_ATTACK_PUNISH_RATIO
	_take_damage(punish_damage, current_lane)
	
	var armor_chance: float = clamp(GameState.stat_adaptability - 1.0, 0.0, 0.85)
	if randf() < armor_chance:
		# Combo Armor triggered
		EventBus.emit_signal("proc_feedback_requested", "FORM ARMOR", Color(0.42, 0.85, 0.72, 1.0))
	else:
		combat_meter.call("record_bad_timing")
		
	_clear_mastery_context("late_attack", current_lane)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.15, 0.15, 0.10), 0.06)
	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(LATE_ATTACK_RECOVERY, "late_attack")


func _fire_parry_followup(combo_mult: float) -> void:
	_play_attack_state(current_lane)

	var followup_damage: float = max(parry_followup_damage, GameState.get_attack_damage()) * combo_mult
	lane_manager.call("damage_enemy", current_lane, followup_damage)
	combat_meter.call("record_lane_read")
	EventBus.emit_signal("player_attacked", current_lane, followup_damage, true)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.65, 0.08), 0.05)
	_emit_slowmo_context("parry_followup")

	parry_followup_active = false
	parry_followup_timer = 0.0
	parry_followup_damage = 0.0

	_grant_chain_bypass()
	_lock_action(TIMED_ATTACK_RECOVERY, "parry_followup")


func _trigger_parry_counter_warp(target_lane: int, damage: float, quality: String) -> void:
	# Automated physical counter-strike on projectile parry.
	# Sequencing: Parry Impact -> Short Freeze (Hit-Stop) -> Warp Strike.
	
	var is_perfect: bool = (quality == "perfect")
	var preset_id: String = "counter_warp_perfect" if is_perfect else "counter_warp_good"
	
	_emit_slowmo_context(preset_id)
	EventBus.emit_signal("screen_flash", Color(1.0, 1.0, 1.0, 0.20 if is_perfect else 0.12), 0.05)

	# 2. Sequential Strike: Execute the warp-attack after a tiny beat.
	# TODO: Clarify fragile delayed state - should this align with SongConductor beat?
	var warp_timer := get_tree().create_timer(0.06)
	warp_timer.timeout.connect(func():
		_play_counter_warp_state(target_lane)
		
		# SFX: Dash/Warp sound cue.
		EventBus.emit_signal("play_sfx", "player_warp")
		
		# Ghosting: Flash a bright cyan/white tint during the dash.
		_flash_sprite_color(Color(1.5, 2.0, 2.0, 1.0), 0.12)
		
		# Resolve the physical strike.
		lane_manager.call("damage_enemy", target_lane, damage)
		EventBus.emit_signal("player_attacked", target_lane, damage, true)
		
		# Feedback: Strong punch for the actual hit resolution.
		EventBus.emit_signal("screen_shake", 5.0 if is_perfect else 3.0, 0.12 if is_perfect else 0.08)
		EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.70, 0.15 if is_perfect else 0.10), 0.06)
	)


func _play_counter_warp_state(target_lane: int) -> void:
	# Radial warp: reach 85% toward the spawn from the hit zone, matching original
	# strike depth but now correct for all 4 cardinal directions (not East-only).
	var spawn_dist: float = lane_manager.get_threat_spawn_pos(target_lane).distance_to(lane_manager.get_player_pos())
	var hit_zone_dist: float = lane_manager.get_threat_hit_zone_pos(target_lane).distance_to(lane_manager.get_player_pos())
	var reach_dist: float = lerp(spawn_dist, hit_zone_dist, 0.15)

	_show_attack_image()
	_play_sprite_pose(ATTACK_SPRITE_POSITION, ATTACK_SPRITE_SCALE, 0.18)
	_play_world_motion(
		_action_world_position(target_lane, reach_dist),
		_neutral_world_position(),
		0.05,
		0.24
	)


func _take_damage(amount: float, source_lane: int) -> void:
	_play_hit_state(source_lane)
	_show_hurt_image()

	var surge_dr: float = 0.0
	if _run_growth != null and _run_growth.has_method("get_runtime_effect"):
		var effect: Dictionary = Dictionary(_run_growth.call("get_runtime_effect", "guard_damage_reduction"))
		surge_dr = float(effect.get("value", 0.0))

	# Mutation Pass: Damage Taken
	if _run_growth != null:
		var invuln: float = _run_growth.get_mutation_bonus("invuln_hits")
		if invuln > 0.0:
			amount = 0.0
			_run_growth.consume_mutation_charges("invuln_hits", 1)
		else:
			var mend: float = _run_growth.get_mutation_bonus("heal_on_hit_taken")
			if mend > 0.0:
				var healed: float = GameState.heal_player(mend)
				if healed > 0.0:
					EventBus.emit_signal("player_healed", healed)
				_run_growth.consume_mutation_charges("heal_on_hit_taken", 1)

	amount = amount * (1.0 - _get_damage_reduction()) * (1.0 - surge_dr)
	GameState.player_hp = max(GameState.player_hp - amount, 0.0)
	_flash_sprite_color(Color(1.0, 0.25, 0.25, 1.0), 0.18)
	combat_meter.call("break_phrase")
	_clear_mastery_context("damage_taken", source_lane)
	EventBus.emit_signal("player_took_damage", amount, source_lane)
	EventBus.emit_signal("screen_shake", 5.0, 0.12)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.1, 0.1, 0.14), 0.10)

	if GameState.player_hp <= 0.0:
		EventBus.emit_signal("player_died")
		EventBus.emit_signal("combat_ended", false)


func _get_creature_bonus() -> float:
	# Sums damage_on_ultimate from all bonded creatures, scaled by bond level.
	var total: float = 0.0
	for creature in GameState.roster:
		var passive: Dictionary = creature.get("bond_passive", {})
		if passive.get("type", "") == "damage_on_ultimate":
			var mult: float = GameState.get_bond_level_mult(int(creature.get("bond_level", 1)))
			total += float(passive.get("value", 0.0)) * mult
	return total


func _get_damage_reduction() -> float:
	# Sums damage_reduction_pct from all bonded creatures, scaled by bond level.
	# Live run defense shares this seam so survivability stays concrete and bounded.
	var total: float = GameState.get_defense_damage_reduction()
	for creature in GameState.roster:
		var passive: Dictionary = creature.get("bond_passive", {})
		if passive.get("type", "") == "damage_reduction_pct":
			var mult: float = GameState.get_bond_level_mult(int(creature.get("bond_level", 1)))
			total += float(passive.get("value", 0.0)) * mult
	return min(total, GameState.COMBINED_DAMAGE_REDUCTION_CAP)


func _get_parry_reflect_bonus() -> float:
	# Sums parry_reflect_mult from all bonded creatures (e.g. Veilskin +0.40), scaled by bond level.
	var total: float = 0.0
	for creature in GameState.roster:
		var passive: Dictionary = creature.get("bond_passive", {})
		if passive.get("type", "") == "parry_reflect_mult":
			var mult: float = GameState.get_bond_level_mult(int(creature.get("bond_level", 1)))
			total += float(passive.get("value", 0.0)) * mult
	return total


func _get_timed_damage_bonus() -> float:
	# Sums timed_damage_flat from all bonded creatures (e.g. Thornback +3), scaled by bond level.
	var total: float = 0.0
	for creature in GameState.roster:
		var passive: Dictionary = creature.get("bond_passive", {})
		if passive.get("type", "") == "timed_damage_flat":
			var mult: float = GameState.get_bond_level_mult(int(creature.get("bond_level", 1)))
			total += float(passive.get("value", 0.0)) * mult
	return total


func _neutral_world_position() -> Vector2:
	if lane_manager == null:
		return Vector2.ZERO

	return lane_manager.get_player_pos()


func _action_world_position(target_dir: int, reach_distance: float) -> Vector2:
	if lane_manager == null:
		return Vector2.ZERO

	var center: Vector2 = lane_manager.get_player_pos()
	var threat_pos: Vector2 = lane_manager.get_threat_hit_zone_pos(target_dir)
	var dir_vec: Vector2 = (threat_pos - center).normalized()
	
	return center + dir_vec * reach_distance


func _setup_player_sprite() -> void:
	# Load textures; fall back gracefully if any file is missing.
	if ResourceLoader.exists(PLAYER_IDLE_PATH):
		_idle_tex = load(PLAYER_IDLE_PATH) as Texture2D
	if ResourceLoader.exists(PLAYER_ATTACK_PATH):
		_attack_tex = load(PLAYER_ATTACK_PATH) as Texture2D
	if ResourceLoader.exists(PLAYER_PARRY_PATH):
		_parry_tex = load(PLAYER_PARRY_PATH) as Texture2D
	if ResourceLoader.exists(PLAYER_HURT_PATH):
		_hurt_tex = load(PLAYER_HURT_PATH) as Texture2D

	_player_sprite = Sprite2D.new()
	_player_sprite.name = "PlayerSprite"
	_player_sprite.texture = _idle_tex
	
	# Determine hframes for idle strip (assuming square 512x512 frames)
	if _idle_tex != null:
		_player_sprite.hframes = clampi(int(float(_idle_tex.get_width()) / _idle_tex.get_height()), 1, 64)
	else:
		_player_sprite.hframes = 1
	
	_player_sprite.vframes = 1
	_player_sprite.flip_h = false
	_player_sprite.position = NEUTRAL_SPRITE_POSITION
	_player_sprite.scale = NEUTRAL_SPRITE_SCALE * PLAYER_SPRITE_SCALE_BASE
	_setup_ground_shadow()
	add_child(_player_sprite)


func _show_player_image(tex: Texture2D, duration: float) -> void:
	if _player_sprite == null or tex == null:
		return
	_player_sprite.texture = tex
	# Update hframes for the new strip
	_player_sprite.hframes = clampi(int(float(tex.get_width()) / tex.get_height()), 1, 64)
	_player_sprite.frame = 0
	
	if _image_restore_tween != null:
		_image_restore_tween.kill()
	_image_restore_tween = create_tween()
	_image_restore_tween.tween_interval(duration)
	_image_restore_tween.tween_callback(func() -> void:
		if _player_sprite != null:
			_player_sprite.texture = _idle_tex
			_player_sprite.hframes = clampi(int(float(_idle_tex.get_width()) / _idle_tex.get_height()), 1, 64)
			_player_sprite.frame = 0
	)


func _show_attack_image() -> void:
	_show_player_image(_attack_tex, ATTACK_IMAGE_DURATION)


func _show_parry_image(quality: String = "good") -> void:
	_show_player_image(_parry_tex, PARRY_IMAGE_DURATION)


func _show_hurt_image() -> void:
	_show_player_image(_hurt_tex, HURT_IMAGE_DURATION)


func _apply_sprite_facing(direction: int) -> void:
	if _player_sprite == null:
		return
	match direction:
		2: _player_sprite.flip_h = false  # East — face right
		3: _player_sprite.flip_h = true   # West — face left


func _setup_ground_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.z_index = -1
	var pts := PackedVector2Array()
	var rx := 14.0
	var ry := 3.5
	for i in range(24):
		var a := (i / 24.0) * TAU
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	shadow.polygon = pts
	shadow.color = Color(0.0, 0.0, 0.0, 0.28)
	shadow.position = Vector2(0.0, 6.0)
	add_child(shadow)


func _setup_energy_aura() -> void:
	_energy_aura = GPUParticles2D.new()
	_energy_aura.name = "EnergyAura"
	_energy_aura.amount = 100
	_energy_aura.lifetime = 1.2
	_energy_aura.preprocess = 0.5
	_energy_aura.visibility_rect = Rect2(-100, -100, 200, 200)
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 21.0
	mat.emission_ring_inner_radius = 15.5
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 24.0
	mat.initial_velocity_max = 48.0
	mat.gravity = Vector3(0, -12, 0)
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.color = Color(0.24, 0.86, 0.74, 0.4) # Starting Cyan
	
	_energy_aura.process_material = mat
	add_child(_energy_aura)
	_energy_aura.position = Vector2.ZERO
	_energy_aura.emitting = true


func _update_aura_by_tier(tier: String) -> void:
	if _energy_aura == null: return
	
	var mat = _energy_aura.process_material as ParticleProcessMaterial
	if mat == null: return
	
	# Use UI_STYLE directly as it is the authoritative source for tier colors in the HUD/Visuals
	var UI_STYLE = load("res://systems/UIStyle.gd")
	var tier_color: Color = UI_STYLE.get_tier_color(tier)

	match tier:
		"stirring", "hunting":
			_energy_aura.amount = 100
		"rampage":
			_energy_aura.amount = 150
		"apex":
			_energy_aura.amount = 200
		"sovereign":
			_energy_aura.amount = 300
			
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(mat, "color", tier_color, 0.5)


func _on_song_beat_pulse(_beat_index: int, intensity: float, _quality: String) -> void:
	if _energy_aura == null: return
	
	var mat = _energy_aura.process_material as ParticleProcessMaterial
	if mat == null: return
	
	# Pulse intensity based on song energy
	var pulse_scale: float = 1.0 + (intensity * 0.15)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_energy_aura, "scale", Vector2(pulse_scale, pulse_scale), 0.05)
	tween.tween_property(_energy_aura, "scale", Vector2.ONE, 0.15)
	
	# Scale particle speed with beat
	var base_vel = mat.initial_velocity_max
	tween.parallel().tween_property(mat, "initial_velocity_max", base_vel * 1.4, 0.05)
	tween.tween_property(mat, "initial_velocity_max", base_vel, 0.15)


func _on_combo_changed(_count: int, tier: String) -> void:
	_update_aura_by_tier(tier)


func _return_to_neutral_state(immediate: bool = false) -> void:
	current_lane = NEUTRAL_LANE

	var vis_node: CanvasItem = (_player_sprite as CanvasItem) if _player_sprite != null else (sprite as CanvasItem)
	var neutral_s: Vector2 = NEUTRAL_SPRITE_SCALE * (PLAYER_SPRITE_SCALE_BASE if _player_sprite != null else 1.0)

	if immediate:
		position = _neutral_world_position()
		vis_node.position = NEUTRAL_SPRITE_POSITION
		vis_node.scale = neutral_s
		return

	_play_sprite_pose(NEUTRAL_SPRITE_POSITION, NEUTRAL_SPRITE_SCALE, 0.06)
	_play_world_motion(_neutral_world_position(), _neutral_world_position(), 0.0, 0.08)


func _play_attack_state(target_lane: int) -> void:
	_apply_sprite_facing(target_lane)
	_show_attack_image()
	_play_sprite_pose(ATTACK_SPRITE_POSITION, ATTACK_SPRITE_SCALE, 0.08)
	_play_world_motion(
		_action_world_position(target_lane, ATTACK_WORLD_X_OFFSET),
		_neutral_world_position(),
		0.04,
		0.10
	)


func _play_parry_state(target_lane: int) -> void:
	_apply_sprite_facing(target_lane)
	_play_sprite_pose(PARRY_SPRITE_POSITION, PARRY_SPRITE_SCALE, 0.10)
	_play_world_motion(
		_action_world_position(target_lane, PARRY_WORLD_X_OFFSET),
		_neutral_world_position(),
		0.04,
		0.10
	)


func _play_dodge_state(target_lane: int) -> void:
	_spawn_dodge_afterimage()
	_play_sprite_pose(DODGE_SPRITE_POSITION, DODGE_SPRITE_SCALE, 0.10)
	_play_world_motion(
		_action_world_position(target_lane, DODGE_WORLD_X_OFFSET),
		_neutral_world_position(),
		0.05,
		0.16
	)


func _play_hit_state(target_lane: int) -> void:
	_apply_sprite_facing(target_lane)
	_play_sprite_pose(HIT_SPRITE_POSITION, HIT_SPRITE_SCALE, 0.12)
	_play_world_motion(
		_action_world_position(target_lane, HIT_WORLD_X_OFFSET),
		_neutral_world_position(),
		0.02,
		0.14
	)


func _play_sprite_pose(target_position: Vector2, target_scale: Vector2, return_time: float) -> void:
	if _sprite_pose_tween != null:
		_sprite_pose_tween.kill()

	var vis_node: CanvasItem = (_player_sprite as CanvasItem) if _player_sprite != null else (sprite as CanvasItem)
	# Scale constants are squash-stretch multipliers; apply PLAYER_SPRITE_SCALE_BASE
	# so the Sprite2D stays at the right display size through the pose animation.
	var action_s: Vector2 = target_scale * (PLAYER_SPRITE_SCALE_BASE if _player_sprite != null else 1.0)
	var neutral_s: Vector2 = NEUTRAL_SPRITE_SCALE * (PLAYER_SPRITE_SCALE_BASE if _player_sprite != null else 1.0)

	_sprite_pose_tween = create_tween()
	_sprite_pose_tween.tween_property(vis_node, "position", target_position, 0.03) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	_sprite_pose_tween.parallel().tween_property(vis_node, "scale", action_s, 0.03) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	_sprite_pose_tween.tween_property(vis_node, "position", NEUTRAL_SPRITE_POSITION, return_time) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_sprite_pose_tween.parallel().tween_property(vis_node, "scale", neutral_s, return_time) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _play_world_motion(action_position: Vector2, return_position: Vector2, push_time: float, return_time: float) -> void:
	if _world_motion_tween != null:
		_world_motion_tween.kill()

	# Capture the lane this action is being performed from. The callback uses this
	# to guard against snapping current_lane to neutral if a chain-bypass action has
	# already moved the player to a different lane while this tween was in flight.
	var acting_lane: int = current_lane

	_world_motion_tween = create_tween()
	if push_time > 0.0:
		_world_motion_tween.tween_property(self, "position", action_position, push_time) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	else:
		position = action_position

	_world_motion_tween.tween_property(self, "position", return_position, return_time) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_world_motion_tween.tween_callback(func() -> void:
		if current_lane != acting_lane:
			return
		current_lane = NEUTRAL_LANE
		if acting_lane != NEUTRAL_LANE:
			EventBus.emit_signal("player_teleported", acting_lane, NEUTRAL_LANE)
	)


func _on_projectile_fired(lane: int, _enemy_id: int) -> void:
	var projectile = lane_manager.get_projectile(lane)
	if is_instance_valid(projectile):
		_connect_projectile_signals(projectile)


func _connect_projectile_signals(projectile) -> void:
	if not is_instance_valid(projectile):
		return

	if not projectile.player_contact.is_connected(_on_projectile_player_contact):
		projectile.player_contact.connect(_on_projectile_player_contact)


func _on_projectile_player_contact(projectile: Node) -> void:
	if not is_instance_valid(projectile) or bool(projectile.get("is_resolved")):
		return

	var proj_damage: float = float(projectile.get("damage"))
	var proj_lane: int = int(projectile.get("lane"))

	if dodge_invuln_timer > 0.0:
		projectile.call("resolve", "dodged_through")
		lane_manager.call("clear_slot", proj_lane)
		EventBus.emit_signal("screen_flash", Color(0.50, 0.70, 1.0, 0.04), 0.03)
		return

	if combat_enabled:
		_take_damage(proj_damage, proj_lane)


func _check_input_buffer() -> void:
	if _input_buffer.is_empty():
		return
	
	var action: String = String(_input_buffer.get("action", ""))
	var lane: int = int(_input_buffer.get("lane", -1))
	var time_left: float = float(_input_buffer.get("time_left", 0.0))
	
	_input_buffer.clear()
	
	if time_left > 0.0:
		match action:
			"attack": _handle_directional_action(lane, "attack")
			"parry": _handle_directional_action(lane, "parry")
			"dodge": _handle_directional_action(lane, "dodge")
			"ultimate": _handle_directional_action(lane, "ultimate")


func _clear_buffered_dodge() -> void:
	if String(_input_buffer.get("action", "")) == "dodge":
		_input_buffer.clear()


func _read_dodge_direction() -> int:
	# In centered combat, dodge direction is towards the threat.
	return _get_target_direction()


func _spawn_dodge_afterimage() -> void:
	if _player_sprite == null or _player_sprite.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = _player_sprite.texture
	ghost.flip_h = _player_sprite.flip_h
	ghost.position = _player_sprite.position
	ghost.scale = _player_sprite.scale
	ghost.modulate = Color(0.72, 0.86, 1.0, 0.34)
	add_child(ghost)
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.14)
	tween.parallel().tween_property(ghost, "scale", _player_sprite.scale * 1.06, 0.14)
	tween.tween_callback(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)
