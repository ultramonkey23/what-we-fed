extends RefCounted

# Phase 2A prototype: bonded creatures act as Vessel Class Modifiers.
# Pure logic only — no scene access, no signals, no side effects.
# Caller owns damage application and HUD feedback.

const CLEAVE_DAMAGE_FRACTION: float = 0.35
const ASHCLAW_ID: String = "ashclaw"
const ASHCLAW_LABEL: String = "ASHCLAW CLEAVE"
const ASHCLAW_EFFECT_ID: String = "ashclaw_cleave"
const ASHCLAW_COLOR: Color = Color(0.92, 0.52, 0.22, 1.0)
const ASHCLAW_SILHOUETTE_COLOR: Color = Color(0.92, 0.52, 0.22, 0.30)
const ASHCLAW_LABEL_DURATION: float = 0.28

# Lane enum (mirrors PlayerCombat.gd:52-55): N=0, S=1, E=2, W=3.
# N/S share the vertical axis; E/W share the horizontal axis.
# Cleave targets the perpendicular axis, giving two adjacent lanes per hit.
const ADJACENT_LANES_BY_LANE: Dictionary = {
	0: [2, 3],
	1: [2, 3],
	2: [0, 1],
	3: [0, 1],
}

static func build_perfect_plan(species_id: String, origin_lane: int, origin_damage: float) -> Dictionary:
	if species_id != ASHCLAW_ID:
		return {}
	var targets: Array = ADJACENT_LANES_BY_LANE.get(origin_lane, [])
	if targets.is_empty():
		return {}
	var cleave_damage: float = max(1.0, origin_damage * CLEAVE_DAMAGE_FRACTION)
	return {
		"effect_id": ASHCLAW_EFFECT_ID,
		"label": ASHCLAW_LABEL,
		"color": ASHCLAW_COLOR,
		"label_duration": ASHCLAW_LABEL_DURATION,
		"targets": targets,
		"damage": cleave_damage,
		"silhouette_color": ASHCLAW_SILHOUETTE_COLOR,
	}
