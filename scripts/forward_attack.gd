extends Node2D

@export var projectile_scene: PackedScene
@export var cooldown_time: float = 0.5
@export var projectile_speed: float = 500.0
@export var projectile_damage: float = 5.0
@export var spread_count: int = 3
@export var spread_angle: float = 60.0

var can_fire: bool = true
var power_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var projectile_count: int = 3  # This is the base spread count

func _ready():
	$CooldownTimer.wait_time = cooldown_time

func can_attack() -> bool:
	return can_fire

func attack():
	if not can_fire:
		return
		
	# Play sound effect
	SoundManager.play_sound("forward")
		
	# Calculate spread angles
	var angle_step = deg_to_rad(spread_angle) / (projectile_count - 1) if projectile_count > 1 else 0
	var start_angle = -deg_to_rad(spread_angle) / 2
	
	# Create projectiles in a spread pattern
	for i in range(projectile_count):
		var angle = start_angle + (angle_step * i)
		var direction = Vector2(sin(angle), -cos(angle)).normalized()
		spawn_projectile(direction)
	
	# Play effects
	$AnimationPlayer.play("attack")
	
	# Start cooldown
	can_fire = false
	$CooldownTimer.start(cooldown_time * cooldown_multiplier)

func spawn_projectile(direction: Vector2):
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage * power_multiplier
	
	# Set projectile texture
	projectile.get_node("Sprite2D").texture = load("res://assets/images/forward_projectile.png")
	
	get_tree().current_scene.add_child(projectile)

func _on_cooldown_timer_timeout():
	can_fire = true

func set_power_multiplier(value: float):
	power_multiplier = value

func set_cooldown_multiplier(value: float):
	cooldown_multiplier = value
	
func set_projectile_count(value: int):
	projectile_count = value