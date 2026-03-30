extends CharacterBody2D

# --- TUNED FOR TIGHT TURNS & DRIFTS ---
@export var max_speed = 500.0        
@export var acceleration = 1000.0    
@export var rolling_resistance = 0.995 
@export var drag = 0.99              
@export var braking_force = 4500.0   

# --- STEERING LOGIC (REVERSE AWARE) ---
@export var steering_limit = 120.0    
@export var steering_speed = 20.0    
var current_steering = 0.0           

# --- DRIFT SETTINGS ---
@export var drift_grip = 0.82        
@export var handbrake_drift = 0.99   

# --- AUDIO SETTINGS ---
@onready var engine_audio = $EngineSound
@onready var horn_audio = $HornSound
@export var base_pitch = 0.6
@export var max_pitch = 1.8

var current_speed_mod = 1.0
var grid_pos = Vector2i.ZERO

func _physics_process(delta):
	# 1. CALCULATE STEERING INPUT
	var target_steering = Input.get_axis("ui_left", "ui_right") * steering_limit
	current_steering = lerp(current_steering, target_steering, steering_speed * delta)
	
	# 2. REALISTIC STEERING GEOMETRY
	var speed = velocity.length()
	if speed > 5.0: # ONLY rotate if the Bao-bao is actually moving
		# Calculate if we are moving forward or backward relative to our facing
		var forward_vector = Vector2.RIGHT.rotated(rotation)
		var dot = velocity.dot(forward_vector)
		
		# If dot is negative, we are reversing. Reverse the steering direction!
		var direction_factor = 1.0 if dot >= 0 else -1.0
		
		# Scale rotation by speed (Tighter turns at low speed, wider at high speed)
		var speed_factor = clamp(speed / 450.0, 0.0, 1.2)
		
		rotation += deg_to_rad(current_steering) * speed_factor * direction_factor * delta

	# 3. ACCELERATION & REVERSE
	var input_direction = Input.get_axis("ui_down", "ui_up")
	if input_direction != 0:
		var move_vec = Vector2.RIGHT.rotated(rotation)
		velocity += move_vec * input_direction * acceleration * delta
	
	# 4. DRIFT & HANDBRAKE
	var lateral_vel = _get_lateral_velocity()
	var forward_vel = _get_forward_velocity()
	var current_drift = drift_grip
	
	if Input.is_action_pressed("ui_select"): # Spacebar
		current_drift = handbrake_drift
		velocity = velocity.move_toward(Vector2.ZERO, braking_force * delta)
	
	velocity = forward_vel + (lateral_vel * current_drift)

	# 5. COASTING & FRICTION
	if input_direction == 0:
		velocity *= rolling_resistance
	
	velocity *= drag
	
	if velocity.length() < 10.0:
		velocity = Vector2.ZERO
	
	if velocity.length() > max_speed * current_speed_mod:
		velocity = velocity.normalized() * max_speed * current_speed_mod

	# 6. PHYSICS & UPDATES
	move_and_slide()
	_update_engine_sound(delta)
	_handle_horn_input()
	_update_grid_radar()

# NEW: WORLD BOUNDARY LOCK (32768 x 32768)
	# We leave a 64px padding so you don't half-disappear off-screen
	global_position.x = clamp(global_position.x, 64.0, 32704.0)
	global_position.y = clamp(global_position.y, 64.0, 32704.0)

func _handle_horn_input():
	if Input.is_physical_key_pressed(KEY_H):
		if horn_audio and not horn_audio.playing:
			horn_audio.play()

func _update_engine_sound(_delta):
	if engine_audio:
		var speed_perc = velocity.length() / max_speed
		var target_pitch = lerp(base_pitch, max_pitch, speed_perc)
		engine_audio.pitch_scale = lerp(engine_audio.pitch_scale, target_pitch, 0.1)
		engine_audio.volume_db = -5.0 if Input.is_action_pressed("ui_select") else 0.0

func _update_grid_radar():
	var new_pos = Vector2i(int(floor(global_position.x / 128.0)), int(floor(global_position.y / 128.0)))
	if new_pos != grid_pos:
		grid_pos = new_pos
		var map_node = get_tree().root.find_child("BarangayMap", true, false)
		if map_node and "socket" in map_node and map_node.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			map_node.socket.send_text(JSON.stringify({
				"cmd": "pos_update", "x": grid_pos.x, "y": grid_pos.y, "rot": rotation
			}))

func _get_lateral_velocity() -> Vector2:
	var side_vector = Vector2.UP.rotated(rotation)
	return side_vector * velocity.dot(side_vector)

func _get_forward_velocity() -> Vector2:
	var forward_vector = Vector2.RIGHT.rotated(rotation)
	return forward_vector * velocity.dot(forward_vector)
