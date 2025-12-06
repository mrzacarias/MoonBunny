extends Control

# Level select screen matching original MoonBunny design exactly

# UI Elements (from scene file)
@onready var background_image = $Background
@onready var title_text = $TitleLabel  
@onready var level_container = $LevelContainer
@onready var arrow_left = $ArrowLeft
@onready var arrow_right = $ArrowRight

# State
var available_levels: Array[String] = []
var current_level_index: int = 0
var level_items: Array[Control] = []
var level_container_tween: Tween
var menu_sound: AudioStream
var pulse_tween: Tween

# Original constants
const ITEM_SPACING = 540.0  # 400 + 140px padding between items

# Font resource
var moonbunny_font: FontFile

func _ready():
	# Load menu sound
	menu_sound = load("res://assets/sounds/menu.wav")
	
	# Load font directly from TTF
	moonbunny_font = load("res://assets/fonts/HUM521BC.TTF")
	
	# Load available levels but don't create UI yet
	load_available_levels()
	
	# Connect to visibility changes to setup UI when screen is shown
	visibility_changed.connect(_on_visibility_changed)
	
	# If already visible, setup immediately
	if visible:
		_setup_when_visible()

func _on_visibility_changed():
	if visible and level_items.is_empty():
		_setup_when_visible()

func _setup_when_visible():
	
	# Adjust container size to accommodate horizontal scrolling
	level_container.position = Vector2(0, 200)  # Full width, positioned below title
	level_container.size = Vector2(get_viewport().size.x, 600)  # Full width, tall enough for items
	
	# Adjust arrow positions to be closer to screen edges
	var screen_width = get_viewport().size.x
	arrow_left.position.x = 50  # 200px closer to left edge (was ~256px, now 50px)
	arrow_right.position.x = screen_width - 114  # 200px closer to right edge (was ~1024px, now ~1166px)
	
	# Ensure both arrows have the same size
	arrow_left.size = Vector2(64, 64)
	arrow_right.size = Vector2(64, 64)
	arrow_left.scale = Vector2(1.0, 1.0)
	arrow_right.scale = Vector2(1.0, 1.0)
	
	
	# Setup level items only when screen is actually visible
	setup_level_items()
	update_display()

func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_left") and current_level_index > 0:
		current_level_index -= 1
		play_menu_sound()
		update_display()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") and current_level_index < available_levels.size() - 1:
		current_level_index += 1
		play_menu_sound()
		update_display()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_play_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

# setup_ui() removed - using scene elements instead

func play_menu_sound():
	if menu_sound:
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = menu_sound
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)

func load_available_levels():
	available_levels.clear()
	
	# Check for levels in the assets/levels directory
	var levels_dir = "res://assets/levels/"
	var dir = DirAccess.open(levels_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				# Check if this directory has a header.lvl file and exclude training
				var header_path = levels_dir + file_name + "/header.lvl"
				if FileAccess.file_exists(header_path) and file_name != "training":
					available_levels.append(file_name)
			file_name = dir.get_next()
	
	# If no levels found, add some default ones for testing
	if available_levels.is_empty():
		available_levels = ["7stars", "green_hill_zone", "bang_bang"]

func setup_level_items():
	"""Create level items exactly like original MoonBunny"""
	for i in range(available_levels.size()):
		var level_name = available_levels[i]
		var level_data = load_level_header(level_name)
		
		# Create level item container (taller to fit text below image)
		var level_item = Control.new()
		level_item.size = Vector2(350, 500)  # Taller for text below
		level_item.position.x = i * ITEM_SPACING
		level_item.scale = Vector2(1.0, 1.0)  # Remove scaling temporarily to test positioning
		
		# Level image (512x362 scaled like original)
		var image_path = "res://assets/levels/" + level_name + "/image.png"
		if FileAccess.file_exists(image_path):
			var level_image = TextureRect.new()
			level_image.texture = load(image_path)
			level_image.size = Vector2(300, 212)  # Scaled from 512x362
			level_image.position = Vector2(25, 20)
			level_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			level_item.add_child(level_image)
		else:
			# Placeholder
			var placeholder = ColorRect.new()
			placeholder.size = Vector2(300, 212)
			placeholder.position = Vector2(25, 20)
			placeholder.color = Color(0.2, 0.3, 0.5, 1.0)
			level_item.add_child(placeholder)
		
		# Text positioning - much larger gap below the image (2x more)
		# Image: Y=20 to Y=232 (height 212), add ~212px gap (full image height)
		var text_y = 450  # Image ends at 232 + 212px gap = 444, round to 450
		var line_spacing = 35
		
		# Debug removed for cleaner output
		
		# Title text (like original) - much larger and below image
		var title_str = level_data.get("TITLE", level_name.replace("_", " ").capitalize())
		var title_label = Label.new()
		title_label.text = title_str
		title_label.position = Vector2(90, text_y)  # Move 90px right for better centering
		title_label.size = Vector2(350, 35)  # Full container width for better centering
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			title_label.add_theme_font_override("font", moonbunny_font)
		title_label.add_theme_font_size_override("font_size", 32)  # Much larger
		title_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(title_label)
		text_y += line_spacing
		
		# Artist text (like original) - below title
		if level_data.has("ARTIST"):
			var artist_str = "by " + level_data["ARTIST"]
			var artist_label = Label.new()
			artist_label.text = artist_str
			artist_label.position = Vector2(90, text_y)  # Move 90px right for better centering
			artist_label.size = Vector2(350, 30)  # Full container width for better centering
			artist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if moonbunny_font:
				artist_label.add_theme_font_override("font", moonbunny_font)
			artist_label.add_theme_font_size_override("font_size", 24)  # Larger
			artist_label.add_theme_color_override("font_color", Color.WHITE)
			level_item.add_child(artist_label)
			text_y += line_spacing
		
		# BPM text (like original)
		var bpm_text = "BPM %.2f" % level_data.get("BPM", 120.0)
		var bpm_label = Label.new()
		bpm_label.text = bpm_text
		bpm_label.position = Vector2(90, text_y)  # Move 90px right for better centering
		bpm_label.size = Vector2(350, 30)  # Full container width for better centering
		bpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			bpm_label.add_theme_font_override("font", moonbunny_font)
		bpm_label.add_theme_font_size_override("font_size", 26)
		bpm_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(bpm_label)
		text_y += line_spacing
		
		# Add high score display like original (placeholder for now)
		var max_rank_label = Label.new()
		max_rank_label.text = "max rank A"  # TODO: Load from save data
		max_rank_label.position = Vector2(90, text_y)  # Move 90px right for better centering
		max_rank_label.size = Vector2(350, 25)  # Full container width for better centering
		max_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			max_rank_label.add_theme_font_override("font", moonbunny_font)
		max_rank_label.add_theme_font_size_override("font_size", 24)
		max_rank_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(max_rank_label)
		text_y += line_spacing - 5  # Slightly closer spacing
		
		var hiscore_label = Label.new()
		hiscore_label.text = "hiscore 39994"  # TODO: Load from save data
		hiscore_label.position = Vector2(90, text_y)  # Move 90px right for better centering
		hiscore_label.size = Vector2(350, 25)  # Full container width for better centering
		hiscore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			hiscore_label.add_theme_font_override("font", moonbunny_font)
		hiscore_label.add_theme_font_size_override("font_size", 24)
		hiscore_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(hiscore_label)
		
		level_container.add_child(level_item)
		level_items.append(level_item)
		
		# Level item created successfully

func update_display():
	"""Update display like original MoonBunny with proper animations"""
	# Update arrow visibility/transparency like original
	if current_level_index < 1:
		arrow_left.modulate.a = 0.0
	else:
		arrow_left.modulate.a = 1.0
		
	if current_level_index >= available_levels.size() - 1:
		arrow_right.modulate.a = 0.0
	else:
		arrow_right.modulate.a = 1.0
	
	# Animate container position (horizontal scrolling like original)
	if level_container_tween:
		level_container_tween.kill()
	
	level_container_tween = create_tween()
	level_container_tween.set_parallel(true)
	
	# Center the current item properly - optimal centering at -280 offset
	var target_x = -current_level_index * ITEM_SPACING + (get_viewport().size.x / 2 - 280)
	level_container_tween.tween_property(level_container, "position:x", target_x, 0.2)
	
	# Reset all scales first - temporarily disable scaling
	for i in range(level_items.size()):
		var item = level_items[i]
		level_container_tween.tween_property(item, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Start pulsing animation for current item (like original)
	start_pulse_animation()

# Signals for communication with Main
signal level_selected(level_name: String)
signal back_to_menu

func _on_play_pressed():
	get_viewport().set_input_as_handled()
	if current_level_index < available_levels.size():
		var level_name = available_levels[current_level_index]
		level_selected.emit(level_name)

func _on_back_pressed():
	get_viewport().set_input_as_handled()
	back_to_menu.emit()

func start_pulse_animation():
	"""Start pulsing animation for current item like original"""
	if pulse_tween:
		pulse_tween.kill()
	
	if current_level_index < level_items.size():
		var current_item = level_items[current_level_index]
		pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_property(current_item, "scale", Vector2(1.05, 1.05), 0.4)
		pulse_tween.tween_property(current_item, "scale", Vector2(1.0, 1.0), 0.4)

func load_level_header(level_name: String) -> Dictionary:
	"""Load level header data like original parse.level_header()"""
	var header_path = "res://assets/levels/" + level_name + "/header.lvl"
	var level_data = {}
	
	if FileAccess.file_exists(header_path):
		var file = FileAccess.open(header_path, FileAccess.READ)
		if file:
			while not file.eof_reached():
				var line = file.get_line().strip_edges()
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
			file.close()
	
	# Set defaults
	level_data["NAME"] = level_name
	if not level_data.has("TITLE"):
		level_data["TITLE"] = level_name.replace("_", " ").capitalize()
	if not level_data.has("BPM"):
		level_data["BPM"] = 120.0
	
	return level_data
