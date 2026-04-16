extends Node2D

@onready var background: ColorRect = $Background
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var lane_manager: Node = $LaneManager
@onready var player_combat: Node2D = $PlayerCombat
@onready var combat_meter: Node = $CombatMeter
@onready var camera_2d: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UI

@onready var combo_label: Label = $UI/ComboLabel
@onready var style_label: Label = $UI/StyleLabel
@onready var stamina_bar: ProgressBar = $UI/StaminaBar
@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var ultimate_label: Label = $UI/UltimateLabel
@onready var result_label: Label = $UI/ResultLabel
@onready var controls_label: Label = $UI/ControlsLabel

const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")
const RING_OUTER_RADIUS: float = 30.0
const RING_GOOD_RADIUS: float = 24.0
const RING_PERFECT_RADIUS: float = 15.0
const RING_POINT_COUNT: int = 32
const LANE_BAND_HEIGHT: float = 54.0
const LANE_IDLE_ALPHA: float = 0.18
const LANE_THREAT_ALPHA: float = 0.34
const LANE_CRITICAL_ALPHA: float = 0.50
const EDGE_STATE_WIDTH: float = 0.016
const RUN_GROWTH_SCRIPT_PATH: String = "res://systems/RunGrowth.gd"
const ENEMY_LOW_HP_THRESHOLD: float = 0.25

var _base_time_scale: float = 1.0
# Incremented each time _on_slow_motion fires. Each restore timer checks its
# captured generation against this; only the latest timer restores time_scale.
var _slow_motion_gen: int = 0
# Per-lane suppression timer (seconds). While > 0, _update_timing_ring_proximity
# skips that lane so a freshly-triggered flash isn't immediately overwritten.
var _ring_highlight_timers: Array[float] = [0.0, 0.0, 0.0]
var _feedback_label: Label = null
var _title_card: Label = null
var _subtitle_card: Label = null
var _timing_circle_container: Node2D = null
var _enemy_marker_container: Node2D = null
var _lane_marker_container: Node2D = null
var _attack_fx_container: Node2D = null
var _meter_shell: ColorRect = null
var _combo_shell: ColorRect = null
var _style_shell: ColorRect = null
var _resource_shell: ColorRect = null
var _support_shell: ColorRect = null
var _support_bar: ProgressBar = null
var _support_value_label: Label = null
var _support_name_label: Label = null
var _run_build_shell: ColorRect = null
var _eaten_value_label: Label = null
var _upgrade_value_label: Label = null
var _bond_value_label: Label = null
var _support_trigger_label: Label = null
var _atk_value_label: Label = null
var _quig_anchor_label: Label = null
var _hp_value_label: Label = null
var _exp_value_label: Label = null
var _battlefield_panel: ColorRect = null
var _battlefield_inner_panel: ColorRect = null
var _battlefield_left_shade: ColorRect = null
var _battlefield_right_shade: ColorRect = null
var _battlefield_top_trim: ColorRect = null
var _battlefield_bottom_trim: ColorRect = null

# Reward / inter-encounter overlay.
var _reward_overlay: ColorRect = null
var _reward_panel: ColorRect = null
var _reward_title_label: Label = null
var _reward_body_label: Label = null
var _reward_quig_label: Label = null
var _reward_hint_label: Label = null
var _reward_bond_card: ColorRect = null
var _reward_eat_card: ColorRect = null
var _reward_bond_label: Label = null
var _reward_eat_label: Label = null
var _reward_bond_effect_label: Label = null
var _reward_eat_effect_label: Label = null
var _reward_creature_tag_label: Label = null
var _growth_overlay: ColorRect = null
var _growth_panel: ColorRect = null
var _growth_title_label: Label = null
var _growth_hint_label: Label = null
var _growth_option_labels: Array[Label] = []

var _combat_finished: bool = false
var _phase_transitioning: bool = false

var _awaiting_reward_choice: bool = false
var _reward_choice_made: bool = false
var _awaiting_continue: bool = false
var _run_finished: bool = false
var _pending_reward_creature: Dictionary = {}

# Incremented each time _load_current_queued_encounter is called. The function
# captures this at entry and bails after the boss-intro await if a newer load
# has superseded it — mirrors the _cycle_task_id pattern in LaneManager.
var _encounter_load_gen: int = 0

var _active_encounter: Dictionary = {}
var _current_phase_index: int = 0
var _encounter_queue: Array = []
var _current_encounter_queue_index: int = 0
var _run_growth: Node = null
var _awaiting_growth_choice: bool = false
var _growth_pause_active: bool = false
var _current_growth_options: Array = []

# enemy_id -> ColorRect
var _enemy_markers_by_id: Dictionary = {}
# enemy_id -> enemy data
var _all_enemies_by_id: Dictionary = {}
# enemy_id -> max HP captured at arena build time (for low-HP threshold)
var _enemy_max_hp: Dictionary = {}
# Boss encounter state
var _is_boss_encounter: bool = false
var _boss_total_hp: float = 0.0
var _boss_current_hp: float = 0.0
var _boss_hp_shell: ColorRect = null
var _boss_hp_bar: ProgressBar = null
var _boss_name_label: Label = null
# enemy_id -> phase index
var _enemy_phase_by_id: Dictionary = {}
var _lane_strips: Dictionary = {}
var _lane_hit_focus: Dictionary = {}


func _ready() -> void:
	_setup_visuals()
	_setup_ui()
	_create_feedback_label()
	_create_title_cards()
	_create_timing_circle_container()
	_create_attack_fx_container()
	_create_reward_overlay()
	_create_growth_overlay()
	_setup_run_growth()
	_connect_eventbus()
	_setup_lane_manager()
	_setup_player_combat()
	_start_mini_run()


func _process(delta: float) -> void:
	for i in range(3):
		if _ring_highlight_timers[i] > 0.0:
			_ring_highlight_timers[i] = max(_ring_highlight_timers[i] - delta, 0.0)
	if _timing_circle_container != null:
		_update_timing_ring_proximity()
	if _lane_marker_container != null:
		_update_lane_visual_states()
	_maybe_present_growth_offer()


func _update_timing_ring_proximity() -> void:
	var biome: Dictionary = _active_encounter.get("biome", {})
	var active_color: Color = biome.get("ring_active_color", Color(1.0, 0.95, 0.55, 1.0))
	var inactive_color: Color = biome.get("ring_inactive_color", Color(0.7, 0.7, 0.8, 0.45))

	var intercept_dist: float = lane_manager.get_enemy_x() - lane_manager.get_hit_zone_x()
	if intercept_dist <= 0.0:
		return

	var outer_entry: float = 1.0 - RING_OUTER_RADIUS / intercept_dist
	var outer_exit: float = 1.0 + RING_OUTER_RADIUS / intercept_dist
	var perfect_entry: float = 1.0 - RING_PERFECT_RADIUS / intercept_dist
	var perfect_exit: float = 1.0 + RING_PERFECT_RADIUS / intercept_dist
	var approach_start: float = outer_entry - 0.08

	for lane in range(3):
		if _ring_highlight_timers[lane] > 0.0:
			continue

		var group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_%d" % lane)
		if group == null:
			continue

		var outer_ring: Line2D = group.get_node_or_null("Outer") as Line2D
		var good_ring: Line2D = group.get_node_or_null("Good") as Line2D
		var perfect_ring: Line2D = group.get_node_or_null("Perfect") as Line2D
		var receiver_fill: Polygon2D = group.get_node_or_null("ReceiverFill") as Polygon2D
		var receiver_glow: Polygon2D = group.get_node_or_null("ReceiverGlow") as Polygon2D
		var edge_ring: Line2D = group.get_node_or_null("Edge") as Line2D
		var beat_mark: Line2D = group.get_node_or_null("BeatMark") as Line2D
		if outer_ring == null or good_ring == null or perfect_ring == null or receiver_fill == null or receiver_glow == null or edge_ring == null or beat_mark == null:
			continue

		var base_color: Color = active_color if lane == player_combat.current_lane else inactive_color

		var outer_color: Color = base_color.darkened(0.02)
		var good_color: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.10)
		var perfect_color: Color = base_color.lightened(0.20)
		var outer_width: float = 2.5
		var good_width: float = 0.8
		var perfect_width: float = 2.5
		var receiver_alpha: float = 0.06 if lane == player_combat.current_lane else 0.03
		var receiver_glow_alpha: float = 0.0
		var edge_alpha: float = 0.0
		var beat_color: Color = base_color.lightened(0.06)

		var proj = lane_manager.get_projectile(lane)
		if proj != null and not proj.is_resolved and not proj.is_reflected:
			var p: float = proj.progress

			if p >= approach_start and p < outer_entry:
				# Projectile is approaching - fade the receiver into focus gradually.
				var t: float = (p - approach_start) / (outer_entry - approach_start)
				outer_color = outer_color.lerp(active_color, t)
				receiver_alpha = lerp(receiver_alpha, 0.18, t)
				receiver_glow_alpha = lerp(0.0, 0.08, t)

			elif p >= outer_entry and p <= outer_exit:
				# Projectile is inside the outer ring - active threat and edge pressure.
				outer_color = active_color.lightened(0.10)
				good_color = Color(active_color.r, active_color.g, active_color.b, 0.12)
				receiver_alpha = 0.22
				receiver_glow_alpha = 0.14
				beat_color = active_color.lightened(0.28)

				if p >= perfect_entry and p <= perfect_exit:
					# Projectile is inside the perfect ring - sharpen the inner receiver truth.
					good_color = Color(active_color.r, active_color.g, active_color.b, 0.16)
					perfect_color = active_color.lightened(0.45)
					perfect_width = 3.4
					receiver_alpha = 0.30
					receiver_glow_alpha = 0.18
					beat_color = active_color.lightened(0.44)

				var edge_distance: float = min(abs(p - outer_entry), abs(p - outer_exit))
				if edge_distance <= EDGE_STATE_WIDTH:
					var edge_t: float = 1.0 - clamp(edge_distance / EDGE_STATE_WIDTH, 0.0, 1.0)
					edge_alpha = 0.18 + (0.26 * edge_t)
					outer_width = lerp(outer_width, 3.0, edge_t)

		receiver_fill.color = Color(active_color.r, active_color.g, active_color.b, receiver_alpha)
		receiver_glow.color = Color(active_color.r, active_color.g, active_color.b, receiver_glow_alpha)
		edge_ring.default_color = Color(active_color.r, active_color.g, active_color.b, edge_alpha)
		beat_mark.default_color = beat_color

		outer_ring.default_color = outer_color
		outer_ring.width = outer_width
		good_ring.default_color = good_color
		good_ring.width = good_width
		perfect_ring.default_color = perfect_color
		perfect_ring.width = perfect_width


func _update_lane_visual_states() -> void:
	var biome: Dictionary = _active_encounter.get("biome", {})
	var lane_color: Color = biome.get("lane_color", Color(0.30, 0.30, 0.35, 1.0))
	var active_color: Color = biome.get("ring_active_color", Color(1.0, 0.95, 0.55, 1.0))
	var inactive_color: Color = biome.get("ring_inactive_color", Color(0.7, 0.7, 0.8, 0.45))
	var time: float = Time.get_ticks_msec() / 1000.0
	var intercept_dist: float = lane_manager.get_enemy_x() - lane_manager.get_hit_zone_x()

	if intercept_dist <= 0.0:
		return

	var outer_entry: float = 1.0 - RING_OUTER_RADIUS / intercept_dist
	var outer_exit: float = 1.0 + RING_OUTER_RADIUS / intercept_dist

	for lane in range(3):
		var strip: ColorRect = _lane_strips.get(lane, null)
		var focus: ColorRect = _lane_hit_focus.get(lane, null)
		if strip == null or focus == null or not is_instance_valid(strip) or not is_instance_valid(focus):
			continue

		var state_color: Color = lane_color
		var state_alpha: float = LANE_IDLE_ALPHA
		var focus_alpha: float = 0.08
		var focus_scale: float = 1.0
		var focus_color: Color = inactive_color

		if lane == player_combat.current_lane:
			state_alpha += 0.05
			focus_alpha = 0.12

		var proj = lane_manager.get_projectile(lane)
		if proj != null and not proj.is_resolved and not proj.is_reflected:
			var p: float = proj.progress
			var pressure: float = clamp((p - 0.76) / 0.28, 0.0, 1.0)
			if pressure > 0.0:
				state_color = lane_color.lerp(active_color.darkened(0.20), 0.55)
				state_alpha = lerp(state_alpha, LANE_THREAT_ALPHA, pressure)
				focus_color = active_color
				focus_alpha = lerp(focus_alpha, 0.28, pressure)
				focus_scale = lerp(1.0, 1.12, pressure)
				var pulse: float = 0.92 + (sin(time * 5.2 + lane) * 0.03 + 0.03) * pressure
				strip.scale.y = pulse
			else:
				strip.scale.y = 1.0

			if p >= outer_entry and p <= outer_exit:
				var critical_t: float = 1.0 - clamp(abs(p - 1.0) / (outer_exit - 1.0), 0.0, 1.0)
				state_alpha = lerp(state_alpha, LANE_CRITICAL_ALPHA, 0.65 + critical_t * 0.35)
				focus_alpha = lerp(focus_alpha, 0.42, 0.70 + critical_t * 0.30)
				focus_scale = lerp(focus_scale, 1.22, 0.70 + critical_t * 0.30)
				focus_color = active_color.lightened(0.08)
		else:
			strip.scale.y = 1.0

		strip.color = Color(state_color.r, state_color.g, state_color.b, state_alpha)
		focus.color = Color(focus_color.r, focus_color.g, focus_color.b, focus_alpha)
		focus.scale = Vector2(focus_scale, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	if _awaiting_growth_choice:
		if key_event.keycode == KEY_1:
			_choose_growth_option(0)
			return
		if key_event.keycode == KEY_2:
			_choose_growth_option(1)
			return
		if key_event.keycode == KEY_3:
			_choose_growth_option(2)
			return

	if _awaiting_reward_choice and not _reward_choice_made:
		if key_event.keycode == KEY_B:
			_choose_bond()
			return
		if key_event.keycode == KEY_E:
			_choose_eat()
			return

	if _awaiting_continue:
		if key_event.keycode == KEY_C:
			_continue_to_next_encounter()
			return
		if key_event.keycode == KEY_R:
			_start_mini_run()
			return

	if _run_finished:
		if key_event.keycode == KEY_R:
			_start_mini_run()
			return


func _setup_visuals() -> void:
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.z_index = -10
	background.color = Color(0.05, 0.04, 0.05, 1.0)

	var field_rect := Rect2(86.0, 102.0, 1108.0, 488.0)

	_battlefield_panel = ColorRect.new()
	_battlefield_panel.name = "BattlefieldPanel"
	_battlefield_panel.position = field_rect.position
	_battlefield_panel.size = field_rect.size
	_battlefield_panel.color = Color(0.07, 0.07, 0.08, 0.92)
	_battlefield_panel.z_index = -7
	add_child(_battlefield_panel)

	_battlefield_inner_panel = ColorRect.new()
	_battlefield_inner_panel.name = "BattlefieldInner"
	_battlefield_inner_panel.position = field_rect.position + Vector2(16.0, 14.0)
	_battlefield_inner_panel.size = field_rect.size - Vector2(32.0, 28.0)
	_battlefield_inner_panel.color = Color(0.10, 0.09, 0.10, 0.56)
	_battlefield_inner_panel.z_index = -6
	add_child(_battlefield_inner_panel)

	_battlefield_left_shade = ColorRect.new()
	_battlefield_left_shade.name = "BattlefieldLeftShade"
	_battlefield_left_shade.position = Vector2(field_rect.position.x + 12.0, field_rect.position.y + 16.0)
	_battlefield_left_shade.size = Vector2(48.0, field_rect.size.y - 32.0)
	_battlefield_left_shade.color = Color(0.03, 0.03, 0.04, 0.46)
	_battlefield_left_shade.z_index = -5
	add_child(_battlefield_left_shade)

	_battlefield_right_shade = ColorRect.new()
	_battlefield_right_shade.name = "BattlefieldRightShade"
	_battlefield_right_shade.position = Vector2(field_rect.end.x - 60.0, field_rect.position.y + 16.0)
	_battlefield_right_shade.size = Vector2(48.0, field_rect.size.y - 32.0)
	_battlefield_right_shade.color = Color(0.03, 0.03, 0.04, 0.40)
	_battlefield_right_shade.z_index = -5
	add_child(_battlefield_right_shade)

	_battlefield_top_trim = ColorRect.new()
	_battlefield_top_trim.name = "BattlefieldTopTrim"
	_battlefield_top_trim.position = field_rect.position + Vector2(10.0, 10.0)
	_battlefield_top_trim.size = Vector2(field_rect.size.x - 20.0, 3.0)
	_battlefield_top_trim.color = Color(0.34, 0.29, 0.25, 0.36)
	_battlefield_top_trim.z_index = -5
	add_child(_battlefield_top_trim)

	_battlefield_bottom_trim = ColorRect.new()
	_battlefield_bottom_trim.name = "BattlefieldBottomTrim"
	_battlefield_bottom_trim.position = Vector2(field_rect.position.x + 10.0, field_rect.end.y - 13.0)
	_battlefield_bottom_trim.size = Vector2(field_rect.size.x - 20.0, 2.0)
	_battlefield_bottom_trim.color = Color(0.20, 0.16, 0.14, 0.28)
	_battlefield_bottom_trim.z_index = -5
	add_child(_battlefield_bottom_trim)

	flash_overlay.anchor_right = 1.0
	flash_overlay.anchor_bottom = 1.0
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_overlay.z_index = 100
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_ui() -> void:
	_build_meter_shell()
	combo_label.text = "0"
	combo_label.position = Vector2(1052.0, 18.0)
	combo_label.size = Vector2(168.0, 24.0)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label.add_theme_font_size_override("font_size", 20)
	combo_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.89, 1.0))
	style_label.text = "Stirring"
	style_label.position = Vector2(954.0, 43.0)
	style_label.size = Vector2(222.0, 20.0)
	style_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	style_label.add_theme_font_size_override("font_size", 16)
	style_label.add_theme_color_override("font_color", Color(0.93, 0.90, 0.84, 1.0))
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	stamina_bar.position = Vector2(124.0, 50.0)
	stamina_bar.size = Vector2(222.0, 10.0)
	stamina_bar.show_percentage = false
	hp_bar.min_value = 0.0
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	hp_bar.position = Vector2(124.0, 27.0)
	hp_bar.size = Vector2(222.0, 12.0)
	hp_bar.show_percentage = false
	ultimate_label.text = "0%"
	ultimate_label.position = Vector2(954.0, 18.0)
	ultimate_label.size = Vector2(100.0, 20.0)
	ultimate_label.add_theme_font_size_override("font_size", 15)
	ultimate_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.70, 1.0))
	result_label.visible = false
	result_label.text = ""
	result_label.position = Vector2(352.0, 254.0)
	result_label.size = Vector2(576.0, 118.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.add_theme_color_override("font_color", Color(0.92, 0.89, 0.80, 1.0))
	controls_label.text = "A/S/D lane  |  Left+Lane parry  |  Right+Lane dodge  |  R ultimate"
	controls_label.position = Vector2(34.0, 648.0)
	controls_label.size = Vector2(620.0, 24.0)
	controls_label.add_theme_font_size_override("font_size", 12)
	controls_label.add_theme_color_override("font_color", Color(0.67, 0.63, 0.58, 0.92))
	_style_progress_bar(hp_bar, Color(0.18, 0.06, 0.08, 0.88), Color(0.73, 0.24, 0.26, 1.0), 6)
	_style_progress_bar(stamina_bar, Color(0.08, 0.09, 0.10, 0.82), Color(0.44, 0.66, 0.58, 1.0), 5)
	_build_quig_anchor()
	_refresh_hud_snapshot(0, 0.0, "stirring")


func _build_meter_shell() -> void:
	_meter_shell = ColorRect.new()
	_meter_shell.name = "MeterShell"
	_meter_shell.position = Vector2.ZERO
	_meter_shell.size = Vector2.ZERO
	_meter_shell.color = Color(0.0, 0.0, 0.0, 0.0)
	ui_layer.add_child(_meter_shell)

	_combo_shell = ColorRect.new()
	_combo_shell.name = "LeftHudShell"
	_combo_shell.position = Vector2(20.0, 10.0)
	_combo_shell.size = Vector2(338.0, 62.0)
	_combo_shell.color = Color(0.08, 0.08, 0.09, 0.68)
	ui_layer.add_child(_combo_shell)

	_style_shell = ColorRect.new()
	_style_shell.name = "RightHudShell"
	_style_shell.position = Vector2(920.0, 10.0)
	_style_shell.size = Vector2(312.0, 62.0)
	_style_shell.color = Color(0.09, 0.08, 0.09, 0.66)
	ui_layer.add_child(_style_shell)

	_resource_shell = ColorRect.new()
	_resource_shell.name = "RightHudAccent"
	_resource_shell.position = Vector2(1038.0, 22.0)
	_resource_shell.size = Vector2(182.0, 16.0)
	_resource_shell.color = Color(0.16, 0.13, 0.11, 0.28)
	ui_layer.add_child(_resource_shell)

	_support_shell = ColorRect.new()
	_support_shell.name = "SupportShell"
	_support_shell.position = Vector2(904.0, 80.0)
	_support_shell.size = Vector2(220.0, 50.0)
	_support_shell.color = Color(0.08, 0.08, 0.10, 0.56)
	ui_layer.add_child(_support_shell)

	_support_name_label = Label.new()
	_support_name_label.position = Vector2(916.0, 84.0)
	_support_name_label.size = Vector2(144.0, 14.0)
	_support_name_label.text = "NO BOND"
	_support_name_label.add_theme_font_size_override("font_size", 10)
	_support_name_label.add_theme_color_override("font_color", Color(0.69, 0.66, 0.62, 0.90))
	ui_layer.add_child(_support_name_label)

	_support_value_label = Label.new()
	_support_value_label.position = Vector2(1060.0, 84.0)
	_support_value_label.size = Vector2(52.0, 14.0)
	_support_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_support_value_label.text = "0%"
	_support_value_label.add_theme_font_size_override("font_size", 11)
	_support_value_label.add_theme_color_override("font_color", Color(0.93, 0.90, 0.84, 1.0))
	ui_layer.add_child(_support_value_label)

	_support_bar = ProgressBar.new()
	_support_bar.position = Vector2(916.0, 99.0)
	_support_bar.size = Vector2(196.0, 8.0)
	_support_bar.min_value = 0.0
	_support_bar.max_value = 100.0
	_support_bar.value = 0.0
	_support_bar.show_percentage = false
	ui_layer.add_child(_support_bar)
	_style_progress_bar(_support_bar, Color(0.08, 0.09, 0.10, 0.80), Color(0.54, 0.70, 0.63, 0.92), 4)

	_support_trigger_label = Label.new()
	_support_trigger_label.name = "SupportTriggerHint"
	_support_trigger_label.position = Vector2(916.0, 110.0)
	_support_trigger_label.size = Vector2(196.0, 12.0)
	_support_trigger_label.text = ""
	_support_trigger_label.add_theme_font_size_override("font_size", 9)
	_support_trigger_label.add_theme_color_override("font_color", Color(0.58, 0.56, 0.52, 0.72))
	ui_layer.add_child(_support_trigger_label)

	_run_build_shell = ColorRect.new()
	_run_build_shell.name = "RunBuildShell"
	_run_build_shell.position = Vector2(904.0, 134.0)
	_run_build_shell.size = Vector2(244.0, 70.0)
	_run_build_shell.color = Color(0.07, 0.07, 0.09, 0.54)
	ui_layer.add_child(_run_build_shell)

	var eaten_caption := Label.new()
	eaten_caption.position = Vector2(916.0, 137.0)
	eaten_caption.size = Vector2(44.0, 12.0)
	eaten_caption.text = "EAT"
	eaten_caption.add_theme_font_size_override("font_size", 10)
	eaten_caption.add_theme_color_override("font_color", Color(0.69, 0.64, 0.59, 0.88))
	ui_layer.add_child(eaten_caption)

	_eaten_value_label = Label.new()
	_eaten_value_label.position = Vector2(954.0, 136.0)
	_eaten_value_label.size = Vector2(184.0, 12.0)
	_eaten_value_label.text = "--"
	_eaten_value_label.add_theme_font_size_override("font_size", 10)
	_eaten_value_label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.81, 0.96))
	ui_layer.add_child(_eaten_value_label)

	var upgrade_caption := Label.new()
	upgrade_caption.position = Vector2(916.0, 160.0)
	upgrade_caption.size = Vector2(44.0, 12.0)
	upgrade_caption.text = "MUT"
	upgrade_caption.add_theme_font_size_override("font_size", 10)
	upgrade_caption.add_theme_color_override("font_color", Color(0.69, 0.64, 0.59, 0.88))
	ui_layer.add_child(upgrade_caption)

	_upgrade_value_label = Label.new()
	_upgrade_value_label.position = Vector2(954.0, 159.0)
	_upgrade_value_label.size = Vector2(184.0, 12.0)
	_upgrade_value_label.text = "--"
	_upgrade_value_label.add_theme_font_size_override("font_size", 10)
	_upgrade_value_label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.81, 0.96))
	ui_layer.add_child(_upgrade_value_label)

	var bond_caption := Label.new()
	bond_caption.position = Vector2(916.0, 183.0)
	bond_caption.size = Vector2(44.0, 12.0)
	bond_caption.text = "BOND"
	bond_caption.add_theme_font_size_override("font_size", 10)
	bond_caption.add_theme_color_override("font_color", Color(0.69, 0.64, 0.59, 0.88))
	ui_layer.add_child(bond_caption)

	_bond_value_label = Label.new()
	_bond_value_label.position = Vector2(954.0, 182.0)
	_bond_value_label.size = Vector2(184.0, 12.0)
	_bond_value_label.text = "--"
	_bond_value_label.add_theme_font_size_override("font_size", 10)
	_bond_value_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.80, 0.96))
	ui_layer.add_child(_bond_value_label)

	var hp_caption := Label.new()
	hp_caption.position = Vector2(34.0, 18.0)
	hp_caption.size = Vector2(72.0, 16.0)
	hp_caption.text = "HEALTH"
	hp_caption.add_theme_font_size_override("font_size", 11)
	hp_caption.add_theme_color_override("font_color", Color(0.70, 0.66, 0.61, 0.92))
	ui_layer.add_child(hp_caption)

	_hp_value_label = Label.new()
	_hp_value_label.position = Vector2(262.0, 16.0)
	_hp_value_label.size = Vector2(86.0, 18.0)
	_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_value_label.add_theme_font_size_override("font_size", 15)
	_hp_value_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.90, 1.0))
	ui_layer.add_child(_hp_value_label)

	var exp_caption := Label.new()
	exp_caption.position = Vector2(34.0, 41.0)
	exp_caption.size = Vector2(72.0, 14.0)
	exp_caption.text = "EXP"
	exp_caption.add_theme_font_size_override("font_size", 11)
	exp_caption.add_theme_color_override("font_color", Color(0.66, 0.68, 0.64, 0.90))
	ui_layer.add_child(exp_caption)

	_exp_value_label = Label.new()
	_exp_value_label.position = Vector2(262.0, 40.0)
	_exp_value_label.size = Vector2(86.0, 16.0)
	_exp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_exp_value_label.add_theme_font_size_override("font_size", 13)
	_exp_value_label.add_theme_color_override("font_color", Color(0.95, 0.97, 0.93, 1.0))
	ui_layer.add_child(_exp_value_label)

	var atk_caption := Label.new()
	atk_caption.position = Vector2(34.0, 63.0)
	atk_caption.size = Vector2(72.0, 14.0)
	atk_caption.text = "ATK"
	atk_caption.add_theme_font_size_override("font_size", 11)
	atk_caption.add_theme_color_override("font_color", Color(0.66, 0.65, 0.63, 0.90))
	ui_layer.add_child(atk_caption)

	_atk_value_label = Label.new()
	_atk_value_label.position = Vector2(262.0, 62.0)
	_atk_value_label.size = Vector2(86.0, 16.0)
	_atk_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_atk_value_label.add_theme_font_size_override("font_size", 13)
	_atk_value_label.add_theme_color_override("font_color", Color(0.90, 0.88, 0.85, 1.0))
	ui_layer.add_child(_atk_value_label)

	var style_caption := Label.new()
	style_caption.position = Vector2(954.0, 41.0)
	style_caption.size = Vector2(48.0, 16.0)
	style_caption.text = "STYLE"
	style_caption.add_theme_font_size_override("font_size", 11)
	style_caption.add_theme_color_override("font_color", Color(0.71, 0.67, 0.62, 0.92))
	ui_layer.add_child(style_caption)

	var score_caption := Label.new()
	score_caption.position = Vector2(1080.0, 18.0)
	score_caption.size = Vector2(68.0, 14.0)
	score_caption.text = "SCORE"
	score_caption.add_theme_font_size_override("font_size", 11)
	score_caption.add_theme_color_override("font_color", Color(0.71, 0.67, 0.62, 0.92))
	ui_layer.add_child(score_caption)

	var ultimate_caption := Label.new()
	ultimate_caption.position = Vector2(954.0, 18.0)
	ultimate_caption.size = Vector2(72.0, 14.0)
	ultimate_caption.text = "ULTIMATE"
	ultimate_caption.add_theme_font_size_override("font_size", 11)
	ultimate_caption.add_theme_color_override("font_color", Color(0.76, 0.70, 0.62, 0.94))
	ui_layer.add_child(ultimate_caption)

	# Boss HP bar — centered between HUD shells, hidden until a boss encounter loads.
	_boss_hp_shell = ColorRect.new()
	_boss_hp_shell.name = "BossHpShell"
	_boss_hp_shell.position = Vector2(380.0, 6.0)
	_boss_hp_shell.size = Vector2(520.0, 56.0)
	_boss_hp_shell.color = Color(0.09, 0.06, 0.04, 0.82)
	_boss_hp_shell.visible = false
	ui_layer.add_child(_boss_hp_shell)

	_boss_name_label = Label.new()
	_boss_name_label.name = "BossNameLabel"
	_boss_name_label.position = Vector2(380.0, 10.0)
	_boss_name_label.size = Vector2(520.0, 16.0)
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.text = ""
	_boss_name_label.add_theme_font_size_override("font_size", 11)
	_boss_name_label.add_theme_color_override("font_color", Color(0.84, 0.60, 0.18, 1.0))
	_boss_name_label.visible = false
	ui_layer.add_child(_boss_name_label)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.name = "BossHpBar"
	_boss_hp_bar.position = Vector2(392.0, 30.0)
	_boss_hp_bar.size = Vector2(496.0, 20.0)
	_boss_hp_bar.min_value = 0.0
	_boss_hp_bar.max_value = 100.0
	_boss_hp_bar.value = 100.0
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.visible = false
	ui_layer.add_child(_boss_hp_bar)
	_style_progress_bar(_boss_hp_bar, Color(0.10, 0.06, 0.03, 0.90), Color(0.84, 0.56, 0.12, 1.0), 4)


func _style_progress_bar(bar: ProgressBar, under_color: Color, fill_color: Color, corner_radius: int) -> void:
	var under := StyleBoxFlat.new()
	under.bg_color = under_color
	under.corner_radius_top_left = corner_radius
	under.corner_radius_top_right = corner_radius
	under.corner_radius_bottom_left = corner_radius
	under.corner_radius_bottom_right = corner_radius
	under.border_width_left = 1
	under.border_width_top = 1
	under.border_width_right = 1
	under.border_width_bottom = 1
	under.border_color = Color(0.17, 0.16, 0.16, 0.94)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = corner_radius
	fill.corner_radius_top_right = corner_radius
	fill.corner_radius_bottom_left = corner_radius
	fill.corner_radius_bottom_right = corner_radius

	bar.add_theme_stylebox_override("background", under)
	bar.add_theme_stylebox_override("fill", fill)


func _build_quig_anchor() -> void:
	_quig_anchor_label = Label.new()
	_quig_anchor_label.name = "QuigAnchor"
	_quig_anchor_label.visible = false
	_quig_anchor_label.position = Vector2(978.0, 176.0)
	_quig_anchor_label.size = Vector2(250.0, 42.0)
	_quig_anchor_label.text = ""
	_quig_anchor_label.add_theme_font_size_override("font_size", 12)
	_quig_anchor_label.add_theme_color_override("font_color", Color(0.72, 0.67, 0.58, 0.72))
	ui_layer.add_child(_quig_anchor_label)


func _refresh_hud_snapshot(score_value: int, exp_value: float, style_tier: String) -> void:
	if _hp_value_label != null:
		_hp_value_label.text = "%d/%d" % [int(GameState.player_hp), int(GameState.player_max_hp)]
	if _exp_value_label != null:
		var growth_level: int = 1
		if _run_growth != null and is_instance_valid(_run_growth):
			growth_level = int(_run_growth.level)
		_exp_value_label.text = "L%d  %.0f" % [growth_level, exp_value]
	_refresh_run_build_readout()

	combo_label.text = "%d" % score_value
	style_label.text = style_tier.capitalize()


func _create_feedback_label() -> void:
	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.visible = false
	_feedback_label.z_index = 90
	_feedback_label.position = Vector2(500.0, 88.0)
	_feedback_label.size = Vector2(260.0, 30.0)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 18)
	add_child(_feedback_label)


func _create_title_cards() -> void:
	_title_card = Label.new()
	_title_card.name = "BiomeTitleCard"
	_title_card.visible = false
	_title_card.z_index = 95
	_title_card.position = Vector2(420.0, 110.0)
	add_child(_title_card)

	_subtitle_card = Label.new()
	_subtitle_card.name = "BiomeSubtitleCard"
	_subtitle_card.visible = false
	_subtitle_card.z_index = 95
	_subtitle_card.position = Vector2(420.0, 140.0)
	add_child(_subtitle_card)


func _create_timing_circle_container() -> void:
	_timing_circle_container = Node2D.new()
	_timing_circle_container.name = "TimingCircles"
	_timing_circle_container.z_index = 20
	add_child(_timing_circle_container)


func _create_attack_fx_container() -> void:
	_attack_fx_container = Node2D.new()
	_attack_fx_container.name = "AttackFX"
	_attack_fx_container.z_index = 30
	add_child(_attack_fx_container)


func _create_reward_overlay() -> void:
	_reward_overlay = ColorRect.new()
	_reward_overlay.name = "RewardOverlay"
	_reward_overlay.visible = false
	_reward_overlay.color = Color(0.01, 0.01, 0.02, 0.88)
	_reward_overlay.anchor_right = 1.0
	_reward_overlay.anchor_bottom = 1.0
	_reward_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_reward_overlay)

	_reward_panel = ColorRect.new()
	_reward_panel.name = "RewardPanel"
	_reward_panel.color = Color(0.09, 0.07, 0.08, 0.98)
	_reward_panel.position = Vector2(160.0, 88.0)
	_reward_panel.size = Vector2(960.0, 452.0)
	_reward_overlay.add_child(_reward_panel)

	_reward_creature_tag_label = Label.new()
	_reward_creature_tag_label.name = "RewardTag"
	_reward_creature_tag_label.position = Vector2(42.0, 18.0)
	_reward_creature_tag_label.size = Vector2(220.0, 18.0)
	_reward_creature_tag_label.add_theme_font_size_override("font_size", 11)
	_reward_creature_tag_label.add_theme_color_override("font_color", Color(0.70, 0.62, 0.56, 0.92))
	_reward_panel.add_child(_reward_creature_tag_label)

	_reward_title_label = Label.new()
	_reward_title_label.name = "RewardTitle"
	_reward_title_label.position = Vector2(42.0, 40.0)
	_reward_title_label.size = Vector2(420.0, 48.0)
	_reward_title_label.add_theme_font_size_override("font_size", 30)
	_reward_title_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.84, 1.0))
	_reward_panel.add_child(_reward_title_label)

	_reward_body_label = Label.new()
	_reward_body_label.name = "RewardBody"
	_reward_body_label.position = Vector2(42.0, 98.0)
	_reward_body_label.size = Vector2(390.0, 150.0)
	_reward_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_body_label.add_theme_font_size_override("font_size", 16)
	_reward_body_label.add_theme_color_override("font_color", Color(0.80, 0.77, 0.72, 0.96))
	_reward_panel.add_child(_reward_body_label)

	_reward_bond_card = ColorRect.new()
	_reward_bond_card.name = "RewardBondCard"
	_reward_bond_card.position = Vector2(468.0, 54.0)
	_reward_bond_card.size = Vector2(206.0, 244.0)
	_reward_bond_card.color = Color(0.09, 0.10, 0.09, 0.96)
	_reward_panel.add_child(_reward_bond_card)

	_reward_bond_label = Label.new()
	_reward_bond_label.name = "RewardBondLabel"
	_reward_bond_label.position = Vector2(18.0, 18.0)
	_reward_bond_label.size = Vector2(160.0, 26.0)
	_reward_bond_label.add_theme_font_size_override("font_size", 18)
	_reward_bond_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.78, 1.0))
	_reward_bond_card.add_child(_reward_bond_label)

	_reward_bond_effect_label = Label.new()
	_reward_bond_effect_label.name = "RewardBondEffect"
	_reward_bond_effect_label.position = Vector2(18.0, 56.0)
	_reward_bond_effect_label.size = Vector2(170.0, 154.0)
	_reward_bond_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_bond_effect_label.add_theme_font_size_override("font_size", 14)
	_reward_bond_effect_label.add_theme_color_override("font_color", Color(0.77, 0.81, 0.76, 0.94))
	_reward_bond_card.add_child(_reward_bond_effect_label)

	_reward_eat_card = ColorRect.new()
	_reward_eat_card.name = "RewardEatCard"
	_reward_eat_card.position = Vector2(694.0, 54.0)
	_reward_eat_card.size = Vector2(206.0, 244.0)
	_reward_eat_card.color = Color(0.11, 0.08, 0.07, 0.96)
	_reward_panel.add_child(_reward_eat_card)

	_reward_eat_label = Label.new()
	_reward_eat_label.name = "RewardEatLabel"
	_reward_eat_label.position = Vector2(18.0, 18.0)
	_reward_eat_label.size = Vector2(160.0, 26.0)
	_reward_eat_label.add_theme_font_size_override("font_size", 18)
	_reward_eat_label.add_theme_color_override("font_color", Color(0.94, 0.73, 0.62, 1.0))
	_reward_eat_card.add_child(_reward_eat_label)

	_reward_eat_effect_label = Label.new()
	_reward_eat_effect_label.name = "RewardEatEffect"
	_reward_eat_effect_label.position = Vector2(18.0, 56.0)
	_reward_eat_effect_label.size = Vector2(170.0, 154.0)
	_reward_eat_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_eat_effect_label.add_theme_font_size_override("font_size", 14)
	_reward_eat_effect_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.73, 0.94))
	_reward_eat_card.add_child(_reward_eat_effect_label)

	_reward_quig_label = Label.new()
	_reward_quig_label.name = "RewardQuig"
	_reward_quig_label.position = Vector2(42.0, 316.0)
	_reward_quig_label.size = Vector2(860.0, 32.0)
	_reward_quig_label.add_theme_font_size_override("font_size", 13)
	_reward_quig_label.add_theme_color_override("font_color", Color(0.72, 0.67, 0.60, 0.92))
	_reward_panel.add_child(_reward_quig_label)

	_reward_hint_label = Label.new()
	_reward_hint_label.name = "RewardHint"
	_reward_hint_label.position = Vector2(42.0, 382.0)
	_reward_hint_label.size = Vector2(860.0, 26.0)
	_reward_hint_label.add_theme_font_size_override("font_size", 13)
	_reward_hint_label.add_theme_color_override("font_color", Color(0.80, 0.76, 0.70, 0.98))
	_reward_panel.add_child(_reward_hint_label)


func _create_growth_overlay() -> void:
	_growth_overlay = ColorRect.new()
	_growth_overlay.name = "GrowthOverlay"
	_growth_overlay.visible = false
	_growth_overlay.color = Color(0.01, 0.01, 0.02, 0.76)
	_growth_overlay.anchor_right = 1.0
	_growth_overlay.anchor_bottom = 1.0
	_growth_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_growth_overlay)

	_growth_panel = ColorRect.new()
	_growth_panel.name = "GrowthPanel"
	_growth_panel.position = Vector2(240.0, 138.0)
	_growth_panel.size = Vector2(800.0, 276.0)
	_growth_panel.color = Color(0.09, 0.07, 0.08, 0.97)
	_growth_overlay.add_child(_growth_panel)

	_growth_title_label = Label.new()
	_growth_title_label.position = Vector2(34.0, 24.0)
	_growth_title_label.size = Vector2(732.0, 32.0)
	_growth_title_label.add_theme_font_size_override("font_size", 22)
	_growth_title_label.add_theme_color_override("font_color", Color(0.95, 0.91, 0.84, 1.0))
	_growth_panel.add_child(_growth_title_label)

	_growth_hint_label = Label.new()
	_growth_hint_label.position = Vector2(34.0, 228.0)
	_growth_hint_label.size = Vector2(732.0, 20.0)
	_growth_hint_label.add_theme_font_size_override("font_size", 12)
	_growth_hint_label.add_theme_color_override("font_color", Color(0.76, 0.71, 0.65, 0.98))
	_growth_panel.add_child(_growth_hint_label)

	for i in range(3):
		var option_label := Label.new()
		option_label.position = Vector2(34.0 + 244.0 * i, 76.0)
		option_label.size = Vector2(212.0, 132.0)
		option_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		option_label.add_theme_font_size_override("font_size", 15)
		option_label.add_theme_color_override("font_color", Color(0.90, 0.85, 0.79, 1.0))
		_growth_panel.add_child(option_label)
		_growth_option_labels.append(option_label)


func _setup_run_growth() -> void:
	var script: Script = load(RUN_GROWTH_SCRIPT_PATH)
	if script == null:
		push_error("RunGrowth script missing: " + RUN_GROWTH_SCRIPT_PATH)
		return

	_run_growth = Node.new()
	_run_growth.name = "RunGrowth"
	_run_growth.set_script(script)
	add_child(_run_growth)


func _connect_eventbus() -> void:
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.style_changed.connect(_on_style_changed)
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.player_took_damage.connect(_on_player_took_damage)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.ultimate_available.connect(_on_ultimate_available)
	EventBus.ultimate_fired.connect(_on_ultimate_fired)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.screen_flash.connect(_on_screen_flash)
	EventBus.screen_shake.connect(_on_screen_shake)
	EventBus.slow_motion.connect(_on_slow_motion)
	EventBus.player_attacked.connect(_on_player_attacked)
	EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.player_dodged.connect(_on_player_dodged)
	EventBus.player_no_stamina.connect(_on_player_no_stamina)
	EventBus.combo_broken.connect(_on_combo_broken)
	EventBus.player_teleported.connect(_on_player_teleported)
	EventBus.timing_ring_pressed.connect(_on_timing_ring_pressed)
	EventBus.run_growth_changed.connect(_on_run_growth_changed)
	EventBus.support_charge_changed.connect(_on_support_charge_changed)
	EventBus.bonded_support_triggered.connect(_on_bonded_support_triggered)
	EventBus.run_upgrade_taken.connect(_on_run_upgrade_taken)


func _setup_lane_manager() -> void:
	lane_manager.setup_layout(get_viewport_rect().size)

	if not lane_manager.load_scene():
		push_error("LaneManager failed to load projectile scene.")
		return

	lane_manager.combat_scene = self


func _setup_player_combat() -> void:
	if player_combat.has_method("setup"):
		player_combat.setup(lane_manager, combat_meter)


func _build_mini_run_queue() -> Array:
	return COMBAT_CONTENT.build_mini_run_queue()


func _start_mini_run() -> void:
	# Starts a fresh run from the beginning of the encounter queue.
	GameState.run_number += 1

	_encounter_queue = _build_mini_run_queue()
	_current_encounter_queue_index = 0
	_run_finished = false
	_is_boss_encounter = false
	_boss_total_hp = 0.0
	_boss_current_hp = 0.0
	_hide_boss_bar()

	_hide_reward_overlay()

	if GameState.has_method("reset_run_state"):
		GameState.reset_run_state()

	EventBus.emit_signal("run_started", int(GameState.run_number))
	_refresh_run_build_readout()
	_load_current_queued_encounter(true)


func _load_current_queued_encounter(reset_hp: bool) -> void:
	_encounter_load_gen += 1
	var load_gen: int = _encounter_load_gen

	if _current_encounter_queue_index < 0 or _current_encounter_queue_index >= _encounter_queue.size():
		_finish_run(true)
		return

	_active_encounter = _encounter_queue[_current_encounter_queue_index]
	_current_phase_index = 0
	_combat_finished = false
	_phase_transitioning = false

	_is_boss_encounter = bool(_active_encounter.get("is_boss", false))

	_rebuild_enemy_lookup_tables()
	_apply_encounter_presentation()
	_build_arena_visuals()
	_draw_timing_circles()
	_prepare_for_encounter(reset_hp)

	if _is_boss_encounter:
		_setup_boss_hp_bar()
		await _show_boss_intro(String(_active_encounter.get("boss_name", "BOSS")))
		# If R was pressed during the intro a newer load has already started — bail out.
		if load_gen != _encounter_load_gen:
			return
	else:
		_hide_boss_bar()
		_show_title_card(
			String(_active_encounter.get("biome", {}).get("name", "Unknown Place")),
			String(_active_encounter.get("title", "Encounter"))
		)

	_start_current_phase()


func _rebuild_enemy_lookup_tables() -> void:
	_all_enemies_by_id.clear()
	_enemy_phase_by_id.clear()

	var phases: Array = _active_encounter.get("phases", [])
	for phase_index in range(phases.size()):
		var phase_enemies: Array = phases[phase_index]
		for enemy in phase_enemies:
			var enemy_id: int = int(enemy.get("id", -1))
			if enemy_id >= 0:
				_all_enemies_by_id[enemy_id] = enemy.duplicate(true)
				_enemy_phase_by_id[enemy_id] = phase_index


func _apply_encounter_presentation() -> void:
	var biome: Dictionary = _active_encounter.get("biome", {})

	background.color = biome.get("background_color", Color(0.06, 0.06, 0.08, 1.0))
	result_label.visible = false
	result_label.text = ""


func _build_arena_visuals() -> void:
	_enemy_markers_by_id.clear()
	_enemy_max_hp.clear()
	_lane_strips.clear()
	_lane_hit_focus.clear()

	if _lane_marker_container != null:
		_lane_marker_container.queue_free()
	if _enemy_marker_container != null:
		_enemy_marker_container.queue_free()

	_lane_marker_container = Node2D.new()
	_lane_marker_container.name = "LaneMarkers"
	add_child(_lane_marker_container)

	_enemy_marker_container = Node2D.new()
	_enemy_marker_container.name = "EnemyMarkers"
	add_child(_enemy_marker_container)

	var biome: Dictionary = _active_encounter.get("biome", {})
	var lane_color: Color = biome.get("lane_color", Color(0.30, 0.30, 0.35, 1.0))
	var inactive_enemy_color: Color = biome.get("enemy_inactive_color", Color(0.40, 0.20, 0.20, 0.5))

	for lane in range(3):
		var lane_strip := ColorRect.new()
		lane_strip.name = "LaneStrip_%d" % lane
		lane_strip.size = Vector2(get_viewport_rect().size.x - 240.0, LANE_BAND_HEIGHT)
		lane_strip.position = Vector2(120.0, lane_manager.get_lane_y(lane) - LANE_BAND_HEIGHT * 0.5)
		lane_strip.pivot_offset = lane_strip.size * 0.5
		lane_strip.color = Color(lane_color.r, lane_color.g, lane_color.b, LANE_IDLE_ALPHA)
		_lane_marker_container.add_child(lane_strip)
		_lane_strips[lane] = lane_strip

		var lane_channel := ColorRect.new()
		lane_channel.name = "LaneChannel_%d" % lane
		lane_channel.size = Vector2(get_viewport_rect().size.x - 260.0, LANE_BAND_HEIGHT - 18.0)
		lane_channel.position = Vector2(130.0, lane_manager.get_lane_y(lane) - (LANE_BAND_HEIGHT - 18.0) * 0.5)
		lane_channel.color = Color(lane_color.r * 0.70, lane_color.g * 0.72, lane_color.b * 0.78, 0.10)
		_lane_marker_container.add_child(lane_channel)

		var lane_line := Line2D.new()
		lane_line.default_color = lane_color.lightened(0.05)
		lane_line.width = 2.2
		lane_line.add_point(Vector2(120.0, lane_manager.get_lane_y(lane)))
		lane_line.add_point(Vector2(get_viewport_rect().size.x - 120.0, lane_manager.get_lane_y(lane)))
		_lane_marker_container.add_child(lane_line)

		var lane_cap_top := Line2D.new()
		lane_cap_top.default_color = Color(lane_color.r, lane_color.g, lane_color.b, 0.16)
		lane_cap_top.width = 1.0
		lane_cap_top.add_point(Vector2(136.0, lane_manager.get_lane_y(lane) - 18.0))
		lane_cap_top.add_point(Vector2(get_viewport_rect().size.x - 136.0, lane_manager.get_lane_y(lane) - 18.0))
		_lane_marker_container.add_child(lane_cap_top)

		var lane_cap_bottom := Line2D.new()
		lane_cap_bottom.default_color = Color(lane_color.r, lane_color.g, lane_color.b, 0.12)
		lane_cap_bottom.width = 1.0
		lane_cap_bottom.add_point(Vector2(136.0, lane_manager.get_lane_y(lane) + 18.0))
		lane_cap_bottom.add_point(Vector2(get_viewport_rect().size.x - 136.0, lane_manager.get_lane_y(lane) + 18.0))
		_lane_marker_container.add_child(lane_cap_bottom)

		var lane_focus := ColorRect.new()
		lane_focus.name = "LaneFocus_%d" % lane
		lane_focus.size = Vector2(48.0, 74.0)
		lane_focus.position = Vector2(
			lane_manager.get_hit_zone_x() - 24.0,
			lane_manager.get_lane_y(lane) - 37.0
		)
		lane_focus.pivot_offset = lane_focus.size * 0.5
		lane_focus.color = Color(0.78, 0.72, 0.54, 0.08)
		_lane_marker_container.add_child(lane_focus)
		_lane_hit_focus[lane] = lane_focus

	for enemy_id in _all_enemies_by_id.keys():
		var enemy: Dictionary = _all_enemies_by_id[enemy_id]
		var lane: int = int(enemy.get("lane", 0))

		var marker_size: float = 64.0 if _is_boss_encounter else 42.0
		var marker_half: float = marker_size * 0.5
		var enemy_marker := ColorRect.new()
		enemy_marker.name = "Enemy_%d" % enemy_id
		enemy_marker.size = Vector2(marker_size, marker_size)
		enemy_marker.position = Vector2(
			lane_manager.get_enemy_x() - marker_half,
			lane_manager.get_lane_y(lane) - marker_half
		)
		enemy_marker.color = inactive_enemy_color
		enemy_marker.modulate = Color(1.0, 1.0, 1.0, 1.0)

		_enemy_marker_container.add_child(enemy_marker)
		_enemy_markers_by_id[enemy_id] = enemy_marker
		_enemy_max_hp[enemy_id] = float(enemy.get("hp", 1))

	_refresh_enemy_marker_states()


func _refresh_enemy_marker_states() -> void:
	var biome: Dictionary = _active_encounter.get("biome", {})
	var active_color: Color = biome.get("enemy_active_color", Color(0.76, 0.21, 0.21, 1.0))
	var inactive_color: Color = biome.get("enemy_inactive_color", Color(0.38, 0.18, 0.18, 0.55))

	for enemy_id in _enemy_markers_by_id.keys():
		var marker: ColorRect = _enemy_markers_by_id[enemy_id]
		if marker == null or not is_instance_valid(marker):
			continue

		var enemy_phase: int = int(_enemy_phase_by_id.get(enemy_id, -1))
		if enemy_phase == _current_phase_index:
			marker.color = active_color
		else:
			marker.color = inactive_color


func _draw_timing_circles() -> void:
	for child in _timing_circle_container.get_children():
		child.queue_free()

	var biome: Dictionary = _active_encounter.get("biome", {})
	var active_color: Color = biome.get("ring_active_color", Color(1.0, 0.95, 0.55, 1.0))
	var inactive_color: Color = biome.get("ring_inactive_color", Color(0.7, 0.7, 0.8, 0.45))

	for lane in range(3):
		var lane_group := Node2D.new()
		lane_group.name = "TimingRing_%d" % lane
		lane_group.position = Vector2(
			lane_manager.get_hit_zone_x(),
			lane_manager.get_lane_y(lane)
		)

		var is_active_lane: bool = lane == player_combat.current_lane
		var base_color: Color = active_color if is_active_lane else inactive_color

		var receiver_glow := _make_disc_polygon(RING_OUTER_RADIUS + 6.0, Color(base_color.r, base_color.g, base_color.b, 0.0))
		receiver_glow.name = "ReceiverGlow"

		var receiver_fill := _make_disc_polygon(RING_GOOD_RADIUS + 1.0, Color(base_color.r, base_color.g, base_color.b, 0.06))
		receiver_fill.name = "ReceiverFill"

		var outer_ring := _make_ring_line(RING_OUTER_RADIUS, base_color.darkened(0.02), 2.5)
		outer_ring.name = "Outer"

		var good_ring := _make_ring_line(
			RING_GOOD_RADIUS,
			Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.10),
			0.8
		)
		good_ring.name = "Good"

		var perfect_ring := _make_ring_line(RING_PERFECT_RADIUS, base_color.lightened(0.20), 2.5)
		perfect_ring.name = "Perfect"

		var edge_ring := _make_ring_line(RING_OUTER_RADIUS + 4.0, Color(base_color.r, base_color.g, base_color.b, 0.0), 1.0)
		edge_ring.name = "Edge"

		# Vertical beat mark at the circle center — the projectile crosses this line
		# at progress = 1.0, which is the center of the perfect parry window.
		var beat_mark := Line2D.new()
		beat_mark.name = "BeatMark"
		beat_mark.default_color = base_color.darkened(0.10)
		beat_mark.width = 1.8
		beat_mark.add_point(Vector2(0.0, -RING_OUTER_RADIUS))
		beat_mark.add_point(Vector2(0.0, RING_OUTER_RADIUS))

		lane_group.add_child(receiver_glow)
		lane_group.add_child(receiver_fill)
		lane_group.add_child(edge_ring)
		lane_group.add_child(outer_ring)
		lane_group.add_child(good_ring)
		lane_group.add_child(perfect_ring)
		lane_group.add_child(beat_mark)
		_timing_circle_container.add_child(lane_group)


func _make_ring_line(radius: float, color: Color, width: float) -> Line2D:
	var ring := Line2D.new()
	ring.default_color = color
	ring.width = width

	for i in range(RING_POINT_COUNT + 1):
		var angle: float = (TAU * float(i)) / float(RING_POINT_COUNT)
		ring.add_point(Vector2(cos(angle), sin(angle)) * radius)

	return ring


func _make_disc_polygon(radius: float, color: Color) -> Polygon2D:
	var disc := Polygon2D.new()
	disc.color = color

	var points := PackedVector2Array()
	for i in range(RING_POINT_COUNT + 1):
		var angle: float = (TAU * float(i)) / float(RING_POINT_COUNT)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	disc.polygon = points
	return disc


func _prepare_for_encounter(reset_hp: bool) -> void:
	# Resets encounter-local state. HP only resets at run start, not between encounters.
	if reset_hp:
		GameState.player_hp = GameState.player_max_hp

	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp

	if player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(true)

	if combat_meter.has_method("reset"):
		combat_meter.reset()

	_hide_reward_overlay()
	result_label.visible = false
	result_label.text = ""
	_set_combat_controls_text()


func _set_combat_controls_text() -> void:
	var encounter_count: int = _encounter_queue.size()
	var encounter_number: int = _current_encounter_queue_index + 1
	controls_label.text = "Encounter %d/%d  |  A/S/D lane  |  Left parry  |  Right dodge  |  R ultimate" % [
		encounter_number,
		encounter_count
	]


func _start_current_phase() -> void:
	if _combat_finished:
		return

	var phases: Array = _active_encounter.get("phases", [])
	if _current_phase_index < 0 or _current_phase_index >= phases.size():
		_complete_current_encounter()
		return

	_phase_transitioning = false
	_refresh_enemy_marker_states()

	var phase_intro_texts: Array = _active_encounter.get("phase_intro_texts", [])
	if _current_phase_index < phase_intro_texts.size():
		_show_feedback(String(phase_intro_texts[_current_phase_index]), Color(0.92, 0.88, 0.74, 1.0), 0.45)

	var phase_enemies: Array = phases[_current_phase_index]
	var lane_array: Array = [{}, {}, {}]

	for enemy in phase_enemies:
		var lane: int = int(enemy.get("lane", -1))
		if lane >= 0 and lane < 3:
			lane_array[lane] = enemy.duplicate(true)

	lane_manager.start_combat(lane_array)


func _advance_phase() -> void:
	if _combat_finished:
		return

	var phases: Array = _active_encounter.get("phases", [])
	_current_phase_index += 1

	if _current_phase_index >= phases.size():
		_complete_current_encounter()
		return

	_phase_transitioning = true
	_refresh_enemy_marker_states()

	var pause_duration: float = 0.45
	if _is_boss_encounter:
		pause_duration = 1.0
		_show_feedback("THE HOLLOW OPENS ITS FULL MOUTH.", Color(0.86, 0.58, 0.14, 1.0), 0.70)
		EventBus.emit_signal("screen_flash", Color(0.60, 0.36, 0.06, 0.20), 0.30)

	var timer: SceneTreeTimer = get_tree().create_timer(pause_duration)
	await timer.timeout

	if _combat_finished:
		return

	_start_current_phase()


func _complete_current_encounter() -> void:
	# Called only when the final phase of the current encounter is cleared.
	if _combat_finished:
		return

	_combat_finished = true
	_phase_transitioning = false

	if lane_manager != null and lane_manager.has_method("stop"):
		lane_manager.stop()

	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(false)

	var biome: Dictionary = _active_encounter.get("biome", {})
	result_label.text = String(biome.get("victory_text", "VICTORY"))
	result_label.visible = true

	if _is_boss_encounter:
		_hide_boss_bar()
		_show_feedback("SOVEREIGN FELLED", Color(0.90, 0.74, 0.28, 1.0), 0.70)
		EventBus.emit_signal("screen_flash", Color(0.55, 0.40, 0.10, 0.16), 0.20)
	else:
		_show_feedback("ENCOUNTER CLEAR", Color(0.85, 1.0, 0.75, 1.0), 0.55)
		EventBus.emit_signal("screen_flash", Color(0.55, 1.0, 0.75, 0.10), 0.14)

	var reward_creature: Dictionary = _active_encounter.get("reward_creature", {})
	if reward_creature.is_empty():
		var pool: Array = _active_encounter.get("reward_creature_pool", [])
		if not pool.is_empty():
			reward_creature = pool[randi() % pool.size()]
	if not reward_creature.is_empty():
		_offer_victory_reward(reward_creature)
		return

	_refresh_run_build_readout()

	if _has_next_encounter():
		_show_continue_overlay_only()
	else:
		_finish_run(true)


func _finish_run(victory: bool) -> void:
	# Final state for the whole run.
	_run_finished = true
	_combat_finished = true
	_phase_transitioning = false

	_hide_boss_bar()

	if lane_manager != null and lane_manager.has_method("stop"):
		lane_manager.stop()

	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(false)

	if victory:
		result_label.text = "RUN COMPLETE"
		result_label.visible = true
		_show_feedback("THE HOLLOW REMEMBERS YOU", Color(0.85, 1.0, 0.75, 1.0), 0.70)
		controls_label.text = "Run complete  |  Press R to restart run"
	else:
		result_label.text = "RUN FAILED"
		result_label.visible = true
		_show_feedback("RUN FAILED", Color(1.0, 0.45, 0.45, 1.0), 0.65)
		controls_label.text = "Run failed  |  Press R to restart run"

	_hide_reward_overlay()


func _has_next_encounter() -> bool:
	return _current_encounter_queue_index < (_encounter_queue.size() - 1)


func _continue_to_next_encounter() -> void:
	if not _awaiting_continue:
		return

	_awaiting_continue = false
	_hide_reward_overlay()
	_current_encounter_queue_index += 1
	_load_current_queued_encounter(false)


func _show_boss_bar() -> void:
	if _boss_hp_shell != null:
		_boss_hp_shell.visible = true
	if _boss_name_label != null:
		_boss_name_label.visible = true
	if _boss_hp_bar != null:
		_boss_hp_bar.visible = true


func _hide_boss_bar() -> void:
	if _boss_hp_shell != null:
		_boss_hp_shell.visible = false
	if _boss_name_label != null:
		_boss_name_label.visible = false
	if _boss_hp_bar != null:
		_boss_hp_bar.visible = false


func _setup_boss_hp_bar() -> void:
	_boss_total_hp = 0.0
	var phases: Array = _active_encounter.get("phases", [])
	for phase in phases:
		for enemy in phase:
			_boss_total_hp += float(enemy.get("hp", 0))
	_boss_current_hp = _boss_total_hp

	if _boss_hp_bar != null:
		_boss_hp_bar.max_value = _boss_total_hp
		_boss_hp_bar.value = _boss_total_hp
	if _boss_name_label != null:
		_boss_name_label.text = String(_active_encounter.get("boss_name", ""))

	_show_boss_bar()


func _show_boss_intro(boss_name: String) -> void:
	EventBus.emit_signal("screen_flash", Color(0.62, 0.36, 0.06, 0.28), 0.30)

	_title_card.text = boss_name
	_title_card.modulate = Color(0.86, 0.62, 0.20, 1.0)
	_title_card.visible = true

	_subtitle_card.text = String(_active_encounter.get("boss_subtitle", "APEX OF THE HOLLOW"))
	_subtitle_card.modulate = Color(0.72, 0.52, 0.28, 0.92)
	_subtitle_card.visible = true

	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(_title_card, "modulate:a", 0.0, 0.42)
	tween.parallel().tween_property(_subtitle_card, "modulate:a", 0.0, 0.42)
	tween.tween_callback(func() -> void:
		_title_card.visible = false
		_subtitle_card.visible = false
		_title_card.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_subtitle_card.modulate = Color(0.85, 0.85, 0.85, 1.0)
	)

	await tween.finished


func _show_title_card(title_text: String, subtitle_text: String) -> void:
	_title_card.text = title_text
	_title_card.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_title_card.visible = true

	_subtitle_card.text = subtitle_text
	_subtitle_card.modulate = Color(0.85, 0.85, 0.85, 1.0)
	_subtitle_card.visible = true

	var tween := create_tween()
	tween.tween_interval(0.65)
	tween.tween_property(_title_card, "modulate:a", 0.0, 0.40)
	tween.parallel().tween_property(_subtitle_card, "modulate:a", 0.0, 0.40)
	tween.tween_callback(func() -> void:
		_title_card.visible = false
		_subtitle_card.visible = false
		_title_card.modulate.a = 1.0
		_subtitle_card.modulate.a = 1.0
	)


func _show_feedback(text: String, color: Color, lifetime: float = 0.38) -> void:
	_feedback_label.text = text
	_feedback_label.modulate = color
	_feedback_label.visible = true
	_feedback_label.scale = Vector2.ONE

	var tween := create_tween()
	tween.tween_property(_feedback_label, "scale", Vector2(1.10, 1.10), 0.07)
	tween.tween_interval(lifetime)
	tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.10)
	tween.tween_callback(func() -> void:
		_feedback_label.visible = false
		_feedback_label.modulate.a = 1.0
		_feedback_label.scale = Vector2.ONE
	)


func _flash_meter_shell(color: Color, duration: float) -> void:
	if _style_shell == null or _combo_shell == null:
		return

	var combo_base: Color = _combo_shell.color
	var style_base: Color = _style_shell.color
	var resource_base: Color = _resource_shell.color
	var tint: Color = color

	var tween := create_tween()
	tween.tween_property(_combo_shell, "color", combo_base.lerp(tint, 0.55), 0.05)
	tween.parallel().tween_property(_style_shell, "color", style_base.lerp(tint, 0.70), 0.05)
	tween.parallel().tween_property(_resource_shell, "color", resource_base.lerp(tint, 0.45), 0.05)
	tween.tween_interval(duration)
	tween.tween_property(_combo_shell, "color", combo_base, 0.12)
	tween.parallel().tween_property(_style_shell, "color", style_base, 0.12)
	tween.parallel().tween_property(_resource_shell, "color", resource_base, 0.12)


func _offer_victory_reward(creature_data: Dictionary) -> void:
	_pending_reward_creature = creature_data.duplicate(true)
	_awaiting_reward_choice = true
	_reward_choice_made = false
	_awaiting_continue = false

	EventBus.emit_signal("capture_offered", _pending_reward_creature)
	_reward_overlay.visible = true

	var _offer_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	var _offer_description: String = String(_pending_reward_creature.get("description", ""))
	_reward_creature_tag_label.text = "CREATURE OFFERING"
	_reward_title_label.text = _offer_creature_name
	_reward_body_label.text = _offer_description
	_reward_bond_label.text = "[B] BOND"
	_reward_bond_effect_label.text = "Keep it close.\n\n%s\n\nRun identity grows around this creature." % _format_bond_passive(_pending_reward_creature.get("bond_passive", {}))
	_reward_eat_label.text = "[E] EAT"
	_reward_eat_effect_label.text = "Take what it gives.\n\n%s\n\nPermanent pressure through consumption." % _format_eat_effect(_pending_reward_creature.get("eat_effect", {}))
	_reward_quig_label.text = String(_pending_reward_creature.get("quig_offer_text", ""))
	_reward_hint_label.text = "Choose one  |  B keeps the creature  |  E consumes it"

	controls_label.text = "Reward choice  |  Press B to Bond  |  Press E to Eat"


func _format_eat_effect(effect: Dictionary) -> String:
	match effect.get("type", ""):
		"damage_flat":
			return "+%.0f permanent attack damage" % float(effect.get("value", 0.0))
		"hp_restore":
			return "restores %.0f HP immediately — no permanent bonus" % float(effect.get("value", 0.0))
		_:
			return "absorb its essence"


func _format_bond_passive(passive: Dictionary) -> String:
	match passive.get("type", ""):
		"damage_on_ultimate":
			return "+%.0f damage added to your ultimate" % float(passive.get("value", 0.0))
		"damage_reduction_pct":
			return "%.0f%% damage reduction while bonded" % (float(passive.get("value", 0.0)) * 100.0)
		"hp_on_kill":
			return "+%.0f HP restored on every enemy kill" % float(passive.get("value", 0.0))
		"parry_reflect_mult":
			return "+%.0f%% parry reflect damage while bonded" % (float(passive.get("value", 0.0)) * 100.0)
		"timed_damage_flat":
			return "+%.0f flat damage added to every timed attack" % float(passive.get("value", 0.0))
		_:
			return "keep in roster"


func _format_bond_passive_short(passive: Dictionary) -> String:
	# Compact version for the in-combat BOND row of the run build shell.
	match passive.get("type", ""):
		"damage_on_ultimate":
			return "+%.0f ult dmg" % float(passive.get("value", 0.0))
		"damage_reduction_pct":
			return "%.0f%% def" % (float(passive.get("value", 0.0)) * 100.0)
		"hp_on_kill":
			return "+%.0f hp/kill" % float(passive.get("value", 0.0))
		"parry_reflect_mult":
			return "+%.0f%% parry" % (float(passive.get("value", 0.0)) * 100.0)
		"timed_damage_flat":
			return "+%.0f timed" % float(passive.get("value", 0.0))
		_:
			return "--"


func _format_trigger_hint(effect_id: String) -> String:
	# One-line description of when the bonded creature fires, shown under the support bar.
	match effect_id:
		"ashclaw_strike":
			return "strikes on perfect timing"
		"bond_remnant_mend":
			return "mends on hit when ready"
		"gruvek_gorge":
			return "gorges all lanes on kill"
		"veilskin_phase":
			return "phases on perfect parry"
		"thornback_rend":
			return "rends on perfect timing"
		_:
			return ""


func _show_continue_after_reward() -> void:
	_awaiting_continue = true

	_reward_creature_tag_label.text = "PATH"
	_reward_title_label.text = "The path opens."
	_reward_body_label.text = "Your choice settles into the hollow.\n\nContinue to the next encounter?"
	_reward_bond_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_hint_label.text = "Press C to continue  |  Press R to restart run"

	controls_label.text = "Press C to continue  |  Press R to restart run"


func _show_continue_overlay_only() -> void:
	_awaiting_continue = true
	_reward_choice_made = true
	_awaiting_reward_choice = false
	_pending_reward_creature = {}
	_reward_overlay.visible = true

	_reward_creature_tag_label.text = "DESCENT"
	_reward_title_label.text = "The hollow turns deeper."
	_reward_body_label.text = "The first mouth closes.\n\nAnother waits."
	_reward_bond_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_quig_label.text = "Quig: \"That wasn't the only one.\""
	_reward_hint_label.text = "Press C to continue  |  Press R to restart run"

	controls_label.text = "Press C to continue  |  Press R to restart run"


func _hide_reward_overlay() -> void:
	_reward_overlay.visible = false
	_pending_reward_creature = {}
	_awaiting_reward_choice = false
	_reward_choice_made = false
	_awaiting_continue = false
	_reward_creature_tag_label.text = ""
	_reward_title_label.text = ""
	_reward_body_label.text = ""
	_reward_bond_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_quig_label.text = ""
	_reward_hint_label.text = ""


func _refresh_run_build_readout() -> void:
	if _eaten_value_label != null:
		_eaten_value_label.text = _format_absorbed_bonus_summary()
	if _upgrade_value_label != null:
		_upgrade_value_label.text = _format_upgrade_summary()

	if _bond_value_label != null:
		var active: Dictionary = GameState.get_active_bonded_creature()
		_bond_value_label.text = _format_bond_passive_short(active.get("bond_passive", {})) if not active.is_empty() else "--"

	if _atk_value_label != null:
		_atk_value_label.text = "%.0f" % GameState.get_attack_damage()

	if _run_build_shell != null:
		var has_build: bool = not GameState.absorbed_types.is_empty() or not GameState.taken_upgrades.is_empty()
		_run_build_shell.color = Color(0.08, 0.08, 0.10, 0.60) if has_build else Color(0.07, 0.07, 0.09, 0.50)


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
			var creature: Dictionary = COMBAT_CONTENT.get_creature(species_id)
			creature_name = String(creature.get("display_name", species_id))

		var short_name: String = _compact_token(creature_name, 4)
		var eat_type: String = String(entry.get("eat_type", "damage_flat"))
		if eat_type == "hp_restore":
			var heal_applied: int = int(round(float(entry.get("heal_applied", 0.0))))
			chips.append("[%s~%d]" % [short_name, heal_applied])
		else:
			var damage_bonus: int = int(round(float(entry.get("damage_bonus", 0.0))))
			chips.append("[%s+%d]" % [short_name, damage_bonus])

	var hidden_count: int = GameState.absorbed_types.size() - visible_count
	if hidden_count > 0:
		chips.append("+%d" % hidden_count)

	return _join_compact_tokens(chips)


func _format_upgrade_summary() -> String:
	if GameState.taken_upgrades.is_empty():
		return "--"

	var titles_by_id: Dictionary = {}
	for upgrade in GROWTH_CONTENT.UPGRADE_POOL:
		titles_by_id[String(upgrade.get("id", ""))] = String(upgrade.get("title", ""))

	var chips: Array[String] = []
	var visible_count: int = min(3, GameState.taken_upgrades.size())
	for i in range(visible_count):
		var upgrade_id: String = String(GameState.taken_upgrades[i])
		var title: String = String(titles_by_id.get(upgrade_id, upgrade_id))
		chips.append("[%s]" % _compact_token(title, 8))

	var hidden_count: int = GameState.taken_upgrades.size() - visible_count
	if hidden_count > 0:
		chips.append("+%d" % hidden_count)

	return _join_compact_tokens(chips)


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


func _maybe_present_growth_offer() -> void:
	if _awaiting_growth_choice or _awaiting_reward_choice or _awaiting_continue or _run_finished:
		return
	if _run_growth == null or not is_instance_valid(_run_growth):
		return
	if not _run_growth.has_method("has_pending_level_up_offer"):
		return
	if not bool(_run_growth.call("has_pending_level_up_offer")):
		return

	var options: Array = _run_growth.call("consume_pending_level_up_offer")
	if options.is_empty():
		return

	_current_growth_options = options
	_awaiting_growth_choice = true
	_growth_overlay.visible = true
	_growth_title_label.text = "LEVEL %d  |  THE RUN MUTATES" % int(_run_growth.get("level"))
	_growth_hint_label.text = "Choose one  |  Press 1, 2, or 3"

	for i in range(_growth_option_labels.size()):
		var label: Label = _growth_option_labels[i]
		if i < options.size():
			var option: Dictionary = options[i]
			label.visible = true
			label.text = "[%d] %s\n%s\n\n%s" % [
				i + 1,
				String(option.get("title", "Unknown")),
				String(option.get("category", "")),
				String(option.get("summary", ""))
			]
		else:
			label.visible = false
			label.text = ""

	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(false)

	_enter_growth_pause()
	controls_label.text = "Level up  |  Press 1, 2, or 3"


func _choose_growth_option(index: int) -> void:
	if not _awaiting_growth_choice:
		return
	if index < 0 or index >= _current_growth_options.size():
		return
	if _run_growth == null or not is_instance_valid(_run_growth):
		return

	var chosen: Dictionary = _current_growth_options[index]
	var upgrade_id: String = String(chosen.get("id", ""))
	var resolved_choice: Dictionary = _run_growth.call("choose_upgrade", upgrade_id)
	if resolved_choice.is_empty():
		return

	_awaiting_growth_choice = false
	_current_growth_options.clear()
	_growth_overlay.visible = false
	_exit_growth_pause()

	if player_combat != null and player_combat.has_method("set_combat_enabled") and not _combat_finished:
		player_combat.set_combat_enabled(true)

	_set_combat_controls_text()
	_show_feedback(String(resolved_choice.get("title", "Mutation")), Color(0.86, 0.98, 0.76, 1.0), 0.40)


func _enter_growth_pause() -> void:
	_growth_pause_active = true
	# Invalidate any in-flight slow-motion restore callback before freezing.
	_slow_motion_gen += 1
	Engine.time_scale = 0.0


func _exit_growth_pause() -> void:
	_growth_pause_active = false
	Engine.time_scale = _base_time_scale


func _choose_bond() -> void:
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	var updated_creature: Dictionary = GameState.add_bonded_creature(_pending_reward_creature)
	EventBus.emit_signal("creature_bonded", updated_creature)

	_reward_choice_made = true
	_awaiting_reward_choice = false

	var _bond_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	_reward_creature_tag_label.text = "BOND SEALED"
	_reward_title_label.text = "%s bonded." % _bond_creature_name
	_reward_body_label.text = "%s enters your roster at bond level %d." % [
		_bond_creature_name,
		int(updated_creature.get("bond_level", 1))
	]
	_reward_bond_label.text = "BONDED"
	_reward_bond_effect_label.text = _format_bond_passive(_pending_reward_creature.get("bond_passive", {}))
	_reward_eat_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_quig_label.text = "Quig: \"Good. Watch — they're already positioning.\""

	if _has_next_encounter():
		_show_continue_after_reward()
	else:
		_reward_hint_label.text = "Press R to restart run"
		controls_label.text = "Run complete  |  Press R to restart run"
		_finish_run(true)


func _choose_eat() -> void:
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	var absorbed_entry: Dictionary = GameState.absorb_creature_type(_pending_reward_creature)
	if String(absorbed_entry.get("eat_type", "")) == "hp_restore":
		var healed: float = float(absorbed_entry.get("heal_applied", 0.0))
		if healed > 0.0:
			EventBus.emit_signal("player_healed", healed)
	EventBus.emit_signal("creature_eaten", _pending_reward_creature)

	_reward_choice_made = true
	_awaiting_reward_choice = false

	var _eat_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	_reward_creature_tag_label.text = "CONSUMED"
	_reward_title_label.text = "%s consumed." % _eat_creature_name
	_reward_body_label.text = "Its nature folds into you."
	_reward_bond_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_label.text = "ABSORBED"
	var _eat_type_str: String = String(absorbed_entry.get("eat_type", "damage_flat"))
	if _eat_type_str == "hp_restore":
		_reward_eat_effect_label.text = "Type: %s\n\n+%.0f HP restored.\nNo permanent bonus." % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("heal_applied", 0.0))
		]
	else:
		_reward_eat_effect_label.text = "Type: %s\n\n+%.1f permanent attack damage" % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("damage_bonus", 0.0))
		]
	_reward_quig_label.text = "Quig is silent."
	_reward_hint_label.text = "..."

	_refresh_run_build_readout()

	var timer: SceneTreeTimer = get_tree().create_timer(3.0)
	await timer.timeout

	if not _reward_choice_made:
		return

	_reward_quig_label.text = "Quig: \"There will be others.\""

	if _has_next_encounter():
		_show_continue_after_reward()
	else:
		_reward_hint_label.text = "Press R to restart run"
		controls_label.text = "Run complete  |  Press R to restart run"
		_finish_run(true)


func _on_combo_changed(count: int, _tier: String) -> void:
	combo_label.text = "%d" % count


func _on_style_changed(score: float, tier: String) -> void:
	style_label.text = tier.capitalize()


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


func _on_player_took_damage(_amount: float, source_lane: int) -> void:
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	if _hp_value_label != null:
		_hp_value_label.text = "%d/%d" % [int(GameState.player_hp), int(GameState.player_max_hp)]
	_show_feedback("STRUCK", Color(0.96, 0.44, 0.40, 1.0), 0.34)
	_highlight_timing_ring(source_lane, Color(1.0, 0.25, 0.25, 1.0), 5.0)
	_flash_meter_shell(Color(0.42, 0.10, 0.11, 0.94), 0.18)


func _on_player_healed(_amount: float) -> void:
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	if _hp_value_label != null:
		_hp_value_label.text = "%d/%d" % [int(GameState.player_hp), int(GameState.player_max_hp)]
	_show_feedback("MEND", Color(0.70, 0.96, 0.84, 1.0), 0.26)
	_flash_meter_shell(Color(0.11, 0.22, 0.17, 0.92), 0.10)


func _on_ultimate_available() -> void:
	ultimate_label.text = "READY"
	_show_feedback("READY", Color(1.0, 0.85, 0.35, 1.0), 0.45)
	_flash_meter_shell(Color(0.30, 0.21, 0.10, 0.94), 0.20)


func _on_ultimate_fired(_power: float) -> void:
	ultimate_label.text = "0%"
	_show_feedback("DEVOUR", Color(1.0, 0.72, 0.25, 1.0), 0.45)
	_flash_meter_shell(Color(0.33, 0.16, 0.08, 0.94), 0.18)


func _on_combat_ended(victory: bool) -> void:
	if _combat_finished:
		return

	if not victory:
		_finish_run(false)
		return

	if _phase_transitioning:
		return

	_advance_phase()


func _on_enemy_damaged(enemy_id: int, damage: float) -> void:
	# Apply persistent low-HP tint before the damage flash so the flash restores to it.
	var lane: int = int(_all_enemies_by_id.get(enemy_id, {}).get("lane", -1))
	if lane >= 0:
		var max_hp: float = float(_enemy_max_hp.get(enemy_id, 0))
		if max_hp > 0.0:
			var current_hp: float = float(lane_manager.get_enemy(lane).get("hp", 0))
			if current_hp / max_hp <= ENEMY_LOW_HP_THRESHOLD:
				var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
				if marker != null and is_instance_valid(marker):
					marker.modulate = Color(0.90, 0.28, 0.28, 1.0)

	# Decrement unified boss HP bar.
	if _is_boss_encounter and _boss_hp_bar != null and is_instance_valid(_boss_hp_bar):
		_boss_current_hp = max(_boss_current_hp - damage, 0.0)
		_boss_hp_bar.value = _boss_current_hp

	_spawn_damage_number(enemy_id, damage)
	_animate_enemy_damage(enemy_id)


func _spawn_damage_number(enemy_id: int, damage: float) -> void:
	var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
		return
	var start_pos: Vector2 = marker.position + Vector2(6.0, -18.0)
	var lbl := Label.new()
	lbl.text = "%.0f" % damage
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78, 1.0))
	lbl.position = start_pos
	lbl.z_index = 10
	_enemy_marker_container.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position:y", start_pos.y - 30.0, 0.6)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(lbl.queue_free)


func _on_enemy_defeated(enemy_id: int) -> void:
	var kill_heal_effect: Dictionary = _get_upgrade_effect("heal_on_kill")
	if not kill_heal_effect.is_empty():
		var healed: float = GameState.heal_player(float(kill_heal_effect.get("value", 0.0)))
		if healed > 0.0:
			EventBus.emit_signal("player_healed", healed)
	_remove_enemy_marker(enemy_id)


func _on_screen_flash(color: Color, duration: float) -> void:
	flash_overlay.color = color
	var tween := create_tween()
	tween.tween_property(flash_overlay, "color:a", color.a, 0.03)
	tween.tween_interval(duration)
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.12)


func _on_screen_shake(intensity: float, duration: float) -> void:
	var original_offset: Vector2 = camera_2d.offset
	var half_duration: float = duration * 0.5

	var tween := create_tween()
	tween.tween_property(camera_2d, "offset", original_offset + Vector2(intensity, 0.0), half_duration)
	tween.tween_property(camera_2d, "offset", original_offset - Vector2(intensity, 0.0), half_duration)
	tween.tween_callback(func() -> void:
		camera_2d.offset = original_offset
	)


func _on_slow_motion(scale: float, duration: float) -> void:
	if _growth_pause_active:
		return

	_slow_motion_gen += 1
	var gen: int = _slow_motion_gen
	Engine.time_scale = scale
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		if _growth_pause_active:
			return
		if _slow_motion_gen == gen:
			Engine.time_scale = _base_time_scale
	)


func _on_player_attacked(lane: int, _damage: float, was_timed: bool) -> void:
	if was_timed:
		_show_feedback("TIMED", Color(1.0, 0.95, 0.55, 1.0), 0.36)
		_highlight_timing_ring(lane, Color(1.0, 0.95, 0.55, 1.0), 5.0)
		_spawn_attack_silhouette_to_lane(lane, Color(1.0, 0.92, 0.58, 0.55), 10.0, 0.12, 1.0)
		_flash_meter_shell(Color(0.25, 0.20, 0.10, 0.94), 0.12)
	else:
		_show_feedback("HIT", Color(0.95, 0.95, 0.95, 1.0), 0.28)
		_highlight_timing_ring(lane, Color(0.95, 0.95, 0.95, 1.0), 4.0)
		_spawn_attack_silhouette_to_lane(lane, Color(0.92, 0.92, 0.92, 0.35), 7.0, 0.10, 0.88)
		_flash_meter_shell(Color(0.16, 0.16, 0.17, 0.94), 0.08)


func _on_timed_attack_resolved(lane: int, _quality: String, damage: float) -> void:
	var ravage_effect: Dictionary = _get_upgrade_effect("timed_attack_bonus_damage")
	if ravage_effect.is_empty():
		return

	var rip_damage: float = damage * float(ravage_effect.get("value", 0.0))
	lane_manager.damage_enemy(lane, rip_damage)
	_spawn_attack_silhouette_to_lane(lane, Color(0.95, 0.48, 0.36, 0.34), 8.0, 0.08, 0.92)


func _on_player_parried(lane: int, quality: String, _reflect_damage: float) -> void:
	if quality == "perfect":
		_show_feedback("PERFECT PARRY", Color(0.68, 1.0, 0.82, 1.0), 0.46)
		_highlight_timing_ring(lane, Color(0.68, 1.0, 0.82, 1.0), 7.0)
		_spawn_attack_silhouette_to_lane(lane, Color(0.68, 1.0, 0.82, 0.72), 13.0, 0.18, 1.08)
		_flash_meter_shell(Color(0.12, 0.28, 0.20, 0.96), 0.20)
	else:
		_show_feedback("PARRY", Color(0.60, 0.94, 0.76, 1.0), 0.34)
		_highlight_timing_ring(lane, Color(0.60, 0.94, 0.76, 1.0), 5.6)
		_spawn_attack_silhouette_to_lane(lane, Color(0.60, 0.94, 0.76, 0.54), 10.0, 0.14, 0.98)
		_flash_meter_shell(Color(0.11, 0.22, 0.18, 0.94), 0.14)


func _on_player_dodged(_from_lane: int, to_lane: int) -> void:
	_show_feedback("DODGE", Color(0.65, 0.85, 1.0, 1.0), 0.28)
	_highlight_timing_ring(to_lane, Color(0.65, 0.85, 1.0, 1.0), 4.0)


func _on_player_no_stamina() -> void:
	_show_feedback("NO STAMINA", Color(1.0, 0.45, 0.45, 1.0), 0.42)
	_flash_meter_shell(Color(0.28, 0.11, 0.11, 0.92), 0.12)


func _on_combo_broken(_lost: int) -> void:
	_show_feedback("BROKEN", Color(1.0, 0.4, 0.4, 1.0), 0.40)


func _on_run_growth_changed(level: int, exp: float, exp_to_next: float) -> void:
	if _exp_value_label != null:
		_exp_value_label.text = "L%d  %.0f/%.0f" % [level, exp, exp_to_next]


func _on_support_charge_changed(current: float, maximum: float, active_species_id: String) -> void:
	if _support_bar != null:
		_support_bar.max_value = maximum
		_support_bar.value = current

	if _support_value_label != null:
		if active_species_id.is_empty():
			_support_value_label.text = "--"
		elif current >= maximum:
			_support_value_label.text = "READY"
		else:
			_support_value_label.text = "%d%%" % int(round((current / maximum) * 100.0))

	if _support_name_label != null:
		if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_active_display_name"):
			var display_name: String = String(_run_growth.call("get_active_display_name"))
			_support_name_label.text = display_name.to_upper()
		else:
			_support_name_label.text = "NO BOND"

	if _support_trigger_label != null:
		if active_species_id.is_empty():
			_support_trigger_label.text = ""
		else:
			var support_role: Dictionary = COMBAT_CONTENT.get_support_role(active_species_id)
			_support_trigger_label.text = _format_trigger_hint(String(support_role.get("effect_id", "")))

	if _support_shell != null:
		var shell_color: Color = Color(0.08, 0.08, 0.10, 0.56)
		if not active_species_id.is_empty() and current >= maximum:
			shell_color = Color(0.10, 0.12, 0.11, 0.72)
		_support_shell.color = shell_color
	_refresh_run_build_readout()


func _on_bonded_support_triggered(_species_id: String, lane: int, effect_id: String) -> void:
	var support_role: Dictionary = _get_support_role_for_effect(effect_id)
	var combo_mult: float = combat_meter.damage_multiplier()
	match effect_id:
		"ashclaw_strike":
			var strike_damage: float = float(support_role.get("effect_value", 10.0)) * combo_mult
			lane_manager.damage_enemy(lane, strike_damage)
			_show_feedback(String(support_role.get("feedback_text", "ASHCLAW")), Color(0.95, 0.60, 0.42, 1.0), 0.28)
			_highlight_timing_ring(lane, Color(0.92, 0.56, 0.38, 1.0), 5.4)
			_spawn_attack_silhouette_to_lane(lane, Color(0.95, 0.60, 0.42, 0.52), 9.0, 0.12, 1.02)
			_flash_meter_shell(Color(0.25, 0.12, 0.10, 0.92), 0.10)
		"bond_remnant_mend":
			var healed: float = GameState.heal_player(float(support_role.get("effect_value", 6.0)))
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			_show_feedback(String(support_role.get("feedback_text", "REMNANT")), Color(0.72, 0.96, 0.88, 1.0), 0.28)
			_highlight_timing_ring(lane, Color(0.68, 0.94, 0.84, 1.0), 4.8)
			_flash_meter_shell(Color(0.12, 0.22, 0.18, 0.92), 0.10)
		"gruvek_gorge":
			var gorge_damage: float = float(support_role.get("effect_value", 10.0)) * combo_mult
			for check_lane in range(3):
				lane_manager.damage_enemy(check_lane, gorge_damage)
			_show_feedback(String(support_role.get("feedback_text", "GORGE")), Color(0.90, 0.52, 0.22, 1.0), 0.30)
			for check_lane in range(3):
				_highlight_timing_ring(check_lane, Color(0.88, 0.50, 0.20, 1.0), 5.0)
			_flash_meter_shell(Color(0.28, 0.14, 0.08, 0.92), 0.12)
		"veilskin_phase":
			var phase_damage: float = float(support_role.get("effect_value", 12.0))
			lane_manager.damage_enemy(lane, phase_damage)
			combat_meter.restore_stamina(25.0)
			_show_feedback(String(support_role.get("feedback_text", "PHASE")), Color(0.78, 0.92, 1.0, 1.0), 0.28)
			_highlight_timing_ring(lane, Color(0.72, 0.88, 1.0, 1.0), 4.8)
			_flash_meter_shell(Color(0.10, 0.18, 0.26, 0.92), 0.10)
		"thornback_rend":
			var rend_damage: float = float(support_role.get("effect_value", 20.0)) * combo_mult
			lane_manager.damage_enemy(lane, rend_damage)
			_show_feedback(String(support_role.get("feedback_text", "REND")), Color(0.96, 0.75, 0.38, 1.0), 0.28)
			_highlight_timing_ring(lane, Color(0.94, 0.72, 0.34, 1.0), 6.0)
			_spawn_attack_silhouette_to_lane(lane, Color(0.96, 0.75, 0.38, 0.60), 12.0, 0.14, 1.10)
			_flash_meter_shell(Color(0.28, 0.16, 0.08, 0.92), 0.10)
		_:
			return


func _on_run_upgrade_taken(upgrade_id: String) -> void:
	match upgrade_id:
		"flesh_ravage":
			_flash_meter_shell(Color(0.28, 0.13, 0.10, 0.92), 0.10)
		"flesh_devour_warmth":
			_flash_meter_shell(Color(0.29, 0.16, 0.10, 0.92), 0.10)
		"bond_surestep_pact":
			_flash_meter_shell(Color(0.12, 0.22, 0.18, 0.92), 0.10)
		"bond_shared_surge":
			_flash_meter_shell(Color(0.13, 0.24, 0.19, 0.92), 0.10)
		"cadence_knife_between_beats":
			_flash_meter_shell(Color(0.24, 0.22, 0.10, 0.92), 0.10)
		"survival_hollow_shelter":
			_flash_meter_shell(Color(0.12, 0.20, 0.18, 0.92), 0.10)
		_:
			pass
	_refresh_run_build_readout()



func _get_upgrade_effect(effect_type: String) -> Dictionary:
	for upgrade in GROWTH_CONTENT.UPGRADE_POOL:
		var upgrade_id: String = String(upgrade.get("id", ""))
		if not GameState.has_upgrade(upgrade_id):
			continue

		var effect: Dictionary = upgrade.get("effect", {})
		if String(effect.get("type", "")) == effect_type:
			return effect

	return {}


func _get_support_role_for_effect(effect_id: String) -> Dictionary:
	var species_id: String = ""
	if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_active_species_id"):
		species_id = String(_run_growth.call("get_active_species_id"))
	if species_id.is_empty():
		return {}

	var support_role: Dictionary = COMBAT_CONTENT.get_support_role(species_id)
	if String(support_role.get("effect_id", "")) != effect_id:
		return {}

	return support_role


func _on_player_teleported(_from_lane: int, _to_lane: int) -> void:
	_draw_timing_circles()


func _on_timing_ring_pressed(lane: int) -> void:
	_animate_timing_ring_press(lane)
	_spawn_attack_silhouette_to_lane(lane, Color(1.0, 1.0, 1.0, 0.18), 5.0, 0.08, 0.72)


func _highlight_timing_ring(lane: int, color: Color, width: float = 4.0) -> void:
	var group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_%d" % lane)
	if group == null:
		return

	_ring_highlight_timers[lane] = 0.20

	for child in group.get_children():
		if child is Line2D:
			var ring := child as Line2D
			if ring.name == "BeatMark":
				continue
			ring.default_color = color
			ring.width = width if ring.name == "Good" else max(width - 1.0, 1.5)


func _animate_timing_ring_press(lane: int) -> void:
	var group: Node2D = _timing_circle_container.get_node_or_null("TimingRing_%d" % lane)
	if group == null:
		return

	var original_position: Vector2 = group.position
	var original_scale: Vector2 = group.scale

	group.scale = Vector2(0.92, 0.92)
	group.position += Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))

	var tween := create_tween()
	tween.tween_property(group, "scale", original_scale, 0.06)
	tween.parallel().tween_property(group, "position", original_position, 0.06)


func _spawn_attack_silhouette_to_lane(
	lane: int,
	color: Color,
	thickness: float,
	lifetime: float,
	reach_scale: float
) -> void:
	if player_combat == null:
		return

	var start_point: Vector2 = player_combat.position + Vector2(10.0, -6.0)
	var end_point: Vector2 = Vector2(
		lane_manager.get_hit_zone_x() + 8.0,
		lane_manager.get_lane_y(lane)
	)

	var delta: Vector2 = (end_point - start_point) * reach_scale
	var length: float = max(delta.length(), 10.0)
	var angle: float = delta.angle()

	var slash := Polygon2D.new()
	slash.color = color
	slash.position = start_point
	slash.rotation = angle
	slash.scale = Vector2(0.18, 1.0)
	slash.polygon = PackedVector2Array([
		Vector2(0.0, -thickness * 0.5),
		Vector2(length, -thickness * 0.5),
		Vector2(length, thickness * 0.5),
		Vector2(0.0, thickness * 0.5)
	])

	_attack_fx_container.add_child(slash)

	var tween := create_tween()
	tween.tween_property(slash, "scale:x", 1.0, 0.04)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, lifetime)
	tween.tween_callback(func() -> void:
		if is_instance_valid(slash):
			slash.queue_free()
	)


func _animate_enemy_damage(enemy_id: int) -> void:
	var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
		return

	var original_position: Vector2 = marker.position
	var original_scale: Vector2 = marker.scale
	var original_modulate: Color = marker.modulate

	marker.modulate = Color(1.0, 0.85, 0.85, 1.0)

	var tween := create_tween()
	tween.tween_property(marker, "position", original_position + Vector2(-6.0, 0.0), 0.03)
	tween.parallel().tween_property(marker, "scale", Vector2(1.12, 0.88), 0.03)
	tween.tween_property(marker, "position", original_position + Vector2(4.0, 0.0), 0.04)
	tween.parallel().tween_property(marker, "scale", Vector2(0.94, 1.06), 0.04)
	tween.tween_property(marker, "position", original_position, 0.05)
	tween.parallel().tween_property(marker, "scale", original_scale, 0.05)
	tween.parallel().tween_property(marker, "modulate", original_modulate, 0.10)


func _remove_enemy_marker(enemy_id: int) -> void:
	if not _enemy_markers_by_id.has(enemy_id):
		return

	var marker: ColorRect = _enemy_markers_by_id[enemy_id]
	if marker == null or not is_instance_valid(marker):
		_enemy_markers_by_id.erase(enemy_id)
		return

	var tween := create_tween()
	tween.tween_property(marker, "modulate:a", 0.0, 0.14)
	tween.parallel().tween_property(marker, "scale", Vector2(0.6, 0.6), 0.12)
	tween.tween_callback(func() -> void:
		if is_instance_valid(marker):
			marker.queue_free()
	)

	_enemy_markers_by_id.erase(enemy_id)
