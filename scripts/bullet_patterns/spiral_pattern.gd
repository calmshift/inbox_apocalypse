extends "res://scripts/bullet_pattern.gd"

# Spiral bullet pattern
# Fires bullets in a spiral pattern

@export var rotation_speed = 2.0  # Rotation speed in radians per second
@export var bullet_count = 8      # Number of bullets per rotation
@export var spiral_duration = 5.0 # How long the spiral pattern lasts

var current_angle = 0.0
var elapsed_time = 0.0

func _process(delta):
	if not active:
		return
		
	elapsed_time += delta
	
	if elapsed_time > spiral_duration:
		active = false
		return
	
	# Update the angle
	current_angle += rotation_speed * delta
	
	# Fire bullets in a spiral pattern
	fire_timer += delta
	if fire_timer >= fire_rate:
		fire_timer = 0
		
		for i in range(bullet_count):
			var angle = current_angle + i * (2 * PI / bullet_count)
			var direction = Vector2(cos(angle), sin(angle))
			fire_bullet(direction)