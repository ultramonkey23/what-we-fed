extends RefCounted
class_name SectorLayout

# Owns all sector geometry: spawn ring distance, hit-zone distance, lane/angle mapping,
# and the visual-offset spread constants used by ZoneManager's striker placement.

const THREAT_COUNT: int = 8
const SPAWN_DISTANCE_RATIO: float = 0.42
const HIT_ZONE_DISTANCE: float = 110.0
const STRIKER_VISUAL_TANGENT_SPREAD: float = 32.0
const STRIKER_VISUAL_RADIAL_SPREAD: float = 18.0

var viewport_size: Vector2 = Vector2.ZERO
var center_pos: Vector2 = Vector2.ZERO

var _spawn_positions: Array[Vector2] = []
var _hit_zone_positions: Array[Vector2] = []


func setup(size: Vector2) -> void:
	var safe_size: Vector2 = size
	if safe_size.x < 10.0 or safe_size.y < 10.0:
		safe_size = Vector2(1280.0, 720.0)

	viewport_size = safe_size
	center_pos = safe_size * 0.5

	_spawn_positions.clear()
	_hit_zone_positions.clear()

	var spawn_dist: float = safe_size.y * SPAWN_DISTANCE_RATIO
	for i in range(THREAT_COUNT):
		var angle: float = (float(i) / float(THREAT_COUNT)) * TAU - PI / 2.0
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		_spawn_positions.append(center_pos + dir * spawn_dist)
		_hit_zone_positions.append(center_pos + dir * HIT_ZONE_DISTANCE)


func spawn_distance() -> float:
	return viewport_size.y * SPAWN_DISTANCE_RATIO


func get_spawn_pos(lane: int) -> Vector2:
	if lane < 0 or lane >= _spawn_positions.size():
		return center_pos
	return _spawn_positions[lane]


func get_hit_zone_pos(lane: int) -> Vector2:
	if lane < 0 or lane >= _hit_zone_positions.size():
		return center_pos
	return _hit_zone_positions[lane]


func get_spawn_pos_for_angle(angle: float) -> Vector2:
	return center_pos + Vector2(cos(angle), sin(angle)) * spawn_distance()


func get_hit_zone_pos_for_angle(angle: float) -> Vector2:
	return center_pos + Vector2(cos(angle), sin(angle)) * HIT_ZONE_DISTANCE


func get_lane_from_angle(angle: float) -> int:
	var sector: float = TAU / 8.0
	var norm_angle: float = fposmod(angle + PI / 2.0 + sector / 2.0, TAU)
	return int(floor(norm_angle / sector)) % 8
