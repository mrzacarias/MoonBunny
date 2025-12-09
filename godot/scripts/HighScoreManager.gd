extends Node

# HighScoreManager - Handles high score persistence across platforms
# Supports both file-based storage (desktop) and browser localStorage (HTML)

# High score data structure: { "level_name": { "score": int, "rank": String } }
var high_scores: Dictionary = {}

# File path for desktop storage
const SAVE_FILE_PATH = "user://highscores.save"

func _ready():
	load_high_scores()

func load_high_scores():
	"""Load high scores from appropriate storage based on platform"""
	high_scores.clear()
	
	if OS.get_name() == "Web":
		load_from_browser_storage()
	else:
		load_from_file()
	
	

func save_high_scores():
	"""Save high scores to appropriate storage based on platform"""
	if OS.get_name() == "Web":
		save_to_browser_storage()
	else:
		save_to_file()
	

func load_from_file():
	"""Load high scores from file (desktop platforms)"""
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				high_scores = json.data
				pass # Successfully loaded
			else:
				print("ERROR: Failed to parse JSON from high scores file")
		else:
			print("ERROR: Failed to open high scores file for reading")

func save_to_file():
	"""Save high scores to file (desktop platforms)"""
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(high_scores)
		file.store_string(json_string)
		file.close()
		pass # Successfully saved
	else:
		print("ERROR: Failed to open high scores file for writing")

func load_from_browser_storage():
	"""Load high scores from browser localStorage (HTML platform)"""
	# Use JavaScriptBridge to access localStorage
	if JavaScriptBridge.eval("typeof(Storage) !== 'undefined'", true):
		var stored_data = JavaScriptBridge.eval("localStorage.getItem('moonbunny_highscores')", true)
		if stored_data and stored_data != "null":
			var json = JSON.new()
			var parse_result = json.parse(stored_data)
			if parse_result == OK:
				high_scores = json.data
				pass # Successfully loaded from localStorage
			else:
				print("ERROR: Failed to parse JSON from localStorage")
	else:
		print("ERROR: localStorage not available in browser")

func save_to_browser_storage():
	"""Save high scores to browser localStorage (HTML platform)"""
	if JavaScriptBridge.eval("typeof(Storage) !== 'undefined'", true):
		var json_string = JSON.stringify(high_scores)
		# Escape quotes for JavaScript
		var escaped_json = json_string.replace("'", "\\'")
		var js_code = "localStorage.setItem('moonbunny_highscores', '" + escaped_json + "')"
		JavaScriptBridge.eval(js_code, true)
		pass # Successfully saved to localStorage
	else:
		print("ERROR: localStorage not available for saving high scores")

func update_high_score(level_name: String, score: int, rank: String) -> bool:
	"""Update high score for a level if it's better than the current one
	Returns true if this is a new high score, false otherwise"""
	
	
	var current_high_score = get_high_score(level_name)
	var is_new_high_score = false
	
	if current_high_score == null or current_high_score.is_empty() or score > current_high_score["score"]:
		high_scores[level_name] = {
			"score": score,
			"rank": rank
		}
		is_new_high_score = true
		save_high_scores()
	else:
		pass # Current high score not beaten
	
	return is_new_high_score

func get_high_score(level_name: String) -> Dictionary:
	"""Get high score data for a level, returns null if no high score exists"""
	return high_scores.get(level_name, {})

func has_high_score(level_name: String) -> bool:
	"""Check if a level has a high score"""
	return level_name in high_scores and high_scores[level_name].has("score")

func get_high_score_text(level_name: String) -> String:
	"""Get formatted high score text for display in level select"""
	if has_high_score(level_name):
		var score_data = get_high_score(level_name)
		return "Hiscore " + str(score_data["score"]) + " - Rank " + score_data["rank"]
	else:
		return ""

func clear_all_high_scores():
	"""Clear all high scores (for testing/reset purposes)"""
	high_scores.clear()
	save_high_scores()
