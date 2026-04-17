extends RefCounted

# Small transition-edge helper for CombatScene.
# Owns repeated side effects that are easy to leak across overlays or handoffs:
# mastery cache clearing, lane-manager stop/song-mode restoration, and audio pause truth.


static func prepare_song_reward_pause(lane_manager: Node, song_conductor: Node, clear_mastery: Callable) -> void:
	clear_mastery.call()
	lane_manager.stop()
	lane_manager.set_song_mode_enabled(true)
	if song_conductor != null and is_instance_valid(song_conductor):
		song_conductor.pause()


static func resume_song_reward(lane_manager: Node, song_conductor: Node, player_combat: Node) -> void:
	lane_manager.set_song_mode_enabled(true)
	if song_conductor != null and is_instance_valid(song_conductor):
		song_conductor.resume()
	if player_combat != null and player_combat.has_method("set_combat_enabled"):
		player_combat.set_combat_enabled(true)


static func prepare_growth_pause(clear_mastery: Callable, set_growth_audio_paused: Callable) -> void:
	clear_mastery.call()
	set_growth_audio_paused.call(true)
	Engine.time_scale = 0.0


static func restore_growth_pause(base_time_scale: float, set_growth_audio_paused: Callable) -> void:
	Engine.time_scale = base_time_scale
	set_growth_audio_paused.call(false)


static func prepare_boss_handoff(lane_manager: Node, clear_mastery: Callable, stop_song_conductor: Callable) -> void:
	clear_mastery.call()
	lane_manager.stop()
	lane_manager.set_song_mode_enabled(false)
	stop_song_conductor.call()


static func prepare_run_restart(stop_song_conductor: Callable, stop_boss_music: Callable, reset_growth_overlay_state: Callable, clear_mastery: Callable) -> void:
	stop_song_conductor.call()
	stop_boss_music.call()
	reset_growth_overlay_state.call()
	clear_mastery.call()
