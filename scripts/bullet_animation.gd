extends Node2D

# This script handles bullet animations and effects

@onready var sprite = $Sprite2D
@onready var trail = $Trail
@onready var collision_particles = $CollisionParticles

var bullet_type = "regular"
var bullet_color = Color(1.0, 1.0, 1.0)

func _ready():
	# Set up initial appearance
	if sprite:
		sprite.modulate = bullet_color
	
	if trail:
		trail.modulate = bullet_color

func set_bullet_type(type: String):
	bullet_type = type
	
	# Set appearance based on type
	match type:
		"reply":
			bullet_color = Color(0.2, 0.6, 1.0)
		"forward":
			bullet_color = Color(0.2, 1.0, 0.4)
		"delete":
			bullet_color = Color(1.0, 0.3, 0.3)
		"spam":
			bullet_color = Color(1.0, 0.5, 0.5)
		"newsletter":
			bullet_color = Color(0.5, 0.8, 1.0)
		"urgent":
			bullet_color = Color(1.0, 0.8, 0.2)
		"boss":
			bullet_color = Color(0.8, 0.2, 0.8)
		"attachment":
			bullet_color = Color(0.7, 0.7, 0.7)
		_:
			bullet_color = Color(1.0, 1.0, 1.0)
	
	# Apply color
	if sprite:
		sprite.modulate = bullet_color
	
	if trail:
		trail.modulate = bullet_color

func play_collision_effect():
	# Emit collision particles
	if collision_particles:
		collision_particles.modulate = bullet_color
		collision_particles.emitting = true
	
	# Hide sprite
	if sprite:
		sprite.visible = false
	
	# Hide trail
	if trail:
		trail.visible = false
	
	# Queue free after particles finish
	await get_tree().create_timer(collision_particles.lifetime).timeout
	queue_free()

func _process(delta):
	# Update trail if moving
	if trail and get_parent() and get_parent().has_method("get_velocity"):
		var velocity = get_parent().get_velocity()
		if velocity.length() > 0:
			trail.visible = true
			
			# Adjust trail based on velocity
			var angle = velocity.angle()
			trail.rotation = angle + PI  # Point trail opposite to movement direction
		else:
			trail.visible = false