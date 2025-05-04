extends Control

func _ready():
	# Fade in
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _on_start_button_pressed():
	# Check if level 1 is unlocked
	if Global.is_level_unlocked(0):
		# Start game at level 1
		Global.current_level_index = 0
		Global.current_level = Global.level_paths[0]
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		# Unlock level 1 and start
		Global.unlock_level(0)
		Global.current_level_index = 0
		Global.current_level = Global.level_paths[0]
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_tutorial_button_pressed():
	# Start tutorial
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")