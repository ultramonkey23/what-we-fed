extends RefCounted

# Run Growth Content - Definitions for growth outcomes and reward lanes
# This follows the Management-Rich mandate for strategic depth.

const EXP_TO_LEVEL_BASE: float = 100.0
const EXP_TO_LEVEL_SCALING: float = 1.15

const DNA_EXP_PER_POINT: float = 2.0
const DNA_BOND_TENDENCY_PER_POINT: float = 0.5
const DNA_BOND_SUPPORT_CHARGE_PER_POINT: float = 1.0

const SUPPORT_MAX: float = 100.0
const CHARGE_TIMED_ATTACK: float = 1.5
const CHARGE_ENEMY_DEFEAT: float = 8.0
const CHARGE_MASTERY_ACTION: float = 12.0

const GORGE_MARK_BONUS_CHARGE: float = 15.0

const EXP_KILL: float = 12.0
const EXP_TIMED_ATTACK: float = 2.0
const EXP_STYLE_MILESTONE: float = 25.0
const EXP_ULTIMATE: float = 40.0

# Tendency Thresholds
const TENDENCY_LEVEL_THRESHOLD: float = 100.0

const LEVEL_THRESHOLDS: Array[float] = [40.0, 92.0, 150.0]

# Tendency Level Up Outcomes
# Maps tendency ID -> data for level up presentation and bonuses
const TENDENCY_LEVEL_UP_OUTCOMES: Dictionary = {
	"aggression": {
		"title": "AGGRESSION SURGE",
		"readout_label": "Ravage active",
		"effects": [
			{"type": "base_damage_flat", "value": 2.0},
			{"type": "surge_aggression", "value": 1.0} # Next hit does bonus damage
		]
	},
	"cadence": {
		"title": "CADENCE SURGE",
		"readout_label": "Flow active",
		"effects": [
			{"type": "good_timed_bonus_damage_per_level", "value": 0.05},
			{"type": "surge_cadence", "value": 1.0} # Next timed hit has doubled mult
		]
	},
	"guard": {
		"title": "GUARD SURGE",
		"readout_label": "Shelter active",
		"effects": [
			{"type": "defense_flat", "value": 1.0},
			{"type": "surge_guard", "value": 1.0} # Next hit taken reduced by 50%
		]
	},
	"bond": {
		"title": "BOND SURGE",
		"readout_label": "Sync active",
		"effects": [
			{"type": "support_charge_now", "value": 30.0},
			{"type": "support_charge_gain_mult_per_level", "value": 0.12},
			{"type": "surge_bond", "value": 1.0} # Next support trigger has doubled effectiveness
		]
	}
}
