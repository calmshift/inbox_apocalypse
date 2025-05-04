extends Area2D

@export var speed: float = 200.0
@export var damage: float = 5.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.DOWN
var homing: bool = false
var tracking_strength: float = 0.2
var target = null
var acceleration: float = 0.0
var max_speed: float = 300.0
var rotation_speed: float = 0.0
var wobble_amount: float = 0.0
var wobble_speed: float = 0.0
var time_alive: float = 0.0

# Visual effects
var trail_enabled: bool = false
var bullet_type: String = "regular"  # regular, spam, urgent, boss, newsletter
var glow_enabled: bool = false
var pulse_enabled: bool = false
var pulse_speed: float = 2.0
var pulse_amount: float = 0.2

func _ready():
	add_to_group("enemy_projectile")
	$LifetimeTimer.wait_time = lifetime
	$LifetimeTimer.start()
	
	# Connect body entered signal
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Set up visual appearance based on bullet type
	match bullet_type:
		"spam":
			modulate = Color(0.5, 1.0, 0.5)  # Green
			trail_enabled = true
			wobble_amount = 0.5
			wobble_speed = 3.0
			if has_node("Sprite2D"):
				$Sprite2D.texture = load("res://assets/images/spam_projectile.png")
		"urgent":
			modulate = Color(1.0, 0.5, 0.5)  # Red
			speed *= 1.2
			acceleration = 50.0
			glow_enabled = true
			if has_node("Sprite2D"):
				$Sprite2D.texture = load("res://assets/images/urgent_projectile.png")
		"newsletter":
			modulate = Color(0.5, 0.7, 1.0)  # Blue
			rotation_speed = 2.0
			pulse_enabled = true
			if has_node("Sprite2D"):
				$Sprite2D.texture = load("res://assets/images/newsletter_projectile.png")
		"boss":
			modulate = Color(0.8, 0.5, 1.0)  # Purple
			trail_enabled = true
			glow_enabled = true
			damage *= 1.5
			if has_node("Sprite2D"):
				$Sprite2D.texture = load("res://assets/images/boss_projectile.png")

func _physics_process(delta):
	time_alive += delta
	
	# Homing behavior
	if homing and target and is_instance_valid(target):
		# Calculate direction to target
		var target_direction = (target.global_position - global_position).normalized()
		
		# Gradually turn towards the target
		direction = direction.lerp(target_direction, tracking_strength * delta)
		direction = direction.normalized()
	
	# Apply acceleration
	if acceleration > 0:
		speed = min(speed + acceleration * delta, max_speed)
	
	# Apply wobble
	if wobble_amount > 0:
		var wobble = sin(time_alive * wobble_speed) * wobble_amount
		direction = direction.rotated(wobble * delta)
	
	# Apply rotation
	if rotation_speed != 0:
		rotation += rotation_speed * delta
	
	# Move bullet
	position += direction * speed * delta
	
	# Visual effects
	if trail_enabled and randf() < 0.2:
		create_trail()
	
	if glow_enabled:
		update_glow()
	
	if pulse_enabled:
		update_pulse(delta)

func set_homing(enabled: bool, new_target = null):
	homing = enabled
	if new_target:
		target = new_target
	
	# Adjust appearance for homing bullets
	if homing:
		trail_enabled = true
		modulate = Color(1.0, 0.3, 0.0)  # Orange
		tracking_strength = 0.8  # Stronger tracking

func create_trail():
	# Create a trail effect
	var trail = Sprite2D.new()
	if has_node("Sprite2D"):
		trail.texture = $Sprite2D.texture
	trail.global_position = global_position
	trail.rotation = rotation
	trail.modulate = modulate
	trail.modulate.a = 0.5
	trail.scale = Vector2(0.7, 0.7)
	
	get_tree().current_scene.add_child(trail)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(trail, "queue_free"))

func update_glow():
	# Create a glow effect
	if randf() < 0.1:
		var glow = Sprite2D.new()
		if has_node("Sprite2D"):
			glow.texture = $Sprite2D.texture
		glow.global_position = global_position
		glow.rotation = rotation
		glow.modulate = modulate
		glow.modulate.a = 0.3
		glow.scale = Vector2(1.5, 1.5)
		
		get_tree().current_scene.add_child(glow)
		
		# Fade out and remove
		var tween = create_tween()
		tween.tween_property(glow, "scale", Vector2(2.5, 2.5), 0.3)
		tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(glow, "queue_free"))

func update_pulse(delta):
	# Pulse the bullet size
	if has_node("Sprite2D"):
		var pulse = sin(time_alive * pulse_speed) * pulse_amount + 1.0
		$Sprite2D.scale = Vector2(pulse, pulse)

func _on_lifetime_timer_timeout():
	# Create a fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(Callable(self, "queue_free"))

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Apply damage to player
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Create hit effect
		create_hit_effect()
		
		# Queue free
		queue_free()

func create_hit_effect():
	# Create a hit effect
	var hit = Sprite2D.new()
	hit.texture = load("res://assets/images/effects/hit.png")
	hit.global_position = global_position
	hit.modulate = modulate
	hit.scale = Vector2(0.5, 0.5)
	
	get_tree().current_scene.add_child(hit)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(hit, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(hit, "modulate:a", 0.0, 0.2)
	tween.tween_callback(Callable(hit, "queue_free"))