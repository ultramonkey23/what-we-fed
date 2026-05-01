class_name EnemyStriker
extends RefCounted

## Owns attack-execution logic for one enemy in the ZoneManager.
## ZoneManager decides WHEN and WHO fires; this class owns HOW:
## damage scaling, speed scaling, Bloodscent, and telegraph profile.

const PALE_DAMAGE_MULT: float = 0.50

var enemy: Dictionary = {}
var projectile_scene: PackedScene = null


func setup(p_enemy: Dictionary, p_scene: PackedScene) -> void:
	enemy = p_enemy
	projectile_scene = p_scene


func is_melee() -> bool:
	var tags: Variant = enemy.get("behaviour_tags", [])
	return tags is Array and (tags as Array).has("melee")


func compute_projectile_damage(punish_mult: float, pale_active: bool) -> float:
	var dmg: float = float(enemy.get("damage", 8.0)) * punish_mult
	if enemy.get("species_id") == "ashclaw":
		var bleed: int = GameState.player_bleed_stacks
		if bleed > 0:
			dmg *= 1.0 + 0.10 * float(bleed)
	if pale_active:
		dmg *= PALE_DAMAGE_MULT
	return dmg


func compute_projectile_speed(base_speed: float) -> float:
	if enemy.get("species_id") == "ashclaw":
		var bleed: int = GameState.player_bleed_stacks
		if bleed > 0:
			return base_speed * (1.0 + 0.15 * float(bleed))
	return base_speed


func compute_melee_damage(punish_mult: float) -> float:
	var dmg: float = float(enemy.get("damage", 14.0)) * punish_mult
	if enemy.get("species_id") == "ashclaw":
		var bleed: int = GameState.player_bleed_stacks
		if bleed > 0:
			dmg *= 1.0 + 0.10 * float(bleed)
	return dmg


func compute_approach_speed() -> float:
	var speed: float = float(enemy.get("approach_speed", 80.0))
	if enemy.get("species_id") == "ashclaw":
		var bleed: int = GameState.player_bleed_stacks
		if bleed > 0:
			speed *= 1.0 + 0.15 * float(bleed)
	return speed


func build_telegraph_profile(section_id: String) -> Dictionary:
	var profile: Dictionary = COMBAT_CONTENT.get_enemy_telegraph_profile(enemy)
	profile["projectile_body_path"] = COMBAT_CONTENT.get_projectile_body_resource_path(enemy)
	var section_mod: String = COMBAT_CONTENT.get_shot_modifier_for_section(section_id)
	var species_mod: String = String(profile.get("species_shot_modifier", "")).strip_edges()
	if not species_mod.is_empty():
		profile["shot_modifier"] = species_mod
	else:
		profile["shot_modifier"] = section_mod
	profile.erase("species_shot_modifier")
	return profile
