extends RefCounted

# Draft-backed map promoted into the runtime song pool so level music can rotate
# between more combat-safe tracks on each run.

const SONG_PATH: String = "res://assets/audio/DAMNHEAVY.wav"
const BPM: float = 180.0
const FINAL_MOVEMENT_FRACTION: float = 0.875
const BASS_ACCENT_THRESHOLD: float = 0.54

const SECTIONS: Array = [
	{
		"id": "opening",
		"label": "WEIGHT GATHERS",
		"start_fraction": 0.00,
		"intensity": 0.64,
		"spawn_interval_mult": 0.90
	},
	{
		"id": "rising",
		"label": "PRESSURE BUILDS",
		"start_fraction": 0.125,
		"intensity": 0.81,
		"spawn_interval_mult": 0.84
	},
	{
		"id": "chorus",
		"label": "DAMNHEAVY",
		"start_fraction": 0.375,
		"intensity": 1.00,
		"spawn_interval_mult": 0.78
	},
	{
		"id": "breakdown",
		"label": "THE FLOOR GIVES",
		"start_fraction": 0.625,
		"intensity": 0.98,
		"spawn_interval_mult": 0.79
	},
	{
		"id": "final",
		"label": "NO AIR LEFT",
		"start_fraction": 0.75,
		"intensity": 0.83,
		"spawn_interval_mult": 0.84
	}
]
