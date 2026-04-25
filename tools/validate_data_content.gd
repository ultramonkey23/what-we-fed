extends SceneTree

# DATA CONTENT VALIDATOR (E002)
# Headless script to verify the integrity of the data/ directory.
# Checks:
# - Unique IDs in constant dictionaries.
# - Resource paths (res://) actually exist.
# - Basic schema sanity for known content files.

var error_count := 0

func _init() -> void:
	print("--- DATA CONTENT VALIDATION START ---")
	
	validate_combat_content()
	validate_performance_reward_content()
	validate_route_content()
	validate_audio_content()
	validate_song_maps()
	
	print("--- DATA CONTENT VALIDATION END ---")
	if error_count > 0:
		print("FAILED: Found %d data errors." % error_count)
		quit(1)
	else:
		print("SUCCESS: Data content is valid.")
		quit(0)

func report_error(msg: String) -> void:
	printerr("ERROR: " + msg)
	error_count += 1

func validate_res_path(path: String, context: String) -> void:
	if not path.begins_with("res://"):
		return
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		report_error("[%s] Path does not exist: %s" % [context, path])

func validate_combat_content() -> void:
	print("Validating CombatContent.gd...")
	var script = load("res://data/CombatContent.gd")
	if not script:
		report_error("Could not load CombatContent.gd")
		return
	
	# Check CREATURES
	var creatures = script.get("CREATURES")
	if creatures:
		var ids = []
		for key in creatures.keys():
			var c = creatures[key]
			var sid = c.get("species_id", "")
			if sid == "":
				report_error("Creature '%s' missing species_id" % key)
			elif sid in ids:
				report_error("Duplicate species_id: %s" % sid)
			else:
				ids.append(sid)
			
			# Check paths
			validate_res_path(c.get("sprite_path", ""), "CREATURES:" + sid)
			validate_res_path(c.get("reward_portrait_path", ""), "CREATURES:" + sid)
			validate_res_path(c.get("support_portrait_path", ""), "CREATURES:" + sid)
			validate_res_path(c.get("battlefield_sprite_path", ""), "CREATURES:" + sid)
	
	# Check ENCOUNTERS
	var encounters = script.get("ENCOUNTERS")
	if encounters:
		var ids = []
		for key in encounters.keys():
			var e = encounters[key]
			var eid = e.get("id", "")
			if eid == "":
				report_error("Encounter '%s' missing id" % key)
			elif eid in ids:
				report_error("Duplicate encounter id: %s" % eid)
			else:
				ids.append(eid)

func validate_performance_reward_content() -> void:
	print("Validating PerformanceRewardContent.gd...")
	var script = load("res://data/PerformanceRewardContent.gd")
	if not script:
		report_error("Could not load PerformanceRewardContent.gd")
		return

	var rewards: Dictionary = script.get("REWARDS")
	var reward_order: Array = script.get("REWARD_ORDER")
	if rewards.is_empty():
		report_error("PerformanceRewardContent.REWARDS is empty")
		return
	if reward_order.is_empty():
		report_error("PerformanceRewardContent.REWARD_ORDER is empty")

	for reward_id in reward_order:
		var id: String = String(reward_id)
		if not rewards.has(id):
			report_error("REWARD_ORDER references missing reward: %s" % id)

	var required_fields: Array[String] = ["id", "title", "summary", "readout", "claim_text"]
	for key in rewards.keys():
		var reward: Dictionary = rewards[key]
		var id: String = String(reward.get("id", ""))
		if id != String(key):
			report_error("Reward key '%s' has mismatched internal id '%s'" % [String(key), id])

		for field_name in required_fields:
			if String(reward.get(field_name, "")).strip_edges().is_empty():
				report_error("Reward '%s' missing required field '%s'" % [String(key), field_name])

		var effect: Dictionary = reward.get("effect", {})
		if effect.is_empty():
			report_error("Reward '%s' missing effect dictionary" % String(key))
		elif String(effect.get("type", "")).strip_edges().is_empty():
			report_error("Reward '%s' missing effect.type" % String(key))

	var phase_mixes: Array = script.get("PHASE_REWARD_MIXES")
	for i in range(phase_mixes.size()):
		for reward_id in phase_mixes[i]:
			var id: String = String(reward_id)
			if not rewards.has(id):
				report_error("PHASE_REWARD_MIXES[%d] references missing reward: %s" % [i, id])

	var affinity_mixes: Dictionary = script.get("AFFINITY_PHASE_MIXES")
	for affinity in affinity_mixes.keys():
		var mixes: Array = affinity_mixes[affinity]
		for i in range(mixes.size()):
			for reward_id in mixes[i]:
				var id: String = String(reward_id)
				if not rewards.has(id):
					report_error("AFFINITY_PHASE_MIXES[%s][%d] references missing reward: %s" % [String(affinity), i, id])

	var flayed: Dictionary = rewards.get("flayed_vessel", {})
	var flayed_effect: Dictionary = flayed.get("effect", {})
	if flayed.is_empty():
		report_error("Missing required Vessel reward: flayed_vessel")
	elif String(flayed_effect.get("type", "")) != "kill_chain_heavy":
		report_error("flayed_vessel effect.type must be kill_chain_heavy")
	else:
		for field_name in ["kills_required", "heal_value", "support_charge"]:
			if not flayed_effect.has(field_name):
				report_error("flayed_vessel effect missing '%s'" % field_name)

func validate_route_content() -> void:
	print("Validating RouteContent.gd...")
	var script = load("res://data/RouteContent.gd")
	if not script:
		report_error("Could not load RouteContent.gd")
		return
	
	var regions = script.get("REGIONS")
	if regions:
		var ids = []
		for r in regions:
			var rid = r.get("id", "")
			if rid == "":
				report_error("Region missing id")
			elif rid in ids:
				report_error("Duplicate region id: %s" % rid)
			else:
				ids.append(rid)

func validate_audio_content() -> void:
	print("Validating AudioContent.gd...")
	var script = load("res://data/AudioContent.gd")
	if not script:
		return
	
	# AudioContent usually has a library or paths dictionary
	# Assuming it has a library or similar structure
	# For now, let's just check if it loads.

func validate_song_maps() -> void:
	print("Validating song_maps/...")
	var dir = DirAccess.open("res://data/song_maps")
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			var path = "res://data/song_maps/" + file_name
			var script = load(path)
			if not script:
				report_error("Could not load song map: " + file_name)
		file_name = dir.get_next()
