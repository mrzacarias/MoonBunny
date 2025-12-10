extends Control

# References
@onready var score_label = $ScoreLabel
@onready var chain_label = $ChainLabel
@onready var judgement_label = $JudgementLabel
@onready var judgement_image = $JudgementImage
@onready var end_level_button = $EndLevelButton

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
	
	# Set up end level button
	if end_level_button:
		end_level_button.pressed.connect(_on_end_level_button_pressed)
		end_level_button.visible = false  # Hidden by default

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

func show_judgement(judgement: String, ring_type: String = "", is_type_specific: bool = false):
	"""Show judgement with animation using images"""
	if not judgement_image:
		return
		
	# Set the appropriate judgement image
	if judgement in judgement_textures:
		judgement_image.texture = judgement_textures[judgement]
	else:
		return
	
	# Always show image in full color
	judgement_image.modulate = Color(1, 1, 1, 1)  # Full opacity
	
	# Create ring explosion effect for PERFECT and GOOD hits with type-specific buttons only
	if judgement in ["PERFECT", "GOOD"] and is_type_specific:
		create_2d_ring_explosion(ring_type)
	
	# Animate appearance and fade
	if judgement_tween:
		judgement_tween.kill()
	judgement_tween = create_tween()
	
	# Fade in quickly, hold, then fade out
	judgement_tween.tween_property(judgement_image, "modulate:a", 1.0, 0.1)
	judgement_tween.tween_interval(0.8)
	judgement_tween.tween_property(judgement_image, "modulate:a", 0.0, 0.5)

func create_2d_ring_explosion(ring_type: String):
	"""Create 2D ring explosion effect from judgement image position using button textures"""
	if not judgement_image:
		return
	
	# Get the center position of the judgement image, adjusted by offset
	var center_pos = judgement_image.global_position + judgement_image.size / 2
	center_pos.x -= 35  # Move 35px to the left
	center_pos.y -= 100  # Move 100px up (90 + 10 more)
	
	# Create 5 ring particles for a cleaner effect
	for i in range(5):
		var ring_particle = create_2d_ring_particle(ring_type)
		add_child(ring_particle)
		
		# Position at the adjusted center position
		ring_particle.position = center_pos
		
		# Make particles appear behind the judgement image
		ring_particle.z_index = -1
		
		# Calculate explosion direction (5 directions in a circle)
		var angle = (i / 5.0) * 2.0 * PI
		var distance = 100.0  # Reasonable distance for visibility
		var target_pos = center_pos + Vector2(cos(angle) * distance, sin(angle) * distance)
		
		# Animate the explosion
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Move outward
		tween.tween_property(ring_particle, "position", target_pos, 0.8)
		# Fade out
		tween.tween_property(ring_particle, "modulate:a", 0.0, 0.8)
		# Scale up slightly
		tween.tween_property(ring_particle, "scale", Vector2(1.5, 1.5), 0.8)
		
		# Clean up after animation
		tween.finished.connect(ring_particle.queue_free)

func create_2d_ring_particle(ring_type: String) -> TextureRect:
	"""Create a 2D ring particle using the appropriate button texture"""
	var particle = TextureRect.new()
	
	# Load the appropriate button texture based on ring type
	var button_texture: Texture2D
	match ring_type:
		"A":
			button_texture = load("res://assets/textures/b_cross.png")
		"B":
			button_texture = load("res://assets/textures/b_circle.png")  # Swapped from C
		"C":
			button_texture = load("res://assets/textures/b_square.png")  # Swapped from B
		"D":
			button_texture = load("res://assets/textures/b_triangle.png")
		_:
			button_texture = load("res://assets/textures/circle.png")  # Fallback
	
	particle.texture = button_texture
	
	# Set size - make it visible but not too large
	particle.size = Vector2(30, 30)
	
	# Set color with transparency for subtle effect
	particle.modulate = Color(1.0, 1.0, 1.0, 0.5)  # White with 0.5 opacity
	
	# Center the texture
	particle.pivot_offset = particle.size / 2
	
	return particle

func update_end_level_button_visibility(is_touch_input: bool):
	"""Show/hide end level button based on input method"""
	if end_level_button:
		end_level_button.visible = is_touch_input

func _on_end_level_button_pressed():
	"""Handle end level button press"""
	# Get the Main scene and its current level
	var main_scene = get_tree().get_first_node_in_group("main")
	if not main_scene:
		main_scene = get_node("/root/Main")
	
	if main_scene and main_scene.has_method("get") and main_scene.get("current_level"):
		var level = main_scene.current_level
		if level and level.has_method("end_level"):
			level.end_level()

# State management is now handled by Main.gd
