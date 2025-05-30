extends Node

signal score_changed(new_score)
signal wave_changed(new_wave, wave_name)
signal combo_changed(combo_count)
signal time_changed(time_remaining)
signal game_over(final_score)
signal level_completed(final_score)
signal boss_health_changed(percent)

@export var player_scene: PackedScene
@export var level_data: Resource
@export var start_wave: int = 1
@export var tutorial_mode: bool = false
@export var keyboard_jam_scene: PackedScene
@export var power_up_scene: PackedScene

# Override level_data with the one from Global
func _enter_tree():
	if Global.current_level:
		level_data = load(Global.current_level)

var current_score: int = 0
var current_wave: int = 0
var player = null
var wave_enemies = []
var is_wave_active: bool = false
var is_level_complete: bool = false
var is_game_over: bool = false
var is_paused: bool = false
var is_tutorial_complete: bool = false
var is_intro_playing: bool = true
var is_boss_active: bool = false
var boss_enemy = null
var max_combo: int = 0
var time_remaining: float = 0
var level_start_time: float = 0
var keyboard_jam_timer: float = 0
var power_up_timer: float = 0
var story_manager = null
var tutorial_manager = null
var special_events = []
var current_special_event = null

func _ready():
	# Find story manager
	var story_nodes = get_tree().get_nodes_in_group("story_manager")
	if story_nodes.size() > 0:
		story_manager = story_nodes[0]
	
	# Set up level
	if level_data:
		time_remaining = level_data.time_limit
		
		# Set player stress recovery rate
		if player and level_data.stress_recovery_rate > 0:
			player.stress_recovery_rate = level_data.stress_recovery_rate
		
		# Load special events
		if level_data.has("special_events"):
			special_events = level_data.special_events.duplicate()
	
	# Check if tutorial mode
	if tutorial_mode:
		# Find or create tutorial manager
		if has_node("TutorialManager"):
			tutorial_manager = get_node("TutorialManager")
			tutorial_manager.connect("tutorial_completed", Callable(self, "_on_tutorial_completed"))
		else:
			var tutorial_scene = load("res://scenes/tutorial_manager.tscn")
			tutorial_manager = tutorial_scene.instantiate()
			tutorial_manager.connect("tutorial_completed", Callable(self, "_on_tutorial_completed"))
			add_child(tutorial_manager)
	else:
		# Start intro sequence if not in tutorial mode
		if story_manager and level_data and level_data.intro_dialog.size() > 0:
			story_manager.show_dialog_sequence(level_data.intro_dialog)
			story_manager.connect("dialog_sequence_finished", Callable(self, "_on_intro_dialog_finished"))
		else:
			is_intro_playing = false
			setup_game()

func _process(delta):
	# Update timers
	if not is_paused and not is_game_over and not is_level_complete and not is_intro_playing and is_tutorial_complete:
		# Update level timer
		if time_remaining > 0:
			time_remaining -= delta
			emit_signal("time_changed", time_remaining)
			
			# Time's up
			if time_remaining <= 0:
				time_remaining = 0
				_on_player_died()  # Game over when time runs out
		
		# Update keyboard jam timer
		if level_data and level_data.keyboard_jam_chance > 0:
			keyboard_jam_timer += delta
			if keyboard_jam_timer >= 10.0:  # Check every 10 seconds
				keyboard_jam_timer = 0
				if randf() < level_data.keyboard_jam_chance:
					spawn_keyboard_jam()
		
		# Update power-up timer
		power_up_timer += delta
		if power_up_timer >= 15.0:  # Check every 15 seconds
			power_up_timer = 0
			if level_data and randf() < level_data.power_up_chance:
				spawn_power_up()
		
		# Check for special events
		check_special_events(delta)

func check_special_events(delta):
	if special_events.size() > 0 and not current_special_event:
		var elapsed_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
		
		for i in range(special_events.size()):
			var event = special_events[i]
			if event.has("trigger_time") and elapsed_time >= event.trigger_time:
				# Trigger this event
				current_special_event = event
				special_events.remove_at(i)
				
				# Execute the event
				execute_special_event(current_special_event)
				break

func execute_special_event(event):
	match event.event_type:
		"screen_shake":
			screen_shake(event.duration, event.intensity)
			await get_tree().create_timer(event.duration).timeout
			current_special_event = null
		
		"bullet_storm":
			load("res://scripts/special_effects.gd").bullet_storm(self, event.bullet_count, event.duration)
			await get_tree().create_timer(event.duration).timeout
			current_special_event = null
		
		"power_surge":
			load("res://scripts/special_effects.gd").power_surge(self, event.duration, event.intensity)
			await get_tree().create_timer(event.duration).timeout
			current_special_event = null
		
		"time_slow":
			load("res://scripts/special_effects.gd").time_slow(self, event.duration, event.intensity)
			await get_tree().create_timer(event.duration).timeout
			current_special_event = null
		
		"screen_glitch":
			load("res://scripts/special_effects.gd").screen_glitch(self, event.duration, event.intensity)
			await get_tree().create_timer(event.duration).timeout
			current_special_event = null
		
		_:
			# Unknown event type, just clear it
			current_special_event = null

func _on_intro_dialog_finished():
	is_intro_playing = false
	setup_game()

func _on_tutorial_completed():
	is_tutorial_complete = true
	setup_game()

func start_game_after_tutorial():
	is_tutorial_complete = true
	setup_game()

func setup_game():
	if is_game_over or is_level_complete:
		return
		
	current_score = 0
	current_wave = start_wave - 1
	is_game_over = false
	is_level_complete = false
	level_start_time = Time.get_ticks_msec() / 1000.0
	
	# Start gameplay music
	if level_data and level_data.music_track:
		SoundManager.play_music(level_data.music_track)
	else:
		SoundManager.play_music("gameplay")
	
	# Spawn player if not already spawned
	if not player:
		spawn_player()
	
	# Start first wave
	start_next_wave()

func spawn_player():
	player = player_scene.instantiate()
	player.position = $PlayerSpawnPosition.position
	player.connect("player_died", Callable(self, "_on_player_died"))
	player.connect("combo_changed", Callable(self, "_on_combo_changed"))
	add_child(player)

func _on_combo_changed(combo_count):
	emit_signal("combo_changed", combo_count)
	if combo_count > max_combo:
		max_combo = combo_count

func start_next_wave():
	if is_game_over or is_level_complete or is_intro_playing or not is_tutorial_complete:
		return
		
	current_wave += 1
	
	# Check if we've completed all waves
	if level_data and current_wave > level_data.total_waves:
		# Check if this is a boss level
		if level_data.boss_level and not is_boss_active:
			start_boss_fight()
		else:
			complete_level()
		return
		
	# Get wave data
	var wave = level_data.get_wave(current_wave)
	if not wave:
		complete_level()
		return
		
	is_wave_active = true
	wave_enemies = []
	
	# Show wave name
	emit_signal("wave_changed", current_wave, wave.wave_name)
	
	# Show wave dialog if available
	if story_manager and wave.wave_dialog and not wave.wave_dialog.is_empty():
		story_manager.show_dialog(wave.wave_dialog.name, wave.wave_dialog.text)
	
	# Spawn enemies
	spawn_wave_enemies(wave)

func spawn_wave_enemies(wave):
	var enemy_scene = load("res://scenes/email_enemy.tscn")
	var spawn_count = wave.enemy_count
	var spawn_interval = wave.enemy_spawn_interval
	
	# If spawn all at once, set interval to 0
	if wave.spawn_all_at_once:
		spawn_interval = 0
	
	# Check if wave has predefined enemies
	if wave.enemies.size() > 0:
		# Spawn predefined enemies
		for i in range(wave.enemies.size()):
			if is_game_over or is_level_complete:
				break
				
			var enemy_data = wave.enemies[i]
			
			# Wait between spawns
			if enemy_data.has("delay") and enemy_data.delay > 0 and i > 0:
				await get_tree().create_timer(enemy_data.delay).timeout
			
			# Create enemy
			var enemy = enemy_scene.instantiate()
			
			# Set enemy properties from data
			if enemy_data.has("sender"):
				enemy.sender = enemy_data.sender
			
			if enemy_data.has("subject_line"):
				enemy.subject_line = enemy_data.subject_line
			
			if enemy_data.has("health"):
				enemy.health = enemy_data.health
				enemy.current_health = enemy_data.health
			
			if enemy_data.has("speed"):
				enemy.speed = enemy_data.speed
			
			if enemy_data.has("time_to_open"):
				enemy.time_to_open = enemy_data.time_to_open
			
			if enemy_data.has("bullet_pattern") and enemy_data.bullet_pattern:
				enemy.bullet_pattern = enemy_data.bullet_pattern
			
			# Set spawn position
			var spawn_pos = get_spawn_position()
			if enemy_data.has("move_pattern"):
				# Use first point of curve as spawn position
				var curve = enemy_data.move_pattern
				if curve and curve.get_point_count() > 0:
					spawn_pos = curve.get_point_position(0)
				enemy.move_pattern = curve
			enemy.global_position = spawn_pos
			
			# Set target position
			var target_pos = Vector2(randf_range(100, get_viewport().get_visible_rect().size.x - 100), 150)
			if enemy_data.has("target_position"):
				target_pos = enemy_data.target_position
			enemy.set_target_position(target_pos)
			
			# Connect signals
			enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))
			
			# Add to scene
			add_child(enemy)
			wave_enemies.append(enemy)
	else:
		# Spawn random enemies based on wave properties
		for i in range(spawn_count):
			if is_game_over or is_level_complete:
				break
				
			# Wait between spawns
			if spawn_interval > 0 and i > 0:
				await get_tree().create_timer(spawn_interval).timeout
			
			# Create enemy
			var enemy = enemy_scene.instantiate()
			
			# Set enemy type
			var enemy_type = "regular"
			if wave.enemy_types.size() > 0:
				enemy_type = wave.enemy_types[randi() % wave.enemy_types.size()]
			enemy.email_type = enemy_type
			
			# Set spawn position
			var spawn_pos = get_spawn_position()
			if wave.spawn_positions.size() > i:
				spawn_pos = wave.spawn_positions[i]
			enemy.global_position = spawn_pos
			
			# Set target position
			var target_pos = Vector2(randf_range(100, get_viewport().get_visible_rect().size.x - 100), 150)
			if wave.target_positions.size() > i:
				target_pos = wave.target_positions[i]
			enemy.set_target_position(target_pos)
			
			# Set subject line based on type
			enemy.subject_line = load("res://scripts/email_subjects.gd").get_subject(enemy_type)
			
			# Set bullet pattern based on type
			var pattern_scene = null
			match enemy_type:
				"regular":
					pattern_scene = load("res://scenes/bullet_patterns/basic_pattern.tscn")
					enemy.health = 30.0
				"urgent":
					pattern_scene = load("res://scenes/bullet_patterns/burst_pattern.tscn")
					enemy.health = 40.0
				"spam":
					pattern_scene = load("res://scenes/bullet_patterns/spiral_pattern.tscn")
					enemy.health = 25.0
				"newsletter":
					pattern_scene = load("res://scenes/bullet_patterns/wave_pattern.tscn")
					enemy.health = 35.0
				"virus":
					pattern_scene = load("res://scenes/bullet_patterns/homing_pattern.tscn")
					enemy.health = 45.0
				"encrypted":
					pattern_scene = load("res://scenes/bullet_patterns/random_pattern.tscn")
					enemy.health = 50.0
				"firewall":
					pattern_scene = load("res://scenes/bullet_patterns/wall_pattern.tscn")
					enemy.health = 60.0
				"corrupted":
					pattern_scene = load("res://scenes/bullet_patterns/glitch_pattern.tscn")
					enemy.health = 55.0
				"quantum":
					pattern_scene = load("res://scenes/bullet_patterns/quantum_pattern.tscn")
					enemy.health = 70.0
				"executive":
					pattern_scene = load("res://scenes/bullet_patterns/executive_pattern.tscn")
					enemy.health = 80.0
				"personal":
					pattern_scene = load("res://scenes/bullet_patterns/personal_pattern.tscn")
					enemy.health = 30.0
				"core":
					pattern_scene = load("res://scenes/bullet_patterns/core_pattern.tscn")
					enemy.health = 100.0
			
			# Adjust health based on wave number
			enemy.health *= (1.0 + (current_wave - 1) * 0.2)
			enemy.current_health = enemy.health
			
			if pattern_scene:
				enemy.bullet_pattern = pattern_scene
			
			# Connect signals
			enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))
			
			# Add to scene
			add_child(enemy)
			wave_enemies.append(enemy)
	
	# Wait until all enemies are defeated
	while not wave_enemies.is_empty() and not is_game_over and not is_level_complete:
		await get_tree().create_timer(0.5).timeout
	
	# Clear bullets if specified
	if wave.clear_bullets_on_complete:
		clear_all_bullets()
	
	# Spawn power-up if specified
	if wave.spawn_power_up_on_complete:
		spawn_power_up()
	
	# If not game over, start next wave
	if not is_game_over and not is_level_complete:
		is_wave_active = false
		await get_tree().create_timer(2.0).timeout
		start_next_wave()

func start_boss_fight():
	is_boss_active = true
	
	# Play boss music
	if level_data.music_track.contains("boss"):
		SoundManager.play_music(level_data.music_track)
	else:
		SoundManager.play_music("boss_theme")
	
	# Show boss intro
	if story_manager:
		var boss_name = "BOSS"
		if level_data.boss_type:
			boss_name = level_data.boss_type.capitalize()
		
		story_manager.show_dialog(boss_name, "Prepare for your final challenge!")
		await story_manager.dialog_finished
	
	# Spawn boss
	var boss_scene = null
	
	# Try to load boss scene based on boss_type
	if level_data.boss_type:
		var boss_path = "res://scenes/bosses/" + level_data.boss_type + "_boss.tscn"
		if ResourceLoader.exists(boss_path):
			boss_scene = load(boss_path)
	
	# Fall back to boss_scene if specified
	if not boss_scene and level_data.boss_scene:
		boss_scene = level_data.boss_scene
	
	# Fall back to generic boss if needed
	if not boss_scene:
		boss_scene = load("res://scenes/bosses/generic_boss.tscn")
	
	# Instantiate boss
	boss_enemy = boss_scene.instantiate()
	boss_enemy.global_position = get_spawn_position()
	boss_enemy.set_target_position(Vector2(get_viewport().get_visible_rect().size.x / 2, 150))
	
	# Set boss health
	if level_data.boss_health > 0:
		boss_enemy.health = level_data.boss_health
		boss_enemy.current_health = level_data.boss_health
	
	# Set boss type
	if level_data.boss_type:
		boss_enemy.boss_type = level_data.boss_type
	
	# Connect signals
	boss_enemy.connect("enemy_died", Callable(self, "_on_boss_died"))
	if boss_enemy.has_signal("phase_changed"):
		boss_enemy.connect("phase_changed", Callable(self, "_on_boss_phase_changed"))
	
	# Add to scene
	add_child(boss_enemy)
	
	# Apply screen effects
	if level_data.screen_effects:
		screen_shake(1.0, level_data.screen_effect_intensity * 10.0)
	
	# Update UI
	var boss_name = "BOSS FIGHT"
	if level_data.boss_type:
		boss_name = level_data.boss_type.to_upper() + " BOSS"
	emit_signal("wave_changed", current_wave, boss_name)
	emit_signal("boss_health_changed", 1.0)
	
	# Play boss intro sound
	SoundManager.play_sound("boss_intro")

func _on_boss_phase_changed(phase):
	# Play phase transition sound
	SoundManager.play_sound("boss_phase_" + str(phase))
	
	# Screen shake effect
	screen_shake(0.5, 10)

func _on_boss_died(boss):
	is_boss_active = false
	boss_enemy = null
	
	# Add big score bonus
	add_score(5000)
	
	# Clear all bullets
	clear_all_bullets()
	
	# Complete level
	complete_level()

func get_spawn_position() -> Vector2:
	# Get a random spawn position from the spawn points
	var spawn_points = $EnemySpawnPoints.get_children()
	if spawn_points.size() > 0:
		var random_index = randi() % spawn_points.size()
		return spawn_points[random_index].global_position
	else:
		# Fallback to a position above the screen
		return Vector2(randf_range(100, get_viewport().get_visible_rect().size.x - 100), -50)

func _on_enemy_died(enemy):
	# Add score
	add_score(enemy.points)
	
	# Remove from wave enemies
	wave_enemies.erase(enemy)
	
	# Update boss health if this is the boss
	if is_boss_active and enemy == boss_enemy:
		emit_signal("boss_health_changed", 0)
	elif is_boss_active and boss_enemy:
		emit_signal("boss_health_changed", boss_enemy.current_health / boss_enemy.health)
	
	# Chance to spawn power-up
	if level_data and randf() < level_data.power_up_chance:
		spawn_power_up(enemy.global_position)

func _on_player_died():
	is_game_over = true
	
	# Calculate final score
	var final_score = current_score
	
	# Play game over sound
	SoundManager.play_sound("game_over")
	
	# Emit game over signal with final score
	emit_signal("game_over", final_score)

func add_score(points: int):
	current_score += points
	emit_signal("score_changed", current_score)

func complete_level():
	is_level_complete = true
	
	# Calculate final score
	var final_score = current_score
	
	# Add time bonus
	if level_data and level_data.time_limit > 0 and time_remaining > 0:
		var time_bonus = int(time_remaining * level_data.time_bonus_multiplier)
		final_score += time_bonus
	
	# Add no damage bonus if player has low stress
	if player and player.current_stress < player.max_stress * 0.3 and level_data:
		final_score += level_data.no_damage_bonus
	
	# Add combo bonus
	if level_data:
		var combo_bonus = max_combo * level_data.combo_bonus_multiplier
		final_score += int(combo_bonus)
	
	# Play level complete sound
	SoundManager.play_sound("level_complete")
	
	# Show outro dialog if available
	if story_manager and level_data and level_data.outro_dialog.size() > 0:
		story_manager.show_dialog_sequence(level_data.outro_dialog)
		await story_manager.dialog_sequence_finished
	
	# Emit level completed signal with final score
	emit_signal("level_completed", final_score)
	
	# Unlock next level
	if Global.current_level_index < Global.level_paths.size() - 1:
		Global.unlock_level(Global.current_level_index + 1)

func spawn_keyboard_jam():
	if not keyboard_jam_scene:
		return
		
	var jam = keyboard_jam_scene.instantiate()
	
	# Set position at random location on screen
	var screen_size = get_viewport().get_visible_rect().size
	jam.position = Vector2(randf_range(100, screen_size.x - 100), -50)
	
	# Add to scene
	add_child(jam)
	
	# Play warning sound
	SoundManager.play_sound("keyboard_jam_warning")

func spawn_power_up(pos = null):
	if not power_up_scene:
		return
		
	var power_up = power_up_scene.instantiate()
	
	# Set random power-up type
	var power_types = ["rapid_fire", "shield", "multi_shot", "stress_relief"]
	power_up.power_type = power_types[randi() % power_types.size()]
	
	# Set position
	if pos:
		power_up.position = pos
	else:
		var screen_size = get_viewport().get_visible_rect().size
		power_up.position = Vector2(randf_range(100, screen_size.x - 100), -50)
	
	# Add to scene
	add_child(power_up)

func clear_all_bullets():
	var bullets = get_tree().get_nodes_in_group("enemy_projectile")
	for bullet in bullets:
		# Create fade out effect
		var tween = create_tween()
		tween.tween_property(bullet, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(bullet, "queue_free"))

func screen_shake(duration: float, intensity: float):
	if has_node("Camera2D"):
		var camera = get_node("Camera2D")
		var original_pos = camera.position
		
		for i in range(int(duration * 20)):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			camera.position = original_pos + offset
			await get_tree().create_timer(0.05).timeout
		
		camera.position = original_pos

func _input(event):
	if is_game_over:
		if event.is_action_pressed("ui_accept"):
			get_tree().reload_current_scene()
	
	if is_level_complete:
		if event.is_action_pressed("ui_accept"):
			get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			toggle_pause()
			
	# Player attack inputs
	if player and not is_game_over and not is_level_complete and not is_paused:
		if event.is_action_pressed("reply"):
			player.use_reply()
		elif event.is_action_pressed("forward"):
			player.use_forward()
		elif event.is_action_pressed("delete"):
			player.use_delete()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if has_node("PauseMenu"):
		$PauseMenu.visible = is_paused

# Button handlers
func _on_reply_button_pressed():
	if player and not is_game_over and not is_level_complete and not is_paused:
		player.use_reply()

func _on_forward_button_pressed():
	if player and not is_game_over and not is_level_complete and not is_paused:
		player.use_forward()

func _on_delete_button_pressed():
	if player and not is_game_over and not is_level_complete and not is_paused:
		player.use_delete()

func _on_resume_button_pressed():
	toggle_pause()

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")