extends Control

func _ready():
	# Connect button signals
	$VBoxContainer/Day1Button.connect("pressed", Callable(self, "_on_day1_button_pressed"))
	$VBoxContainer/Day2Button.connect("pressed", Callable(self, "_on_day2_button_pressed"))
	$VBoxContainer/Day3Button.connect("pressed", Callable(self, "_on_day3_button_pressed"))
	$VBoxContainer/Day4Button.connect("pressed", Callable(self, "_on_day4_button_pressed"))
	$BackButton.connect("pressed", Callable(self, "_on_back_button_pressed"))
	
	# Start playing menu music if not already playing
	if not SoundManager.is_music_playing("main_menu"):
		SoundManager.play_music("main_menu")

func _on_day1_button_pressed():
	SoundManager.play_sound("button_click")
	Global.current_level = "res://resources/level_1.tres"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_day2_button_pressed():
	SoundManager.play_sound("button_click")
	Global.current_level = "res://resources/levels/level_2.tres"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_day3_button_pressed():
	SoundManager.play_sound("button_click")
	# For the prototype, day 3 uses the same level as day 1
	Global.current_level = "res://resources/level_1.tres"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_day4_button_pressed():
	SoundManager.play_sound("button_click")
	# For the prototype, day 4 uses the same level as day 2
	Global.current_level = "res://resources/levels/level_2.tres"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")