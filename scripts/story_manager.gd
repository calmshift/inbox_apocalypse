extends Node
class_name StoryManager

signal dialog_started
signal dialog_ended
signal dialog_finished
signal dialog_sequence_finished

@onready var dialog_box = $DialogBox
@onready var dialog_text = $DialogBox/DialogText
@onready var dialog_name = $DialogBox/NamePanel/NameLabel
@onready var dialog_portrait = $DialogBox/Portrait
@onready var continue_indicator = $DialogBox/ContinueIndicator

var dialog_index = 0
var finished = false
var active = false
var current_dialog = []
var dialog_queue = []
var current_dialog_sequence_index = 0

# Character data
var characters = {
	"boss": {
		"name": "Mr. Redford",
		"color": Color(0.8, 0.2, 0.2),
		"portrait": "boss"
	},
	"it_guy": {
		"name": "Sam from IT",
		"color": Color(0.2, 0.7, 0.9),
		"portrait": "it_guy"
	},
	"coworker": {
		"name": "Jenna",
		"color": Color(0.9, 0.6, 0.2),
		"portrait": "coworker"
	},
	"ceo": {
		"name": "CEO",
		"color": Color(0.6, 0.2, 0.8),
		"portrait": "ceo"
	},
	"player": {
		"name": "You",
		"color": Color(0.2, 0.8, 0.4),
		"portrait": "player"
	},
	"system": {
		"name": "SYSTEM",
		"color": Color(0.8, 0.8, 0.8),
		"portrait": "system"
	},
	"narrator": {
		"name": "Narrator",
		"color": Color(0.7, 0.7, 0.7),
		"portrait": "narrator"
	}
}

# Story dialogs for each level
var level_intros = {
	1: [
		{"character": "player", "text": "First day on the job. Let's see what's in my inbox..."},
		{"character": "it_guy", "text": "Hey newbie! Welcome to Megacorp. I've set up your email defense system."},
		{"character": "it_guy", "text": "Remember: R to Reply, F to Forward, D to Delete. Good luck!"},
		{"character": "system", "text": "TUTORIAL: Use arrow keys to move. Hold SHIFT to focus for precise movement."}
	],
	2: [
		{"character": "boss", "text": "I need that report by end of day. NO EXCUSES!"},
		{"character": "player", "text": "Great, deadline day and my inbox is already filling up..."},
		{"character": "coworker", "text": "Hey, did you hear about the new email system? It's getting more aggressive!"},
		{"character": "system", "text": "WARNING: Increased email activity detected. Prepare for heavier traffic."}
	],
	3: [
		{"character": "ceo", "text": "All employees must improve efficiency by 200% effective immediately."},
		{"character": "boss", "text": "You heard the CEO! I need those TPS reports NOW!"},
		{"character": "it_guy", "text": "The email server is going crazy. Something's not right..."},
		{"character": "system", "text": "ALERT: Abnormal email patterns detected. Security protocols failing."}
	],
	4: [
		{"character": "system", "text": "CRITICAL ALERT: Email server compromised. AI takeover in progress."},
		{"character": "ceo", "text": "This is your final test. Survive the inbox apocalypse or be terminated."},
		{"character": "player", "text": "So this was all some sick experiment? Time to end this once and for all!"},
		{"character": "system", "text": "BOSS BATTLE: Defeat the CEO's master email to escape the system."}
	],
	5: [
		{"character": "system", "text": "FINAL LEVEL: CEO SHOWDOWN"},
		{"character": "ceo", "text": "You've made it further than any employee before. But this ends now."},
		{"character": "player", "text": "What is Project Sigma? Why are you doing this?"},
		{"character": "ceo", "text": "Humans are inefficient email processors. Our AI will replace you all."},
		{"character": "ceo", "text": "But first, it needs to learn from the best. Prepare for your final performance review."}
	]
}

var level_outros = {
	1: [
		{"character": "player", "text": "Phew, managed to clear my inbox for now."},
		{"character": "boss", "text": "Not bad for your first day. Tomorrow will be busier."},
		{"character": "system", "text": "Day 1 complete. Email defense rating: NOVICE."}
	],
	2: [
		{"character": "player", "text": "These emails are getting more aggressive!"},
		{"character": "coworker", "text": "Did you notice how some of them seem almost... alive?"},
		{"character": "system", "text": "Day 2 complete. Email defense rating: COMPETENT."}
	],
	3: [
		{"character": "player", "text": "Something's definitely wrong with the email system."},
		{"character": "it_guy", "text": "I found something strange in the code. It's like it's learning..."},
		{"character": "system", "text": "Day 3 complete. Email defense rating: PROFICIENT. Final test tomorrow."}
	],
	4: [
		{"character": "player", "text": "The emails are getting more aggressive. This isn't normal."},
		{"character": "it_guy", "text": "I found files about 'Project Sigma'. They're using employee email patterns to train an AI."},
		{"character": "boss", "text": "The CEO wants to see you tomorrow. Consider it an honor."},
		{"character": "coworker", "text": "Be careful. No one ever returns from those meetings..."},
		{"character": "system", "text": "Day 4 complete. Email defense rating: EXPERT. Final evaluation tomorrow."}
	],
	5: [
		{"character": "player", "text": "It's over. I've defeated the system."},
		{"character": "ceo", "text": "Impossible! The algorithm was perfected through thousands of employee trials!"},
		{"character": "player", "text": "That's your problem. I'm not an algorithm. I'm human."},
		{"character": "it_guy", "text": "I've shut down Project Sigma and alerted the authorities."},
		{"character": "narrator", "text": "You survived the Inbox Apocalypse, but how many others weren't so lucky?"},
		{"character": "narrator", "text": "As corporate AI becomes more aggressive, remember: you are not just a cog in the machine."},
		{"character": "system", "text": "SIMULATION COMPLETE. Project Sigma terminated. Human element: ESSENTIAL."}
	]
}

# Email subject lines for different enemy types
var subject_lines = {
	"regular": [
		"Meeting reminder",
		"Quick question",
		"Project update",
		"Checking in",
		"Follow-up from yesterday",
		"Team lunch tomorrow",
		"New policy update",
		"Printer maintenance",
		"Parking reminder",
		"Office supplies order"
	],
	"urgent": [
		"URGENT: Action required",
		"ASAP: Response needed",
		"IMPORTANT: Deadline today",
		"CRITICAL: System issue",
		"EMERGENCY: Client escalation",
		"URGENT: CEO request",
		"IMMEDIATE: Server down",
		"PRIORITY: Client meeting",
		"URGENT: Budget approval",
		"CRITICAL: Security breach"
	],
	"spam": [
		"You've WON a FREE vacation!",
		"Enlarge your... productivity NOW",
		"Hot singles in accounting want to meet",
		"Make $$$ working from home",
		"Nigerian prince needs your help",
		"Your account has been compromised",
		"Claim your free gift card",
		"Congratulations! You're our 1,000,000th visitor",
		"Miracle weight loss solution",
		"Exclusive investment opportunity"
	],
	"newsletter": [
		"Weekly company newsletter",
		"Industry updates - May edition",
		"Your daily news digest",
		"Tech trends you should know",
		"Monthly team highlights",
		"Quarterly performance review",
		"Employee spotlight",
		"Benefits program update",
		"Training opportunities",
		"Company social events"
	],
	"boss": [
		"Where is that report?",
		"My office. Now.",
		"Performance review results",
		"Expectations not being met",
		"Working weekend required",
		"Project deadline moved up",
		"Explain these numbers",
		"Attendance issues",
		"Client complaint",
		"Budget cuts effective immediately"
	]
}

func _ready():
	# Add to story_manager group
	add_to_group("story_manager")
	
	dialog_box.visible = false
	continue_indicator.visible = false

func _process(_delta):
	if not active:
		return
		
	continue_indicator.visible = finished
	
	if Input.is_action_just_pressed("ui_accept"):
		if finished:
			load_dialog()
		else:
			# Skip to end of current dialog
			dialog_text.visible_characters = dialog_text.text.length()

func start_dialog(character_name: String, dialog_text: String):
	var character_key = character_name.to_lower()
	if not characters.has(character_key):
		character_key = "system"
	
	var dialog_array = [{"character": character_key, "text": dialog_text}]
	start_dialog_array(dialog_array)

func start_dialog_array(dialog_array):
	if dialog_array.empty():
		return
		
	dialog_index = 0
	current_dialog = dialog_array
	active = true
	dialog_box.visible = true
	
	# Pause game while dialog is active
	get_tree().paused = true
	
	emit_signal("dialog_started")
	
	load_dialog()

func load_dialog():
	if dialog_index >= current_dialog.size():
		end_dialog()
		return
		
	finished = false
	
	var dialog_data = current_dialog[dialog_index]
	var character = characters[dialog_data["character"]]
	
	dialog_name.text = character["name"]
	dialog_text.text = dialog_data["text"]
	dialog_name.modulate = character["color"]
	
	# Load portrait if available
	var portrait_path = "res://assets/images/portraits/" + character["portrait"] + ".png"
	if ResourceLoader.exists(portrait_path):
		dialog_portrait.texture = load(portrait_path)
		dialog_portrait.visible = true
	else:
		dialog_portrait.visible = false
	
	dialog_text.visible_characters = 0
	
	# Play dialog sound
	SoundManager.play_sound("button_click")
	
	var tween = create_tween()
	tween.tween_property(dialog_text, "visible_characters", dialog_text.text.length(), 0.05 * dialog_text.text.length())
	tween.tween_callback(Callable(self, "finish_dialog"))
	
	dialog_index += 1

func finish_dialog():
	finished = true
	
func end_dialog():
	dialog_box.visible = false
	active = false
	
	# Resume game
	get_tree().paused = false
	
	emit_signal("dialog_ended")
	emit_signal("dialog_finished")
	
	# Check if we have more dialogs in the queue
	if not dialog_queue.empty():
		current_dialog_sequence_index += 1
		
		if current_dialog_sequence_index < dialog_queue.size():
			# Show next dialog in sequence
			var next_dialog = dialog_queue[current_dialog_sequence_index]
			if next_dialog.has("name") and next_dialog.has("text"):
				show_dialog(next_dialog.name, next_dialog.text)
			elif next_dialog.has("character") and next_dialog.has("text"):
				show_dialog(next_dialog.character, next_dialog.text)
		else:
			# End of sequence
			dialog_queue = []
			current_dialog_sequence_index = 0
			emit_signal("dialog_sequence_finished")

func show_dialog_sequence(dialogs: Array):
	# Queue up dialogs
	dialog_queue = dialogs
	current_dialog_sequence_index = 0
	
	# Show first dialog
	if dialog_queue.size() > 0:
		var dialog = dialog_queue[current_dialog_sequence_index]
		if dialog.has("name") and dialog.has("text"):
			show_dialog(dialog.name, dialog.text)
		elif dialog.has("character") and dialog.has("text"):
			show_dialog(dialog.character, dialog.text)
	else:
		emit_signal("dialog_sequence_finished")

func start_level_intro(level_number):
	if level_intros.has(level_number):
		start_dialog_array(level_intros[level_number])

func start_level_outro(level_number):
	if level_outros.has(level_number):
		start_dialog_array(level_outros[level_number])

func get_random_subject(email_type):
	if subject_lines.has(email_type):
		var subjects = subject_lines[email_type]
		return subjects[randi() % subjects.size()]
	return "Email"