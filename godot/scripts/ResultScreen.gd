extends Control

# Result/Ranking screen based on original MoonBunny ResultScreen
class_name ResultScreen

# Signal to return to main menu
signal return_to_menu

# UI References (connected to scene nodes)
@onready var title_label: Label = $TitleLabel
@onready var judgement_names: Label = $JudgementNames
@onready var judgement_counts: Label = $JudgementCounts
@onready var rank_label: Label = $RankLabel
@onready var rank_image: TextureRect = $RankImage
@onready var score_label: Label = $ScoreLabel
@onready var continue_label: Label = $ContinueLabel

var rank_textures: Dictionary = {}

func _ready():
	# Load rank textures
	setup_rank_textures()
	
	# Always start with input disabled - will be enabled when shown
	set_process_input(false)

func _input(event):
	"""Unified input handling - all input types in one place"""
	if not visible:
		return
	
	# Handle all input types that should continue
	# Only process events that have a pressed state
	var should_process = false
	if event is InputEventKey and event.pressed:
		should_process = true
	elif event is InputEventJoypadButton and event.pressed:
		should_process = true
	elif event is InputEventMouseButton and event.pressed:
		should_process = true
	elif event is InputEventScreenTouch and event.pressed:
		should_process = true
	
	if should_process:
		var should_continue = false
		
		# Keyboard input
		if event is InputEventKey:
			should_continue = event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]
		
		# Mouse/Touch/Gamepad input
		elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or \
			 event is InputEventScreenTouch or \
			 (event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]):
			should_continue = true
		
		if should_continue:
			_continue_to_menu()
			get_viewport().set_input_as_handled()

func _continue_to_menu():
	"""Handle continue input from any source"""
	# Disable input processing immediately to prevent double-processing
	set_process_input(false)
	# Emit signal to return to menu
	return_to_menu.emit()

func setup_rank_textures():
	"""Load rank textures"""
	var texture_files = {
		"SS": "res://assets/textures/rank_ss.png",
		"S": "res://assets/textures/rank_s.png", 
		"A": "res://assets/textures/rank_a.png",
		"B": "res://assets/textures/rank_b.png",
		"C": "res://assets/textures/rank_c.png",
		"F": "res://assets/textures/rank_f.png"
	}
	
	for rank in texture_files.keys():
		var file_path = texture_files[rank]
		if ResourceLoader.exists(file_path):
			rank_textures[rank] = load(file_path)
		else:
			print("ERROR: Rank texture file not found: ", file_path)
	

func show_results(stats: Dictionary, score: int, n_rings: int, level_name: String = "", rank: String = ""):
	"""Show results using scene-based UI elements"""
	
	# Disable input first to prevent immediate processing
	set_process_input(false)
	
	# Calculate rank if not provided
	if rank == "":
		rank = calculate_rank(stats, n_rings)
	
	# Save high score if level name is provided
	if level_name != "":
		var is_new_high_score = HighScoreManager.update_high_score(level_name, score, rank)
		if is_new_high_score:
			pass # New high score recorded
	
	# Update judgement counts
	var judgements = ["PERFECT", "GOOD", "OK", "BAD", "MISS"]
	var counts_text = ""
	for judgement in judgements:
		var count = stats.get(judgement, 0)
		counts_text += str(count) + "\n"
	
	judgement_counts.text = counts_text.strip_edges()
	
	# Update rank image
	if rank in rank_textures:
		rank_image.texture = rank_textures[rank]
		
		# Debug TextureRect properties
		
		# Ensure visibility
		rank_image.visible = true
		rank_image.modulate = Color.WHITE
		
	else:
		# Fallback to F rank if rank not found
		if "F" in rank_textures:
			rank_image.texture = rank_textures["F"]
			rank_image.visible = true
			rank_image.modulate = Color.WHITE
	
	# Update score
	score_label.text = "SCORE   " + str(score)
	
	
	# Enable input after a delay to prevent immediate ESC processing
	get_tree().create_timer(0.5).timeout.connect(func(): 
		if is_instance_valid(self) and visible:
			set_process_input(true)
	)

func calculate_rank(stats: Dictionary, n_rings: int) -> String:
	"""Calculate rank based on performance like original MoonBunny"""
	
	if n_rings == 0:
		return "F"
	
	# Calculate rates like original
	var rates = {}
	for key in ["PERFECT", "GOOD", "OK", "BAD", "MISS"]:
		rates[key] = float(stats.get(key, 0)) / float(n_rings)
	
	
	# Use exact original logic from main.py
	if rates["PERFECT"] == 1.0:
		return "SS"
	elif rates["MISS"] <= 0 and rates["BAD"] <= 0.1 and rates["PERFECT"] >= 0.5:
		return "S"
	elif rates["MISS"] <= 0.05 and (rates["MISS"] + rates["BAD"] <= 0.2) and (rates["GOOD"] + rates["PERFECT"] >= 0.4):
		return "A"
	elif (rates["MISS"] + rates["BAD"] <= 0.3) and (rates["GOOD"] + rates["PERFECT"] >= 0.3):
		return "B"
	elif (rates["MISS"] + rates["BAD"] <= 0.4) and (rates["GOOD"] + rates["PERFECT"] >= 0.2):
		return "C"
	else:
		return "F"

func clear_results():
	"""Clear previous result display"""
	# Reset UI elements to default state
	judgement_counts.text = "0\n0\n0\n0\n0"
	rank_image.texture = null
	score_label.text = "SCORE   0"
