extends Control

func _ready():
	# Set up button connections
	$VBoxContainer/StartButton.connect("pressed", Callable(self, "_on_start_button_pressed"))
	$VBoxContainer/OptionsButton.connect("pressed", Callable(self, "_on_options_button_pressed"))
	$VBoxContainer/QuitButton.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	
	# Start playing menu music
	SoundManager.play_music("main_menu")

func _on_start_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_options_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_quit_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().quit()