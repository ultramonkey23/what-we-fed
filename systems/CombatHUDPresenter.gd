extends RefCounted

# ── Bound node references ─────────────────────────────────────────────────────
# All nodes are created and owned by CombatScene.
# This presenter holds references only — it never frees them.

# Static HUD nodes (from @onready in CombatScene)
var _combo_label: Label
var _style_label: Label
var _stamina_bar: ProgressBar
var _hp_bar: ProgressBar
var _ultimate_label: Label
var _controls_label: Label

# Dynamic readout labels
var _hp_value_label: Label
var _exp_value_label: Label

# Support readout cluster
var _support_shell: ColorRect
var _support_bar: ProgressBar
var _support_value_label: Label
var _support_name_label: Label
var _support_trigger_label: Label
var _support_creature_portrait: TextureRect
var _support_portrait_species: String = ""

# Run build readout cluster
var _run_build_shell: ColorRect
var _eaten_value_label: Label
var _upgrade_value_label: Label
var _bond_value_label: Label
var _atk_value_label: Label
var _def_value_label: Label
var _dna_route_label: Label

# DNA HUD cluster
var _dna_shell: ColorRect
var _dna_emblem: TextureRect
var _dna_slot_labels: Array[Label] = []

# Boss bar cluster
var _boss_hp_shell: ColorRect
var _boss_hp_bar: ProgressBar
var _boss_name_label: Label
var _boss_state_label: Label

# Song / boss timer HUD
var _song_timer_label: Label
var _song_phase_label: Label

# ── Content preloads (passed from CombatScene at construction) ────────────────
var _combat_content: GDScript
var _presentation_text: GDScript
var _ui_style: GDScript


func _init(combat_content: GDScript, presentation_text: GDScript, ui_style: GDScript) -> void:
	_combat_content = combat_content
	_presentation_text = presentation_text
	_ui_style = ui_style


func bind_nodes(nodes: Dictionary) -> void:
	# Static @onready nodes
	_combo_label = nodes.get("combo_label")
	_style_label = nodes.get("style_label")
	_stamina_bar = nodes.get("stamina_bar")
	_hp_bar = nodes.get("hp_bar")
	_ultimate_label = nodes.get("ultimate_label")
	_controls_label = nodes.get("controls_label")
	# Resource readout
	_hp_value_label = nodes.get("hp_value_label")
	_exp_value_label = nodes.get("exp_value_label")
	# Support cluster
	_support_shell = nodes.get("support_shell")
	_support_bar = nodes.get("support_bar")
	_support_value_label = nodes.get("support_value_label")
	_support_name_label = nodes.get("support_name_label")
	_support_trigger_label = nodes.get("support_trigger_label")
	_support_creature_portrait = nodes.get("support_creature_portrait")
	# Run build cluster
	_run_build_shell = nodes.get("run_build_shell")
	_eaten_value_label = nodes.get("eaten_value_label")
	_upgrade_value_label = nodes.get("upgrade_value_label")
	_bond_value_label = nodes.get("bond_value_label")
	_atk_value_label = nodes.get("atk_value_label")
	_def_value_label = nodes.get("def_value_label")
	_dna_route_label = nodes.get("dna_route_label")
	# DNA HUD cluster
	_dna_shell = nodes.get("dna_shell")
	_dna_emblem = nodes.get("dna_emblem")
	_dna_slot_labels = nodes.get("dna_slot_labels", [] as Array[Label])
	# Boss bar cluster
	_boss_hp_shell = nodes.get("boss_hp_shell")
	_boss_hp_bar = nodes.get("boss_hp_bar")
	_boss_name_label = nodes.get("boss_name_label")
	_boss_state_label = nodes.get("boss_state_label")
	# Song HUD
	_song_timer_label = nodes.get("song_timer_label")
	_song_phase_label = nodes.get("song_phase_label")


# ── Resource HUD ──────────────────────────────────────────────────────────────

func refresh_hp(hp: float, max_hp: float) -> void:
	if _hp_bar != null:
		_hp_bar.max_value = max_hp
		_hp_bar.value = hp
	if _hp_value_label != null:
		_hp_value_label.text = "%d/%d" % [int(hp), int(max_hp)]


func refresh_stamina(current: float, maximum: float) -> void:
	if _stamina_bar != null:
		_stamina_bar.max_value = maximum
		_stamina_bar.value = current


func refresh_combo(count: int, tier: String = "") -> void:
	if _combo_label != null:
		var old_count: int = int(_combo_label.text)
		_combo_label.text = "%d" % count
		if not tier.is_empty():
			_combo_label.modulate = _ui_style.get_tier_color(tier)
		
		if count > old_count:
			var tween := _combo_label.create_tween()
			_combo_label.scale = Vector2(1.24, 1.24)
			tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.12)


func refresh_style(tier: String) -> void:
	if _style_label != null:
		_style_label.text = _ui_style.get_tier_label(tier)
		_style_label.modulate = _ui_style.get_tier_color(tier)


func set_ultimate_text(text: String) -> void:
	if _ultimate_label != null:
		_ultimate_label.text = text


func set_exp_text(level: int, exp: float, exp_to_next: float = -1.0) -> void:
	if _exp_value_label == null:
		return
	if exp_to_next >= 0.0:
		_exp_value_label.text = "L%d  %.0f/%.0f" % [level, exp, exp_to_next]
	else:
		_exp_value_label.text = "L%d  %.0f" % [level, exp]


func set_controls_text(text: String) -> void:
	if _controls_label != null:
		_controls_label.text = text


func refresh_stats(atk: float, def: float) -> void:
	if _atk_value_label != null:
		_atk_value_label.text = "%.0f" % atk
	if _def_value_label != null:
		_def_value_label.text = "%.0f" % def


# ── Support readout ──────────────────────────────────────────────────────────

func refresh_support(current: float, maximum: float, active_species_id: String, run_growth: Node) -> void:
	if _support_bar != null:
		_support_bar.max_value = maximum
		_support_bar.value = current

	if _support_value_label != null:
		var was_ready: bool = _support_value_label.text == "RDY"
		if active_species_id.is_empty():
			_support_value_label.text = "--"
		elif current >= maximum - 0.05:
			_support_value_label.text = "RDY"
			_support_value_label.modulate = Color(0.88, 1.0, 0.90, 1.0)
			if not was_ready:
				var tween := _support_value_label.create_tween()
				_support_value_label.scale = Vector2(1.3, 1.3)
				tween.tween_property(_support_value_label, "scale", Vector2.ONE, 0.15)
		else:
			_support_value_label.text = "%d" % int(floor((current / maximum) * 100.0))
			_support_value_label.modulate = Color(0.98, 0.82, 0.58, 1.0)

	if _support_name_label != null:
		if run_growth != null and is_instance_valid(run_growth) and run_growth.has_method("get_active_display_name"):
			var display_name: String = String(run_growth.call("get_active_display_name"))
			if current >= maximum - 0.05 and not active_species_id.is_empty():
				_support_name_label.text = _presentation_text.support_ready_label(display_name)
			else:
				var bonded: Dictionary = GameState.get_active_bonded_creature()
				var bond_level: int = int(bonded.get("bond_level", 1))
				if bond_level > 1:
					var short_name: String = display_name.left(5).strip_edges()
					_support_name_label.text = "%s L%d" % [short_name, bond_level]
				else:
					_support_name_label.text = compact_hud_copy(display_name, 7)
		else:
			_support_name_label.text = _presentation_text.SUPPORT_EMPTY_NAME

	if _support_creature_portrait != null:
		if active_species_id != _support_portrait_species:
			_support_portrait_species = active_species_id
			if not active_species_id.is_empty():
				var portrait_path: String = _combat_content.get_creature_art_path(active_species_id, "support")
				if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
					var portrait_tex: Texture2D = load(portrait_path) as Texture2D
					if portrait_tex != null:
						_support_creature_portrait.texture = portrait_tex
						_support_creature_portrait.visible = true
					else:
						_support_creature_portrait.visible = false
				else:
					_support_creature_portrait.visible = false
			else:
				_support_creature_portrait.visible = false
				_support_creature_portrait.texture = null
	if _support_trigger_label != null:
		if not active_species_id.is_empty():
			var support_role: Dictionary = _combat_content.get_support_role(active_species_id)
			_support_trigger_label.text = compact_hud_copy(
				_presentation_text.trigger_hint(String(support_role.get("effect_id", ""))), 18)
		else:
			var tendency_summary: String = compact_hud_copy(_format_upgrade_summary(run_growth), 18)
			if tendency_summary.is_empty() or tendency_summary == "--":
				_support_trigger_label.text = "No tendency"
			else:
				_support_trigger_label.text = tendency_summary

	if _support_shell != null:
		var shell_role: String = "support_idle"
		if not active_species_id.is_empty() and current >= maximum:
			shell_role = "support_ready"
		_ui_style.apply_shell_style(_support_shell, shell_role)
	if _support_bar != null:
		var bar_role: String = "support_idle"
		if not active_species_id.is_empty() and current >= maximum:
			bar_role = "support_ready"
		_ui_style.apply_bar_style(_support_bar, bar_role)


# ── Run build readout ─────────────────────────────────────────────────────────

func refresh_run_build(run_growth: Node) -> void:
	if _eaten_value_label != null:
		_eaten_value_label.text = _format_absorbed_bonus_summary()
	if _upgrade_value_label != null:
		_upgrade_value_label.text = _format_upgrade_summary(run_growth)

	if _bond_value_label != null:
		var active: Dictionary = GameState.get_active_bonded_creature()
		if not active.is_empty():
			var active_bond_level: int = int(active.get("bond_level", 1))
			var level_mult: float = GameState.get_bond_level_mult(active_bond_level)
			_bond_value_label.text = _presentation_text.format_bond_passive_short(active.get("bond_passive", {}), level_mult)
		else:
			_bond_value_label.text = "--"

	if _atk_value_label != null:
		_atk_value_label.text = "%.0f" % GameState.get_attack_damage()
	if _def_value_label != null:
		_def_value_label.text = "%.0f" % GameState.player_defense
	if _dna_route_label != null and run_growth != null and is_instance_valid(run_growth) and run_growth.has_method("get_dna_routing_label"):
		_dna_route_label.text = String(run_growth.call("get_dna_routing_label"))

	if _run_build_shell != null:
		var has_build: bool = not GameState.absorbed_types.is_empty()
		_run_build_shell.color = Color(0.08, 0.08, 0.10, 0.60) if has_build else Color(0.07, 0.07, 0.09, 0.50)


# ── DNA HUD ───────────────────────────────────────────────────────────────────

func refresh_dna_hud(song_mode: bool, song_phase_index: int, song_phases: Array, pending_creature: Dictionary) -> void:
	if _dna_slot_labels.is_empty():
		return

	var relevant_species: Array[String] = []
	if song_mode and song_phase_index >= 0 and song_phase_index < song_phases.size():
		var phase: Dictionary = song_phases[song_phase_index]
		for species_id in phase.get("reward_pool", []):
			var typed: String = String(species_id)
			if not typed.is_empty() and not relevant_species.has(typed):
				relevant_species.append(typed)

	if not pending_creature.is_empty():
		var pending_species: String = String(pending_creature.get("species_id", ""))
		if not pending_species.is_empty() and not relevant_species.has(pending_species):
			relevant_species.insert(0, pending_species)

	if relevant_species.is_empty():
		for species_id in GameState.dna_by_species.keys():
			var typed: String = String(species_id)
			if GameState.get_dna(typed) > 0.0:
				relevant_species.append(typed)
		relevant_species.sort()

	if _dna_shell != null:
		_dna_shell.visible = song_mode and not relevant_species.is_empty()
	if _dna_emblem != null:
		_dna_emblem.visible = _dna_shell != null and _dna_shell.visible

	for i in range(_dna_slot_labels.size()):
		var label: Label = _dna_slot_labels[i]
		label.visible = _dna_shell == null or _dna_shell.visible
		if i >= relevant_species.size():
			label.text = "--"
			label.modulate = Color(0.82, 0.82, 0.82, 1.0)
			continue

		var species_id: String = relevant_species[i]
		var creature: Dictionary = _combat_content.get_creature(species_id)
		var display_name: String = String(creature.get("display_name", species_id)).to_upper()
		var threshold: float = float(creature.get("dna_threshold", 0.0))
		var current_dna: float = GameState.get_dna(species_id)
		if threshold > 0.0:
			var gate_state: String = "READY" if current_dna >= threshold else "LOCKED"
			label.text = "%s %s" % [_compact_token(display_name, 4), gate_state.left(1)]
			label.modulate = Color(0.84, 0.98, 0.88, 1.0) if current_dna >= threshold else Color(0.96, 0.82, 0.72, 1.0)
		else:
			label.text = "%s %.0f" % [_compact_token(display_name, 4), current_dna]
			label.modulate = Color(0.90, 0.90, 0.88, 1.0)


# ── Boss bar ──────────────────────────────────────────────────────────────────

func show_boss_bar() -> void:
	if _boss_hp_shell != null:
		_boss_hp_shell.visible = true
	if _boss_name_label != null:
		_boss_name_label.visible = true
	if _boss_state_label != null:
		_boss_state_label.visible = true
	if _boss_hp_bar != null:
		_boss_hp_bar.visible = true


func hide_boss_bar() -> void:
	if _boss_hp_shell != null:
		_boss_hp_shell.visible = false
	if _boss_name_label != null:
		_boss_name_label.visible = false
	if _boss_state_label != null:
		_boss_state_label.visible = false
	if _boss_hp_bar != null:
		_boss_hp_bar.visible = false


func setup_boss_bar(total_hp: float, boss_name: String, state_text: String) -> void:
	if _boss_hp_bar != null:
		_boss_hp_bar.max_value = total_hp
		_boss_hp_bar.value = total_hp
	if _boss_name_label != null:
		_boss_name_label.text = boss_name
	if _boss_state_label != null:
		_boss_state_label.text = state_text
	show_boss_bar()


func update_boss_hp(current: float) -> void:
	if _boss_hp_bar != null:
		_boss_hp_bar.value = current


func set_boss_state_text(text: String) -> void:
	if _boss_state_label != null:
		_boss_state_label.text = text


# ── Song / boss timer HUD ────────────────────────────────────────────────────

func update_song_timer(remaining: float) -> void:
	if _song_timer_label != null:
		_song_timer_label.text = "%d" % int(ceil(remaining))


func hide_song_hud() -> void:
	if _song_timer_label != null:
		_song_timer_label.visible = false
	if _song_phase_label != null:
		_song_phase_label.visible = false


func show_boss_race_hud(phase_label_text: String) -> void:
	if _song_phase_label != null:
		_song_phase_label.text = phase_label_text
		_song_phase_label.add_theme_color_override("font_color", Color(0.82, 0.50, 0.28, 0.80))
		_song_phase_label.visible = true
	if _boss_state_label != null:
		_boss_state_label.text = "Race active  |  Break at 50%"
	if _song_timer_label != null:
		_song_timer_label.add_theme_color_override("font_color", Color(0.70, 0.55, 0.44, 0.85))
		_song_timer_label.visible = true


func update_boss_race_timer(remaining: float, total: float) -> void:
	if _song_timer_label == null:
		return
	_song_timer_label.text = "%d" % int(ceil(remaining))
	var frac: float = clampf(remaining / max(total, 1.0), 0.0, 1.0)
	var urgency: float = clampf((0.5 - frac) / 0.5, 0.0, 1.0)
	_song_timer_label.add_theme_color_override("font_color",
		Color(lerpf(0.70, 1.0, urgency), lerpf(0.55, 0.20, urgency), lerpf(0.44, 0.20, urgency), 0.92))


# ── Public formatting helpers (callable from CombatScene for reward overlay) ─

func compact_hud_copy(text: String, max_length: int) -> String:
	var compact: String = " ".join(text.split("\n", false)).strip_edges()
	if compact.length() <= max_length:
		return compact
	if max_length <= 3:
		return compact.left(max_length)
	return compact.left(max_length - 3).strip_edges() + "..."


# ── Private helpers ───────────────────────────────────────────────────────────

func _compact_token(text: String, max_len: int) -> String:
	var cleaned: String = text.strip_edges().to_upper().replace(" ", "")
	if cleaned.length() <= max_len:
		return cleaned
	return cleaned.substr(0, max_len)


func _join_compact_tokens(tokens: Array[String]) -> String:
	if tokens.is_empty():
		return ""
	var result: String = tokens[0]
	for i in range(1, tokens.size()):
		result += " " + tokens[i]
	return result


func _format_absorbed_bonus_summary() -> String:
	if GameState.absorbed_types.is_empty():
		return "--"
	var chips: Array[String] = []
	var visible_count: int = min(2, GameState.absorbed_types.size())
	for i in range(visible_count):
		var entry: Dictionary = GameState.absorbed_types[i]
		var species_id: String = String(entry.get("source_species_id", ""))
		var creature_name: String = species_id
		if not species_id.is_empty():
			var creature: Dictionary = _combat_content.get_creature(species_id)
			creature_name = String(creature.get("display_name", species_id))
		var short_name: String = _compact_token(creature_name, 4)
		var eat_type: String = String(entry.get("eat_type", ""))
		if eat_type == "support_charge":
			var charge_bonus: int = int(round(float(entry.get("support_charge_bonus", 0.0))))
			chips.append("[%sCH+%d]" % [short_name, charge_bonus])
		elif eat_type == "hp_restore":
			var heal_amount: int = int(round(float(entry.get("heal_applied", 0.0))))
			chips.append("[%sHP+%d]" % [short_name, heal_amount])
		elif eat_type == "max_hp_flat":
			var max_hp_bonus: int = int(round(float(entry.get("max_hp_bonus", 0.0))))
			chips.append("[%sMHP+%d]" % [short_name, max_hp_bonus])
		else:
			var damage_bonus: int = int(round(float(entry.get("damage_bonus", 0.0))))
			chips.append("[%s+%d]" % [short_name, damage_bonus])
	var hidden_count: int = GameState.absorbed_types.size() - visible_count
	if hidden_count > 0:
		chips.append("+%d" % hidden_count)
	return _join_compact_tokens(chips)


func _format_upgrade_summary(run_growth: Node) -> String:
	if run_growth != null and is_instance_valid(run_growth) and run_growth.has_method("get_tendency_summary"):
		return String(run_growth.call("get_tendency_summary"))
	return "--"
