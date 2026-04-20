extends RefCounted

# Lightweight encounter-identity metadata for the live song-run.
# This is not a new combat ruleset. It only shapes how the current runtime
# presents phases and which empty lanes it prefers to refill first.

const REGION_IDENTITIES: Dictionary = {
	"feeding_hollow": {
		"pressure_name": "Predation",
		"phase_styles": {
			"opening": {"tag": "STALK", "spawn_mode": "track_player"},
			"rising": {"tag": "PRESS", "spawn_mode": "center_bias"},
			"chorus": {"tag": "DEVOUR", "spawn_mode": "collapse"},
			"breakdown": {"tag": "RECOIL", "spawn_mode": "track_player"},
			"final": {"tag": "OVERRUN", "spawn_mode": "collapse"}
		},
		"escalation_rules": {
			"respawn_delay": 0.35,
			"pressure_shaping": "aggressive", # Kills trigger immediate pressure in other lanes
			"surge_on_phase_start": true
		}
	},
	"pale_shelf": {
		"pressure_name": "Exposure",
		"phase_styles": {
			"opening": {"tag": "EXPOSE", "spawn_mode": "edge_bias"},
			"rising": {"tag": "SHEAR", "spawn_mode": "flank_player"},
			"chorus": {"tag": "STRIP", "spawn_mode": "flank_player"},
			"breakdown": {"tag": "COLD", "spawn_mode": "edge_bias"},
			"final": {"tag": "CLAIM", "spawn_mode": "flank_player"}
		},
		"escalation_rules": {
			"respawn_delay": 1.20, # Slower, more deliberate
			"pressure_shaping": "attritional", # Fewer enemies, but each is higher grade/HP
			"surge_on_phase_start": false
		}
	},
	"drowned_cut": {
		"pressure_name": "Resonance",
		"phase_styles": {
			"opening": {"tag": "ECHO", "spawn_mode": "spread"},
			"rising": {"tag": "SWELL", "spawn_mode": "spread"},
			"chorus": {"tag": "RESONATE", "spawn_mode": "spread"},
			"breakdown": {"tag": "DRAG", "spawn_mode": "edge_bias"},
			"final": {"tag": "SURGE", "spawn_mode": "spread"}
		},
		"escalation_rules": {
			"respawn_delay": 0.15, # Fast, volume-based
			"pressure_shaping": "resonant", # Kills trigger immediate same-lane replacement
			"surge_on_phase_start": true
		}
	}
}


static func get_region_identity(region_id: String) -> Dictionary:
	if REGION_IDENTITIES.has(region_id):
		return REGION_IDENTITIES[region_id].duplicate(true)
	return REGION_IDENTITIES["feeding_hollow"].duplicate(true)


static func get_phase_style(region_id: String, phase_id: String) -> Dictionary:
	var identity: Dictionary = get_region_identity(region_id)
	var styles: Dictionary = identity.get("phase_styles", {})
	if styles.has(phase_id):
		return styles[phase_id].duplicate(true)
	return {}


static func get_escalation_rules(region_id: String) -> Dictionary:
	var identity: Dictionary = get_region_identity(region_id)
	return identity.get("escalation_rules", {
		"respawn_delay": 0.40,
		"pressure_shaping": "default",
		"surge_on_phase_start": true
	}).duplicate(true)
