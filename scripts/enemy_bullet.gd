extends Area2D

@export var speed: float = 200.0
@export var damage: float = 5.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.DOWN

func _ready():
	add_to_group("enemy_projectile")
	$LifetimeTimer.wait_time = lifetime
	$LifetimeTimer.start()

func _physics_process(delta):
	position += direction * speed * delta

func _on_lifetime_timer_timeout():
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()