extends Node

# This script provides hit stop functionality for the game
# Hit stop is a brief pause in the game when an impactful event occurs
# It makes hits feel more powerful and provides visual feedback

# Singleton instance
var _instance = null
static func get_instance():
	return Engine.get_singleton("HitStop")

# Hit stop parameters
var is_active = false
var original_time_scale = 1.0
var duration = 0.0
var current_time = 0.0
var intensity = 0.0

# Initialize the singleton
func _init():
	if _instance == null:
		_instance = self
	
	# Register as singleton
	Engine.register_singleton("HitStop", self)

# Process hit stop effect
func _process(delta):
	if is_active:
		current_time += delta
		
		if current_time >= duration:
			# End hit stop
			Engine.time_scale = original_time_scale
			is_active = false
		else:
			# Apply hit stop effect
			var progress = current_time / duration
			var eased_progress = ease_out_cubic(progress)
			var current_scale = lerp(intensity, original_time_scale, eased_progress)
			Engine.time_scale = current_scale

# Start a hit stop effect
func start(duration_seconds: float, intensity_factor: float = 0.05):
	if is_active:
		# If already active, only override if new hit stop is more intense
		if intensity_factor < intensity:
			return
	
	# Store original time scale if not already in hit stop
	if not is_active:
		original_time_scale = Engine.time_scale
	
	# Set hit stop parameters
	duration = duration_seconds
	current_time = 0.0
	intensity = intensity_factor
	is_active = true
	
	# Apply initial time scale
	Engine.time_scale = intensity

# Stop hit stop effect immediately
func stop():
	if is_active:
		Engine.time_scale = original_time_scale
		is_active = false

# Easing function for smooth transitions
func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3)

# Clean up
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		Engine.unregister_singleton("HitStop")