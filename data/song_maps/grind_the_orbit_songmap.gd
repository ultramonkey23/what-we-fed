extends RefCounted

# Drowned Cut live song map.
# Built as a bounded authored pass from the existing draft analysis so one region
# gets a distinct runtime cadence without broad soundtrack churn.

const SONG_PATH: String = "res://assets/audio/Grind the Orbit.wav"

# Draft BPM confidence is low, so this remains approximate until a fuller music pass.
# The region routing will fall back to the default track if runtime validation regresses.
const BPM: float = 180.0

# Leaves a readable late-song boss handoff without forcing the final movement too early.
const FINAL_MOVEMENT_FRACTION: float = 0.88

const SECTIONS: Array = [
	{
		"id": "opening",
		"label": "THE WATER STIRS",
		"start_fraction": 0.00,
		"intensity": 0.28,
		"spawn_interval_mult": 1.00
	},
	{
		"id": "rising",
		"label": "THE WEIGHT RETURNS",
		"start_fraction": 0.14,
		"intensity": 0.56,
		"spawn_interval_mult": 0.94
	},
	{
		"id": "chorus",
		"label": "DEEP RESONANCE",
		"start_fraction": 0.33,
		"intensity": 0.82,
		"spawn_interval_mult": 0.82
	},
	{
		"id": "breakdown",
		"label": "STILL WATER",
		"start_fraction": 0.56,
		"intensity": 0.42,
		"spawn_interval_mult": 1.08
	},
	{
		"id": "final",
		"label": "THE CUT OPENS",
		"start_fraction": 0.69,
		"intensity": 0.94,
		"spawn_interval_mult": 0.78
	}
]
