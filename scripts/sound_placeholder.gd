extends Node

# This script creates placeholder sound files for testing

func _ready():
	create_placeholder_sounds()

func create_placeholder_sounds():
	# Create placeholder directory
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("assets/sounds/placeholder"):
		dir.make_dir_recursive("assets/sounds/placeholder")
	
	# Create placeholder sound files
	create_sound_file("gameplay.ogg")
	create_sound_file("main_menu.ogg")
	create_sound_file("boss_theme.ogg")
	create_sound_file("tutorial_theme.ogg")
	create_sound_file("level_1.ogg")
	create_sound_file("level_2.ogg")
	create_sound_file("level_3.ogg")
	create_sound_file("level_4.ogg")
	create_sound_file("level_5.ogg")
	create_sound_file("level_6.ogg")
	create_sound_file("level_7.ogg")
	create_sound_file("level_8.ogg")
	create_sound_file("level_9.ogg")
	create_sound_file("level_10.ogg")
	create_sound_file("level_11.ogg")
	create_sound_file("level_12.ogg")
	create_sound_file("level_13.ogg")
	create_sound_file("level_14.ogg")
	create_sound_file("level_15.ogg")
	create_sound_file("final_boss.ogg")
	create_sound_file("victory.ogg")
	create_sound_file("game_over_music.ogg")
	
	# Create placeholder sound effects
	create_sound_file("button_click.wav")
	create_sound_file("menu_select.wav")
	create_sound_file("menu_back.wav")
	create_sound_file("reply.wav")
	create_sound_file("forward.wav")
	create_sound_file("delete.wav")
	create_sound_file("enemy_hit.wav")
	create_sound_file("enemy_death.wav")
	create_sound_file("player_hit.wav")
	create_sound_file("level_complete.wav")
	create_sound_file("game_over.wav")
	create_sound_file("boss_intro.wav")
	create_sound_file("boss_phase_1.wav")
	create_sound_file("boss_phase_2.wav")
	create_sound_file("boss_phase_3.wav")
	create_sound_file("keyboard_jam_warning.wav")

func create_sound_file(filename: String):
	var file_path = "res://assets/sounds/placeholder/" + filename
	
	# Check if file already exists
	if FileAccess.file_exists(file_path):
		return
	
	# Create empty file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string("PLACEHOLDER SOUND FILE")
	
	print("Created placeholder sound file: " + file_path)