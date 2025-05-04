extends Node2D

# This script handles player animations

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var attack_particles = $AttackParticles

var current_animation = "idle"

func _ready():
	# Initialize animations
	if animation_player:
		animation_player.play("idle")

func play_movement_animation(direction: Vector2):
	if direction.length() > 0.1:
		# Moving
		if direction.x < -0.5:
			play_animation("move_left")
		elif direction.x > 0.5:
			play_animation("move_right")
		else:
			play_animation("move")
	else:
		# Idle
		play_animation("idle")

func play_animation(anim_name: String):
	if current_animation == anim_name:
		return
		
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		current_animation = anim_name

func play_attack_animation(attack_type: String):
	match attack_type:
		"reply":
			play_animation("attack_reply")
			spawn_attack_particles(Color(0.2, 0.6, 1.0))
		"forward":
			play_animation("attack_forward")
			spawn_attack_particles(Color(0.2, 1.0, 0.4))
		"delete":
			play_animation("attack_delete")
			spawn_attack_particles(Color(1.0, 0.3, 0.3))

func spawn_attack_particles(color: Color):
	if attack_particles:
		attack_particles.emitting = true
		attack_particles.modulate = color
		
		# Create a small screen shake
		if get_tree().get_nodes_in_group("camera").size() > 0:
			var camera = get_tree().get_nodes_in_group("camera")[0]
			if camera.has_node("ScreenShake"):
				camera.get_node("ScreenShake").start(0.2, 15, 8)
		
		# Apply hit stop
		HitStop.stop(0.05)

func play_hit_animation():
	play_animation("hit")
	
	# Flash the sprite
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
		
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.3)
	
	# Create screen shake
	if get_tree().get_nodes_in_group("camera").size() > 0:
		var camera = get_tree().get_nodes_in_group("camera")[0]
		if camera.has_node("ScreenShake"):
			camera.get_node("ScreenShake").start(0.3, 20, 15)
	
	# Apply hit stop
	HitStop.stop(0.1)