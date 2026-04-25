extends Node2D

const ROUTE_CONTENT = preload("res://data/RouteContent.gd")
const COMBAT_DATA = preload("res://data/CombatContent.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")

const COMBAT_SCENE_PATH: String = "res://scenes/combat/CombatScene.tscn"
const TITLE_SCENE_PATH: String = "res://scenes/ui/TitleScreen.tscn"

const PRESETS: Array[Dictionary] = [
	{
		"id": "normal_boot",
		"name": "Normal Combat Boot",
		"summary": "Open a clean song run from the selected region with an optional bonded support.",
		"start_mode": "song",
		"song_phase_index": 0,
		"default_support_species_id": "",
		"dna_seed": {},
		"run_growth": {}
	},
	{
		"id": "reward_preview",
		"name": "Mid-Song Reward Preview",
		"summary": "Jump into an active phase with seeded DNA and an open live reward shell.",
		"start_mode": "song",
		"song_phase_index": 2,
		"default_support_species_id": "knellspine",
		"preview_live_reward_species_id": "knellspine",
		"dna_seed": {"knellspine": 6.0, "gruvek": 4.0},
		"run_growth": {
			"level": 3,
			"exp": 18.0,
			"tendency_levels": {"aggression": 1, "cadence": 1, "guard": 0, "bond": 1},
			"tendency_points": {"aggression": 1.2, "cadence": 2.6, "guard": 0.8, "bond": 2.4},
			"support_charge": 58.0
		}
	},
	{
		"id": "tendency_state",
		"name": "Tendency Growth State",
		"summary": "Seed run-growth pressure, support charge, and tendency levels for surge and HUD checks.",
		"start_mode": "song",
		"song_phase_index": 1,
		"default_support_species_id": "bond_remnant",
		"run_growth": {
			"level": 5,
			"exp": 24.0,
			"tendency_levels": {"aggression": 2, "cadence": 1, "guard": 1, "bond": 2},
			"tendency_points": {"aggression": 3.2, "cadence": 2.1, "guard": 2.4, "bond": 3.6},
			"support_charge": 82.0
		},
		"player_hp_ratio": 0.72
	},
	{
		"id": "boss_threshold",
		"name": "Boss Threshold State",
		"summary": "Run the live boss handoff, then land directly in the 50 percent threshold state.",
		"start_mode": "boss",
		"default_support_species_id": "thornback",
		"trigger_boss_threshold": true,
		"run_growth": {
			"level": 6,
			"exp": 30.0,
			"tendency_levels": {"aggression": 2, "cadence": 2, "guard": 1, "bond": 1},
			"tendency_points": {"aggression": 3.5, "cadence": 3.1, "guard": 1.2, "bond": 1.8},
			"support_charge": 100.0
		}
	},
	{
		"id": "hud_stress",
		"name": "HUD Readability Stress",
		"summary": "Load a busy combat state with support, DNA, absorbed bonuses, and a live reward prompt.",
		"start_mode": "song",
		"song_phase_index": 3,
		"default_support_species_id": "marrowward",
		"preview_live_reward_species_id": "hushcoil",
		"dna_seed": {
			"hushcoil": 9.0,
			"knellspine": 6.0,
			"marrowward": 8.0,
			"thornback": 9.0
		},
		"absorbed_species_ids": ["thornback", "marrowward"],
		"run_growth": {
			"level": 7,
			"exp": 44.0,
			"tendency_levels": {"aggression": 2, "cadence": 2, "guard": 2, "bond": 2},
			"tendency_points": {"aggression": 2.8, "cadence": 2.8, "guard": 2.8, "bond": 2.8},
			"support_charge": 100.0
		},
		"player_hp_ratio": 0.84
	},
	{
		"id": "generated_boss",
		"name": "Generated Boss (debug bridge)",
		"summary": "Boss handoff loads EncounterGenerator output normalized for CombatScene (harness only).",
		"start_mode": "boss",
		"debug_generated_boss_encounter": true,
		"default_support_species_id": "thornback",
		"run_growth": {
			"level": 4,
			"exp": 20.0,
			"tendency_levels": {"aggression": 1, "cadence": 1, "guard": 1, "bond": 1},
			"tendency_points": {"aggression": 2.0, "cadence": 2.0, "guard": 2.0, "bond": 2.0},
			"support_charge": 70.0
		}
	},
	{
		"id": "control_focus",
		"name": "Control Focus Sequence",
		"summary": "Harness-only sequence that exercises N/E/S/W focus with attack, parry, and dodge timing.",
		"start_mode": "song",
		"song_phase_index": 0,
		"default_support_species_id": "veilskin",
		"debug_control_sequence": true,
		"debug_autoquit_seconds": 7.5,
		"run_growth": {
			"level": 3,
			"exp": 16.0,
			"tendency_levels": {"aggression": 1, "cadence": 1, "guard": 1, "bond": 1},
			"tendency_points": {"aggression": 1.6, "cadence": 1.6, "guard": 1.6, "bond": 1.6},
			"support_charge": 100.0
		}
	},
	{
		"id": "melee_stress",
		"name": "Melee Approach Stress",
		"summary": "Jump into chorus with stalker melee enemies seeded — validates approach/bounce/timing loop.",
		"start_mode": "song",
		"song_phase_index": 2,
		"default_support_species_id": "ashclaw",
		"run_growth": {
			"level": 3,
			"exp": 16.0,
			"tendency_levels": {"aggression": 1, "cadence": 1, "guard": 0, "bond": 1},
			"tendency_points": {"aggression": 1.4, "cadence": 1.8, "guard": 0.4, "bond": 1.2},
			"support_charge": 60.0
		}
	}
]

const SUPPORT_OPTIONS: Array[String] = [
	"",
	"ashclaw",
	"bond_remnant",
	"gruvek",
	"veilskin",
	"thornback",
	"knellspine",
	"marrowward",
	"gorefane",
	"hushcoil"
]

var _preset_index: int = 0
var _region_index: int = 0
var _support_index: int = 0
var _can_input: bool = false

var _preset_labels: Array[Label] = []
var _summary_label: Label = null
var _region_value_label: Label = null
var _support_value_label: Label = null
var _detail_label: Label = null


func _ready() -> void:
	DevHarness.clear_request()
	_build_ui()
	_apply_env_overrides()
	_refresh_ui()
	if _should_autolaunch_from_env():
		call_deferred("_launch_selected_preset")
	await get_tree().create_timer(0.12).timeout
	_can_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not _can_input:
		return
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_1: _set_preset_index(0)
		KEY_2: _set_preset_index(1)
		KEY_3: _set_preset_index(2)
		KEY_4: _set_preset_index(3)
		KEY_5: _set_preset_index(4)
		KEY_6: _set_preset_index(5)
		KEY_7: _set_preset_index(6)
		KEY_LEFT: _cycle_region(-1)
		KEY_RIGHT: _cycle_region(1)
		KEY_UP: _cycle_support(-1)
		KEY_DOWN: _cycle_support(1)
		KEY_ENTER, KEY_SPACE: _launch_selected_preset()
		KEY_T, KEY_ESCAPE:
			DevHarness.clear_request()
			get_tree().change_scene_to_file(TITLE_SCENE_PATH)
			return
		_:
			return

	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _set_preset_index(index: int) -> void:
	_preset_index = clampi(index, 0, PRESETS.size() - 1)
	_refresh_ui()


func _cycle_region(direction: int) -> void:
	_region_index = wrapi(_region_index + direction, 0, ROUTE_CONTENT.REGIONS.size())
	_refresh_ui()


func _cycle_support(direction: int) -> void:
	_support_index = wrapi(_support_index + direction, 0, SUPPORT_OPTIONS.size())
	_refresh_ui()


func _launch_selected_preset() -> void:
	var preset: Dictionary = PRESETS[_preset_index].duplicate(true)
	var region: Dictionary = ROUTE_CONTENT.REGIONS[_region_index]
	var support_species_id: String = _resolve_support_species_id(preset)

	var request: Dictionary = preset.duplicate(true)
	request["region_id"] = String(region.get("id", "feeding_hollow"))
	request["support_species_id"] = support_species_id
	request["support_bond_level"] = 2 if not support_species_id.is_empty() else 0
	var autoquit_seconds: float = _resolve_autoquit_seconds()
	if autoquit_seconds > 0.0:
		request["debug_autoquit_seconds"] = autoquit_seconds

	GameState.set_active_region(region)
	DevHarness.queue_request(request)
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _resolve_support_species_id(preset: Dictionary) -> String:
	var selected_species_id: String = SUPPORT_OPTIONS[_support_index]
	if not selected_species_id.is_empty():
		return selected_species_id
	return String(preset.get("default_support_species_id", ""))


func _build_ui() -> void:
	UI_STYLE.attach_shell_backdrop(self)

	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var header: Label = Label.new()
	header.text = "DEBUG BOOT"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(1280.0, 52.0)
	header.position = Vector2(0.0, 28.0)
	UI_STYLE.apply_label(header, "screen_title")
	canvas.add_child(header)

	var sub: Label = Label.new()
	sub.text = "Development-facing combat harness. This does not replace the live player flow."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1280.0, 24.0)
	sub.position = Vector2(0.0, 78.0)
	UI_STYLE.apply_label(sub, "screen_subtitle")
	canvas.add_child(sub)

	var preset_shell: ColorRect = ColorRect.new()
	preset_shell.color = Color(0.11, 0.07, 0.07, 1.0)
	preset_shell.position = Vector2(76.0, 126.0)
	preset_shell.size = Vector2(450.0, 500.0)
	canvas.add_child(preset_shell)

	var preset_title: Label = Label.new()
	preset_title.text = "PRESETS"
	preset_title.position = Vector2(18.0, 16.0)
	preset_title.size = Vector2(160.0, 24.0)
	UI_STYLE.apply_label(preset_title, "subheading")
	preset_shell.add_child(preset_title)

	for i in range(PRESETS.size()):
		var line := Label.new()
		line.position = Vector2(18.0, 58.0 + i * 64.0)
		line.size = Vector2(404.0, 54.0)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_STYLE.apply_label(line, "body")
		preset_shell.add_child(line)
		_preset_labels.append(line)

	var config_shell: ColorRect = ColorRect.new()
	config_shell.color = Color(0.10, 0.07, 0.08, 1.0)
	config_shell.position = Vector2(560.0, 126.0)
	config_shell.size = Vector2(644.0, 432.0)
	canvas.add_child(config_shell)

	var config_title: Label = Label.new()
	config_title.text = "CONFIG"
	config_title.position = Vector2(18.0, 16.0)
	config_title.size = Vector2(140.0, 24.0)
	UI_STYLE.apply_label(config_title, "subheading")
	config_shell.add_child(config_title)

	_summary_label = Label.new()
	_summary_label.position = Vector2(18.0, 52.0)
	_summary_label.size = Vector2(604.0, 62.0)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_summary_label, "body")
	config_shell.add_child(_summary_label)

	var region_label: Label = Label.new()
	region_label.text = "Region"
	region_label.position = Vector2(18.0, 136.0)
	region_label.size = Vector2(140.0, 22.0)
	UI_STYLE.apply_label(region_label, "card_tag")
	config_shell.add_child(region_label)

	_region_value_label = Label.new()
	_region_value_label.position = Vector2(18.0, 160.0)
	_region_value_label.size = Vector2(604.0, 30.0)
	UI_STYLE.apply_label(_region_value_label, "card_title")
	config_shell.add_child(_region_value_label)

	var support_label: Label = Label.new()
	support_label.text = "Bonded Support"
	support_label.position = Vector2(18.0, 214.0)
	support_label.size = Vector2(180.0, 22.0)
	UI_STYLE.apply_label(support_label, "card_tag")
	config_shell.add_child(support_label)

	_support_value_label = Label.new()
	_support_value_label.position = Vector2(18.0, 238.0)
	_support_value_label.size = Vector2(604.0, 30.0)
	UI_STYLE.apply_label(_support_value_label, "card_title")
	config_shell.add_child(_support_value_label)

	_detail_label = Label.new()
	_detail_label.position = Vector2(18.0, 294.0)
	_detail_label.size = Vector2(604.0, 110.0)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_detail_label, "body")
	config_shell.add_child(_detail_label)

	var hint: Label = Label.new()
	hint.text = "1-7 preset  |  Left/Right region  |  Up/Down support  |  Enter launch  |  T / Esc title"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1280.0, 28.0)
	hint.position = Vector2(0.0, 662.0)
	UI_STYLE.apply_label(hint, "hint")
	canvas.add_child(hint)


func _refresh_ui() -> void:
	var preset: Dictionary = PRESETS[_preset_index]
	for i in range(_preset_labels.size()):
		var line: Label = _preset_labels[i]
		line.text = "%d. %s\n%s" % [
			i + 1,
			String(PRESETS[i].get("name", "")),
			String(PRESETS[i].get("summary", ""))
		]
		line.modulate = Color(1.0, 0.92, 0.74, 1.0) if i == _preset_index else Color(0.76, 0.74, 0.70, 1.0)

	var region: Dictionary = ROUTE_CONTENT.REGIONS[_region_index]
	var support_species_id: String = _resolve_support_species_id(preset)
	var support_name: String = "None"
	if not support_species_id.is_empty():
		support_name = String(COMBAT_DATA.get_creature(support_species_id).get("display_name", support_species_id))

	_summary_label.text = String(preset.get("summary", ""))
	_region_value_label.text = "%s  |  %s" % [
		String(region.get("name", "")),
		String(region.get("modifier_label", ""))
	]
	_support_value_label.text = support_name
	_detail_label.text = _build_detail_text(preset, support_species_id)


func _apply_env_overrides() -> void:
	var preset_id: String = OS.get_environment("WHAT_WE_FED_DEBUG_PRESET").strip_edges().to_lower()
	if not preset_id.is_empty():
		for i in range(PRESETS.size()):
			if String(PRESETS[i].get("id", "")).to_lower() == preset_id:
				_preset_index = i
				break

	var region_id: String = OS.get_environment("WHAT_WE_FED_DEBUG_REGION").strip_edges().to_lower()
	if not region_id.is_empty():
		for i in range(ROUTE_CONTENT.REGIONS.size()):
			if String(ROUTE_CONTENT.REGIONS[i].get("id", "")).to_lower() == region_id:
				_region_index = i
				break

	var support_species_id: String = OS.get_environment("WHAT_WE_FED_DEBUG_SUPPORT").strip_edges().to_lower()
	if not support_species_id.is_empty():
		for i in range(SUPPORT_OPTIONS.size()):
			if SUPPORT_OPTIONS[i].to_lower() == support_species_id:
				_support_index = i
				break


func _should_autolaunch_from_env() -> bool:
	var autolaunch_flag: String = OS.get_environment("WHAT_WE_FED_DEBUG_AUTOLAUNCH").strip_edges()
	if autolaunch_flag == "1":
		return true
	return DisplayServer.get_name() == "headless" and not OS.get_environment("WHAT_WE_FED_DEBUG_PRESET").strip_edges().is_empty()


func _resolve_autoquit_seconds() -> float:
	var raw_value: String = OS.get_environment("WHAT_WE_FED_DEBUG_AUTOQUIT_SECONDS").strip_edges()
	if raw_value.is_empty():
		return 0.0
	return maxf(raw_value.to_float(), 0.0)


func _build_detail_text(preset: Dictionary, support_species_id: String) -> String:
	var parts: Array[String] = []
	var start_mode: String = String(preset.get("start_mode", "song"))
	if start_mode == "boss":
		parts.append("Boot: live boss handoff")
		if bool(preset.get("debug_generated_boss_encounter", false)):
			parts.append("Boss encounter: EncounterGenerator via GeneratedEncounterAdapter (debug)")
		if bool(preset.get("trigger_boss_threshold", false)):
			parts.append("Boss: 50 percent threshold forced")
	else:
		parts.append("Song phase: %d" % int(preset.get("song_phase_index", 0)))
		if bool(preset.get("debug_control_sequence", false)):
			parts.append("Harness: auto N/E/S/W focus plus attack/parry/dodge sequence")

	if not support_species_id.is_empty():
		parts.append("Support: %s bonded at level 2" % String(COMBAT_DATA.get_creature(support_species_id).get("display_name", support_species_id)))

	var dna_seed: Dictionary = preset.get("dna_seed", {})
	if not dna_seed.is_empty():
		var dna_tokens: Array[String] = []
		for species_id in dna_seed.keys():
			dna_tokens.append("%s %.0f" % [
				String(COMBAT_DATA.get_creature(String(species_id)).get("display_name", species_id)),
				float(dna_seed[species_id])
			])
		parts.append("DNA: " + ", ".join(dna_tokens))

	var absorbed_species_ids: Array = preset.get("absorbed_species_ids", [])
	if not absorbed_species_ids.is_empty():
		var absorbed_names: Array[String] = []
		for species_id in absorbed_species_ids:
			absorbed_names.append(String(COMBAT_DATA.get_creature(String(species_id)).get("display_name", species_id)))
		parts.append("Absorbed: " + ", ".join(absorbed_names))

	var reward_species_id: String = String(preset.get("preview_live_reward_species_id", ""))
	if not reward_species_id.is_empty():
		parts.append("Live reward: %s preview" % String(COMBAT_DATA.get_creature(reward_species_id).get("display_name", reward_species_id)))

	var run_growth: Dictionary = preset.get("run_growth", {})
	if not run_growth.is_empty():
		parts.append("Growth: level %d, support %.0f%%" % [
			int(run_growth.get("level", 1)),
			float(run_growth.get("support_charge", 0.0))
		])

	return "\n".join(parts)
