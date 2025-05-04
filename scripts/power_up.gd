extends Area2D

signal collected(power_up)

@export_enum("rapid_fire", "shield", "multi_shot", "stress_relief") var power_type: String = "rapid_fire"
@export var lifetime: float = 10.0
@export var move_speed: float = 50.0
@export var wobble_amount: float = 10.0
@export var wobble_speed: float = 3.0

var initial_position: Vector2
var time_alive: float = 0.0

func _ready():
	add_to_group("power_up")
	initial_position = global_position
	
	# Set up appearance based on power type
	match power_type:
		"rapid_fire":
			$Sprite2D.modulate = Color(1.0, 0.5, 0.2)  # Orange
		"shield":
			$Sprite2D.modulate = Color(0.2, 0.7, 1.0)  # Blue
		"multi_shot":
			$Sprite2D.modulate = Color(0.8, 0.2, 1.0)  # Purple
		"stress_relief":
			$Sprite2D.modulate = Color(0.2, 1.0, 0.5)  # Green
	
	# Start lifetime timer
	$LifetimeTimer.wait_time = lifetime
	$LifetimeTimer.start()
	
	# Start blinking when about to expire
	var blink_time = lifetime * 0.7
	get_tree().create_timer(blink_time).timeout.connect(start_blinking)

func _physics_process(delta):
	time_alive += delta
	
	# Wobble movement
	var wobble_offset = sin(time_alive * wobble_speed) * wobble_amount
	global_position.x = initial_position.x + wobble_offset
	
	# Slow downward movement
	global_position.y += move_speed * delta

func start_blinking():
	# Create blinking effect when power-up is about to expire
	var tween = create_tween()
	tween.set_loops(10)  # Blink 10 times
	tween.tween_property($Sprite2D, "modulate:a", 0.2, 0.2)
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.2)

func _on_lifetime_timer_timeout():
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(self, "queue_free"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("collected", self)
		
		# Create collection effect
		var effect = Sprite2D.new()
		effect.texture = $Sprite2D.texture
		effect.global_position = global_position
		effect.modulate = $Sprite2D.modulate
		get_tree().current_scene.add_child(effect)
		
		# Animate effect
		var tween = create_tween()
		tween.tween_property(effect, "scale", Vector2(2, 2), 0.3)
		tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(effect, "queue_free"))
		
		# Remove power-up
		queue_free()