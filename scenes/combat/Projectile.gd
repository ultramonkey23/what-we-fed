extends ThreatBase
class_name Projectile

const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
const SOVEREIGN_DAMAGE_CALCULATOR = preload("res://systems/SovereignDamageCalculator.gd")

# Set to true to show live progress and zone labels on each projectile while testing.
# Disable before shipping — leaving this false has zero runtime cost.
const DEBUG_TIMING: bool = false

# Timing is based on projectile progress: a float from 0.0 (just fired at enemy_x)
# to 1.0 (reached hit_zone_x). Progress continues past 1.0 as the projectile travels
# toward the player. All timing windows are thresholds against this progress value.
# "early" = before GOOD_MIN  |  "good" = GOOD_MIN..PERFECT_MIN or PERFECT_MAX..GOOD_MAX
# "perfect" = PERFECT_MIN..PERFECT_MAX  |  "miss" = beyond
#
# Timing Truth Bundle:
# - outer ring = success boundary (0.96..1.04)
# - inner ring = perfect boundary (0.98..1.02)
# - beat mark at progress 1.0 = center of perfect truth
# There is no hidden late grace zone; close-quarters proximity grace is centralized
# in CombatFeelContent and kept small enough to read as physical contact.
const ATTACK_GOOD_MIN: float = 0.96
const ATTACK_PERFECT_MIN: float = 0.98
const ATTACK_PERFECT_MAX: float = 1.02
const ATTACK_GOOD_MAX: float = 1.04

# Parry timing bands: ring-exact. Good = inside the outer ring. Perfect = inner ring only.
# Outside all rings = failed parry, except for the same tiny contact grace used by attacks.
const PARRY_GOOD_MIN: float = 0.96
const PARRY_PERFECT_MIN: float = 0.98
const PARRY_PERFECT_MAX: float = 1.02
const PARRY_GOOD_MAX: float = 1.04

# Reflected projectiles travel back a little faster to feel punchy.
const REFLECT_SPEED_MULT: float = 1.25
const PLAYER_CONTACT_RADIUS: float = 21.0 # Tight enough that visual contact reads as honest.

# Body: per-enemy art under res://assets/sprites/projectile_bodies/<species_id or type>.png (see generator).
# Modifier: song-section preset — grayscale overlay (shot1–6) + trail/glow tuning (shot_modifier).
const DEFAULT_PROJECTILE_BODY_PATH: String = "res://assets/sprites/projectile_bodies/dreg.png"
const SHOT_MODIFIER_TEXTURES: Dictionary = {
	"fang": "res://assets/sprites/shot1.png",
	"mass": "res://assets/sprites/shot2.png",
	"needle": "res://assets/sprites/shot3.png",
	"veil": "res://assets/sprites/shot4.png",
	"chorus": "res://assets/sprites/shot5.png",
	"sovereign": "res://assets/sprites/shot6.png"
}
const DEFAULT_SHOT_MODIFIER_PATH: String = "res://assets/sprites/shot1.png"
# Maps the 32x32 sprite to ~24×12 world footprint (slightly larger for readability).
const SHOT_BASE_SCALE: Vector2 = Vector2(0.61, 0.31)
const DEFAULT_PROJECTILE_COLOR: Color = Color(0.95, 0.58, 0.22, 1.0)
const DEFAULT_REFLECT_COLOR: Color = Color(0.55, 1.0, 0.78, 1.0)

var enemy_pos: Vector2 = Vector2.ZERO
var hit_zone_pos: Vector2 = Vector2.ZERO
var player_pos: Vector2 = Vector2.ZERO

var target_beat_time: float = -1.0
var fire_song_time: float = 0.0
var conductor_ref: SongConductor = null

# Projectile Doctrine: Soft Tracking
var max_turn_rate: float = 1.5
var commit_threshold: float = 0.75
var _is_committed: bool = false
var _current_radial_vector: Vector2 = Vector2.ZERO
var _initial_distance_to_center: float = 0.0
var _hit_zone_distance_to_center: float = 0.0

var _reported_hit_zone: bool = false
var _reported_player_contact: bool = false
var _reported_enemy_contact: bool = false
var _body: Sprite2D
var _modifier: Sprite2D
var _core: ColorRect
var _trail: Line2D
var _glow: Polygon2D
var _total_distance: float = 0.0



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
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.antialiased = true
	# Incoming moves -world X: wake extends +local X (behind), tip toward -local X.
	_trail.add_point(Vector2(34.0, 0.0))
	_trail.add_point(Vector2(-8.0, 0.0))
	add_child(_trail)

	_body = Sprite2D.new()
	_body.name = "Body"
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var _body_tex: Texture2D = load(DEFAULT_PROJECTILE_BODY_PATH) as Texture2D
	if _body_tex:
		_body.texture = _body_tex
	_body.position = Vector2(0.0, 0.0)
	_body.scale = SHOT_BASE_SCALE
	_body.modulate = Color(0.95, 0.58, 0.22, 1.0)
	add_child(_body)

	_modifier = Sprite2D.new()
	_modifier.name = "ShotModifier"
	_modifier.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var _mod_mat := CanvasItemMaterial.new()
	_mod_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_modifier.material = _mod_mat
	_modifier.position = Vector2.ZERO
	_modifier.scale = SHOT_BASE_SCALE
	_modifier.z_index = 1
	var _mod_tex: Texture2D = load(DEFAULT_SHOT_MODIFIER_PATH) as Texture2D
	if _mod_tex:
		_modifier.texture = _mod_tex
	_modifier.modulate = Color(0.5, 0.5, 0.5, 0.5)
	add_child(_modifier)

	_core = ColorRect.new()
	_core.name = "Core"
	_core.size = Vector2(10.0, 6.0)
	_core.position = Vector2(-5.0, -3.0)
	_core.color = Color(1.0, 0.84, 0.58, 0.95)
	add_child(_core)

	telegraph_profile = _build_telegraph_profile({})
	_refresh_body_sprite()
	_refresh_modifier_overlay()
	_configure_telegraph_shape()

	if DEBUG_TIMING:
		var debug_label := Label.new()
		debug_label.name = "DebugLabel"
		debug_label.position = Vector2(-22.0, -52.0)
		debug_label.add_theme_font_size_override("font_size", 10)
		add_child(debug_label)


func _process(delta: float) -> void:
	if is_resolved:
		return

	if is_reflected:
		_process_reflected(delta)
	else:
		_process_incoming_song_synced(delta)


func setup(
	projectile_lane: int,
	projectile_enemy_id: int,
	projectile_damage: float,
	projectile_speed: float,
	start_pos: Vector2,
	target_hit_zone_pos: Vector2,
	target_player_pos: Vector2,
	projectile_telegraph_profile: Dictionary = {},
	target_player_ref: Node2D = null
) -> void:
	lane = projectile_lane
	enemy_id = projectile_enemy_id
	damage = projectile_damage
	speed = projectile_speed
	enemy_pos = start_pos
	hit_zone_pos = target_hit_zone_pos
	player_pos = target_player_pos
	player_ref = target_player_ref
	position = enemy_pos
	
	_total_distance = enemy_pos.distance_to(hit_zone_pos)
	
	# Radial Tracking Initialization
	var center = player_pos # In LaneManager, player_pos passed here is _center_pos
	_initial_distance_to_center = enemy_pos.distance_to(center)
	_hit_zone_distance_to_center = hit_zone_pos.distance_to(center)
	_current_radial_vector = (enemy_pos - center).normalized()
	
	# Rotate to face player
	rotation = (player_pos - enemy_pos).angle()

	progress = 0.0
	is_resolved = false
	is_reflected = false
	_is_committed = false
	reflected_damage = 0.0
	_reported_hit_zone = false
	_reported_player_contact = false
	_reported_enemy_contact = false
	telegraph_profile = _build_telegraph_profile(projectile_telegraph_profile)
	
	# Load profile overrides
	max_turn_rate = float(telegraph_profile.get("max_turn_rate", 1.5))
	commit_threshold = float(telegraph_profile.get("commit_threshold", 0.75))
	
	_refresh_body_sprite()
	_refresh_modifier_overlay()
	_configure_telegraph_shape()

	if _body != null:
		_apply_projectile_palette(_incoming_body_color(), false)


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
		_apply_projectile_palette(_reflected_body_color(), true)
	_update_visual_state(true)


func evaluate_attack_timing() -> String:
	if is_resolved or is_reflected:
		return "already_resolved"

	var quality: String = _evaluate_hit_zone_timing(
		COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS,
		COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS
	)
	if not quality.is_empty():
		return quality

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

	var quality: String = _evaluate_hit_zone_timing(
		COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS,
		COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS
	)
	if not quality.is_empty():
		return quality

	if progress < PARRY_GOOD_MIN:
		return "early"
	elif progress < PARRY_PERFECT_MIN:
		return "good"
	elif progress <= PARRY_PERFECT_MAX:
		return "perfect"
	elif progress <= PARRY_GOOD_MAX:
		return "good"

	return "miss"


func _evaluate_hit_zone_timing(good_radius: float, perfect_radius: float) -> String:
	var distance_to_hit_zone: float = position.distance_to(hit_zone_pos)
	if distance_to_hit_zone <= perfect_radius:
		return "perfect"
	if distance_to_hit_zone <= good_radius:
		return "good"
	return ""


func time_until_hit_zone() -> float:
	if is_resolved or is_reflected or speed <= 0.0:
		return -1.0

	var remaining_distance: float = position.distance_to(hit_zone_pos)
	return max(remaining_distance / speed, 0.0)


func time_until_player_contact() -> float:
	if is_resolved or is_reflected or speed <= 0.0:
		return -1.0

	var remaining_distance: float = position.distance_to(player_pos)
	return max(remaining_distance / speed, 0.0)


func resolve(result: String) -> void:
	if is_resolved:
		return

	is_resolved = true
	emit_signal("resolved", self, result)

	var timer: SceneTreeTimer = get_tree().create_timer(0.10)
	timer.timeout.connect(queue_free)


func evaluate_proximity_timing(attacker_pos: Vector2) -> String:
	if is_resolved or is_reflected:
		return "already_resolved"
		
	# CONTACT TRUTH: Absolute physical proximity check.
	var dist: float = global_position.distance_to(attacker_pos)
	
	var proximity_grace: float = COMBAT_FEEL_CONTENT.RING_PROXIMITY_FORGIVENESS
	if dist <= COMBAT_FEEL_CONTENT.RING_PERFECT_RADIUS + proximity_grace * 0.45:
		return "perfect"
	if dist <= COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS + proximity_grace:
		return "good"
		
	return "miss"


func _process_incoming_song_synced(delta: float) -> void:
	if conductor_ref != null and target_beat_time > 0.0:
		# ABSOLUTE SONG SYNC: 
		# Move the projectile based on the current song position vs its fire/target time.
		var song_now: float = conductor_ref.get_song_time()
		var total_flight_duration: float = target_beat_time - fire_song_time
		if total_flight_duration > 0.0:
			progress = (song_now - fire_song_time) / total_flight_duration
		else:
			progress = 1.0
	else:
		# Fallback to speed-based delta movement if not in song mode or missing conductor.
		if _total_distance > 0.0:
			progress += (speed * delta) / _total_distance
		else:
			progress = 1.0

	# Projectile Doctrine: Soft Tracking logic
	var current_player_pos: Vector2 = player_pos
	if player_ref != null and is_instance_valid(player_ref):
		current_player_pos = player_ref.global_position

	if not _is_committed:
		if progress >= commit_threshold:
			_is_committed = true
		else:
			var player_delta: Vector2 = current_player_pos - player_pos # relative to fixed center
			
			if player_delta.length() > 0.1:
				var desired_radial_vector: Vector2 = player_delta.normalized()
				var current_angle: float = _current_radial_vector.angle()
				var target_angle: float = desired_radial_vector.angle()
				var angle_diff: float = angle_difference(current_angle, target_angle)
				
				var turn_step: float = clamp(angle_diff, -max_turn_rate * delta, max_turn_rate * delta)
				_current_radial_vector = _current_radial_vector.rotated(turn_step)
			
			# Face the center (direction of travel)
			rotation = _current_radial_vector.angle() + PI

	# Map progress to physical position using radial model relative to CURRENT player
	var current_dist: float = lerp(_initial_distance_to_center, _hit_zone_distance_to_center, progress)
	position = current_player_pos + _current_radial_vector * current_dist

	# Update hit_zone_pos for timing checks (always at current_dist 0.0 relative to player)
	hit_zone_pos = current_player_pos + _current_radial_vector * _hit_zone_distance_to_center

	if not _reported_hit_zone and progress >= 1.0:
		_reported_hit_zone = true
		emit_signal("reached_hit_zone", self)

	if not _reported_player_contact:
		var actual_player_pos: Vector2 = player_pos
		if player_ref != null and is_instance_valid(player_ref):
			actual_player_pos = player_ref.global_position

		if global_position.distance_to(actual_player_pos) <= PLAYER_CONTACT_RADIUS:
			_reported_player_contact = true
			emit_signal("player_contact", self)

	_update_visual_state(false)

	if DEBUG_TIMING:
		var _dbg: Label = get_node_or_null("DebugLabel") as Label
		if _dbg != null:
			_dbg.text = "%.3f\nA:%s\nP:%s\nHZ:%+.3f" % [
				progress,
				evaluate_attack_timing(),
				evaluate_parry_timing(),
				progress - 1.0
			]


func set_song_sync(conductor: SongConductor, hit_time: float) -> void:
	conductor_ref = conductor
	target_beat_time = hit_time
	if conductor_ref != null:
		fire_song_time = conductor_ref.get_song_time()


func _process_reflected(delta: float) -> void:
	# Reflected projectiles travel from player_pos back to enemy_pos
	var reflect_dir: Vector2 = (enemy_pos - player_pos).normalized()
	position += reflect_dir * speed * REFLECT_SPEED_MULT * delta
	_update_visual_state(true)

	if not _reported_enemy_contact:
		var dist_to_origin: float = position.distance_to(enemy_pos)
		# If we've passed the enemy origin or are very close, resolve.
		# Check if the dot product of motion vs direction to origin flipped.
		if dist_to_origin < 25.0:
			_reported_enemy_contact = true
			emit_signal("enemy_contact", self)


func _apply_projectile_palette(body_color: Color, reflected: bool) -> void:
	var trail_alpha: float = float(telegraph_profile.get("trail_alpha", 0.24))
	var glow_alpha: float = float(telegraph_profile.get("glow_alpha", 0.12))
	if reflected:
		trail_alpha = 0.30
		glow_alpha = 0.16

	if _body != null:
		_body.modulate = body_color
	if _modifier != null:
		_modifier.modulate = Color(body_color.r * 0.52, body_color.g * 0.52, body_color.b * 0.52, 0.52)
	if _core != null:
		_core.color = body_color.lightened(0.36)
	if _trail != null:
		_trail.default_color = Color(body_color.r, body_color.g, body_color.b, trail_alpha)
	if _glow != null:
		_glow.color = Color(body_color.r, body_color.g, body_color.b, glow_alpha)


func _update_visual_state(reflected: bool) -> void:
	var base_color: Color = _incoming_body_color()
	if reflected:
		base_color = _reflected_body_color()

	var pressure_start: float = float(telegraph_profile.get("pressure_start", 0.72))
	pressure_start = max(0.1, pressure_start - SOVEREIGN_DAMAGE_CALCULATOR.get_telegraph_eye_bias())
	
	var pressure_gain: float = max(float(telegraph_profile.get("pressure_gain", 1.0)), 0.6)
	var pressure: float = 0.85 if reflected else clamp(((progress - pressure_start) / (1.0 - pressure_start)) * pressure_gain, 0.0, 1.0)
	var imminent: float = 0.0 if reflected else clamp((progress - 0.96) / 0.08, 0.0, 1.0)
	var body_pressure_scale: Vector2 = telegraph_profile.get("body_pressure_scale", Vector2(0.12, 0.08))
	var base_body_scale: Vector2 = telegraph_profile.get("body_base_scale", Vector2.ONE)
	var body_scale: Vector2 = base_body_scale + (body_pressure_scale * pressure) + Vector2.ONE * imminent * 0.04
	var trail_alpha: float = float(telegraph_profile.get("trail_alpha", 0.24)) + pressure * 0.22 + imminent * 0.08
	var glow_alpha: float = float(telegraph_profile.get("glow_alpha", 0.13)) + pressure * 0.18 + imminent * 0.10
	var trail_back: float = float(telegraph_profile.get("trail_back", 34.0))
	var trail_front: float = float(telegraph_profile.get("trail_front", 8.0))
	var trail_pressure_back: float = float(telegraph_profile.get("trail_pressure_back", 18.0))
	var trail_pressure_front: float = float(telegraph_profile.get("trail_pressure_front", 5.0))
	var glow_base_scale: Vector2 = telegraph_profile.get("glow_base_scale", Vector2.ONE)
	var glow_pressure_scale: Vector2 = telegraph_profile.get("glow_pressure_scale", Vector2(0.16, 0.08))
	var core_pressure_scale: Vector2 = telegraph_profile.get("core_pressure_scale", Vector2(0.20, 0.10))
	var trail_width: float = float(telegraph_profile.get("trail_width", 5.0))
	var trail_pressure_width: float = float(telegraph_profile.get("trail_pressure_width", 2.0))
	var core_color: Color = Color(telegraph_profile.get("accent_color", base_color.lightened(0.36)))

	if _body != null:
		_body.scale = SHOT_BASE_SCALE * body_scale
		_body.modulate = base_color.lightened(pressure * 0.06 + imminent * 0.10)
		_body.flip_h = reflected
	if _modifier != null:
		_modifier.scale = _body.scale
		_modifier.flip_h = reflected
		var mod_a: float = clampf(0.46 + pressure * 0.14 + imminent * 0.12, 0.0, 0.85)
		_modifier.modulate = Color(
			base_color.r * 0.52,
			base_color.g * 0.52,
			base_color.b * 0.52,
			mod_a
		)
	if _core != null:
		_core.scale = Vector2.ONE + core_pressure_scale * pressure + Vector2.ONE * imminent * 0.08
		_core.color = core_color.lightened(0.18 + pressure * 0.16 + imminent * 0.10)
	if _trail != null:
		_trail.width = trail_width + pressure * trail_pressure_width + imminent * 0.8
		_trail.default_color = Color(base_color.r, base_color.g, base_color.b, trail_alpha)
		var tb: float = trail_back + pressure * trail_pressure_back + imminent * 8.0
		var tf: float = trail_front + pressure * trail_pressure_front + imminent * 3.0
		if not reflected:
			# Wake toward +local X (enemy); tip toward -local X (player / motion).
			_trail.set_point_position(0, Vector2(tb, 0.0))
			_trail.set_point_position(1, Vector2(-tf, 0.0))
		else:
			_trail.set_point_position(0, Vector2(-tb, 0.0))
			_trail.set_point_position(1, Vector2(tf, 0.0))
	if _glow != null:
		var gs: Vector2 = glow_base_scale + glow_pressure_scale * pressure + Vector2.ONE * imminent * 0.10
		_glow.scale = Vector2(gs.x * (-1.0 if reflected else 1.0), gs.y)
		_glow.color = Color(base_color.r, base_color.g, base_color.b, glow_alpha)


func _incoming_body_color() -> Color:
	return Color(telegraph_profile.get("projectile_color", DEFAULT_PROJECTILE_COLOR))


func _reflected_body_color() -> Color:
	return Color(telegraph_profile.get("reflected_color", DEFAULT_REFLECT_COLOR))


func _build_telegraph_profile(source: Dictionary) -> Dictionary:
	var profile: Dictionary = {
		"family": "fang",
		"projectile_color": DEFAULT_PROJECTILE_COLOR,
		"reflected_color": DEFAULT_REFLECT_COLOR,
		"accent_color": Color(1.0, 0.84, 0.58, 1.0),
		"trail_alpha": 0.24,
		"glow_alpha": 0.13,
		"trail_width": 5.0,
		"trail_pressure_width": 2.0,
		"trail_back": 34.0,
		"trail_front": 8.0,
		"trail_pressure_back": 18.0,
		"trail_pressure_front": 5.0,
		"body_base_scale": Vector2.ONE,
		"body_pressure_scale": Vector2(0.12, 0.08),
		"glow_base_scale": Vector2.ONE,
		"glow_pressure_scale": Vector2(0.16, 0.08),
		"core_size": Vector2(10.0, 6.0),
		"core_pressure_scale": Vector2(0.20, 0.10),
		"pressure_start": 0.72,
		"pressure_gain": 1.0,
		"max_turn_rate": 1.5,
		"commit_threshold": 0.75
	}
	var mod_key: String = String(source.get("shot_modifier", source.get("family", "fang")))
	match mod_key:
		"mass":
			profile["trail_width"] = 6.4
			profile["trail_pressure_width"] = 2.6
			profile["trail_back"] = 26.0
			profile["trail_front"] = 6.0
			profile["trail_pressure_back"] = 12.0
			profile["body_base_scale"] = Vector2(1.18, 1.08)
			profile["body_pressure_scale"] = Vector2(0.14, 0.12)
			profile["glow_base_scale"] = Vector2(1.10, 1.04)
			profile["glow_pressure_scale"] = Vector2(0.22, 0.12)
			profile["core_size"] = Vector2(12.0, 8.0)
			profile["pressure_start"] = 0.68
			profile["pressure_gain"] = 0.92
			profile["max_turn_rate"] = 2.2
			profile["commit_threshold"] = 0.82
		"needle":
			profile["trail_width"] = 4.0
			profile["trail_pressure_width"] = 1.6
			profile["trail_back"] = 42.0
			profile["trail_front"] = 12.0
			profile["trail_pressure_back"] = 22.0
			profile["trail_pressure_front"] = 6.0
			profile["body_base_scale"] = Vector2(0.84, 0.82)
			profile["body_pressure_scale"] = Vector2(0.16, 0.06)
			profile["glow_base_scale"] = Vector2(0.88, 0.72)
			profile["glow_pressure_scale"] = Vector2(0.22, 0.10)
			profile["core_size"] = Vector2(8.0, 5.0)
			profile["pressure_start"] = 0.76
			profile["pressure_gain"] = 1.14
			profile["max_turn_rate"] = 0.8
			profile["commit_threshold"] = 0.70
		"veil":
			profile["trail_width"] = 5.6
			profile["trail_back"] = 30.0
			profile["trail_front"] = 7.0
			profile["glow_alpha"] = 0.16
			profile["body_base_scale"] = Vector2(0.96, 0.92)
			profile["body_pressure_scale"] = Vector2(0.10, 0.10)
			profile["glow_base_scale"] = Vector2(1.26, 1.02)
			profile["glow_pressure_scale"] = Vector2(0.18, 0.10)
			profile["core_size"] = Vector2(9.0, 5.0)
			profile["pressure_start"] = 0.70
			profile["pressure_gain"] = 0.96
		"chorus":
			profile["trail_width"] = 4.8
			profile["trail_back"] = 36.0
			profile["trail_front"] = 10.0
			profile["body_base_scale"] = Vector2(1.02, 0.88)
			profile["body_pressure_scale"] = Vector2(0.14, 0.10)
			profile["glow_base_scale"] = Vector2(1.12, 0.96)
			profile["glow_pressure_scale"] = Vector2(0.18, 0.12)
			profile["core_size"] = Vector2(8.0, 8.0)
			profile["pressure_start"] = 0.72
			profile["pressure_gain"] = 1.06
		"sovereign":
			profile["trail_width"] = 6.8
			profile["trail_pressure_width"] = 2.8
			profile["trail_back"] = 40.0
			profile["trail_front"] = 12.0
			profile["trail_pressure_back"] = 24.0
			profile["trail_pressure_front"] = 7.0
			profile["glow_alpha"] = 0.18
			profile["body_base_scale"] = Vector2(1.24, 1.06)
			profile["body_pressure_scale"] = Vector2(0.16, 0.10)
			profile["glow_base_scale"] = Vector2(1.22, 1.02)
			profile["glow_pressure_scale"] = Vector2(0.24, 0.14)
			profile["core_size"] = Vector2(12.0, 8.0)
			profile["pressure_start"] = 0.70
			profile["pressure_gain"] = 1.12
		_:
			pass

	for key in source.keys():
		profile[key] = source[key]

	# Strong visual scale-down for on-field threats (gameplay radii unchanged).
	const THREAT_VISUAL_MULT: float = 0.72
	profile["body_base_scale"] = profile["body_base_scale"] * THREAT_VISUAL_MULT
	profile["glow_base_scale"] = profile["glow_base_scale"] * THREAT_VISUAL_MULT
	profile["core_size"] = profile["core_size"] * THREAT_VISUAL_MULT
	profile["trail_width"] = float(profile["trail_width"]) * 0.85
	profile["trail_pressure_width"] = float(profile["trail_pressure_width"]) * 0.85

	return profile


func _configure_telegraph_shape() -> void:
	if _glow == null or _trail == null or _core == null:
		return

	var mod_key: String = String(telegraph_profile.get("shot_modifier", telegraph_profile.get("family", "fang")))
	match mod_key:
		"mass":
			_glow.polygon = PackedVector2Array([
				Vector2(-22.0, 0.0),
				Vector2(-14.0, -12.0),
				Vector2(6.0, -12.0),
				Vector2(20.0, -4.0),
				Vector2(20.0, 4.0),
				Vector2(6.0, 12.0),
				Vector2(-14.0, 12.0)
			])
		"needle":
			_glow.polygon = PackedVector2Array([
				Vector2(-26.0, 0.0),
				Vector2(-6.0, -6.0),
				Vector2(20.0, 0.0),
				Vector2(-6.0, 6.0)
			])
		"veil":
			_glow.polygon = PackedVector2Array([
				Vector2(-24.0, 0.0),
				Vector2(-12.0, -12.0),
				Vector2(8.0, -14.0),
				Vector2(18.0, 0.0),
				Vector2(8.0, 14.0),
				Vector2(-12.0, 12.0)
			])
		"chorus":
			_glow.polygon = PackedVector2Array([
				Vector2(-22.0, 0.0),
				Vector2(-10.0, -10.0),
				Vector2(4.0, -6.0),
				Vector2(20.0, -2.0),
				Vector2(20.0, 2.0),
				Vector2(4.0, 6.0),
				Vector2(-10.0, 10.0)
			])
		"sovereign":
			_glow.polygon = PackedVector2Array([
				Vector2(-24.0, 0.0),
				Vector2(-14.0, -12.0),
				Vector2(0.0, -14.0),
				Vector2(20.0, -6.0),
				Vector2(24.0, 0.0),
				Vector2(20.0, 6.0),
				Vector2(0.0, 14.0),
				Vector2(-14.0, 12.0)
			])
		_:
			_glow.polygon = PackedVector2Array([
				Vector2(-18.0, 0.0),
				Vector2(-8.0, -10.0),
				Vector2(12.0, -10.0),
				Vector2(20.0, 0.0),
				Vector2(12.0, 10.0),
				Vector2(-8.0, 10.0)
			])

	var core_size: Vector2 = telegraph_profile.get("core_size", Vector2(10.0, 6.0))
	_core.size = core_size
	_core.position = -core_size * 0.5


func _refresh_modifier_overlay() -> void:
	if _modifier == null:
		return
	var mod_id: String = String(telegraph_profile.get("shot_modifier", "fang"))
	var mod_path: String = String(SHOT_MODIFIER_TEXTURES.get(mod_id, DEFAULT_SHOT_MODIFIER_PATH))
	if ResourceLoader.exists(mod_path):
		_modifier.texture = load(mod_path) as Texture2D


func _refresh_body_sprite() -> void:
	if _body == null:
		return

	var path: String = String(telegraph_profile.get("sprite_path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		path = String(telegraph_profile.get("projectile_body_path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		path = DEFAULT_PROJECTILE_BODY_PATH

	if ResourceLoader.exists(path):
		_body.texture = load(path) as Texture2D
