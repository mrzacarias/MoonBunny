extends Control

# Signal to notify when splash screen is finished
signal splash_finished

# References to child nodes
@onready var logo = $CenterContainer/VBoxContainer/Logo
@onready var splash_sound = $SplashSound
@onready var timer = $Timer

# Animation properties
var fade_in_duration = 0.5
var display_duration = 3.0
var fade_out_duration = 0.5

# State tracking
var splash_completed = false
var splash_tween: Tween

func _ready():
	print("SplashScreen: Ready")
	
	# Set splash sound volume using centralized config
	if splash_sound:
		AudioManager.apply_standard_volume(splash_sound, "sfx")
	
	# Connect timer signal
	timer.timeout.connect(_on_timer_timeout)
	
	# Debug logo properties
	print("SplashScreen: Logo texture: ", logo.texture)
	print("SplashScreen: Logo size: ", logo.size)
	print("SplashScreen: Logo custom_minimum_size: ", logo.custom_minimum_size)
	
	# Start with logo invisible
	logo.modulate.a = 0.0
	
	# Start the splash sequence
	start_splash()

func start_splash():
	"""Start the splash screen sequence"""
	print("SplashScreen: Starting splash sequence")
	
	# Play splash sound
	if splash_sound and splash_sound.stream:
		splash_sound.play()
	
	# Create tween sequence
	splash_tween = create_tween()
	
	# Fade in logo
	splash_tween.tween_property(logo, "modulate:a", 1.0, fade_in_duration)
	
	# Wait for display duration
	splash_tween.tween_interval(display_duration)
	
	# Fade out logo
	splash_tween.tween_property(logo, "modulate:a", 0.0, fade_out_duration)
	
	# When tween finishes, emit signal
	splash_tween.finished.connect(_on_splash_complete)

func _on_splash_complete():
	"""Called when splash animation completes"""
	if not splash_completed:
		print("SplashScreen: Splash complete, emitting signal")
		splash_completed = true
		splash_finished.emit()

func _on_timer_timeout():
	"""Fallback timer in case tween doesn't work"""
	print("SplashScreen: Timer timeout fallback")
	splash_finished.emit()

func _input(event):
	"""Allow skipping splash with specific keys only"""
	if not visible:
		return  # Don't handle input if splash screen is not visible
		
	if event is InputEventKey and event.pressed:
		# Only allow skipping with Enter, Space, or Escape
		if event.keycode in [KEY_ENTER, KEY_SPACE, KEY_ESCAPE]:
			print("SplashScreen: Skip key pressed, skipping splash")
			skip_splash()
	elif event is InputEventJoypadButton and event.pressed:
		# Allow any joypad button to skip
		print("SplashScreen: Joypad button pressed, skipping splash")
		skip_splash()
	elif event is InputEventMouseButton and event.pressed:
		# Allow mouse clicks to skip
		print("SplashScreen: Mouse button pressed, skipping splash")
		skip_splash()
	elif event is InputEventScreenTouch and event.pressed:
		# Allow touch to skip
		print("SplashScreen: Touch detected, skipping splash")
		skip_splash()

func skip_splash():
	"""Skip splash screen and stop all audio"""
	if splash_completed:
		return  # Already completed, don't emit again
	
	# Stop splash sound immediately
	if splash_sound and splash_sound.playing:
		splash_sound.stop()
		print("SplashScreen: Stopped elefante.wav sound")
	
	# Stop the tween to prevent it from completing later
	if splash_tween:
		splash_tween.kill()
	
	# Mark as completed and emit signal
	splash_completed = true
	splash_finished.emit()
