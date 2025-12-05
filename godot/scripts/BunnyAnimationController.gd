extends Node3D

# Bunny Animation Controller
# Handles programmatic rotations for dive, fly, rise, turn-left, turn-right
# Instead of using separate .egg animation files

@export var bunny_mesh: MeshInstance3D
@export var animation_speed: float = 2.0
@export var dive_angle: float = -30.0  # degrees
@export var rise_angle: float = 30.0   # degrees
@export var turn_angle: float = 45.0   # degrees

enum BunnyState {
	NORMAL,
	DIVING,
	FLYING,
	RISING,
	TURNING_LEFT,
	TURNING_RIGHT
}

var current_state: BunnyState = BunnyState.NORMAL
var target_rotation: Vector3 = Vector3.ZERO
var original_rotation: Vector3 = Vector3.ZERO

func _ready():
	if bunny_mesh:
		original_rotation = bunny_mesh.rotation_degrees

func _process(delta):
	if bunny_mesh:
		# Smoothly interpolate to target rotation
		bunny_mesh.rotation_degrees = bunny_mesh.rotation_degrees.lerp(target_rotation, animation_speed * delta)

# Animation functions to call from gameplay code
func set_dive():
	current_state = BunnyState.DIVING
	target_rotation = original_rotation + Vector3(dive_angle, 0, 0)

func set_fly():
	current_state = BunnyState.FLYING
	target_rotation = original_rotation

func set_rise():
	current_state = BunnyState.RISING  
	target_rotation = original_rotation + Vector3(rise_angle, 0, 0)

func set_turn_left():
	current_state = BunnyState.TURNING_LEFT
	target_rotation = original_rotation + Vector3(0, 0, turn_angle)

func set_turn_right():
	current_state = BunnyState.TURNING_RIGHT
	target_rotation = original_rotation + Vector3(0, 0, -turn_angle)

func set_normal():
	current_state = BunnyState.NORMAL
	target_rotation = original_rotation

# Get current animation state
func get_current_state() -> BunnyState:
	return current_state

# Check if animation is complete (close to target rotation)
func is_animation_complete() -> bool:
	if not bunny_mesh:
		return true
	return bunny_mesh.rotation_degrees.distance_to(target_rotation) < 1.0
