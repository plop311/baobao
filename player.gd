extends CharacterBody2D

# --- TUNED FOR TIGHT TURNS & DRIFTS ---
@export var max_speed = 500.0
@export var acceleration = 1000.0    
@export var rolling_resistance = 0.995 
@export var drag = 0.99              
@export var braking_force = 4500.0   

# --- ⚙️ GEARBOX SETTINGS ---
var current_gear = 1
var gear_speeds = {1: 180.0, 2: 360.0, 3: 540.0} 
var gear_acceleration_mult = {1: 1.2, 2: 1.0, 3: 0.8} 

# --- STEERING LOGIC ---
@export var steering_limit = 120.0    
@export var steering_speed = 20.0    
var current_steering = 0.0           

# --- DRIFT SETTINGS ---
@export var drift_grip = 0.82
@export var handbrake_drift = 0.99   

# --- SCORE & LORE ---
# This is the "Chaos Meter" that the scoreboard UI looks for
var score: float = 0.0 

# --- AUDIO & JUICE ---
@onready var engine_audio = $EngineSound
@onready var horn_audio = $HornSound
# Nodes must be named EXACTLY like this in your Scene Tree
@onready var backfire_audio = get_node_or_null("BackfireSound")
@onready var gear_audio = get_node_or_null("GearShiftSound")
@onready var exhaust_particles = get_node_or_null("ExhaustParticles")

@export var base_pitch = 0.6
@export var max_pitch = 1.8

# Logic Flags
var last_input_direction = 0.0
var backfire_cooldown = 0.0
var gear_shift_timer = 0.0 
var is_reloading = false 

var current_speed_mod = 1.0
var grid_pos = Vector2i.ZERO

func _physics_process(delta):
	if is_reloading: return

	# 1. GEAR LOGIC
	_handle_gear_logic(delta)

	# 2. STEERING
	var target_steering = Input.get_axis("ui_left", "ui_right") * steering_limit
	current_steering = lerp(current_steering, target_steering, steering_speed * delta)
	
	var speed = velocity.length()
	if speed > 5.0: 
		var forward_vector = Vector2.RIGHT.rotated(rotation)
		var direction_factor = 1.0 if velocity.dot(forward_vector) >= 0 else -1.0
		var speed_factor = clamp(speed / 450.0, 0.0, 1.2)
		rotation += deg_to_rad(current_steering) * speed_factor * direction_factor * delta

	# 3. ACCELERATION
	var input_direction = Input.get_axis("ui_down", "ui_up")
	_check_for_backfire(input_direction, delta)

	if input_direction != 0 and gear_shift_timer <= 0:
		var move_vec = Vector2.RIGHT.rotated(rotation)
		var accel_final = acceleration * gear_acceleration_mult[current_gear]
		velocity += move_vec * input_direction * accel_final * delta
	
	if gear_shift_timer > 0:
		gear_shift_timer -= delta

	# 4. DRIFT & FRICTION
	var lateral_vel = _get_lateral_velocity()
	var forward_vel = _get_forward_velocity()
	var current_drift = drift_grip
	
	if Input.is_action_pressed("ui_select"): # Spacebar
		current_drift = handbrake_drift
		velocity = velocity.move_toward(Vector2.ZERO, braking_force * delta)
	
	velocity = forward_vel + (lateral_vel * current_drift)

	if input_direction == 0: velocity *= rolling_resistance
	velocity *= drag
	
	# Gear-based speed limiter
	if velocity.length() > gear_speeds[current_gear] * current_speed_mod:
		velocity = velocity.normalized() * gear_speeds[current_gear] * current_speed_mod

	# 5. UPDATES
	move_and_slide()
	_update_engine_sound(delta)
	_handle_horn_input()
	_update_grid_radar()
	
	# --- CHAOS SCORING ---
	# Fast driving increases the meter over time
	if speed > 100:
		score += (speed / 100.0) * delta * 10.0

	global_position.x = clamp(global_position.x, 64.0, 32704.0)
	global_position.y = clamp(global_position.y, 64.0, 32704.0)

# --- ⚙️ TRANSMISSION SYSTEM ---
func _handle_gear_logic(_delta):
	var speed = velocity.length()
	var old_gear = current_gear
	
	if speed < 160: current_gear = 1
	elif speed < 340: current_gear = 2
	else: current_gear = 3
	
	if current_gear > old_gear:
		_trigger_gear_shift()

func _trigger_gear_shift():
	print("⚙️ SHIFT! Current Gear: ", current_gear)
	gear_shift_timer = 0.15 
	if gear_audio: 
		gear_audio.play()
	else:
		print("❌ ERROR: GearShiftSound node not found!")
	
	if randf() > 0.4:
		_trigger_backfire_effect()

# --- 🚨 JUICE & AUDIO ---
func _trigger_backfire_effect():
	print("🔥 POP!")
	backfire_cooldown = 0.4
	
	# Bonus Chaos for every loud pop
	score += 50 
	
	if backfire_audio:
		backfire_audio.pitch_scale = randf_range(0.8, 1.4)
		backfire_audio.play()
	else:
		print("❌ ERROR: BackfireSound node not found!")
		
	if exhaust_particles:
		exhaust_particles.restart()
		exhaust_particles.emitting = true

func _update_engine_sound(_delta):
	if engine_audio:
		var speed = velocity.length()
		var gear_min = 0.0 if current_gear == 1 else gear_speeds[current_gear-1]
		var gear_max = gear_speeds[current_gear]
		var gear_perc = (speed - gear_min) / (gear_max - gear_min)
		
		var target_pitch = lerp(0.7, 1.6, gear_perc)
		engine_audio.pitch_scale = lerp(engine_audio.pitch_scale, target_pitch, 0.1)

func _check_for_backfire(current_input, delta):
	if backfire_cooldown > 0:
		backfire_cooldown -= delta
		return
	
	if last_input_direction > 0 and current_input <= 0 and velocity.length() > 300:
		if randf() > 0.3: 
			_trigger_backfire_effect()
			
	last_input_direction = current_input

# --- UTILS ---
func _handle_horn_input():
	if Input.is_physical_key_pressed(KEY_H) and horn_audio and not horn_audio.playing:
		horn_audio.play()

func _update_grid_radar():
	var new_pos = Vector2i(int(floor(global_position.x / 128.0)), int(floor(global_position.y / 128.0)))
	if new_pos != grid_pos:
		grid_pos = new_pos
		var map_node = get_tree().root.find_child("BarangayMap", true, false)
		if map_node and "socket" in map_node and map_node.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			map_node.socket.send_text(JSON.stringify({"cmd": "pos_update", "x": grid_pos.x, "y": grid_pos.y, "rot": rotation}))

func _get_lateral_velocity() -> Vector2:
	var side_vector = Vector2.UP.rotated(rotation)
	return side_vector * velocity.dot(side_vector)

func _get_forward_velocity() -> Vector2:
	var forward_vector = Vector2.RIGHT.rotated(rotation)
	return forward_vector * velocity.dot(forward_vector)
