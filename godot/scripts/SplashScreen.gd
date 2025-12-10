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
	
	# Manual node resolution for HTML export compatibility
	if not logo:
		logo = get_node_or_null("CenterContainer/VBoxContainer/Logo")
	if not splash_sound:
		splash_sound = get_node_or_null("SplashSound")
	if not timer:
		timer = get_node_or_null("Timer")
	
	# Debug resolved variables
	
	# Set splash sound volume using centralized config
	if splash_sound:
		AudioManager.apply_standard_volume(splash_sound, "sfx")
	else:
		pass # Failed to apply standard volume
	
	# Connect timer signal
	if timer:
		timer.timeout.connect(_on_timer_timeout)
		# Start timer as fallback
		timer.start()
	else:
		pass # Timer not available
	
	# Debug logo properties
	if logo:
		
		# Start with logo invisible
		logo.modulate.a = 0.0
	else:
		pass # Logo not available
	
	# Start the splash sequence
	start_splash()

func start_splash():
	"""Start the splash screen sequence"""
	
	# Try to play splash sound (may fail in HTML due to autoplay policy)
	if splash_sound and splash_sound.stream:
		splash_sound.play()
		# Check if it actually started playing
		await get_tree().process_frame
		if splash_sound.playing:
			pass # Sound is playing
		else:
			pass # Sound not playing
	else:
		pass # Splash sound not available
	
	# Only proceed if logo exists
	if not logo:
		_on_splash_complete()
		return
	
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
		splash_completed = true
		splash_finished.emit()

func _on_timer_timeout():
	"""Fallback timer in case tween doesn't work"""
	splash_finished.emit()

func _input(event):
	"""Allow skipping splash with specific keys only"""
	if not visible:
		return  # Don't handle input if splash screen is not visible
		
	if event is InputEventKey and event.pressed:
		# Only allow skipping with Enter, Space, or Escape
		if event.keycode in [KEY_ENTER, KEY_SPACE, KEY_ESCAPE]:
			skip_splash()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		# Allow any joypad button to skip
		skip_splash()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		# Allow mouse clicks to skip
		skip_splash()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		# Allow touch to skip
		skip_splash()
		get_viewport().set_input_as_handled()

func skip_splash():
	"""Skip splash screen and stop all audio"""
	if splash_completed:
		return  # Already completed, don't emit again
	
	# Stop splash sound immediately
	if splash_sound and splash_sound.playing:
		splash_sound.stop()
	
	# Stop the tween to prevent it from completing later
	if splash_tween:
		splash_tween.kill()
	
	# Stop the fallback timer to prevent double callbacks
	if timer:
		timer.stop()
	
	# Clear any pending input events to prevent them from affecting the main menu
	Input.flush_buffered_events()
	
	# Mark as completed and emit signal
	splash_completed = true
	splash_finished.emit()
