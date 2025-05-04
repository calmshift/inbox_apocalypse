extends Control
class_name IntroSequence

signal intro_completed
signal dialog_finished

@onready var animation_player = $AnimationPlayer
@onready var dialog_box = $DialogBox
@onready var dialog_text = $DialogBox/DialogText
@onready var dialog_name = $DialogBox/NamePanel/NameLabel
@onready var dialog_portrait = $DialogBox/Portrait
@onready var continue_indicator = $DialogBox/ContinueIndicator
@onready var background = $Background
@onready var overlay = $Overlay
@onready var title_logo = $TitleLogo
@onready var particles = $Particles
@onready var skip_button = $SkipButton

var dialog_index = 0
var finished = false
var active = true
var typing_speed = 0.03
var typing_sound_cooldown = 0.1
var current_typing_cooldown = 0.0
var show_title_at_end = true

var dialog = [
	{
		"name": "Narrator",
		"text": "In the not-so-distant future, corporate life has become a literal battle for survival...",
		"portrait": "narrator",
		"sound": "dialog_next"
	},
	{
		"name": "Narrator",
		"text": "Emails aren't just annoying interruptions anymore. They're dangerous entities that threaten to overwhelm workers with their endless demands.",
		"portrait": "narrator",
		"sound": "dialog_next"
	},
	{
		"name": "System",
		"text": "MEGACORP INDUSTRIES - EMPLOYEE TERMINAL ACTIVATED",
		"portrait": "system",
		"sound": "email_open"
	},
	{
		"name": "Boss",
		"text": "I need that report by end of day. NO EXCUSES!",
		"portrait": "boss",
		"sound": "boss_laugh"
	},
	{
		"name": "You",
		"text": "Another day at Megacorp Industries... My inbox is already filling up.",
		"portrait": "player",
		"sound": "typing"
	},
	{
		"name": "IT Guy",
		"text": "Hey, I installed that new email defense system you requested. Just press R to Reply, F to Forward, and D to Delete.",
		"portrait": "it_guy",
		"sound": "keyboard_typing"
	},
	{
		"name": "You",
		"text": "Thanks, Sam. I'll need all the help I can get with today's inbox apocalypse.",
		"portrait": "player",
		"sound": "typing"
	},
	{
		"name": "Narrator",
		"text": "Little did they know, today would be different. Today, the emails would fight back...",
		"portrait": "narrator",
		"sound": "dialog_next"
	},
	{
		"name": "System",
		"text": "WARNING: ABNORMAL EMAIL ACTIVITY DETECTED. INBOX OVERLOAD IMMINENT.",
		"portrait": "system",
		"sound": "keyboard_jam_warning"
	},
	{
		"name": "Narrator",
		"text": "INBOX APOCALYPSE",
		"portrait": "narrator",
		"sound": "level_complete",
		"is_title": true
	}
]

func _ready():
	dialog_box.visible = false
	continue_indicator.visible = false
	
	if title_logo:
		title_logo.visible = false
	
	if particles:
		particles.emitting = false
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
	
	# Play ambient office sounds
	SoundManager.play_ambient("office_ambience", -15, true)
	
	# Start with fade in
	overlay.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 2.0)
	tween.tween_callback(Callable(self, "start_dialog"))

func start_dialog():
	dialog_box.visible = true
	load_dialog()

func _process(delta):
	continue_indicator.visible = finished
	
	# Update typing sound cooldown
	if current_typing_cooldown > 0:
		current_typing_cooldown -= delta
	
	if active:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
			if finished:
				load_dialog()
			else:
				# Skip to end of current dialog
				dialog_text.visible_characters = dialog_text.text.length()
				finish_dialog()

func load_dialog():
	if dialog_index >= dialog.size():
		end_dialog()
		return
		
	finished = false
	
	var current_dialog = dialog[dialog_index]
	dialog_name.text = current_dialog["name"]
	dialog_text.text = current_dialog["text"]
	
	# Set portrait
	var portrait_path = "res://assets/images/portraits/" + current_dialog["portrait"] + ".png"
	if ResourceLoader.exists(portrait_path):
		dialog_portrait.texture = load(portrait_path)
	
	# Play dialog sound
	if current_dialog.has("sound"):
		SoundManager.play_sound(current_dialog["sound"])
	
	# Check if this is the title reveal
	if current_dialog.has("is_title") and current_dialog["is_title"] and show_title_at_end:
		if title_logo:
			animation_player.play("title_reveal")
	
	dialog_text.visible_characters = 0
	
	# Create typing effect with sound
	var tween = create_tween()
	tween.tween_method(Callable(self, "_set_visible_characters"), 0, dialog_text.text.length(), typing_speed * dialog_text.text.length())
	tween.tween_callback(Callable(self, "finish_dialog"))
	
	dialog_index += 1

func _set_visible_characters(count: int):
	dialog_text.visible_characters = count
	
	# Play typing sound with cooldown
	if current_typing_cooldown <= 0:
		current_typing_cooldown = typing_sound_cooldown
		if dialog[dialog_index-1]["name"] == "You" or dialog[dialog_index-1]["name"] == "IT Guy":
			SoundManager.play_sound("typing", -20)

func finish_dialog():
	finished = true
	emit_signal("dialog_finished")
	
	# Special effects for certain dialogs
	if dialog_index > 0 and dialog_index <= dialog.size():
		var current_dialog = dialog[dialog_index-1]
		
		if current_dialog["name"] == "System" and current_dialog["text"].contains("WARNING"):
			# Screen shake for warning
			screen_shake(0.5, 5.0)
			
		if current_dialog.has("is_title") and current_dialog["is_title"]:
			# Start particles for title
			if particles:
				particles.emitting = true
	
func end_dialog():
	# Stop ambient sound
	SoundManager.stop_ambient()
	
	# Play ending music
	SoundManager.play_music("main_menu", -5)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 1.0)
	tween.tween_callback(Callable(self, "emit_completed"))

func emit_completed():
	emit_signal("intro_completed")
	
func skip_intro():
	SoundManager.play_sound("menu_select")
	dialog_index = dialog.size()
	end_dialog()

func _on_skip_button_pressed():
	skip_intro()

# Screen shake effect
func screen_shake(duration = 0.5, intensity = 5.0):
	var original_pos = background.position
	
	var tween = create_tween()
	for i in range(int(duration * 20)):
		var rand_x = randf_range(-intensity, intensity)
		var rand_y = randf_range(-intensity, intensity)
		tween.tween_property(background, "position", original_pos + Vector2(rand_x, rand_y), 0.05)
	
	tween.tween_property(background, "position", original_pos, 0.1)