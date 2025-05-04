extends Node

# Sound effect paths
var sound_effects = {
	"reply": "res://assets/sounds/reply.wav",
	"forward": "res://assets/sounds/forward.wav",
	"delete": "res://assets/sounds/delete.wav",
	"email_open": "res://assets/sounds/email_open.wav",
	"player_hit": "res://assets/sounds/player_hit.wav",
	"enemy_hit": "res://assets/sounds/enemy_hit.wav",
	"level_complete": "res://assets/sounds/level_complete.wav",
	"game_over": "res://assets/sounds/game_over.wav",
	"button_click": "res://assets/sounds/button_click.wav"
}

# Music paths
var music_tracks = {
	"main_menu": "res://assets/sounds/main_menu.ogg",
	"gameplay": "res://assets/sounds/gameplay.ogg",
	"boss": "res://assets/sounds/boss.ogg"
}

# AudioStreamPlayers for sound effects
var sound_players = []
var max_sound_players = 8

# AudioStreamPlayer for music
var music_player = null

func _ready():
	# Create sound effect players
	for i in range(max_sound_players):
		var player = AudioStreamPlayer.new()
		add_child(player)
		sound_players.append(player)
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

# Play a sound effect
func play_sound(sound_name: String, volume_db: float = 0.0):
	if not sound_effects.has(sound_name):
		print("Sound effect not found: " + sound_name)
		return
	
	# Find an available player
	for player in sound_players:
		if not player.playing:
			# Load the sound
			var sound = load(sound_effects[sound_name])
			if sound:
				player.stream = sound
				player.volume_db = volume_db
				player.play()
				return
			break
	
	# If all players are busy, just print a message
	print("All sound players are busy")

# Play music
func play_music(track_name: String, volume_db: float = 0.0):
	if not music_tracks.has(track_name):
		print("Music track not found: " + track_name)
		return
	
	# Load the music
	var music = load(music_tracks[track_name])
	if music:
		music_player.stream = music
		music_player.volume_db = volume_db
		music_player.play()

# Stop music
func stop_music():
	music_player.stop()

# Set music volume
func set_music_volume(volume_db: float):
	music_player.volume_db = volume_db
	
# Check if a specific music track is playing
func is_music_playing(track_name: String) -> bool:
	if not music_player.playing:
		return false
		
	if not music_tracks.has(track_name):
		return false
		
	var current_music_path = music_player.stream.resource_path if music_player.stream else ""
	var track_path = music_tracks[track_name]
	
	return current_music_path == track_path