extends CanvasLayer

@onready var stress_bar = $StressBar
@onready var score_label = $ScoreLabel
@onready var wave_label = $WaveLabel
@onready var game_over_panel = $GameOverPanel
@onready var level_complete_panel = $LevelCompletePanel
@onready var reply_button = $ActionButtons/ReplyButton
@onready var forward_button = $ActionButtons/ForwardButton
@onready var delete_button = $ActionButtons/DeleteButton

var game_manager = null

func _ready():
	game_over_panel.visible = false
	level_complete_panel.visible = false
	
	# Find game manager
	game_manager = get_parent()
	
	# Connect signals
	if game_manager:
		game_manager.connect("score_changed", Callable(self, "_on_score_changed"))
		game_manager.connect("wave_changed", Callable(self, "_on_wave_changed"))
		game_manager.connect("game_over", Callable(self, "_on_game_over"))
		game_manager.connect("level_completed", Callable(self, "_on_level_completed"))
	
	# Connect player stress signal
	if game_manager and game_manager.player:
		game_manager.player.connect("stress_changed", Callable(self, "_on_stress_changed"))

func _on_score_changed(new_score):
	score_label.text = "Score: " + str(new_score)

func _on_wave_changed(new_wave):
	wave_label.text = "Wave: " + str(new_wave)

func _on_stress_changed(stress_percent):
	stress_bar.value = stress_percent * 100

func _on_game_over():
	game_over_panel.visible = true
	SoundManager.play_sound("game_over")

func _on_level_completed():
	level_complete_panel.visible = true
	SoundManager.play_sound("level_complete")

func _on_reply_button_pressed():
	if game_manager and game_manager.player:
		game_manager.player.use_reply()
		SoundManager.play_sound("reply")

func _on_forward_button_pressed():
	if game_manager and game_manager.player:
		game_manager.player.use_forward()
		SoundManager.play_sound("forward")

func _on_delete_button_pressed():
	if game_manager and game_manager.player:
		game_manager.player.use_delete()
		SoundManager.play_sound("delete")

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_retry_button_pressed():
	get_tree().reload_current_scene()

func _on_next_level_button_pressed():
	# This would be implemented to load the next level
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")