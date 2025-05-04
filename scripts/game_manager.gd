extends Node

signal score_changed(new_score)
signal wave_changed(new_wave)
signal game_over
signal level_completed

@export var player_scene: PackedScene
@export var level_data: Resource
@export var start_wave: int = 1

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

func _ready():
	# Start gameplay music
	SoundManager.play_music("gameplay")
	
	setup_game()

func setup_game():
	current_score = 0
	current_wave = start_wave - 1
	is_game_over = false
	is_level_complete = false
	
	# Spawn player
	spawn_player()
	
	# Start first wave
	start_next_wave()

func spawn_player():
	player = player_scene.instantiate()
	player.position = $PlayerSpawnPosition.position
	player.connect("player_died", Callable(self, "_on_player_died"))
	add_child(player)

func start_next_wave():
	if is_game_over or is_level_complete:
		return
		
	current_wave += 1
	emit_signal("wave_changed", current_wave)
	
	if current_wave > level_data.total_waves:
		complete_level()
		return
		
	is_wave_active = true
	wave_enemies = []
	
	# Get wave data
	var wave = level_data.get_wave(current_wave)
	
	# Spawn enemies with delay
	for enemy_data in wave.enemies:
		await get_tree().create_timer(enemy_data.delay).timeout
		
		if is_game_over or is_level_complete:
			break
			
		var enemy = enemy_data.enemy_scene.instantiate()
		enemy.global_position = get_spawn_position()
		enemy.set_target_position(enemy_data.target_position)
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))
		
		# Set enemy properties
		if enemy_data.has("health"):
			enemy.health = enemy_data.health
		if enemy_data.has("speed"):
			enemy.speed = enemy_data.speed
		if enemy_data.has("subject_line"):
			enemy.subject_line = enemy_data.subject_line
		if enemy_data.has("sender"):
			enemy.sender = enemy_data.sender
		if enemy_data.has("time_to_open"):
			enemy.time_to_open = enemy_data.time_to_open
		if enemy_data.has("bullet_pattern"):
			enemy.bullet_pattern = enemy_data.bullet_pattern
		if enemy_data.has("move_pattern"):
			enemy.move_pattern = enemy_data.move_pattern
		
		add_child(enemy)
		wave_enemies.append(enemy)
	
	# Wait until all enemies are defeated
	while not wave_enemies.is_empty() and not is_game_over and not is_level_complete:
		await get_tree().create_timer(0.5).timeout
	
	# If not game over, start next wave
	if not is_game_over and not is_level_complete:
		is_wave_active = false
		await get_tree().create_timer(2.0).timeout
		start_next_wave()

func get_spawn_position() -> Vector2:
	# Get a random spawn position from the spawn points
	var spawn_points = $EnemySpawnPoints.get_children()
	if spawn_points.size() > 0:
		var random_index = randi() % spawn_points.size()
		return spawn_points[random_index].global_position
	else:
		# Fallback to a position above the screen
		return Vector2(randf_range(100, get_viewport().size.x - 100), -50)

func _on_enemy_died(enemy):
	# Add score
	add_score(enemy.points)
	
	# Remove from wave enemies
	wave_enemies.erase(enemy)

func _on_player_died():
	is_game_over = true
	emit_signal("game_over")

func add_score(points: int):
	current_score += points
	emit_signal("score_changed", current_score)

func complete_level():
	is_level_complete = true
	emit_signal("level_completed")

func _input(event):
	if is_game_over or is_level_complete:
		if event.is_action_pressed("ui_accept"):
			get_tree().reload_current_scene()
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			
	# Player attack inputs
	if player and not is_game_over and not is_level_complete:
		if event.is_action_pressed("reply"):
			player.use_reply()
		elif event.is_action_pressed("forward"):
			player.use_forward()
		elif event.is_action_pressed("delete"):
			player.use_delete()