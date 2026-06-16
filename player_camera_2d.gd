extends Camera2D

# This script lives ONLY on the Camera2D attached to the Player (Bao-bao)
# It handles the smooth "Follow" and the dynamic "Speed Zoom" for the main view.

@export_group("Follow Settings")
@export var target_node: NodePath
@onready var target = get_node_or_null(target_node)

@export_group("Zoom Settings")
@export var min_zoom: float = 1.2    # Zoomed in (Slow speed / stopped)
@export var max_zoom: float = 0.9    # Zoomed out (High speed)
@export var zoom_speed: float = 2.0  # How fast the lens moves

@export_group("Shake Settings")
@export var decay: float = 0.8  # How quickly the shaking stops
@export var max_offset: Vector2 = Vector2(100, 75)  # Maximum render offset in pixels
@export var max_roll: float = 0.1  # Maximum rotation in radians
var trauma: float = 0.0  # Current shake strength
var trauma_power: int = 2  # Trauma exponent for a non-linear shake

func _ready():
	# Force this camera to be the master of the main screen
	make_current()
	
	# If target wasn't set in inspector, try to find the parent (Player)
	if not target and get_parent() is CharacterBody2D:
		target = get_parent()

func _process(delta):
	if not target:
		return
		
	# 1. POSITION SMOOTHING (Manual or Inspector)
	# If you have "Position Smoothing" enabled in the Inspector, 
	# Godot handles the following. We focus on the Zoom logic here.
	
	# 2. DYNAMIC SPEED ZOOM
	# We calculate speed based on the Player's velocity
	var speed = target.velocity.length()
	
	# Map the speed (roughly 0 to 540) to our zoom range (1.2 to 0.9)
	# This ensures the camera pulls back as you shift into 3rd gear
	var target_zoom_val = remap(clamp(speed, 0, 600), 0, 600, min_zoom, max_zoom)
	var target_zoom = Vector2(target_zoom_val, target_zoom_val)
	
	# Smoothly interpolate the zoom so it doesn't snap
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)

	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		shake()

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)

func _notification(what):
	# Security check: If something tries to steal 'current' status, 
	# we can re-assert it here if needed, but for now, we play nice.
	pass
