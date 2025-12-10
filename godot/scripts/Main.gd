extends Control

# Main controller based on original MoonBunny main.py structure

# Game states (simplified from GameStateMachine)
enum GameState {
	SPLASH,
	TITLE,
	LEVEL_SELECT,
	LEVEL,
	TRAINING,
	HOW_TO_PLAY,
	RESULT
}

# Global input method tracking
enum GlobalInputMethod {
	KEYBOARD,
	MOUSE,
	GAMEPAD,
	TOUCH
}
var last_input_method: GlobalInputMethod = GlobalInputMethod.KEYBOARD

# Splash screen fallback timer tracking
var splash_fallback_timer: SceneTreeTimer = null

# UI References
@onready var splash_screen = $UI/SplashScreen
@onready var main_menu = $UI/MainMenu
@onready var level_select = $UI/LevelSelect
@onready var gameplay_ui = $UI/GameplayUI
@onready var result_screen = $UI/ResultScreen
@onready var how_to_play_screen = $UI/HowToPlayScreen
@onready var background_color = $BackgroundColor
@onready var black_screen_overlay = $UI/BlackScreenOverlay

# 3D Scene
@onready var level_container = $Level

# Audio
@onready var menu_music = $MenuMusic

# Current level instance
var current_level: Level = null

# Theme music
var theme_music_playing = false

# Game state management
var current_state: GameState = GameState.SPLASH
var previous_state: GameState

# Level data (moved from GameStateMachine)
var selected_level: String = ""
var selected_difficulty: String = "Normal"
var level_score: int = 0
var judgement_stats: Dictionary = {}
var is_training: bool = false

func _ready():
	
	# Manual node resolution for HTML export compatibility
	if not splash_screen:
		splash_screen = get_node_or_null("UI/SplashScreen")
	if not main_menu:
		main_menu = get_node_or_null("UI/MainMenu")
	if not level_select:
		level_select = get_node_or_null("UI/LevelSelect")
	if not gameplay_ui:
		gameplay_ui = get_node_or_null("UI/GameplayUI")
	if not result_screen:
		result_screen = get_node_or_null("UI/ResultScreen")
	if not how_to_play_screen:
		how_to_play_screen = get_node_or_null("UI/HowToPlayScreen")
	if not background_color:
		background_color = get_node_or_null("BackgroundColor")
	if not black_screen_overlay:
		black_screen_overlay = get_node_or_null("UI/BlackScreenOverlay")
	if not level_container:
		level_container = get_node_or_null("Level")
	if not menu_music:
		menu_music = get_node_or_null("MenuMusic")
	
	# Apply AudioManager volume settings to menu music
	if menu_music:
		AudioManager.apply_standard_volume(menu_music, "menu")
	
	
	# Connect UI signals with null checks
	if main_menu and main_menu.has_signal("start_pressed"):
		main_menu.start_pressed.connect(on_menu_start)
	if main_menu and main_menu.has_signal("training_pressed"):
		main_menu.training_pressed.connect(on_menu_training)
	if main_menu and main_menu.has_signal("exit_pressed"):
		main_menu.exit_pressed.connect(on_menu_exit)
	
	if level_select and level_select.has_signal("level_selected"):
		level_select.level_selected.connect(on_level_selected)
	if level_select and level_select.has_signal("back_to_menu"):
		level_select.back_to_menu.connect(on_back_to_menu)
	
	# Connect ResultScreen signal
	if result_screen and result_screen.has_signal("return_to_menu"):
		result_screen.return_to_menu.connect(_on_result_screen_return_to_menu)
	
	# Connect HowToPlayScreen signal
	if how_to_play_screen and how_to_play_screen.has_signal("ready_to_continue"):
		how_to_play_screen.ready_to_continue.connect(_on_how_to_play_ready_to_continue)
	
	# For HTML exports, use a timer-based splash screen as fallback
	# The SplashScreen script often doesn't work properly in HTML exports
	if splash_screen and splash_screen.has_signal("splash_finished"):
		splash_screen.splash_finished.connect(_on_splash_finished)
	else:
		# Fallback timer for HTML exports
		splash_fallback_timer = get_tree().create_timer(3.5)
		splash_fallback_timer.timeout.connect(func():
			_on_splash_finished()
		)
	
	# Setup initial state
	change_state(GameState.SPLASH)
	
	# Input handling is now managed by individual UI screens

func _input(event):
	"""Handle global input events - simplified to only ESC key"""
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		# Only handle ESC for level select and levels (not splash, title, results, or how-to-play)
		if current_state == GameState.LEVEL_SELECT or current_state == GameState.LEVEL or current_state == GameState.TRAINING:
			handle_nav_back()
			get_viewport().set_input_as_handled()

func change_state(new_state: GameState):
	"""Change game state and update UI"""
	
	# Store previous state
	previous_state = current_state
	current_state = new_state
	
	# Hide all UI first
	hide_all_ui()
	
	# Show appropriate UI for new state
	match new_state:
		GameState.SPLASH:
			show_splash_screen()
		GameState.TITLE:
			show_title_screen()
		GameState.LEVEL_SELECT:
			show_level_select()
		GameState.LEVEL, GameState.TRAINING:
			show_gameplay()
		GameState.HOW_TO_PLAY:
			show_how_to_play()
		GameState.RESULT:
			show_result()

func handle_nav_back():
	"""Handle back/cancel navigation"""
	match current_state:
		GameState.LEVEL_SELECT:
			change_state(GameState.TITLE)
		GameState.RESULT:
			change_state(GameState.TITLE)
		GameState.LEVEL, GameState.TRAINING:
			# End level early and go to results
			if current_level:
				current_level.end_level()
			else:
				# Fallback if no level
				show_empty_results()
				change_state(GameState.RESULT)

func hide_all_ui():
	"""Hide all UI screens"""
	if splash_screen:
		splash_screen.visible = false
	if main_menu:
		main_menu.visible = false
	if level_select:
		level_select.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if result_screen:
		result_screen.visible = false
	if how_to_play_screen:
		how_to_play_screen.visible = false
	if black_screen_overlay:
		black_screen_overlay.visible = false

func show_splash_screen():
	"""Show splash screen with simple approach for HTML exports"""
	if splash_screen:
		splash_screen.visible = true
		
		# Try to play the splash sound manually
		var splash_sound = splash_screen.get_node_or_null("SplashSound")
		if splash_sound and splash_sound.stream:
			splash_sound.play()
		
		# Simple logo fade animation
		var logo = splash_screen.get_node_or_null("CenterContainer/VBoxContainer/Logo")
		if logo:
			logo.modulate.a = 0.0
			var tween = create_tween()
			tween.tween_property(logo, "modulate:a", 1.0, 0.5)
			tween.tween_interval(2.0)  # Show for 2 seconds
			tween.tween_property(logo, "modulate:a", 0.0, 0.5)
		else:
			print("ERROR: Failed to load background image")
	else:
		print("ERROR: Background image not found")
	
	if background_color:
		background_color.visible = false  # Hide background during splash
	stop_theme_music()  # Make sure no music is playing during splash

func show_title_screen():
	"""Show title screen and start theme music"""
	if main_menu:
		main_menu.visible = true
	if background_color:
		background_color.visible = true  # Show background during menus
	start_theme_music()
	
	# Add delay to prevent immediate input processing when coming from any state
	# This prevents rapid clicking from causing state transition issues
	if main_menu:
		main_menu.input_enabled = false
	
	# Use a longer delay for better input debouncing
	# Splash screen needs extra time to prevent startup input issues
	var delay_time = 0.8 if previous_state == GameState.SPLASH else (0.3 if previous_state == GameState.RESULT else 0.2)
	get_tree().create_timer(delay_time).timeout.connect(func(): 
		if main_menu and is_instance_valid(main_menu):
			main_menu.input_enabled = true
	)

func show_level_select():
	"""Show level selection screen"""
	if level_select:
		level_select.visible = true
	if background_color:
		background_color.visible = true  # Show background during menus
	start_theme_music()


func show_gameplay():
	"""Show gameplay UI and start level"""
	# Show black screen overlay initially while start sound plays
	if black_screen_overlay:
		black_screen_overlay.visible = true
	if gameplay_ui:
		gameplay_ui.visible = false  # Hide gameplay UI initially
	if background_color:
		background_color.visible = false  # Hide background during gameplay
	stop_theme_music()
	start_level()

func show_result():
	"""Show result screen using scene-based approach"""
	# Clean up current level first to remove GUI elements
	if current_level:
		current_level.queue_free()
		current_level = null
	
	
	# Use local result data
	if result_screen:
		if judgement_stats.has("stats"):
			# New format with complete data structure
			result_screen.show_results(
				judgement_stats["stats"], 
				judgement_stats.get("score", 0), 
				judgement_stats.get("n_rings", 0),
				selected_level,
				judgement_stats.get("rank", "")
			)
		else:
			# Fallback if data format is different (old format)
			result_screen.show_results(judgement_stats, level_score, 0, selected_level)
		
		result_screen.visible = true
	if background_color:
		background_color.visible = true  # Show background during results

func start_theme_music():
	"""Start theme music if not already playing"""
	if not theme_music_playing and menu_music:
		# Connect to finished signal for manual looping if not already connected
		if not menu_music.finished.is_connected(_on_menu_music_finished):
			menu_music.finished.connect(_on_menu_music_finished)
		
		# Don't set any loop properties - xjust play and use manual looping
		menu_music.play()
		theme_music_playing = true

func _on_menu_music_finished():
	"""Restart music when it finishes to create looping effect"""
	if theme_music_playing and menu_music:
		menu_music.play()

func stop_theme_music():
	"""Stop theme music"""
	if theme_music_playing and menu_music:
		menu_music.stop()
		theme_music_playing = false

func start_level():
	"""Start the selected level like original enterLevel/enterTraining"""
	
	# Clean up previous level
	if current_level:
		current_level.queue_free()
		current_level = null
	
	# Load Level scene and create instance
	var level_scene = preload("res://scenes/Level.tscn")
	current_level = level_scene.instantiate()
	
	# Initialize level with parameters
	current_level.level_name = selected_level
	current_level.difficulty = selected_difficulty
	current_level.is_training = is_training
	
	# Connect level signals
	current_level.level_finished.connect(_on_level_finished)
	current_level.ring_hit.connect(_on_ring_hit)
	current_level.music_started.connect(_on_level_music_started)
	
	# Add to scene
	if level_container:
		level_container.add_child(current_level)
	
	# Set initial input method based on last menu interaction (after adding to tree)
	current_level.set_initial_input_method(last_input_method)
	
	# Start level playback
	current_level.play()

func _on_level_finished(result_data: Dictionary):
	"""Handle level completion"""
	judgement_stats = result_data
	level_score = result_data.get("score", 0)
	change_state(GameState.RESULT)

func _on_training_finished():
	"""Handle training completion"""
	# Training goes to results just like regular levels
	pass

func _on_ring_hit(judgement: String, chain: int, ring_type: String, is_type_specific: bool):
	"""Handle ring hit for UI updates"""
	# Update gameplay UI
	if current_level and gameplay_ui:
		var score_label = gameplay_ui.get_node("ScoreLabel")
		var chain_label = gameplay_ui.get_node("ChainLabel")
		if score_label:
			score_label.text = "Score: " + str(current_level.score)
		if chain_label:
			chain_label.text = "Chain: " + str(chain)
		# Show judgement image with ring explosion effect info
		gameplay_ui.show_judgement(judgement, ring_type, is_type_specific)

func _on_level_music_started():
	"""Handle level music started - transition from black screen to gameplay UI"""
	if black_screen_overlay:
		black_screen_overlay.visible = false
	if gameplay_ui:
		gameplay_ui.visible = true

# Menu navigation handlers - these get called by UI screens
func on_menu_start():
	"""Handle start button from main menu"""
	# Disable menu input immediately to prevent double-processing
	if main_menu:
		main_menu.input_enabled = false
	change_state(GameState.LEVEL_SELECT)

func on_menu_training():
	"""Handle training button from main menu"""
	# Disable menu input immediately to prevent double-processing
	if main_menu:
		main_menu.input_enabled = false
	# Set training level and go to how-to-play screen first
	selected_level = "training"
	selected_difficulty = "Normal"
	is_training = true
	change_state(GameState.HOW_TO_PLAY)


func on_menu_exit():
	"""Handle exit button from main menu"""
	get_tree().quit()

func on_level_selected(level_name: String):
	"""Handle level selection"""
	selected_level = level_name
	selected_difficulty = "Normal"
	is_training = false
	change_state(GameState.LEVEL)

func on_back_to_menu():
	"""Handle back to main menu"""
	# Clear training flag when returning to menu
	is_training = false
	selected_level = ""
	selected_difficulty = "Normal"
	change_state(GameState.TITLE)

func _on_result_screen_return_to_menu():
	"""Handle ResultScreen signal to return to main menu"""
	on_back_to_menu()

func _on_how_to_play_ready_to_continue():
	"""Handle HowToPlayScreen signal to continue to training"""
	change_state(GameState.TRAINING)

func show_how_to_play():
	"""Show how-to-play screen with appropriate control image"""
	if how_to_play_screen:
		how_to_play_screen.visible = true
		# Use device detection instead of last input method for more reliable results
		var input_method = detect_device_input_method()
		how_to_play_screen.show_for_input_method(input_method)
	if background_color:
		background_color.visible = true  # Show background during how-to-play
	stop_theme_music()

func detect_device_input_method() -> int:
	"""Detect the most appropriate input method based on device capabilities and last interaction"""
	print("Device Detection Debug:")
	print("  OS Name: ", OS.get_name())
	print("  Screen Size: ", DisplayServer.screen_get_size())
	print("  Touch Available: ", DisplayServer.is_touchscreen_available())
	print("  Connected Joypads: ", Input.get_connected_joypads())
	print("  Is Mobile Device: ", is_mobile_device())
	print("  Last Input Method: ", last_input_method)
	
	# Check if we're on a mobile device first (highest priority)
	if is_mobile_device():
		print("  -> Using TOUCH input method (3) - mobile device")
		return 3  # TOUCH
	
	# Check if touch screen is available AND user actually used touch
	if DisplayServer.is_touchscreen_available() and last_input_method == 3:
		print("  -> Using TOUCH input method (3) - touch screen used")
		return 3  # TOUCH
	
	# Check if gamepad is connected AND user actually used gamepad
	if not Input.get_connected_joypads().is_empty() and last_input_method == 2:
		print("  -> Using GAMEPAD input method (2) - gamepad used")
		return 2  # GAMEPAD
	
	# For desktop devices, use the actual input method that was used
	if last_input_method == 1:  # MOUSE
		print("  -> Using MOUSE input method (1) - mouse used")
		return 1  # MOUSE (will show keyboard/mouse image)
	elif last_input_method == 0:  # KEYBOARD
		print("  -> Using KEYBOARD input method (0) - keyboard used")
		return 0  # KEYBOARD (will show keyboard/mouse image)
	
	# Fallback: Default to keyboard/mouse for desktop
	print("  -> Using KEYBOARD input method (0) - default fallback")
	return 0  # KEYBOARD

func is_mobile_device() -> bool:
	"""Detect if we're running on a mobile device"""
	# Check the OS name
	var os_name = OS.get_name()
	if os_name in ["Android", "iOS"]:
		return true
	
	# For web exports, check user agent or screen size
	if os_name == "Web":
		# Check if screen is small (typical mobile resolution)
		var screen_size = DisplayServer.screen_get_size()
		var is_small_screen = screen_size.x <= 768 or screen_size.y <= 768
		
		# Check if touch is available (most reliable for web)
		var has_touch = DisplayServer.is_touchscreen_available()
		
		# Mobile if small screen AND touch available
		return is_small_screen and has_touch
	
	return false

func set_last_input_method(method: GlobalInputMethod):
	"""Set the last used input method globally"""
	last_input_method = method

func get_last_input_method() -> GlobalInputMethod:
	"""Get the last used input method"""
	return last_input_method

func get_gameplay_ui():
	"""Get the GameplayUI node"""
	return gameplay_ui


func _on_splash_finished():
	"""Handle splash screen completion"""
	# Prevent multiple calls if both timer and signal fire
	if current_state != GameState.SPLASH:
		return
	
	# Clear the fallback timer reference
	splash_fallback_timer = null
	
	# Clear any pending input events from splash screen
	Input.flush_buffered_events()
	change_state(GameState.TITLE)

func show_empty_results():
	"""Show empty results for cancelled levels"""
	judgement_stats = {
		"stats": {"PERFECT": 0, "GOOD": 0, "OK": 0, "BAD": 0, "MISS": 0},
		"score": 0,
		"n_rings": 0
	}
	level_score = 0
