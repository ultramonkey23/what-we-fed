extends RefCounted

# Boss 1 climax map.
# This timeline is used to drive boss decree shifts from authored song sections.
# Values remain intentionally conservative until a dedicated audio-authorship pass.

const SONG_PATH: String = "res://assets/audio/boss 1.wav"
const BPM: float = 132.0
const FINAL_MOVEMENT_FRACTION: float = 0.98

const SECTIONS: Array = [
	{
		"id": "opening",
		"label": "SOVEREIGN AWAKENING",
		"start_fraction": 0.00,
		"intensity": 0.30,
		"spawn_interval_mult": 1.00
	},
	{
		"id": "rising",
		"label": "LAW TIGHTENS",
		"start_fraction": 0.20,
		"intensity": 0.52,
		"spawn_interval_mult": 0.96
	},
	{
		"id": "chorus",
		"label": "DECREE I",
		"start_fraction": 0.44,
		"intensity": 0.74,
		"spawn_interval_mult": 0.90
	},
	{
		"id": "breakdown",
		"label": "BREATH BEFORE BREAK",
		"start_fraction": 0.66,
		"intensity": 0.58,
		"spawn_interval_mult": 1.04
	},
	{
		"id": "final",
		"label": "DECREE II",
		"start_fraction": 0.82,
		"intensity": 0.96,
		"spawn_interval_mult": 0.84
	}
]
