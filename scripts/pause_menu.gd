extends Control

func _ready():
	# Connect button signals
	$Panel/VBoxContainer/ResumeButton.connect("pressed", Callable(self, "_on_resume_button_pressed"))
	$Panel/VBoxContainer/OptionsButton.connect("pressed", Callable(self, "_on_options_button_pressed"))
	$Panel/VBoxContainer/MainMenuButton.connect("pressed", Callable(self, "_on_main_menu_button_pressed"))
	
	# Hide the pause menu initially
	hide()

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var new_state = !get_tree().paused
	get_tree().paused = new_state
	visible = new_state

func _on_resume_button_pressed():
	toggle_pause()

func _on_options_button_pressed():
	# For the prototype, just resume the game
	toggle_pause()
	# In a full implementation, this would open the options menu
	# get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_main_menu_button_pressed():
	toggle_pause()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")