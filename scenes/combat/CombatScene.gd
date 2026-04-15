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

const BIOME_FEEDING_HOLLOW := {
	"name": "The Feeding Hollow",
	"subtitle": "The place remembers every mouth.",
	"background_color": Color(0.10, 0.05, 0.06, 1.0),
	"lane_color": Color(0.34, 0.24, 0.26, 1.0),
	"enemy_active_color": Color(0.76, 0.21, 0.21, 1.0),
	"enemy_inactive_color": Color(0.38, 0.18, 0.18, 0.55),
	"ring_active_color": Color(0.98, 0.93, 0.68, 1.0),
	"ring_inactive_color": Color(0.58, 0.52, 0.44, 0.45),
	"victory_text": "THE HOLLOW YIELDS",
	"defeat_text": "YOU FED THE HOLLOW"
}

const CREATURE_ASHCLAW := {
	"species_id": "ashclaw",
	"display_name": "Ashclaw",
	"primary_type": "predator",
	"secondary_type": "grit",
	"archetypes": ["guardian", "berserker"],
	"capture_threshold": 0.30,
	"bond_level": 1,
	"description": "Something that learned to cut before it learned to stop.",
	"eat_effect": {"type": "damage_flat", "value": 2.0},
	"bond_passive": {"type": "damage_on_ultimate", "value": 5.0},
	"quig_offer_text": "Quig watches the claws, not you.",
	"wrong_detail": "claws worn completely flat but still cutting"
}

const CREATURE_BOND_REMNANT := {
	"species_id": "bond_remnant",
	"display_name": "Bond Remnant",
	"primary_type": "bond",
	"secondary_type": "hollow",
	"archetypes": ["phantom", "anchor"],
	"capture_threshold": 0.25,
	"bond_level": 1,
	"description": "It holds the shape of something that survived its own end.",
	"eat_effect": {"type": "damage_flat", "value": 1.0},
	"bond_passive": {"type": "damage_reduction_pct", "value": 0.08},
	"quig_offer_text": "Quig does not look at it directly.",
	"wrong_detail": "teeth set in a jaw that never learned to close"
}

const ENCOUNTER_FEEDING_HOLLOW_01 := {
	"id": "feeding_hollow_01",
	"title": "First Hunger",
	"biome": BIOME_FEEDING_HOLLOW,
	"reward_creature": CREATURE_ASHCLAW,
	"phase_intro_texts": [
		"Something stirs above.",
		"It learns your rhythm.",
		"The hunger reveals itself."
	],
	"phases": [
		[
			{"id": 0, "type": "dreg", "hp": 28.0, "damage": 7.0, "lane": 0}
		],
		[
			{"id": 1, "type": "dreg", "hp": 32.0, "damage": 8.0, "lane": 1}
		],
		[
			{"id": 2, "type": "bond_reaper", "hp": 58.0, "damage": 13.0, "lane": 2}
		]
	]
}

const ENCOUNTER_FEEDING_HOLLOW_02 := {
	"id": "feeding_hollow_02",
	"title": "Second Mouth",
	"biome": BIOME_FEEDING_HOLLOW,
	"reward_creature": CREATURE_BOND_REMNANT,
	"phase_intro_texts": [
		"It no longer waits for you.",
		"The flanks open.",
		"The hollow chooses a mouth."
	],
	"phases": [
		[
			{"id": 10, "type": "dreg", "hp": 32.0, "damage": 8.0, "lane": 1}
		],
		[
			{"id": 11, "type": "dreg", "hp": 24.0, "damage": 7.0, "lane": 0},
			{"id": 12, "type": "dreg", "hp": 24.0, "damage": 7.0, "lane": 2}
		],
		[
			{"id": 13, "type": "bond_reaper", "hp": 64.0, "damage": 15.0, "lane": 1}
		]
	]
}

const RING_OUTER_RADIUS: float = 30.0
const RING_GOOD_RADIUS: float = 24.0
const RING_PERFECT_RADIUS: float = 15.0
const RING_POINT_COUNT: int = 32

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

# Reward / inter-encounter overlay.
var _reward_overlay: ColorRect = null
var _reward_panel: ColorRect = null
var _reward_title_label: Label = null
var _reward_body_label: Label = null
var _reward_quig_label: Label = null
var _reward_hint_label: Label = null

var _combat_finished: bool = false
var _phase_transitioning: bool = false
var _last_combat_victory: bool = false

var _awaiting_reward_choice: bool = false
var _reward_choice_made: bool = false
var _awaiting_continue: bool = false
var _run_finished: bool = false
var _run_victory: bool = false
var _pending_reward_creature: Dictionary = {}

var _active_encounter: Dictionary = {}
var _current_phase_index: int = 0
var _encounter_queue: Array = []
var _current_encounter_queue_index: int = 0

# enemy_id -> ColorRect
var _enemy_markers_by_id: Dictionary = {}
# enemy_id -> enemy data
var _all_enemies_by_id: Dictionary = {}
# enemy_id -> phase index
var _enemy_phase_by_id: Dictionary = {}


func _ready() -> void:
	_setup_visuals()
	_setup_ui()
	_create_feedback_label()
	_create_title_cards()
	_create_timing_circle_container()
	_create_attack_fx_container()
	_create_reward_overlay()
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
		if outer_ring == null or good_ring == null or perfect_ring == null:
			continue

		var base_color: Color = active_color if lane == player_combat.current_lane else inactive_color

		var outer_color: Color = base_color.darkened(0.05)
		var good_color: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.18)
		var perfect_color: Color = base_color.lightened(0.15)
		var outer_width: float = 2.2
		var good_width: float = 1.0
		var perfect_width: float = 2.2

		var proj = lane_manager.get_projectile(lane)
		if proj != null and not proj.is_resolved and not proj.is_reflected:
			var p: float = proj.progress

			if p >= approach_start and p < outer_entry:
				# Projectile is approaching — fade the outer ring in gradually.
				var t: float = (p - approach_start) / (outer_entry - approach_start)
				outer_color = outer_color.lerp(active_color, t)

			elif p >= outer_entry and p <= outer_exit:
				# Projectile is inside the outer ring — full outer glow.
				outer_color = active_color.lightened(0.10)
				good_color = Color(active_color.r, active_color.g, active_color.b, 0.16)

				if p >= perfect_entry and p <= perfect_exit:
					# Projectile is inside the perfect ring — brighten inner rings.
					good_color = Color(active_color.r, active_color.g, active_color.b, 0.22)
					perfect_color = active_color.lightened(0.45)
					perfect_width = 3.2

		outer_ring.default_color = outer_color
		outer_ring.width = outer_width
		good_ring.default_color = good_color
		good_ring.width = good_width
		perfect_ring.default_color = perfect_color
		perfect_ring.width = perfect_width


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
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

	flash_overlay.anchor_right = 1.0
	flash_overlay.anchor_bottom = 1.0
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_overlay.z_index = 100
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_ui() -> void:
	combo_label.text = "Combo: 0"
	style_label.text = "Style: Stirring"
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	hp_bar.min_value = 0.0
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	ultimate_label.text = "Ultimate: 0%"
	result_label.visible = false
	result_label.text = ""
	controls_label.text = "A/S/D lane  |  Left+Lane parry  |  Right+Lane dodge  |  R ultimate"


func _create_feedback_label() -> void:
	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.visible = false
	_feedback_label.z_index = 90
	_feedback_label.position = Vector2(520.0, 72.0)
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
	_reward_overlay.color = Color(0.02, 0.02, 0.03, 0.78)
	_reward_overlay.anchor_right = 1.0
	_reward_overlay.anchor_bottom = 1.0
	_reward_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_reward_overlay)

	_reward_panel = ColorRect.new()
	_reward_panel.name = "RewardPanel"
	_reward_panel.color = Color(0.12, 0.08, 0.09, 0.96)
	_reward_panel.position = Vector2(250.0, 120.0)
	_reward_panel.size = Vector2(780.0, 360.0)
	_reward_overlay.add_child(_reward_panel)

	_reward_title_label = Label.new()
	_reward_title_label.name = "RewardTitle"
	_reward_title_label.position = Vector2(36.0, 26.0)
	_reward_panel.add_child(_reward_title_label)

	_reward_body_label = Label.new()
	_reward_body_label.name = "RewardBody"
	_reward_body_label.position = Vector2(36.0, 72.0)
	_reward_panel.add_child(_reward_body_label)

	_reward_quig_label = Label.new()
	_reward_quig_label.name = "RewardQuig"
	_reward_quig_label.position = Vector2(36.0, 190.0)
	_reward_panel.add_child(_reward_quig_label)

	_reward_hint_label = Label.new()
	_reward_hint_label.name = "RewardHint"
	_reward_hint_label.position = Vector2(36.0, 300.0)
	_reward_panel.add_child(_reward_hint_label)


func _connect_eventbus() -> void:
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.style_changed.connect(_on_style_changed)
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.player_took_damage.connect(_on_player_took_damage)
	EventBus.ultimate_available.connect(_on_ultimate_available)
	EventBus.ultimate_fired.connect(_on_ultimate_fired)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.screen_flash.connect(_on_screen_flash)
	EventBus.screen_shake.connect(_on_screen_shake)
	EventBus.slow_motion.connect(_on_slow_motion)
	EventBus.player_attacked.connect(_on_player_attacked)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.player_dodged.connect(_on_player_dodged)
	EventBus.player_no_stamina.connect(_on_player_no_stamina)
	EventBus.combo_broken.connect(_on_combo_broken)
	EventBus.player_teleported.connect(_on_player_teleported)
	EventBus.timing_ring_pressed.connect(_on_timing_ring_pressed)


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
	return [
		ENCOUNTER_FEEDING_HOLLOW_01.duplicate(true),
		ENCOUNTER_FEEDING_HOLLOW_02.duplicate(true)
	]


func _start_mini_run() -> void:
	# Starts a fresh 2-encounter prototype run.
	_encounter_queue = _build_mini_run_queue()
	_current_encounter_queue_index = 0
	_run_finished = false
	_run_victory = false
	_last_combat_victory = false

	_hide_reward_overlay()

	if GameState.has_method("reset_run_state"):
		GameState.reset_run_state()

	EventBus.emit_signal("run_started", int(GameState.run_number))
	_load_current_queued_encounter(true)


func _load_current_queued_encounter(reset_hp: bool) -> void:
	if _current_encounter_queue_index < 0 or _current_encounter_queue_index >= _encounter_queue.size():
		_finish_run(true)
		return

	_active_encounter = _encounter_queue[_current_encounter_queue_index]
	_current_phase_index = 0
	_combat_finished = false
	_phase_transitioning = false
	_last_combat_victory = false

	_rebuild_enemy_lookup_tables()
	_apply_encounter_presentation()
	_build_arena_visuals()
	_draw_timing_circles()
	_prepare_for_encounter(reset_hp)
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
		var lane_line := Line2D.new()
		lane_line.default_color = lane_color
		lane_line.width = 2.0
		lane_line.add_point(Vector2(120.0, lane_manager.get_lane_y(lane)))
		lane_line.add_point(Vector2(get_viewport_rect().size.x - 120.0, lane_manager.get_lane_y(lane)))
		_lane_marker_container.add_child(lane_line)

	for enemy_id in _all_enemies_by_id.keys():
		var enemy: Dictionary = _all_enemies_by_id[enemy_id]
		var lane: int = int(enemy.get("lane", 0))

		var enemy_marker := ColorRect.new()
		enemy_marker.name = "Enemy_%d" % enemy_id
		enemy_marker.size = Vector2(42.0, 42.0)
		enemy_marker.position = Vector2(
			lane_manager.get_enemy_x() - 21.0,
			lane_manager.get_lane_y(lane) - 21.0
		)
		enemy_marker.color = inactive_enemy_color
		enemy_marker.modulate = Color(1.0, 1.0, 1.0, 1.0)

		_enemy_marker_container.add_child(enemy_marker)
		_enemy_markers_by_id[enemy_id] = enemy_marker

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

		var outer_ring := _make_ring_line(RING_OUTER_RADIUS, base_color.darkened(0.05), 2.2)
		outer_ring.name = "Outer"

		var good_ring := _make_ring_line(
			RING_GOOD_RADIUS,
			Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.18),
			1.0
		)
		good_ring.name = "Good"

		var perfect_ring := _make_ring_line(RING_PERFECT_RADIUS, base_color.lightened(0.15), 2.2)
		perfect_ring.name = "Perfect"

		# Vertical beat mark at the circle center — the projectile crosses this line
		# at progress = 1.0, which is the center of the perfect parry window.
		var beat_mark := Line2D.new()
		beat_mark.name = "BeatMark"
		beat_mark.default_color = base_color.darkened(0.10)
		beat_mark.width = 1.5
		beat_mark.add_point(Vector2(0.0, -RING_OUTER_RADIUS))
		beat_mark.add_point(Vector2(0.0, RING_OUTER_RADIUS))

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

	var timer: SceneTreeTimer = get_tree().create_timer(0.45)
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
	_last_combat_victory = true

	if lane_manager != null and lane_manager.has_method("stop"):
		lane_manager.stop()

	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(false)

	var biome: Dictionary = _active_encounter.get("biome", {})
	result_label.text = String(biome.get("victory_text", "VICTORY"))
	result_label.visible = true

	_show_feedback("ENCOUNTER CLEAR", Color(0.85, 1.0, 0.75, 1.0), 0.55)
	EventBus.emit_signal("screen_flash", Color(0.55, 1.0, 0.75, 0.10), 0.14)

	var reward_creature: Dictionary = _active_encounter.get("reward_creature", {})
	if not reward_creature.is_empty():
		_offer_victory_reward(reward_creature)
		return

	if _has_next_encounter():
		_show_continue_overlay_only()
	else:
		_finish_run(true)


func _finish_run(victory: bool) -> void:
	# Final state for the whole 2-encounter mini-run.
	_run_finished = true
	_run_victory = victory
	_combat_finished = true
	_phase_transitioning = false
	_last_combat_victory = victory

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


func _offer_victory_reward(creature_data: Dictionary) -> void:
	_pending_reward_creature = creature_data.duplicate(true)
	_awaiting_reward_choice = true
	_reward_choice_made = false
	_awaiting_continue = false

	EventBus.emit_signal("capture_offered", _pending_reward_creature)
	_reward_overlay.visible = true

	var _offer_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	var _offer_description: String = String(_pending_reward_creature.get("description", ""))
	_reward_title_label.text = "%s waits." % _offer_creature_name
	_reward_body_label.text = "%s\n\n[B] Bond  — %s\n[E] Eat   — %s" % [
		_offer_description,
		_format_bond_passive(_pending_reward_creature.get("bond_passive", {})),
		_format_eat_effect(_pending_reward_creature.get("eat_effect", {}))
	]
	_reward_quig_label.text = String(_pending_reward_creature.get("quig_offer_text", ""))
	_reward_hint_label.text = "Choose: B or E"

	controls_label.text = "Reward choice  |  Press B to Bond  |  Press E to Eat"


func _format_eat_effect(effect: Dictionary) -> String:
	match effect.get("type", ""):
		"damage_flat":
			return "+%.0f permanent attack damage" % float(effect.get("value", 0.0))
		_:
			return "absorb its essence"


func _format_bond_passive(passive: Dictionary) -> String:
	match passive.get("type", ""):
		"damage_on_ultimate":
			return "+%.0f damage added to your ultimate" % float(passive.get("value", 0.0))
		"damage_reduction_pct":
			return "%.0f%% damage reduction while bonded" % (float(passive.get("value", 0.0)) * 100.0)
		_:
			return "keep in roster"


func _show_continue_after_reward() -> void:
	_awaiting_continue = true

	_reward_title_label.text = "The path opens."
	_reward_body_label.text = "Your choice settles into the hollow.\n\nContinue to the next encounter?"
	_reward_hint_label.text = "Press C to continue  |  Press R to restart run"

	controls_label.text = "Press C to continue  |  Press R to restart run"


func _show_continue_overlay_only() -> void:
	_awaiting_continue = true
	_reward_choice_made = true
	_awaiting_reward_choice = false
	_pending_reward_creature = {}
	_reward_overlay.visible = true

	_reward_title_label.text = "The hollow turns deeper."
	_reward_body_label.text = "The first mouth closes.\n\nAnother waits."
	_reward_quig_label.text = "Quig: \"That wasn't the only one.\""
	_reward_hint_label.text = "Press C to continue  |  Press R to restart run"

	controls_label.text = "Press C to continue  |  Press R to restart run"


func _hide_reward_overlay() -> void:
	_reward_overlay.visible = false
	_pending_reward_creature = {}
	_awaiting_reward_choice = false
	_reward_choice_made = false
	_awaiting_continue = false
	_reward_title_label.text = ""
	_reward_body_label.text = ""
	_reward_quig_label.text = ""
	_reward_hint_label.text = ""


func _choose_bond() -> void:
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	var updated_creature: Dictionary = GameState.add_bonded_creature(_pending_reward_creature)
	EventBus.emit_signal("creature_bonded", updated_creature)

	_reward_choice_made = true
	_awaiting_reward_choice = false

	var _bond_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	_reward_title_label.text = "%s bonded." % _bond_creature_name
	_reward_body_label.text = "%s enters your roster at bond level %d.\n%s" % [
		_bond_creature_name,
		int(updated_creature.get("bond_level", 1)),
		_format_bond_passive(_pending_reward_creature.get("bond_passive", {}))
	]
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
	EventBus.emit_signal("creature_eaten", _pending_reward_creature)

	_reward_choice_made = true
	_awaiting_reward_choice = false

	var _eat_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	_reward_title_label.text = "%s consumed." % _eat_creature_name
	_reward_body_label.text = "Absorbed type: %s  (+%.1f damage)" % [
		String(absorbed_entry.get("type", "unknown")).capitalize(),
		float(absorbed_entry.get("damage_bonus", 0.0))
	]
	_reward_quig_label.text = "Quig is silent."
	_reward_hint_label.text = "..."

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
	combo_label.text = "Combo: %d" % count


func _on_style_changed(score: float, tier: String) -> void:
	style_label.text = "Style: %s (%.0f)" % [tier.capitalize(), score]


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


func _on_player_took_damage(_amount: float, source_lane: int) -> void:
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	_show_feedback("HIT", Color(1.0, 0.35, 0.35, 1.0), 0.40)
	_highlight_timing_ring(source_lane, Color(1.0, 0.25, 0.25, 1.0), 5.0)


func _on_ultimate_available() -> void:
	ultimate_label.text = "Ultimate: READY"
	_show_feedback("READY", Color(1.0, 0.85, 0.35, 1.0), 0.45)


func _on_ultimate_fired(_power: float) -> void:
	ultimate_label.text = "Ultimate: 0%"
	_show_feedback("DEVOUR", Color(1.0, 0.72, 0.25, 1.0), 0.45)


func _on_combat_ended(victory: bool) -> void:
	if _combat_finished:
		return

	if not victory:
		_finish_run(false)
		return

	if _phase_transitioning:
		return

	_advance_phase()


func _on_enemy_damaged(enemy_id: int, _damage: float) -> void:
	_animate_enemy_damage(enemy_id)


func _on_enemy_defeated(enemy_id: int) -> void:
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
	_slow_motion_gen += 1
	var gen: int = _slow_motion_gen
	Engine.time_scale = scale
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		if _slow_motion_gen == gen:
			Engine.time_scale = _base_time_scale
	)


func _on_player_attacked(lane: int, _damage: float, was_timed: bool) -> void:
	if was_timed:
		_show_feedback("TIMED", Color(1.0, 0.95, 0.55, 1.0), 0.36)
		_highlight_timing_ring(lane, Color(1.0, 0.95, 0.55, 1.0), 5.0)
		_spawn_attack_silhouette_to_lane(lane, Color(1.0, 0.92, 0.58, 0.55), 10.0, 0.12, 1.0)
	else:
		_show_feedback("HIT", Color(0.95, 0.95, 0.95, 1.0), 0.28)
		_highlight_timing_ring(lane, Color(0.95, 0.95, 0.95, 1.0), 4.0)
		_spawn_attack_silhouette_to_lane(lane, Color(0.92, 0.92, 0.92, 0.35), 7.0, 0.10, 0.88)


func _on_player_parried(lane: int, quality: String, _reflect_damage: float) -> void:
	if quality == "perfect":
		_show_feedback("PERFECT PARRY", Color(0.55, 1.0, 0.78, 1.0), 0.45)
		_highlight_timing_ring(lane, Color(0.55, 1.0, 0.78, 1.0), 6.0)
		_spawn_attack_silhouette_to_lane(lane, Color(0.55, 1.0, 0.78, 0.65), 11.0, 0.16, 1.05)
	else:
		_show_feedback("PARRY", Color(0.55, 1.0, 0.78, 1.0), 0.34)
		_highlight_timing_ring(lane, Color(0.55, 1.0, 0.78, 1.0), 5.0)
		_spawn_attack_silhouette_to_lane(lane, Color(0.55, 1.0, 0.78, 0.45), 9.0, 0.13, 0.96)


func _on_player_dodged(_from_lane: int, to_lane: int) -> void:
	_show_feedback("DODGE", Color(0.65, 0.85, 1.0, 1.0), 0.28)
	_highlight_timing_ring(to_lane, Color(0.65, 0.85, 1.0, 1.0), 4.0)


func _on_player_no_stamina() -> void:
	_show_feedback("NO STAMINA", Color(1.0, 0.45, 0.45, 1.0), 0.42)


func _on_combo_broken(_lost: int) -> void:
	_show_feedback("BROKEN", Color(1.0, 0.4, 0.4, 1.0), 0.40)


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
