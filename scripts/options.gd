extends Control

func _ready():
	# Connect button signals
	$BackButton.connect("pressed", Callable(self, "_on_back_button_pressed"))
	$VBoxContainer/FullscreenCheck.connect("toggled", Callable(self, "_on_fullscreen_toggled"))
	$VBoxContainer/MusicSlider.connect("value_changed", Callable(self, "_on_music_volume_changed"))
	$VBoxContainer/SFXSlider.connect("value_changed", Callable(self, "_on_sfx_volume_changed"))

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_fullscreen_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_music_volume_changed(value):
	# This would be implemented to adjust music volume
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	pass

func _on_sfx_volume_changed(value):
	# This would be implemented to adjust SFX volume
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	pass