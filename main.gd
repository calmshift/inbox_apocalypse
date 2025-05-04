extends Node

func _ready():
	# This script is attached to the main scene that loads first
	# It can be used for global game initialization
	
	# Initialize random number generator
	randomize()
	
	# Load the main menu scene
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")