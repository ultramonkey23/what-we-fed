extends RefCounted

# ─── TIMING RINGS ────────────────────────────────────────────────────────────
const RING_OUTER_RADIUS: float = 30.0 # SUCCESS: matches Projectile.ATTACK_GOOD_MIN (0.96) @ 1280 width
const RING_PERFECT_RADIUS: float = 15.0 # PERFECT: matches Projectile.ATTACK_PERFECT_MIN (0.98) @ 1280 width
const RING_POINT_COUNT: int = 32
const EDGE_STATE_WIDTH: float = 0.016

# ─── LANE VISUALS ────────────────────────────────────────────────────────────
const LANE_BAND_HEIGHT: float = 36.0
const LANE_IDLE_ALPHA: float = 0.062
const LANE_THREAT_ALPHA: float = 0.14
const LANE_CRITICAL_ALPHA: float = 0.24
const LANE_THREAT_FOCUS_ALPHA: float = 0.32
const LANE_IMMINENT_FOCUS_ALPHA: float = 0.64

const FOCAL_MARKER_WIDTH: float = 2.0
const FOCAL_MARKER_SIZE: Vector2 = Vector2(48.0, 72.0)
const FOCAL_MARKER_COLOR: Color = Color(0.92, 0.88, 0.76, 0.24)
const FOCAL_MARKER_ACTIVE_ALPHA: float = 0.72

# ─── VISUAL DURATIONS & TIMINGS ──────────────────────────────────────────────
const COMBAT_FEEDBACK_MIN_LIFETIME: float = 0.62
const COMBAT_FEEDBACK_FADE_TIME: float = 0.24
const BEAT_FEEDBACK_HOLD_TIME: float = 0.42
const BEAT_FEEDBACK_FADE_TIME: float = 0.24
const PERFORMANCE_PROC_CHIP_VISIBLE_TIME: float = 1.8
const PERFORMANCE_PROC_CHIP_FADE_TIME: float = 1.2
const TENDENCY_ANCHOR_HOLD_TIME: float = 2.3
const TENDENCY_ANCHOR_FADE_TIME: float = 0.26
const DAMAGE_NUMBER_FLOAT_TIME: float = 0.85

# ─── HUD LAYOUT & ASSETS ─────────────────────────────────────────────────────
const COMBAT_PANEL_TOP_LEFT_PATH: String = "res://assets/ui/combat/panels/combat_panel_top_left.png.png"
const COMBAT_PANEL_TOP_RIGHT_PATH: String = "res://assets/ui/combat/panels/combat_panel_top_right.png.png"
const COMBAT_PANEL_REWARD_CLAIM_PATH: String = "res://assets/ui/combat/panels/combat_panel_reward_claim.png.png"
const COMBAT_PANEL_TOP_LEFT_REGION: Rect2 = Rect2(101.0, 272.0, 1331.0, 372.0)
const COMBAT_PANEL_TOP_RIGHT_REGION: Rect2 = Rect2(138.0, 262.0, 1290.0, 360.0)
const COMBAT_PANEL_REWARD_CLAIM_REGION: Rect2 = Rect2(82.0, 160.0, 1387.0, 430.0)

const RIGHT_HUD_STACK_X: float = 1172.0
const RIGHT_HUD_STACK_WIDTH: float = 96.0
const RIGHT_HUD_LABEL_X: float = 1180.0
const RIGHT_HUD_VALUE_X: float = 1238.0
const RIGHT_HUD_ROW_WIDTH: float = 24.0
const RIGHT_HUD_TEXT_WIDTH: float = 80.0

const COMPACT_LIVE_REWARD_POS: Vector2 = Vector2(520.0, 590.0)
const COMPACT_LIVE_REWARD_SIZE: Vector2 = Vector2(240.0, 62.0)
const COMPACT_PERFORMANCE_OFFER_POS: Vector2 = Vector2(508.0, 586.0)
const COMPACT_PERFORMANCE_OFFER_SIZE: Vector2 = Vector2(264.0, 58.0)

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
	"res://assets/backgrounds/combat/cbg1.png",
	"res://assets/backgrounds/combat/cbg2.png",
	"res://assets/backgrounds/combat/cbg3.png",
]
const COMBAT_BG_MODULATE: Color = Color(0.78, 0.78, 0.78, 1.0)
