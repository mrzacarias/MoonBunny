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
	print("🏆 ResultScreen: _ready called, input disabled")

func _input(event):
	"""Handle input to continue like original"""
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		# Debug: Show when keys are pressed but not processed
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
			print("🏆 ResultScreen: Key pressed (", OS.get_keycode_string(event.keycode), ") - processing enabled: ", is_processing_input())
		
		match event.keycode:
			KEY_SPACE, KEY_ENTER, KEY_ESCAPE:
				print("🏆 ResultScreen: Input received (", OS.get_keycode_string(event.keycode), "), emitting return_to_menu signal")
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
			print("🏆 ResultScreen: Loaded ", rank, " texture: ", rank_textures[rank])
		else:
			print("❌ ResultScreen: Texture file not found: ", file_path)
	
	print("🏆 ResultScreen: Rank textures loaded - total: ", rank_textures.size())

func show_results(stats: Dictionary, score: int, n_rings: int):
	"""Show results using scene-based UI elements"""
	print("🏆 ResultScreen: show_results called with stats=", stats, " score=", score, " n_rings=", n_rings)
	
	# Disable input first to prevent immediate processing
	set_process_input(false)
	
	# Calculate rank
	var rank = calculate_rank(stats, n_rings)
	
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
		print("🏆 ResultScreen: Set rank image to ", rank, " - texture: ", rank_textures[rank])
		
		# Debug TextureRect properties
		print("🏆 ResultScreen: RankImage visible: ", rank_image.visible)
		print("🏆 ResultScreen: RankImage size: ", rank_image.size)
		print("🏆 ResultScreen: RankImage position: ", rank_image.position)
		print("🏆 ResultScreen: RankImage modulate: ", rank_image.modulate)
		
		# Ensure visibility
		rank_image.visible = true
		rank_image.modulate = Color.WHITE
		
	else:
		print("❌ ResultScreen: Rank ", rank, " not found in textures!")
		# Fallback to F rank if rank not found
		if "F" in rank_textures:
			rank_image.texture = rank_textures["F"]
			rank_image.visible = true
			rank_image.modulate = Color.WHITE
			print("🏆 ResultScreen: Using F rank as fallback")
	
	# Update score
	score_label.text = "SCORE   " + str(score)
	
	print("🏆 ResultScreen: Showing results - Rank: ", rank, " Score: ", score)
	
	# Enable input after a delay to prevent immediate ESC processing
	get_tree().create_timer(0.5).timeout.connect(func(): 
		if is_instance_valid(self) and visible:
			set_process_input(true)
			print("🏆 ResultScreen: Input processing enabled after delay")
	)

func calculate_rank(stats: Dictionary, n_rings: int) -> String:
	"""Calculate rank based on performance like original MoonBunny"""
	print("🏆 ResultScreen: Calculating rank - stats: ", stats, " n_rings: ", n_rings)
	
	if n_rings == 0:
		print("🏆 ResultScreen: n_rings is 0, returning F")
		return "F"
	
	# Calculate rates like original
	var rates = {}
	for key in ["PERFECT", "GOOD", "OK", "BAD", "MISS"]:
		rates[key] = float(stats.get(key, 0)) / float(n_rings)
	
	print("🏆 ResultScreen: Calculated rates: ", rates)
	
	# Use exact original logic from main.py
	if rates["PERFECT"] == 1.0:
		print("🏆 ResultScreen: Perfect score, returning SS")
		return "SS"
	elif rates["MISS"] <= 0 and rates["BAD"] <= 0.1 and rates["PERFECT"] >= 0.5:
		print("🏆 ResultScreen: S rank conditions met")
		return "S"
	elif rates["MISS"] <= 0.05 and (rates["MISS"] + rates["BAD"] <= 0.2) and (rates["GOOD"] + rates["PERFECT"] >= 0.4):
		print("🏆 ResultScreen: A rank conditions met")
		return "A"
	elif (rates["MISS"] + rates["BAD"] <= 0.3) and (rates["GOOD"] + rates["PERFECT"] >= 0.3):
		print("🏆 ResultScreen: B rank conditions met")
		return "B"
	elif (rates["MISS"] + rates["BAD"] <= 0.4) and (rates["GOOD"] + rates["PERFECT"] >= 0.2):
		print("🏆 ResultScreen: C rank conditions met")
		return "C"
	else:
		print("🏆 ResultScreen: No rank conditions met, returning F")
		return "F"

func clear_results():
	"""Clear previous result display"""
	# Reset UI elements to default state
	judgement_counts.text = "0\n0\n0\n0\n0"
	rank_image.texture = null
	score_label.text = "SCORE   0"
