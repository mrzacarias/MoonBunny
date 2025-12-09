# Global Level Resource Manager for HTML Export Compatibility
# Preloads and manages all level resources since dynamic loading doesn't work in HTML exports

extends Node

# Preloaded resources
var level_images: Dictionary = {}
var level_music: Dictionary = {}
var level_headers: Dictionary = {}
var level_rings: Dictionary = {}

# Available levels (automatically detected, excluding training)
var available_levels: Array[String] = []

func _ready():
	discover_available_levels()
	preload_all_resources()

func discover_available_levels():
	"""Automatically discover available levels from the levels directory, excluding training"""
	available_levels.clear()
	
	# Check if we're running in HTML/Web export
	if OS.get_name() == "Web":
		# For HTML export, use hardcoded list since file system access is limited
		# These are the levels that actually exist in the assets/levels directory
		available_levels = ["7stars", "bang_bang", "green_hill_zone", "mirrors_edge", "rirura_2"]
		available_levels.sort()
		return
	
	# Try to read levels directory dynamically (desktop platforms)
	var levels_dir = DirAccess.open("res://assets/levels/")
	if levels_dir:
		levels_dir.list_dir_begin()
		var dir_name = levels_dir.get_next()
		
		while dir_name != "":
			# Check if it's a directory and not a special entry
			if levels_dir.current_is_dir() and not dir_name.begins_with("."):
				# Exclude training level (handled separately by main menu)
				if dir_name != "training":
					# Verify it has the required files (header.json and music file)
					var level_path = "res://assets/levels/" + dir_name + "/"
					if FileAccess.file_exists(level_path + "header.json"):
						# Check for music file (could be .mp3 or other formats)
						var has_music = false
						var music_extensions = [".mp3", ".ogg", ".wav"]
						for ext in music_extensions:
							if FileAccess.file_exists(level_path + dir_name + ext):
								has_music = true
								break
						
						if has_music:
							available_levels.append(dir_name)
						else:
							print("ERROR: Level ", dir_name, " missing music file")
					else:
						print("ERROR: Level ", dir_name, " missing header.json file")
			
			dir_name = levels_dir.get_next()
		
		levels_dir.list_dir_end()
	else:
		# Fallback to hardcoded list (excluding training)
		available_levels = [
			"7stars",
			"bang_bang", 
			"green_hill_zone",
			"mirrors_edge",
			"rirura_2"
		]
	
	# Sort levels alphabetically for consistent ordering
	available_levels.sort()

func preload_all_resources():
	"""Preload all level resources for HTML export compatibility"""
	
	# Always preload training level for main menu access
	preload_level_resources("training")
	
	# Preload discovered levels
	for level_name in available_levels:
		preload_level_resources(level_name)

func preload_level_resources(level_name: String):
	"""Preload all resources for a specific level"""
	
	# Preload images
	var image_path = "res://assets/levels/" + level_name + "/image.png"
	var texture = load(image_path)
	if texture:
		level_images[level_name] = texture
	else:
		print("ERROR: Failed to load level image: ", image_path)
	
	# Preload music
	var music_path = "res://assets/levels/" + level_name + "/" + level_name + ".mp3"
	var music = load(music_path)
	if music:
		level_music[level_name] = music
	else:
		print("ERROR: Failed to load music file: ", music_path)
	
	# Load .json files - Godot automatically imports these as resources for HTML compatibility
	var header_path = "res://assets/levels/" + level_name + "/header.json"
	var ring_path = "res://assets/levels/" + level_name + "/Normal.json"
	
	# Load header file as JSON
	var header_file = FileAccess.open(header_path, FileAccess.READ)
	if header_file:
		var json_string = header_file.get_as_text()
		header_file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var header_data = json.data
			# Convert JSON back to the original key=value format for compatibility
			var header_content = ""
			for key in header_data:
				header_content += key + "=" + str(header_data[key]) + "\n"
			level_headers[level_name] = header_content.strip_edges()
		else:
			print("ERROR: Failed to parse JSON in header file: ", header_path)
			level_headers[level_name] = ""
	else:
		print("ERROR: Failed to load header file: ", header_path)
		level_headers[level_name] = ""
	
	# Load ring file as JSON
	var ring_file = FileAccess.open(ring_path, FileAccess.READ)
	if ring_file:
		var json_string = ring_file.get_as_text()
		ring_file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var ring_data = json.data
			level_rings[level_name] = ring_data["content"]
		else:
			print("ERROR: Failed to parse JSON in ring file: ", ring_path)
			level_rings[level_name] = ""
	else:
		print("ERROR: Failed to load ring file: ", ring_path)
		level_rings[level_name] = ""

# Getter functions for other scripts to use
func get_level_image(level_name: String) -> Texture2D:
	return level_images.get(level_name, null)

func get_level_music(level_name: String) -> AudioStream:
	return level_music.get(level_name, null)

func get_level_header(level_name: String) -> String:
	return level_headers.get(level_name, "")

func get_level_rings(level_name: String) -> String:
	return level_rings.get(level_name, "")

func get_available_levels() -> Array[String]:
	"""Get list of available levels for level select (excludes training level)"""
	return available_levels

func parse_level_header(level_name: String) -> Dictionary:
	"""Parse level header data from preloaded content"""
	var level_data = {}
	var header_content = get_level_header(level_name)
	
	if header_content != "":
		var lines = header_content.split("\n")
		
		for line in lines:
			line = line.strip_edges()
			if line == "" or line.begins_with("#"):
				continue
			
			var parts = line.split("=")
			if parts.size() == 2:
				var key = parts[0].strip_edges()
				var value = parts[1].strip_edges()
				
				match key:
					"BPM":
						level_data["BPM"] = value.to_float()
					"TITLE":
						level_data["TITLE"] = value
					"ARTIST":
						level_data["ARTIST"] = value
					"MUSIC_FILE":
						level_data["MUSIC_FILE"] = value
					"DIFFICULTIES":
						level_data["DIFFICULTIES"] = value
	
	# Set defaults
	level_data["NAME"] = level_name
	if not level_data.has("TITLE"):
		level_data["TITLE"] = level_name.replace("_", " ").capitalize()
	if not level_data.has("BPM"):
		level_data["BPM"] = 120.0
	
	return level_data
