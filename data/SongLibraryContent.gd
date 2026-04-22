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
		"status": "live",
		"intended_role": "main_run_variant",
		"timing_map_status": "mapped",
		"timing_map_path": "res://data/song_maps/black_sun_rising_over_shattered_spires_songmap.gd",
		"draft_analysis_path": "res://data/song_maps/drafts/black_sun_rising_over_shattered_spires_draft.json"
	},
	"damnheavy": {
		"id": "damnheavy",
		"display_name": "DAMNHEAVY",
		"file_path": "res://assets/audio/DAMNHEAVY.wav",
		"status": "live",
		"intended_role": "main_run_variant",
		"timing_map_status": "mapped",
		"timing_map_path": "res://data/song_maps/damnheavy_songmap.gd",
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
		"timing_map_status": "mapped",
		"timing_map_path": "res://data/song_maps/boss_1_songmap.gd",
		"draft_analysis_path": "res://data/song_maps/drafts/boss_1_draft.json"
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
	},
	"drums_of_despair": {
		"id": "drums_of_despair",
		"display_name": "Drums of Despair",
		"file_path": "res://assets/audio/Drums of Despair.wav",
		"status": "parked",
		"intended_role": "main_run_variant",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": ""
	},
	"swamp_maw_engine": {
		"id": "swamp_maw_engine",
		"display_name": "Swamp Maw Engine",
		"file_path": "res://assets/audio/Swamp Maw Engine.wav",
		"status": "parked",
		"intended_role": "main_run_variant",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": ""
	},
	"swamp_maw_rites": {
		"id": "swamp_maw_rites",
		"display_name": "Swamp Maw Rites",
		"file_path": "res://assets/audio/Swamp Maw Rites.wav",
		"status": "parked",
		"intended_role": "main_run_variant",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": ""
	},
	"teeth_in_the_static": {
		"id": "teeth_in_the_static",
		"display_name": "Teeth in the Static",
		"file_path": "res://assets/audio/Teeth in the Static.wav",
		"status": "parked",
		"intended_role": "main_run_variant",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": ""
	},
	"teeth_in_the_water": {
		"id": "teeth_in_the_water",
		"display_name": "Teeth In The Water",
		"file_path": "res://assets/audio/Teeth In The Water.wav",
		"status": "parked",
		"intended_role": "main_run_variant",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": ""
	},
	"the_end": {
		"id": "the_end",
		"display_name": "The End",
		"file_path": "res://assets/audio/The end.wav",
		"status": "parked",
		"intended_role": "main_run_variant",
		"timing_map_status": "unmapped",
		"timing_map_path": "",
		"draft_analysis_path": ""
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

static func get_song_map(song_data: Dictionary):
	var timing_map_path: String = String(song_data.get("timing_map_path", ""))
	if timing_map_path.is_empty() or not ResourceLoader.exists(timing_map_path):
		return null
	return load(timing_map_path)

static func get_mapped_main_run_song_pool() -> Array:
	var pool: Array = []
	for song_id in SONGS_BY_ID.keys():
		var song: Dictionary = Dictionary(SONGS_BY_ID[song_id])
		var role: String = String(song.get("intended_role", ""))
		if String(song.get("status", "")) != "live":
			continue
		if role == "boss":
			continue
		if String(song.get("timing_map_status", "")) != "mapped":
			continue
		if get_song_map(song) == null:
			continue
		pool.append(song.duplicate(true))
	return pool

static func build_randomized_regular_level_playlist(level_count: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = get_mapped_main_run_song_pool()
	if pool.is_empty():
		return [get_live_main_run_song()]

	var shuffled: Array = pool.duplicate(true)
	for i in range(shuffled.size() - 1, 0, -1):
		var swap_idx: int = rng.randi_range(0, i)
		var tmp: Variant = shuffled[i]
		shuffled[i] = shuffled[swap_idx]
		shuffled[swap_idx] = tmp

	var playlist: Array = []
	for i in range(level_count):
		if shuffled.is_empty():
			shuffled = pool.duplicate(true)
		playlist.append(Dictionary(shuffled[i % shuffled.size()]).duplicate(true))
	return playlist
