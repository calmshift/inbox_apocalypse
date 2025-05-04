extends Node
class_name TutorialManager

signal tutorial_completed
signal tutorial_step_completed(step_name)
signal tutorial_enemy_spawned(enemy)
signal tutorial_power_up_spawned(power_up)

# Tutorial panels
@onready var tutorial_panels = $TutorialPanels
@onready var movement_panel = $TutorialPanels/MovementPanel
@onready var focus_panel = $TutorialPanels/FocusPanel
@onready var attack_panel = $TutorialPanels/AttackPanel
@onready var enemy_panel = $TutorialPanels/EnemyPanel
@onready var combo_panel = $TutorialPanels/ComboPanel
@onready var power_up_panel = $TutorialPanels/PowerUpPanel
@onready var keyboard_jam_panel = $TutorialPanels/KeyboardJamPanel
@onready var boss_panel = $TutorialPanels/BossPanel

# UI elements
@onready var animation_player = $AnimationPlayer
@onready var continue_button = $ContinueButton
@onready var skip_button = $SkipButton
@onready var highlight_area = $HighlightArea
@onready var arrow_indicator = $ArrowIndicator
@onready var tutorial_progress = $TutorialProgress

# Tutorial state
var current_step = 0
var total_steps = 8
var player = null
var game_manager = null
var auto_advance = true
var spawn_tutorial_enemies = false
var spawn_tutorial_power_ups = false
var spawn_tutorial_keyboard_jam = false
var spawn_tutorial_boss = false
var tutorial_active = false
var steps_to_complete = []
var completed_steps = {}

# Tutorial steps enum
enum TutorialStep {
	MOVEMENT,
	FOCUS,
	ATTACK,
	ENEMY,
	COMBO,
	POWER_UP,
	KEYBOARD_JAM,
	BOSS
}

func _ready():
	# Hide all panels initially
	for panel in tutorial_panels.get_children():
		panel.visible = false
	
	# Hide highlight and arrow
	if highlight_area:
		highlight_area.visible = false
	if arrow_indicator:
		arrow_indicator.visible = false
	
	# Connect button signals
	continue_button.pressed.connect(_on_continue_button_pressed)
	skip_button.pressed.connect(skip_tutorial)
	
	# Find references to player and game manager
	await get_tree().create_timer(0.5).timeout
	game_manager = get_parent()
	if game_manager and game_manager.has_node("Player"):
		player = game_manager.get_node("Player")
		
		# Connect to player signals
		player.combo_changed.connect(_on_combo_changed)
		player.power_up_activated.connect(_on_power_up_activated)
		player.keyboard_jammed.connect(_on_keyboard_jammed)
		player.keyboard_unjammed.connect(_on_keyboard_unjammed)

func start_tutorial(steps_list = []):
	tutorial_active = true
	current_step = 0
	completed_steps.clear()
	
	# If specific steps provided, use them
	if not steps_list.empty():
		steps_to_complete = steps_list.duplicate()
		total_steps = steps_to_complete.size()
	else:
		# Otherwise use all steps
		steps_to_complete = []
		for step in TutorialStep.values():
			steps_to_complete.append(step)
		total_steps = steps_to_complete.size()
	
	# Update progress display
	if tutorial_progress:
		tutorial_progress.max_value = total_steps
		tutorial_progress.value = 0
	
	# Play tutorial music
	SoundManager.play_music("tutorial_theme")
	
	# Start with first step
	show_next_step()

func show_next_step():
	# Hide all panels
	for panel in tutorial_panels.get_children():
		panel.visible = false
	
	# Hide highlight and arrow
	if highlight_area:
		highlight_area.visible = false
	if arrow_indicator:
		arrow_indicator.visible = false
	
	# Reset spawn flags
	spawn_tutorial_enemies = false
	spawn_tutorial_power_ups = false
	spawn_tutorial_keyboard_jam = false
	spawn_tutorial_boss = false
	
	# Check if we've completed all steps
	if current_step >= steps_to_complete.size():
		end_tutorial()
		return
	
	# Get the current tutorial step
	var step = steps_to_complete[current_step]
	
	# Update progress display
	if tutorial_progress:
		tutorial_progress.value = current_step
	
	# Show appropriate panel and set up step
	match step:
		TutorialStep.MOVEMENT:
			movement_panel.visible = true
			animation_player.play("pulse_movement")
			auto_advance = true
			
			# Set up highlight for movement keys
			if highlight_area:
				highlight_area.visible = true
				highlight_area.position = Vector2(100, 500)
				highlight_area.size = Vector2(200, 100)
			
		TutorialStep.FOCUS:
			focus_panel.visible = true
			animation_player.play("pulse_focus")
			auto_advance = true
			
			# Set up highlight for shift key
			if highlight_area:
				highlight_area.visible = true
				highlight_area.position = Vector2(50, 550)
				highlight_area.size = Vector2(100, 50)
			
		TutorialStep.ATTACK:
			attack_panel.visible = true
			animation_player.play("pulse_attack")
			auto_advance = true
			
			# Spawn a test enemy for attack practice
			spawn_tutorial_enemies = true
			
			# Set up highlight for attack buttons
			if highlight_area:
				highlight_area.visible = true
				highlight_area.position = Vector2(300, 500)
				highlight_area.size = Vector2(300, 50)
			
		TutorialStep.ENEMY:
			enemy_panel.visible = true
			animation_player.play("pulse_enemy")
			auto_advance = false
			
			# Spawn more test enemies
			spawn_tutorial_enemies = true
			
		TutorialStep.COMBO:
			combo_panel.visible = true
			animation_player.play("pulse_combo")
			auto_advance = false
			
			# Spawn enemies for combo practice
			spawn_tutorial_enemies = true
			
			# Set up highlight for combo counter
			if highlight_area:
				highlight_area.visible = true
				highlight_area.position = Vector2(700, 50)
				highlight_area.size = Vector2(100, 50)
			
		TutorialStep.POWER_UP:
			power_up_panel.visible = true
			animation_player.play("pulse_power_up")
			auto_advance = false
			
			# Spawn power-ups for demonstration
			spawn_tutorial_power_ups = true
			
		TutorialStep.KEYBOARD_JAM:
			if keyboard_jam_panel:
				keyboard_jam_panel.visible = true
				animation_player.play("pulse_keyboard_jam")
				auto_advance = false
				
				# Trigger a keyboard jam event
				spawn_tutorial_keyboard_jam = true
			else:
				# Skip this step if panel doesn't exist
				current_step += 1
				show_next_step()
				return
				
		TutorialStep.BOSS:
			if boss_panel:
				boss_panel.visible = true
				animation_player.play("pulse_boss")
				auto_advance = false
				
				# Spawn a tutorial boss
				spawn_tutorial_boss = true
			else:
				# Skip this step if panel doesn't exist
				current_step += 1
				show_next_step()
				return
				
		_: # Unknown step
			push_error("Unknown tutorial step: " + str(step))
			current_step += 1
			show_next_step()
			return
	
	# Play sound effect
	SoundManager.play_sound("dialog_next")
	
	# Emit signal
	emit_signal("tutorial_step_completed", step_to_string(step))
	
	# Increment step counter
	current_step += 1

func _on_continue_button_pressed():
	show_next_step()

func end_tutorial():
	tutorial_active = false
	
	# Hide all panels
	for panel in tutorial_panels.get_children():
		panel.visible = false
	
	# Hide highlight and arrow
	if highlight_area:
		highlight_area.visible = false
	if arrow_indicator:
		arrow_indicator.visible = false
	
	# Stop spawning tutorial objects
	spawn_tutorial_enemies = false
	spawn_tutorial_power_ups = false
	spawn_tutorial_keyboard_jam = false
	spawn_tutorial_boss = false
	
	# Play completion sound
	SoundManager.play_sound("level_complete")
	
	# Mark tutorial as completed in Global
	if Global:
		Global.complete_tutorial()
	
	# Emit signal that tutorial is complete
	emit_signal("tutorial_completed")
	
	# Start the actual game
	if game_manager and game_manager.has_method("start_game_after_tutorial"):
		game_manager.start_game_after_tutorial()

# Skip tutorial if requested
func skip_tutorial():
	# Play button sound
	SoundManager.play_sound("menu_select")
	
	# Mark tutorial as completed in Global
	if Global:
		Global.complete_tutorial()
	
	end_tutorial()

# Helper function to convert enum to string
func step_to_string(step):
	match step:
		TutorialStep.MOVEMENT: return "movement"
		TutorialStep.FOCUS: return "focus"
		TutorialStep.ATTACK: return "attack"
		TutorialStep.ENEMY: return "enemy"
		TutorialStep.COMBO: return "combo"
		TutorialStep.POWER_UP: return "power_up"
		TutorialStep.KEYBOARD_JAM: return "keyboard_jam"
		TutorialStep.BOSS: return "boss"
		_: return "unknown"

# Helper function to convert string to enum
func string_to_step(step_name):
	match step_name.to_lower():
		"movement": return TutorialStep.MOVEMENT
		"focus": return TutorialStep.FOCUS
		"attack": return TutorialStep.ATTACK
		"enemy": return TutorialStep.ENEMY
		"combo": return TutorialStep.COMBO
		"power_up": return TutorialStep.POWER_UP
		"keyboard_jam": return TutorialStep.KEYBOARD_JAM
		"boss": return TutorialStep.BOSS
		_: return -1

# Check for specific tutorial completion conditions
func _process(delta):
	if not player or not tutorial_active:
		return
	
	# Get current tutorial step
	var step_index = current_step - 1  # Because we already incremented in show_next_step
	if step_index < 0 or step_index >= steps_to_complete.size():
		return
		
	var current_tutorial_step = steps_to_complete[step_index]
	
	# Check for auto-advancement based on player actions
	match current_tutorial_step:
		TutorialStep.MOVEMENT:
			if player.has_moved and auto_advance:
				show_next_step()
		
		TutorialStep.FOCUS:
			if player.has_used_focus and auto_advance:
				show_next_step()
		
		TutorialStep.ATTACK:
			if player.has_used_reply and player.has_used_forward and player.has_used_delete and auto_advance:
				show_next_step()
	
	# Spawn tutorial objects if needed
	if spawn_tutorial_enemies:
		spawn_enemy_timer(delta)
	
	if spawn_tutorial_power_ups:
		spawn_power_up_timer(delta)
		
	if spawn_tutorial_keyboard_jam:
		spawn_keyboard_jam_timer(delta)
		
	if spawn_tutorial_boss:
		spawn_boss_timer(delta)

var enemy_spawn_timer = 0.0
var enemy_spawn_interval = 3.0
var power_up_spawn_timer = 0.0
var power_up_spawn_interval = 5.0
var keyboard_jam_spawn_timer = 0.0
var keyboard_jam_spawn_interval = 8.0
var boss_spawn_timer = 0.0
var boss_spawn_interval = 2.0

func spawn_enemy_timer(delta):
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= enemy_spawn_interval:
		enemy_spawn_timer = 0.0
		spawn_tutorial_enemy()

func spawn_tutorial_enemy():
	if not game_manager:
		return
		
	var enemy_scene = load("res://scenes/email_enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Configure enemy based on current tutorial step
	var step_index = current_step - 1
	if step_index >= 0 and step_index < steps_to_complete.size():
		var current_tutorial_step = steps_to_complete[step_index]
		
		match current_tutorial_step:
			TutorialStep.ATTACK:
				enemy.email_type = "regular"
				enemy.health = 5.0
				enemy.subject_line = "Practice Target"
				enemy.time_to_open = 10.0  # Give player more time
			TutorialStep.ENEMY:
				enemy.email_type = "regular"
				enemy.health = 10.0
				enemy.subject_line = "Incoming Email"
				enemy.time_to_open = 5.0
			TutorialStep.COMBO:
				enemy.email_type = "regular"
				enemy.health = 3.0  # Easier to kill for combos
				enemy.subject_line = "Combo Practice"
				enemy.time_to_open = 5.0
			_:
				enemy.email_type = "regular"
				enemy.health = 10.0
				enemy.subject_line = "Tutorial Email"
				enemy.time_to_open = 5.0
	else:
		# Default configuration
		enemy.email_type = "regular"
		enemy.health = 10.0
		enemy.subject_line = "Tutorial Email"
		enemy.time_to_open = 5.0
	
	enemy.sender = "tutorial@megacorp.com"
	
	# Set position at top of screen with random x
	var screen_size = get_viewport().get_visible_rect().size
	enemy.position = Vector2(randf_range(100, screen_size.x - 100), -50)
	
	# Set target position
	enemy.set_target_position(Vector2(randf_range(100, screen_size.x - 100), 150))
	
	# Add to scene
	game_manager.add_child(enemy)
	
	# Emit signal
	emit_signal("tutorial_enemy_spawned", enemy)

func spawn_power_up_timer(delta):
	power_up_spawn_timer += delta
	if power_up_spawn_timer >= power_up_spawn_interval:
		power_up_spawn_timer = 0.0
		spawn_tutorial_power_up()

func spawn_tutorial_power_up():
	if not game_manager:
		return
		
	var power_up_scene = load("res://scenes/power_up.tscn")
	var power_up = power_up_scene.instantiate()
	
	# Configure power-up
	var power_types = ["rapid_fire", "shield", "multi_shot", "stress_relief"]
	power_up.power_type = power_types[randi() % power_types.size()]
	
	# Set position at random location on screen
	var screen_size = get_viewport().get_visible_rect().size
	power_up.position = Vector2(randf_range(100, screen_size.x - 100), randf_range(100, screen_size.y - 100))
	
	# Add to scene
	game_manager.add_child(power_up)
	
	# Emit signal
	emit_signal("tutorial_power_up_spawned", power_up)

func spawn_keyboard_jam_timer(delta):
	keyboard_jam_spawn_timer += delta
	if keyboard_jam_spawn_timer >= keyboard_jam_spawn_interval:
		keyboard_jam_spawn_timer = 0.0
		spawn_tutorial_keyboard_jam()

func spawn_tutorial_keyboard_jam():
	if not player or not player.has_method("trigger_keyboard_jam"):
		return
		
	# Trigger a keyboard jam on the player
	player.trigger_keyboard_jam()
	
	# Play warning sound
	SoundManager.play_sound("keyboard_jam_warning")

func spawn_boss_timer(delta):
	boss_spawn_timer += delta
	if boss_spawn_timer >= boss_spawn_interval:
		boss_spawn_timer = 0.0
		spawn_tutorial_boss()
		
		# Only spawn one boss
		spawn_tutorial_boss = false

func spawn_tutorial_boss():
	if not game_manager:
		return
		
	var boss_scene = load("res://scenes/boss_email.tscn")
	var boss = boss_scene.instantiate()
	
	# Configure boss
	boss.email_type = "boss"
	boss.health = 30.0
	boss.subject_line = "TUTORIAL BOSS"
	boss.sender = "boss@megacorp.com"
	boss.time_to_open = 8.0
	boss.total_phases = 2  # Simplified boss for tutorial
	
	# Set position at top of screen
	var screen_size = get_viewport().get_visible_rect().size
	boss.position = Vector2(screen_size.x / 2, -100)
	
	# Set target position
	boss.set_target_position(Vector2(screen_size.x / 2, 150))
	
	# Add to scene
	game_manager.add_child(boss)

# Signal handlers
func _on_combo_changed(combo_count):
	var step_index = current_step - 1
	if step_index >= 0 and step_index < steps_to_complete.size():
		var current_tutorial_step = steps_to_complete[step_index]
		
		if current_tutorial_step == TutorialStep.COMBO and combo_count >= 5:
			show_next_step()

func _on_power_up_activated(_power_type):
	var step_index = current_step - 1
	if step_index >= 0 and step_index < steps_to_complete.size():
		var current_tutorial_step = steps_to_complete[step_index]
		
		if current_tutorial_step == TutorialStep.POWER_UP:
			# Wait a moment to let player see the power-up effect
			await get_tree().create_timer(2.0).timeout
			show_next_step()

func _on_keyboard_jammed():
	var step_index = current_step - 1
	if step_index >= 0 and step_index < steps_to_complete.size():
		var current_tutorial_step = steps_to_complete[step_index]
		
		if current_tutorial_step == TutorialStep.KEYBOARD_JAM:
			# Highlight the jammed key
			if highlight_area:
				highlight_area.visible = true
				highlight_area.position = Vector2(300, 300)
				highlight_area.size = Vector2(100, 100)

func _on_keyboard_unjammed():
	var step_index = current_step - 1
	if step_index >= 0 and step_index < steps_to_complete.size():
		var current_tutorial_step = steps_to_complete[step_index]
		
		if current_tutorial_step == TutorialStep.KEYBOARD_JAM:
			# Wait a moment to let player see they fixed it
			await get_tree().create_timer(1.0).timeout
			show_next_step()