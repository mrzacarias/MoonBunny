extends Control

# Main controller based on original MoonBunny main.py structure

# Game states (simplified from GameStateMachine)
enum GameState {
	TITLE,
	LEVEL_SELECT,
	LEVEL,
	TRAINING,
	RESULT
}

# UI References
@onready var main_menu = $UI/MainMenu
@onready var level_select = $UI/LevelSelect
@onready var gameplay_ui = $UI/GameplayUI
@onready var result_screen = $UI/ResultScreen
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
var current_state: GameState = GameState.TITLE
var previous_state: GameState

# Level data (moved from GameStateMachine)
var selected_level: String = ""
var selected_difficulty: String = "Normal"
var level_score: int = 0
var judgement_stats: Dictionary = {}
var is_training: bool = false

func _ready():
	print("Main scene ready")
	
	# Connect UI signals
	main_menu.start_pressed.connect(on_menu_start)
	main_menu.training_pressed.connect(on_menu_training)
	main_menu.exit_pressed.connect(on_menu_exit)
	
	level_select.level_selected.connect(on_level_selected)
	level_select.back_to_menu.connect(on_back_to_menu)
	
	# Connect ResultScreen signal
	result_screen.return_to_menu.connect(_on_result_screen_return_to_menu)
	
	# Setup initial state
	change_state(GameState.TITLE)
	
	# Setup input handling
	setup_input()

func setup_input():
	"""Setup global input handling like original Controller class"""
	# Input will be handled by individual UI screens and forwarded to state machine
	pass

func _input(event):
	"""Handle global input events"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				# Don't handle ESC in RESULT state - let ResultScreen handle it
				if current_state != GameState.RESULT:
					handle_nav_back()

func change_state(new_state: GameState):
	"""Change game state and update UI"""
	print("🏠 Main: State changed to ", GameState.keys()[new_state])
	print("🏠 Main: is_training=", is_training)
	
	# Store previous state
	previous_state = current_state
	current_state = new_state
	
	# Hide all UI first
	hide_all_ui()
	
	# Show appropriate UI for new state
	match new_state:
		GameState.TITLE:
			show_title_screen()
		GameState.LEVEL_SELECT:
			show_level_select()
		GameState.LEVEL, GameState.TRAINING:
			show_gameplay()
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
	main_menu.visible = false
	level_select.visible = false
	gameplay_ui.visible = false
	result_screen.visible = false
	black_screen_overlay.visible = false

func show_title_screen():
	"""Show title screen and start theme music"""
	main_menu.visible = true
	background_color.visible = true  # Show background during menus
	start_theme_music()
	
	# Add delay to prevent immediate input processing when coming from results
	if previous_state == GameState.RESULT:
		print("🏠 Main: Coming from results, adding input delay")
		# Temporarily disable main menu input using flag
		main_menu.input_enabled = false
		get_tree().create_timer(0.5).timeout.connect(func(): 
			if main_menu and is_instance_valid(main_menu):
				main_menu.input_enabled = true
				print("🏠 Main: MainMenu input re-enabled")
		)
	else:
		# Normal case - enable input immediately
		main_menu.input_enabled = true

func show_level_select():
	"""Show level selection screen"""
	level_select.visible = true
	background_color.visible = true  # Show background during menus
	start_theme_music()


func show_gameplay():
	"""Show gameplay UI and start level"""
	# Show black screen overlay initially while start sound plays
	black_screen_overlay.visible = true
	gameplay_ui.visible = false  # Hide gameplay UI initially
	background_color.visible = false  # Hide background during gameplay
	stop_theme_music()
	start_level()

func show_result():
	"""Show result screen using scene-based approach"""
	# Clean up current level first to remove GUI elements
	if current_level:
		current_level.queue_free()
		current_level = null
	
	print("🏠 Main: Showing ResultScreen scene")
	
	# Use local result data
	if judgement_stats.has("stats"):
		# New format with complete data structure
		result_screen.show_results(judgement_stats["stats"], judgement_stats.get("score", 0), judgement_stats.get("n_rings", 0))
	else:
		# Fallback if data format is different (old format)
		result_screen.show_results(judgement_stats, level_score, 0)
	
	result_screen.visible = true
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
	level_container.add_child(current_level)
	
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

func _on_ring_hit(judgement: String, chain: int):
	"""Handle ring hit for UI updates"""
	# Update gameplay UI
	if current_level:
		gameplay_ui.get_node("ScoreLabel").text = "Score: " + str(current_level.score)
		gameplay_ui.get_node("ChainLabel").text = "Chain: " + str(chain)
		# Show judgement image
		gameplay_ui.show_judgement(judgement)

func _on_level_music_started():
	"""Handle level music started - transition from black screen to gameplay UI"""
	print("🏠 Main: Level music started, transitioning to gameplay UI")
	black_screen_overlay.visible = false
	gameplay_ui.visible = true

# Menu navigation handlers - these get called by UI screens
func on_menu_start():
	"""Handle start button from main menu"""
	change_state(GameState.LEVEL_SELECT)

func on_menu_training():
	"""Handle training button from main menu"""
	# Set training level and start
	selected_level = "rain_of_love"
	selected_difficulty = "Normal"
	is_training = true
	change_state(GameState.TRAINING)


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
	print("🏠 Main: ResultScreen requested return to menu")
	on_back_to_menu()

func show_empty_results():
	"""Show empty results for cancelled levels"""
	judgement_stats = {
		"stats": {"PERFECT": 0, "GOOD": 0, "OK": 0, "BAD": 0, "MISS": 0},
		"score": 0,
		"n_rings": 0
	}
	level_score = 0
