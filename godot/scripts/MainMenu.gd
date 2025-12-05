extends Control

# Menu options
enum MenuOption {
	START,
	TRAINING,
	EXIT
}

# References
@onready var background = $Background
@onready var title_image = $TitleImage
@onready var menu_labels = $MenuLabels
@onready var copyright_label = $CopyrightLabel
@onready var star_particles = $StarParticles

# Menu items
var menu_items: Array[Label] = []
var menu_options = ["Start", "Training", "Exit"]
var current_selection: int = 0

# Animation tweens
var selection_tween: Tween
var menu_sound: AudioStream
var input_enabled: bool = true  # Flag to control input processing

# Font resource
var moonbunny_font: FontFile

func _ready():
	# Load menu sound
	menu_sound = load("res://assets/sounds/menu.wav")
	
	# Load font directly from TTF
	moonbunny_font = load("res://assets/fonts/HUM521BC.TTF")
	
	# Setup menu items
	setup_menu_items()
	
	# Set initial selection
	update_selection()
	
	# State management is now handled by Main.gd
	
	# Setup star particles to match viewport width
	setup_star_particles()
	
	# Menu music is now handled by Main.gd

func setup_star_particles():
	if star_particles:
		# Get viewport size
		var viewport_size = get_viewport().get_visible_rect().size
		
		# Position star particles to cover full width, starting above screen
		var half_width = viewport_size.x / 2
		star_particles.position.x = half_width
		star_particles.position.y = -100  # Start above screen for better effect
		
		# Update emission area to match viewport width
		var particle_material = star_particles.process_material as ParticleProcessMaterial
		if particle_material:
			particle_material.emission_box_extents = Vector3(half_width, 10, 0)
		
		# Start particles
		star_particles.emitting = true

func _notification(what):
	# Handle viewport size changes
	if what == NOTIFICATION_RESIZED:
		setup_star_particles()
		update_menu_positions()

func update_menu_positions():
	# Update menu item positions when viewport changes
	var viewport_size = get_viewport().get_visible_rect().size
	var start_y = viewport_size.y * 0.65
	var spacing = 80
	var center_x = viewport_size.x / 2
	
	for i in range(menu_items.size()):
		var label = menu_items[i]
		var center_y = start_y + i * spacing
		label.position = Vector2(center_x - label.size.x / 2, center_y - label.size.y / 2)
		# Update pivot point as well
		label.pivot_offset = label.size / 2

func setup_menu_items():
	# Create menu labels positioned in bottom third of screen
	var viewport_size = get_viewport().get_visible_rect().size
	
	for i in range(menu_options.size()):
		var label = Label.new()
		label.text = menu_options[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Position in bottom third of screen (starting at 66% down)
		var start_y = viewport_size.y * 0.65
		var spacing = 80
		var center_x = viewport_size.x / 2
		var center_y = start_y + i * spacing
		
		# Set size and position so scaling works from center
		label.size = Vector2(200, 50)
		label.position = Vector2(center_x - label.size.x / 2, center_y - label.size.y / 2)
		
		# Set pivot point to center for proper scaling
		label.pivot_offset = label.size / 2
		
		# Style to match original - use original font and size (scale 0.2 = ~48px)
		if moonbunny_font:
			label.add_theme_font_override("font", moonbunny_font)
		label.add_theme_font_size_override("font_size", 70)
		label.modulate = Color.WHITE
		label.z_index = 3  # Make sure menu items appear above particles
		
		menu_labels.add_child(label)
		menu_items.append(label)

func _input(event):
	if not visible or not input_enabled:
		return
	
	# Input is now controlled by visibility and input_enabled flag
		
	if event.is_action_pressed("ui_up"):
		print("🏠 MainMenu: UP pressed")
		change_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		print("🏠 MainMenu: DOWN pressed")
		change_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		print("🏠 MainMenu: ACCEPT pressed, selection=", current_selection)
		select_current_option()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		print("🏠 MainMenu: CANCEL pressed")
		_on_exit_pressed()
		get_viewport().set_input_as_handled()

func change_selection(direction: int):
	# Play menu sound
	if menu_sound:
		AudioServer.get_bus_index("Master")
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = menu_sound
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)
	
	current_selection = (current_selection + direction) % menu_items.size()
	if current_selection < 0:
		current_selection = menu_items.size() - 1
	
	update_selection()

func update_selection():
	# Animate selection like the original
	if selection_tween:
		selection_tween.kill()
	
	selection_tween = create_tween()
	selection_tween.set_parallel(true)  # Allow multiple simultaneous animations
	
	for i in range(menu_items.size()):
		var label = menu_items[i]
		
		if i == current_selection:
			# Scale up selected item
			selection_tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.2)
			label.modulate = Color.WHITE
		else:
			# Scale down unselected items
			selection_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
			label.modulate = Color(0.8, 0.8, 0.8, 1.0)

func select_current_option():
	print("🏠 MainMenu: Selecting option ", current_selection)
	match current_selection:
		0: 
			print("🏠 MainMenu: Starting game (going to level select)")
			_on_start_pressed()
		1: 
			print("🏠 MainMenu: Starting training")
			_on_training_pressed()
		2: 
			print("🏠 MainMenu: Exiting game")
			_on_exit_pressed()

# Signals for communication with Main
signal start_pressed
signal training_pressed
signal exit_pressed

func _on_start_pressed():
	get_viewport().set_input_as_handled()
	start_pressed.emit()

func _on_training_pressed():
	get_viewport().set_input_as_handled()
	training_pressed.emit()

func _on_exit_pressed():
	get_viewport().set_input_as_handled()
	exit_pressed.emit()

# State handling is now done by Main.gd
