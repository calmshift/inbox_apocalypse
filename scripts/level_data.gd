extends Resource
class_name LevelData

@export var level_name: String = "Day 1"
@export var level_description: String = "Your first day at the office."
@export var total_waves: int = 3
@export var waves: Array = []

func get_wave(wave_number: int):
	if wave_number <= 0 or wave_number > waves.size():
		return null
	return waves[wave_number - 1]

# Inner class for wave data
class WaveData:
	var enemies: Array = []
	var wave_name: String = ""
	
	func _init(p_wave_name: String = "", p_enemies: Array = []):
		wave_name = p_wave_name
		enemies = p_enemies