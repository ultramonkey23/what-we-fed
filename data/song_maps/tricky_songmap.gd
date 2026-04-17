extends RefCounted

const AUDIO_CONTENT = preload("res://data/AudioContent.gd")

# Song map for the current live main-run track.
# Additional songs should stay parked until they have their own deliberate map.
# Section timings use start_fraction (0.0–1.0 of total song duration) so this
# map adapts to the actual WAV length at runtime without manual time-coding.
#
# SongConductor multiplies start_fraction by the stream's get_length() at startup
# to produce absolute trigger times. Tune the fractions after hearing the track
# in context — they are the primary authoring knob for music-driven pressure.
#
# spawn_interval_mult: multiplier applied to the region's phase cycle_interval.
#   1.0  = unchanged  |  0.80 = 20% faster  |  1.20 = 20% slower
# intensity: 0.0–1.0 advisory value — exposed on SongConductor for any system
#   that wants to read current musical pressure (e.g. visual intensity pulses).

const SONG_PATH: String = AUDIO_CONTENT.MAIN_RUN_TRACK_PATH

# BPM of the track — used by SongConductor's beat-quality system to evaluate
# whether a player action landed on-beat (perfect / good / off).
# 128 BPM = one beat every ~0.469 s. Tune this to match tricky.wav's actual tempo.
const BPM: float = 128.0

# Boss / final movement triggers at this fraction of total song length.
# 0.88 = 88% through — leaves the final 12% for the boss encounter.
# Adjust if the track has a notable climax point at a different position.
const FINAL_MOVEMENT_FRACTION: float = 0.88

# Five sections matching the phase ids in RegionSongContent so CombatScene can
# look them up by id and drive _enter_song_phase() from the conductor signal.
const SECTIONS: Array = [
	{
		"id": "opening",
		"label": "THE SONG BEGINS",
		"start_fraction": 0.00,
		"intensity": 0.18,
		"spawn_interval_mult": 1.00
	},
	{
		"id": "rising",
		"label": "RISING VERSE",
		"start_fraction": 0.19,
		"intensity": 0.44,
		"spawn_interval_mult": 0.96
	},
	{
		"id": "chorus",
		"label": "FIRST CHORUS",
		"start_fraction": 0.44,
		"intensity": 0.72,
		"spawn_interval_mult": 0.84
	},
	{
		"id": "breakdown",
		"label": "BREAKDOWN",
		"start_fraction": 0.63,
		"intensity": 0.36,
		"spawn_interval_mult": 1.12
	},
	{
		"id": "final",
		"label": "FINAL CHORUS",
		"start_fraction": 0.75,
		"intensity": 0.92,
		"spawn_interval_mult": 0.78
	}
]
