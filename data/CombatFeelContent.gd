extends RefCounted

# ─── TIMING RINGS ────────────────────────────────────────────────────────────
const RING_OUTER_RADIUS: float = 22.0 # Honest good window for 360-degree spatial combat.
const RING_PERFECT_RADIUS: float = 10.5 # Inner bite point: readable, but still earned.
const RING_POINT_COUNT: int = 32
const EDGE_STATE_WIDTH: float = 0.016
const RING_VISUAL_SCALE: float = 1.45 # Presentation scale only; gameplay radii stay authoritative.
const RING_PROXIMITY_FORGIVENESS: float = 6.0 # Small close-quarters grace outside the visible good band.

# ─── LANE VISUALS ────────────────────────────────────────────────────────────
const LANE_BAND_HEIGHT: float = 18.0
const LANE_IDLE_ALPHA: float = 0.038
const LANE_THREAT_ALPHA: float = 0.12
const LANE_CRITICAL_ALPHA: float = 0.24
const LANE_THREAT_FOCUS_ALPHA: float = 0.32
const LANE_IMMINENT_FOCUS_ALPHA: float = 0.64

const FOCAL_MARKER_WIDTH: float = 2.0
const FOCAL_MARKER_SIZE: Vector2 = Vector2(24.0, 36.0) # Halved
const FOCAL_MARKER_COLOR: Color = Color(0.92, 0.88, 0.76, 0.24)
const FOCAL_MARKER_ACTIVE_ALPHA: float = 0.72

const LANE_LEGACY_VISUALS := {
	"ring_active_scale": 1.0,
	"ring_inactive_scale": 0.8,
	"ring_perfect_scale": 1.2,
	"ring_good_scale": 1.1,
	"ring_transition_speed": 0.15,
	"lane_highlight_intensity": 0.3,
	"danger_lane_tint": Color(1.0, 0.2, 0.2, 0.4)
}

# ─── VISUAL DURATIONS & TIMINGS ──────────────────────────────────────────────
const COMBAT_FEEDBACK_MIN_LIFETIME: float = 0.50
const COMBAT_FEEDBACK_FADE_TIME: float = 0.24
const BEAT_FEEDBACK_HOLD_TIME: float = 0.42
const BEAT_FEEDBACK_FADE_TIME: float = 0.24
const PERFORMANCE_PROC_CHIP_VISIBLE_TIME: float = 1.8
const PERFORMANCE_PROC_CHIP_FADE_TIME: float = 1.2
const TENDENCY_ANCHOR_HOLD_TIME: float = 2.3
const TENDENCY_ANCHOR_FADE_TIME: float = 0.26
const DAMAGE_NUMBER_FLOAT_TIME: float = 0.85
const PARRY_FOLLOWUP_WINDOW_BASE: float = 0.55
const PARRY_FOLLOWUP_WINDOW_ON_BEAT: float = 0.85

# ─── SLOW MOTION PRESETS & TENDENCIES ────────────────────────────────────────
const SLOWMO_PRESETS_BY_CONTEXT: Dictionary = {
	"parry_perfect_beat_perfect": {"scale": 0.65, "duration": 1.20},
	"parry_perfect_beat_good": {"scale": 0.68, "duration": 1.00},
	"parry_perfect_offbeat": {"scale": 0.72, "duration": 0.80},
	"timed_attack_perfect_beat_perfect": {"scale": 0.75, "duration": 0.80},
	"timed_attack_perfect_other": {"scale": 0.80, "duration": 0.60},
	"timed_attack_good": {"scale": 0.88, "duration": 0.40},
	"parry_followup": {"scale": 0.86, "duration": 0.40},
	"ultimate_perfect": {"scale": 0.55, "duration": 1.40},
	"ultimate_good": {"scale": 0.62, "duration": 1.20},
	"ultimate_base": {"scale": 0.72, "duration": 1.00},
	"counter_warp_perfect": {"scale": 0.35, "duration": 1.20},
	"counter_warp_good": {"scale": 0.45, "duration": 1.00},
	"boss_defeat": {"scale": 0.35, "duration": 2.50},
	"critical_hit": {"scale": 0.50, "duration": 0.40}
}

const SLOW_MOTION_DURATION := {
	"parry_perfect_beat_perfect": 1.20,
	"parry_perfect_beat_good": 1.00,
	"parry_perfect_offbeat": 0.80,
	"timed_attack_perfect_beat_perfect": 0.80,
	"timed_attack_perfect_other": 0.60,
	"timed_attack_good": 0.40,
	"parry_followup": 0.40,
	"ultimate_perfect": 1.40,
	"ultimate_good": 1.20,
	"ultimate_base": 1.00,
	"counter_warp_perfect": 1.20,
	"counter_warp_good": 1.00,
	"boss_defeat": 2.5,
	"critical_hit": 0.4
}

const SLOW_MOTION_SCALES := {
	"parry_perfect_beat_perfect": 0.65,
	"parry_perfect_beat_good": 0.68,
	"parry_perfect_offbeat": 0.72,
	"timed_attack_perfect_beat_perfect": 0.75,
	"timed_attack_perfect_other": 0.80,
	"timed_attack_good": 0.88,
	"parry_followup": 0.86,
	"ultimate_perfect": 0.55,
	"ultimate_good": 0.62,
	"ultimate_base": 0.72,
	"counter_warp_perfect": 0.35,
	"counter_warp_good": 0.45,
	"hit_stop": 0.35
}

const HIT_STOP_DURATION := {
	"light_attack": 0.08,
	"heavy_attack": 0.12,
	"parry": 0.15,
	"perfect_parry": 0.2,
	"ultimate": 0.3,
	"boss_hit": 0.1
}

const SLOWMO_TIER_THRESHOLDS: Dictionary = {
	"puncture_max_scale": 0.40, # Raised to catch all hit-stops
	"stretch_max_scale": 0.69  # Lowered to strictly suppress 0.70 light hits
}

# ─── TEMPO & TIME DISTORTION ────────────────────────────────────────────────
const TEMPO_NONE: StringName = &"none"
const TEMPO_PUNCTURE: StringName = &"puncture" # Micro-time combat violence
const TEMPO_STRETCH: StringName = &"stretch"   # Relative time dilation (part of Suspension)
const TEMPO_VOID: StringName = &"void"         # Complete tactical pause (Suspension: slowed choice/reward)
const TEMPO_DECREE: StringName = &"decree"     # Boss/world law shift
const TEMPO_PRIORITY: Dictionary = {
	TEMPO_NONE: 0,
	TEMPO_STRETCH: 1,  # Lower priority
	TEMPO_PUNCTURE: 2, # Higher priority: hit-stops override dilation
	TEMPO_DECREE: 3,
	TEMPO_VOID: 4
}
const PUNCTURE_MIN_SCALE: float = 0.15
const PUNCTURE_MAX_SCALE: float = 0.35
const PUNCTURE_MAX_DURATION: float = 0.08
const PUNCTURE_COOLDOWN_SECONDS: float = 0.20
const STRETCH_SCALE: float = 0.65
const STRETCH_MAX_DURATION: float = 1.20
const VOID_SCALE: float = 0.35
const DECREE_SCALE: float = 0.40
const DECREE_MIN_DURATION: float = 0.40
const DECREE_MAX_DURATION: float = 1.20
const TEMPO_DISTORTION_WINDOW_SECONDS: float = 10.0
const PUNCTURE_MAX_DISTORTION_PER_WINDOW: float = 1.40

# ─── CAMERA EFFECTS ──────────────────────────────────────────────────────────
const CAMERA_SHAKE := {
	"light_hit": {"intensity": 2.0, "duration": 0.15, "frequency": 15.0},
	"heavy_hit": {"intensity": 4.0, "duration": 0.25, "frequency": 12.0},
	"parry": {"intensity": 3.0, "duration": 0.2, "frequency": 20.0},
	"perfect_parry": {"intensity": 5.0, "duration": 0.3, "frequency": 25.0},
	"ultimate": {"intensity": 8.0, "duration": 0.5, "frequency": 10.0},
	"boss_impact": {"intensity": 6.0, "duration": 0.4, "frequency": 8.0}
}

const CAMERA_ZOOM := {
	"attack_zoom": {"amount": 1.1, "duration": 0.2, "ease_type": "ease_out"},
	"parry_zoom": {"amount": 1.15, "duration": 0.25, "ease_type": "ease_out"},
	"ultimate_zoom": {"amount": 1.3, "duration": 0.4, "ease_type": "ease_out"},
	"boss_zoom": {"amount": 1.2, "duration": 0.3, "ease_type": "ease_in_out"}
}

# ─── VISUAL EFFECTS ──────────────────────────────────────────────────────────
const AFFINITY_COLORS := {
	"flesh": Color(0.92, 0.28, 0.18, 0.52),    # Aggressive Red-Orange
	"hollow": Color(0.58, 0.88, 1.0, 0.44),    # Cold Ethereal Blue
	"gorge": Color(0.96, 0.52, 0.12, 0.48),    # Warm Predatory Orange
	"reflex": Color(0.24, 0.78, 1.0, 0.46),    # Sharp Signal Blue
	"cadence": Color(1.0, 0.88, 0.26, 0.50),   # Alert Pulse Gold
	"guard": Color(0.42, 0.72, 0.96, 0.46),    # Stable Shield Azure
	"hush": Color(0.64, 0.62, 0.84, 0.42),     # Dampened Violet
	"steel": Color(0.88, 0.92, 0.96, 0.48),    # Hard Metallic Grey
	"void": Color(0.12, 0.08, 0.16, 0.60)      # Deep Ink Black
}

const SCREEN_FLASH := {
	"light_damage": {"color": Color(1.0, 0.2, 0.2, 0.3), "duration": 0.1},
	"heavy_damage": {"color": Color(1.0, 0.1, 0.1, 0.5), "duration": 0.15},
	"perfect_parry": {"color": Color(1.0, 1.0, 1.0, 0.99), "duration": 0.08},
	"manga_inversion": {"color": Color(1.0, 1.0, 1.0, 0.99), "duration": 0.08},
	"ultimate_activation": {"color": Color(1.0, 0.8, 0.2, 0.6), "duration": 0.3},
	"heal": {"color": Color(0.2, 1.0, 0.4, 0.3), "duration": 0.2},
	"shield": {"color": Color(0.4, 0.8, 1.0, 0.3), "duration": 0.15},
	"boss_intro_1": {"color": Color(0.68, 0.32, 0.06, 0.34), "duration": 0.20},
	"boss_intro_2": {"color": Color(0.62, 0.24, 0.04, 0.20), "duration": 0.14},
	"boss_threshold": {"color": Color(0.74, 0.28, 0.04, 0.34), "duration": 0.20},
	"boss_threshold_pulse": {"color": Color(0.80, 0.32, 0.04, 0.20), "duration": 0.16}
}

const IMPACT_SCALING := {
	"light_hit": {"scale_multiplier": 1.2, "duration": 0.15},
	"heavy_hit": {"scale_multiplier": 1.5, "duration": 0.25},
	"critical_hit": {"scale_multiplier": 2.0, "duration": 0.3},
	"parry": {"scale_multiplier": 1.8, "duration": 0.2},
	"ultimate": {"scale_multiplier": 2.5, "duration": 0.4}
}

# ─── AUDIO FEEDBACK ──────────────────────────────────────────────────────────
const AUDIO_PITCH := {
	"light_attack": 1.0,
	"heavy_attack": 0.9,
	"perfect_timing": 1.2,
	"parry": 1.1,
	"ultimate": 0.8,
	"boss_hit": 0.85
}

const AUDIO_VOLUME := {
	"base_sfx": 1.0,
	"impact_sfx": 1.2,
	"parry_sfx": 1.3,
	"ultimate_sfx": 1.5,
	"boss_sfx": 1.4,
	"ambient_music": 0.7,
	"combat_music": 0.9
}

# ─── COMBAT METER FEEL ───────────────────────────────────────────────────────
const COMBO_FEEDBACK := {
	"combo_break_shake": {"intensity": 3.0, "duration": 0.2, "frequency": 18.0},
	"tier_upgrade_flash": {"color": Color(1.0, 0.9, 0.3, 0.4), "duration": 0.25},
	"ultimate_ready_glow": {"color": Color(1.0, 0.7, 0.2, 0.6), "pulse_duration": 1.0, "pulse_intensity": 0.3}
}

const STAMINA_FEEDBACK := {
	"low_stamina_tint": Color(1.0, 0.3, 0.3, 0.2),
	"no_stamina_flash": {"color": Color(1.0, 0.1, 0.1, 0.5), "duration": 0.2},
	"stamina_gain_pulse": {"scale": 1.1, "duration": 0.1}
}

# ─── UI ANIMATION ────────────────────────────────────────────────────────────
const UI_ANIMATIONS := {
	"damage_number": {
		"rise_speed": 60.0,
		"fade_duration": 1.0,
		"scale_curve": [0.5, 1.2, 1.0, 0.8],
		"critical_scale": 1.5
	},
	"combo_counter": {
		"pop_scale": 1.3,
		"pop_duration": 0.15,
		"shake_intensity": 2.0,
		"shake_duration": 0.1
	},
	"health_bar": {
		"shake_on_damage": {"intensity": 1.5, "duration": 0.1},
		"smooth_lerp_speed": 8.0,
		"damage_show_duration": 0.3
	},
	"ultimate_ready": {"glow_pulse_speed": 2.0, "border_flash_speed": 3.0, "ready_scale": 1.05}
}

# ─── TIMING WINDOWS ──────────────────────────────────────────────────────────
const TIMING_WINDOWS := {
	"perfect_timing_ms": 65,
	"good_timing_ms": 130,
	"attack_buffer_ms": 100,
	"parry_buffer_ms": 150,
	"dodge_buffer_ms": 200
}

const TELEGRAPH_TIMING := {
	"base_duration": 0.8,
	"elite_duration": 1.2,
	"boss_duration": 1.5,
	"warning_fade": 0.15,
	"attack_windup": 0.3
}

const EXPOSE_WINDOW := {
	"base_duration": 1.2,
	"elite_duration": 1.0,
	"boss_duration": 0.8,
	"perfect_window": 0.4,
	"good_window": 0.8
}

# ─── PARTICLE EFFECTS ────────────────────────────────────────────────────────
const PARTICLE_SYSTEMS := {
	"blood_splash": {"count": 15, "spread": 45.0, "initial_velocity": 100.0, "lifetime": 0.8, "color": Color(0.8, 0.1, 0.1, 0.8)},
	"parry_spark": {"count": 8, "spread": 30.0, "initial_velocity": 150.0, "lifetime": 0.4, "color": Color(0.2, 1.0, 0.8, 0.9)},
	"ultimate_burst": {"count": 25, "spread": 360.0, "initial_velocity": 200.0, "lifetime": 1.2, "color": Color(1.0, 0.8, 0.2, 0.7)},
	"heal_aura": {"count": 12, "spread": 180.0, "initial_velocity": 50.0, "lifetime": 1.0, "color": Color(0.2, 1.0, 0.4, 0.6)}
}

# ─── HUD LAYOUT & ASSETS ─────────────────────────────────────────────────────
# Shipped combat panels live under res://assets/ui/combat/panels/ (names match *.import source_file).
const _HUD_TOP_LEFT_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_top_left.png",
	"res://assets/ui/combat/panels/combat_panel_premium_top_left.png",
	"res://assets/ui/combat/panels/combat_panel_top_left.png.png",
]
const _HUD_TOP_RIGHT_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_top_right.png",
	"res://assets/ui/combat/panels/combat_panel_premium_top_right.png",
	"res://assets/ui/combat/panels/combat_panel_top_right.png.png",
]
const _HUD_REWARD_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_reward_claim.png",
	"res://assets/ui/combat/panels/combat_panel_premium_reward.png",
	"res://assets/ui/combat/panels/combat_panel_reward_claim.png.png",
]
const _HUD_BOTTOM_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_bottom.png",
	"res://assets/ui/combat/panels/combat_panel_bottom.png.png",
]
## Atlas slice in texture pixel space (legacy / shared sheet shells).
const HUD_TOP_LEFT_ATLAS_REGION: Rect2 = Rect2(102.0, 276.0, 1328.0, 379.0)
const HUD_TOP_RIGHT_ATLAS_REGION: Rect2 = Rect2(138.0, 278.0, 1265.0, 371.0)
## Premium Menace claws: sheet-local slice (aligns claws to expanded HUD frames). Empty size → entire texture bounds.
const HUD_PREMIUM_TOP_LEFT_ATLAS_REGION: Rect2 = Rect2(101.0, 275.0, 1330.0, 382.0)
const HUD_PREMIUM_TOP_RIGHT_ATLAS_REGION: Rect2 = Rect2(136.0, 276.0, 1268.0, 376.0)
const HUD_REWARD_ATLAS_REGION: Rect2 = Rect2(86.0, 131.0, 1381.0, 565.0)
const HUD_BOTTOM_ATLAS_REGION: Rect2 = Rect2()
const HUD_TOP_LEFT_NINE_SLICE: Vector4 = Vector4.ZERO
const HUD_TOP_RIGHT_NINE_SLICE: Vector4 = Vector4.ZERO
const HUD_REWARD_NINE_SLICE: Vector4 = Vector4.ZERO
const HUD_TOP_LEFT_CONTENT_MARGIN: Vector4 = Vector4(18.0, 12.0, 18.0, 10.0)
const HUD_TOP_RIGHT_CONTENT_MARGIN: Vector4 = Vector4(20.0, 12.0, 20.0, 10.0)
const HUD_REWARD_CONTENT_MARGIN: Vector4 = Vector4(30.0, 22.0, 30.0, 30.0)
const HUD_REWARD_COMPACT_CONTENT_MARGIN: Vector4 = Vector4(12.0, 8.0, 12.0, 10.0)
const HUD_BOTTOM_NINE_SLICE: Vector4 = Vector4.ZERO
const HUD_BOTTOM_CONTENT_MARGIN: Vector4 = Vector4(10.0, 3.0, 10.0, 3.0)
const _HUD_BAR_TRACK_PATHS: Array[String] = [
	"res://assets/ui/combat/bars/combat_bar_track.png",
	"res://assets/ui/combat/bars/combat_bar_hp_track.png",
	"res://assets/ui/combat/panels/combat_bar_track.png",
	"res://assets/ui/combat/bars/combat_bar_track.png.png",
]
const HUD_BAR_TRACK_ATLAS_REGION: Rect2 = Rect2()
const HUD_BAR_TRACK_NINE_SLICE: Vector4 = Vector4(6.0, 4.0, 6.0, 4.0)

# ─── VIEWPORT DATA ───────────────────────────────────────────────────────────
const HUD_VIEWPORT_WIDTH: float = 1280.0
const HUD_VIEWPORT_HEIGHT: float = 720.0
const HUD_OUTER_MARGIN: float = 12.0
const HUD_TOP_BAND_Y: float = 4.0
const HUD_TOP_BAND_HEIGHT: float = 160.0
const HUD_TOP_PANEL_WIDTH: float = 320.0
const HUD_TOP_RIGHT_PANEL_WIDTH: float = 132.0
const HUD_GAP_BELOW_TOP_BAND: float = 10.0
const HUD_RIGHT_RAIL_WIDTH: float = 132.0
const HUD_RIGHT_STACK_MIN_HEIGHT: float = 218.0
const HUD_BOTTOM_STRIP_HEIGHT: float = 34.0
const HUD_BOTTOM_OUTER_MARGIN: float = 10.0
const HUD_BOSS_BLOCK_WIDTH: float = 488.0
const HUD_BOSS_BLOCK_X: float = (HUD_VIEWPORT_WIDTH - HUD_BOSS_BLOCK_WIDTH) * 0.5
const HUD_BOSS_BLOCK_Y: float = HUD_TOP_BAND_Y + 26.0
const RIGHT_HUD_STACK_X: float = HUD_VIEWPORT_WIDTH - HUD_OUTER_MARGIN - HUD_RIGHT_RAIL_WIDTH
const RIGHT_HUD_STACK_WIDTH: float = HUD_RIGHT_RAIL_WIDTH
const RIGHT_HUD_LABEL_X: float = RIGHT_HUD_STACK_X + 8.0
const RIGHT_HUD_VALUE_X: float = RIGHT_HUD_STACK_X + 74.0
const RIGHT_HUD_ROW_WIDTH: float = 22.0
const RIGHT_HUD_TEXT_WIDTH: float = 108.0
const COMPACT_LIVE_REWARD_WIDTH: float = 132.0
const COMPACT_LIVE_REWARD_HEIGHT: float = 64.0
const COMPACT_LIVE_REWARD_ABOVE_FOOTER_GAP: float = 8.0
const HUD_COMBAT_FEEDBACK_Y: float = 108.0
const HUD_COMBAT_FEEDBACK_HALF_WIDTH: float = 220.0
const HUD_COMBAT_FEEDBACK_HEIGHT: float = 34.0
const HUD_COMBAT_FEEDBACK_FONT_SIZE: int = 20
const HUD_COMBAT_FEEDBACK_PUNCH_SCALE: float = 1.06
const COMPACT_PERFORMANCE_OFFER_WIDTH: float = 132.0
const COMPACT_PERFORMANCE_OFFER_HEIGHT: float = 64.0
const COMPACT_PERFORMANCE_OFFER_ABOVE_FOOTER_GAP: float = 8.0

# ─── SPRITE ANIMATION DATA ───────────────────────────────────────────────────
const QUIG_SPRITE_PATH: String = "res://assets/sprites/quig.png"
const QUIG_FRAME_SIZE: Vector2i = Vector2i(32, 32)
const QUIG_FRAME_COUNT: int = 8
const QUIG_FRAME_DURATION: float = 0.11
const DNA_SPRITE_PATH: String = "res://assets/sprites/dna.png"
const DNA_FRAME_SIZE: Vector2i = Vector2i(32, 32)
const DNA_FRAME_COUNT: int = 5
const DNA_FRAME_DURATION: float = 0.18

# ─── BACKGROUND DATA ─────────────────────────────────────────────────────────
const COMBAT_BG_PATHS: Array[String] = [
	"res://assets/backgrounds/combat/Ruins_world.png",
	"res://assets/backgrounds/combat/arcane_world.png",
	"res://assets/backgrounds/combat/lightlycurrupted_world.png",
	"res://assets/backgrounds/combat/blue_world.png",
	"res://assets/backgrounds/combat/purple_world.png",
	"res://assets/backgrounds/combat/gentle_world.png",
	"res://assets/backgrounds/combat/darkgentle_world.png",
]
const COMBAT_BG_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

# ─── UTILITY FUNCTIONS ───────────────────────────────────────────────────────
static func get_slowmo_preset(context_id: String, fallback: Dictionary = {}) -> Dictionary:
	if SLOWMO_PRESETS_BY_CONTEXT.has(context_id):
		return Dictionary(SLOWMO_PRESETS_BY_CONTEXT[context_id]).duplicate(true)
	return fallback.duplicate(true)

static func get_slow_motion_duration(event_type: String) -> float:
	return SLOW_MOTION_DURATION.get(event_type, 0.1)

static func get_slow_motion_scale(event_type: String) -> float:
	return SLOW_MOTION_SCALES.get(event_type, 1.0)

static func get_hit_stop_duration(attack_type: String) -> float:
	return HIT_STOP_DURATION.get(attack_type, 0.1)

static func get_camera_shake_params(shake_type: String) -> Dictionary:
	return CAMERA_SHAKE.get(shake_type, {"intensity": 1.0, "duration": 0.1, "frequency": 10.0})

static func get_screen_flash_params(flash_type: String) -> Dictionary:
	return SCREEN_FLASH.get(flash_type, {"color": Color.WHITE, "duration": 0.1})

static func get_affinity_color(affinity: String) -> Color:
	return AFFINITY_COLORS.get(affinity, Color(1.0, 1.0, 1.0, 0.4))

static func get_timing_window_ms(window_type: String) -> float:
	return TIMING_WINDOWS.get(window_type, 100.0)

static func get_impact_scaling(impact_type: String) -> Dictionary:
	return IMPACT_SCALING.get(impact_type, {"scale_multiplier": 1.0, "duration": 0.1})

static func get_ui_animation_params(ui_element: String) -> Dictionary:
	return UI_ANIMATIONS.get(ui_element, {})

static func get_particle_params(particle_type: String) -> Dictionary:
	return PARTICLE_SYSTEMS.get(particle_type, {"count": 5, "lifetime": 0.5})

# ─── DIFFICULTY SCALING ──────────────────────────────────────────────────────
static func apply_difficulty_scaling(base_value: float, difficulty: String, scaling_type: String) -> float:
	var scaling_factors: Dictionary = {
		"easy": {"timing": 1.2, "damage": 0.8, "speed": 0.9},
		"medium": {"timing": 1.0, "damage": 1.0, "speed": 1.0},
		"hard": {"timing": 0.8, "damage": 1.3, "speed": 1.1},
		"extreme": {"timing": 0.6, "damage": 1.6, "speed": 1.2}
	}
	var factors: Dictionary = scaling_factors.get(difficulty, scaling_factors["medium"])
	var multiplier: float = factors.get(scaling_type, 1.0)
	return base_value * multiplier

# ─── ASSET RESOLUTION ────────────────────────────────────────────────────────
static func _first_existing_texture_path(paths: Array[String]) -> String:
	for p in paths:
		if ResourceLoader.exists(p): return p
		var abs_path: String = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(abs_path): return p
	return ""

static func resolved_hud_top_left_panel_path() -> String: return _first_existing_texture_path(_HUD_TOP_LEFT_PANEL_PATHS)
static func resolved_hud_top_right_panel_path() -> String: return _first_existing_texture_path(_HUD_TOP_RIGHT_PANEL_PATHS)
static func resolved_hud_reward_panel_path() -> String: return _first_existing_texture_path(_HUD_REWARD_PANEL_PATHS)
static func resolved_bar_track_path() -> String: return _first_existing_texture_path(_HUD_BAR_TRACK_PATHS)
static func resolved_hud_bottom_panel_path() -> String: return _first_existing_texture_path(_HUD_BOTTOM_PANEL_PATHS)

static func hud_bottom_texture_region() -> Rect2: return _texture_region_or_full(resolved_hud_bottom_panel_path(), HUD_BOTTOM_ATLAS_REGION)
static func hud_top_left_texture_region() -> Rect2:
	var p: String = resolved_hud_top_left_panel_path()
	if p.get_file() == "combat_panel_premium_top_left.png":
		return _texture_region_or_full(p, HUD_PREMIUM_TOP_LEFT_ATLAS_REGION)
	return _texture_region_or_full(p, HUD_TOP_LEFT_ATLAS_REGION)
static func hud_top_right_texture_region() -> Rect2:
	var p: String = resolved_hud_top_right_panel_path()
	if p.get_file() == "combat_panel_premium_top_right.png":
		return _texture_region_or_full(p, HUD_PREMIUM_TOP_RIGHT_ATLAS_REGION)
	return _texture_region_or_full(p, HUD_TOP_RIGHT_ATLAS_REGION)
static func hud_reward_texture_region() -> Rect2: return _texture_region_or_full(resolved_hud_reward_panel_path(), HUD_REWARD_ATLAS_REGION)
static func hud_bar_track_texture_region() -> Rect2: return _texture_region_or_full(resolved_bar_track_path(), HUD_BAR_TRACK_ATLAS_REGION)

static func _texture_region_or_full(texture_path: String, atlas_region: Rect2) -> Rect2:
	if texture_path.is_empty(): return Rect2()
	var tex: Texture2D = load(texture_path) as Texture2D
	if tex == null: return Rect2()
	var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(tex.get_size()))
	if atlas_region.size.x <= 0.0 or atlas_region.size.y <= 0.0:
		return bounds
	var inter: Rect2 = atlas_region.intersection(bounds)
	if inter.size.x <= 0.0 or inter.size.y <= 0.0:
		return bounds
	return inter

static func compact_live_reward_position_for_viewport(vp: Vector2) -> Vector2:
	return Vector2(vp.x - HUD_OUTER_MARGIN - COMPACT_LIVE_REWARD_WIDTH, vp.y - HUD_BOTTOM_OUTER_MARGIN - HUD_BOTTOM_STRIP_HEIGHT - COMPACT_LIVE_REWARD_ABOVE_FOOTER_GAP - COMPACT_LIVE_REWARD_HEIGHT)

static func compact_live_reward_position() -> Vector2: return compact_live_reward_position_for_viewport(Vector2(HUD_VIEWPORT_WIDTH, HUD_VIEWPORT_HEIGHT))
static func compact_live_reward_size() -> Vector2: return Vector2(COMPACT_LIVE_REWARD_WIDTH, COMPACT_LIVE_REWARD_HEIGHT)
static func compact_performance_offer_size() -> Vector2: return Vector2(COMPACT_PERFORMANCE_OFFER_WIDTH, COMPACT_PERFORMANCE_OFFER_HEIGHT)

static func compact_performance_offer_global_position_for_viewport(vp: Vector2) -> Vector2:
	var sz: Vector2 = compact_performance_offer_size()
	var live_top: float = compact_live_reward_position_for_viewport(vp).y
	var stack_gap: float = maxf(COMPACT_PERFORMANCE_OFFER_ABOVE_FOOTER_GAP, 8.0)
	return Vector2(vp.x - HUD_OUTER_MARGIN - sz.x, live_top - stack_gap - sz.y)
