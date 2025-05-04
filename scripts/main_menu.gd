extends Control

func _ready():
	# Load game data
	Global.load_game()
	
	# Start playing menu music
	SoundManager.play_music("main_menu")
	
	# Fade in
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _on_start_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _on_level_select_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_tutorial_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_options_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_credits_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().change_scene_to_file("res://scenes/credits.tscn")

func _on_quit_button_pressed():
	SoundManager.play_sound("button_click")
	get_tree().quit()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_quit_button_pressed()