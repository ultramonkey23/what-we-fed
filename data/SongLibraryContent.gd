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
		"intended_role": "region_main_run",
		"intended_region_id": "pale_shelf",
		"timing_map_status": "mapped",
		"timing_map_path": "res://data/song_maps/newness_songmap.gd",
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
		"status": "live",
		"intended_role": "region_main_run",
		"intended_region_id": "drowned_cut",
		"timing_map_status": "mapped",
		"timing_map_path": "res://data/song_maps/grind_the_orbit_songmap.gd",
		"draft_analysis_path": "res://data/song_maps/drafts/grind_the_orbit_draft.json"
	},
	"boss_1": {
		"id": "boss_1",
		"display_name": "Boss 1",
		"file_path": "res://assets/audio/boss 1.wav",
		"status": "live",
		"intended_role": "boss",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": ""
	},
	"void_echo": {
		"id": "void_echo",
		"display_name": "Void Echo",
		"file_path": "res://assets/audio/void_echo.wav",
		"status": "parked",
		"intended_role": "region_main_run",
		"intended_region_id": "echoing_chasm",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/void_echo_draft.json"
	},
	"crystal_refraction": {
		"id": "crystal_refraction",
		"display_name": "Crystal Refraction",
		"file_path": "res://assets/audio/crystal_refraction.wav",
		"status": "parked",
		"intended_role": "region_main_run",
		"intended_region_id": "crystalline_spire",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/crystal_refraction_draft.json"
	},
	"marsh_whispers": {
		"id": "marsh_whispers",
		"display_name": "Marsh Whispers",
		"file_path": "res://assets/audio/marsh_whispers.wav",
		"status": "parked",
		"intended_role": "region_main_run",
		"intended_region_id": "whispering_marsh",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/marsh_whispers_draft.json"
	},
	"iron_forged": {
		"id": "iron_forged",
		"display_name": "Iron Forged",
		"file_path": "res://assets/audio/iron_forged.wav",
		"status": "parked",
		"intended_role": "region_main_run",
		"intended_region_id": "iron_boneyard",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/iron_forged_draft.json"
	},
	"dissolved_knowledge": {
		"id": "dissolved_knowledge",
		"display_name": "Dissolved Knowledge",
		"file_path": "res://assets/audio/dissolved_knowledge.wav",
		"status": "parked",
		"intended_role": "region_main_run",
		"intended_region_id": "sunken_library",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/dissolved_knowledge_draft.json"
	},
	"boss_2": {
		"id": "boss_2",
		"display_name": "Boss 2",
		"file_path": "res://assets/audio/boss_2.wav",
		"status": "parked",
		"intended_role": "boss",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/boss_2_draft.json"
	},
	"boss_3": {
		"id": "boss_3",
		"display_name": "Boss 3",
		"file_path": "res://assets/audio/boss_3.wav",
		"status": "parked",
		"intended_role": "boss",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": "res://data/song_maps/drafts/boss_3_draft.json"
	}
}

const LIVE_MAIN_RUN_SONG_ID: String = "tricky"
const LIVE_BOSS_SONG_ID: String = "boss_1"
const REGION_MAIN_RUN_SONG_IDS: Dictionary = {
	"pale_shelf": "newness",
	"drowned_cut": "grind_the_orbit",
	"echoing_chasm": "void_echo",
	"crystalline_spire": "crystal_refraction",
	"whispering_marsh": "marsh_whispers",
	"iron_boneyard": "iron_forged",
	"sunken_library": "dissolved_knowledge"
}

static func get_song(song_id: String) -> Dictionary:
	if SONGS_BY_ID.has(song_id):
		return SONGS_BY_ID[song_id].duplicate(true)
	return {}

static func get_live_main_run_song() -> Dictionary:
	return get_song(LIVE_MAIN_RUN_SONG_ID)

static func get_live_boss_song() -> Dictionary:
	return get_song(LIVE_BOSS_SONG_ID)

static func get_region_main_run_song(region_id: String) -> Dictionary:
	var resolved_song_id: String = String(REGION_MAIN_RUN_SONG_IDS.get(region_id, LIVE_MAIN_RUN_SONG_ID))
	return get_song(resolved_song_id)
