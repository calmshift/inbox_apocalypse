extends Node

# Game state
var current_level = "res://resources/level_1.tres"  # Path to the current level resource
var max_level = 4
var player_score = 0
var high_score = 0

# Game settings
var music_volume = 0.0
var sfx_volume = 0.0

# Save game data
func save_game():
	var save_data = {
		"high_score": high_score,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save_data))

# Load game data
func load_game():
	if FileAccess.file_exists("user://savegame.save"):
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		var json_string = save_file.get_line()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			if data.has("high_score"):
				high_score = data["high_score"]
			if data.has("music_volume"):
				music_volume = data["music_volume"]
			if data.has("sfx_volume"):
				sfx_volume = data["sfx_volume"]

# Reset game state for a new game
func new_game():
	current_level = 1
	player_score = 0

# Update high score if needed
func update_high_score():
	if player_score > high_score:
		high_score = player_score
		save_game()

# Level completed, move to next level
func level_completed():
	current_level += 1
	if current_level > max_level:
		current_level = 1