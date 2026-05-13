extends Node2D

@onready var sprite: ColorRect = $Sprite
const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
const SOVEREIGN_DAMAGE_CALCULATOR = preload("res://systems/SovereignDamageCalculator.gd")

# Combat result tuning.
const GOOD_PARRY_REFLECT_MULT: float = 1.2
const PERFECT_PARRY_REFLECT_MULT: float = 2.0

# Recovery / anti-spam tuning.
const BASIC_ATTACK_RECOVERY: float = 0.50
const TIMED_ATTACK_RECOVERY: float = 0.30
const PERFECT_ATTACK_RECOVERY: float = 0.20
const EARLY_ATTACK_RECOVERY: float = 0.40
const LATE_ATTACK_RECOVERY: float = 0.50

const GOOD_PARRY_RECOVERY: float = 0.22
const PERFECT_PARRY_RECOVERY: float = 0.14
const FAILED_PARRY_RECOVERY: float = 0.32
const PARRY_CAPTURE_RADIUS: float = 190.0
const PARRY_CAPTURE_CONE_DOT: float = 0.05
const PARRY_PANIC_RADIUS: float = 72.0
const PARRY_PROGRESS_GOOD_MIN: float = 0.88
const PARRY_PROGRESS_PERFECT_MIN: float = 0.97
const PARRY_PROGRESS_PERFECT_MAX: float = 1.04
const PARRY_PROGRESS_GOOD_MAX: float = 1.18

const DODGE_RECOVERY: float = 0.48
const DODGE_GOOD_RECOVERY: float = 0.34
const DODGE_IFRAME_WINDOW: float = 0.22
const DODGE_IFRAME_WINDOW_ON_BEAT: float = 0.28
const DODGE_PUSH_TIME: float = 0.26
const ULTIMATE_RECOVERY: float = 0.45

const CHAIN_BYPASS_WINDOW: float = 0.60
const INPUT_BUFFER_WINDOW: float = 0.14

# Player sprite images.
const PLAYER_IDLE_PATH: String = "res://assets/characters/player/combat/player_idle.png"
const PLAYER_ATTACK_PATH: String = "res://assets/characters/player/combat/player_attack.png"
const PLAYER_ATKEFFECT_PATH: String = "res://assets/characters/player/combat/player_atkeffect.png"
const PLAYER_PARRY_PATH: String = "res://assets/characters/player/combat/player_parry.png"
const PLAYER_HURT_PATH: String = "res://assets/characters/player/combat/player_hurt.png"

# Attack Range Tuning
const PREDATORY_LUNGE_MIN_DISTANCE: float = 80.0
const PREDATORY_LUNGE_STANDOFF: float = 45.0
const PREDATORY_LUNGE_PUSH_TIME: float = 0.07
const ATTACK_EFFECT_MIN_LENGTH: float = 46.0
const ATTACK_EFFECT_MAX_LENGTH: float = 118.0

# Base display scale for the Sprite2D. 0.05 -> 512px image ~= 25px tall.
# Kept compact so the character reads as a focal point inside the timing sigil.
const PLAYER_SPRITE_SCALE_BASE: float = 0.05
# How long each temporary image holds before returning to idle (seconds).
const ATTACK_IMAGE_DURATION: float = 0.35
const PARRY_IMAGE_DURATION: float = 0.22
const HURT_IMAGE_DURATION: float = 0.30

# Cardinal focus rules.
const DEFAULT_FOCUS_SECTOR: int = 2

# Neutral stance rules.
const ATTACK_WORLD_X_OFFSET: float = 18.0
const PARRY_WORLD_X_OFFSET: float = -6.0
const DODGE_WORLD_X_OFFSET: float = -16.0
const HIT_WORLD_X_OFFSET: float = -10.0

# Sprite-local pose offsets. Neutral is centered on the logical origin so the
# character sits inside the timing sigil. Action offsets scale proportionally
# from the old values (~0.5× to match new 0.05 vs old 0.115 scale).
const NEUTRAL_SPRITE_POSITION := Vector2(0.0, -9.0)
const ATTACK_SPRITE_POSITION := Vector2(9.0, 1.0)
const PARRY_SPRITE_POSITION := Vector2(6.0, 1.5)
const DODGE_SPRITE_POSITION := Vector2(-5.0, 4.0) # Deep heavy tuck
const HIT_SPRITE_POSITION := Vector2(-3.0, 1.5)

const NEUTRAL_SPRITE_SCALE := Vector2(1.0, 1.0)
const ATTACK_SPRITE_SCALE := Vector2(1.14, 0.90)
const PARRY_SPRITE_SCALE := Vector2(1.02, 1.10)
const DODGE_SPRITE_SCALE := Vector2(1.18, 0.78)
const HIT_SPRITE_SCALE := Vector2(0.94, 1.0)

var zone_manager: Node = null
var combat_meter: Node = null
var _song_conductor: Node = null
var _sprite_color_tween: Tween = null

var parry_followup_active: bool = false
var parry_followup_timer: float = 0.0
var parry_followup_damage: float = 0.0

var action_lock_timer: float = 0.0
var current_action_state: String = "idle"
var dodge_invuln_timer: float = 0.0

var chain_bypass_available: bool = false
var chain_bypass_timer: float = 0.0
var combat_enabled: bool = true

# Free Movement Tuning
const MOVEMENT_SPEED: float = 240.0
const MOVE_ACCELERATION: float = 1200.0
const MOVE_FRICTION: float = 800.0
const FOCUS_SNAP_THRESHOLD: float = 0.2 # Minimum joystick deflection to change focus

var free_position: Vector2 = Vector2.ZERO
var _move_velocity: Vector2 = Vector2.ZERO
var _facing_direction: Vector2 = Vector2.DOWN # Start facing SOUTH
var movement_enabled: bool = true

var _sprite_pose_tween: Tween = null
var _world_motion_tween: Tween = null

var _player_sprite: Sprite2D = null
var _atk_effect_sprite: Sprite2D = null
var _combat_visual_rig: Node2D = null
var _energy_aura: GPUParticles2D = null
var _idle_tex: Texture2D = null
var _attack_tex: Texture2D = null
var _atkeffect_tex: Texture2D = null
var _parry_tex: Texture2D = null
var _hurt_tex: Texture2D = null
var _image_restore_tween: Tween = null
var _atk_effect_pulse_tween: Tween = null
var _input_buffer: Dictionary = {}
var active_focus_sector: int = DEFAULT_FOCUS_SECTOR


func _ready() -> void:
	sprite.visible = false  # hide placeholder ColorRect; Sprite2D takes over
	free_position = global_position
	_setup_player_sprite()
	_setup_energy_aura()
	_return_to_neutral_state(true)


func _exit_tree() -> void:
	if EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.disconnect(_on_projectile_fired)
	if EventBus.combo_changed.is_connected(_on_combo_changed):
		EventBus.combo_changed.disconnect(_on_combo_changed)
	if EventBus.song_beat_pulse.is_connected(_on_song_beat_pulse):
		EventBus.song_beat_pulse.disconnect(_on_song_beat_pulse)


func _process(delta: float) -> void:
	if movement_enabled and combat_enabled and current_action_state != "dodge":
		_handle_free_movement(delta)

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
				int(_input_buffer.get("lane", active_focus_sector)),
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
	var action_type: String = _get_combat_action_from_event(event)
	if action_type.is_empty():
		return

	if not combat_enabled:
		_emit_input_report(action_type, _get_target_direction(), false, false, "combat_disabled")
		get_viewport().set_input_as_handled()
		return

	if zone_manager == null or combat_meter == null:
		_emit_input_report(action_type, _get_target_direction(), false, false, "missing_runtime")
		get_viewport().set_input_as_handled()
		return

	_handle_combat_action(action_type)
	get_viewport().set_input_as_handled()


func _get_target_direction() -> int:
	# Returns a sector index for visual/HUD purposes based on facing,
	# but does not dictate combat resolution.
	return _get_sector_from_vector(_facing_direction)


func get_active_focus_sector() -> int:
	return _get_target_direction()


func debug_force_focus_and_action(sector: int, action_type: String) -> bool:
	if not OS.is_debug_build():
		return false
	if zone_manager == null or combat_meter == null:
		return false
	# For debug, we temporarily force the facing to the sector's direction
	var angle: float = (float(sector) / 8.0) * TAU - PI/2.0
	_facing_direction = Vector2(cos(angle), sin(angle))
	return _handle_combat_action(action_type)


func _set_active_focus_sector(sector: int, show_ring_feedback: bool = true) -> void:
	sector = clampi(sector, 0, (zone_manager.THREAT_COUNT - 1) if zone_manager != null else 7)
	if active_focus_sector == sector:
		return
	active_focus_sector = sector
	if show_ring_feedback:
		EventBus.emit_signal("timing_ring_pressed", active_focus_sector)


func _get_combat_action_from_event(event: InputEvent) -> String:
	if event.is_action_pressed("action_attack"):
		return "attack"
	if event.is_action_pressed("action_parry"):
		return "parry"
	if event.is_action_pressed("action_dodge"):
		return "dodge"
	if event.is_action_pressed("action_ultimate"):
		return "ultimate"
	if event.is_action_pressed("action_support"):
		return "support"
	return ""


func _handle_combat_action(action_type: String) -> bool:
	# RESOLUTION TRUTH: True Spatial Interaction.
	# We no longer "snap" to a target. We act exactly where aimed.
	var targets: Dictionary = _get_targets_in_cone()
	var current_aim_dir: int = _get_target_direction()

	var immediate_reject: String = _get_immediate_rejection_reason(action_type)
	if not immediate_reject.is_empty():
		_emit_input_report(action_type, current_aim_dir, false, false, immediate_reject)
		_emit_rejected_input_feedback(action_type, immediate_reject)
		return false

	if not _can_accept_action():
		_buffer_action(action_type, current_aim_dir, "locked")
		return true

	_consume_chain_bypass_if_needed()
	EventBus.emit_signal("timing_ring_pressed", current_aim_dir)
	
	match action_type:
		"attack":
			_emit_input_report(action_type, current_aim_dir, true, false, "accepted")
			_try_attack(targets)
		"parry":
			_emit_input_report(action_type, current_aim_dir, true, false, "accepted")
			_try_parry(targets)
		"dodge":
			_emit_input_report(action_type, current_aim_dir, true, false, "accepted")
			_try_dodge_radial(current_aim_dir)
		"support":
			_emit_input_report(action_type, current_aim_dir, true, false, "accepted")
			_try_support_activation(current_aim_dir)
		"ultimate":
			_emit_input_report(action_type, current_aim_dir, true, false, "accepted")
			_try_ultimate()
		_:
			_emit_input_report(action_type, current_aim_dir, false, false, "unknown_action")
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
	if zone_manager == null or combat_meter == null:
		return "missing_runtime"
	match action_type:
		"parry":
			if not combat_meter.can_parry():
				return "no_stamina"
		"dodge":
			if not combat_meter.can_dodge():
				return "no_stamina"
		"ultimate":
			if not combat_meter.is_ultimate_available():
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


func _emit_input_report(action_type: String, sector: int, accepted: bool, buffered: bool, reason: String) -> void:
	var cooldowns: Dictionary = _build_input_cooldowns()
	EventBus.emit_signal(
		"combat_input_resolved",
		action_type,
		sector,
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
		"ultimate_ready": combat_meter.is_ultimate_available() if combat_meter != null else false
	}


func _try_dodge_radial(_target_dir: int) -> void:
	# In radial combat, dodge moves the player "through" the threat or to the center.
	# For now, we reuse _try_dodge logic but map the target_dir correctly.
	_try_dodge()

func setup(new_zone_manager: Node, new_combat_meter: Node) -> void:
	zone_manager = new_zone_manager
	combat_meter = new_combat_meter
	combat_enabled = true
	active_focus_sector = DEFAULT_FOCUS_SECTOR

	if not EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.connect(_on_projectile_fired)
	
	if not EventBus.combo_changed.is_connected(_on_combo_changed):
		EventBus.combo_changed.connect(_on_combo_changed)
	
	if not EventBus.song_beat_pulse.is_connected(_on_song_beat_pulse):
		EventBus.song_beat_pulse.connect(_on_song_beat_pulse)

	var enemies: Dictionary = zone_manager.get_all_enemies() if zone_manager else {}
	for id in enemies.keys():
		var projectile = zone_manager.get_projectile_by_id(id)
		if is_instance_valid(projectile):
			_connect_projectile_signals(projectile)

	_return_to_neutral_state(true)


func set_combat_enabled(enabled: bool) -> void:
	combat_enabled = enabled

	if not combat_enabled:
		action_lock_timer = 0.0
		current_action_state = "idle"
		_move_velocity = Vector2.ZERO
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


func set_combat_visual_rig(rig: Node) -> void:
	_combat_visual_rig = rig


func sync_presentation_facing_with_zone_manager(lm: Node) -> void:
	if _player_sprite == null or lm == null:
		return
	if current_action_state == "dodge":
		return # ABSOLUTE TIMING TRUTH: Dodge handles its own rotation/spin visual.
	if _combat_visual_rig == null or not is_instance_valid(_combat_visual_rig):
		return
	var lane: int = clampi(active_focus_sector, 0, lm.THREAT_COUNT - 1 if lm else 3)
	var to_threat: Vector2 = lm.get_threat_hit_zone_pos(lane) - lm.get_player_pos()
	if to_threat.length_squared() < 4.0:
		return
	var base_angle: float = to_threat.angle()
	var off: float = -PI * 0.5
	var lerp_w: float = 0.22
	off = _combat_visual_rig.get_player_visual_facing_angle_offset()
	lerp_w = _combat_visual_rig.get_player_facing_lerp_weight()
	var target: float = base_angle + off
	_player_sprite.rotation = lerp_angle(_player_sprite.rotation, target, lerp_w)


func _get_beat_quality() -> String:
	if _song_conductor == null or not _song_conductor.has_method("get_beat_quality"):
		return "off"
	return String(_song_conductor.get_beat_quality())


func _evaluate_projectile_timing_with_forgiveness(projectile: ThreatBase) -> String:
	# TIMING TRUTH: Priority to progress-based hit-zone alignment.
	# Target nodes (Projectile/Melee) check proximity to their Hit Zone (radius 110).
	var quality: String = projectile.evaluate_attack_timing()

	if quality == "miss" or quality.is_empty():
		# Fallback: Absolute physical contact forgiveness (for lunges or close-quarters)
		var base_proximity: String = projectile.evaluate_proximity_timing(global_position)
		if base_proximity != "miss":
			return base_proximity
		
		# Extra parry forgiveness from calculator
		var hit_zone_raw: Variant = projectile.get("hit_zone_pos")
		if typeof(hit_zone_raw) == TYPE_VECTOR2:
			var hit_zone_pos: Vector2 = hit_zone_raw
			var dist: float = projectile.global_position.distance_to(hit_zone_pos)
			var bonus: float = SOVEREIGN_DAMAGE_CALCULATOR.get_parry_forgiveness_radius_bonus()
			if dist <= COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS + bonus:
				return "good"
				
		return "miss"
		
	return quality


func _evaluate_parry_timing_with_forgiveness(projectile: ThreatBase) -> String:
	var quality: String = projectile.evaluate_parry_timing()

	if quality == "miss" or quality.is_empty():
		var base_proximity: String = projectile.evaluate_proximity_timing(global_position)
		if base_proximity != "miss":
			return base_proximity

		var hit_zone_raw: Variant = projectile.get("hit_zone_pos")
		if typeof(hit_zone_raw) == TYPE_VECTOR2:
			var hit_zone_pos: Vector2 = hit_zone_raw
			var dist: float = projectile.global_position.distance_to(hit_zone_pos)
			var bonus: float = SOVEREIGN_DAMAGE_CALCULATOR.get_parry_forgiveness_radius_bonus()
			if dist <= COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS + bonus + 10.0:
				return "good"

	return quality


func _resolve_nerve_parry_quality(projectile: ThreatBase) -> String:
	var quality: String = _evaluate_parry_timing_with_forgiveness(projectile)
	if quality == "perfect" or quality == "good" or quality == "already_resolved":
		return quality

	var physical_distance: float = projectile.global_position.distance_to(free_position)
	if physical_distance <= PARRY_PANIC_RADIUS:
		return "good"
	if physical_distance <= PARRY_CAPTURE_RADIUS * 0.72:
		return "good"

	var progress_value: float = projectile.progress
	if progress_value >= PARRY_PROGRESS_PERFECT_MIN and progress_value <= PARRY_PROGRESS_PERFECT_MAX:
		return "perfect"
	if progress_value >= PARRY_PROGRESS_GOOD_MIN and progress_value <= PARRY_PROGRESS_GOOD_MAX:
		return "good"
	if progress_value < PARRY_PROGRESS_GOOD_MIN:
		return "early"
	return "late"


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
	var base_scale: float = COMBAT_FEEL_CONTENT.get_slow_motion_scale(context_id)
	var base_duration: float = COMBAT_FEEL_CONTENT.get_slow_motion_duration(context_id)
	
	var preset: Dictionary = COMBAT_FEEL_CONTENT.get_slowmo_preset(context_id, {
		"scale": base_scale,
		"duration": base_duration
	})
	EventBus.emit_signal("slow_motion", float(preset.get("scale", base_scale)), float(preset.get("duration", base_duration)))


func _emit_mastery_context(event_id: String, sector: int, action_quality: String, beat_quality: String) -> void:
	EventBus.emit_signal("mastery_context_updated", {
		"event_id": event_id,
		"lane": sector,
		"action_quality": action_quality,
		"beat_quality": beat_quality,
		"phrase_window": _get_phrase_window(),
		"cadence_window": _get_cadence_window(),
		"timestamp": Time.get_ticks_msec() / 1000.0
	})


func _clear_mastery_context(event_id: String, sector: int) -> void:
	EventBus.emit_signal("mastery_context_updated", {
		"event_id": event_id,
		"lane": sector,
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


func _handle_free_movement(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("mod_left", "mod_right", "mod_up", "mod_down")
	var input_len: float = input_vector.length()

	if input_len > 0.0:
		var wish: Vector2 = input_vector / input_len * MOVEMENT_SPEED
		_move_velocity = _move_velocity.move_toward(wish, MOVE_ACCELERATION * delta)
	else:
		_move_velocity = _move_velocity.move_toward(Vector2.ZERO, MOVE_FRICTION * delta)

	free_position += _move_velocity * delta
	global_position = free_position

	if input_len > 0.0:
		# Update facing direction (continuous 360-degree aim)
		_facing_direction = input_vector / input_len
		if input_len > FOCUS_SNAP_THRESHOLD:
			var target_sector: int = _get_sector_from_vector(input_vector)
			_set_active_focus_sector(target_sector, false) # No ring feedback every frame


func _get_targets_in_cone() -> Dictionary:
	if zone_manager == null:
		return {"projectiles": [], "enemies": []}

	var found_projectiles: Array = []
	var found_enemies: Array = []
	
	# Action-RPG truth: melee starts narrow/short, then grows slowly through stats.
	var min_dot: float = 0.62
	var attack_range: float = SOVEREIGN_DAMAGE_CALCULATOR.get_attack_range()
	var lunge_range: float = SOVEREIGN_DAMAGE_CALCULATOR.get_predatory_lunge_range()
	var center_pos: Vector2 = zone_manager.get_player_pos()

	# 1. Projectiles in cone: Absolute Spatial Resolution
	var all_projectiles: Array = zone_manager.get_all_active_projectiles()
	
	for raw_threat in all_projectiles:
		var threat: ThreatBase = raw_threat as ThreatBase
		if threat != null and is_instance_valid(threat) and not threat.is_resolved:
			var to_target: Vector2 = threat.global_position - free_position
			var dist: float = to_target.length()
			if dist <= attack_range:
				var dot: float = _facing_direction.dot(to_target.normalized())
				if dot >= min_dot:
					var lane_id: int = threat.lane
					if lane_id == -1:
						lane_id = _get_sector_from_vector(threat.global_position - center_pos)
					found_projectiles.append({
						"ref": threat,
						"lane": lane_id,
						"distance": dist,
						"dot": dot,
						"pos": threat.global_position,
						"precision": _target_lock_score(dot, dist, attack_range),
						"progress": threat.progress
					})

	# 2. Enemies in honest lunge reach. Lock-on and damage share this same list.
	# Nearest-in-range is the target truth; facing affects precision, not eligibility.
	var enemies: Dictionary = zone_manager.get_all_enemies()
	for id in enemies.keys():
		var enemy = enemies[id]
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue

		var target_pos: Vector2 = zone_manager.get_enemy_pos(id)
		var to_target: Vector2 = target_pos - free_position
		var dist: float = to_target.length()
		
		if dist <= lunge_range:
			var dir_to_enemy: Vector2 = to_target.normalized()
			var dot: float = _facing_direction.dot(dir_to_enemy)
			var enemy_lane = int(enemy.get("lane", -1))
			if enemy_lane == -1:
				enemy_lane = _get_sector_from_vector(target_pos - center_pos)

			found_enemies.append({
				"ref": id,
				"lane": enemy_lane,
				"distance": dist,
				"dot": dot,
				"pos": target_pos,
				"precision": _target_lock_score(maxf(dot, 0.0), dist, lunge_range)
			})
						
	return {"projectiles": found_projectiles, "enemies": found_enemies}


func _get_parry_targets() -> Array:
	var candidates: Array = []
	if zone_manager == null:
		return candidates

	var all_projectiles: Array = zone_manager.get_all_active_projectiles()
	var center_pos: Vector2 = zone_manager.get_player_pos()
	var radius: float = PARRY_CAPTURE_RADIUS + SOVEREIGN_DAMAGE_CALCULATOR.get_parry_forgiveness_radius_bonus()
	for raw_threat in all_projectiles:
		var threat: ThreatBase = raw_threat as ThreatBase
		if threat == null or not is_instance_valid(threat) or threat.is_resolved or threat.is_reflected:
			continue

		var to_target: Vector2 = threat.global_position - free_position
		var dist: float = to_target.length()
		if dist > radius:
			continue

		var dot: float = 1.0
		if dist > 0.01:
			dot = _facing_direction.dot(to_target / dist)
		var panic_catch: bool = dist <= PARRY_PANIC_RADIUS
		if dot < PARRY_CAPTURE_CONE_DOT and not panic_catch:
			continue

		var lane_id: int = threat.lane
		if lane_id == -1:
			lane_id = _get_sector_from_vector(threat.global_position - center_pos)
		var urgency: float = clampf(float(threat.progress), 0.0, 1.25)
		candidates.append({
			"ref": threat,
			"lane": lane_id,
			"distance": dist,
			"dot": dot,
			"pos": threat.global_position,
			"precision": _target_lock_score(maxf(dot, 0.0), dist, radius) + urgency,
			"progress": threat.progress
		})
	return candidates


func _resolve_parry_miss_feedback() -> String:
	if zone_manager == null:
		return "NO THREAT CAUGHT"

	var closest_distance: float = INF
	var best_dot: float = -1.0
	var best_quality: String = "miss"
	for raw_threat in zone_manager.get_all_active_projectiles():
		var threat: ThreatBase = raw_threat as ThreatBase
		if threat == null or not is_instance_valid(threat) or threat.is_resolved or threat.is_reflected:
			continue
		var to_target: Vector2 = threat.global_position - free_position
		var dist: float = to_target.length()
		if dist < closest_distance:
			closest_distance = dist
			best_dot = _facing_direction.dot(to_target.normalized()) if dist > 0.01 else 1.0
			best_quality = _resolve_nerve_parry_quality(threat)

	if closest_distance == INF:
		return "NO THREAT CAUGHT"
	if closest_distance > PARRY_CAPTURE_RADIUS + SOVEREIGN_DAMAGE_CALCULATOR.get_parry_forgiveness_radius_bonus():
		return "OUT OF REACH"
	if best_dot < PARRY_CAPTURE_CONE_DOT:
		return "BAD ANGLE"
	if best_quality == "early":
		return "TOO EARLY"
	if best_quality == "late" or best_quality == "miss":
		return "TOO LATE"
	return "NO THREAT CAUGHT"


func _resolve_reflect_target_pos(enemy_id: int, projectile: ThreatBase) -> Vector2:
	if zone_manager == null:
		return projectile.global_position + _facing_direction * PARRY_CAPTURE_RADIUS

	var enemy: Dictionary = zone_manager.get_enemy_by_id(enemy_id)
	if not enemy.is_empty() and float(enemy.get("hp", 0.0)) > 0.0:
		return zone_manager.get_enemy_pos(enemy_id)

	var enemies: Dictionary = zone_manager.get_all_enemies()
	var best_pos: Vector2 = projectile.global_position - _facing_direction * PARRY_CAPTURE_RADIUS
	var best_dist_sq: float = INF
	for id in enemies.keys():
		var candidate: Dictionary = enemies.get(id, {})
		if float(candidate.get("hp", 0.0)) <= 0.0:
			continue
		var pos: Vector2 = zone_manager.get_enemy_pos(int(id))
		var dist_sq: float = projectile.global_position.distance_squared_to(pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_pos = pos
	return best_pos


func _target_lock_score(dot: float, distance: float, max_range: float) -> float:
	var range_score: float = 1.0 - clampf(distance / maxf(max_range, 1.0), 0.0, 1.0)
	return clampf(dot, 0.0, 1.0) * 1.4 + range_score * 0.45


func get_attack_lock_targets() -> Array:
	var targets: Dictionary = _get_targets_in_cone()
	var enemies: Array = targets.get("enemies", [])
	enemies.sort_custom(func(a, b):
		var dist_a: float = float(a.get("distance", 99999.0))
		var dist_b: float = float(b.get("distance", 99999.0))
		if not is_equal_approx(dist_a, dist_b):
			return dist_a < dist_b
		return float(a.get("precision", 0.0)) > float(b.get("precision", 0.0))
	)
	var cap: int = SOVEREIGN_DAMAGE_CALCULATOR.get_attack_target_cap()
	var result: Array = []
	for i in range(mini(cap, enemies.size())):
		var target: Dictionary = Dictionary(enemies[i]).duplicate(true)
		target["is_primary"] = (i == 0)
		result.append(target)
	return result

func get_lungeable_enemies() -> Array:
	return get_attack_lock_targets()


func get_primary_action_target() -> Dictionary:
	var targets: Dictionary = _get_targets_in_cone()
	var projectiles: Array = targets.get("projectiles", [])
	var enemies: Array = get_attack_lock_targets()
	
	var candidates: Array[Dictionary] = []
	for p in projectiles:
		var projectile: Variant = p.get("ref", null)
		var projectile_progress: float = float(p.get("progress", 0.0))
		candidates.append({
			"type": "projectile",
			"lane": int(p.get("lane", -1)),
			"ref": projectile,
			"pos": p.get("pos", Vector2.ZERO),
			"precision": float(p.get("precision", 0.0)) + clampf(projectile_progress - 0.72, 0.0, 0.28) * 1.15,
			"distance": float(p.get("distance", 0.0)),
			"progress": projectile_progress,
			"enemy_id": int(projectile.get("enemy_id")) if is_instance_valid(projectile) else -1
		})
	for e in enemies:
		candidates.append({
			"type": "enemy",
			"id": int(e.get("ref", -1)),
			"lane": int(e.get("lane", -1)),
			"pos": e.get("pos", Vector2.ZERO),
			"precision": float(e.get("precision", 0.0)),
			"distance": float(e.get("distance", 0.0))
		})
	if candidates.is_empty():
		return {}

	candidates.sort_custom(func(a, b): return float(a.get("precision", 0.0)) > float(b.get("precision", 0.0)))
	return candidates[0]


func _get_sector_from_vector(dir: Vector2) -> int:
	if dir.length_squared() < 0.01:
		return active_focus_sector

	var angle: float = dir.angle() # -PI to PI
	# Map angle to 0..7 index, where 0 is North (-PI/2)
	# Sector size is TAU/8 (45 degrees)
	var sector_size: float = TAU / 8.0
	# Offset so sector 0 is centered on -PI/2
	var norm_angle: float = fposmod(angle + PI/2.0 + sector_size/2.0, TAU)
	return int(floor(norm_angle / sector_size)) % 8
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
	var nerve_mult: float = SOVEREIGN_DAMAGE_CALCULATOR.get_action_recovery_mult()
	action_lock_timer = max(duration * nerve_mult, 0.0)
	current_action_state = state
	
	# Soulslike i-frames: handle invincibility window during the initial recovery burst.
	if state == "dodge" or state == "timed_dodge":
		var beat: String = _get_beat_quality()
		dodge_invuln_timer = DODGE_IFRAME_WINDOW_ON_BEAT if beat == "perfect" else DODGE_IFRAME_WINDOW


func _try_attack(targets: Dictionary) -> void:
	var current_aim: int = _get_target_direction()
	var combo_mult: float = combat_meter.damage_multiplier() if combat_meter else 1.0

	if parry_followup_active:
		# Parry followup still focuses on one lane's direction but hits the cone
		_fire_parry_followup(combo_mult, targets)
		return

	var projectiles: Array = targets.get("projectiles", [])
	var enemies: Array = get_attack_lock_targets()

	if not projectiles.is_empty():
		# Timed Attack Logic: Find the best quality projectile in the cone.
		# If multiple exist, prioritize the strongest spatial lock.
		projectiles.sort_custom(func(a, b): return float(a.get("precision", 0.0)) > float(b.get("precision", 0.0)))
		var p_data = projectiles[0]
		_play_attack_state(current_aim, p_data)
		var projectile: ThreatBase = p_data.get("ref") as ThreatBase
		var quality: String = _evaluate_projectile_timing_with_forgiveness(projectile)
		
		match quality:
			"good", "perfect":
				_resolve_timed_attack(projectile, combo_mult, quality)
				# Also cleave other enemies in the cone if it's a good/perfect hit
				for e_data in enemies:
					# Apply a portion of the timed damage to other enemies in range
					_idle_attack_on_target(e_data, combo_mult * 1.5) 
				return
			"early":
				_resolve_early_attack(current_aim)
				return
			"late":
				_resolve_late_attack(projectile, current_aim)
				return

	# If no projectiles handled, do a spatial sweep on all enemies in the cone
	if not enemies.is_empty():
		_play_attack_state(current_aim, enemies[0])
		_play_predatory_lunge_to_target(enemies[0])
		for e_data in enemies:
			_idle_attack_on_target(e_data, combo_mult)
	else:
		_play_attack_state(current_aim)
		_idle_attack_on_target({}, combo_mult)


func _try_parry(_targets: Dictionary) -> void:
	var current_aim: int = _get_target_direction()
	_play_parry_state(current_aim)
	
	var projectiles: Array = _get_parry_targets()

	if projectiles.is_empty():
		combat_meter.record_bad_timing()
		_clear_mastery_context("failed_parry", current_aim)
		_flash_sprite_color(Color(0.82, 0.24, 0.28, 1.0), 0.12)
		EventBus.emit_signal("proc_feedback_requested", _resolve_parry_miss_feedback(), Color(1.0, 0.45, 0.45, 1.0))
		EventBus.emit_signal("screen_flash", Color(1.0, 0.2, 0.2, 0.06), 0.04)
		_lock_action(FAILED_PARRY_RECOVERY, "failed_parry")
		return

	if not combat_meter.can_parry():
		EventBus.emit_signal("player_no_stamina")
		return

	if not combat_meter.spend_stamina_for_parry():
		return

	# Find the best projectile to parry in the cone
	projectiles.sort_custom(func(a, b): return float(a.get("precision", 0.0)) > float(b.get("precision", 0.0)))
	var p_data = projectiles[0]
	var projectile: ThreatBase = p_data.get("ref") as ThreatBase
	var quality: String = _resolve_nerve_parry_quality(projectile)
	var target_sector: int = int(p_data.get("lane", -1))

	if quality != "good" and quality != "perfect":
		combat_meter.record_bad_timing()
		_clear_mastery_context("failed_parry", target_sector)
		var miss_text: String = "TOO EARLY" if quality == "early" else "TOO LATE"
		EventBus.emit_signal("proc_feedback_requested", miss_text, Color(1.0, 0.45, 0.45, 1.0))
		EventBus.emit_signal("screen_flash", Color(1.0, 0.2, 0.2, 0.08), 0.05)
		_lock_action(FAILED_PARRY_RECOVERY, "failed_parry")
		return

	var beat: String = _get_beat_quality()
	var combo_mult: float = combat_meter.damage_multiplier()
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
	if quality == "perfect":
		var stamina_gain: float = RunGrowth.get_mutation_bonus("stamina_on_perfect_parry")
		if stamina_gain > 0.0:
			combat_meter.restore_stamina(stamina_gain)
			RunGrowth.consume_mutation_charges("stamina_on_perfect_parry", 1)
			
		var expose_all: float = RunGrowth.get_mutation_bonus("expose_all_on_perfect_parry")
		if expose_all > 0.0:
			var enemies = zone_manager.get_all_enemies()
			for id in enemies.keys():
				zone_manager.apply_status_by_id(id, "expose", {"duration": expose_all})
			RunGrowth.consume_mutation_charges("expose_all_on_perfect_parry", 1)

	var pale_all: float = RunGrowth.get_mutation_bonus("pale_on_parry")
	if pale_all > 0.0:
		var enemies = zone_manager.get_all_enemies()
		for id in enemies.keys():
			zone_manager.apply_status_by_id(id, "pale", {})
		RunGrowth.consume_mutation_charges("pale_on_parry", 1)

	var reflect_damage: float = SOVEREIGN_DAMAGE_CALCULATOR.get_parry_reflect_damage(
		projectile.damage,
		reflect_mult,
		combo_mult,
		_sum_bond_passive("parry_reflect_mult")
	)
	var enemy_id: int = projectile.enemy_id
	var reflect_target_pos: Vector2 = _resolve_reflect_target_pos(enemy_id, projectile)

	projectile.reflect_to_enemy_at(reflect_damage, reflect_target_pos)
	combat_meter.record_parry(quality)
	combat_meter.record_phrase_action(quality)
	_show_parry_image(quality)
	_emit_mastery_context("parry", target_sector, quality, beat)

	# Consolidate parry/counter into one flow
	_trigger_parry_counter_warp(enemy_id, target_sector, reflect_damage, quality)

	EventBus.emit_signal("player_parried", target_sector, quality, reflect_damage, _facing_direction)

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


const DODGE_DISTANCE: float = 165.0

func _try_dodge() -> void:
	if not combat_meter.spend_stamina_for_dodge():
		return

	# Hunting Field Dodge: Roll in the direction of movement.
	# Use current input if available for max responsiveness, fallback to last pressed.
	var input_vec: Vector2 = Input.get_vector("mod_left", "mod_right", "mod_up", "mod_down")
	var dodge_dir_vec: Vector2 = input_vec.normalized() if input_vec.length() > 0.0 else _facing_direction
	
	var to_pos: Vector2 = global_position + dodge_dir_vec * DODGE_DISTANCE
	
	# Derive sector index for visual/signal compatibility
	var dodge_sector: int = _get_sector_from_vector(dodge_dir_vec)

	_play_dodge_state_radial(to_pos)

	# I-frames and masteries.
	var beat: String = _get_beat_quality()
	combat_meter.record_dodge()
	combat_meter.record_phrase_action("good")
	_emit_mastery_context("dodge", dodge_sector, "good", beat)
	EventBus.emit_signal("player_dodged", -1, dodge_sector, _facing_direction)

	if beat == "perfect" or beat == "good":
		_flash_sprite_color(Color(0.55, 0.82, 1.0, 1.0), 0.10)
		EventBus.emit_signal("screen_flash", Color(0.55, 0.75, 1.0, 0.10), 0.06)
		_lock_action(DODGE_GOOD_RECOVERY, "dodge")
	else:
		EventBus.emit_signal("screen_flash", Color(0.65, 0.85, 1.0, 0.06), 0.05)
		_lock_action(DODGE_RECOVERY, "dodge")


func _try_support_activation(target_sector: int) -> void:
	# Active Creature Support: Trigger the bonded creature's support move manually.
	# This move consumes support charge (handled in RunGrowth).
	var beat: String = _get_beat_quality()
	EventBus.support_manual_activation_requested.emit(target_sector, beat)
	
	if beat == "perfect":
		_flash_sprite_color(Color(1.0, 1.0, 1.0, 1.0), 0.12)
		_lock_action(PERFECT_ATTACK_RECOVERY, "support")
	else:
		_lock_action(TIMED_ATTACK_RECOVERY, "support")

func _play_dodge_state_radial(target_pos: Vector2) -> void:
	_apply_sprite_facing()
	_spawn_dodge_afterimage()
	_play_sprite_pose(DODGE_SPRITE_POSITION, DODGE_SPRITE_SCALE, 0.10)
	
	# Predatory slip: readable displacement without freezing the song-run flow.
	var vis_node: CanvasItem = (_player_sprite as CanvasItem) if _player_sprite != null else (sprite as CanvasItem)
	
	_play_world_motion(target_pos, DODGE_PUSH_TIME)
	
	if is_inside_tree():
		CombatFeedbackDirector.trigger_shake(3.0, 0.07)
	
	var dodge_tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	
	dodge_tween.tween_property(vis_node, "rotation", vis_node.rotation + PI * 0.42, DODGE_PUSH_TIME)
	
	var roll_scale = NEUTRAL_SPRITE_SCALE * (PLAYER_SPRITE_SCALE_BASE if _player_sprite != null else 1.0) * 0.82
	dodge_tween.tween_property(vis_node, "scale", roll_scale, DODGE_PUSH_TIME * 0.35).set_trans(Tween.TRANS_SINE)
	dodge_tween.chain().tween_property(vis_node, "scale", NEUTRAL_SPRITE_SCALE * (PLAYER_SPRITE_SCALE_BASE if _player_sprite != null else 1.0), DODGE_PUSH_TIME * 0.65).set_trans(Tween.TRANS_BACK)
	
	# Reflex Flare: Over-brightened burst at start (High-contrast Manga)
	var flare_col = Color(2.0, 2.5, 3.0, 1.0) 
	var base_col = Color.WHITE if _player_sprite != null else Color(0.25, 0.55, 0.95, 1.0)
	var prop: String = "modulate" if _player_sprite != null else "color"
	
	dodge_tween.tween_property(vis_node, prop, flare_col, 0.05)
	
	var return_tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return_tween.tween_interval(0.12)
	return_tween.tween_property(vis_node, prop, base_col, 0.22)


func _try_ultimate() -> void:
	if not combat_meter.is_ultimate_available():
		return

	_show_player_image(_attack_tex, ULTIMATE_RECOVERY)
	_play_sprite_pose(ATTACK_SPRITE_POSITION, ATTACK_SPRITE_SCALE * 1.5, 0.4) # Dramatic pose
	_play_world_motion(_action_world_position(ATTACK_WORLD_X_OFFSET * 2.0), 0.1)

	var beat: String = _get_beat_quality()
	var multiplier: float = combat_meter.consume_ultimate()
	if multiplier <= 0.0:
		return

	var total_damage: float = SOVEREIGN_DAMAGE_CALCULATOR.get_ultimate_damage(multiplier, beat, _sum_bond_passive("damage_on_ultimate"))

	var all_enemies: Dictionary = zone_manager.get_all_enemies()
	for id in all_enemies.keys():
		zone_manager.damage_enemy_by_id(id, total_damage)

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


func _idle_attack_on_target(target_data: Dictionary, combo_mult: float) -> void:
	var target_sector: int = int(target_data.get("lane", -1))
	var idle_damage: float = SOVEREIGN_DAMAGE_CALCULATOR.get_idle_attack_damage(combo_mult)
	var enemy_id: int = int(target_data.get("ref", -1))
	
	if enemy_id != -1:
		zone_manager.damage_enemy_by_id(enemy_id, idle_damage)
		# Trigger spectacular feedback using the newly optimized runtime
		var impact_profile: Dictionary = {
			"shake_intensity": 1.15,
			"shake_duration": 0.08,
			"hitstop_scale": 0.85,
			"hitstop_duration": 0.04,
			"ring_width": 2.2,
			"burst_color": Color(0.9, 0.9, 1.0, 0.75),
			"flash_color": Color(1.0, 1.0, 1.0, 0.04),
			"flash_duration": 0.03,
			"sfx_cue": "timed_hit"
		}
		# We emit a request for the presentation controller to handle this spectacular hit
		EventBus.emit_signal("impact_burst_requested", impact_profile, target_sector, enemy_id)
		
	combat_meter.record_attack()
	_clear_mastery_context("idle_attack", target_sector)
	EventBus.emit_signal("player_attacked", target_sector, idle_damage, false, _facing_direction)

	_lock_action(BASIC_ATTACK_RECOVERY, "idle_attack")


func _play_predatory_lunge_to_target(target_data: Dictionary) -> void:
	var target_pos: Vector2 = Vector2(target_data.get("pos", Vector2.ZERO))
	if target_pos.is_zero_approx():
		return
	var to_target: Vector2 = target_pos - free_position
	var distance: float = to_target.length()
	if distance < PREDATORY_LUNGE_MIN_DISTANCE:
		return
	var lunge_dir: Vector2 = to_target / distance
	var lunge_distance: float = minf(distance - PREDATORY_LUNGE_STANDOFF, SOVEREIGN_DAMAGE_CALCULATOR.get_predatory_lunge_range())
	if lunge_distance <= 0.0:
		return
	_facing_direction = lunge_dir
	_play_world_motion(free_position + lunge_dir * lunge_distance, PREDATORY_LUNGE_PUSH_TIME)


func _resolve_timed_attack(projectile: ThreatBase, combo_mult: float, quality: String) -> void:
	var beat: String = _get_beat_quality()
	var phrase_bonus: float = combat_meter.get_phrase_bonus()

	# Growth multiplier: aggression adds flat % to all timed hits;
	# cadence adds additional flat % to good and perfect hits only.
	# Resolve through RunGrowth's public effect bridge so legacy compatibility
	# and live surges share one authoritative source.
	var growth_mult: float = 1.0
	var aggr_effect: Dictionary = {}
	aggr_effect = Dictionary(RunGrowth.get_runtime_effect("timed_attack_bonus_damage"))

	growth_mult += float(aggr_effect.get("value", 0.0))

	if quality == "good" or quality == "perfect":
		var cad_effect: Dictionary = {}
		cad_effect = Dictionary(RunGrowth.get_runtime_effect("good_timed_bonus_damage"))
		growth_mult += float(cad_effect.get("value", 0.0))

	# Mutation Pass: Timed Damage
	var mutation_bonus: float = 0.0
	mutation_bonus = RunGrowth.get_mutation_bonus("timed_damage_flat", {"quality": quality})
	if mutation_bonus > 0.0:
		RunGrowth.consume_mutation_charges("timed_damage_flat", 1, {"quality": quality})

	var timed_damage: float = SOVEREIGN_DAMAGE_CALCULATOR.get_timed_attack_damage(
		float(projectile.get("damage")),
		combo_mult,
		phrase_bonus,
		quality,
		beat,
		growth_mult,
		_sum_bond_passive("timed_damage_flat"),
		mutation_bonus
	)
	var recovery: float = TIMED_ATTACK_RECOVERY

	var target_sector: int = projectile.lane
	var target_enemy_id: int = projectile.enemy_id

	projectile.resolve("attack_%s" % quality)
	
	if target_enemy_id != -1:
		zone_manager.damage_enemy_by_id(target_enemy_id, timed_damage)

	combat_meter.record_timed_attack()
	combat_meter.record_phrase_action(quality)
	_emit_mastery_context("timed_attack", target_sector, quality, beat)

	EventBus.emit_signal("player_attacked", target_sector, timed_damage, true, _facing_direction)
	EventBus.emit_signal("timed_attack_resolved", target_sector, quality, timed_damage, target_enemy_id)

	if quality == "perfect":
		# Visual flash handled by CombatFeedbackDirector
		_flash_sprite_color(Color(1.0, 1.0, 1.2, 1.0), 0.12)
		
		recovery = PERFECT_ATTACK_RECOVERY
		if beat == "perfect":
			_emit_slowmo_context("timed_attack_perfect_beat_perfect")
		else:
			_emit_slowmo_context("timed_attack_perfect_other")
	else:
		_flash_sprite_color(Color(0.95, 0.62, 0.18, 1.0), 0.10)
		_emit_slowmo_context("timed_attack_good")

	_grant_chain_bypass()
	_lock_action(recovery, "timed_attack")


func _resolve_early_attack(target_sector: int) -> void:
	var armor_chance: float = clamp(GameState.stat_adaptability - 1.0, 0.0, 0.85)
	if randf() < armor_chance:
		# Combo Armor triggered: do not call record_bad_timing
		EventBus.emit_signal("proc_feedback_requested", "FORM ARMOR", Color(0.42, 0.85, 0.72, 1.0))
	else:
		combat_meter.record_bad_timing()
		
	_clear_mastery_context("early_attack", target_sector)
	EventBus.emit_signal("attack_timing_early_resolved", target_sector)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.15, 0.15, 0.05), 0.04)
	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(EARLY_ATTACK_RECOVERY, "early_attack")


func _resolve_late_attack(projectile: ThreatBase, target_sector: int) -> void:
	# Late attack means the projectile has already hit or is very close.
	# We still allow it to resolve but with a heavy punish.
	var combo_mult: float = combat_meter.damage_multiplier()
	var punish_damage: float = SOVEREIGN_DAMAGE_CALCULATOR.get_late_attack_damage(combo_mult)
	
	projectile.resolve("attack_late")

	var target_enemy_id: int = projectile.enemy_id
	
	if target_enemy_id != -1:
		zone_manager.damage_enemy_by_id(target_enemy_id, punish_damage)

	var armor_chance: float = clamp(GameState.stat_adaptability - 1.0, 0.0, 0.85)
	if randf() < armor_chance:
		EventBus.emit_signal("proc_feedback_requested", "FORM ARMOR", Color(0.42, 0.85, 0.72, 1.0))
	else:
		combat_meter.record_bad_timing()

	_clear_mastery_context("late_attack", target_sector)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.15, 0.15, 0.10), 0.06)
	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(LATE_ATTACK_RECOVERY, "late_attack")


func _fire_parry_followup(combo_mult: float, targets: Dictionary) -> void:
	var target_sector: int = _get_target_direction()

	var followup_damage: float = max(parry_followup_damage, GameState.get_attack_damage()) * combo_mult
	var enemies: Array = get_attack_lock_targets()
	var primary_target: Dictionary = enemies[0] if not enemies.is_empty() else {}
	_play_attack_state(target_sector, primary_target)
	
	if not enemies.is_empty():
		for e_data in enemies:
			zone_manager.damage_enemy_by_id(int(e_data.get("ref", -1)), followup_damage)
		
	combat_meter.record_lane_read()
	EventBus.emit_signal("player_attacked", target_sector, followup_damage, true)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.65, 0.08), 0.05)
	_emit_slowmo_context("parry_followup")

	parry_followup_active = false
	parry_followup_timer = 0.0
	parry_followup_damage = 0.0

	_grant_chain_bypass()
	_lock_action(TIMED_ATTACK_RECOVERY, "parry_followup")


func _trigger_parry_counter_warp(enemy_id: int, target_sector: int, damage: float, quality: String) -> void:
	# Automated physical counter-strike on projectile parry.
	# Sequencing: Parry Impact -> Short Freeze (Hit-Stop) -> Warp Strike.
	
	var is_perfect: bool = (quality == "perfect")
	var preset_id: String = "counter_warp_perfect" if is_perfect else "counter_warp_good"
	
	_emit_slowmo_context(preset_id)
	EventBus.emit_signal("screen_flash", Color(1.0, 1.0, 1.0, 0.20 if is_perfect else 0.12), 0.05)

	# 2. Sequential Strike: Execute the warp-attack after a tiny beat.
	var warp_timer := get_tree().create_timer(0.06)
	warp_timer.timeout.connect(func():
		_play_counter_warp_state()
		
		# SFX: Dash/Warp sound cue.
		EventBus.emit_signal("play_sfx", "player_warp")
		
		# Ghosting: Flash a bright cyan/white tint during the dash.
		_flash_sprite_color(Color(1.5, 2.0, 2.0, 1.0), 0.12)
		
		# Resolve the physical strike.
		if enemy_id != -1:
			zone_manager.damage_enemy_by_id(enemy_id, damage)
		
		EventBus.emit_signal("player_attacked", target_sector, damage, true)
		
		# Feedback: Strong punch for the actual hit resolution.
		EventBus.emit_signal("screen_shake", 5.0 if is_perfect else 3.0, 0.12 if is_perfect else 0.08)
		EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.70, 0.15 if is_perfect else 0.10), 0.06)
	)


func _play_counter_warp_state() -> void:
	# Radial warp: uses a fixed spatial reach distance based on Action-RPG aim,
	# rather than calculating distance between hardcoded lane spawn/hit zones.
	var reach_dist: float = SOVEREIGN_DAMAGE_CALCULATOR.get_attack_range() * 0.85

	_show_attack_image()
	_play_sprite_pose(ATTACK_SPRITE_POSITION, ATTACK_SPRITE_SCALE, 0.18)
	_play_world_motion(_action_world_position(reach_dist), 0.05)


func _take_damage(amount: float, source_sector: int) -> void:
	if dodge_invuln_timer > 0.0:
		EventBus.emit_signal("proc_feedback_requested", "DODGED", Color(0.24, 0.78, 1.0, 1.0))
		return

	_play_hit_state(source_sector)
	_show_hurt_image()

	var surge_dr: float = 0.0
	var effect: Dictionary = Dictionary(RunGrowth.get_runtime_effect("guard_damage_reduction"))
	surge_dr = float(effect.get("value", 0.0))

	# Mutation Pass: Damage Taken
	var invuln: float = RunGrowth.get_mutation_bonus("invuln_hits")
	if invuln > 0.0:
		amount = 0.0
		RunGrowth.consume_mutation_charges("invuln_hits", 1)
	else:
		var mend: float = RunGrowth.get_mutation_bonus("heal_on_hit_taken")
		if mend > 0.0:
			var healed: float = GameState.heal_player(mend)
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			RunGrowth.consume_mutation_charges("heal_on_hit_taken", 1)

	amount = SOVEREIGN_DAMAGE_CALCULATOR.get_incoming_damage_after_reduction(
		amount,
		_get_damage_reduction(),
		surge_dr
	)
	
	# Apply Blood-Ember Vulnerability
	amount *= GameState.get_player_bleed_damage_mult()

	GameState.player_hp = max(GameState.player_hp - amount, 0.0)
	_flash_sprite_color(Color(1.0, 0.25, 0.25, 1.0), 0.18)
	combat_meter.break_phrase()
	_clear_mastery_context("damage_taken", source_sector)
	EventBus.emit_signal("player_took_damage", amount, source_sector)

	if GameState.player_hp <= 0.0:
		EventBus.emit_signal("player_died")
		EventBus.emit_signal("combat_ended", false)


func _sum_bond_passive(passive_type: String) -> float:
	# Bond-trait expression: bonded creature passives of the given type sum, each scaled by bond level mult.
	var total: float = 0.0
	for creature in GameState.roster:
		var passive: Dictionary = creature.get("bond_passive", {})
		if passive.get("type", "") == passive_type:
			var mult: float = GameState.get_bond_level_mult(int(creature.get("bond_level", 1)))
			total += float(passive.get("value", 0.0)) * mult
	return total


func _get_damage_reduction() -> float:
	# Live-run defense + bonded damage_reduction_pct passives, capped at COMBINED_DAMAGE_REDUCTION_CAP.
	var total: float = GameState.get_defense_damage_reduction() + _sum_bond_passive("damage_reduction_pct")
	return min(total, GameState.COMBINED_DAMAGE_REDUCTION_CAP)


func _neutral_world_position() -> Vector2:
	return free_position


func _action_world_position(reach_distance: float) -> Vector2:
	# SPATIAL PURITY: Lunges follow the continuous 360-degree facing direction,
	# rather than snapping to the centers of the visual lane sectors.
	return free_position + _facing_direction * reach_distance

func _setup_player_sprite() -> void:
	# Load textures; fall back gracefully if any file is missing.
	if ResourceLoader.exists(PLAYER_IDLE_PATH):
		_idle_tex = load(PLAYER_IDLE_PATH) as Texture2D
	if ResourceLoader.exists(PLAYER_ATTACK_PATH):
		_attack_tex = load(PLAYER_ATTACK_PATH) as Texture2D
	if ResourceLoader.exists(PLAYER_ATKEFFECT_PATH):
		_atkeffect_tex = load(PLAYER_ATKEFFECT_PATH) as Texture2D
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

	# Setup the Attack Effect (Energy Sword)
	if _atkeffect_tex != null:
		_atk_effect_sprite = Sprite2D.new()
		_atk_effect_sprite.name = "AttackEffect"
		_atk_effect_sprite.texture = _atkeffect_tex
		_atk_effect_sprite.visible = false
		_atk_effect_sprite.modulate.a = 0.0
		# Align downward asset (+90 deg to face RIGHT by default)
		_atk_effect_sprite.rotation = PI / 2.0 
		# Scale to match the fair stat-scaled attack range.
		var base_scale: float = SOVEREIGN_DAMAGE_CALCULATOR.get_attack_range() / _atkeffect_tex.get_height()
		_atk_effect_sprite.scale = Vector2(base_scale, base_scale)
		# Pivot at the hilt
		_atk_effect_sprite.offset = Vector2(0, _atkeffect_tex.get_height() / 2.0)
		# Parented to self (root) for stability — no coordinate flipping
		add_child(_atk_effect_sprite)

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


func _apply_sprite_facing() -> void:
	if _player_sprite == null:
		return
	if _combat_visual_rig != null and is_instance_valid(_combat_visual_rig):
		return

	# Use raw facing vector for stable Action-RPG rotation/flipping.
	if _facing_direction.x > 0.05:
		_player_sprite.flip_h = false  # Face Right
	elif _facing_direction.x < -0.05:
		_player_sprite.flip_h = true   # Face Left
	# If neutral/vertical, maintain last flip state.


func _setup_ground_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.z_index = -1
	var pts := PackedVector2Array()
	var rx := 8.0 # Reduced from 14
	var ry := 2.2 # Reduced from 3.5
	for i in range(24):
		var a := (i / 24.0) * TAU
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	shadow.polygon = pts
	shadow.color = Color(0.0, 0.0, 0.0, 0.28)
	shadow.position = Vector2(0.0, 3.0) # Reduced from 6.0
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
	var vis_node: CanvasItem = (_player_sprite as CanvasItem) if _player_sprite != null else (sprite as CanvasItem)
	var neutral_s: Vector2 = NEUTRAL_SPRITE_SCALE * (PLAYER_SPRITE_SCALE_BASE if _player_sprite != null else 1.0)

	if immediate:
		# Note: We keep global_position sync for immediate resets (start/restart)
		global_position = _neutral_world_position()
		_move_velocity = Vector2.ZERO
		vis_node.position = NEUTRAL_SPRITE_POSITION
		vis_node.scale = neutral_s
		return

	_play_sprite_pose(NEUTRAL_SPRITE_POSITION, NEUTRAL_SPRITE_SCALE, 0.06)
	# World motion snap-back removed to allow player to own their position.


func _play_attack_state(_target_sector: int, target_data: Dictionary = {}) -> void:
	_apply_sprite_facing()
	_show_attack_image()
	_pulse_attack_effect(target_data)
	_play_sprite_pose(ATTACK_SPRITE_POSITION, ATTACK_SPRITE_SCALE, 0.08)
	_play_world_motion(_action_world_position(ATTACK_WORLD_X_OFFSET), 0.04)


func _pulse_attack_effect(target_data: Dictionary = {}) -> void:
	if _atk_effect_sprite == null or _atkeffect_tex == null:
		return

	if _atk_effect_pulse_tween != null:
		_atk_effect_pulse_tween.kill()

	var target_pos: Vector2 = Vector2(target_data.get("pos", free_position + _facing_direction * SOVEREIGN_DAMAGE_CALCULATOR.get_attack_range()))
	var to_target: Vector2 = target_pos - free_position
	var aim_dir: Vector2 = _facing_direction
	if to_target.length_squared() > 4.0:
		aim_dir = to_target.normalized()
		_facing_direction = aim_dir
	
	var visible_length: float = clampf(
		minf(to_target.length(), SOVEREIGN_DAMAGE_CALCULATOR.get_attack_range()),
		ATTACK_EFFECT_MIN_LENGTH,
		ATTACK_EFFECT_MAX_LENGTH
	)
	var texture_height: float = maxf(float(_atkeffect_tex.get_height()), 1.0)
	var length_scale: float = visible_length / texture_height
	var slash_pos: Vector2 = NEUTRAL_SPRITE_POSITION + aim_dir * (visible_length * 0.46)

	_atk_effect_sprite.visible = true
	_atk_effect_sprite.position = slash_pos
	_atk_effect_sprite.rotation = aim_dir.angle() + PI / 2.0
	_atk_effect_sprite.modulate = Color(1.0, 0.93, 0.82, 0.0)
	_atk_effect_sprite.scale = Vector2(length_scale * 0.72, length_scale * 0.22)

	_atk_effect_pulse_tween = create_tween()
	_atk_effect_pulse_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	
	_atk_effect_pulse_tween.tween_property(_atk_effect_sprite, "scale", Vector2(length_scale * 1.08, length_scale * 0.42), 0.055)
	_atk_effect_pulse_tween.parallel().tween_property(_atk_effect_sprite, "modulate", Color(1.25, 1.05, 0.86, 0.95), 0.045)
	_atk_effect_pulse_tween.parallel().tween_property(_atk_effect_sprite, "position", slash_pos + aim_dir * 7.0, 0.055)
	
	_atk_effect_pulse_tween.tween_property(_atk_effect_sprite, "modulate", Color(0.95, 0.12, 0.06, 0.0), 0.16)
	_atk_effect_pulse_tween.parallel().tween_property(_atk_effect_sprite, "scale", Vector2(length_scale * 1.22, length_scale * 0.16), 0.16)
	_atk_effect_pulse_tween.parallel().tween_property(_atk_effect_sprite, "position", slash_pos + aim_dir * 18.0, 0.16)
	
	_atk_effect_pulse_tween.tween_callback(func() -> void:
		_atk_effect_sprite.visible = false
	)

	_spawn_attack_impact_sparks(aim_dir, visible_length)


func _spawn_attack_impact_sparks(aim_dir: Vector2, visible_length: float) -> void:
	var spark_count: int = 5
	for i in range(spark_count):
		var spark := Line2D.new()
		spark.width = 1.2 if i < 3 else 0.8
		spark.default_color = Color(1.0, 0.16, 0.06, 0.72) if i < 3 else Color(0.96, 0.92, 0.84, 0.68)
		spark.z_index = 5
		var side: Vector2 = aim_dir.rotated(PI * 0.5)
		var base: Vector2 = NEUTRAL_SPRITE_POSITION + aim_dir * (visible_length * randf_range(0.42, 0.92))
		var jitter: Vector2 = side * randf_range(-8.0, 8.0)
		var slash_dir: Vector2 = aim_dir.rotated(randf_range(-0.45, 0.45))
		spark.points = PackedVector2Array([
			base + jitter,
			base + jitter + slash_dir * randf_range(8.0, 18.0)
		])
		add_child(spark)
		var tween := spark.create_tween()
		tween.tween_property(spark, "default_color:a", 0.0, 0.12)
		tween.parallel().tween_property(spark, "width", 0.0, 0.12)
		tween.tween_callback(spark.queue_free)


func _play_parry_state(_target_sector: int) -> void:
	_apply_sprite_facing()
	_play_sprite_pose(PARRY_SPRITE_POSITION, PARRY_SPRITE_SCALE, 0.10)
	_play_world_motion(_action_world_position(PARRY_WORLD_X_OFFSET), 0.04)


func _play_dodge_state(_target_sector: int) -> void:
	_spawn_dodge_afterimage()
	_play_sprite_pose(DODGE_SPRITE_POSITION, DODGE_SPRITE_SCALE, 0.10)
	_play_world_motion(_action_world_position(DODGE_WORLD_X_OFFSET), 0.05)


func _play_hit_state(_target_sector: int) -> void:
	_apply_sprite_facing()
	_play_sprite_pose(HIT_SPRITE_POSITION, HIT_SPRITE_SCALE, 0.12)
	_play_world_motion(_action_world_position(HIT_WORLD_X_OFFSET), 0.02)


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


func _play_world_motion(action_position: Vector2, push_time: float) -> void:
	if _world_motion_tween != null:
		_world_motion_tween.kill()

	movement_enabled = false # Disable free movement during the lunge "push"

	_world_motion_tween = create_tween()
	if push_time > 0.0:
		_world_motion_tween.tween_property(self, "global_position", action_position, push_time) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	else:
		global_position = action_position

	# Permissive Recovery: Once the push is finished, the player owns their new position.
	_world_motion_tween.tween_callback(func() -> void:
		free_position = global_position
		_move_velocity = Vector2.ZERO
		movement_enabled = true 
	)


func _on_projectile_fired(_lane: int, enemy_id: int) -> void:
	var projectile = zone_manager.get_projectile_by_id(enemy_id)
	if is_instance_valid(projectile):
		_connect_projectile_signals(projectile)


func _connect_projectile_signals(projectile) -> void:
	if not is_instance_valid(projectile):
		return

	if not projectile.player_contact.is_connected(_on_projectile_player_contact):
		projectile.player_contact.connect(_on_projectile_player_contact)


func _on_projectile_player_contact(projectile: Node) -> void:
	if not is_instance_valid(projectile):
		return
	var threat: ThreatBase = projectile as ThreatBase
	if threat == null or threat.is_resolved:
		return

	if dodge_invuln_timer > 0.0:
		threat.resolve("dodged_through")
		EventBus.emit_signal("screen_flash", Color(0.50, 0.70, 1.0, 0.04), 0.03)
		return

	if combat_enabled:
		_take_damage(threat.damage, threat.lane)

		# Blood-Ember: Projectiles from Ashclaw apply Bleed to player
		if threat.enemy_id != -1 and zone_manager != null:
			var enemy: Dictionary = zone_manager.get_enemy_by_id(threat.enemy_id)
			var species_id: String = String(enemy.get("species_id", ""))
			if species_id == "ashclaw":
				GameState.apply_player_bleed()


func _check_input_buffer() -> void:
	if _input_buffer.is_empty():
		return
	
	var action: String = String(_input_buffer.get("action", ""))
	var time_left: float = float(_input_buffer.get("time_left", 0.0))
	
	_input_buffer.clear()
	
	if time_left > 0.0:
		_handle_combat_action(action)


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
	ghost.rotation = _player_sprite.rotation
	ghost.modulate = Color(0.72, 0.86, 1.0, 0.45) # Brighter blue ghost
	add_child(ghost)
	
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.28) # Longer tail (from 0.14)
	tween.tween_property(ghost, "scale", _player_sprite.scale * 1.15, 0.28) # Larger expand (from 1.06)
	
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)
