extends Node3D

# Particle effects for MoonBunny - based on original particle.py

class_name ParticleEffects

# Ring hit particle effect (like original BunnyParticles)
class RingHitParticles extends GPUParticles3D:
	func _init():
		setup_ring_particles()
		
	func setup_ring_particles():
		"""Setup ring hit particles like original BunnyParticles"""
		# Basic particle setup
		emitting = false
		amount = 50
		lifetime = 3.0
		visibility_aabb = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
		
		# Create process material
		var material = ParticleProcessMaterial.new()
		
		# Emission settings (like original)
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 0.1
		
		# Velocity settings (like original radiate pattern)
		material.direction = Vector3(0, 1, 0)
		material.initial_velocity_min = 2.0
		material.initial_velocity_max = 5.0
		material.angular_velocity_min = -180.0
		material.angular_velocity_max = 180.0
		
		# Gravity (like original LinearVectorForce)
		material.gravity = Vector3(0, -3.0, 0)
		
		# Scale animation (like original InitialXScale/FinalXScale)
		material.scale_min = 0.03
		material.scale_max = 0.1
		
		# Color (like original blue particles)
		material.color = Color(0.4, 0.4, 1.0, 0.8)
		
		process_material = material
		
		# Create particle texture
		create_particle_texture()
		
	func create_particle_texture():
		"""Create particle texture (fallback if star_particle.png not found)"""
		var star_path = "res://assets/textures/star_particle.png"
		if ResourceLoader.exists(star_path):
			# Create quad mesh with texture for particles
			var quad_mesh = QuadMesh.new()
			quad_mesh.size = Vector2(0.1, 0.1)
			
			var material = StandardMaterial3D.new()
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
			material.albedo_texture = load(star_path)
			material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			draw_pass_1 = quad_mesh
			material_override = material
		else:
			# Create simple star texture fallback
			var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			# Simple star pattern
			for y in range(16):
				for x in range(16):
					var center_x = 8
					var center_y = 8
					var dist = sqrt((x - center_x) * (x - center_x) + (y - center_y) * (y - center_y))
					if dist < 6:
						var alpha = 1.0 - (dist / 6.0)
						image.set_pixel(x, y, Color(1, 1, 1, alpha))
			
			var texture_resource = ImageTexture.new()
			texture_resource.set_image(image)
			
			# Create quad mesh with fallback texture
			var quad_mesh = QuadMesh.new()
			quad_mesh.size = Vector2(0.1, 0.1)
			
			var material = StandardMaterial3D.new()
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
			material.albedo_texture = texture_resource
			material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			draw_pass_1 = quad_mesh
			material_override = material
			
	func play_hit_effect(position: Vector3, judgement: String):
		"""Play particle effect at ring hit position"""
		global_position = position
		
		# Adjust particle count based on judgement quality
		match judgement:
			"PERFECT":
				amount = 100
				(process_material as ParticleProcessMaterial).color = Color(1.0, 0.8, 0.0, 0.9)  # Gold
			"GOOD":
				amount = 75
				(process_material as ParticleProcessMaterial).color = Color(0.0, 1.0, 0.0, 0.8)  # Green
			"OK":
				amount = 50
				(process_material as ParticleProcessMaterial).color = Color(1.0, 1.0, 0.0, 0.7)  # Yellow
			"BAD":
				amount = 25
				(process_material as ParticleProcessMaterial).color = Color(1.0, 0.5, 0.0, 0.6)  # Orange
			_:
				amount = 10
				(process_material as ParticleProcessMaterial).color = Color(0.5, 0.5, 0.5, 0.5)  # Gray
		
		# Start emission
		restart()
		emitting = true
		
		# Auto-stop after a short burst
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func(): emitting = false)

# Miss effect particles (like original miss particles)
class MissParticles extends GPUParticles3D:
	func _init():
		setup_miss_particles()
		
	func setup_miss_particles():
		"""Setup miss particles - darker, falling effect"""
		emitting = false
		amount = 30
		lifetime = 2.0
		visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
		
		var material = ParticleProcessMaterial.new()
		
		# Emission
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 0.2
		
		# Downward velocity for "miss" feeling
		material.direction = Vector3(0, -1, 0)
		material.initial_velocity_min = 1.0
		material.initial_velocity_max = 3.0
		
		# Strong gravity
		material.gravity = Vector3(0, -9.8, 0)
		
		# Dark red/gray color
		material.color = Color(0.6, 0.2, 0.2, 0.7)
		
		# Smaller scale
		material.scale_min = 0.02
		material.scale_max = 0.05
		
		process_material = material
		
		# Use same mesh setup as hit particles
		var star_path = "res://assets/textures/star_particle.png"
		if ResourceLoader.exists(star_path):
			var quad_mesh = QuadMesh.new()
			quad_mesh.size = Vector2(0.05, 0.05)  # Smaller for miss effect
			
			var mesh_material = StandardMaterial3D.new()
			mesh_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
			mesh_material.albedo_texture = load(star_path)
			mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			draw_pass_1 = quad_mesh
			material_override = mesh_material
			
	func play_miss_effect(position: Vector3):
		"""Play miss effect at position"""
		global_position = position
		restart()
		emitting = true
		
		# Auto-stop
		var timer = get_tree().create_timer(0.3)
		timer.timeout.connect(func(): emitting = false)

# Particle manager for the level
class ParticleManager extends Node3D:
	var hit_particle_pool: Array[RingHitParticles] = []
	var miss_particle_pool: Array[MissParticles] = []
	var pool_size = 10
	
	func _ready():
		setup_particle_pools()
		
	func setup_particle_pools():
		"""Create particle pools for performance"""
		# Create hit particle pool
		for i in range(pool_size):
			var hit_particles = RingHitParticles.new()
			hit_particles.name = "HitParticles_%d" % i
			add_child(hit_particles)
			hit_particle_pool.append(hit_particles)
			
		# Create miss particle pool
		for i in range(pool_size):
			var miss_particles = MissParticles.new()
			miss_particles.name = "MissParticles_%d" % i
			add_child(miss_particles)
			miss_particle_pool.append(miss_particles)
			
		print("🎆 ParticleManager: Created pools with ", pool_size, " hit and ", pool_size, " miss particle systems")
		
	func play_hit_effect(position: Vector3, judgement: String):
		"""Play hit effect using pooled particles"""
		var particles = get_available_hit_particles()
		if particles:
			particles.play_hit_effect(position, judgement)
			
	func play_miss_effect(position: Vector3):
		"""Play miss effect using pooled particles"""
		var particles = get_available_miss_particles()
		if particles:
			particles.play_miss_effect(position)
			
	func get_available_hit_particles() -> RingHitParticles:
		"""Get available hit particles from pool"""
		for particles in hit_particle_pool:
			if not particles.emitting:
				return particles
		return hit_particle_pool[0]  # Fallback to first if all busy
		
	func get_available_miss_particles() -> MissParticles:
		"""Get available miss particles from pool"""
		for particles in miss_particle_pool:
			if not particles.emitting:
				return particles
		return miss_particle_pool[0]  # Fallback to first if all busy
