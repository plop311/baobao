extends Node2D

var total_score = 0
var tile_size = Vector2(128, 128)
var following_player = true

func _ready():
	# 1. Initialize the UI so it doesn't stay at "0"
	update_ui()
	
	# 2. Wait for the BarangayMap to finish its loop
	await get_tree().process_frame
	
	# 3. Set the Camera boundaries
	setup_camera_limits()

	spawn_props(20)
	spawn_objective()

func spawn_objective():
	var roads = get_tree().get_nodes_in_group("Roads")
	if roads.size() == 0: return

	var road = roads[randi() % roads.size()]
	var points = road.curve.get_baked_points()
	if points.size() > 0:
		var pt = points[randi() % points.size()]
		var obj = Area2D.new()
		obj.name = "DeliveryObjective"
		obj.global_position = road.to_global(pt)

		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 100.0
		collision.shape = shape
		obj.add_child(collision)

		var visual = ColorRect.new()
		visual.color = Color(0, 1, 0, 0.5) # Translucent green box
		visual.size = Vector2(200, 200)
		visual.position = Vector2(-100, -100)
		obj.add_child(visual)

		obj.body_entered.connect(_on_objective_entered.bind(obj))
		add_child(obj)

func _on_objective_entered(body: Node2D, obj: Area2D):
	if body.name == "Player":
		total_score += 100
		update_ui()
		obj.queue_free()
		spawn_objective()

func spawn_props(count: int):
	var roads = get_tree().get_nodes_in_group("Roads")
	if roads.size() == 0: return

	var prop_script = load("res://prop.gd")
	for i in range(count):
		var road = roads[randi() % roads.size()]
		var points = road.curve.get_baked_points()
		if points.size() > 0:
			var pt = points[randi() % points.size()]
			var prop = Area2D.new()
			prop.name = "Prop_" + str(i)
			prop.set_script(prop_script)
			prop.global_position = road.to_global(pt) + Vector2(randf_range(-40, 40), randf_range(-40, 40))

			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(30, 30)
			collision.shape = shape
			prop.add_child(collision)

			var visual = ColorRect.new()
			visual.color = Color(0.6, 0.4, 0.2) # Brown box
			visual.size = Vector2(30, 30)
			visual.position = Vector2(-15, -15)
			prop.add_child(visual)

			add_child(prop)

func _input(event):
	# TRIGGER: Tap the 'C' key to toggle between Bao-bao and Police
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		toggle_camera_target()

func toggle_camera_target():
	var cam = get_viewport().get_camera_2d()
	var player = find_child("Player", true, false)
	var police = find_child("Police", true, false)
	
	if not cam:
		print("⚠️ [CAMERA] No active Camera2D found!")
		return
	
	following_player = !following_player
	
	if following_player:
		if player:
			_switch_cam_focus(cam, player)
			print("🎥 [CAMERA] Focus: Bao-bao")
		else:
			print("⚠️ [CAMERA] Player node missing!")
	else:
		if police:
			_switch_cam_focus(cam, police)
			print("🎥 [CAMERA] Focus: LTO Patrol")
		else:
			print("⚠️ [CAMERA] Police car not found on map!")
			following_player = true # Revert if police are missing

func _switch_cam_focus(cam: Camera2D, new_target: Node2D):
	# To ensure the camera follows the new target, we make it a child of that target.
	# We also reset its local position so it sits perfectly on top of them.
	if cam.get_parent():
		cam.get_parent().remove_child(cam)
	
	new_target.add_child(cam)
	cam.position = Vector2.ZERO
	cam.reset_smoothing() # Snap immediately to the new target

func setup_camera_limits():
	var cam = get_viewport().get_camera_2d()
	var map_node = find_child("BarangayMap", true, false)
	
	if cam and map_node:
		if "map_data" in map_node and map_node.map_data.has("grid"):
			var grid = map_node.map_data["grid"]
			var rows = grid.size()
			var cols = grid[0].size()
			
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = cols * tile_size.x
			cam.limit_bottom = rows * tile_size.y
			
			cam.reset_smoothing()
			print("📷 [CAMERA] Bounds updated to: ", cols * tile_size.x, "x", rows * tile_size.y)
		else:
			print("⚠️ [MAP] map_data or 'grid' key missing on BarangayMap node!")
	else:
		print("⚠️ [SYSTEM] Missing Camera2D or BarangayMap node.")

func add_point():
	total_score += 1
	update_ui()

func update_ui():
	# Finds ScoreLabel and updates the text.
	var label = find_child("ScoreLabel", true, false)
	if label:
		label.text = "Score: " + str(total_score)
	else:
		print("⚠️ [UI] ScoreLabel node not found in scene tree.")
