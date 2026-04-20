extends Node2D

signal reached_hit_zone(projectile)
signal player_contact(projectile)
signal enemy_contact(projectile)
signal resolved(projectile, result: String)

# Set to true to show live progress and zone labels on each projectile while testing.
# Disable before shipping — leaving this false has zero runtime cost.
const DEBUG_TIMING: bool = false

# Timing is based on projectile progress: a float from 0.0 (just fired at enemy_x)
# to 1.0 (reached hit_zone_x). Progress continues past 1.0 as the projectile travels
# toward the player. All timing windows are thresholds against this progress value.
#
# Progress is distance-based, not time-based:
#   progress = (enemy_x - position.x) / (enemy_x - hit_zone_x)
#
# "early" = before GOOD_MIN  |  "good" = GOOD_MIN..PERFECT_MIN or PERFECT_MAX..GOOD_MAX
# "perfect" = PERFECT_MIN..PERFECT_MAX  |  "miss" = beyond
#
# Timing Truth Contract:
# - Perfect zone (0.98..1.02) centered at beat mark (1.0)
# - Good zone (0.96..1.04) maps to visible outer ring
# - No hidden grace zones beyond visible rings
# - Visual rings are rendered based on ring-to-progress conversion in CombatScene.gd
# - See docs/TIMING_CONSTANTS_REFERENCE.md for complete constant documentation
const ATTACK_GOOD_MIN: float = 0.96
const ATTACK_PERFECT_MIN: float = 0.98
const ATTACK_PERFECT_MAX: float = 1.02
const ATTACK_GOOD_MAX: float = 1.04

# Parry timing bands: identical to attack. Good = inside the outer ring.
# Perfect = inner ring only. Outside all rings = failed parry.
# No hidden timing windows beyond what the visible circles show.
const PARRY_GOOD_MIN: float = 0.96
const PARRY_PERFECT_MIN: float = 0.98
const PARRY_PERFECT_MAX: float = 1.02
const PARRY_GOOD_MAX: float = 1.04

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
var _core: ColorRect
var _trail: Line2D
var _glow: Polygon2D


func _ready() -> void:
	# Placeholder visual built in code so Projectile.tscn stays root-only.
	_glow = Polygon2D.new()
	_glow.name = "Glow"
	_glow.color = Color(0.95, 0.58, 0.22, 0.12)
	_glow.polygon = PackedVector2Array([
		Vector2(-18.0, 0.0),
		Vector2(-8.0, -10.0),
		Vector2(12.0, -10.0),
		Vector2(20.0, 0.0),
		Vector2(12.0, 10.0),
		Vector2(-8.0, 10.0)
	])
	add_child(_glow)

	_trail = Line2D.new()
	_trail.name = "Trail"
	_trail.default_color = Color(0.95, 0.58, 0.22, 0.22)
	_trail.width = 5.0
	_trail.add_point(Vector2(-30.0, 0.0))
	_trail.add_point(Vector2(10.0, 0.0))
	add_child(_trail)

	_body = ColorRect.new()
	_body.name = "Body"
	_body.size = Vector2(24.0, 12.0)
	_body.position = Vector2(-12.0, -6.0)
	_body.color = Color(0.95, 0.58, 0.22, 1.0)
	add_child(_body)

	_core = ColorRect.new()
	_core.name = "Core"
	_core.size = Vector2(10.0, 6.0)
	_core.position = Vector2(-5.0, -3.0)
	_core.color = Color(1.0, 0.84, 0.58, 0.95)
	add_child(_core)

	if DEBUG_TIMING:
		var debug_label := Label.new()
		debug_label.name = "DebugLabel"
		debug_label.position = Vector2(-22.0, -52.0)
		debug_label.add_theme_font_size_override("font_size", 10)
		debug_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(debug_label)
		
		# Zone boundary markers for visual calibration.
		_create_debug_zone_markers()


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
		_apply_projectile_palette(Color(0.95, 0.58, 0.22, 1.0), false)


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
		_apply_projectile_palette(Color(0.55, 1.0, 0.78, 1.0), true)


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

	_update_visual_state(false)
	_update_debug_display()



func _process_reflected(delta: float) -> void:
	position.x += speed * REFLECT_SPEED_MULT * delta
	_update_visual_state(true)

	if not _reported_enemy_contact and position.x >= enemy_x:
		_reported_enemy_contact = true
		enemy_contact.emit(self)


func _apply_projectile_palette(body_color: Color, reflected: bool) -> void:
	var trail_alpha: float = 0.24
	var glow_alpha: float = 0.12
	if reflected:
		trail_alpha = 0.30
		glow_alpha = 0.16

	if _body != null:
		_body.color = body_color
	if _core != null:
		_core.color = body_color.lightened(0.36)
	if _trail != null:
		_trail.default_color = Color(body_color.r, body_color.g, body_color.b, trail_alpha)
	if _glow != null:
		_glow.color = Color(body_color.r, body_color.g, body_color.b, glow_alpha)


func _update_visual_state(reflected: bool) -> void:
	var base_color: Color = Color(0.95, 0.58, 0.22, 1.0)
	if reflected:
		base_color = Color(0.55, 1.0, 0.78, 1.0)

	var pressure: float = 0.85 if reflected else clamp((progress - 0.72) / 0.32, 0.0, 1.0)
	var body_scale: Vector2 = Vector2(1.0 + pressure * 0.12, 1.0 + pressure * 0.08)
	var trail_alpha: float = 0.24 + pressure * 0.22
	var glow_alpha: float = 0.13 + pressure * 0.18

	if _body != null:
		_body.scale = body_scale
		_body.color = base_color.lightened(pressure * 0.06)
	if _core != null:
		_core.scale = Vector2(1.0 + pressure * 0.20, 1.0 + pressure * 0.10)
		_core.color = base_color.lightened(0.34 + pressure * 0.12)
	if _trail != null:
		_trail.width = 5.0 + pressure * 2.0
		_trail.default_color = Color(base_color.r, base_color.g, base_color.b, trail_alpha)
		_trail.set_point_position(0, Vector2(-34.0 - pressure * 18.0, 0.0))
		_trail.set_point_position(1, Vector2(8.0 + pressure * 5.0, 0.0))
	if _glow != null:
		_glow.scale = Vector2(1.0 + pressure * 0.16, 1.0 + pressure * 0.08)
		_glow.color = Color(base_color.r, base_color.g, base_color.b, glow_alpha)


func _create_debug_zone_markers() -> void:
	# Optional debug visualization: draw zone boundaries as vertical indicators
	# relative to the projectile's expected hit point. This helps verify that
	# visual rings align with the actual timing windows.
	# Only active when DEBUG_TIMING = true.
	if not DEBUG_TIMING:
		return
	
	# Assume a standard layout: hit_zone_x is where the beat mark should be.
	# The rings expand from there based on intercept distance.
	# This marker set is visual calibration only — not part of game logic.
	
	var debug_group := Node2D.new()
	debug_group.name = "DebugZoneMarkers"
	add_child(debug_group)
	
	# We'll paint zone markers as the projectile approaches.
	# These will be updated in _process to show the active zone relative to hit.


func _get_debug_zone_quality(p: float) -> String:
	# Return a label for the current progress zone.
	if p < 0.92:
		return "→FAR"
	elif p < ATTACK_GOOD_MIN:
		return "EARLY"
	elif p < ATTACK_PERFECT_MIN:
		return "GOOD-early"
	elif p <= ATTACK_PERFECT_MAX:
		return "PERFECT"
	elif p <= ATTACK_GOOD_MAX:
		return "GOOD-late"
	else:
		return "LATE"


func _update_debug_display() -> void:
	# Enhanced debug label showing progress, timing quality, and zone indicators.
	# This helps verify that the visual rings align with actual game logic windows.
	if not DEBUG_TIMING or is_resolved:
		return
	
	var _dbg: Label = get_node_or_null("DebugLabel") as Label
	if _dbg == null:
		return
	
	var attack_quality: String = evaluate_attack_timing()
	var parry_quality: String = evaluate_parry_timing()
	var zone_quality: String = _get_debug_zone_quality(progress)
	var offset: float = progress - 1.0
	
	_dbg.text = "P:%.3f [%s]\nA:%s | P:%s\nZone:%s" % [
		progress,
		"%.2f%%" % (offset * 100.0),
		attack_quality[0],  # First letter
		parry_quality[0],   # First letter
		zone_quality
	]

