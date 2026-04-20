extends RefCounted

# Pale Shelf live song map.
# Derived from the existing draft analysis, then tightened into the current
# five-phase run structure so the route gains a longer, authored arc without
# touching the boss track or the other route identities.

const SONG_PATH: String = "res://assets/audio/newness.wav"

# Draft tempo confidence is low; this remains approximate until a dedicated
# audio-authorship pass validates the song more deeply.
const BPM: float = 74.0

# Leaves a short end stretch for the unchanged boss handoff.
const FINAL_MOVEMENT_FRACTION: float = 0.90

const SECTIONS: Array = [
	{
		"id": "opening",
		"label": "NOTHING HIDES",
		"start_fraction": 0.00,
		"intensity": 0.30,
		"spawn_interval_mult": 1.04
	},
	{
		"id": "rising",
		"label": "THE SHELF WATCHES",
		"start_fraction": 0.25,
		"intensity": 0.54,
		"spawn_interval_mult": 0.98
	},
	{
		"id": "chorus",
		"label": "FULLY EXPOSED",
		"start_fraction": 0.42,
		"intensity": 0.92,
		"spawn_interval_mult": 0.84
	},
	{
		"id": "breakdown",
		"label": "COLD BREATH",
		"start_fraction": 0.62,
		"intensity": 0.58,
		"spawn_interval_mult": 1.06
	},
	{
		"id": "final",
		"label": "THE SHELF CLAIMS ALL",
		"start_fraction": 0.78,
		"intensity": 0.88,
		"spawn_interval_mult": 0.86
	}
]
