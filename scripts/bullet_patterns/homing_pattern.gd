extends "res://scripts/bullet_pattern.gd"

# Homing bullet pattern
# Fires bullets that home in on the player

@export var tracking_strength = 0.5  # How strongly bullets track the player
@export var max_bullets = 10         # Maximum number of bullets to fire
@export var spread_angle = 45.0      # Initial spread angle in degrees

var bullet_count = 0
var player = null

func _ready():
	# Find the player
	await get_tree().create_timer(0.1).timeout
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(delta):
	if not active or bullet_count >= max_bullets:
		active = false
		return
		
	fire_timer += delta
	if fire_timer >= fire_rate:
		fire_timer = 0
		bullet_count += 1
		
		# Calculate direction towards player with some randomness
		var direction = Vector2.RIGHT
		if player:
			direction = (player.global_position - global_position).normalized()
			
		# Add some randomness to the direction
		var random_angle = randf_range(-deg_to_rad(spread_angle/2), deg_to_rad(spread_angle/2))
		direction = direction.rotated(random_angle)
		
		# Fire a homing bullet
		var bullet = fire_bullet(direction)
		if bullet:
			bullet.homing = true
			bullet.tracking_strength = tracking_strength
			bullet.target = player