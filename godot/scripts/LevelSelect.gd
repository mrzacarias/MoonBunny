extends Control

# Simple Level Select Screen - Clean and straightforward approach

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

# Responsive constants based on viewport size
var item_spacing: float
var image_size: Vector2
var font_size_title: int
var font_size_info: int
var effective_viewport_size: Vector2  # Store the corrected viewport size for centering

# Font resource
var moonbunny_font: FontFile

# Touch debouncing
var last_touch_time: float = 0.0
const TOUCH_DEBOUNCE_TIME: float = 0.3  # 300ms debounce

func _ready():
	# Load font
	moonbunny_font = load("res://assets/fonts/HUM521BC.TTF")
	
	# Load menu sound
	menu_sound = load("res://assets/sounds/menu.wav")
	
	# Calculate responsive sizes based on viewport
	calculate_responsive_sizes()
	
	# Load available levels
	load_available_levels()
	
	# Setup UI when visible
	visibility_changed.connect(_on_visibility_changed)
	if visible:
		setup_level_items()
		update_display()

func _on_visibility_changed():
	if visible:
		# Always reload high scores when level select becomes visible
		HighScoreManager.load_high_scores()
		
		if level_items.is_empty():
			calculate_responsive_sizes()  # Recalculate on visibility change
			setup_level_items()
			update_display()
		else:
			# Refresh high scores and rebuild level items to show updated scores
			setup_level_items()
			update_display()

func calculate_responsive_sizes():
	"""Calculate responsive sizes based on viewport dimensions"""
	var viewport_size = get_viewport().size
	var base_width = 1024.0  # Base reference width
	
	# HTML-specific viewport handling
	if OS.get_name() == "Web":
		# Force HTML to use 960x720 as reference since that's the actual canvas size
		viewport_size = Vector2(960, 720)
	
	# Store the effective viewport size for centering calculations
	effective_viewport_size = viewport_size
	
	var scale_factor = viewport_size.x / base_width
	
	# Ensure minimum scale for readability
	scale_factor = max(scale_factor, 0.6)
	
	# Calculate responsive values (15% smaller than before)
	item_spacing = 600.0 * scale_factor * 0.85
	image_size = Vector2(469, 469) * scale_factor * 0.85
	font_size_title = int(54 * scale_factor * 0.85)
	font_size_info = int(41 * scale_factor * 0.85)

func _input(event):
	if not visible:
		return
	
	# Simple input handling
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
	
	# Handle mouse clicks
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_mouse_click(event.position)
		get_viewport().set_input_as_handled()
	
	# Handle touch input with debouncing
	elif event is InputEventScreenTouch and event.pressed:
		var current_time = Time.get_time_dict_from_system()
		var current_timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second + current_time.millisecond / 1000.0
		
		# Debounce touch input to prevent double-touches
		if current_timestamp - last_touch_time > TOUCH_DEBOUNCE_TIME:
			last_touch_time = current_timestamp
			handle_mouse_click(event.position)  # Same logic as mouse
		get_viewport().set_input_as_handled()
	
	# Handle mouse hover for level selection
	elif event is InputEventMouseMotion:
		handle_mouse_hover(event.position)

func load_available_levels():
	available_levels.clear()
	
	# Use LevelResourceManager which handles HTML compatibility
	available_levels = LevelResourceManager.get_available_levels()

func setup_level_items():
	"""Create level items with simple, clean logic"""
	# Clear existing items
	for item in level_items:
		if item:
			item.queue_free()
	level_items.clear()
	
	for child in level_container.get_children():
		child.queue_free()
	
	# Create items with simple positioning
	for i in range(available_levels.size()):
		var level_name = available_levels[i]
		var level_data = load_level_header(level_name)
		
		# Create main container
		var level_item = Control.new()
		var container_height = image_size.y + 200  # Dynamic height based on image size
		level_item.size = Vector2(item_spacing, container_height)
		level_item.position = Vector2(i * item_spacing, 0)  # Simple spacing
		
		# Create image using NinePatchRect
		var level_image = NinePatchRect.new()
		
		# Use LevelResourceManager which handles HTML compatibility
		var texture = LevelResourceManager.get_level_image(level_name)
		
		if texture and texture is Texture2D:
			level_image.texture = texture
		else:
			# Create a simple colored rectangle as fallback
			var placeholder = ColorRect.new()
			placeholder.color = Color(0.2, 0.3, 0.5, 1.0)
			placeholder.size = image_size
			placeholder.position = Vector2((item_spacing - image_size.x) / 2, 20)
			level_item.add_child(placeholder)
			level_image = null
		
		if level_image:
			level_image.size = image_size
			level_image.position = Vector2((item_spacing - image_size.x) / 2, 20)  # Center horizontally
			level_item.add_child(level_image)
		
		# Create text labels - all centered under the image (20px closer)
		var text_y = image_size.y - 20
		var text_width = item_spacing - 40  # Leave margins
		var text_x = 20
		
		# Title
		var title_label = Label.new()
		title_label.text = level_data.get("TITLE", level_name.replace("_", " ").capitalize())
		title_label.position = Vector2(text_x, text_y)
		var title_height = font_size_title + 10  # Dynamic height based on font size
		title_label.size = Vector2(text_width, title_height)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_override("font", moonbunny_font)
		title_label.add_theme_font_size_override("font_size", font_size_title)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(title_label)
		text_y += title_height + 10  # Dynamic spacing
		
		# Declare info_height for reuse
		var info_height: int
		
		# Artist
		if level_data.has("ARTIST"):
			var artist_label = Label.new()
			artist_label.text = "by " + level_data["ARTIST"]
			artist_label.position = Vector2(text_x, text_y)
			info_height = font_size_info + 8  # Dynamic height based on font size
			artist_label.size = Vector2(text_width, info_height)
			artist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			artist_label.add_theme_font_override("font", moonbunny_font)
			artist_label.add_theme_font_size_override("font_size", font_size_info)
			artist_label.add_theme_color_override("font_color", Color.WHITE)
			level_item.add_child(artist_label)
			text_y += info_height + 8  # Dynamic spacing
		
		# BPM
		var bpm_label = Label.new()
		bpm_label.text = "BPM " + str(level_data.get("BPM", 120))
		bpm_label.position = Vector2(text_x, text_y)
		info_height = font_size_info + 8  # Reuse the already declared variable
		bpm_label.size = Vector2(text_width, info_height)
		bpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bpm_label.add_theme_font_override("font", moonbunny_font)
		bpm_label.add_theme_font_size_override("font_size", font_size_info)
		bpm_label.add_theme_color_override("font_color", Color.WHITE)
		level_item.add_child(bpm_label)
		text_y += info_height + 8  # Dynamic spacing
		
		# High Score (if exists)
		if HighScoreManager.has_high_score(level_name):
			var high_score_label = Label.new()
			high_score_label.text = HighScoreManager.get_high_score_text(level_name)
			high_score_label.position = Vector2(text_x, text_y)
			var high_score_height = font_size_info + 8  # Dynamic height based on font size
			high_score_label.size = Vector2(text_width, high_score_height)
			high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			high_score_label.add_theme_font_override("font", moonbunny_font)
			high_score_label.add_theme_font_size_override("font_size", font_size_info)
			# Yellow color with black outline
			high_score_label.add_theme_color_override("font_color", Color.YELLOW)
			high_score_label.add_theme_color_override("font_outline_color", Color.BLACK)
			high_score_label.add_theme_constant_override("outline_size", 2)
			level_item.add_child(high_score_label)
		
		level_container.add_child(level_item)
		level_items.append(level_item)

func update_display():
	"""Simple display update with clean centering"""
	# Update arrow visibility
	arrow_left.modulate.a = 1.0 if current_level_index > 0 else 0.3
	arrow_right.modulate.a = 1.0 if current_level_index < available_levels.size() - 1 else 0.3
	
	# Simple centering: move container so current item is centered on screen
	if level_container_tween:
		level_container_tween.kill()
	
	level_container_tween = create_tween()
	
	var screen_center = effective_viewport_size.x / 2
	var current_item_center = current_level_index * item_spacing + (item_spacing / 2)
	var target_x = screen_center - current_item_center
	
	# Add HTML-specific centering offset for fine-tuning
	if OS.get_name() == "Web":
		var html_offset = image_size.x / 2
		target_x += html_offset
	
	level_container_tween.tween_property(level_container, "position:x", target_x, 0.2)

func play_menu_sound():
	"""Play menu navigation sound"""
	if menu_sound:
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = menu_sound
		AudioManager.apply_standard_volume(audio_player, "menu")
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)

func load_level_header(level_name: String) -> Dictionary:
	"""Load level header data using LevelResourceManager for HTML compatibility"""
	
	# Use LevelResourceManager which handles HTML compatibility with fallbacks
	var level_data = LevelResourceManager.parse_level_header(level_name)
	
	return level_data

func handle_mouse_click(click_position: Vector2):
	"""Handle mouse/touch clicks on level selection"""
	# Check if clicking on arrow buttons
	if arrow_left and arrow_left.visible:
		var left_rect = Rect2(arrow_left.global_position, arrow_left.size)
		if left_rect.has_point(click_position) and current_level_index > 0:
			current_level_index -= 1
			play_menu_sound()
			update_display()
			return
	
	if arrow_right and arrow_right.visible:
		var right_rect = Rect2(arrow_right.global_position, arrow_right.size)
		if right_rect.has_point(click_position) and current_level_index < available_levels.size() - 1:
			current_level_index += 1
			play_menu_sound()
			update_display()
			return
	
	# Check if clicking on current level item (to select/play)
	if level_items.size() > current_level_index:
		var current_item = level_items[current_level_index]
		var item_rect = Rect2(current_item.global_position, current_item.size)
		if item_rect.has_point(click_position):
			_on_play_pressed()
			return

func handle_mouse_hover(mouse_position: Vector2):
	"""Handle mouse hover for level selection"""
	# Check if hovering over arrow buttons for visual feedback
	if arrow_left and arrow_left.visible:
		var left_rect = Rect2(arrow_left.global_position, arrow_left.size)
		if left_rect.has_point(mouse_position) and current_level_index > 0:
			# Could add hover effect here
			return
	
	if arrow_right and arrow_right.visible:
		var right_rect = Rect2(arrow_right.global_position, arrow_right.size)
		if right_rect.has_point(mouse_position) and current_level_index < available_levels.size() - 1:
			# Could add hover effect here
			return

# Signals
signal level_selected(level_name: String)
signal back_to_menu

func _on_play_pressed():
	if current_level_index < available_levels.size():
		var level_name = available_levels[current_level_index]
		level_selected.emit(level_name)

func _on_back_pressed():
	back_to_menu.emit()

func get_main():
	return get_node("/root/Main")
