extends RefCounted

# Draft-backed map promoted into the runtime song pool so runs can pull from a
# wider soundtrack set without falling back to unmapped combat timing.

const SONG_PATH: String = "res://assets/audio/Black sun rising over shattered spires.wav"
const BPM: float = 159.0
const FINAL_MOVEMENT_FRACTION: float = 0.9167
const BASS_ACCENT_THRESHOLD: float = 0.58

const SECTIONS: Array = [
	{
		"id": "opening",
		"label": "ASH BEFORE DAWN",
		"start_fraction": 0.00,
		"intensity": 0.71,
		"spawn_interval_mult": 0.88
	},
	{
		"id": "rising",
		"label": "SPIRES AWAKEN",
		"start_fraction": 0.25,
		"intensity": 0.88,
		"spawn_interval_mult": 0.82
	},
	{
		"id": "chorus",
		"label": "BLACK SUN ASCENDS",
		"start_fraction": 0.50,
		"intensity": 0.73,
		"spawn_interval_mult": 0.87
	},
	{
		"id": "breakdown",
		"label": "STONE REMEMBERS",
		"start_fraction": 0.5833,
		"intensity": 0.82,
		"spawn_interval_mult": 0.84
	},
	{
		"id": "final",
		"label": "THE SKY SPLITS",
		"start_fraction": 0.75,
		"intensity": 0.87,
		"spawn_interval_mult": 0.82
	}
]
