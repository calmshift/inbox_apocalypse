extends CharacterBody2D

signal stress_changed(new_value)
signal player_died

@export var speed: float = 300.0
@export var focus_speed_multiplier: float = 0.5
@export var max_stress: float = 100.0
@export var invincibility_time: float = 1.0

var current_stress: float = 0.0
var is_focus_mode: bool = false
var is_invincible: bool = false
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	$InvincibilityTimer.wait_time = invincibility_time

func _physics_process(delta):
	# Get input direction
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	
	# Apply focus mode speed reduction if active
	var current_speed = speed
	if Input.is_action_pressed("focus_mode"):
		is_focus_mode = true
		current_speed *= focus_speed_multiplier
		$HitboxSprite.modulate = Color(0.5, 0.8, 1.0, 0.8)  # Blue tint in focus mode
	else:
		is_focus_mode = false
		$HitboxSprite.modulate = Color(1.0, 1.0, 1.0, 0.5)  # Normal color
	
	# Set velocity and move
	velocity = direction * current_speed
	move_and_slide()
	
	# Clamp position to screen boundaries
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func take_damage(amount: float):
	if is_invincible:
		return
		
	current_stress += amount
	emit_signal("stress_changed", current_stress / max_stress)
	
	# Play sound effect
	SoundManager.play_sound("player_hit")
	
	# Visual feedback
	$AnimationPlayer.play("damage_flash")
	
	# Start invincibility
	is_invincible = true
	$InvincibilityTimer.start()
	
	# Check for death
	if current_stress >= max_stress:
		die()

func die():
	set_physics_process(false)
	$AnimationPlayer.play("death")
	await $AnimationPlayer.animation_finished
	emit_signal("player_died")

func _on_invincibility_timer_timeout():
	is_invincible = false

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy_projectile"):
		take_damage(area.damage)
		area.queue_free()
	elif area.is_in_group("enemy"):
		take_damage(area.contact_damage)

func use_reply():
	if $ReplyAttack.can_attack():
		$ReplyAttack.attack()

func use_forward():
	if $ForwardAttack.can_attack():
		$ForwardAttack.attack()

func use_delete():
	if $DeleteAttack.can_attack():
		$DeleteAttack.attack()