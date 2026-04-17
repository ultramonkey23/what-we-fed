extends RefCounted

# Live audio truth for the current vertical slice.
# Runtime code should read active track paths from here.
# SongLibraryContent carries the wider repo inventory, including parked tracks.

const SONG_LIBRARY = preload("res://data/SongLibraryContent.gd")

const MAIN_RUN_TRACK_PATH: String = SONG_LIBRARY.SONGS_BY_ID[SONG_LIBRARY.LIVE_MAIN_RUN_SONG_ID]["file_path"]
const BOSS_TRACK_PATH: String = SONG_LIBRARY.SONGS_BY_ID[SONG_LIBRARY.LIVE_BOSS_SONG_ID]["file_path"]
