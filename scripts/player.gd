extends CharacterBody2D

signal stress_changed(new_value)
signal player_died
signal combo_changed(combo_count)
signal power_up_activated(power_type)
signal control_jammed(jammed_controls)
signal control_unjammed

@export var speed: float = 300.0
@export var focus_speed_multiplier: float = 0.5
@export var max_stress: float = 100.0
@export var invincibility_time: float = 1.0
@export var stress_recovery_rate: float = 2.0  # Stress points recovered per second

var current_stress: float = 0.0
var is_focus_mode: bool = false
var is_invincible: bool = false
var screen_size: Vector2

# Tutorial tracking
var has_moved: bool = false
var has_used_focus: bool = false
var has_used_reply: bool = false
var has_used_forward: bool = false
var has_used_delete: bool = false

# Combo system
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 3.0  # Seconds before combo resets
var max_combo: int = 0

# Power-ups
var power_up_active: bool = false
var power_up_type: String = ""
var power_up_timer: float = 0.0
var power_up_duration: float = 10.0

# Control jamming
var jammed_controls: Array = []
var is_jammed: bool = false

# Visual effects
var trail_timer: float = 0.0
var trail_interval: float = 0.1

func _ready():
	screen_size = get_viewport_rect().size
	$InvincibilityTimer.wait_time = invincibility_time
	add_to_group("player")
	
	# Initialize UI elements
	emit_signal("stress_changed", current_stress / max_stress)
	emit_signal("combo_changed", combo_count)

func _physics_process(delta):
	# Get input direction
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	
	if direction.length() > 0:
		has_moved = true
	
	# Apply focus mode speed reduction if active
	var current_speed = speed
	if Input.is_action_pressed("focus_mode"):
		is_focus_mode = true
		has_used_focus = true
		current_speed *= focus_speed_multiplier
		$HitboxSprite.modulate = Color(0.5, 0.8, 1.0, 0.8)  # Blue tint in focus mode
	else:
		is_focus_mode = false
		$HitboxSprite.modulate = Color(1.0, 1.0, 1.0, 0.5)  # Normal color
	
	# Set velocity and move
	velocity = direction * current_speed
	move_and_slide()
	
	# Clamp position to screen boundaries
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
	# Handle combo timer
	if combo_count > 0:
		combo_timer += delta
		if combo_timer >= combo_timeout:
			reset_combo()
	
	# Handle power-up timer
	if power_up_active:
		power_up_timer += delta
		if power_up_timer >= power_up_duration:
			deactivate_power_up()
	
	# Gradually recover stress when not at max
	if current_stress > 0:
		current_stress = max(0, current_stress - stress_recovery_rate * delta)
		emit_signal("stress_changed", current_stress / max_stress)
	
	# Create movement trail effect
	trail_timer += delta
	if trail_timer >= trail_interval and (velocity.length() > 50 or is_focus_mode):
		create_trail()
		trail_timer = 0

func create_trail():
	var trail = Sprite2D.new()
	trail.texture = $Sprite2D.texture
	trail.global_position = global_position
	trail.scale = scale * 0.9
	
	if is_focus_mode:
		trail.modulate = Color(0.5, 0.8, 1.0, 0.3)
	else:
		trail.modulate = Color(1.0, 1.0, 1.0, 0.2)
	
	get_tree().current_scene.add_child(trail)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(trail, "queue_free"))

func take_damage(amount: float):
	if is_invincible:
		return
	
	# Reduce damage if power-up is active
	if power_up_active and power_up_type == "shield":
		amount *= 0.5
		
	current_stress += amount
	emit_signal("stress_changed", current_stress / max_stress)
	
	# Reset combo when hit
	reset_combo()
	
	# Play sound effect
	SoundManager.play_sound("player_hit")
	
	# Visual feedback
	$AnimationPlayer.play("damage_flash")
	
	# Start invincibility
	is_invincible = true
	$InvincibilityTimer.start()
	
	# Check for death
	if current_stress >= max_stress:
		die()

func die():
	set_physics_process(false)
	$AnimationPlayer.play("death")
	
	# Create explosion effect
	var explosion = Sprite2D.new()
	explosion.texture = load("res://assets/images/effects/explosion.png")
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
	# Fade out explosion
	var tween = create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(explosion, "queue_free"))
	
	await $AnimationPlayer.animation_finished
	emit_signal("player_died")

func _on_invincibility_timer_timeout():
	is_invincible = false

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy_projectile"):
		take_damage(area.damage)
		area.queue_free()
	elif area.is_in_group("enemy"):
		take_damage(area.contact_damage)
	elif area.is_in_group("power_up"):
		if area.has_method("collect"):
			area.collect(self)
		else:
			collect_power_up(area.power_type)
			area.queue_free()
	elif area.is_in_group("keyboard_jam"):
		if area.has_method("jam_keyboard"):
			area.jam_keyboard(self)
		else:
			jam_controls(["reply", "forward", "delete"])

func use_reply():
	if $ReplyAttack.can_attack() and not is_control_jammed("reply"):
		$ReplyAttack.attack()
		has_used_reply = true
		increment_combo()

func use_forward():
	if $ForwardAttack.can_attack() and not is_control_jammed("forward"):
		$ForwardAttack.attack()
		has_used_forward = true
		increment_combo()

func use_delete():
	if $DeleteAttack.can_attack() and not is_control_jammed("delete"):
		$DeleteAttack.attack()
		has_used_delete = true
		increment_combo()

func increment_combo():
	combo_count += 1
	combo_timer = 0.0
	
	if combo_count > max_combo:
		max_combo = combo_count
	
	emit_signal("combo_changed", combo_count)
	
	# Apply combo effects
	if combo_count >= 10:
		# Every 10 combos, reduce stress
		if combo_count % 10 == 0:
			current_stress = max(0, current_stress - 5.0)
			emit_signal("stress_changed", current_stress / max_stress)
			
			# Visual effect for stress reduction
			var effect = Sprite2D.new()
			effect.texture = load("res://assets/images/effects/hit.png")
			effect.global_position = global_position
			effect.modulate = Color(0.2, 1.0, 0.2)
			get_tree().current_scene.add_child(effect)
			
			var tween = create_tween()
			tween.tween_property(effect, "scale", Vector2(2, 2), 0.5)
			tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.5)
			tween.tween_callback(Callable(effect, "queue_free"))
	
	# Increase attack power based on combo
	var power_multiplier = 1.0 + min(combo_count * 0.05, 1.0)  # Max 2x power at 20+ combo
	$ReplyAttack.set_power_multiplier(power_multiplier)
	$ForwardAttack.set_power_multiplier(power_multiplier)
	$DeleteAttack.set_power_multiplier(power_multiplier)

func reset_combo():
	combo_count = 0
	combo_timer = 0.0
	emit_signal("combo_changed", combo_count)
	
	# Reset attack power
	$ReplyAttack.set_power_multiplier(1.0)
	$ForwardAttack.set_power_multiplier(1.0)
	$DeleteAttack.set_power_multiplier(1.0)

func collect_power_up(type):
	# Deactivate current power-up if one is active
	if power_up_active:
		deactivate_power_up()
	
	power_up_type = type
	power_up_active = true
	power_up_timer = 0.0
	
	# Apply power-up effect
	match type:
		"rapid_fire":
			$ReplyAttack.set_cooldown_multiplier(0.5)
			$ForwardAttack.set_cooldown_multiplier(0.5)
			$DeleteAttack.set_cooldown_multiplier(0.5)
		"shield":
			# Shield effect is handled in take_damage
			pass
		"multi_shot":
			$ReplyAttack.set_projectile_count(3)
			$ForwardAttack.set_projectile_count(5)
		"stress_relief":
			current_stress = max(0, current_stress - 30.0)
			emit_signal("stress_changed", current_stress / max_stress)
	
	# Visual effect for power-up
	var effect = Sprite2D.new()
	effect.texture = load("res://assets/images/effects/hit.png")
	effect.global_position = global_position
	effect.modulate = Color(1.0, 1.0, 0.2)
	get_tree().current_scene.add_child(effect)
	
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(3, 3), 0.5)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(effect, "queue_free"))
	
	# Emit signal
	emit_signal("power_up_activated", type)
	
	# Play sound effect
	SoundManager.play_sound("power_up")

func deactivate_power_up():
	# Remove power-up effect
	match power_up_type:
		"rapid_fire":
			$ReplyAttack.set_cooldown_multiplier(1.0)
			$ForwardAttack.set_cooldown_multiplier(1.0)
			$DeleteAttack.set_cooldown_multiplier(1.0)
		"shield":
			# Shield effect is handled in take_damage
			pass
		"multi_shot":
			$ReplyAttack.set_projectile_count(1)
			$ForwardAttack.set_projectile_count(3)
	
	power_up_active = false
	power_up_type = ""
	
	# Play sound effect
	SoundManager.play_sound("power_up_end")

func jam_controls(controls_to_jam: Array):
	jammed_controls = controls_to_jam
	is_jammed = true
	
	# Visual effect for jammed controls
	$AnimationPlayer.play("jam_controls")
	
	# Play sound effect
	SoundManager.play_sound("keyboard_jam")
	
	# Emit signal
	emit_signal("control_jammed", jammed_controls)

func unjam_controls():
	jammed_controls = []
	is_jammed = false
	
	# Visual effect for unjammed controls
	$AnimationPlayer.play("unjam_controls")
	
	# Play sound effect
	SoundManager.play_sound("keyboard_unjam")
	
	# Emit signal
	emit_signal("control_unjammed")

func is_control_jammed(control: String) -> bool:
	return is_jammed and control in jammed_controls

func activate_power_up(type: String, duration: float):
	collect_power_up(type)
	power_up_duration = duration