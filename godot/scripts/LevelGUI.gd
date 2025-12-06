extends Node

# GUI components for MoonBunny Level - based on original gui.py

class_name LevelGUI

# ButtonViewer class - recreates original ButtonViewer from gui.py
class ButtonViewer extends Control:
	var BTN_SPACE_PER_BEAT = 0.2  # Original: self.BTN_SPACE_PER_BEAT = 0.2
	var BTN_SIZE = 64.0           # Original: self.BTN_SIZE = 64.0
	var z_pos = -0.8              # Original: z_pos=-0.8
	
	var music_bpm: float
	var beat_delay: float
	var button_container: Control
	var button_marker: TextureRect
	var initial_x: float
	
	# Button textures (like original tex_buttons)
	var button_textures = {}
	
	# Button colors matching ring colors from ModelLoader
	var button_colors = {
		"A": Color(0.3, 0.5, 1.0, 1.0),  # Bright blue
		"B": Color(1.0, 0.2, 0.2, 1.0),  # Bright red
		"C": Color(1.0, 0.2, 1.0, 1.0),  # Bright magenta
		"D": Color(1.0, 1.0, 0.2, 1.0)   # Bright yellow
	}
	
	func _init(bpm: float):
		music_bpm = bpm
		beat_delay = 60.0 / music_bpm  # Like original beat_delay(bpm)
		
		# Setup UI
		setup_button_viewer()
		
	func _ready():
		# Update positions with actual viewport size
		if get_viewport():
			var actual_size = get_viewport().get_visible_rect().size
			if button_marker:
				# Position at bottom center for better visibility
				button_marker.position = Vector2(actual_size.x / 2 - BTN_SIZE / 2, actual_size.y - BTN_SIZE - 20)
				button_marker.modulate = Color(1, 1, 0, 0.8)  # Yellow marker for visibility
		
	func setup_button_viewer():
		"""Setup button viewer UI with colored circle icons"""
		# Use circle texture for all buttons with color modulation
		var circle_texture_path = "res://assets/textures/circle.png"
		var circle_texture = null
		
		if ResourceLoader.exists(circle_texture_path):
			circle_texture = load(circle_texture_path)
		else:
			print("⚠️ Circle texture not found: ", circle_texture_path)
			# Create fallback circle texture
			var fallback_texture = ImageTexture.new()
			var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)  # White circle fallback
			fallback_texture.set_image(image)
			circle_texture = fallback_texture
		
		# Set same circle texture for all button types
		for button in ["A", "B", "C", "D"]:
			button_textures[button] = circle_texture
		
		# Create button marker (like original button_marker)
		button_marker = TextureRect.new()
		var marker_path = "res://assets/textures/b_marker.png"
		if ResourceLoader.exists(marker_path):
			button_marker.texture = load(marker_path)
		else:
			# Fallback marker
			var marker_texture = ImageTexture.new()
			var marker_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			marker_image.fill(Color(1, 1, 1, 0.5))  # Semi-transparent white
			marker_texture.set_image(marker_image)
			button_marker.texture = marker_texture
		
		button_marker.size = Vector2(BTN_SIZE, BTN_SIZE)
		# Use safe viewport size access
		var viewport_size = Vector2(1280, 960)  # Default size, will be updated in _ready
		button_marker.position = Vector2(viewport_size.x / 2 - BTN_SIZE / 2, viewport_size.y * 0.8)
		add_child(button_marker)
		
		# Create container for buttons
		button_container = Control.new()
		button_container.name = "ButtonContainer"
		# Position container at the same Y as the marker, and X at center so buttons align with marker
		button_container.position = Vector2(viewport_size.x / 2, viewport_size.y - BTN_SIZE - 20)
		# Make container visible for debugging
		button_container.modulate = Color(1, 1, 1, 1)  # Fully visible
		add_child(button_container)
		initial_x = button_container.position.x
		
		# Make the ButtonViewer itself visible
		modulate = Color(1, 1, 1, 1)  # Ensure ButtonViewer is visible
		
	
	func append_button(button: String, ring_y: float):
		"""Add button to timeline like original append_button"""
		if not button in button_textures:
			print("⚠️ Unknown button: ", button)
			return
			
		var btn_image = TextureRect.new()
		btn_image.texture = button_textures[button]
		btn_image.size = Vector2(BTN_SIZE, BTN_SIZE)
		
		# Apply color modulation to match ring colors
		if button in button_colors:
			btn_image.modulate = button_colors[button]
		else:
			btn_image.modulate = Color.WHITE  # Default white if button not found
		
		# Position using EXACT same formula as rings: ring_time * RING_SPACING_PER_BEAT + 5.0
		# Convert ring Y position to button X position
		# When ring_time matches music_time, button should be centered INSIDE the square
		var x_pos = -ring_y * BTN_SPACE_PER_BEAT / 20.0 * 200  # Negative X = buttons start from left
		# Center the button within the square marker (offset by half button size)
		# Move down by 50% of button size to align with square
		btn_image.position = Vector2(x_pos - BTN_SIZE / 2, -BTN_SIZE / 2 + BTN_SIZE * 0.5)  # Center within square
		
		button_container.add_child(btn_image)
		
	func update_timeline(music_time: float):
		"""Update button timeline position like original update()"""
		# Use EXACT same formula as bunny positioning: time_to_position()
		# Bunny uses: (music_time / beat_delay) * RING_SPACING_PER_BEAT
		var bunny_y_pos = (music_time / beat_delay) * 20.0  # Same as bunny (RING_SPACING_PER_BEAT = 20)
		var time_pos = bunny_y_pos * BTN_SPACE_PER_BEAT / 20.0 * 200  # Positive = move right as time progresses (buttons come from left)
		button_container.position.x = initial_x + time_pos
		
		
	func button_hit():
		"""Handle button hit feedback like original"""
		# Could add hit animation/effects here
		pass

# ScoreDisplay class - recreates original ScoreDisplay from gui.py  
class ScoreDisplay extends Control:
	var score_label: Label
	var chain_label: Label
	
	func _init():
		setup_score_display()
		
	func _ready():
		# Update positions with actual viewport size
		if get_viewport() and chain_label:
			var actual_size = get_viewport().get_visible_rect().size
			chain_label.position = Vector2(actual_size.x - 200, 20)
		
	func setup_score_display():
		"""Setup score display UI"""
		# Score label
		score_label = Label.new()
		score_label.text = "Score: 0"
		score_label.add_theme_font_size_override("font_size", 36)
		score_label.position = Vector2(20, 20)
		score_label.size = Vector2(300, 50)
		add_child(score_label)
		
		# Chain label  
		chain_label = Label.new()
		chain_label.text = "Chain: 0"
		chain_label.add_theme_font_size_override("font_size", 36)
		# Use safe viewport size access
		var viewport_size = Vector2(1280, 960)  # Default size
		chain_label.position = Vector2(viewport_size.x - 200, 20)
		chain_label.size = Vector2(180, 50)
		add_child(chain_label)
		
		
	func update_score(score: int):
		"""Update score display"""
		score_label.text = "Score: " + str(score)
		
	func update_chain(chain: int):
		"""Update chain display"""
		chain_label.text = "Chain: " + str(chain)

# JudgementDisplay class - shows hit judgements like PERFECT, GOOD, etc.
class JudgementDisplay extends Control:
	var judgement_image: TextureRect
	var judgement_tween: Tween
	var judgement_textures: Dictionary = {}
	
	func _init():
		setup_judgement_display()
		
	func _ready():
		# Update positions with actual viewport size
		if get_viewport() and judgement_image:
			var actual_size = get_viewport().get_visible_rect().size
			# Position on left side of screen, slightly up from center
			judgement_image.position = Vector2(30, actual_size.y * 0.4 - 196)
		
	func setup_judgement_display():
		"""Setup judgement display UI"""
		# Load judgement textures like original game
		judgement_textures["PERFECT"] = load("res://assets/textures/j_perfect.png")
		judgement_textures["GOOD"] = load("res://assets/textures/j_good.png")
		judgement_textures["OK"] = load("res://assets/textures/j_ok.png")
		judgement_textures["BAD"] = load("res://assets/textures/j_bad.png")
		judgement_textures["MISS"] = load("res://assets/textures/j_miss.png")
		
		# Create image display instead of text
		judgement_image = TextureRect.new()
		judgement_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		judgement_image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		# Use safe viewport size access
		var viewport_size = Vector2(1280, 960)  # Default size
		# Position on left side of screen, slightly up from center
		judgement_image.position = Vector2(30, viewport_size.y * 0.4 - 196)
		judgement_image.size = Vector2(384, 192)  # Bigger size for judgement images (1.5x larger)
		judgement_image.modulate = Color.TRANSPARENT  # Start invisible
		add_child(judgement_image)
		
		
	func show_judgement(judgement: String, _chain: int):
		"""Show judgement with animation using images like original game"""
		# Set the appropriate judgement image
		if judgement in judgement_textures:
			judgement_image.texture = judgement_textures[judgement]
		else:
			print("⚠️ Unknown judgement: ", judgement)
			return
		
		# Always show image in full color (no color tinting needed for images)
		judgement_image.modulate = Color(1, 1, 1, 1)  # Full opacity, no color change
		
		# Animate appearance and fade
		if judgement_tween:
			judgement_tween.kill()
		judgement_tween = create_tween()
		
		# Fade in quickly, hold, then fade out (same timing as original)
		judgement_tween.tween_property(judgement_image, "modulate:a", 1.0, 0.1)
		judgement_tween.tween_interval(0.8)  # Use tween_interval instead of tween_delay
		judgement_tween.tween_property(judgement_image, "modulate:a", 0.0, 0.5)
