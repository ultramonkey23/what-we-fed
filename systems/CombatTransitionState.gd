extends RefCounted

# Small transition-edge helper for CombatScene.
# Owns repeated side effects that are easy to leak across boss handoffs or run restarts:
# mastery cache clearing and active audio teardown.


static func prepare_boss_handoff(lane_manager: Node, clear_mastery: Callable, stop_song_conductor: Callable) -> void:
	clear_mastery.call()
	lane_manager.stop()
	lane_manager.set_song_mode_enabled(false)
	stop_song_conductor.call()


static func prepare_run_restart(stop_song_conductor: Callable, stop_boss_music: Callable, clear_mastery: Callable) -> void:
	stop_song_conductor.call()
	stop_boss_music.call()
	clear_mastery.call()
