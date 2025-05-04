extends Area2D

signal jam_activated(keys)
signal jam_cleared

@export var jam_duration: float = 5.0
@export var key_count: int = 3
@export var move_speed: float = 80.0
@export var damage_on_contact: float = 5.0

var keys_to_press: Array = []
var keys_pressed: Array = []
var is_active: bool = false
var possible_keys = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
                     "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

func _ready():
	add_to_group("obstacle")
	$JamTimer.wait_time = jam_duration
	
	# Generate random keys to press
	for i in range(key_count):
		var random_key = possible_keys[randi() % possible_keys.size()]
		keys_to_press.append(random_key)
		
	# Update label
	update_key_display()

func _physics_process(delta):
	# Move downward
	position.y += move_speed * delta
	
	# Remove if off screen
	if position.y > 800:
		queue_free()

func _input(event):
	if not is_active:
		return
		
	if event is InputEventKey and event.pressed:
		var key_pressed = OS.get_keycode_string(event.keycode)
		
		# Check if this is one of our target keys
		if keys_to_press.has(key_pressed) and not keys_pressed.has(key_pressed):
			keys_pressed.append(key_pressed)
			
			# Play key press sound
			SoundManager.play_sound("key_press")
			
			# Update display
			update_key_display()
			
			# Check if all keys are pressed
			if keys_pressed.size() == keys_to_press.size():
				clear_jam()

func update_key_display():
	var display_text = ""
	
	for key in keys_to_press:
		if keys_pressed.has(key):
			display_text += "[" + key + "] "
		else:
			display_text += key + " "
			
	$KeysLabel.text = display_text

func activate_jam():
	is_active = true
	$JamTimer.start()
	$AnimationPlayer.play("active")
	
	# Emit signal with keys that need to be pressed
	emit_signal("jam_activated", keys_to_press)
	
	# Play activation sound
	SoundManager.play_sound("keyboard_jam")

func clear_jam():
	is_active = false
	$JamTimer.stop()
	$AnimationPlayer.play("cleared")
	
	# Emit signal that jam is cleared
	emit_signal("jam_cleared")
	
	# Play cleared sound
	SoundManager.play_sound("jam_cleared")
	
	# Remove after animation
	await $AnimationPlayer.animation_finished
	queue_free()

func _on_jam_timer_timeout():
	# If timer expires, the jam clears but player doesn't get reward
	is_active = false
	$AnimationPlayer.play("timeout")
	
	# Emit signal that jam is cleared
	emit_signal("jam_cleared")
	
	# Play timeout sound
	SoundManager.play_sound("jam_timeout")
	
	# Remove after animation
	await $AnimationPlayer.animation_finished
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and not is_active:
		# Damage player on contact
		body.take_damage(damage_on_contact)
		
		# Activate the jam
		activate_jam()