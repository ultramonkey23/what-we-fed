extends Node2D

signal reached_hit_zone(projectile)
signal player_contact(projectile)
signal enemy_contact(projectile)
signal resolved(projectile, result: String)

# Attack timing bands: generous and readable.
const ATTACK_GOOD_MIN: float = 0.60
const ATTACK_PERFECT_MIN: float = 0.78
const ATTACK_PERFECT_MAX: float = 0.92
const ATTACK_GOOD_MAX: float = 1.02
const ATTACK_LATE_MAX: float = 1.10

# Parry timing bands: tighter than attack.
const PARRY_GOOD_MIN: float = 0.74
const PARRY_PERFECT_MIN: float = 0.84
const PARRY_PERFECT_MAX: float = 0.90
const PARRY_GOOD_MAX: float = 0.97
const PARRY_LATE_MAX: float = 1.02

# Reflected projectiles travel back a little faster to feel punchy.
const REFLECT_SPEED_MULT: float = 1.25

var lane: int = 0
var enemy_id: int = -1
var damage: float = 10.0
var speed: float = 265.0

var enemy_x: float = 0.0
var hit_zone_x: float = 0.0
var player_x: float = 0.0

var progress: float = 0.0
var is_resolved: bool = false
var is_reflected: bool = false
var reflected_damage: float = 0.0

var _reported_hit_zone: bool = false
var _reported_player_contact: bool = false
var _reported_enemy_contact: bool = false
var _body: ColorRect


func _ready() -> void:
	# Placeholder visual built in code so Projectile.tscn stays root-only.
	_body = ColorRect.new()
	_body.name = "Body"
	_body.size = Vector2(26.0, 14.0)
	_body.position = Vector2(-13.0, -7.0)
	_body.color = Color(0.95, 0.58, 0.22, 1.0)
	add_child(_body)


func _process(delta: float) -> void:
	if is_resolved:
		return

	if is_reflected:
		_process_reflected(delta)
	else:
		_process_incoming(delta)


func setup(
	projectile_lane: int,
	projectile_enemy_id: int,
	projectile_damage: float,
	projectile_speed: float,
	start_x: float,
	target_hit_zone_x: float,
	target_player_x: float,
	lane_y: float
) -> void:
	lane = projectile_lane
	enemy_id = projectile_enemy_id
	damage = projectile_damage
	speed = projectile_speed
	enemy_x = start_x
	hit_zone_x = target_hit_zone_x
	player_x = target_player_x
	position = Vector2(enemy_x, lane_y)

	progress = 0.0
	is_resolved = false
	is_reflected = false
	reflected_damage = 0.0
	_reported_hit_zone = false
	_reported_player_contact = false
	_reported_enemy_contact = false

	if _body != null:
		_body.color = Color(0.95, 0.58, 0.22, 1.0)


func reflect_to_enemy(return_damage: float) -> void:
	# Converts the projectile into a returning threat aimed back at the enemy.
	if is_resolved:
		return

	is_reflected = true
	reflected_damage = return_damage
	_reported_hit_zone = true
	_reported_player_contact = true
	_reported_enemy_contact = false

	if _body != null:
		_body.color = Color(0.55, 1.0, 0.78, 1.0)


func evaluate_attack_timing() -> String:
	if is_resolved or is_reflected:
		return "already_resolved"

	if progress < ATTACK_GOOD_MIN:
		return "early"
	elif progress < ATTACK_PERFECT_MIN:
		return "good"
	elif progress <= ATTACK_PERFECT_MAX:
		return "perfect"
	elif progress <= ATTACK_GOOD_MAX:
		return "good"
	elif progress <= ATTACK_LATE_MAX:
		return "late"

	return "miss"


func evaluate_parry_timing() -> String:
	if is_resolved or is_reflected:
		return "already_resolved"

	if progress < PARRY_GOOD_MIN:
		return "early"
	elif progress < PARRY_PERFECT_MIN:
		return "good"
	elif progress <= PARRY_PERFECT_MAX:
		return "perfect"
	elif progress <= PARRY_GOOD_MAX:
		return "good"
	elif progress <= PARRY_LATE_MAX:
		return "late"

	return "miss"


func time_until_hit_zone() -> float:
	if is_resolved or is_reflected or speed <= 0.0:
		return -1.0

	var remaining_distance: float = position.x - hit_zone_x
	return max(remaining_distance / speed, 0.0)


func time_until_player_contact() -> float:
	if is_resolved or is_reflected or speed <= 0.0:
		return -1.0

	var remaining_distance: float = position.x - player_x
	return max(remaining_distance / speed, 0.0)


func resolve(result: String) -> void:
	if is_resolved:
		return

	is_resolved = true
	resolved.emit(self, result)

	var timer: SceneTreeTimer = get_tree().create_timer(0.10)
	timer.timeout.connect(queue_free)


func _process_incoming(delta: float) -> void:
	if enemy_x <= player_x:
		return

	position.x -= speed * delta

	var intercept_distance: float = enemy_x - hit_zone_x
	if intercept_distance > 0.0:
		progress = (enemy_x - position.x) / intercept_distance

	if not _reported_hit_zone and position.x <= hit_zone_x:
		_reported_hit_zone = true
		reached_hit_zone.emit(self)

	if not _reported_player_contact and position.x <= player_x:
		_reported_player_contact = true
		player_contact.emit(self)


func _process_reflected(delta: float) -> void:
	position.x += speed * REFLECT_SPEED_MULT * delta

	if not _reported_enemy_contact and position.x >= enemy_x:
		_reported_enemy_contact = true
		enemy_contact.emit(self)
