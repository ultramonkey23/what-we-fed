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
# Shipped combat panels live under res://assets/ui/combat/panels/ (names match *.import source_file).
const _HUD_TOP_LEFT_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_top_left.png.png",
	"res://assets/ui/combat/panels/combat_panel_top_left.png",
	"res://assets/ui/combat/panels/combat_panel_premium_top_left.png",
]
const _HUD_TOP_RIGHT_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_top_right.png.png",
	"res://assets/ui/combat/panels/combat_panel_top_right.png",
	"res://assets/ui/combat/panels/combat_panel_premium_top_right.png",
]
const _HUD_REWARD_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_reward_claim.png.png",
	"res://assets/ui/combat/panels/combat_panel_reward_claim.png",
	"res://assets/ui/combat/panels/combat_panel_premium_reward.png",
]
const _HUD_BOTTOM_PANEL_PATHS: Array[String] = [
	"res://assets/ui/combat/panels/combat_panel_bottom.png.png",
	"res://assets/ui/combat/panels/combat_panel_bottom.png",
]
## Atlas slice in **texture pixel space** (Rect2() = use full image). Set when a sheet packs multiple panels.
const HUD_TOP_LEFT_ATLAS_REGION: Rect2 = Rect2()
const HUD_TOP_RIGHT_ATLAS_REGION: Rect2 = Rect2()
const HUD_REWARD_ATLAS_REGION: Rect2 = Rect2()
const HUD_BOTTOM_ATLAS_REGION: Rect2 = Rect2()
## Nine-slice expand margins (texture px): left, top, right, bottom. Keep ZERO for full-bleed panels; set when art is a 9-slice sheet.
const HUD_TOP_LEFT_NINE_SLICE: Vector4 = Vector4.ZERO
const HUD_TOP_RIGHT_NINE_SLICE: Vector4 = Vector4.ZERO
const HUD_REWARD_NINE_SLICE: Vector4 = Vector4.ZERO
## Optional inset for PanelContainer content (screen px).
const HUD_TOP_LEFT_CONTENT_MARGIN: Vector4 = Vector4.ZERO
const HUD_TOP_RIGHT_CONTENT_MARGIN: Vector4 = Vector4.ZERO
const HUD_REWARD_CONTENT_MARGIN: Vector4 = Vector4.ZERO
const HUD_BOTTOM_NINE_SLICE: Vector4 = Vector4.ZERO
const HUD_BOTTOM_CONTENT_MARGIN: Vector4 = Vector4.ZERO
## Progress bar track (shared underlay for HP / stamina when present).
const _HUD_BAR_TRACK_PATHS: Array[String] = [
	"res://assets/ui/combat/bars/combat_bar_track.png",
	"res://assets/ui/combat/bars/combat_bar_track.png.png",
	"res://assets/ui/combat/bars/combat_bar_hp_track.png",
	"res://assets/ui/combat/panels/combat_bar_track.png",
]
const HUD_BAR_TRACK_ATLAS_REGION: Rect2 = Rect2()
const HUD_BAR_TRACK_NINE_SLICE: Vector4 = Vector4(6.0, 4.0, 6.0, 4.0)


static func _first_existing_texture_path(paths: Array[String]) -> String:
	for p in paths:
		if ResourceLoader.exists(p):
			return p
		var abs_path: String = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(abs_path):
			return p
	return ""


static func resolved_hud_top_left_panel_path() -> String:
	return _first_existing_texture_path(_HUD_TOP_LEFT_PANEL_PATHS)


static func resolved_hud_top_right_panel_path() -> String:
	return _first_existing_texture_path(_HUD_TOP_RIGHT_PANEL_PATHS)


static func resolved_hud_reward_panel_path() -> String:
	return _first_existing_texture_path(_HUD_REWARD_PANEL_PATHS)


static func resolved_bar_track_path() -> String:
	return _first_existing_texture_path(_HUD_BAR_TRACK_PATHS)


static func resolved_hud_bottom_panel_path() -> String:
	return _first_existing_texture_path(_HUD_BOTTOM_PANEL_PATHS)


static func hud_bottom_texture_region() -> Rect2:
	return _texture_region_or_full(resolved_hud_bottom_panel_path(), HUD_BOTTOM_ATLAS_REGION)


static func hud_top_left_texture_region() -> Rect2:
	return _texture_region_or_full(resolved_hud_top_left_panel_path(), HUD_TOP_LEFT_ATLAS_REGION)


static func hud_top_right_texture_region() -> Rect2:
	return _texture_region_or_full(resolved_hud_top_right_panel_path(), HUD_TOP_RIGHT_ATLAS_REGION)


static func hud_reward_texture_region() -> Rect2:
	return _texture_region_or_full(resolved_hud_reward_panel_path(), HUD_REWARD_ATLAS_REGION)


static func hud_bar_track_texture_region() -> Rect2:
	var p: String = resolved_bar_track_path()
	return _texture_region_or_full(p, HUD_BAR_TRACK_ATLAS_REGION)


static func _texture_region_or_full(texture_path: String, atlas_region: Rect2) -> Rect2:
	if texture_path.is_empty():
		return Rect2()
	if atlas_region.size.x <= 0.0 or atlas_region.size.y <= 0.0:
		return Rect2()
	var tex: Texture2D = load(texture_path) as Texture2D
	if tex == null:
		return Rect2()
	var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(tex.get_size()))
	var inter: Rect2 = atlas_region.intersection(bounds)
	if inter.size.x <= 0.0 or inter.size.y <= 0.0:
		return Rect2()
	return inter

## Combat HUD grid @ 1280×720: symmetric top corners, one right rail, bottom strip.
const HUD_VIEWPORT_WIDTH: float = 1280.0
const HUD_OUTER_MARGIN: float = 12.0
const HUD_TOP_BAND_Y: float = 6.0
const HUD_TOP_BAND_HEIGHT: float = 96.0
const HUD_TOP_PANEL_WIDTH: float = 300.0
const HUD_GAP_BELOW_TOP_BAND: float = 10.0
const HUD_RIGHT_RAIL_WIDTH: float = 108.0
const HUD_BOTTOM_STRIP_HEIGHT: float = 42.0
const HUD_BOTTOM_OUTER_MARGIN: float = 10.0
## Boss readout sits in the lane between top corner panels (not under them).
const HUD_BOSS_BLOCK_WIDTH: float = 488.0
const HUD_BOSS_BLOCK_X: float = (HUD_VIEWPORT_WIDTH - HUD_BOSS_BLOCK_WIDTH) * 0.5
const HUD_BOSS_BLOCK_Y: float = HUD_TOP_BAND_Y + HUD_TOP_BAND_HEIGHT + 4.0

const RIGHT_HUD_STACK_X: float = HUD_VIEWPORT_WIDTH - HUD_OUTER_MARGIN - HUD_RIGHT_RAIL_WIDTH
const RIGHT_HUD_STACK_WIDTH: float = HUD_RIGHT_RAIL_WIDTH
const RIGHT_HUD_LABEL_X: float = RIGHT_HUD_STACK_X + 8.0
const RIGHT_HUD_VALUE_X: float = RIGHT_HUD_STACK_X + 56.0
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
