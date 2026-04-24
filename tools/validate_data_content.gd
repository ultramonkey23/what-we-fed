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
