extends RefCounted

# Live audio truth for the current vertical slice.
# Runtime code should read active track paths from here.
# SongLibraryContent carries the wider repo inventory, including parked tracks.

const SONG_LIBRARY = preload("res://data/SongLibraryContent.gd")

const MAIN_RUN_TRACK_PATH: String = SONG_LIBRARY.SONGS_BY_ID[SONG_LIBRARY.LIVE_MAIN_RUN_SONG_ID]["file_path"]
const BOSS_TRACK_PATH: String = SONG_LIBRARY.SONGS_BY_ID[SONG_LIBRARY.LIVE_BOSS_SONG_ID]["file_path"]

static func get_region_main_run_song(region_id: String) -> Dictionary:
	return SONG_LIBRARY.get_region_main_run_song(region_id)

static func get_song_map(song_data: Dictionary):
	var timing_map_path: String = String(song_data.get("timing_map_path", ""))
	if timing_map_path.is_empty() or not ResourceLoader.exists(timing_map_path):
		return preload("res://data/song_maps/tricky_songmap.gd")
	return load(timing_map_path)

static func get_region_song_map(region_id: String):
	var song: Dictionary = get_region_main_run_song(region_id)
	return get_song_map(song)
