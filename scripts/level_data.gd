extends Resource
class_name LevelData

# Wave data class
class WaveData extends Resource:
	@export var wave_name: String = "Wave 1"
	@export var enemy_count: int = 5
	@export var enemy_types: Array[String] = ["regular"]
	@export var enemy_spawn_interval: float = 2.0
	@export var spawn_all_at_once: bool = false
	@export var spawn_positions: Array[Vector2] = []
	@export var target_positions: Array[Vector2] = []
	@export var wave_time_limit: float = 30.0  # Seconds, 0 = no limit
	@export var clear_bullets_on_complete: bool = true
	@export var spawn_power_up_on_complete: bool = false
	@export var wave_dialog: Dictionary = {}
	@export var enemies: Array = []
	
	func _init(p_wave_name: String = "Wave 1", p_count: int = 5, 
			   p_types: Array = ["regular"], p_interval: float = 2.0, 
			   p_all_at_once: bool = false):
		wave_name = p_wave_name
		enemy_count = p_count
		if p_types.size() > 0:
			enemy_types = p_types
		enemy_spawn_interval = p_interval
		spawn_all_at_once = p_all_at_once

# Level properties
@export var level_number: int = 1
@export var level_name: String = "Day 1"
@export var level_description: String = "Your first day at the office."
@export var background_scene: PackedScene
@export var background_image: String = "res://assets/images/backgrounds/office_bg_1.png"
@export var music_track: String = "level_1"
@export var difficulty: int = 1  # 1-10 scale
@export var enemy_count: int = 5
@export var enemy_types: Array[String] = ["regular"]
@export var spawn_delay: float = 3.0
@export var boss_level: bool = false
@export var boss_type: String = ""
@export var boss_health: float = 100.0
@export var boss_scene: PackedScene
@export var total_waves: int = 3
@export var waves: Array = []
@export var intro_dialog: Array[Dictionary] = []
@export var outro_dialog: Array[Dictionary] = []
@export var time_limit: float = 180.0  # Seconds, 0 = no limit
@export var stress_recovery_rate: float = 2.0  # How fast stress recovers
@export var power_up_chance: float = 0.1  # Chance of enemy dropping power-up
@export var keyboard_jam_chance: float = 0.05  # Chance of keyboard jam appearing
@export var tutorial_level: bool = false
@export var tutorial_steps: Array[String] = []
@export var next_level: String = ""
@export var is_unlocked: bool = false

# Scoring
@export var level_complete_score: int = 1000
@export var level_complete_time_bonus: int = 500
@export var level_complete_health_bonus: int = 300
@export var level_complete_combo_bonus: int = 200
@export var level_complete_perfect_bonus: int = 1000
@export var base_score: int = 1000
@export var time_bonus_multiplier: float = 10.0
@export var no_damage_bonus: int = 500
@export var combo_bonus_multiplier: float = 5.0

# Special effects
@export var screen_effects: bool = false
@export var screen_effect_intensity: float = 0.2
@export var special_events: Array[Dictionary] = []
@export var background_scroll_speed: float = 0.0
@export var background_parallax_effect: bool = false

func _init():
	# Initialize with default waves if none exist
	if waves.size() == 0 and total_waves > 0:
		create_default_waves()

func get_wave(wave_number: int):
	if wave_number <= 0 or wave_number > waves.size():
		return null
	return waves[wave_number - 1]

# Create default waves based on total_waves
func create_default_waves():
	waves.clear()
	
	for i in range(total_waves):
		var wave = WaveData.new()
		wave.wave_name = "Wave " + str(i + 1)
		
		# Increase difficulty with each wave
		wave.enemy_count = enemy_count + i * 2
		
		# Add more enemy types in later waves
		if i == 0:
			wave.enemy_types = ["regular"]
		elif i == 1:
			wave.enemy_types = ["regular", "spam"]
		else:
			wave.enemy_types = ["regular", "spam", "urgent"]
		
		# Decrease spawn interval in later waves
		wave.enemy_spawn_interval = max(0.5, spawn_delay - (i * 0.5))
		
		# Final wave has special properties
		if i == total_waves - 1:
			wave.clear_bullets_on_complete = true
			wave.spawn_power_up_on_complete = true
			
			# If it's a boss level, reduce enemy count for final wave
			if boss_level:
				wave.enemy_count = max(1, enemy_count - 2)
		
		waves.append(wave)