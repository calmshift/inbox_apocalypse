extends Node2D

# This script handles enemy animations

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var hit_particles = $HitParticles
@onready var death_particles = $DeathParticles

var current_animation = "idle"
var enemy_type = "regular"

func _ready():
	# Initialize animations
	if animation_player:
		animation_player.play("idle")

func set_enemy_type(type: String):
	enemy_type = type
	
	# Set appearance based on type
	match type:
		"spam":
			if sprite:
				sprite.modulate = Color(1.0, 0.5, 0.5)
		"newsletter":
			if sprite:
				sprite.modulate = Color(0.5, 0.8, 1.0)
		"urgent":
			if sprite:
				sprite.modulate = Color(1.0, 0.8, 0.2)
		"boss":
			if sprite:
				sprite.modulate = Color(0.8, 0.2, 0.8)
				sprite.scale = Vector2(1.5, 1.5)
		"attachment":
			if sprite:
				sprite.modulate = Color(0.7, 0.7, 0.7)
		_:
			if sprite:
				sprite.modulate = Color(1.0, 1.0, 1.0)

func play_animation(anim_name: String):
	if current_animation == anim_name:
		return
		
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		current_animation = anim_name

func play_idle_animation():
	play_animation("idle")

func play_open_animation():
	play_animation("open")

func play_hit_animation():
	# Flash the sprite
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
		
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.2)
	
	# Emit hit particles
	if hit_particles:
		hit_particles.emitting = true
	
	# Play hit sound based on enemy type
	match enemy_type:
		"boss":
			SoundManager.play_sound("boss_hit")
		_:
			SoundManager.play_sound("enemy_hit")
	
	# Apply small hit stop
	HitStop.stop(0.03)

func play_death_animation():
	play_animation("death")
	
	# Emit death particles
	if death_particles:
		death_particles.emitting = true
	
	# Play death sound based on enemy type
	match enemy_type:
		"boss":
			SoundManager.play_sound("boss_death")
		_:
			SoundManager.play_sound("enemy_death")
	
	# Create screen shake
	if enemy_type == "boss":
		if get_tree().get_nodes_in_group("camera").size() > 0:
			var camera = get_tree().get_nodes_in_group("camera")[0]
			if camera.has_node("ScreenShake"):
				camera.get_node("ScreenShake").start(0.5, 30, 20)
		
		# Apply longer hit stop for boss death
		HitStop.stop(0.2)
	else:
		# Apply small hit stop for regular enemy death
		HitStop.stop(0.05)