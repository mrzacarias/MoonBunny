extends Control

# References to control image
@onready var control_image = $ControlImage

# Control textures
var gamepad_texture: Texture2D
var keyboard_mouse_texture: Texture2D
var touch_texture: Texture2D

# Timer for minimum display time
var display_timer: Timer
var minimum_display_time: float = 3.0

# Signal to notify when ready to continue
signal ready_to_continue

func _ready():
	# Load control textures
	gamepad_texture = load("res://assets/textures/tela_gamepad.png")
	keyboard_mouse_texture = load("res://assets/textures/tela_keyboard_mouse.png")
	touch_texture = load("res://assets/textures/tela_touch.png")
	
	# Create and setup timer
	display_timer = Timer.new()
	display_timer.wait_time = minimum_display_time
	display_timer.one_shot = true
	display_timer.timeout.connect(_on_timer_timeout)
	add_child(display_timer)

func show_for_input_method(input_method: int):
	"""Show the appropriate control image based on input method"""
	# Set the appropriate texture based on input method
	match input_method:
		0: # KEYBOARD
			control_image.texture = keyboard_mouse_texture
		1: # MOUSE
			control_image.texture = keyboard_mouse_texture
		2: # GAMEPAD
			control_image.texture = gamepad_texture
		3: # TOUCH
			control_image.texture = touch_texture
		_:
			control_image.texture = keyboard_mouse_texture # Default fallback
	
	# Start the timer
	display_timer.start()

func _on_timer_timeout():
	"""Called when minimum display time has elapsed"""
	ready_to_continue.emit()
