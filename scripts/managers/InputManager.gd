extends Node

# === BUFFER SETTINGS ===
const JUMP_BUFFER_TIME = 0.1
const COYOTE_TIME = 0.12

# === INPUT STATES ===
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_grounded: bool = false

# === INPUT DATA ===
var movement_input: float = 0.0
var jump_pressed: bool = false
var jump_held: bool = false
var jump_released: bool = false
var rotate_left_pressed: bool = false
var rotate_right_pressed: bool = false
var dash_pressed: bool = false

# === SIGNALS ===
signal jump_buffered
signal coyote_jump_available
signal movement_changed(direction: float)
signal rotate_left_requested
signal rotate_right_requested
signal dash_requested

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	_update_timers(delta)
	_read_inputs()
	_process_buffers()

func _update_timers(delta):
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if coyote_timer > 0:
		coyote_timer -= delta

func _read_inputs():
	# Movement
	var new_movement = Input.get_axis("move_left", "move_right")
	if new_movement != movement_input:
		movement_input = new_movement
		movement_changed.emit(movement_input)
	
	# Jump
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_held = Input.is_action_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	
	# Rotation
	rotate_left_pressed = Input.is_action_just_pressed("rotate_left")
	rotate_right_pressed = Input.is_action_just_pressed("rotate_right")
	
	# Dash
	dash_pressed = Input.is_action_just_pressed("dash")

func _process_buffers():
	# Jump buffer
	if jump_pressed:
		jump_buffer_timer = JUMP_BUFFER_TIME
		jump_buffered.emit()
	
	# Rotation (immédiat)
	if rotate_left_pressed:
		rotate_left_requested.emit()
	if rotate_right_pressed:
		rotate_right_requested.emit()
	
	# Dash (immédiat)
	if dash_pressed:
		dash_requested.emit()

# === GROUNDING SYSTEM ===
func set_grounded(grounded: bool):
	var was_grounded = is_grounded
	is_grounded = grounded
	
	if was_grounded and not grounded:
		coyote_timer = COYOTE_TIME
		coyote_jump_available.emit()

# === BUFFER CHECKS ===
func consume_jump_buffer() -> bool:
	if jump_buffer_timer > 0:
		jump_buffer_timer = 0.0
		return true
	return false

func has_coyote_time() -> bool:
	return coyote_timer > 0.0

func can_coyote_jump() -> bool:
	return has_coyote_time() and not is_grounded

# === GETTERS ===
func get_movement() -> float:
	return movement_input

func is_jump_held() -> bool:
	return jump_held

func was_jump_released() -> bool:
	return jump_released
