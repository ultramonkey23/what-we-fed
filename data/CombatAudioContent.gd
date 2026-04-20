extends RefCounted

# The Combat Audio Registry (Batch 1 Intake)
# Maps sfx_cue strings from CombatImpactFeedback.gd to assets/audio/sfx/combat/*.wav

const SFX_MAP: Dictionary = {
	"timed_hit": "res://assets/audio/sfx/combat/hit_good.wav",
	"perfect_timed_hit": "res://assets/audio/sfx/combat/hit_perfect.wav",
	"parry": "res://assets/audio/sfx/combat/parry_good.wav",
	"perfect_parry": "res://assets/audio/sfx/combat/parry_perfect.wav",
	"enemy_hit": "res://assets/audio/sfx/combat/enemy_hit.wav",
	"heavy_enemy_hit": "res://assets/audio/sfx/combat/enemy_hit_heavy.wav",
	"boss_hit": "res://assets/audio/sfx/combat/boss_hit.wav"
}

static func get_sfx_path(cue_id: String) -> String:
	if SFX_MAP.has(cue_id):
		return String(SFX_MAP[cue_id])
	return ""
