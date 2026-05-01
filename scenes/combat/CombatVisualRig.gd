extends Node2D
## Editor-authorable presentation rig for combat. Parent node is snapped to the lane logical
## center each frame so Marker2D children act as stable world-space anchors relative to the player.
##
## Gameplay / timing / hit zones are unchanged; only presentation reads this node.

@export_group("Enemy visuals (lane 2 = East, lane 3 = West)")
@export var apply_east_west_anchor_offsets: bool = true

@export_group("Sigil / Bone-Ink beat spine")
## Extra local offset for the vertical beat spine (Line2D named BeatMark) inside TimingRing_Core.
@export var sigil_bone_ink_local_offset: Vector2 = Vector2.ZERO
## Added to the aim-at-focus-lane rotation (radians).
@export var sigil_bone_ink_rotation_offset: float = 0.0

@export_group("Player visual facing")
## Added to atan2(threat) so the combat art reads correctly when facing each lane.
@export var player_visual_facing_angle_offset: float = -PI * 0.5
@export var player_facing_lerp_weight: float = 0.22

@onready var enemy_anchor_east: Marker2D = $EnemyVisualEast
@onready var enemy_anchor_west: Marker2D = $EnemyVisualWest
@onready var sigil_direction_pivot: Node2D = $SigilDirectionPivot


func resolve_enemy_marker_world_pos(lane: int, baseline: Vector2, zone_manager: Node) -> Vector2:
	if not apply_east_west_anchor_offsets:
		return baseline
	if zone_manager == null or not zone_manager.has_method("get_threat_spawn_pos"):
		return baseline

	var spawn: Vector2 = zone_manager.call("get_threat_spawn_pos", lane)
	var anchor: Marker2D = null
	if lane == 2:
		anchor = enemy_anchor_east
	elif lane == 3:
		anchor = enemy_anchor_west
	if anchor == null or not is_instance_valid(anchor):
		return baseline

	return anchor.global_position + (baseline - spawn)


func get_sigil_bone_ink_local_offset() -> Vector2:
	var pivot_off := Vector2.ZERO
	if sigil_direction_pivot != null and is_instance_valid(sigil_direction_pivot):
		pivot_off = sigil_direction_pivot.position
	return pivot_off + sigil_bone_ink_local_offset


func get_sigil_bone_ink_rotation_offset() -> float:
	var pivot_rot := 0.0
	if sigil_direction_pivot != null and is_instance_valid(sigil_direction_pivot):
		pivot_rot = sigil_direction_pivot.rotation
	return pivot_rot + sigil_bone_ink_rotation_offset


func get_player_visual_facing_angle_offset() -> float:
	return player_visual_facing_angle_offset


func get_player_facing_lerp_weight() -> float:
	return clampf(player_facing_lerp_weight, 0.05, 1.0)
