extends Camera2D

# --- CONFIG ---
@export var target_node: CharacterBody2D # Drag your Tuktuk here in the Inspector
@export var min_zoom: float = 0.6         # Zoomed out (Fast)
@export var max_zoom: float = 1.0         # Normal view (Slow/Idle)
@export var zoom_speed: float = 2.0      # How fast the camera reacts

func _process(delta):
	if not target_node:
		return
	
	# 1. Get the current speed of the Tuktuk
	var speed = target_node.velocity.length()
	var max_speed = 600.0 # Adjust this to match your Tuktuk's top speed
	
	# 2. Calculate the "Desired" zoom based on speed
	# Remap speed (0 to max) to zoom (max_zoom to min_zoom)
	var speed_factor = clamp(speed / max_speed, 0.0, 1.0)
	var target_zoom_val = lerp(max_zoom, min_zoom, speed_factor)
	
	# 3. Smoothly interpolate to the target zoom
	var target_vector = Vector2(target_zoom_val, target_zoom_val)
	zoom = zoom.lerp(target_vector, zoom_speed * delta)
