extends Node2D

@export var projectile_scene: PackedScene
@export var cooldown_time: float = 0.5
@export var projectile_speed: float = 500.0
@export var projectile_damage: float = 5.0
@export var spread_count: int = 5
@export var spread_angle: float = 60.0

var can_fire: bool = true

func _ready():
	$CooldownTimer.wait_time = cooldown_time

func can_attack() -> bool:
	return can_fire

func attack():
	if not can_fire:
		return
		
	# Calculate spread angles
	var angle_step = deg_to_rad(spread_angle) / (spread_count - 1) if spread_count > 1 else 0
	var start_angle = -deg_to_rad(spread_angle) / 2
	
	# Create projectiles in a spread pattern
	for i in range(spread_count):
		var angle = start_angle + (angle_step * i)
		var direction = Vector2(sin(angle), -cos(angle)).normalized()
		
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position
		projectile.direction = direction
		projectile.speed = projectile_speed
		projectile.damage = projectile_damage
		get_tree().current_scene.add_child(projectile)
	
	# Play effects
	$AnimationPlayer.play("attack")
	
	# Start cooldown
	can_fire = false
	$CooldownTimer.start()

func _on_cooldown_timer_timeout():
	can_fire = true