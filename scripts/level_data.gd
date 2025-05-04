extends Resource
class_name LevelData

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
@export var waves: Array[WaveData] = []
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

func get_wave(wave_number: int):
	if wave_number <= 0 or wave_number > waves.size():
		return null
	return waves[wave_number - 1]

# Inner class for wave data
class WaveData:
	var enemies: Array = []
	var wave_name: String = "Wave 1"
	var enemy_count: int = 5
	var enemy_types: Array[String] = ["regular"]
	var enemy_spawn_interval: float = 2.0
	var spawn_all_at_once: bool = false
	var spawn_positions: Array[Vector2] = []
	var target_positions: Array[Vector2] = []
	var wave_dialog: Dictionary = {}
	var wave_time_limit: float = 30.0  # Seconds, 0 = no limit
	var clear_bullets_on_complete: bool = true
	var spawn_power_up_on_complete: bool = false
	
	func _init(p_wave_name: String = "Wave 1", p_enemies: Array = [], 
			   p_count: int = 5, p_types: Array = ["regular"], 
			   p_interval: float = 2.0, p_all_at_once: bool = false):
		wave_name = p_wave_name
		enemies = p_enemies
		enemy_count = p_count
		enemy_types = p_types
		enemy_spawn_interval = p_interval
		spawn_all_at_once = p_all_at_once