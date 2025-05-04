extends "res://scripts/bullet_pattern.gd"

# Burst bullet pattern
# Fires bullets in bursts with pauses in between

@export var burst_count = 3       # Number of bursts
@export var bullets_per_burst = 5 # Number of bullets per burst
@export var burst_interval = 1.0  # Time between bursts
@export var spread_angle = 30.0   # Spread angle in degrees

var burst_timer = 0.0
var current_burst = 0
var burst_active = false

func _process(delta):
	if not active:
		return
		
	burst_timer += delta
	
	if not burst_active and burst_timer >= burst_interval:
		burst_timer = 0
		burst_active = true
		current_burst += 1
		
		# Fire a burst of bullets
		for i in range(bullets_per_burst):
			var angle_offset = (i - bullets_per_burst / 2.0) * deg_to_rad(spread_angle / bullets_per_burst)
			var direction = Vector2(cos(angle_offset), sin(angle_offset))
			fire_bullet(direction)
		
		# Play sound effect
		if owner and owner.has_method("play_sound"):
			owner.play_sound("email_open")
		
		burst_active = false
		
		# Check if we've completed all bursts
		if current_burst >= burst_count:
			active = false