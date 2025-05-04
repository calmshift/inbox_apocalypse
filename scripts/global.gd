extends Node

# Game state
var current_level = "res://resources/levels/level_1.tres"  # Path to the current level resource
var current_level_index = 0
var level_paths = [
	"res://resources/levels/level_1.tres",
	"res://resources/levels/level_2.tres",
	"res://resources/levels/level_3.tres",
	"res://resources/levels/level_4.tres",
	"res://resources/levels/level_5.tres"
]
var unlocked_levels = [true, false, false, false, false]  # First level is unlocked by default
var player_score = 0
var high_scores = [0, 0, 0, 0, 0]  # High score for each level
var max_combo_achieved = 0
var total_emails_cleared = 0
var total_deaths = 0
var total_play_time = 0.0
var current_session_time = 0.0
var achievements_unlocked = {
	"first_day": false,
	"combo_master": false,
	"inbox_zero": false,
	"power_user": false,
	"boss_slayer": false
}

# Game settings
var music_volume = 0.5
var sfx_volume = 0.7
var show_hitbox = false
var tutorial_completed = false
var screen_shake_enabled = true
var particles_enabled = true
var difficulty_modifier = 1.0  # 0.75 = easier, 1.5 = harder

# Save game data
func save_game():
	var save_data = {
		"high_scores": high_scores,
		"unlocked_levels": unlocked_levels,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"tutorial_completed": tutorial_completed,
		"max_combo_achieved": max_combo_achieved,
		"total_emails_cleared": total_emails_cleared,
		"total_deaths": total_deaths,
		"total_play_time": total_play_time,
		"achievements_unlocked": achievements_unlocked,
		"screen_shake_enabled": screen_shake_enabled,
		"particles_enabled": particles_enabled,
		"difficulty_modifier": difficulty_modifier,
		"show_hitbox": show_hitbox
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
			if data.has("high_scores"):
				high_scores = data["high_scores"]
			if data.has("unlocked_levels"):
				unlocked_levels = data["unlocked_levels"]
			if data.has("music_volume"):
				music_volume = data["music_volume"]
			if data.has("sfx_volume"):
				sfx_volume = data["sfx_volume"]
			if data.has("tutorial_completed"):
				tutorial_completed = data["tutorial_completed"]
			if data.has("max_combo_achieved"):
				max_combo_achieved = data["max_combo_achieved"]
			if data.has("total_emails_cleared"):
				total_emails_cleared = data["total_emails_cleared"]
			if data.has("total_deaths"):
				total_deaths = data["total_deaths"]
			if data.has("total_play_time"):
				total_play_time = data["total_play_time"]
			if data.has("achievements_unlocked"):
				achievements_unlocked = data["achievements_unlocked"]
			if data.has("screen_shake_enabled"):
				screen_shake_enabled = data["screen_shake_enabled"]
			if data.has("particles_enabled"):
				particles_enabled = data["particles_enabled"]
			if data.has("difficulty_modifier"):
				difficulty_modifier = data["difficulty_modifier"]
			if data.has("show_hitbox"):
				show_hitbox = data["show_hitbox"]

# Reset game state for a new game
func new_game():
	current_level_index = 0
	current_level = level_paths[current_level_index]
	player_score = 0

# Update high score if needed
func update_high_score(level_index, score):
	if level_index >= 0 and level_index < high_scores.size():
		if score > high_scores[level_index]:
			high_scores[level_index] = score
			save_game()
			return true
	return false

# Level completed, move to next level
func level_completed(score = 0, combo = 0, emails_cleared = 0):
	# Update statistics
	if score > 0:
		update_high_score(current_level_index, score)
	
	if combo > max_combo_achieved:
		max_combo_achieved = combo
	
	total_emails_cleared += emails_cleared
	
	# Unlock next level
	if current_level_index < level_paths.size() - 1:
		unlock_level(current_level_index + 1)
		current_level_index += 1
		current_level = level_paths[current_level_index]
		save_game()
		return true
	return false

# Check for achievements
func check_achievements():
	# First day completed
	if not achievements_unlocked["first_day"] and unlocked_levels[1]:
		achievements_unlocked["first_day"] = true
		return "first_day"
	
	# Combo master (20+ combo)
	if not achievements_unlocked["combo_master"] and max_combo_achieved >= 20:
		achievements_unlocked["combo_master"] = true
		return "combo_master"
	
	# Inbox zero (clear all levels)
	if not achievements_unlocked["inbox_zero"] and unlocked_levels[level_paths.size() - 1]:
		achievements_unlocked["inbox_zero"] = true
		return "inbox_zero"
	
	# Power user (clear 100 emails)
	if not achievements_unlocked["power_user"] and total_emails_cleared >= 100:
		achievements_unlocked["power_user"] = true
		return "power_user"
	
	# Boss slayer (defeat final boss)
	if not achievements_unlocked["boss_slayer"] and current_level_index == level_paths.size() - 1:
		var level = load(level_paths[current_level_index])
		if level and level.boss_level and high_scores[current_level_index] > 0:
			achievements_unlocked["boss_slayer"] = true
			return "boss_slayer"
	
	return ""

# Set current level by index
func set_level(index):
	if index >= 0 and index < level_paths.size() and unlocked_levels[index]:
		current_level_index = index
		current_level = level_paths[current_level_index]
		return true
	return false

# Unlock a level
func unlock_level(index):
	if index >= 0 and index < unlocked_levels.size():
		unlocked_levels[index] = true
		save_game()
		return true
	return false

# Check if a level is unlocked
func is_level_unlocked(index):
	if index >= 0 and index < unlocked_levels.size():
		return unlocked_levels[index]
	return false

# Get level name
func get_level_name(index):
	if index >= 0 and index < level_paths.size():
		var level = load(level_paths[index])
		if level:
			return level.level_name
	return "Unknown Level"

# Get level description
func get_level_description(index):
	if index >= 0 and index < level_paths.size():
		var level = load(level_paths[index])
		if level:
			return level.level_description
	return "No description available"

# Get level difficulty
func get_level_difficulty(index):
	if index >= 0 and index < level_paths.size():
		var level = load(level_paths[index])
		if level:
			return level.difficulty
	return 1

# Mark tutorial as completed
func complete_tutorial():
	tutorial_completed = true
	save_game()