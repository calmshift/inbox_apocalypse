extends Control
class_name EndGameSequence

signal sequence_completed

# References to UI elements
@onready var background = $Background
@onready var overlay = $Overlay
@onready var dialog_box = $DialogBox
@onready var dialog_text = $DialogBox/DialogText
@onready var dialog_portrait = $DialogBox/Portrait
@onready var dialog_name = $DialogBox/NamePanel/NameLabel
@onready var continue_indicator = $DialogBox/ContinueIndicator
@onready var animation_player = $AnimationPlayer
@onready var particles = $Particles
@onready var credits_panel = $CreditsPanel
@onready var score_panel = $ScorePanel
@onready var final_score_label = $ScorePanel/FinalScoreLabel
@onready var high_score_label = $ScorePanel/HighScoreLabel
@onready var continue_button = $ContinueButton

# Dialog sequence
var dialog_index = 0
var finished = false
var active = true
var is_victory = false
var final_score = 0
var high_score = 0

# Dialog sequences
var victory_dialog = [
	{
		"name": "CEO",
		"text": "Impossible! How could a mere employee defeat my email system?",
		"portrait": "ceo"
	},
	{
		"name": "You",
		"text": "I've had enough of your corporate control. The emails don't own me anymore!",
		"portrait": "player"
	},
	{
		"name": "CEO",
		"text": "You may have won this battle, but the corporate world will always find a way to fill your inbox...",
		"portrait": "ceo"
	},
	{
		"name": "IT Guy",
		"text": "Hey, you did it! I've never seen anyone handle their inbox like that before.",
		"portrait": "it_guy"
	},
	{
		"name": "Coworker",
		"text": "Does this mean we get to leave early today?",
		"portrait": "coworker"
	},
	{
		"name": "Narrator",
		"text": "And so, the Inbox Apocalypse was averted... for now.",
		"portrait": "narrator"
	},
	{
		"name": "Narrator",
		"text": "But in offices around the world, emails continue to multiply, waiting for their chance to rise again...",
		"portrait": "narrator"
	}
]

var defeat_dialog = [
	{
		"name": "System",
		"text": "INBOX OVERLOAD. EMPLOYEE PRODUCTIVITY COMPROMISED.",
		"portrait": "system"
	},
	{
		"name": "You",
		"text": "There's... too many... emails...",
		"portrait": "player"
	},
	{
		"name": "Boss",
		"text": "I expected better from you. Clear your desk by the end of the day.",
		"portrait": "boss"
	},
	{
		"name": "CEO",
		"text": "Another employee consumed by the inbox. The system works perfectly.",
		"portrait": "ceo"
	},
	{
		"name": "Narrator",
		"text": "Game Over. The emails have won this round.",
		"portrait": "narrator"
	},
	{
		"name": "Narrator",
		"text": "But perhaps with better email management strategies, you could try again...",
		"portrait": "narrator"
	}
]

var current_dialog = []

func _ready():
	# Hide UI elements initially
	dialog_box.visible = false
	continue_indicator.visible = false
	credits_panel.visible = false
	score_panel.visible = false
	
	if continue_button:
		continue_button.visible = false
		continue_button.pressed.connect(_on_continue_button_pressed)
	
	# Set overlay to fully opaque for fade-in
	overlay.modulate.a = 1.0

func start_sequence(victory: bool, score: int = 0):
	is_victory = victory
	final_score = score
	
	# Get high score from Global
	if Global and Global.current_level_index < Global.high_scores.size():
		high_score = Global.high_scores[Global.current_level_index]
	
	# Set appropriate dialog
	current_dialog = victory_dialog if is_victory else defeat_dialog
	
	# Play appropriate music
	if is_victory:
		SoundManager.play_music("victory")
	else:
		SoundManager.play_music("game_over")
	
	# Start sequence
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 2.0)
	tween.tween_callback(Callable(self, "start_dialog"))

func start_dialog():
	dialog_box.visible = true
	dialog_index = 0
	load_dialog()

func _process(_delta):
	continue_indicator.visible = finished
	
	if active and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select")):
		if finished:
			load_dialog()
		else:
			# Skip to end of current dialog
			dialog_text.visible_characters = dialog_text.text.length()
			finish_dialog()

func load_dialog():
	if dialog_index >= current_dialog.size():
		show_end_screen()
		return
		
	finished = false
	
	var dialog = current_dialog[dialog_index]
	dialog_name.text = dialog["name"]
	dialog_text.text = dialog["text"]
	
	# Set portrait
	var portrait_path = "res://assets/images/portraits/" + dialog["portrait"] + ".png"
	if ResourceLoader.exists(portrait_path):
		dialog_portrait.texture = load(portrait_path)
	
	# Play appropriate sound based on character
	match dialog["name"]:
		"System":
			SoundManager.play_sound("email_open")
		"CEO":
			SoundManager.play_sound("boss_laugh")
		"Boss":
			SoundManager.play_sound("keyboard_jam_warning")
		_:
			SoundManager.play_sound("dialog_next")
	
	# Reset text visibility
	dialog_text.visible_characters = 0
	
	# Create typing effect
	var tween = create_tween()
	tween.tween_property(dialog_text, "visible_characters", dialog_text.text.length(), 0.05 * dialog_text.text.length())
	tween.tween_callback(Callable(self, "finish_dialog"))
	
	dialog_index += 1

func finish_dialog():
	finished = true

func show_end_screen():
	# Hide dialog box
	dialog_box.visible = false
	
	if is_victory:
		# Show victory effects
		if particles:
			particles.emitting = true
		
		# Play victory sound
		SoundManager.play_sound("level_complete")
	else:
		# Play defeat sound
		SoundManager.play_sound("game_over")
	
	# Show score panel
	score_panel.visible = true
	if final_score_label:
		final_score_label.text = "Final Score: " + str(final_score)
	if high_score_label:
		high_score_label.text = "High Score: " + str(high_score)
	
	# Show credits
	await get_tree().create_timer(2.0).timeout
	credits_panel.visible = true
	
	if animation_player:
		animation_player.play("scroll_credits")
		await animation_player.animation_finished
	
	# Show continue button
	if continue_button:
		continue_button.visible = true

func _on_continue_button_pressed():
	# Play button sound
	SoundManager.play_sound("button_click")
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 1.0)
	tween.tween_callback(Callable(self, "emit_completed"))

func emit_completed():
	emit_signal("sequence_completed")

func skip_sequence():
	# Play button sound
	SoundManager.play_sound("menu_select")
	
	emit_completed()