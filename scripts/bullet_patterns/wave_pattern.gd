extends "res://scripts/bullet_pattern.gd"

# Wave bullet pattern
# Fires bullets in a wave pattern

@export var wave_count = 3        # Number of waves
@export var bullets_per_wave = 10 # Number of bullets per wave
@export var wave_interval = 1.0   # Time between waves
@export var wave_width = 120.0    # Width of the wave in degrees

var wave_timer = 0.0
var current_wave = 0

func _process(delta):
	if not active:
		return
		
	wave_timer += delta
	
	if wave_timer >= wave_interval:
		wave_timer = 0
		current_wave += 1
		
		# Fire a wave of bullets
		for i in range(bullets_per_wave):
			var angle = deg_to_rad(-wave_width/2 + i * (wave_width / (bullets_per_wave - 1)))
			var direction = Vector2(cos(angle), sin(angle))
			fire_bullet(direction)
		
		# Play sound effect
		if owner and owner.has_method("play_sound"):
			owner.play_sound("email_open")
		
		# Check if we've completed all waves
		if current_wave >= wave_count:
			active = false