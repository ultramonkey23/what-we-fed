extends Node2D
class_name ThreatBase

# Shared interface for Projectile and MeleeApproach.
# Owns the properties and virtual methods that PlayerCombat dispatches on the
# hot path so those calls can be statically typed instead of duck-typed .call().

signal reached_hit_zone(threat: ThreatBase)
signal player_contact(threat: ThreatBase)
@warning_ignore("unused_signal")
signal enemy_contact(threat: ThreatBase)
signal resolved(threat: ThreatBase, result: String)

var lane: int = 0
var enemy_id: int = -1
var damage: float = 0.0
var speed: float = 0.0
var reflected_damage: float = 0.0
var telegraph_profile: Dictionary = {}
var player_ref: Node2D = null
var is_resolved: bool = false
var is_reflected: bool = false
var progress: float = 0.0


func evaluate_attack_timing() -> String:
	return "miss"


func evaluate_parry_timing() -> String:
	return "miss"


func evaluate_proximity_timing(_attacker_pos: Vector2) -> String:
	return "miss"


func resolve(_result: String) -> void:
	pass


func reflect_to_enemy(_return_damage: float) -> void:
	pass


func reflect_to_enemy_at(return_damage: float, _target_pos: Vector2) -> void:
	reflect_to_enemy(return_damage)


func time_until_hit_zone() -> float:
	return -1.0


func time_until_player_contact() -> float:
	return -1.0
