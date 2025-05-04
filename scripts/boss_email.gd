extends "res://scripts/email_enemy.gd"

signal phase_changed(phase)
signal boss_defeated

@export var phase_count: int = 3
@export var phase_health_thresholds: Array[float] = [0.7, 0.4, 0.1]
@export var phase_patterns: Array[PackedScene] = []
@export var intro_dialog: String = "I am the boss email! Prepare to be overwhelmed!"
@export var phase_dialogs: Array[String] = [
	"You think you can handle my first phase?",
	"Now witness my true power!",
	"This isn't even my final form!"
]
@export var defeat_dialog: String = "Impossible! How could you defeat me?"

var current_phase: int = 0
var dialog_shown: bool = false
var phase_transitions: Array[bool] = []
var original_bullet_pattern: PackedScene = null
var dialog_manager = null

func _ready():
	# Call parent _ready
	super._ready()
	
	# Set up boss-specific properties
	email_type = "boss"
	
	# Initialize phase transitions array
	for i in range(phase_count):
		phase_transitions.append(false)
	
	# Store original bullet pattern
	original_bullet_pattern = bullet_pattern
	
	# Find dialog manager
	await get_tree().create_timer(0.1).timeout
	var story_manager = get_tree().get_nodes_in_group("story_manager")
	if story_manager.size() > 0:
		dialog_manager = story_manager[0]
	
	# Show intro dialog
	if dialog_manager and not dialog_shown:
		dialog_manager.show_dialog("Boss", intro_dialog)
		dialog_shown = true

func _physics_process(delta):
	# Call parent _physics_process
	super._physics_process(delta)
	
	# Check for phase transitions
	check_phase_transitions()

func check_phase_transitions():
	var health_percent = current_health / health
	
	for i in range(phase_count):
		if health_percent <= phase_health_thresholds[i] and not phase_transitions[i]:
			transition_to_phase(i + 1)
			phase_transitions[i] = true
			break

func transition_to_phase(phase):
	current_phase = phase
	
	# Stop current pattern
	if pattern_instance:
		pattern_instance.queue_free()
		pattern_instance = null
	
	# Play transition animation
	$AnimationPlayer.play("phase_transition")
	
	# Show phase dialog
	if dialog_manager and phase - 1 < phase_dialogs.size():
		dialog_manager.show_dialog("Boss", phase_dialogs[phase - 1])
	
	# Play phase transition sound
	SoundManager.play_sound("boss_phase_" + str(phase))
	
	# Screen shake effect
	if get_tree().current_scene.has_method("screen_shake"):
		get_tree().current_scene.screen_shake(0.5, 5.0 + phase * 2.0)
	
	# Create phase transition visual effect
	create_phase_transition_effect(phase)
	
	# Wait for animation to finish
	await $AnimationPlayer.animation_finished
	
	# Change bullet pattern if we have one for this phase
	if phase - 1 < phase_patterns.size() and phase_patterns[phase - 1]:
		bullet_pattern = phase_patterns[phase - 1]
	else:
		bullet_pattern = original_bullet_pattern
	
	# Modify boss properties based on phase
	match phase:
		1:
			# Phase 1 - Standard boss
			speed *= 1.2
		2:
			# Phase 2 - Faster, more aggressive
			speed *= 1.5
			time_to_open *= 0.7
		3:
			# Phase 3 - Final form, very aggressive
			speed *= 2.0
			time_to_open *= 0.5
			# Add shield
			$Shield.visible = true
	
	# Activate new pattern
	is_open = false
	$OpenTimer.start(time_to_open * (1.0 - 0.2 * phase))  # Faster opening for later phases
	
	# Emit signal
	emit_signal("phase_changed", phase)

func create_phase_transition_effect(phase):
	# Create a dramatic visual effect for phase transition
	var effect_color = Color(1.0, 0.2, 0.2)  # Default red
	
	match phase:
		1:
			effect_color = Color(1.0, 0.5, 0.2)  # Orange
		2:
			effect_color = Color(0.2, 0.5, 1.0)  # Blue
		3:
			effect_color = Color(1.0, 0.2, 1.0)  # Purple
	
	# Create expanding ring effect
	for i in range(3):
		var ring = Sprite2D.new()
		ring.texture = load("res://assets/images/effects/ring.png")
		ring.global_position = global_position
		ring.modulate = effect_color
		ring.modulate.a = 0.7
		ring.scale = Vector2(0.5, 0.5)
		get_tree().current_scene.add_child(ring)
		
		var delay = i * 0.2
		var tween = create_tween()
		tween.set_delay(delay)
		tween.tween_property(ring, "scale", Vector2(5.0, 5.0), 0.5)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.5)
		tween.tween_callback(Callable(ring, "queue_free"))
	
	# Create flash effect
	var flash = ColorRect.new()
	flash.color = effect_color
	flash.color.a = 0.3
	flash.size = get_viewport_rect().size
	flash.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(Callable(flash, "queue_free"))

func die():
	# Stop any active patterns
	if pattern_instance:
		pattern_instance.queue_free()
		pattern_instance = null
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Play death animation
	$AnimationPlayer.play("boss_death")
	
	# Create dramatic death effect
	create_boss_death_effect()
	
	# Play boss death sound
	SoundManager.play_sound("boss_death")
	
	# Screen shake effect
	if get_tree().current_scene.has_method("screen_shake"):
		get_tree().current_scene.screen_shake(1.0, 10.0)
	
	# Show defeat dialog before dying
	if dialog_manager:
		dialog_manager.show_dialog("Boss", defeat_dialog)
		await dialog_manager.dialog_finished
	
	# Emit boss defeated signal
	emit_signal("boss_defeated")
	
	# Wait for animation to finish
	await $AnimationPlayer.animation_finished
	
	# Emit signal before freeing
	emit_signal("enemy_died", self)
	queue_free()

func create_boss_death_effect():
	# Create multiple explosion effects
	for i in range(10):
		var delay = i * 0.1
		get_tree().create_timer(delay).timeout.connect(func():
			var explosion = Sprite2D.new()
			explosion.texture = load("res://assets/images/effects/explosion.png")
			explosion.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			explosion.scale = Vector2(randf_range(0.8, 1.5), randf_range(0.8, 1.5))
			explosion.rotation = randf_range(0, 2 * PI)
			get_tree().current_scene.add_child(explosion)
			
			# Fade out explosion
			var tween = create_tween()
			tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
			tween.tween_callback(Callable(explosion, "queue_free"))
		)
	
	# Create final big explosion
	get_tree().create_timer(1.0).timeout.connect(func():
		var final_explosion = Sprite2D.new()
		final_explosion.texture = load("res://assets/images/effects/explosion.png")
		final_explosion.global_position = global_position
		final_explosion.scale = Vector2(3.0, 3.0)
		get_tree().current_scene.add_child(final_explosion)
		
		# Fade out explosion
		var tween = create_tween()
		tween.tween_property(final_explosion, "scale", Vector2(5.0, 5.0), 0.5)
		tween.parallel().tween_property(final_explosion, "modulate:a", 0.0, 0.5)
		tween.tween_callback(Callable(final_explosion, "queue_free"))
	)

# Override take_damage to add visual effects for boss
func take_damage(amount: float):
	# Call parent take_damage
	super.take_damage(amount)
	
	# Add extra visual feedback for boss damage
	if current_health > 0:
		# Create hit particles
		for i in range(3):
			var particle = Sprite2D.new()
			particle.texture = load("res://assets/images/effects/hit.png")
			particle.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			particle.scale = Vector2(0.5, 0.5)
			particle.modulate = Color(1.0, 0.3, 0.3, 0.7)
			get_tree().current_scene.add_child(particle)
			
			var tween = create_tween()
			tween.tween_property(particle, "scale", Vector2(0.1, 0.1), 0.3)
			tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)
			tween.tween_callback(Callable(particle, "queue_free"))