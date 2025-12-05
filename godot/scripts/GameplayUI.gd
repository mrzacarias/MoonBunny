extends Control

# References
@onready var score_label = $ScoreLabel
@onready var chain_label = $ChainLabel
@onready var judgement_label = $JudgementLabel
@onready var judgement_image = $JudgementImage

# Animation
var judgement_tween: Tween

# Judgement textures
var judgement_textures: Dictionary = {}

func _ready():
	# UI updates will be handled by Main.gd through direct function calls
	# Hide judgement label since we're using image-based judgements now
	if judgement_label:
		judgement_label.visible = false
	
	# Load judgement textures
	setup_judgement_textures()
	
	# Set up judgement image
	if judgement_image:
		judgement_image.modulate = Color.TRANSPARENT  # Start invisible

func _on_score_updated(new_score: int):
	score_label.text = "Score: " + str(new_score)

func _on_chain_updated(new_chain: int):
	chain_label.text = "Chain: " + str(new_chain)

func _on_judgement_made(judgement: String, _chain_value: int):
	show_judgement(judgement)

func setup_judgement_textures():
	"""Load judgement textures"""
	judgement_textures["PERFECT"] = load("res://assets/textures/j_perfect.png")
	judgement_textures["GOOD"] = load("res://assets/textures/j_good.png")
	judgement_textures["OK"] = load("res://assets/textures/j_ok.png")
	judgement_textures["BAD"] = load("res://assets/textures/j_bad.png")
	judgement_textures["MISS"] = load("res://assets/textures/j_miss.png")

func show_judgement(judgement: String):
	"""Show judgement with animation using images"""
	if not judgement_image:
		return
		
	# Set the appropriate judgement image
	if judgement in judgement_textures:
		judgement_image.texture = judgement_textures[judgement]
	else:
		print("⚠️ Unknown judgement: ", judgement)
		return
	
	# Always show image in full color
	judgement_image.modulate = Color(1, 1, 1, 1)  # Full opacity
	
	# Animate appearance and fade
	if judgement_tween:
		judgement_tween.kill()
	judgement_tween = create_tween()
	
	# Fade in quickly, hold, then fade out
	judgement_tween.tween_property(judgement_image, "modulate:a", 1.0, 0.1)
	judgement_tween.tween_interval(0.8)
	judgement_tween.tween_property(judgement_image, "modulate:a", 0.0, 0.5)

# State management is now handled by Main.gd
