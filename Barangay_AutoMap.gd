extends Node2D

var socket = WebSocketPeer.new()
var bridge_url = "ws://127.0.0.1:8080"
var tex_cache = {}
var map_data = {} 
var junction_points = [] 

# THE OFFICIAL PROJECT OFFSET
# This shifts everything (BG, Assets, and now AI Tracks) to match your visual alignment
var world_offset = Vector2(-660, -48)

func _ready():
	print("[SYSTEM] Loading Vector map from JSON...")
	var file = FileAccess.open("res://map_data.json", FileAccess.READ)
	if not file: return
	map_data = JSON.parse_string(file.get_as_text())
	
	var tex_road = load("res://Stickers/road_base.png")
	var tex_line = load("res://Stickers/road_line_dashed.png")
	var tex_sidewalk = load("res://Stickers/sidewalk_base.png")
	
	if map_data.has("vector_paths"):
		for path in map_data["vector_paths"]:
			junction_points.append(Vector2(path[0][0], path[0][1]))
			junction_points.append(Vector2(path[-1][0], path[-1][1]))
	
	# 1. BACKGROUND SETUP
	var base_bg = ColorRect.new()
	base_bg.color = Color(0.18, 0.35, 0.15)
	base_bg.size = Vector2(32768 + 1024, 32768) 
	base_bg.position = world_offset
	base_bg.z_index = -20
	add_child(base_bg)
	
	socket.connect_to_url(bridge_url)

	# 2. BUILD ROADS & TRACKS
	if map_data.has("vector_paths"):
		for path_array in map_data["vector_paths"]:
			_build_vector_ribbon(path_array, tex_road, tex_sidewalk, tex_line)

	# 3. SPAWN INITIAL ASSETS
	if map_data.has("grid"):
		var grid = map_data["grid"]
		for y in range(grid.size()):
			for x in range(grid[y].size()):
				var cell = grid[y][x] 
				if cell.type != "Ground" and cell.type != "Road_Marker":
					var pos = Vector2(x * 128, y * 128) + world_offset
					_spawn_asset(cell.type, pos, cell.path)

func _process(_delta):
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet().get_string_from_utf8()
			var data = JSON.parse_string(packet)
			if data and data.has("cmd") and data.cmd == "spawn":
				_spawn_asset(data.type, Vector2(data.x*128, data.y*128) + world_offset, data.path)

func _build_vector_ribbon(points_array, t_road, t_side, t_line):
	# --- THE RAILROAD LOGIC ---
	# We create a Path2D node that holds the "Truth" of the road
	var new_path = Path2D.new()
	var new_curve = Curve2D.new()
	
	# Add the points to the curve with the world offset applied
	for pt in points_array:
		new_curve.add_point(Vector2(pt[0], pt[1]) + world_offset)
	
	new_path.curve = new_curve
	
	# MARK THE TRACK: This allows the police AI to find the road via code
	new_path.add_to_group("Roads")
	add_child(new_path)
	
	# --- DRAWING LOGIC ---
	# We bake the points so the road is smooth
	new_curve.bake_interval = 15.0
	var smooth_points = new_curve.get_baked_points()
	
	# Draw Sidewalk and Road Base
	_draw_simple_line(smooth_points, 320, t_side, -12, true, new_path)
	_draw_simple_line(smooth_points, 256, t_road, -11, true, new_path)
	
	# Road Lines (Dashed)
	var current_line = Line2D.new()
	_setup_dash_style(current_line, t_line)
	new_path.add_child(current_line)
	
	for i in range(smooth_points.size()):
		var p = smooth_points[i]
		var in_junction = false
		for j_pt in junction_points:
			if p.distance_to(j_pt + world_offset) < 180.0:
				in_junction = true
				break
		
		if in_junction:
			if current_line.points.size() > 0:
				current_line = Line2D.new()
				_setup_dash_style(current_line, t_line)
				new_path.add_child(current_line)
			continue
		
		current_line.add_point(p)

func _setup_dash_style(l, tex):
	l.width = 12
	l.texture = tex
	l.texture_mode = Line2D.LINE_TEXTURE_TILE
	l.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	l.z_index = -9
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.antialiased = false
	l.begin_cap_mode = Line2D.LINE_CAP_NONE
	l.end_cap_mode = Line2D.LINE_CAP_NONE

func _draw_simple_line(pts, w, tex, z, cap, parent):
	var l = Line2D.new()
	l.points = pts
	l.width = w
	l.texture = tex
	l.texture_mode = Line2D.LINE_TEXTURE_TILE
	l.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	l.z_index = z
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND if cap else Line2D.LINE_CAP_NONE
	l.end_cap_mode = Line2D.LINE_CAP_ROUND if cap else Line2D.LINE_CAP_NONE
	l.antialiased = false
	parent.add_child(l)

func _spawn_asset(t, pos, p):
	if p == "": return
	if not tex_cache.has(p): tex_cache[p] = load("res://" + p)
	
	var s = Sprite2D.new()
	s.texture = tex_cache[p]
	s.centered = false
	
	var static_body = StaticBody2D.new()
	# This ensures buildings are solid for the AI to hit during chases
	static_body.collision_layer = 1 
	
	var collision_shape = CollisionShape2D.new()
	
	if t == "Building":
		s.position = pos + Vector2(12, 12)
		s.scale = Vector2(0.85, 0.85)
		s.z_index = 5
		var rect = RectangleShape2D.new()
		rect.size = Vector2(110, 110)
		collision_shape.shape = rect
		collision_shape.position = pos + Vector2(64, 64)
		
	elif t == "Nature": 
		var offset = Vector2(randf_range(-15,15), randf_range(-15,15))
		s.position = pos + offset
		s.z_index = 10 
		s.modulate = Color(0.9, 0.9, 0.9, 1.0)
		var circle = CircleShape2D.new()
		circle.radius = 25.0
		collision_shape.shape = circle
		collision_shape.position = pos + Vector2(64, 90) + offset
	
	add_child(s)
	add_child(static_body)
	static_body.add_child(collision_shape)
	s.set_script(load("res://Scripts/CullingObject.gd"))
