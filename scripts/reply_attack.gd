extends Node2D

@export var projectile_scene: PackedScene
@export var cooldown_time: float = 0.3
@export var projectile_speed: float = 600.0
@export var projectile_damage: float = 10.0

var can_fire: bool = true
var power_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var projectile_count: int = 1
var spread_angle: float = 5.0  # Degrees between projectiles when firing multiple

func _ready():
	$CooldownTimer.wait_time = cooldown_time

func can_attack() -> bool:
	return can_fire

func attack():
	if not can_fire:
		return
		
	# Play sound effect
	SoundManager.play_sound("reply")
	
	# Create projectiles
	if projectile_count == 1:
		# Single projectile
		spawn_projectile(Vector2.UP)
	else:
		# Multiple projectiles with spread
		var total_spread = spread_angle * (projectile_count - 1)
		var start_angle = -total_spread / 2
		
		for i in range(projectile_count):
			var angle = start_angle + i * spread_angle
			var direction = Vector2.UP.rotated(deg_to_rad(angle))
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
	projectile.get_node("Sprite2D").texture = load("res://assets/images/player_projectile.png")
	
	get_tree().current_scene.add_child(projectile)

func _on_cooldown_timer_timeout():
	can_fire = true

func set_power_multiplier(value: float):
	power_multiplier = value

func set_cooldown_multiplier(value: float):
	cooldown_multiplier = value
	
func set_projectile_count(value: int):
	projectile_count = value