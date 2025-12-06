extends Node3D

# Simple texture debugger utility
# This appears to be a development/debugging tool

func _ready():
	print("TextureDebugger ready")
	# This is likely a development tool, so we'll keep it minimal
	
func _input(event):
	# Add any debugging input handling here if needed
	pass

# Add any texture debugging functionality here as needed
func debug_texture(texture: Texture2D):
	if texture:
		print("Texture info: ", texture.get_size())
	else:
		print("No texture provided")
