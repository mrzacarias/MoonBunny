extends Node

# Performance management for HTML export optimization
# Dynamically adjusts quality settings based on frame rate

signal quality_changed(new_quality: String)

enum QualityLevel {
	HIGH,
	MEDIUM,
	LOW
}

var current_quality: QualityLevel = QualityLevel.HIGH
var frame_time_samples: Array[float] = []
var sample_count: int = 60  # Monitor 60 frames
var target_fps: float = 60.0
var low_fps_threshold: float = 45.0
var high_fps_threshold: float = 55.0

# Performance monitoring
var check_interval: float = 2.0  # Check every 2 seconds
var last_check_time: float = 0.0

func _ready():
	# Start with medium quality for web to be safe
	if OS.get_name() == "Web":
		set_quality_level(QualityLevel.MEDIUM)
	else:
		set_quality_level(QualityLevel.HIGH)

func _process(delta):
	# Collect frame time samples
	frame_time_samples.append(delta)
	if frame_time_samples.size() > sample_count:
		frame_time_samples.pop_front()
	
	# Check performance periodically
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_check_time >= check_interval:
		check_performance()
		last_check_time = current_time

func check_performance():
	if frame_time_samples.size() < sample_count:
		return
	
	# Calculate average FPS
	var avg_frame_time = 0.0
	for sample in frame_time_samples:
		avg_frame_time += sample
	avg_frame_time /= frame_time_samples.size()
	
	var avg_fps = 1.0 / avg_frame_time if avg_frame_time > 0 else 60.0
	
	# Adjust quality based on performance
	match current_quality:
		QualityLevel.HIGH:
			if avg_fps < low_fps_threshold:
				set_quality_level(QualityLevel.MEDIUM)
		QualityLevel.MEDIUM:
			if avg_fps < low_fps_threshold:
				set_quality_level(QualityLevel.LOW)
			elif avg_fps > high_fps_threshold:
				set_quality_level(QualityLevel.HIGH)
		QualityLevel.LOW:
			if avg_fps > high_fps_threshold:
				set_quality_level(QualityLevel.MEDIUM)

func set_quality_level(level: QualityLevel):
	if current_quality == level:
		return
	
	current_quality = level
	apply_quality_settings()
	
	var quality_name = ""
	match level:
		QualityLevel.HIGH: quality_name = "HIGH"
		QualityLevel.MEDIUM: quality_name = "MEDIUM"
		QualityLevel.LOW: quality_name = "LOW"
	
	print("Performance: Quality set to ", quality_name)
	quality_changed.emit(quality_name)

func apply_quality_settings():
	var viewport = get_viewport()
	if not viewport:
		return
	
	match current_quality:
		QualityLevel.HIGH:
			# High quality settings
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			set_terrain_quality(1.0)
			set_particle_quality(1.0)
		
		QualityLevel.MEDIUM:
			# Medium quality settings
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			set_terrain_quality(0.8)
			set_particle_quality(0.7)
		
		QualityLevel.LOW:
			# Low quality settings
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			set_terrain_quality(0.6)
			set_particle_quality(0.5)

func set_terrain_quality(quality_factor: float):
	# Reduce terrain patch count and detail based on quality
	var level_node = get_tree().get_first_node_in_group("level")
	if level_node and level_node.has_method("set_terrain_quality"):
		level_node.set_terrain_quality(quality_factor)

func set_particle_quality(quality_factor: float):
	# Reduce particle effects based on quality
	var particle_nodes = get_tree().get_nodes_in_group("particles")
	for particle_node in particle_nodes:
		if particle_node.has_method("set_quality_factor"):
			particle_node.set_quality_factor(quality_factor)

func get_current_quality() -> QualityLevel:
	return current_quality

func force_quality_level(level: QualityLevel):
	"""Force a specific quality level (useful for user settings)"""
	set_quality_level(level)

# Web-specific optimizations
func optimize_for_web():
	if OS.get_name() == "Web":
		# Reduce thread pool sizes
		var config = Engine.get_singleton("ProjectSettings")
		if config:
			# These would need to be set before export, but we can optimize runtime behavior
			pass
		
		# Start with conservative settings
		set_quality_level(QualityLevel.MEDIUM)
