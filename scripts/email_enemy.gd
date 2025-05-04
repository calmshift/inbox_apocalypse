extends Area2D

signal enemy_died(enemy)

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

func _ready():
	add_to_group("enemy")
	current_health = health
	$OpenTimer.wait_time = time_to_open
	$OpenTimer.start()
	
	# Set up subject line
	$SubjectLabel.text = subject_line
	
	# Create path if move pattern is set
	if move_pattern:
		var path = Path2D.new()
		path.curve = move_pattern
		path_follow = PathFollow2D.new()
		path.add_child(path_follow)
		get_parent().add_child(path)
		path.global_position = global_position

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

func take_damage(amount: float):
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
	
	# Wait for animation to finish
	await $AnimationPlayer.animation_finished
	
	# Emit signal before freeing
	emit_signal("enemy_died", self)
	queue_free()

func _on_open_timer_timeout():
	is_open = true
	$AnimationPlayer.play("open")
	
	# Play sound effect
	SoundManager.play_sound("email_open")
	
	# Instantiate bullet pattern
	if bullet_pattern:
		pattern_instance = bullet_pattern.instantiate()
		pattern_instance.global_position = global_position
		get_tree().current_scene.add_child(pattern_instance)
		
		# Make pattern follow this enemy
		if pattern_instance.has_method("set_target"):
			pattern_instance.set_target(self)

func set_target_position(pos: Vector2):
	target_position = pos