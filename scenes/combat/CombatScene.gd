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
const AUDIO_CONTENT = preload("res://data/AudioContent.gd")
const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")
const SONG_CONTENT = preload("res://data/SongContent.gd")
const TRICKY_SONGMAP = preload("res://data/song_maps/tricky_songmap.gd")
const SONG_CONDUCTOR_SCRIPT = preload("res://systems/SongConductor.gd")
const COMBAT_TRANSITION_STATE = preload("res://systems/CombatTransitionState.gd")
const COMBAT_IMPACT_FEEDBACK = preload("res://systems/CombatImpactFeedback.gd")
const COMBAT_PRESENTATION_RUNTIME = preload("res://systems/CombatPresentationRuntime.gd")
const ENCOUNTER_IDENTITY_RUNTIME = preload("res://systems/EncounterIdentityRuntime.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")
const RING_OUTER_RADIUS: float = 30.0
const RING_GOOD_RADIUS: float = 24.0
const RING_PERFECT_RADIUS: float = 15.0
const RING_POINT_COUNT: int = 32
const LANE_BAND_HEIGHT: float = 36.0
const LANE_IDLE_ALPHA: float = 0.0
const LANE_THREAT_ALPHA: float = 0.054
const LANE_CRITICAL_ALPHA: float = 0.112
const EDGE_STATE_WIDTH: float = 0.016
const RUN_GROWTH_SCRIPT_PATH: String = "res://systems/RunGrowth.gd"
const ENEMY_LOW_HP_THRESHOLD: float = 0.25
const SUPPORT_MASTERY_CONTEXT_TIMEOUT: float = 1.75
const LIVE_REWARD_WINDOW: float = 8.0
const DNA_HUD_VISIBLE_SLOTS: int = 2
# DNA economy: amount granted per enemy kill from the current phase's reward pool.
# Phase reward_pool maps kills to creature species — accumulated DNA gates bond/eat.
const DNA_PER_KILL: float = 2.5

# Combat background images. Picked randomly at run start; expandable for
# boss-specific or region-specific overrides via _apply_combat_background().
const COMBAT_BG_PATHS: Array[String] = [
	"res://assets/backgrounds/combat/cbg1.png",
	"res://assets/backgrounds/combat/cbg2.png",
	"res://assets/backgrounds/combat/cbg3.png",
]
# Dim factor applied to all combat backgrounds.
# Keeps images atmospheric without competing with lanes, rings, or HUD.
const COMBAT_BG_MODULATE: Color = Color(0.78, 0.78, 0.78, 1.0)

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
var _support_creature_portrait: TextureRect = null
var _support_portrait_species: String = ""  # cached species_id to skip redundant texture loads
var _run_build_shell: ColorRect = null
var _eaten_value_label: Label = null
var _upgrade_value_label: Label = null
var _bond_value_label: Label = null
var _support_trigger_label: Label = null
var _atk_value_label: Label = null
var _quig_anchor_label: Label = null
var _hp_value_label: Label = null
var _exp_value_label: Label = null
var _dna_shell: ColorRect = null
var _dna_slot_labels: Array[Label] = []
var _battlefield_panel: ColorRect = null
var _battlefield_inner_panel: ColorRect = null
var _battlefield_left_shade: ColorRect = null
var _battlefield_right_shade: ColorRect = null
var _battlefield_top_trim: ColorRect = null
var _battlefield_bottom_trim: ColorRect = null
var _bg_sprite: TextureRect = null
var _bonded_creature_sprite: Sprite2D = null
var _bonded_creature_species: String = ""
var _presentation_runtime: RefCounted = null

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
var _reward_creature_portrait: TextureRect = null

var _combat_finished: bool = false
var _phase_transitioning: bool = false

# enemy_id -> Color — active status color override for enemy markers.
# Cleared when the status expires or the enemy is defeated.
var _status_marker_overrides: Dictionary = {}

var _awaiting_reward_choice: bool = false
var _reward_choice_made: bool = false
var _run_finished: bool = false
var _pending_reward_creature: Dictionary = {}
var _pending_reward_dna_locked: bool = false
var _live_reward_shell: ColorRect = null
var _live_reward_title_label: Label = null
var _live_reward_body_label: Label = null
var _live_reward_hint_label: Label = null
var _live_reward_queue: Array[Dictionary] = []
var _live_reward_offer_timer: float = 0.0

# Incremented each time an encounter payload is loaded. The function
# captures this at entry and bails after the boss intro await if a newer load
# has superseded it — mirrors the _cycle_task_id pattern in LaneManager.
var _encounter_load_gen: int = 0

var _active_encounter: Dictionary = {}
var _current_phase_index: int = 0
var _run_growth: Node = null

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

# Song-mode state (used when _song_mode == true).
var _song_mode: bool = false
var _song_elapsed: float = 0.0
var _song_paused: bool = false
var _song_phase_index: int = -1
var _song_boss_triggered: bool = false
var _next_song_enemy_id: int = 100
var _song_reward_pending: bool = false
# Active phase table — set at run start from RegionSongContent based on active_region.
var _song_phases: Array = []
# SongConductor child node — null when no music-driven run is active.
var _song_conductor: Node = null
# Maps dynamically spawned song enemy_id → lane (so we know where to respawn on death).
var _song_enemy_lanes: Dictionary = {}
var _song_timer_label: Label = null
var _song_phase_label: Label = null
var _song_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _song_phase_dna_award_index: int = 0
# Brief beat-quality text shown near the timing rings when the player acts on-beat.
var _beat_feedback_label: Label = null
var _last_mastery_context: Dictionary = {}

# Boss music race state.
# newness.wav plays during the final boss encounter.
# If the boss is not killed before the track ends, the player loses.
var _boss_music_player: AudioStreamPlayer = null
var _boss_race_active: bool = false
var _boss_music_duration: float = 0.0
var _boss_hp_threshold_fired: bool = false  # fires once when boss HP crosses 50%
var _boss_presence_timer: float = 0.0       # drives sovereign marker urgency pulse
# Current region id — set at _start_song_run(); drives per-region runtime feel.
var _region_id: String = ""


func _ready() -> void:
	_setup_visuals()
	_setup_ui()
	_create_feedback_label()
	_create_title_cards()
	_create_timing_circle_container()
	_create_attack_fx_container()
	_setup_presentation_runtime()
	_create_reward_overlay()
	_create_live_reward_shell()
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
	if _song_mode and _song_reward_pending and _awaiting_reward_choice and _live_reward_offer_timer > 0.0:
		_live_reward_offer_timer = max(_live_reward_offer_timer - delta, 0.0)
		_refresh_live_reward_shell()
		if _live_reward_offer_timer <= 0.0:
			_expire_live_reward_offer()

	if _song_mode and not _song_paused and not _run_finished:
		if _song_conductor != null:
			# Conductor is active: sync elapsed time from audio playback position.
			# Section transitions and boss trigger are driven by conductor signals,
			# not by _tick_song_phase() or the manual SONG_DURATION check below.
			_song_elapsed = _song_conductor.get_song_time()
		else:
			# Fallback (no audio): wall-clock timer with manual phase/boss checks.
			_song_elapsed += delta
			_tick_song_phase()
			if not _song_boss_triggered and _song_elapsed >= SONG_CONTENT.SONG_DURATION:
				_trigger_boss_final_movement()
		_update_song_hud()
		# Stall recovery: if the fire cycle is running but stalled with live enemies,
		# kick it back. This catches any edge case where _cycle_stalled got set but
		# set_enemy() missed the restart (e.g. enemies placed while _combat_running was false).
		if not _song_boss_triggered and lane_manager.is_combat_running() and lane_manager.is_song_cycle_stalled() and lane_manager.alive_count() > 0:
			lane_manager.start_song_cycle()

	if _boss_race_active and _boss_music_player != null and is_instance_valid(_boss_music_player):
		_update_boss_race_hud()
		_update_boss_presence(delta)


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

	# Beat pulse — brief alpha boost on all receivers each beat.
	# Phase 0 = beat fired, decays quickly; small anticipation rise near phase 1.
	# This gives the player a visual metronome without relying on a projectile.
	var beat_pulse: float = 0.0
	if _song_conductor != null and is_instance_valid(_song_conductor) and _song_conductor.is_beat_active():
		var bp: float = _song_conductor.get_beat_phase()
		if bp < 0.18:
			beat_pulse = (1.0 - bp / 0.18) * 0.13
		elif bp > 0.88:
			beat_pulse = ((bp - 0.88) / 0.12) * 0.06

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

		var outer_color: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.56)
		var good_color: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.20)
		var perfect_color: Color = base_color.lightened(0.32)
		var outer_width: float = 1.8
		var good_width: float = 1.0
		var perfect_width: float = 3.6
		var receiver_alpha: float = 0.10 if lane == player_combat.current_lane else 0.05
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
					perfect_width = 4.4
					receiver_alpha = 0.32
					receiver_glow_alpha = 0.18
					beat_color = active_color.lightened(0.44)

				var edge_distance: float = min(abs(p - outer_entry), abs(p - outer_exit))
				if edge_distance <= EDGE_STATE_WIDTH:
					var edge_t: float = 1.0 - clamp(edge_distance / EDGE_STATE_WIDTH, 0.0, 1.0)
					edge_alpha = 0.18 + (0.26 * edge_t)
					outer_width = lerp(outer_width, 3.0, edge_t)

		# Apply beat pulse on top of proximity-driven alpha.
		# The pulse is identical across all lanes — it is a global metronome, not lane-specific.
		receiver_alpha = minf(receiver_alpha + beat_pulse, 0.52)
		if beat_pulse > 0.03:
			beat_color = beat_color.lerp(active_color.lightened(0.38), beat_pulse / 0.13)

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
		var focus_alpha: float = 0.015
		var focus_scale: float = 1.0
		var focus_color: Color = inactive_color

		if lane == player_combat.current_lane:
			state_alpha += 0.014
			focus_alpha = 0.032

		var proj = lane_manager.get_projectile(lane)
		if proj != null and not proj.is_resolved and not proj.is_reflected:
			var p: float = proj.progress
			var pressure: float = clamp((p - 0.76) / 0.28, 0.0, 1.0)
			if pressure > 0.0:
				state_color = lane_color.lerp(active_color.darkened(0.20), 0.55)
				state_alpha = lerp(state_alpha, LANE_THREAT_ALPHA, pressure)
				focus_color = active_color
				focus_alpha = lerp(focus_alpha, 0.16, pressure)
				focus_scale = lerp(1.0, 1.08, pressure)
				var pulse: float = 0.92 + (sin(time * 5.2 + lane) * 0.03 + 0.03) * pressure
				strip.scale.y = pulse
			else:
				strip.scale.y = 1.0

			if p >= outer_entry and p <= outer_exit:
				var critical_t: float = 1.0 - clamp(abs(p - 1.0) / (outer_exit - 1.0), 0.0, 1.0)
				state_alpha = lerp(state_alpha, LANE_CRITICAL_ALPHA, 0.65 + critical_t * 0.35)
				focus_alpha = lerp(focus_alpha, 0.24, 0.70 + critical_t * 0.30)
				focus_scale = lerp(focus_scale, 1.14, 0.70 + critical_t * 0.30)
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

	if _awaiting_reward_choice and not _reward_choice_made:
		if key_event.keycode == KEY_B:
			_choose_bond()
			return
		if key_event.keycode == KEY_E:
			_choose_eat()
			return
		if key_event.keycode == KEY_N:
			_pass_reward()
			return

	if _run_finished:
		if key_event.keycode == KEY_R:
			_start_mini_run()
			return
		if key_event.keycode == KEY_T:
			get_tree().change_scene_to_file("res://scenes/ui/LairScene.tscn")
			return


func _apply_text_role(label: Label, role: String, align: int = -1) -> void:
	UI_STYLE.apply_label(label, role, align)


func _set_shell_treatment(shell: ColorRect, color: Color, border_color: Color) -> void:
	if shell == null:
		return
	shell.color = color
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := StyleBoxFlat.new()
	panel.bg_color = color
	panel.corner_radius_top_left = 7
	panel.corner_radius_top_right = 7
	panel.corner_radius_bottom_left = 7
	panel.corner_radius_bottom_right = 7
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = border_color
	shell.add_theme_stylebox_override("panel", panel)


func _setup_visuals() -> void:
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.z_index = -10
	background.color = Color(0.05, 0.04, 0.05, 1.0)

	_apply_combat_background()

	var field_rect := Rect2(104.0, 112.0, 1060.0, 464.0)

	_battlefield_panel = ColorRect.new()
	_battlefield_panel.name = "BattlefieldPanel"
	_battlefield_panel.position = field_rect.position
	_battlefield_panel.size = field_rect.size
	_battlefield_panel.color = Color(0.02, 0.02, 0.03, 0.02)
	_battlefield_panel.z_index = -7
	add_child(_battlefield_panel)

	_battlefield_inner_panel = ColorRect.new()
	_battlefield_inner_panel.name = "BattlefieldInner"
	_battlefield_inner_panel.position = field_rect.position + Vector2(18.0, 18.0)
	_battlefield_inner_panel.size = field_rect.size - Vector2(36.0, 36.0)
	_battlefield_inner_panel.color = Color(0.02, 0.02, 0.03, 0.01)
	_battlefield_inner_panel.z_index = -6
	add_child(_battlefield_inner_panel)

	_battlefield_left_shade = ColorRect.new()
	_battlefield_left_shade.name = "BattlefieldLeftShade"
	_battlefield_left_shade.position = Vector2(field_rect.position.x + 6.0, field_rect.position.y + 20.0)
	_battlefield_left_shade.size = Vector2(86.0, field_rect.size.y - 40.0)
	_battlefield_left_shade.color = Color(0.02, 0.02, 0.03, 0.14)
	_battlefield_left_shade.z_index = -5
	add_child(_battlefield_left_shade)

	_battlefield_right_shade = ColorRect.new()
	_battlefield_right_shade.name = "BattlefieldRightShade"
	_battlefield_right_shade.position = Vector2(field_rect.end.x - 92.0, field_rect.position.y + 20.0)
	_battlefield_right_shade.size = Vector2(86.0, field_rect.size.y - 40.0)
	_battlefield_right_shade.color = Color(0.02, 0.02, 0.03, 0.10)
	_battlefield_right_shade.z_index = -5
	add_child(_battlefield_right_shade)

	_battlefield_top_trim = ColorRect.new()
	_battlefield_top_trim.name = "BattlefieldTopTrim"
	_battlefield_top_trim.position = field_rect.position + Vector2(76.0, 8.0)
	_battlefield_top_trim.size = Vector2(field_rect.size.x - 152.0, 2.0)
	_battlefield_top_trim.color = Color(0.44, 0.37, 0.28, 0.20)
	_battlefield_top_trim.z_index = -5
	add_child(_battlefield_top_trim)

	_battlefield_bottom_trim = ColorRect.new()
	_battlefield_bottom_trim.name = "BattlefieldBottomTrim"
	_battlefield_bottom_trim.position = Vector2(field_rect.position.x + 96.0, field_rect.end.y - 10.0)
	_battlefield_bottom_trim.size = Vector2(field_rect.size.x - 192.0, 1.0)
	_battlefield_bottom_trim.color = Color(0.34, 0.27, 0.21, 0.16)
	_battlefield_bottom_trim.z_index = -5
	add_child(_battlefield_bottom_trim)

	flash_overlay.anchor_right = 1.0
	flash_overlay.anchor_bottom = 1.0
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_overlay.z_index = 100
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_combat_background(override_path: String = "") -> void:
	# Loads and applies a combat background image behind the battlefield.
	# override_path: pass a specific res:// path to force a particular image.
	#   e.g. for a boss encounter: _apply_combat_background("res://assets/backgrounds/combat/boss_hollow.png")
	#   e.g. for a region: _apply_combat_background("res://assets/backgrounds/combat/pale_shelf.png")
	# Without override, picks randomly from COMBAT_BG_PATHS.
	if _bg_sprite != null and is_instance_valid(_bg_sprite):
		_bg_sprite.queue_free()
		_bg_sprite = null

	var path: String = override_path
	if path.is_empty():
		path = COMBAT_BG_PATHS[randi() % COMBAT_BG_PATHS.size()]

	if not ResourceLoader.exists(path):
		return

	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return

	_bg_sprite = TextureRect.new()
	_bg_sprite.name = "CombatBg"
	_bg_sprite.texture = tex
	# Explicit pixel size from viewport — anchor-based sizing on a Control node
	# dynamically added to a Node2D parent resolves to Vector2(0,0) at _ready() time
	# because there is no parent Control rect to anchor against. Setting position and
	# size directly is the reliable path here.
	_bg_sprite.position = Vector2.ZERO
	_bg_sprite.size = get_viewport_rect().size
	# STRETCH_SCALE fills the rect exactly — no cropping, no letterboxing.
	# The image is always centered and covers the full window.
	_bg_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_sprite.z_index = -9
	_bg_sprite.modulate = COMBAT_BG_MODULATE
	add_child(_bg_sprite)


func _setup_ui() -> void:
	_build_meter_shell()
	combo_label.text = "0"
	combo_label.position = Vector2(1040.0, 16.0)
	combo_label.size = Vector2(180.0, 30.0)
	_apply_text_role(combo_label, "primary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	combo_label.add_theme_font_size_override("font_size", 24)
	style_label.text = "Stirring"
	style_label.position = Vector2(962.0, 46.0)
	style_label.size = Vector2(174.0, 24.0)
	_apply_text_role(style_label, "secondary_value", HORIZONTAL_ALIGNMENT_LEFT)
	style_label.add_theme_font_size_override("font_size", 17)
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	stamina_bar.position = Vector2(34.0, 58.0)
	stamina_bar.size = Vector2(340.0, 13.0)
	stamina_bar.show_percentage = false
	hp_bar.min_value = 0.0
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	hp_bar.position = Vector2(34.0, 36.0)
	hp_bar.size = Vector2(340.0, 16.0)
	hp_bar.show_percentage = false
	ultimate_label.text = "0%"
	ultimate_label.position = Vector2(946.0, 18.0)
	ultimate_label.size = Vector2(102.0, 24.0)
	_apply_text_role(ultimate_label, "warm_value")
	ultimate_label.add_theme_font_size_override("font_size", 20)
	result_label.visible = false
	result_label.text = ""
	result_label.position = Vector2(320.0, 290.0)
	result_label.size = Vector2(640.0, 72.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_text_role(result_label, "screen_title")
	controls_label.text = "A S D choose lane  |  Left Arrow + lane parry  |  Right Arrow + lane dodge  |  R unleash"
	controls_label.position = Vector2(32.0, 646.0)
	controls_label.size = Vector2(720.0, 26.0)
	_apply_text_role(controls_label, "hint")
	_style_progress_bar(hp_bar, Color(0.18, 0.06, 0.08, 0.88), Color(0.73, 0.24, 0.26, 1.0), 6)
	_style_progress_bar(stamina_bar, Color(0.08, 0.09, 0.10, 0.82), Color(0.44, 0.66, 0.58, 1.0), 5)
	_build_quig_anchor()
	_build_dna_shell()
	_build_song_hud()
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
	_combo_shell.position = Vector2(18.0, 8.0)
	_combo_shell.size = Vector2(374.0, 108.0)
	_set_shell_treatment(_combo_shell, Color(0.07, 0.07, 0.08, 0.84), Color(0.23, 0.20, 0.18, 0.88))
	ui_layer.add_child(_combo_shell)

	_style_shell = ColorRect.new()
	_style_shell.name = "RightHudShell"
	_style_shell.position = Vector2(892.0, 8.0)
	_style_shell.size = Vector2(340.0, 84.0)
	_set_shell_treatment(_style_shell, Color(0.08, 0.07, 0.08, 0.84), Color(0.24, 0.20, 0.18, 0.88))
	ui_layer.add_child(_style_shell)

	_resource_shell = ColorRect.new()
	_resource_shell.name = "RightHudAccent"
	_resource_shell.position = Vector2(1044.0, 18.0)
	_resource_shell.size = Vector2(176.0, 24.0)
	_set_shell_treatment(_resource_shell, Color(0.15, 0.12, 0.10, 0.30), Color(0.30, 0.24, 0.18, 0.46))
	ui_layer.add_child(_resource_shell)

	_support_shell = ColorRect.new()
	_support_shell.name = "SupportShell"
	_support_shell.position = Vector2(892.0, 98.0)
	_support_shell.size = Vector2(276.0, 90.0)
	_set_shell_treatment(_support_shell, Color(0.08, 0.08, 0.10, 0.74), Color(0.20, 0.22, 0.19, 0.78))
	ui_layer.add_child(_support_shell)

	# Bonded creature portrait — shown when the active support creature has a sprite_path.
	# Hides automatically for creatures without art; no fallback needed.
	_support_creature_portrait = TextureRect.new()
	_support_creature_portrait.name = "SupportPortrait"
	_support_creature_portrait.position = Vector2(902.0, 108.0)
	_support_creature_portrait.size = Vector2(64.0, 64.0)
	_support_creature_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_support_creature_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_support_creature_portrait.visible = false
	ui_layer.add_child(_support_creature_portrait)

	_support_name_label = Label.new()
	_support_name_label.position = Vector2(974.0, 108.0)
	_support_name_label.size = Vector2(136.0, 20.0)
	_support_name_label.text = "No bond"
	_apply_text_role(_support_name_label, "caption_strong")
	_support_name_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(_support_name_label)

	_support_value_label = Label.new()
	_support_value_label.position = Vector2(1106.0, 108.0)
	_support_value_label.size = Vector2(54.0, 20.0)
	_support_value_label.text = "--"
	_apply_text_role(_support_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_support_value_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(_support_value_label)

	_support_bar = ProgressBar.new()
	_support_bar.position = Vector2(974.0, 132.0)
	_support_bar.size = Vector2(186.0, 12.0)
	_support_bar.min_value = 0.0
	_support_bar.max_value = 100.0
	_support_bar.value = 0.0
	_support_bar.show_percentage = false
	ui_layer.add_child(_support_bar)
	_style_progress_bar(_support_bar, Color(0.08, 0.09, 0.10, 0.80), Color(0.54, 0.70, 0.63, 0.92), 4)

	_support_trigger_label = Label.new()
	_support_trigger_label.name = "SupportTriggerHint"
	_support_trigger_label.position = Vector2(974.0, 150.0)
	_support_trigger_label.size = Vector2(186.0, 22.0)
	_support_trigger_label.text = ""
	_apply_text_role(_support_trigger_label, "dim")
	_support_trigger_label.add_theme_font_size_override("font_size", 12)
	ui_layer.add_child(_support_trigger_label)

	_run_build_shell = ColorRect.new()
	_run_build_shell.name = "RunBuildShell"
	_run_build_shell.position = Vector2(892.0, 196.0)
	_run_build_shell.size = Vector2(244.0, 70.0)
	_set_shell_treatment(_run_build_shell, Color(0.07, 0.07, 0.09, 0.58), Color(0.19, 0.18, 0.17, 0.66))
	ui_layer.add_child(_run_build_shell)

	var eaten_caption := Label.new()
	eaten_caption.position = Vector2(904.0, 199.0)
	eaten_caption.size = Vector2(44.0, 12.0)
	eaten_caption.text = "Consumed"
	_apply_text_role(eaten_caption, "caption")
	ui_layer.add_child(eaten_caption)

	_eaten_value_label = Label.new()
	_eaten_value_label.position = Vector2(942.0, 198.0)
	_eaten_value_label.size = Vector2(184.0, 12.0)
	_eaten_value_label.text = "--"
	_apply_text_role(_eaten_value_label, "hint")
	ui_layer.add_child(_eaten_value_label)

	var upgrade_caption := Label.new()
	upgrade_caption.position = Vector2(904.0, 220.0)
	upgrade_caption.size = Vector2(52.0, 12.0)
	upgrade_caption.text = "Tendency"
	_apply_text_role(upgrade_caption, "caption")
	ui_layer.add_child(upgrade_caption)

	_upgrade_value_label = Label.new()
	_upgrade_value_label.position = Vector2(942.0, 219.0)
	_upgrade_value_label.size = Vector2(184.0, 12.0)
	_upgrade_value_label.text = "--"
	_apply_text_role(_upgrade_value_label, "hint")
	ui_layer.add_child(_upgrade_value_label)

	var bond_caption := Label.new()
	bond_caption.position = Vector2(904.0, 243.0)
	bond_caption.size = Vector2(52.0, 12.0)
	bond_caption.text = "Bond"
	_apply_text_role(bond_caption, "caption")
	ui_layer.add_child(bond_caption)

	_bond_value_label = Label.new()
	_bond_value_label.position = Vector2(942.0, 242.0)
	_bond_value_label.size = Vector2(184.0, 12.0)
	_bond_value_label.text = "--"
	_apply_text_role(_bond_value_label, "cool_value")
	ui_layer.add_child(_bond_value_label)

	var hp_caption := Label.new()
	hp_caption.position = Vector2(34.0, 16.0)
	hp_caption.size = Vector2(96.0, 20.0)
	hp_caption.text = "Health"
	_apply_text_role(hp_caption, "caption_strong")
	hp_caption.add_theme_font_size_override("font_size", 15)
	ui_layer.add_child(hp_caption)

	_hp_value_label = Label.new()
	_hp_value_label.position = Vector2(250.0, 12.0)
	_hp_value_label.size = Vector2(124.0, 24.0)
	_apply_text_role(_hp_value_label, "primary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_value_label.add_theme_font_size_override("font_size", 22)
	ui_layer.add_child(_hp_value_label)

	# EXP and Attack share the bottom row of the left panel, separated left/right.
	var exp_caption := Label.new()
	exp_caption.position = Vector2(34.0, 84.0)
	exp_caption.size = Vector2(44.0, 16.0)
	exp_caption.text = "EXP"
	_apply_text_role(exp_caption, "caption")
	exp_caption.add_theme_font_size_override("font_size", 13)
	ui_layer.add_child(exp_caption)

	_exp_value_label = Label.new()
	_exp_value_label.position = Vector2(78.0, 82.0)
	_exp_value_label.size = Vector2(156.0, 18.0)
	_apply_text_role(_exp_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_LEFT)
	_exp_value_label.add_theme_font_size_override("font_size", 15)
	ui_layer.add_child(_exp_value_label)

	var atk_caption := Label.new()
	atk_caption.position = Vector2(246.0, 84.0)
	atk_caption.size = Vector2(38.0, 16.0)
	atk_caption.text = "Atk"
	_apply_text_role(atk_caption, "caption")
	atk_caption.add_theme_font_size_override("font_size", 13)
	ui_layer.add_child(atk_caption)

	_atk_value_label = Label.new()
	_atk_value_label.position = Vector2(286.0, 82.0)
	_atk_value_label.size = Vector2(88.0, 18.0)
	_apply_text_role(_atk_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_atk_value_label.add_theme_font_size_override("font_size", 15)
	ui_layer.add_child(_atk_value_label)

	var style_caption := Label.new()
	style_caption.position = Vector2(904.0, 48.0)
	style_caption.size = Vector2(56.0, 18.0)
	style_caption.text = "Style"
	_apply_text_role(style_caption, "caption")
	style_caption.add_theme_font_size_override("font_size", 13)
	ui_layer.add_child(style_caption)

	var score_caption := Label.new()
	score_caption.position = Vector2(1088.0, 20.0)
	score_caption.size = Vector2(70.0, 16.0)
	score_caption.text = "Score"
	_apply_text_role(score_caption, "caption")
	score_caption.add_theme_font_size_override("font_size", 13)
	ui_layer.add_child(score_caption)

	var ultimate_caption := Label.new()
	ultimate_caption.position = Vector2(904.0, 20.0)
	ultimate_caption.size = Vector2(50.0, 16.0)
	ultimate_caption.text = "Ult"
	_apply_text_role(ultimate_caption, "caption")
	ultimate_caption.add_theme_font_size_override("font_size", 13)
	ui_layer.add_child(ultimate_caption)

	_bonded_creature_sprite = Sprite2D.new()
	_bonded_creature_sprite.name = "BondedCreatureSprite"
	_bonded_creature_sprite.visible = false
	_bonded_creature_sprite.centered = true
	_bonded_creature_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_bonded_creature_sprite)

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
	_boss_name_label.text = ""
	_apply_text_role(_boss_name_label, "boss", HORIZONTAL_ALIGNMENT_CENTER)
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


func _build_song_hud() -> void:
	# Song phase label — top-center, dim.
	_song_phase_label = Label.new()
	_song_phase_label.name = "SongPhaseLabel"
	_song_phase_label.text = ""
	_apply_text_role(_song_phase_label, "dim", HORIZONTAL_ALIGNMENT_CENTER)
	_song_phase_label.size = Vector2(400.0, 20.0)
	_song_phase_label.position = Vector2(440.0, 10.0)
	_song_phase_label.visible = false
	ui_layer.add_child(_song_phase_label)

	# Song timer label — top-right corner, shows seconds remaining.
	_song_timer_label = Label.new()
	_song_timer_label.name = "SongTimerLabel"
	_song_timer_label.text = ""
	_apply_text_role(_song_timer_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_song_timer_label.size = Vector2(80.0, 22.0)
	_song_timer_label.position = Vector2(1180.0, 10.0)
	_song_timer_label.visible = false
	ui_layer.add_child(_song_timer_label)

	# Beat feedback label — appears near the timing rings briefly when the player
	# lands a combat action on-beat (IN SYNC / ON BEAT / LOCKED IN / SLIP).
	# Position is tunable; currently centered on the hit zone area.
	_beat_feedback_label = Label.new()
	_beat_feedback_label.name = "BeatFeedbackLabel"
	_beat_feedback_label.text = ""
	_apply_text_role(_beat_feedback_label, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	_beat_feedback_label.size = Vector2(180.0, 20.0)
	_beat_feedback_label.position = Vector2(354.0, 344.0)
	_beat_feedback_label.visible = false
	_beat_feedback_label.z_index = 6
	ui_layer.add_child(_beat_feedback_label)


func _build_quig_anchor() -> void:
	_quig_anchor_label = Label.new()
	_quig_anchor_label.name = "QuigAnchor"
	_quig_anchor_label.visible = false
	_quig_anchor_label.position = Vector2(916.0, 234.0)
	_quig_anchor_label.size = Vector2(228.0, 42.0)
	_quig_anchor_label.text = ""
	_apply_text_role(_quig_anchor_label, "dim")
	ui_layer.add_child(_quig_anchor_label)


func _build_dna_shell() -> void:
	_dna_shell = ColorRect.new()
	_dna_shell.name = "DnaShell"
	_dna_shell.position = Vector2(892.0, 274.0)
	_dna_shell.size = Vector2(276.0, 84.0)
	_set_shell_treatment(_dna_shell, Color(0.07, 0.07, 0.09, 0.64), Color(0.18, 0.22, 0.20, 0.72))
	ui_layer.add_child(_dna_shell)

	var dna_caption := Label.new()
	dna_caption.position = Vector2(904.0, 278.0)
	dna_caption.size = Vector2(60.0, 14.0)
	dna_caption.text = "DNA"
	_apply_text_role(dna_caption, "caption_strong")
	dna_caption.add_theme_font_size_override("font_size", 13)
	ui_layer.add_child(dna_caption)

	_dna_slot_labels.clear()
	for i in range(DNA_HUD_VISIBLE_SLOTS):
		var label := Label.new()
		label.position = Vector2(904.0, 298.0 + i * 24.0)
		label.size = Vector2(248.0, 20.0)
		label.text = "--"
		_apply_text_role(label, "secondary_value")
		label.add_theme_font_size_override("font_size", 14)
		ui_layer.add_child(label)
		_dna_slot_labels.append(label)


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
	_feedback_label.position = Vector2(494.0, 84.0)
	_feedback_label.size = Vector2(272.0, 36.0)
	_feedback_label.pivot_offset = Vector2(136.0, 18.0)
	_apply_text_role(_feedback_label, "feedback", HORIZONTAL_ALIGNMENT_CENTER)
	_feedback_label.add_theme_font_size_override("font_size", 26)
	add_child(_feedback_label)


func _create_title_cards() -> void:
	_title_card = Label.new()
	_title_card.name = "BiomeTitleCard"
	_title_card.visible = false
	_title_card.z_index = 95
	_title_card.position = Vector2(420.0, 110.0)
	_title_card.size = Vector2(480.0, 34.0)
	_apply_text_role(_title_card, "heading", HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_title_card)

	_subtitle_card = Label.new()
	_subtitle_card.name = "BiomeSubtitleCard"
	_subtitle_card.visible = false
	_subtitle_card.z_index = 95
	_subtitle_card.position = Vector2(420.0, 140.0)
	_subtitle_card.size = Vector2(480.0, 26.0)
	_apply_text_role(_subtitle_card, "hint", HORIZONTAL_ALIGNMENT_CENTER)
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


func _setup_presentation_runtime() -> void:
	_presentation_runtime = COMBAT_PRESENTATION_RUNTIME.new(
		flash_overlay,
		camera_2d,
		_timing_circle_container,
		_attack_fx_container,
		player_combat,
		lane_manager,
		_enemy_markers_by_id,
		_ring_highlight_timers
	)


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
	_set_shell_treatment(_reward_panel, Color(0.09, 0.07, 0.08, 0.98), Color(0.26, 0.20, 0.18, 0.94))
	_reward_panel.position = Vector2(160.0, 88.0)
	_reward_panel.size = Vector2(960.0, 452.0)
	_reward_overlay.add_child(_reward_panel)

	# Creature portrait — shown when a sprite_path is available for the offered creature.
	# Positioned in the left column; text labels shift right to accommodate it.
	_reward_creature_portrait = TextureRect.new()
	_reward_creature_portrait.name = "CreaturePortrait"
	_reward_creature_portrait.position = Vector2(42.0, 50.0)
	_reward_creature_portrait.size = Vector2(152.0, 240.0)
	_reward_creature_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reward_creature_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reward_creature_portrait.visible = false
	_reward_panel.add_child(_reward_creature_portrait)

	_reward_creature_tag_label = Label.new()
	_reward_creature_tag_label.name = "RewardTag"
	_reward_creature_tag_label.position = Vector2(204.0, 18.0)
	_reward_creature_tag_label.size = Vector2(250.0, 18.0)
	_apply_text_role(_reward_creature_tag_label, "caption_strong")
	_reward_panel.add_child(_reward_creature_tag_label)

	_reward_title_label = Label.new()
	_reward_title_label.name = "RewardTitle"
	_reward_title_label.position = Vector2(204.0, 40.0)
	_reward_title_label.size = Vector2(250.0, 56.0)
	_apply_text_role(_reward_title_label, "heading")
	_reward_panel.add_child(_reward_title_label)

	_reward_body_label = Label.new()
	_reward_body_label.name = "RewardBody"
	_reward_body_label.position = Vector2(204.0, 98.0)
	_reward_body_label.size = Vector2(250.0, 150.0)
	_reward_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_role(_reward_body_label, "body")
	_reward_panel.add_child(_reward_body_label)

	_reward_bond_card = ColorRect.new()
	_reward_bond_card.name = "RewardBondCard"
	_reward_bond_card.position = Vector2(468.0, 54.0)
	_reward_bond_card.size = Vector2(206.0, 244.0)
	_set_shell_treatment(_reward_bond_card, Color(0.09, 0.10, 0.09, 0.96), Color(0.24, 0.31, 0.25, 0.88))
	_reward_panel.add_child(_reward_bond_card)

	var bond_accent := ColorRect.new()
	bond_accent.name = "BondAccent"
	bond_accent.size = Vector2(206.0, 4.0)
	bond_accent.position = Vector2.ZERO
	bond_accent.color = Color(0.80, 0.60, 0.24, 0.90)
	_reward_bond_card.add_child(bond_accent)

	_reward_bond_label = Label.new()
	_reward_bond_label.name = "RewardBondLabel"
	_reward_bond_label.position = Vector2(18.0, 18.0)
	_reward_bond_label.size = Vector2(168.0, 26.0)
	_apply_text_role(_reward_bond_label, "bond_heading")
	_reward_bond_card.add_child(_reward_bond_label)

	_reward_bond_effect_label = Label.new()
	_reward_bond_effect_label.name = "RewardBondEffect"
	_reward_bond_effect_label.position = Vector2(18.0, 56.0)
	_reward_bond_effect_label.size = Vector2(170.0, 154.0)
	_reward_bond_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_role(_reward_bond_effect_label, "body")
	_reward_bond_card.add_child(_reward_bond_effect_label)

	_reward_eat_card = ColorRect.new()
	_reward_eat_card.name = "RewardEatCard"
	_reward_eat_card.position = Vector2(694.0, 54.0)
	_reward_eat_card.size = Vector2(206.0, 244.0)
	_set_shell_treatment(_reward_eat_card, Color(0.11, 0.08, 0.07, 0.96), Color(0.36, 0.24, 0.20, 0.92))
	_reward_panel.add_child(_reward_eat_card)

	var eat_accent := ColorRect.new()
	eat_accent.name = "EatAccent"
	eat_accent.size = Vector2(206.0, 4.0)
	eat_accent.position = Vector2.ZERO
	eat_accent.color = Color(0.72, 0.22, 0.18, 0.90)
	_reward_eat_card.add_child(eat_accent)

	_reward_eat_label = Label.new()
	_reward_eat_label.name = "RewardEatLabel"
	_reward_eat_label.position = Vector2(18.0, 18.0)
	_reward_eat_label.size = Vector2(168.0, 26.0)
	_apply_text_role(_reward_eat_label, "eat_heading")
	_reward_eat_card.add_child(_reward_eat_label)

	_reward_eat_effect_label = Label.new()
	_reward_eat_effect_label.name = "RewardEatEffect"
	_reward_eat_effect_label.position = Vector2(18.0, 56.0)
	_reward_eat_effect_label.size = Vector2(170.0, 154.0)
	_reward_eat_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_role(_reward_eat_effect_label, "body")
	_reward_eat_card.add_child(_reward_eat_effect_label)

	_reward_quig_label = Label.new()
	_reward_quig_label.name = "RewardQuig"
	_reward_quig_label.position = Vector2(42.0, 316.0)
	_reward_quig_label.size = Vector2(860.0, 32.0)
	_apply_text_role(_reward_quig_label, "hint")
	_reward_panel.add_child(_reward_quig_label)

	_reward_hint_label = Label.new()
	_reward_hint_label.name = "RewardHint"
	_reward_hint_label.position = Vector2(42.0, 382.0)
	_reward_hint_label.size = Vector2(860.0, 26.0)
	_apply_text_role(_reward_hint_label, "hint")
	_reward_panel.add_child(_reward_hint_label)


func _create_live_reward_shell() -> void:
	_live_reward_shell = ColorRect.new()
	_live_reward_shell.name = "LiveRewardShell"
	_live_reward_shell.visible = false
	_live_reward_shell.position = Vector2(456.0, 516.0)
	_live_reward_shell.size = Vector2(410.0, 124.0)
	_set_shell_treatment(_live_reward_shell, Color(0.08, 0.07, 0.08, 0.86), Color(0.30, 0.24, 0.18, 0.78))
	ui_layer.add_child(_live_reward_shell)

	_live_reward_title_label = Label.new()
	_live_reward_title_label.position = Vector2(16.0, 12.0)
	_live_reward_title_label.size = Vector2(378.0, 24.0)
	_apply_text_role(_live_reward_title_label, "subheading")
	_live_reward_shell.add_child(_live_reward_title_label)

	_live_reward_body_label = Label.new()
	_live_reward_body_label.position = Vector2(16.0, 40.0)
	_live_reward_body_label.size = Vector2(378.0, 48.0)
	_live_reward_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_role(_live_reward_body_label, "body")
	_live_reward_body_label.add_theme_font_size_override("font_size", 13)
	_live_reward_shell.add_child(_live_reward_body_label)

	_live_reward_hint_label = Label.new()
	_live_reward_hint_label.position = Vector2(16.0, 92.0)
	_live_reward_hint_label.size = Vector2(378.0, 18.0)
	_apply_text_role(_live_reward_hint_label, "hint")
	_live_reward_hint_label.add_theme_font_size_override("font_size", 12)
	_live_reward_shell.add_child(_live_reward_hint_label)


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
	EventBus.screen_flash.connect(_presentation_runtime.on_screen_flash)
	EventBus.screen_shake.connect(_presentation_runtime.on_screen_shake)
	EventBus.slow_motion.connect(_on_slow_motion)
	EventBus.player_attacked.connect(_on_player_attacked)
	EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.player_dodged.connect(_on_player_dodged)
	EventBus.player_no_stamina.connect(_on_player_no_stamina)
	EventBus.combo_broken.connect(_on_combo_broken)
	EventBus.player_teleported.connect(_on_player_teleported)
	EventBus.timing_ring_pressed.connect(_presentation_runtime.on_timing_ring_pressed)
	EventBus.run_growth_changed.connect(_on_run_growth_changed)
	EventBus.tendency_growth_resolved.connect(_on_tendency_growth_resolved)
	EventBus.support_charge_changed.connect(_on_support_charge_changed)
	EventBus.bonded_support_triggered.connect(_on_bonded_support_triggered)
	EventBus.dna_gained.connect(_on_dna_gained)
	EventBus.mastery_context_updated.connect(_on_mastery_context_updated)
	EventBus.enemy_status_applied.connect(_on_enemy_status_applied)
	EventBus.enemy_status_cleared.connect(_on_enemy_status_cleared)
	EventBus.phrase_milestone.connect(_on_phrase_milestone)
	EventBus.tier_changed.connect(_on_tier_changed)


func _setup_lane_manager() -> void:
	lane_manager.setup_layout(get_viewport_rect().size)

	if not lane_manager.load_scene():
		push_error("LaneManager failed to load projectile scene.")
		return

	lane_manager.combat_scene = self


func _setup_player_combat() -> void:
	if player_combat.has_method("setup"):
		player_combat.setup(lane_manager, combat_meter)


func _start_song_run() -> void:
	_song_mode = true
	_song_elapsed = 0.0
	_song_paused = false
	_song_phase_index = -1
	_song_boss_triggered = false
	_next_song_enemy_id = 100
	_song_reward_pending = false
	_song_enemy_lanes.clear()
	_song_rng.randomize()
	_clear_mastery_context_cache()

	var region_id: String = String(GameState.active_region.get("id", "feeding_hollow"))
	var song_run: Dictionary = ENCOUNTER_IDENTITY_RUNTIME.build_song_run(region_id)
	_region_id = String(song_run.get("region_id", region_id))
	_song_phases = song_run.get("phases", [])

	_active_encounter = {
		"biome": song_run.get("biome", COMBAT_CONTENT.BIOME_FEEDING_HOLLOW),
		"identity": song_run.get("identity", {}),
		"phases": [],
		"phase_intro_texts": []
	}
	_current_phase_index = 0
	_combat_finished = false
	_phase_transitioning = false

	_rebuild_enemy_lookup_tables()
	_apply_encounter_presentation()
	_build_arena_visuals()
	_draw_timing_circles()
	_prepare_for_encounter(true)
	_refresh_bonded_creature_render()

	lane_manager.set_song_mode_enabled(true)

	if _song_timer_label != null:
		_song_timer_label.visible = true
		_song_timer_label.text = "%d" % int(SONG_CONTENT.SONG_DURATION)
	if _song_phase_label != null:
		_song_phase_label.visible = true

	_set_song_controls_text()

	# Enter phase 0 — starts the fire cycle with initial enemies.
	_enter_song_phase(0)

	# Start the music conductor. Phase transitions from here on are driven by
	# conductor signals, not _tick_song_phase(). Phase 0 is already entered above;
	# the conductor's opening section signal will only update spawn_interval_mult.
	_start_song_conductor()


func _tick_song_phase() -> void:
	# Check if it is time to advance to the next phase.
	var next_idx: int = _song_phase_index + 1
	if next_idx >= _song_phases.size():
		return
	var next_phase: Dictionary = _song_phases[next_idx]
	if _song_elapsed >= float(next_phase.get("start_time", 9999.0)):
		_enter_song_phase(next_idx)


func _enter_song_phase(new_idx: int) -> void:
	var old_idx: int = _song_phase_index
	_song_phase_index = new_idx
	var new_phase: Dictionary = _song_phases[new_idx]
	var new_reward_pool: Array = new_phase.get("reward_pool", [])
	_song_phase_dna_award_index = _song_rng.randi_range(0, max(new_reward_pool.size() - 1, 0)) if not new_reward_pool.is_empty() else 0

	_apply_song_phase_cadence(new_phase)

	var intro_text: String = ENCOUNTER_IDENTITY_RUNTIME.get_phase_intro_text(_region_id, new_phase)
	if not intro_text.is_empty():
		_show_feedback(intro_text, Color(0.92, 0.88, 0.74, 1.0), 0.55)

	if _song_phase_label != null:
		_song_phase_label.text = ENCOUNTER_IDENTITY_RUNTIME.get_phase_display_label(_region_id, new_phase)

	# If the previous phase had a reward pool, queue its creature offer without pausing the song.
	if old_idx >= 0:
		var old_phase: Dictionary = _song_phases[old_idx]
		var reward_pool: Array = old_phase.get("reward_pool", [])
		if not reward_pool.is_empty():
			_offer_song_phase_reward(reward_pool)

	_seed_song_enemies_for_phase(new_phase)


func _seed_song_enemies_for_phase(phase: Dictionary) -> void:
	var max_threats: int = int(phase.get("max_active_threats", 2))
	var current_alive: int = lane_manager.alive_count()
	var lanes_to_fill: int = min(max_threats - current_alive, lane_manager.LANE_COUNT)
	if lanes_to_fill <= 0:
		# Alive count already meets the phase cap, but still ensure the fire cycle
		# is running — it may have been stopped by a reward-pause stop() call.
		if not lane_manager.is_combat_running():
			lane_manager.start_song_cycle()
		return

	# Prefer lanes without an active enemy; fall back to any lane.
	var empty_lanes: Array = []
	for lane in range(lane_manager.LANE_COUNT):
		if lane_manager.get_enemy(lane).is_empty() or float(lane_manager.get_enemy(lane).get("hp", 0.0)) <= 0.0:
			empty_lanes.append(lane)

	var ordered_lanes: Array = ENCOUNTER_IDENTITY_RUNTIME.order_empty_lanes(
		_region_id,
		phase,
		empty_lanes,
		player_combat.current_lane,
		_song_rng
	)

	# Fill lanes in the order preferred by the current encounter identity.
	var filled: int = 0
	for i in range(ordered_lanes.size()):
		if filled >= lanes_to_fill:
			break
		_place_song_enemy(int(ordered_lanes[i]))
		filled += 1

	# If the fire cycle hasn't started yet (phase 0 entry), kick it off.
	if not lane_manager.is_combat_running():
		lane_manager.start_song_cycle()


func _place_song_enemy(lane: int) -> void:
	var phase: Dictionary = _song_phases[_song_phase_index]
	var enemy: Dictionary = ENCOUNTER_IDENTITY_RUNTIME.pick_weighted_enemy(phase, _song_rng)
	if enemy.is_empty():
		return
	enemy["id"] = _next_song_enemy_id
	enemy["lane"] = lane
	_song_enemy_lanes[_next_song_enemy_id] = lane
	_next_song_enemy_id += 1
	lane_manager.set_enemy(lane, enemy)

	# Register the enemy in the lookup tables and create its visual marker.
	# This mirrors _build_arena_visuals() per-enemy logic; skipping it would leave
	# the enemy logically present but invisible (and break damage numbers / low-HP tint).
	var enemy_id: int = int(enemy.get("id", 0))
	_all_enemies_by_id[enemy_id] = enemy.duplicate(true)
	_enemy_max_hp[enemy_id] = float(enemy.get("hp", 1.0))
	_enemy_phase_by_id[enemy_id] = _song_phase_index

	var biome: Dictionary = _active_encounter.get("biome", {})
	var inactive_color: Color = biome.get("enemy_inactive_color", Color(0.38, 0.18, 0.18, 0.55))
	var marker_size: float = 42.0
	var marker_half: float = marker_size * 0.5
	# Dark frame behind the marker gives enemies visual weight and separates them from the background.
	var marker_frame := ColorRect.new()
	marker_frame.size = Vector2(marker_size + 2.0, marker_size + 2.0)
	marker_frame.position = Vector2(
		lane_manager.get_enemy_x() - marker_half - 1.0,
		lane_manager.get_lane_y(lane) - marker_half - 1.0
	)
	marker_frame.color = Color(0.0, 0.0, 0.0, 0.44)
	_enemy_marker_container.add_child(marker_frame)

	var enemy_marker := ColorRect.new()
	enemy_marker.name = "Enemy_%d" % enemy_id
	enemy_marker.size = Vector2(marker_size, marker_size)
	enemy_marker.position = Vector2(
		lane_manager.get_enemy_x() - marker_half,
		lane_manager.get_lane_y(lane) - marker_half
	)
	enemy_marker.color = inactive_color
	enemy_marker.modulate = enemy.get("marker_modulate", Color(1.0, 1.0, 1.0, 1.0))
	_enemy_marker_container.add_child(enemy_marker)
	_enemy_markers_by_id[enemy_id] = enemy_marker

func _offer_song_phase_reward(reward_pool: Array) -> void:
	var creature_id: String = reward_pool[_song_rng.randi_range(0, reward_pool.size() - 1)]
	var creature: Dictionary = COMBAT_CONTENT.get_creature(creature_id)
	if creature.is_empty():
		return

	_song_reward_pending = true
	_live_reward_queue.append(creature)
	if not _awaiting_reward_choice:
		_show_next_live_reward_offer()


func _resume_song_after_reward() -> void:
	_hide_live_reward_shell()
	_pending_reward_creature = {}
	_pending_reward_dna_locked = false
	_show_next_live_reward_offer()


func _trigger_boss_final_movement() -> void:
	_live_reward_queue.clear()
	_song_reward_pending = false
	_awaiting_reward_choice = false
	_hide_live_reward_shell()
	_song_boss_triggered = true
	_song_paused = true
	_song_mode = false
	_boss_hp_threshold_fired = false
	_boss_presence_timer = 0.0
	COMBAT_TRANSITION_STATE.prepare_boss_handoff(
		lane_manager,
		Callable(self, "_clear_mastery_context_cache"),
		Callable(self, "_stop_song_conductor")
	)
	# Phase 1 opens at a deliberate 1.05 s interval — slower than the final song
	# chorus — so the first sovereign feels like a shift in register, not just more of
	# the same. Phase 2 and the 50%-HP escalation accelerate from here.
	# Wide stagger (0.54) keeps lanes separated — each sovereign arrives as its own event.
	lane_manager.set_cycle_interval(1.05)
	lane_manager.set_fire_stagger(0.54)

	# Start the boss climax track. This replaces tricky.wav and becomes the
	# damage-race timer — kill the boss before newness.wav ends or lose.
	_start_boss_music()

	# The live boss handoff is a direct encounter payload, not a queued run step.
	var boss_encounter: Dictionary = ENCOUNTER_IDENTITY_RUNTIME.build_live_boss_encounter()

	_run_finished = false
	_is_boss_encounter = false

	_hide_song_hud()
	_show_boss_race_hud()
	_load_encounter_payload(boss_encounter, false)


func _update_song_hud() -> void:
	if _song_timer_label == null:
		return
	var remaining: float
	if _song_conductor != null:
		# Count down to the final movement (boss trigger), not total song length.
		remaining = max(_song_conductor.get_final_movement_time() - _song_elapsed, 0.0)
	else:
		remaining = max(SONG_CONTENT.SONG_DURATION - _song_elapsed, 0.0)
	_song_timer_label.text = "%d" % int(ceil(remaining))


func _set_song_controls_text() -> void:
	controls_label.text = "A S D choose lane  |  Left Arrow parry  |  Right Arrow dodge  |  R unleash"


func _start_song_conductor() -> void:
	# Instantiate SongConductor, wire signals, and start playback.
	# Called at the end of _start_song_run() after phase 0 is already entered,
	# so the opening section signal from the conductor only updates spawn_mult.
	_stop_song_conductor()

	_song_conductor = SONG_CONDUCTOR_SCRIPT.new()
	_song_conductor.name = "SongConductor"
	add_child(_song_conductor)
	_song_conductor.section_changed.connect(_on_conductor_section_changed)
	_song_conductor.final_movement_reached.connect(_on_conductor_final_movement)
	_song_conductor.start(TRICKY_SONGMAP)
	player_combat.call("set_song_conductor", _song_conductor)


func _on_conductor_section_changed(section_id: String, data: Dictionary) -> void:
	# Find the matching phase in _song_phases by id and enter it.
	# If we are already in this phase (phase 0 pre-entered at run start),
	# skip _enter_song_phase() and only apply the conductor's cycle multiplier on
	# top of the existing phase cadence baseline.
	for i in range(_song_phases.size()):
		if String(_song_phases[i].get("id", "")) == section_id:
			if i != _song_phase_index:
				_enter_song_phase(i)
			_apply_song_phase_cadence(_song_phases[i], float(data.get("spawn_interval_mult", 1.0)))
			break


func _on_conductor_final_movement() -> void:
	# Boss trigger driven by the song map's FINAL_MOVEMENT_FRACTION.
	# Replaces the old SONG_CONTENT.SONG_DURATION wall-clock check.
	if not _song_boss_triggered and _song_mode and not _run_finished:
		_trigger_boss_final_movement()


func _hide_song_hud() -> void:
	if _song_timer_label != null:
		_song_timer_label.visible = false
	if _song_phase_label != null:
		_song_phase_label.visible = false


# ── Boss music race ──────────────────────────────────────────────────────────

func _start_boss_music() -> void:
	# Load and play the live boss track. Wires the finished signal so song-end triggers
	# defeat if the boss is still alive. Sets _boss_race_active immediately so
	# the countdown is visible through the boss intro animation.
	_stop_boss_music()
	var stream: AudioStream = load(AUDIO_CONTENT.BOSS_TRACK_PATH)
	if stream == null:
		push_error("CombatScene: failed to load boss music " + AUDIO_CONTENT.BOSS_TRACK_PATH)
		return
	_boss_music_player = AudioStreamPlayer.new()
	_boss_music_player.name = "BossMusicPlayer"
	_boss_music_player.stream = stream
	_boss_music_player.volume_db = 0.0
	add_child(_boss_music_player)
	_boss_music_duration = stream.get_length()
	if _boss_music_duration <= 0.0:
		push_error("CombatScene: boss music reports zero length — using 180 s fallback")
		_boss_music_duration = 180.0
	_boss_music_player.finished.connect(_on_boss_music_finished)
	_boss_race_active = true
	_boss_music_player.play()


func _stop_boss_music() -> void:
	_boss_race_active = false
	if _boss_music_player != null and is_instance_valid(_boss_music_player):
		_boss_music_player.stop()
		_boss_music_player.queue_free()
	_boss_music_player = null


func _show_boss_race_hud() -> void:
	# Reuse the song HUD labels for the boss countdown.
	if _song_phase_label != null:
		_song_phase_label.text = "KILL IT BEFORE THE SONG ENDS"
		_song_phase_label.add_theme_color_override("font_color", Color(0.82, 0.50, 0.28, 0.80))
		_song_phase_label.visible = true
	if _song_timer_label != null:
		_song_timer_label.add_theme_color_override("font_color", Color(0.70, 0.55, 0.44, 0.85))
		_song_timer_label.visible = true


func _update_boss_race_hud() -> void:
	if _song_timer_label == null or _boss_music_player == null or not is_instance_valid(_boss_music_player):
		return
	var elapsed: float = _boss_music_player.get_playback_position()
	var remaining: float = max(_boss_music_duration - elapsed, 0.0)
	_song_timer_label.text = "%d" % int(ceil(remaining))
	# Shift the timer label toward red as time runs out (ramps in the final 50%).
	var frac: float = clampf(remaining / max(_boss_music_duration, 1.0), 0.0, 1.0)
	var urgency: float = clampf((0.5 - frac) / 0.5, 0.0, 1.0)
	_song_timer_label.add_theme_color_override("font_color",
		Color(lerpf(0.70, 1.0, urgency), lerpf(0.55, 0.20, urgency), lerpf(0.44, 0.20, urgency), 0.92))


func _update_boss_presence(delta: float) -> void:
	# Pulses active sovereign markers with increasing urgency as the timer counts down.
	# Status color overrides (REND, EXPOSE, etc.) always take priority.
	_boss_presence_timer += delta
	if _boss_music_player == null or not is_instance_valid(_boss_music_player):
		return
	var elapsed: float = _boss_music_player.get_playback_position()
	var remaining: float = max(_boss_music_duration - elapsed, 0.0)
	var urgency: float = clampf(1.0 - (remaining / max(_boss_music_duration, 1.0)), 0.0, 1.0)
	# Pulse rate: 0.8 Hz at start → 2.5 Hz at full urgency
	var pulse_rate: float = lerpf(0.8, 2.5, urgency)
	var pulse: float = sin(_boss_presence_timer * TAU * pulse_rate) * 0.5 + 0.5
	var biome: Dictionary = _active_encounter.get("biome", {})
	var boss_active_color: Color = biome.get("enemy_active_color", Color(0.86, 0.58, 0.14, 1.0))
	# Lerp toward danger red at high urgency
	var danger_color: Color = Color(1.0, 0.18, 0.08, 1.0)
	var base_color: Color = boss_active_color.lerp(danger_color, urgency * 0.65)
	var pulse_alpha: float = lerpf(0.72, 1.0, pulse * urgency)
	var pulsed_color: Color = Color(base_color.r, base_color.g, base_color.b, pulse_alpha)

	for enemy_id in _enemy_markers_by_id.keys():
		var marker: ColorRect = _enemy_markers_by_id[enemy_id]
		if marker == null or not is_instance_valid(marker):
			continue
		# Never override a status color.
		if _status_marker_overrides.has(enemy_id):
			continue
		var enemy_phase: int = int(_enemy_phase_by_id.get(enemy_id, -1))
		if enemy_phase == _current_phase_index:
			marker.color = pulsed_color


func _on_boss_music_finished() -> void:
	# Called when newness.wav plays to its end.
	# Guard: if the boss was already killed, _boss_race_active is false — do nothing.
	if not _boss_race_active or _run_finished:
		return
	_boss_race_active = false
	_stop_boss_music()
	_hide_song_hud()
	if _run_finished:
		return
	# Song ended while boss still lives — player loses.
	lane_manager.stop()
	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(false)
	_show_feedback("THE SONG DEVOURED YOU", Color(1.0, 0.28, 0.22, 1.0), 0.80)
	EventBus.emit_signal("screen_flash", Color(0.55, 0.06, 0.06, 0.28), 0.40)
	await get_tree().create_timer(0.8).timeout
	if not _run_finished:
		_finish_run(false)


func _stop_song_conductor() -> void:
	if _song_conductor != null and is_instance_valid(_song_conductor):
		_song_conductor.stop()
		_song_conductor.queue_free()
	_song_conductor = null


func _start_mini_run() -> void:
	# Reset transient transition state before resetting run data.
	COMBAT_TRANSITION_STATE.prepare_run_restart(
		Callable(self, "_stop_song_conductor"),
		Callable(self, "_stop_boss_music"),
		Callable(self, "_clear_mastery_context_cache")
	)

	# Resets shared run state then launches in song mode.
	GameState.run_number += 1
	_run_finished = false
	_is_boss_encounter = false
	_boss_total_hp = 0.0
	_boss_current_hp = 0.0
	_hide_boss_bar()
	_hide_reward_overlay()

	if GameState.has_method("reset_run_state"):
		GameState.reset_run_state()

	EventBus.emit_signal("run_started", int(GameState.run_number))
	_live_reward_queue.clear()
	_song_reward_pending = false
	_hide_live_reward_shell()
	_refresh_run_build_readout()
	_start_song_run()


# Direct encounter loader used by the live runtime. Song phases build their
# own pressure state; only the boss handoff uses an authored encounter payload.
func _load_encounter_payload(encounter: Dictionary, reset_hp: bool) -> void:
	_encounter_load_gen += 1
	var load_gen: int = _encounter_load_gen

	if encounter.is_empty():
		_finish_run(true)
		return

	_active_encounter = encounter.duplicate(true)
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
		lane_strip.size = Vector2(760.0, LANE_BAND_HEIGHT)
		lane_strip.position = Vector2(208.0, lane_manager.get_lane_y(lane) - LANE_BAND_HEIGHT * 0.5)
		lane_strip.pivot_offset = lane_strip.size * 0.5
		lane_strip.color = Color(lane_color.r, lane_color.g, lane_color.b, LANE_IDLE_ALPHA)
		_lane_marker_container.add_child(lane_strip)
		_lane_strips[lane] = lane_strip

		var lane_focus := ColorRect.new()
		lane_focus.name = "LaneFocus_%d" % lane
		lane_focus.size = Vector2(42.0, 66.0)
		lane_focus.position = Vector2(
			lane_manager.get_hit_zone_x() - 21.0,
			lane_manager.get_lane_y(lane) - 33.0
		)
		lane_focus.pivot_offset = lane_focus.size * 0.5
		lane_focus.color = Color(0.78, 0.72, 0.54, 0.012)
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
		enemy_marker.modulate = enemy.get("marker_modulate", Color(1.0, 1.0, 1.0, 1.0))

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

		# Apply active status color override on top of biome color.
		if _status_marker_overrides.has(enemy_id):
			marker.color = _status_marker_overrides[enemy_id]


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

		# Glow and edge rings kept at alpha 0 — they serve as structural nodes for the
		# proximity animation system in _update_timing_ring_proximity().
		var receiver_glow := _make_disc_polygon(RING_OUTER_RADIUS + 6.0, Color(base_color.r, base_color.g, base_color.b, 0.0))
		receiver_glow.name = "ReceiverGlow"

		# Inner fill: active lane gets a subtle glow, inactive is nearly invisible.
		var fill_alpha: float = 0.07 if is_active_lane else 0.03
		var receiver_fill := _make_disc_polygon(RING_GOOD_RADIUS + 1.0, Color(base_color.r, base_color.g, base_color.b, fill_alpha))
		receiver_fill.name = "ReceiverFill"

		# Outer ring: boundary marker — slightly thicker for cleaner visibility.
		var outer_ring := _make_ring_line(RING_OUTER_RADIUS, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.56), 1.8)
		outer_ring.name = "Outer"

		# Good ring: subtle mid-ring, guides the eye toward perfect without calling attention.
		var good_ring := _make_ring_line(
			RING_GOOD_RADIUS,
			Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.20),
			1.0
		)
		good_ring.name = "Good"

		# Perfect ring: the focal point — thicker and bright, the true target.
		var perfect_ring := _make_ring_line(RING_PERFECT_RADIUS, base_color.lightened(0.32), 3.6)
		perfect_ring.name = "Perfect"

		var edge_ring := _make_ring_line(RING_OUTER_RADIUS + 4.0, Color(base_color.r, base_color.g, base_color.b, 0.0), 1.0)
		edge_ring.name = "Edge"

		# Beat mark: thin vertical line at the exact hit point.
		var beat_mark := Line2D.new()
		beat_mark.name = "BeatMark"
		beat_mark.default_color = Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.55)
		beat_mark.width = 1.2
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
	if _song_mode:
		_set_song_controls_text()
		return
	if _is_boss_encounter:
		controls_label.text = "Boss encounter  |  A S D choose lane  |  Left Arrow parry  |  Right Arrow dodge  |  R unleash"
	else:
		controls_label.text = "A S D choose lane  |  Left Arrow parry  |  Right Arrow dodge  |  R unleash"


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
		EventBus.emit_signal("screen_shake", 5.0, 0.30)
		# Three-lane phase — tighten the fire cadence to 0.78 s.
		# Tighter stagger (0.45) brings all three sovereigns into quicker succession.
		lane_manager.set_cycle_interval(0.78)
		lane_manager.set_fire_stagger(0.45)

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
		# Boss killed — stop the race music and timer before the reward overlay.
		_boss_race_active = false
		_stop_boss_music()
		_hide_song_hud()
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
	_finish_run(true)


func _finish_run(victory: bool) -> void:
	# Final state for the whole run.
	_run_finished = true
	_combat_finished = true
	_phase_transitioning = false

	_stop_boss_music()
	_hide_song_hud()
	_hide_boss_bar()

	if lane_manager != null and lane_manager.has_method("stop"):
		lane_manager.stop()

	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(false)

	if victory:
		result_label.text = "RUN COMPLETE"
		result_label.visible = true
		_show_feedback("THE HOLLOW REMEMBERS YOU", Color(0.85, 1.0, 0.75, 1.0), 0.70)
		controls_label.text = "Run complete  |  R restart  |  T return to lair"
	else:
		result_label.text = "RUN FAILED"
		result_label.visible = true
		_show_feedback("RUN FAILED", Color(1.0, 0.45, 0.45, 1.0), 0.65)
		controls_label.text = "Run failed  |  R restart  |  T return to lair"

	_hide_reward_overlay()
	_hide_live_reward_shell()
	_live_reward_queue.clear()

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
	# First strike: flash + shake + all rings flare to threat color.
	EventBus.emit_signal("screen_flash", Color(0.68, 0.32, 0.06, 0.34), 0.20)
	EventBus.emit_signal("screen_shake", 2.2, 0.16)
	for _intro_lane in range(3):
		_presentation_runtime.highlight_timing_ring(_intro_lane, Color(0.92, 0.42, 0.12, 1.0), 6.2)

	_title_card.text = boss_name
	_title_card.modulate = Color(0.88, 0.52, 0.10, 0.0)
	_title_card.visible = true

	_subtitle_card.text = String(_active_encounter.get("boss_subtitle", "APEX OF THE HOLLOW"))
	_subtitle_card.modulate = Color(0.72, 0.52, 0.28, 0.0)
	_subtitle_card.visible = true

	var tween := create_tween()
	# Title punches in quickly.
	tween.tween_property(_title_card, "modulate:a", 1.0, 0.10)
	tween.tween_interval(0.16)
	# Second impact flash as subtitle reveals.
	tween.tween_callback(func() -> void:
		EventBus.emit_signal("screen_flash", Color(0.62, 0.24, 0.04, 0.20), 0.14)
	)
	tween.tween_property(_subtitle_card, "modulate:a", 0.80, 0.18)
	tween.tween_interval(0.76)
	tween.tween_property(_title_card, "modulate:a", 0.0, 0.42)
	tween.parallel().tween_property(_subtitle_card, "modulate:a", 0.0, 0.42)
	tween.tween_callback(func() -> void:
		_title_card.visible = false
		_subtitle_card.visible = false
		_title_card.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_subtitle_card.modulate = Color(0.85, 0.85, 0.85, 1.0)
	)

	await tween.finished


func _trigger_boss_threshold_spectacle() -> void:
	# Fires once when boss HP crosses 50% — a second-act arrival moment.
	# All rings flare to threat color, two pulse-flashes, and a strong shake.
	for _thresh_lane in range(3):
		_presentation_runtime.highlight_timing_ring(_thresh_lane, Color(0.94, 0.38, 0.08, 1.0), 7.2)

	EventBus.emit_signal("screen_flash", Color(0.74, 0.28, 0.04, 0.34), 0.20)
	EventBus.emit_signal("screen_shake", 2.4, 0.14)

	var pulse_tween := create_tween()
	pulse_tween.tween_interval(0.26)
	pulse_tween.tween_callback(func() -> void:
		EventBus.emit_signal("screen_flash", Color(0.80, 0.32, 0.04, 0.20), 0.16)
		EventBus.emit_signal("screen_shake", 1.6, 0.10)
	)
	pulse_tween.tween_interval(0.22)
	pulse_tween.tween_callback(func() -> void:
		EventBus.emit_signal("screen_flash", Color(0.62, 0.22, 0.04, 0.12), 0.12)
	)


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
	# Punch-in: start enlarged and snap down — reads as impact authority, not decoration.
	_feedback_label.scale = Vector2(1.32, 1.32)

	var tween := create_tween()
	tween.tween_property(_feedback_label, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_interval(lifetime)
	tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.13)
	tween.tween_callback(func() -> void:
		_feedback_label.visible = false
		_feedback_label.modulate.a = 1.0
		_feedback_label.scale = Vector2.ONE
	)


func _get_beat_quality_for_action() -> String:
	# Returns the conductor's current beat quality ("perfect" / "good" / "off").
	# Returns "off" when no conductor is active (boss phase, no song, etc.).
	if _song_conductor == null or not is_instance_valid(_song_conductor):
		return "off"
	return _song_conductor.get_beat_quality()


func _show_beat_feedback(text: String, color: Color) -> void:
	# Shows a brief beat-quality label (IN SYNC / ON BEAT / LOCKED IN / SLIP) near
	# the timing rings. Fades out quickly so it does not crowd the main feedback.
	if _beat_feedback_label == null:
		return
	_beat_feedback_label.text = text
	_beat_feedback_label.modulate = Color(color.r, color.g, color.b, 1.0)
	_beat_feedback_label.visible = true
	var tween := create_tween()
	tween.tween_interval(0.22)
	tween.tween_property(_beat_feedback_label, "modulate:a", 0.0, 0.16)
	tween.tween_callback(func() -> void:
		_beat_feedback_label.visible = false
		_beat_feedback_label.modulate.a = 1.0
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

	EventBus.emit_signal("capture_offered", _pending_reward_creature)
	_reward_overlay.visible = true

	var _offer_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	var _offer_description: String = String(_pending_reward_creature.get("description", ""))
	var _encounter_context: String = _describe_creature_offer_context(_pending_reward_creature)

	# DNA gate: check whether the player has accumulated enough DNA for this species.
	var _offer_species_id: String = String(_pending_reward_creature.get("species_id", ""))
	var _offer_dna_threshold: float = float(_pending_reward_creature.get("dna_threshold", 0.0))
	var _player_dna: float = GameState.get_dna(_offer_species_id)
	_pending_reward_dna_locked = not GameState.has_dna_for(_offer_species_id, _offer_dna_threshold)

	_reward_creature_tag_label.text = "Creature"
	_reward_title_label.text = _offer_creature_name

	var _body_text: String = _offer_description
	if not _encounter_context.is_empty():
		_body_text += "\n\nEncounter: %s" % _encounter_context

	# Append DNA status to the description body.
	if _offer_dna_threshold > 0.0:
		var _dna_line: String
		if _pending_reward_dna_locked:
			_dna_line = "DNA:  %.0f / %.0f  —  not enough" % [_player_dna, _offer_dna_threshold]
		else:
			_dna_line = "DNA:  %.0f / %.0f  —  sufficient" % [_player_dna, _offer_dna_threshold]
		_reward_body_label.text = _body_text + "\n\n" + _dna_line
	else:
		_reward_body_label.text = _body_text

	if _pending_reward_dna_locked:
		_reward_bond_label.text = "Bond  [B]  — locked"
		_reward_bond_effect_label.text = "Not enough DNA.\n\n%s" % _format_bond_passive(_pending_reward_creature.get("bond_passive", {}))
		_reward_eat_label.text = "Eat  [E]  — locked"
		_reward_eat_effect_label.text = "Not enough DNA.\n\n%s" % _describe_eat_effect(_pending_reward_creature.get("eat_effect", {}))
		_reward_hint_label.text = "Insufficient DNA  |  N — pass this creature"
		controls_label.text = "DNA locked  |  N pass"
	else:
		_reward_bond_label.text = "Bond  [B]"
		_reward_bond_effect_label.text = "Keep it close.\n\n%s\n\nThe run bends around this creature." % _format_bond_passive(_pending_reward_creature.get("bond_passive", {}))
		_reward_eat_label.text = "Eat  [E]"
		_reward_eat_effect_label.text = "Take what it gives.\n\n%s\n\nImmediate pressure through consumption." % _describe_eat_effect(_pending_reward_creature.get("eat_effect", {}))
		_reward_hint_label.text = "Choose one  |  B keeps it close  |  E feeds on it  |  N pass"
		controls_label.text = "Reward choice  |  B bond  |  E eat  |  N pass"

	_reward_quig_label.text = String(_pending_reward_creature.get("quig_offer_text", ""))

	# Load and show creature portrait if art is available.
	if _reward_creature_portrait != null:
		var sprite_path: String = String(_pending_reward_creature.get("sprite_path", ""))
		if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			var portrait_tex: Texture2D = load(sprite_path) as Texture2D
			if portrait_tex != null:
				_reward_creature_portrait.texture = portrait_tex
				_reward_creature_portrait.visible = true
			else:
				_reward_creature_portrait.visible = false
		else:
			_reward_creature_portrait.visible = false


func _format_eat_effect(effect: Dictionary) -> String:
	match effect.get("type", ""):
		"damage_flat":
			return "+%.0f permanent attack damage" % float(effect.get("value", 0.0))
		"hp_restore":
			return "restores %.0f HP immediately — no permanent bonus" % float(effect.get("value", 0.0))
		_:
			return "absorb its essence"


func _describe_eat_effect(effect: Dictionary) -> String:
	match effect.get("type", ""):
		"damage_flat":
			return "+%.0f permanent attack damage" % float(effect.get("value", 0.0))
		"hp_restore":
			return "restores %.0f HP immediately â€” no permanent bonus" % float(effect.get("value", 0.0))
		"max_hp_flat":
			return "+%.0f max HP immediately" % float(effect.get("value", 0.0))
		"support_charge":
			return "+%.0f support charge immediately" % float(effect.get("value", 0.0))
		_:
			return "absorb its essence"


func _format_bond_passive(passive: Dictionary, bond_level: int = 1) -> String:
	var mult: float = GameState.get_bond_level_mult(bond_level)
	match passive.get("type", ""):
		"damage_on_ultimate":
			return "+%.0f damage added to your ultimate" % (float(passive.get("value", 0.0)) * mult)
		"damage_reduction_pct":
			return "%.0f%% damage reduction while bonded" % (float(passive.get("value", 0.0)) * mult * 100.0)
		"hp_on_kill":
			return "+%.1f HP restored on every enemy kill" % (float(passive.get("value", 0.0)) * mult)
		"parry_reflect_mult":
			return "+%.0f%% parry reflect damage while bonded" % (float(passive.get("value", 0.0)) * mult * 100.0)
		"timed_damage_flat":
			return "+%.1f flat damage added to every timed attack" % (float(passive.get("value", 0.0)) * mult)
		_:
			return "keep in roster"


func _format_bond_passive_short(passive: Dictionary, bond_level: int = 1) -> String:
	# Compact version for the in-combat BOND row of the run build shell.
	# bond_level scales displayed values to reflect current progression.
	var mult: float = GameState.get_bond_level_mult(bond_level)
	match passive.get("type", ""):
		"damage_on_ultimate":
			return "+%.0f ult dmg" % (float(passive.get("value", 0.0)) * mult)
		"damage_reduction_pct":
			return "%.0f%% def" % (float(passive.get("value", 0.0)) * mult * 100.0)
		"hp_on_kill":
			return "+%.1f hp/kill" % (float(passive.get("value", 0.0)) * mult)
		"parry_reflect_mult":
			return "+%.0f%% parry" % (float(passive.get("value", 0.0)) * mult * 100.0)
		"timed_damage_flat":
			return "+%.1f timed" % (float(passive.get("value", 0.0)) * mult)
		_:
			return "--"


func _format_trigger_hint(effect_id: String) -> String:
	# One-line description of when the bonded creature fires, shown under the support bar.
	match effect_id:
		"ashclaw_strike":
			return "Triggers on perfect timing"
		"bond_remnant_mend":
			return "Triggers on damage while ready"
		"gruvek_gorge":
			return "Triggers on kill"
		"veilskin_phase":
			return "Triggers on perfect parry"
		"thornback_rend":
			return "Triggers on perfect timing"
		_:
			return ""


func _describe_trigger_hint(effect_id: String) -> String:
	match effect_id:
		"knellspine_peal":
			return "Triggers on good timing"
		"marrowward_ward":
			return "Triggers on dodge"
		"gorefane_maul":
			return "Triggers on ultimate"
		"hushcoil_lull":
			return "Triggers on perfect parry"
		_:
			return _format_trigger_hint(effect_id)


func _hide_reward_overlay() -> void:
	_reward_overlay.visible = false
	_pending_reward_creature = {}
	_awaiting_reward_choice = false
	_reward_choice_made = false
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
		if not active.is_empty():
			var active_bond_level: int = int(active.get("bond_level", 1))
			_bond_value_label.text = _format_bond_passive_short(active.get("bond_passive", {}), active_bond_level)
		else:
			_bond_value_label.text = "--"

	if _atk_value_label != null:
		_atk_value_label.text = "%.0f" % GameState.get_attack_damage()

	if _run_build_shell != null:
		var has_build: bool = not GameState.absorbed_types.is_empty()
		_run_build_shell.color = Color(0.08, 0.08, 0.10, 0.60) if has_build else Color(0.07, 0.07, 0.09, 0.50)
	_refresh_dna_hud()


func _refresh_dna_hud() -> void:
	if _dna_slot_labels.is_empty():
		return

	var relevant_species: Array[String] = []
	if _song_mode and _song_phase_index >= 0 and _song_phase_index < _song_phases.size():
		var phase: Dictionary = _song_phases[_song_phase_index]
		for species_id in phase.get("reward_pool", []):
			var typed_species_id: String = String(species_id)
			if not typed_species_id.is_empty() and not relevant_species.has(typed_species_id):
				relevant_species.append(typed_species_id)

	if not _pending_reward_creature.is_empty():
		var pending_species_id: String = String(_pending_reward_creature.get("species_id", ""))
		if not pending_species_id.is_empty() and not relevant_species.has(pending_species_id):
			relevant_species.insert(0, pending_species_id)

	if relevant_species.is_empty():
		for species_id in GameState.dna_by_species.keys():
			var typed_species_id: String = String(species_id)
			if GameState.get_dna(typed_species_id) > 0.0:
				relevant_species.append(typed_species_id)
		relevant_species.sort()

	for i in range(_dna_slot_labels.size()):
		var label: Label = _dna_slot_labels[i]
		if i >= relevant_species.size():
			label.text = "--"
			continue

		var species_id: String = relevant_species[i]
		var creature: Dictionary = COMBAT_CONTENT.get_creature(species_id)
		var display_name: String = String(creature.get("display_name", species_id)).to_upper()
		var threshold: float = float(creature.get("dna_threshold", 0.0))
		var current: float = GameState.get_dna(species_id)
		if threshold > 0.0:
			label.text = "%s  %.0f/%.0f" % [display_name, current, threshold]
		else:
			label.text = "%s  %.0f" % [display_name, current]


func _show_live_reward_offer(creature_data: Dictionary) -> void:
	if _live_reward_shell == null:
		return

	_pending_reward_creature = creature_data.duplicate(true)
	_pending_reward_dna_locked = not GameState.has_dna_for(
		String(_pending_reward_creature.get("species_id", "")),
		float(_pending_reward_creature.get("dna_threshold", 0.0))
	)
	_reward_choice_made = false
	_awaiting_reward_choice = true
	_live_reward_offer_timer = LIVE_REWARD_WINDOW
	_live_reward_shell.visible = true
	EventBus.emit_signal("capture_offered", _pending_reward_creature)
	_refresh_live_reward_shell()
	_refresh_dna_hud()
	_refresh_song_controls_text()


func _refresh_live_reward_shell() -> void:
	if _live_reward_shell == null or _pending_reward_creature.is_empty():
		return

	var species_id: String = String(_pending_reward_creature.get("species_id", ""))
	var threshold: float = float(_pending_reward_creature.get("dna_threshold", 0.0))
	var current_dna: float = GameState.get_dna(species_id)
	var display_name: String = String(_pending_reward_creature.get("display_name", "Creature"))
	var encounter_context: String = _describe_creature_offer_context(_pending_reward_creature)
	_live_reward_title_label.text = "%s in reach" % display_name
	var live_body: String = String(_pending_reward_creature.get("description", ""))
	if not encounter_context.is_empty():
		live_body += "\nEncounter: %s" % encounter_context
	live_body += "\nDNA %.0f/%.0f" % [current_dna, threshold]
	_live_reward_body_label.text = live_body
	if _pending_reward_dna_locked:
		_live_reward_hint_label.text = "Locked for now  |  N pass  |  %.0fs" % ceil(_live_reward_offer_timer)
	else:
		_live_reward_hint_label.text = "B bond  |  E eat  |  N pass  |  %.0fs" % ceil(_live_reward_offer_timer)


func _hide_live_reward_shell() -> void:
	if _live_reward_shell != null:
		_live_reward_shell.visible = false
	_live_reward_offer_timer = 0.0


func _refresh_song_controls_text() -> void:
	if _song_reward_pending and _awaiting_reward_choice:
		if _pending_reward_dna_locked:
			controls_label.text = "Combat live  |  DNA locked  |  N pass reward"
		else:
			controls_label.text = "Combat live  |  B bond  |  E eat  |  N pass reward"
		return
	_set_song_controls_text()


func _show_next_live_reward_offer() -> void:
	if _live_reward_queue.is_empty():
		_song_reward_pending = false
		_hide_live_reward_shell()
		_refresh_song_controls_text()
		return

	var next_creature: Dictionary = _live_reward_queue.pop_front()
	_show_live_reward_offer(next_creature)


func _expire_live_reward_offer() -> void:
	if not _song_reward_pending or not _awaiting_reward_choice:
		return
	_pass_reward()


func _describe_creature_offer_context(creature_data: Dictionary) -> String:
	var species_id: String = String(creature_data.get("species_id", ""))
	if species_id.is_empty():
		return ""
	return COMBAT_CONTENT.get_creature_encounter_summary(species_id)


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
		elif eat_type == "max_hp_flat":
			var max_hp_bonus: int = int(round(float(entry.get("max_hp_bonus", 0.0))))
			chips.append("[%sHP+%d]" % [short_name, max_hp_bonus])
		elif eat_type == "support_charge":
			var support_charge_bonus: int = int(round(float(entry.get("support_charge_bonus", 0.0))))
			chips.append("[%sCH+%d]" % [short_name, support_charge_bonus])
		else:
			var damage_bonus: int = int(round(float(entry.get("damage_bonus", 0.0))))
			chips.append("[%s+%d]" % [short_name, damage_bonus])

	var hidden_count: int = GameState.absorbed_types.size() - visible_count
	if hidden_count > 0:
		chips.append("+%d" % hidden_count)

	return _join_compact_tokens(chips)


func _format_upgrade_summary() -> String:
	if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_tendency_summary"):
		return String(_run_growth.call("get_tendency_summary"))
	return "--"


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


func _choose_bond() -> void:
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	# DNA gate: bond costs the creature's dna_threshold in species-specific DNA.
	var _bond_species: String = String(_pending_reward_creature.get("species_id", ""))
	var _bond_threshold: float = float(_pending_reward_creature.get("dna_threshold", 0.0))
	if not GameState.has_dna_for(_bond_species, _bond_threshold):
		_show_feedback("NOT ENOUGH DNA", Color(0.92, 0.46, 0.28, 1.0), 0.42)
		return

	GameState.spend_dna(_bond_species, _bond_threshold)

	var updated_creature: Dictionary = GameState.add_bonded_creature(_pending_reward_creature)
	EventBus.emit_signal("creature_bonded", updated_creature)
	_refresh_dna_hud()

	_reward_choice_made = true
	_awaiting_reward_choice = false

	var _bond_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	_reward_creature_tag_label.text = "Bond sealed"
	_reward_title_label.text = "%s bonded." % _bond_creature_name
	_reward_body_label.text = "%s enters your roster at bond level %d." % [
		_bond_creature_name,
		int(updated_creature.get("bond_level", 1))
	]
	_reward_bond_label.text = "Bonded"
	_reward_bond_effect_label.text = _format_bond_passive(_pending_reward_creature.get("bond_passive", {}))
	_reward_eat_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_quig_label.text = "Quig: \"Good. Watch — they're already positioning.\""

	if _song_reward_pending:
		_show_feedback("%s BONDED" % _bond_creature_name.to_upper(), Color(0.82, 0.94, 0.76, 1.0), 0.34)
		_resume_song_after_reward()
	else:
		_reward_hint_label.text = "R restart run"
		controls_label.text = "Run complete  |  R restart run"
		_finish_run(true)


func _choose_eat() -> void:
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	# DNA gate: eat costs the creature's dna_threshold in species-specific DNA.
	var _eat_species: String = String(_pending_reward_creature.get("species_id", ""))
	var _eat_threshold: float = float(_pending_reward_creature.get("dna_threshold", 0.0))
	if not GameState.has_dna_for(_eat_species, _eat_threshold):
		_show_feedback("NOT ENOUGH DNA", Color(0.92, 0.46, 0.28, 1.0), 0.42)
		return

	GameState.spend_dna(_eat_species, _eat_threshold)

	var absorbed_entry: Dictionary = GameState.absorb_creature_type(_pending_reward_creature)
	if String(absorbed_entry.get("eat_type", "")) == "hp_restore":
		var healed: float = float(absorbed_entry.get("heal_applied", 0.0))
		if healed > 0.0:
			EventBus.emit_signal("player_healed", healed)
	elif String(absorbed_entry.get("eat_type", "")) == "max_hp_flat":
		EventBus.emit_signal("player_healed", float(absorbed_entry.get("heal_applied", 0.0)))
	elif String(absorbed_entry.get("eat_type", "")) == "support_charge":
		if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_support_charge_direct"):
			_run_growth.call("gain_support_charge_direct", float(absorbed_entry.get("support_charge_bonus", 0.0)))

	# Hollow Feed upgrade: extra heal on any eat.
	var hollow_feed_effect: Dictionary = _get_growth_effect("eat_hp_restore")
	if not hollow_feed_effect.is_empty():
		var feed_healed: float = GameState.heal_player(float(hollow_feed_effect.get("value", 0.0)))
		if feed_healed > 0.0:
			EventBus.emit_signal("player_healed", feed_healed)

	EventBus.emit_signal("creature_eaten", _pending_reward_creature)
	_refresh_dna_hud()

	_reward_choice_made = true
	_awaiting_reward_choice = false

	var _eat_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	_reward_creature_tag_label.text = "Consumed"
	_reward_title_label.text = "%s consumed." % _eat_creature_name
	_reward_body_label.text = "Its nature folds into you."
	_reward_bond_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_label.text = "Absorbed"
	var _eat_type_str: String = String(absorbed_entry.get("eat_type", "damage_flat"))
	if _eat_type_str == "hp_restore":
		_reward_eat_effect_label.text = "Type: %s\n\n+%.0f HP restored.\nNo permanent bonus." % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("heal_applied", 0.0))
		]
	elif _eat_type_str == "max_hp_flat":
		_reward_eat_effect_label.text = "Type: %s\n\n+%.0f max HP.\n+%.0f HP restored." % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("max_hp_bonus", 0.0)),
			float(absorbed_entry.get("heal_applied", 0.0))
		]
	elif _eat_type_str == "support_charge":
		_reward_eat_effect_label.text = "Type: %s\n\n+%.0f support charge immediately." % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("support_charge_bonus", 0.0))
		]
	else:
		_reward_eat_effect_label.text = "Type: %s\n\n+%.1f permanent attack damage" % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("damage_bonus", 0.0))
		]
	_reward_quig_label.text = "Quig is silent."
	_reward_hint_label.text = "..."

	_refresh_run_build_readout()

	if _song_reward_pending:
		_show_feedback("%s CONSUMED" % _eat_creature_name.to_upper(), Color(0.94, 0.62, 0.30, 1.0), 0.34)
		_resume_song_after_reward()
		return

	var timer: SceneTreeTimer = get_tree().create_timer(3.0)
	await timer.timeout

	if not _reward_choice_made:
		return

	_reward_quig_label.text = "Quig: \"There will be others.\""

	if _song_reward_pending:
		_show_feedback("REWARD PASSED", Color(0.76, 0.60, 0.42, 1.0), 0.24)
		_resume_song_after_reward()
	else:
		_reward_hint_label.text = "R restart run"
		controls_label.text = "Run complete  |  R restart run"
		_finish_run(true)


func _pass_reward() -> void:
	# Player opts out of the current reward offer.
	# Fires when the player presses N — also the only valid action when DNA-locked.
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	_reward_choice_made = true
	_awaiting_reward_choice = false
	_pending_reward_dna_locked = false
	_pending_reward_creature = {}

	_reward_creature_tag_label.text = "Passed"
	_reward_title_label.text = "Gone."
	_reward_body_label.text = "It will not return."
	_reward_bond_label.text = ""
	_reward_eat_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_quig_label.text = "Quig: \"It won't be back.\""
	_reward_hint_label.text = "..."
	controls_label.text = ""

	if _song_reward_pending:
		_show_feedback("REWARD PASSED", Color(0.76, 0.60, 0.42, 1.0), 0.24)
		_resume_song_after_reward()
	else:
		_reward_hint_label.text = "R restart run"
		controls_label.text = "Run complete  |  R restart run"
		_finish_run(true)


func _on_combo_changed(count: int, _tier: String) -> void:
	combo_label.text = "%d" % count


func _on_style_changed(score: float, tier: String) -> void:
	style_label.text = tier.capitalize()


func _on_dna_gained(_species_id: String, _amount: float, _total: float) -> void:
	_refresh_dna_hud()
	if _song_reward_pending and _awaiting_reward_choice:
		_pending_reward_dna_locked = not GameState.has_dna_for(
			String(_pending_reward_creature.get("species_id", "")),
			float(_pending_reward_creature.get("dna_threshold", 0.0))
		)
		_refresh_live_reward_shell()
		_refresh_song_controls_text()


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


func _on_player_took_damage(_amount: float, source_lane: int) -> void:
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	if _hp_value_label != null:
		_hp_value_label.text = "%d/%d" % [int(GameState.player_hp), int(GameState.player_max_hp)]
	# Pale Shelf: hits feel clinical and punishing — "EXPOSED" in cold blue, harder flash.
	# All other regions: standard warm "STRUCK".
	if _region_id == "pale_shelf":
		_show_feedback("EXPOSED", Color(0.72, 0.76, 0.96, 1.0), 0.48)
		_presentation_runtime.highlight_timing_ring(source_lane, Color(0.65, 0.72, 0.98, 1.0), 5.0)
		_flash_meter_shell(Color(0.18, 0.18, 0.38, 0.96), 0.22)
		EventBus.emit_signal("screen_flash", Color(0.38, 0.40, 0.62, 0.18), 0.28)
	else:
		_show_feedback("STRUCK", Color(0.96, 0.44, 0.40, 1.0), 0.34)
		_presentation_runtime.highlight_timing_ring(source_lane, Color(1.0, 0.25, 0.25, 1.0), 5.0)
		_flash_meter_shell(Color(0.42, 0.10, 0.11, 0.94), 0.18)


func _on_player_healed(_amount: float) -> void:
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	if _hp_value_label != null:
		_hp_value_label.text = "%d/%d" % [int(GameState.player_hp), int(GameState.player_max_hp)]
	_show_feedback("MEND", Color(0.70, 0.96, 0.84, 1.0), 0.26)
	_flash_meter_shell(Color(0.11, 0.22, 0.17, 0.92), 0.10)


func _on_ultimate_available() -> void:
	ultimate_label.text = "Ready"
	_show_feedback("READY", Color(1.0, 0.85, 0.35, 1.0), 0.45)
	_flash_meter_shell(Color(0.30, 0.21, 0.10, 0.94), 0.20)


func _on_ultimate_fired(_power: float) -> void:
	ultimate_label.text = "0%"
	var tier: String = combat_meter.get_current_tier()
	var ult_text: String = "DEVOUR"
	if tier == "sovereign":
		ult_text = "SOVEREIGN DEVOUR"
	elif tier == "apex":
		ult_text = "APEX STRIKE"
	_show_feedback(ult_text, Color(1.0, 0.72, 0.25, 1.0), 0.50)
	var bq: String = _get_beat_quality_for_action()
	if bq == "perfect":
		_show_beat_feedback("PERFECT DROP", Color(1.0, 0.88, 0.40, 1.0))
	elif bq == "good":
		_show_beat_feedback("ON THE DROP", Color(0.92, 0.80, 0.36, 1.0))
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
	var is_boss_target: bool = _is_boss_encounter and _enemy_phase_by_id.has(enemy_id)
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
		# One-shot mid-fight escalation at 50% total HP.
		# Fires during phase 1 or 2 — whichever the blow lands in.
		if not _boss_hp_threshold_fired and _boss_total_hp > 0.0 and (_boss_current_hp / _boss_total_hp) <= 0.5:
			_boss_hp_threshold_fired = true
			_show_feedback("SOVEREIGN UNLEASH", Color(0.92, 0.42, 0.12, 1.0), 0.70)
			_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_boss_threshold_profile())
			_trigger_boss_threshold_spectacle()
			# State 3: tightest cadence - 0.60 s cycle, 0.44 stagger. Projectiles cluster hard.
			lane_manager.set_cycle_interval(0.60)
			lane_manager.set_fire_stagger(0.44)

	_spawn_damage_number(enemy_id, damage)
	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_enemy_hit_profile(damage, is_boss_target), lane, enemy_id)


func _spawn_damage_number(enemy_id: int, damage: float) -> void:
	var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
		return
	var start_pos: Vector2 = marker.position + Vector2(6.0, -18.0)
	var lbl := Label.new()
	lbl.text = "%.0f" % damage
	lbl.position = start_pos
	lbl.z_index = 10
	UI_STYLE.apply_label(lbl, "caption_strong")
	_enemy_marker_container.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position:y", start_pos.y - 30.0, 0.6)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(lbl.queue_free)


func _on_enemy_defeated(enemy_id: int) -> void:
	var kill_heal_effect: Dictionary = _get_growth_effect("heal_on_kill")
	if not kill_heal_effect.is_empty():
		var healed: float = GameState.heal_player(float(kill_heal_effect.get("value", 0.0)))
		if healed > 0.0:
			EventBus.emit_signal("player_healed", healed)
	_remove_enemy_marker(enemy_id)

	# Region-specific kill momentum feedback (song mode only).
	# Feeding Hollow: every kill pulses the predator identity.
	# Pale Shelf: silence — deaths feel hollow, not celebrated.
	# Drowned Cut: resonate the kill through the bond layer.
	if _song_mode and not _song_paused and not _song_boss_triggered:
		match _region_id:
			"feeding_hollow":
				_show_beat_feedback("FLESH", Color(0.88, 0.28, 0.18, 1.0))
				EventBus.emit_signal("screen_flash", Color(0.35, 0.05, 0.05, 0.05), 0.05)
			"drowned_cut":
				_show_beat_feedback("RESONANCE", Color(0.48, 0.88, 0.76, 1.0))
				EventBus.emit_signal("screen_flash", Color(0.10, 0.38, 0.32, 0.05), 0.05)

	# DNA economy: creature encounters now pay out the species you actually killed.
	# Fallback to the phase reward pool only if a legacy enemy payload has no species id.
	if _song_mode and not _song_boss_triggered and _song_phase_index >= 0 and _song_phase_index < _song_phases.size():
		var defeated_enemy: Dictionary = _all_enemies_by_id.get(enemy_id, {})
		var dna_species: String = String(defeated_enemy.get("reward_species_id", defeated_enemy.get("species_id", "")))
		var dna_amount: float = float(defeated_enemy.get("dna_reward", DNA_PER_KILL))
		if dna_species.is_empty():
			var _dna_phase: Dictionary = _song_phases[_song_phase_index]
			var _dna_pool: Array = _dna_phase.get("reward_pool", [])
			if not _dna_pool.is_empty():
				dna_species = String(_dna_pool[_song_phase_dna_award_index % _dna_pool.size()])
				_song_phase_dna_award_index += 1
				dna_amount = DNA_PER_KILL
		if not dna_species.is_empty() and dna_amount > 0.0:
			GameState.add_dna(dna_species, dna_amount)
			EventBus.emit_signal("dna_gained", dna_species, dna_amount, GameState.get_dna(dna_species))
			_show_feedback("+%s DNA" % String(COMBAT_CONTENT.get_creature(dna_species).get("display_name", dna_species)).to_upper(), Color(0.62, 0.96, 0.78, 1.0), 0.22)

	if _song_mode and not _song_paused and not _song_boss_triggered:
		var dead_lane: int = _song_enemy_lanes.get(enemy_id, -1)
		if dead_lane >= 0:
			_song_enemy_lanes.erase(enemy_id)
			# Schedule a respawn in the same lane if the phase still has room.
			var respawn_lane: int = dead_lane
			get_tree().create_timer(0.40).timeout.connect(func() -> void:
				if _song_mode and not _song_paused and not _song_boss_triggered:
					var phase: Dictionary = _song_phases[_song_phase_index]
					var max_threats: int = int(phase.get("max_active_threats", 2))
					if lane_manager.alive_count() < max_threats:
						_place_song_enemy(respawn_lane)
			, CONNECT_ONE_SHOT)


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
		_presentation_runtime.highlight_timing_ring(lane, Color(1.0, 0.95, 0.55, 1.0), 5.0)
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(1.0, 0.92, 0.58, 0.55), 10.0, 0.12, 1.0)
		_flash_meter_shell(Color(0.25, 0.20, 0.10, 0.94), 0.12)
		# Beat quality bonus: on-beat timed attacks get richer feedback and a sharper flash.
		var bq: String = _get_beat_quality_for_action()
		if bq == "perfect":
			_show_beat_feedback("IN SYNC", Color(1.0, 0.95, 0.55, 1.0))
		elif bq == "good":
			_show_beat_feedback("ON BEAT", Color(0.88, 0.84, 0.52, 1.0))
	else:
		_show_feedback("HIT", Color(0.95, 0.95, 0.95, 1.0), 0.28)
		_presentation_runtime.highlight_timing_ring(lane, Color(0.95, 0.95, 0.95, 1.0), 4.0)
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.92, 0.92, 0.92, 0.35), 7.0, 0.10, 0.88)
		_flash_meter_shell(Color(0.16, 0.16, 0.17, 0.94), 0.08)


func _on_timed_attack_resolved(lane: int, quality: String, damage: float) -> void:
	var ravage_effect: Dictionary = _get_growth_effect("timed_attack_bonus_damage")
	var beat_quality: String = _get_beat_quality_for_action()
	var enemy_id: int = _get_enemy_id_for_lane(lane)
	if not ravage_effect.is_empty():
		var rip_damage: float = damage * float(ravage_effect.get("value", 0.0))
		lane_manager.damage_enemy(lane, rip_damage)
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.95, 0.48, 0.36, 0.34), 8.0, 0.08, 0.92)

	if quality == "good":
		var flow_effect: Dictionary = _get_growth_effect("good_timed_bonus_damage")
		if not flow_effect.is_empty():
			var flow_damage: float = damage * float(flow_effect.get("value", 0.0))
			lane_manager.damage_enemy(lane, flow_damage)

	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_timed_attack_profile(quality, beat_quality), lane, enemy_id)


func _on_player_parried(lane: int, quality: String, _reflect_damage: float) -> void:
	var bq: String = _get_beat_quality_for_action()
	var enemy_id: int = _get_enemy_id_for_lane(lane)
	if quality == "perfect":
		_show_feedback("PERFECT PARRY", Color(0.68, 1.0, 0.82, 1.0), 0.46)
		_presentation_runtime.highlight_timing_ring(lane, Color(0.68, 1.0, 0.82, 1.0), 7.0)
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.68, 1.0, 0.82, 0.72), 13.0, 0.18, 1.08)
		_flash_meter_shell(Color(0.12, 0.28, 0.20, 0.96), 0.20)
		# Beat quality: perfect parry on the beat is the highest-reward action in the game.
		# slow_motion is owned by PlayerCombat for parries; only show UI feedback here.
		if bq == "perfect":
			_show_beat_feedback("LOCKED IN", Color(0.68, 1.0, 0.82, 1.0))
		elif bq == "good":
			_show_beat_feedback("IN SYNC", Color(0.60, 0.94, 0.76, 1.0))
	else:
		_show_feedback("PARRY", Color(0.60, 0.94, 0.76, 1.0), 0.34)
		_presentation_runtime.highlight_timing_ring(lane, Color(0.60, 0.94, 0.76, 1.0), 5.6)
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.60, 0.94, 0.76, 0.54), 10.0, 0.14, 0.98)
		_flash_meter_shell(Color(0.11, 0.22, 0.18, 0.94), 0.14)
		if bq == "perfect" or bq == "good":
			_show_beat_feedback("ON BEAT", Color(0.60, 0.94, 0.76, 1.0))

	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_parry_profile(quality, bq), lane, enemy_id)


func _on_player_dodged(_from_lane: int, to_lane: int) -> void:
	_show_feedback("DODGE", Color(0.65, 0.85, 1.0, 1.0), 0.28)
	_presentation_runtime.highlight_timing_ring(to_lane, Color(0.65, 0.85, 1.0, 1.0), 4.0)
	var bq: String = _get_beat_quality_for_action()
	if bq == "perfect":
		_show_beat_feedback("SLIP", Color(0.65, 0.85, 1.0, 1.0))
		EventBus.emit_signal("screen_flash", Color(0.50, 0.70, 1.0, 0.05), 0.04)
	elif bq == "good":
		_show_beat_feedback("SLIP", Color(0.55, 0.75, 0.92, 1.0))


func _on_player_no_stamina() -> void:
	_show_feedback("NO STAMINA", Color(1.0, 0.45, 0.45, 1.0), 0.42)
	_flash_meter_shell(Color(0.28, 0.11, 0.11, 0.92), 0.12)


func _on_combo_broken(_lost: int) -> void:
	_show_feedback("BROKEN", Color(1.0, 0.4, 0.4, 1.0), 0.40)


func _on_run_growth_changed(level: int, exp: float, exp_to_next: float) -> void:
	if _exp_value_label != null:
		_exp_value_label.text = "L%d  %.0f/%.0f" % [level, exp, exp_to_next]
	_refresh_run_build_readout()


func _on_tendency_growth_resolved(tendency_id: String, title: String, summary: String) -> void:
	_refresh_run_build_readout()
	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_tendency_surge_profile(tendency_id))
	var color: Color = Color(0.92, 0.86, 0.70, 1.0)
	match tendency_id:
		"aggression":
			color = Color(0.96, 0.56, 0.30, 1.0)
		"cadence":
			color = Color(0.94, 0.86, 0.40, 1.0)
		"guard":
			color = Color(0.74, 0.92, 1.0, 1.0)
		"bond":
			color = Color(0.74, 0.96, 0.82, 1.0)
	_show_feedback(title, color, 0.42)
	_quig_anchor_label.text = summary
	_quig_anchor_label.visible = true
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(_quig_anchor_label, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void:
		_quig_anchor_label.visible = false
		_quig_anchor_label.modulate.a = 1.0
	)


func _on_support_charge_changed(current: float, maximum: float, active_species_id: String) -> void:
	if _support_bar != null:
		_support_bar.max_value = maximum
		_support_bar.value = current

	if _support_value_label != null:
		if active_species_id.is_empty():
			_support_value_label.text = "--"
		elif current >= maximum:
			_support_value_label.text = "Ready"
		else:
			_support_value_label.text = "%d%%" % int(round((current / maximum) * 100.0))

	if _support_name_label != null:
		if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_active_display_name"):
			var display_name: String = String(_run_growth.call("get_active_display_name"))
			_support_name_label.text = display_name
		else:
			_support_name_label.text = "No bond"

	# Creature portrait: load only when the active species changes.
	if _support_creature_portrait != null:
		if active_species_id != _support_portrait_species:
			_support_portrait_species = active_species_id
			if not active_species_id.is_empty():
				var portrait_path: String = COMBAT_CONTENT.get_creature_sprite_path(active_species_id)
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
		if active_species_id.is_empty():
			_support_trigger_label.text = ""
		else:
			var support_role: Dictionary = COMBAT_CONTENT.get_support_role(active_species_id)
			_support_trigger_label.text = _describe_trigger_hint(String(support_role.get("effect_id", "")))

	if _support_shell != null:
		var shell_color: Color = Color(0.08, 0.08, 0.10, 0.56)
		if not active_species_id.is_empty() and current >= maximum:
			shell_color = Color(0.10, 0.12, 0.11, 0.72)
		_support_shell.color = shell_color
	_refresh_bonded_creature_render(active_species_id)
	_refresh_run_build_readout()


func _refresh_bonded_creature_render(active_species_id: String = "") -> void:
	if _bonded_creature_sprite == null or lane_manager == null:
		return

	var species_id: String = active_species_id
	if species_id.is_empty() and _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_active_species_id"):
		species_id = String(_run_growth.call("get_active_species_id"))

	if species_id.is_empty():
		_bonded_creature_species = ""
		_bonded_creature_sprite.visible = false
		_bonded_creature_sprite.texture = null
		return

	var sprite_path: String = COMBAT_CONTENT.get_creature_sprite_path(species_id)
	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		_bonded_creature_species = species_id
		_bonded_creature_sprite.visible = false
		_bonded_creature_sprite.texture = null
		return

	if species_id != _bonded_creature_species:
		var render_tex: Texture2D = load(sprite_path) as Texture2D
		if render_tex == null:
			_bonded_creature_sprite.visible = false
			_bonded_creature_sprite.texture = null
			return
		_bonded_creature_species = species_id
		_bonded_creature_sprite.texture = render_tex

	var render_config: Dictionary = COMBAT_CONTENT.get_creature_combat_render(species_id)
	var world_offset: Vector2 = render_config.get("world_offset", Vector2(-108.0, 74.0))
	var render_scale: float = float(render_config.get("scale", 0.052))
	var render_modulate: Color = render_config.get("modulate", Color(0.90, 0.89, 0.86, 0.86))
	var render_z: int = int(render_config.get("z_index", 5))
	_bonded_creature_sprite.position = Vector2(
		lane_manager.get_player_x() + world_offset.x,
		lane_manager.get_lane_y(1) + world_offset.y
	)
	_bonded_creature_sprite.scale = Vector2.ONE * render_scale
	_bonded_creature_sprite.modulate = render_modulate
	_bonded_creature_sprite.z_index = render_z
	_bonded_creature_sprite.visible = true


func _apply_song_phase_cadence(phase: Dictionary, spawn_mult: float = 1.0) -> void:
	var base_interval: float = float(phase.get("cycle_interval", 2.2))
	var base_stagger: float = float(phase.get("fire_stagger", 0.45))
	lane_manager.set_cycle_interval(base_interval * spawn_mult)
	lane_manager.set_fire_stagger(base_stagger)


func _clear_mastery_context_cache() -> void:
	_last_mastery_context.clear()


func _on_mastery_context_updated(data: Dictionary) -> void:
	_last_mastery_context = data.duplicate(true)


func _get_mastery_window() -> String:
	# Returns the current phrase-depth tier for support mastery branching.
	# Phrase count accumulates through consecutive quality (good/perfect) actions.
	# "flow_state" = 8+ actions; "in_pocket" = 5+; "" = below threshold (no enhancement).
	var count: int = combat_meter.phrase_count
	if count >= 8:
		return "flow_state"
	if count >= 5:
		return "in_pocket"
	return ""


func _get_current_cadence_window() -> String:
	if _song_conductor == null or not is_instance_valid(_song_conductor):
		return ""
	var section_id: String = String(_song_conductor.get("current_section_id"))
	var intensity: float = float(_song_conductor.get("current_intensity"))
	if section_id == "final" or intensity >= 0.85:
		return "surge"
	if section_id == "chorus" or intensity >= 0.62:
		return "drive"
	return ""


func _build_support_mastery_context(effect_id: String, lane: int) -> Dictionary:
	var context: Dictionary = {
		"source_event": "",
		"lane": lane,
		"action_quality": "",
		"beat_quality": "off",
		"phrase_window": _get_mastery_window(),
		"cadence_window": _get_current_cadence_window(),
		"is_recent": false,
		"window_id": ""
	}
	if not _last_mastery_context.is_empty():
		var now: float = Time.get_ticks_msec() / 1000.0
		var age: float = now - float(_last_mastery_context.get("timestamp", -999.0))
		if age <= SUPPORT_MASTERY_CONTEXT_TIMEOUT:
			context["source_event"] = String(_last_mastery_context.get("event_id", ""))
			context["lane"] = int(_last_mastery_context.get("lane", lane))
			context["action_quality"] = String(_last_mastery_context.get("action_quality", ""))
			context["beat_quality"] = String(_last_mastery_context.get("beat_quality", "off"))
			context["phrase_window"] = String(_last_mastery_context.get("phrase_window", context["phrase_window"]))
			context["cadence_window"] = String(_last_mastery_context.get("cadence_window", context["cadence_window"]))
			context["is_recent"] = true

	var phrase_window: String = String(context.get("phrase_window", ""))
	var cadence_window: String = String(context.get("cadence_window", ""))
	var action_quality: String = String(context.get("action_quality", ""))
	var beat_quality: String = String(context.get("beat_quality", "off"))
	var precision: bool = action_quality == "perfect" and (beat_quality == "perfect" or beat_quality == "good")

	if precision and cadence_window == "surge" and (phrase_window == "flow_state" or phrase_window == "in_pocket"):
		context["window_id"] = "cadence_surge"
	elif phrase_window == "flow_state":
		context["window_id"] = "flow_state"
	elif phrase_window == "in_pocket":
		context["window_id"] = "in_pocket"
	elif precision and cadence_window == "drive" and effect_id == "thornback_rend":
		context["window_id"] = "in_pocket"

	return context


func _on_bonded_support_triggered(_species_id: String, lane: int, effect_id: String) -> void:
	var support_role: Dictionary = _get_support_role_for_effect(effect_id)
	var combo_mult: float = combat_meter.damage_multiplier()
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	var bond_mult: float = GameState.get_bond_level_mult(int(active_creature.get("bond_level", 1)))
	var mastery_context: Dictionary = _build_support_mastery_context(effect_id, lane)
	var mastery: String = String(mastery_context.get("window_id", ""))
	var cadence_surge: bool = mastery == "cadence_surge"
	var support_profile: Dictionary = COMBAT_IMPACT_FEEDBACK.build_support_profile(effect_id, cadence_surge)
	var support_enemy_id: int = _get_enemy_id_for_lane(lane)
	if effect_id == "bond_remnant_mend" or effect_id == "gruvek_gorge" or effect_id == "marrowward_ward" or effect_id == "gorefane_maul":
		support_enemy_id = -1

	# HOLLOW amplifier: when Bond Remnant is the active creature, REND gets one extra charge
	# and EXPOSE lasts 0.5 s longer. Mastery windows stack on top of this.
	var is_hollow_active: bool = String(active_creature.get("species_id", "")) == "bond_remnant"
	var rend_charges: int = 4 if is_hollow_active else 3
	var expose_duration: float = 3.0 if is_hollow_active else 2.5
	if cadence_surge:
		_show_beat_feedback("CADENCE SURGE", Color(1.0, 0.88, 0.42, 1.0))

	match effect_id:
		"ashclaw_strike":
			var strike_damage: float = float(support_role.get("effect_value", 10.0)) * combo_mult * bond_mult
			var expose_time: float = expose_duration
			if cadence_surge:
				strike_damage *= 1.35
				expose_time += 1.0
			lane_manager.damage_enemy(lane, strike_damage)
			lane_manager.apply_status(lane, "expose", {"duration": expose_time})
			# Mastery window: in_pocket adds REND (1 charge) on top of EXPOSE — the claw tears
			# deeper when triggered through sustained precision. flow_state escalates to 2 charges.
			if cadence_surge:
				lane_manager.apply_status(lane, "rend", {"charges": rend_charges + 1})
				_show_feedback("ASHCLAW SURGE", Color(1.0, 0.58, 0.18, 1.0), 0.46)
			elif mastery == "flow_state":
				lane_manager.apply_status(lane, "rend", {"charges": rend_charges - 1})
				_show_feedback("ASHCLAW REND", Color(1.0, 0.52, 0.22, 1.0), 0.44)
			elif mastery == "in_pocket":
				lane_manager.apply_status(lane, "rend", {"charges": 1})
				_show_feedback("ASHCLAW TEARS", Color(0.98, 0.56, 0.30, 1.0), 0.40)
			else:
				_show_feedback(String(support_role.get("feedback_text", "ASHCLAW")), Color(0.95, 0.60, 0.42, 1.0), 0.36)
			_presentation_runtime.highlight_timing_ring(lane, Color(0.92, 0.56, 0.38, 1.0), 7.0)
			_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.95, 0.60, 0.42, 0.72), 16.0, 0.14, 1.18)
			_flash_meter_shell(Color(0.25, 0.12, 0.10, 0.92), 0.10)
		"bond_remnant_mend":
			var base_heal: float = float(support_role.get("effect_value", 6.0)) * bond_mult
			# Mastery window: in_pocket adds a stamina pulse (precision earns recovery).
			# flow_state heals more deeply and restores more stamina.
			var heal_amount: float = base_heal
			var stamina_restore: float = 0.0
			var mend_text: String = String(support_role.get("feedback_text", "REMNANT"))
			var mend_color: Color = Color(0.72, 0.96, 0.88, 1.0)
			if cadence_surge:
				heal_amount = base_heal * 1.85
				stamina_restore = 28.0
				mend_text = "SURGE MEND"
				mend_color = Color(0.64, 1.0, 0.86, 1.0)
			elif mastery == "flow_state":
				heal_amount = base_heal * 1.5
				stamina_restore = 20.0
				mend_text = "DEEP MEND"
				mend_color = Color(0.60, 1.0, 0.82, 1.0)
			elif mastery == "in_pocket":
				stamina_restore = 12.0
				mend_text = "MEND PULSE"
				mend_color = Color(0.66, 0.98, 0.86, 1.0)
			var healed: float = GameState.heal_player(heal_amount)
			if healed > 0.0:
				EventBus.emit_signal("player_healed", healed)
			if stamina_restore > 0.0:
				combat_meter.restore_stamina(stamina_restore)
			_show_feedback(mend_text, mend_color, 0.28)
			_presentation_runtime.highlight_timing_ring(lane, Color(0.68, 0.94, 0.84, 1.0), 4.8)
			_flash_meter_shell(Color(0.12, 0.22, 0.18, 0.92), 0.10)
		"gruvek_gorge":
			var gorge_damage: float = float(support_role.get("effect_value", 10.0)) * combo_mult * bond_mult
			if cadence_surge:
				gorge_damage *= 1.18
			for check_lane in range(3):
				lane_manager.damage_enemy(check_lane, gorge_damage)
			# Apply GORGE-MARK to surviving enemies after gorge damage resolves.
			for check_lane in range(3):
				var surviving: Dictionary = lane_manager.get_enemy(check_lane)
				if surviving.has("hp") and float(surviving["hp"]) > 0.0:
					lane_manager.apply_status(check_lane, "gorge_mark", {})
			if cadence_surge:
				var gorge_healed: float = GameState.heal_player(6.0 * bond_mult)
				if gorge_healed > 0.0:
					EventBus.emit_signal("player_healed", gorge_healed)
				_show_feedback("FEAST WAVE", Color(0.94, 0.58, 0.18, 1.0), 0.42)
			else:
				_show_feedback(String(support_role.get("feedback_text", "GORGE")), Color(0.90, 0.52, 0.22, 1.0), 0.38)
			for check_lane in range(3):
				_presentation_runtime.highlight_timing_ring(check_lane, Color(0.88, 0.50, 0.20, 1.0), 6.0)
				_presentation_runtime.spawn_attack_silhouette_to_lane(check_lane, Color(0.90, 0.52, 0.22, 0.55), 11.0, 0.10, 1.05)
			_flash_meter_shell(Color(0.28, 0.14, 0.08, 0.92), 0.12)
		"veilskin_phase":
			var phase_damage: float = float(support_role.get("effect_value", 12.0)) * bond_mult
			if cadence_surge:
				phase_damage *= 1.20
			lane_manager.damage_enemy(lane, phase_damage)
			# Mastery window: flow_state applies PALE to all 3 lanes — a full battlefield
			# disruption instead of a single-lane nerf. in_pocket adds extra stamina.
			var stamina_amount: float = 25.0
			var phase_text: String = String(support_role.get("feedback_text", "PHASE"))
			if cadence_surge:
				for pale_lane in range(3):
					lane_manager.apply_status(pale_lane, "pale", {})
				stamina_amount = 40.0
				phase_text = "VEIL CASCADE"
			elif mastery == "flow_state":
				for pale_lane in range(3):
					lane_manager.apply_status(pale_lane, "pale", {})
				stamina_amount = 35.0
				phase_text = "FULL PHASE"
			elif mastery == "in_pocket":
				lane_manager.apply_status(lane, "pale", {})
				stamina_amount = 32.0
				phase_text = "CLEAN PHASE"
			else:
				lane_manager.apply_status(lane, "pale", {})
			combat_meter.restore_stamina(stamina_amount)
			_show_feedback(phase_text, Color(0.78, 0.92, 1.0, 1.0), 0.36)
			for ring_lane in range(3):
				_presentation_runtime.highlight_timing_ring(ring_lane, Color(0.72, 0.88, 1.0, 1.0), 5.5)
			_flash_meter_shell(Color(0.10, 0.18, 0.26, 0.92), 0.10)
		"knellspine_peal":
			var peal_damage: float = float(support_role.get("effect_value", 8.0)) * combo_mult * bond_mult
			var charge_return: float = 18.0
			var peal_text: String = String(support_role.get("feedback_text", "PEAL"))
			if cadence_surge:
				peal_damage *= 1.25
				charge_return = 28.0
				lane_manager.apply_status(lane, "expose", {"duration": 3.0})
				peal_text = "SURGE PEAL"
			elif mastery == "flow_state":
				charge_return = 24.0
				lane_manager.apply_status(lane, "expose", {"duration": 2.5})
				peal_text = "DEEP PEAL"
			lane_manager.damage_enemy(lane, peal_damage)
			if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("gain_support_charge_direct"):
				_run_growth.call("gain_support_charge_direct", charge_return)
			_show_feedback(peal_text, Color(0.98, 0.82, 0.34, 1.0), 0.34)
			_presentation_runtime.highlight_timing_ring(lane, Color(1.0, 0.84, 0.42, 1.0), 6.2)
			_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.98, 0.82, 0.34, 0.68), 14.0, 0.12, 1.12)
			_flash_meter_shell(Color(0.24, 0.18, 0.08, 0.92), 0.10)
		"marrowward_ward":
			var ward_heal: float = float(support_role.get("effect_value", 8.0)) * bond_mult
			var ward_stamina: float = 18.0
			var ward_text: String = String(support_role.get("feedback_text", "WARD"))
			for pale_lane in range(3):
				lane_manager.apply_status(pale_lane, "pale", {})
			if cadence_surge:
				ward_heal *= 1.5
				ward_stamina = 32.0
				ward_text = "FULL WARD"
			elif mastery == "flow_state":
				ward_heal *= 1.25
				ward_stamina = 24.0
				ward_text = "BONE WARD"
			var ward_restored: float = GameState.heal_player(ward_heal)
			if ward_restored > 0.0:
				EventBus.emit_signal("player_healed", ward_restored)
			combat_meter.restore_stamina(ward_stamina)
			_show_feedback(ward_text, Color(0.78, 0.92, 0.82, 1.0), 0.34)
			for ring_lane in range(3):
				_presentation_runtime.highlight_timing_ring(ring_lane, Color(0.78, 0.92, 0.82, 1.0), 5.4)
			_flash_meter_shell(Color(0.12, 0.18, 0.14, 0.92), 0.10)
		"gorefane_maul":
			var maul_damage: float = float(support_role.get("effect_value", 14.0)) * combo_mult * bond_mult
			var maul_charges: int = 1
			var maul_text: String = String(support_role.get("feedback_text", "MAUL"))
			if cadence_surge:
				maul_damage *= 1.22
				maul_charges = 3
				maul_text = "FEAST MAUL"
			elif mastery == "flow_state":
				maul_charges = 2
				maul_text = "RIP MAUL"
			for check_lane in range(3):
				lane_manager.damage_enemy(check_lane, maul_damage)
			for check_lane in range(3):
				var maul_enemy: Dictionary = lane_manager.get_enemy(check_lane)
				if maul_enemy.has("hp") and float(maul_enemy["hp"]) > 0.0:
					lane_manager.apply_status(check_lane, "rend", {"charges": maul_charges})
			_show_feedback(maul_text, Color(0.96, 0.44, 0.20, 1.0), 0.40)
			for check_lane in range(3):
				_presentation_runtime.highlight_timing_ring(check_lane, Color(0.98, 0.48, 0.22, 1.0), 6.8)
				_presentation_runtime.spawn_attack_silhouette_to_lane(check_lane, Color(0.96, 0.44, 0.20, 0.62), 15.0, 0.14, 1.10)
			_flash_meter_shell(Color(0.30, 0.12, 0.08, 0.92), 0.12)
		"hushcoil_lull":
			var lull_damage: float = float(support_role.get("effect_value", 7.0)) * combo_mult * bond_mult
			var lull_text: String = String(support_role.get("feedback_text", "LULL"))
			lane_manager.damage_enemy(lane, lull_damage)
			for pale_lane in range(3):
				lane_manager.apply_status(pale_lane, "pale", {})
			if cadence_surge:
				lane_manager.apply_status(lane, "expose", {"duration": 3.0})
				combat_meter.restore_stamina(18.0)
				lull_text = "DEAD LULL"
			elif mastery == "flow_state":
				lane_manager.apply_status(lane, "expose", {"duration": 2.5})
				lull_text = "DEEP LULL"
			_show_feedback(lull_text, Color(0.72, 0.82, 0.98, 1.0), 0.34)
			for ring_lane in range(3):
				_presentation_runtime.highlight_timing_ring(ring_lane, Color(0.68, 0.80, 0.98, 1.0), 5.8)
			_flash_meter_shell(Color(0.10, 0.14, 0.24, 0.92), 0.10)
		"thornback_rend":
			var rend_damage: float = float(support_role.get("effect_value", 20.0)) * combo_mult * bond_mult
			if cadence_surge:
				rend_damage *= 1.25
			lane_manager.damage_enemy(lane, rend_damage)
			# Mastery window: each tier adds rend charges — more hits at +30% damage.
			# flow_state adds 2 charges; in_pocket adds 1.
			var mastery_charges: int = rend_charges
			var rend_text: String = String(support_role.get("feedback_text", "REND"))
			var rend_color: Color = Color(0.96, 0.75, 0.38, 1.0)
			if cadence_surge:
				mastery_charges = rend_charges + 3
				rend_text = "THORNBURST"
				rend_color = Color(1.0, 0.84, 0.24, 1.0)
			elif mastery == "flow_state":
				mastery_charges = rend_charges + 2
				rend_text = "REND SURGE"
				rend_color = Color(1.0, 0.82, 0.28, 1.0)
			elif mastery == "in_pocket":
				mastery_charges = rend_charges + 1
				rend_text = "DEEP REND"
				rend_color = Color(0.98, 0.78, 0.32, 1.0)
			lane_manager.apply_status(lane, "rend", {"charges": mastery_charges})
			_show_feedback(rend_text, rend_color, 0.36)
			_presentation_runtime.highlight_timing_ring(lane, Color(0.94, 0.72, 0.34, 1.0), 7.5)
			_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.96, 0.75, 0.38, 0.78), 18.0, 0.16, 1.22)
			_flash_meter_shell(Color(0.28, 0.16, 0.08, 0.92), 0.10)
		_:
			return

	_presentation_runtime.apply_impact_profile(support_profile, lane, support_enemy_id)

	# Pack Signal upgrade: heal on every support trigger.
	var pack_heal_effect: Dictionary = _get_growth_effect("support_trigger_heal")
	if not pack_heal_effect.is_empty():
		var pack_healed: float = GameState.heal_player(float(pack_heal_effect.get("value", 0.0)))
		if pack_healed > 0.0:
			EventBus.emit_signal("player_healed", pack_healed)


func _on_phrase_milestone(count: int) -> void:
	# Consecutive quality action chain announcements.
	if count >= 8:
		_show_beat_feedback("FLOW STATE", Color(1.0, 0.88, 0.40, 1.0))
		EventBus.emit_signal("screen_flash", Color(0.60, 0.50, 0.12, 0.08), 0.06)
	elif count == 5:
		_show_beat_feedback("IN THE POCKET", Color(0.95, 0.82, 0.38, 1.0))
		EventBus.emit_signal("screen_flash", Color(0.50, 0.42, 0.10, 0.06), 0.05)
	elif count == 3:
		_show_beat_feedback("PHRASE", Color(0.88, 0.78, 0.36, 1.0))


func _on_tier_changed(new_tier: String, _old_tier: String) -> void:
	# Combat tier escalation announcements.
	match new_tier:
		"sovereign":
			_show_feedback("SOVEREIGN", Color(1.0, 0.88, 0.35, 1.0), 0.60)
			EventBus.emit_signal("screen_flash", Color(0.70, 0.55, 0.10, 0.14), 0.12)
			EventBus.emit_signal("screen_shake", 3.0, 0.18)
		"apex":
			_show_feedback("APEX", Color(0.95, 0.72, 0.28, 1.0), 0.50)
			EventBus.emit_signal("screen_flash", Color(0.55, 0.38, 0.08, 0.10), 0.08)
		"rampage":
			_show_feedback("RAMPAGE", Color(0.90, 0.55, 0.22, 1.0), 0.40)
		"hunting":
			_show_beat_feedback("HUNTING", Color(0.85, 0.58, 0.25, 1.0))


func _get_enemy_id_for_lane(lane: int) -> int:
	var enemy: Dictionary = lane_manager.get_enemy(lane)
	if enemy.is_empty():
		return -1
	return int(enemy.get("id", -1))


func _on_enemy_status_applied(lane: int, status_id: String) -> void:
	# Updates the enemy marker color to reflect the new status.
	# "gorge_mark_triggered" fires when a marked enemy dies — show FEAST feedback.
	if status_id == "gorge_mark_triggered":
		_show_feedback("FEAST", Color(0.92, 0.60, 0.20, 1.0), 0.36)
		return

	var enemy_id: int = _get_enemy_id_for_lane(lane)
	if enemy_id < 0:
		return
	var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
		return

	match status_id:
		"rend":
			_status_marker_overrides[enemy_id] = Color(0.80, 0.22, 0.10, 0.92)
			_show_feedback("REND", Color(0.94, 0.40, 0.24, 1.0), 0.30)
		"pale":
			_status_marker_overrides[enemy_id] = Color(0.40, 0.42, 0.58, 0.70)
			_show_feedback("PALE", Color(0.74, 0.78, 0.96, 1.0), 0.28)
		"gorge_mark":
			_status_marker_overrides[enemy_id] = Color(0.72, 0.50, 0.10, 0.88)
			# No feedback — gorge already showed "GORGE".
		"expose":
			_status_marker_overrides[enemy_id] = Color(0.84, 0.70, 0.12, 0.92)
			_show_feedback("EXPOSED", Color(0.96, 0.88, 0.44, 1.0), 0.32)
		_:
			return

	marker.color = _status_marker_overrides[enemy_id]


func _on_enemy_status_cleared(lane: int) -> void:
	# Resets the enemy marker color to its biome-based color when a status expires or is consumed.
	var enemy_id: int = _get_enemy_id_for_lane(lane)
	if enemy_id < 0:
		return
	_status_marker_overrides.erase(enemy_id)

	var marker: ColorRect = _enemy_markers_by_id.get(enemy_id, null)
	if marker == null or not is_instance_valid(marker):
		return

	var biome: Dictionary = _active_encounter.get("biome", {})
	var active_color: Color = biome.get("enemy_active_color", Color(0.76, 0.21, 0.21, 1.0))
	var inactive_color: Color = biome.get("enemy_inactive_color", Color(0.38, 0.18, 0.18, 0.55))
	var phase: int = int(_enemy_phase_by_id.get(enemy_id, -1))
	marker.color = active_color if phase == _current_phase_index else inactive_color


func _get_growth_effect(effect_type: String) -> Dictionary:
	if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_runtime_effect"):
		var runtime_effect: Dictionary = _run_growth.call("get_runtime_effect", effect_type)
		if not runtime_effect.is_empty():
			return runtime_effect
	return _get_legacy_upgrade_effect(effect_type)


func _get_legacy_upgrade_effect(effect_type: String) -> Dictionary:
	# Deprecated compatibility path for stale taken_upgrades data.
	# Real run growth now resolves through RunGrowth tendency effects.
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


func _remove_enemy_marker(enemy_id: int) -> void:
	_status_marker_overrides.erase(enemy_id)
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
