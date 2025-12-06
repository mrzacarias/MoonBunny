# Global Audio Configuration for MoonBunny
# Centralized volume settings for all audio in the game
# Static utility class - access via AudioManager.function_name()

class_name AudioManager

# Volume settings (in dB)
# 0 dB = 100% volume, -3.1 dB ≈ 70% volume, -6 dB ≈ 50% volume
const MASTER_VOLUME_DB: float = -3.1  # 70% volume for all audio
const MUSIC_VOLUME_DB: float = MASTER_VOLUME_DB
const SFX_VOLUME_DB: float = MASTER_VOLUME_DB
const MENU_SOUND_VOLUME_DB: float = MASTER_VOLUME_DB

# Convenience function to apply standard volume to any AudioStreamPlayer
static func apply_standard_volume(audio_player: AudioStreamPlayer, audio_type: String = "default"):
	"""Apply standard volume settings to an AudioStreamPlayer"""
	if not audio_player:
		return
	
	match audio_type.to_lower():
		"music", "level_music":
			audio_player.volume_db = MUSIC_VOLUME_DB
		"sfx", "sound_effect", "miss", "start":
			audio_player.volume_db = SFX_VOLUME_DB
		"menu", "menu_sound":
			audio_player.volume_db = MENU_SOUND_VOLUME_DB
		_:
			audio_player.volume_db = MASTER_VOLUME_DB

# Get volume for specific audio type
static func get_volume_db(audio_type: String = "default") -> float:
	"""Get the volume in dB for a specific audio type"""
	match audio_type.to_lower():
		"music", "level_music":
			return MUSIC_VOLUME_DB
		"sfx", "sound_effect", "miss", "start":
			return SFX_VOLUME_DB
		"menu", "menu_sound":
			return MENU_SOUND_VOLUME_DB
		_:
			return MASTER_VOLUME_DB

# Debug function to print current volume settings
static func print_volume_settings():
	"""Print current volume settings for debugging"""
	print("AudioManager Volume Settings:")
	print("  Master: ", MASTER_VOLUME_DB, " dB")
	print("  Music: ", MUSIC_VOLUME_DB, " dB")
	print("  SFX: ", SFX_VOLUME_DB, " dB")
	print("  Menu: ", MENU_SOUND_VOLUME_DB, " dB")
