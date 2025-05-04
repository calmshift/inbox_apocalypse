extends Node2D

@export var projectile_scene: PackedScene
@export var cooldown_time: float = 0.3
@export var projectile_speed: float = 600.0
@export var projectile_damage: float = 10.0

var can_fire: bool = true

func _ready():
	$CooldownTimer.wait_time = cooldown_time

func can_attack() -> bool:
	return can_fire

func attack():
	if not can_fire:
		return
		
	# Create projectile
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = Vector2.UP
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