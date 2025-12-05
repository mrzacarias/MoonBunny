extends Node3D
class_name EarAnimationController

# Simple Ear Animation Controller - Alternating Wave Pattern
# Creates up-down wave motion through ear bones

@export var animation_player: AnimationPlayer
@export var skeleton: Skeleton3D
@export var wave_frequency: float = 10.0  # Hz - how fast the wave alternates
@export var wave_amplitude: float = 0.05  # Small but visible amplitude for testing

var ear_bones: Array[int] = []
var ear_bone_names: Array[String] = []
var base_time: float = 0.0

func _ready():
	# Find animation player and skeleton if not assigned
	if not animation_player:
		animation_player = ModelLoader.find_animation_player(get_parent())
	if not skeleton:
		skeleton = ModelLoader.find_skeleton(get_parent())
	
	
	if skeleton:
		setup_ear_bones()

func setup_ear_bones():
	"""Find and setup ear bones for animation"""
	if not skeleton:
		return
	
	
	# Find ear bones by name
	ear_bones.clear()
	ear_bone_names.clear()
	
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		var bone_name_lower = bone_name.to_lower()
		
		# Look for ear bones (skip Aux/base bones, focus on Ear1, Ear2, Ear3, Ear4)
		if ("ear" in bone_name_lower or "Ear" in bone_name) and not "aux" in bone_name_lower:
			ear_bones.append(i)
			ear_bone_names.append(bone_name)
	
	if ear_bones.size() == 0:
		# Fallback: use first few bones if no specific ear bones found
		for i in range(min(4, skeleton.get_bone_count())):
			if i > 0:  # Skip root bone
				ear_bones.append(i)
				ear_bone_names.append(skeleton.get_bone_name(i))

func _process(delta):
	"""Update ear wave animation"""
	if ear_bones.size() == 0 or not skeleton:
		return
	
	base_time += delta
	update_alternating_wave()

func update_alternating_wave():
	"""Create alternating up-down wave pattern through ear bones"""
	if not skeleton or ear_bones.size() == 0:
		return
	
	# Create the base wave - alternates between -1 and 1
	var wave_phase = sin(base_time * wave_frequency * PI * 2.0)
	
	# Apply alternating pattern to each bone
	for i in range(ear_bones.size()):
		var bone_index = ear_bones[i]
		var bone_position = i + 1  # Bone 1, 2, 3, 4...
		
		# Alternating pattern: odd bones go one way, even bones go the other
		var bone_direction = 1.0 if (bone_position % 2 == 1) else -1.0
		
		# Calculate very small rotation for this bone
		var bone_wave = wave_phase * bone_direction * wave_amplitude
		
		# Use X-axis rotation for vertical ear movement
		var rotation_vector = Vector3(bone_wave, 0.0, 0.0)
		
		# Get current pose rotation (or identity if none set)
		var current_rotation = skeleton.get_bone_pose_rotation(bone_index)
		if current_rotation == Quaternion.IDENTITY:
			# If no pose set, start from rest rotation
			current_rotation = skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
		
		# Apply small rotation increment
		var rotation_increment = Quaternion.from_euler(rotation_vector)
		var new_rotation = current_rotation * rotation_increment
		
		# Set the bone rotation
		skeleton.set_bone_pose_rotation(bone_index, new_rotation)

func set_wave_frequency(frequency: float):
	"""Set the wave frequency (Hz)"""
	wave_frequency = frequency

func set_wave_amplitude(amplitude: float):
	"""Set the wave amplitude (strength)"""
	wave_amplitude = amplitude

func enable_test_mode():
	"""Enable test mode with enhanced wave effect"""
	wave_frequency = 15.0  # Faster for testing
	wave_amplitude = 0.2   # Stronger for visibility

func play_wind_animation():
	"""Start the wave animation (compatibility function)"""
	# Animation starts automatically in _process
	pass

func set_movement_velocity(_velocity: Vector3):
	"""Compatibility function for movement influence (not used in this simple version)"""
	pass
