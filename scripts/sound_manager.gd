extends Node

# Sound effect paths
var sound_effects = {
	# Player actions
	"reply": "res://assets/sounds/reply.wav",
	"forward": "res://assets/sounds/forward.wav",
	"delete": "res://assets/sounds/delete.wav",
	"focus_mode": "res://assets/sounds/focus_mode.wav",
	
	# Enemy sounds
	"email_open": "res://assets/sounds/email_open.wav",
	"enemy_hit": "res://assets/sounds/enemy_hit.wav",
	"enemy_death": "res://assets/sounds/enemy_death.wav",
	
	# Player states
	"player_hit": "res://assets/sounds/player_hit.wav",
	"player_death": "res://assets/sounds/player_death.wav",
	"power_up": "res://assets/sounds/power_up.wav",
	"power_up_end": "res://assets/sounds/power_up_end.wav",
	"shield_up": "res://assets/sounds/shield_up.wav",
	"shield_down": "res://assets/sounds/shield_down.wav",
	"shield_hit": "res://assets/sounds/shield_hit.wav",
	
	# Game states
	"level_complete": "res://assets/sounds/level_complete.wav",
	"game_over": "res://assets/sounds/game_over.wav",
	"wave_start": "res://assets/sounds/wave_start.wav",
	"wave_complete": "res://assets/sounds/wave_complete.wav",
	"achievement_unlocked": "res://assets/sounds/achievement_unlocked.wav",
	
	# UI sounds
	"button_click": "res://assets/sounds/button_click.wav",
	"menu_select": "res://assets/sounds/menu_select.wav",
	"menu_back": "res://assets/sounds/menu_back.wav",
	"dialog_next": "res://assets/sounds/dialog_next.wav",
	"typing": "res://assets/sounds/typing.wav",
	
	# Boss sounds
	"boss_phase_1": "res://assets/sounds/boss_phase_1.wav",
	"boss_phase_2": "res://assets/sounds/boss_phase_2.wav",
	"boss_phase_3": "res://assets/sounds/boss_phase_3.wav",
	"boss_death": "res://assets/sounds/boss_death.wav",
	"boss_hit": "res://assets/sounds/boss_hit.wav",
	"boss_shield": "res://assets/sounds/boss_shield.wav",
	"boss_laugh": "res://assets/sounds/boss_laugh.wav",
	
	# Obstacles
	"keyboard_jam_warning": "res://assets/sounds/keyboard_jam_warning.wav",
	"keyboard_jam": "res://assets/sounds/keyboard_jam.wav",
	"keyboard_unjam": "res://assets/sounds/keyboard_unjam.wav",
	"paper_storm": "res://assets/sounds/paper_storm.wav",
	
	# Combo system
	"combo_1": "res://assets/sounds/combo_1.wav",
	"combo_5": "res://assets/sounds/combo_5.wav",
	"combo_10": "res://assets/sounds/combo_10.wav",
	"combo_20": "res://assets/sounds/combo_20.wav",
	"combo_break": "res://assets/sounds/combo_break.wav",
	
	# Ambient sounds
	"office_ambience": "res://assets/sounds/office_ambience.wav",
	"keyboard_typing": "res://assets/sounds/keyboard_typing.wav",
	"printer_noise": "res://assets/sounds/printer_noise.wav",
	"phone_ring": "res://assets/sounds/phone_ring.wav",
	"coffee_machine": "res://assets/sounds/coffee_machine.wav"
}

# Music paths
var music_tracks = {
	"main_menu": "res://assets/sounds/main_menu.ogg",
	"tutorial_theme": "res://assets/sounds/tutorial_theme.ogg",
	"level_1": "res://assets/sounds/level_1.ogg",
	"level_2": "res://assets/sounds/level_2.ogg",
	"level_3": "res://assets/sounds/level_3.ogg",
	"level_4": "res://assets/sounds/level_4.ogg",
	"level_5": "res://assets/sounds/level_5.ogg",
	"boss_theme": "res://assets/sounds/boss_theme.ogg",
	"final_boss": "res://assets/sounds/final_boss.ogg",
	"credits": "res://assets/sounds/credits.ogg",
	"game_over": "res://assets/sounds/game_over_music.ogg",
	"victory": "res://assets/sounds/victory.ogg",
	
	# Fallback tracks
	"gameplay": "res://assets/sounds/gameplay.ogg"
}

# AudioStreamPlayers for sound effects
var sound_players = []
var max_sound_players = 12

# AudioStreamPlayer for music
var music_player = null

# AudioStreamPlayer for ambient sounds
var ambient_player = null

# Volume settings
var master_volume: float = 0.0
var music_volume: float = 0.0
var sfx_volume: float = 0.0

# Sound effect cooldowns to prevent spam
var sound_cooldowns = {}
var cooldown_times = {
	"player_hit": 0.1,
	"enemy_hit": 0.05,
	"combo_break": 0.5,
	"keyboard_jam": 1.0
}

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
	
	# Create ambient sound player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	# Load volume settings from Global
	if Global:
		music_volume = Global.music_volume
		sfx_volume = Global.sfx_volume
		
	# Apply volume settings
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	
func _process(delta):
	# Update sound cooldowns
	var keys_to_remove = []
	for sound in sound_cooldowns.keys():
		sound_cooldowns[sound] -= delta
		if sound_cooldowns[sound] <= 0:
			keys_to_remove.append(sound)
	
	# Remove expired cooldowns
	for key in keys_to_remove:
		sound_cooldowns.erase(key)

# Play a sound effect
func play_sound(sound_name: String, volume_db: float = 0.0):
	if not sound_effects.has(sound_name):
		print("Sound effect not found: " + sound_name)
		return
	
	# Check if sound is on cooldown
	if sound_cooldowns.has(sound_name) and sound_cooldowns[sound_name] > 0:
		return
	
	# Apply cooldown if needed
	if cooldown_times.has(sound_name):
		sound_cooldowns[sound_name] = cooldown_times[sound_name]
	
	# Find an available player
	for player in sound_players:
		if not player.playing:
			# Load the sound
			var sound = load(sound_effects[sound_name])
			if sound:
				player.stream = sound
				player.volume_db = volume_db + sfx_volume
				player.play()
				return
			break
	
	# If all players are busy, find the oldest one and replace it
	var oldest_player = sound_players[0]
	var oldest_time = sound_players[0].get_playback_position()
	
	for player in sound_players:
		if player.get_playback_position() > oldest_time:
			oldest_player = player
			oldest_time = player.get_playback_position()
	
	# Load the sound into the oldest player
	var sound = load(sound_effects[sound_name])
	if sound:
		oldest_player.stream = sound
		oldest_player.volume_db = volume_db + sfx_volume
		oldest_player.play()

# Play music
func play_music(track_name: String, volume_db: float = 0.0, crossfade: bool = false):
	if not music_tracks.has(track_name):
		print("Music track not found: " + track_name)
		return
	
	# Check if already playing this track
	if is_music_playing(track_name):
		return
	
	# Load the music
	var music = load(music_tracks[track_name])
	if music:
		if crossfade and music_player.playing:
			# Create a crossfade effect
			var old_volume = music_player.volume_db
			var tween = create_tween()
			tween.tween_property(music_player, "volume_db", -40.0, 1.0)
			tween.tween_callback(Callable(self, "_switch_music_track").bind(music, volume_db + music_volume))
		else:
			# Just play the new track
			music_player.stream = music
			music_player.volume_db = volume_db + music_volume
			music_player.play()

# Helper function for crossfade
func _switch_music_track(new_music, new_volume):
	music_player.stream = new_music
	music_player.volume_db = new_volume
	music_player.play()

# Play ambient sound
func play_ambient(sound_name: String, volume_db: float = -10.0, loop: bool = true):
	if not sound_effects.has(sound_name):
		print("Ambient sound not found: " + sound_name)
		return
	
	# Load the ambient sound
	var sound = load(sound_effects[sound_name])
	if sound:
		ambient_player.stream = sound
		ambient_player.volume_db = volume_db + sfx_volume
		ambient_player.stream.loop = loop
		ambient_player.play()

# Stop ambient sound
func stop_ambient():
	ambient_player.stop()

# Stop music
func stop_music():
	music_player.stop()

# Fade out music
func fade_out_music(duration: float = 2.0):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, duration)
	tween.tween_callback(Callable(music_player, "stop"))

# Set music volume
func set_music_volume(volume_db: float):
	music_volume = volume_db
	if music_player:
		music_player.volume_db = volume_db

# Set SFX volume
func set_sfx_volume(volume_db: float):
	sfx_volume = volume_db
	
# Check if a specific music track is playing
func is_music_playing(track_name: String) -> bool:
	if not music_player.playing:
		return false
		
	if not music_tracks.has(track_name):
		return false
		
	var current_music_path = music_player.stream.resource_path if music_player.stream else ""
	var track_path = music_tracks[track_name]
	
	return current_music_path == track_path

# Play combo sound based on combo count
func play_combo_sound(combo_count: int):
	if combo_count >= 20:
		play_sound("combo_20", 2.0)
	elif combo_count >= 10:
		play_sound("combo_10", 1.0)
	elif combo_count >= 5:
		play_sound("combo_5", 0.0)
	elif combo_count >= 1:
		play_sound("combo_1", -2.0)