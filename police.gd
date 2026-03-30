extends CharacterBody2D

enum State { PATROL, PURSUIT, BUSTED, RECOVERING }
var current_state = State.PATROL

# --- AAAA+ PERFORMANCE SPECS ---
@export var patrol_speed = 220.0
@export var chase_speed = 380.0
@export var acceleration = 1500.0
@export var friction = 0.92
@export var lane_offset = 35.0

# --- CHASE TUNING ---
@export var detection_range = 0.0 # This will be set by the circle radius in _ready
@export var lose_range = 1000.0
@export var stuck_threshold_dist = 25.0 
@export var stuck_max_time = 5.0

# --- JUICE SETTINGS ---
@export var strobe_speed = 30.0 
var siren_timer: float = 0.0

# --- TARGETS ---
@onready var player = get_tree().root.find_child("Player", true, false)

# Audio & Visual Nodes
@onready var light_red = get_node_or_null("SirenRed")
@onready var light_blue = get_node_or_null("SirenBlue")
@onready var siren_audio = get_node_or_null("SirenAudio")
@onready var engine_audio = get_node_or_null("EngineAudio")
@onready var detection_zone_shape = get_node_or_null("DetectionZone/CollisionShape2D")

# Internal Logic
var current_track_points = []
var current_point_index = 0
var is_reloading = false

# Stuck Logic Variables
var stuck_timer: float = 0.0
var pos_check_timer: float = 0.0
var last_check_pos: Vector2 = Vector2.ZERO
var recovery_timer: float = 0.0
var recovery_attempts: int = 0 

func _ready():
	await get_tree().process_frame
	
	# SYNC RADAR TO CIRCLE: This makes the math match your blue circle in the editor
	if detection_zone_shape and detection_zone_shape.shape is CircleShape2D:
		detection_range = detection_zone_shape.shape.radius
	else:
		detection_range = 600.0 # Fallback if node not found
		
	_pick_new_track(true)
	last_check_pos = global_position
	
	if engine_audio: 
		engine_audio.play()
	
	# Start with a quiet neighborhood
	_toggle_siren_visuals(false)

func _physics_process(delta):
	if is_reloading: return

	# 1. Stuck & Engine Logic
	_check_if_stuck_coords(delta)
	_run_engine_logic()

	# 2. State Machine Logic
	match current_state:
		State.PATROL:
			_run_rail_system(delta)
			_detect_player_logic()
		State.PURSUIT:
			_run_simple_chase(delta)
			_check_lose_player()
		State.RECOVERING:
			_run_recovery_logic(delta)
			_check_lose_player()
		State.BUSTED:
			velocity = velocity.move_toward(Vector2.ZERO, 2000 * delta)

	# 3. Apply Movement
	move_and_slide()
	_apply_visual_rotation(delta)

	# 4. Global Siren Guard (THE LASER FOCUS FIX)
	_update_siren_behavior(delta)

# --- 🚨 THE SIREN FIX ---
func _update_siren_behavior(delta):
	# BINARY RULE: On during chase/bust, OFF during patrol/stuck-recovery.
	if current_state == State.PURSUIT or current_state == State.BUSTED:
		_run_siren_animation(delta)
	else:
		_toggle_siren_visuals(false)

# --- 🚂 THE RAIL SYSTEM ---
func _run_rail_system(delta):
	if current_track_points.size() < 2:
		_pick_new_track(false)
		return

	var target_pt = current_track_points[current_point_index]
	var next_idx = (current_point_index + 1) % current_track_points.size()
	var road_dir = (current_track_points[next_idx] - target_pt).normalized()
	var rail_goal = target_pt + (road_dir.rotated(PI/2) * lane_offset)

	var direction = global_position.direction_to(rail_goal)
	if global_position.distance_to(rail_goal) < 110.0:
		current_point_index += 1
		if current_point_index >= current_track_points.size():
			_pick_new_track(false) 
			return
	
	velocity = velocity.move_toward(direction * patrol_speed, acceleration * delta)

# --- 🏎️ THE PURSUIT ---
func _run_simple_chase(delta):
	if not player: return
	var dir_to_player = global_position.direction_to(player.global_position)
	velocity = velocity.move_toward(dir_to_player * chase_speed, acceleration * delta)
	velocity *= friction

# --- 🛠️ RECOVERY LOGIC ---
func _run_recovery_logic(delta):
	recovery_timer -= delta
	var reverse_dir = Vector2.LEFT.rotated(rotation + 0.4) 
	velocity = velocity.move_toward(reverse_dir * (patrol_speed * 0.8), acceleration * delta)
	
	if recovery_timer <= 0:
		if player and global_position.distance_to(player.global_position) < lose_range:
			current_state = State.PURSUIT
		else:
			current_state = State.PATROL
			_snap_to_nearest_rail_point()

# --- 🔊 AUDIO & PITCH LOGIC ---
func _run_engine_logic():
	if not engine_audio: return
	var speed_percent = velocity.length() / chase_speed
	engine_audio.pitch_scale = lerp(0.8, 1.4, speed_percent)

func _run_siren_animation(delta):
	if siren_audio and not siren_audio.playing:
		siren_audio.play()

	siren_timer += delta * strobe_speed
	if light_red and light_blue:
		light_red.visible = true
		light_blue.visible = true
		var pulse = sin(siren_timer)
		if pulse > 0:
			light_red.energy = 12.0
			light_blue.energy = 0.0
		else:
			light_red.energy = 0.0
			light_blue.energy = 12.0

func _toggle_siren_visuals(active: bool):
	if siren_audio and not active:
		siren_audio.stop()
	if light_red: light_red.visible = active
	if light_blue: light_blue.visible = active

# --- HELPERS ---

func _check_if_stuck_coords(delta):
	pos_check_timer += delta
	if pos_check_timer >= 1.0:
		var dist_moved = global_position.distance_to(last_check_pos)
		if dist_moved < stuck_threshold_dist:
			stuck_timer += 1.0
		else:
			stuck_timer = 0.0
			recovery_attempts = 0 
		last_check_pos = global_position
		pos_check_timer = 0.0

	if stuck_timer >= 2.0 and current_state != State.RECOVERING and current_state != State.BUSTED:
		recovery_attempts += 1
		if recovery_attempts > 2:
			_pick_new_track(true)
			stuck_timer = 0.0
			recovery_attempts = 0
		else:
			current_state = State.RECOVERING
			recovery_timer = 1.5
			stuck_timer = 2.1 

	if stuck_timer > stuck_max_time:
		stuck_timer = 0.0
		recovery_attempts = 0
		current_state = State.PATROL
		_pick_new_track(true)

func _detect_player_logic():
	if player and global_position.distance_to(player.global_position) < detection_range:
		current_state = State.PURSUIT

func _check_lose_player():
	if player and global_position.distance_to(player.global_position) > lose_range:
		current_state = State.PATROL
		_snap_to_nearest_rail_point()

func _apply_visual_rotation(delta):
	if velocity.length() > 50.0 and current_state != State.RECOVERING:
		rotation = lerp_angle(rotation, velocity.angle(), 10.0 * delta)

func _snap_to_nearest_rail_point():
	var roads = get_tree().get_nodes_in_group("Roads")
	if roads.size() == 0: return
	var closest_road = roads[0]
	var min_dist = 9999999.0
	for road in roads:
		var d = global_position.distance_to(road.to_global(road.curve.get_point_position(0)))
		if d < min_dist:
			min_dist = d
			closest_road = road
	
	var baked = closest_road.curve.get_baked_points()
	current_track_points = []
	for p in baked: current_track_points.append(closest_road.to_global(p))
	
	var nearest_idx = 0
	var nearest_dist = 999999.0
	for i in range(current_track_points.size()):
		var d = global_position.distance_to(current_track_points[i])
		if d < nearest_dist:
			nearest_dist = d
			nearest_idx = i
	current_point_index = nearest_idx

func _pick_new_track(must_warp: bool = false):
	_snap_to_nearest_rail_point()
	if must_warp and current_track_points.size() > 0:
		global_position = current_track_points[current_point_index]

# --- SIGNALS ---

func _on_hit_box_body_entered(body: Node2D) -> void:
	if is_reloading: return 
	if body.name == "Player":
		is_reloading = true
		current_state = State.BUSTED
		await get_tree().create_timer(1.2).timeout
		get_tree().reload_current_scene()

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player" and current_state == State.PATROL:
		current_state = State.PURSUIT
