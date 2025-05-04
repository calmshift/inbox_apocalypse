extends Node

# This script handles special effects for the game

# Screen shake effect
static func screen_shake(node, duration: float, intensity: float):
	if node.has_node("Camera2D"):
		var camera = node.get_node("Camera2D")
		var original_pos = camera.position
		
		for i in range(int(duration * 20)):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			camera.position = original_pos + offset
			await node.get_tree().create_timer(0.05).timeout
		
		camera.position = original_pos

# Hit stop effect (time freeze)
static func hit_stop(node, duration: float):
	var original_time_scale = Engine.time_scale
	Engine.time_scale = 0.05
	await node.get_tree().create_timer(duration * 0.05).timeout
	Engine.time_scale = original_time_scale

# Flash effect
static func flash(node, color: Color, duration: float):
	var flash_rect = ColorRect.new()
	flash_rect.color = color
	flash_rect.size = node.get_viewport_rect().size
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	node.add_child(flash_rect)
	
	var tween = node.create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, duration)
	tween.tween_callback(Callable(flash_rect, "queue_free"))

# Bullet storm effect
static func bullet_storm(node, bullet_count: int, duration: float):
	var bullet_scene = load("res://scenes/enemy_bullet.tscn")
	var screen_size = node.get_viewport_rect().size
	
	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		var spawn_pos = Vector2(randf_range(0, screen_size.x), -50)
		var target_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + 50)
		
		bullet.position = spawn_pos
		bullet.velocity = (target_pos - spawn_pos).normalized() * randf_range(100, 300)
		
		node.add_child(bullet)
		
		await node.get_tree().create_timer(duration / bullet_count).timeout

# Power surge effect
static func power_surge(node, duration: float, intensity: float):
	# Slow down all bullets
	var bullets = node.get_tree().get_nodes_in_group("enemy_projectile")
	var original_speeds = []
	
	for bullet in bullets:
		original_speeds.append(bullet.velocity.length())
		bullet.velocity = bullet.velocity.normalized() * 20.0
	
	# Screen effects
	flash(node, Color(0.2, 0.8, 1.0, 0.3), 0.5)
	screen_shake(node, 0.5, intensity * 2.0)
	
	# Wait for duration
	await node.get_tree().create_timer(duration).timeout
	
	# Speed up all bullets
	bullets = node.get_tree().get_nodes_in_group("enemy_projectile")
	for i in range(min(bullets.size(), original_speeds.size())):
		bullets[i].velocity = bullets[i].velocity.normalized() * (original_speeds[i] * 1.5)
	
	# Final effects
	flash(node, Color(1.0, 0.2, 0.2, 0.3), 0.5)
	screen_shake(node, 0.5, intensity * 3.0)

# Screen glitch effect
static func screen_glitch(node, duration: float, intensity: float):
	var glitch_shader = load("res://shaders/glitch.gdshader")
	var screen_rect = ColorRect.new()
	screen_rect.material = ShaderMaterial.new()
	screen_rect.material.shader = glitch_shader
	screen_rect.size = node.get_viewport_rect().size
	screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	node.add_child(screen_rect)
	
	# Set shader parameters
	screen_rect.material.set_shader_parameter("intensity", intensity)
	
	# Animate glitch effect
	for i in range(int(duration * 10)):
		screen_rect.material.set_shader_parameter("intensity", randf_range(0.1, intensity))
		await node.get_tree().create_timer(0.1).timeout
	
	# Fade out and remove
	var tween = node.create_tween()
	tween.tween_property(screen_rect.material, "shader_parameter/intensity", 0.0, 0.5)
	tween.tween_callback(Callable(screen_rect, "queue_free"))

# Time slow effect
static func time_slow(node, duration: float, slow_factor: float):
	var original_time_scale = Engine.time_scale
	
	# Slow down time
	Engine.time_scale = slow_factor
	
	# Visual effect
	flash(node, Color(0.5, 0.5, 1.0, 0.2), 0.5)
	
	# Wait for duration
	await node.get_tree().create_timer(duration * slow_factor).timeout
	
	# Return to normal speed
	Engine.time_scale = original_time_scale
	
	# Visual effect for returning to normal
	flash(node, Color(1.0, 1.0, 1.0, 0.2), 0.3)

# Attack animation effect
static func attack_animation(node, attack_type: String, origin_pos: Vector2, direction: Vector2):
	var animation_scene = null
	
	match attack_type:
		"reply":
			animation_scene = load("res://scenes/effects/reply_effect.tscn")
		"forward":
			animation_scene = load("res://scenes/effects/forward_effect.tscn")
		"delete":
			animation_scene = load("res://scenes/effects/delete_effect.tscn")
	
	if animation_scene:
		var animation = animation_scene.instantiate()
		animation.position = origin_pos
		animation.rotation = direction.angle()
		
		node.add_child(animation)
		
		# Animation will auto-delete after playing
		return animation
	
	return null