extends RefCounted
class_name ModelLoader

# Enhanced model loader that applies proper materials to .obj models
# This compensates for the texture loss during .egg to .obj conversion

static func load_model_with_materials(model_path: String, texture_path: String = "") -> Node3D:
	"""Load a GLB model with embedded materials and animations"""
	
	# Ensure .glb extension
	var glb_path = model_path
	if not glb_path.ends_with(".glb"):
		glb_path = model_path.get_basename() + ".glb"
	
	if ResourceLoader.exists(glb_path):
		var glb_scene = load(glb_path)
		if glb_scene and glb_scene is PackedScene:
			var scene_instance = glb_scene.instantiate()
			
			# Check for animations and skeleton
			var animation_player = find_animation_player(scene_instance)
			var skeleton = find_skeleton(scene_instance)
			
			if animation_player:
				pass # Animation player found and logged
			
			if skeleton:
				pass # Skeleton found and logged
				
			# Return the entire scene to preserve animations and skeleton
			return scene_instance
	
	return null

static func find_animation_player(node: Node) -> AnimationPlayer:
	"""Recursively find the first AnimationPlayer in a scene tree"""
	if node is AnimationPlayer:
		return node as AnimationPlayer
	
	for child in node.get_children():
		var result = find_animation_player(child)
		if result:
			return result
	
	return null

static func find_skeleton(node: Node) -> Skeleton3D:
	"""Recursively find the first Skeleton3D in a scene tree"""
	if node is Skeleton3D:
		return node as Skeleton3D
	
	for child in node.get_children():
		var result = find_skeleton(child)
		if result:
			return result
	
	return null

static func find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Recursively find the first MeshInstance3D in a scene tree"""
	if node is MeshInstance3D:
		return node as MeshInstance3D
	
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	
	return null

static func create_material_with_texture(texture_path: String) -> StandardMaterial3D:
	"""Create a StandardMaterial3D with the specified texture"""
	var material = StandardMaterial3D.new()
	
	# Platform-specific brightness adjustment
	var brightness_multiplier = 1.0
	if OS.get_name() == "Web":
		brightness_multiplier = 0.7  # 30% darker for HTML
	
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		if texture:
			material.albedo_texture = texture
			material.albedo_color = Color(1.0, 1.0, 1.0, 1.0) * brightness_multiplier  # Adjusted for web
		else:
			material.albedo_color = Color(0.8, 0.8, 0.8, 1.0) * brightness_multiplier  # Fallback gray
	else:
		material.albedo_color = Color(0.8, 0.8, 0.8, 1.0) * brightness_multiplier  # Fallback gray
	
	# Set good default material properties for Godot 4.x
	material.roughness = 1.0  # Maximum roughness to eliminate reflections
	material.metallic = 0.0   # No metallic properties
	# Note: 'specular' property was removed in Godot 4.x, now controlled by roughness and metallic
	material.flags_transparent = false
	material.flags_albedo_tex_force_srgb = true
	# Additional settings to reduce reflections
	# Note: specular property removed in Godot 4.x - controlled by roughness and metallic
	# Use normal albedo color without web-specific adjustments
	# material.albedo_color = material.albedo_color * 1.1  # Removed web-specific brightness
	
	return material

static func create_bunny_material() -> StandardMaterial3D:
	"""Create the bunny material with proper texture"""
	var bunny_texture_path = "res://assets/models/bunnyboy.tga"
	return create_material_with_texture(bunny_texture_path)

static func create_ring_material(button: String) -> StandardMaterial3D:
	"""Create ring material with proper colors and effects"""
	var material = StandardMaterial3D.new()
	
	# Platform-specific brightness adjustment
	var brightness_multiplier = 1.0
	if OS.get_name() == "Web":
		brightness_multiplier = 0.42  # 58% darker for HTML (0.6 * 0.7 = 0.42 for additional 30% reduction)
	
	# Additional 30% darkness for HTML (separate from emission brightness)
	var albedo_multiplier = 1.0
	if OS.get_name() == "Web":
		albedo_multiplier = 0.7  # 30% darker albedo for HTML
	
	match button:
		"A": 
			material.albedo_color = Color(0.4, 0.3, 0.8, 1.0) * albedo_multiplier  # Purple/Blue
			material.emission = Color(0.2, 0.15, 0.4, 1.0) * brightness_multiplier
		"B": 
			material.albedo_color = Color(0.6, 0.2, 0.2, 1.0) * albedo_multiplier  # Dark Red/Maroon
			material.emission = Color(0.3, 0.1, 0.1, 1.0) * brightness_multiplier
		"C": 
			material.albedo_color = Color(0.8, 0.3, 0.8, 1.0) * albedo_multiplier  # Purple/Magenta
			material.emission = Color(0.4, 0.15, 0.4, 1.0) * brightness_multiplier
		"D": 
			# D ring gets additional 30% darkness on top of HTML darkness (0.7 * 0.7 = 0.49)
			var d_multiplier = albedo_multiplier * 0.7  # Extra 30% darker for D ring
			material.albedo_color = Color(0.3, 0.8, 0.3, 1.0) * d_multiplier  # Green extra dark
			material.emission = Color(0.15, 0.4, 0.15, 1.0) * brightness_multiplier * 0.7  # Emission also extra dark
		_:
			material.albedo_color = Color(1.0, 1.0, 1.0, 1.0) * albedo_multiplier  # White default
			material.emission = Color(0.3, 0.3, 0.3, 1.0) * brightness_multiplier
	
	material.emission_enabled = true
	material.roughness = 0.1
	material.metallic = 0.8
	# Note: specular property was removed in Godot 4.x
	material.flags_transparent = false
	
	return material

static func create_skybox_material() -> StandardMaterial3D:
	"""Create skybox material with proper texture"""
	var material = StandardMaterial3D.new()
	
	# Skybox material settings for Godot 4 - optimized for brightness
	material.cull_mode = BaseMaterial3D.CULL_FRONT  # Render inside
	material.flags_unshaded = true  # This is key - unshaded means no lighting affects it
	material.flags_do_not_receive_shadows = true
	material.flags_disable_ambient_light = true  # This is correct for skybox
	material.no_depth_test = true
	material.vertex_color_use_as_albedo = false
	material.flags_albedo_tex_force_srgb = true  # Force sRGB for proper color space in web
	
	# Try the better skybox texture first
	var sky_texture_paths = [
		"res://assets/models/skybox_sky.jpg",
		"res://assets/models/sky.jpg"
	]
	
	var texture_loaded = false
	for sky_texture_path in sky_texture_paths:
		if ResourceLoader.exists(sky_texture_path):
			var sky_texture = load(sky_texture_path)
			if sky_texture and sky_texture is Texture2D:
				material.albedo_texture = sky_texture
				material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # Pure white base
				
				# Restore emission system for consistent brightness in both editor and web
				material.emission_enabled = true
				material.emission_texture = sky_texture  # Use same texture for emission
				
				# Use same emission for all platforms to ensure consistent brightness
				material.emission = Color(2.5, 2.5, 2.5, 1.0)  # Same emission for both web and desktop
				
				# Optimize texture settings for web export brightness
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
				material.uv1_scale = Vector3(1.0, 1.0, 1.0)
				material.uv1_offset = Vector3(0.0, 0.0, 0.0)
				# Ensure proper shading for brightness
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				
				texture_loaded = true
				break
			else:
				print("ERROR: Failed to load sky texture as Texture2D: ", sky_texture_path)
		else:
			print("ERROR: Sky texture file not found: ", sky_texture_path)
	
	if not texture_loaded:
		setup_gradient_sky_material(material)
	
	return material
static func setup_gradient_sky_material(material: StandardMaterial3D):
	"""Setup gradient sky material as fallback"""
	material.albedo_color = Color(0.5, 0.7, 1.0, 1.0)  # Sky blue
	material.emission_enabled = true
	material.emission = Color(0.3, 0.5, 0.8, 1.0)  # Bright sky blue emission

static func get_terrain_texture_for_type(terrain_type: int) -> String:
	"""Get the appropriate texture path for terrain type based on original .egg analysis"""
	var terrain_textures = {
		1: "res://assets/models/wall.jpg",
		2: "res://assets/models/wall_triangle.jpg", 
		3: "res://assets/models/wall_corner.jpg",
		4: "res://assets/models/roof.jpg",
		5: "res://assets/models/grass.jpg",
		6: "res://assets/models/mountain.tga",
		7: "res://assets/models/wall.jpg",
		8: "res://assets/models/grass.jpg"
	}
	
	return terrain_textures.get(terrain_type, "res://assets/models/grass.jpg")

static func load_mesh_only(model_path: String, texture_path: String = "") -> Node3D:
	"""Load a GLB model and return the complete scene (for skybox, terrain, etc.)
	This preserves all meshes in GLB files instead of just the first one."""
	
	# Ensure .glb extension
	var glb_path = model_path
	if not glb_path.ends_with(".glb"):
		glb_path = model_path.get_basename() + ".glb"
	
	if ResourceLoader.exists(glb_path):
		var glb_scene = load(glb_path)
		if glb_scene and glb_scene is PackedScene:
			var scene_instance = glb_scene.instantiate()
			
			# Return the complete scene to preserve all meshes
			# This fixes the issue where floating mountains were being lost
			# because only the first mesh was being extracted
			return scene_instance
	
	return null
