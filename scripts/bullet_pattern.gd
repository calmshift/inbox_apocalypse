extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5
@export var bullet_speed: float = 200.0
@export var bullet_damage: float = 5.0
@export var pattern_duration: float = 10.0
@export var bullet_count: int = 8
@export var rotation_speed: float = 30.0  # Degrees per second

var target = null
var current_angle: float = 0.0

func _ready():
	$FireTimer.wait_time = fire_rate
	$FireTimer.start()
	
	$DurationTimer.wait_time = pattern_duration
	$DurationTimer.start()

func _process(delta):
	# Update position if following a target
	if target and is_instance_valid(target):
		global_position = target.global_position
	
	# Rotate the pattern
	current_angle += rotation_speed * delta

func set_target(new_target):
	target = new_target

func _on_fire_timer_timeout():
	fire_bullets()

func fire_bullets():
	var angle_step = 2 * PI / bullet_count
	
	for i in range(bullet_count):
		var angle = current_angle + (i * angle_step)
		var direction = Vector2(cos(angle), sin(angle)).normalized()
		
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = direction
		bullet.speed = bullet_speed
		bullet.damage = bullet_damage
		get_tree().current_scene.add_child(bullet)

func _on_duration_timer_timeout():
	queue_free()