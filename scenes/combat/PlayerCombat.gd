extends Node2D

@onready var sprite: ColorRect = $Sprite

const FOLLOW_UP_WINDOW: float = 0.55

# Combat result tuning.
const TIMED_ATTACK_DAMAGE_RATIO: float = 0.5
const LATE_ATTACK_PUNISH_RATIO: float = 0.18
const GOOD_PARRY_REFLECT_MULT: float = 1.2
const PERFECT_PARRY_REFLECT_MULT: float = 2.0
const IDLE_ATTACK_DAMAGE_RATIO: float = 0.05

# Recovery / anti-spam tuning.
const BASIC_ATTACK_RECOVERY: float = 0.28
const TIMED_ATTACK_RECOVERY: float = 0.14
const PERFECT_ATTACK_RECOVERY: float = 0.08
const EARLY_ATTACK_RECOVERY: float = 0.24
const LATE_ATTACK_RECOVERY: float = 0.32

const GOOD_PARRY_RECOVERY: float = 0.22
const PERFECT_PARRY_RECOVERY: float = 0.14
const FAILED_PARRY_RECOVERY: float = 0.32

const DODGE_RECOVERY: float = 0.22
const ULTIMATE_RECOVERY: float = 0.45

const CHAIN_BYPASS_WINDOW: float = 0.60

# Neutral stance rules.
# NEUTRAL_LANE is a core design rule: the player always returns here after every action.
# All action tweens return to this lane's Y position via _play_world_motion.
# Do not remove the return-to-center snap without updating every action state function.
const NEUTRAL_LANE: int = 1
const NEUTRAL_WORLD_X_OFFSET: float = -36.0
const ATTACK_WORLD_X_OFFSET: float = 2.0
const PARRY_WORLD_X_OFFSET: float = -8.0
const DODGE_WORLD_X_OFFSET: float = -18.0
const HIT_WORLD_X_OFFSET: float = -26.0

# Sprite-local pose offsets.
const NEUTRAL_SPRITE_POSITION := Vector2(-46.0, -55.0)
const ATTACK_SPRITE_POSITION := Vector2(-8.0, -55.0)
const PARRY_SPRITE_POSITION := Vector2(-18.0, -55.0)
const DODGE_SPRITE_POSITION := Vector2(-54.0, -55.0)
const HIT_SPRITE_POSITION := Vector2(-58.0, -55.0)

const NEUTRAL_SPRITE_SCALE := Vector2(1.0, 1.0)
const ATTACK_SPRITE_SCALE := Vector2(1.16, 0.92)
const PARRY_SPRITE_SCALE := Vector2(1.08, 1.04)
const DODGE_SPRITE_SCALE := Vector2(0.92, 1.04)
const HIT_SPRITE_SCALE := Vector2(0.96, 1.0)

var lane_manager: Node = null
var combat_meter: Node = null

var current_lane: int = NEUTRAL_LANE
var parry_followup_active: bool = false
var parry_followup_timer: float = 0.0
var parry_followup_damage: float = 0.0

var action_lock_timer: float = 0.0
var current_action_state: String = "idle"

var chain_bypass_available: bool = false
var chain_bypass_timer: float = 0.0
var combat_enabled: bool = true

var _sprite_pose_tween: Tween = null
var _world_motion_tween: Tween = null


func _ready() -> void:
	# Placeholder body styling.
	sprite.size = Vector2(38.0, 55.0)
	sprite.color = Color(0.25, 0.55, 0.95, 1.0)
	_return_to_neutral_state(true)


func _process(delta: float) -> void:
	if action_lock_timer > 0.0:
		action_lock_timer = max(action_lock_timer - delta, 0.0)
		if action_lock_timer <= 0.0:
			current_action_state = "idle"

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
	if not combat_enabled:
		return

	if lane_manager == null or combat_meter == null:
		return

	if not _can_accept_action():
		return

	if event.is_action_pressed("action_ultimate"):
		_try_ultimate()
		return

	if event.is_action_pressed("lane_attack_0"):
		_handle_lane_action(0)
		return

	if event.is_action_pressed("lane_attack_1"):
		_handle_lane_action(1)
		return

	if event.is_action_pressed("lane_attack_2"):
		_handle_lane_action(2)
		return


func setup(new_lane_manager: Node, new_combat_meter: Node) -> void:
	lane_manager = new_lane_manager
	combat_meter = new_combat_meter
	combat_enabled = true
	current_lane = NEUTRAL_LANE

	if not EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.connect(_on_projectile_fired)

	for lane in range(3):
		var projectile = lane_manager.get_projectile(lane)
		if projectile != null:
			_connect_projectile_signals(projectile)

	_return_to_neutral_state(true)


func set_combat_enabled(enabled: bool) -> void:
	combat_enabled = enabled

	if not combat_enabled:
		action_lock_timer = 0.0
		current_action_state = "idle"
		chain_bypass_available = false
		chain_bypass_timer = 0.0
		parry_followup_active = false
		parry_followup_timer = 0.0
		parry_followup_damage = 0.0
		_return_to_neutral_state(true)


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
	action_lock_timer = max(duration, 0.0)
	current_action_state = state


func _handle_lane_action(target_lane: int) -> void:
	target_lane = clamp(target_lane, 0, 2)
	_consume_chain_bypass_if_needed()
	_select_action_lane(target_lane)

	# Immediate ring feedback on button press.
	EventBus.emit_signal("timing_ring_pressed", current_lane)

	if Input.is_action_pressed("mod_back"):
		_try_parry()
		return

	if Input.is_action_pressed("mod_forward"):
		_try_dodge()
		return

	_try_attack()


func _select_action_lane(target_lane: int) -> void:
	var previous_lane: int = current_lane
	current_lane = target_lane

	if previous_lane != current_lane:
		EventBus.emit_signal("player_teleported", previous_lane, current_lane)


func _try_attack() -> void:
	_play_attack_state(current_lane)

	var projectile = lane_manager.get_projectile(current_lane)
	var combo_mult: float = combat_meter.damage_multiplier()

	if parry_followup_active:
		_fire_parry_followup(combo_mult)
		return

	if projectile == null:
		_idle_attack(combo_mult)
		return

	var quality: String = String(projectile.evaluate_attack_timing())

	match quality:
		"good":
			_resolve_timed_attack(projectile, combo_mult, quality)
		"perfect":
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

	var projectile = lane_manager.get_projectile(current_lane)
	if projectile == null:
		return

	if not combat_meter.can_parry():
		EventBus.emit_signal("player_no_stamina")
		return

	if not combat_meter.spend_stamina_for_parry():
		return

	var quality: String = String(projectile.evaluate_parry_timing())

	if quality != "good" and quality != "perfect":
		combat_meter.record_bad_timing()
		EventBus.emit_signal("screen_flash", Color(1.0, 0.2, 0.2, 0.08), 0.05)
		_lock_action(FAILED_PARRY_RECOVERY, "failed_parry")
		return

	var combo_mult: float = combat_meter.damage_multiplier()
	var reflect_mult: float = GOOD_PARRY_REFLECT_MULT
	var recovery: float = GOOD_PARRY_RECOVERY

	if quality == "perfect":
		reflect_mult = PERFECT_PARRY_REFLECT_MULT
		recovery = PERFECT_PARRY_RECOVERY

	var reflect_damage: float = float(projectile.damage) * reflect_mult * combo_mult * (1.0 + _get_parry_reflect_bonus())

	projectile.reflect_to_enemy(reflect_damage)
	lane_manager.clear_slot(current_lane)
	combat_meter.record_parry(quality)

	parry_followup_active = true
	parry_followup_timer = FOLLOW_UP_WINDOW
	parry_followup_damage = reflect_damage

	EventBus.emit_signal("player_parried", current_lane, quality, reflect_damage)

	if quality == "perfect":
		EventBus.emit_signal("screen_flash", Color(0.45, 1.0, 0.75, 0.16), 0.08)
		EventBus.emit_signal("slow_motion", 0.76, 0.08)
	else:
		EventBus.emit_signal("screen_flash", Color(0.45, 1.0, 0.75, 0.10), 0.06)

	_lock_action(recovery, "parry")


func _try_dodge() -> void:
	var from_lane: int = current_lane
	var to_lane: int = current_lane + 1

	if Input.is_action_pressed("mod_up"):
		to_lane = current_lane - 1
	elif Input.is_action_pressed("mod_down"):
		to_lane = current_lane + 1
	else:
		to_lane = current_lane + 1 if current_lane < 2 else current_lane - 1

	to_lane = clamp(to_lane, 0, 2)

	if to_lane == from_lane:
		return

	current_lane = to_lane
	EventBus.emit_signal("player_teleported", from_lane, to_lane)
	_play_dodge_state(to_lane)

	var destination_projectile = lane_manager.get_projectile(to_lane)
	if destination_projectile != null:
		destination_projectile.resolve("dodged_through")
		lane_manager.clear_slot(to_lane)

	combat_meter.record_dodge()
	EventBus.emit_signal("player_dodged", from_lane, to_lane)
	EventBus.emit_signal("screen_flash", Color(0.65, 0.85, 1.0, 0.06), 0.05)

	_lock_action(DODGE_RECOVERY, "dodge")


func _try_ultimate() -> void:
	_play_attack_state(current_lane)

	if not combat_meter.is_ultimate_available():
		return

	var multiplier: float = combat_meter.consume_ultimate()
	if multiplier <= 0.0:
		return

	var total_damage: float = GameState.get_attack_damage() * multiplier
	total_damage += _get_creature_bonus()

	for lane in range(3):
		lane_manager.damage_enemy(lane, total_damage)

	EventBus.emit_signal("screen_flash", Color(1.0, 0.75, 0.3, 0.16), 0.10)
	EventBus.emit_signal("slow_motion", 0.72, 0.10)

	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(ULTIMATE_RECOVERY, "ultimate")


func _idle_attack(combo_mult: float) -> void:
	var idle_damage: float = (GameState.get_attack_damage() * IDLE_ATTACK_DAMAGE_RATIO) * combo_mult
	lane_manager.damage_enemy(current_lane, idle_damage)
	combat_meter.record_attack()
	EventBus.emit_signal("player_attacked", current_lane, idle_damage, false)
	EventBus.emit_signal("screen_flash", Color(0.85, 0.85, 0.85, 0.04), 0.03)

	_lock_action(BASIC_ATTACK_RECOVERY, "idle_attack")


func _resolve_timed_attack(projectile, combo_mult: float, quality: String) -> void:
	var timed_damage: float = (float(projectile.damage) * TIMED_ATTACK_DAMAGE_RATIO) * combo_mult + _get_timed_damage_bonus()
	var recovery: float = TIMED_ATTACK_RECOVERY

	projectile.resolve("attack_%s" % quality)
	lane_manager.clear_slot(current_lane)
	lane_manager.damage_enemy(current_lane, timed_damage)
	combat_meter.record_timed_attack()

	EventBus.emit_signal("player_attacked", current_lane, timed_damage, true)
	EventBus.emit_signal("timed_attack_resolved", current_lane, quality, timed_damage)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.55, 0.12), 0.07)

	if quality == "perfect":
		recovery = PERFECT_ATTACK_RECOVERY
		EventBus.emit_signal("slow_motion", 0.80, 0.06)
	else:
		EventBus.emit_signal("slow_motion", 0.88, 0.04)

	_grant_chain_bypass()
	_lock_action(recovery, "timed_attack")


func _resolve_early_attack() -> void:
	combat_meter.record_bad_timing()
	EventBus.emit_signal("screen_flash", Color(1.0, 0.15, 0.15, 0.05), 0.04)
	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(EARLY_ATTACK_RECOVERY, "early_attack")


func _resolve_late_attack(projectile) -> void:
	var punish_damage: float = float(projectile.damage) * LATE_ATTACK_PUNISH_RATIO
	_take_damage(punish_damage, current_lane)
	combat_meter.record_bad_timing()
	EventBus.emit_signal("screen_flash", Color(1.0, 0.15, 0.15, 0.10), 0.06)
	chain_bypass_available = false
	chain_bypass_timer = 0.0
	_lock_action(LATE_ATTACK_RECOVERY, "late_attack")


func _fire_parry_followup(combo_mult: float) -> void:
	_play_attack_state(current_lane)

	var followup_damage: float = max(parry_followup_damage, GameState.get_attack_damage()) * combo_mult
	lane_manager.damage_enemy(current_lane, followup_damage)
	combat_meter.record_lane_read()
	EventBus.emit_signal("player_attacked", current_lane, followup_damage, true)
	EventBus.emit_signal("screen_flash", Color(1.0, 0.95, 0.65, 0.08), 0.05)
	EventBus.emit_signal("slow_motion", 0.86, 0.04)

	parry_followup_active = false
	parry_followup_timer = 0.0
	parry_followup_damage = 0.0

	_grant_chain_bypass()
	_lock_action(TIMED_ATTACK_RECOVERY, "parry_followup")


func _take_damage(amount: float, source_lane: int) -> void:
	_play_hit_state(source_lane)

	amount = amount * (1.0 - _get_damage_reduction())
	GameState.player_hp = max(GameState.player_hp - amount, 0.0)
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
	# Capped at 50% to prevent stacking from becoming degenerate.
	var total: float = 0.0
	for creature in GameState.roster:
		var passive: Dictionary = creature.get("bond_passive", {})
		if passive.get("type", "") == "damage_reduction_pct":
			var mult: float = GameState.get_bond_level_mult(int(creature.get("bond_level", 1)))
			total += float(passive.get("value", 0.0)) * mult
	return min(total, 0.50)


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

	return Vector2(
		lane_manager.get_player_x() + NEUTRAL_WORLD_X_OFFSET,
		lane_manager.get_lane_y(NEUTRAL_LANE)
	)


func _action_world_position(target_lane: int, x_offset: float) -> Vector2:
	if lane_manager == null:
		return Vector2.ZERO

	return Vector2(
		lane_manager.get_player_x() + x_offset,
		lane_manager.get_lane_y(target_lane)
	)


func _return_to_neutral_state(immediate: bool = false) -> void:
	current_lane = NEUTRAL_LANE

	if immediate:
		position = _neutral_world_position()
		sprite.position = NEUTRAL_SPRITE_POSITION
		sprite.scale = NEUTRAL_SPRITE_SCALE
		return

	_play_sprite_pose(NEUTRAL_SPRITE_POSITION, NEUTRAL_SPRITE_SCALE, 0.06)
	_play_world_motion(_neutral_world_position(), _neutral_world_position(), 0.0, 0.08)


func _play_attack_state(target_lane: int) -> void:
	_play_sprite_pose(ATTACK_SPRITE_POSITION, ATTACK_SPRITE_SCALE, 0.08)
	_play_world_motion(
		_action_world_position(target_lane, ATTACK_WORLD_X_OFFSET),
		_neutral_world_position(),
		0.04,
		0.10
	)


func _play_parry_state(target_lane: int) -> void:
	_play_sprite_pose(PARRY_SPRITE_POSITION, PARRY_SPRITE_SCALE, 0.10)
	_play_world_motion(
		_action_world_position(target_lane, PARRY_WORLD_X_OFFSET),
		_neutral_world_position(),
		0.04,
		0.10
	)


func _play_dodge_state(target_lane: int) -> void:
	_play_sprite_pose(DODGE_SPRITE_POSITION, DODGE_SPRITE_SCALE, 0.10)
	_play_world_motion(
		_action_world_position(target_lane, DODGE_WORLD_X_OFFSET),
		_neutral_world_position(),
		0.03,
		0.12
	)


func _play_hit_state(target_lane: int) -> void:
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

	_sprite_pose_tween = create_tween()
	_sprite_pose_tween.tween_property(sprite, "position", target_position, 0.03)
	_sprite_pose_tween.parallel().tween_property(sprite, "scale", target_scale, 0.03)
	_sprite_pose_tween.tween_property(sprite, "position", NEUTRAL_SPRITE_POSITION, return_time)
	_sprite_pose_tween.parallel().tween_property(sprite, "scale", NEUTRAL_SPRITE_SCALE, return_time)


func _play_world_motion(action_position: Vector2, return_position: Vector2, push_time: float, return_time: float) -> void:
	if _world_motion_tween != null:
		_world_motion_tween.kill()

	# Capture the lane this action is being performed from. The callback uses this
	# to guard against snapping current_lane to neutral if a chain-bypass action has
	# already moved the player to a different lane while this tween was in flight.
	var acting_lane: int = current_lane

	_world_motion_tween = create_tween()
	if push_time > 0.0:
		_world_motion_tween.tween_property(self, "position", action_position, push_time)
	else:
		position = action_position

	_world_motion_tween.tween_property(self, "position", return_position, return_time)
	_world_motion_tween.tween_callback(func() -> void:
		if current_lane != acting_lane:
			return
		current_lane = NEUTRAL_LANE
		if acting_lane != NEUTRAL_LANE:
			EventBus.emit_signal("player_teleported", acting_lane, NEUTRAL_LANE)
	)


func _on_projectile_fired(lane: int, _enemy_id: int) -> void:
	var projectile = lane_manager.get_projectile(lane)
	if projectile != null:
		_connect_projectile_signals(projectile)


func _connect_projectile_signals(projectile) -> void:
	if projectile == null:
		return

	if not projectile.player_contact.is_connected(_on_projectile_player_contact):
		projectile.player_contact.connect(_on_projectile_player_contact)


func _on_projectile_player_contact(projectile) -> void:
	if not combat_enabled:
		return

	if projectile == null or projectile.is_resolved:
		return

	_take_damage(float(projectile.damage), int(projectile.lane))
	projectile.resolve("miss")
	lane_manager.clear_slot(int(projectile.lane))
