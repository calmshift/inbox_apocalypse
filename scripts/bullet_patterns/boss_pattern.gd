extends "res://scripts/bullet_pattern.gd"

# Boss bullet pattern
# Complex pattern for boss fights

@export var phase_duration = 3.0  # Duration of each phase
@export var total_phases = 4      # Total number of phases

var current_phase = 0
var phase_timer = 0.0
var angle = 0.0

func _process(delta):
	if not active:
		return
		
	phase_timer += delta
	angle += delta * 2.0
	
	# Change phase if needed
	if phase_timer >= phase_duration:
		phase_timer = 0.0
		current_phase = (current_phase + 1) % total_phases
		
		# Play phase transition sound
		if owner and owner.has_method("play_sound"):
			owner.play_sound("boss_phase")
	
	# Fire bullets based on current phase
	fire_timer += delta
	if fire_timer >= fire_rate:
		fire_timer = 0
		
		match current_phase:
			0: # Spiral pattern
				for i in range(8):
					var dir_angle = angle + i * (2 * PI / 8)
					var direction = Vector2(cos(dir_angle), sin(dir_angle))
					fire_bullet(direction)
			
			1: # Cross pattern
				for i in range(4):
					var dir_angle = angle + i * (PI / 2)
					var direction = Vector2(cos(dir_angle), sin(dir_angle))
					fire_bullet(direction)
					
					# Diagonal shots
					var diag_angle = angle + i * (PI / 2) + (PI / 4)
					var diag_direction = Vector2(cos(diag_angle), sin(diag_angle))
					fire_bullet(diag_direction)
			
			2: # Random burst
				for i in range(5):
					var random_angle = randf() * 2 * PI
					var direction = Vector2(cos(random_angle), sin(random_angle))
					fire_bullet(direction)
			
			3: # Targeted pattern
				var players = get_tree().get_nodes_in_group("player")
				if players.size() > 0:
					var player = players[0]
					var direction = (player.global_position - global_position).normalized()
					
					# Fire directly at player
					fire_bullet(direction)
					
					# Fire slightly to the sides
					fire_bullet(direction.rotated(deg_to_rad(15)))
					fire_bullet(direction.rotated(deg_to_rad(-15)))
					
					# Fire perpendicular shots
					fire_bullet(direction.rotated(deg_to_rad(90)))
					fire_bullet(direction.rotated(deg_to_rad(-90)))