extends Node2D

# ─── ONREADY NODES ───────────────────────────────────────────────────────────
@onready var background: ColorRect = $Background
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var lane_manager: Node = $LaneManager
@onready var player_combat: Node2D = $PlayerCombat
@onready var combat_meter: Node = $CombatMeter
@onready var camera_2d: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UI

# ─── UI ELEMENTS ─────────────────────────────────────────────────────────────
@onready var combo_label: Label = $UI/ComboLabel
@onready var style_label: Label = $UI/StyleLabel
@onready var stamina_bar: ProgressBar = $UI/StaminaBar
@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var ultimate_label: Label = $UI/UltimateLabel
@onready var result_label: Label = $UI/ResultLabel
@onready var controls_label: Label = $UI/ControlsLabel

# ─── PRELOADS ────────────────────────────────────────────────────────────────
const COMBAT_CONTENT = preload("res://data/CombatContent.gd")
const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const AUDIO_CONTENT = preload("res://data/AudioContent.gd")
const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")
const ROUTE_CONTENT = preload("res://data/RouteContent.gd")
const RUN_PACING_CONTENT = preload("res://data/RunPacingContent.gd")
const TRICKY_SONGMAP = preload("res://data/song_maps/tricky_songmap.gd")
const SONG_CONDUCTOR_SCRIPT = preload("res://systems/SongConductor.gd")
const COMBAT_TRANSITION_STATE = preload("res://systems/CombatTransitionState.gd")
const COMBAT_IMPACT_FEEDBACK = preload("res://systems/CombatImpactFeedback.gd")
const COMBAT_PRESENTATION_RUNTIME = preload("res://systems/CombatPresentationRuntime.gd")
const COMBAT_PRESENTATION_CONTROLLER = preload("res://systems/CombatPresentationController.gd")
const ENCOUNTER_IDENTITY_RUNTIME = preload("res://systems/EncounterIdentityRuntime.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")
const COMBAT_AUDIO_PLAYER = preload("res://systems/CombatAudioPlayer.gd")
const ENCOUNTER_ESCALATION_DIRECTOR = preload("res://systems/EncounterEscalationDirector.gd")
const MUSIC_CONTROL_LAYER = preload("res://systems/MusicControlLayer.gd")
const DIFFICULTY_MODIFIER_DIRECTOR = preload("res://systems/DifficultyModifierDirector.gd")
const SUPPORT_EFFECT_RESOLVER = preload("res://systems/SupportEffectResolver.gd")
const PATH_RUN_PLAN = preload("res://systems/PathRunPlan.gd")
const POTENTIAL_GATE = preload("res://systems/PotentialGate.gd")

# ─── CONSTANTS ───────────────────────────────────────────────────────────────
const RUN_GROWTH_SCRIPT_PATH: String = "res://systems/RunGrowth.gd"
const PERFORMANCE_REWARD_DIRECTOR_SCRIPT_PATH: String = "res://systems/PerformanceRewardDirector.gd"
const RUN_STATS_SCRIPT_PATH: String = "res://systems/RunStats.gd"
const COMBAT_PERFORMANCE_HUD_SCENE: PackedScene = preload("res://scenes/ui/CombatPerformanceHUD.tscn")
const RUN_SPINE_SCENE: PackedScene = preload("res://scenes/ui/RunSpineScene.tscn")
const GROWTH_CHOICE_SCENE: PackedScene = preload("res://scenes/ui/GrowthChoiceIntersection.tscn")
const PREDATION_POOL = preload("res://systems/PredationPool.gd")
const ENEMY_LOW_HP_THRESHOLD: float = 0.25
const SUPPORT_MASTERY_CONTEXT_TIMEOUT: float = 1.75
const LIVE_REWARD_WINDOW: float = 10.0
const DNA_HUD_VISIBLE_SLOTS: int = 2
const DNA_PER_KILL: float = 2.5
const HUD_PANEL_VISIBLE_ALPHA_THRESHOLD: float = 0.08
const BOND_REMNANT_IDLE_HFRAMES: int = 6
const BOND_REMNANT_IDLE_VFRAMES: int = 4
const BOND_REMNANT_IDLE_FRAME_DURATION: float = 0.10

const COMBAT_HUD_PRESENTER = preload("res://systems/CombatHUDPresenter.gd")

# ─── STATE VARIABLES ─────────────────────────────────────────────────────────
var _base_time_scale: float = 1.0
var _slow_motion_gen: int = 0
var _ring_highlight_timers: Array[float] = [0.0, 0.0, 0.0]
var _surge_window_tendency: String = ""
var _surge_window_timer: float = 0.0

# ─── UI NODES (DYNAMICALLY CREATED) ──────────────────────────────────────────
var _hud_top_left_container: VBoxContainer = null
var _hud_top_left_panel: Control = null
var _hud_top_right_container: VBoxContainer = null
var _hud_top_right_panel: PanelContainer = null
var _hud_top_right_accent_host: Control = null
var _hud_right_stack: VBoxContainer = null
var _hud_bottom_container: HBoxContainer = null
var _feedback_label: Label = null
var _feedback_backing: ColorRect = null
var _title_card: Label = null
var _subtitle_card: Label = null
var _timing_circle_container: Node2D = null
var _timing_rings_cache: Array[Dictionary] = []
var _enemy_marker_container: Node2D = null
var _lane_marker_container: Node2D = null
var _texture_cache: Dictionary = {}
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
var _def_value_label: Label = null
var _quig_anchor_label: Label = null
var _quig_anchor_sprite: TextureRect = null
var _quig_shell: ColorRect = null
var _hp_value_label: Label = null
var _exp_value_label: Label = null
var _dna_route_label: Label = null
var _dna_route_shell: ColorRect = null
var _mutation_value_label: Label = null
var _run_score_label: Label = null
var _end_stats_label: Label = null
var _dna_shell: ColorRect = null
var _dna_emblem: TextureRect = null
var _dna_slot_labels: Array[Label] = []
var _battlefield_panel: ColorRect = null
var _battlefield_inner_panel: ColorRect = null
var _battlefield_left_shade: ColorRect = null
var _battlefield_right_shade: ColorRect = null
var _battlefield_top_trim: ColorRect = null
var _battlefield_bottom_trim: ColorRect = null
var _bg_sprite: Control = null
var _bonded_creature_sprite: Sprite2D = null
var _bonded_creature_species: String = ""
var _presentation_runtime: RefCounted = null
var _presentation_controller: Node = null
var _hud_presenter: RefCounted = null
var _combat_audio_player: Node = null
var _timing_debug_label: Label = null

# ─── REWARD OVERLAY ELEMENTS ─────────────────────────────────────────────────
var _reward_overlay: ColorRect = null
var _reward_wrapper_shell: PanelContainer = null
var _reward_panel: ColorRect = null
var _reward_title_label: Label = null
var _reward_body_label: Label = null
var _reward_quig_label: Label = null
var _reward_quig_sprite: TextureRect = null
var _reward_hint_label: Label = null
var _reward_bond_card: ColorRect = null
var _reward_eat_card: ColorRect = null
var _reward_bond_label: Label = null
var _reward_eat_label: Label = null
var _reward_bond_effect_label: Label = null
var _reward_eat_effect_label: Label = null
var _reward_creature_tag_label: Label = null
var _reward_creature_portrait: TextureRect = null
var _reward_body_scroll: ScrollContainer = null
var _reward_bond_effect_scroll: ScrollContainer = null
var _reward_eat_effect_scroll: ScrollContainer = null

# ─── UPGRADE CHOICE ELEMENTS ─────────────────────────────────────────────────
var _upgrade_overlay: ColorRect = null
var _upgrade_panel: ColorRect = null
var _upgrade_card_nodes: Array[ColorRect] = []
var _upgrade_choice_labels: Array[Label] = []
var _awaiting_upgrade_choice: bool = false
var _pending_upgrades: Array[Dictionary] = []
var _pending_predation: Array[Dictionary] = []
var _pending_path_choice_nodes: Array[Dictionary] = []
var _pending_path_choice_level_index: int = -1
var _active_path_node: Dictionary = {}
var _active_path_context: Dictionary = {}

var _run_spine_surface: Node = null
var _growth_choice_surface: Node = null
var _growth_choice_context: Dictionary = {}
# Legacy between-level overlay vars retained for non-song upgrade flow compatibility.
var _run_prep_overlay: ColorRect = null
var _run_prep_panel: ColorRect = null
var _run_prep_scroll: ScrollContainer = null
var _run_prep_body_label: Label = null
var _run_prep_next_label: Label = null
var _awaiting_run_prep: bool = false
var _run_prep_dest_is_boss: bool = false

# ─── LIVE REWARD ELEMENTS ────────────────────────────────────────────────────
var _live_reward_shell: PanelContainer = null
var _live_reward_title_label: Label = null
var _live_reward_body_label: Label = null
var _live_reward_hint_label: Label = null
var _live_reward_queue: Array[Dictionary] = []
var _live_reward_offer_timer: float = 0.0

# ─── RUNTIME REQUISITES ──────────────────────────────────────────────────────
var _combat_finished: bool = false
var _phase_transitioning: bool = false
var _awaiting_reward_choice: bool = false
var _reward_choice_made: bool = false
var _run_finished: bool = false
var _pending_reward_creature: Dictionary = {}
var _pending_reward_dna_locked: bool = false
var _performance_reward_director: Node = null
var _performance_hud: Control = null
var _quig_tween: Tween = null
var _encounter_load_gen: int = 0
var _active_encounter: Dictionary = {}
var _current_phase_index: int = 0
var _run_growth: Node = null
var _run_stats: Node = null

# ─── ENEMY TRACKING ──────────────────────────────────────────────────────────
var _enemy_markers_by_id: Dictionary = {}
var _all_enemies_by_id: Dictionary = {}
var _enemy_max_hp: Dictionary = {}
var _status_marker_overrides: Dictionary = {}
var _enemy_phase_by_id: Dictionary = {}

# ─── BOSS STATE ──────────────────────────────────────────────────────────────
var _is_boss_encounter: bool = false
var _boss_total_hp: float = 0.0
var _boss_current_hp: float = 0.0
var _boss_hp_shell: ColorRect = null
var _boss_hp_bar: ProgressBar = null
var _boss_name_label: Label = null
var _boss_state_label: Label = null

# ─── LANE VISUALS ────────────────────────────────────────────────────────────
var _lane_strips: Dictionary = {}
var _lane_hit_focus: Dictionary = {}
var _hud_visible_region_cache: Dictionary = {}

# ─── SONG MODE STATE ─────────────────────────────────────────────────────────
var _song_mode: bool = false
var _song_elapsed: float = 0.0
var _song_paused: bool = false
var _song_phase_index: int = -1
var _song_boss_triggered: bool = false
var _next_song_enemy_id: int = 100
var _song_reward_pending: bool = false
var _song_phases: Array = []
var _song_conductor: Node = null
var _song_enemy_lanes: Dictionary = {}
var _song_timer_label: Label = null
var _song_phase_label: Label = null
var _song_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _escalation_director: Node = null
var _support_resolver: RefCounted = null
var _song_phase_dna_award_index: int = 0
var _song_section_spawn_mult: float = 1.0
var _song_level_start_time: float = 0.0
var _song_level_end_time: float = 0.0
var _base_difficulty_modifiers: Dictionary = {}
var _difficulty_modifiers: Dictionary = {}
var _music_control_layer: RefCounted = null
var _difficulty_modifier_director: RefCounted = null
var _last_beat_index: int = -1
var _song_level_transitioning: bool = false
var _regular_level_windows: Array = []
var _regular_level_index: int = 0
var _beat_feedback_label: Label = null
var _last_mastery_context: Dictionary = {}
var _quig_anim_accum: float = 0.0
var _quig_anim_frame: int = 0
var _dna_anim_accum: float = 0.0
var _dna_anim_frame: int = 0
var _bonded_creature_anim_accum: float = 0.0

# ─── BOSS MUSIC & HUD ────────────────────────────────────────────────────────
var _boss_music_player: AudioStreamPlayer = null
var _boss_race_active: bool = false
var _boss_music_duration: float = 0.0
var _boss_hp_threshold_fired: bool = false
var _boss_presence_timer: float = 0.0
var _region_id: String = ""
var _dev_harness_request: Dictionary = {}
var _active_song_map: Script = TRICKY_SONGMAP
var _active_song_data: Dictionary = {}


# ─── LIFECYCLE ───────────────────────────────────────────────────────────────

func _ready() -> void:
	if DevHarness.has_pending_request():
		_dev_harness_request = DevHarness.get_pending_request()
	
	_initialize_systems()
	_initialize_ui()
	_initialize_run_state()
	_connect_signals()
	
	_start_mini_run()
	
	if not _dev_harness_request.is_empty():
		call_deferred("_apply_dev_harness_post_boot_state")


func _exit_tree() -> void:
	var vp: Viewport = get_viewport()
	if vp.size_changed.is_connected(_sync_fullscreen_underlay_controls):
		vp.size_changed.disconnect(_sync_fullscreen_underlay_controls)
	if vp.size_changed.is_connected(_sync_compact_transient_hud_layout):
		vp.size_changed.disconnect(_sync_compact_transient_hud_layout)

	# Disconnect all EventBus signals to prevent memory leaks and desync.
	if EventBus.combo_changed.is_connected(_on_combo_changed):
		EventBus.combo_changed.disconnect(_on_combo_changed)
	if EventBus.style_changed.is_connected(_on_style_changed):
		EventBus.style_changed.disconnect(_on_style_changed)
	if EventBus.stamina_changed.is_connected(_on_stamina_changed):
		EventBus.stamina_changed.disconnect(_on_stamina_changed)
	if EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.disconnect(_on_player_took_damage)
	if EventBus.player_healed.is_connected(_on_player_healed):
		EventBus.player_healed.disconnect(_on_player_healed)
	if EventBus.ultimate_available.is_connected(_on_ultimate_available):
		EventBus.ultimate_available.disconnect(_on_ultimate_available)
	if EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.disconnect(_on_ultimate_fired)
	if EventBus.combat_ended.is_connected(_on_combat_ended):
		EventBus.combat_ended.disconnect(_on_combat_ended)
	if EventBus.enemy_damaged.is_connected(_on_enemy_damaged):
		EventBus.enemy_damaged.disconnect(_on_enemy_damaged)
	if EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.disconnect(_on_enemy_defeated)
	
	if _presentation_runtime != null:
		if EventBus.screen_flash.is_connected(_presentation_runtime.on_screen_flash):
			EventBus.screen_flash.disconnect(_presentation_runtime.on_screen_flash)
		if EventBus.screen_shake.is_connected(_presentation_runtime.on_screen_shake):
			EventBus.screen_shake.disconnect(_presentation_runtime.on_screen_shake)
		if EventBus.timing_ring_pressed.is_connected(_presentation_runtime.on_timing_ring_pressed):
			EventBus.timing_ring_pressed.disconnect(_presentation_runtime.on_timing_ring_pressed)

	if EventBus.slow_motion.is_connected(_on_slow_motion):
		EventBus.slow_motion.disconnect(_on_slow_motion)
	if EventBus.player_attacked.is_connected(_on_player_attacked):
		EventBus.player_attacked.disconnect(_on_player_attacked)
	if EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.disconnect(_on_timed_attack_resolved)
	if EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.disconnect(_on_player_parried)
	if EventBus.player_dodged.is_connected(_on_player_dodged):
		EventBus.player_dodged.disconnect(_on_player_dodged)
	if EventBus.player_no_stamina.is_connected(_on_player_no_stamina):
		EventBus.player_no_stamina.disconnect(_on_player_no_stamina)
	if EventBus.combo_broken.is_connected(_on_combo_broken):
		EventBus.combo_broken.disconnect(_on_combo_broken)
	if EventBus.player_teleported.is_connected(_on_player_teleported):
		EventBus.player_teleported.disconnect(_on_player_teleported)
	if EventBus.run_growth_changed.is_connected(_on_run_growth_changed):
		EventBus.run_growth_changed.disconnect(_on_run_growth_changed)
	if EventBus.run_growth_level_resolved.is_connected(_on_run_growth_level_resolved):
		EventBus.run_growth_level_resolved.disconnect(_on_run_growth_level_resolved)
	if EventBus.tendency_growth_resolved.is_connected(_on_tendency_growth_resolved):
		EventBus.tendency_growth_resolved.disconnect(_on_tendency_growth_resolved)
	if EventBus.support_charge_changed.is_connected(_on_support_charge_changed):
		EventBus.support_charge_changed.disconnect(_on_support_charge_changed)
	if EventBus.creature_bonded.is_connected(_on_creature_bonded):
		EventBus.creature_bonded.disconnect(_on_creature_bonded)
	if EventBus.dna_routing_changed.is_connected(_on_dna_routing_changed):
		EventBus.dna_routing_changed.disconnect(_on_dna_routing_changed)
	if EventBus.bonded_support_triggered.is_connected(_on_bonded_support_triggered):
		EventBus.bonded_support_triggered.disconnect(_on_bonded_support_triggered)
	if EventBus.dna_gained.is_connected(_on_dna_gained):
		EventBus.dna_gained.disconnect(_on_dna_gained)
	if EventBus.mastery_context_updated.is_connected(_on_mastery_context_updated):
		EventBus.mastery_context_updated.disconnect(_on_mastery_context_updated)
	if EventBus.enemy_status_applied.is_connected(_on_enemy_status_applied):
		EventBus.enemy_status_applied.disconnect(_on_enemy_status_applied)
	if EventBus.enemy_status_cleared.is_connected(_on_enemy_status_cleared):
		EventBus.enemy_status_cleared.disconnect(_on_enemy_status_cleared)
	if EventBus.phrase_milestone.is_connected(_on_phrase_milestone):
		EventBus.phrase_milestone.disconnect(_on_phrase_milestone)
	if EventBus.tier_changed.is_connected(_on_tier_changed):
		EventBus.tier_changed.disconnect(_on_tier_changed)


func _initialize_systems() -> void:
	_setup_lane_manager()
	_setup_player_combat()
	_setup_run_growth()
	_setup_run_stats()
	_setup_performance_rewards()
	_setup_escalation_director()
	_setup_music_difficulty_layers()
	_setup_support_resolver()


func _setup_support_resolver() -> void:
	_support_resolver = SUPPORT_EFFECT_RESOLVER.new()
	_support_resolver.feedback_requested.connect(_show_feedback)
	_support_resolver.flash_requested.connect(_flash_meter_shell)
	_support_resolver.intervention_requested.connect(_spawn_support_intervention)
	_support_resolver.heal_requested.connect(func(amt): 
		var healed = GameState.heal_player(amt)
		if healed > 0.0: EventBus.emit_signal("player_healed", healed)
	)
	_support_resolver.stamina_requested.connect(func(amt):
		if combat_meter != null: combat_meter.call("restore_stamina", amt)
	)
	_support_resolver.support_charge_requested.connect(func(amt):
		if _run_growth != null and _run_growth.has_method("gain_support_charge_direct"):
			_run_growth.call("gain_support_charge_direct", amt)
	)
	_support_resolver.highlight_ring_requested.connect(func(lane, color, duration):
		if _presentation_runtime != null: _presentation_runtime.highlight_timing_ring(lane, color, duration)
	)


func _setup_escalation_director() -> void:
	if _escalation_director != null and is_instance_valid(_escalation_director):
		return

	_escalation_director = ENCOUNTER_ESCALATION_DIRECTOR.new()
	_escalation_director.name = "EncounterEscalationDirector"
	add_child(_escalation_director)
	_escalation_director.lane_manager = lane_manager
	_escalation_director.player_combat = player_combat
	_escalation_director.phase_changed.connect(_on_escalation_phase_changed)
	_escalation_director.spawn_requested.connect(_on_escalation_spawn_requested)
	_escalation_director.feedback_requested.connect(_on_escalation_feedback_requested)


func _setup_music_difficulty_layers() -> void:
	if _music_control_layer == null:
		_music_control_layer = MUSIC_CONTROL_LAYER.new()
	if _difficulty_modifier_director == null:
		_difficulty_modifier_director = DIFFICULTY_MODIFIER_DIRECTOR.new()


func _on_escalation_phase_changed(index: int, _phase_data: Dictionary) -> void:
	_enter_song_phase(index)


func _on_escalation_spawn_requested(lane: int, enemy_data: Dictionary) -> void:
	_place_song_enemy_data(lane, enemy_data)


func _on_escalation_feedback_requested(text: String, color: Color, duration: float) -> void:
	_show_feedback(text, color, duration)


func _initialize_ui() -> void:
	_setup_presentation_controller()
	_setup_visuals()
	if not get_viewport().size_changed.is_connected(_sync_fullscreen_underlay_controls):
		get_viewport().size_changed.connect(_sync_fullscreen_underlay_controls)
	_setup_ui()
	_setup_ui_pivots()
	_create_feedback_label()
	_create_title_cards()
	_create_timing_circle_container()
	_create_attack_fx_container()
	_setup_presentation_runtime()
	_create_reward_overlay()
	_create_upgrade_overlay()
	_create_run_spine_surface()
	_create_growth_choice_surface()
	_create_live_reward_shell()
	_create_hud_presenter()
	_setup_performance_hud()
	if not get_viewport().size_changed.is_connected(_sync_compact_transient_hud_layout):
		get_viewport().size_changed.connect(_sync_compact_transient_hud_layout)
	call_deferred("_sync_compact_transient_hud_layout")
	_refresh_hud_snapshot(0, 0.0, "stirring")


func _setup_presentation_controller() -> void:
	if _presentation_controller != null and is_instance_valid(_presentation_controller):
		return
	_presentation_controller = COMBAT_PRESENTATION_CONTROLLER.new()
	_presentation_controller.name = "CombatPresentationController"
	add_child(_presentation_controller)


func _initialize_run_state() -> void:
	_combat_finished = false
	_phase_transitioning = false
	_run_finished = false


func _connect_signals() -> void:
	_connect_eventbus()


func _process(delta: float) -> void:
	_update_timers(delta)
	_update_presentation_layers()
	_update_performance_systems(delta)
	_update_song_logic(delta)
	_update_boss_race(delta)
	_tick_hud_sprite_animation(delta)
	_tick_bonded_creature_animation(delta)


func _update_timers(delta: float) -> void:
	for i in range(3):
		if _ring_highlight_timers[i] > 0.0:
			_ring_highlight_timers[i] = max(_ring_highlight_timers[i] - delta, 0.0)
	
	if _surge_window_timer > 0.0:
		_surge_window_timer = max(_surge_window_timer - delta, 0.0)
		if _surge_window_timer <= 0.0:
			_surge_window_tendency = ""
	
	if _song_mode and _song_reward_pending and _awaiting_reward_choice and _live_reward_offer_timer > 0.0:
		_live_reward_offer_timer = max(_live_reward_offer_timer - delta, 0.0)
		_refresh_live_reward_shell()
		if _live_reward_offer_timer <= 0.0:
			_expire_live_reward_offer()


func _update_presentation_layers() -> void:
	if _timing_circle_container != null:
		_update_timing_ring_proximity()
	if _lane_marker_container != null:
		_update_lane_visual_states()
	if _enemy_marker_container != null:
		_update_enemy_marker_threat_states()
	if _bg_sprite != null:
		_update_background_effects()


func _update_background_effects() -> void:
	var focus_pos: Vector2 = Vector2.ZERO
	if player_combat != null:
		focus_pos = player_combat.global_position
	else:
		focus_pos = get_viewport().get_mouse_position()
	
	_presentation_controller.update_background_parallax(_bg_sprite, focus_pos)
	
	# Only update tendency reaction every few frames to save performance
	if Engine.get_process_frames() % 30 == 0 and _run_growth != null:
		var leading: String = _run_growth.call("_get_leading_tendency_id")
		_presentation_controller.update_background_tendency_reaction(_bg_sprite, leading)


func _update_performance_systems(delta: float) -> void:
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("process_tick"):
		if not _awaiting_reward_choice and not _is_run_spine_active():
			_performance_reward_director.call("process_tick", delta)
			if _performance_hud != null and _performance_hud.has_method("process_tick"):
				_performance_hud.process_tick(
					delta,
					_song_mode,
					_run_finished,
					_awaiting_reward_choice or _is_run_spine_active()
				)


func _update_song_logic(delta: float) -> void:
	if not _song_mode or _run_finished:
		return
	if _music_control_layer != null and _music_control_layer.has_method("process_tick"):
		_music_control_layer.call("process_tick", delta)
		
	if not _song_paused:
		if _song_conductor != null:
			_song_elapsed = _song_conductor.get_song_time()
			if _escalation_director != null:
				_escalation_director.update_song_time(_song_elapsed)

			# Beat crossing detection

			var current_beat: int = _song_conductor.get_beat_count()
			if current_beat > _last_beat_index:
				_last_beat_index = current_beat
				var quality: String = _song_conductor.get_beat_quality()
				if GameState.has_method("set_last_beat_quality"):
					GameState.call("set_last_beat_quality", quality)
				_presentation_runtime.on_beat_pulse(quality, 1.0)
			elif current_beat < _last_beat_index:
				# Handle song seeking backwards or restarts.
				_last_beat_index = current_beat
		else:
			_song_elapsed += delta
			if _escalation_director != null:
				_escalation_director.update_song_time(_song_elapsed)
			if not _song_boss_triggered and _song_elapsed >= _song_level_end_time:
				_on_regular_level_complete()
		
		_update_song_hud()
		_recover_stalled_cycles()
		_update_timing_debug()
		_rebuild_music_driven_difficulty()


func _update_timing_debug() -> void:
	if _timing_debug_label == null or not _timing_debug_label.visible:
		return

	if _song_conductor == null or not _song_conductor.is_beat_active():
		_timing_debug_label.text = "Beat: --"
		return

	var quality: String = _song_conductor.get_beat_quality()
	var phase: float = _song_conductor.get_beat_phase()
	var debug_text: String = "Beat: %s (%.2f)" % [quality.to_upper(), phase]
	if _music_control_layer != null and _difficulty_modifier_director != null and not _base_difficulty_modifiers.is_empty():
		var music_state: Dictionary = _music_control_layer.call("build_state")
		var progression_state: Dictionary = _build_music_progression_state()
		var run_progress: float = float(progression_state.get("run_progress", 0.0))
		var skill_expression: float = float(progression_state.get("skill_expression", 0.5))
		var phrase_intensity: float = float(music_state.get("phrase_intensity", 0.0))
		var section_mood: String = String(music_state.get("section_mood", "steady"))
		var tempo_band: String = String(music_state.get("tempo_band", "mid"))
		var accent_window: float = float(music_state.get("accent_window", 0.0))
		var escalation_window: float = float(music_state.get("escalation_window", 0.0))
		debug_text += "\nDir: %s/%s  RP %.2f  SK %.2f  PI %.2f  A %.2f  E %.2f" % [
			tempo_band,
			section_mood,
			run_progress,
			skill_expression,
			phrase_intensity,
			accent_window,
			escalation_window
		]
	_timing_debug_label.text = debug_text
	_timing_debug_label.modulate = UI_STYLE.get_quality_feedback_color(quality)


func _recover_stalled_cycles() -> void:
	if not _song_boss_triggered and lane_manager.is_combat_running() and lane_manager.is_song_cycle_stalled() and lane_manager.alive_count() > 0:
		lane_manager.start_song_cycle()


func _update_boss_race(delta: float) -> void:
	if _boss_race_active and _boss_music_player != null and is_instance_valid(_boss_music_player):
		var elapsed: float = _boss_music_player.get_playback_position()
		if _escalation_director != null:
			_escalation_director.update_song_time(elapsed)
		_update_boss_race_hud()
		_update_boss_presence(delta)


func _update_timing_ring_proximity() -> void:
	_presentation_controller.update_timing_ring_proximity(
		_active_encounter,
		lane_manager,
		player_combat,
		_song_conductor,
		_timing_rings_cache,
		_ring_highlight_timers,
		_surge_window_timer,
		_surge_window_tendency
	)


func _update_lane_visual_states() -> void:
	var biome: Dictionary = _active_encounter.get("biome", {})
	var ring_palette: Dictionary = UI_STYLE.get_combat_ring_palette()
	var lane_color: Color = biome.get("lane_color", ring_palette.get("lane", Color(0.30, 0.30, 0.35, 1.0)))
	var active_color: Color = biome.get("ring_active_color", ring_palette.get("active", Color(1.0, 0.95, 0.55, 1.0)))
	var inactive_color: Color = biome.get("ring_inactive_color", ring_palette.get("inactive", Color(0.7, 0.7, 0.8, 0.45)))
	var time: float = Time.get_ticks_msec() / 1000.0
	var intercept_dist: float = lane_manager.get_enemy_x() - lane_manager.get_hit_zone_x()

	if intercept_dist <= 0.0:
		return

	var outer_entry: float = 1.0 - COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS / intercept_dist
	var outer_exit: float = 1.0 + COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS / intercept_dist

	for lane in range(3):
		var strip: TextureRect = _lane_strips.get(lane, null)
		var focus: Node2D = _lane_hit_focus.get(lane, null)
		if strip == null or focus == null or not is_instance_valid(strip) or not is_instance_valid(focus):
			continue

		var state_color: Color = lane_color
		var state_alpha: float = COMBAT_FEEL_CONTENT.LANE_IDLE_ALPHA
		var focus_alpha: float = COMBAT_FEEL_CONTENT.FOCAL_MARKER_COLOR.a
		var focus_scale: float = 1.0
		var focus_color: Color = inactive_color

		if lane == int(player_combat.get("current_lane")):
			state_alpha += 0.02
			focus_alpha = COMBAT_FEEL_CONTENT.FOCAL_MARKER_ACTIVE_ALPHA * 0.45

		var proj = lane_manager.get_projectile(lane)
		if proj != null and not proj.is_resolved and not proj.is_reflected:
			var p: float = proj.progress
			var telegraph_profile: Dictionary = proj.telegraph_profile
			var threat_color: Color = Color(telegraph_profile.get("lane_color", active_color))
			var accent_color: Color = Color(telegraph_profile.get("accent_color", threat_color.lightened(0.18)))
			var warning_bias: float = max(float(telegraph_profile.get("warning_bias", 1.0)), 0.84)
			var pressure: float = clamp(((p - 0.74) / 0.26) * warning_bias, 0.0, 1.0)
			if pressure > 0.0:
				state_color = lane_color.lerp(threat_color.darkened(0.18), 0.62)
				state_alpha = lerp(state_alpha, COMBAT_FEEL_CONTENT.LANE_THREAT_ALPHA, pressure)
				focus_color = accent_color
				focus_alpha = lerp(focus_alpha, COMBAT_FEEL_CONTENT.FOCAL_MARKER_ACTIVE_ALPHA, pressure)
				focus_scale = lerp(1.0, 1.12, pressure)
				var pulse: float = 1.0 + (sin(time * (5.0 + warning_bias * 0.7) + lane) * 0.01 + 0.01) * pressure
				strip.scale.y = pulse
			else:
				strip.scale.y = 1.0

			if p >= outer_entry and p <= outer_exit:
				var critical_t: float = 1.0 - clamp(abs(p - 1.0) / (outer_exit - 1.0), 0.0, 1.0)
				state_alpha = lerp(state_alpha, COMBAT_FEEL_CONTENT.LANE_CRITICAL_ALPHA, 0.65 + critical_t * 0.35)
				focus_alpha = lerp(focus_alpha, 1.0, 0.70 + critical_t * 0.30)
				focus_scale = lerp(focus_scale, 1.18, 0.70 + critical_t * 0.30)
				focus_color = accent_color.lightened(0.12)
		else:
			strip.scale.y = 1.0

		strip.modulate = Color(state_color.r, state_color.g, state_color.b, state_alpha)
		focus.modulate = Color(focus_color.r, focus_color.g, focus_color.b, focus_alpha)
		focus.scale = Vector2(focus_scale, focus_scale)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	if _is_growth_choice_active():
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

	if _awaiting_upgrade_choice:
		if key_event.keycode == KEY_1:
			_choose_upgrade(0)
			return
		if key_event.keycode == KEY_2:
			_choose_upgrade(1)
			return
		if key_event.keycode == KEY_3:
			_choose_upgrade(2)
			return

	if _is_run_spine_active():
		return

	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.call("has_active_offer"):
		if key_event.keycode == KEY_F:
			_performance_reward_director.call("claim_active_offer", "manual")
			return

	if not _run_finished and key_event.is_action_pressed("toggle_dna_route"):
		if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("toggle_dna_routing_preference"):
			_run_growth.call("toggle_dna_routing_preference")
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
	UI_STYLE.apply_shell_style(shell, "", "", color, border_color)


func _setup_visuals() -> void:
	var refs: Dictionary = _presentation_controller.setup_visuals(
		self,
		background,
		flash_overlay,
		_bg_sprite,
		_battlefield_panel,
		_battlefield_left_shade,
		_battlefield_right_shade,
		_battlefield_top_trim,
		_battlefield_bottom_trim
	)
	_bg_sprite = refs.get("bg_sprite")
	_battlefield_panel = refs.get("battlefield_panel")
	_battlefield_left_shade = refs.get("battlefield_left_shade")
	_battlefield_right_shade = refs.get("battlefield_right_shade")
	_battlefield_top_trim = refs.get("battlefield_top_trim")
	_battlefield_bottom_trim = refs.get("battlefield_bottom_trim")


func _sync_fullscreen_underlay_controls() -> void:
	_presentation_controller.sync_fullscreen_underlay_controls(
		self,
		background,
		flash_overlay,
		_bg_sprite
	)


func _apply_combat_background(override_path: String = "") -> void:
	_bg_sprite = _presentation_controller.apply_combat_background(
		self,
		background,
		flash_overlay,
		_bg_sprite,
		override_path
	)


func _setup_ui_pivots() -> void:
	if combo_label != null:
		combo_label.pivot_offset = combo_label.size * 0.5


func _setup_ui() -> void:
	_build_hud_containers()
	_build_meter_shell()
	combo_label.reparent(_hud_top_right_container)
	combo_label.text = "0"
	combo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(combo_label, "primary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	combo_label.add_theme_font_size_override("font_size", 26)

	style_label.reparent(_hud_top_right_container)
	style_label.text = "Stirring"
	style_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(style_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	style_label.add_theme_font_size_override("font_size", 15)

	var hp_row := HBoxContainer.new()
	hp_row.name = "HpRow"
	hp_row.custom_minimum_size = Vector2(0.0, 22.0)
	hp_row.add_theme_constant_override("separation", 6)
	_hud_top_left_container.add_child(hp_row)
	
	var hp_caption := Label.new()
	hp_caption.text = "Health"
	hp_caption.custom_minimum_size = Vector2(64.0, 0.0)
	_apply_text_role(hp_caption, "caption_strong")
	hp_caption.add_theme_font_size_override("font_size", 14)
	hp_row.add_child(hp_caption)

	_hp_value_label = Label.new()
	_hp_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(_hp_value_label, "primary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_value_label.add_theme_font_size_override("font_size", 22)
	hp_row.add_child(_hp_value_label)

	hp_bar.reparent(_hud_top_left_container)
	hp_bar.min_value = 0.0
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	var bar_w: float = _safe_inner_width(
		COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH,
		COMBAT_FEEL_CONTENT.HUD_TOP_LEFT_CONTENT_MARGIN,
		Vector4(14.0, 8.0, 12.0, 6.0)
	) - 6.0
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(bar_w, 14.0)
	hp_bar.show_percentage = false

	var stamina_row := HBoxContainer.new()
	stamina_row.name = "StaminaRow"
	stamina_row.custom_minimum_size = Vector2(0.0, 22.0)
	stamina_row.add_theme_constant_override("separation", 6)
	_hud_top_left_container.add_child(stamina_row)
	
	var stamina_caption := Label.new()
	stamina_caption.text = "Stamina"
	stamina_caption.custom_minimum_size = Vector2(64.0, 0.0)
	_apply_text_role(stamina_caption, "caption_strong")
	stamina_caption.add_theme_font_size_override("font_size", 14)
	stamina_row.add_child(stamina_caption)

	stamina_bar.reparent(stamina_row)
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	stamina_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamina_bar.custom_minimum_size = Vector2(0.0, 11.0)
	stamina_bar.show_percentage = false

	ultimate_label.reparent(_hud_top_right_container)
	ultimate_label.text = "0%"
	ultimate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(ultimate_label, "warm_value", HORIZONTAL_ALIGNMENT_RIGHT)
	ultimate_label.add_theme_font_size_override("font_size", 16)
	
	result_label.visible = false
	result_label.text = ""
	result_label.position = Vector2(320.0, 290.0)
	result_label.size = Vector2(640.0, 72.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_text_role(result_label, "screen_title")

	_end_stats_label = Label.new()
	_end_stats_label.name = "EndStatsLabel"
	_end_stats_label.position = Vector2(380.0, 370.0)
	_end_stats_label.size = Vector2(520.0, 160.0)
	_end_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end_stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_end_stats_label.visible = false
	_apply_text_role(_end_stats_label, "secondary_value")
	_end_stats_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(_end_stats_label)

	controls_label.reparent(_hud_bottom_container)
	controls_label.text = PRESENTATION_TEXT.COMBAT_CONTROLS
	controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(controls_label, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	controls_label.add_theme_font_size_override("font_size", 14)

	_style_progress_bar(hp_bar, Color(0.18, 0.06, 0.08, 0.88), Color(0.73, 0.24, 0.26, 1.0), 6)
	_style_progress_bar(stamina_bar, Color(0.08, 0.09, 0.10, 0.82), Color(0.44, 0.66, 0.58, 1.0), 5)
	_build_quig_anchor()
	_build_dna_shell()
	_build_song_hud()
	var stats_row_node: Node = _hud_top_left_container.get_node_or_null("StatsRow")
	if stats_row_node != null:
		_hud_top_left_container.move_child(stats_row_node, _hud_top_left_container.get_child_count() - 1)


func _hud_attach_combat_panel_art(panel: Control, texture_path: String, region: Rect2) -> void:
	if texture_path.is_empty():
		return
	var existing_backing: Node = panel.get_node_or_null("HudPanelBacking")
	if existing_backing != null:
		existing_backing.queue_free()
	var existing: Node = panel.get_node_or_null("HudPanelArt")
	if existing != null:
		existing.queue_free()
	var src: Texture2D = load(texture_path) as Texture2D
	if src == null:
		src = ResourceLoader.load(texture_path, "", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if src == null:
		push_warning("CombatScene: could not load HUD panel texture: " + texture_path)
		return
	var resolved_region: Rect2 = _resolve_visible_panel_region(src, region, texture_path)
	var backing := ColorRect.new()
	backing.name = "HudPanelBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.color = Color(0.03, 0.03, 0.04, 0.72)
	backing.anchor_left = 0.0
	backing.anchor_top = 0.0
	backing.anchor_right = 1.0
	backing.anchor_bottom = 1.0
	backing.offset_left = 0.0
	backing.offset_top = 0.0
	backing.offset_right = 0.0
	backing.offset_bottom = 0.0
	panel.add_child(backing)
	var art := TextureRect.new()
	art.name = "HudPanelArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.ignore_texture_size = true
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.anchor_left = 0.0
	art.anchor_top = 0.0
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0
	art.offset_left = 0.0
	art.offset_top = 0.0
	art.offset_right = 0.0
	art.offset_bottom = 0.0
	if resolved_region.size.x > 0.0 and resolved_region.size.y > 0.0:
		var atlas := AtlasTexture.new()
		atlas.atlas = src
		atlas.region = resolved_region
		art.texture = atlas
	else:
		art.texture = src
	panel.add_child(art)
	panel.move_child(backing, 0)
	panel.move_child(art, 1)


func _resolve_visible_panel_region(texture: Texture2D, requested_region: Rect2, texture_path: String) -> Rect2:
	if texture == null:
		return Rect2()
	var cache_key: String = "%s|%s|%s|%s|%s" % [
		texture_path,
		str(requested_region.position.x),
		str(requested_region.position.y),
		str(requested_region.size.x),
		str(requested_region.size.y)
	]
	if _hud_visible_region_cache.has(cache_key):
		return _hud_visible_region_cache[cache_key]

	var tex_bounds := Rect2(Vector2.ZERO, texture.get_size())
	var sample_region: Rect2 = requested_region
	if sample_region.size.x <= 0.0 or sample_region.size.y <= 0.0:
		sample_region = tex_bounds
	else:
		sample_region = sample_region.intersection(tex_bounds)
		if sample_region.size.x <= 0.0 or sample_region.size.y <= 0.0:
			sample_region = tex_bounds

	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		_hud_visible_region_cache[cache_key] = sample_region
		return sample_region

	var min_x: int = int(floor(sample_region.position.x))
	var min_y: int = int(floor(sample_region.position.y))
	var max_x: int = int(ceil(sample_region.end.x))
	var max_y: int = int(ceil(sample_region.end.y))

	var found: bool = false
	var tight_min_x: int = max_x
	var tight_min_y: int = max_y
	var tight_max_x: int = min_x
	var tight_max_y: int = min_y
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var a: float = image.get_pixel(x, y).a
			if a < HUD_PANEL_VISIBLE_ALPHA_THRESHOLD:
				continue
			found = true
			if x < tight_min_x:
				tight_min_x = x
			if y < tight_min_y:
				tight_min_y = y
			if x > tight_max_x:
				tight_max_x = x
			if y > tight_max_y:
				tight_max_y = y

	var resolved: Rect2 = sample_region
	if found:
		resolved = Rect2(
			Vector2(float(tight_min_x), float(tight_min_y)),
			Vector2(float(tight_max_x - tight_min_x + 1), float(tight_max_y - tight_min_y + 1))
		)
	_hud_visible_region_cache[cache_key] = resolved
	return resolved


func _apply_wrapper_safe_zone(body: MarginContainer, safe_margin: Vector4, fallback_margin: Vector4) -> void:
	var margins: Vector4 = fallback_margin
	if safe_margin != Vector4.ZERO:
		margins = safe_margin
	body.offset_left = margins.x
	body.offset_top = margins.y
	body.offset_right = -margins.z
	body.offset_bottom = -margins.w


func _safe_inner_width(outer_width: float, margin: Vector4, fallback_margin: Vector4, min_width: float = 32.0) -> float:
	var margins: Vector4 = fallback_margin
	if margin != Vector4.ZERO:
		margins = margin
	return maxf(min_width, outer_width - margins.x - margins.z)


func _build_hud_containers() -> void:
	var hud_m: float = COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN
	var hud_ty: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y
	var hud_th: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_HEIGHT
	var hud_tl_w: float = COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH
	var hud_tr_w: float = COMBAT_FEEL_CONTENT.HUD_TOP_RIGHT_PANEL_WIDTH
	var right_stack_min_h: float = COMBAT_FEEL_CONTENT.HUD_RIGHT_STACK_MIN_HEIGHT
	var tr_height: float = hud_th + COMBAT_FEEL_CONTENT.HUD_GAP_BELOW_TOP_BAND + right_stack_min_h
	# Top Left Stack
	var tl_panel := Panel.new()
	_hud_top_left_panel = tl_panel
	tl_panel.name = "TopLeftPanel"
	tl_panel.z_index = 40
	tl_panel.clip_contents = true
	tl_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tl_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tl_panel.position = Vector2(hud_m, hud_ty)
	tl_panel.size = Vector2(hud_tl_w, hud_th)
	tl_panel.custom_minimum_size = Vector2(hud_tl_w, hud_th)
	var tl_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_top_left_panel_path()
	if tl_tex.is_empty():
		UI_STYLE.apply_shell_style(tl_panel, "hud_left", "")
	else:
		UI_STYLE.apply_shell_style(
			tl_panel,
			"hud_left",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(tl_panel, tl_tex, COMBAT_FEEL_CONTENT.hud_top_left_texture_region())
	ui_layer.add_child(tl_panel)
	_enforce_top_left_panel_rect()

	var tl_body := MarginContainer.new()
	tl_body.name = "TopLeftBody"
	tl_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(tl_body, COMBAT_FEEL_CONTENT.HUD_TOP_LEFT_CONTENT_MARGIN, Vector4(14.0, 8.0, 12.0, 6.0))
	tl_panel.add_child(tl_body)

	_hud_top_left_container = VBoxContainer.new()
	_hud_top_left_container.name = "TopLeftVBox"
	_hud_top_left_container.add_theme_constant_override("separation", 4)
	_hud_top_left_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_top_left_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tl_body.add_child(_hud_top_left_container)

	# Top Right Stack wrapper now owns both top metrics and persistent right-column readouts.
	var tr_panel := PanelContainer.new()
	_hud_top_right_panel = tr_panel
	tr_panel.name = "TopRightPanel"
	tr_panel.z_index = 40
	tr_panel.position = Vector2(COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - hud_m - hud_tr_w, hud_ty)
	tr_panel.size = Vector2(hud_tr_w, tr_height)
	tr_panel.custom_minimum_size = Vector2(hud_tr_w, tr_height)
	var tr_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_top_right_panel_path()
	if tr_tex.is_empty():
		UI_STYLE.apply_shell_style(tr_panel, "hud_right", "")
	else:
		UI_STYLE.apply_shell_style(
			tr_panel,
			"hud_right",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(tr_panel, tr_tex, COMBAT_FEEL_CONTENT.hud_top_right_texture_region())
	ui_layer.add_child(tr_panel)

	var tr_body := MarginContainer.new()
	tr_body.name = "TopRightBody"
	tr_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(tr_body, COMBAT_FEEL_CONTENT.HUD_TOP_RIGHT_CONTENT_MARGIN, Vector4(12.0, 8.0, 14.0, 6.0))
	tr_panel.add_child(tr_body)

	var accent_host := Control.new()
	accent_host.name = "RightHudAccentHost"
	accent_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	accent_host.offset_left = 0.0
	accent_host.offset_top = 0.0
	accent_host.offset_right = 0.0
	accent_host.offset_bottom = 0.0
	accent_host.z_index = 4
	_hud_top_right_accent_host = accent_host
	tr_panel.add_child(accent_host)

	var tr_stack := VBoxContainer.new()
	tr_stack.name = "TopRightStack"
	tr_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tr_stack.add_theme_constant_override("separation", COMBAT_FEEL_CONTENT.HUD_GAP_BELOW_TOP_BAND)
	tr_body.add_child(tr_stack)

	_hud_top_right_container = VBoxContainer.new()
	_hud_top_right_container.name = "TopRightVBox"
	_hud_top_right_container.add_theme_constant_override("separation", 3)
	_hud_top_right_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_top_right_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tr_stack.add_child(_hud_top_right_container)

	_hud_right_stack = VBoxContainer.new()
	_hud_right_stack.name = "RightStackContainer"
	_hud_right_stack.custom_minimum_size = Vector2(0.0, right_stack_min_h)
	_hud_right_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_right_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hud_right_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_right_stack.add_theme_constant_override("separation", 6)
	tr_stack.add_child(_hud_right_stack)

	var bottom_panel := PanelContainer.new()
	bottom_panel.name = "BottomHudPanel"
	bottom_panel.z_index = 40
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = hud_m
	bottom_panel.offset_right = -hud_m
	bottom_panel.offset_top = -(COMBAT_FEEL_CONTENT.HUD_BOTTOM_STRIP_HEIGHT + COMBAT_FEEL_CONTENT.HUD_BOTTOM_OUTER_MARGIN)
	bottom_panel.offset_bottom = -COMBAT_FEEL_CONTENT.HUD_BOTTOM_OUTER_MARGIN
	var bottom_tex: String = COMBAT_FEEL_CONTENT.resolved_hud_bottom_panel_path()
	if bottom_tex.is_empty():
		UI_STYLE.apply_shell_style(bottom_panel, "hud_accent")
	else:
		UI_STYLE.apply_shell_style(
			bottom_panel,
			"hud_left",
			"",
			Color(),
			Color(),
			Rect2(),
			Vector4.ZERO,
			Vector4.ZERO,
			Color(),
			true
		)
	_hud_attach_combat_panel_art(bottom_panel, bottom_tex, COMBAT_FEEL_CONTENT.hud_bottom_texture_region())
	ui_layer.add_child(bottom_panel)

	var bottom_body := MarginContainer.new()
	bottom_body.name = "BottomBody"
	bottom_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(
		bottom_body,
		COMBAT_FEEL_CONTENT.HUD_BOTTOM_CONTENT_MARGIN,
		Vector4(10.0, 4.0, 10.0, 4.0)
	)
	bottom_panel.add_child(bottom_body)

	_hud_bottom_container = HBoxContainer.new()
	_hud_bottom_container.name = "BottomContainer"
	_hud_bottom_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_bottom_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hud_bottom_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_bottom_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_body.add_child(_hud_bottom_container)


func _enforce_top_left_panel_rect() -> void:
	if _hud_top_left_panel == null or not is_instance_valid(_hud_top_left_panel):
		return
	var hud_m: float = COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN
	var hud_ty: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y
	var hud_tl_w: float = COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH
	var hud_th: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_HEIGHT
	_hud_top_left_panel.custom_minimum_size = Vector2(hud_tl_w, hud_th)
	_hud_top_left_panel.position = Vector2(hud_m, hud_ty)
	_hud_top_left_panel.size = Vector2(hud_tl_w, hud_th)


func _build_meter_shell() -> void:
	_meter_shell = ColorRect.new()
	_meter_shell.name = "MeterShell"
	_meter_shell.position = Vector2.ZERO
	_meter_shell.size = Vector2.ZERO
	_meter_shell.color = Color(0.0, 0.0, 0.0, 0.0)
	ui_layer.add_child(_meter_shell)

	_resource_shell = ColorRect.new()
	_resource_shell.name = "RightHudAccent"
	_resource_shell.z_index = 42
	_resource_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_shell.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_resource_shell.anchor_left = 1.0
	_resource_shell.anchor_top = 0.0
	_resource_shell.anchor_right = 1.0
	_resource_shell.anchor_bottom = 0.0
	_resource_shell.offset_left = -52.0
	_resource_shell.offset_top = 6.0
	_resource_shell.offset_right = -8.0
	_resource_shell.offset_bottom = 20.0
	UI_STYLE.apply_shell_style(_resource_shell, "hud_accent")
	_resource_shell.color = Color(0.16, 0.10, 0.08, 0.07)
	if _hud_top_right_accent_host != null:
		_hud_top_right_accent_host.add_child(_resource_shell)
	elif _hud_top_right_panel != null:
		_hud_top_right_panel.add_child(_resource_shell)
	else:
		_resource_shell.position = Vector2(
			COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN - 52.0,
			COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y + 6.0
		)
		_resource_shell.size = Vector2(44.0, 14.0)
		ui_layer.add_child(_resource_shell)

	_support_shell = ColorRect.new()
	_support_shell.name = "SupportShell"
	_support_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 64.0)
	UI_STYLE.apply_shell_style(_support_shell, "support_idle")
	_hud_right_stack.add_child(_support_shell)

	var support_body := MarginContainer.new()
	support_body.name = "SupportBody"
	support_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	support_body.offset_left = 8.0
	support_body.offset_top = 4.0
	support_body.offset_right = -8.0
	support_body.offset_bottom = -6.0
	_support_shell.add_child(support_body)

	var support_vbox := VBoxContainer.new()
	support_vbox.name = "SupportVBox"
	support_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	support_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	support_vbox.add_theme_constant_override("separation", 3)
	support_body.add_child(support_vbox)

	var support_header := HBoxContainer.new()
	support_header.name = "SupportHeader"
	support_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	support_header.add_theme_constant_override("separation", 4)
	support_vbox.add_child(support_header)

	_support_name_label = Label.new()
	_support_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_support_name_label.custom_minimum_size = Vector2(0.0, 20.0)
	_support_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_support_name_label.text = PRESENTATION_TEXT.SUPPORT_EMPTY_NAME
	_apply_text_role(_support_name_label, "secondary_value")
	_support_name_label.add_theme_font_size_override("font_size", 15)
	support_header.add_child(_support_name_label)

	_support_value_label = Label.new()
	_support_value_label.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_ROW_WIDTH + 12.0, 22.0)
	_support_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_support_value_label.text = "--"
	_apply_text_role(_support_value_label, "alert_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_support_value_label.add_theme_font_size_override("font_size", 16)
	support_header.add_child(_support_value_label)

	_support_bar = ProgressBar.new()
	_support_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_support_bar.custom_minimum_size = Vector2(0.0, 13.0)
	_support_bar.min_value = 0.0
	_support_bar.max_value = 100.0
	_support_bar.value = 0.0
	_support_bar.show_percentage = false
	support_vbox.add_child(_support_bar)
	UI_STYLE.apply_bar_style(_support_bar, "support_idle")

	_support_trigger_label = Label.new()
	_support_trigger_label.name = "SupportTriggerHint"
	_support_trigger_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_support_trigger_label.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_TEXT_WIDTH, 18.0)
	_support_trigger_label.text = ""
	_apply_text_role(_support_trigger_label, "status_line")
	_support_trigger_label.add_theme_font_size_override("font_size", 13)
	support_vbox.add_child(_support_trigger_label)

	_run_build_shell = ColorRect.new()
	_run_build_shell.name = "RunBuildShell"
	_run_build_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 56.0)
	UI_STYLE.apply_shell_style(_run_build_shell, "run_build")
	_run_build_shell.visible = false
	_hud_right_stack.add_child(_run_build_shell)

	var run_build_body := MarginContainer.new()
	run_build_body.name = "RunBuildBody"
	run_build_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	run_build_body.offset_left = 8.0
	run_build_body.offset_top = 4.0
	run_build_body.offset_right = -8.0
	run_build_body.offset_bottom = -4.0
	_run_build_shell.add_child(run_build_body)

	var run_build_vbox := VBoxContainer.new()
	run_build_vbox.name = "RunBuildVBox"
	run_build_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_build_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	run_build_vbox.add_theme_constant_override("separation", 1)
	run_build_body.add_child(run_build_vbox)

	var eaten_row := HBoxContainer.new()
	eaten_row.name = "EatenRow"
	eaten_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eaten_row.add_theme_constant_override("separation", 4)
	run_build_vbox.add_child(eaten_row)

	var eaten_caption := Label.new()
	eaten_caption.custom_minimum_size = Vector2(34.0, 16.0)
	eaten_caption.text = PRESENTATION_TEXT.RUN_BUILD_EATEN_CAPTION
	_apply_text_role(eaten_caption, "caption_strong")
	eaten_caption.visible = false
	eaten_row.add_child(eaten_caption)

	_eaten_value_label = Label.new()
	_eaten_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_eaten_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_eaten_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_eaten_value_label.text = "--"
	_apply_text_role(_eaten_value_label, "status_line")
	_eaten_value_label.add_theme_font_size_override("font_size", 16)
	_eaten_value_label.visible = false
	eaten_row.add_child(_eaten_value_label)

	var upgrade_row := HBoxContainer.new()
	upgrade_row.name = "UpgradeRow"
	upgrade_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_row.add_theme_constant_override("separation", 4)
	run_build_vbox.add_child(upgrade_row)

	var upgrade_caption := Label.new()
	upgrade_caption.custom_minimum_size = Vector2(34.0, 16.0)
	upgrade_caption.text = PRESENTATION_TEXT.RUN_BUILD_TENDENCY_CAPTION
	_apply_text_role(upgrade_caption, "caption_strong")
	upgrade_caption.visible = false
	upgrade_row.add_child(upgrade_caption)

	_upgrade_value_label = Label.new()
	_upgrade_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_upgrade_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_upgrade_value_label.text = "--"
	_apply_text_role(_upgrade_value_label, "alert_value")
	_upgrade_value_label.add_theme_font_size_override("font_size", 16)
	_upgrade_value_label.visible = false
	upgrade_row.add_child(_upgrade_value_label)

	var bond_row := HBoxContainer.new()
	bond_row.name = "BondRow"
	bond_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_row.add_theme_constant_override("separation", 4)
	run_build_vbox.add_child(bond_row)

	var bond_caption := Label.new()
	bond_caption.custom_minimum_size = Vector2(34.0, 16.0)
	bond_caption.text = PRESENTATION_TEXT.RUN_BUILD_BOND_CAPTION
	_apply_text_role(bond_caption, "caption_strong")
	bond_caption.visible = false
	bond_row.add_child(bond_caption)

	_bond_value_label = Label.new()
	_bond_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bond_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_bond_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bond_value_label.text = "--"
	_apply_text_role(_bond_value_label, "cool_value")
	_bond_value_label.add_theme_font_size_override("font_size", 16)
	_bond_value_label.visible = false
	bond_row.add_child(_bond_value_label)

	# Top-left sub-container for secondary stats (EXP, Def, Atk) — moved to bottom of column in _setup_ui
	var stats_row := HBoxContainer.new()
	stats_row.name = "StatsRow"
	stats_row.custom_minimum_size = Vector2(
		_safe_inner_width(
			COMBAT_FEEL_CONTENT.HUD_TOP_PANEL_WIDTH,
			COMBAT_FEEL_CONTENT.HUD_TOP_LEFT_CONTENT_MARGIN,
			Vector4(14.0, 8.0, 12.0, 6.0)
		),
		18.0
	)
	_hud_top_left_container.add_child(stats_row)

	var exp_caption := Label.new()
	exp_caption.text = "EXP"
	_apply_text_role(exp_caption, "caption")
	exp_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(exp_caption)

	_exp_value_label = Label.new()
	_exp_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_role(_exp_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_LEFT)
	_exp_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_exp_value_label)

	var def_caption := Label.new()
	def_caption.text = "Def"
	_apply_text_role(def_caption, "caption")
	def_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(def_caption)

	_def_value_label = Label.new()
	_def_value_label.custom_minimum_size = Vector2(26.0, 0.0)
	_apply_text_role(_def_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_def_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_def_value_label)

	var atk_caption := Label.new()
	atk_caption.text = "Atk"
	_apply_text_role(atk_caption, "caption")
	atk_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(atk_caption)

	_atk_value_label = Label.new()
	_atk_value_label.custom_minimum_size = Vector2(26.0, 0.0)
	_apply_text_role(_atk_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_atk_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_atk_value_label)

	# Top-Right sub-containers for readouts
	var ult_row := HBoxContainer.new()
	ult_row.alignment = BoxContainer.ALIGNMENT_END
	ult_row.custom_minimum_size = Vector2(0.0, 22.0)
	ult_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(ult_row)
	
	var ultimate_caption := Label.new()
	ultimate_caption.text = "Ult"
	ultimate_caption.custom_minimum_size = Vector2(44.0, 0.0)
	_apply_text_role(ultimate_caption, "caption_strong")
	ultimate_caption.add_theme_font_size_override("font_size", 14)
	ult_row.add_child(ultimate_caption)
	ultimate_label.reparent(ult_row)
	ultimate_label.custom_minimum_size = Vector2(40.0, 0.0)

	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_END
	score_row.custom_minimum_size = Vector2(0.0, 22.0)
	score_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(score_row)

	var score_caption := Label.new()
	score_caption.text = "Combo"
	score_caption.custom_minimum_size = Vector2(44.0, 0.0)
	_apply_text_role(score_caption, "caption_strong")
	score_caption.add_theme_font_size_override("font_size", 14)
	score_row.add_child(score_caption)
	combo_label.reparent(score_row)
	combo_label.custom_minimum_size = Vector2(50.0, 0.0)

	var style_row := HBoxContainer.new()
	style_row.alignment = BoxContainer.ALIGNMENT_END
	style_row.custom_minimum_size = Vector2(0.0, 22.0)
	style_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(style_row)

	var style_caption := Label.new()
	style_caption.text = "Style"
	style_caption.custom_minimum_size = Vector2(44.0, 0.0)
	_apply_text_role(style_caption, "caption_strong")
	style_caption.add_theme_font_size_override("font_size", 14)
	style_row.add_child(style_caption)
	style_label.reparent(style_row)
	style_label.custom_minimum_size = Vector2(100.0, 0.0)

	_dna_route_shell = ColorRect.new()
	_dna_route_shell.name = "DnaRouteShell"
	_dna_route_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 38.0)
	UI_STYLE.apply_shell_style(_dna_route_shell, "hud_right")
	_hud_right_stack.add_child(_dna_route_shell)

	var dna_route_body := MarginContainer.new()
	dna_route_body.name = "DnaRouteBody"
	dna_route_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	dna_route_body.offset_left = 8.0
	dna_route_body.offset_top = 3.0
	dna_route_body.offset_right = -8.0
	dna_route_body.offset_bottom = -3.0
	_dna_route_shell.add_child(dna_route_body)

	var dna_route_vbox := VBoxContainer.new()
	dna_route_vbox.name = "DnaRouteVBox"
	dna_route_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_route_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dna_route_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dna_route_vbox.add_theme_constant_override("separation", 1)
	dna_route_body.add_child(dna_route_vbox)

	_dna_route_label = Label.new()
	_dna_route_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dna_route_label.custom_minimum_size = Vector2(0.0, 22.0)
	_dna_route_label.text = PRESENTATION_TEXT.DNA_ROUTE_BOND_LABEL
	_apply_text_role(_dna_route_label, "status_line", HORIZONTAL_ALIGNMENT_CENTER)
	_dna_route_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dna_route_label.add_theme_font_size_override("font_size", 14)
	dna_route_vbox.add_child(_dna_route_label)

	# Initialize mutation value label (for enhanced mutation system)
	_mutation_value_label = Label.new()
	_mutation_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mutation_value_label.custom_minimum_size = Vector2(0.0, 18.0)
	_mutation_value_label.text = ""
	_apply_text_role(_mutation_value_label, "status_line", HORIZONTAL_ALIGNMENT_CENTER)
	_mutation_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mutation_value_label.add_theme_font_size_override("font_size", 14)
	_mutation_value_label.visible = false
	dna_route_vbox.add_child(_mutation_value_label)

	var run_score_row := HBoxContainer.new()
	run_score_row.alignment = BoxContainer.ALIGNMENT_END
	run_score_row.custom_minimum_size = Vector2(0.0, 22.0)
	run_score_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(run_score_row)

	var run_score_caption := Label.new()
	run_score_caption.text = "Run"
	run_score_caption.custom_minimum_size = Vector2(44.0, 0.0)
	_apply_text_role(run_score_caption, "caption_strong")
	run_score_caption.add_theme_font_size_override("font_size", 14)
	run_score_row.add_child(run_score_caption)

	_run_score_label = Label.new()
	_run_score_label.name = "RunScoreLabel"
	_run_score_label.text = "0"
	_apply_text_role(_run_score_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_run_score_label.add_theme_font_size_override("font_size", 13)
	_run_score_label.custom_minimum_size = Vector2(80.0, 0.0)
	run_score_row.add_child(_run_score_label)

	_bonded_creature_sprite = Sprite2D.new()
	_bonded_creature_sprite.name = "BondedCreatureSprite"
	_bonded_creature_sprite.visible = false
	_bonded_creature_sprite.centered = true
	_bonded_creature_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_bonded_creature_sprite)

	# Boss HP bar — centered between top corner panels, below top band (hidden until boss).
	var boss_x: float = COMBAT_FEEL_CONTENT.HUD_BOSS_BLOCK_X
	var boss_y: float = COMBAT_FEEL_CONTENT.HUD_BOSS_BLOCK_Y
	var boss_w: float = COMBAT_FEEL_CONTENT.HUD_BOSS_BLOCK_WIDTH
	_boss_hp_shell = ColorRect.new()
	_boss_hp_shell.name = "BossHpShell"
	_boss_hp_shell.position = Vector2(boss_x, boss_y)
	_boss_hp_shell.size = Vector2(boss_w, 52.0)
	_boss_hp_shell.z_index = 38
	UI_STYLE.apply_shell_style(_boss_hp_shell, "boss_shell")
	_boss_hp_shell.visible = false
	ui_layer.add_child(_boss_hp_shell)

	var boss_body := MarginContainer.new()
	boss_body.name = "BossBody"
	boss_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_body.offset_left = 12.0
	boss_body.offset_top = 3.0
	boss_body.offset_right = -12.0
	boss_body.offset_bottom = -3.0
	_boss_hp_shell.add_child(boss_body)

	var boss_vbox := VBoxContainer.new()
	boss_vbox.name = "BossVBox"
	boss_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	boss_vbox.add_theme_constant_override("separation", 1)
	boss_body.add_child(boss_vbox)

	_boss_name_label = Label.new()
	_boss_name_label.name = "BossNameLabel"
	_boss_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_name_label.custom_minimum_size = Vector2(0.0, 22.0)
	_boss_name_label.text = ""
	_apply_text_role(_boss_name_label, "boss", HORIZONTAL_ALIGNMENT_CENTER)
	_boss_name_label.add_theme_font_size_override("font_size", 26)
	_boss_name_label.visible = false
	boss_vbox.add_child(_boss_name_label)

	_boss_state_label = Label.new()
	_boss_state_label.name = "BossStateLabel"
	_boss_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_state_label.custom_minimum_size = Vector2(0.0, 14.0)
	_boss_state_label.text = ""
	_apply_text_role(_boss_state_label, "body", HORIZONTAL_ALIGNMENT_CENTER)
	_boss_state_label.add_theme_font_size_override("font_size", 14)
	_boss_state_label.add_theme_color_override("font_color", UI_STYLE.get_manga_color("alert_gold"))
	_boss_state_label.visible = false
	boss_vbox.add_child(_boss_state_label)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.name = "BossHpBar"
	_boss_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_hp_bar.custom_minimum_size = Vector2(0.0, 12.0)
	_boss_hp_bar.min_value = 0.0
	_boss_hp_bar.max_value = 100.0
	_boss_hp_bar.value = 100.0
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.visible = false
	boss_vbox.add_child(_boss_hp_bar)
	UI_STYLE.apply_bar_style(_boss_hp_bar, "boss")


func _style_progress_bar(bar: ProgressBar, under_color: Color, fill_color: Color, corner_radius: int) -> void:
	var role: String = ""
	if bar == _support_bar:
		role = "support_idle"
	elif bar == _boss_hp_bar:
		role = "boss"

	if not role.is_empty():
		UI_STYLE.apply_bar_style(bar, role)
		return

	var track_path: String = COMBAT_FEEL_CONTENT.resolved_bar_track_path()
	var under: StyleBox
	if not track_path.is_empty():
		var sb_tex: StyleBoxTexture = (
			UI_STYLE.stylebox_texture_from_path(
				track_path,
				COMBAT_FEEL_CONTENT.hud_bar_track_texture_region(),
				COMBAT_FEEL_CONTENT.HUD_BAR_TRACK_NINE_SLICE,
				Vector4.ZERO,
				Color(1.0, 1.0, 1.0, 1.0)
			) as StyleBoxTexture
		)
		if sb_tex != null:
			under = sb_tex
		else:
			under = _style_progress_bar_flat_under(under_color, corner_radius)
	else:
		under = _style_progress_bar_flat_under(under_color, corner_radius)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = corner_radius
	fill.corner_radius_top_right = corner_radius
	fill.corner_radius_bottom_left = corner_radius
	fill.corner_radius_bottom_right = corner_radius

	bar.add_theme_stylebox_override("background", under)
	bar.add_theme_stylebox_override("fill", fill)


func _style_progress_bar_flat_under(under_color: Color, corner_radius: int) -> StyleBoxFlat:
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
	return under


func _create_panel_backing(
	name: String,
	texture_path: String,
	region: Rect2,
	position: Vector2,
	size: Vector2,
	modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
) -> TextureRect:
	if not ResourceLoader.exists(texture_path):
		return null

	var source_texture: Texture2D = load(texture_path) as Texture2D
	if source_texture == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = region

	var backing := TextureRect.new()
	backing.name = name
	backing.texture = atlas
	backing.position = position
	backing.size = size
	backing.stretch_mode = TextureRect.STRETCH_SCALE
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.modulate = modulate
	ui_layer.add_child(backing)
	return backing


func _build_strip_sprite(
	name: String,
	texture_path: String,
	frame_size: Vector2i,
	initial_frame: int,
	position: Vector2,
	size: Vector2
) -> TextureRect:
	if not ResourceLoader.exists(texture_path):
		return null

	var source_texture: Texture2D = load(texture_path) as Texture2D
	if source_texture == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = Rect2(
		Vector2(frame_size.x * initial_frame, 0.0),
		Vector2(frame_size.x, frame_size.y)
	)

	var sprite := TextureRect.new()
	sprite.name = name
	sprite.texture = atlas
	sprite.position = position
	sprite.size = size
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite


func _build_song_hud() -> void:
	var hud_m: float = COMBAT_FEEL_CONTENT.HUD_OUTER_MARGIN
	var hud_ty: float = COMBAT_FEEL_CONTENT.HUD_TOP_BAND_Y
	# Song phase label — top-center, dim (above corner art).
	_song_phase_label = Label.new()
	_song_phase_label.name = "SongPhaseLabel"
	_song_phase_label.text = ""
	_apply_text_role(_song_phase_label, "dim", HORIZONTAL_ALIGNMENT_CENTER)
	_song_phase_label.size = Vector2(300.0, 18.0)
	_song_phase_label.position = Vector2((COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - 300.0) * 0.5, hud_ty + 4.0)
	_song_phase_label.z_index = 45
	_song_phase_label.visible = false
	ui_layer.add_child(_song_phase_label)

	# Song timer label — upper-right, aligned with top band (above corner panels).
	_song_timer_label = Label.new()
	_song_timer_label.name = "SongTimerLabel"
	_song_timer_label.text = ""
	_apply_text_role(_song_timer_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_song_timer_label.size = Vector2(52.0, 18.0)
	_song_timer_label.position = Vector2(COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - hud_m - 56.0, hud_ty + 26.0)
	_song_timer_label.z_index = 45
	_song_timer_label.visible = false
	ui_layer.add_child(_song_timer_label)

	# Beat feedback label — appears near the timing rings briefly when the player
	# lands a combat action on-beat (IN SYNC / ON BEAT / LOCKED IN / SLIP).
	# Position is tunable; currently centered on the hit zone area.
	_beat_feedback_label = Label.new()
	_beat_feedback_label.name = "BeatFeedbackLabel"
	_beat_feedback_label.text = ""
	_beat_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_beat_feedback_label.custom_minimum_size = Vector2(0.0, 20.0)
	_apply_text_role(_beat_feedback_label, "alert_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_beat_feedback_label.add_theme_font_size_override("font_size", 16)
	_beat_feedback_label.visible = false
	_hud_top_left_container.add_child(_beat_feedback_label)


func _build_quig_anchor() -> void:
	var quig_shell := ColorRect.new()
	_quig_shell = quig_shell
	quig_shell.name = "QuigShell"
	quig_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 24.0)
	quig_shell.color = Color(0.0, 0.0, 0.0, 0.0)
	quig_shell.visible = false
	_hud_right_stack.add_child(quig_shell)

	_quig_anchor_sprite = _build_strip_sprite(
		"QuigAnchorSprite",
		COMBAT_FEEL_CONTENT.QUIG_SPRITE_PATH,
		COMBAT_FEEL_CONTENT.QUIG_FRAME_SIZE,
		0,
		Vector2(2.0, 2.0),
		Vector2(24.0, 24.0)
	)
	if _quig_anchor_sprite != null:
		_quig_anchor_sprite.visible = false
		quig_shell.add_child(_quig_anchor_sprite)

		if OS.is_debug_build():
			_timing_debug_label = Label.new()
			_timing_debug_label.position = Vector2(10.0, 116.0)
			_timing_debug_label.size = Vector2(240.0, 24.0)
			_timing_debug_label.add_theme_font_size_override("font_size", 13)
			_timing_debug_label.modulate = UI_STYLE.get_quality_feedback_color("idle")
			_timing_debug_label.visible = true
			ui_layer.add_child(_timing_debug_label)

	_quig_anchor_label = Label.new()
	_quig_anchor_label.name = "QuigAnchor"
	_quig_anchor_label.visible = false
	_quig_anchor_label.position = Vector2(28.0, 0.0)
	_quig_anchor_label.size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH - 28.0, 28.0)
	_quig_anchor_label.text = ""
	_apply_text_role(_quig_anchor_label, "dim")
	_quig_anchor_label.add_theme_font_size_override("font_size", 13)
	quig_shell.add_child(_quig_anchor_label)


func _build_dna_shell() -> void:
	_dna_shell = ColorRect.new()
	_dna_shell.name = "DnaShell"
	_dna_shell.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH, 46.0)
	UI_STYLE.apply_shell_style(_dna_shell, "dna")
	_dna_shell.visible = false
	_hud_right_stack.add_child(_dna_shell)

	var dna_body := MarginContainer.new()
	dna_body.name = "DnaBody"
	dna_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	dna_body.offset_left = 8.0
	dna_body.offset_top = 5.0
	dna_body.offset_right = -8.0
	dna_body.offset_bottom = -5.0
	_dna_shell.add_child(dna_body)

	var dna_vbox := VBoxContainer.new()
	dna_vbox.name = "DnaVBox"
	dna_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dna_vbox.add_theme_constant_override("separation", 1)
	dna_body.add_child(dna_vbox)

	var dna_header := HBoxContainer.new()
	dna_header.name = "DnaHeader"
	dna_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_header.add_theme_constant_override("separation", 3)
	dna_vbox.add_child(dna_header)

	var dna_caption := Label.new()
	dna_caption.custom_minimum_size = Vector2(42.0, 16.0)
	dna_caption.text = "DNA"
	_apply_text_role(dna_caption, "caption_strong")
	dna_caption.add_theme_font_size_override("font_size", 16)
	dna_header.add_child(dna_caption)

	var dna_header_spacer := Control.new()
	dna_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dna_header.add_child(dna_header_spacer)

	_dna_emblem = _build_strip_sprite(
		"DnaEmblem",
		COMBAT_FEEL_CONTENT.DNA_SPRITE_PATH,
		COMBAT_FEEL_CONTENT.DNA_FRAME_SIZE,
		0,
		Vector2.ZERO,
		Vector2(16.0, 16.0)
	)
	if _dna_emblem != null:
		_dna_emblem.modulate = Color(1.0, 1.0, 1.0, 0.82)
		dna_header.add_child(_dna_emblem)

	_dna_slot_labels.clear()
	for i in range(DNA_HUD_VISIBLE_SLOTS):
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(0.0, 14.0)
		label.text = "--"
		_apply_text_role(label, "secondary_value")
		label.add_theme_font_size_override("font_size", 14)
		dna_vbox.add_child(label)
		_dna_slot_labels.append(label)


func _refresh_hud_snapshot(score_value: int, exp_value: float, style_tier: String) -> void:
	_hud_presenter.refresh_hp(GameState.player_hp, GameState.player_max_hp)
	var growth_level: int = 1
	if _run_growth != null and is_instance_valid(_run_growth):
		growth_level = int(_run_growth.level)
	_hud_presenter.set_exp_text(growth_level, exp_value)
	_refresh_run_build_readout()
	_hud_presenter.refresh_combo(score_value, style_tier)
	_hud_presenter.refresh_style(style_tier)


func _create_feedback_label() -> void:
	var half_w: float = COMBAT_FEEL_CONTENT.HUD_COMBAT_FEEDBACK_HALF_WIDTH
	var fy: float = COMBAT_FEEL_CONTENT.HUD_COMBAT_FEEDBACK_Y
	var fh: float = COMBAT_FEEL_CONTENT.HUD_COMBAT_FEEDBACK_HEIGHT

	_feedback_backing = ColorRect.new()
	_feedback_backing.name = "FeedbackBacking"
	_feedback_backing.visible = false
	_feedback_backing.z_index = 89
	_feedback_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_backing.anchor_left = 0.5
	_feedback_backing.anchor_top = 0.0
	_feedback_backing.anchor_right = 0.5
	_feedback_backing.anchor_bottom = 0.0
	_feedback_backing.offset_left = -half_w
	_feedback_backing.offset_top = fy
	_feedback_backing.offset_right = half_w
	_feedback_backing.offset_bottom = fy + fh
	UI_STYLE.apply_shell_style(_feedback_backing, "feedback_backing")
	ui_layer.add_child(_feedback_backing)

	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.visible = false
	_feedback_label.z_index = 90
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_label.anchor_left = 0.5
	_feedback_label.anchor_top = 0.0
	_feedback_label.anchor_right = 0.5
	_feedback_label.anchor_bottom = 0.0
	_feedback_label.offset_left = -half_w + 8.0
	_feedback_label.offset_top = fy + 2.0
	_feedback_label.offset_right = half_w - 8.0
	_feedback_label.offset_bottom = fy + fh - 2.0
	_feedback_label.pivot_offset = Vector2(half_w - 8.0, (fh - 4.0) * 0.5)
	_apply_text_role(_feedback_label, "feedback", HORIZONTAL_ALIGNMENT_CENTER)
	_feedback_label.add_theme_font_size_override("font_size", COMBAT_FEEL_CONTENT.HUD_COMBAT_FEEDBACK_FONT_SIZE)
	ui_layer.add_child(_feedback_label)


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
	_timing_circle_container = _presentation_controller.create_timing_circle_container(self)
	_timing_rings_cache.clear()


func _create_attack_fx_container() -> void:
	_attack_fx_container = _presentation_controller.create_attack_fx_container(self)


func _setup_presentation_runtime() -> void:
	_presentation_runtime = COMBAT_PRESENTATION_RUNTIME.new(
		flash_overlay,
		camera_2d,
		_timing_circle_container,
		_attack_fx_container,
		player_combat,
		lane_manager,
		_enemy_markers_by_id,
		_ring_highlight_timers,
		_bg_sprite
	)

	_combat_audio_player = COMBAT_AUDIO_PLAYER.new()
	_combat_audio_player.name = "CombatAudioPlayer"
	add_child(_combat_audio_player)


func _create_reward_overlay() -> void:
	var nodes: Dictionary = _presentation_controller.create_reward_overlay(ui_layer)
	_reward_overlay = nodes.get("reward_overlay")
	_reward_wrapper_shell = nodes.get("reward_wrapper_shell")
	_reward_panel = nodes.get("reward_panel")
	_reward_title_label = nodes.get("reward_title_label")
	_reward_body_label = nodes.get("reward_body_label")
	_reward_quig_label = nodes.get("reward_quig_label")
	_reward_quig_sprite = nodes.get("reward_quig_sprite")
	_reward_hint_label = nodes.get("reward_hint_label")
	_reward_bond_card = nodes.get("reward_bond_card")
	_reward_eat_card = nodes.get("reward_eat_card")
	_reward_bond_label = nodes.get("reward_bond_label")
	_reward_eat_label = nodes.get("reward_eat_label")
	_reward_bond_effect_label = nodes.get("reward_bond_effect_label")
	_reward_eat_effect_label = nodes.get("reward_eat_effect_label")
	_reward_creature_tag_label = nodes.get("reward_creature_tag_label")
	_reward_creature_portrait = nodes.get("reward_creature_portrait")
	_reward_body_scroll = nodes.get("reward_body_scroll")
	_reward_bond_effect_scroll = nodes.get("reward_bond_effect_scroll")
	_reward_eat_effect_scroll = nodes.get("reward_eat_effect_scroll")


func _schedule_reward_scroll_reflow() -> void:
	_presentation_controller.schedule_reward_scroll_reflow(self)


func _reflow_reward_scroll_labels() -> void:
	_presentation_controller.reflow_reward_scroll_labels(
		_reward_body_scroll,
		_reward_body_label,
		_reward_bond_effect_scroll,
		_reward_bond_effect_label,
		_reward_eat_effect_scroll,
		_reward_eat_effect_label
	)


func _reflow_scroll_label_pair(scroll: ScrollContainer, label: Label) -> void:
	if scroll == null or label == null:
		return
	var inner_w: float = maxf(1.0, scroll.size.x - 10.0)
	label.custom_minimum_size.x = inner_w
	var content_h: float = label.get_minimum_size().y
	label.custom_minimum_size.y = maxf(scroll.size.y, content_h)


func _create_upgrade_overlay() -> void:
	_upgrade_overlay = ColorRect.new()
	_upgrade_overlay.name = "UpgradeOverlay"
	_upgrade_overlay.visible = false
	_upgrade_overlay.color = Color(0.01, 0.01, 0.02, 0.90)
	_upgrade_overlay.anchor_right = 1.0
	_upgrade_overlay.anchor_bottom = 1.0
	_upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_upgrade_overlay)

	_upgrade_panel = ColorRect.new()
	_upgrade_panel.name = "UpgradePanel"
	_set_shell_treatment(_upgrade_panel, Color(0.08, 0.06, 0.07, 0.98), Color(0.24, 0.18, 0.16, 0.94))
	_upgrade_panel.position = Vector2(120.0, 140.0)
	_upgrade_panel.size = Vector2(1040.0, 440.0)
	_upgrade_overlay.add_child(_upgrade_panel)

	var header := Label.new()
	header.text = "CHOOSE YOUR GROWTH"
	header.position = Vector2(0.0, 24.0)
	header.size = Vector2(1040.0, 40.0)
	_apply_text_role(header, "heading", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(header)

	var sub := Label.new()
	sub.text = "Select one evolution to anchor before the next leg"
	sub.position = Vector2(0.0, 68.0)
	sub.size = Vector2(1040.0, 24.0)
	_apply_text_role(sub, "screen_subtitle", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(sub)

	var card_w: float = 300.0
	var card_h: float = 280.0
	var gap: float = 32.0
	var start_x: float = (1040.0 - (card_w * 3 + gap * 2)) * 0.5

	for i in range(3):
		var card := ColorRect.new()
		card.name = "UpgradeCard_%d" % i
		card.position = Vector2(start_x + i * (card_w + gap), 110.0)
		card.size = Vector2(card_w, card_h)
		_set_shell_treatment(card, Color(0.12, 0.09, 0.10, 0.96), Color(0.30, 0.22, 0.20, 0.88))
		_upgrade_panel.add_child(card)
		_upgrade_card_nodes.append(card)

		var index_label := Label.new()
		index_label.text = str(i + 1)
		index_label.position = Vector2(14.0, 14.0)
		index_label.size = Vector2(24.0, 24.0)
		_apply_text_role(index_label, "card_index")
		card.add_child(index_label)

		var cat_label := Label.new()
		cat_label.name = "Category"
		cat_label.position = Vector2(14.0, 42.0)
		cat_label.size = Vector2(card_w - 28.0, 18.0)
		_apply_text_role(cat_label, "caption_strong")
		card.add_child(cat_label)

		var title_label := Label.new()
		title_label.name = "Title"
		title_label.position = Vector2(14.0, 64.0)
		title_label.size = Vector2(card_w - 28.0, 48.0)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_text_role(title_label, "card_title")
		card.add_child(title_label)

		var sep := ColorRect.new()
		sep.position = Vector2(14.0, 120.0)
		sep.size = Vector2(card_w - 28.0, 1.0)
		sep.color = Color(0.28, 0.20, 0.18, 0.50)
		card.add_child(sep)

		var body_label := Label.new()
		body_label.name = "Body"
		body_label.position = Vector2(14.0, 134.0)
		body_label.size = Vector2(card_w - 28.0, 120.0)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_text_role(body_label, "body")
		card.add_child(body_label)

	var hint := Label.new()
	hint.text = "1 / 2 / 3 - Select Upgrade"
	hint.position = Vector2(0.0, 400.0)
	hint.size = Vector2(1040.0, 24.0)
	_apply_text_role(hint, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(hint)


func _create_run_prep_overlay() -> void:
	_run_prep_overlay = ColorRect.new()
	_run_prep_overlay.name = "RunPrepOverlay"
	_run_prep_overlay.visible = false
	_run_prep_overlay.z_index = 50
	_run_prep_overlay.color = Color(0.01, 0.01, 0.02, 0.92)
	_run_prep_overlay.anchor_right = 1.0
	_run_prep_overlay.anchor_bottom = 1.0
	_run_prep_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_run_prep_overlay)

	_run_prep_panel = ColorRect.new()
	_run_prep_panel.name = "RunPrepPanel"
	_set_shell_treatment(_run_prep_panel, Color(0.07, 0.05, 0.06, 0.98), Color(0.22, 0.16, 0.14, 0.94))
	_run_prep_panel.position = Vector2(120.0, 88.0)
	_run_prep_panel.size = Vector2(1040.0, 504.0)
	_run_prep_overlay.add_child(_run_prep_panel)

	var header := Label.new()
	header.text = PRESENTATION_TEXT.RUN_PREP_HEADER
	header.position = Vector2(0.0, 16.0)
	header.size = Vector2(1040.0, 36.0)
	_apply_text_role(header, "heading", HORIZONTAL_ALIGNMENT_CENTER)
	_run_prep_panel.add_child(header)

	var sub := Label.new()
	sub.text = PRESENTATION_TEXT.RUN_PREP_SUBTITLE
	sub.position = Vector2(0.0, 52.0)
	sub.size = Vector2(1040.0, 22.0)
	_apply_text_role(sub, "screen_subtitle", HORIZONTAL_ALIGNMENT_CENTER)
	_run_prep_panel.add_child(sub)

	_run_prep_next_label = Label.new()
	_run_prep_next_label.position = Vector2(0.0, 76.0)
	_run_prep_next_label.size = Vector2(1040.0, 22.0)
	_apply_text_role(_run_prep_next_label, "caption_strong", HORIZONTAL_ALIGNMENT_CENTER)
	_run_prep_panel.add_child(_run_prep_next_label)

	_run_prep_scroll = ScrollContainer.new()
	_run_prep_scroll.name = "RunPrepScroll"
	_run_prep_scroll.position = Vector2(24.0, 106.0)
	_run_prep_scroll.size = Vector2(992.0, 330.0)
	_run_prep_panel.add_child(_run_prep_scroll)

	_run_prep_body_label = Label.new()
	_run_prep_body_label.name = "RunPrepBody"
	_run_prep_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_role(_run_prep_body_label, "body")
	_run_prep_scroll.add_child(_run_prep_body_label)

	var hint := Label.new()
	hint.text = PRESENTATION_TEXT.RUN_PREP_CONTROLS
	hint.position = Vector2(0.0, 448.0)
	hint.size = Vector2(1040.0, 44.0)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_role(hint, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	_run_prep_panel.add_child(hint)


func _creature_display_name(species_id: String) -> String:
	if species_id.is_empty():
		return "?"
	var creature: Dictionary = COMBAT_CONTENT.get_creature(species_id)
	if creature.is_empty():
		return species_id
	return String(creature.get("display_name", species_id))


func _compose_run_prep_body() -> String:
	var blocks: Array[String] = []

	var hp_line: String = "Vitals  |  HP %.0f / %.0f  |  ATK %.0f  |  DEF %.0f" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.get_attack_damage(),
		GameState.player_defense
	]
	blocks.append(hp_line)

	var growth_line: String = "Growth  |  —"
	if _run_growth != null and is_instance_valid(_run_growth):
		growth_line = "Growth  |  level %d  |  urge %.0f / %.0f" % [
			int(_run_growth.level),
			float(_run_growth.current_exp),
			float(_run_growth.exp_to_next)
		]
	blocks.append(growth_line)

	var route_line: String = "DNA harvest  |  %s" % PRESENTATION_TEXT.DNA_ROUTE_BOND_LABEL
	if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("get_dna_routing_label"):
		route_line = "DNA harvest  |  %s" % String(_run_growth.call("get_dna_routing_label"))
	blocks.append(route_line)

	if GameState.roster.is_empty():
		blocks.append("Bonds  |  none yet")
	else:
		var bond_lines: Array[String] = []
		for creature in GameState.roster:
			var sid: String = String(creature.get("species_id", ""))
			var bl: int = int(creature.get("bond_level", 1))
			bond_lines.append("%s  (bond L%d)" % [_creature_display_name(sid), bl])
		blocks.append("Bonds  |  " + "\n  ".join(PackedStringArray(bond_lines)))

	var dna_pairs: Array[Dictionary] = []
	for species_key in GameState.dna_by_species.keys():
		var sid2: String = String(species_key)
		var amt: float = GameState.get_dna(sid2)
		if amt <= 0.0001:
			continue
		dna_pairs.append({"id": sid2, "amt": amt})
	dna_pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["amt"]) > float(b["amt"]))

	if dna_pairs.is_empty():
		blocks.append("Stored DNA  |  none")
	else:
		var dna_lines: Array[String] = []
		var limit: int = mini(dna_pairs.size(), 8)
		for i in range(limit):
			var row: Dictionary = dna_pairs[i]
			dna_lines.append("%s  × %.0f" % [_creature_display_name(String(row["id"])), float(row["amt"])])
		if dna_pairs.size() > limit:
			dna_lines.append("…  +%d more species" % (dna_pairs.size() - limit))
		blocks.append("Stored DNA  |  " + "\n  ".join(PackedStringArray(dna_lines)))

	if GameState.active_mutations.is_empty():
		blocks.append("Inner work  |  no mutations yet")
	else:
		var mut_lines: Array[String] = []
		for mut in GameState.active_mutations:
			var mid: String = String(mut.get("id", "mutation"))
			var charges: int = int(mut.get("current_charges", 0))
			var effect: Dictionary = mut.get("effect", {})
			var etype: String = String(effect.get("type", ""))
			var tail: String = ("  |  " + etype) if not etype.is_empty() else ""
			mut_lines.append("%s  —  %d charges%s" % [mid, charges, tail])
		blocks.append("Inner work  |  " + "\n  ".join(PackedStringArray(mut_lines)))

	if GameState.absorbed_types.is_empty():
		blocks.append("Digestions  |  none logged")
	else:
		var digest: Array[String] = []
		var cap: int = mini(GameState.absorbed_types.size(), 6)
		for j in range(cap):
			var ab: Dictionary = GameState.absorbed_types[j]
			digest.append(
				"%s from %s"
				% [String(ab.get("eat_type", "?")), _creature_display_name(String(ab.get("source_species_id", "")))]
			)
		var more2: int = GameState.absorbed_types.size() - cap
		if more2 > 0:
			digest.append("… +%d earlier" % more2)
		blocks.append("Digestions  |  " + "\n  ".join(PackedStringArray(digest)))

	return "\n\n".join(PackedStringArray(blocks))


func _refresh_run_prep_body() -> void:
	if _run_prep_body_label == null or _run_prep_scroll == null:
		return
	_run_prep_body_label.text = _compose_run_prep_body()
	_reflow_scroll_label_pair(_run_prep_scroll, _run_prep_body_label)


func _show_run_prep_between_song_levels() -> void:
	if _run_prep_overlay == null:
		return
	_run_prep_next_label.text = (
		PRESENTATION_TEXT.RUN_PREP_NEXT_BOSS
		if _run_prep_dest_is_boss
		else PRESENTATION_TEXT.RUN_PREP_NEXT_REGULAR
	)
	_refresh_run_prep_body()
	_run_prep_overlay.visible = true
	_awaiting_run_prep = true
	controls_label.text = PRESENTATION_TEXT.RUN_PREP_CONTROLS
	_refresh_run_build_readout()


func _hide_run_prep_overlay() -> void:
	_awaiting_run_prep = false
	if _run_prep_overlay != null:
		_run_prep_overlay.visible = false


func _continue_song_after_run_prep() -> void:
	if not _awaiting_run_prep:
		return
	_hide_run_prep_overlay()
	if _run_prep_dest_is_boss:
		_trigger_boss_final_movement()
	else:
		_advance_to_next_regular_level()


func _create_live_reward_shell() -> void:
	var nodes: Dictionary = _presentation_controller.create_live_reward_shell(ui_layer)
	_live_reward_shell = nodes.get("live_reward_shell")
	_live_reward_title_label = nodes.get("live_reward_title_label")
	_live_reward_body_label = nodes.get("live_reward_body_label")
	_live_reward_hint_label = nodes.get("live_reward_hint_label")


func _create_hud_presenter() -> void:
	_hud_presenter = COMBAT_HUD_PRESENTER.new(COMBAT_CONTENT, PRESENTATION_TEXT, UI_STYLE)
	_hud_presenter.bind_nodes({
		# Static @onready nodes
		"combo_label": combo_label,
		"style_label": style_label,
		"stamina_bar": stamina_bar,
		"hp_bar": hp_bar,
		"ultimate_label": ultimate_label,
		"controls_label": controls_label,
		# Resource readout
		"hp_value_label": _hp_value_label,
		"exp_value_label": _exp_value_label,
		# Support cluster
		"support_shell": _support_shell,
		"support_bar": _support_bar,
		"support_value_label": _support_value_label,
		"support_name_label": _support_name_label,
		"support_trigger_label": _support_trigger_label,
		"support_creature_portrait": null,
		# Run build cluster
		"run_build_shell": _run_build_shell,
		"eaten_value_label": _eaten_value_label,
		"upgrade_value_label": _upgrade_value_label,
		"bond_value_label": _bond_value_label,
		"atk_value_label": _atk_value_label,
		"def_value_label": _def_value_label,
		"dna_route_label": _dna_route_label,
		"mutation_value_label": _mutation_value_label,
		# DNA HUD cluster
		"dna_shell": _dna_shell,
		"dna_emblem": _dna_emblem,
		"dna_slot_labels": _dna_slot_labels,
		# Boss bar cluster
		"boss_hp_shell": _boss_hp_shell,
		"boss_hp_bar": _boss_hp_bar,
		"boss_name_label": _boss_name_label,
		"boss_state_label": _boss_state_label,
		# Song HUD
		"song_timer_label": _song_timer_label,
		"song_phase_label": _song_phase_label,
	})


func _setup_run_growth() -> void:
	var script: Script = load(RUN_GROWTH_SCRIPT_PATH)
	if script == null:
		push_error("RunGrowth script missing: " + RUN_GROWTH_SCRIPT_PATH)
		return

	_run_growth = Node.new()
	_run_growth.name = "RunGrowth"
	_run_growth.set_script(script)
	add_child(_run_growth)
	if is_instance_valid(player_combat) and player_combat.has_method("set_run_growth"):
		player_combat.call("set_run_growth", _run_growth)


func _setup_run_stats() -> void:
	var script: Script = load(RUN_STATS_SCRIPT_PATH)
	if script == null:
		push_error("RunStats script missing: " + RUN_STATS_SCRIPT_PATH)
		return

	_run_stats = Node.new()
	_run_stats.name = "RunStats"
	_run_stats.set_script(script)
	add_child(_run_stats)

	if _run_stats.has_signal("score_changed"):
		_run_stats.connect("score_changed", Callable(self, "_on_run_score_changed"))


func _setup_performance_rewards() -> void:
	var script: Script = load(PERFORMANCE_REWARD_DIRECTOR_SCRIPT_PATH)
	if script == null:
		push_error("PerformanceRewardDirector script missing: " + PERFORMANCE_REWARD_DIRECTOR_SCRIPT_PATH)
		return

	_performance_reward_director = Node.new()
	_performance_reward_director.name = "PerformanceRewardDirector"
	_performance_reward_director.set_script(script)
	add_child(_performance_reward_director)

	if _performance_reward_director.has_method("bind_runtime"):
		_performance_reward_director.call("bind_runtime", combat_meter, _run_growth, _run_stats)
		_performance_reward_director.set("offers_enabled", false)
		if _performance_reward_director.has_method("sync_from_gamestate"):
			_performance_reward_director.call("sync_from_gamestate")

	if _performance_reward_director.has_signal("reward_claimed"):
		_performance_reward_director.connect("reward_claimed", Callable(self, "_on_performance_reward_claimed"))
	if _performance_reward_director.has_signal("proc_feedback"):
		_performance_reward_director.connect("proc_feedback", Callable(self, "_on_performance_reward_feedback"))


func _setup_performance_hud() -> void:
	if _performance_hud != null and is_instance_valid(_performance_hud):
		return
	if COMBAT_PERFORMANCE_HUD_SCENE == null:
		return
	var inst: Node = COMBAT_PERFORMANCE_HUD_SCENE.instantiate()
	if inst == null or not (inst is Control):
		if inst != null:
			inst.queue_free()
		return
	_performance_hud = inst as Control
	if _hud_right_stack != null and is_instance_valid(_hud_right_stack):
		_hud_right_stack.add_child(_performance_hud)
		_performance_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_performance_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_performance_hud.position = Vector2.ZERO
	else:
		ui_layer.add_child(_performance_hud)
		_performance_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_performance_hud.position = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_X - 14.0, 238.0)
	if _performance_reward_director != null and _performance_hud.has_method("bind_runtime"):
		_performance_hud.bind_runtime(_performance_reward_director)
	_sync_message_lane_ownership()


func _sync_compact_transient_hud_layout() -> void:
	_presentation_controller.sync_compact_transient_hud_layout(
		_hud_top_left_panel,
		_live_reward_shell,
		_performance_hud
	)


func _sync_message_lane_ownership() -> void:
	_presentation_controller.sync_message_lane_ownership(_live_reward_shell, _performance_hud)


func _center_performance_offer_shell() -> void:
	_presentation_controller.center_performance_offer_shell(_live_reward_shell, _performance_hud)


func _on_performance_reward_claimed(_reward_data: Dictionary, _source: String) -> void:
	# CombatScene-side logic for claims (e.g. SFX) can go here.
	pass


func _on_performance_reward_feedback(text: String, color: Color) -> void:
	_show_feedback(text, color, 0.34)
	# Chip feedback is handled by _performance_hud itself via signals.


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
	EventBus.proc_feedback_requested.connect(_on_proc_feedback_requested)
	EventBus.ultimate_power_granted.connect(_on_ultimate_power_granted)
	EventBus.enemy_status_applied_requested.connect(_on_enemy_status_applied_requested)
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
	EventBus.run_growth_level_resolved.connect(_on_run_growth_level_resolved)
	EventBus.tendency_growth_resolved.connect(_on_tendency_growth_resolved)
	EventBus.support_charge_changed.connect(_on_support_charge_changed)
	EventBus.creature_bonded.connect(_on_creature_bonded)
	EventBus.dna_routing_changed.connect(_on_dna_routing_changed)
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
		player_combat.call("setup", lane_manager, combat_meter)


func _start_song_run() -> void:
	_song_mode = true
	_song_elapsed = 0.0
	_set_song_paused(false)
	_song_phase_index = -1
	_song_boss_triggered = false
	_song_level_transitioning = false
	_next_song_enemy_id = 100
	_song_reward_pending = false
	_song_enemy_lanes.clear()
	_song_rng.randomize()
	_song_section_spawn_mult = 1.0
	_song_level_start_time = 0.0
	_song_level_end_time = 0.0
	_base_difficulty_modifiers = {}
	_difficulty_modifiers = {}
	if _music_control_layer != null and _music_control_layer.has_method("reset"):
		_music_control_layer.call("reset")
	_clear_mastery_context_cache()

	var region_id: String = String(GameState.active_region.get("id", "feeding_hollow"))
	_region_id = region_id if not region_id.is_empty() else "feeding_hollow"
	_active_song_data = AUDIO_CONTENT.get_region_main_run_song(_region_id)
	_active_song_map = AUDIO_CONTENT.get_region_song_map(_region_id)
	if OS.is_debug_build():
		print("CombatScene: region song route -> %s / %s" % [
			_region_id,
			String(_active_song_data.get("display_name", "Unknown"))
		])

	var song_duration: float = _resolve_active_song_duration()
	_regular_level_windows = RUN_PACING_CONTENT.build_regular_level_windows(_region_id, song_duration)
	_regular_level_index = clampi(int(_dev_harness_request.get("regular_level_index", 0)), 0, max(_regular_level_windows.size() - 1, 0))
	var regular_level_count: int = _regular_level_windows.size()
	if GameState.run_path_plan.is_empty() or GameState.run_path_plan.size() != regular_level_count:
		GameState.run_path_plan = PATH_RUN_PLAN.build_plan(_region_id, regular_level_count)
	_prepare_path_context_for_level(_regular_level_index)

	_start_regular_level(_regular_level_index, true)


func _resolve_active_song_duration() -> float:
	var song_path: String = String(_active_song_data.get("file_path", ""))
	if song_path.is_empty():
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	var stream: AudioStream = load(song_path)
	if stream == null:
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	var stream_duration: float = stream.get_length()
	if stream_duration <= 0.0:
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	return stream_duration


func _start_regular_level(level_index: int, reset_hp: bool) -> void:
	if level_index < 0 or level_index >= _regular_level_windows.size():
		_trigger_boss_final_movement()
		return

	_set_song_paused(false)
	_song_level_transitioning = false
	_regular_level_index = level_index
	var level_window: Dictionary = _regular_level_windows[_regular_level_index]
	var level_duration: float = float(level_window.get("duration", RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS))
	var level_start: float = float(level_window.get("start_time", 0.0))
	var level_end: float = float(level_window.get("end_time", level_start + level_duration))
	_song_level_start_time = level_start
	_song_level_end_time = level_end
	_song_section_spawn_mult = 1.0
	_song_phase_index = -1
	_last_beat_index = -1
	_song_elapsed = level_start
	_song_reward_pending = false
	_song_enemy_lanes.clear()
	_status_marker_overrides.clear()
	if lane_manager != null and lane_manager.has_method("stop"):
		lane_manager.stop()
	lane_manager.set_song_mode_enabled(true)

	var encounter_options: Dictionary = Dictionary(_active_path_context.get("encounter_options", {})).duplicate(true)
	_base_difficulty_modifiers = _build_level_difficulty_modifiers(encounter_options)
	encounter_options["difficulty_modifiers"] = _base_difficulty_modifiers.duplicate(true)
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	var grade_ceiling_id: String = POTENTIAL_GATE.resolve_grade_ceiling(
		active_creature,
		GameState.active_region,
		int(GameState.run_number),
		_regular_level_index,
		bool(encounter_options.get("elite", false))
	)
	encounter_options["grade_ceiling_id"] = grade_ceiling_id
	var song_run: Dictionary = ENCOUNTER_IDENTITY_RUNTIME.build_song_run(_region_id, _regular_level_index, level_duration, encounter_options)
	_song_phases = song_run.get("phases", [])
	for i in range(_song_phases.size()):
		var phase: Dictionary = _song_phases[i]
		phase["start_time"] = float(phase.get("start_time", 0.0)) + level_start
		_song_phases[i] = phase

	if _performance_reward_director != null and is_instance_valid(_performance_reward_director):
		if reset_hp and _performance_reward_director.has_method("start_song_run"):
			_performance_reward_director.call("start_song_run", _song_phases)

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
	_prepare_for_encounter(reset_hp)
	_refresh_bonded_creature_render()

	if _escalation_director != null:
		_escalation_director.setup(_region_id, _song_phases, _song_rng)
		_escalation_director.start(level_start)
	_rebuild_music_driven_difficulty()

	lane_manager.set_song_mode_enabled(true)

	if _song_timer_label != null:
		_song_timer_label.visible = true
	if _song_phase_label != null:
		_song_phase_label.visible = true
	_hud_presenter.update_song_timer(max(level_end - level_start, 0.0))

	_set_song_controls_text()

	# Enter phase 0 for this regular level and begin from its song window start.
	var start_phase_index: int = 0
	_enter_song_phase(start_phase_index)

	# Start the conductor inside this authored level window.
	_start_song_conductor(level_start, level_end)
	var level_label: String = String(level_window.get("label", "LEVEL %d" % (_regular_level_index + 1)))
	var node_name: String = String(_active_path_node.get("display_name", "Prey"))
	_show_feedback("%s  [%d/%d]  •  %s" % [level_label, _regular_level_index + 1, _regular_level_windows.size(), node_name], Color(0.90, 0.84, 0.66, 1.0), 0.48)


func _advance_to_next_regular_level() -> void:
	if _song_level_transitioning:
		return
	_song_level_transitioning = true
	var next_level_index: int = _regular_level_index + 1
	if next_level_index >= _regular_level_windows.size():
		_trigger_boss_final_movement()
		return
	_start_regular_level(next_level_index, false)


func _on_regular_level_complete() -> void:
	if _song_boss_triggered or not _song_mode:
		return
	
	# Stop all combat and pacing systems.
	if lane_manager != null and lane_manager.has_method("stop"):
		lane_manager.stop()
	if _escalation_director != null:
		_escalation_director.pause()
	_set_song_paused(true)

	var reward_creature: Dictionary = _get_level_completion_reward_creature()
	if not reward_creature.is_empty():
		_show_growth_choice_intersection(reward_creature, "song", "run_spine", false)
		return

	# Fallback: if no authored creature is available, keep existing flow.
	_show_level_completion_rewards()


func _show_level_completion_rewards() -> void:
	_hide_reward_overlay()
	_hide_run_spine_surface()
	_hide_growth_choice_surface()

	_pending_upgrades.clear()
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director):
		_pending_upgrades = _performance_reward_director.call("get_level_completion_choices", 3)

	var advancing_to_boss: bool = _regular_level_index + 1 >= _regular_level_windows.size()
	if _run_spine_surface != null and _run_spine_surface.has_method("present_level_completion"):
		_run_spine_surface.call("present_level_completion", _pending_upgrades, _run_growth, advancing_to_boss)
	if _pending_upgrades.is_empty():
		if not _try_present_predation_after_run_spine():
			_try_present_path_choice_after_run_spine()
	_show_feedback("LEVEL COMPLETE", Color(0.85, 0.95, 0.75, 1.0), 0.60)
	controls_label.text = ""


func _get_level_completion_reward_creature() -> Dictionary:
	var reward_creature: Dictionary = Dictionary(_active_encounter.get("reward_creature", {}))
	if not reward_creature.is_empty():
		return reward_creature

	# Approved v1 behavior: deterministic first item from pool when no explicit single creature exists.
	var pool: Array = _active_encounter.get("reward_creature_pool", [])
	if pool.is_empty():
		return {}
	return Dictionary(pool[0]).duplicate(true)


func _show_growth_choice_intersection(
	creature_data: Dictionary,
	source_flow: String,
	advance_target: String,
	advance_to_boss: bool
) -> void:
	if creature_data.is_empty():
		return

	_pending_reward_creature = creature_data.duplicate(true)
	_pending_reward_dna_locked = not GameState.has_dna_for(
		String(_pending_reward_creature.get("species_id", "")),
		float(_pending_reward_creature.get("dna_threshold", 0.0))
	)
	_awaiting_reward_choice = true
	_reward_choice_made = false

	var perf_summary: Dictionary = {}
	if _run_stats != null and is_instance_valid(_run_stats) and _run_stats.has_method("get_compact_summary"):
		perf_summary = _run_stats.call("get_compact_summary")

	_growth_choice_context = {
		"source_flow": source_flow,
		"advance_target": advance_target,
		"advance_to_boss": advance_to_boss
	}

	var payload: Dictionary = {
		"source_flow": source_flow,
		"advance_target": advance_target,
		"advance_to_boss": advance_to_boss,
		"creature": _pending_reward_creature.duplicate(true),
		"performance": perf_summary.duplicate(true),
		"bond_available": not _pending_reward_dna_locked,
		"eat_available": not _pending_reward_dna_locked,
		"fail_safe_pass_allowed": _pending_reward_dna_locked
	}
	GameState.set_growth_choice_intersection_payload(payload)
	EventBus.emit_signal("capture_offered", _pending_reward_creature)

	_hide_reward_overlay()
	_hide_run_spine_surface()
	if _growth_choice_surface != null and is_instance_valid(_growth_choice_surface) and _growth_choice_surface.has_method("present"):
		_growth_choice_surface.call("present")
	controls_label.text = ""
	_show_feedback("GROWTH INTERSECTION", Color(0.90, 0.80, 0.64, 1.0), 0.42)


func _create_run_spine_surface() -> void:
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface):
		return
	_run_spine_surface = RUN_SPINE_SCENE.instantiate()
	_run_spine_surface.name = "RunSpineSurface"
	_run_spine_surface.visible = false
	add_child(_run_spine_surface)
	if _run_spine_surface.has_signal("upgrade_selected"):
		_run_spine_surface.connect("upgrade_selected", Callable(self, "_on_run_spine_upgrade_selected"))
	if _run_spine_surface.has_signal("continue_requested"):
		_run_spine_surface.connect("continue_requested", Callable(self, "_on_run_spine_continue_requested"))
	if _run_spine_surface.has_signal("predation_selected"):
		_run_spine_surface.connect("predation_selected", Callable(self, "_on_run_spine_predation_selected"))
	if _run_spine_surface.has_signal("path_node_selected"):
		_run_spine_surface.connect("path_node_selected", Callable(self, "_on_run_spine_path_node_selected"))


func _create_growth_choice_surface() -> void:
	if _growth_choice_surface != null and is_instance_valid(_growth_choice_surface):
		return
	_growth_choice_surface = GROWTH_CHOICE_SCENE.instantiate()
	_growth_choice_surface.name = "GrowthChoiceSurface"
	_growth_choice_surface.visible = false
	add_child(_growth_choice_surface)
	if _growth_choice_surface.has_signal("growth_choice_selected"):
		_growth_choice_surface.connect("growth_choice_selected", Callable(self, "_on_growth_choice_selected"))


func _is_growth_choice_active() -> bool:
	return _growth_choice_surface != null and is_instance_valid(_growth_choice_surface) and _growth_choice_surface.visible


func _hide_growth_choice_surface() -> void:
	if _growth_choice_surface != null and is_instance_valid(_growth_choice_surface) and _growth_choice_surface.has_method("hide_surface"):
		_growth_choice_surface.call("hide_surface")


func _on_growth_choice_selected(choice_id: String) -> void:
	if not _is_growth_choice_active():
		return
	if _pending_reward_creature.is_empty():
		_hide_growth_choice_surface()
		GameState.clear_growth_choice_intersection_payload()
		_growth_choice_context.clear()
		return

	var resolved: bool = false
	match choice_id:
		"bond":
			resolved = _apply_pending_reward_choice("bond")
		"eat":
			resolved = _apply_pending_reward_choice("eat")
		"pass":
			if _pending_reward_dna_locked:
				_reward_choice_made = true
				_awaiting_reward_choice = false
				resolved = true

	if not resolved:
		return

	_pending_reward_creature = {}
	_pending_reward_dna_locked = false
	_hide_growth_choice_surface()
	GameState.clear_growth_choice_intersection_payload()

	var source_flow: String = String(_growth_choice_context.get("source_flow", "legacy"))
	_growth_choice_context.clear()

	if source_flow == "song":
		_show_level_completion_rewards()
	else:
		_check_for_upgrade_choices()


func _is_run_spine_active() -> bool:
	return _run_spine_surface != null and is_instance_valid(_run_spine_surface) and _run_spine_surface.visible


func _hide_run_spine_surface() -> void:
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface) and _run_spine_surface.has_method("hide_surface"):
		_run_spine_surface.call("hide_surface")


func _on_run_spine_upgrade_selected(index: int) -> void:
	if index < 0 or index >= _pending_upgrades.size():
		return
	if _performance_reward_director == null or not is_instance_valid(_performance_reward_director):
		return

	var upgrade: Dictionary = _pending_upgrades[index]
	_performance_reward_director.set("_active_offer", upgrade)
	_performance_reward_director.call("claim_active_offer", "manual")
	_performance_reward_director.call("consume_banked_reward")
	_refresh_run_build_readout()

	if _run_spine_surface != null and _run_spine_surface.has_method("notify_upgrade_committed"):
		_run_spine_surface.call("notify_upgrade_committed", index)
	_pending_upgrades.clear()
	if _try_present_predation_after_run_spine():
		return
	_try_present_path_choice_after_run_spine()


func _try_present_predation_after_run_spine() -> bool:
	_pending_predation.clear()
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("consume_pending_predation_offers"):
		_pending_predation = _performance_reward_director.call("consume_pending_predation_offers", 2)
	if _pending_predation.is_empty():
		return false
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface) and _run_spine_surface.has_method("present_predation_pool"):
		_run_spine_surface.call("present_predation_pool", _pending_predation)
		return true
	return false


func _on_run_spine_predation_selected(index: int) -> void:
	if index < 0 or index >= _pending_predation.size():
		return
	var choice: Dictionary = _pending_predation[index]
	if not PREDATION_POOL.apply_choice(choice, _run_growth):
		return
	_refresh_run_build_readout()
	_show_feedback("PREDATION TAKEN", Color(0.88, 0.62, 0.42, 1.0), 0.55)
	_pending_predation.clear()
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface) and _run_spine_surface.has_method("notify_predation_committed"):
		_run_spine_surface.call("notify_predation_committed", index)
	_try_present_path_choice_after_run_spine()


func _try_present_path_choice_after_run_spine() -> bool:
	var next_level_index: int = _regular_level_index + 1
	if next_level_index >= _regular_level_windows.size():
		return false
	if not PATH_RUN_PLAN.is_branch_slot(GameState.run_path_plan, next_level_index):
		return false
	var candidates: Array[Dictionary] = PATH_RUN_PLAN.get_branch_candidates(GameState.run_path_plan, next_level_index)
	if candidates.is_empty():
		return false
	_pending_path_choice_nodes = candidates
	_pending_path_choice_level_index = next_level_index
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface) and _run_spine_surface.has_method("present_path_choice"):
		var branch_label: String = _path_branch_label_for_level(next_level_index)
		_show_feedback(
			"PATH BRANCH %s  •  choose L%d" % [branch_label, next_level_index + 1],
			Color(0.72, 0.90, 0.98, 1.0),
			0.55
		)
		# Path choice always picks the next regular level; boss comes after level completion flow.
		_run_spine_surface.call("present_path_choice", candidates, false)
		return true
	return false


func _on_run_spine_path_node_selected(node_id: String) -> void:
	if _pending_path_choice_level_index < 0:
		return
	var valid_choice: bool = false
	for node in _pending_path_choice_nodes:
		if String(node.get("id", "")) == node_id:
			valid_choice = true
			break
	if not valid_choice:
		return
	GameState.run_path_plan = PATH_RUN_PLAN.apply_branch_choice(GameState.run_path_plan, _pending_path_choice_level_index, node_id)
	GameState.run_path_chosen_ids.append(node_id)
	var chosen_name: String = node_id.replace("_", " ").to_upper()
	for node in _pending_path_choice_nodes:
		if String(node.get("id", "")) == node_id:
			chosen_name = String(node.get("display_name", chosen_name))
			break
	_show_feedback(
		"PATH LOCKED  •  %s  ->  L%d" % [chosen_name, _pending_path_choice_level_index + 1],
		Color(0.80, 0.90, 0.66, 1.0),
		0.55
	)
	_pending_path_choice_nodes.clear()
	_pending_path_choice_level_index = -1
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface) and _run_spine_surface.has_method("notify_path_committed"):
		_run_spine_surface.call("notify_path_committed", node_id)


func _on_run_spine_continue_requested(advance_to_boss: bool) -> void:
	_hide_run_spine_surface()
	if advance_to_boss:
		_trigger_boss_final_movement()
	else:
		var next_level_index: int = _regular_level_index + 1
		if next_level_index < _regular_level_windows.size():
			_show_feedback("PATH ADVANCE  ->  L%d" % (next_level_index + 1), Color(0.70, 0.88, 0.98, 1.0), 0.45)
		_prepare_path_context_for_level(_regular_level_index + 1)
		_advance_to_next_regular_level()


func _prepare_path_context_for_level(level_index: int) -> void:
	_active_path_node = PATH_RUN_PLAN.get_level_node(GameState.run_path_plan, level_index)
	_active_path_context = PATH_RUN_PLAN.apply_node_effects(_active_path_node, GameState, _run_growth, _performance_reward_director)
	if OS.is_debug_build():
		print(
			"PathMap: preparing L%d with node=%s"
			% [level_index + 1, String(_active_path_node.get("id", "prey"))]
		)


func _path_branch_label_for_level(level_index: int) -> String:
	var branch_counter: int = 0
	for i in range(GameState.run_path_plan.size()):
		var entry: Dictionary = Dictionary(GameState.run_path_plan[i])
		if not bool(entry.get("is_branch_slot", false)):
			continue
		if int(entry.get("level_index", -1)) == level_index:
			var codepoint: int = "A".unicode_at(0) + branch_counter
			return String.chr(codepoint)
		branch_counter += 1
	return "?"


func _enter_song_phase(new_idx: int) -> void:
	var old_idx: int = _song_phase_index
	_song_phase_index = new_idx
	var new_phase: Dictionary = _song_phases[new_idx]
	var new_reward_pool: Array = new_phase.get("reward_pool", [])
	_song_phase_dna_award_index = _song_rng.randi_range(0, max(new_reward_pool.size() - 1, 0)) if not new_reward_pool.is_empty() else 0
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("enter_song_phase"):
		_performance_reward_director.call("enter_song_phase", new_idx, new_phase)

	# ─── Apply escalation profile if present ─────────────────────────────
	var profile_name = null
	if _active_encounter.has("phase_escalation_profiles"):
		var phase_profiles = _active_encounter["phase_escalation_profiles"]
		if phase_profiles is Array and _song_phase_index >= 0 and _song_phase_index < phase_profiles.size():
			profile_name = phase_profiles[_song_phase_index]
	elif _active_encounter.has("escalation_profile"):
		profile_name = _active_encounter["escalation_profile"]
	if profile_name != null and COMBAT_CONTENT.ESCALATION_PROFILES.has(profile_name):
		var profile = COMBAT_CONTENT.ESCALATION_PROFILES[profile_name]
		if lane_manager != null:
			if profile.has("cycle_interval"):
				lane_manager.set_cycle_interval(profile["cycle_interval"])
			if profile.has("fire_stagger"):
				lane_manager.set_fire_stagger(profile["fire_stagger"])

	_apply_song_phase_cadence(new_phase, _song_section_spawn_mult)

	if _song_phase_label != null:
		_song_phase_label.text = ENCOUNTER_IDENTITY_RUNTIME.get_phase_display_label(_region_id, new_phase)

	# If the previous phase had a reward pool, queue its creature offer without pausing the song.
	if old_idx >= 0:
		var old_phase: Dictionary = _song_phases[old_idx]
		var reward_pool: Array = old_phase.get("reward_pool", [])
		if not reward_pool.is_empty():
			_offer_song_phase_reward(reward_pool)


func _place_song_enemy_data(lane: int, enemy_data: Dictionary) -> void:
	var enemy: Dictionary = enemy_data.duplicate(true)
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
	var marker_data: Dictionary = _build_enemy_marker(enemy_id, lane, enemy, 42.0, inactive_color)
	
	if _enemy_marker_container != null and is_instance_valid(_enemy_marker_container):
		_enemy_marker_container.add_child(marker_data["root"])
	
	_enemy_markers_by_id[enemy_id] = marker_data

	if not lane_manager.is_combat_running():
		lane_manager.start_song_cycle()

func _offer_song_phase_reward(reward_pool: Array) -> void:
	if _escalation_director != null:
		_escalation_director.pause()
	
	var creature_id: String = reward_pool[_song_rng.randi_range(0, reward_pool.size() - 1)]
	var creature: Dictionary = COMBAT_CONTENT.get_creature(creature_id)
	if creature.is_empty():
		return

	_song_reward_pending = true
	_live_reward_queue.append(creature)
	if not _awaiting_reward_choice:
		_show_next_live_reward_offer()


func _resume_song_after_reward() -> void:
	if _escalation_director != null:
		_escalation_director.resume()
	if lane_manager != null and is_instance_valid(lane_manager):
		lane_manager.start_song_cycle()
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
	_set_song_paused(true)
	_song_mode = false
	if _escalation_director != null:
		_escalation_director.stop()
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

	# Start the boss climax track. This stops the region run song and becomes the
	# damage-race timer — kill the boss before the boss track ends or lose.
	_start_boss_music()

	# The live boss handoff is a direct encounter payload, not a queued run step.
	var boss_encounter: Dictionary = ENCOUNTER_IDENTITY_RUNTIME.build_live_boss_encounter()

	_run_finished = false
	_is_boss_encounter = false

	_hide_song_hud()
	_show_boss_race_hud()
	_load_encounter_payload(boss_encounter, false)

	if _escalation_director != null:
		# Authored boss encounters use their own phase logic in _start_current_phase;
		# clearing phases here prevents the director from trying to process them as Song phases.
		_escalation_director.setup(_region_id, [], _song_rng)


func _update_song_hud() -> void:
	var remaining: float
	if _song_conductor != null:
		# Count down to the current regular-level window end.
		remaining = max(_song_conductor.get_final_movement_time() - _song_elapsed, 0.0)
	else:
		remaining = max(_song_level_end_time - _song_elapsed, 0.0)
	_hud_presenter.update_song_timer(remaining)


func _set_song_controls_text() -> void:
	_hud_presenter.set_controls_text(PRESENTATION_TEXT.COMBAT_CONTROLS)


func _start_song_conductor(start_time: float = 0.0, end_time: float = -1.0) -> void:
	# Instantiate SongConductor, wire signals, and start playback.
	# Called at the start of each regular level window after phase 0 is entered.
	# Section signals only adjust cadence multipliers; phase transitions stay local.
	_stop_song_conductor()

	_song_conductor = SONG_CONDUCTOR_SCRIPT.new()
	_song_conductor.name = "SongConductor"
	add_child(_song_conductor)
	_song_conductor.section_changed.connect(_on_conductor_section_changed)
	_song_conductor.final_movement_reached.connect(_on_conductor_final_movement)
	_song_conductor.accent_fired.connect(_on_conductor_accent_fired)
	_song_conductor.start(_active_song_map, start_time, end_time)
	if _music_control_layer != null:
		if "BPM" in _active_song_map and _music_control_layer.has_method("set_bpm"):
			_music_control_layer.call("set_bpm", float(_active_song_map.BPM))
		if _music_control_layer.has_method("notify_section"):
			_music_control_layer.call("notify_section", String(_song_conductor.current_section_id), {
				"intensity": float(_song_conductor.current_intensity)
			})
	player_combat.call("set_song_conductor", _song_conductor)
	if _song_conductor != null:
		_hud_presenter.update_song_timer(max(_song_conductor.get_final_movement_time() - start_time, 0.0))


func is_song_paused() -> bool:
	return _song_paused


func _set_song_paused(paused: bool) -> void:
	if _song_paused == paused:
		return
	_song_paused = paused
	if _song_conductor != null and is_instance_valid(_song_conductor):
		if paused:
			_song_conductor.pause()
		else:
			_song_conductor.resume()


func _on_conductor_section_changed(section_id: String, data: Dictionary) -> void:
	# Section changes are used as cadence modulation only.
	# Regular-level phase transitions are time-authored per level window.
	_song_section_spawn_mult = float(data.get("spawn_interval_mult", 1.0))
	if section_id == "final":
		_song_section_spawn_mult = min(_song_section_spawn_mult, 0.86)
	if _music_control_layer != null and _music_control_layer.has_method("notify_section"):
		_music_control_layer.call("notify_section", section_id, data)
	_rebuild_music_driven_difficulty()
	if _song_phase_index >= 0 and _song_phase_index < _song_phases.size():
		_apply_song_phase_cadence(_song_phases[_song_phase_index], _song_section_spawn_mult)


func _on_conductor_final_movement() -> void:
	# End of the current regular-level window.
	if not _song_boss_triggered and _song_mode and not _run_finished:
		_on_regular_level_complete()


func _on_conductor_accent_fired() -> void:
	# Bass drop / accent detected in the WAV.
	# Pull forward the next authored threat cycle.
	if not _song_mode or _run_finished:
		return
	if _music_control_layer != null and _music_control_layer.has_method("notify_accent"):
		_music_control_layer.call("notify_accent")
	_rebuild_music_driven_difficulty()
		
	if lane_manager != null and is_instance_valid(lane_manager):
		lane_manager.trigger_accent_burst()
	
	# Small HUD pulse feedback for the accent
	if _presentation_runtime != null:
		_presentation_runtime.on_beat_pulse("accent", 1.2)


func _hide_song_hud() -> void:
	_hud_presenter.hide_song_hud()


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
	_hud_presenter.show_boss_race_hud("KILL IT BEFORE THE SONG ENDS")


func _update_boss_race_hud() -> void:
	if _boss_music_player == null or not is_instance_valid(_boss_music_player):
		return
	var elapsed: float = _boss_music_player.get_playback_position()
	var remaining: float = max(_boss_music_duration - elapsed, 0.0)
	_hud_presenter.update_boss_race_timer(remaining, _boss_music_duration)


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
		var marker_data: Dictionary = _enemy_markers_by_id[enemy_id]
		# Never override a status color.
		if _status_marker_overrides.has(enemy_id):
			continue
		var enemy_phase: int = int(_enemy_phase_by_id.get(enemy_id, -1))
		if enemy_phase == _current_phase_index:
			var body_node = marker_data.get("body")
			if is_instance_valid(body_node):
				var marker_body: ColorRect = body_node
				marker_body.color = pulsed_color


func _on_boss_music_finished() -> void:
	# Called when the boss track plays to its end.
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
		player_combat.call("set_combat_enabled", false)
	_show_feedback("THE SONG DEVOURED YOU", Color(1.0, 0.28, 0.22, 1.0), 0.80)
	EventBus.emit_signal("screen_flash", Color(0.55, 0.06, 0.06, 0.28), 0.40)
	await get_tree().create_timer(0.8).timeout
	if not _run_finished:
		_finish_run(false)


func get_current_song_section_id() -> String:
	# Used by LaneManager to stamp shot_modifier onto each fired projectile.
	if _song_conductor == null or not is_instance_valid(_song_conductor):
		return ""
	return String(_song_conductor.current_section_id)


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
	if not GameState.run_in_progress:
		GameState.run_number += 1
		_texture_cache.clear()
		_apply_dev_harness_region_override()
		if GameState.has_method("reset_run_state"):
			GameState.reset_run_state()
		if _performance_reward_director != null and _performance_reward_director.has_method("reset_full_run_data"):
			_performance_reward_director.call("reset_full_run_data")
		GameState.run_in_progress = true
		
	_run_finished = false
	_is_boss_encounter = false
	_boss_total_hp = 0.0
	_boss_current_hp = 0.0
	_hide_boss_bar()
	_hide_reward_overlay()
	_apply_dev_harness_pre_run_state()

	EventBus.emit_signal("run_started", int(GameState.run_number))
	_last_beat_index = -1
	_live_reward_queue.clear()
	_song_reward_pending = false
	_regular_level_windows.clear()
	_regular_level_index = 0
	_pending_path_choice_nodes.clear()
	_pending_path_choice_level_index = -1
	_active_path_node.clear()
	_active_path_context.clear()
	_song_level_end_time = 0.0
	_song_level_transitioning = false
	_hide_live_reward_shell()
	_hide_run_spine_surface()
	_hide_growth_choice_surface()
	_growth_choice_context.clear()
	GameState.clear_growth_choice_intersection_payload()
	_refresh_run_build_readout()
	_start_song_run()


func _apply_dev_harness_region_override() -> void:
	if _dev_harness_request.is_empty():
		return
	var requested_region_id: String = String(_dev_harness_request.get("region_id", ""))
	if requested_region_id.is_empty():
		return
	for region in ROUTE_CONTENT.REGIONS:
		if String(region.get("id", "")) == requested_region_id:
			GameState.set_active_region(region)
			return


func _apply_dev_harness_pre_run_state() -> void:
	if _dev_harness_request.is_empty():
		return

	var support_species_id: String = String(_dev_harness_request.get("support_species_id", ""))
	if not support_species_id.is_empty():
		var bonded_creature: Dictionary = COMBAT_CONTENT.get_creature(support_species_id)
		if not bonded_creature.is_empty():
			bonded_creature["bond_level"] = max(int(_dev_harness_request.get("support_bond_level", 2)), 1)
			bonded_creature["bond_order"] = 1
			GameState.roster = [bonded_creature]

	var dna_seed: Dictionary = _dev_harness_request.get("dna_seed", {})
	if not dna_seed.is_empty():
		GameState.dna_by_species = dna_seed.duplicate(true)

	var absorbed_species_ids: Array = _dev_harness_request.get("absorbed_species_ids", [])
	for species_id in absorbed_species_ids:
		var creature: Dictionary = COMBAT_CONTENT.get_creature(String(species_id))
		if not creature.is_empty():
			GameState.absorb_creature_type(creature)


func _apply_dev_harness_post_boot_state() -> void:
	if _dev_harness_request.is_empty():
		return

	var run_growth_state: Dictionary = _dev_harness_request.get("run_growth", {})
	if not run_growth_state.is_empty() and _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("apply_debug_state"):
		_run_growth.call("apply_debug_state", run_growth_state)

	if _dev_harness_request.has("player_hp_ratio"):
		_debug_set_player_hp_ratio(float(_dev_harness_request.get("player_hp_ratio", 1.0)))

	var reward_species_id: String = String(_dev_harness_request.get("preview_live_reward_species_id", ""))
	if not reward_species_id.is_empty():
		var reward_creature: Dictionary = COMBAT_CONTENT.get_creature(reward_species_id)
		if not reward_creature.is_empty():
			_show_live_reward_offer(reward_creature)

	if String(_dev_harness_request.get("start_mode", "song")) == "boss":
		await _debug_begin_boss_preview(bool(_dev_harness_request.get("trigger_boss_threshold", false)))

	DevHarness.clear_request()
	_dev_harness_request.clear()


func _debug_set_player_hp_ratio(ratio: float) -> void:
	var clamped_ratio: float = clampf(ratio, 0.15, 1.0)
	GameState.player_hp = max(GameState.player_max_hp * clamped_ratio, 1.0)
	_hud_presenter.refresh_hp(GameState.player_hp, GameState.player_max_hp)


func _debug_begin_boss_preview(trigger_threshold: bool) -> void:
	_trigger_boss_final_movement()
	await get_tree().create_timer(1.7).timeout
	if trigger_threshold and _is_boss_encounter:
		_debug_apply_boss_threshold_preview()


func _debug_apply_boss_threshold_preview() -> void:
	if _boss_total_hp <= 0.0 or _hud_presenter == null:
		return
	_boss_current_hp = _boss_total_hp * 0.5
	_hud_presenter.update_boss_hp(_boss_current_hp)
	if not _boss_hp_threshold_fired:
		_boss_hp_threshold_fired = true
		_show_feedback("SOVEREIGN UNLEASH", Color(0.92, 0.42, 0.12, 1.0), 0.70)
		if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("notify_boss_threshold"):
			_performance_reward_director.call("notify_boss_threshold", "sovereign_unleash", 8.0, "BOSS BREAK")
		_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_boss_threshold_profile())
		_trigger_boss_threshold_spectacle()
		lane_manager.set_cycle_interval(0.60)
		lane_manager.set_fire_stagger(0.44)


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
	var phases: Array = _active_encounter.get("phases", [])
	if phases.is_empty():
		return

	_all_enemies_by_id.clear()
	_enemy_phase_by_id.clear()

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
	if _end_stats_label != null:
		_end_stats_label.visible = false


func _build_arena_visuals() -> void:
	var refs: Dictionary = _presentation_controller.build_arena_visuals(
		self,
		_active_encounter,
		lane_manager,
		_all_enemies_by_id,
		_enemy_phase_by_id,
		_enemy_markers_by_id,
		_enemy_max_hp,
		_lane_strips,
		_lane_hit_focus,
		_status_marker_overrides,
		_current_phase_index,
		_is_boss_encounter,
		_texture_cache,
		_lane_marker_container,
		_enemy_marker_container
	)
	_lane_marker_container = refs.get("lane_marker_container")
	_enemy_marker_container = refs.get("enemy_marker_container")


func _refresh_enemy_marker_states() -> void:
	_presentation_controller.refresh_enemy_marker_states(
		_active_encounter,
		_enemy_markers_by_id,
		_enemy_phase_by_id,
		_status_marker_overrides,
		_current_phase_index
	)


func _build_enemy_marker(enemy_id: int, lane: int, enemy: Dictionary, marker_size: float, base_color: Color) -> Dictionary:
	return _presentation_controller._build_enemy_marker(
		enemy_id,
		lane,
		enemy,
		marker_size,
		base_color,
		lane_manager,
		_texture_cache
	)

func _configure_enemy_marker_shape(accent: ColorRect, sigil: ColorRect, marker_size: float, family: String) -> void:
	_presentation_controller._configure_enemy_marker_shape(accent, sigil, marker_size, family)


func _tune_enemy_silhouette_color(requested: Color, body_color: Color) -> Color:
	return _presentation_controller._tune_enemy_silhouette_color(requested, body_color)


func _update_enemy_marker_threat_states() -> void:
	_presentation_controller.update_enemy_marker_threat_states(
		_enemy_markers_by_id,
		_all_enemies_by_id,
		lane_manager
	)


func _draw_timing_circles() -> void:
	_presentation_controller.draw_timing_circles(
		_timing_circle_container,
		_timing_rings_cache,
		_active_encounter,
		lane_manager,
		player_combat
	)


func _make_ring_line(radius: float, color: Color, width: float) -> Line2D:
	return _presentation_controller._make_ring_line(radius, color, width)


func _make_disc_polygon(radius: float, color: Color) -> Polygon2D:
	return _presentation_controller._make_disc_polygon(radius, color)


func _prepare_for_encounter(reset_hp: bool) -> void:
	# Resets encounter-local state. HP only resets at run start, not between encounters.
	if reset_hp:
		GameState.player_hp = GameState.player_max_hp

	_hud_presenter.refresh_hp(GameState.player_hp, GameState.player_max_hp)

	if player_combat.has_method("set_combat_enabled"):
		player_combat.call("set_combat_enabled", true)

	if combat_meter.has_method("reset"):
		combat_meter.call("reset")

	_hide_reward_overlay()
	result_label.visible = false
	result_label.text = ""
	if _end_stats_label != null:
		_end_stats_label.visible = false
	_set_combat_controls_text()


func _set_combat_controls_text() -> void:
	if _song_mode:
		_set_song_controls_text()
		return
	if _is_boss_encounter:
		controls_label.text = PRESENTATION_TEXT.COMBAT_BOSS_CONTROLS
	else:
		controls_label.text = PRESENTATION_TEXT.COMBAT_CONTROLS


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
		player_combat.call("set_combat_enabled", false)

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
		_show_growth_choice_intersection(reward_creature, "legacy", "route", false)
		return

	_refresh_run_build_readout()
	_check_for_upgrade_choices()


func _check_for_upgrade_choices() -> void:
	var banked: int = 0
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director):
		banked = int(_performance_reward_director.get("banked_reward_count"))
	
	if banked > 0:
		_show_upgrade_choices()
	else:
		_advance_to_next_stage()


func _show_upgrade_choices() -> void:
	_hide_reward_overlay()
	_awaiting_upgrade_choice = true
	_pending_upgrades = _performance_reward_director.call("get_upgrade_choices", 3)
	
	for i in range(3):
		var card := _upgrade_card_nodes[i] as ColorRect
		if i < _pending_upgrades.size():
			var up: Dictionary = _pending_upgrades[i]
			card.visible = true
			card.get_node("Category").text = String(up.get("tag", "UPGRADE"))
			card.get_node("Title").text = String(up.get("title", "Unknown"))
			card.get_node("Body").text = String(up.get("summary", ""))
		else:
			card.visible = false
			
	_upgrade_overlay.visible = true
	controls_label.text = PRESENTATION_TEXT.RUN_SPINE_EVOLUTION_CONTROLS


func _choose_upgrade(index: int) -> void:
	if index < 0 or index >= _pending_upgrades.size():
		return
	
	var up: Dictionary = _pending_upgrades[index]
	_performance_reward_director.set("_active_offer", up)
	_performance_reward_director.call("claim_active_offer", "manual")
	_performance_reward_director.call("consume_banked_reward")
	
	_awaiting_upgrade_choice = false
	_upgrade_overlay.visible = false
	
	# After choosing, determine if we continue the song run or finish/boss.
	if _song_mode:
		_run_prep_dest_is_boss = _regular_level_index + 1 >= _regular_level_windows.size()
		_show_run_prep_between_song_levels()
	else:
		_advance_to_next_stage()


func _advance_to_next_stage() -> void:
	if _is_boss_encounter:
		_finish_run(true)
	else:
		# Transition back to RouteScene to choose next level
		get_tree().change_scene_to_file("res://scenes/ui/RouteScene.tscn")


func _finish_run(victory: bool) -> void:
	# Final state for the whole run.
	_run_finished = true
	_combat_finished = true
	_phase_transitioning = false
	_hide_run_spine_surface()
	_hide_growth_choice_surface()
	_growth_choice_context.clear()
	GameState.clear_growth_choice_intersection_payload()
	GameState.run_in_progress = false

	_stop_boss_music()
	_stop_song_conductor()
	_hide_song_hud()
	_hide_boss_bar()

	if lane_manager != null and lane_manager.has_method("stop"):
		lane_manager.stop()

	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.call("set_combat_enabled", false)

	if victory:
		result_label.text = "RUN COMPLETE"
		result_label.visible = true
		_show_feedback("THE HOLLOW REMEMBERS YOU", Color(0.85, 1.0, 0.75, 1.0), 0.70)
		controls_label.text = PRESENTATION_TEXT.RUN_END_CONTROLS_VICTORY
	else:
		result_label.text = "RUN FAILED"
		result_label.visible = true
		_show_feedback("RUN FAILED", Color(1.0, 0.45, 0.45, 1.0), 0.65)
		controls_label.text = PRESENTATION_TEXT.RUN_END_CONTROLS_FAILURE

	_show_end_stats()
	_hide_reward_overlay()
	_hide_live_reward_shell()
	_live_reward_queue.clear()

func _show_boss_bar() -> void:
	_hud_presenter.show_boss_bar()


func _hide_boss_bar() -> void:
	_hud_presenter.hide_boss_bar()


func _setup_boss_hp_bar() -> void:
	_boss_total_hp = 0.0
	var phases: Array = _active_encounter.get("phases", [])
	for phase in phases:
		for enemy in phase:
			_boss_total_hp += float(enemy.get("hp", 0))
	_boss_current_hp = _boss_total_hp
	_hud_presenter.setup_boss_bar(
		_boss_total_hp,
		String(_active_encounter.get("boss_name", "")),
		PRESENTATION_TEXT.BOSS_STATE_OPENING
	)


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


func _show_feedback(text: String, color: Color, lifetime: float = COMBAT_FEEL_CONTENT.COMBAT_FEEDBACK_MIN_LIFETIME) -> void:
	var punch: float = COMBAT_FEEL_CONTENT.HUD_COMBAT_FEEDBACK_PUNCH_SCALE
	_feedback_label.text = text
	_feedback_label.modulate = color
	_feedback_label.visible = true
	if _feedback_backing != null:
		_feedback_backing.visible = true
		_feedback_backing.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_feedback_backing.scale = Vector2(punch, punch)
	_feedback_label.scale = Vector2(punch, punch)

	var tween := create_tween()
	tween.tween_property(_feedback_label, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if _feedback_backing != null:
		tween.parallel().tween_property(_feedback_backing, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_interval(max(lifetime, COMBAT_FEEL_CONTENT.COMBAT_FEEDBACK_MIN_LIFETIME))
	tween.tween_property(_feedback_label, "modulate:a", 0.0, COMBAT_FEEL_CONTENT.COMBAT_FEEDBACK_FADE_TIME)
	if _feedback_backing != null:
		tween.parallel().tween_property(_feedback_backing, "modulate:a", 0.0, COMBAT_FEEL_CONTENT.COMBAT_FEEDBACK_FADE_TIME)
	tween.tween_callback(func() -> void:
		_feedback_label.visible = false
		_feedback_label.modulate.a = 1.0
		_feedback_label.scale = Vector2.ONE
		if _feedback_backing != null:
			_feedback_backing.visible = false
			_feedback_backing.modulate.a = 1.0
			_feedback_backing.scale = Vector2.ONE
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
	tween.tween_interval(COMBAT_FEEL_CONTENT.BEAT_FEEDBACK_HOLD_TIME)
	tween.tween_property(_beat_feedback_label, "modulate:a", 0.0, COMBAT_FEEL_CONTENT.BEAT_FEEDBACK_FADE_TIME)
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

	_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_CREATURE
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
		_dna_line = PRESENTATION_TEXT.dna_status_line(_player_dna, _offer_dna_threshold, _pending_reward_dna_locked)
		_reward_body_label.text = _body_text + "\n\n" + _dna_line
	else:
		_reward_body_label.text = _body_text

	if _pending_reward_dna_locked:
		_reward_bond_label.text = PRESENTATION_TEXT.reward_bond_label(true)
		var active_bond_level: int = int(_pending_reward_creature.get("bond_level", 1))
		@warning_ignore("static_called_on_instance")
		var level_mult: float = GameState.get_bond_level_mult(active_bond_level)
		_reward_bond_effect_label.text = PRESENTATION_TEXT.reward_locked_effect_body(
			PRESENTATION_TEXT.format_bond_passive_long(_pending_reward_creature.get("bond_passive", {}), level_mult)
		)
		_reward_eat_label.text = PRESENTATION_TEXT.reward_eat_label(true)
		_reward_eat_effect_label.text = PRESENTATION_TEXT.reward_locked_effect_body(
			PRESENTATION_TEXT.format_eat_effect(_pending_reward_creature.get("eat_effect", {}))
		)
		_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_LOCKED
		controls_label.text = PRESENTATION_TEXT.REWARD_CONTROLS_LOCKED
	else:
		_reward_bond_label.text = PRESENTATION_TEXT.reward_bond_label(false)
		var active_bond_level: int = int(_pending_reward_creature.get("bond_level", 1))
		@warning_ignore("static_called_on_instance")
		var level_mult: float = GameState.get_bond_level_mult(active_bond_level)
		_reward_bond_effect_label.text = PRESENTATION_TEXT.reward_bond_body(
			PRESENTATION_TEXT.format_bond_passive_long(_pending_reward_creature.get("bond_passive", {}), level_mult)
		)
		_reward_eat_label.text = PRESENTATION_TEXT.reward_eat_label(false)
		var mutation_summary: String = String(_pending_reward_creature.get("mutation", {}).get("summary", ""))
		var eat_effect_text: String = PRESENTATION_TEXT.format_eat_effect(_pending_reward_creature.get("eat_effect", {}))
		if not mutation_summary.is_empty():
			eat_effect_text += "\n\nMutation: %s" % mutation_summary
			
		_reward_eat_effect_label.text = PRESENTATION_TEXT.reward_eat_body(eat_effect_text)
		_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_CHOICE
		controls_label.text = PRESENTATION_TEXT.REWARD_CONTROLS_CHOICE

	_reward_quig_label.text = String(_pending_reward_creature.get("quig_offer_text", ""))
	_refresh_quig_ui_state()

	# Load and show creature portrait if art is available.
	if _reward_creature_portrait != null:
		var reward_species_id: String = String(_pending_reward_creature.get("species_id", ""))
		var sprite_path: String = COMBAT_CONTENT.get_creature_art_path(reward_species_id, "reward")
		if sprite_path.is_empty():
			sprite_path = String(_pending_reward_creature.get("sprite_path", ""))
		if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			var portrait_tex: Texture2D = load(sprite_path) as Texture2D
			if portrait_tex != null:
				_reward_creature_portrait.texture = portrait_tex
				_reward_creature_portrait.visible = true
			else:
				_reward_creature_portrait.visible = false
		else:
			_reward_creature_portrait.visible = false

	_schedule_reward_scroll_reflow()


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
	_refresh_quig_ui_state()
	_schedule_reward_scroll_reflow()


func _refresh_run_build_readout() -> void:
	_hud_presenter.refresh_run_build(_run_growth)
	_refresh_dna_hud()


func _refresh_dna_hud() -> void:
	_hud_presenter.refresh_dna_hud(_song_mode, _song_phase_index, _song_phases, _pending_reward_creature)


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
	_refresh_quig_ui_state()
	_sync_message_lane_ownership()


func _refresh_live_reward_shell() -> void:
	if _live_reward_shell == null or _pending_reward_creature.is_empty():
		return

	var species_id: String = String(_pending_reward_creature.get("species_id", ""))
	var threshold: float = float(_pending_reward_creature.get("dna_threshold", 0.0))
	var current_dna: float = GameState.get_dna(species_id)
	var display_name: String = String(_pending_reward_creature.get("display_name", "Creature"))
	var encounter_context: String = _describe_creature_offer_context(_pending_reward_creature)
	_live_reward_title_label.text = PRESENTATION_TEXT.live_reward_title(display_name)
	var live_body: String = _compact_hud_copy(String(_pending_reward_creature.get("description", "")), 30)
	if not encounter_context.is_empty():
		live_body += "  %s" % _compact_hud_copy(encounter_context, 12)
	live_body += "\n%s" % PRESENTATION_TEXT.live_dna_gate_line(current_dna, threshold)
	_live_reward_body_label.text = live_body
	_live_reward_hint_label.text = PRESENTATION_TEXT.live_reward_hint(_pending_reward_dna_locked, _live_reward_offer_timer)


func _compact_hud_copy(text: String, max_length: int) -> String:
	var compact: String = " ".join(text.split("\n", false)).strip_edges()
	if compact.length() <= max_length:
		return compact
	if max_length <= 3:
		return compact.left(max_length)
	return compact.left(max_length - 3).strip_edges() + "..."


func _hide_live_reward_shell() -> void:
	if _live_reward_shell != null:
		_live_reward_shell.visible = false
	_live_reward_offer_timer = 0.0
	_refresh_quig_ui_state()
	_sync_message_lane_ownership()


func _refresh_song_controls_text() -> void:
	if _song_reward_pending and _awaiting_reward_choice:
		if _pending_reward_dna_locked:
			_hud_presenter.set_controls_text(PRESENTATION_TEXT.LIVE_CONTROLS_LOCKED)
		else:
			_hud_presenter.set_controls_text(PRESENTATION_TEXT.LIVE_CONTROLS_CHOICE)
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


func _apply_pending_reward_choice(choice_id: String) -> bool:
	if not _awaiting_reward_choice or _reward_choice_made:
		return false
	if choice_id != "bond" and choice_id != "eat":
		return false

	var species_id: String = String(_pending_reward_creature.get("species_id", ""))
	var threshold: float = float(_pending_reward_creature.get("dna_threshold", 0.0))
	if not GameState.has_dna_for(species_id, threshold):
		_pending_reward_dna_locked = true
		return false

	GameState.spend_dna(species_id, threshold)
	_pending_reward_dna_locked = false

	if choice_id == "bond":
		var updated_creature: Dictionary = GameState.add_bonded_creature(_pending_reward_creature)
		EventBus.emit_signal("creature_bonded", updated_creature)
		_reward_choice_made = true
		_awaiting_reward_choice = false
		_refresh_run_build_readout()
		return true

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
	_reward_choice_made = true
	_awaiting_reward_choice = false
	_refresh_run_build_readout()
	return true


func _choose_bond() -> void:
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	var _bond_species: String = String(_pending_reward_creature.get("species_id", ""))
	if not _apply_pending_reward_choice("bond"):
		_show_feedback("NOT ENOUGH DNA", Color(0.92, 0.46, 0.28, 1.0), 0.42)
		return

	var _bond_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	var updated_creature: Dictionary = GameState.get_bonded_creature(_bond_species)
	var _new_bond_level: int = int(updated_creature.get("bond_level", 1))
	var _bond_deepened: bool = _new_bond_level > 1
	_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_BONDED
	_reward_title_label.text = "%s deepens." % _bond_creature_name if _bond_deepened else "%s bonded." % _bond_creature_name
	_reward_body_label.text = PRESENTATION_TEXT.bond_result_body(_bond_creature_name, _new_bond_level)
	_reward_bond_label.text = "Bond L%d" % _new_bond_level if _bond_deepened else "Bonded"
	@warning_ignore("static_called_on_instance")
	_reward_bond_effect_label.text = PRESENTATION_TEXT.format_bond_passive_long(
		_pending_reward_creature.get("bond_passive", {}), 
		GameState.get_bond_level_mult(_new_bond_level)
	)
	_reward_eat_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_quig_label.text = PRESENTATION_TEXT.bond_result_quig(_bond_creature_name)

	# Evolutionary update: reflect the new growth stage in the portrait.
	var _new_growth_stage: String = GameState.get_creature_growth_stage(_new_bond_level)
	var _new_portrait: String = COMBAT_CONTENT.get_creature_art_path(_bond_species, "support", _new_growth_stage)
	if not _new_portrait.is_empty() and ResourceLoader.exists(_new_portrait):
		var _port_tex: Texture2D = load(_new_portrait) as Texture2D
		if _port_tex != null:
			_reward_creature_portrait.texture = _port_tex

	_refresh_quig_ui_state()
	_schedule_reward_scroll_reflow()

	if _song_reward_pending:
		_resume_song_after_reward()
	else:
		_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_WAIT
		controls_label.text = ""
		_check_for_upgrade_choices()


func _choose_eat() -> void:
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	if not _apply_pending_reward_choice("eat"):
		_show_feedback("NOT ENOUGH DNA", Color(0.92, 0.46, 0.28, 1.0), 0.42)
		return

	var absorbed_entry: Dictionary = {}
	if not GameState.absorbed_types.is_empty():
		absorbed_entry = Dictionary(GameState.absorbed_types[GameState.absorbed_types.size() - 1]).duplicate(true)
	var _eat_creature_name: String = String(_pending_reward_creature.get("display_name", "creature"))
	_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_EATEN
	_reward_title_label.text = "%s consumed." % _eat_creature_name
	_reward_body_label.text = PRESENTATION_TEXT.eat_result_body()
	_reward_bond_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_label.text = "Absorbed"
	var mutation_summary: String = String(_pending_reward_creature.get("mutation", {}).get("summary", ""))
	var mutation_line: String = "\n\nMutation gained: %s" % mutation_summary if not mutation_summary.is_empty() else ""

	var _eat_type_str: String = String(absorbed_entry.get("eat_type", "damage_flat"))
	if _eat_type_str == "hp_restore":
		_reward_eat_effect_label.text = "Type: %s\n\n+%.0f HP restored.\nNo permanent bonus.%s" % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("heal_applied", 0.0)),
			mutation_line
		]
	elif _eat_type_str == "max_hp_flat":
		_reward_eat_effect_label.text = "Type: %s\n\n+%.0f max HP.\n+%.0f HP restored.%s" % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("max_hp_bonus", 0.0)),
			float(absorbed_entry.get("heal_applied", 0.0)),
			mutation_line
		]
	elif _eat_type_str == "support_charge":
		_reward_eat_effect_label.text = "Type: %s\n\n+%.0f support charge immediately.%s" % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("support_charge_bonus", 0.0)),
			mutation_line
		]
	else:
		_reward_eat_effect_label.text = "Type: %s\n\n+%.1f permanent attack damage%s" % [
			String(absorbed_entry.get("type", "unknown")).capitalize(),
			float(absorbed_entry.get("damage_bonus", 0.0)),
			mutation_line
		]
	_reward_quig_label.text = PRESENTATION_TEXT.eat_result_quig(_eat_creature_name)
	_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_WAIT
	_refresh_quig_ui_state()
	_schedule_reward_scroll_reflow()

	if _song_reward_pending:
		_show_feedback("%s CONSUMED" % _eat_creature_name.to_upper(), Color(0.94, 0.62, 0.30, 1.0), 0.34)
		_resume_song_after_reward()
		return

	var timer: SceneTreeTimer = get_tree().create_timer(3.0)
	await timer.timeout

	if not _reward_choice_made:
		return

	_reward_quig_label.text = "Quig: \"There will be others. They may remember this.\""
	_refresh_quig_ui_state()

	if _song_reward_pending:
		_show_feedback("REWARD PASSED", Color(0.76, 0.60, 0.42, 1.0), 0.24)
		_resume_song_after_reward()
	else:
		_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_WAIT
		controls_label.text = ""
		_check_for_upgrade_choices()


func _pass_reward() -> void:
	# Player opts out of the current reward offer.
	# Fires when the player presses N — also the only valid action when DNA-locked.
	if not _awaiting_reward_choice or _reward_choice_made:
		return

	_reward_choice_made = true
	_awaiting_reward_choice = false
	_pending_reward_dna_locked = false
	_pending_reward_creature = {}

	_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_PASSED
	_reward_title_label.text = PRESENTATION_TEXT.REWARD_TITLE_PASSED
	_reward_body_label.text = PRESENTATION_TEXT.REWARD_BODY_PASSED
	_reward_bond_label.text = ""
	_reward_eat_label.text = ""
	_reward_bond_effect_label.text = ""
	_reward_eat_effect_label.text = ""
	_reward_quig_label.text = PRESENTATION_TEXT.pass_result_quig()
	_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_WAIT
	controls_label.text = ""
	_refresh_quig_ui_state()
	_schedule_reward_scroll_reflow()

	if _song_reward_pending:
		_show_feedback("REWARD PASSED", Color(0.76, 0.60, 0.42, 1.0), 0.24)
		_resume_song_after_reward()
	else:
		_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_WAIT
		controls_label.text = ""
		_check_for_upgrade_choices()


func _on_combo_changed(count: int, tier: String) -> void:
	_hud_presenter.refresh_combo(count, tier)


func _on_run_score_changed(score: int) -> void:
	if _run_score_label != null:
		_run_score_label.text = "%d" % score


func _show_end_stats() -> void:
	if _end_stats_label == null or _run_stats == null or not is_instance_valid(_run_stats):
		return

	var kills: int = int(_run_stats.get("kills"))
	var dmg: int = int(_run_stats.get("damage_dealt"))
	var p_att: int = int(_run_stats.get("perfect_attacks"))
	var g_att: int = int(_run_stats.get("good_attacks"))
	var p_par: int = int(_run_stats.get("perfect_parries"))
	var g_par: int = int(_run_stats.get("good_parries"))
	var ult: int = int(_run_stats.get("ultimates_fired"))
	var sup: int = int(_run_stats.get("support_triggers"))
	var surges: int = int(_run_stats.get("tendency_surges"))
	var hit: int = int(_run_stats.get("times_hit"))
	var bonds: int = int(_run_stats.get("bonds"))
	var eats: int = int(_run_stats.get("eats"))
	var score: int = int(_run_stats.get("run_score"))
	var grade: String = _run_stats.call("get_grade") if _run_stats.has_method("get_grade") else "—"

	var growth_level: int = 1
	if _run_growth != null and is_instance_valid(_run_growth):
		growth_level = int(_run_growth.level)

	_end_stats_label.text = (
		"[ %s ]  %d pts\n\n" % [grade, score]
		+ "Kills %d    Damage %d    Hits taken %d\n" % [kills, dmg, hit]
		+ "Perfect %d  Good %d    Parries %d+%d\n" % [p_att, g_att, p_par, g_par]
		+ "Ultimates %d    Support %d    Surges %d\n" % [ult, sup, surges]
		+ "Bonded %d    Eaten %d    Level %d" % [bonds, eats, growth_level]
	)
	_end_stats_label.visible = true


func _on_style_changed(_score: float, tier: String) -> void:
	_hud_presenter.refresh_style(tier)


func _on_dna_gained(_species_id: String, _amount: float, _total: float) -> void:
	_refresh_dna_hud()
	if _song_reward_pending and _awaiting_reward_choice:
		_pending_reward_dna_locked = not GameState.has_dna_for(
			String(_pending_reward_creature.get("species_id", "")),
			float(_pending_reward_creature.get("dna_threshold", 0.0))
		)
		_refresh_live_reward_shell()
		_refresh_song_controls_text()


func _on_dna_routing_changed(route_id: String, label: String) -> void:
	var route_color: Color = Color(0.82, 0.96, 0.82, 1.0) if route_id == "bond" else Color(0.96, 0.84, 0.62, 1.0)
	if _dna_route_label != null:
		_dna_route_label.text = label
		_dna_route_label.modulate = route_color
	
	if _dna_route_shell != null:
		var tween := create_tween()
		_dna_route_shell.modulate = Color(1.5, 1.5, 1.5, 1.0)
		tween.tween_property(_dna_route_shell, "modulate", Color.WHITE, 0.25)
	
	_show_feedback(label, route_color, 0.20)
	if _is_run_spine_active() and _run_spine_surface != null and _run_spine_surface.has_method("refresh_prep_summary"):
		_run_spine_surface.call("refresh_prep_summary")


func _on_stamina_changed(current: float, maximum: float) -> void:
	_hud_presenter.refresh_stamina(current, maximum)


func _on_player_took_damage(_amount: float, source_lane: int) -> void:
	_hud_presenter.refresh_hp(GameState.player_hp, GameState.player_max_hp)
	if _escalation_director != null:
		_escalation_director.notify_player_hp_changed(GameState.get_hp_percent())
	# Pale Shelf: hits feel clinical and punishing — "EXPOSED" in cold blue, harder flash.
	# All other regions: standard warm "STRUCK".
	if _region_id == "pale_shelf":
		_show_feedback("EXPOSED", Color(0.72, 0.76, 0.96, 1.0), 0.48)
		_presentation_runtime.highlight_timing_ring(source_lane, Color(0.65, 0.72, 0.98, 1.0), 5.0)
		_flash_meter_shell(Color(0.18, 0.18, 0.38, 0.96), 0.22)
		EventBus.emit_signal("screen_flash", Color(0.38, 0.40, 0.62, 0.18), 0.28)
	else:
		_show_feedback("STRUCK", Color(0.96, 0.44, 0.40, 1.0), 0.24)
		_presentation_runtime.highlight_timing_ring(source_lane, Color(1.0, 0.25, 0.25, 1.0), 5.0)
		_flash_meter_shell(Color(0.42, 0.10, 0.11, 0.94), 0.18)


func _on_player_healed(_amount: float) -> void:
	_hud_presenter.refresh_hp(GameState.player_hp, GameState.player_max_hp)
	if _escalation_director != null:
		_escalation_director.notify_player_hp_changed(GameState.get_hp_percent())
	_show_feedback("MEND", Color(0.70, 0.96, 0.84, 1.0), 0.26)
	_flash_meter_shell(Color(0.11, 0.22, 0.17, 0.92), 0.10)


func _on_ultimate_available() -> void:
	_hud_presenter.set_ultimate_text("Ready")
	_show_feedback("READY", Color(1.0, 0.85, 0.35, 1.0), 0.45)
	_flash_meter_shell(Color(0.30, 0.21, 0.10, 0.94), 0.20)


func _on_ultimate_fired(_power: float) -> void:
	_hud_presenter.set_ultimate_text("0%")
	var tier: String = String(combat_meter.call("get_current_tier"))
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
				var marker_data = _enemy_markers_by_id.get(enemy_id, null)
				if marker_data != null:
					var body_node = marker_data.get("body")
					if is_instance_valid(body_node):
						var marker_body: ColorRect = body_node
						marker_body.modulate = Color(0.90, 0.28, 0.28, 1.0)

	# Decrement unified boss HP bar.
	if _is_boss_encounter and _hud_presenter != null:
		_boss_current_hp = max(_boss_current_hp - damage, 0.0)
		_hud_presenter.update_boss_hp(_boss_current_hp)
		
		if _escalation_director != null and _boss_total_hp > 0.0:
			_escalation_director.notify_boss_hp_changed(_boss_current_hp / _boss_total_hp)
		
		# Feedback and effects only (director handles timing shift)
		if not _boss_hp_threshold_fired and _boss_total_hp > 0.0 and (_boss_current_hp / _boss_total_hp) <= 0.5:
			_boss_hp_threshold_fired = true
			_hud_presenter.set_boss_state_text(PRESENTATION_TEXT.BOSS_STATE_FINAL)
			if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("notify_boss_threshold"):
				_performance_reward_director.call("notify_boss_threshold", "sovereign_unleash", 8.0, "BOSS BREAK")
			_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_boss_threshold_profile())
			_trigger_boss_threshold_spectacle()

	_spawn_damage_number(enemy_id, damage)
	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_enemy_hit_profile(damage, is_boss_target), lane, enemy_id)


func _spawn_damage_number(enemy_id: int, damage: float) -> void:
	var marker_data = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null:
		return
	
	var root_node = marker_data.get("root")
	if not is_instance_valid(root_node):
		return
		
	var root: Node2D = root_node
	var start_pos: Vector2 = root.position + Vector2(6.0, -18.0)
	var lbl := Label.new()
	lbl.text = "%.0f" % damage
	lbl.position = start_pos
	lbl.z_index = 10
	UI_STYLE.apply_label(lbl, "warm_value")
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_constant_override("outline_size", 2)
	_enemy_marker_container.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position:y", start_pos.y - 44.0, COMBAT_FEEL_CONTENT.DAMAGE_NUMBER_FLOAT_TIME)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, COMBAT_FEEL_CONTENT.DAMAGE_NUMBER_FLOAT_TIME)
	tween.tween_callback(lbl.queue_free)


func _on_proc_feedback_requested(text: String, color: Color) -> void:
	_show_feedback(text, color, 0.40)


func _on_ultimate_power_granted(amount: float) -> void:
	if combat_meter != null and combat_meter.has_method("gain_ultimate_power"):
		combat_meter.call("gain_ultimate_power", amount)


func _on_enemy_status_applied_requested(lane: int, status_id: String, params: Dictionary) -> void:
	if lane_manager != null and lane_manager.has_method("apply_status"):
		lane_manager.call("apply_status", lane, status_id, params)


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
			var dna_result: Dictionary = {}
			if _run_growth != null and is_instance_valid(_run_growth) and _run_growth.has_method("process_dna_gain"):
				dna_result = _run_growth.call("process_dna_gain", dna_species, dna_amount)
			else:
				GameState.add_dna(dna_species, dna_amount)
				dna_result = {
					"banked": true,
					"total": GameState.get_dna(dna_species),
					"route_id": "bond",
					"exp_gained": 0.0
				}
			EventBus.emit_signal("dna_gained", dna_species, dna_amount, float(dna_result.get("total", GameState.get_dna(dna_species))))
			var dna_name: String = String(COMBAT_CONTENT.get_creature(dna_species).get("display_name", dna_species)).to_upper()
			if bool(dna_result.get("auto_bonded", false)):
				# Skip DNA feedback; _on_creature_bonded will handle the 'BONDED' flash.
				pass
			elif bool(dna_result.get("banked", false)):
				_show_feedback("+%s DNA" % dna_name, Color(0.62, 0.96, 0.78, 1.0), 0.22)
			else:
				_show_feedback("+%s DNA -> EXP" % dna_name, Color(0.96, 0.84, 0.62, 1.0), 0.22)

	if _song_mode and not _song_paused and not _song_boss_triggered:
		var dead_lane: int = _song_enemy_lanes.get(enemy_id, -1)
		if dead_lane >= 0:
			_song_enemy_lanes.erase(enemy_id)
			if _escalation_director != null:
				_escalation_director.notify_enemy_defeated(enemy_id, dead_lane)


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
	var flat_bonus_effect: Dictionary = _get_growth_effect("timed_attack_bonus_flat")
	var beat_quality: String = _get_beat_quality_for_action()
	var enemy_id: int = _get_enemy_id_for_lane(lane)
	if not ravage_effect.is_empty():
		var rip_damage: float = damage * float(ravage_effect.get("value", 0.0))
		lane_manager.damage_enemy(lane, rip_damage)
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.95, 0.48, 0.36, 0.34), 8.0, 0.08, 0.92)
	if not flat_bonus_effect.is_empty():
		lane_manager.damage_enemy(lane, float(flat_bonus_effect.get("value", 0.0)))
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, Color(0.98, 0.70, 0.34, 0.30), 8.0, 0.08, 0.94)

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


func _on_run_growth_changed(level: int, current_exp: float, exp_to_next: float) -> void:
	_hud_presenter.set_exp_text(level, current_exp, exp_to_next)
	_refresh_run_build_readout()


func _on_run_growth_level_resolved(result: Dictionary) -> void:
	_refresh_run_build_readout()
	if result.is_empty():
		return
	var readout_label: String = String(result.get("readout_label", ""))
	var summary: String = String(result.get("summary", ""))
	if readout_label.is_empty():
		return
	_quig_anchor_label.text = _compact_hud_copy("%s - %s" % [readout_label, summary], 34)
	_quig_anchor_label.visible = true
	_refresh_quig_ui_state()
	
	if _quig_tween != null:
		_quig_tween.kill()
		
	_quig_tween = create_tween()
	_quig_tween.tween_interval(COMBAT_FEEL_CONTENT.TENDENCY_ANCHOR_HOLD_TIME)
	_quig_tween.tween_property(_quig_anchor_label, "modulate:a", 0.0, COMBAT_FEEL_CONTENT.TENDENCY_ANCHOR_FADE_TIME)
	_quig_tween.tween_callback(func() -> void:
		_quig_anchor_label.visible = false
		_quig_anchor_label.modulate.a = 1.0
		_refresh_quig_ui_state()
	)
	var snapshot: Dictionary = result.get("snapshot", {})
	if not snapshot.is_empty():
		_hud_presenter.refresh_hp(
			float(snapshot.get("player_hp", GameState.player_hp)),
			float(snapshot.get("player_max_hp", GameState.player_max_hp))
		)
		_hud_presenter.refresh_stats(
			float(snapshot.get("attack_damage", GameState.get_attack_damage())),
			float(snapshot.get("player_defense", GameState.player_defense))
		)


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
	_surge_window_tendency = tendency_id
	_surge_window_timer = 4.0
	_quig_anchor_label.text = _compact_hud_copy(summary, 34)
	_quig_anchor_label.visible = true
	_refresh_quig_ui_state()
	
	if _quig_tween != null:
		_quig_tween.kill()
	
	_quig_tween = create_tween()
	_quig_tween.tween_interval(COMBAT_FEEL_CONTENT.TENDENCY_ANCHOR_HOLD_TIME)
	_quig_tween.tween_property(_quig_anchor_label, "modulate:a", 0.0, COMBAT_FEEL_CONTENT.TENDENCY_ANCHOR_FADE_TIME)
	_quig_tween.tween_callback(func() -> void:
		_quig_anchor_label.visible = false
		_quig_anchor_label.modulate.a = 1.0
		_refresh_quig_ui_state()
	)


func _tick_hud_sprite_animation(delta: float) -> void:
	if _has_active_quig_ui():
		_quig_anim_accum += delta
		if _quig_anim_accum >= COMBAT_FEEL_CONTENT.QUIG_FRAME_DURATION:
			_quig_anim_accum = fmod(_quig_anim_accum, COMBAT_FEEL_CONTENT.QUIG_FRAME_DURATION)
			_quig_anim_frame = (_quig_anim_frame + 1) % COMBAT_FEEL_CONTENT.QUIG_FRAME_COUNT
			_apply_strip_frame(_quig_anchor_sprite, COMBAT_FEEL_CONTENT.QUIG_FRAME_SIZE, _quig_anim_frame)
			_apply_strip_frame(_reward_quig_sprite, COMBAT_FEEL_CONTENT.QUIG_FRAME_SIZE, _quig_anim_frame)
	else:
		if _quig_anim_frame != 0:
			_quig_anim_frame = 0
			_apply_strip_frame(_quig_anchor_sprite, COMBAT_FEEL_CONTENT.QUIG_FRAME_SIZE, 0)
			_apply_strip_frame(_reward_quig_sprite, COMBAT_FEEL_CONTENT.QUIG_FRAME_SIZE, 0)
		_quig_anim_accum = 0.0

	if _dna_shell != null and _dna_shell.visible and _dna_emblem != null:
		_dna_anim_accum += delta
		if _dna_anim_accum >= COMBAT_FEEL_CONTENT.DNA_FRAME_DURATION:
			_dna_anim_accum = fmod(_dna_anim_accum, COMBAT_FEEL_CONTENT.DNA_FRAME_DURATION)
			_dna_anim_frame = (_dna_anim_frame + 1) % COMBAT_FEEL_CONTENT.DNA_FRAME_COUNT
			_apply_strip_frame(_dna_emblem, COMBAT_FEEL_CONTENT.DNA_FRAME_SIZE, _dna_anim_frame)
	else:
		if _dna_anim_frame != 0:
			_dna_anim_frame = 0
			_apply_strip_frame(_dna_emblem, COMBAT_FEEL_CONTENT.DNA_FRAME_SIZE, 0)
		_dna_anim_accum = 0.0


func _tick_bonded_creature_animation(delta: float) -> void:
	if _bonded_creature_sprite == null or not _bonded_creature_sprite.visible:
		return
	var frame_count: int = _bonded_creature_sprite.hframes * _bonded_creature_sprite.vframes
	if frame_count <= 1:
		return
	_bonded_creature_anim_accum += delta
	if _bonded_creature_anim_accum >= BOND_REMNANT_IDLE_FRAME_DURATION:
		_bonded_creature_anim_accum = fmod(_bonded_creature_anim_accum, BOND_REMNANT_IDLE_FRAME_DURATION)
		_bonded_creature_sprite.frame = (_bonded_creature_sprite.frame + 1) % frame_count


func _apply_strip_frame(target: TextureRect, frame_size: Vector2i, frame: int) -> void:
	if target == null or not is_instance_valid(target):
		return
	var atlas: AtlasTexture = target.texture as AtlasTexture
	if atlas == null:
		return
	atlas.region = Rect2(
		Vector2(frame * frame_size.x, 0.0),
		Vector2(frame_size.x, frame_size.y)
	)


func _has_active_quig_ui() -> bool:
	var anchor_live: bool = _quig_anchor_label != null and _quig_anchor_label.visible and not _quig_anchor_label.text.is_empty()
	var reward_live: bool = _reward_overlay != null and _reward_overlay.visible and _reward_quig_label != null and not _reward_quig_label.text.is_empty()
	return anchor_live or reward_live


func _refresh_quig_ui_state() -> void:
	var anchor_live: bool = _quig_anchor_label != null and _quig_anchor_label.visible and not _quig_anchor_label.text.is_empty()
	if _quig_shell != null:
		_quig_shell.visible = anchor_live
	if _quig_anchor_sprite != null:
		_quig_anchor_sprite.visible = anchor_live
		if anchor_live:
			_quig_anchor_sprite.modulate = _quig_anchor_label.modulate

	var reward_live: bool = _reward_overlay != null and _reward_overlay.visible and _reward_quig_label != null and not _reward_quig_label.text.is_empty()
	if _reward_quig_sprite != null:
		_reward_quig_sprite.visible = reward_live


func _on_creature_bonded(creature_data: Dictionary) -> void:
	var _name: String = String(creature_data.get("display_name", "creature")).to_upper()
	var _level: int = int(creature_data.get("bond_level", 1))
	var _flash_text: String = "BOND L%d" % _level if _level > 1 else "%s BONDED" % _name
	var _flash_color: Color = Color(0.62, 0.88, 1.0, 1.0) if _level > 1 else Color(0.82, 0.94, 0.76, 1.0)
	
	_show_feedback(_flash_text, _flash_color, 0.48)
	EventBus.emit_signal("screen_flash", _flash_color.lerp(Color.WHITE, 0.5), 0.12)
	
	_refresh_dna_hud()
	_refresh_run_build_readout()


func _on_support_charge_changed(current: float, maximum: float, active_species_id: String) -> void:
	_hud_presenter.refresh_support(current, maximum, active_species_id, _run_growth)
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
		_bonded_creature_sprite.hframes = 1
		_bonded_creature_sprite.vframes = 1
		_bonded_creature_sprite.frame = 0
		_bonded_creature_anim_accum = 0.0
		return

	var bonded: Dictionary = GameState.get_active_bonded_creature()
	var bond_level: int = int(bonded.get("bond_level", 1))
	var growth_stage: String = GameState.get_creature_growth_stage(bond_level)
	var portrait_key: String = "%s_%s" % [species_id, growth_stage]

	var sprite_path: String = COMBAT_CONTENT.get_creature_art_path(species_id, "battlefield", growth_stage)
	if species_id == "bond_remnant" and growth_stage == "baby":
		var remnant_fallback_path: String = "res://assets/creatures/bond_remnant/forms/bond_remnant_adult.png"
		if ResourceLoader.exists(remnant_fallback_path):
			sprite_path = remnant_fallback_path
	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		_bonded_creature_species = species_id
		_bonded_creature_sprite.visible = false
		_bonded_creature_sprite.texture = null
		_bonded_creature_sprite.hframes = 1
		_bonded_creature_sprite.vframes = 1
		_bonded_creature_sprite.frame = 0
		_bonded_creature_anim_accum = 0.0
		return

	if portrait_key != _bonded_creature_species:
		var render_tex: Texture2D = load(sprite_path) as Texture2D
		if render_tex == null:
			_bonded_creature_sprite.visible = false
			_bonded_creature_sprite.texture = null
			_bonded_creature_sprite.hframes = 1
			_bonded_creature_sprite.vframes = 1
			_bonded_creature_sprite.frame = 0
			_bonded_creature_anim_accum = 0.0
			return
		_bonded_creature_species = portrait_key
		_bonded_creature_sprite.texture = render_tex
		if species_id == "bond_remnant" and growth_stage == "baby" and sprite_path.ends_with("bond_remnant_idle.png"):
			_bonded_creature_sprite.hframes = BOND_REMNANT_IDLE_HFRAMES
			_bonded_creature_sprite.vframes = BOND_REMNANT_IDLE_VFRAMES
		else:
			_bonded_creature_sprite.hframes = 1
			_bonded_creature_sprite.vframes = 1
		_bonded_creature_sprite.frame = 0
		_bonded_creature_anim_accum = 0.0

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
	var cadence_band: Dictionary = Dictionary(_difficulty_modifiers.get("threat_cadence", {}))
	var cadence_mult: float = clampf(float(cadence_band.get("cycle_interval_mult", 1.0)), 0.75, 1.35)
	var stagger_mult: float = clampf(float(cadence_band.get("fire_stagger_mult", 1.0)), 0.85, 1.15)
	lane_manager.set_cycle_interval(base_interval * spawn_mult * cadence_mult)
	lane_manager.set_fire_stagger(base_stagger * stagger_mult)


func _build_music_progression_state() -> Dictionary:
	var total_levels: int = max(_regular_level_windows.size(), 1)
	var level_ratio: float = clampf(float(_regular_level_index) / float(max(total_levels - 1, 1)), 0.0, 1.0)
	var level_duration: float = max(_song_level_end_time - _song_level_start_time, 0.001)
	var level_progress: float = clampf((_song_elapsed - _song_level_start_time) / level_duration, 0.0, 1.0)
	var run_progress: float = clampf((float(_regular_level_index) + level_progress) / float(total_levels), 0.0, 1.0)
	return {
		"run_progress": run_progress,
		"level_progress": level_progress,
		"level_index_ratio": level_ratio,
		"skill_expression": _estimate_player_skill_expression()
	}


func _estimate_player_skill_expression() -> float:
	if combat_meter == null or not is_instance_valid(combat_meter):
		return 0.5
	var combo_norm: float = clampf(float(combat_meter.get("combo_count")) / 24.0, 0.0, 1.0)
	var phrase_norm: float = clampf(float(combat_meter.get("phrase_count")) / 8.0, 0.0, 1.0)
	var tier_value: float = 0.20
	if combat_meter.has_method("get_current_tier"):
		match String(combat_meter.call("get_current_tier")):
			"hunting":
				tier_value = 0.40
			"rampage":
				tier_value = 0.62
			"apex":
				tier_value = 0.82
			"sovereign":
				tier_value = 0.96
	var beat_value: float = 0.55
	if _song_conductor != null and is_instance_valid(_song_conductor) and _song_conductor.has_method("is_beat_active") and _song_conductor.is_beat_active():
		match String(_song_conductor.get_beat_quality()):
			"perfect":
				beat_value = 1.0
			"good":
				beat_value = 0.74
			_:
				beat_value = 0.38
	var skill: float = combo_norm * 0.38 + phrase_norm * 0.30 + tier_value * 0.22 + beat_value * 0.10
	return clampf(skill, 0.0, 1.0)


func _rebuild_music_driven_difficulty() -> void:
	if _difficulty_modifier_director == null or _music_control_layer == null:
		return
	if _base_difficulty_modifiers.is_empty():
		return
	var music_state: Dictionary = _music_control_layer.call("build_state")
	var progression_state: Dictionary = _build_music_progression_state()
	var new_modifiers: Dictionary = _difficulty_modifier_director.call(
		"compute_active_modifiers",
		_base_difficulty_modifiers,
		music_state,
		progression_state
	)
	if new_modifiers == _difficulty_modifiers:
		return
	_difficulty_modifiers = new_modifiers
	_apply_difficulty_modifiers_to_runtime()
	if _song_phase_index >= 0 and _song_phase_index < _song_phases.size():
		_apply_song_phase_cadence(_song_phases[_song_phase_index], _song_section_spawn_mult)


func _build_level_difficulty_modifiers(encounter_options: Dictionary) -> Dictionary:
	var scaling: Dictionary = RUN_PACING_CONTENT.get_level_scaling(_region_id, _regular_level_index)
	var quality_mult_by_level: Array[float] = [1.0, 1.10, 1.20]
	var clutch_mult_by_level: Array[float] = [1.0, 1.08, 1.15]
	var respawn_mult_by_level: Array[float] = [1.0, 0.92, 0.82]
	var reward_decay_by_level: Array[float] = [1.0, 1.08, 1.16]
	var reward_choice_delta_by_level: Array[int] = [0, 0, -1]
	var idx: int = clampi(_regular_level_index, 0, quality_mult_by_level.size() - 1)
	var mods: Dictionary = {
		"threat_cadence": {
			"cycle_interval_mult": float(scaling.get("cycle_interval_mult", 1.0)),
			"fire_stagger_mult": float(scaling.get("fire_stagger_mult", 1.0))
		},
		"threat_quality": {
			"high_grade_weight_mult": quality_mult_by_level[idx],
			"clutch_species_weight_mult": clutch_mult_by_level[idx]
		},
		"lane_pressure": {
			"respawn_delay_mult": respawn_mult_by_level[idx],
			"max_active_threats_bonus": int(scaling.get("max_active_threats_bonus", 0))
		},
		"punish_severity": {
			"projectile_damage_mult": float(scaling.get("enemy_damage_mult", 1.0))
		},
		"reward_pressure": {
			"offer_decay_mult": reward_decay_by_level[idx],
			"level_choice_delta": reward_choice_delta_by_level[idx]
		}
	}
	if bool(encounter_options.get("elite", false)):
		var quality_band: Dictionary = Dictionary(mods.get("threat_quality", {}))
		quality_band["high_grade_weight_mult"] = float(quality_band.get("high_grade_weight_mult", 1.0)) * 1.12
		mods["threat_quality"] = quality_band

		var lane_band: Dictionary = Dictionary(mods.get("lane_pressure", {}))
		lane_band["respawn_delay_mult"] = float(lane_band.get("respawn_delay_mult", 1.0)) * 0.90
		lane_band["max_active_threats_bonus"] = int(lane_band.get("max_active_threats_bonus", 0)) + 1
		mods["lane_pressure"] = lane_band

		var reward_band: Dictionary = Dictionary(mods.get("reward_pressure", {}))
		reward_band["level_choice_delta"] = int(reward_band.get("level_choice_delta", 0)) - 1
		mods["reward_pressure"] = reward_band
	return mods


func _apply_difficulty_modifiers_to_runtime() -> void:
	if _escalation_director != null and is_instance_valid(_escalation_director) and _escalation_director.has_method("set_difficulty_modifiers"):
		_escalation_director.call("set_difficulty_modifiers", _difficulty_modifiers)
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("set_difficulty_modifiers"):
		_performance_reward_director.call("set_difficulty_modifiers", _difficulty_modifiers)
	if lane_manager != null and is_instance_valid(lane_manager) and lane_manager.has_method("set_punish_damage_mult"):
		var punish_band: Dictionary = Dictionary(_difficulty_modifiers.get("punish_severity", {}))
		lane_manager.call("set_punish_damage_mult", float(punish_band.get("projectile_damage_mult", 1.0)))


func _clear_mastery_context_cache() -> void:
	_last_mastery_context.clear()


func _on_mastery_context_updated(data: Dictionary) -> void:
	_last_mastery_context = data.duplicate(true)


func _get_mastery_window() -> String:
	# Returns the current phrase-depth tier for support mastery branching.
	# Phrase count accumulates through consecutive quality (good/perfect) actions.
	# "flow_state" = 8+ actions; "in_pocket" = 5+; "" = below threshold (no enhancement).
	var count: int = int(combat_meter.get("phrase_count"))
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


func _on_bonded_support_triggered(species_id: String, lane: int, effect_id: String) -> void:
	var _support_role: Dictionary = COMBAT_CONTENT.get_support_role(species_id)
	var combo_mult: float = float(combat_meter.call("damage_multiplier"))
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	@warning_ignore("static_called_on_instance")
	var bond_mult: float = GameState.get_bond_level_mult(int(active_creature.get("bond_level", 1)))
	
	# Bond Surge: next support trigger has doubled effectiveness.
	var bond_surge: bool = false
	var surge_mult: float = 1.0
	if _run_growth != null and _run_growth.has_method("get_runtime_effect"):
		var surge_effect: Dictionary = Dictionary(_run_growth.call("get_runtime_effect", "bond_trigger_mult"))
		surge_mult = float(surge_effect.get("value", 1.0))
		bond_surge = surge_mult > 1.0

	var mastery_context: Dictionary = _build_support_mastery_context(effect_id, lane)
	var mastery: String = String(mastery_context.get("window_id", ""))
	var cadence_surge: bool = mastery == "cadence_surge"
	var support_profile: Dictionary = COMBAT_IMPACT_FEEDBACK.build_support_profile(effect_id, cadence_surge, bond_surge)
	
	if bond_surge:
		_show_feedback("SYNC ACTIVE", Color(0.44, 0.96, 0.78, 1.0), 0.42)
	var support_enemy_id: int = _get_enemy_id_for_lane(lane)
	if effect_id == "bond_remnant_mend" or effect_id == "gruvek_gorge" or effect_id == "marrowward_ward" or effect_id == "gorefane_maul" or effect_id == "siltgrip_drag":
		support_enemy_id = -1

	# HOLLOW amplifier: when Bond Remnant is the active creature, REND gets one extra charge
	# and EXPOSE lasts 0.5 s longer. Mastery windows stack on top of this.
	var is_hollow_active: bool = String(active_creature.get("species_id", "")) == "bond_remnant"

	if _support_resolver != null:
		var ctx: Dictionary = {
			"species_id": species_id,
			"lane": lane,
			"effect_id": effect_id,
			"combo_mult": combo_mult,
			"bond_mult": bond_mult,
			"surge_mult": surge_mult,
			"mastery_window": mastery,
			"cadence_surge": cadence_surge,
			"bond_surge": bond_surge,
			"is_hollow_active": is_hollow_active,
			"lane_manager": lane_manager,
			"combat_meter": combat_meter,
			"game_state": GameState
		}
		_support_resolver.resolve(ctx)

	_presentation_runtime.apply_impact_profile(support_profile, lane, support_enemy_id)

	# Pack Signal upgrade: heal on every support trigger.
	var pack_heal_effect: Dictionary = _get_growth_effect("support_trigger_heal")
	if not pack_heal_effect.is_empty():
		var pack_healed: float = GameState.heal_player(float(pack_heal_effect.get("value", 0.0)))
		if pack_healed > 0.0:
			EventBus.emit_signal("player_healed", pack_healed)


func _on_phrase_milestone(count: int) -> void:
	if _music_control_layer != null and _music_control_layer.has_method("notify_phrase_marker"):
		_music_control_layer.call("notify_phrase_marker", count)
	_rebuild_music_driven_difficulty()
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
	var marker_data = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null:
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

	var body_node = marker_data.get("body")
	if is_instance_valid(body_node):
		var marker_body: ColorRect = body_node
		marker_body.color = _status_marker_overrides[enemy_id]


func _on_enemy_status_cleared(lane: int) -> void:
	# Resets the enemy marker color to its biome-based color when a status expires or is consumed.
	var enemy_id: int = _get_enemy_id_for_lane(lane)
	if enemy_id < 0:
		return
	_status_marker_overrides.erase(enemy_id)

	var marker_data = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null:
		return

	var biome: Dictionary = _active_encounter.get("biome", {})
	var active_color: Color = biome.get("enemy_active_color", Color(0.76, 0.21, 0.21, 1.0))
	var inactive_color: Color = biome.get("enemy_inactive_color", Color(0.38, 0.18, 0.18, 0.55))
	var phase: int = int(_enemy_phase_by_id.get(enemy_id, -1))
	
	var body_node = marker_data.get("body")
	if is_instance_valid(body_node):
		var marker_body: ColorRect = body_node
		marker_body.color = active_color if phase == _current_phase_index else inactive_color


func _get_growth_effect(effect_type: String) -> Dictionary:
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("get_runtime_effect"):
		var performance_effect: Dictionary = _performance_reward_director.call("get_runtime_effect", effect_type)
		if not performance_effect.is_empty():
			return performance_effect
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


func _on_player_teleported(_from_lane: int, _to_lane: int) -> void:
	_draw_timing_circles()


func _remove_enemy_marker(enemy_id: int) -> void:
	_status_marker_overrides.erase(enemy_id)
	if not _enemy_markers_by_id.has(enemy_id):
		return

	var marker_data: Dictionary = _enemy_markers_by_id[enemy_id]
	var root_node = marker_data.get("root")
	if not is_instance_valid(root_node):
		_enemy_markers_by_id.erase(enemy_id)
		return

	var marker: Node2D = root_node
	var tween := create_tween()
	tween.tween_property(marker, "modulate:a", 0.0, 0.14)
	tween.parallel().tween_property(marker, "scale", Vector2(0.6, 0.6), 0.12)
	tween.tween_callback(func() -> void:
		if is_instance_valid(marker):
			marker.queue_free()
	)

	_enemy_markers_by_id.erase(enemy_id)


func _spawn_support_intervention(species_id: String, lane: int, tint: Color) -> void:
	var bonded: Dictionary = GameState.get_bonded_creature(species_id)
	var bond_level: int = int(bonded.get("bond_level", 1))
	var growth_stage: String = GameState.get_creature_growth_stage(bond_level)
	
	var support_art: String = COMBAT_CONTENT.get_creature_art_path(species_id, "support", growth_stage)
	if not support_art.is_empty():
		_presentation_runtime.spawn_creature_intervention(lane, support_art, tint)
	else:
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, tint, 16.0, 0.14, 1.18)
