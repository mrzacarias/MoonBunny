extends RefCounted
class_name ModelLoader

# Enhanced model loader that applies proper materials to .obj models
# This compensates for the texture loss during .egg to .obj conversion

static func load_model_with_materials(model_path: String, texture_path: String = "") -> Node3D:
	"""Load a model (.glb preferred, .obj fallback) and apply proper materials"""
	
	# Try .glb first (has embedded materials and animations)
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
				print("✅ Found AnimationPlayer with ", animation_player.get_animation_list().size(), " animations")
			
			if skeleton:
				print("✅ Found Skeleton3D with ", skeleton.get_bone_count(), " bones")
			
			print("Loaded GLB model: ", glb_path)
			# Return the entire scene to preserve animations and skeleton
			return scene_instance
	
	# Fallback to .obj file (if it exists)
	var obj_path = model_path.get_basename() + ".obj"
	if ResourceLoader.exists(obj_path):
		var mesh_instance = MeshInstance3D.new()
		var mesh = load(obj_path)
		if mesh and mesh is Mesh:
			mesh_instance.mesh = mesh
			print("Loaded OBJ model: ", obj_path)
			
			# Apply material with texture if provided
			if texture_path != "":
				var material = create_material_with_texture(texture_path)
				mesh_instance.material_override = material
			else:
				# Apply default material for .obj files that don't have embedded materials
				var default_material = StandardMaterial3D.new()
				default_material.albedo_color = Color(0.8, 0.8, 0.8, 1.0)
				default_material.roughness = 0.6
				default_material.metallic = 0.0
				mesh_instance.material_override = default_material
			
			return mesh_instance
	
	print("Model file not found: ", model_path, " (tried .glb and .obj)")
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
	
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		if texture:
			material.albedo_texture = texture
			material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # Full white to show texture
			print("Applied texture: ", texture_path)
		else:
			print("Failed to load texture: ", texture_path)
			material.albedo_color = Color(0.8, 0.8, 0.8, 1.0)  # Fallback gray
	else:
		print("Texture file not found: ", texture_path)
		material.albedo_color = Color(0.8, 0.8, 0.8, 1.0)  # Fallback gray
	
	# Set good default material properties for Godot 4.x
	material.roughness = 0.4
	material.metallic = 0.0
	# Note: 'specular' property was removed in Godot 4.x, now controlled by roughness and metallic
	material.flags_transparent = false
	material.flags_albedo_tex_force_srgb = true
	
	return material

static func create_bunny_material() -> StandardMaterial3D:
	"""Create the bunny material with proper texture"""
	var bunny_texture_path = "res://assets/models/bunnyboy.tga"
	return create_material_with_texture(bunny_texture_path)

static func create_ring_material(button: String) -> StandardMaterial3D:
	"""Create ring material with proper colors and effects"""
	var material = StandardMaterial3D.new()
	
	match button:
		"A": 
			material.albedo_color = Color(0.3, 0.5, 1.0, 1.0)  # Bright blue
			material.emission = Color(0.15, 0.25, 0.6, 1.0)
		"B": 
			material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)  # Bright red
			material.emission = Color(0.6, 0.1, 0.1, 1.0)
		"C": 
			material.albedo_color = Color(1.0, 0.2, 1.0, 1.0)  # Bright magenta
			material.emission = Color(0.6, 0.1, 0.6, 1.0)
		"D": 
			material.albedo_color = Color(1.0, 1.0, 0.2, 1.0)  # Bright yellow
			material.emission = Color(0.6, 0.6, 0.1, 1.0)
		_:
			material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # White default
			material.emission = Color(0.3, 0.3, 0.3, 1.0)
	
	material.emission_enabled = true
	material.roughness = 0.1
	material.metallic = 0.8
	# Note: specular property was removed in Godot 4.x
	material.flags_transparent = false
	
	return material

static func create_skybox_material() -> StandardMaterial3D:
	"""Create skybox material with proper texture"""
	var material = StandardMaterial3D.new()
	
	# Skybox material settings for Godot 4
	material.cull_mode = BaseMaterial3D.CULL_FRONT  # Render inside
	material.flags_unshaded = true
	material.flags_do_not_receive_shadows = true
	material.flags_disable_ambient_light = true
	material.no_depth_test = true
	material.vertex_color_use_as_albedo = false
	material.flags_albedo_tex_force_srgb = true
	
	# Try the better skybox texture first
	var sky_texture_paths = [
		"res://assets/models/skybox_sky.jpg",
		"res://assets/models/sky.jpg"
	]
	
	var texture_loaded = false
	for sky_texture_path in sky_texture_paths:
		print("🔍 Trying to load: ", sky_texture_path)
		if ResourceLoader.exists(sky_texture_path):
			var sky_texture = load(sky_texture_path)
			print("🔍 Loaded resource type: ", type_string(typeof(sky_texture)))
			if sky_texture and sky_texture is Texture2D:
				material.albedo_texture = sky_texture
				material.albedo_color = Color.WHITE  # Pure white to show texture clearly
				
				# Force texture settings
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
				material.uv1_scale = Vector3(1.0, 1.0, 1.0)
				material.uv1_offset = Vector3(0.0, 0.0, 0.0)
				
				print("✅ Successfully applied sky texture: ", sky_texture_path)
				print("🔍 Texture size: ", sky_texture.get_size())
				texture_loaded = true
				break
			else:
				print("❌ Failed to load sky texture as Texture2D: ", sky_texture_path)
		else:
			print("❌ Sky texture file not found: ", sky_texture_path)
	
	if not texture_loaded:
		print("⚠️ Using fallback gradient skybox")
		setup_gradient_sky_material(material)
	
	return material
static func setup_gradient_sky_material(material: StandardMaterial3D):
	"""Setup gradient sky material as fallback"""
	material.albedo_color = Color(0.5, 0.7, 1.0, 1.0)  # Sky blue
	material.emission_enabled = true
	material.emission = Color(0.3, 0.5, 0.8, 1.0)  # Bright sky blue emission
	print("Using gradient skybox material")

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

static func load_mesh_only(model_path: String, texture_path: String = "") -> MeshInstance3D:
	"""Load a model and return only the MeshInstance3D (for skybox, terrain, etc.)"""
	
	# Try .glb first
	var glb_path = model_path
	if not glb_path.ends_with(".glb"):
		glb_path = model_path.get_basename() + ".glb"
	
	if ResourceLoader.exists(glb_path):
		var glb_scene = load(glb_path)
		if glb_scene and glb_scene is PackedScene:
			var scene_instance = glb_scene.instantiate()
			var found_mesh = find_mesh_instance(scene_instance)
			
			if found_mesh:
				# Create a new mesh instance with copied data
				var new_mesh_instance = MeshInstance3D.new()
				new_mesh_instance.mesh = found_mesh.mesh
				new_mesh_instance.material_override = found_mesh.material_override
				
				# Clean up the temporary scene
				scene_instance.queue_free()
				return new_mesh_instance
	
	# Fallback to .obj file
	var obj_path = model_path.get_basename() + ".obj"
	if ResourceLoader.exists(obj_path):
		var mesh_instance = MeshInstance3D.new()
		var mesh = load(obj_path)
		if mesh and mesh is Mesh:
			mesh_instance.mesh = mesh
			print("Loaded OBJ mesh: ", obj_path)
			
			# Apply material with texture if provided
			if texture_path != "":
				var material = create_material_with_texture(texture_path)
				mesh_instance.material_override = material
			else:
				# Apply default material for .obj files that don't have embedded materials
				var default_material = StandardMaterial3D.new()
				default_material.albedo_color = Color(0.8, 0.8, 0.8, 1.0)
				default_material.roughness = 0.6
				default_material.metallic = 0.0
				mesh_instance.material_override = default_material
			
			return mesh_instance
	
	print("Model file not found: ", model_path, " (tried .glb and .obj)")
	return null
