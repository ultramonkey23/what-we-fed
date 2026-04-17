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
