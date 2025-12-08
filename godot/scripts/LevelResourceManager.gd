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
	print("LevelResourceManager: Initializing")
	discover_available_levels()
	preload_all_resources()

func discover_available_levels():
	"""Automatically discover available levels from the levels directory, excluding training"""
	available_levels.clear()
	
	var levels_dir = DirAccess.open("res://assets/levels/")
	if levels_dir:
		levels_dir.list_dir_begin()
		var dir_name = levels_dir.get_next()
		
		while dir_name != "":
			# Check if it's a directory and not a special entry
			if levels_dir.current_is_dir() and not dir_name.begins_with("."):
				# Exclude training level (handled separately by main menu)
				if dir_name != "training":
					# Verify it has the required files (header.lvl and music file)
					var level_path = "res://assets/levels/" + dir_name + "/"
					if FileAccess.file_exists(level_path + "header.lvl"):
						# Check for music file (could be .mp3 or other formats)
						var has_music = false
						var music_extensions = [".mp3", ".ogg", ".wav"]
						for ext in music_extensions:
							if FileAccess.file_exists(level_path + dir_name + ext):
								has_music = true
								break
						
						if has_music:
							available_levels.append(dir_name)
							print("LevelResourceManager: Discovered level: ", dir_name)
						else:
							print("LevelResourceManager: Skipping ", dir_name, " - no music file found")
					else:
						print("LevelResourceManager: Skipping ", dir_name, " - no header.lvl found")
			
			dir_name = levels_dir.get_next()
		
		levels_dir.list_dir_end()
	else:
		print("LevelResourceManager: Could not open levels directory, falling back to hardcoded list")
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
	print("LevelResourceManager: Available levels: ", available_levels)

func preload_all_resources():
	"""Preload all level resources for HTML export compatibility"""
	print("LevelResourceManager: Preloading all level resources")
	
	# Always preload training level for main menu access
	preload_level_resources("training")
	
	# Preload discovered levels
	for level_name in available_levels:
		preload_level_resources(level_name)

func preload_level_resources(level_name: String):
	"""Preload all resources for a specific level"""
	print("LevelResourceManager: Preloading resources for ", level_name)
	
	# Preload images
	var image_path = "res://assets/levels/" + level_name + "/image.png"
	var texture = load(image_path)
	if texture:
		level_images[level_name] = texture
		print("LevelResourceManager: Loaded image for ", level_name)
	else:
		print("LevelResourceManager: Failed to load image for ", level_name)
	
	# Preload music
	var music_path = "res://assets/levels/" + level_name + "/" + level_name + ".mp3"
	var music = load(music_path)
	if music:
		level_music[level_name] = music
		print("LevelResourceManager: Loaded music for ", level_name)
	else:
		print("LevelResourceManager: Failed to load music for ", level_name)
	
	# For HTML exports, FileAccess doesn't work reliably
	# Use fallback data for now, but try FileAccess first for desktop/editor
	var header_path = "res://assets/levels/" + level_name + "/header.lvl"
	var ring_path = "res://assets/levels/" + level_name + "/Normal.rng"
	
	# Try FileAccess first (works in editor/desktop)
	var header_file = FileAccess.open(header_path, FileAccess.READ)
	if header_file:
		var header_content = header_file.get_as_text()
		level_headers[level_name] = header_content
		header_file.close()
		print("LevelResourceManager: Loaded header via FileAccess for ", level_name)
	else:
		print("LevelResourceManager: FileAccess failed for header, using fallback for ", level_name)
		level_headers[level_name] = get_fallback_header(level_name)
	
	# Same for ring files
	var ring_file = FileAccess.open(ring_path, FileAccess.READ)
	if ring_file:
		var ring_content = ring_file.get_as_text()
		level_rings[level_name] = ring_content
		ring_file.close()
		print("LevelResourceManager: Loaded rings via FileAccess for ", level_name)
	else:
		print("LevelResourceManager: FileAccess failed for rings, using fallback for ", level_name)
		level_rings[level_name] = get_fallback_rings(level_name)

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

func get_fallback_header(level_name: String) -> String:
	"""Get fallback header data for HTML exports"""
	match level_name:
		"7stars":
			return "MUSIC_FILE=7stars.mp3\nTITLE=Seven Stars\nARTIST=Apples In Stereo\nBPM=132\nDIFFICULTIES=Normal"
		"bang_bang":
			return "MUSIC_FILE=bang_bang.mp3\nTITLE=Bang Bang Mystery Man\nARTIST=Mary Jo feat. Cairbre\nBPM=157\nDIFFICULTIES=Normal"
		"green_hill_zone":
			return "MUSIC_FILE=green_hill_zone.mp3\nTITLE=Green Hill Zone\nARTIST=Masato Nakamura\nBPM=150\nDIFFICULTIES=Normal"
		"magic_love":
			return "MUSIC_FILE=magic_love.mp3\nTITLE=Magic Love\nARTIST=Unknown\nBPM=108\nDIFFICULTIES=Normal"
		"rain_of_love":
			return "MUSIC_FILE=rain_of_love.mp3\nTITLE=Rain of Love\nARTIST=Unknown\nBPM=120\nDIFFICULTIES=Normal"
		"mirrors_edge":
			return "MUSIC_FILE=mirrors_edge.mp3\nTITLE=Still Alive - Mirror's Edge Theme\nARTIST=Lisa Miskovsky\nBPM=107\nDIFFICULTIES=Normal"
		"rirura_2":
			return "MUSIC_FILE=rirura_2.mp3\nTITLE=Rirura Riruha\nARTIST=Kaela Kimura\nBPM=138\nDIFFICULTIES=Normal"
		"training":
			return "MUSIC_FILE=training.mp3\nTITLE=Training\nARTIST=FreeLoops.org\nBPM=102\nDIFFICULTIES=Normal"
		_:
			return "MUSIC_FILE=" + level_name + ".mp3\nTITLE=" + level_name.replace("_", " ").capitalize() + "\nARTIST=Unknown\nBPM=120\nDIFFICULTIES=Normal"

func get_fallback_rings(level_name: String) -> String:
	"""Get actual ring data embedded for HTML exports"""
	match level_name:
		"7stars":
			return """0, 0; 14.94903; A
-0.14, 0; 3.98641; C
0.14, 0; 3.98641; B
-0.14, 0; 3.98641; C
0.14, 0; 3.488109; B
0.14, 0; 0.498301; B

# Verse
-0.14, 0; 3.98641; C
0.14, 0; 3.98641; B
-0.14, 0; 3.98641; C
0.14, 0; 3.488109; B
0.14, 0; 0.498301; B
-0.14, -0.08; 3.98641; C
0.14, -0.08; 3.98641; B
-0.14, -0.08; 3.98641; C
0.14, -0.08; 3.488109; B
0.14, -0.08; 0.498301; B
-0.14, 0; 3.98641; C
0.14, 0; 3.98641; B
-0.14, 0; 3.98641; C
0.14, 0; 3.488109; B
0.14, 0; 0.498301; B
-0.14, 0.08; 3.98641; C
0.14, 0.08; 3.98641; B
-0.14, 0.08; 3.98641; C
0.14, 0.08; 3.488109; B
0.14, 0.08; 0.498301; B

# And you don't even know my name...
0.07, 0; 0.996602; D
0.07, 0; 0.996602; D
0.07, 0; 0.498301; D
0.07, 0; 0.498301; D

-0.07, 0; 0.996602; A
-0.07, 0; 1.993205; A
-0.07, 0; 0.498301; A
-0.07, 0; 0.498301; A

0.07, 0; 0.996602; D
0.07, 0; 1.993205; D
0.07, 0; 0.498301; D
0.07, 0; 0.498301; D

-0.07, 0; 0.996602; A
-0.07, 0; 1.993205; A
-0.07, 0; 0.498301; A
-0.07, 0; 0.498301; A

# Verse
-0.14, 0; 0.996602; C
0.14, 0; 3.98641; B
-0.14, 0; 3.98641; C
0.14, 0; 3.98641; B
-0.14, 0; 3.488109; C
-0.14, 0; 0.498301; C

0.14, 0; 3.98641; B
-0.14, 0; 3.98641; C
0.14, 0; 3.98641; B
-0.14, 0; 3.488109; C
-0.14, 0; 0.498301; C

0.14, 0; 3.98641; B
-0.14, 0; 3.98641; C
0.14, 0; 3.98641; B
-0.14, 0; 3.488109; C
-0.14, 0; 0.498301; C

0.14, 0; 3.98641; B
-0.14, 0; 3.98641; C
0.14, 0; 3.98641; B
-0.14, 0; 3.488109; C
-0.14, 0; 0.498301; C

# And you don't even know my name...
0.07, 0; 0.996602; D
0.07, 0; 0.996602; D
0.07, 0; 0.498301; D
0.07, 0; 0.498301; D

-0.07, 0; 0.996602; A
-0.07, 0; 1.993205; A
-0.07, 0; 0.498301; A
-0.07, 0; 0.498301; A

0.07, 0; 0.996602; D
0.07, 0; 1.993205; D
0.07, 0; 0.498301; D
0.07, 0; 0.498301; D

-0.07, 0; 0.996602; A
-0.07, 0; 1.993205; A
-0.07, 0; 0.498301; A
-0.07, 0; 0.498301; A

0, 0; 0.996602; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C

0, 0; 1.494903; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B

0, 0; 1.494903; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C

0, 0; 1.494903; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B

0, 0; 1.494903; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C

0, 0; 1.494903; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B

0, 0; 1.494903; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C

0, 0; 1.494903; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B

0, 0; 1.494903; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C
0, 0; 0.498301; C

0, 0; 1.494903; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B
0, 0; 0.498301; B"""
		"bang_bang":
			return """0.0,0.0 ; 5.25 ; A
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.50 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.25 ; A 
0.0,0.0 ; 3.00 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 2.25 ; A

0.3,0.0 ; 3.25 ; B 
0.3,0.0 ; 0.75 ; B 
0.3,0.0 ; 1.75 ; B 
0.3,0.0 ; 1.50 ; B 
0.3,0.0 ; 1.50 ; B 
0.3,0.0 ; 0.75 ; B 
0.3,0.0 ; 1.75 ; B 
0.3,0.0 ; 1.50 ; B 
0.3,0.0 ; 1.25 ; B 
0.3,0.0 ; 0.75 ; B 
0.3,0.0 ; 1.75 ; B 
0.3,0.0 ; 1.25 ; B 
0.3,0.0 ; 1.50 ; B 
0.3,0.0 ; 0.50 ; B 
0.3,0.0 ; 2.00 ; B 
0.3,0.0 ; 1.25 ; B 
0.3,0.0 ; 1.50 ; B 
0.3,0.0 ; 0.50 ; B 
0.3,0.0 ; 2.50 ; B 
0.3,0.0 ; 1.00 ; B 
0.3,0.0 ; 1.25 ; B 
0.3,0.0 ; 0.75 ; B 
0.3,0.0 ; 2.00 ; B 
0.3,0.0 ; 1.25 ; B 
0.3,0.0 ; 1.50 ; B 
0.3,0.0 ; 2.00 ; B 
0.3,0.0 ; 2.50 ; B

0.0,0.0 ; 3.75 ; A 
0.0,0.0 ; 0.50 ; A 
0.0,0.0 ; 0.50 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 2.75 ; A 
0.0,0.0 ; 1.00 ; A 
0.0,0.0 ; 1.50 ; A 
0.0,0.0 ; 0.50 ; A 
0.0,0.0 ; 2.00 ; A 
0.0,0.0 ; 0.50 ; A 
0.0,0.0 ; 0.25 ; A 
0.0,0.0 ; 0.50 ; A 
0.0,0.0 ; 2.25 ; A 
0.0,0.0 ; 1.00 ; A 
0.0,0.0 ; 1.00 ; A

-0.3, 0.0 ; 3.25 ; C 
-0.3, 0.0 ; 1.00 ; C 
-0.3, 0.0 ; 1.25 ; C

0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 1.00 ; A 
0.0,0.0 ; 1.25 ; A

0.3, 0.0 ; 3.00 ; B 
0.3, 0.0 ; 1.00 ; B 
0.3, 0.0 ; 1.25 ; B

0.0,0.0 ; 3.00 ; A 
0.0,0.0 ; 1.25 ; A 
0.0,0.0 ; 1.00 ; A

0.3, 0.0 ; 3.25 ; B 
0.3, 0.0 ; 1.00 ; B 
0.3, 0.0 ; 1.00 ; B

0.0,0.0 ; 3.25 ; A 
0.0,0.0 ; 1.00 ; A 
0.0,0.0 ; 1.00 ; A

-0.3, 0.0 ; 3.25 ; C 
-0.3, 0.0 ; 1.00 ; C 
-0.3, 0.0 ; 1.25 ; C

-0.3, -0.3 ; 2.75 ; A 
-0.3, -0.3 ; 2.25 ; A

-0.3, 0.0 ; 3.50 ; C 
-0.3, 0.0 ; 2.00 ; C

0.0, 0.0 ; 3.25 ; A 
0.0, 0.0 ; 1.75 ; A

0.0, 0.3 ; 3.50 ; D
0.0, 0.3 ; 2.00 ; D

0.15, 0.3 ; 3.50 ; D
0.15, 0.3 ; 2.00 ; D

0.3, 0.3 ; 3.00 ; B
0.3, 0.3 ; 2.25 ; B

0.3, 0.15 ; 3.00 ; B 
0.3, 0.15 ; 2.25 ; B 

0.15, 0.15 ; 3.25 ; A 
0.15, 0.15 ; 2.00 ; A 

0.15, 0.0 ; 3.25 ; A 
0.15, 0.0 ; 2.00 ; A 

0.0, 0.0 ; 3.25 ; A 
0.0, 0.0 ; 2.25 ; A 

0.0, 0.15 ; 3.25 ; D 
0.0, 0.15 ; 2.25 ; D 

0.0, 0.15 ; 3.00 ; D 
0.0, 0.15 ; 2.25 ; D 

0.0, 0.15 ; 3.50 ; D 
0.0, 0.15 ; 0.75 ; D 
0.0, 0.15 ; 1.50 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 1.50 ; D 
0.0, 0.15 ; 0.50 ; D 

0.0, 0.15 ; 2.00 ; D 
0.0, 0.15 ; 1.50 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 0.50 ; D 

0.0, 0.15 ; 2.00 ; D 
0.0, 0.15 ; 1.50 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 0.50 ; D 

0.0, 0.15 ; 2.25 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 0.50 ; D 

0.0, 0.15 ; 2.25 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 0.75 ; D 

0.0, 0.15 ; 2.00 ; D 
0.0, 0.15 ; 1.50 ; D 
0.0, 0.15 ; 1.25 ; D 
0.0, 0.15 ; 2.25 ; D 
0.0, 0.15 ; 2.50 ; D 

0.0, 0.0 ; 3.00 ; A 

0.0, 0.0 ; 3.00 ; A 
0.0, 0.0 ; 0.75 ; A 
0.0, 0.0 ; 1.75 ; A 

0.0, 0.0 ; 5.25 ; A 
0.0, 0.0 ; 0.25 ; A 
0.0, 0.0 ; 0.50 ; A 
0.0, 0.0 ; 7.50 ; A

0.0, 0.0 ; 2.00 ; A 
0.0, 0.0 ; 2.00 ; A 
0.0, 0.0 ; 7.00 ; A 
0.0, 0.0 ; 1.50 ; A 

0.0, 0.0 ; 8.75 ; A 
0.0, 0.0 ; 2.00 ; A 
0.0, 0.0 ; 3.50 ; A 
0.0, 0.0 ; 1.75 ; A 
0.0, 0.0 ; 3.25 ; A 
0.0, 0.0 ; 2.75 ; A 

0.15, 0.0 ; 13.50 ; B 
0.15, 0.0 ; 1.00 ; B 
0.15, 0.0 ; 0.75 ; B 
0.15, 0.0 ; 0.50 ; B 

0.15, 0.15 ; 3.00 ; B 
0.15, 0.15 ; 0.50 ; B 
0.15, 0.15 ; 0.75 ; B 
0.15, 0.15 ; 0.75 ; B 
0.15, 0.15 ; 1.25 ; B 
0.15, 0.15 ; 2.25 ; B 
0.15, 0.15 ; 1.00 ; B 
0.15, 0.15 ; 1.00 ; B 
0.15, 0.15 ; 0.25 ; B 
0.15, 0.15 ; 2.75 ; B 
0.15, 0.15 ; 0.75 ; B 
0.15, 0.15 ; 0.75 ; B 
0.15, 0.15 ; 0.75 ; B 
0.15, 0.15 ; 2.75 ; B 
0.15, 0.15 ; 2.50 ; B 

0.3, 0.15 ; 8.75 ; B

0.3, 0.3 ; 4.75 ; D

0.15, 0.3; 5.75 ; D 

0.0, 0.3 ; 5.00 ; D 

-0.15, 0.3 ; 5.25 ; C

-0.15, 0.15 ; 5.25 ; C 

-0.15, 0.0 ; 5.50 ; C

0.0, 0.0 ; 2.50 ; A 
0.0, 0.0 ; 2.00 ; A 
0.0, 0.0 ; 3.75 ; A 
0.0, 0.0 ; 2.75 ; A 
0.0, 0.0 ; 2.25 ; A 
0.0, 0.0 ; 1.25 ; A 
0.0, 0.0 ; 1.25 ; A 
0.0, 0.0 ; 0.50 ; A 
0.0, 0.0 ; 0.25 ; A 
0.0, 0.0 ; 2.00 ; A 
0.0, 0.0 ; 0.50 ; A 
0.0, 0.0 ; 0.25 ; A 
0.0, 0.0 ; 2.25 ; A 
0.0, 0.0 ; 2.25 ; A 
0.0, 0.0 ; 2.75 ; A 
0.0, 0.0 ; 2.50 ; A 
0.0, 0.0 ; 3.00 ; A 
0.0, 0.0 ; 2.00 ; A 
0.0, 0.0 ; 3.25 ; A 
0.0, 0.0 ; 2.25 ; A 
0.0, 0.0 ; 3.00 ; A 
0.0, 0.0 ; 2.25 ; A 
0.0, 0.0 ; 3.25 ; A 
0.0, 0.0 ; 2.25 ; A 
0.0, 0.0 ; 2.75 ; A 
0.0, 0.0 ; 2.00 ; A 
0.0, 0.0 ; 3.50 ; A 
0.0, 0.0 ; 2.75 ; A 

0.0,0.0 ; 13.75 ; A 
0.0,0.0 ; 1.00 ; A 
0.0,0.0 ; 1.00 ; A 
0.0,0.0 ; 0.25 ; A 
0.0,0.0 ; 2.75 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 1.50 ; A 
0.0,0.0 ; 1.50 ; A 
0.0,0.0 ; 1.25 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 0.50 ; A 
0.0,0.0 ; 2.75 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 0.75 ; A 
0.0,0.0 ; 2.75 ; A 
0.0,0.0 ; 1.75 ; A 
0.0,0.0 ; 1.50 ; A 
0.0,0.0 ; 1.25 ; A 
0.0,0.0 ; 1.50 ; A 
0.0,0.0 ; 2.50 ; A"""
		"green_hill_zone":
			return """#Preludio
0, 0; 4.2925; A
0, 0; 1.42; A
0, 0; 1.585; A
0, 0; 1.435; A
0, 0; 1.55; A
0, 0; 0.915; A
0, 0; 1.0775; A
0, 0; 1.465; A
0, 0; 1.54; A
0.12, 0.02; 5.0025; B
0.12, 0.04; 1.46; B
0.12, 0.06; 1.515; B
-0.12, -0.02; 1.0425; C
-0.12, -0.04; 1.4825; C
-0.12, -0.06; 1.5475; C
-0.12, -0.08; 0.98; C
0, 0; 1.4575; A

#refrao
0, 0.1; 5.055; D
0, 0.1; 0.5425; D
0, 0.1; 0.4875; D
0, 0.1; 0.545; D

-0.12, 0.1; 1.9175; C
-0.12, -0.1; 0.4775; C
-0.12, 0.1; 1.0025; C
-0.12, -0.1; 0.505; C
-0.12, 0.1; 0.995; C
-0.12, 0.1; 0.5425; C
-0.12, -0.1; 0.9825; C

0.12, 0; 2.9775; B
0.12, 0.1; 0.49; B
0.12, -0.1; 0.4975; B
0.12, 0.1; 1.025; B
0.12, -0.1; 0.5275; B
0.12, 0.1; 1.01; B
0.12, 0.1; 0.505; B
0.12, -0.1; 0.99; B

-0.12, 0.1; 3.4975; C
-0.12, -0.1; 0.475; C
-0.12, 0.1; 1.0425; C
-0.12, -0.1; 0.525; C
-0.12, 0.1; 0.9525; C
-0.12, 0.1; 0.4875; C
-0.12, -0.1; 1.02; C

0.12, 0.1; 3.075; B
0.12, 0.1; 0.4675; B
0.12, -0.1; 0.46; B
0.12, 0.1; 0.995; B
0.12, -0.1; 0.5125; B
0.12, 0.1; 1.0275; B
0.12, 0.1; 0.52; B
0, 0.12; 0.95; D
0, 0.14; 0.4825; D
0, 0.16; 0.48; D
0, 0.18; 0.56; D

0, 0.18; 4.995; D
0, 0.18; 1.02; D
0, 0.18; 0.9725; D
0, 0.18; 1.035; D

0, -0.18; 4.9725; A
0, -0.18; 1.01; A
0, -0.18; 1.1375; A
0, -0.18; 0.895; A

-0.18, 0; 4.9575; C
-0.18, 0; 1.0125; C
-0.18, 0; 0.9725; C
-0.18, 0; 1.0375; C

0.18, 0; 3.9425; B
0.18, 0; 1.22; B
0.18, 0; 0.93; B

#Interludio
0, -0.18; 1.91; A
0, -0.16; 1.54; A
0, -0.14; 1.46; A
0, -0.12; 1.5525; A
0, -0.1; 1.4975; A
0, -0.08; 0.96; A
0.18, 0; 1.0475; B
0.16, 0; 1.44; B
0.14, 0; 1.505; B
0.12, 0; 1.4525; B
0.1, 0; 1.4575; B
0.08, 0; 1.07; B
-0.18, 0; 1.05; C
-0.16, 0; 1.5175; C
-0.14, 0; 1.46; C
-0.12, 0; 1.5625; C
-0.1, 0; 1.4775; C
-0.08, 0; 1.005; C
0, 0.18; 0.98; D
0, 0.16; 1.4725; D
0, 0.14; 1.535; D
0, 0.12; 1.5475; D
0, 0.1; 1.4875; D
0, 0.08; 0.905; D
0, 0.06; 1.035; D

#Refrao
0.1, -0.12; 2.105; A
-0.1, -0.12; 0.535; A
0.1, -0.12; 0.86; A
-0.1, -0.12; 0.525; A
0.1, -0.12; 0.9325; A
0.1, -0.12; 0.5625; A
-0.1, -0.12; 1.0275; A

0, 0.12; 2.9925; D
0.1, 0.12; 0.4975; D
-0.1, 0.12; 0.505; D
0.1, 0.12; 0.9975; D
-0.1, 0.12; 0.525; D
0.1, 0.12; 0.975; D
0.1, 0.12; 0.5425; D
-0.1, 0.12; 0.95; D

0.1, -0.06; 3.5275; A
-0.1, -0.06; 0.4675; A
0.1, -0.06; 1.0625; A
-0.1, -0.06; 0.53; A
0.1, -0.06; 0.905; A
0.1, -0.06; 0.505; A
-0.1, -0.06; 1.035; A

0, 0.06; 3.045; D
0.1, 0.06; 0.4825; D
-0.1, 0.06; 0.465; D
0.1, 0.06; 1.02; D
-0.1, 0.06; 0.505; D
0.1, 0.06; 0.9825; D
0.1, 0.06; 0.5275; D
-0.1, 0.06; 1.0625; D"""
		"magic_love":
			return """#Musica 'magic_love.mp3' salva no diretorio 'magic_love'

0, 0; 4.7484; A
0, 0; 1.0728; A
0, 0; 1.125; A
0, 0; 1.098; A
0, 0; 1.1268; A
0, 0; 0.81; A
0, 0; 0.8172; A

0, 0; 2.9466; D
0, 0; 1.089; D
0, 0; 1.098; D
0, 0; 1.1286; D
0, 0; 1.107; D
0, 0; 0.9; D
0, 0; 0.783; D
0, 0; 0.8118; D

0, 0; 2.097; A
0, 0; 1.0386; A
0, 0; 1.134; A
0, 0; 1.143; A
0, 0; 1.125; A
0, 0; 0.8118; A
0, 0; 0.8532; A

0, 0; 2.8926; D
0, 0; 1.0692; D
0, 0; 1.1178; D
0, 0; 1.0728; D
0, 0; 1.1592; D
0, 0; 0.8118; D
0, 0; 0.8388; D

0, 0; 2.853; A
0, 0; 0.819; A
0, 0; 0.9396; A
0, 0; 0.522; A
0, 0; 0.8154; A
0, 0; 0.8298; A
0, 0; 0.5814; A
0, 0; 0.8694; A
0, 0; 0.8874; A
0, 0; 0.774; A

0, 0; 2.0106; D
0, 0; 0.7812; D
0, 0; 0.8658; D
0, 0; 0.576; D
0, 0; 0.8388; D
0, 0; 0.864; D
0, 0; 0.5112; D
0, 0; 0.8478; D
0, 0; 0.8712; D
0, 0; 0.8316; D

0, 0; 1.989; A
0, 0; 0.7848; A
0, 0; 0.8838; A
0, 0; 0.576; A
0, 0; 0.8172; A
0, 0; 0.8838; A
0, 0; 0.5292; A
0, 0; 0.8874; A
0, 0; 0.8694; A
0, 0; 0.8478; A

0, 0; 1.9566; D
0, 0; 0.7434; D
0, 0; 0.9378; D
0, 0; 0.4878; D
0, 0; 0.783; D
0, 0; 0.99; D
0, 0; 0.5112; D
0, 0; 1.08; D
0, 0; 1.1286; D
0, 0; 1.0872; D
0, 0; 1.1538; D
0, 0; 1.1736; D
0, 0; 1.134; D
0, 0; 1.1412; D
0, 0; 1.1286; D
0, 0; 1.0638; D
0, 0; 1.1268; D
0, 0; 1.1214; D
0, 0; 1.1574; D
0, 0; 1.1034; D
0, 0; 1.1736; D
0, 0; 1.1106; D
0, 0; 1.0872; D
0, 0; 0.8298; D
0, 0; 0.873; D
0, 0; 1.1736; D

0, 0; 1.5732; A
0, 0; 0.8784; A
0, 0; 0.882; A
0, 0; 0.54; A
0, 0; 0.8298; A
0, 0; 0.9018; A
0, 0; 0.5202; A
0, 0; 0.864; A
0, 0; 0.8532; A
0, 0; 0.9198; A

0, 0; 1.8648; D
0, 0; 0.8352; D
0, 0; 0.882; D
0, 0; 0.5418; D
0, 0; 0.8028; D
0, 0; 0.9018; D"""
		"mirrors_edge":
			return """
#Parte 1
0, 0; 3.75391666667; A
0, 0; 1.86893333333; A
0, 0; 0.948733333333; A
0, 0; 1.04146666667; A
0.15, 0; 2.0116; B
-0.15, 0; 1.00758333333; C

0, 0; 1.53188333333; D
0, 0; 1.38743333333; D
0, 0; 1.1021; D
0, 0; 1.00223333333; D
-0.15, 0; 2.0437; C
0.15, 0; 0.929116666667; B

#Parte 2
0.15, -0.15; 17.7102833333; B
0.15, -0.15; 1.44271666667; B
0.15, -0.15; 0.859566666667; B
0.15, -0.15; 1.06108333333; B
0.15, -0.15; 0.472583333333; B

-0.15, -0.15; 1.01471666667; A
-0.15, -0.15; 0.527866666667; A
-0.15, -0.15; 0.879183333333; A
-0.15, -0.15; 0.987966666667; A
-0.15, -0.15; 0.531433333333; A

-0.15, 0.15; 1.07; C
-0.15, 0.15; 0.515383333333; C
-0.15, 0.15; 0.879183333333; C
-0.15, 0.15; 1.01828333333; C
-0.15, 0.15; 0.517166666667; C

0.15, 0.15; 0.980833333333; D
0.15, 0.15; 0.515383333333; D
0.15, 0.15; 0.9416; D
0.15, 0.15; 0.987966666667; D
0.15, 0.15; 0.504683333333; D

0, -0.1; 1.59608333333; A
0, -0.1; 0.4708; A
0, -0.1; 1.00936666667; A
0, -0.1; 2.0544; A
0, -0.1; 0.552833333333; A
0, -0.1; 0.89345; A
0, -0.1; 0.542133333333; A

0, 0.1; 1.49978333333; D
0, 0.1; 0.477933333333; D
0, 0.1; 0.52965; D
0, 0.1; 0.961216666667; D
0, 0.1; 0.980833333333; D
0, 0.1; 1.05216666667; D
0, 0.1; 0.980833333333; D
0, 0.1; 0.998666666667; D
0, 0.1; 0.977266666667; D

0, 0; 1.98128333333; A
0, 0; 0.527866666667; A
0, 0; 0.74365; A
0, 0; 0.741866666667; A
0, 0; 1.10566666667; A
0, 0; 0.447616666667; A
0, 0; 0.488633333333; A
0, 0; 0.939816666667; A

0.15, -0.15; 2.02765; B
0.15, -0.15; 0.463666666667; B
0.15, -0.15; 0.483283333333; B
0.15, -0.15; 1.03968333333; B

-0.15, -0.15; 1.93491666667; C
-0.15, -0.15; 0.515383333333; C
-0.15, -0.15; 0.526083333333; C
-0.15, -0.15; 1.01293333333; C
-0.15, -0.15; 0.954083333333; C

0, 0.15; 2.02943333333; D
0, 0.15; 0.510033333333; D
0, 0.15; 1.02185; D

0, 0; 2.05618333333; A
0, 0; 0.451183333333; A
0, 0; 0.948733333333; A

0, 0; 2.05083333333; A
0, 0; 0.445833333333; A
0, 0; 0.5778; A
0, 0; 0.955866666667; A
0, 0; 1.02363333333; A
0, 0; 0.998666666667; A
0, 0; 0.948733333333; A
0, 0; 1.06286666667; A
0, 0; 1.00936666667; A
0, 0; 0.526083333333; A

#espiral
0, -0.20; 1.51226666667; A
0.05, -0.15; 0.986183333333; A
0.10, -0.10; 0.966566666667; A
0.15, -0.05; 0.51895; A
0.20, 0; 1.48908333333; B
0.15, 0.05; 0.980833333333; B
0.10, 0.10; 1.5622; B
0.05, 0.15; 0.996883333333; B
0, 0.20; 0.485066666667; D
-0.05, 0.15; 0.9095; D
-0.10, 0.10; 1.0165; D
-0.15, 0.05; 2.033; D
-0.20, 0; 0.982616666667; C
-0.12, 0; 1.07178333333; C
-0.07, 0; 0.55105; C

0, -0.15; 1.41775; A
0, -0.15; 0.966566666667; A
0, -0.15; 1.04503333333; A
0, -0.15; 0.522516666667; A
0, -0.15; 1.00223333333; A
0, -0.15; 0.526083333333; A

0.15, -0.15; 0.884533333333; B
0.15, -0.15; 1.07891666667; B
0.15, -0.15; 0.501116666667; B
0.15, -0.15; 0.980833333333; B
0.15, -0.15; 0.485066666667; B

0, -0.15; 1.04681666667; A
0, -0.15; 0.959433333333; A
0, -0.15; 1.00936666667; A
0, -0.15; 0.998666666667; A
0, -0.15; 0.980833333333; A
0, -0.15; 0.506466666667; A
0, -0.15; 0.458316666667; A
0, -0.15; 0.559966666667; A

-0.15, -0.15; 0.961216666667; C
-0.15, -0.15; 0.527866666667; C
-0.15, -0.15; 0.9202; C
-0.15, -0.15; 1.00936666667; C
-0.15, -0.15; 0.533216666667; C

0, 0; 1.54615; A
0, 0; 1.00758333333; A
0, 0; 1.55328333333; A
0, 0; 0.971916666667; A
0, 0; 0.506466666667; A
0, 0; 0.916633333333; A
0, 0; 0.961216666667; A

-0.15, 0.15; 1.57468333333; C
-0.15, 0.15; 0.56175; C
-0.15, 0.15; 0.95765; C

0, 0.15; 1.0593; D
0, 0.15; 0.488633333333; D
0, 0.15; 0.9737; D
0, 0.15; 0.493983333333; D
0, 0.15; 0.9416; D

0.15, 0.15; 1.01471666667; B
0.15, 0.15; 0.56175; B
0.15, 0.15; 0.970133333333; B
0.15, 0.15; 0.51895; B
0.15, 0.15; 0.8667; B

0, 0.15; 1.06465; D
0, 0.15; 0.542133333333; D
0, 0.15; 1.06465; D
0, 0.15; 0.451183333333; D
0, 0.15; 0.948733333333; D

-0.15, 0.15; 0.977266666667; C
-0.15, 0.15; 1.08248333333; C
-0.15, 0.15; 1.0058; C
-0.15, 0.15; 0.9951; C
-0.15, 0.15; 0.4815; C
-0.15, 0.15; 0.47615; C
-0.15, 0.15; 0.510033333333; C

0, 0; 1.49265; A
0, 0; 0.535; A
0, 0; 0.938033333333; A
0, 0; 0.511816666667; A
0, 0; 1.02898333333; A

0, 0; 0.966566666667; D
0, 0; 0.520733333333; D
0, 0; 0.977266666667; D
0, 0; 0.501116666667; D
0, 0; 0.998666666667; D

0.15, -0.15; 1.00758333333; A
0.15, -0.15; 0.5243; A
0.15, -0.15; 0.92555; A
0.15, -0.15; 0.531433333333; A
0.15, -0.15; 1.05573333333; A

0.15, 0.15; 1.03968333333; B
0.15, 0.15; 0.479716666667; B
0.15, 0.15; 0.929116666667; B
0.15, 0.15; 0.495766666667; B
0.15, 0.15; 0.97905; B

-0.15, -0.15; 1.01828333333; C
-0.15, -0.15; 0.49755; C
-0.15, -0.15; 0.938033333333; C
-0.15, -0.15; 0.511816666667; C
-0.15, -0.15; 1.08961666667; C

-0.15, 0.15; 0.993316666667; D
-0.15, 0.15; 0.515383333333; D
-0.15, 0.15; 0.954083333333; D
-0.15, 0.15; 0.506466666667; D
-0.15, 0.15; 0.982616666667; D

0, 0; 1.54793333333; A
0, 0; 0.5136; A
0, 0; 0.90415; A
0, 0; 1.54258333333; A
0, 0; 0.51895; A
0, 0; 0.9951; A
0, 0; 0.52965; A

0, 0; 0.964783333333; D
0, 0; 1.61926666667; D
0, 0; 0.911283333333; D
0, 0; 0.991533333333; D
0, 0; 0.533216666667; D
-0.15, 0; 1.4659; C
0.15, 0; 1.00936666667; B

0, 0; 1.54793333333; A
0, 0; 1.49978333333; A
0, 0; 0.938033333333; A
0, 0; 0.977266666667; A
0, 0; 0.536783333333; A
0.15, 0; 1.44628333333; B
-0.15, 0; 0.998666666667; C

0, 0; 1.00223333333; D
0, 0; 0.54035; D
-0.1, 0; 1.52831666667; C
0.1, 0; 0.971916666667; B

0, 0; 1.59073333333; A
0.1, 0; 1.43023333333; B
-0.1, 0; 0.991533333333; C

0, 0; 1.6264; D
-0.1, 0; 1.498; C
0.1, 0; 1.11636666667; B

0, 0; 1.56576666667; A
0, 0; 1.58538333333; A"""
		"rirura_2":
			return """#Musica 'rirura_2.mp3' salva no diretorio 'rirura_2'

0, 0; 6.5021; A
0, 0; 1.9941; A
0, 0; 1.9389; A
0, 0; 2.0148; A
0, 0; 2.0148; A
0, 0; 2.0608; A
0, 0; 2.0125; A
0, 0; 1.9918; A
0, 0; 2.0585; A
0, 0; 1.9711; A
0, 0; 2.1298; A
0, 0; 2.0309; A
0, 0; 1.9205; A
0, 0; 1.9895; A

0.15, 0.12; 2.0148; B
0.15, -0.12; 0.9269; B
-0.15, 0.12; 3.082; C
-0.15, -0.12; 0.9913; C
0.15, 0.12; 3.036; B
0.15, -0.12; 0.9269; B
-0.15, 0.12; 3.1694; C
-0.15, -0.12; 0.9292; C
0.15, 0.12; 3.0291; B
0.15, -0.12; 0.9246; B
-0.15, 0.12; 3.1096; C
-0.15, -0.12; 0.9453; C
0.15, 0.12; 3.0314; B
0.15, -0.12; 0.9269; B
0, 0; 3.0797; A
0, 0; 2.0125; A

0, -0.17; 2.0608; A
0.17, 0; 2.0125; B
0, 0.17; 1.9228; D
-0.17, 0; 2.0378; C
0, -0.17; 2.0539; A
0.17, 0; 1.9458; B
0, 0.17; 2.0332; D
-0.17, 0; 1.8768; C
0, -0.17; 2.1735; A
0.17, 0; 1.9895; B
0, 0.17; 1.9895; D
-0.17, 0; 2.0079; C
0, -0.17; 2.0355; A
0.17, 0; 2.0401; B
0, 0.17; 1.9895; D
-0.17, 0; 1.9435; C

-0.15, 0.12; 1.9895; C
-0.15, -0.12; 0.9913; C
0.15, 0.12; 2.967; B
0.15, -0.12; 1.0603; B
-0.15, 0.12; 3.0107; C
-0.15, -0.12; 0.9752; C
0.15, 0.12; 3.0728; B
0.15, -0.12; 0.9775; B
-0.15, 0.12; 3.0245; C
-0.15, -0.12; 0.9775; C
0.15, 0.12; 3.0774; B
0.15, -0.12; 0.9683; B
-0.15, 0.12; 3.0084; C
-0.15, -0.12; 0.9499; C
0, 0; 3.1004; A
0, 0; 2.0125; A

0, -0.17; 1.9941; A
-0.17, 0; 2.0125; C
0, 0.17; 1.9688; D
0.17, 0; 2.0332; B
0, -0.17; 2.0631; A
-0.17, 0; 1.9918; C
0, 0.17; 2.0102; D
0.17, 0; 2.0608; B
0, -0.17; 1.9251; A
-0.17, 0; 1.9481; C
0, 0.17; 2.0378; D
0.17, 0; 2.0539; B
0, -0.17; 1.9918; A
-0.17, 0; 2.0332; C
0, 0.17; 1.9734; D
0.17, 0; 1.9895; B

-0.15, -0.12; 2.0378; C
-0.15, -0.12; 1.0143; C
-0.15, -0.12; 1.0235; C
-0.15, -0.12; 2.0309; C
-0.15, -0.12; 1.9481; C
-0.15, -0.12; 2.0171; C

0, 0; 1.0189; D
0, 0; 0.6233; D
0, 0; 1.3179; D
0, 0; 2.0148; D
0, 0; 0.6279; D
0, 0; 1.3432; D

0.15, 0.12; 1.9872; B
0.15, 0.12; 2.0608; B
0.15, 0.12; 2.0401; B
0.15, 0.12; 2.0148; B

0, 0; 1.9918; D
0, 0; 0.6233; D
0, 0; 1.3179; D
0, 0; 2.0148; D
0, 0; 0.6279; D
0, 0; 1.3432; D

-0.15, -0.12; 1.9872; C
-0.15, -0.12; 2.0631; C
-0.15, -0.12; 2.0608; C
-0.15, -0.12; 2.0171; C

0, 0; 1.9941; D
0, 0; 0.7153; D
0, 0; 1.3616; D
0, 0; 1.9688; D
0, 0; 0.6532; D
0, 0; 1.4582; D

0.15, 0; 1.9366; B
0.15, 0; 1.9182; B
0.15, 0; 1.978; B
0.15, 0; 2.0355; B
0.15, 0; 1.9435; B
0.15, 0; 2.1229; B

0, 0; 1.9228; A
0, 0; 0.6509; A
0, 0; 1.4536; A

-0.15, 0; 1.9872; C
-0.15, 0; 1.9941; C

0, 0; 2.0608; D
0, 0; 0.6187; D
0, 0; 1.5088; D

0.15, 0; 1.9895; B
0.15, 0; 1.9619; B

0, 0; 2.0378; A
0, 0; 0.5819; A
0, 0; 1.3662; A

0, -0.18; 2.1022; A
0.18, 0; 2.0355; B
-0.18, 0; 2.0424; C
0, 0.18; 2.04516; D"""
		"training":
			return """#Musica 'training.mp3' salva no diretorio 'training'

#inicio
0, 0; 4.4115; A
0, 0; 4.2517; B
0, 0; 4.1939; D

#comeca loop
-0.18, 0; 4.2891; C
0, 0.18; 2.1726; D
0.18, 0; 2.0621; B
0, -0.18; 2.1454; A
-0.18, 0; 1.9754; C
0, -0.18; 2.1743; A
0.18, 0; 2.1896; B
0, 0.18; 2.1607; D
-0.18, 0; 2.1454; C
0, 0.18; 2.1046; D
0.18, 0; 2.0808; B
0, -0.18; 2.1539; A

#finaliza
0, 0; 2.1505; C
0, 0; 2.0621; A
0, 0; 1.9754; B
0, 0; 2.3307; D"""
		_:
			return "# Fallback - no specific ring data available\n0, 0; 4.0; A\n0.1, 0; 1.0; B\n-0.1, 0; 1.0; C\n0, 0.1; 1.0; D\n0, -0.1; 1.0; A"
	return ""

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
