extends Node2D

@export var cooldown_time: float = 2.0
@export var explosion_radius: float = 150.0
@export var explosion_damage: float = 20.0
@export var clear_bullets: bool = true

var can_fire: bool = true
var power_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0

func _ready():
	$CooldownTimer.wait_time = cooldown_time
	$ExplosionArea/CollisionShape2D.shape.radius = explosion_radius

func can_attack() -> bool:
	return can_fire

func attack():
	if not can_fire:
		return
		
	# Play sound effect
	SoundManager.play_sound("delete")
		
	# Play effects
	$AnimationPlayer.play("attack")
	$ExplosionArea.monitoring = true
	
	# Create visual explosion effect
	create_explosion_effect()
	
	# Clear bullets if enabled
	if clear_bullets:
		var bullets = get_tree().get_nodes_in_group("enemy_projectile")
		var cleared_count = 0
		for bullet in bullets:
			if bullet.global_position.distance_to(global_position) <= explosion_radius:
				# Create small hit effect at bullet position
				create_hit_effect(bullet.global_position)
				bullet.queue_free()
				cleared_count += 1
		
		# If many bullets were cleared, play a special sound
		if cleared_count > 10:
			SoundManager.play_sound("delete_many")
	
	# Start cooldown
	can_fire = false
	$CooldownTimer.start(cooldown_time * cooldown_multiplier)
	
	# Disable collision after a short time
	await get_tree().create_timer(0.1).timeout
	$ExplosionArea.monitoring = false

func create_explosion_effect():
	# Create explosion sprite
	var explosion = Sprite2D.new()
	explosion.texture = load("res://assets/images/effects/explosion.png")
	explosion.global_position = global_position
	explosion.scale = Vector2(explosion_radius / 32.0, explosion_radius / 32.0)  # Adjust based on texture size
	explosion.modulate = Color(1.0, 0.3, 0.3, 0.7)  # Red tint
	get_tree().current_scene.add_child(explosion)
	
	# Animate explosion
	var tween = create_tween()
	tween.tween_property(explosion, "scale", explosion.scale * 1.5, 0.2)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(explosion, "queue_free"))

func create_hit_effect(pos):
	var hit = Sprite2D.new()
	hit.texture = load("res://assets/images/effects/hit.png")
	hit.global_position = pos
	hit.scale = Vector2(0.5, 0.5)
	hit.modulate = Color(1.0, 0.5, 0.5, 0.7)
	get_tree().current_scene.add_child(hit)
	
	var tween = create_tween()
	tween.tween_property(hit, "modulate:a", 0.0, 0.2)
	tween.tween_callback(Callable(hit, "queue_free"))

func _on_cooldown_timer_timeout():
	can_fire = true

func _on_explosion_area_area_entered(area):
	if area.is_in_group("enemy"):
		area.take_damage(explosion_damage * power_multiplier)
		create_hit_effect(area.global_position)

func set_power_multiplier(value: float):
	power_multiplier = value

func set_cooldown_multiplier(value: float):
	cooldown_multiplier = value