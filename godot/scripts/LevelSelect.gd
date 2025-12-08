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

# Responsive constants - adjust based on viewport width
func get_item_spacing() -> float:
	var screen_width = get_viewport().size.x
	# Scale item spacing based on screen width
	# Original: 540px for 1280px screen (42% of screen width)
	# For smaller screens, use a smaller percentage to fit better
	if screen_width <= 960:
		return screen_width * 0.35  # 35% of screen width for smaller screens
	else:
		return screen_width * 0.42  # 42% of screen width for larger screens

# Font resource
var moonbunny_font: FontFile

# Using global LevelResourceManager for HTML export compatibility

func _ready():
	print("LevelSelect: _ready called")
	
	# Load menu sound
	menu_sound = load("res://assets/sounds/menu.wav")
	
	# Load font directly from TTF
	moonbunny_font = load("res://assets/fonts/HUM521BC.TTF")
	
# Resources are now preloaded by LevelResourceManager autoload
	
	# Load available levels but don't create UI yet
	load_available_levels()
	
	# Connect to visibility changes to setup UI when screen is shown
	visibility_changed.connect(_on_visibility_changed)
	
	# If already visible, setup immediately
	if visible:
		_setup_when_visible()

func _on_visibility_changed():
	print("LevelSelect: visibility changed - visible: ", visible, " level_items.is_empty(): ", level_items.is_empty())
	if visible and level_items.is_empty():
		_setup_when_visible()

func _setup_when_visible():
	print("LevelSelect: _setup_when_visible called")
	
	# Title and container positioning is now handled by the scene file
	# No need to override positioning here
	
	# Fix arrow positions to be properly visible and responsive
	var screen_width = get_viewport().size.x
	var screen_height = get_viewport().size.y
	
	if arrow_left:
		arrow_left.position.x = 50  # Fixed distance from left edge
		arrow_left.position.y = screen_height / 2 - 32  # Center vertically
		arrow_left.size = Vector2(64, 64)
		arrow_left.scale = Vector2(1.0, 1.0)
	
	if arrow_right:
		arrow_right.position.x = screen_width - 114  # Fixed distance from right edge (64px width + 50px margin)
		arrow_right.position.y = screen_height / 2 - 32  # Center vertically
		arrow_right.size = Vector2(64, 64)
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
	# Get available levels from the global resource manager
	available_levels = LevelResourceManager.get_available_levels()
	print("LevelSelect: Available levels: ", available_levels)

func setup_level_items():
	"""Create level items exactly like original MoonBunny"""
	for i in range(available_levels.size()):
		var level_name = available_levels[i]
		var level_data = load_level_header(level_name)
		
		# Create level item container (taller to fit text below image)
		var level_item = Control.new()
		var item_width = get_item_spacing() * 0.65  # Item width is 65% of spacing
		level_item.size = Vector2(item_width, 500)  # Responsive width, fixed height
		level_item.position.x = i * get_item_spacing()
		level_item.scale = Vector2(1.0, 1.0)  # Remove scaling temporarily to test positioning
		
		# Level image (512x362 scaled like original)
		var level_texture = LevelResourceManager.get_level_image(level_name)
		var image_width = item_width * 0.85  # Image is 85% of item width
		var image_height = image_width * 0.707  # Maintain 512x362 aspect ratio (362/512 = 0.707)
		var image_x = (item_width - image_width) / 2  # Center horizontally
		
		# Debug output to understand positioning
		print("LevelSelect Debug - item_width: ", item_width, ", image_width: ", image_width, ", image_x: ", image_x)
		
		# Variables for text positioning (will be set based on actual image size)
		var text_x: float
		var text_width: float
		
		# Get texture from LevelResourceManager (works in web exports)
		var texture = LevelResourceManager.get_level_image(level_name)
		if texture:
			var original_size = texture.get_size()
			var target_size = Vector2(original_size.x * 0.84375, original_size.y * 0.84375)  # 0.84375 scaling from working version
			
			var level_image = NinePatchRect.new()
			level_image.texture = texture
			level_image.position = Vector2(image_x, 20)  # Use calculated position
			level_image.size = target_size
			level_item.add_child(level_image)
			
			print("LevelSelect: Image ", level_name, " - Original: ", original_size, " -> 84.375%: ", target_size)
			print("LevelSelect: Image position: ", level_image.position, ", size: ", level_image.size)
			print("LevelSelect: Image actual bounds: X=", level_image.position.x, " to ", level_image.position.x + level_image.size.x)
			
			# Set text positioning using the ACTUAL image size
			var actual_image_width = target_size.x  # Use the actual target_size width
			text_x = image_x  # Align with image left edge
			text_width = actual_image_width  # Use full actual image width
			
			print("LevelSelect Debug - Using actual image width: ", actual_image_width)
			print("LevelSelect Debug - Text positioning: X=", text_x, ", width=", text_width)
		else:
			# Blue placeholder if no image
			var placeholder = ColorRect.new()
			placeholder.position = Vector2(image_x, 20)
			placeholder.size = Vector2(image_width, image_height)
			placeholder.color = Color(0.2, 0.3, 0.5, 1.0)
			level_item.add_child(placeholder)
			print("LevelSelect: Using placeholder for level: ", level_name)
			
			# For placeholder, use the calculated image_width
			text_x = image_x
			text_width = image_width
			
			print("LevelSelect Debug - Using placeholder width: ", image_width)
			print("LevelSelect Debug - Text positioning: X=", text_x, ", width=", text_width)
		
		# Text positioning - closer to the image
		# Image: Y=20 to Y=452 (height 432), reduce gap to bring text closer
		var text_y = 400  # Image ends at 452, add smaller gap to bring text closer
		var line_spacing = 35
		
		# Debug removed for cleaner output
		
		# Title text (like original) - much larger and below image
		var title_str = level_data.get("TITLE", level_name.replace("_", " ").capitalize())
		var title_label = Label.new()
		title_label.text = title_str
		title_label.position = Vector2(text_x, text_y)  # Align with adjusted image position
		title_label.size = Vector2(text_width, 35)  # Match adjusted text width for proper centering
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			title_label.add_theme_font_override("font", moonbunny_font)
		title_label.add_theme_font_size_override("font_size", 38)  # 20% larger (32 * 1.2)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(title_label)
		text_y += line_spacing
		
		# Artist text (like original) - below title
		if level_data.has("ARTIST"):
			var artist_str = "by " + level_data["ARTIST"]
			var artist_label = Label.new()
			artist_label.text = artist_str
			artist_label.position = Vector2(text_x, text_y)  # Align with adjusted image position
			artist_label.size = Vector2(text_width, 30)  # Match adjusted text width for proper centering
			artist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if moonbunny_font:
				artist_label.add_theme_font_override("font", moonbunny_font)
			artist_label.add_theme_font_size_override("font_size", 29)  # 20% larger (24 * 1.2)
			artist_label.add_theme_color_override("font_color", Color.WHITE)
			level_item.add_child(artist_label)
			text_y += line_spacing
		
		# BPM text (like original)
		var bpm_text = "BPM %.2f" % level_data.get("BPM", 120.0)
		var bpm_label = Label.new()
		bpm_label.text = bpm_text
		bpm_label.position = Vector2(text_x, text_y)  # Align with adjusted image position
		bpm_label.size = Vector2(text_width, 30)  # Match adjusted text width for proper centering
		bpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			bpm_label.add_theme_font_override("font", moonbunny_font)
		bpm_label.add_theme_font_size_override("font_size", 31)  # 20% larger (26 * 1.2)
		bpm_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(bpm_label)
		text_y += line_spacing
		
		# Add high score display like original (placeholder for now)
		var max_rank_label = Label.new()
		max_rank_label.text = "max rank A"  # TODO: Load from save data
		max_rank_label.position = Vector2(text_x, text_y)  # Align with adjusted image position
		max_rank_label.size = Vector2(text_width, 25)  # Match adjusted text width for proper centering
		max_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			max_rank_label.add_theme_font_override("font", moonbunny_font)
		max_rank_label.add_theme_font_size_override("font_size", 29)  # 20% larger (24 * 1.2)
		max_rank_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(max_rank_label)
		text_y += line_spacing - 5  # Slightly closer spacing
		
		var hiscore_label = Label.new()
		hiscore_label.text = "hiscore 39994"  # TODO: Load from save data
		hiscore_label.position = Vector2(text_x, text_y)  # Align with adjusted image position
		hiscore_label.size = Vector2(text_width, 25)  # Match adjusted text width for proper centering
		hiscore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if moonbunny_font:
			hiscore_label.add_theme_font_override("font", moonbunny_font)
		hiscore_label.add_theme_font_size_override("font_size", 29)  # 20% larger (24 * 1.2)
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
	
	# Center the current item properly - align with the "Select Level" title
	var screen_width = get_viewport().size.x
	var item_spacing = get_item_spacing()
	var item_width = item_spacing * 0.65  # Item width is 65% of spacing
	
	# Center the current item: screen center minus half item width minus current item position
	var screen_center = screen_width / 2
	var current_item_position = current_level_index * item_spacing
	var item_center_offset = item_width / 2
	var target_x = screen_center - current_item_position - item_center_offset
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
	print("LevelSelect: _on_play_pressed called - current_level_index: ", current_level_index, " available_levels: ", available_levels)
	get_viewport().set_input_as_handled()
	if current_level_index < available_levels.size():
		var level_name = available_levels[current_level_index]
		print("LevelSelect: Selecting level: ", level_name)
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
	"""Load level header data from global resource manager"""
	return LevelResourceManager.parse_level_header(level_name)
