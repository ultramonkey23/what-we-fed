extends Node2D

## Short-lived Sprite2D impacts for resolved combat outcomes only (driven by CombatScene signal).

const KIND_PERFECT := &"perfect"
const KIND_PARRY := &"parry"
const KIND_MISS := &"miss"
const KIND_DODGE := &"dodge"
const KIND_ELITE := &"elite"
const KIND_BOSS := &"boss"

@export var texture_perfect: Texture2D
@export var texture_parry: Texture2D
@export var texture_miss: Texture2D
@export var texture_dodge: Texture2D
@export var texture_elite: Texture2D
@export var texture_boss: Texture2D


func _ready() -> void:
	z_index = 31
	_fill_default_textures()
	var host: Node = get_parent()
	if host != null and host.has_signal("impact_fx_requested"):
		if not host.impact_fx_requested.is_connected(_on_impact_fx_requested):
			host.impact_fx_requested.connect(_on_impact_fx_requested)


func _exit_tree() -> void:
	var host: Node = get_parent()
	if host != null and host.has_signal("impact_fx_requested") and host.impact_fx_requested.is_connected(_on_impact_fx_requested):
		host.impact_fx_requested.disconnect(_on_impact_fx_requested)


func _fill_default_textures() -> void:
	if texture_perfect == null:
		texture_perfect = load("res://art/vfx/impact/impact_perfect.png") as Texture2D
	if texture_parry == null:
		texture_parry = load("res://art/vfx/impact/impact_parry.png") as Texture2D
	if texture_miss == null:
		texture_miss = load("res://art/vfx/impact/impact_miss.png") as Texture2D
	if texture_dodge == null:
		texture_dodge = load("res://art/vfx/impact/impact_dodge.png") as Texture2D
	if texture_elite == null:
		texture_elite = load("res://art/vfx/impact/impact_elite.png") as Texture2D
	if texture_boss == null:
		texture_boss = load("res://art/vfx/impact/impact_boss.png") as Texture2D


func _on_impact_fx_requested(kind: StringName, world_pos: Vector2, direction: Vector2, scale_mult: float) -> void:
	spawn(kind, world_pos, direction, scale_mult)


func spawn(kind: StringName, world_pos: Vector2, direction: Vector2, scale_mult: float) -> void:
	var tex: Texture2D = _texture_for_kind(kind)
	if tex == null:
		return

	var cfg := _config_for_kind(kind)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	spr.position = world_pos
	spr.z_index = 1

	var dir := direction
	if dir.length_squared() < 0.000001:
		dir = Vector2.RIGHT
	var angle: float = dir.angle()
	var angle_jitter_deg: float = float(cfg.get("angle_jitter_deg", 0.0))
	if angle_jitter_deg > 0.0:
		angle += deg_to_rad(randf_range(-angle_jitter_deg, angle_jitter_deg))
	spr.rotation = angle

	var min_scale_mult: float = float(cfg.get("min_scale_mult", 0.12))
	var s: float = cfg.base_scale * maxf(scale_mult, min_scale_mult)
	if cfg.thin_stretch:
		spr.scale = Vector2(s * 1.12, s * 0.48)
	else:
		spr.scale = Vector2(s, s)

	spr.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(spr)

	var rise: float = float(cfg.get("rise", 0.038))
	var hold: float = float(cfg.get("hold", 0.020))
	var fade_time: float = maxf(float(cfg.get("lifetime", 0.10)) - rise - hold, 0.05)
	var t := create_tween()
	t.tween_property(spr, "modulate:a", cfg.peak_alpha, rise)
	if hold > 0.0:
		t.tween_interval(hold)
	t.tween_property(spr, "modulate:a", 0.0, fade_time)
	t.parallel().tween_property(spr, "scale", spr.scale * cfg.end_scale_mul, fade_time)
	t.tween_callback(func() -> void:
		if is_instance_valid(spr):
			spr.queue_free()
	)


func _texture_for_kind(kind: StringName) -> Texture2D:
	match kind:
		KIND_PERFECT:
			return texture_perfect
		KIND_PARRY:
			return texture_parry
		KIND_MISS:
			return texture_miss
		KIND_DODGE:
			return texture_dodge
		KIND_ELITE:
			return texture_elite
		KIND_BOSS:
			return texture_boss
		_:
			return null


func _config_for_kind(kind: StringName) -> Dictionary:
	match kind:
		KIND_PERFECT:
			return {"base_scale": 0.225, "lifetime": 0.16, "peak_alpha": 0.96, "thin_stretch": false, "end_scale_mul": 1.08, "rise": 0.040, "hold": 0.020}
		KIND_PARRY:
			return {"base_scale": 0.205, "lifetime": 0.145, "peak_alpha": 0.94, "thin_stretch": false, "end_scale_mul": 1.07, "rise": 0.038, "hold": 0.018}
		KIND_MISS:
			return {"base_scale": 0.16, "lifetime": 0.105, "peak_alpha": 0.80, "thin_stretch": true, "end_scale_mul": 1.14, "rise": 0.030, "hold": 0.010, "min_scale_mult": 0.82, "angle_jitter_deg": 5.0}
		KIND_DODGE:
			return {"base_scale": 0.15, "lifetime": 0.11, "peak_alpha": 0.76, "thin_stretch": true, "end_scale_mul": 1.11, "rise": 0.032, "hold": 0.012, "min_scale_mult": 0.86, "angle_jitter_deg": 4.0}
		KIND_ELITE:
			return {"base_scale": 0.215, "lifetime": 0.13, "peak_alpha": 0.92, "thin_stretch": false, "end_scale_mul": 1.06, "rise": 0.034, "hold": 0.014}
		KIND_BOSS:
			return {"base_scale": 0.265, "lifetime": 0.16, "peak_alpha": 0.98, "thin_stretch": false, "end_scale_mul": 1.09, "rise": 0.042, "hold": 0.020}
		_:
			return {"base_scale": 0.18, "lifetime": 0.10, "peak_alpha": 0.80, "thin_stretch": false, "end_scale_mul": 1.0}
