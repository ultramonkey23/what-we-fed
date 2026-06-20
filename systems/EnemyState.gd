class_name EnemyState extends RefCounted

var id: int = -1
var population_data: Dictionary = {}
var striker_data: Dictionary = {}
var position: Vector2 = Vector2.ZERO
var orbit_angle: float = 0.0
var orbit_radius_offset: float = 0.0
var visual_offset: Vector2 = Vector2.ZERO
var projectile_scene: PackedScene = null
var striker_object: RefCounted = null

func setup(
	p_id: int,
	p_population_data: Dictionary,
	p_striker_data: Dictionary,
	p_position: Vector2,
	p_orbit_angle: float,
	p_orbit_radius_offset: float,
	p_visual_offset: Vector2,
	p_projectile_scene: PackedScene,
	p_striker_object: RefCounted
) -> void:
	id = p_id
	population_data = p_population_data
	striker_data = p_striker_data
	position = p_position
	orbit_angle = p_orbit_angle
	orbit_radius_offset = p_orbit_radius_offset
	visual_offset = p_visual_offset
	projectile_scene = p_projectile_scene
	striker_object = p_striker_object
