extends Node3D

# Level class based on original MoonBunny Level class
class_name Level

# Import GUI components
const LevelGUIClass = preload("res://scripts/LevelGUI.gd")

signal level_finished(result_data: Dictionary)
signal ring_hit(judgement: String, chain: int, ring_type: String, is_type_specific: bool)
signal music_started()

# Constants from original - expanded movement area for better gameplay
const FLY_AREA_W = 8.0  # Increased from 6.0 for wider movement
const FLY_AREA_H = 6.0  # Increased from 4.0 for taller movement
const FLY_AREA_L = -2.5  # Expanded left boundary
const FLY_AREA_R = 2.5   # Expanded right boundary
const FLY_AREA_T = -7.7   # Adjusted for camera Z=-10 (bunny at -9.7, range ±2.0)
const FLY_AREA_B = -11.7   # Adjusted for camera Z=-10 (bunny at -9.7, range ±2.0)

const RING_SPACING_PER_BEAT = 20.0  # Match original MoonBunny spacing
const CONTROL_UPDATE_DELAY = 0.016  # ~60fps
const SPEED_SCALE = 0.05
const TERRAIN_SPEED_MULTIPLIER = 0.2  # Slower terrain movement for better feel
const TERRAIN_PATCH_SIZE = 24.0  # Consistent terrain patch size for GLB files
# Remove timing offset - original game doesn't use one, the offset comes from the positioning mismatch

# Level info
var level_name: String
var difficulty: String = "Normal"
var is_training: bool = false

# Game state
var music_bpm: float = 120.0
var beat_delay: float
var music_start_time: float
var is_playing: bool = false
var score: int = 0
var chain: int = 0
var terrain_offset: float = 0.0  # Separate terrain position tracking

# Automatic delay detection for visual synchronization
var timing_offset: float = 0.0  # Calculated timing offset to apply to player position
var calibration_complete: bool = false

# Judgement stats
var judgement_stats = {
	"PERFECT": 0,
	"GOOD": 0,
	"OK": 0,
	"BAD": 0,
	"MISS": 0
}
var n_rings: int = 0

# Scene references (now from .tscn file)
@onready var bunny_actor: Node3D = $BunnyActor
@onready var camera: Camera3D = $Camera3D
@onready var environment_node: Node3D = $Environment
@onready var rings_container: Node3D = $Rings
@onready var terrain_container: Node3D = $Terrain
@onready var skybox_container: Node3D = $Skybox
@onready var audio_container: Node3D = $Audio
@onready var gui_container: Node3D = $GUI
var audio_player: AudioStreamPlayer

# Game objects
var ring_list: Array = []
var terrain_patch_list: Array = []
var skybox: MeshInstance3D

# Multi-input support variables
var mouse_old_x: float = 0.0
var mouse_old_y: float = 0.0
var mouse_factor: float = 240.0  # Same as original
var target_position: Vector3  # Target position for smooth movement
var movement_lerp_speed: float = 8.0  # Speed of smooth movement interpolation
# Input method tracking for smart switching
enum InputMethod {
	KEYBOARD,
	MOUSE,
	GAMEPAD,
	TOUCH
}
var current_input_method: InputMethod = InputMethod.KEYBOARD
var input_method_lock_timer: float = 0.0
var INPUT_METHOD_LOCK_DURATION: float = 0.2  # Shorter lock for more responsive switching
var using_pointer_input: bool = false  # Legacy compatibility flag
var last_touch_time: float = 0.0  # Debouncing for touch input
const TOUCH_DEBOUNCE_TIME: float = 0.2  # 200ms debounce
var touch_start_position: Vector2 = Vector2.ZERO  # Track where touch started
var is_dragging: bool = false  # Track if currently dragging
const DRAG_THRESHOLD: float = 20.0  # Minimum distance to consider it a drag (pixels)

# Animation variables for smooth LERP
var base_rotation: Vector3 = Vector3(0, 180, 0)  # Base flying pose
var target_rotation: Vector3 = Vector3(0, 180, 0)  # Target rotation for smooth animation
var animation_lerp_speed: float = 6.0  # Speed of rotation animation
var movement_velocity: Vector3 = Vector3.ZERO  # Smoothed movement velocity for animation

# GUI elements (like original)
var button_viewer: LevelGUIClass.ButtonViewer
# judgement_display is now handled by GameplayUI in Main.gd

# Input handling
var button_map = {"left": false, "right": false, "up": false, "down": false}
var last_control_update: float = 0.0

# Sounds
var miss_sound: AudioStreamPlayer
var start_level_sound: AudioStreamPlayer
var hit_sounds: Dictionary = {}

func _init(level_name_param: String = "", diff: String = "Normal", training: bool = false):
	level_name = level_name_param
	difficulty = diff
	is_training = training

func _exit_tree():
	"""Ensure mouse cursor is restored when level is destroyed"""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready():
	
	# Hide mouse cursor during gameplay for cleaner experience
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Load level header to get BPM and other info
	load_level_header()
	
	# Calculate beat delay from BPM
	beat_delay = 60.0 / music_bpm
	
	setup_audio()
	setup_graphics()
	setup_terrain()
	setup_gui()
	setup_rings()
	setup_input()
	
	# Initialize target position for smooth movement
	if bunny_actor:
		target_position = bunny_actor.position
		# Initialize animation rotation
		bunny_actor.rotation_degrees = base_rotation
		target_rotation = base_rotation
	
	# Initial positions logged
	
	# Start tasks (like original ctask_ functions)
	setup_tasks()

func setup_audio():
	"""Setup audio system like original"""
	# Load level music from resource manager
	if level_name != "":
		var music_stream = LevelResourceManager.get_level_music(level_name)
		if music_stream:
			audio_player = AudioStreamPlayer.new()
			audio_player.stream = music_stream
			AudioManager.apply_standard_volume(audio_player, "level_music")
			audio_container.add_child(audio_player)
		else:
			print("ERROR: Failed to load music file for level: ", level_name)
	
	# Load sound effects
	miss_sound = AudioStreamPlayer.new()
	var miss_stream = load("res://assets/sounds/miss.ogg")
	if miss_stream:
		miss_sound.stream = miss_stream
		AudioManager.apply_standard_volume(miss_sound, "sfx")
		audio_container.add_child(miss_sound)
	
	# Load start level sound
	start_level_sound = AudioStreamPlayer.new()
	var start_stream = load("res://assets/sounds/start_level.ogg")
	if start_stream:
		start_level_sound.stream = start_stream
		AudioManager.apply_standard_volume(start_level_sound, "sfx")
		audio_container.add_child(start_level_sound)

func setup_graphics():
	"""Setup 3D graphics like original"""
	# Setup bunny actor (bunny_actor node already exists from scene)
	setup_bunny_actor()
	
	# Camera is already positioned in the scene file
	# Just make sure it looks at origin
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	
	# Create skybox
	setup_skybox()
	
	# Check if mesh skybox has any materials (override or surface)
	var _skybox_has_materials = false
	if skybox:
		if skybox.material_override:
			_skybox_has_materials = true
		elif skybox.mesh:
			for i in range(skybox.mesh.get_surface_count()):
				if skybox.mesh.surface_get_material(i):
					_skybox_has_materials = true
					break
	
	# Force environment sky for better web export brightness
	setup_environment_sky()
	
	# Lighting is already set up in the scene file, but adjust for HTML platform
	adjust_lighting_for_platform()

func setup_bunny_actor():
	"""Setup bunny actor with mesh and animations like original"""
	# Load main bunny model using ModelLoader (GLB preferred)
	var bunny_mesh_path = "res://assets/models/bunny_boy.glb"
	var bunny_texture_path = "res://assets/models/bunnyboy.tga"
	
	var bunny_scene_or_mesh = ModelLoader.load_model_with_materials(bunny_mesh_path, bunny_texture_path)
	
	if bunny_scene_or_mesh == null:
		# Fallback to capsule mesh
		var mesh_instance = MeshInstance3D.new()
		var capsule_mesh = CapsuleMesh.new()
		capsule_mesh.radius = 0.3
		capsule_mesh.height = 0.6
		mesh_instance.mesh = capsule_mesh
		
		# Apply fallback material
		var fallback_material = StandardMaterial3D.new()
		fallback_material.albedo_color = Color(1.0, 0.95, 0.9, 1.0)  # Slightly brighter bunny-like color for web
		fallback_material.roughness = 0.4
		fallback_material.metallic = 0.0
		mesh_instance.material_override = fallback_material
		
		bunny_actor.add_child(mesh_instance)
	else:
		# Check if we got a full scene (GLB) or just a mesh (OBJ fallback)
		if bunny_scene_or_mesh is Node3D and bunny_scene_or_mesh.get_child_count() > 0:
			# This is a full GLB scene with potential animations
			bunny_actor.add_child(bunny_scene_or_mesh)
			
			# Setup ear animation controller if we have animations
			var animation_player = ModelLoader.find_animation_player(bunny_scene_or_mesh)
			var skeleton = ModelLoader.find_skeleton(bunny_scene_or_mesh)
			
			if animation_player or skeleton:
				var ear_controller = preload("res://scripts/EarAnimationController.gd").new()
				ear_controller.name = "EarAnimationController"
				ear_controller.animation_player = animation_player
				ear_controller.skeleton = skeleton
				
				# Configure ear animation settings for alternating wave effect
				ear_controller.wave_frequency = 10.0  # 10Hz alternating wave frequency
				ear_controller.wave_amplitude = 0.05  # Small but visible amplitude
				
				bunny_scene_or_mesh.add_child(ear_controller)
				
				# Store reference for later use
				bunny_actor.set_meta("ear_controller", ear_controller)
				
				# Start wind animation if available
				ear_controller.play_wind_animation()
		else:
			# This is just a MeshInstance3D (OBJ fallback or simple mesh)
			bunny_actor.add_child(bunny_scene_or_mesh)
	
	# Add custom properties like original
	bunny_actor.set_meta("speed", Vector3.ZERO)
	bunny_actor.set_meta("last_update", 0.0)
	bunny_actor.set_meta("current_anim", "fly")
	
	# Adjust bunny Z position to be close to camera Z=-10 (small offset for visibility)
	bunny_actor.position.z = -10

func setup_skybox():
	"""Create a proper textured skybox like the original"""
	# Try multiple approaches for skybox
	
	# Method 1: Try to load the original skybox GLB model
	var skybox_scene = ModelLoader.load_mesh_only("res://assets/models/skybox")
	if skybox_scene:
		# Find the main mesh instance in the skybox scene
		skybox = ModelLoader.find_mesh_instance(skybox_scene)
		if skybox:
			# Remove from current parent before adding to new parent
			if skybox.get_parent():
				skybox.get_parent().remove_child(skybox)
			
			# Clear the owner to avoid inconsistency warnings
			skybox.owner = null
			
			skybox.name = "SkyboxMesh"
			
			# Check if the skybox model has materials
			var has_materials = false
			if skybox.material_override:
				has_materials = true
			elif skybox.mesh:
				# Check mesh surface materials
				for i in range(skybox.mesh.get_surface_count()):
					var surface_material = skybox.mesh.surface_get_material(i)
					if surface_material:
						has_materials = true
						break
			
			if not has_materials:
				var sky_material = ModelLoader.create_skybox_material()
				skybox.material_override = sky_material
		
		# Clean up the temporary scene since we extracted the mesh
		skybox_scene.queue_free()
	else:
		# Method 2: Create a large inverted cube (better UV mapping than sphere)
		skybox = MeshInstance3D.new()
		skybox.name = "SkyboxMesh"
		
		# Use BoxMesh instead of SphereMesh for better texture mapping
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(4000, 4000, 4000)  # Much larger box so rotation is less noticeable
		skybox.mesh = box_mesh
		
		# Create skybox material
		var sky_material = ModelLoader.create_skybox_material()
		skybox.material_override = sky_material
		
		# Flip the box inside-out by scaling negatively
		skybox.scale = Vector3(-1, 1, -1)
		# Created procedural box skybox
	
	# Position at world origin and orient the donut horizontally (flipped)
	skybox.position = Vector3(0, 0, 0)
	skybox.rotation_degrees = Vector3(90, 0, 0)  # Rotate 90 degrees to flip donut vertically (back to original)
	skybox.scale = Vector3(100, 120, 30)  # Make donut 5x bigger (was 10x, now 50x)
	skybox_container.add_child(skybox)
	
	# Debug: Print skybox info
	# Skybox setup complete

func animate_skybox_texture():
	"""Animate skybox texture UV coordinates for cloud movement effect"""
	if not skybox or not skybox.mesh:
		return
	
	var material = null
	
	# Try material_override first
	if skybox.material_override:
		material = skybox.material_override
	# If no material_override, try surface materials
	elif skybox.mesh.get_surface_count() > 0:
		material = skybox.mesh.surface_get_material(0)
	
	if material and material is StandardMaterial3D:
		var std_material = material as StandardMaterial3D
		# Simple horizontal drift only - no vertical movement
		var time = Time.get_ticks_msec() / 1000.0
		var uv_offset = Vector3(time * 0.01, 0.0, 0.0)  # Only X axis drift, no Y movement
		std_material.uv1_offset = uv_offset

func adjust_lighting_for_platform():
	"""Adjust lighting brightness for HTML platform - make objects darker"""
	if OS.get_name() == "Web":
		# Find and adjust DirectionalLight nodes (now 40% darker total)
		var env_node = get_node("Environment")
		if env_node:
			for child in env_node.get_children():
				if child is DirectionalLight3D:
					var original_energy = child.light_energy
					child.light_energy = original_energy * 0.6  # 40% darker (was 0.8, now 0.6)
		
		# Adjust camera environment ambient light if it exists (now 40% darker total)
		if camera and camera.environment:
			var env = camera.environment
			var original_ambient = env.ambient_light_energy
			env.ambient_light_energy = original_ambient * 0.6  # 40% darker (was 0.8, now 0.6)

func setup_environment_sky():
	"""Setup environment-based sky as backup method"""
	if not camera:
		return
		
	# Create environment if it doesn't exist
	var env = camera.environment
	if not env:
		env = Environment.new()
		camera.environment = env
	
	# Try to set up sky with texture
	var sky_texture_paths = [
		"res://assets/models/skybox_sky.jpg",
		"res://assets/models/sky.jpg"
	]
	
	for sky_texture_path in sky_texture_paths:
		if ResourceLoader.exists(sky_texture_path):
			var sky_texture = load(sky_texture_path)
			if sky_texture and sky_texture is Texture2D:
				# Create sky material with platform-specific brightness
				var sky = Sky.new()
				var sky_material = PanoramaSkyMaterial.new()
				sky_material.panorama = sky_texture
				
				# Use same energy for all platforms to ensure consistent brightness
				sky_material.energy_multiplier = 1.8  # Same energy for both web and desktop
				
				sky.sky_material = sky_material
				
				# Apply to environment with enhanced settings
				env.background_mode = Environment.BG_SKY
				env.sky = sky
				env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
				env.sky_custom_fov = 0.0  # Use full panorama
				
				return
	

# Material creation functions moved to ModelLoader.gd

func override_terrain_materials(terrain_scene: Node3D):
	"""Modify existing materials in terrain scene to remove reflections while preserving textures"""
	# Recursively find all MeshInstance3D nodes and modify their materials
	var mesh_instances = find_all_mesh_instances(terrain_scene)
	
	for mesh_instance in mesh_instances:
		if mesh_instance is MeshInstance3D:
			# Try to modify existing materials instead of replacing them
			modify_mesh_materials(mesh_instance)

func modify_mesh_materials(mesh_instance: MeshInstance3D):
	"""Modify materials on a mesh instance to remove reflections while preserving textures"""
	if not mesh_instance.mesh:
		return
	
	# Check all surface materials
	for surface_idx in range(mesh_instance.mesh.get_surface_count()):
		var material = mesh_instance.get_surface_override_material(surface_idx)
		if not material:
			material = mesh_instance.mesh.surface_get_material(surface_idx)
		
		if material and material is StandardMaterial3D:
			# Modify the existing material properties to remove reflections
			var std_material = material as StandardMaterial3D
			std_material.roughness = 1.0  # Maximum roughness for no reflections
			std_material.metallic = 0.0   # No metallic properties
			# Note: specular property removed in Godot 4.x - controlled by roughness and metallic
			# Keep all other properties (textures, colors, etc.) unchanged

func find_all_mesh_instances(node: Node) -> Array:
	"""Recursively find all MeshInstance3D nodes in a scene"""
	var mesh_instances = []
	
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		mesh_instances.append_array(find_all_mesh_instances(child))
	
	return mesh_instances

func create_fallback_terrain(index: int, patch_size: float, terrain_z: float, start_offset: float = -50.0):
	"""Create fallback terrain when .obj files can't be loaded"""
	var terrain_mesh = PlaneMesh.new()
	terrain_mesh.size = Vector2(40, 40)
	terrain_mesh.subdivide_width = 20  # More subdivisions for better detail
	terrain_mesh.subdivide_depth = 20
	
	var terrain_instance = MeshInstance3D.new()
	terrain_instance.mesh = terrain_mesh
	
	# Position and rotate to be horizontal with proper start offset
	terrain_instance.position = Vector3(0, start_offset + patch_size * index - 0.1, terrain_z)
	terrain_instance.rotation_degrees = Vector3(-90, 0, 0)
	
	# Create material with textures using ModelLoader
	var terrain_type = (index % 8) + 1
	var texture_path = ModelLoader.get_terrain_texture_for_type(terrain_type)
	var material = ModelLoader.create_material_with_texture(texture_path)
	material.uv1_scale = Vector3(4.0, 4.0, 1.0)  # Tile the texture
	
	# Extra settings to eliminate reflections on terrain
	material.roughness = 1.0  # Maximum roughness for no reflections
	material.metallic = 0.0   # No metallic properties
	# Note: specular property removed in Godot 4.x - controlled by roughness and metallic
	terrain_instance.material_override = material
	
	terrain_container.add_child(terrain_instance)
	terrain_patch_list.append(terrain_instance)

# Lighting is now set up in the Level.tscn scene file

func setup_terrain():
	"""Setup terrain patches like original"""
	# Reduce terrain patches for web performance
	var terrain_patches = 30
	if OS.get_name() == "Web":
		terrain_patches = 20  # Reduce by 33% for web
	
	const TERRAIN_Z = -15.0
	var terrain_patch_size = TERRAIN_PATCH_SIZE  # Use consistent size for GLB files
	
	# Start terrain earlier to cover player starting position
	# Player starts at Y=0, camera at Y=-2.5, so we need terrain to start before that
	var terrain_start_offset = -50.0  # Start terrain well before player position
	
	for i in range(terrain_patches):
		# Use all 8 terrain types cycling through them
		var terrain_index = (i % 8) + 1
		
		# Use ModelLoader to load terrain (tries GLB first, then OBJ fallback)
		var terrain_scene = ModelLoader.load_mesh_only("res://assets/models/terrain_%d" % terrain_index)
		
		if terrain_scene:
			# For GLB files, we want to preserve all meshes, so add the complete scene
			# This ensures floating mountains and other terrain details are included
			
			# Position terrain to start before player position and extend forward
			terrain_scene.position = Vector3(0, terrain_start_offset + terrain_patch_size * i - 0.1, TERRAIN_Z)
			
			# Rotate terrain to be horizontal
			terrain_scene.rotation_degrees = Vector3(-90, 0, 180)
			
			# Override all materials in the terrain scene to remove reflections
			override_terrain_materials(terrain_scene)
			
			terrain_container.add_child(terrain_scene)
			terrain_patch_list.append(terrain_scene)
		else:
			# Use fallback if loading failed
			create_fallback_terrain(i, terrain_patch_size, TERRAIN_Z, terrain_start_offset)

func setup_gui():
	"""Setup GUI elements like original gui.py"""
	# Create button viewer (button timeline at bottom of screen)
	button_viewer = LevelGUIClass.ButtonViewer.new(music_bpm)
	gui_container.add_child(button_viewer)
	
	# Judgement display is now handled by GameplayUI in Main.gd

func cleanup_gui():
	"""Clean up GUI elements when level ends"""
	if button_viewer and is_instance_valid(button_viewer):
		button_viewer.queue_free()
		button_viewer = null
	
	# Judgement display is now handled by GameplayUI in Main.gd
	

func setup_rings():
	"""Setup rings from level data like original"""
	if level_name == "":
		return
		
	# Load ring data (simplified for now)
	# In original, this comes from parse.level_rings()
	var ring_data = load_ring_data()
	
	for ring_info in ring_data:
		# Create ring mesh (torus)
		var ring_instance = MeshInstance3D.new()
		var torus_mesh = TorusMesh.new()
		torus_mesh.inner_radius = 1.0
		torus_mesh.outer_radius = 1.3
		ring_instance.mesh = torus_mesh
		
		# Position like original - use time to calculate position like time2pos()
		var pos = ring_info.get("position", Vector2.ZERO)
		var ring_time = ring_info.get("time", 0.0)
		var button = ring_info.get("button", "A")
		
		# Use same formula as moonbunny_godot for consistency: time_to_position()
		# This converts time to beats first, then to position
		var ring_y = time_to_position(ring_time)
		
		# Calculate base position with proper normalization to keep rings in bounds
		# Use expanded area bounds to allow rings closer to the edges (match moonbunny_godot)
		var safe_area_x = FLY_AREA_R * 0.95  # 2.375 (95% of full area to allow maximum spread)
		var safe_area_z = abs(FLY_AREA_T - FLY_AREA_B) / 2.0 * 0.95  # 1.9 (95% of Z range for maximum spread)
		
		# Normalize the position to fit within bounds
		# First, scale the position to use more of the available space (match moonbunny_godot)
		var scaled_x = pos.x * 7.0  # Scale up for more spread (increased to match moonbunny_godot)
		var scaled_z = pos.y * 7.0  # Scale up for more spread (increased to match moonbunny_godot)
		
		# Then clamp to area bounds
		var base_x = clamp(scaled_x, -safe_area_x, safe_area_x)
		var base_z = clamp(scaled_z, -safe_area_z, safe_area_z)
		
		# Add randomization for rings at center (0,0) to make them more scattered
		if pos.x == 0.0 and pos.y == 0.0:
			# Add random offset for center rings within bounds (reduced by 50%)
			base_x += randf_range(-safe_area_x * 0.4, safe_area_x * 0.4)
			base_z += randf_range(-safe_area_z * 0.4, safe_area_z * 0.4)
		else:
			# Add small randomization to all rings for more variety (reduced by 50%)
			base_x += randf_range(-0.15, 0.15)
			base_z += randf_range(-0.1, 0.1)
		
		# Final clamp to ensure we never go outside bounds
		base_x = clamp(base_x, -safe_area_x, safe_area_x)
		base_z = clamp(base_z, -safe_area_z, safe_area_z)
		
		# Calculate the exact ring position once and reuse it
		var ring_position = Vector3(
			base_x,  # X = left/right
			ring_y,  # Y = forward
			(FLY_AREA_T + FLY_AREA_B) / 2.0 + base_z   # Z = up/down - centered in fly area (match moonbunny_godot)
		)
		ring_instance.position = ring_position
		
		# Add ring material using ModelLoader
		var ring_material = ModelLoader.create_ring_material(button)
		ring_instance.material_override = ring_material
		
		# Create debug inner circle for proximity bonus visualization (75% of ring radius)
		var inner_circle = MeshInstance3D.new()
		var inner_torus = TorusMesh.new()
		
		# Calculate the proximity radius more accurately based on screen-space projection
		# We'll use 75% of the main ring's outer radius as a base, but this will be
		# more accurate when viewed from different camera angles
		var proximity_radius = 1.5 * 0.4  # 40% of main ring collision radius = 0.6
		inner_torus.inner_radius = proximity_radius - 0.08  # Slightly thicker for better visibility
		inner_torus.outer_radius = proximity_radius
		inner_circle.mesh = inner_torus
		
		# Create a semi-transparent material for the debug circle matching main ring color
		var debug_material = StandardMaterial3D.new()
		# Get the same color as the main ring but with 40% transparency
		var main_ring_color = ring_material.albedo_color
		debug_material.albedo_color = Color(main_ring_color.r, main_ring_color.g, main_ring_color.b, 0.4)
		debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debug_material.flags_unshaded = true
		debug_material.no_depth_test = false  # Enable depth testing for proper occlusion
		
		inner_circle.material_override = debug_material
		
		# Position the inner circle at the EXACT same location as the ring
		inner_circle.position = ring_position
		
		rings_container.add_child(ring_instance)
		rings_container.add_child(inner_circle)
		
		# Store ring data - EXACT original format plus debug circle reference
		# Original: self.ring_list.append({"node":ring, "time":beat*self.BEAT_DELAY, "button":button, "cleared": False})
		# But "beat" was actually time, so time*BEAT_DELAY = time*(60/BPM) = time*beat_delay
		ring_list.append({
			"node": ring_instance,
			"debug_circle": inner_circle,  # Reference to debug inner circle
			"time": ring_time,  # Use ring_time directly (already in seconds, like moonbunny_godot)
			"button": button,
			"cleared": false,
			"position": pos,  # Original normalized position for reference
			"world_position": Vector2(base_x, (FLY_AREA_T + FLY_AREA_B) / 2.0 + base_z)  # Actual world position for collision detection
		})
		
		# Add button to button viewer (timeline at bottom)
		if button_viewer:
			button_viewer.append_button(button, ring_y)
	
	n_rings = ring_list.size()

func load_ring_data() -> Array:
	"""Load ring data from resource manager"""
	var ring_data = []
	
	if level_name == "":
		return ring_data
	
	# Get ring content from resource manager
	var ring_content = LevelResourceManager.get_level_rings(level_name)
	if ring_content == "":
		return ring_data
	
	var lines = ring_content.split("\n")
	var cumulative_time = 0.0
	var _line_number = 0
	
	for line in lines:
		line = line.strip_edges()
		_line_number += 1
		
		# Skip empty lines and comments
		if line == "" or line.begins_with("#"):
			continue
		
		# Parse line: "x, y; time; button" or "x,y ; time ; button"
		var parts = line.split(";")
		if parts.size() != 3:
			continue
		
		# Parse position - handle both "x, y" and "x,y" formats
		var pos_str = parts[0].strip_edges()
		var pos_parts = pos_str.split(",")
		if pos_parts.size() != 2:
			continue
		
		var x = pos_parts[0].strip_edges().to_float()
		var y = pos_parts[1].strip_edges().to_float()
		
		# Parse time (cumulative)
		var time_str = parts[1].strip_edges()
		var time_delta = time_str.to_float()
		cumulative_time += time_delta
		
		# Parse button
		var button = parts[2].strip_edges()
		
		# Store both time and beat for proper positioning
		var beat = cumulative_time / beat_delay
		
		ring_data.append({
			"position": Vector2(x, y),
			"beat": beat,
			"button": button,
			"time": cumulative_time
		})
		
	
	return ring_data

func setup_input():
	"""Setup input handling like original"""
	# Input will be handled in _process and _input functions
	pass


func load_level_header():
	"""Load level header file to get BPM and other metadata from resource manager"""
	if level_name == "":
		return
	
	# Use resource manager to get parsed header data
	var level_data = LevelResourceManager.parse_level_header(level_name)
	if level_data.has("BPM"):
		music_bpm = level_data["BPM"]
	else:
		print("ERROR: Failed to parse BPM from header file for level: ", level_name)

func setup_tasks():
	"""Setup continuous tasks like original ctask_ functions"""
	# These will be handled in _process function
	pass

func play():
	"""Start level playback like original with start sound delay"""
	if start_level_sound and start_level_sound.stream:
		# Play start level sound first, then music after it finishes
		start_level_sound.play()
		start_level_sound.finished.connect(_on_start_sound_finished)
	else:
		# Fallback: start music immediately
		_start_music()

func _on_start_sound_finished():
	"""Called when start level sound finishes, then start music"""
	_start_music()

func _start_music():
	"""Actually start the level music"""
	if audio_player and audio_player.stream:
		audio_player.play()
		music_start_time = Time.get_unix_time_from_system()
		is_playing = true
		
		# Detect HTML delay pattern and set timing offset
		if not calibration_complete:
			var music_time = audio_player.get_playback_position()
			if music_time == 0.0:
				# HTML delay pattern detected
				timing_offset = 1.1
			else:
				# Normal timing
				timing_offset = 0.0
			calibration_complete = true
		
		# Emit signal to notify that music has started
		music_started.emit()

func _process(_delta):
	"""Main game loop - combines all original ctask_ functions"""
	if not is_playing:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var music_time = audio_player.get_playback_position()
	
	# Move character (ctask_moveChar equivalent)
	update_character_movement(current_time, music_time, _delta)
	
	# Update camera (part of ctask_moveChar)
	update_camera(music_time)
	
	# Update button timeline (with timing offset for synchronization)
	if button_viewer:
		var adjusted_music_time = music_time + timing_offset
		button_viewer.update_timeline(adjusted_music_time)
	
	# Check rings (ctask_checkNextRing equivalent)
	check_next_ring(music_time)
	
	# Update terrain (ctask_terrainPatch equivalent)
	update_terrain_patches(music_time)
	
	# Check for level end (ctask_checkEnd equivalent)
	check_level_end(music_time)

func update_character_movement(current_time: float, music_time: float, delta: float):
	"""Update character movement like original ctask_moveChar"""
	if not bunny_actor:
		return
	
	# Update bunny forward position based on music time (with timing offset for HTML delay)
	var adjusted_music_time = music_time + timing_offset
	var bunny_pos = time_to_position(adjusted_music_time)
	bunny_actor.position.y = bunny_pos
	
	# Timing is now correct, debug removed
	
	# Handle input-based movement
	if current_time - last_control_update > CONTROL_UPDATE_DELAY:
		var s_x = 0.0
		var s_z = 0.0
		
		# Handle mouse movement (like original control_mouse function)
		handle_mouse_movement()
		
		# Handle keyboard movement - always enabled alongside mouse/touch
		if button_map["left"]: s_x -= SPEED_SCALE
		if button_map["right"]: s_x += SPEED_SCALE
		if button_map["up"]: s_z += SPEED_SCALE
		if button_map["down"]: s_z -= SPEED_SCALE
		
		# Apply keyboard movement with clamping like original
		if s_x != 0 or s_z != 0:
			bunny_actor.position.x = clamp(bunny_actor.position.x + s_x, FLY_AREA_L, FLY_AREA_R)
			bunny_actor.position.z = clamp(bunny_actor.position.z + s_z, FLY_AREA_B, FLY_AREA_T)
			# Update animations based on movement like original (amplify for visibility)
			update_bunny_animation(s_x * 20.0, s_z * 20.0)
			# Set keyboard as input method when using keyboard
			set_input_method(InputMethod.KEYBOARD)
		
		# Handle gamepad movement
		handle_gamepad_movement()
		
		last_control_update = current_time
	
	# Apply smooth movement for mouse/touch (every frame)
	if current_input_method == InputMethod.MOUSE or current_input_method == InputMethod.TOUCH:
		apply_smooth_movement(delta)
	
	# Apply smooth animation (every frame)
	apply_smooth_animation(delta)

func update_bunny_animation(s_x: float, s_z: float):
	"""Update bunny animation target based on movement velocity"""
	if not bunny_actor:
		return
	
	# Smooth the movement velocity for less jittery animations
	var target_velocity = Vector3(s_x, 0, s_z)
	movement_velocity = movement_velocity.lerp(target_velocity, 0.2)
	
	# Calculate target rotation based on smoothed velocity
	var roll = 0.0  # Banking left/right
	var pitch = 0.0  # Pitching up/down
	
	# Banking (roll) based on horizontal movement
	if abs(movement_velocity.x) > 0.001:
		roll = -movement_velocity.x * 200.0  # Negative because bunny faces backwards (Y=180)
		roll = clamp(roll, -45.0, 45.0)  # Limit banking angle to max 45 degrees as requested
	
	# Pitching based on vertical movement  
	if abs(movement_velocity.z) > 0.001:
		pitch = -movement_velocity.z * 150.0  # Negative to fix inversion: up movement = pitch up
		pitch = clamp(pitch, -30.0, 30.0)  # Limit pitch angle
	
	# Removed excessive debug output
	
	# Set target rotation (base rotation + movement-based rotation)
	# Put roll back in Z component (correct for banking)
	target_rotation = base_rotation + Vector3(pitch, 0, roll)

func handle_mouse_movement():
	"""Handle mouse movement with precise screen-to-world coordinate mapping"""
	if not camera:
		return
	
	# Lock mouse movement when gamepad is being used
	if current_input_method == InputMethod.GAMEPAD:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Convert screen coordinates to normalized coordinates (0-1)
	var norm_x = mouse_pos.x / viewport_size.x
	var norm_y = mouse_pos.y / viewport_size.y
	
	# Map normalized coordinates to world fly area
	# X: 0 -> FLY_AREA_L, 1 -> FLY_AREA_R
	# Y: 0 -> FLY_AREA_T, 1 -> FLY_AREA_B (inverted because screen Y goes down, world Z goes up)
	var pos_x = lerp(FLY_AREA_L, FLY_AREA_R, norm_x)
	var pos_z = lerp(FLY_AREA_T, FLY_AREA_B, norm_y)
	
	# Clamp to fly area bounds (should already be in bounds, but just in case)
	pos_x = clamp(pos_x, FLY_AREA_L, FLY_AREA_R)
	pos_z = clamp(pos_z, FLY_AREA_B, FLY_AREA_T)
	
	# Check if mouse has moved significantly to activate mouse input
	var mouse_delta_x = mouse_pos.x - mouse_old_x
	var mouse_delta_y = mouse_pos.y - mouse_old_y
	var mouse_movement = Vector2(mouse_delta_x, mouse_delta_y).length()
	
	if mouse_movement > 5.0:  # Threshold to activate mouse input
		set_input_method(InputMethod.MOUSE)
	
	# Only process mouse positioning if mouse input is active
	if current_input_method == InputMethod.MOUSE:
		# Set target position for smooth movement
		if bunny_actor:
			target_position.x = pos_x
			target_position.z = pos_z
			
			# Scale mouse delta to reasonable animation values (increased sensitivity)
			var s_x = clamp(mouse_delta_x * 0.05, -2.0, 2.0)
			var s_z = clamp(-mouse_delta_y * 0.05, -2.0, 2.0)  # Invert Y for correct up/down mapping
			
			update_bunny_animation(s_x, s_z)
	
	# Always update mouse position for movement detection
	mouse_old_x = mouse_pos.x
	mouse_old_y = mouse_pos.y

func handle_touch_movement():
	"""Handle touch screen movement with smooth LERP"""
	# Touch events are handled in _input function instead

func handle_gamepad_movement():
	"""Handle gamepad movement"""
	# Check for connected gamepads
	var gamepads = Input.get_connected_joypads()
	if gamepads.is_empty():
		return
	
	# Use first connected gamepad
	var gamepad_id = gamepads[0]
	
	# Get analog stick input
	var left_stick_x = Input.get_joy_axis(gamepad_id, JOY_AXIS_LEFT_X)
	var left_stick_y = Input.get_joy_axis(gamepad_id, JOY_AXIS_LEFT_Y)
	
	# Apply deadzone
	var deadzone = 0.2
	if abs(left_stick_x) < deadzone: left_stick_x = 0.0
	if abs(left_stick_y) < deadzone: left_stick_y = 0.0
	
	# Apply movement
	var gamepad_speed = SPEED_SCALE * 2.0  # Slightly faster for analog sticks
	var s_x = left_stick_x * gamepad_speed
	var s_z = -left_stick_y * gamepad_speed  # Invert Y axis
	
	# Check if gamepad stick has moved to activate gamepad input (always check, regardless of current method)
	if abs(left_stick_x) > deadzone or abs(left_stick_y) > deadzone:
		set_input_method(InputMethod.GAMEPAD, true)  # Always bypass lock for immediate response
	
	# Apply movement only if gamepad is active
	if current_input_method == InputMethod.GAMEPAD:
		if bunny_actor and (abs(s_x) > 0 or abs(s_z) > 0):
			bunny_actor.position.x = clamp(bunny_actor.position.x + s_x, FLY_AREA_L, FLY_AREA_R)
			bunny_actor.position.z = clamp(bunny_actor.position.z + s_z, FLY_AREA_B, FLY_AREA_T)
			# Update animation for gamepad movement
			update_bunny_animation(s_x * 10.0, s_z * 10.0)  # Scale up for better animation response

func apply_smooth_movement(delta: float):
	"""Apply smooth LERP movement for mouse/touch input"""
	if not bunny_actor:
		return
	
	# Smoothly interpolate to target position
	bunny_actor.position.x = lerp(bunny_actor.position.x, target_position.x, movement_lerp_speed * delta)
	bunny_actor.position.z = lerp(bunny_actor.position.z, target_position.z, movement_lerp_speed * delta)

func apply_smooth_animation(_delta: float):
	"""Apply smooth LERP animation for bunny rotations"""
	if not bunny_actor:
		return
	
	# Update ear animation controller with current movement (new controller ignores movement)
	var ear_controller = bunny_actor.get_meta("ear_controller", null)
	if ear_controller and ear_controller.has_method("set_movement_velocity"):
		ear_controller.set_movement_velocity(movement_velocity)
	
	# Reset to base rotation first
	bunny_actor.rotation_degrees = base_rotation
	
	# Apply pitch (up/down) in local space
	var current_pitch = 0.0
	if abs(movement_velocity.z) > 0.001:
		current_pitch = -movement_velocity.z * 75.0  # Reduced from 150.0 (50% more subtle)
		current_pitch = clamp(current_pitch, -15.0, 15.0)  # Reduced max angle from 30.0
	
	# Apply roll (banking) in local space
	var current_roll = 0.0
	if abs(movement_velocity.x) > 0.001:
		current_roll = movement_velocity.x * 100.0  # Reduced from 200.0 (50% more subtle)
		current_roll = clamp(current_roll, -22.5, 22.5)  # Reduced max angle from 45.0
	
	# Apply rotations in local space
	if abs(current_pitch) > 0.1:
		bunny_actor.rotate_object_local(Vector3.RIGHT, deg_to_rad(current_pitch))
	if abs(current_roll) > 0.1:
		bunny_actor.rotate_object_local(Vector3.UP, deg_to_rad(current_roll))  # Try Vector3.UP as requested
	
	# Removed excessive debug output
	
	# If no movement for a while, gradually return to base pose
	if movement_velocity.length() < 0.005:
		movement_velocity = movement_velocity.lerp(Vector3.ZERO, 0.1)

func update_camera(_music_time: float):
	"""Update camera position like original"""
	if not camera or not bunny_actor:
		return
	
	# Camera follows bunny Y position with closer offset
	var camera_offset = 2.5
	camera.position.y = bunny_actor.position.y - camera_offset
	# Keep original X and Z positions
	camera.position.x = 0
	camera.position.z = -10
	
	# Debug: Print positions every 2 seconds
	# Position tracking (debug logs removed)
	
	# Update skybox - make it follow player X and Y position (no rotation of geometry)
	if skybox:
		# Make skybox follow bunny X (left/right) and Y (forward) position, keep Z fixed
		skybox.position = Vector3(bunny_actor.position.x, bunny_actor.position.y, -70)
		
		# Animate the texture UV coordinates instead of rotating the geometry
		animate_skybox_texture()

func check_next_ring(music_time: float):
	"""Check ring collision and timing like original ctask_checkNextRing"""
	if ring_list.is_empty():
		return
	
	var ring = ring_list[0]
	
	# Check if ring is missed - EXACT original logic (with timing offset)
	# Original: if ring["time"] - pos < -0.11: (where pos = self.music.getTime())
	var adjusted_music_time = music_time + timing_offset
	
	
	if ring["time"] - adjusted_music_time < -0.11:
		if not ring["cleared"]:
			# Miss!
			if miss_sound:
				miss_sound.play()
			chain = 0
			judgement_stats["MISS"] += 1
			
			# Show miss judgement feedback like original
			ring_hit.emit("MISS", chain, ring["button"], false)  # MISS is not type-specific
			
			ring["cleared"] = true
			
			# Remove ring and debug circle
			ring["node"].queue_free()
			if ring.has("debug_circle") and ring["debug_circle"]:
				ring["debug_circle"].queue_free()
			ring_list.pop_front()

func update_terrain_patches(_music_time: float):
	"""Update terrain patches like original ctask_terrainPatch"""
	if terrain_patch_list.is_empty():
		return
		
	var closest_patch = terrain_patch_list[0]
		
	# Check if camera has passed the closest patch (like original)
	if camera.global_position.y > closest_patch.global_position.y + 40:  # Approximate bounds
		var last_patch = terrain_patch_list[-1]
		var safe_patch_size = TERRAIN_PATCH_SIZE  # For GLB files
		
		# Move closest patch to the end
		closest_patch.position.y = last_patch.position.y + safe_patch_size - 0.1
		
		# Rotate the list
		terrain_patch_list.append(terrain_patch_list.pop_front())

func check_level_end(_music_time: float):
	"""Check if level should end like original ctask_checkEnd"""
	if not audio_player.playing and ring_list.is_empty():
		end_level()

func time_to_position(time: float) -> float:
	"""Convert music time to Y position - EXACT original time2pos"""
	# Original: return (time / delay_per_beat) * space_per_beat
	return (time / beat_delay) * RING_SPACING_PER_BEAT

func _input(event):
	"""Handle input events - keyboard, mouse, touch, and gamepad"""
	if event is InputEventKey:
		var pressed = event.pressed
		
		match event.keycode:
			# ESC key to end level early (like original)
			KEY_ESCAPE:
				if pressed:
					end_level()
			
			# Movement controls - use arrow keys like original
			KEY_LEFT:
				button_map["left"] = pressed
				if pressed: set_input_method(InputMethod.KEYBOARD)
			KEY_RIGHT:
				button_map["right"] = pressed
				if pressed: set_input_method(InputMethod.KEYBOARD)
			KEY_UP:
				button_map["up"] = pressed
				if pressed: set_input_method(InputMethod.KEYBOARD)
			KEY_DOWN:
				button_map["down"] = pressed
				if pressed: set_input_method(InputMethod.KEYBOARD)
			
			# Ring hitting controls - WASD like original with type-specific confirmation
			KEY_S:
				if pressed: 
					set_input_method(InputMethod.KEYBOARD)
					check_button_press("A")  # S = A button (Ring type A)
			KEY_A:
				if pressed: 
					set_input_method(InputMethod.KEYBOARD)
					check_button_press("C")  # A = C button (Ring type C)
			KEY_D:
				if pressed: 
					set_input_method(InputMethod.KEYBOARD)
					check_button_press("B")  # D = B button (Ring type B)
			KEY_W:
				if pressed: 
					set_input_method(InputMethod.KEYBOARD)
					check_button_press("D")  # W = D button (Ring type D)
			
			# Centralized hit button - spacebar for keyboard (works for all ring types)
			KEY_SPACE:
				if pressed: 
					set_input_method(InputMethod.KEYBOARD)
					check_centralized_button_press(InputMethod.KEYBOARD, Vector2.ZERO)
			
			# Test mode key for ear animations
			KEY_T:
				if pressed: enable_ear_test_mode()
	
	# Handle touch screen input
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Touch start - record position and time for drag detection
			var current_time = Time.get_time_dict_from_system()
			var current_timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second + current_time.millisecond / 1000.0
			
			set_input_method(InputMethod.TOUCH)
			touch_start_position = event.position
			is_dragging = false
			last_touch_time = current_timestamp
		else:
			# Touch release - check if it was a tap (not drag) for ring hitting
			if not is_dragging:
				# This was a tap, not a drag - hit rings
				var current_time = Time.get_time_dict_from_system()
				var current_timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second + current_time.millisecond / 1000.0
				
				# Debounce to prevent double-touches
				if current_timestamp - last_touch_time > TOUCH_DEBOUNCE_TIME:
					check_centralized_button_press(InputMethod.TOUCH, touch_start_position)
			is_dragging = false
	
	elif event is InputEventScreenDrag:
		# Touch drag - handle movement only
		set_input_method(InputMethod.TOUCH)
		
		# Check if we've moved enough to consider this a drag
		var drag_distance = event.position.distance_to(touch_start_position)
		if drag_distance > DRAG_THRESHOLD:
			is_dragging = true
		
		# Only handle movement if we're actually dragging (not just small movements)
		if is_dragging:
			handle_touch_at_position(event.position)
	
	# Handle mouse movement (when mouse moves)
	elif event is InputEventMouseMotion:
		# Mouse movement is handled in handle_mouse_movement() during _process
		pass
	
	# Handle mouse clicks for ring hitting
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					set_input_method(InputMethod.MOUSE)
					check_centralized_button_press(InputMethod.MOUSE, event.position)  # Mouse click works for all ring types
	
	# Handle gamepad button presses for ring hitting
	elif event is InputEventJoypadButton:
		if event.pressed:
			set_input_method(InputMethod.GAMEPAD)
			match event.button_index:
				JOY_BUTTON_A:
					check_button_press("A")  # A button = Ring type A
				JOY_BUTTON_X:
					check_button_press("B")  # X button = Ring type B
				JOY_BUTTON_B:
					check_button_press("C")  # B button = Ring type C
				JOY_BUTTON_Y:
					check_button_press("D")  # Y button = Ring type D

func handle_touch_at_position(touch_pos: Vector2):
	"""Handle touch input at given screen position with precise coordinate mapping"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Convert screen coordinates to normalized coordinates (0-1)
	var norm_x = touch_pos.x / viewport_size.x
	var norm_y = touch_pos.y / viewport_size.y
	
	# Map normalized coordinates to world fly area
	# X: 0 -> FLY_AREA_L, 1 -> FLY_AREA_R
	# Y: 0 -> FLY_AREA_T, 1 -> FLY_AREA_B (inverted because screen Y goes down, world Z goes up)
	var pos_x = lerp(FLY_AREA_L, FLY_AREA_R, norm_x)
	var pos_z = lerp(FLY_AREA_T, FLY_AREA_B, norm_y)
	
	# Clamp to fly area bounds (should already be in bounds, but just in case)
	pos_x = clamp(pos_x, FLY_AREA_L, FLY_AREA_R)
	pos_z = clamp(pos_z, FLY_AREA_B, FLY_AREA_T)
	
	# Set target position for smooth movement
	if bunny_actor:
		target_position.x = pos_x
		target_position.z = pos_z
		using_pointer_input = true
		
		# Calculate smooth movement velocity for animation
		var touch_delta_x = touch_pos.x - mouse_old_x
		var touch_delta_y = touch_pos.y - mouse_old_y
		
		# Scale touch delta to reasonable animation values (increased sensitivity)
		var s_x = clamp(touch_delta_x * 0.05, -2.0, 2.0)
		var s_z = clamp(-touch_delta_y * 0.05, -2.0, 2.0)  # Invert Y for correct up/down mapping
		
		update_bunny_animation(s_x, s_z)
		
		mouse_old_x = touch_pos.x
		mouse_old_y = touch_pos.y

func check_button_press(button: String):
	"""Check if button press hits a ring like original"""
	var music_time = audio_player.get_playback_position()
	if ring_list.is_empty():
		return
	
	var ring = ring_list[0]
	# Apply timing offset for hit detection synchronization
	var adjusted_music_time = music_time + timing_offset
	var time_diff = abs(ring["time"] - adjusted_music_time)
	
	
	# Check if correct button and within timing window
	if ring["button"] == button and not ring["cleared"]:
		var judgement = ""
		
		# Timing windows matching original game exactly with 50% bonus for type-specific hits
		var base_score = 0
		if time_diff <= 0.08:
			judgement = "PERFECT"
			base_score = 200  # Original score values
			chain += 1
		elif time_diff <= 0.2:
			judgement = "GOOD"
			base_score = 100
			chain += 1
		elif time_diff <= 0.3:
			judgement = "OK"
			base_score = 50
			chain += 1
		elif time_diff <= 0.5:
			judgement = "BAD"
			base_score = 5
			chain = 0
		else:
			return  # Too far off
		
		# Apply 50% bonus for using type-specific key
		var bonus_score = int(base_score * 1.5)
		score += bonus_score
		
		# Check position accuracy - use world coordinates for both
		var bunny_pos = Vector2(bunny_actor.position.x, bunny_actor.position.z)
		var ring_world_pos = ring.get("world_position", Vector2.ZERO)
		var distance = bunny_pos.distance_to(ring_world_pos)
		
		# Increase collision radius to be more forgiving - ring outer radius is 1.3
		if distance < 1.5:  # Within ring collision area
			judgement_stats[judgement] += 1
			ring["cleared"] = true
			
			# Button hit feedback like original: self.btn_viewer.button_hit()
			if button_viewer:
				button_viewer.button_hit()
			
			ring_hit.emit(judgement, chain, ring["button"], true)  # Type-specific hit
			
			# Remove ring and debug circle
			ring["node"].queue_free()
			if ring.has("debug_circle") and ring["debug_circle"]:
				ring["debug_circle"].queue_free()
			ring_list.pop_front()

func check_centralized_button_press(input_method: InputMethod, screen_position: Vector2 = Vector2.ZERO):
	"""Check if centralized button press hits a ring - ignores button type (for mouse/touch)"""
	var music_time = audio_player.get_playback_position()
	if ring_list.is_empty():
		return
	
	var ring = ring_list[0]
	# Apply timing offset for hit detection synchronization
	var adjusted_music_time = music_time + timing_offset
	var time_diff = abs(ring["time"] - adjusted_music_time)
	
	# Check timing window regardless of button type (centralized hit)
	if not ring["cleared"]:
		var judgement = ""
		
		# Timing windows matching original game exactly with 50% bonus only for touch hits
		var base_score = 0
		if time_diff <= 0.08:
			judgement = "PERFECT"
			base_score = 200  # Original score values
			chain += 1
		elif time_diff <= 0.2:
			judgement = "GOOD"
			base_score = 100
			chain += 1
		elif time_diff <= 0.3:
			judgement = "OK"
			base_score = 50
			chain += 1
		elif time_diff <= 0.5:
			judgement = "BAD"
			base_score = 5
			chain = 0
		else:
			return  # Too far off
		
		# Apply 50% bonus only for touch hits (touch devices don't have multiple buttons)
		var final_score = base_score
		if input_method == InputMethod.TOUCH:
			final_score = int(base_score * 1.5)  # 50% bonus for touch
		
		# Check for proximity bonus for touch/mouse hits (50% extra if close to ring center)
		# Always check proximity to update ring color, but only apply bonus for touch/mouse
		var proximity_bonus = check_proximity_bonus(ring, screen_position)
		if (input_method == InputMethod.TOUCH or input_method == InputMethod.MOUSE) and proximity_bonus:
			final_score = int(final_score * 1.5)  # Additional 50% bonus for close hits
		
		score += final_score
		
		# Check position accuracy - use world coordinates for bunny position OR 2D proximity bonus
		var bunny_pos = Vector2(bunny_actor.position.x, bunny_actor.position.z)
		var ring_world_pos = ring.get("world_position", Vector2.ZERO)
		var distance = bunny_pos.distance_to(ring_world_pos)
		
		# DEBUG: Print hit detection details
		# Accept hit if: bunny is within 3D collision area OR proximity bonus was achieved (3D inner ring hit)
		var hit_accepted = (distance < 1.5) or proximity_bonus  # Within ring collision area OR close 3D hit
		
		if hit_accepted:
			judgement_stats[judgement] += 1
			ring["cleared"] = true
			
			# Button hit feedback like original: self.btn_viewer.button_hit()
			if button_viewer:
				button_viewer.button_hit()
			
			# Determine if this should be treated as type-specific (touch OR proximity bonus)
			var is_type_specific = (input_method == InputMethod.TOUCH) or proximity_bonus
			ring_hit.emit(judgement, chain, ring["button"], is_type_specific)
			
			# Remove ring and debug circle
			ring["node"].queue_free()
			if ring.has("debug_circle") and ring["debug_circle"]:
				ring["debug_circle"].queue_free()
			ring_list.pop_front()
		else:
			print("❌ HIT REJECTED - Neither 3D collision nor 2D proximity achieved")

func check_proximity_bonus(ring: Dictionary, click_screen_position: Vector2 = Vector2.ZERO) -> bool:
	"""Check if bunny position is within inner ring using EXACT same logic as main ring"""
	print("🎯 INNER RING BONUS CHECK:")
	if click_screen_position != Vector2.ZERO:
		print("  Click screen position: ", click_screen_position)
	
	if not bunny_actor:
		print("  ❌ No bunny found")
		return false
	
	# Use EXACT same logic as main ring detection, but with smaller radius
	# Check position accuracy - use world coordinates for both (COPIED FROM MAIN RING LOGIC)
	var bunny_pos = Vector2(bunny_actor.position.x, bunny_actor.position.z)
	var ring_world_pos = ring.get("world_position", Vector2.ZERO)
	var distance = bunny_pos.distance_to(ring_world_pos)
	
	# Inner ring radius - 40% of main ring for challenging gameplay
	# Main ring uses: distance < 1.5 (ring outer radius is 1.3, collision is 1.5)
	var inner_ring_radius = 1.5 * 0.4  # 40% of main ring collision radius = 0.6
	
	# Use EXACT same collision check as main ring
	var is_within_inner_ring = distance < inner_ring_radius
	
	# Update the inner ring color based on proximity
	update_inner_ring_color(ring, is_within_inner_ring)
	
	
	return is_within_inner_ring

func update_inner_ring_color(ring: Dictionary, is_within_proximity: bool):
	"""Update the inner ring color to match main ring color with 40% transparency"""
	var debug_circle = ring.get("debug_circle")
	if not debug_circle:
		return
	
	# Get the button type to match the main ring color
	var button_type = ring.get("button", "")
	
	# Get the same color as the main ring from ModelLoader
	var main_ring_material = ModelLoader.create_ring_material(button_type)
	var main_ring_color = main_ring_material.albedo_color
	
	# Create new material with same color but 40% transparency (0.4 alpha)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(main_ring_color.r, main_ring_color.g, main_ring_color.b, 0.4)
	
	# Set up proper transparency and depth testing like main rings
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.flags_unshaded = true
	
	# Enable proper depth testing so it occludes correctly with bunny and other objects
	material.no_depth_test = false
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	material.depth_test_enabled = true
	
	# Remove depth offset - let natural z-depth handle occlusion like main rings
	material.depth_offset_enabled = false
	material.depth_offset_bias = 0.0
	
	debug_circle.material_override = material


func get_ring_color(button_type: String) -> Color:
	"""Get the color for a ring type"""
	match button_type:
		"A": 
			return Color(0.3, 0.5, 1.0, 1.0)  # Bright blue
		"B": 
			return Color(1.0, 0.2, 1.0, 1.0)  # Bright magenta (swapped from C)
		"C": 
			return Color(1.0, 0.2, 0.2, 1.0)  # Bright red (swapped from B)
		"D": 
			return Color(1.0, 1.0, 0.2, 1.0)  # Bright yellow
		_:
			return Color(1.0, 1.0, 1.0, 1.0)  # White default

func set_input_method(method: InputMethod, bypass_lock: bool = false):
	"""Set the current input method and disable others if needed"""
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Check if switching between keyboard and mouse (same controller group)
	var is_keyboard_mouse_switch = (
		(current_input_method == InputMethod.KEYBOARD and method == InputMethod.MOUSE) or
		(current_input_method == InputMethod.MOUSE and method == InputMethod.KEYBOARD)
	)
	
	# Prevent rapid switching within lock duration (unless bypassing or switching within keyboard/mouse group)
	if not bypass_lock and not is_keyboard_mouse_switch and current_time - input_method_lock_timer < INPUT_METHOD_LOCK_DURATION:
		return
	
	if current_input_method != method:
		current_input_method = method
		
		# Only set lock timer if not bypassing and not switching within keyboard/mouse group
		if not bypass_lock and not is_keyboard_mouse_switch:
			input_method_lock_timer = current_time
		
		# Disable conflicting input methods
		match method:
			InputMethod.KEYBOARD:
				using_pointer_input = false
			InputMethod.MOUSE:
				using_pointer_input = true
			InputMethod.GAMEPAD:
				using_pointer_input = false
			InputMethod.TOUCH:
				using_pointer_input = true
		

func end_level():
	"""End the level and return to menu like original"""
	is_playing = false
	
	# Restore mouse cursor when leaving level
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Stop music like original
	if audio_player:
		audio_player.stop()
	
	# Count all remaining rings as misses when level ends early
	var remaining_rings = ring_list.size()
	if remaining_rings > 0:
		judgement_stats["MISS"] += remaining_rings
		
		# Clean up remaining ring nodes and debug circles
		for ring in ring_list:
			if ring["node"] and is_instance_valid(ring["node"]):
				ring["node"].queue_free()
			if ring.has("debug_circle") and ring["debug_circle"] and is_instance_valid(ring["debug_circle"]):
				ring["debug_circle"].queue_free()
		ring_list.clear()
	
	# Clean up GUI elements
	cleanup_gui()
	
	
	# Calculate rank for high score tracking
	var rank = calculate_rank()
	
	# Update high score if this is a new record
	var is_new_high_score = HighScoreManager.update_high_score(level_name, score, rank)
	
	if is_new_high_score:
		pass # High score updated in HighScoreManager
	
	# Create result data structure like original ResultScreen expects
	var result_data = {
		"stats": judgement_stats,
		"score": score,
		"n_rings": n_rings,
		"rank": rank,
		"is_new_high_score": is_new_high_score
	}
	
	# Emit level finished like original
	level_finished.emit(result_data)

func calculate_rank() -> String:
	"""Calculate rank based on performance like original MoonBunny"""
	if n_rings == 0:
		return "F"
	
	# Calculate rates like original
	var rates = {}
	for key in ["PERFECT", "GOOD", "OK", "BAD", "MISS"]:
		rates[key] = float(judgement_stats.get(key, 0)) / float(n_rings)
	
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

func enable_ear_test_mode():
	"""Enable test mode for ear animations"""
	var ear_controller = bunny_actor.get_meta("ear_controller", null) if bunny_actor else null
	if ear_controller and ear_controller.has_method("enable_test_mode"):
		ear_controller.enable_test_mode()
