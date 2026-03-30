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

func _notification(what):
	# Security check: If something tries to steal 'current' status, 
	# we can re-assert it here if needed, but for now, we play nice.
	pass
