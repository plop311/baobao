extends Camera2D

# This script lives ONLY on the Camera2D INSIDE the SubViewport
# It is designed to be a "Quiet Observer"

func _ready():
	# 1. Wait for the main scene to load fully
	await get_tree().process_frame
	
	var root_vp = get_tree().root.get_viewport()
	var main_world = root_vp.find_world_2d()
	var my_vp = get_viewport()
	
	# 2. Only link if we are in the small window
	if my_vp is SubViewport and my_vp != root_vp:
		my_vp.world_2d = main_world
		zoom = Vector2(0.15, 0.15)
		
		# EXTREMELY IMPORTANT: 
		# We use make_current() but ONLY for this sub-viewport.
		make_current() 
	else:
		# If this script is accidentally on the main camera, turn it off!
		set_process(false)

func _process(_delta):
	# Follow the Player
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		global_position = player.global_position
