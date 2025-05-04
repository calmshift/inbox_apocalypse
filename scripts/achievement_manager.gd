extends Node
class_name AchievementManager

signal achievement_unlocked(achievement_name, description)

# Achievement data
var achievements = {
	"first_day": {
		"name": "First Day Survivor",
		"description": "Complete your first day at Megacorp",
		"icon": "res://assets/images/achievements/first_day.png",
		"secret": false
	},
	"combo_master": {
		"name": "Combo Master",
		"description": "Reach a combo of 20 or higher",
		"icon": "res://assets/images/achievements/combo_master.png",
		"secret": false
	},
	"inbox_zero": {
		"name": "Inbox Zero",
		"description": "Clear all levels in the game",
		"icon": "res://assets/images/achievements/inbox_zero.png",
		"secret": false
	},
	"power_user": {
		"name": "Power User",
		"description": "Clear 100 emails",
		"icon": "res://assets/images/achievements/power_user.png",
		"secret": false
	},
	"boss_slayer": {
		"name": "Boss Slayer",
		"description": "Defeat the final boss",
		"icon": "res://assets/images/achievements/boss_slayer.png",
		"secret": false
	},
	"perfect_day": {
		"name": "Perfect Day",
		"description": "Complete a level without taking damage",
		"icon": "res://assets/images/achievements/perfect_day.png",
		"secret": true
	},
	"speed_worker": {
		"name": "Speed Worker",
		"description": "Complete a level in under 60 seconds",
		"icon": "res://assets/images/achievements/speed_worker.png",
		"secret": true
	},
	"keyboard_warrior": {
		"name": "Keyboard Warrior",
		"description": "Unjam your keyboard 10 times",
		"icon": "res://assets/images/achievements/keyboard_warrior.png",
		"secret": true
	},
	"coffee_break": {
		"name": "Coffee Break",
		"description": "Collect 20 power-ups",
		"icon": "res://assets/images/achievements/coffee_break.png",
		"secret": true
	},
	"overtime": {
		"name": "Overtime",
		"description": "Play the game for a total of 2 hours",
		"icon": "res://assets/images/achievements/overtime.png",
		"secret": true
	}
}

# Achievement notification UI
@onready var notification_panel = $NotificationPanel
@onready var achievement_name_label = $NotificationPanel/AchievementName
@onready var achievement_description_label = $NotificationPanel/AchievementDescription
@onready var achievement_icon = $NotificationPanel/AchievementIcon
@onready var animation_player = $AnimationPlayer

# Achievement stats
var keyboard_jams_fixed = 0
var power_ups_collected = 0
var perfect_levels_completed = 0
var speed_levels_completed = 0

func _ready():
	# Hide notification panel initially
	if notification_panel:
		notification_panel.visible = false
	
	# Load achievement stats from Global
	if Global:
		# Check for any achievements that should be unlocked
		check_achievements()

func check_achievements():
	if not Global:
		return
		
	var achievement = Global.check_achievements()
	if achievement != "":
		unlock_achievement(achievement)
	
	# Check for secret achievements
	check_secret_achievements()

func check_secret_achievements():
	if not Global:
		return
	
	# Perfect day achievement
	if perfect_levels_completed > 0 and not Global.achievements_unlocked.has("perfect_day"):
		Global.achievements_unlocked["perfect_day"] = true
		unlock_achievement("perfect_day")
	
	# Speed worker achievement
	if speed_levels_completed > 0 and not Global.achievements_unlocked.has("speed_worker"):
		Global.achievements_unlocked["speed_worker"] = true
		unlock_achievement("speed_worker")
	
	# Keyboard warrior achievement
	if keyboard_jams_fixed >= 10 and not Global.achievements_unlocked.has("keyboard_warrior"):
		Global.achievements_unlocked["keyboard_warrior"] = true
		unlock_achievement("keyboard_warrior")
	
	# Coffee break achievement
	if power_ups_collected >= 20 and not Global.achievements_unlocked.has("coffee_break"):
		Global.achievements_unlocked["coffee_break"] = true
		unlock_achievement("coffee_break")
	
	# Overtime achievement
	if Global.total_play_time >= 7200 and not Global.achievements_unlocked.has("overtime"):
		Global.achievements_unlocked["overtime"] = true
		unlock_achievement("overtime")
	
	# Save achievements
	Global.save_game()

func unlock_achievement(achievement_id):
	if not achievements.has(achievement_id):
		push_error("Achievement not found: " + achievement_id)
		return
	
	var achievement = achievements[achievement_id]
	
	# Play sound
	SoundManager.play_sound("achievement_unlocked")
	
	# Show notification
	show_achievement_notification(achievement_id)
	
	# Emit signal
	emit_signal("achievement_unlocked", achievement["name"], achievement["description"])
	
	# Mark as unlocked in Global
	if Global and Global.achievements_unlocked.has(achievement_id):
		Global.achievements_unlocked[achievement_id] = true
		Global.save_game()

func show_achievement_notification(achievement_id):
	if not notification_panel or not achievement_name_label or not achievement_description_label:
		return
	
	var achievement = achievements[achievement_id]
	
	# Set notification content
	achievement_name_label.text = achievement["name"]
	achievement_description_label.text = achievement["description"]
	
	# Load icon if it exists
	if achievement_icon and ResourceLoader.exists(achievement["icon"]):
		achievement_icon.texture = load(achievement["icon"])
	
	# Show notification with animation
	notification_panel.visible = true
	if animation_player:
		animation_player.play("achievement_popup")
		await animation_player.animation_finished
		
		# Hide after a delay
		await get_tree().create_timer(3.0).timeout
		animation_player.play_backwards("achievement_popup")
		await animation_player.animation_finished
		notification_panel.visible = false

# Methods to track achievement progress
func register_keyboard_jam_fixed():
	keyboard_jams_fixed += 1
	check_achievements()

func register_power_up_collected():
	power_ups_collected += 1
	check_achievements()

func register_perfect_level():
	perfect_levels_completed += 1
	check_achievements()

func register_speed_level():
	speed_levels_completed += 1
	check_achievements()

# Get all achievements for display in UI
func get_all_achievements():
	var achievement_list = []
	
	for id in achievements.keys():
		var achievement = achievements[id].duplicate()
		achievement["id"] = id
		achievement["unlocked"] = Global.achievements_unlocked.has(id) and Global.achievements_unlocked[id]
		achievement_list.append(achievement)
	
	return achievement_list