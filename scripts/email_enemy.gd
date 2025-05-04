extends Area2D

signal enemy_died(enemy)

@export_enum("regular", "urgent", "spam", "newsletter", "boss") var email_type: String = "regular"
@export var health: float = 30.0
@export var speed: float = 100.0
@export var contact_damage: float = 10.0
@export var points: int = 100
@export var subject_line: String = "Important Meeting"
@export var sender: String = "boss@company.com"
@export var time_to_open: float = 5.0
@export var bullet_pattern: PackedScene
@export var move_pattern: Curve2D

var is_open: bool = false
var target_position: Vector2
var current_health: float
var path_follow: PathFollow2D
var pattern_instance = null
var bullet_type: String = "regular"
var special_ability_active: bool = false
var special_ability_timer: float = 0.0

# Visual effects
var wobble_amount: float = 0.0
var original_scale: Vector2

func _ready():
	add_to_group("enemy")
	current_health = health
	$OpenTimer.wait_time = time_to_open
	$OpenTimer.start()
	original_scale = scale
	
	# Set up subject line
	$SubjectLabel.text = subject_line
	
	# Configure based on email type
	configure_email_type()
	
	# Create path if move pattern is set
	if move_pattern:
		var path = Path2D.new()
		path.curve = move_pattern
		path_follow = PathFollow2D.new()
		path.add_child(path_follow)
		get_parent().add_child(path)
		path.global_position = global_position

func configure_email_type():
	match email_type:
		"regular":
			# Standard email
			$Sprite2D.texture = load("res://assets/images/email_regular.png")
			bullet_type = "regular"
			
		"urgent":
			# Urgent email - faster, more damage, red color
			$Sprite2D.texture = load("res://assets/images/email_urgent.png")
			bullet_type = "urgent"
			speed *= 1.2
			contact_damage *= 1.5
			time_to_open *= 0.8
			$OpenTimer.wait_time = time_to_open
			$SubjectLabel.modulate = Color(1.0, 0.5, 0.5)
			
		"spam":
			# Spam email - more bullets, green color
			$Sprite2D.texture = load("res://assets/images/email_spam.png")
			bullet_type = "spam"
			health *= 0.8
			current_health = health
			points *= 1.5
			wobble_amount = 0.1
			$SubjectLabel.modulate = Color(0.5, 1.0, 0.5)
			
		"newsletter":
			# Newsletter email - slow but spawns multiple patterns
			$Sprite2D.texture = load("res://assets/images/email_newsletter.png")
			bullet_type = "regular"
			speed *= 0.8
			health *= 1.2
			current_health = health
			$SubjectLabel.modulate = Color(0.5, 0.5, 1.0)
			
		"boss":
			# Boss email - tough, complex patterns, purple color
			$Sprite2D.texture = load("res://assets/images/email_boss.png")
			bullet_type = "boss"
			health *= 2.0
			current_health = health
			speed *= 0.7
			contact_damage *= 2.0
			points *= 3.0
			$SubjectLabel.modulate = Color(0.8, 0.5, 1.0)
			wobble_amount = 0.05
			
			# Make boss emails larger
			scale *= 1.3

func _physics_process(delta):
	if path_follow:
		# Follow the path
		path_follow.progress += speed * delta
		global_position = path_follow.global_position
	else:
		# Simple movement toward target
		var direction = (target_position - global_position).normalized()
		global_position += direction * speed * delta
		
		# Stop when close to target
		if global_position.distance_to(target_position) < 10:
			speed = 0
	
	# Apply wobble effect if needed
	if wobble_amount > 0:
		scale = original_scale + Vector2(
			sin(Time.get_ticks_msec() * 0.01) * wobble_amount,
			cos(Time.get_ticks_msec() * 0.01) * wobble_amount
		)
	
	# Handle special abilities
	if special_ability_active:
		special_ability_timer += delta
		handle_special_ability(delta)

func handle_special_ability(delta):
	match email_type:
		"spam":
			# Spam emails occasionally spawn extra bullets randomly
			if special_ability_timer >= 1.0:
				special_ability_timer = 0.0
				if randf() < 0.3:  # 30% chance each second
					spawn_random_bullet()
		
		"newsletter":
			# Newsletters periodically spawn small bullet bursts
			if special_ability_timer >= 2.0:
				special_ability_timer = 0.0
				spawn_newsletter_burst()
		
		"boss":
			# Boss emails have a shield that periodically activates
			if special_ability_timer >= 3.0:
				special_ability_timer = 0.0
				toggle_boss_shield()

func spawn_random_bullet():
	var bullet = preload("res://scenes/enemy_bullet.tscn").instantiate()
	bullet.global_position = global_position
	bullet.direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	bullet.bullet_type = "spam"
	get_tree().current_scene.add_child(bullet)
	
	# Play sound effect
	SoundManager.play_sound("email_open", -10.0)  # Quieter than normal

func spawn_newsletter_burst():
	for i in range(4):
		var bullet = preload("res://scenes/enemy_bullet.tscn").instantiate()
		bullet.global_position = global_position
		var angle = i * (2 * PI / 4)
		bullet.direction = Vector2(cos(angle), sin(angle))
		get_tree().current_scene.add_child(bullet)
	
	# Play sound effect
	SoundManager.play_sound("email_open", -5.0)

func toggle_boss_shield():
	# Visual effect for shield
	var shield_active = !$Shield.visible
	$Shield.visible = shield_active
	
	# When shield is active, take less damage
	if shield_active:
		# Play shield activation sound
		SoundManager.play_sound("boss_shield")
		
		# Create shield visual effect
		var tween = create_tween()
		tween.tween_property($Shield, "modulate:a", 0.7, 0.3)
		
		# Shield deactivates after 1.5 seconds
		await get_tree().create_timer(1.5).timeout
		
		# Deactivate shield
		tween = create_tween()
		tween.tween_property($Shield, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(self, "toggle_boss_shield"))

func take_damage(amount: float):
	# Reduce damage if boss shield is active
	if email_type == "boss" and $Shield.visible:
		amount *= 0.2
	
	current_health -= amount
	
	# Visual feedback
	$AnimationPlayer.play("hit")
	
	# Play sound effect
	SoundManager.play_sound("enemy_hit")
	
	if current_health <= 0:
		die()

func die():
	# Stop any active patterns
	if pattern_instance:
		pattern_instance.queue_free()
	
	# Play death animation
	$AnimationPlayer.play("death")
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Create explosion effect
	var explosion = Sprite2D.new()
	explosion.texture = load("res://assets/images/effects/explosion.png")
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
	# Fade out explosion
	var tween = create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(explosion, "queue_free"))
	
	# Wait for animation to finish
	await $AnimationPlayer.animation_finished
	
	# Emit signal before freeing
	emit_signal("enemy_died", self)
	queue_free()

func _on_open_timer_timeout():
	is_open = true
	$AnimationPlayer.play("open")
	
	# Play sound effect based on email type
	match email_type:
		"urgent":
			SoundManager.play_sound("email_open", 5.0)  # Louder for urgent
		"spam":
			SoundManager.play_sound("email_open", 0.0)  # Normal volume
		"newsletter":
			SoundManager.play_sound("email_open", -5.0)  # Quieter for newsletter
		"boss":
			SoundManager.play_sound("boss_phase_1")  # Special sound for boss
		_:
			SoundManager.play_sound("email_open")
	
	# Instantiate bullet pattern
	if bullet_pattern:
		pattern_instance = bullet_pattern.instantiate()
		pattern_instance.global_position = global_position
		
		# Configure pattern based on email type
		match email_type:
			"urgent":
				if pattern_instance.has("bullet_speed"):
					pattern_instance.bullet_speed *= 1.3
				if pattern_instance.has("bullet_color"):
					pattern_instance.bullet_color = Color(1.0, 0.3, 0.3)
			"spam":
				if pattern_instance.has("bullet_count"):
					pattern_instance.bullet_count *= 1.5
				if pattern_instance.has("bullet_spread"):
					pattern_instance.bullet_spread *= 2.0
				if pattern_instance.has("bullet_color"):
					pattern_instance.bullet_color = Color(0.3, 1.0, 0.3)
			"newsletter":
				if pattern_instance.has("bullet_scale"):
					pattern_instance.bullet_scale *= 1.2
				if pattern_instance.has("bullet_color"):
					pattern_instance.bullet_color = Color(0.3, 0.5, 1.0)
			"boss":
				if pattern_instance.has("bullet_speed"):
					pattern_instance.bullet_speed *= 1.2
				if pattern_instance.has("bullet_count"):
					pattern_instance.bullet_count *= 1.5
				if pattern_instance.has("bullet_scale"):
					pattern_instance.bullet_scale *= 1.3
				if pattern_instance.has("bullet_color"):
					pattern_instance.bullet_color = Color(0.8, 0.3, 1.0)
		
		# Add to scene
		get_tree().current_scene.add_child(pattern_instance)
		
		# Make pattern follow this enemy
		if pattern_instance.has_method("set_target"):
			pattern_instance.set_target(self)
		
		# Configure bullet pattern based on email type
		if pattern_instance.has_method("set_bullet_type"):
			pattern_instance.set_bullet_type(bullet_type)
		
		# Start the pattern
		if pattern_instance.has_method("start_pattern"):
			pattern_instance.start_pattern()
	
	# Activate special ability
	special_ability_active = true
	
	# Screen shake for urgent and boss emails
	if email_type == "urgent" or email_type == "boss":
		if get_tree().current_scene.has_method("screen_shake"):
			var intensity = 3.0 if email_type == "urgent" else 5.0
			get_tree().current_scene.screen_shake(0.3, intensity)

func set_target_position(pos: Vector2):
	target_position = pos