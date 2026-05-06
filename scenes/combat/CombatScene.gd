extends Node2D
class_name CombatScene

signal impact_fx_requested(kind: StringName, world_pos: Vector2, direction: Vector2, scale_mult: float)

# ─── ONREADY NODES ───────────────────────────────────────────────────────────
@onready var background: ColorRect = $Background
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var zone_manager: ZoneManager = $ZoneManager
@onready var player_combat: PlayerCombat = $PlayerCombat
@onready var combat_meter: CombatMeter = $CombatMeter
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
const COMBAT_FEEL_CONTENT = preload("res://data/CombatFeelContent.gd")
const PRESENTATION_TEXT = preload("res://data/PresentationTextContent.gd")
const AUDIO_CONTENT = preload("res://data/AudioContent.gd")
const SONG_LIBRARY_CONTENT = preload("res://data/SongLibraryContent.gd")
const SONG_COMBAT_PROFILE_CONTENT = preload("res://data/SongCombatProfileContent.gd")
const ROUTE_CONTENT = preload("res://data/RouteContent.gd")
const RUN_PACING_CONTENT = preload("res://data/RunPacingContent.gd")
const TRICKY_SONGMAP = preload("res://data/song_maps/tricky_songmap.gd")
const SONG_CONDUCTOR_SCRIPT = preload("res://systems/SongConductor.gd")
const COMBAT_TRANSITION_STATE = preload("res://systems/CombatTransitionState.gd")
const COMBAT_IMPACT_FEEDBACK = preload("res://systems/CombatImpactFeedback.gd")
const COMBAT_PRESENTATION_RUNTIME = preload("res://systems/CombatPresentationRuntime.gd")
const COMBAT_PRESENTATION_CONTROLLER = preload("res://systems/CombatPresentationController.gd")
const ENCOUNTER_IDENTITY_RUNTIME = preload("res://systems/EncounterIdentityRuntime.gd")
const GENERATED_ENCOUNTER_ADAPTER = preload("res://systems/GeneratedEncounterAdapter.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")
const HUD_PANEL_ART = preload("res://systems/HUDPanelArt.gd")
const COMBAT_AUDIO_PLAYER = preload("res://systems/CombatAudioPlayer.gd")
const ENCOUNTER_ESCALATION_DIRECTOR = preload("res://systems/EncounterEscalationDirector.gd")
const MUSIC_CONTROL_LAYER = preload("res://systems/MusicControlLayer.gd")
const DIFFICULTY_MODIFIER_DIRECTOR = preload("res://systems/DifficultyModifierDirector.gd")
const SUPPORT_EFFECT_RESOLVER = preload("res://systems/SupportEffectResolver.gd")
const COLLAR_DIRECTOR = preload("res://systems/CollarDirector.gd")
const PATH_RUN_PLAN = preload("res://systems/PathRunPlan.gd")
const DEBUG_TRACE = preload("res://systems/DebugTrace.gd")
const VESSEL_MODIFIER_DIRECTOR = preload("res://systems/VesselModifierDirector.gd")

# ─── CONSTANTS ───────────────────────────────────────────────────────────────
const PERFORMANCE_REWARD_DIRECTOR_SCRIPT_PATH: String = "res://systems/PerformanceRewardDirector.gd"
const COMBAT_PERFORMANCE_HUD_SCENE: PackedScene = preload("res://scenes/ui/PowerFantasyCombatHUD.tscn")
const COMBAT_HUD_ROOT_SCENE: PackedScene = preload("res://scenes/ui/CombatHudRoot.tscn")
const RUN_SPINE_SCENE: PackedScene = preload("res://scenes/ui/RunSpineScene.tscn")
const GROWTH_CHOICE_SCENE: PackedScene = preload("res://scenes/ui/GrowthChoiceIntersection.tscn")
const EVENT_SCENE: PackedScene = preload("res://scenes/ui/EventScene.tscn")
const EVENT_CONTENT = preload("res://data/EventContent.gd")
const PREDATION_POOL = preload("res://systems/PredationPool.gd")
const ENEMY_LOW_HP_THRESHOLD: float = 0.25
const SUPPORT_MASTERY_CONTEXT_TIMEOUT: float = 1.75
const LIVE_REWARD_WINDOW: float = 3.2
const DNA_HUD_VISIBLE_SLOTS: int = 2
const DNA_PER_KILL: float = 2.5
const BOND_REMNANT_IDLE_HFRAMES: int = 6
const BOND_REMNANT_IDLE_VFRAMES: int = 4
const BOND_REMNANT_IDLE_FRAME_DURATION: float = 0.10
const SONG_REWARD_STALL_GUARD_SECONDS: float = 0.75
const REWARD_RUNTIME_NONE: StringName = &"none"
const REWARD_RUNTIME_SONG_LIVE: StringName = &"song_live"

const VICTORY_REWARD_DIRECTOR = preload("res://systems/VictoryRewardDirector.gd")
const COMBAT_RUN_DIRECTOR = preload("res://systems/CombatRunDirector.gd")
const ENCOUNTER_GENERATOR_SCRIPT_PATH: String = "res://examples/demo_encounter_stack/EncounterGenerator.gd"
const COMBAT_HUD_PRESENTER = preload("res://systems/CombatHUDPresenter.gd")
const COMBAT_FEEDBACK_SHELL = preload("res://scenes/ui/CombatFeedbackShell.gd")
const IMPACT_FX_RUNTIME_SCENE: PackedScene = preload("res://systems/presentation/ImpactFxRuntime.tscn")
const COMBAT_VISUAL_RIG_SCENE: PackedScene = preload("res://scenes/combat/CombatVisualRig.tscn")

# ─── STATE VARIABLES ─────────────────────────────────────────────────────────
var _run_director: Node = null
var _victory_reward_director: Node = null
var _vessel_modifier_director: Node = null
var _base_time_scale: float = 1.0
var _ring_highlight_timers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _surge_window_tendency: String = ""
var _surge_window_timer: float = 0.0
var _tempo_state_family: StringName = COMBAT_FEEL_CONTENT.TEMPO_NONE
var _tempo_state_id: StringName = &""
var _tempo_state_until_ms: int = 0
var _tempo_state_started_ms: int = 0
var _tempo_recovery_start_ms: int = 0
var _tempo_recovery_duration_ms: int = 0
var _tempo_recovery_from_scale: float = 1.0
var _tempo_puncture_cooldown_until_ms: int = 0
var _tempo_stretch_cooldown_until_ms: int = 0
var _tempo_distortion_window: Array[Dictionary] = []
var _tempo_telemetry_counts: Dictionary = {
	COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE: 0,
	COMBAT_FEEL_CONTENT.TEMPO_STRETCH: 0,
	COMBAT_FEEL_CONTENT.TEMPO_VOID: 0,
	COMBAT_FEEL_CONTENT.TEMPO_DECREE: 0
}

# ─── TRANSLATION OVERLAY ──────────────────────────────────────────────────────
var _translation_overlay: ColorRect = null
var _translation_header: Label = null
var _translation_body: Label = null
var _translation_hint: Label = null
var _translation_can_continue: bool = false
var _tempo_recovery_tween: Tween = null

# ─── UI NODES (DYNAMICALLY CREATED) ──────────────────────────────────────────
var _hud_top_left_container: VBoxContainer = null
var _hud_top_left_panel: Control = null
var _hud_top_right_container: VBoxContainer = null
var _hud_top_right_panel: PanelContainer = null
var _hud_top_right_accent_host: Control = null
var _hud_right_stack: VBoxContainer = null
var _hud_bottom_container: HBoxContainer = null
var _hud_root: Control = null
var _hud_decor_layer: Control = null
var _hud_primary_layer: Control = null
var _hud_secondary_layer: Control = null
var _hud_overlay_layer: Control = null
var _title_card: Label = null
var _subtitle_card: Label = null
var _timing_circle_container: Node2D = null
var _timing_rings_cache: Array[Dictionary] = []
var _enemy_marker_container: Node2D = null
var _lane_marker_container: Node2D = null
var _texture_cache: Dictionary = {}
var _attack_fx_container: Node2D = null
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
var _battlefield_panel: Control = null
var _bg_sprite: Control = null
var _bonded_creature_sprite: Sprite2D = null
var _bonded_creature_species: String = ""
var _presentation_runtime: RefCounted = null
var _presentation_controller: CombatPresentationController = null
var _combat_visual_rig: CombatVisualRig = null
var _hud_presenter: RefCounted = null
var _scouter_shell: Panel = null
var _power_scouter_label: Label = null
var _combat_audio_player: Node = null
var _timing_debug_label: Label = null
var _last_combat_input_report: Dictionary = {}

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
var _reward_dna_label: Label = null
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
var _awaiting_upgrade_choice: bool = false
var _pending_upgrades: Array[Dictionary] = []
var _pending_predation: Array[Dictionary] = []
var _pending_path_choice_nodes: Array[Dictionary] = []
var _pending_path_choice_level_index: int = -1
var _active_path_context: Dictionary = {}

var _run_spine_surface: RunSpineScene = null
var _event_surface: EventScene = null
var _growth_choice_surface: GrowthChoiceIntersection = null
var _growth_choice_context: Dictionary = {}

# ─── LIVE REWARD ELEMENTS ────────────────────────────────────────────────────
var _live_reward_shell: PanelContainer = null
var _live_reward_title_label: Label = null
var _live_reward_body_label: Label = null
var _live_reward_dna_label: Label = null
var _live_reward_hint_label: Label = null
var _song_reward_stall_guard: float = 0.0
var _between_level_growth_queue: Array[Dictionary] = []
var _between_level_growth_stored_this_level: bool = false

var _song_reward_pending: bool = false

# ─── RUNTIME REQUISITES ──────────────────────────────────────────────────────
var _combat_finished: bool = false
var _phase_transitioning: bool = false
var _run_finished: bool = false
var _active_reward_runtime: StringName = REWARD_RUNTIME_NONE

var _pending_reward_creature: Dictionary = {}
var _pending_reward_dna_locked: bool = false
var _awaiting_reward_choice: bool = false
var _reward_choice_made: bool = false
var _live_reward_offer_timer: float = 0.0
var _live_reward_queue: Array[Dictionary] = []

var _performance_reward_director: Node = null  # runtime-scripted Node.new()+set_script(); cannot statically type
var _performance_hud: Control = null
var _quig_narrative_system: Node = null
var _quig_tween: Tween = null
var _encounter_load_gen: int = 0
var _active_encounter: Dictionary = {}
var _current_phase_index: int = 0

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

# ─── SONG MODE STATE ─────────────────────────────────────────────────────────
var _song_mode: bool = false
var _song_elapsed: float = 0.0
var _song_paused: bool = false
var _song_phase_index: int = -1
var _song_boss_triggered: bool = false
var _next_song_enemy_id: int = 100
var _song_phases: Array = []
var _song_conductor: SongConductor = null
var _song_enemy_lanes: Dictionary = {}
var _song_timer_label: Label = null
var _song_phase_label: Label = null
var _song_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _escalation_director: EncounterEscalationDirector = null
var _latest_ecology_snapshot: Dictionary = {}
var _active_attack_authority_budget: int = 3
var _support_resolver: SupportEffectResolver = null
var _collar_director: RefCounted = null
var _song_phase_dna_award_index: int = 0
var _song_section_spawn_mult: float = 1.0
var _song_level_start_time: float = 0.0
var _song_level_end_time: float = 0.0
var _base_difficulty_modifiers: Dictionary = {}
var _difficulty_modifiers: Dictionary = {}
var _music_control_layer: MusicControlLayer = null
var _song_combat_state: Dictionary = {}
var _difficulty_modifier_director: DifficultyModifierDirector = null
var _last_beat_index: int = -1
var _song_level_transitioning: bool = false
var _beat_feedback_label: Label = null
var _last_mastery_context: Dictionary = {}
var _quig_anim_accum: float = 0.0
var _quig_anim_frame: int = 0
var _dna_anim_accum: float = 0.0
var _dna_anim_frame: int = 0
var _dna_pickup_flavor_cooldown: float = 0.0
var _dna_pickup_flavor_rotation: Dictionary = {}
var _bonded_creature_anim_accum: float = 0.0

# ─── BOSS MUSIC & HUD ────────────────────────────────────────────────────────
var _boss_music_player: AudioStreamPlayer = null
var _boss_race_active: bool = false
var _boss_music_duration: float = 0.0
var _boss_hp_threshold_fired: bool = false
var _boss_decree_timeline_active: bool = false
var _boss_presence_timer: float = 0.0
var _region_id: String = ""
var _dev_harness_request: Dictionary = {}
var _active_song_map: Script = TRICKY_SONGMAP
var _active_song_data: Dictionary = {}
var _active_song_profile: Dictionary = SONG_COMBAT_PROFILE_CONTENT.get_profile("")
var _boss_song_profile: Dictionary = SONG_COMBAT_PROFILE_CONTENT.get_profile("boss_1")
var _last_applied_hunt_pressure_step: int = -1
var _critical_threat_pressure: float = 0.0
var _critical_threat_lane: int = -1
var _readability_pulse_mult: float = 1.0
var _critical_warning_cooldown_until_ms: int = 0
var _feedback_shell: RefCounted = null

const CRITICAL_WARNING_COOLDOWN_MS: int = 900


# ─── LIFECYCLE ───────────────────────────────────────────────────────────────

func _ready() -> void:
	if DevHarness.has_pending_request():
		_dev_harness_request = DevHarness.get_pending_request()
	
	_initialize_systems()
	_initialize_ui()
	_initialize_run_state()
	_connect_signals()
	
	_start_run_engagement(not GameState.run_in_progress)
	
	if not _dev_harness_request.is_empty():
		call_deferred("_apply_dev_harness_post_boot_state")


func _exit_tree() -> void:
	_reset_tempo_state()
	var vp: Viewport = get_viewport()
	if vp.size_changed.is_connected(_sync_fullscreen_underlay_controls):
		vp.size_changed.disconnect(_sync_fullscreen_underlay_controls)
	if vp.size_changed.is_connected(_sync_compact_transient_hud_layout):
		vp.size_changed.disconnect(_sync_compact_transient_hud_layout)

	# Disconnect all EventBus signals to prevent memory leaks and desync.
	if EventBus.combo_changed.is_connected(_on_combo_changed):
		EventBus.combo_changed.disconnect(_on_combo_changed)
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
	if EventBus.dna_lock_denied.is_connected(_on_dna_lock_denied):
		EventBus.dna_lock_denied.disconnect(_on_dna_lock_denied)
	if EventBus.vessel_shifted.is_connected(_on_vessel_shifted):
		EventBus.vessel_shifted.disconnect(_on_vessel_shifted)
	if EventBus.proc_feedback_requested.is_connected(_on_proc_feedback_requested):
		EventBus.proc_feedback_requested.disconnect(_on_proc_feedback_requested)
	if zone_manager != null and is_instance_valid(zone_manager):
		if EventBus.enemy_status_applied_requested.is_connected(zone_manager.apply_status):
			EventBus.enemy_status_applied_requested.disconnect(zone_manager.apply_status)
	if EventBus.ultimate_power_granted.is_connected(_on_ultimate_power_granted):
		EventBus.ultimate_power_granted.disconnect(_on_ultimate_power_granted)
	
	if _presentation_runtime != null:
		if EventBus.screen_flash.is_connected(_presentation_runtime.on_screen_flash):
			EventBus.screen_flash.disconnect(_presentation_runtime.on_screen_flash)
		if EventBus.screen_shake.is_connected(_presentation_runtime.on_screen_shake):
			EventBus.screen_shake.disconnect(_presentation_runtime.on_screen_shake)
		if EventBus.timing_ring_pressed.is_connected(_presentation_runtime.on_timing_ring_pressed):
			EventBus.timing_ring_pressed.disconnect(_presentation_runtime.on_timing_ring_pressed)
		if EventBus.song_beat_pulse.is_connected(_presentation_runtime.on_song_beat_pulse):
			EventBus.song_beat_pulse.disconnect(_presentation_runtime.on_song_beat_pulse)
		if EventBus.ui_shake.is_connected(_presentation_runtime.on_ui_shake):
			EventBus.ui_shake.disconnect(_presentation_runtime.on_ui_shake)
		if EventBus.dna_resonated.is_connected(_presentation_runtime.on_dna_resonated):
			EventBus.dna_resonated.disconnect(_presentation_runtime.on_dna_resonated)
		if EventBus.projectile_fired.is_connected(_presentation_runtime.on_projectile_fired):
			EventBus.projectile_fired.disconnect(_presentation_runtime.on_projectile_fired)
		_presentation_runtime.set_readability_stress(0.0)

	if EventBus.slow_motion.is_connected(_on_slow_motion):
		EventBus.slow_motion.disconnect(_on_slow_motion)
	if EventBus.player_attacked.is_connected(_on_player_attacked):
		EventBus.player_attacked.disconnect(_on_player_attacked)
	if EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.disconnect(_on_timed_attack_resolved)
	if EventBus.attack_timing_early_resolved.is_connected(_on_attack_timing_early_resolved):
		EventBus.attack_timing_early_resolved.disconnect(_on_attack_timing_early_resolved)
	if EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.disconnect(_on_player_parried)
	if EventBus.player_dodged.is_connected(_on_player_dodged):
		EventBus.player_dodged.disconnect(_on_player_dodged)
	if EventBus.combat_input_resolved.is_connected(_on_combat_input_resolved):
		EventBus.combat_input_resolved.disconnect(_on_combat_input_resolved)
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
	if EventBus.quig_narrative_triggered.is_connected(_on_quig_narrative_triggered):
		EventBus.quig_narrative_triggered.disconnect(_on_quig_narrative_triggered)
	
	if _hud_presenter != null:
		_hud_presenter.cleanup()

	if _victory_reward_director != null and is_instance_valid(_victory_reward_director):
		if _victory_reward_director.has_method("reset"):
			_victory_reward_director.reset()


func _initialize_systems() -> void:
	_setup_zone_manager()
	_setup_player_combat()
	_setup_performance_rewards()
	_setup_vessel_modifier_director()
	_setup_escalation_director()
	_setup_music_difficulty_layers()
	_setup_run_director()
	_setup_victory_reward_director()
	_setup_support_resolver()
	_setup_quig_narrative()
	_setup_bonded_companions()

	if RunStats and RunStats.has_signal("score_changed"):		RunStats.score_changed.connect(_on_run_score_changed)


func _setup_quig_narrative() -> void:
	if _quig_narrative_system != null and is_instance_valid(_quig_narrative_system):
		return
	_quig_narrative_system = preload("res://systems/QuigNarrativeSystem.gd").new()
	_quig_narrative_system.name = "QuigNarrativeSystem"
	add_child(_quig_narrative_system)


func _setup_bonded_companions() -> void:
	# PERSISTENT COMPANION DOCTRINE: Bonded creatures are active participants.
	# 360-degree movement, lane-independent targeting, auto-attack synergy.
	for child in get_children():
		if child.name.begins_with("BondedCompanion_"):
			child.queue_free()
			
	for creature in GameState.roster:
		var species_id: String = String(creature.get("species_id", ""))
		if species_id.is_empty(): continue
		_ensure_bonded_companion(species_id)


func _ensure_bonded_companion(species_id: String) -> void:
	if species_id.is_empty():
		return
	if get_node_or_null("BondedCompanion_" + species_id) != null:
		return
	var companion_script = load("res://scenes/combat/BondedCompanion.gd")
	if companion_script:
		var companion: BondedCompanion = companion_script.new() as BondedCompanion
		companion.name = "BondedCompanion_" + species_id
		add_child(companion)
		companion.setup(species_id, player_combat, zone_manager)


func _has_bonded_companion(species_id: String) -> bool:
	var companion: Node = get_node_or_null("BondedCompanion_" + species_id)
	return companion != null and is_instance_valid(companion)


func _setup_run_director() -> void:
	_run_director = COMBAT_RUN_DIRECTOR.new()
	add_child(_run_director)
	_run_director.drop_scheduled.connect(_on_run_director_drop_scheduled)


func _setup_victory_reward_director() -> void:
	_victory_reward_director = VICTORY_REWARD_DIRECTOR.new()
	_victory_reward_director.name = "VictoryRewardDirector"
	add_child(_victory_reward_director)
	_victory_reward_director.offer_started.connect(_on_victory_offer_started)
	_victory_reward_director.offer_ended.connect(_on_victory_offer_ended)
	_victory_reward_director.choice_resolved.connect(_on_victory_choice_resolved)


func _setup_support_resolver() -> void:
	_support_resolver = SUPPORT_EFFECT_RESOLVER.new()
	_collar_director = COLLAR_DIRECTOR.new()
	_support_resolver.feedback_requested.connect(_show_feedback)
	_support_resolver.flash_requested.connect(_flash_meter_shell)
	_support_resolver.intervention_requested.connect(_spawn_support_intervention)
	_support_resolver.heal_requested.connect(func(amt): 
		var healed = GameState.heal_player(amt)
		if healed > 0.0: 
			EventBus.emit_signal("player_healed", healed)
			_refresh_run_build_readout()
	)
	_support_resolver.stamina_requested.connect(func(amt):
		if combat_meter != null: 
			combat_meter.restore_stamina(amt)
			_refresh_run_build_readout()
	)
	_support_resolver.support_charge_requested.connect(func(amt):
		RunGrowth.gain_support_charge_direct(amt)
		_refresh_run_build_readout()
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
	_escalation_director.zone_manager = zone_manager
	_escalation_director.player_combat = player_combat
	_escalation_director.phase_changed.connect(_on_escalation_phase_changed)
	_escalation_director.spawn_requested.connect(_on_escalation_spawn_requested)
	_escalation_director.feedback_requested.connect(_on_escalation_feedback_requested)
	_escalation_director.ecology_state_changed.connect(_on_escalation_ecology_state_changed)


func _setup_music_difficulty_layers() -> void:
	if _music_control_layer == null:
		_music_control_layer = MUSIC_CONTROL_LAYER.new()
	if _difficulty_modifier_director == null:
		_difficulty_modifier_director = DIFFICULTY_MODIFIER_DIRECTOR.new()
	if _music_control_layer != null:
		_music_control_layer.configure(_active_song_profile)


func _on_escalation_ecology_state_changed(snapshot: Dictionary) -> void:
	_latest_ecology_snapshot = snapshot.duplicate(true)
	_apply_attack_authority_budget(_latest_ecology_snapshot)


func _on_escalation_phase_changed(index: int, _phase_data: Dictionary) -> void:
	_enter_song_phase(index)


func _on_escalation_spawn_requested(lane: int, enemy_data: Dictionary) -> void:
	if zone_manager != null and is_instance_valid(zone_manager):
		zone_manager.set_enemy(lane, enemy_data)
		var live_enemy: Dictionary = _resolve_spawned_live_enemy(lane, enemy_data)
		if live_enemy.is_empty():
			return
		var enemy_id: int = int(live_enemy.get("id", -1))
		if enemy_id < 0:
			return
		_all_enemies_by_id[enemy_id] = live_enemy.duplicate(true)
		_enemy_max_hp[enemy_id] = float(live_enemy.get("max_hp", live_enemy.get("hp", 1.0)))
		if not _enemy_phase_by_id.has(enemy_id):
			_enemy_phase_by_id[enemy_id] = _current_phase_index
		_ensure_enemy_marker_for_live_enemy(enemy_id, live_enemy)


func _resolve_spawned_live_enemy(spawn_lane: int, enemy_seed: Dictionary) -> Dictionary:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return {}

	# Fast path: lane spawn landed directly in a striker lane.
	var lane_enemy: Dictionary = zone_manager.get_enemy(spawn_lane)
	if not lane_enemy.is_empty():
		return lane_enemy.duplicate(true)

	var all_live: Dictionary = zone_manager.get_all_enemies()
	if all_live.is_empty():
		return {}

	# Preferred path: reuse seeded id when present.
	var seeded_id: int = int(enemy_seed.get("id", -1))
	if seeded_id >= 0 and all_live.has(seeded_id):
		return Dictionary(all_live.get(seeded_id, {})).duplicate(true)

	# Fallback: choose newest unknown live enemy id.
	var newest_id: int = -1
	for key in all_live.keys():
		var eid: int = int(key)
		if _all_enemies_by_id.has(eid):
			continue
		if newest_id < 0 or eid > newest_id:
			newest_id = eid
	if newest_id >= 0:
		return Dictionary(all_live.get(newest_id, {})).duplicate(true)

	return {}


func _ensure_enemy_marker_for_live_enemy(enemy_id: int, enemy_data: Dictionary) -> void:
	if enemy_id < 0:
		return
	if _enemy_markers_by_id.has(enemy_id):
		return
	if _enemy_marker_container == null or not is_instance_valid(_enemy_marker_container):
		return
	if _presentation_controller == null:
		return

	var lane: int = int(enemy_data.get("lane", -1))
	var marker_size: float = 64.0 if _is_boss_encounter else 42.0
	var biome: Dictionary = _active_encounter.get("biome", {})
	var base_color: Color = biome.get("enemy_inactive_color", Color(0.40, 0.20, 0.20, 0.5))
	var marker_data: Dictionary = _build_enemy_marker(enemy_id, lane, enemy_data, marker_size, base_color)
	var root = marker_data.get("root")
	if not is_instance_valid(root):
		return
	_enemy_marker_container.add_child(root)
	_enemy_markers_by_id[enemy_id] = marker_data
	_refresh_enemy_marker_states()


func _on_escalation_feedback_requested(text: String, color: Color, duration: float) -> void:
	_show_feedback(text, color, duration)


func _on_victory_offer_started(creature_data: Dictionary, is_live: bool, is_dna_locked: bool, timer: float) -> void:
	if is_live:
		_show_live_reward_offer_internal(creature_data, is_dna_locked, timer)
	else:
		_show_victory_reward_internal(creature_data, is_dna_locked)


func _on_victory_offer_ended() -> void:
	_hide_reward_overlay()
	_hide_live_reward_shell()


func _on_victory_choice_resolved(choice_id: String, creature_data: Dictionary) -> void:
	var void_elapsed: float = _current_void_elapsed_seconds()
	_notify_tempo_mastery(COMBAT_FEEL_CONTENT.TEMPO_VOID, "choice_commit", {
		"choice": choice_id,
		"elapsed_seconds": void_elapsed,
		"window_seconds": LIVE_REWARD_WINDOW
	})

	_refresh_reward_overlay_resolution(choice_id, creature_data)
	_refresh_dna_hud()
	_refresh_run_build_readout()
	_refresh_quig_ui_state()
	
	if choice_id != "pass":
		var feedback_color: Color = Color(0.82, 0.94, 0.76, 1.0) if choice_id == "bond" else Color(0.94, 0.62, 0.30, 1.0)
		var feedback_text: String = "BONDED" if choice_id == "bond" else "CONSUMED"
		
		if _active_reward_runtime == REWARD_RUNTIME_SONG_LIVE:
			_show_feedback("%s %s" % [str(creature_data.get("display_name", "")).to_upper(), feedback_text], feedback_color, 0.34)
			_resume_song_combat_runtime_from_reward()
		else:
			_show_feedback(feedback_text, feedback_color, 0.42)
	else:
		if _active_reward_runtime == REWARD_RUNTIME_SONG_LIVE:
			_show_feedback("PASSED", Color(0.7, 0.7, 0.75, 1.0), 0.18)
			_resume_song_combat_runtime_from_reward()


func _refresh_reward_overlay_content() -> void:
	if _pending_reward_creature.is_empty():
		return

	var _offer_creature_name: String = str(_pending_reward_creature.get("display_name", "creature"))
	var _offer_description: String = str(_pending_reward_creature.get("description", ""))
	var _encounter_context: String = _describe_creature_offer_context(_pending_reward_creature)

	# DNA gate: check whether the player has accumulated enough DNA for this species.
	var _offer_species_id: String = str(_pending_reward_creature.get("species_id", ""))
	var _offer_dna_threshold: float = GameState.get_effective_dna_threshold(_offer_species_id)
	var _player_dna: float = GameState.get_dna(_offer_species_id)
	var _archive_tether_ready: bool = GameState.is_species_ever_bonded(_offer_species_id)

	_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_CREATURE
	_reward_title_label.text = PRESENTATION_TEXT.live_reward_title(_offer_creature_name)
	
	var body: String = _offer_description
	if not _encounter_context.is_empty():
		body += "\n\nEncounter Context: %s" % _encounter_context
	_reward_body_label.text = body
	
	if _reward_dna_label != null:
		_reward_dna_label.text = PRESENTATION_TEXT.bond_offer_gate_line(_offer_species_id)
		_reward_dna_label.modulate = Color(0.4, 0.9, 0.8) if _archive_tether_ready or _player_dna >= _offer_dna_threshold else Color(1.0, 0.4, 0.4)

	_reward_bond_label.text = "B Tether" if _archive_tether_ready else ("B Bond" if not _pending_reward_dna_locked else "B Bond - DNA locked")
	_reward_eat_label.text = "E Consume"

	# Evolutionary logic: bond passive is scaled by current potential
	var bond_passive: Dictionary = _pending_reward_creature.get("bond_passive", {})
	@warning_ignore("static_called_on_instance")
	_reward_bond_effect_label.text = PRESENTATION_TEXT.format_bond_passive_long(bond_passive, 1.0)
	
	# Eat effect is scaled by current potential
	var eat_effect: Dictionary = _pending_reward_creature.get("eat_effect", {})
	_reward_eat_effect_label.text = PRESENTATION_TEXT.format_eat_effect(eat_effect)
	
	_reward_quig_label.text = PRESENTATION_TEXT.bond_result_quig(_offer_creature_name)
	_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_LOCKED if _pending_reward_dna_locked else PRESENTATION_TEXT.REWARD_HINT_CHOICE


func _refresh_reward_overlay_resolution(choice_id: String, creature_data: Dictionary) -> void:
	if _reward_overlay == null or not _reward_overlay.visible:
		return
		
	var creature_name: String = str(creature_data.get("display_name", "creature"))
	
	match choice_id:
		"bond":
			var species_id: String = str(creature_data.get("species_id", ""))
			var updated_creature: Dictionary = GameState.get_bonded_creature(species_id)
			var new_bond_level: int = int(updated_creature.get("bond_level", 1))
			var bond_deepened: bool = new_bond_level > 1
			_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_BONDED
			_reward_title_label.text = "%s deepens." % creature_name if bond_deepened else "%s bonded." % creature_name
			_reward_body_label.text = PRESENTATION_TEXT.bond_result_body(creature_name, new_bond_level)
			_reward_bond_label.text = "Bond L%d" % new_bond_level if bond_deepened else "Bonded"
			@warning_ignore("static_called_on_instance")
			_reward_bond_effect_label.text = PRESENTATION_TEXT.format_bond_passive_long(
				creature_data.get("bond_passive", {}), 
				GameState.get_bond_level_mult(new_bond_level)
			)
			_reward_eat_label.text = ""
			_reward_eat_effect_label.text = ""
			_reward_quig_label.text = PRESENTATION_TEXT.bond_result_quig(creature_name)

			var new_growth_stage: String = GameState.get_creature_growth_stage(new_bond_level)
			var new_portrait: String = COMBAT_CONTENT.get_creature_art_path(species_id, "support", new_growth_stage)
			if not new_portrait.is_empty() and ResourceLoader.exists(new_portrait):
				var port_tex: Texture2D = load(new_portrait) as Texture2D
				if port_tex != null:
					_reward_creature_portrait.texture = port_tex
		"eat":
			var absorbed_entry: Dictionary = {}
			if not GameState.absorbed_types.is_empty():
				absorbed_entry = Dictionary(GameState.absorbed_types[GameState.absorbed_types.size() - 1]).duplicate(true)
			_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_EATEN
			_reward_title_label.text = "%s consumed." % creature_name
			_reward_body_label.text = PRESENTATION_TEXT.eat_result_body()
			_reward_bond_label.text = ""
			_reward_bond_effect_label.text = ""
			_reward_eat_label.text = "Absorbed"
			
			var mutation_summary: String = str(creature_data.get("mutation", {}).get("summary", ""))
			var mutation_line: String = "\n\nMutation gained: %s" % mutation_summary if not mutation_summary.is_empty() else ""

			var eat_type_str: String = str(absorbed_entry.get("eat_type", "damage_flat"))
			if eat_type_str == "hp_restore":
				_reward_eat_effect_label.text = "Type: %s\n\n+%.0f HP restored.\nNo permanent bonus.%s" % [
					str(absorbed_entry.get("type", "unknown")).capitalize(),
					float(absorbed_entry.get("heal_applied", 0.0)),
					mutation_line
				]
			elif eat_type_str == "max_hp_flat":
				_reward_eat_effect_label.text = "Type: %s\n\n+%.0f max HP.\n+%.0f HP restored.%s" % [
					str(absorbed_entry.get("type", "unknown")).capitalize(),
					float(absorbed_entry.get("max_hp_bonus", 0.0)),
					float(absorbed_entry.get("heal_applied", 0.0)),
					mutation_line
				]
			elif eat_type_str == "support_charge":
				_reward_eat_effect_label.text = "Type: %s\n\n+%.0f support charge immediately.%s" % [
					str(absorbed_entry.get("type", "unknown")).capitalize(),
					float(absorbed_entry.get("support_charge_bonus", 0.0)),
					mutation_line
				]
			else:
				_reward_eat_effect_label.text = "Type: %s\n\n+%.1f permanent attack damage%s" % [
					str(absorbed_entry.get("type", "unknown")).capitalize(),
					float(absorbed_entry.get("damage_bonus", 0.0)),
					mutation_line
				]
			_reward_quig_label.text = PRESENTATION_TEXT.eat_result_quig(creature_name)
		"pass":
			_reward_creature_tag_label.text = PRESENTATION_TEXT.REWARD_TAG_PASSED
			_reward_title_label.text = PRESENTATION_TEXT.REWARD_TITLE_PASSED
			_reward_body_label.text = PRESENTATION_TEXT.REWARD_BODY_PASSED
			_reward_bond_label.text = ""
			_reward_eat_label.text = ""
			_reward_bond_effect_label.text = ""
			_reward_eat_effect_label.text = ""
			_reward_quig_label.text = PRESENTATION_TEXT.pass_result_quig()
	
	_schedule_reward_scroll_reflow()


func _show_live_reward_offer_internal(creature_data: Dictionary, is_dna_locked: bool, timer: float) -> void:
	if _live_reward_shell == null: return
	
	if _song_mode and not _run_finished:
		_begin_song_live_reward_runtime()

	_pending_reward_creature = creature_data.duplicate(true)
	_pending_reward_dna_locked = is_dna_locked
	_awaiting_reward_choice = true
	_reward_choice_made = false
	_live_reward_offer_timer = timer
	_song_reward_stall_guard = SONG_REWARD_STALL_GUARD_SECONDS

	var is_breakthrough: bool = not _pending_reward_dna_locked or str(_pending_reward_creature.get("type", "")) == "performance"
	if is_breakthrough:
		_begin_void(&"live_reward_offer", {
			"species_id": str(_pending_reward_creature.get("species_id", "")),
			"dna_locked": _pending_reward_dna_locked
		})
	else:
		_track_tempo_event(COMBAT_FEEL_CONTENT.TEMPO_NONE, &"live_reward_minimal")

	_live_reward_shell.visible = true
	EventBus.emit_signal("capture_offered", _pending_reward_creature)
	_refresh_live_reward_shell()
	_refresh_dna_hud()
	_refresh_song_controls_text()
	_refresh_quig_ui_state()
	_sync_message_lane_ownership()


func _show_victory_reward_internal(creature_data: Dictionary, is_dna_locked: bool) -> void:
	_pending_reward_creature = creature_data.duplicate(true)
	_pending_reward_dna_locked = is_dna_locked
	_awaiting_reward_choice = true
	_reward_choice_made = false

	EventBus.emit_signal("capture_offered", _pending_reward_creature)
	_reward_overlay.visible = true
	_refresh_reward_overlay_content()
	_refresh_dna_hud()
	_refresh_quig_ui_state()


func _resolve_runtime_authority_budget(phase: Dictionary = {}, snapshot: Dictionary = {}) -> int:
	var lane_count: int = 3
	if zone_manager != null and is_instance_valid(zone_manager):
		lane_count = int(zone_manager.THREAT_COUNT)
	var authority_budget: int = lane_count
	if not snapshot.is_empty():
		authority_budget = int(snapshot.get("attack_authority_budget", snapshot.get("authority_budget", authority_budget)))
	elif _escalation_director != null:
		var live_snapshot: Dictionary = _escalation_director.get_ecology_snapshot()
		authority_budget = int(live_snapshot.get("attack_authority_budget", live_snapshot.get("authority_budget", authority_budget)))
	elif not phase.is_empty():
		authority_budget = int(phase.get("authority_target", phase.get("max_active_threats", authority_budget)))
	return clampi(authority_budget, 1, lane_count)


func _apply_attack_authority_budget(snapshot: Dictionary = {}, phase: Dictionary = {}) -> void:
	if zone_manager == null or not is_instance_valid(zone_manager):
		return
	var resolved_budget: int = _resolve_runtime_authority_budget(phase, snapshot)
	if resolved_budget == _active_attack_authority_budget:
		return
	_active_attack_authority_budget = resolved_budget
	zone_manager.set_attack_authority_budget(_active_attack_authority_budget)


func _initialize_ui() -> void:
	_setup_presentation_controller()
	_setup_combat_visual_rig()
	_setup_visuals()
	_ensure_hud_root()
	_create_feedback_shell()
	if not get_viewport().size_changed.is_connected(_sync_fullscreen_underlay_controls):
		get_viewport().size_changed.connect(_sync_fullscreen_underlay_controls)
	_setup_ui()
	_setup_ui_pivots()
	_create_feedback_label()
	_create_title_cards()
	_create_timing_circle_container()
	_create_attack_fx_container()
	_create_impact_fx_runtime()
	_setup_presentation_runtime()
	_create_reward_overlay()
	_create_upgrade_overlay()
	_create_run_spine_surface()
	_create_growth_choice_surface()
	_create_live_reward_shell()
	_create_hud_presenter()
	if _hud_presenter != null:
		_hud_presenter.apply_hp_stamina_resource_bar_styles(hp_bar, stamina_bar)
	_setup_performance_hud()
	if not get_viewport().size_changed.is_connected(_sync_compact_transient_hud_layout):
		get_viewport().size_changed.connect(_sync_compact_transient_hud_layout)
	call_deferred("_sync_compact_transient_hud_layout")
	_refresh_hud_snapshot(0, 0.0, "stirring")


func _create_feedback_shell() -> void:
	if _feedback_shell != null:
		return
	_feedback_shell = COMBAT_FEEDBACK_SHELL.new(UI_STYLE, COMBAT_FEEL_CONTENT, self, Callable(_presentation_controller, "apply_text_role"))


func _setup_presentation_controller() -> void:
	if _presentation_controller != null and is_instance_valid(_presentation_controller):
		return
	_presentation_controller = COMBAT_PRESENTATION_CONTROLLER.new()
	_presentation_controller.name = "CombatPresentationController"
	add_child(_presentation_controller)


func _setup_combat_visual_rig() -> void:
	if _combat_visual_rig != null and is_instance_valid(_combat_visual_rig):
		return
	if COMBAT_VISUAL_RIG_SCENE == null:
		return
	var inst: Node = COMBAT_VISUAL_RIG_SCENE.instantiate()
	if inst == null or not (inst is CombatVisualRig):
		if inst != null:
			inst.queue_free()
		return
	_combat_visual_rig = inst as CombatVisualRig
	_combat_visual_rig.name = "CombatVisualRig"
	add_child(_combat_visual_rig)
	if _presentation_controller != null:
		_presentation_controller.set_combat_visual_rig(_combat_visual_rig)
	if player_combat != null:
		player_combat.set_combat_visual_rig(_combat_visual_rig)


func _initialize_run_state() -> void:
	_combat_finished = false
	_phase_transitioning = false
	_run_finished = false
	_dna_pickup_flavor_cooldown = 0.0
	_dna_pickup_flavor_rotation.clear()
	_reset_tempo_state()


func _connect_signals() -> void:
	_connect_eventbus()


func _process(delta: float) -> void:
	_update_timers(delta)
	_update_presentation_layers(delta)
	_update_performance_systems(delta)
	_update_song_logic(delta)
	_update_boss_race(delta)
	_tick_hud_sprite_animation(delta)
	_tick_bonded_creature_animation(delta)


func _update_timers(delta: float) -> void:
	_update_tempo_state()

	# Vectorized timer updates for performance
	var threat_count: int = zone_manager.THREAT_COUNT if zone_manager else 8
	for i in range(threat_count):
		if _ring_highlight_timers[i] > 0.0:
			_ring_highlight_timers[i] = max(_ring_highlight_timers[i] - delta, 0.0)
	
	if _surge_window_timer > 0.0:
		_surge_window_timer = max(_surge_window_timer - delta, 0.0)
		if _surge_window_timer <= 0.0:
			_surge_window_tendency = ""

	if _victory_reward_director != null:
		var v_delta: float = _resolve_void_timer_delta(delta)
		_victory_reward_director.process_tick(v_delta)
		if _victory_reward_director.is_awaiting_choice():
			_refresh_live_reward_shell()
			if _victory_reward_director.get_pending_creature().is_empty():
				_song_reward_stall_guard = maxf(_song_reward_stall_guard - delta, 0.0)
				if _song_reward_stall_guard <= 0.0:
					_recover_song_reward_flow("empty_pending_creature")
			else:
				_song_reward_stall_guard = SONG_REWARD_STALL_GUARD_SECONDS
	if _dna_pickup_flavor_cooldown > 0.0:
		_dna_pickup_flavor_cooldown = max(_dna_pickup_flavor_cooldown - delta, 0.0)


func _update_tempo_state() -> void:
	var now: int = Time.get_ticks_msec()
	
	# 1. Process Active State Expiry
	if _tempo_state_family != COMBAT_FEEL_CONTENT.TEMPO_NONE:
		if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_VOID:
			# Void exits through reward resolution or expiry, not a fixed timer.
			pass
		elif _tempo_state_until_ms > 0 and now >= _tempo_state_until_ms:
			_exit_tempo_state(_tempo_state_family, false)
			return

	# 2. Process Manual Recovery Ramp (Wall-Clock Based)
	if _tempo_recovery_duration_ms > 0:
		var elapsed: int = now - _tempo_recovery_start_ms
		if elapsed >= _tempo_recovery_duration_ms:
			_apply_tempo_time_scale(_base_time_scale)
			_tempo_recovery_duration_ms = 0
		else:
			var t: float = float(elapsed) / float(_tempo_recovery_duration_ms)
			# SINE_OUT transition for fluid return to speed
			var eased_t: float = sin(t * PI * 0.5)
			var target_scale: float = lerpf(_tempo_recovery_from_scale, _base_time_scale, eased_t)
			_apply_tempo_time_scale(target_scale)


func _resolve_void_timer_delta(delta: float) -> float:
	if _tempo_state_family != COMBAT_FEEL_CONTENT.TEMPO_VOID:
		return delta
	var current_time_scale: float = maxf(Engine.time_scale, 0.01)
	# Keep Choice Void windows deterministic in wall-clock seconds.
	return delta / current_time_scale


func _reset_tempo_state() -> void:
	_kill_tempo_recovery_tween()
	_tempo_state_family = COMBAT_FEEL_CONTENT.TEMPO_NONE
	_tempo_state_id = &""
	_tempo_state_until_ms = 0
	_tempo_state_started_ms = 0
	_tempo_puncture_cooldown_until_ms = 0
	_tempo_stretch_cooldown_until_ms = 0
	_tempo_distortion_window.clear()
	_tempo_telemetry_counts[COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE] = 0
	_tempo_telemetry_counts[COMBAT_FEEL_CONTENT.TEMPO_STRETCH] = 0
	_tempo_telemetry_counts[COMBAT_FEEL_CONTENT.TEMPO_VOID] = 0
	_tempo_telemetry_counts[COMBAT_FEEL_CONTENT.TEMPO_DECREE] = 0
	_song_reward_stall_guard = 0.0
	_apply_tempo_time_scale(_base_time_scale)


func _tempo_priority(family: StringName) -> int:
	return int(COMBAT_FEEL_CONTENT.TEMPO_PRIORITY.get(family, 0))


func _tempo_distortion_available(family: StringName, tempo_scale_value: float, duration: float) -> bool:
	if family != COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE:
		# Anti-spam budget applies only to repeated micro-puncture effects.
		return true
	var now: int = Time.get_ticks_msec()
	var window_ms: int = int(COMBAT_FEEL_CONTENT.TEMPO_DISTORTION_WINDOW_SECONDS * 1000.0)
	var next_window: Array[Dictionary] = []
	var used: float = 0.0
	for row in _tempo_distortion_window:
		var ts: int = int(row.get("t_ms", 0))
		if now - ts <= window_ms:
			next_window.append(row)
			used += float(row.get("weight", 0.0))
	_tempo_distortion_window = next_window
	var proposed: float = maxf(1.0 - clampf(tempo_scale_value, 0.0, 1.0), 0.0) * maxf(duration, 0.0)
	return used + proposed <= COMBAT_FEEL_CONTENT.PUNCTURE_MAX_DISTORTION_PER_WINDOW


func _register_tempo_distortion(family: StringName, tempo_scale_value: float, duration: float) -> void:
	if family != COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE:
		return
	_tempo_distortion_window.append({
		"t_ms": Time.get_ticks_msec(),
		"weight": maxf(1.0 - clampf(tempo_scale_value, 0.0, 1.0), 0.0) * maxf(duration, 0.0)
	})


func _apply_tempo_time_scale(tempo_scale_value: float) -> void:
	# SOVEREIGN FINAL PASS: Physically prevent engine freezes. 
	# Floor 0.35 ensures Witch Time remains fluid and active.
	Engine.time_scale = clampf(tempo_scale_value, 0.35, 1.0)
	
	# Sync Music Dilation: LPF + Pitch Shift
	if _song_conductor != null and is_instance_valid(_song_conductor):
		_song_conductor.set_tempo_distortion(tempo_scale_value)
	
	# Direct player pitch sync if not using conductor's player (Boss tracks)
	if _boss_music_player != null and is_instance_valid(_boss_music_player):
		_boss_music_player.pitch_scale = clampf(tempo_scale_value, 0.45, 1.0)


func _kill_tempo_recovery_tween() -> void:
	if _tempo_recovery_tween != null:
		_tempo_recovery_tween.kill()
		_tempo_recovery_tween = null
	_tempo_recovery_duration_ms = 0


func _ramp_to_base_time_scale(duration: float = 0.25) -> void:
	_kill_tempo_recovery_tween()
	_tempo_recovery_from_scale = clampf(Engine.time_scale, 0.35, 1.0)
	_tempo_recovery_start_ms = Time.get_ticks_msec()
	_tempo_recovery_duration_ms = int(duration * 1000.0)


func _track_tempo_event(family: StringName, event_id: StringName, payload: Dictionary = {}) -> void:
	if family == COMBAT_FEEL_CONTENT.TEMPO_NONE:
		return
	_tempo_telemetry_counts[family] = int(_tempo_telemetry_counts.get(family, 0)) + 1
	if GameState != null:
		GameState.register_tempo_event(str(family), str(event_id), payload)


func _notify_tempo_mastery(family: StringName, event_id: StringName, payload: Dictionary = {}) -> void:
	if _performance_reward_director == null or not is_instance_valid(_performance_reward_director):
		return
	if _performance_reward_director.has_method("notify_tempo_mastery"):
		_performance_reward_director.call("notify_tempo_mastery", str(family), str(event_id), payload)


func _enter_tempo_state(family: StringName, event_id: StringName, tempo_scale_value: float, duration: float = 0.0, payload: Dictionary = {}) -> bool:
	if family == COMBAT_FEEL_CONTENT.TEMPO_NONE:
		return false
	var now: int = Time.get_ticks_msec()
	var family_priority: int = _tempo_priority(family)
	var current_priority: int = _tempo_priority(_tempo_state_family)
	
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_VOID and family != COMBAT_FEEL_CONTENT.TEMPO_VOID:
		# Void (T3) is a complete tactical pause, nothing overrides it.
		return false
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE and family != COMBAT_FEEL_CONTENT.TEMPO_DECREE:
		return false
	
	# IMPACT GATING: Make these moments feel rare and earned.
	if family == COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE:
		if now < _tempo_puncture_cooldown_until_ms:
			return false
		if not bool(payload.get("impact_weight", false)):
			# Only high-weight hits (kills, elite hits) trigger hitstop.
			return false
			
	if family == COMBAT_FEEL_CONTENT.TEMPO_STRETCH:
		if now < _tempo_stretch_cooldown_until_ms:
			return false
		# Relaxed: Always allow time-bending on skill actions regardless of tier.
	if family_priority < current_priority:
		return false
	if not _tempo_distortion_available(family, tempo_scale_value, duration):
		return false
	if _tempo_state_family != COMBAT_FEEL_CONTENT.TEMPO_NONE and _tempo_state_family != family:
		_exit_tempo_state(_tempo_state_family, true)
	_kill_tempo_recovery_tween()
	_tempo_state_family = family
	_tempo_state_id = event_id
	_tempo_state_started_ms = now
	_tempo_state_until_ms = now + int(maxf(duration, 0.0) * 1000.0) if duration > 0.0 else 0
	_apply_tempo_time_scale(tempo_scale_value)
	_register_tempo_distortion(family, tempo_scale_value, duration)
	_track_tempo_event(family, event_id, payload)
	
	match family:
		COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE:
			_tempo_puncture_cooldown_until_ms = now + int(COMBAT_FEEL_CONTENT.PUNCTURE_COOLDOWN_SECONDS * 1000.0)
		COMBAT_FEEL_CONTENT.TEMPO_STRETCH:
			# Skill feedback: amber pulse to telegraph Witch Time entry
			EventBus.emit_signal("screen_flash", Color(1.0, 0.65, 0.0, 0.12), 0.08)
			# Brief cooldown so it doesn't overlap constantly, but remains reliable.
			_tempo_stretch_cooldown_until_ms = now + 1000 
		COMBAT_FEEL_CONTENT.TEMPO_VOID:
			if _song_conductor != null:
				_song_conductor.set_void_filter(true)
		COMBAT_FEEL_CONTENT.TEMPO_DECREE:
			if _hud_presenter != null:
				_hud_presenter.set_boss_state_text("BLACK SIGNAL DECREE")
	return true


func _exit_tempo_state(family: StringName, preempted: bool) -> void:
	if _tempo_state_family != family:
		return
	var exited_family: StringName = _tempo_state_family
	_tempo_state_family = COMBAT_FEEL_CONTENT.TEMPO_NONE
	_tempo_state_id = &""
	_tempo_state_until_ms = 0
	_tempo_state_started_ms = 0
	
	if exited_family == COMBAT_FEEL_CONTENT.TEMPO_VOID:
		if _song_conductor != null:
			_song_conductor.set_void_filter(false)

	if not preempted:
		_track_tempo_event(family, &"resolved", {})
	
	if preempted or family == COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE or exited_family == COMBAT_FEEL_CONTENT.TEMPO_VOID:
		_apply_tempo_time_scale(_base_time_scale)
	else:
		_ramp_to_base_time_scale()
	
	if exited_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE and _hud_presenter != null and _is_boss_encounter:
		if _boss_hp_threshold_fired:
			_hud_presenter.set_boss_state_text(PRESENTATION_TEXT.boss_state_final(_region_id))
		else:
			_hud_presenter.set_boss_state_text(PRESENTATION_TEXT.boss_state_opening(_region_id))
	if exited_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE and _song_reward_pending and not _awaiting_reward_choice and not _live_reward_queue.is_empty():
		call_deferred("_show_next_live_reward_offer")


func _recover_song_reward_flow(reason: String) -> void:
	_track_tempo_event(COMBAT_FEEL_CONTENT.TEMPO_VOID, &"stall_recovered", {
		"reason": reason
	})
	_resume_song_combat_runtime_from_reward()


func _reset_pending_reward_state(clear_live_queue: bool = false) -> void:
	_awaiting_reward_choice = false
	_reward_choice_made = false
	_active_reward_runtime = REWARD_RUNTIME_NONE
	_pending_reward_creature = {}
	_pending_reward_dna_locked = false
	_live_reward_offer_timer = 0.0
	_song_reward_stall_guard = 0.0
	if clear_live_queue:
		_live_reward_queue.clear()


func _begin_song_live_reward_runtime() -> void:
	_song_reward_pending = true
	_active_reward_runtime = REWARD_RUNTIME_SONG_LIVE
	# Keep escalation runtime alive during live reward interaction.
	# Song-pressure suspension is owned by tempo/void + explicit resume handshake.


func _is_song_live_reward_runtime_active() -> bool:
	return _song_mode and _active_reward_runtime == REWARD_RUNTIME_SONG_LIVE


func _resume_song_combat_runtime_from_reward(clear_live_queue: bool = false) -> void:
	_song_reward_pending = false
	_active_reward_runtime = REWARD_RUNTIME_NONE
	_set_song_paused(false)
	if _escalation_director != null:
		_escalation_director.resume()
	_rehydrate_song_pressure_after_reward()
	if zone_manager != null and is_instance_valid(zone_manager):
		zone_manager.start_song_cycle()
	_hide_live_reward_shell()
	_reset_pending_reward_state(clear_live_queue)
	_refresh_song_controls_text()


func _rehydrate_song_pressure_after_reward() -> void:
	if not _song_mode or _run_finished:
		return
	if zone_manager == null or not is_instance_valid(zone_manager):
		return
	if zone_manager.alive_count() > 0:
		return
	if _song_phase_index < 0 or _song_phase_index >= _song_phases.size():
		return
	var target_lane: int = _resolve_song_empty_lane_near_player()
	var phase: Dictionary = _song_phases[_song_phase_index]
	var pool: Array = phase.get("enemy_pool", [])
	if pool.is_empty():
		return
	var chosen: Dictionary = Dictionary(pool[_song_rng.randi_range(0, pool.size() - 1)]).duplicate(true)
	_place_song_enemy_data(target_lane, chosen)


func _resolve_song_empty_lane_near_player() -> int:
	if zone_manager == null:
		return 2 # East fallback

	var player_lane: int = _get_player_focus_lane()
	var total_lanes: int = int(zone_manager.THREAT_COUNT)

	# Priority 1: Current lane if empty
	if zone_manager.is_lane_empty(player_lane):
		return player_lane

	# Priority 2: Immediate adjacent lanes (8-way circle)
	var left_adj: int = (player_lane - 1 + total_lanes) % total_lanes
	var right_adj: int = (player_lane + 1) % total_lanes

	if zone_manager.is_lane_empty(left_adj):
		return left_adj
	if zone_manager.is_lane_empty(right_adj):
		return right_adj

	# Priority 3: Any empty lane
	for i in range(total_lanes):
		if zone_manager.is_lane_empty(i):
			return i

	return player_lane # Fallback to player lane if everything is full

func _get_player_focus_lane() -> int:
	if player_combat == null:
		return 2
	return player_combat.get_active_focus_lane()


func _lane_cardinal_token(lane: int) -> String:
	match lane:
		0: return "N"
		1: return "NE"
		2: return "E"
		3: return "SE"
		4: return "S"
		5: return "SW"
		6: return "W"
		7: return "NW"
		_: return "?"


func _song_reserve_count() -> int:
	if zone_manager != null:
		# In the new model, 'reserve' count is basically (total alive - strikers).
		return max(0, zone_manager.alive_count() - zone_manager.alive_striker_count())
	return 0


func _continue_after_non_song_reward_resolution() -> void:
	_reward_hint_label.text = PRESENTATION_TEXT.REWARD_HINT_WAIT
	controls_label.text = ""
	_check_for_upgrade_choices()


func _trigger_puncture(event_id: StringName, tempo_scale_value: float, duration: float, payload: Dictionary = {}) -> bool:
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE or _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_VOID:
		return false
	var clamped_scale: float = clampf(tempo_scale_value, COMBAT_FEEL_CONTENT.PUNCTURE_MIN_SCALE, COMBAT_FEEL_CONTENT.PUNCTURE_MAX_SCALE)
	var clamped_duration: float = clampf(duration, 0.04, COMBAT_FEEL_CONTENT.PUNCTURE_MAX_DURATION)
	return _enter_tempo_state(COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE, event_id, clamped_scale, clamped_duration, payload)


func _begin_void(event_id: StringName, payload: Dictionary = {}) -> void:
	# Void is a semi-pause for high-value decisions. 
	# Duration 0 means it lasts until explicit _end_void.
	_enter_tempo_state(COMBAT_FEEL_CONTENT.TEMPO_VOID, event_id, COMBAT_FEEL_CONTENT.VOID_SCALE, 0.0, payload)


func _end_void(event_id: StringName, payload: Dictionary = {}) -> void:
	if _tempo_state_family != COMBAT_FEEL_CONTENT.TEMPO_VOID:
		return
	_track_tempo_event(COMBAT_FEEL_CONTENT.TEMPO_VOID, event_id, payload)
	_exit_tempo_state(COMBAT_FEEL_CONTENT.TEMPO_VOID, false)


func _trigger_decree(event_id: StringName, duration: float, payload: Dictionary = {}) -> void:
	var clamped_duration: float = clampf(duration, COMBAT_FEEL_CONTENT.DECREE_MIN_DURATION, COMBAT_FEEL_CONTENT.DECREE_MAX_DURATION)
	_enter_tempo_state(COMBAT_FEEL_CONTENT.TEMPO_DECREE, event_id, COMBAT_FEEL_CONTENT.DECREE_SCALE, clamped_duration, payload)


func _current_void_elapsed_seconds() -> float:
	if _tempo_state_family != COMBAT_FEEL_CONTENT.TEMPO_VOID or _tempo_state_started_ms <= 0:
		return 0.0
	var now: int = Time.get_ticks_msec()
	return float(now - _tempo_state_started_ms) / 1000.0



func _update_presentation_layers(delta: float) -> void:
	if _combat_visual_rig != null and is_instance_valid(_combat_visual_rig) and zone_manager != null:
		_combat_visual_rig.global_position = zone_manager.get_player_pos()
		if player_combat != null:
			player_combat.sync_presentation_facing_with_zone_manager(zone_manager)
	if _timing_circle_container != null:
		_update_timing_ring_proximity(delta)
		if _presentation_runtime != null and player_combat != null:
			_presentation_runtime.tick_sigil_recovery(player_combat, delta)
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
	
	_presentation_controller.update_background_parallax(_bg_sprite, focus_pos, _readability_pulse_mult)
	
	# Only update tendency reaction every few frames to save performance
	if Engine.get_process_frames() % 30 == 0:
		var leading: String = RunGrowth.get_leading_tendency_id()
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
	if _music_control_layer != null:
		_music_control_layer.process_tick(delta)
	_refresh_song_combat_state()
	_ensure_song_runtime_active()
		
	if not _song_paused:
		if _song_conductor != null:
			_song_elapsed = _song_conductor.get_song_time()
			if _escalation_director != null:
				_escalation_director.update_song_time(_song_elapsed)
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


func _on_conductor_beat_pulse(beat_index: int, quality: String, intensity: float, _song_time: float) -> void:
	_last_beat_index = beat_index
	GameState.set_last_beat_quality(quality)
	var beat_intensity: float = intensity * _readability_pulse_mult
	EventBus.emit_signal("song_beat_pulse", beat_index, beat_intensity, quality)


func _should_hold_song_runtime_paused() -> bool:
	if _song_level_transitioning:
		return true
	if _is_growth_choice_active():
		return true
	if _is_run_spine_active():
		return true
	if _awaiting_upgrade_choice:
		return true
	return false


func _ensure_song_runtime_active() -> void:
	if not _song_mode or _run_finished or _song_boss_triggered:
		return
	if _should_hold_song_runtime_paused():
		return

	if _song_paused:
		_set_song_paused(false)
	elif _song_conductor != null and is_instance_valid(_song_conductor) and _song_conductor.has_method("resume"):
		# Defensive rehydration: if conductor internals desynced from _song_paused flag,
		# force resume to prevent silent post-reward freeze.
		_song_conductor.resume()

	if _escalation_director != null:
		_escalation_director.resume()
	if zone_manager != null and is_instance_valid(zone_manager):
		if not zone_manager.is_combat_running() or zone_manager.is_song_cycle_stalled():
			zone_manager.start_song_cycle()
		if zone_manager.alive_count() <= 0:
			_rehydrate_song_pressure_after_reward()


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
		var music_state: Dictionary = _song_combat_state
		if music_state.is_empty():
			_refresh_song_combat_state()
			music_state = _song_combat_state
		var progression_state: Dictionary = _build_music_progression_state()
		var run_progress: float = float(progression_state.get("run_progress", 0.0))
		var skill_expression: float = float(progression_state.get("skill_expression", 0.5))
		var phrase_intensity: float = float(music_state.get("phrase_intensity", 0.0))
		var section_mood: String = str(music_state.get("section_mood", "steady"))
		var tempo_band: String = str(music_state.get("tempo_band", "mid"))
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
		if _escalation_director != null:
			var momentum_ratio: float = _escalation_director.get_kill_momentum_ratio()
			var pressure_points: float = 0.0
			var pressure_cap: float = 0.0
			if not _latest_ecology_snapshot.is_empty():
				pressure_points = float(_latest_ecology_snapshot.get("pressure_points", 0.0))
				pressure_cap = float(_latest_ecology_snapshot.get("pressure_cap", 0.0))
			debug_text += "\nEco: M %.2f  A %d  R %d  P %.2f/%.2f" % [
				momentum_ratio,
				_active_attack_authority_budget,
				_song_reserve_count(),
				pressure_points,
				pressure_cap
			]
	if not _last_combat_input_report.is_empty():
		var input_action: String = str(_last_combat_input_report.get("action", "--")).to_upper()
		var input_lane: int = int(_last_combat_input_report.get("lane", -1))
		var accepted: bool = bool(_last_combat_input_report.get("accepted", false))
		var buffered: bool = bool(_last_combat_input_report.get("buffered", false))
		var input_reason: String = str(_last_combat_input_report.get("reason", ""))
		var input_state: String = str(_last_combat_input_report.get("state", "idle"))
		var cooldowns: Dictionary = Dictionary(_last_combat_input_report.get("cooldowns", {}))
		var lock_left: float = float(cooldowns.get("action_lock", 0.0))
		var stamina_now: float = float(cooldowns.get("stamina", 0.0))
		var ult_ready: bool = bool(cooldowns.get("ultimate_ready", false))
		var status_text: String = "OK" if accepted else ("BUF" if buffered else "NO")
		debug_text += "\nInput: %s L%d %s [%s] %s  lock=%.2f  sta=%.1f  ult=%s" % [
			input_action,
			input_lane,
			status_text,
			input_state,
			input_reason,
			lock_left,
			stamina_now,
			"Y" if ult_ready else "N"
		]
	_timing_debug_label.text = debug_text
	_timing_debug_label.modulate = UI_STYLE.get_quality_feedback_color(quality)


func _recover_stalled_cycles() -> void:
	if not _song_boss_triggered and zone_manager.is_combat_running() and zone_manager.is_song_cycle_stalled() and zone_manager.alive_count() > 0:
		zone_manager.start_song_cycle()


func _update_boss_race(delta: float) -> void:
	if _boss_race_active and _boss_music_player != null and is_instance_valid(_boss_music_player):
		var elapsed: float = _boss_music_player.get_playback_position()
		if _escalation_director != null:
			_escalation_director.update_song_time(elapsed)
		_update_boss_race_hud()
		_update_boss_presence(delta)


func _update_timing_ring_proximity(delta: float) -> void:
	_presentation_controller.update_timing_ring_proximity(
		_active_encounter,
		zone_manager,
		player_combat,
		_song_conductor,
		_timing_rings_cache,
		_ring_highlight_timers,
		_surge_window_timer,
		_surge_window_tendency,
		delta
	)


func _update_lane_visual_states() -> void:
	var biome: Dictionary = _active_encounter.get("biome", {})
	var ring_palette: Dictionary = UI_STYLE.get_combat_ring_palette()
	var lane_color: Color = biome.get("lane_color", ring_palette.get("lane", Color(0.30, 0.30, 0.35, 1.0)))
	var active_color: Color = biome.get("ring_active_color", ring_palette.get("active", Color(1.0, 0.95, 0.55, 1.0)))
	var inactive_color: Color = biome.get("ring_inactive_color", ring_palette.get("inactive", Color(0.7, 0.7, 0.8, 0.45)))
	var time: float = Time.get_ticks_msec() / 1000.0
	var critical_peak: float = 0.0
	_critical_threat_lane = -1

	for lane in range(zone_manager.THREAT_COUNT if zone_manager else 8):
		var intercept_dist: float = _lane_intercept_distance(lane)
		if intercept_dist <= 0.0:
			continue

		var outer_entry: float = 1.0 - COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS / intercept_dist
		var outer_exit: float = 1.0 + COMBAT_FEEL_CONTENT.RING_OUTER_RADIUS / intercept_dist
		var strip: TextureRect = _lane_strips.get(lane, null)
		var focus: Node2D = _lane_hit_focus.get(lane, null)
		if strip == null or focus == null or not is_instance_valid(strip) or not is_instance_valid(focus):
			continue

		var state_color: Color = lane_color
		var state_alpha: float = COMBAT_FEEL_CONTENT.LANE_IDLE_ALPHA
		var focus_alpha: float = COMBAT_FEEL_CONTENT.FOCAL_MARKER_COLOR.a
		var focus_scale: float = 1.0
		var focus_color: Color = inactive_color

		if lane == _get_player_focus_lane():
			state_alpha = maxf(state_alpha, COMBAT_FEEL_CONTENT.LANE_THREAT_FOCUS_ALPHA)
			focus_color = active_color
			focus_alpha = COMBAT_FEEL_CONTENT.FOCAL_MARKER_ACTIVE_ALPHA
			focus_scale = 1.08

		var proj = zone_manager.get_projectile(lane)
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
				if critical_t > critical_peak:
					critical_peak = critical_t
					_critical_threat_lane = lane
				else:
					critical_peak = maxf(critical_peak, critical_t)
		else:
			strip.scale.y = 1.0

		strip.modulate = Color(state_color.r, state_color.g, state_color.b, state_alpha)
		focus.modulate = Color(focus_color.r, focus_color.g, focus_color.b, focus_alpha)
		focus.scale = Vector2(focus_scale, focus_scale)

	_critical_threat_pressure = lerpf(_critical_threat_pressure, critical_peak, 0.35)
	var target_pulse_mult: float = lerpf(1.0, 0.58, clampf(_critical_threat_pressure, 0.0, 1.0))
	_readability_pulse_mult = lerpf(_readability_pulse_mult, target_pulse_mult, 0.25)
	if _presentation_runtime != null:
		_presentation_runtime.set_readability_stress(_critical_threat_pressure)
	var now_ms: int = Time.get_ticks_msec()
	if _critical_threat_pressure >= 0.86 and now_ms >= _critical_warning_cooldown_until_ms:
		var threat_msg: String = "THREAT"
		if _critical_threat_lane >= 0:
			threat_msg = "THREAT %s" % _lane_cardinal_token(_critical_threat_lane)
		_show_feedback(threat_msg, Color(1.0, 0.56, 0.38, 1.0), 0.22)
		_critical_warning_cooldown_until_ms = now_ms + CRITICAL_WARNING_COOLDOWN_MS


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	if _translation_overlay != null and _translation_overlay.visible:
		if _translation_can_continue:
			_on_translation_continue()
		get_viewport().set_input_as_handled()
		return

	if _is_growth_choice_active():
		return
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE and not _run_finished:
		# Decree moments are world-law assertions, not decision menus.
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
		RunGrowth.toggle_dna_routing_preference()
		return

	if _run_finished:
		if key_event.keycode == KEY_R:
			_start_run_engagement(true)
			return
		if key_event.keycode == KEY_T:
			get_tree().change_scene_to_file("res://scenes/ui/LairScene.tscn")
			return


func _setup_visuals() -> void:
	var refs: Dictionary = _presentation_controller.setup_visuals(
		self,
		background,
		flash_overlay,
		_bg_sprite,
		_battlefield_panel
	)
	_bg_sprite = refs.get("bg_sprite")
	_battlefield_panel = refs.get("battlefield_panel")


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


func _ensure_hud_root() -> void:
	if _hud_root != null and is_instance_valid(_hud_root):
		return
	if COMBAT_HUD_ROOT_SCENE == null:
		return
	var inst: Node = COMBAT_HUD_ROOT_SCENE.instantiate()
	if inst == null or not (inst is Control):
		if inst != null:
			inst.queue_free()
		return
	_hud_root = inst as Control
	_hud_root.name = "CombatHudRoot"
	ui_layer.add_child(_hud_root)
	_hud_decor_layer = _hud_root.get_node_or_null("DecorLayer") as Control
	_hud_primary_layer = _hud_root.get_node_or_null("PrimaryLayer") as Control
	_hud_secondary_layer = _hud_root.get_node_or_null("SecondaryLayer") as Control
	_hud_overlay_layer = _hud_root.get_node_or_null("OverlayLayer") as Control


func _setup_ui() -> void:
	_build_hud_containers()
	_build_meter_shell()
	combo_label.reparent(_hud_top_right_container)
	combo_label.text = "0"
	combo_label.visible = false # Hidden in favor of performance HUD
	combo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(combo_label, "hud_metric_value", HORIZONTAL_ALIGNMENT_RIGHT)
	combo_label.add_theme_font_size_override("font_size", 26)

	style_label.reparent(_hud_top_right_container)
	style_label.text = "Stirring"
	style_label.visible = false # Hidden in favor of performance HUD
	style_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(style_label, "hud_meta", HORIZONTAL_ALIGNMENT_RIGHT)
	style_label.add_theme_font_size_override("font_size", 15)

	var hp_row := HBoxContainer.new()
	hp_row.name = "HpRow"
	hp_row.custom_minimum_size = Vector2(0.0, 22.0)
	hp_row.add_theme_constant_override("separation", 6)
	_hud_top_left_container.add_child(hp_row)

	var hp_caption := Label.new()
	hp_caption.text = "Health"
	hp_caption.custom_minimum_size = Vector2(64.0, 0.0)
	_presentation_controller.apply_text_role(hp_caption, "hud_metric_title")
	hp_caption.add_theme_font_size_override("font_size", 14)
	hp_row.add_child(hp_caption)

	_hp_value_label = Label.new()
	_hp_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(_hp_value_label, "hud_metric_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_value_label.add_theme_font_size_override("font_size", 22)
	hp_row.add_child(_hp_value_label)

	hp_bar.reparent(_hud_top_left_container)
	hp_bar.min_value = 0.0
	hp_bar.max_value = GameState.player_max_hp
	hp_bar.value = GameState.player_hp
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(0.0, 14.0)
	hp_bar.show_percentage = false

	var stamina_row := HBoxContainer.new()
	stamina_row.name = "StaminaRow"
	stamina_row.custom_minimum_size = Vector2(0.0, 22.0)
	stamina_row.add_theme_constant_override("separation", 6)
	_hud_top_left_container.add_child(stamina_row)

	var stamina_caption := Label.new()
	stamina_caption.text = "Stamina"
	stamina_caption.custom_minimum_size = Vector2(64.0, 0.0)
	_presentation_controller.apply_text_role(stamina_caption, "hud_metric_title")
	stamina_caption.add_theme_font_size_override("font_size", 14)
	stamina_row.add_child(stamina_caption)

	stamina_bar.reparent(stamina_row)
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	stamina_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamina_bar.custom_minimum_size = Vector2(0.0, 11.0)
	stamina_bar.show_percentage = false

	# Dedicated Biomass Power Scouter (Diegetic Element)
	_scouter_shell = Panel.new()
	_scouter_shell.name = "ScouterShell"
	_scouter_shell.custom_minimum_size = Vector2(210.0, 32.0)
	UI_STYLE.apply_shell_style(_scouter_shell, "hud_accent")
	_hud_top_left_container.add_child(_scouter_shell)

	_power_scouter_label = Label.new()
	_power_scouter_label.name = "PowerScouterLabel"
	_power_scouter_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_power_scouter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power_scouter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_presentation_controller.apply_text_role(_power_scouter_label, "scouter")
	_power_scouter_label.text = "POWER LEVEL: 0"
	_scouter_shell.add_child(_power_scouter_label)

	ultimate_label.reparent(_hud_top_right_container)
	ultimate_label.text = "0%"
	ultimate_label.visible = false # Hidden in favor of performance HUD
	ultimate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(ultimate_label, "hud_meta", HORIZONTAL_ALIGNMENT_RIGHT)
	ultimate_label.add_theme_font_size_override("font_size", 16)	
	result_label.visible = false
	result_label.text = ""
	result_label.position = Vector2(320.0, 290.0)
	result_label.size = Vector2(640.0, 72.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	controls_label.visible = false # Hidden in favor of performance HUD framing
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_presentation_controller.apply_text_role(result_label, "screen_title")

	_end_stats_label = Label.new()
	_end_stats_label.name = "EndStatsLabel"
	_end_stats_label.position = Vector2(380.0, 370.0)
	_end_stats_label.size = Vector2(520.0, 160.0)
	_end_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end_stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_end_stats_label.visible = false
	_presentation_controller.apply_text_role(_end_stats_label, "secondary_value")
	_end_stats_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(_end_stats_label)

	controls_label.reparent(_hud_bottom_container)
	controls_label.text = PRESENTATION_TEXT.COMBAT_CONTROLS
	controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(controls_label, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	controls_label.add_theme_font_size_override("font_size", 16)

	_build_quig_anchor()
	_build_dna_shell()
	_build_song_hud()
	var stats_row_node: Node = _hud_top_left_container.get_node_or_null("StatsRow")
	if stats_row_node != null:
		_hud_top_left_container.move_child(stats_row_node, _hud_top_left_container.get_child_count() - 1)


func _hud_attach_combat_panel_art(panel: Control, texture_path: String, region: Rect2) -> void:
	HUD_PANEL_ART.apply_panel_art(panel, texture_path, region)


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
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(tl_panel)
	else:
		ui_layer.add_child(tl_panel)
	_enforce_top_left_panel_rect()

	var tl_body := MarginContainer.new()
	tl_body.name = "TopLeftBody"
	tl_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_wrapper_safe_zone(tl_body, COMBAT_FEEL_CONTENT.HUD_TOP_LEFT_CONTENT_MARGIN, Vector4(14.0, 8.0, 12.0, 6.0))
	tl_panel.add_child(tl_body)

	_hud_top_left_container = VBoxContainer.new()
	_hud_top_left_container.name = "TopLeftVBox"
	_hud_top_left_container.add_theme_constant_override("separation", 10)
	_hud_top_left_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_top_left_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tl_body.add_child(_hud_top_left_container)

	# Top Right Stack wrapper now owns both top metrics and persistent right-column readouts.
	var tr_panel := PanelContainer.new()
	_hud_top_right_panel = tr_panel
	tr_panel.name = "TopRightPanel"
	tr_panel.z_index = 40
	tr_panel.clip_contents = true
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
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(tr_panel)
	else:
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
	tr_stack.add_theme_constant_override("separation", int(COMBAT_FEEL_CONTENT.HUD_GAP_BELOW_TOP_BAND))
	tr_body.add_child(tr_stack)

	_hud_top_right_container = VBoxContainer.new()
	_hud_top_right_container.name = "TopRightVBox"
	_hud_top_right_container.add_theme_constant_override("separation", 10)
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
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(bottom_panel)
	else:
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


func _sync_hud_shell_interface_wound_glow() -> void:
	if _presentation_controller == null or not is_instance_valid(_presentation_controller):
		return
	var c: int = 0
	if combat_meter != null and is_instance_valid(combat_meter):
		c = int(combat_meter.combo_count)
	var norm: float = clampf(float(c) / float(CombatMeter.ULTIMATE_THRESHOLD), 0.0, 1.0)
	_presentation_controller.update_hud_interface_wound_glow(_hud_top_left_panel, _hud_top_right_panel, norm)


func _build_meter_shell() -> void:
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
		if _hud_secondary_layer != null:
			_hud_secondary_layer.add_child(_resource_shell)
		else:
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
	_support_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_support_name_label.clip_text = true
	_support_name_label.text = PRESENTATION_TEXT.SUPPORT_EMPTY_NAME
	_presentation_controller.apply_text_role(_support_name_label, "secondary_value")
	_support_name_label.add_theme_font_size_override("font_size", 15)
	support_header.add_child(_support_name_label)

	_support_value_label = Label.new()
	_support_value_label.custom_minimum_size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_ROW_WIDTH + 12.0, 22.0)
	_support_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_support_value_label.text = "--"
	_presentation_controller.apply_text_role(_support_value_label, "alert_value", HORIZONTAL_ALIGNMENT_RIGHT)
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
	_support_trigger_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_support_trigger_label.clip_text = true
	_support_trigger_label.text = ""
	_presentation_controller.apply_text_role(_support_trigger_label, "status_line")
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
	_presentation_controller.apply_text_role(eaten_caption, "caption_strong")
	eaten_caption.visible = false
	eaten_row.add_child(eaten_caption)

	_eaten_value_label = Label.new()
	_eaten_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_eaten_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_eaten_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_eaten_value_label.text = "--"
	_presentation_controller.apply_text_role(_eaten_value_label, "status_line")
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
	_presentation_controller.apply_text_role(upgrade_caption, "caption_strong")
	upgrade_caption.visible = false
	upgrade_row.add_child(upgrade_caption)

	_upgrade_value_label = Label.new()
	_upgrade_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_upgrade_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_upgrade_value_label.text = "--"
	_presentation_controller.apply_text_role(_upgrade_value_label, "alert_value")
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
	_presentation_controller.apply_text_role(bond_caption, "caption_strong")
	bond_caption.visible = false
	bond_row.add_child(bond_caption)

	_bond_value_label = Label.new()
	_bond_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bond_value_label.custom_minimum_size = Vector2(0.0, 16.0)
	_bond_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bond_value_label.text = "--"
	_presentation_controller.apply_text_role(_bond_value_label, "cool_value")
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
	stats_row.visible = false
	_hud_top_left_container.add_child(stats_row)

	var exp_caption := Label.new()
	exp_caption.text = "EXP"
	_presentation_controller.apply_text_role(exp_caption, "caption")
	exp_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(exp_caption)

	_exp_value_label = Label.new()
	_exp_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presentation_controller.apply_text_role(_exp_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_LEFT)
	_exp_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_exp_value_label)

	var def_caption := Label.new()
	def_caption.text = "Def"
	_presentation_controller.apply_text_role(def_caption, "caption")
	def_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(def_caption)

	_def_value_label = Label.new()
	_def_value_label.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(_def_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_def_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_def_value_label)

	var atk_caption := Label.new()
	atk_caption.text = "Atk"
	_presentation_controller.apply_text_role(atk_caption, "caption")
	atk_caption.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(atk_caption)

	_atk_value_label = Label.new()
	_atk_value_label.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(_atk_value_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_atk_value_label.add_theme_font_size_override("font_size", 14)
	stats_row.add_child(_atk_value_label)

	# Top-Right sub-containers for readouts
	var ult_row := HBoxContainer.new()
	ult_row.alignment = BoxContainer.ALIGNMENT_END
	ult_row.custom_minimum_size = Vector2(0.0, 22.0)
	ult_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(ult_row)
	
	var ultimate_caption := Label.new()
	ultimate_caption.text = "ULT"
	ultimate_caption.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(ultimate_caption, "caption_strong")
	ultimate_caption.add_theme_font_size_override("font_size", 14)
	ult_row.add_child(ultimate_caption)
	ultimate_label.reparent(ult_row)
	ultimate_label.custom_minimum_size = Vector2(0.0, 0.0)
	ultimate_label.clip_text = true

	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_END
	score_row.custom_minimum_size = Vector2(0.0, 22.0)
	score_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(score_row)

	var score_caption := Label.new()
	score_caption.text = "CMB"
	score_caption.custom_minimum_size = Vector2(26.0, 0.0)
	_presentation_controller.apply_text_role(score_caption, "caption_strong")
	score_caption.add_theme_font_size_override("font_size", 14)
	score_row.add_child(score_caption)
	combo_label.reparent(score_row)
	combo_label.custom_minimum_size = Vector2(0.0, 0.0)
	combo_label.clip_text = true

	var style_row := HBoxContainer.new()
	style_row.alignment = BoxContainer.ALIGNMENT_END
	style_row.custom_minimum_size = Vector2(0.0, 22.0)
	style_row.add_theme_constant_override("separation", 6)
	_hud_top_right_container.add_child(style_row)

	var style_caption := Label.new()
	style_caption.text = "STY"
	style_caption.custom_minimum_size = Vector2(24.0, 0.0)
	_presentation_controller.apply_text_role(style_caption, "caption_strong")
	style_caption.add_theme_font_size_override("font_size", 14)
	style_row.add_child(style_caption)
	style_label.reparent(style_row)
	style_label.custom_minimum_size = Vector2(0.0, 0.0)
	style_label.clip_text = true

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
	_presentation_controller.apply_text_role(_dna_route_label, "status_line", HORIZONTAL_ALIGNMENT_CENTER)
	_dna_route_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dna_route_label.add_theme_font_size_override("font_size", 15)
	dna_route_vbox.add_child(_dna_route_label)

	# Initialize mutation value label (for enhanced mutation system)
	_mutation_value_label = Label.new()
	_mutation_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mutation_value_label.custom_minimum_size = Vector2(0.0, 18.0)
	_mutation_value_label.text = ""
	_presentation_controller.apply_text_role(_mutation_value_label, "status_line", HORIZONTAL_ALIGNMENT_CENTER)
	_mutation_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mutation_value_label.add_theme_font_size_override("font_size", 15)
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
	_presentation_controller.apply_text_role(run_score_caption, "caption_strong")
	run_score_caption.add_theme_font_size_override("font_size", 14)
	run_score_row.add_child(run_score_caption)

	_run_score_label = Label.new()
	_run_score_label.name = "RunScoreLabel"
	_run_score_label.text = "0"
	_presentation_controller.apply_text_role(_run_score_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
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
	if _hud_primary_layer != null:
		_hud_primary_layer.add_child(_boss_hp_shell)
	else:
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
	_presentation_controller.apply_text_role(_boss_name_label, "boss", HORIZONTAL_ALIGNMENT_CENTER)
	_boss_name_label.add_theme_font_size_override("font_size", 26)
	_boss_name_label.visible = false
	boss_vbox.add_child(_boss_name_label)

	_boss_state_label = Label.new()
	_boss_state_label.name = "BossStateLabel"
	_boss_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_state_label.custom_minimum_size = Vector2(0.0, 14.0)
	_boss_state_label.text = ""
	_presentation_controller.apply_text_role(_boss_state_label, "body", HORIZONTAL_ALIGNMENT_CENTER)
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


func _create_panel_backing(
	node_name: String,
	texture_path: String,
	region: Rect2,
	node_position: Vector2,
	node_size: Vector2,
	node_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
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
	backing.name = node_name
	backing.texture = atlas
	backing.position = node_position
	backing.size = node_size
	backing.stretch_mode = TextureRect.STRETCH_SCALE
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.modulate = node_modulate
	ui_layer.add_child(backing)
	return backing


func _build_strip_sprite(
	node_name: String,
	texture_path: String,
	frame_size: Vector2i,
	initial_frame: int,
	node_position: Vector2,
	node_size: Vector2
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
	sprite.name = node_name
	sprite.texture = atlas
	sprite.position = node_position
	sprite.size = node_size
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
	_presentation_controller.apply_text_role(_song_phase_label, "dim", HORIZONTAL_ALIGNMENT_CENTER)
	_song_phase_label.size = Vector2(300.0, 18.0)
	_song_phase_label.position = Vector2((COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - 300.0) * 0.5, hud_ty + 4.0)
	_song_phase_label.z_index = 45
	_song_phase_label.visible = false
	if _hud_secondary_layer != null:
		_hud_secondary_layer.add_child(_song_phase_label)
	else:
		ui_layer.add_child(_song_phase_label)

	# Song timer label — upper-right, aligned with top band (above corner panels).
	_song_timer_label = Label.new()
	_song_timer_label.name = "SongTimerLabel"
	_song_timer_label.text = ""
	_presentation_controller.apply_text_role(_song_timer_label, "secondary_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_song_timer_label.size = Vector2(52.0, 18.0)
	_song_timer_label.position = Vector2(COMBAT_FEEL_CONTENT.HUD_VIEWPORT_WIDTH - hud_m - 56.0, hud_ty + 26.0)
	_song_timer_label.z_index = 45
	_song_timer_label.visible = false
	if _hud_secondary_layer != null:
		_hud_secondary_layer.add_child(_song_timer_label)
	else:
		ui_layer.add_child(_song_timer_label)

	# Beat feedback label — appears near the timing rings briefly when the player
	# lands a combat action on-beat (IN SYNC / ON BEAT / LOCKED IN / SLIP).
	# Position is tunable; currently centered on the hit zone area.
	_beat_feedback_label = Label.new()
	_beat_feedback_label.name = "BeatFeedbackLabel"
	_beat_feedback_label.text = ""
	_beat_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_beat_feedback_label.custom_minimum_size = Vector2(0.0, 20.0)
	_presentation_controller.apply_text_role(_beat_feedback_label, "alert_value", HORIZONTAL_ALIGNMENT_RIGHT)
	_beat_feedback_label.add_theme_font_size_override("font_size", 16)
	_beat_feedback_label.visible = false
	_hud_top_left_container.add_child(_beat_feedback_label)

	_sync_hud_shell_interface_wound_glow()


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
			# Keep debug builds visually clean unless explicitly enabled.
			_timing_debug_label.visible = false
			ui_layer.add_child(_timing_debug_label)

	_quig_anchor_label = Label.new()
	_quig_anchor_label.name = "QuigAnchor"
	_quig_anchor_label.visible = false
	_quig_anchor_label.position = Vector2(28.0, 0.0)
	_quig_anchor_label.size = Vector2(COMBAT_FEEL_CONTENT.RIGHT_HUD_STACK_WIDTH - 28.0, 28.0)
	_quig_anchor_label.text = ""
	_presentation_controller.apply_text_role(_quig_anchor_label, "dim")
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
	_presentation_controller.apply_text_role(dna_caption, "caption_strong")
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
		_presentation_controller.apply_text_role(label, "secondary_value")
		label.add_theme_font_size_override("font_size", 14)
		dna_vbox.add_child(label)
		_dna_slot_labels.append(label)


func _refresh_hud_snapshot(score_value: int, _exp_value: float, style_tier: String) -> void:
	if _hud_presenter == null:
		return
	_hud_presenter.refresh_primary_hud_snapshot(
		score_value,
		style_tier,
		RunGrowth,
		_song_mode,
		_song_phase_index,
		_song_phases,
		_pending_creature_snapshot()
	)


func _create_feedback_label() -> void:
	if _feedback_shell == null:
		return
	_feedback_shell.create_feedback_nodes(_hud_overlay_layer, ui_layer)


func _create_title_cards() -> void:
	if _feedback_shell == null:
		return
	_feedback_shell.create_title_cards(self)
	_title_card = _feedback_shell.get_title_card()
	_subtitle_card = _feedback_shell.get_subtitle_card()


func _create_timing_circle_container() -> void:
	_timing_circle_container = _presentation_controller.create_timing_circle_container(self)
	_timing_rings_cache.clear()


func _create_attack_fx_container() -> void:
	_attack_fx_container = _presentation_controller.create_attack_fx_container(self)


func _create_impact_fx_runtime() -> void:
	if get_node_or_null("ImpactFxRuntime") != null:
		return
	var ifx: Node = IMPACT_FX_RUNTIME_SCENE.instantiate()
	ifx.name = "ImpactFxRuntime"
	add_child(ifx)


func _setup_presentation_runtime() -> void:
	_presentation_runtime = COMBAT_PRESENTATION_RUNTIME.new(
		flash_overlay,
		camera_2d,
		_timing_circle_container,
		_attack_fx_container,
		player_combat,
		zone_manager,
		ui_layer,
		_enemy_markers_by_id,
		_ring_highlight_timers,
		_battlefield_panel,
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
	_reward_dna_label = nodes.get("reward_dna_label")
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
	_presentation_controller.set_shell_treatment(_upgrade_panel, Color(0.08, 0.06, 0.07, 0.98), Color(0.24, 0.18, 0.16, 0.94))
	_upgrade_panel.position = Vector2(120.0, 140.0)
	_upgrade_panel.size = Vector2(1040.0, 440.0)
	_upgrade_overlay.add_child(_upgrade_panel)

	var header := Label.new()
	header.text = "CHOOSE YOUR GROWTH"
	header.position = Vector2(0.0, 24.0)
	header.size = Vector2(1040.0, 40.0)
	_presentation_controller.apply_text_role(header, "heading", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(header)

	var sub := Label.new()
	sub.text = "Select one evolution to anchor before the next leg"
	sub.position = Vector2(0.0, 68.0)
	sub.size = Vector2(1040.0, 24.0)
	_presentation_controller.apply_text_role(sub, "screen_subtitle", HORIZONTAL_ALIGNMENT_CENTER)
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
		_presentation_controller.set_shell_treatment(card, Color(0.12, 0.09, 0.10, 0.96), Color(0.30, 0.22, 0.20, 0.88))
		_upgrade_panel.add_child(card)
		_upgrade_card_nodes.append(card)

		var index_label := Label.new()
		index_label.text = str(i + 1)
		index_label.position = Vector2(14.0, 14.0)
		index_label.size = Vector2(24.0, 24.0)
		_presentation_controller.apply_text_role(index_label, "card_index")
		card.add_child(index_label)

		var cat_label := Label.new()
		cat_label.name = "Category"
		cat_label.position = Vector2(14.0, 42.0)
		cat_label.size = Vector2(card_w - 28.0, 18.0)
		_presentation_controller.apply_text_role(cat_label, "caption_strong")
		card.add_child(cat_label)

		var title_label := Label.new()
		title_label.name = "Title"
		title_label.position = Vector2(14.0, 64.0)
		title_label.size = Vector2(card_w - 28.0, 48.0)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_presentation_controller.apply_text_role(title_label, "card_title")
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
		_presentation_controller.apply_text_role(body_label, "body")
		card.add_child(body_label)

	var hint := Label.new()
	hint.text = "1 / 2 / 3 - Select Upgrade"
	hint.position = Vector2(0.0, 400.0)
	hint.size = Vector2(1040.0, 24.0)
	_presentation_controller.apply_text_role(hint, "hint", HORIZONTAL_ALIGNMENT_CENTER)
	_upgrade_panel.add_child(hint)


func _create_live_reward_shell() -> void:
	var nodes: Dictionary = _presentation_controller.create_live_reward_shell(ui_layer)
	_live_reward_shell = nodes.get("live_reward_shell")
	_live_reward_title_label = nodes.get("live_reward_title_label")
	_live_reward_body_label = nodes.get("live_reward_body_label")
	_live_reward_dna_label = nodes.get("live_reward_dna_label")
	_live_reward_hint_label = nodes.get("live_reward_hint_label")


func _create_hud_presenter() -> void:
	_hud_presenter = COMBAT_HUD_PRESENTER.new(COMBAT_CONTENT, PRESENTATION_TEXT, UI_STYLE)
	var nodes: Dictionary = _build_hud_contract_nodes()
	_hud_presenter.initialize(nodes)


func _build_hud_contract_nodes() -> Dictionary:
	# Centralized node contract to keep CombatScene and CombatHUDPresenter synchronized.
	return {
		"combat_meter": combat_meter if combat_meter != null and is_instance_valid(combat_meter) else null,
		"combo_label": combo_label,
		"style_label": style_label,
		"stamina_bar": stamina_bar,
		"hp_bar": hp_bar,
		"ultimate_label": ultimate_label,
		"controls_label": controls_label,
		"hp_value_label": _hp_value_label,
		"exp_value_label": _exp_value_label,
		"power_scouter_label": _power_scouter_label,
		"scouter_shell": _scouter_shell,
		"support_shell": _support_shell,
		"support_bar": _support_bar,
		"support_value_label": _support_value_label,
		"support_name_label": _support_name_label,
		"support_trigger_label": _support_trigger_label,
		"support_creature_portrait": null,
		"run_build_shell": _run_build_shell,
		"eaten_value_label": _eaten_value_label,
		"upgrade_value_label": _upgrade_value_label,
		"bond_value_label": _bond_value_label,
		"atk_value_label": _atk_value_label,
		"def_value_label": _def_value_label,
		"dna_route_label": _dna_route_label,
		"dna_route_shell": _dna_route_shell,
		"mutation_value_label": _mutation_value_label,
		"dna_shell": _dna_shell,
		"dna_emblem": _dna_emblem,
		"dna_slot_labels": _dna_slot_labels,
		"boss_hp_shell": _boss_hp_shell,
		"boss_hp_bar": _boss_hp_bar,
		"boss_name_label": _boss_name_label,
		"boss_state_label": _boss_state_label,
		"song_timer_label": _song_timer_label,
		"song_phase_label": _song_phase_label,
		"run_score_label": _run_score_label,
		"beat_feedback_label": _beat_feedback_label,
	}


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
		_performance_reward_director.call("bind_runtime", combat_meter, RunGrowth, RunStats)
		_performance_reward_director.set("offers_enabled", false)
		if _performance_reward_director.has_method("sync_from_reward_state"):
			_performance_reward_director.call("sync_from_reward_state")
		elif _performance_reward_director.has_method("sync_from_gamestate"):
			_performance_reward_director.call("sync_from_gamestate")

	if _performance_reward_director.has_signal("proc_feedback"):
		_performance_reward_director.connect("proc_feedback", Callable(self, "_on_performance_reward_feedback"))
	if _performance_reward_director.has_signal("pressure_bias_changed"):
		_performance_reward_director.connect("pressure_bias_changed", Callable(self, "_on_performance_pressure_bias_changed"))


func _setup_vessel_modifier_director() -> void:
	# Connect listener first so the initial _refresh_active_vessel() inside bind_runtime
	# delivers vessel_shifted to this scene when the run resumes with a bonded creature.
	if not EventBus.vessel_shifted.is_connected(_on_vessel_shifted):
		EventBus.vessel_shifted.connect(_on_vessel_shifted)

	_vessel_modifier_director = VESSEL_MODIFIER_DIRECTOR.new()
	_vessel_modifier_director.name = "VesselModifierDirector"
	add_child(_vessel_modifier_director)
	_vessel_modifier_director.bind_runtime(zone_manager)


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
	
	# Add to overlay layer for full-screen framing
	if _hud_overlay_layer != null:
		_hud_overlay_layer.add_child(_performance_hud)
	elif _hud_primary_layer != null:
		_hud_primary_layer.add_child(_performance_hud)
	else:
		ui_layer.add_child(_performance_hud)
		
	_performance_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_performance_hud.offset_left = 0
	_performance_hud.offset_top = 0
	_performance_hud.offset_right = 0
	_performance_hud.offset_bottom = 0
	_performance_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE

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


func _on_performance_pressure_bias_changed(snapshot: Dictionary) -> void:
	if not _song_mode or _song_paused or _song_boss_triggered or _run_finished:
		return
	if _song_phase_index < 0 or _song_phase_index >= _song_phases.size():
		return
	var pressure_ratio: float = clampf(float(snapshot.get("pressure_ratio", 0.0)), 0.0, 1.0)
	var pressure_step: int = int(round(pressure_ratio * 10.0))
	if pressure_step == _last_applied_hunt_pressure_step:
		return
	_last_applied_hunt_pressure_step = pressure_step
	_apply_song_phase_cadence(_song_phases[_song_phase_index], _song_section_spawn_mult)


func _on_performance_reward_feedback(text: String, color: Color) -> void:
	_show_feedback(text, color, 0.34)
	# Chip feedback is handled by _performance_hud itself via signals.


func _connect_eventbus() -> void:
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.player_took_damage.connect(_on_player_took_damage)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.ultimate_available.connect(_on_ultimate_available)
	EventBus.ultimate_fired.connect(_on_ultimate_fired)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.enemy_defeated.connect(_presentation_runtime.on_enemy_defeated)
	EventBus.dna_lock_denied.connect(_on_dna_lock_denied)
	EventBus.proc_feedback_requested.connect(_on_proc_feedback_requested)
	EventBus.ultimate_power_granted.connect(_on_ultimate_power_granted)
	EventBus.enemy_status_applied_requested.connect(_on_enemy_status_applied_requested)
	EventBus.screen_flash.connect(_presentation_runtime.on_screen_flash)
	EventBus.screen_shake.connect(_presentation_runtime.on_screen_shake)
	EventBus.ui_shake.connect(_presentation_runtime.on_ui_shake)
	EventBus.dna_resonated.connect(_presentation_runtime.on_dna_resonated)
	EventBus.slow_motion.connect(_on_slow_motion)
	EventBus.player_attacked.connect(_on_player_attacked)
	EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	EventBus.attack_timing_early_resolved.connect(_on_attack_timing_early_resolved)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.player_dodged.connect(_on_player_dodged)
	EventBus.combat_input_resolved.connect(_on_combat_input_resolved)
	EventBus.player_no_stamina.connect(_on_player_no_stamina)
	EventBus.combo_broken.connect(_on_combo_broken)
	EventBus.player_teleported.connect(_on_player_teleported)
	EventBus.timing_ring_pressed.connect(_presentation_runtime.on_timing_ring_pressed)
	EventBus.song_beat_pulse.connect(_presentation_runtime.on_song_beat_pulse)
	EventBus.projectile_fired.connect(_presentation_runtime.on_projectile_fired)
	EventBus.run_growth_changed.connect(_on_run_growth_changed)
	EventBus.run_growth_level_resolved.connect(_on_run_growth_level_resolved)
	EventBus.tendency_growth_resolved.connect(_on_tendency_growth_resolved)
	EventBus.support_charge_changed.connect(_on_support_charge_changed)
	EventBus.creature_bonded.connect(_on_creature_bonded)
	EventBus.dna_routing_changed.connect(_on_dna_routing_changed)
	EventBus.bonded_support_triggered.connect(_on_bonded_support_triggered)
	EventBus.dna_gained.connect(_on_dna_gained)
	EventBus.mastery_context_updated.connect(_on_mastery_context_updated)
	EventBus.impact_burst_requested.connect(_presentation_runtime.apply_impact_profile)
	EventBus.enemy_status_applied.connect(_on_enemy_status_applied)
	EventBus.enemy_status_cleared.connect(_on_enemy_status_cleared)
	EventBus.phrase_milestone.connect(_on_phrase_milestone)
	EventBus.tier_changed.connect(_on_tier_changed)
	EventBus.quig_narrative_triggered.connect(_on_quig_narrative_triggered)


func _setup_zone_manager() -> void:
	zone_manager.setup_layout(get_viewport_rect().size)

	if not zone_manager.load_scene():
		push_error("ZoneManager failed to load projectile scene.")
		return

	zone_manager.combat_scene = self
	_active_attack_authority_budget = int(zone_manager.THREAT_COUNT)
	zone_manager.set_attack_authority_budget(_active_attack_authority_budget)


func _setup_player_combat() -> void:
	# Keep player silhouette above timing sigil visuals for readability.
	player_combat.z_index = 25
	player_combat.setup(zone_manager, combat_meter)


func _start_song_run() -> void:
	_song_mode = true
	_song_elapsed = 0.0
	_set_song_paused(false)
	_reset_tempo_state()
	_song_phase_index = -1
	_song_boss_triggered = false
	_song_level_transitioning = false
	_next_song_enemy_id = 100
	_song_reward_pending = false
	_active_reward_runtime = REWARD_RUNTIME_NONE
	_between_level_growth_stored_this_level = false
	_song_enemy_lanes.clear()
	_latest_ecology_snapshot.clear()
	_song_rng.randomize()
	_song_section_spawn_mult = 1.0
	_song_level_start_time = 0.0
	_song_level_end_time = 0.0
	_base_difficulty_modifiers = {}
	_difficulty_modifiers = {}
	if _music_control_layer != null:
		_music_control_layer.reset()
	_song_combat_state.clear()
	_clear_mastery_context_cache()
	_last_applied_hunt_pressure_step = -1

	_run_director.initialize_run(str(GameState.active_region.get("id", "feeding_hollow")), _dev_harness_request)
	_active_song_data = _run_director.get_active_song_data()
	_active_song_profile = _run_director.get_active_song_profile()
	_active_song_map = _run_director.get_active_song_map()

	_start_regular_level(_run_director.regular_level_index, true)


func _resolve_active_song_duration() -> float:
	var song_path: String = str(_active_song_data.get("file_path", ""))
	if song_path.is_empty():
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	var stream: AudioStream = ResourceLoader.load(song_path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
	if stream == null:
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	var stream_duration: float = stream.get_length()
	if stream_duration <= 0.0:
		return RUN_PACING_CONTENT.MAX_REGULAR_LEVEL_DURATION_SECONDS
	return stream_duration


func _start_regular_level(level_index: int, reset_hp: bool) -> void:
	var level_data: Dictionary = _run_director.start_level(level_index, reset_hp)
	if level_data.get("is_boss_trigger", false):
		_trigger_boss_final_movement()
		return

	_active_song_data = Dictionary(level_data.get("song_data", {}))
	_active_song_profile = Dictionary(_run_director.get_active_song_profile())
	_active_song_map = level_data.get("song_map", TRICKY_SONGMAP)
	if _music_control_layer != null:
		_music_control_layer.configure(_active_song_profile)
	_set_song_paused(false)
	_reset_tempo_state()
	_song_level_transitioning = false
	_song_level_start_time = float(level_data.get("start_time", 0.0))
	_song_level_end_time = float(level_data.get("end_time", 0.0))
	_song_section_spawn_mult = 1.0
	_song_phase_index = -1
	_last_applied_hunt_pressure_step = -1
	_last_beat_index = -1
	_song_elapsed = _song_level_start_time
	_song_reward_pending = false
	_active_reward_runtime = REWARD_RUNTIME_NONE
	_between_level_growth_stored_this_level = false
	_song_enemy_lanes.clear()
	_latest_ecology_snapshot.clear()
	_status_marker_overrides.clear()
	if _song_mode and not _is_boss_encounter:
		_clear_song_enemy_tracking()
	if zone_manager != null:
		zone_manager.stop()
	zone_manager.set_song_mode_enabled(true)
	_active_attack_authority_budget = int(zone_manager.THREAT_COUNT)
	_apply_attack_authority_budget()

	_base_difficulty_modifiers = Dictionary(level_data.get("difficulty_modifiers", {}))
	var song_run_data: Dictionary = Dictionary(level_data.get("song_run", {}))
	_song_phases = song_run_data.get("phases", [])
	
	for i in range(_song_phases.size()):
		var phase: Dictionary = _song_phases[i]
		phase["start_time"] = float(phase.get("start_time", 0.0)) + _song_level_start_time
		_song_phases[i] = phase

	if _performance_reward_director != null and is_instance_valid(_performance_reward_director):
		if reset_hp and _performance_reward_director.has_method("start_song_run"):
			_performance_reward_director.call("start_song_run", _song_phases)

	_active_encounter = {
		"biome": song_run_data.get("biome", COMBAT_CONTENT.BIOME_FEEDING_HOLLOW),
		"identity": song_run_data.get("identity", {}),
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
		if "BPM" in _active_song_map:
			_escalation_director.set_song_bpm(float(_active_song_map.BPM))
		_escalation_director.start(_song_level_start_time)
	_rebuild_music_driven_difficulty()

	zone_manager.set_song_mode_enabled(true)

	if _song_timer_label != null:
		_song_timer_label.visible = true
	if _song_phase_label != null:
		_song_phase_label.visible = true
	_hud_presenter.update_song_timer(max(_song_level_end_time - _song_level_start_time, 0.0))

	_set_song_controls_text()

	# Enter phase 0 for this regular level and begin from its song window start.
	var start_phase_index: int = 0
	_enter_song_phase(start_phase_index)

	# Start the conductor inside this authored level window.
	_start_song_conductor(_song_level_start_time, _song_level_end_time)
	var level_label: String = str(level_data.get("label", "LEVEL %d" % (_run_director.regular_level_index + 1)))
	var song_name: String = str(level_data.get("song_display_name", ""))
	var node_name: String = str(_run_director.active_path_context.get("display_name", "Prey"))
	var run_track_text: String = song_name if not song_name.is_empty() else "Unknown Track"
	_show_feedback("%s  [%d/%d]  •  %s  •  %s" % [level_label, _run_director.regular_level_index + 1, _run_director.regular_level_windows.size(), node_name, run_track_text], Color(0.90, 0.84, 0.66, 1.0), 0.48)


func _advance_to_next_regular_level() -> void:
	if _song_level_transitioning:
		return
	_song_level_transitioning = true

	if _run_director != null:
		_run_director.complete_level()

		# Clear gains now that they've been presented
		RunGrowth.clear_combat_gains()

		_prepare_path_context_for_level(_run_director.regular_level_index)
		var encounter_options: Dictionary = Dictionary(_active_path_context.get("encounter_options", {}))
		if bool(encounter_options.get("is_event", false)):
			_song_level_transitioning = false 
			_create_event_surface()
			var event_type = str(encounter_options.get("event_type", "narrative"))
			var event_id = EVENT_CONTENT.get_random_event_id_for_type(event_type)
			_event_surface.present_event(event_id)
			return

	_start_regular_level(_run_director.regular_level_index, false)

func _on_regular_level_complete() -> void:
	if _song_boss_triggered or not _song_mode or _is_run_spine_active():
		return

	# Stop combat, pacing, and song transport.
	_set_song_paused(true)
	if zone_manager != null:
		zone_manager.stop()
	if _escalation_director != null:
		_escalation_director.pause()
	_stop_song_conductor()

	_song_reward_pending = false
	_reset_pending_reward_state(true)
	_hide_live_reward_shell()

	if RunGrowth.get("pending_bonds") is Array:
		RunGrowth.get("pending_bonds").clear()
	_between_level_growth_queue.clear()
	
	_show_translation_overlay()


func _create_translation_overlay() -> void:
	if _translation_overlay != null: return
	
	_translation_overlay = ColorRect.new()
	_translation_overlay.name = "TranslationOverlay"
	_translation_overlay.visible = false
	_translation_overlay.color = Color(0.01, 0.01, 0.02, 0.95)
	_translation_overlay.anchor_right = 1.0
	_translation_overlay.anchor_bottom = 1.0
	_translation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(_translation_overlay)
	
	var panel = ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.07, 0.60)
	panel.anchor_left = 0.5; panel.anchor_top = 0.5
	panel.anchor_right = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -400.0; panel.offset_top = -240.0
	panel.offset_right = 400.0; panel.offset_bottom = 200.0
	UI_STYLE.apply_shell_style(panel, "mm_shell")
	_translation_overlay.add_child(panel)
	
	_translation_header = Label.new()
	_translation_header.text = "LINEAGE EXTRACTION"
	_translation_header.position = Vector2(0, 20)
	_translation_header.size = Vector2(800, 50)
	UI_STYLE.apply_label(_translation_header, "mm_title", HORIZONTAL_ALIGNMENT_CENTER)
	_translation_header.add_theme_color_override("font_color", UI_STYLE.get_manga_color("blood_ember"))
	panel.add_child(_translation_header)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(40, 80)
	scroll.size = Vector2(720, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	
	_translation_body = Label.new()
	_translation_body.custom_minimum_size = Vector2(720, 0)
	_translation_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_translation_body, "mm_body")
	_translation_body.add_theme_font_size_override("font_size", 13)
	scroll.add_child(_translation_body)
	
	_translation_hint = Label.new()
	_translation_hint.text = "PRESS ANY KEY TO CONTINUE"
	_translation_hint.position = Vector2(0, 370)
	_translation_hint.size = Vector2(800, 30)
	UI_STYLE.apply_label(_translation_hint, "mm_hint", HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(_translation_hint)


func _show_translation_overlay() -> void:
	_create_translation_overlay()
	
	var lines: Array[String] = []
	lines.append("[ FEED PERFORMANCE ]")
	lines.append("• Marks Extracted: %d" % RunStats.combat_kills)
	lines.append("• Damage Output: %.0f" % RunStats.combat_damage)
	lines.append("• Perfect Syncs: %d" % RunStats.combat_perfects)
	if RunStats.combat_hits == 0:
		lines.append("• Vessel Integrity: UNTOUCHED (+Bonus)")
	else:
		lines.append("• Vessel Breaches: %d" % RunStats.combat_hits)
	lines.append("")

	var gains: Array[Dictionary] = RunGrowth.get_gains_this_combat()
	if not gains.is_empty():
		lines.append("[ GROWTH EVOLVED ]")
		for gain in gains:
			lines.append("• %s: %s" % [str(gain.get("title", "LEVEL UP")), str(gain.get("summary", ""))])
		lines.append("")
	
	_translation_body.text = "\n".join(PackedStringArray(lines))
	_translation_overlay.visible = true
	_translation_can_continue = false
	
	var t = create_tween()
	_translation_overlay.modulate.a = 0.0
	t.tween_property(_translation_overlay, "modulate:a", 1.0, 0.25)
	t.tween_callback(func(): _translation_can_continue = true)


func _hide_translation_overlay() -> void:
	if _translation_overlay:
		_translation_overlay.visible = false
	_translation_can_continue = false


func _on_translation_continue() -> void:
	_hide_translation_overlay()
	_show_next_between_level_growth_choice()


func _on_run_director_drop_scheduled(target_time: float) -> void:
	_hide_run_spine_surface()
	_hide_growth_choice_surface()
	_show_feedback("PREPARE...", Color(0.9, 0.4, 0.3, 1.0), 0.8)
	
	# Open the gate for the upcoming advance.
	_song_level_transitioning = false

	var current_song_time: float = 0.0
	if _song_conductor != null and is_instance_valid(_song_conductor):
		current_song_time = _song_conductor.get_song_time()
	var time_until_drop: float = target_time - current_song_time
	get_tree().create_timer(max(time_until_drop - 0.1, 0.01)).timeout.connect(
		func(): 
			_advance_to_next_regular_level()
	)

func _show_level_completion_rewards() -> void:
	_hide_reward_overlay()
	_hide_run_spine_surface()
	_hide_growth_choice_surface()

	_pending_upgrades.clear()
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director):
		if _performance_reward_director.has_method("get_level_completion_context") and _performance_reward_director.has_method("set_level_completion_context"):
			var completion_context: Dictionary = _performance_reward_director.call("get_level_completion_context")
			completion_context["regular_level_index"] = _run_director.regular_level_index
			completion_context["regular_level_count"] = _run_director.regular_level_windows.size()
			completion_context["power_level"] = GameState.get_power_level()
			completion_context["growth_level"] = RunGrowth.level if RunGrowth != null else 1
			_performance_reward_director.call("set_level_completion_context", completion_context)
		_pending_upgrades = _performance_reward_director.call("get_level_completion_choices", 3)

	var advancing_to_boss: bool = _run_director.regular_level_index + 1 >= _run_director.regular_level_windows.size()
	if _run_spine_surface != null:
		_run_spine_surface.present_level_completion(_pending_upgrades, RunGrowth, advancing_to_boss)
	_show_feedback("LEVEL COMPLETE", Color(0.85, 0.95, 0.75, 1.0), 0.60)
	controls_label.text = ""


func _show_next_between_level_growth_choice() -> void:
	if _between_level_growth_queue.is_empty():
		_show_level_completion_rewards()
		return
	var creature_data: Dictionary = _between_level_growth_queue.pop_front()
	if creature_data.is_empty():
		_show_next_between_level_growth_choice()
		return
	_show_growth_choice_intersection(creature_data, "song_between_level", "run_spine", false)


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
	var species_id: String = str(_pending_reward_creature.get("species_id", ""))
	var effective_threshold: float = GameState.get_effective_dna_threshold(species_id)
	_pending_reward_dna_locked = not GameState.has_dna_for(species_id, effective_threshold)
	_awaiting_reward_choice = true
	_reward_choice_made = false

	var perf_summary: Dictionary = {}
	perf_summary = RunStats.get_compact_summary()

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
		"eat_available": true,
		"fail_safe_pass_allowed": _pending_reward_dna_locked or source_flow == "song_between_level"
	}
	GameState.set_growth_choice_intersection_payload(payload)
	EventBus.emit_signal("capture_offered", _pending_reward_creature)

	_hide_reward_overlay()
	_hide_run_spine_surface()
	
	_begin_void(&"growth_choice_intersection", {
		"species_id": str(_pending_reward_creature.get("species_id", ""))
	})
	
	if _growth_choice_surface != null and is_instance_valid(_growth_choice_surface):
		_growth_choice_surface.present()
	controls_label.text = ""
	_show_feedback("GROWTH INTERSECTION", Color(0.90, 0.80, 0.64, 1.0), 0.42)


func _create_run_spine_surface() -> void:
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface):
		return
	_run_spine_surface = RUN_SPINE_SCENE.instantiate() as RunSpineScene
	_run_spine_surface.name = "RunSpineSurface"
	_run_spine_surface.visible = false
	add_child(_run_spine_surface)
	_run_spine_surface.upgrade_selected.connect(_on_run_spine_upgrade_selected)
	if _run_spine_surface.has_signal("continue_requested"):
		_run_spine_surface.connect("continue_requested", Callable(self, "_on_run_spine_continue_requested"))
	if _run_spine_surface.has_signal("predation_selected"):
		_run_spine_surface.connect("predation_selected", Callable(self, "_on_run_spine_predation_selected"))
	if _run_spine_surface.has_signal("path_node_selected"):
		_run_spine_surface.connect("path_node_selected", Callable(self, "_on_run_spine_path_node_selected"))
	if _run_spine_surface.has_signal("management_action_requested"):
		_run_spine_surface.connect("management_action_requested", Callable(self, "_on_run_spine_management_action_requested"))


func _create_event_surface() -> void:
	if _event_surface != null and is_instance_valid(_event_surface):
		return
	_event_surface = EVENT_SCENE.instantiate() as EventScene
	add_child(_event_surface)
	_event_surface.event_completed.connect(_on_event_completed)


func _on_event_completed(choice: Dictionary) -> void:
	if choice.is_empty():
		# User just closed or no choice made, skip and move on
		_complete_event_flow()
		return
	
	# Apply cost
	var cost: Dictionary = Dictionary(choice.get("cost", {}))
	if not cost.is_empty():
		var type = str(cost.get("type", ""))
		var val = float(cost.get("value", 0))
		if type == "dna":
			GameState.spend_dna(str(cost.get("species", "")), val)
		elif type == "dna_any":
			GameState.spend_dna_any(val)
	
	# Apply effects
	var effect: Dictionary = Dictionary(choice.get("effect", {}))
	_apply_event_effect(effect)
	
	_show_feedback("EVENT RESOLVED  •  %s" % str(choice.get("label", "Outcome")).to_upper(), Color(0.72, 0.90, 0.66, 1.0), 0.55)
	_complete_event_flow()


func _apply_event_effect(effect: Dictionary) -> void:
	var type = str(effect.get("type", ""))
	match type:
		"fate_shift":
			var fate_id = str(effect.get("fate_id", ""))
			var amount = float(effect.get("amount", 0.0))
			if GameState.world_fate_channels.has(fate_id):
				GameState.world_fate_channels[fate_id] = clampf(GameState.world_fate_channels[fate_id] + amount, 0.0, 1.0)
				# Trigger re-dominance check if GameState has it
				GameState._resolve_world_fate_dominance()
		"hp_restore":
			GameState.player_hp = minf(GameState.player_hp + float(effect.get("value", 0)), GameState.player_max_hp)
		"hp_restore_percent":
			GameState.player_hp = minf(GameState.player_hp + GameState.player_max_hp * float(effect.get("value", 0)), GameState.player_max_hp)
		"permanent_stat_gain":
			var stat = str(effect.get("stat", ""))
			var val = float(effect.get("value", 0))
			if stat in ["player_base_damage", "player_max_hp", "player_defense"]:
				GameState.set(stat, GameState.get(stat) + val)
		"multi":
			for e in effect.get("effects", []):
				_apply_event_effect(Dictionary(e))


func _complete_event_flow() -> void:
	if _run_director != null:
		_run_director.complete_level()
		# After an event, we usually want to present the next path choice if it's a branch
		if not _try_present_path_choice_after_run_spine():
			# If no branch choice, advance to next level automatically
			_advance_to_next_regular_level()
	else:
		_advance_to_next_regular_level()


func _create_growth_choice_surface() -> void:
	if _growth_choice_surface != null and is_instance_valid(_growth_choice_surface):
		return
	_growth_choice_surface = GROWTH_CHOICE_SCENE.instantiate() as GrowthChoiceIntersection
	_growth_choice_surface.name = "GrowthChoiceSurface"
	_growth_choice_surface.visible = false
	add_child(_growth_choice_surface)
	_growth_choice_surface.growth_choice_selected.connect(_on_growth_choice_selected)


func _is_growth_choice_active() -> bool:
	return _growth_choice_surface != null and is_instance_valid(_growth_choice_surface) and _growth_choice_surface.visible


func _hide_growth_choice_surface() -> void:
	if _growth_choice_surface != null and is_instance_valid(_growth_choice_surface):
		_growth_choice_surface.hide_surface()
	
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_VOID:
		_end_void(&"growth_choice_hidden")


func _on_growth_choice_selected(choice_id: String) -> void:
	if _victory_reward_director != null:
		_victory_reward_director.resolve_choice(choice_id)

	var source_flow: String = str(_growth_choice_context.get("source_flow", "route"))
	_growth_choice_context.clear()

	if source_flow == "song":
		_show_level_completion_rewards()
	elif source_flow == "song_between_level":
		# Between-level growth must always collapse back to the management shell
		# after one decision, regardless of B/E/N choice.
		_between_level_growth_queue.clear()
		_show_level_completion_rewards()
	else:
		_check_for_upgrade_choices()


func _is_run_spine_active() -> bool:
	return _run_spine_surface != null and is_instance_valid(_run_spine_surface) and _run_spine_surface.visible


func _hide_run_spine_surface() -> void:
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface):
		_run_spine_surface.hide_surface()


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

	if _run_spine_surface != null:
		_run_spine_surface.notify_upgrade_committed(index)
	_pending_upgrades.clear()


func _try_present_predation_after_run_spine() -> bool:
	_pending_predation.clear()
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("consume_pending_predation_offers"):
		_pending_predation = _performance_reward_director.call("consume_pending_predation_offers", 2)
	if _pending_predation.is_empty():
		return false
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface):
		_run_spine_surface.present_predation_pool(_pending_predation)
		return true
	return false


func _on_run_spine_predation_selected(index: int) -> void:
	if index < 0 or index >= _pending_predation.size():
		return
	var choice: Dictionary = _pending_predation[index]
	if not PREDATION_POOL.apply_choice(choice, RunGrowth):
		return
	_refresh_run_build_readout()
	_show_feedback("PREDATION TAKEN", Color(0.88, 0.62, 0.42, 1.0), 0.55)
	_pending_predation.clear()
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface):
		_run_spine_surface.notify_predation_committed(index)
	_try_present_path_choice_after_run_spine()


func _try_present_path_choice_after_run_spine() -> bool:
	var next_level_index: int = _run_director.regular_level_index + 1
	if next_level_index >= _run_director.regular_level_windows.size():
		return false
	if not PATH_RUN_PLAN.is_branch_slot(GameState.run_path_plan, next_level_index):
		return false
	var candidates: Array[Dictionary] = PATH_RUN_PLAN.get_branch_candidates(GameState.run_path_plan, next_level_index)
	if candidates.is_empty():
		return false
	_pending_path_choice_nodes = candidates
	_pending_path_choice_level_index = next_level_index
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface):
		var branch_label: String = _path_branch_label_for_level(next_level_index)
		_show_feedback(
			"PATH BRANCH %s  •  choose L%d" % [branch_label, next_level_index + 1],
			Color(0.72, 0.90, 0.98, 1.0),
			0.55
		)
		_run_spine_surface.present_path_choice(candidates, false)
		return true
	return false


func _on_run_spine_path_node_selected(node_id: String) -> void:
	if _pending_path_choice_level_index < 0:
		return
	var valid_choice: bool = false
	var chosen_node: Dictionary = {}
	for node in _pending_path_choice_nodes:
		if str(node.get("id", "")) == node_id:
			valid_choice = true
			chosen_node = Dictionary(node).duplicate(true)
			break
	if not valid_choice:
		return
	if not PATH_RUN_PLAN.validate_node_access(node_id, GameState):
		_show_feedback(
			"PATH LOCKED  •  cannot pay entry cost",
			Color(0.95, 0.34, 0.20, 1.0),
			0.65
		)
		return
	PATH_RUN_PLAN.apply_node_effects(chosen_node, GameState, RunGrowth, _performance_reward_director, true)
	GameState.run_path_plan = PATH_RUN_PLAN.apply_branch_choice(GameState.run_path_plan, _pending_path_choice_level_index, node_id)
	GameState.run_path_chosen_ids.append(node_id)
	var chosen_name: String = node_id.replace("_", " ").to_upper()
	for node in _pending_path_choice_nodes:
		if str(node.get("id", "")) == node_id:
			chosen_name = str(node.get("display_name", chosen_name))
			break
	_show_feedback(
		"PATH LOCKED  •  %s  ->  L%d" % [chosen_name, _pending_path_choice_level_index + 1],
		Color(0.80, 0.90, 0.66, 1.0),
		0.55
	)
	_pending_path_choice_nodes.clear()
	_pending_path_choice_level_index = -1
	if _run_spine_surface != null and is_instance_valid(_run_spine_surface):
		_run_spine_surface.notify_path_committed(node_id)


func _on_run_spine_management_action_requested(action_id: String, payload: Dictionary) -> void:
	var status: String = str(payload.get("status", ""))
	match action_id:
		"equip":
			if status == "ok":
				_show_feedback("EQUIPPED  •  BUILD LOCKED", Color(0.68, 0.90, 0.74, 1.0), 0.30)
			else:
				_show_feedback("EQUIP FAILED", Color(0.90, 0.52, 0.44, 1.0), 0.30)
		"salvage":
			if status == "ok":
				_show_feedback("SALVAGED  •  SLOT OPENED", Color(0.84, 0.72, 0.48, 1.0), 0.30)
			else:
				_show_feedback("SALVAGE FAILED", Color(0.90, 0.52, 0.44, 1.0), 0.30)
		"collar_equip":
			if status == "ok":
				_show_feedback("COLLAR EQUIPPED", Color(0.72, 0.88, 1.0, 1.0), 0.32)
			else:
				_show_feedback("COLLAR EQUIP FAILED", Color(0.90, 0.52, 0.44, 1.0), 0.30)
		"collar_unlock":
			if status == "ok":
				_show_feedback("COLLAR UNLOCKED", Color(0.72, 0.88, 1.0, 1.0), 0.32)
			else:
				_show_feedback("COLLAR NEEDS DNA", Color(0.90, 0.52, 0.44, 1.0), 0.30)
	_refresh_run_build_readout()


func _on_run_spine_continue_requested(advance_to_boss: bool) -> void:
	_hide_run_spine_surface()
	
	if advance_to_boss:
		_trigger_boss_final_movement()
	else:
		_advance_to_next_regular_level()


func _prepare_path_context_for_level(level_index: int) -> void:
	_run_director.prepare_path_context_for_level(level_index)
	_active_path_context = _run_director.active_path_context


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
		if zone_manager != null:
			if profile.has("cycle_interval"):
				zone_manager.set_cycle_interval(profile["cycle_interval"])
			if profile.has("fire_stagger"):
				zone_manager.set_fire_stagger(profile["fire_stagger"])

	_apply_song_phase_cadence(new_phase, _song_section_spawn_mult)
	_apply_attack_authority_budget(_latest_ecology_snapshot, new_phase)

	if _song_phase_label != null:
		_song_phase_label.text = ENCOUNTER_IDENTITY_RUNTIME.get_phase_display_label(_region_id, new_phase)

	# If the previous phase had a reward pool, queue its creature offer without pausing the song.
	if old_idx >= 0:
		var old_phase: Dictionary = _song_phases[old_idx]
		var reward_pool: Array = old_phase.get("reward_pool", [])
		if not reward_pool.is_empty():
			_offer_song_phase_reward(reward_pool)


func _place_song_enemy_data(lane: int, enemy_data: Dictionary) -> void:
	if enemy_data.is_empty():
		return

	var seeded_enemy: Dictionary = enemy_data.duplicate(true)
	if int(seeded_enemy.get("id", -1)) < 0:
		seeded_enemy["id"] = _next_song_enemy_id
		_next_song_enemy_id += 1

	# LaneManager handles internal orbiting if the active attack budget is full.
	# It also handles ID generation if needed.
	zone_manager.set_enemy(lane, seeded_enemy)

	var enemies: Dictionary = zone_manager.get_all_enemies()
	var enemy_id: int = int(seeded_enemy.get("id", -1))
	if not enemies.has(enemy_id):
		enemy_id = _resolve_newest_untracked_enemy_id(enemies)

	if enemy_id == -1: return

	var enemy_final: Dictionary = enemies[enemy_id]
	_all_enemies_by_id[enemy_id] = enemy_final.duplicate(true)
	_enemy_max_hp[enemy_id] = float(enemy_final.get("hp", 1.0))
	_enemy_phase_by_id[enemy_id] = _song_phase_index

	var biome: Dictionary = _active_encounter.get("biome", {})
	var inactive_color: Color = biome.get("enemy_inactive_color", Color(0.38, 0.18, 0.18, 0.55))
	var marker_data: Dictionary = _build_enemy_marker(enemy_id, lane, enemy_final, 42.0, inactive_color)
	
	if _enemy_marker_container != null and is_instance_valid(_enemy_marker_container):
		_enemy_marker_container.add_child(marker_data["root"])
	
	_enemy_markers_by_id[enemy_id] = marker_data

	if not zone_manager.is_combat_running():
		zone_manager.start_song_cycle()

func _offer_song_phase_reward(reward_pool: Array) -> void:
	if reward_pool.is_empty():
		return
	if _between_level_growth_stored_this_level:
		return
	var creature_id: String = reward_pool[_song_rng.randi_range(0, reward_pool.size() - 1)]
	var creature: Dictionary = COMBAT_CONTENT.get_creature(creature_id)
	if creature.is_empty():
		return
	_live_reward_queue.append(creature.duplicate(true))
	_between_level_growth_stored_this_level = true
	_show_feedback("HUNT OFFERED  •  %s" % str(creature.get("display_name", "CREATURE")).to_upper(), Color(0.80, 0.88, 0.72, 1.0), 0.24)
	_show_next_live_reward_offer()


func _resume_song_after_reward() -> void:
	_end_void(&"reward_resolved", {
		"pending_queue": _live_reward_queue.size()
	})
	_resume_song_combat_runtime_from_reward()
	_show_next_live_reward_offer()


func _trigger_boss_final_movement() -> void:
	_song_reward_pending = false
	_reset_pending_reward_state(true)
	_exit_tempo_state(_tempo_state_family, true)
	_hide_live_reward_shell()
	_song_boss_triggered = true
	_set_song_paused(true)
	_song_mode = false
	if _escalation_director != null:
		_escalation_director.stop()
	_latest_ecology_snapshot.clear()
	if zone_manager != null and is_instance_valid(zone_manager):
		_active_attack_authority_budget = int(zone_manager.THREAT_COUNT)
		zone_manager.set_attack_authority_budget(_active_attack_authority_budget)
	_boss_hp_threshold_fired = false
	_boss_decree_timeline_active = false
	_boss_presence_timer = 0.0
	COMBAT_TRANSITION_STATE.prepare_boss_handoff(
		zone_manager,
		Callable(self, "_clear_mastery_context_cache"),
		Callable(self, "_stop_song_conductor")
	)
	# Phase 1 opens at a deliberate 1.05 s interval — slower than the final song
	# chorus — so the first sovereign feels like a shift in register, not just more of
	# the same. Phase 2 and the 50%-HP escalation accelerate from here.
	# Wide stagger (0.54) keeps lanes separated — each sovereign arrives as its own event.
	zone_manager.set_cycle_interval(1.05)
	zone_manager.set_fire_stagger(0.54)

	# Start the boss climax track. This stops the region run song and becomes the
	# damage-race timer — kill the boss before the boss track ends or lose.
	_start_boss_music()
	_start_boss_decree_timeline()

	# The live boss handoff is a direct encounter payload, not a queued run step.
	var boss_encounter: Dictionary
	if _should_use_dev_generated_boss_encounter():
		_region_id = str(GameState.active_region.get("id", "feeding_hollow"))
		boss_encounter = _build_dev_generated_boss_encounter()
	else:
		boss_encounter = ENCOUNTER_IDENTITY_RUNTIME.build_live_boss_encounter()

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
	_song_conductor.beat_pulse.connect(_on_conductor_beat_pulse)
	_song_conductor.final_movement_reached.connect(_on_conductor_final_movement)
	_song_conductor.accent_fired.connect(_on_conductor_accent_fired)
	_song_conductor.start(_active_song_map, start_time, end_time, false, _build_conductor_options(_active_song_profile))
	if _music_control_layer != null:
		if "BPM" in _active_song_map:
			_music_control_layer.set_bpm(float(_active_song_map.BPM))
		_music_control_layer.notify_section(str(_song_conductor.current_section_id), {
			"intensity": float(_song_conductor.current_intensity)
		})
	_refresh_song_combat_state()
	player_combat.set_song_conductor(_song_conductor)
	if _song_conductor != null:
		_hud_presenter.update_song_timer(max(_song_conductor.get_final_movement_time() - start_time, 0.0))


func _build_conductor_options(song_profile: Dictionary) -> Dictionary:
	var contract: Dictionary = Dictionary(song_profile.get("conductor_contract", {}))
	return {
		"song_id": str(_active_song_data.get("id", "")),
		"cadence_window_rules": Array(contract.get("cadence_window_rules", [])),
		"accent_threshold": SONG_COMBAT_PROFILE_CONTENT.resolve_accent_threshold(song_profile, _active_song_map)
	}


func is_song_paused() -> bool:
	return _song_paused


func _set_song_paused(paused: bool) -> void:
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
	var cadence_law: Dictionary = SONG_COMBAT_PROFILE_CONTENT.apply_cadence_law_to_values(
		_active_song_profile,
		section_id,
		_song_section_spawn_mult,
		1.0,
		1.0
	)
	_song_section_spawn_mult = float(cadence_law.get("spawn_mult", _song_section_spawn_mult))
	if _music_control_layer != null:
		_music_control_layer.notify_section(section_id, data)
	_refresh_song_combat_state()
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
	if _music_control_layer != null:
		_music_control_layer.notify_accent()
	_refresh_song_combat_state()
	_rebuild_music_driven_difficulty()
		
	var lane_law: Dictionary = Dictionary(_active_song_profile.get("lane_law", {}))
	var pressure_law: Dictionary = Dictionary(_active_song_profile.get("pressure_law", {}))
	var accent_burst_strength: float = float(lane_law.get("accent_burst_strength", 1.0))
	var accent_feedback_scale: float = float(pressure_law.get("accent_feedback_scale", 1.2))

	# LAW OF THE ACCENT: Visual feedback.
	EventBus.emit_signal("screen_flash", Color(1.0, 1.0, 1.0, 0.05), 0.05)
	EventBus.emit_signal("screen_shake", 1.5 * accent_burst_strength, 0.06)

	if zone_manager != null and is_instance_valid(zone_manager):
		for _i in range(maxi(int(round(accent_burst_strength)), 1)):
			zone_manager.trigger_accent_burst()
	
	# Small HUD pulse feedback for the accent
	if _presentation_runtime != null:
		_presentation_runtime.on_beat_pulse("accent", accent_feedback_scale)


func _hide_song_hud() -> void:
	_hud_presenter.hide_song_hud()


# ── Boss music race ──────────────────────────────────────────────────────────

func _start_boss_music() -> void:
	# Load and play the live boss track. Wires the finished signal so song-end triggers
	# defeat if the boss is still alive. Sets _boss_race_active immediately so
	# the countdown is visible through the boss intro animation.
	_stop_boss_music()
	var boss_song_id: String = SONG_COMBAT_PROFILE_CONTENT.get_boss_song_id_for_region(_region_id)
	var boss_song: Dictionary = SONG_LIBRARY_CONTENT.get_song(boss_song_id)
	var boss_track_path: String = str(boss_song.get("file_path", AUDIO_CONTENT.BOSS_TRACK_PATH))
	var stream: AudioStream = ResourceLoader.load(boss_track_path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
	if stream == null:
		push_error("CombatScene: failed to load boss music " + boss_track_path)
		return
	_boss_music_player = AudioStreamPlayer.new()
	_boss_music_player.name = "BossMusicPlayer"
	_boss_music_player.stream = stream
	_boss_music_player.bus = "MusicAnalysis"
	_boss_music_player.volume_db = 0.0
	add_child(_boss_music_player)
	_boss_music_duration = stream.get_length()
	if _boss_music_duration <= 0.0:
		push_error("CombatScene: boss music reports zero length — using 180 s fallback")
		_boss_music_duration = 180.0
	_boss_music_player.finished.connect(_on_boss_music_finished)
	_boss_race_active = true
	_boss_music_player.play()


func _start_boss_decree_timeline() -> void:
	_boss_decree_timeline_active = false
	var boss_song_id: String = SONG_COMBAT_PROFILE_CONTENT.get_boss_song_id_for_region(_region_id)
	var boss_song: Dictionary = SONG_LIBRARY_CONTENT.get_song(boss_song_id)
	if boss_song.is_empty():
		boss_song = SONG_LIBRARY_CONTENT.get_live_boss_song()
	_boss_song_profile = SONG_COMBAT_PROFILE_CONTENT.get_profile(str(boss_song.get("id", "boss_1")))
	var timing_map_path: String = str(boss_song.get("timing_map_path", ""))
	if timing_map_path.is_empty() or not ResourceLoader.exists(timing_map_path):
		return
	var boss_song_map: Script = load(timing_map_path)
	if boss_song_map == null:
		return
	_stop_song_conductor()
	_song_conductor = SONG_CONDUCTOR_SCRIPT.new()
	_song_conductor.name = "BossSongConductor"
	add_child(_song_conductor)
	_song_conductor.section_changed.connect(_on_boss_conductor_section_changed)
	# Timeline-only mode keeps decree timing authored by song sections without
	# layering duplicate audible tracks over the boss race music.
	_song_conductor.start(boss_song_map, 0.0, -1.0, true, {
		"song_id": str(boss_song.get("id", "boss_1")),
		"cadence_window_rules": Array(Dictionary(_boss_song_profile.get("conductor_contract", {})).get("cadence_window_rules", [])),
		"accent_threshold": SONG_COMBAT_PROFILE_CONTENT.resolve_accent_threshold(_boss_song_profile, boss_song_map)
	})
	_boss_decree_timeline_active = true


func _stop_boss_music() -> void:
	_boss_race_active = false
	_boss_decree_timeline_active = false
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
	zone_manager.stop()
	if player_combat != null:
		player_combat.set_combat_enabled(false)
	_show_feedback("THE SONG DEVOURED YOU", Color(1.0, 0.28, 0.22, 1.0), 0.80)
	EventBus.emit_signal("screen_flash", Color(0.55, 0.06, 0.06, 0.28), 0.40)
	await get_tree().create_timer(0.8).timeout
	if not _run_finished:
		_finish_run(false)


func _on_boss_conductor_section_changed(section_id: String, _data: Dictionary) -> void:
	if not _is_boss_encounter:
		return
	var rule: Dictionary = SONG_COMBAT_PROFILE_CONTENT.get_boss_section_rule(_boss_song_profile, section_id)
	if rule.is_empty():
		return
	var decree_id: StringName = StringName(str(rule.get("decree_id", "")))
	var duration: float = float(rule.get("duration", 0.0))
	var meta: Dictionary = Dictionary(rule.get("meta", {}))
	if decree_id != StringName("") and duration > 0.0:
		_trigger_decree(decree_id, duration, meta)
	if section_id == "chorus":
		_show_feedback(PRESENTATION_TEXT.boss_threshold_break_line(_region_id), Color(0.96, 0.46, 0.14, 1.0), 0.42)
	if bool(rule.get("set_boss_threshold_fired", false)):
		if _boss_hp_threshold_fired:
			return
		_boss_hp_threshold_fired = true
		if _hud_presenter != null:
			_hud_presenter.set_boss_state_text(PRESENTATION_TEXT.boss_state_final(_region_id))
		var threshold_notice: Dictionary = Dictionary(rule.get("notify_threshold", {}))
		if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("notify_boss_threshold"):
			_performance_reward_director.call(
				"notify_boss_threshold",
				str(threshold_notice.get("id", "sovereign_unleash")),
				float(threshold_notice.get("value", 8.0)),
				str(threshold_notice.get("label", "BOSS BREAK"))
			)
		if _presentation_runtime != null:
			_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_boss_threshold_profile())
		if bool(rule.get("trigger_threshold_spectacle", false)):
			_trigger_boss_threshold_spectacle()


func get_current_song_section_id() -> String:
	# Used by LaneManager to stamp shot_modifier onto each fired projectile.
	if _song_conductor == null or not is_instance_valid(_song_conductor):
		return ""
	return str(_song_conductor.current_section_id)


func get_song_conductor() -> SongConductor:
	return _song_conductor


func _stop_song_conductor() -> void:
	if _song_conductor != null and is_instance_valid(_song_conductor):
		_song_conductor.stop()
		_song_conductor.queue_free()
	_song_conductor = null


func _start_run_engagement(is_new_run: bool) -> void:
	# Reset transient transition state before potentially resetting run data.
	COMBAT_TRANSITION_STATE.prepare_run_restart(
		Callable(self, "_stop_song_conductor"),
		Callable(self, "_stop_boss_music"),
		Callable(self, "_clear_mastery_context_cache")
	)

	if is_new_run and GameState.is_intro_bond_choice_pending():
		get_tree().change_scene_to_file("res://scenes/ui/IntroBondChoiceScene.tscn")
		return

	_run_director.initialize_run(str(GameState.active_region.get("id", "feeding_hollow")), _dev_harness_request)

	_run_finished = false
	_is_boss_encounter = false
	_boss_total_hp = 0.0
	_boss_current_hp = 0.0
	_hide_boss_bar()
	_hide_reward_overlay()
	_apply_dev_harness_pre_run_state()

	_last_beat_index = -1
	_between_level_growth_queue.clear()
	_between_level_growth_stored_this_level = false
	_song_reward_pending = false
	_reset_pending_reward_state(true)
	_pending_path_choice_nodes.clear()
	_pending_path_choice_level_index = -1
	_active_path_context.clear()
	_song_level_end_time = 0.0
	_song_level_transitioning = false
	_hide_live_reward_shell()
	_hide_run_spine_surface()
	_hide_growth_choice_surface()
	_growth_choice_context.clear()
	GameState.clear_growth_choice_intersection_payload()
	_refresh_run_build_readout()
	
	if is_new_run:
		_start_song_run()
	else:
		_continue_song_run()


func _continue_song_run() -> void:
	_active_song_data = _run_director.get_active_song_data()
	_active_song_profile = _run_director.get_active_song_profile()
	_active_song_map = _run_director.get_active_song_map()

	_start_regular_level(_run_director.regular_level_index, false)

func _apply_dev_harness_region_override() -> void:
	if _dev_harness_request.is_empty():
		return
	var requested_region_id: String = str(_dev_harness_request.get("region_id", ""))
	if requested_region_id.is_empty():
		return
	for region in ROUTE_CONTENT.REGIONS:
		if str(region.get("id", "")) == requested_region_id:
			GameState.set_active_region(region)
			return


func _apply_dev_harness_pre_run_state() -> void:
	if _dev_harness_request.is_empty():
		return

	var support_species_id: String = str(_dev_harness_request.get("support_species_id", ""))
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
		var creature: Dictionary = COMBAT_CONTENT.get_creature(str(species_id))
		if not creature.is_empty():
			GameState.absorb_creature_type(creature)


func _apply_dev_harness_post_boot_state() -> void:
	if not is_inside_tree() or _dev_harness_request.is_empty():
		return

	var run_growth_state: Dictionary = _dev_harness_request.get("run_growth", {})
	if not run_growth_state.is_empty():
		RunGrowth.apply_debug_state(run_growth_state)

	if _dev_harness_request.has("player_hp_ratio"):
		_debug_set_player_hp_ratio(float(_dev_harness_request.get("player_hp_ratio", 1.0)))

	var reward_species_id: String = str(_dev_harness_request.get("preview_live_reward_species_id", ""))
	if not reward_species_id.is_empty():
		var reward_creature: Dictionary = COMBAT_CONTENT.get_creature(reward_species_id)
		if not reward_creature.is_empty():
			_show_live_reward_offer(reward_creature)

	if str(_dev_harness_request.get("start_mode", "song")) == "boss":
		await _debug_begin_boss_preview(bool(_dev_harness_request.get("trigger_boss_threshold", false)))

	if bool(_dev_harness_request.get("debug_control_sequence", false)):
		await _run_dev_harness_control_sequence()

	_schedule_dev_harness_autoquit()

	DevHarness.clear_request()
	_dev_harness_request.clear()


func _schedule_dev_harness_autoquit() -> void:
	var autoquit_seconds: float = float(_dev_harness_request.get("debug_autoquit_seconds", 0.0))
	if autoquit_seconds <= 0.0:
		return
	DEBUG_TRACE.append_agent_event(
		"debug-harness",
		"H_AUTOQUIT_SCHEDULED",
		"CombatScene.gd:_schedule_dev_harness_autoquit",
		"Scheduled harness-owned autoquit",
		{"delay_seconds": autoquit_seconds}
	)
	var timer: SceneTreeTimer = get_tree().create_timer(autoquit_seconds)
	timer.timeout.connect(_begin_dev_harness_autoquit)


func _begin_dev_harness_autoquit() -> void:
	DevHarness.clear_request()
	var shutdown_scene := Node.new()
	shutdown_scene.name = "DebugHarnessShutdownScene"
	get_tree().root.add_child(shutdown_scene)
	if get_tree().current_scene == self:
		get_tree().current_scene = shutdown_scene
	queue_free()
	var quit_timer: SceneTreeTimer = get_tree().create_timer(0.50)
	quit_timer.timeout.connect(get_tree().quit)


func _run_dev_harness_control_sequence() -> void:
	if zone_manager == null or player_combat == null:
		push_warning("CONTROL_FOCUS_SEQUENCE FAIL missing combat runtime")
		return

	print("CONTROL_FOCUS_SEQUENCE BEGIN")
	zone_manager.stop()
	zone_manager.set_song_mode_enabled(false)
	zone_manager.set_attack_authority_budget(zone_manager.THREAT_COUNT)

	for lane in range(zone_manager.THREAT_COUNT):
		zone_manager.set_enemy(lane, _build_debug_control_enemy(lane))

	var steps: Array[Dictionary] = [
		{"lane": 0, "action": "attack", "threshold": 0.99, "label": "N_ATTACK", "expect_projectile_cleared": true},
		{"lane": 2, "action": "parry", "threshold": 0.99, "label": "E_PARRY", "expect_projectile_cleared": true},
		{"lane": 1, "action": "dodge", "threshold": 1.13, "label": "S_DODGE", "expect_projectile_cleared": false},
		{"lane": 3, "action": "attack", "threshold": 0.99, "label": "W_ATTACK", "expect_projectile_cleared": true}
	]

	for step in steps:
		var lane: int = int(step.get("lane", 0))
		var label: String = str(step.get("label", "STEP"))
		if not _debug_fire_control_lane(lane):
			print("CONTROL_FOCUS_SEQUENCE %s FAIL fire" % label)
			continue

		var reached: bool = await _debug_wait_for_projectile_progress(lane, float(step.get("threshold", 0.99)), 2.8)
		if not reached:
			print("CONTROL_FOCUS_SEQUENCE %s FAIL timing" % label)
			continue

		var action_ok: bool = player_combat.debug_force_focus_and_action(lane, str(step.get("action", "")))
		await get_tree().create_timer(0.26).timeout
		var focused_lane: int = _get_player_focus_lane()
		var expect_cleared: bool = bool(step.get("expect_projectile_cleared", true))
		var projectile_cleared: bool = zone_manager.get_projectile(lane) == null
		if expect_cleared and not projectile_cleared:
			projectile_cleared = await _debug_wait_for_projectile_clear(lane, 0.35)
		var step_passed: bool = action_ok and focused_lane == lane and (projectile_cleared or not expect_cleared)
		var reason: String = ""
		if not action_ok:
			reason = "action_rejected"
		elif focused_lane != lane:
			reason = "focus_mismatch"
		elif expect_cleared and not projectile_cleared:
			reason = "projectile_not_cleared"
		else:
			reason = "ok"
		print("CONTROL_FOCUS_SEQUENCE %s %s focus=%d projectile_cleared=%s reason=%s" % [
			label,
			"PASS" if step_passed else "FAIL",
			focused_lane,
			str(projectile_cleared),
			reason
		])

	print("CONTROL_FOCUS_SEQUENCE END")


func _build_debug_control_enemy(lane: int) -> Dictionary:
	return {
		"id": 9400 + lane,
		"type": "dreg",
		"species_id": "dreg",
		"display_name": "Control Dreg %d" % lane,
		"hp": 999.0,
		"max_hp": 999.0,
		"damage": 6.0,
		"defense": 0.0,
		"dna_reward": 0.0,
		"lane": lane,
		"projectile_speed": 265.0
	}


func _debug_fire_control_lane(lane: int) -> bool:
	for clear_lane in range(zone_manager.THREAT_COUNT if zone_manager != null else 8):
		var projectile = zone_manager.get_projectile(clear_lane)
		if projectile != null and is_instance_valid(projectile):
			projectile.call("resolve", "debug_reset")
	var fired_v: Variant = zone_manager.debug_fire_lane(lane)
	return fired_v == true


func _debug_wait_for_projectile_progress(lane: int, threshold: float, max_wait: float) -> bool:
	var elapsed: float = 0.0
	while elapsed < max_wait:
		var projectile = zone_manager.get_projectile(lane)
		if projectile != null and is_instance_valid(projectile):
			if not bool(projectile.get("is_resolved")) and float(projectile.get("progress")) >= threshold:
				return true
		await get_tree().create_timer(0.02).timeout
		elapsed += 0.02
	return false


func _debug_wait_for_projectile_clear(lane: int, max_wait: float) -> bool:
	var elapsed: float = 0.0
	while elapsed < max_wait:
		var projectile = zone_manager.get_projectile(lane)
		if projectile == null or not is_instance_valid(projectile):
			return true
		await get_tree().create_timer(0.02).timeout
		elapsed += 0.02
	return false


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
		_hud_presenter.set_boss_state_text(PRESENTATION_TEXT.boss_state_final(_region_id))
		_show_feedback(PRESENTATION_TEXT.boss_threshold_final_line(_region_id), Color(0.92, 0.42, 0.12, 1.0), 0.70)
		if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("notify_boss_threshold"):
			_performance_reward_director.call("notify_boss_threshold", "sovereign_unleash", 8.0, "BOSS BREAK")
		_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_boss_threshold_profile())
		_trigger_boss_threshold_spectacle()
		zone_manager.set_cycle_interval(0.60)
		zone_manager.set_fire_stagger(0.44)


func _should_use_dev_generated_boss_encounter() -> bool:
	if _dev_harness_request.is_empty():
		return false
	return bool(_dev_harness_request.get("debug_generated_boss_encounter", false))


func _build_dev_generated_boss_encounter() -> Dictionary:
	var region_id: String = str(GameState.active_region.get("id", "feeding_hollow"))
	var script_res: Resource = load(ENCOUNTER_GENERATOR_SCRIPT_PATH)
	if script_res == null or not (script_res is GDScript):
		push_error("CombatScene: EncounterGenerator script missing; using authored boss.")
		return ENCOUNTER_IDENTITY_RUNTIME.build_live_boss_encounter()
	var gen_script: GDScript = script_res as GDScript
	var gen: Node = gen_script.new() as Node
	gen.call("set_generation_params", region_id, "hard", 0.92)
	var raw: Dictionary = gen.call("generate_encounter", "boss", {})
	gen.free()
	var phases: Array = raw.get("phases", [])
	if raw.is_empty() or phases.is_empty():
		push_warning("CombatScene: generated boss encounter empty; using authored boss.")
		return ENCOUNTER_IDENTITY_RUNTIME.build_live_boss_encounter()
	return GENERATED_ENCOUNTER_ADAPTER.normalize_for_combat_scene(raw, region_id, true)


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
		await _show_boss_intro(str(_active_encounter.get("boss_name", "BOSS")))
		# If R was pressed during the intro a newer load has already started — bail out.
		if load_gen != _encounter_load_gen:
			return
	else:
		_hide_boss_bar()
		_show_title_card(
			str(_active_encounter.get("biome", {}).get("name", "Unknown Place")),
			str(_active_encounter.get("title", "Encounter"))
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
		zone_manager,
		player_combat,
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
		zone_manager,
		_texture_cache
	)

func _update_enemy_marker_threat_states() -> void:
	_presentation_controller.update_enemy_marker_threat_states(
		_enemy_markers_by_id,
		_all_enemies_by_id,
		zone_manager
	)


func _draw_timing_circles() -> void:
	_presentation_controller.draw_timing_circles(
		_timing_circle_container,
		_timing_rings_cache,
		_active_encounter,
		zone_manager,
		player_combat
	)


func _prepare_for_encounter(reset_hp: bool) -> void:
	# Resets encounter-local state. HP only resets at run start, not between encounters.
	if reset_hp:
		GameState.player_hp = GameState.player_max_hp

	_hud_presenter.refresh_hp(GameState.player_hp, GameState.player_max_hp)

	player_combat.set_combat_enabled(true)

	combat_meter.reset()

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
		_show_feedback(str(phase_intro_texts[_current_phase_index]), Color(0.92, 0.88, 0.74, 1.0), 0.45)

	var phase_enemies: Array = phases[_current_phase_index]
	var lane_count: int = zone_manager.THREAT_COUNT if zone_manager != null else 8
	var lane_array: Array = []
	for _i in range(lane_count):
		lane_array.append({})

	for enemy in phase_enemies:
		var lane: int = int(enemy.get("lane", -1))
		if lane >= 0 and lane < lane_count:
			lane_array[lane] = enemy.duplicate(true)

	zone_manager.start_combat(lane_array)


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
		_show_feedback(PRESENTATION_TEXT.boss_threshold_final_line(_region_id), Color(0.86, 0.58, 0.14, 1.0), 0.70)
		EventBus.emit_signal("screen_flash", Color(0.60, 0.36, 0.06, 0.20), 0.30)
		EventBus.emit_signal("screen_shake", 5.0, 0.30)
		# Three-lane phase — tighten the fire cadence to 0.78 s.
		# Tighter stagger (0.45) brings all three sovereigns into quicker succession.
		zone_manager.set_cycle_interval(0.78)
		zone_manager.set_fire_stagger(0.45)

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

	if zone_manager != null:
		zone_manager.stop()

	if player_combat != null:
		player_combat.set_combat_enabled(false)

	var biome: Dictionary = _active_encounter.get("biome", {})
	result_label.text = str(biome.get("victory_text", "VICTORY"))
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
		_show_growth_choice_intersection(reward_creature, "route", "route", false)
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
			card.get_node("Category").text = str(up.get("tag", "UPGRADE"))
			card.get_node("Title").text = str(up.get("title", "Unknown"))
			card.get_node("Body").text = str(up.get("summary", ""))
		else:
			card.visible = false
			
	_upgrade_overlay.visible = true
	controls_label.text = PRESENTATION_TEXT.RUN_SPINE_EVOLUTION_CONTROLS


func _choose_upgrade(index: int) -> void:
	if index < 0 or index >= _pending_upgrades.size():
		return

	var up: Dictionary = _pending_upgrades[index]
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director):
		_performance_reward_director.set("_active_offer", up)
		_performance_reward_director.call("claim_active_offer", "manual")
		_performance_reward_director.call("consume_banked_reward")

	_awaiting_upgrade_choice = false
	_upgrade_overlay.visible = false

	# After choosing, check if there are MORE banked rewards before advancing.
	var banked: int = 0
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director):
		banked = int(_performance_reward_director.get("banked_reward_count"))

	if banked > 0:
		_show_upgrade_choices()
		return

	# If no more banked rewards, determine if we continue the song run or finish/boss.
	_advance_to_next_stage()

func _advance_to_next_stage() -> void:
	if _is_boss_encounter:
		_finish_run(true)
	else:
		GameState.advance_run_loop()
		
		# Keep between-level routing inside the run spine surface when available.
		# RouteScene remains a pre-run screen; mid-run path choice stays in-combat.
		var can_present_run_spine: bool = (
			_song_mode
			and not _run_finished
			and _run_spine_surface != null
			and is_instance_valid(_run_spine_surface)
		)
		if can_present_run_spine:
			_pending_upgrades.clear()
			_run_spine_surface.present_level_completion(_pending_upgrades, RunGrowth, GameState.boss_ready)
			if not _try_present_predation_after_run_spine():
				_try_present_path_choice_after_run_spine()
			_show_feedback("STAGE COMPLETE", Color(0.85, 0.95, 0.75, 1.0), 0.52)
			controls_label.text = ""
			return
		# Fallback guard: if the spine surface is unavailable, use the new loop interlude.
		get_tree().change_scene_to_file("res://scenes/ui/TranslationScene.tscn")


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
	var tendency_snapshot: Dictionary = {}
	tendency_snapshot = Dictionary(RunGrowth.get_tendency_snapshot())
	if _is_boss_encounter:
		GameState.register_world_boss_outcome(_resolve_world_boss_outcome_id(victory), {
			"region_id": _region_id,
			"boss_name": str(_active_encounter.get("boss_name", "")),
			"run_number": int(GameState.run_number)
		})
	GameState.resolve_world_fate_for_run({
		"run_number": int(GameState.run_number),
		"victory": victory,
		"is_boss_encounter": _is_boss_encounter,
		"tendency_snapshot": tendency_snapshot,
		"tempo_snapshot": GameState.get_run_tempo_snapshot()
	})
	EventBus.emit_signal("run_completed", victory)

	_stop_boss_music()
	_stop_song_conductor()
	_hide_song_hud()
	_hide_boss_bar()

	if zone_manager != null:
		zone_manager.stop()

	if player_combat != null:
		player_combat.set_combat_enabled(false)

	if victory:
		result_label.text = "RUN COMPLETE"
		result_label.visible = true
		_show_feedback(PRESENTATION_TEXT.post_run_summary(_build_post_run_summary_payload(), _region_id, true), Color(0.85, 1.0, 0.75, 1.0), 0.70)
		controls_label.text = PRESENTATION_TEXT.RUN_END_CONTROLS_VICTORY
	else:
		result_label.text = "RUN FAILED"
		result_label.visible = true
		_show_feedback(PRESENTATION_TEXT.post_run_summary(_build_post_run_summary_payload(), _region_id, false), Color(1.0, 0.45, 0.45, 1.0), 0.65)
		controls_label.text = PRESENTATION_TEXT.RUN_END_CONTROLS_FAILURE

	_show_end_stats()
	_hide_reward_overlay()
	_hide_live_reward_shell()
	_live_reward_queue.clear()


func _resolve_world_boss_outcome_id(victory: bool) -> String:
	if victory:
		return "boss_defeated"
	if _is_boss_encounter and _boss_music_player != null and is_instance_valid(_boss_music_player):
		return "boss_survived_song"
	return "boss_survived_song"


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
		str(_active_encounter.get("boss_name", "")),
		PRESENTATION_TEXT.boss_state_opening(_region_id)
	)


func _show_boss_intro(boss_name: String) -> void:
	if not is_inside_tree(): return
	
	# First strike: flash + shake + all rings flare to threat color.
	var flash_1: Dictionary = COMBAT_FEEL_CONTENT.get_screen_flash_params("boss_intro_1")
	EventBus.emit_signal("screen_flash", flash_1.color, flash_1.duration)
	EventBus.emit_signal("screen_shake", 2.2, 0.16)
	
	for _intro_lane in range(zone_manager.THREAT_COUNT if zone_manager else 8):
		_presentation_runtime.highlight_timing_ring(_intro_lane, Color(0.92, 0.42, 0.12, 1.0), 6.2)

	_title_card.text = boss_name
	_title_card.modulate = Color(0.88, 0.52, 0.10, 0.0)
	_title_card.visible = true

	_subtitle_card.text = PRESENTATION_TEXT.boss_intro_line(
		_region_id,
		str(_active_encounter.get("boss_subtitle", "APEX VERDICT"))
	)
	_subtitle_card.modulate = Color(0.72, 0.52, 0.28, 0.0)
	_subtitle_card.visible = true

	var tween := create_tween()
	# Title punches in quickly.
	tween.tween_property(_title_card, "modulate:a", 1.0, 0.10)
	tween.tween_interval(0.16)
	# Second impact flash as subtitle reveals.
	tween.tween_callback(func() -> void:
		var flash_2: Dictionary = COMBAT_FEEL_CONTENT.get_screen_flash_params("boss_intro_2")
		EventBus.emit_signal("screen_flash", flash_2.color, flash_2.duration)
	)
	tween.tween_property(_subtitle_card, "modulate:a", 0.80, 0.18)
	tween.tween_interval(0.76)
	tween.tween_property(_title_card, "modulate:a", 0.0, 0.42)
	tween.parallel().tween_property(_subtitle_card, "modulate:a", 0.0, 0.42)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(self): return
		_title_card.visible = false
		_subtitle_card.visible = false
		_title_card.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_subtitle_card.modulate = Color(0.85, 0.85, 0.85, 1.0)
	)

	await tween.finished


func _trigger_boss_threshold_spectacle() -> void:
	if not is_inside_tree(): return
	
	# Fires once when boss HP crosses 50% — a second-act arrival moment.
	# All rings flare to threat color, two pulse-flashes, and a strong shake.
	_trigger_decree(&"boss_threshold", 1.22, {
		"boss_phase": "threshold_50"
	})
	_show_feedback(PRESENTATION_TEXT.boss_threshold_break_line(_region_id), Color(0.96, 0.46, 0.14, 1.0), 0.52)
	for _thresh_lane in range(zone_manager.THREAT_COUNT):
		_presentation_runtime.highlight_timing_ring(_thresh_lane, Color(0.94, 0.38, 0.08, 1.0), 7.2)

	var flash_1: Dictionary = COMBAT_FEEL_CONTENT.get_screen_flash_params("boss_threshold")
	EventBus.emit_signal("screen_flash", flash_1.color, flash_1.duration)
	EventBus.emit_signal("screen_shake", 2.4, 0.14)

	var pulse_tween := create_tween()
	pulse_tween.tween_interval(0.26)
	pulse_tween.tween_callback(func() -> void:
		if not is_instance_valid(self): return
		var flash_2: Dictionary = COMBAT_FEEL_CONTENT.get_screen_flash_params("boss_threshold_pulse")
		EventBus.emit_signal("screen_flash", flash_2.color, flash_2.duration)
		EventBus.emit_signal("screen_shake", 1.6, 0.10)
	)
	pulse_tween.tween_interval(0.22)
	pulse_tween.tween_callback(func() -> void:
		if not is_instance_valid(self): return
		EventBus.emit_signal("screen_flash", Color(0.62, 0.22, 0.04, 0.12), 0.12)
	)


func _show_title_card(title_text: String, subtitle_text: String) -> void:
	if _feedback_shell == null:
		return
	_feedback_shell.show_title_card(title_text, subtitle_text)


func _show_feedback(text: String, color: Color, lifetime: float = COMBAT_FEEL_CONTENT.COMBAT_FEEDBACK_MIN_LIFETIME) -> void:
	if _feedback_shell == null:
		return
	_feedback_shell.show_feedback(text, color, lifetime, _critical_threat_pressure)


func _get_beat_quality_for_action() -> String:
	# Returns the conductor's current beat quality ("perfect" / "good" / "off").
	# Returns "off" when no conductor is active (boss phase, no song, etc.).
	if _song_conductor == null or not is_instance_valid(_song_conductor):
		return "off"
	return _song_conductor.get_beat_quality()


func _show_beat_feedback(text: String, color: Color) -> void:
	if _hud_presenter != null:
		_hud_presenter.show_beat_feedback_timed(text, color, _critical_threat_pressure)


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
	if _hud_presenter == null:
		return
	_hud_presenter.refresh_progression_readouts(RunGrowth, _song_mode, _song_phase_index, _song_phases, _pending_creature_snapshot())


func _pending_creature_snapshot() -> Dictionary:
	if _victory_reward_director == null:
		return {}
	return _victory_reward_director.get_pending_creature()


func _refresh_dna_hud() -> void:
	if _hud_presenter == null:
		return
	_hud_presenter.refresh_dna_hud(_song_mode, _song_phase_index, _song_phases, _pending_creature_snapshot())


func _show_live_reward_offer(creature_data: Dictionary) -> void:
	if _victory_reward_director != null:
		_victory_reward_director.offer_creature(creature_data, true, LIVE_REWARD_WINDOW)


func _refresh_live_reward_shell() -> void:
	if _live_reward_shell == null or _victory_reward_director == null:
		return
		
	var pending_creature: Dictionary = _victory_reward_director.get_pending_creature()
	if pending_creature.is_empty():
		return

	var species_id: String = str(pending_creature.get("species_id", ""))
	var threshold: float = GameState.get_effective_dna_threshold(species_id)
	var current_dna: float = GameState.get_dna(species_id)
	var archive_tether_ready: bool = GameState.is_species_ever_bonded(species_id)
	var display_name: String = str(pending_creature.get("display_name", "Creature"))
	var encounter_context: String = _describe_creature_offer_context(pending_creature)
	_live_reward_title_label.text = PRESENTATION_TEXT.live_reward_title(display_name)
	
	var live_body: String = _hud_presenter.compact_hud_copy(str(pending_creature.get("description", "")), 30)
	if not encounter_context.is_empty():
		live_body += "  %s" % _hud_presenter.compact_hud_copy(encounter_context, 12)
	_live_reward_body_label.text = live_body
	
	if _live_reward_dna_label != null:
		_live_reward_dna_label.text = PRESENTATION_TEXT.live_bond_offer_gate_line(species_id)
		_live_reward_dna_label.modulate = Color(0.4, 0.9, 0.8) if archive_tether_ready or current_dna >= threshold else Color(1.0, 0.4, 0.4)

	_live_reward_hint_label.text = PRESENTATION_TEXT.live_reward_hint(_victory_reward_director.is_dna_locked(), _victory_reward_director.get_offer_timer())


func _hide_live_reward_shell() -> void:
	if _live_reward_shell != null:
		_live_reward_shell.visible = false
	_live_reward_offer_timer = 0.0
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_VOID:
		_end_void(&"shell_hidden")
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
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE:
		return

	var next_creature: Dictionary = _live_reward_queue.pop_front()
	_show_live_reward_offer(next_creature)


func _expire_live_reward_offer() -> void:
	if not _song_reward_pending or not _awaiting_reward_choice:
		return
	_notify_tempo_mastery(COMBAT_FEEL_CONTENT.TEMPO_VOID, "choice_timeout", {
		"window_seconds": LIVE_REWARD_WINDOW
	})
	_pass_reward()


func _describe_creature_offer_context(creature_data: Dictionary) -> String:
	var species_id: String = str(creature_data.get("species_id", ""))
	if species_id.is_empty():
		return ""
	return COMBAT_CONTENT.get_creature_encounter_summary(species_id)


func _choose_bond() -> void:
	if _victory_reward_director != null:
		_victory_reward_director.resolve_choice("bond")


func _choose_eat() -> void:
	if _victory_reward_director != null:
		_victory_reward_director.resolve_choice("eat")


func _pass_reward() -> void:
	if _victory_reward_director != null:
		_victory_reward_director.resolve_choice("pass")


func _on_combo_changed(count: int, tier: String) -> void:
	_hud_presenter.refresh_combo(count, tier)
	_sync_hud_shell_interface_wound_glow()


func _on_run_score_changed(score: int) -> void:
	if _hud_presenter != null:
		_hud_presenter.refresh_run_score(score)


func _show_end_stats() -> void:
	if _end_stats_label == null:
		return

	var kills: int = RunStats.kills
	var dmg: int = int(RunStats.damage_dealt)
	var p_att: int = RunStats.perfect_attacks
	var g_att: int = RunStats.good_attacks
	var p_par: int = RunStats.perfect_parries
	var g_par: int = RunStats.good_parries
	var ult: int = RunStats.ultimates_fired
	var sup: int = RunStats.support_triggers
	var surges: int = RunStats.tendency_surges
	var hit: int = RunStats.times_hit
	var bonds: int = RunStats.bonds
	var eats: int = RunStats.eats
	var score: int = RunStats.run_score
	var grade: String = RunStats.get_grade()

	var growth_level: int = 1
	growth_level = RunGrowth.level
	var post_run_summary: String = PRESENTATION_TEXT.post_run_summary(
		_build_post_run_summary_payload(),
		_region_id,
		result_label.text == "RUN COMPLETE"
	)

	_end_stats_label.text = (
		"[ %s ]  %d pts\n\n" % [grade, score]
		+ "Kills %d    Damage %d    Hits taken %d\n" % [kills, dmg, hit]
		+ "Perfect %d  Good %d    Parries %d+%d\n" % [p_att, g_att, p_par, g_par]
		+ "Ultimates %d    Support %d    Surges %d\n" % [ult, sup, surges]
		+ "Bonded %d    Eaten %d    Passed %d    Level %d\n\n" % [bonds, eats, RunStats.passes, growth_level]
		+ post_run_summary
	)
	_end_stats_label.visible = true


func _on_dna_gained(_species_id: String, _amount: float, _total: float) -> void:
	_refresh_dna_hud()
	if _song_reward_pending and _awaiting_reward_choice:
		var species_id: String = str(_pending_reward_creature.get("species_id", ""))
		var threshold: float = GameState.get_effective_dna_threshold(species_id)
		_pending_reward_dna_locked = not GameState.is_species_ever_bonded(species_id) and not GameState.has_dna_for(species_id, threshold)
		_refresh_live_reward_shell()
		_refresh_song_controls_text()


func _on_dna_lock_denied(_species_id: String, current: float, required: float) -> void:
	var msg: String = "NEED %.0f DNA" % (required - current)
	if current <= 0.0:
		msg = "NO DNA COLLECTED"
	_show_feedback(msg, Color(1.0, 0.42, 0.35, 1.0), 0.38)
	EventBus.emit_signal("play_sfx", "choice_fail")
	_presentation_runtime.on_screen_shake(1.5, 0.08)


func _build_post_run_summary_payload() -> Dictionary:
	return {
		"kills": RunStats.kills,
		"bonds": RunStats.bonds,
		"eats": RunStats.eats,
		"passes": RunStats.passes
	}


func _on_dna_routing_changed(route_id: String, label: String) -> void:
	var route_color: Color
	if _hud_presenter != null:
		route_color = _hud_presenter.dna_route_accent_color(route_id)
		_hud_presenter.apply_dna_routing_highlight(route_id, label)
	else:
		route_color = Color(0.82, 0.96, 0.82, 1.0) if route_id == "bond" else Color(0.96, 0.84, 0.62, 1.0)
		if _dna_route_label != null:
			_dna_route_label.text = label
			_dna_route_label.modulate = route_color
		if _dna_route_shell != null:
			var tween := create_tween()
			_dna_route_shell.modulate = Color(1.5, 1.5, 1.5, 1.0)
			tween.tween_property(_dna_route_shell, "modulate", Color.WHITE, 0.25)
	_show_feedback(label, route_color, 0.20)
	if _is_run_spine_active() and _run_spine_surface != null:
		_run_spine_surface.refresh_prep_summary()


func _on_player_took_damage(amount: float, source_sector: int) -> void:
	_kill_tempo_recovery_tween()
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_STRETCH:
		_exit_tempo_state(COMBAT_FEEL_CONTENT.TEMPO_STRETCH, true)
	else:
		_apply_tempo_time_scale(_base_time_scale)
	if _escalation_director != null:
		_escalation_director.notify_player_hp_changed(GameState.get_hp_percent())
		_escalation_director.notify_player_took_damage(amount, source_sector)

	_trigger_regional_feedback("player_damaged", {"sector": source_sector})


func _trigger_regional_feedback(event_id: String, ctx: Dictionary = {}) -> void:
	var lane: int = int(ctx.get("lane", -1))
	match event_id:
		"player_damaged":
			if _region_id == "pale_shelf":
				_show_feedback("EXPOSED", Color(0.72, 0.76, 0.96, 1.0), 0.48)
				_presentation_runtime.highlight_timing_ring(lane, Color(0.65, 0.72, 0.98, 1.0), 5.0)
				_flash_meter_shell(Color(0.18, 0.18, 0.38, 0.96), 0.22)
				EventBus.emit_signal("screen_flash", Color(0.38, 0.40, 0.62, 0.18), 0.28)
			else:
				_show_feedback("STRUCK", Color(0.96, 0.44, 0.40, 1.0), 0.24)
				_presentation_runtime.highlight_timing_ring(lane, Color(1.0, 0.25, 0.25, 1.0), 5.0)
				_flash_meter_shell(Color(0.42, 0.10, 0.11, 0.94), 0.18)
		
		"enemy_defeated":
			match _region_id:
				"feeding_hollow":
					_show_beat_feedback("FLESH", Color(0.88, 0.28, 0.18, 1.0))
					EventBus.emit_signal("screen_flash", Color(0.35, 0.05, 0.05, 0.05), 0.05)
				"drowned_cut":
					if _song_boss_triggered:
						_show_beat_feedback("RESONANCE", Color(0.48, 0.88, 0.76, 1.0))
						EventBus.emit_signal("screen_flash", Color(0.10, 0.38, 0.32, 0.05), 0.05)
						EventBus.emit_signal("dna_resonated", Color(0.48, 0.88, 0.76), 0.3)
		
		"phrase_milestone":
			var count: int = int(ctx.get("count", 0))
			if count >= 8:
				_show_beat_feedback("FLOW STATE", Color(1.0, 0.88, 0.40, 1.0))
				EventBus.emit_signal("screen_flash", Color(0.60, 0.50, 0.12, 0.08), 0.06)
			elif count == 5:
				_show_beat_feedback("IN THE POCKET", Color(0.95, 0.82, 0.38, 1.0))
				EventBus.emit_signal("screen_flash", Color(0.50, 0.42, 0.10, 0.06), 0.05)
			elif count == 3:
				_show_beat_feedback("PHRASE", Color(0.88, 0.78, 0.36, 1.0))


func _on_player_healed(_amount: float) -> void:
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
	var ultimate_profile: Dictionary = {
		"flash_color": Color(1.0, 0.78, 0.32, 0.20),
		"flash_duration": 0.10,
		"shake_intensity": 2.8,
		"shake_duration": 0.14,
		"hitstop_scale": 0.62,
		"hitstop_duration": 0.08,
		"ring_width": 7.0,
		"burst_color": Color(1.0, 0.72, 0.24, 0.66),
		"burst_scale": 1.6
	}
	if bq == "perfect":
		ultimate_profile["shake_intensity"] = 3.6
		ultimate_profile["hitstop_scale"] = 0.54
		ultimate_profile["hitstop_duration"] = 0.10
		ultimate_profile["burst_scale"] = 1.85
	_presentation_runtime.apply_impact_profile(ultimate_profile)


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
	var boss_threshold_impact: bool = false
	if lane >= 0:
		var max_hp: float = float(_enemy_max_hp.get(enemy_id, 0))
		if max_hp > 0.0:
			var enemy_data: Dictionary = zone_manager.get_enemy_by_id(enemy_id)
			var current_hp: float = float(enemy_data.get("hp", 0))
			if current_hp / max_hp <= ENEMY_LOW_HP_THRESHOLD:
				var marker_data = _enemy_markers_by_id.get(enemy_id, null)
				if marker_data != null:
					var body_node = marker_data.get("body")
					if is_instance_valid(body_node):
						var marker_body: ColorRect = body_node
						marker_body.modulate = Color(0.90, 0.28, 0.28, 1.0)
		_refresh_enemy_marker_health(enemy_id)

	# Decrement unified boss HP bar.
	if _is_boss_encounter and _hud_presenter != null:
		_boss_current_hp = max(_boss_current_hp - damage, 0.0)
		_hud_presenter.update_boss_hp(_boss_current_hp)
		
		if _escalation_director != null and _boss_total_hp > 0.0:
			_escalation_director.notify_boss_hp_changed(_boss_current_hp / _boss_total_hp)
		
		# Feedback and effects only (director handles timing shift)
		if not _boss_decree_timeline_active and not _boss_hp_threshold_fired and _boss_total_hp > 0.0 and (_boss_current_hp / _boss_total_hp) <= 0.5:
			_boss_hp_threshold_fired = true
			EventBus.emit_signal("sovereign_threshold_reached", 0.5)
			_hud_presenter.set_boss_state_text(PRESENTATION_TEXT.boss_state_final(_region_id))
			if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("notify_boss_threshold"):
				_performance_reward_director.call("notify_boss_threshold", "sovereign_unleash", 8.0, "BOSS BREAK")
			_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_boss_threshold_profile())
			_trigger_boss_threshold_spectacle()
			boss_threshold_impact = true

	_spawn_damage_number(enemy_id, damage)
	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_enemy_hit_profile(damage, is_boss_target), lane, enemy_id)

	var impact_pos: Vector2 = _impact_world_pos_for_enemy(enemy_id)
	if impact_pos != Vector2.ZERO:
		if is_boss_target:
			if boss_threshold_impact:
				impact_fx_requested.emit(&"boss", impact_pos, Vector2.LEFT, 1.36)
			else:
				impact_fx_requested.emit(&"boss", impact_pos, Vector2.LEFT, 1.02)
		elif _enemy_is_elite_for_impact(enemy_id):
			impact_fx_requested.emit(&"elite", impact_pos, Vector2.LEFT, 0.80)


func _spawn_damage_number(enemy_id: int, damage: float) -> void:
	var marker_data = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null:
		return
	
	var root_node = marker_data.get("root")
	if not is_instance_valid(root_node):
		return
		
	var root: Node2D = root_node
	var player_damage_anchor: float = maxf(GameState.get_attack_damage(), 1.0)
	var damage_ratio: float = damage / player_damage_anchor
	var is_heavy_target: bool = _is_boss_encounter and _enemy_phase_by_id.has(enemy_id)
	var is_elite_target: bool = _enemy_is_elite_for_impact(enemy_id)
	var font_size: int = 19
	var outline_size: int = 2
	var rise: float = 44.0
	var float_time: float = COMBAT_FEEL_CONTENT.DAMAGE_NUMBER_FLOAT_TIME
	var damage_color: Color = Color(0.96, 0.80, 0.50, 1.0)
	if is_heavy_target or damage_ratio >= 1.65:
		font_size = 31
		outline_size = 4
		rise = 66.0
		float_time *= 1.12
		damage_color = Color(1.0, 0.58, 0.22, 1.0)
	elif is_elite_target or damage_ratio >= 1.0:
		font_size = 25
		outline_size = 3
		rise = 54.0
		damage_color = Color(1.0, 0.74, 0.32, 1.0)
	elif damage_ratio <= 0.35:
		font_size = 15
		damage_color = Color(0.76, 0.70, 0.62, 0.82)

	var start_pos: Vector2 = root.position + Vector2(8.0, -24.0 if font_size >= 25 else -18.0)
	var lbl := Label.new()
	lbl.text = "%.0f" % damage
	lbl.position = start_pos
	lbl.z_index = 13 if font_size >= 25 else 10
	UI_STYLE.apply_label(lbl, "warm_value")
	lbl.modulate = damage_color
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_constant_override("outline_size", outline_size)
	_enemy_marker_container.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position:y", start_pos.y - rise, float_time)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, float_time)
	tween.tween_callback(lbl.queue_free)


func _refresh_enemy_marker_health(enemy_id: int) -> void:
	var marker_data = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null:
		return
	var lane: int = int(_all_enemies_by_id.get(enemy_id, {}).get("lane", -1))
	if lane < 0:
		return
	var max_hp: float = maxf(float(_enemy_max_hp.get(enemy_id, 0.0)), 1.0)
	var enemy_data_v: Dictionary = zone_manager.get_enemy(lane)
	var current_hp: float = clampf(float(enemy_data_v.get("hp", 0.0)), 0.0, max_hp)
	var ratio: float = current_hp / max_hp
	var track_node = marker_data.get("hp_track")
	var fill_node = marker_data.get("hp_fill")
	var label_node = marker_data.get("hp_label")
	if is_instance_valid(track_node) and is_instance_valid(fill_node):
		var track: ColorRect = track_node
		var fill: ColorRect = fill_node
		fill.size = Vector2(track.size.x * ratio, track.size.y)
		if ratio <= ENEMY_LOW_HP_THRESHOLD:
			fill.color = Color(1.0, 0.20, 0.16, 1.0)
		elif _enemy_is_elite_for_impact(enemy_id):
			fill.color = Color(0.96, 0.36, 0.14, 0.98)
		else:
			fill.color = Color(0.68, 0.16, 0.18, 0.92)
	if is_instance_valid(label_node):
		var hp_label: Label = label_node
		hp_label.text = "HP %.0f/%.0f" % [current_hp, max_hp]
		var hp_tween := hp_label.create_tween()
		hp_tween.tween_property(hp_label, "scale", Vector2(1.06, 1.06), 0.05)
		hp_tween.tween_property(hp_label, "scale", Vector2.ONE, 0.10)


func _on_proc_feedback_requested(text: String, color: Color) -> void:
	var u: String = text.strip_edges().to_upper()
	if u == "EMPTY PARRY":
		_show_feedback("WRONG LANE", color, 0.28)
		return
	if u == "NOT READY":
		# Ultimate rejection: main line already shows NO CHARGE from combat_input_resolved.
		return
	_show_feedback(text, color, 0.40)


func _on_ultimate_power_granted(amount: float) -> void:
	if combat_meter != null:
		combat_meter.gain_ultimate_power(amount)


func _on_enemy_status_applied_requested(enemy_id: int, status_id: String, params: Dictionary) -> void:
	if zone_manager == null: return
	if enemy_id != -1:
		zone_manager.apply_status_by_id(enemy_id, status_id, params)


func _on_enemy_defeated(enemy_id: int) -> void:
	var defeated_enemy_context: Dictionary = _resolve_enemy_context(enemy_id)
	var kill_heal_effect: Dictionary = _get_growth_effect("heal_on_kill")
	if not kill_heal_effect.is_empty():
		var healed: float = GameState.heal_player(float(kill_heal_effect.get("value", 0.0)))
		if healed > 0.0:
			EventBus.emit_signal("player_healed", healed)
	_remove_enemy_marker(enemy_id)
	_all_enemies_by_id.erase(enemy_id)
	_enemy_max_hp.erase(enemy_id)
	_enemy_phase_by_id.erase(enemy_id)

	if _song_mode and not _song_paused and not _song_boss_triggered:
		_trigger_regional_feedback("enemy_defeated")

	# DNA economy: creature encounters now pay out the species you actually killed.
	if _song_mode and not _song_boss_triggered and _song_phase_index >= 0 and _song_phase_index < _song_phases.size():
		_process_dna_award(defeated_enemy_context)

	if _song_mode and not _song_paused and not _song_boss_triggered:
		if _escalation_director != null:
			var defeated_lane: int = int(defeated_enemy_context.get("lane", -1))
			_escalation_director.notify_enemy_defeated(enemy_id, defeated_lane, false)


func _process_dna_award(defeated_enemy: Dictionary) -> void:
	var dna_species: String = str(defeated_enemy.get("reward_species_id", defeated_enemy.get("species_id", "")))
	var dna_amount: float = float(defeated_enemy.get("dna_reward", DNA_PER_KILL))
	
	# Fallback to local enemy reward pool if no direct species is identified.
	if dna_species.is_empty() and defeated_enemy.has("reward_pool"):
		var _local_pool: Array = defeated_enemy.get("reward_pool", [])
		if not _local_pool.is_empty():
			dna_species = str(_local_pool[0])
	
	if dna_species.is_empty():
		var _dna_phase_val = _song_phases[_song_phase_index]
		if _dna_phase_val is Dictionary:
			var _dna_pool: Array = _dna_phase_val.get("reward_pool", [])
			if not _dna_pool.is_empty():
				dna_species = str(_dna_pool[_song_phase_dna_award_index % _dna_pool.size()])
				_song_phase_dna_award_index += 1
				dna_amount = DNA_PER_KILL
				
	if dna_species.is_empty() or dna_amount <= 0.0:
		return

	var dna_result: Dictionary = {}
	dna_result = RunGrowth.process_dna_gain(dna_species, dna_amount)
	
	EventBus.emit_signal("dna_gained", dna_species, dna_amount, float(dna_result.get("total", GameState.get_dna(dna_species))))
	_show_dna_feedback(dna_species, dna_amount, dna_result)


func _show_dna_feedback(species_id: String, _amount: float, result: Dictionary) -> void:
	var dna_name: String = str(COMBAT_CONTENT.get_creature(species_id).get("display_name", species_id)).to_upper()
	if bool(result.get("auto_bonded", false)):
		return

	if bool(result.get("banked", false)):
		var dna_color := Color(0.24, 0.86, 0.74, 1.0)
		if _region_id == "drowned_cut":
			_show_beat_feedback("DROWNED RESONANCE", dna_color)
			EventBus.emit_signal("screen_flash", Color(0.10, 0.38, 0.32, 0.12), 0.10)
			EventBus.emit_signal("dna_resonated", dna_color, 0.85)
		else:
			_show_beat_feedback("%s DNA" % dna_name, dna_color)
		
		_show_feedback("+%s DNA" % dna_name, Color(0.62, 0.96, 0.78, 1.0), 0.22)
		_maybe_show_dna_pickup_flavor(species_id, result)
	else:
		if _region_id == "drowned_cut":
			_show_beat_feedback("RESONANCE", Color(0.48, 0.88, 0.76, 1.0))
			EventBus.emit_signal("screen_flash", Color(0.10, 0.38, 0.32, 0.05), 0.05)
			EventBus.emit_signal("dna_resonated", Color(0.48, 0.88, 0.76), 0.4)
		_show_feedback("+%s DNA -> EXP" % dna_name, Color(0.96, 0.84, 0.62, 1.0), 0.22)
		_maybe_show_dna_pickup_flavor(species_id, result)



func _resolve_enemy_context(enemy_id: int) -> Dictionary:
	if zone_manager != null and is_instance_valid(zone_manager):
		var live_enemies: Dictionary = zone_manager.get_all_enemies()
		if live_enemies.has(enemy_id):
			return Dictionary(live_enemies[enemy_id]).duplicate(true)
	return Dictionary(_all_enemies_by_id.get(enemy_id, {})).duplicate(true)


func _resolve_newest_untracked_enemy_id(enemies: Dictionary) -> int:
	var newest_id: int = -1
	for key in enemies.keys():
		var enemy_id: int = int(key)
		if _all_enemies_by_id.has(enemy_id):
			continue
		if newest_id < 0 or enemy_id > newest_id:
			newest_id = enemy_id
	return newest_id


func _resolve_dna_pickup_state(species_id: String, dna_result: Dictionary) -> String:
	if GameState.player_max_hp > 0.0 and (GameState.player_hp / GameState.player_max_hp) <= 0.35:
		return "low_hp"
	var support_charge: float = 0.0
	support_charge = float(RunGrowth.get("support_charge"))
	if support_charge >= 80.0:
		return "high_support"
	var species_total: float = float(dna_result.get("total", GameState.get_dna(species_id)))
	if species_total >= 20.0:
		return "high_dna"
	return "default"


func _maybe_show_dna_pickup_flavor(species_id: String, dna_result: Dictionary) -> void:
	if _dna_pickup_flavor_cooldown > 0.0:
		return
	var state_id: String = _resolve_dna_pickup_state(species_id, dna_result)
	var rotation_key: String = "%s:%s" % [_region_id, state_id]
	var flavor_rotation: int = int(_dna_pickup_flavor_rotation.get(rotation_key, 0))
	var flavor_line: String = PRESENTATION_TEXT.dna_pickup_flavor(_region_id, state_id, flavor_rotation)
	if flavor_line.is_empty():
		return
	_dna_pickup_flavor_rotation[rotation_key] = flavor_rotation + 1
	_dna_pickup_flavor_cooldown = PRESENTATION_TEXT.DNA_PICKUP_FLAVOR_COOLDOWN_SECONDS
	_show_feedback(flavor_line, Color(0.88, 0.92, 0.98, 1.0), 0.20)


func _on_slow_motion(requested_scale: float, duration: float) -> void:
	# SOVEREIGN SAFETY: Never allow a scale below the active biological floor 
	# unless it is an explicit PUNCTURE event.
	var safe_scale: float = maxf(requested_scale, 0.35)
	
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_VOID:
		_track_tempo_event(COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE, &"suppressed_by_void")
		return
	
	# Mapping incoming requests to high-impact tiers v1.
	var puncture_max_scale: float = float(COMBAT_FEEL_CONTENT.SLOWMO_TIER_THRESHOLDS.get("puncture_max_scale", 0.1))
	var stretch_max_scale: float = float(COMBAT_FEEL_CONTENT.SLOWMO_TIER_THRESHOLDS.get("stretch_max_scale", 0.7))

	if requested_scale < puncture_max_scale:
		# PUNCTURE: Very heavy slowdown (killing blow freeze). 
		# We allow the original low scale but keep it extremely brief.
		_trigger_puncture(&"combat_puncture", requested_scale, duration, {
			"impact_weight": true
		})
	elif safe_scale <= stretch_max_scale:
		# STRETCH: Witch Time dilation (perfect parry/dodge/hits).
		_enter_tempo_state(COMBAT_FEEL_CONTENT.TEMPO_STRETCH, &"combat_stretch", safe_scale, duration, {})
	else:
		# Standard execution feedback (0.7+ scale) is now suppressed to keep
		# the game feeling high-pressure and fast. Only rare distortion allowed.
		_track_tempo_event(COMBAT_FEEL_CONTENT.TEMPO_NONE, &"suppressed_low_weight")


func _impact_lane_forward(lane: int) -> Vector2:
	if zone_manager == null or player_combat == null:
		return Vector2.RIGHT
	var start_point: Vector2 = _lane_player_pos()
	var end_point: Vector2 = _lane_hit_zone_pos(lane)
	var delta: Vector2 = end_point - start_point
	if delta.length_squared() < 1.0:
		return Vector2.RIGHT
	return delta.normalized()


func _impact_pos_lane(lane: int, t: float = 0.52) -> Vector2:
	if zone_manager == null or player_combat == null:
		return Vector2.ZERO
	return _lane_player_pos().lerp(_lane_hit_zone_pos(lane), t)


func _lane_player_pos() -> Vector2:
	if zone_manager != null:
		return zone_manager.get_player_pos()
	if player_combat != null:
		return player_combat.position
	return Vector2.ZERO


func _lane_hit_zone_pos(lane: int) -> Vector2:
	if zone_manager != null:
		return zone_manager.get_threat_hit_zone_pos(lane)
	return _lane_player_pos() + _lane_direction_fallback(lane) * 110.0


func _lane_spawn_pos(lane: int) -> Vector2:
	if zone_manager != null:
		return zone_manager.get_threat_spawn_pos(lane)
	return _lane_player_pos() + _lane_direction_fallback(lane) * 260.0


func _lane_intercept_distance(lane: int) -> float:
	return maxf(_lane_spawn_pos(lane).distance_to(_lane_hit_zone_pos(lane)), 1.0)


func _lane_direction_fallback(lane: int) -> Vector2:
	var threat_count: float = 8.0
	var angle: float = (float(lane) / threat_count) * TAU - PI/2.0
	return Vector2(cos(angle), sin(angle))


func _impact_world_pos_for_enemy(enemy_id: int) -> Vector2:
	var marker_data: Variant = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null or not marker_data is Dictionary:
		return Vector2.ZERO
	var root_node: Variant = marker_data.get("root")
	var body_node: Variant = marker_data.get("body")
	if not is_instance_valid(root_node):
		_enemy_markers_by_id.erase(enemy_id)
		_status_marker_overrides.erase(enemy_id)
		return Vector2.ZERO
	var root: Node2D = root_node as Node2D
	if root == null:
		return Vector2.ZERO
	var body: ColorRect = body_node as ColorRect
	if is_instance_valid(body):
		return root.position + body.position + body.size * 0.5
	return root.position


func _enemy_is_elite_for_impact(enemy_id: int) -> bool:
	var entry: Dictionary = _all_enemies_by_id.get(enemy_id, {})
	if str(entry.get("grade", "")) == "alpha" or str(entry.get("type", "")) == "sovereign":
		return true
	var tags: Variant = entry.get("behaviour_tags", [])
	if tags is Array:
		return (tags as Array).has("elite")
	return false


func _on_attack_timing_early_resolved(lane: int) -> void:
	var lane_count: int = zone_manager.THREAT_COUNT if zone_manager != null else 8
	if lane < 0 or lane >= lane_count:
		return
	var fwd: Vector2 = _impact_lane_forward(lane)
	var jitter: float = 0.06 if lane == 1 or lane == 3 else -0.06
	impact_fx_requested.emit(&"miss", _impact_pos_lane(lane, 0.36), fwd.rotated(jitter), 0.74)


func _on_player_attacked(sector: int, _damage: float, was_timed: bool) -> void:
	if was_timed:
		_show_feedback("TIMED", Color(1.0, 0.95, 0.55, 1.0), 0.36)
		_presentation_runtime.highlight_timing_ring(sector, Color(1.0, 0.95, 0.55, 1.0), 5.0)
		_presentation_runtime.spawn_attack_silhouette_to_lane(sector, Color(1.0, 0.92, 0.58, 0.55), 10.0, 0.12, 1.0)
		_flash_meter_shell(Color(0.25, 0.20, 0.10, 0.94), 0.12)
		# Beat quality bonus: on-beat timed attacks get richer feedback and a sharper flash.
		var bq: String = _get_beat_quality_for_action()
		if bq == "perfect":
			_show_beat_feedback("IN SYNC", Color(1.0, 0.95, 0.55, 1.0))
		elif bq == "good":
			_show_beat_feedback("ON BEAT", Color(0.88, 0.84, 0.52, 1.0))
	else:
		_show_feedback("HIT", Color(0.95, 0.95, 0.95, 1.0), 0.28)
		_presentation_runtime.highlight_timing_ring(sector, Color(0.95, 0.95, 0.95, 1.0), 4.0)
		_presentation_runtime.spawn_attack_silhouette_to_lane(sector, Color(0.92, 0.92, 0.92, 0.35), 7.0, 0.10, 0.88)
		_flash_meter_shell(Color(0.16, 0.16, 0.17, 0.94), 0.08)


func _on_timed_attack_resolved(sector: int, quality: String, damage: float, enemy_id: int) -> void:
	var flat_bonus_effect: Dictionary = _get_growth_effect("timed_attack_bonus_flat")
	var beat_quality: String = _get_beat_quality_for_action()
	if not flat_bonus_effect.is_empty() and enemy_id != -1:
		zone_manager.damage_enemy_by_id(enemy_id, float(flat_bonus_effect.get("value", 0.0)))
		_presentation_runtime.spawn_attack_silhouette_to_lane(sector, Color(0.98, 0.70, 0.34, 0.30), 8.0, 0.08, 0.94)

	if quality == "perfect":
		impact_fx_requested.emit(&"perfect", _impact_pos_lane(sector, 0.58), _impact_lane_forward(sector), 1.0)
		_notify_tempo_mastery(COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE, "perfect_hit", {
			"beat_quality": beat_quality
		})
		_try_apply_vessel_modifier_on_perfect(sector, damage)
	elif quality == "good":
		impact_fx_requested.emit(&"perfect", _impact_pos_lane(sector, 0.52), _impact_lane_forward(sector), 0.78)

	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_timed_attack_profile(quality, beat_quality), sector, enemy_id)
	_presentation_runtime.pulse_sigil_result_snap(quality, "attack")

	if quality == "perfect":
		_presentation_controller.on_combat_event(_bg_sprite, "perfect")
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE and (quality == "perfect" or quality == "good"):
		_notify_tempo_mastery(COMBAT_FEEL_CONTENT.TEMPO_DECREE, "law_response", {
			"response": "timed_attack",
			"quality": quality
		})


func _try_apply_vessel_modifier_on_perfect(origin_lane: int, origin_damage: float) -> void:
	var bonded: Dictionary = GameState.get_active_bonded_creature()
	if bonded.is_empty():
		return
	var species_id: String = String(bonded.get("species_id", ""))
	var plan: Dictionary = VESSEL_MODIFIER_DIRECTOR.build_perfect_plan(species_id, origin_lane, origin_damage)
	if plan.is_empty():
		return
	var targets: Array = plan.get("targets", [])
	var cleave_damage: float = float(plan.get("damage", 0.0))
	var silhouette_color: Color = plan.get("silhouette_color", Color(1.0, 1.0, 1.0, 0.30))
	for target_variant in targets:
		var target_lane: int = int(target_variant)
		var enemy_id: int = _get_enemy_id_for_lane(target_lane)
		if enemy_id != -1:
			zone_manager.damage_enemy_by_id(enemy_id, cleave_damage)
		_presentation_runtime.spawn_attack_silhouette_to_lane(target_lane, silhouette_color, 7.0, 0.08, 0.92)
	_show_feedback(
		String(plan.get("label", "")),
		plan.get("color", Color(1.0, 1.0, 1.0, 1.0)),
		float(plan.get("label_duration", 0.28))
	)


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

	var parry_scale: float = 1.16 if quality == "perfect" else 1.0
	impact_fx_requested.emit(&"parry", _impact_pos_lane(lane, 0.56), _impact_lane_forward(lane), parry_scale)

	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_parry_profile(quality, bq), lane, enemy_id)
	_presentation_runtime.pulse_sigil_result_snap(quality, "parry")

	if quality == "perfect":
		_presentation_controller.on_combat_event(_bg_sprite, "perfect")
		_notify_tempo_mastery(COMBAT_FEEL_CONTENT.TEMPO_PUNCTURE, "perfect_parry", {
			"beat_quality": bq
		})
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE and (quality == "perfect" or quality == "good"):
		_notify_tempo_mastery(COMBAT_FEEL_CONTENT.TEMPO_DECREE, "law_response", {
			"response": "parry",
			"quality": quality
		})


func _on_player_dodged(from_sector: int, to_sector: int) -> void:
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_NONE:
		_kill_tempo_recovery_tween()
		_apply_tempo_time_scale(_base_time_scale)
	_show_feedback("DODGE", Color(0.65, 0.85, 1.0, 1.0), 0.28)
	_presentation_runtime.highlight_timing_ring(to_sector, Color(0.65, 0.85, 1.0, 1.0), 4.0)
	var slip: Vector2 = Vector2(0.26, float(to_sector - from_sector))
	if slip.y == 0.0:
		slip.y = 1.0
	var dodge_dir: Vector2 = slip.normalized()
	impact_fx_requested.emit(&"dodge", _impact_pos_lane(to_sector, 0.40), dodge_dir, 1.04)
	var bq: String = _get_beat_quality_for_action()
	_presentation_runtime.apply_impact_profile(COMBAT_IMPACT_FEEDBACK.build_dodge_profile(bq), to_sector, _get_enemy_id_for_lane(to_sector))
	if bq == "perfect":
		_show_beat_feedback("SLIP", Color(0.65, 0.85, 1.0, 1.0))
		EventBus.emit_signal("screen_flash", Color(0.50, 0.70, 1.0, 0.05), 0.04)
	elif bq == "good":
		_show_beat_feedback("SLIP", Color(0.55, 0.75, 0.92, 1.0))
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("notify_dodge_timing_quality"):
		_performance_reward_director.call("notify_dodge_timing_quality", from_sector, to_sector, bq)
	if _tempo_state_family == COMBAT_FEEL_CONTENT.TEMPO_DECREE:
		_notify_tempo_mastery(COMBAT_FEEL_CONTENT.TEMPO_DECREE, "law_response", {
			"response": "dodge",
			"quality": bq
		})


func _on_player_no_stamina() -> void:
	_show_feedback("NO STAMINA", Color(1.0, 0.45, 0.45, 1.0), 0.42)
	_flash_meter_shell(Color(0.28, 0.11, 0.11, 0.92), 0.12)


func _on_combat_input_resolved(
	action: String,
	lane: int,
	accepted: bool,
	buffered: bool,
	reason: String,
	state: String,
	cooldowns: Dictionary
) -> void:
	_last_combat_input_report = {
		"action": action,
		"lane": lane,
		"accepted": accepted,
		"buffered": buffered,
		"reason": reason,
		"state": state,
		"cooldowns": cooldowns
	}
	if _presentation_runtime != null:
		_presentation_runtime.pulse_sigil_input_echo(action, accepted, buffered, reason)
	if buffered:
		_show_feedback("QUEUE %s" % action.to_upper(), Color(0.84, 0.90, 1.0, 1.0), 0.16)
		return
	if accepted:
		return
	if reason == "no_stamina":
		# player_no_stamina already drives the banner + meter flash once.
		return
	_show_feedback(_compact_rejection_feedback(action, reason, state), Color(1.0, 0.56, 0.50, 1.0), 0.24)


func _compact_rejection_feedback(action: String, reason: String, state: String) -> String:
	match reason:
		"no_stamina":
			return "NO STAMINA"
		"no_charge":
			return "NO CHARGE"
		"locked":
			return "RECOVERING"
		"wrong_lane":
			return "WRONG LANE"
		"combat_disabled", "missing_runtime":
			return "UNAVAILABLE"
	if state != "idle":
		return "RECOVERING"
	return "%s DENIED" % action.to_upper()


func _on_combo_broken(_lost: int) -> void:
	_show_feedback("BROKEN", Color(1.0, 0.4, 0.4, 1.0), 0.40)


func _on_run_growth_changed(level: int, current_exp: float, exp_to_next: float) -> void:
	if _hud_presenter == null:
		return
	_hud_presenter.refresh_after_run_growth_exp(
		RunGrowth,
		level,
		current_exp,
		exp_to_next,
		_song_mode,
		_song_phase_index,
		_song_phases,
		_pending_creature_snapshot()
	)


func _on_run_growth_level_resolved(result: Dictionary) -> void:
	_refresh_run_build_readout()
	if result.is_empty():
		return
	
	# Sovereign Evolution Feedback
	var readout_label: String = str(result.get("readout_label", ""))
	var summary: String = str(result.get("summary", ""))
	
	if not readout_label.is_empty():
		# Trigger visual impact
		CombatFeedbackDirector.trigger_hit_stop(0.02, 0.15)
		CombatFeedbackDirector.trigger_shake(12.0, 0.20)
		EventBus.emit_signal("screen_flash", Color(0.12, 0.12, 0.14, 0.70), 0.15)
		
		_show_feedback("%s EVOLVED" % readout_label.to_upper(), Color(0.92, 0.22, 0.22, 1.0), 1.2)
		_quig_anchor_label.text = _hud_presenter.compact_hud_copy("%s - %s" % [readout_label, summary], 34)
		_quig_anchor_label.visible = true
		_refresh_quig_ui_state()
		
		if _quig_tween != null:
			_quig_tween.kill()
			
		_quig_tween = create_tween()
		_quig_tween.tween_interval(COMBAT_FEEL_CONTENT.TENDENCY_ANCHOR_HOLD_TIME * 1.5)
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
	_quig_anchor_label.text = _hud_presenter.compact_hud_copy(summary, 34)
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


func _on_vessel_shifted(class_data: Dictionary) -> void:
	if class_data.is_empty():
		return
	if _presentation_controller == null or not is_instance_valid(_presentation_controller):
		return

	var vibe_color: Color = class_data.get("vibe_color", Color.WHITE)
	_presentation_controller.refresh_vessel_vibe(class_data, _timing_rings_cache)
	
	# Visual feedback
	EventBus.screen_flash.emit(vibe_color.lerp(Color.WHITE, 0.4), 0.1)
	EventBus.slow_motion.emit(0.35, 0.12)
	EventBus.play_sfx.emit("vessel_shift")


func _on_creature_bonded(creature_data: Dictionary) -> void:
	var _name: String = str(creature_data.get("display_name", "creature")).to_upper()
	var _level: int = int(creature_data.get("bond_level", 1))
	var _flash_text: String = "BOND L%d" % _level if _level > 1 else "%s BONDED" % _name
	var _flash_color: Color = Color(0.62, 0.88, 1.0, 1.0) if _level > 1 else Color(0.82, 0.94, 0.76, 1.0)
	var species_id: String = str(creature_data.get("species_id", ""))
	
	_show_feedback(_flash_text, _flash_color, 0.48)
	EventBus.emit_signal("screen_flash", _flash_color.lerp(Color.WHITE, 0.5), 0.12)
	EventBus.emit_signal("dna_resonated", _flash_color, 1.0)
	_ensure_bonded_companion(species_id)
	
	_refresh_dna_hud()
	_refresh_run_build_readout()


func _on_support_charge_changed(current: float, maximum: float, active_species_id: String) -> void:
	_hud_presenter.refresh_support(current, maximum, active_species_id, RunGrowth)
	_refresh_bonded_creature_render(active_species_id)
	_refresh_run_build_readout()


func _refresh_bonded_creature_render(active_species_id: String = "") -> void:
	if _bonded_creature_sprite == null or zone_manager == null:
		return

	var species_id: String = active_species_id
	if species_id.is_empty():
		species_id = RunGrowth.get_active_species_id()

	if species_id.is_empty():
		_bonded_creature_species = ""
		_bonded_creature_sprite.visible = false
		_bonded_creature_sprite.texture = null
		_bonded_creature_sprite.hframes = 1
		_bonded_creature_sprite.vframes = 1
		_bonded_creature_sprite.frame = 0
		_bonded_creature_anim_accum = 0.0
		return

	if species_id == "ashclaw" and _has_bonded_companion(species_id):
		# Ashclaw's live combat body is BondedCompanion; this legacy support sprite
		# is only visual and has no target/attack wiring, so do not duplicate it.
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
		var old_stage: String = _bonded_creature_species.split("_")[-1] if not _bonded_creature_species.is_empty() else ""
		var render_tex: Texture2D = load(sprite_path) as Texture2D
		if render_tex == null:
			_bonded_creature_sprite.visible = false
			_bonded_creature_sprite.texture = null
			_bonded_creature_sprite.hframes = 1
			_bonded_creature_sprite.vframes = 1
			_bonded_creature_sprite.frame = 0
			_bonded_creature_anim_accum = 0.0
			return
		
		# Detect evolution for spectacular feedback
		var is_evolution: bool = not old_stage.is_empty() and old_stage != growth_stage
		if is_evolution:
			_trigger_creature_evolution_fx(species_id, growth_stage)

		_bonded_creature_species = portrait_key
		_bonded_creature_sprite.texture = render_tex
		
		# Auto-detect hframes for animation strips (assuming square frames)
		var h_frames: int = clampi(int(float(render_tex.get_width()) / render_tex.get_height()), 1, 64)
		_bonded_creature_sprite.hframes = h_frames
		_bonded_creature_sprite.vframes = 1 # Most creature sprites use one-row animation strips.
		
		# Legacy handling for old bond_remnant grid if path still matches
		if species_id == "bond_remnant" and growth_stage == "baby" and sprite_path.ends_with("bond_remnant_idle.png") and h_frames < 6:
			_bonded_creature_sprite.hframes = BOND_REMNANT_IDLE_HFRAMES
			_bonded_creature_sprite.vframes = BOND_REMNANT_IDLE_VFRAMES
		
		_bonded_creature_sprite.frame = 0
		_bonded_creature_anim_accum = 0.0

	var render_config: Dictionary = COMBAT_CONTENT.get_creature_combat_render(species_id)
	var world_offset: Vector2 = render_config.get("world_offset", Vector2(-108.0, 74.0))
	var render_scale: float = float(render_config.get("scale", 0.052))
	var render_modulate: Color = render_config.get("modulate", Color(0.90, 0.89, 0.86, 0.86))
	var render_z: int = int(render_config.get("z_index", 5))
	_bonded_creature_sprite.position = _lane_player_pos() + world_offset
	_bonded_creature_sprite.scale = Vector2.ONE * render_scale
	_bonded_creature_sprite.modulate = render_modulate
	_bonded_creature_sprite.z_index = render_z
	_bonded_creature_sprite.visible = true


func _apply_song_phase_cadence(phase: Dictionary, spawn_mult: float = 1.0) -> void:
	_apply_attack_authority_budget(_latest_ecology_snapshot, phase)
	var base_interval: float = float(phase.get("cycle_interval", 2.2))
	var base_stagger: float = float(phase.get("fire_stagger", 0.45))
	
	var section_id: String = ""
	var intensity: float = 0.0
	if _song_conductor != null and is_instance_valid(_song_conductor):
		section_id = str(_song_conductor.get("current_section_id"))
		intensity = float(_song_conductor.get("current_intensity"))
	
	# THE RESONANCE LAW: Resolve tier from intensity.
	var resonance: Dictionary = SONG_COMBAT_PROFILE_CONTENT.resolve_resonance_tier(intensity)
	var resonance_cadence: float = float(resonance.get("cadence_mult", 1.0))
	var resonance_density: float = float(resonance.get("density_mult", 1.0))
	var perfect_ms: int = int(resonance.get("perfect_window_ms", 65))
	
	# Apply windows to conductor.
	if _song_conductor != null:
		_song_conductor.beat_perfect_window = perfect_ms / 1000.0
		_song_conductor.beat_good_window = (perfect_ms * 2.0) / 1000.0
	
	var cadence_band: Dictionary = Dictionary(_difficulty_modifiers.get("threat_cadence", {}))
	var cadence_mult: float = clampf(float(cadence_band.get("cycle_interval_mult", 1.0)), 0.75, 1.35)
	var stagger_mult: float = clampf(float(cadence_band.get("fire_stagger_mult", 1.0)), 0.85, 1.15)
	
	var resolved: Dictionary = SONG_COMBAT_PROFILE_CONTENT.apply_cadence_law_to_values(
		_active_song_profile,
		section_id,
		spawn_mult,
		base_interval,
		base_stagger
	)
	var resolved_spawn_mult: float = float(resolved.get("spawn_mult", spawn_mult))
	var resolved_interval: float = float(resolved.get("cycle_interval", base_interval))
	var resolved_stagger: float = float(resolved.get("fire_stagger", base_stagger))
	var hunt_pressure_mult: float = 1.0
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("get_pressure_bias_snapshot"):
		var pressure_bias: Dictionary = _performance_reward_director.call("get_pressure_bias_snapshot")
		hunt_pressure_mult = clampf(float(pressure_bias.get("spawn_interval_mult", 1.0)), 0.86, 1.14)
	
	# Combine authoring, difficulty, and RESONANCE.
	var final_interval: float = resolved_interval * resonance_cadence * cadence_mult
	var final_spawn_mult: float = resolved_spawn_mult * hunt_pressure_mult / max(resonance_density, 0.1)
	
	if not zone_manager.is_combat_running():
		zone_manager.start_song_cycle()
	zone_manager.set_cycle_interval(final_interval * final_spawn_mult)
	zone_manager.set_fire_stagger(resolved_stagger * stagger_mult)


func _build_music_progression_state() -> Dictionary:
	var total_levels: int = max(_run_director.regular_level_windows.size(), 1)
	var level_ratio: float = clampf(float(_run_director.regular_level_index) / float(max(total_levels - 1, 1)), 0.0, 1.0)
	var level_duration: float = max(_song_level_end_time - _song_level_start_time, 0.001)
	var level_progress: float = clampf((_song_elapsed - _song_level_start_time) / level_duration, 0.0, 1.0)
	var run_progress: float = clampf((float(_run_director.regular_level_index) + level_progress) / float(total_levels), 0.0, 1.0)
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
	match combat_meter.get_current_tier():
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
		match str(_song_conductor.get_beat_quality()):
			"perfect":
				beat_value = 1.0
			"good":
				beat_value = 0.74
			_:
				beat_value = 0.38
	var progression_law: Dictionary = Dictionary(_active_song_profile.get("progression_law", {}))
	var beat_values: Dictionary = Dictionary(progression_law.get("beat_quality_values", {}))
	var weight_map: Dictionary = Dictionary(progression_law.get("skill_weights", {}))
	if not beat_values.is_empty():
		var beat_key: String = "off"
		if beat_value >= 0.99:
			beat_key = "perfect"
		elif beat_value >= 0.70:
			beat_key = "good"
		beat_value = float(beat_values.get(beat_key, beat_value))
	var combo_w: float = float(weight_map.get("combo", 0.38))
	var phrase_w: float = float(weight_map.get("phrase", 0.30))
	var tier_w: float = float(weight_map.get("tier", 0.22))
	var beat_w: float = float(weight_map.get("beat", 0.10))
	var skill: float = combo_norm * combo_w + phrase_norm * phrase_w + tier_value * tier_w + beat_value * beat_w
	return clampf(skill, 0.0, 1.0)


func _trigger_creature_evolution_fx(species_id: String, stage: String) -> void:
	# Spectacular evolution feedback
	var flash_color := Color.WHITE
	var shake_power := 4.0
	
	match stage:
		"teen":
			flash_color = Color(0.82, 0.16, 0.74, 0.3) # Purple/Mutation
			shake_power = 6.0
		"adult":
			flash_color = Color(0.90, 0.32, 0.15, 0.4) # Red/Apex
			shake_power = 10.0
	
	EventBus.emit_signal("screen_flash", flash_color, 0.25)
	EventBus.emit_signal("screen_shake", shake_power, 0.4)
	
	if _bonded_creature_sprite:
		var base_scale: float = _bonded_creature_sprite.scale.x
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		_bonded_creature_sprite.scale = Vector2.ZERO
		tween.tween_property(_bonded_creature_sprite, "scale", Vector2(base_scale, base_scale), 0.8)
		
		# Energy pulse from creature
		var pulse := Sprite2D.new()
		pulse.texture = _bonded_creature_sprite.texture
		pulse.position = _bonded_creature_sprite.position
		pulse.scale = _bonded_creature_sprite.scale
		pulse.modulate = flash_color
		pulse.modulate.a = 0.6
		add_child(pulse)
		
		var p_tween = create_tween()
		p_tween.tween_property(pulse, "scale", pulse.scale * 3.0, 0.6)
		p_tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.6)
		p_tween.tween_callback(pulse.queue_free)


func _rebuild_music_driven_difficulty() -> void:
	if _difficulty_modifier_director == null or _music_control_layer == null:
		return
	if _base_difficulty_modifiers.is_empty():
		return
	if _song_combat_state.is_empty():
		_refresh_song_combat_state()
	var music_state: Dictionary = _song_combat_state
	var progression_state: Dictionary = _build_music_progression_state()
	var new_modifiers: Dictionary = _difficulty_modifier_director.compute_active_modifiers(
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


func _refresh_song_combat_state() -> void:
	if _music_control_layer == null:
		_song_combat_state = {}
		return
	var built_state: Dictionary = _music_control_layer.build_state()
	_song_combat_state = built_state.duplicate(true)


func _build_level_difficulty_modifiers(encounter_options: Dictionary) -> Dictionary:
	return SONG_COMBAT_PROFILE_CONTENT.build_level_difficulty_modifiers(
		_region_id,
		_run_director.regular_level_index,
		encounter_options,
		_active_song_profile
	)


func _apply_difficulty_modifiers_to_runtime() -> void:
	if _escalation_director != null and is_instance_valid(_escalation_director):
		_escalation_director.set_difficulty_modifiers(_difficulty_modifiers)
	if _performance_reward_director != null and is_instance_valid(_performance_reward_director) and _performance_reward_director.has_method("set_difficulty_modifiers"):
		_performance_reward_director.call("set_difficulty_modifiers", _difficulty_modifiers)
	if zone_manager != null and is_instance_valid(zone_manager):
		var punish_band: Dictionary = Dictionary(_difficulty_modifiers.get("punish_severity", {}))
		zone_manager.set_punish_damage_mult(float(punish_band.get("projectile_damage_mult", 1.0)))


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
	if _song_combat_state.is_empty():
		_refresh_song_combat_state()
	var from_state: String = str(_song_combat_state.get("cadence_window", ""))
	if not from_state.is_empty():
		return from_state
	if _song_conductor != null and is_instance_valid(_song_conductor):
		return str(_song_conductor.get("current_cadence_window"))
	return ""


func _on_bonded_support_triggered(species_id: String, lane: int, effect_id: String) -> void:
	var combo_mult: float = combat_meter.damage_multiplier()
	var active_creature: Dictionary = GameState.get_active_bonded_creature()
	@warning_ignore("static_called_on_instance")
	var bond_mult: float = GameState.get_bond_level_mult(int(active_creature.get("bond_level", 1)))
	
	# Bond Surge: next support trigger has doubled effectiveness.
	var surge_mult: float = 1.0
	var surge_effect: Dictionary = Dictionary(RunGrowth.get_runtime_effect("bond_trigger_mult"))
	surge_mult = float(surge_effect.get("value", 1.0))

	if surge_mult > 1.0:
		_show_feedback("SYNC ACTIVE", Color(0.44, 0.96, 0.78, 1.0), 0.42)

	var mastery_context: Dictionary = _support_resolver.build_mastery_context(
		effect_id,
		lane,
		_get_mastery_window(),
		_get_current_cadence_window(),
		_last_mastery_context,
		SUPPORT_MASTERY_CONTEXT_TIMEOUT
	)
	
	var mastery: String = str(mastery_context.get("window_id", ""))
	var cadence_surge: bool = (mastery == "cadence_surge")
	var support_profile: Dictionary = COMBAT_IMPACT_FEEDBACK.build_support_profile(effect_id, cadence_surge, surge_mult > 1.0)
	
	var support_enemy_id: int = _get_enemy_id_for_lane(lane)
	if effect_id in ["bond_remnant_mend", "gruvek_gorge", "marrowward_ward", "gorefane_maul", "siltgrip_drag"]:
		support_enemy_id = -1

	if _support_resolver != null:
		var ctx: Dictionary = {
			"species_id": species_id,
			"lane": lane,
			"targets": player_combat._get_targets_in_cone() if player_combat != null else {},
			"effect_id": effect_id,
			"combo_mult": combo_mult,
			"bond_mult": bond_mult,
			"surge_mult": surge_mult,
			"mastery_window": mastery,
			"cadence_surge": cadence_surge,
			"bond_surge": surge_mult > 1.0,
			"is_hollow_active": str(active_creature.get("species_id", "")) == "bond_remnant",
			"zone_manager": zone_manager,
			"combat_meter": combat_meter,
			"game_state": GameState
		}
		
		ctx["collar_mod"] = _support_resolver.apply_collar_logic(ctx, GameState.get_equipped_collar(), combat_meter)
		
		if ctx["collar_mod"].has("redirected_lane"):
			support_enemy_id = _get_enemy_id_for_lane(int(ctx.get("lane", lane)))
		
		_support_resolver.resolve(ctx)

	_presentation_runtime.apply_impact_profile(support_profile, lane, support_enemy_id)

	# Pack Signal upgrade: heal on every support trigger.
	var pack_heal_effect: Dictionary = _get_growth_effect("support_trigger_heal")
	if not pack_heal_effect.is_empty():
		var pack_healed: float = GameState.heal_player(float(pack_heal_effect.get("value", 0.0)))
		if pack_healed > 0.0:
			EventBus.emit_signal("player_healed", pack_healed)


func _on_phrase_milestone(count: int) -> void:
	if _music_control_layer != null:
		_music_control_layer.notify_phrase_marker(count)
	_rebuild_music_driven_difficulty()
	
	_trigger_regional_feedback("phrase_milestone", {"count": count})


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
	var enemy: Dictionary = zone_manager.get_enemy(lane)
	if enemy.is_empty():
		return -1
	return int(enemy.get("id", -1))


func _on_enemy_status_applied(enemy_id: int, status_id: String, params: Dictionary) -> void:
	# Updates the enemy marker color to reflect the new status.
	# "gorge_mark_triggered" fires when a marked enemy dies — show FEAST feedback.
	if status_id == "gorge_mark_triggered":
		_show_feedback("FEAST", Color(0.92, 0.60, 0.20, 1.0), 0.36)
		return

	if enemy_id < 0:
		return
	var marker_data = _enemy_markers_by_id.get(enemy_id, null)
	if marker_data == null:
		return

	match status_id:
		"bleed":
			_status_marker_overrides[enemy_id] = Color(0.80, 0.22, 0.10, 0.92)
			_show_feedback("BLEED", Color(0.94, 0.40, 0.24, 1.0), 0.30)
		"rend":
			_status_marker_overrides[enemy_id] = Color(0.98, 0.76, 0.32, 0.92)
			_show_feedback("REND", Color(1.0, 0.84, 0.45, 1.0), 0.32)
		"expose":
			_status_marker_overrides[enemy_id] = Color(0.40, 0.42, 0.58, 0.70)
			_show_feedback("PALE", Color(0.74, 0.78, 0.96, 1.0), 0.28)
		"gorge_mark":
			_status_marker_overrides[enemy_id] = Color(0.72, 0.50, 0.10, 0.88)
			# No feedback — gorge already showed "GORGE".
		"expose":
			_status_marker_overrides[enemy_id] = Color(0.84, 0.70, 0.12, 0.92)
			_show_feedback("EXPOSED", Color(0.96, 0.88, 0.44, 1.0), 0.32)
		"venom":
			if bool(params.get("slow", false)):
				# Sludge Synergy
				_status_marker_overrides[enemy_id] = Color(0.24, 0.52, 0.18, 0.92)
				_show_feedback("SYSTEM BREACH", Color(0.44, 0.88, 0.36, 1.0), 0.38)
			else:
				_status_marker_overrides[enemy_id] = Color(0.48, 0.12, 0.64, 0.92)
				_show_feedback("VENOM", Color(0.72, 0.36, 0.88, 1.0), 0.34)
		"slow":
			_status_marker_overrides[enemy_id] = Color(0.18, 0.62, 0.12, 0.88)
			_show_feedback("SLOW", Color(0.36, 0.88, 0.32, 1.0), 0.30)
		_:
			return

	var body_node = marker_data.get("body")
	if is_instance_valid(body_node):
		var marker_body: ColorRect = body_node
		marker_body.color = _status_marker_overrides[enemy_id]


func _on_enemy_status_cleared(enemy_id: int) -> void:
	# Resets the enemy marker color to its biome-based color when a status expires or is consumed.
	if enemy_id != -1 and _status_marker_overrides.has(enemy_id):
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
	var runtime_effect: Dictionary = RunGrowth.get_runtime_effect(effect_type)
	if not runtime_effect.is_empty():
		return runtime_effect
	return {}


func _on_player_teleported(_from_sector: int, _to_sector: int) -> void:
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


func _clear_song_enemy_tracking() -> void:
	for marker_data in _enemy_markers_by_id.values():
		if not (marker_data is Dictionary):
			continue
		var root_node = marker_data.get("root")
		if is_instance_valid(root_node):
			root_node.queue_free()
	_enemy_markers_by_id.clear()
	_all_enemies_by_id.clear()
	_enemy_max_hp.clear()
	_enemy_phase_by_id.clear()
	_status_marker_overrides.clear()


func _spawn_support_intervention(species_id: String, lane: int, tint: Color) -> void:
	var bonded: Dictionary = GameState.get_bonded_creature(species_id)
	var bond_level: int = int(bonded.get("bond_level", 1))
	var growth_stage: String = GameState.get_creature_growth_stage(bond_level)
	
	var support_art: String = COMBAT_CONTENT.get_creature_art_path(species_id, "support", growth_stage)
	if not support_art.is_empty():
		if is_instance_valid(_presentation_runtime) and _presentation_runtime.has_method("spawn_creature_intervention"):
			_presentation_runtime.spawn_creature_intervention(lane, support_art, tint)
		elif is_instance_valid(_presentation_runtime) and _presentation_runtime.has_method("spawn_attack_silhouette_to_lane"):
			_presentation_runtime.spawn_attack_silhouette_to_lane(lane, tint, 16.0, 0.14, 1.18)
	else:
		_presentation_runtime.spawn_attack_silhouette_to_lane(lane, tint, 16.0, 0.14, 1.18)


func _on_quig_narrative_triggered(text: String, duration: float) -> void:
	if _quig_anchor_label == null:
		return

	_quig_anchor_label.text = _hud_presenter.compact_hud_copy(text, 58)
	_quig_anchor_label.visible = true
	_refresh_quig_ui_state()	
	if _quig_tween != null:
		_quig_tween.kill()
	
	_quig_tween = create_tween()
	_quig_tween.tween_interval(duration)
	_quig_tween.tween_property(_quig_anchor_label, "modulate:a", 0.0, COMBAT_FEEL_CONTENT.TENDENCY_ANCHOR_FADE_TIME)
	_quig_tween.finished.connect(func():
		if _quig_anchor_label != null:
			_quig_anchor_label.visible = false
			_quig_anchor_label.modulate.a = 1.0
			_refresh_quig_ui_state()
	)
