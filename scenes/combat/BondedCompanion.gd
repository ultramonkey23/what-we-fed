extends Node2D

const COMBAT_DATA_CONTENT = preload("res://data/CombatContent.gd")
const MOTION_JUICE = preload("res://systems/MotionJuice.gd")

var species_id: String = ""
var player_combat: Node2D = null
var zone_manager: Node = null

var _sprite: Sprite2D
var _attack_timer: float = 0.0
var _attack_interval: float = 2.4 # Faster auto-attack (Glass Cannon feel)
var _target_enemy_id: int = -1

var _follow_offset: Vector2 = Vector2(-42.0, -28.0) # Over-the-shoulder
var _follow_speed: float = 8.5
var _is_attacking: bool = false
var _idle_tex: Texture2D = null

func setup(p_species_id: String, p_player: Node2D, p_zone_manager: Node) -> void:
	species_id = p_species_id
	player_combat = p_player
	zone_manager = p_zone_manager
	
	_setup_visuals()
	
	# Initial positioning
	if player_combat:
		global_position = player_combat.global_position + _follow_offset
		
	if not EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.connect(_on_player_took_damage)


func _exit_tree() -> void:
	if EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.disconnect(_on_player_took_damage)


func _on_player_took_damage(_amount: float, _sector_id: int) -> void:
	animate_hurt()


func _setup_visuals() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	
	var path: String = COMBAT_DATA_CONTENT.get_creature_art_path(species_id, "battlefield", "adult")
	if not ResourceLoader.exists(path):
		path = COMBAT_DATA_CONTENT.get_creature_art_path(species_id, "battlefield", "teen")
		
	if ResourceLoader.exists(path):
		_idle_tex = load(path) as Texture2D
		if _idle_tex:
			_sprite.texture = _idle_tex
			_sprite.hframes = clampi(int(float(_idle_tex.get_width()) / _idle_tex.get_height()), 1, 64)
			_sprite.frame = 0
		
	var render = COMBAT_DATA_CONTENT.get_creature_combat_render(species_id)
	
	# DYNAMIC GROWTH SCALING: Size increases with bond level (Age)
	var bond_level: int = 1
	var bonded_data: Dictionary = GameState.get_bonded_creature(species_id)
	if not bonded_data.is_empty():
		bond_level = int(bonded_data.get("bond_level", 1))
	
	var growth_stage: String = GameState.get_creature_growth_stage(bond_level)
	var age_scales: Dictionary = render.get("age_scales", {})
	var base_scale: float = float(age_scales.get(growth_stage, render.get("scale", 0.052)))
	
	_sprite.scale = Vector2.ONE * base_scale * 0.82
	_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) # Full opaque


func _process(delta: float) -> void:
	if player_combat == null or not is_instance_valid(player_combat):
		return
	
	# PERSISTENT FACING DOCTRINE: Companions maintain focus on the Vessel or the Prey.
	if not _is_attacking:
		var target_pos: Vector2 = player_combat.global_position + _follow_offset.rotated(player_combat.rotation)
		global_position = global_position.lerp(target_pos, _follow_speed * delta)
		
		# IDLE FACING: Always focus on the Vessel (Player)
		var angle_to_player = (player_combat.global_position - global_position).angle()
		rotation = lerp_angle(rotation, angle_to_player - PI/2, 6.0 * delta)
	else:
		# COMBAT FACING: Focus on the specific Prey target
		if _target_enemy_id != -1 and zone_manager != null and is_instance_valid(zone_manager):
			var e_pos = zone_manager.get_enemy_pos(_target_enemy_id)
			var angle_to_enemy = (e_pos - global_position).angle()
			rotation = lerp_angle(rotation, angle_to_enemy - PI/2, 14.0 * delta)

	# Auto-Attack Logic
	if not _is_attacking:
		_attack_timer += delta
		if _attack_timer >= _attack_interval:
			_try_auto_attack()


func _try_auto_attack() -> void:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return
	
	var enemies: Dictionary = zone_manager.get_all_enemies()
	if enemies.is_empty():
		return
	
	var closest_id: int = -1
	var min_dist: float = 99999.0
	for id in enemies.keys():
		var e_pos: Vector2 = zone_manager.get_enemy_pos(id)
		var d: float = global_position.distance_to(e_pos)
		if d < min_dist:
			min_dist = d
			closest_id = id
			
	if closest_id != -1:
		_execute_attack(closest_id)
		_attack_timer = 0.0


func _execute_attack(enemy_id: int) -> void:
	_is_attacking = true
	_target_enemy_id = enemy_id
	
	var e_pos: Vector2 = zone_manager.get_enemy_pos(enemy_id)
	var orig_pos: Vector2 = global_position
	
	# Visual Trail
	_spawn_dash_trail(orig_pos, e_pos)
	
	var tween: Tween = create_tween()
	
	# Swap to attack frame
	var atk_path: String = COMBAT_CONTENT.get_creature_art_path(species_id, "attack", "adult")
	if not ResourceLoader.exists(atk_path): atk_path = COMBAT_CONTENT.get_creature_art_path(species_id, "attack", "teen")
	
	if ResourceLoader.exists(atk_path):
		var atk_tex = load(atk_path) as Texture2D
		if atk_tex:
			_sprite.texture = atk_tex
			_sprite.hframes = clampi(int(float(atk_tex.get_width()) / atk_tex.get_height()), 1, 64)
			_sprite.frame = 0

	# Strike (Super Fast)
	tween.tween_property(self, "global_position", e_pos, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): 
		if zone_manager and is_instance_valid(zone_manager):
			# SCALED DAMAGE: Glass Cannon doctrine
			var base_dmg: float = 5.0 + (GameState.stat_power * 0.22)
			zone_manager.damage_enemy_by_id(enemy_id, base_dmg)
			
			# Apply Blood-Ember synergy (Bleed)
			zone_manager.apply_status_by_id(enemy_id, "bleed", {})
			
			EventBus.emit_signal("play_sfx", "ashclaw_strike_short")
			EventBus.emit_signal("ui_shake", 0.6, 0.06)
			_spawn_impact_visual(e_pos)
	)
	
	tween.tween_interval(0.10)
	
	# Return
	tween.tween_property(self, "global_position", orig_pos, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.finished.connect(func():
		_is_attacking = false
		_target_enemy_id = -1
		_restore_idle_texture(_idle_tex)
	)


func animate_hurt() -> void:
	if _is_attacking: return
	
	var hurt_path: String = COMBAT_CONTENT.get_creature_art_path(species_id, "hurt", "adult")
	if ResourceLoader.exists(hurt_path):
		var hurt_tex = load(hurt_path) as Texture2D
		if hurt_tex:
			var old_tex = _sprite.texture
			_sprite.texture = hurt_tex
			_sprite.hframes = clampi(int(float(hurt_tex.get_width()) / hurt_tex.get_height()), 1, 64)
			_sprite.frame = 0
			
			var tree = get_tree()
			if tree:
				var t := tree.create_timer(0.3)
				t.timeout.connect(_restore_idle_texture.bind(old_tex))
	
	var tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.2)


func _restore_idle_texture(target_tex: Texture2D) -> void:
	if is_instance_valid(_sprite) and target_tex != null:
		_sprite.texture = target_tex
		_sprite.hframes = clampi(int(float(target_tex.get_width()) / target_tex.get_height()), 1, 64)
		_sprite.frame = 0


func _spawn_dash_trail(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	get_parent().add_child(line)
	line.points = PackedVector2Array([from, to])
	line.width = 12.0
	line.default_color = Color(1.0, 0.45, 0.18, 0.65) # Ember
	var tween := line.create_tween()
	tween.tween_property(line, "width", 0.0, 0.15)
	tween.parallel().tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)


func _spawn_impact_visual(pos: Vector2) -> void:
	# Diegetic hit reaction
	if get_parent().has_method("_spawn_ink_splatter"):
		get_parent().call("_spawn_ink_splatter", pos, Color(0.85, 0.22, 0.15, 0.95))
