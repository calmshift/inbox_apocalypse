extends Node2D

@export var cooldown_time: float = 2.0
@export var explosion_radius: float = 150.0
@export var explosion_damage: float = 20.0
@export var clear_bullets: bool = true

var can_fire: bool = true

func _ready():
	$CooldownTimer.wait_time = cooldown_time
	$ExplosionArea/CollisionShape2D.shape.radius = explosion_radius

func can_attack() -> bool:
	return can_fire

func attack():
	if not can_fire:
		return
		
	# Play effects
	$AnimationPlayer.play("attack")
	$ExplosionArea.monitoring = true
	
	# Clear bullets if enabled
	if clear_bullets:
		var bullets = get_tree().get_nodes_in_group("enemy_projectile")
		for bullet in bullets:
			if bullet.global_position.distance_to(global_position) <= explosion_radius:
				bullet.queue_free()
	
	# Start cooldown
	can_fire = false
	$CooldownTimer.start()
	
	# Disable collision after a short time
	await get_tree().create_timer(0.1).timeout
	$ExplosionArea.monitoring = false

func _on_cooldown_timer_timeout():
	can_fire = true

func _on_explosion_area_area_entered(area):
	if area.is_in_group("enemy"):
		area.take_damage(explosion_damage)