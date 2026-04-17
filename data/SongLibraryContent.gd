extends RefCounted

# Source of truth for song assets currently present in the repo.
# Keep live runtime assignments explicit here and stage all other tracks as parked
# until they have a deliberate gameplay role and, if needed, a timing map.
# Draft waveform analysis outputs live separately under data/song_maps/drafts/.

const SONGS_BY_ID: Dictionary = {
	"tricky": {
		"id": "tricky",
		"display_name": "Tricky",
		"file_path": "res://assets/audio/tricky.wav",
		"status": "live",
		"intended_role": "main_run",
		"timing_map_status": "mapped",
		"timing_map_path": "res://data/song_maps/tricky_songmap.gd",
		"draft_analysis_path": "res://data/song_maps/drafts/tricky_draft.json"
	},
	"newness": {
		"id": "newness",
		"display_name": "Newness",
		"file_path": "res://assets/audio/newness.wav",
		"status": "live",
		"intended_role": "boss",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/newness_draft.json"
	},
	"black_sun_rising_over_shattered_spires": {
		"id": "black_sun_rising_over_shattered_spires",
		"display_name": "Black Sun Rising Over Shattered Spires",
		"file_path": "res://assets/audio/Black sun rising over shattered spires.wav",
		"status": "parked",
		"intended_role": "unknown",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/black_sun_rising_over_shattered_spires_draft.json"
	},
	"damnheavy": {
		"id": "damnheavy",
		"display_name": "DAMNHEAVY",
		"file_path": "res://assets/audio/DAMNHEAVY.wav",
		"status": "parked",
		"intended_role": "unknown",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/damnheavy_draft.json"
	},
	"grind_the_orbit": {
		"id": "grind_the_orbit",
		"display_name": "Grind the Orbit",
		"file_path": "res://assets/audio/Grind the Orbit.wav",
		"status": "parked",
		"intended_role": "unknown",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/grind_the_orbit_draft.json"
	}
}

const LIVE_MAIN_RUN_SONG_ID: String = "tricky"
const LIVE_BOSS_SONG_ID: String = "newness"

static func get_song(song_id: String) -> Dictionary:
	if SONGS_BY_ID.has(song_id):
		return SONGS_BY_ID[song_id].duplicate(true)
	return {}

static func get_live_main_run_song() -> Dictionary:
	return get_song(LIVE_MAIN_RUN_SONG_ID)

static func get_live_boss_song() -> Dictionary:
	return get_song(LIVE_BOSS_SONG_ID)
