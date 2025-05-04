extends Node

# This script provides screen shake functionality for the game
# It can be attached to a Camera2D node to add screen shake effects

@export var decay = 5.0  # How quickly the shake stops [0, 10]
@export var max_offset = Vector2(100, 75)  # Maximum displacement in pixels
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly)
@export var trauma = 0.0  # Current shake strength [0, 1]
@export var trauma_power = 2  # Trauma exponent for screen shake falloff

var noise = FastNoiseLite.new()
var noise_y = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.frequency = 0.5

func _process(delta):
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		shake()

# Add trauma to the camera (0.0 to 1.0)
func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

# Apply shake to camera based on current trauma
func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	
	# Calculate shake offset and rotation
	var offset_x = max_offset.x * amount * noise.get_noise_2d(noise.seed, noise_y)
	var offset_y = max_offset.y * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
	var rotation_amount = max_roll * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
	
	# Apply to camera
	if get_parent() is Camera2D:
		get_parent().offset = Vector2(offset_x, offset_y)
		get_parent().rotation = rotation_amount
	
# Shake with specific parameters
func shake_once(duration = 0.2, intensity = 0.5):
	# Add trauma
	add_trauma(intensity)
	
	# Create timer to ensure shake stops
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	# Ensure trauma is reduced after duration
	trauma = max(trauma - intensity, 0.0)

# Shake with specific parameters and custom decay
func shake_with_decay(intensity = 0.5, custom_decay = 5.0):
	# Store original decay
	var original_decay = decay
	
	# Set new decay and add trauma
	decay = custom_decay
	add_trauma(intensity)
	
	# Wait until trauma is gone
	await get_tree().create_timer(intensity / custom_decay * 2).timeout
	
	# Restore original decay
	decay = original_decay