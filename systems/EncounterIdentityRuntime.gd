extends RefCounted

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const REGION_SONG_CONTENT = preload("res://data/RegionSongContent.gd")
const IDENTITY_CONTENT = preload("res://data/EncounterIdentityContent.gd")
const RUN_PACING_CONTENT = preload("res://data/RunPacingContent.gd")
const POTENTIAL_GATE = preload("res://systems/PotentialGate.gd")


static func build_song_run(region_id: String, regular_level_index: int = 0, level_duration: float = 120.0, options: Dictionary = {}) -> Dictionary:
	var resolved_region_id: String = region_id if not region_id.is_empty() else "feeding_hollow"
	var base_phases: Array = REGION_SONG_CONTENT.get_song_phases(resolved_region_id)
	var scaled_phases: Array = _build_scaled_song_level_phases(
		resolved_region_id,
		base_phases,
		regular_level_index,
		level_duration,
		options
	)
	return {
		"region_id": resolved_region_id,
		"biome": _get_biome_for_region(resolved_region_id),
		"identity": IDENTITY_CONTENT.get_region_identity(resolved_region_id),
		"phases": scaled_phases
	}


static func build_live_boss_encounter() -> Dictionary:
	var boss_encounter: Dictionary = COMBAT_CONTENT.get_encounter("feeding_hollow_boss")
	boss_encounter["reward_creature_pool"] = [COMBAT_CONTENT.get_creature("thornback")]
	return boss_encounter


static func get_phase_display_label(region_id: String, phase: Dictionary) -> String:
	var base_label: String = String(phase.get("label", ""))
	var style: Dictionary = IDENTITY_CONTENT.get_phase_style(region_id, String(phase.get("id", "")))
	var tag: String = String(style.get("tag", ""))
	if base_label.is_empty():
		return tag
	if tag.is_empty():
		return base_label
	return "%s  /  %s" % [base_label, tag]


static func get_phase_intro_text(region_id: String, phase: Dictionary) -> String:
	var intro_text: String = String(phase.get("intro_text", ""))
	var identity: Dictionary = IDENTITY_CONTENT.get_region_identity(region_id)
	var pressure_name: String = String(identity.get("pressure_name", ""))
	if intro_text.is_empty() or pressure_name.is_empty():
		return intro_text
	return "%s  [%s]" % [intro_text, pressure_name]


static func order_empty_lanes(
	region_id: String,
	phase: Dictionary,
	empty_lanes: Array,
	player_lane: int,
	rng: RandomNumberGenerator
) -> Array:
	var lanes: Array = empty_lanes.duplicate()
	if lanes.is_empty():
		return lanes

	var style: Dictionary = IDENTITY_CONTENT.get_phase_style(region_id, String(phase.get("id", "")))
	var spawn_mode: String = String(style.get("spawn_mode", "spread"))
	var preferred_order: Array = _preferred_lane_order(spawn_mode, player_lane, rng)
	var ordered: Array = []

	for lane in preferred_order:
		if lanes.has(lane):
			ordered.append(lane)

	for lane in lanes:
		if not ordered.has(lane):
			ordered.append(lane)

	return ordered


static func pick_weighted_enemy(phase: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = phase.get("enemy_pool", [])
	if pool.is_empty():
		return {}

	var total_weight: float = 0.0
	for entry in pool:
		total_weight += float(entry.get("weight", 1.0))

	var roll: float = rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for entry in pool:
		cursor += float(entry.get("weight", 1.0))
		if roll <= cursor:
			return entry.duplicate(true)

	return pool.back().duplicate(true)


static func _get_biome_for_region(region_id: String) -> Dictionary:
	match region_id:
		"pale_shelf":
			return COMBAT_CONTENT.BIOME_PALE_SHELF.duplicate(true)
		"drowned_cut":
			return COMBAT_CONTENT.BIOME_DROWNED_CUT.duplicate(true)
		_:
			return COMBAT_CONTENT.BIOME_FEEDING_HOLLOW.duplicate(true)


static func _preferred_lane_order(spawn_mode: String, player_lane: int, rng: RandomNumberGenerator) -> Array:
	match spawn_mode:
		"track_player":
			match player_lane:
				0:
					return [0, 1, 2, 3]
				1:
					return [1, 0, 2, 3]
				2:
					return [2, 1, 0, 3]
				3:
					return [3, 1, 0, 2]
				_:
					return [1, 0, 2, 3]
		"center_bias":
			return [1, 0, 2, 3]
		"edge_bias":
			if rng.randi() % 2 == 0:
				return [0, 2, 3, 1]
			return [2, 3, 0, 1]
		"flank_player":
			match player_lane:
				0:
					return [2, 3, 1, 0]
				1:
					if rng.randi() % 2 == 0:
						return [0, 2, 3, 1]
					return [2, 3, 0, 1]
				2:
					return [0, 3, 1, 2]
				3:
					return [2, 0, 1, 3]
				_:
					if rng.randi() % 2 == 0:
						return [0, 2, 3, 1]
					return [2, 3, 0, 1]
		"collapse":
			var order: Array = []
			order.append(player_lane)
			order.append(1)
			order.append(0)
			order.append(2)
			order.append(3)
			return _unique_lane_order(order)
		"spread":
			if rng.randi() % 2 == 0:
				return [0, 2, 3, 1]
			return [2, 3, 0, 1]
		_:
			return [0, 1, 2, 3]


static func _unique_lane_order(order: Array) -> Array:
	var unique: Array = []
	for lane in order:
		if not unique.has(lane):
			unique.append(lane)
	return unique


static func _build_scaled_song_level_phases(
	region_id: String,
	source_phases: Array,
	regular_level_index: int,
	level_duration: float,
	options: Dictionary = {}
) -> Array:
	var scaled: Array = []
	if source_phases.is_empty():
		return scaled
	var safe_duration: float = max(level_duration, 20.0)
	var phase_fractions: Array[float] = RUN_PACING_CONTENT.get_phase_start_fractions()
	var scaling: Dictionary = RUN_PACING_CONTENT.get_level_scaling(region_id, regular_level_index)
	var cycle_mult: float = float(scaling.get("cycle_interval_mult", 1.0))
	var stagger_mult: float = float(scaling.get("fire_stagger_mult", 1.0))
	var threat_bonus: int = int(scaling.get("max_active_threats_bonus", 0))
	var hp_mult: float = float(scaling.get("enemy_hp_mult", 1.0))
	var damage_mult: float = float(scaling.get("enemy_damage_mult", 1.0))
	var projectile_speed_mult: float = float(scaling.get("enemy_projectile_speed_mult", 1.0))
	var grade_ceiling_id: String = POTENTIAL_GATE.normalize_grade_id(String(options.get("grade_ceiling_id", POTENTIAL_GATE.GRADE_ALPHA)))
	var elite_mode: bool = bool(options.get("elite", false))
	var difficulty_modifiers: Dictionary = Dictionary(options.get("difficulty_modifiers", {}))
	var threat_quality_band: Dictionary = Dictionary(difficulty_modifiers.get("threat_quality", {}))
	var high_grade_weight_mult: float = clampf(float(threat_quality_band.get("high_grade_weight_mult", 1.0)), 0.7, 2.0)
	if elite_mode:
		cycle_mult *= float(options.get("cycle_interval_mult", 0.92))
		threat_bonus += int(options.get("max_active_threats_bonus", 1))
		hp_mult *= float(options.get("enemy_hp_mult", 1.18))
		damage_mult *= float(options.get("enemy_damage_mult", 1.12))
		projectile_speed_mult *= float(options.get("enemy_projectile_speed_mult", 1.05))

	for i in range(source_phases.size()):
		var phase: Dictionary = Dictionary(source_phases[i]).duplicate(true)
		var start_fraction: float = phase_fractions[i] if i < phase_fractions.size() else clampf(float(i) / float(max(source_phases.size() - 1, 1)), 0.0, 1.0)
		phase["start_time"] = start_fraction * safe_duration
		phase["cycle_interval"] = max(float(phase.get("cycle_interval", 2.2)) * cycle_mult, 0.35)
		phase["fire_stagger"] = clampf(float(phase.get("fire_stagger", 0.45)) * stagger_mult, 0.42, 0.90)
		phase["max_active_threats"] = clampi(int(phase.get("max_active_threats", 2)) + threat_bonus, 1, 5)

		var pool: Array = phase.get("enemy_pool", [])
		var scaled_pool: Array = []
		for enemy in pool:
			var scaled_enemy: Dictionary = Dictionary(enemy).duplicate(true)
			var enemy_grade_id: String = String(scaled_enemy.get("grade", POTENTIAL_GATE.GRADE_MATURE))
			scaled_enemy["grade"] = POTENTIAL_GATE.clamp_grade_id(enemy_grade_id, grade_ceiling_id)
			if String(scaled_enemy.get("grade", POTENTIAL_GATE.GRADE_BROOD)) == POTENTIAL_GATE.GRADE_ALPHA:
				scaled_enemy["weight"] = float(scaled_enemy.get("weight", 1.0)) * high_grade_weight_mult
			scaled_enemy["hp"] = float(scaled_enemy.get("hp", 28.0)) * hp_mult
			scaled_enemy["damage"] = float(scaled_enemy.get("damage", 8.0)) * damage_mult
			if scaled_enemy.has("projectile_speed"):
				scaled_enemy["projectile_speed"] = float(scaled_enemy.get("projectile_speed", 265.0)) * projectile_speed_mult
			scaled_pool.append(scaled_enemy)
		phase["enemy_pool"] = scaled_pool
		scaled.append(phase)
	return scaled
