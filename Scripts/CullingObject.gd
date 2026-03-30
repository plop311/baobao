extends Sprite2D

func _process(_delta):
	# Simple GTA-style culling: 
	# If we are too far from the camera, don't draw
	var cam = get_viewport().get_camera_2d()
	if cam:
		var dist = global_position.distance_to(cam.global_position)
		visible = dist < 2000 # Only show tiles within 2000 pixels
