# scripts/managers/InputManager.gd - Version simplifiée
extends Node

# === INPUT CACHE ===
var movement_input: float = 0.0
var jump_just_pressed: bool = false
var jump_held: bool = false
var jump_just_released: bool = false
var dash_just_pressed: bool = false

# === TIMERS ===
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0

# === STATE ===
var is_grounded: bool = false

# === SIGNALS ===
signal rotate_left_requested
signal rotate_right_requested
signal push_requested
signal dash_requested

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	_update_timers(delta)
	_read_inputs()

func _read_inputs():
	# Cache tous les inputs en une fois
	var new_movement = Input.get_axis("move_left", "move_right")
	movement_input = new_movement
	
	jump_just_pressed = Input.is_action_just_pressed("jump")
	jump_held = Input.is_action_pressed("jump")
	jump_just_released = Input.is_action_just_released("jump")
	dash_just_pressed = Input.is_action_just_pressed("dash")
	
	# Buffer automatique
	if jump_just_pressed:
		jump_buffer_timer = PlayerConstants.JUMP_BUFFER_TIME
	
	# Actions instantanées
	if Input.is_action_just_pressed("rotate_left"):
		rotate_left_requested.emit()
	
	if Input.is_action_just_pressed("rotate_right"):
		rotate_right_requested.emit()
	
	if Input.is_action_just_pressed("push"):
		push_requested.emit()
	
	if dash_just_pressed:
		dash_requested.emit()

func _update_timers(delta):
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if coyote_timer > 0:
		coyote_timer -= delta

# === API PUBLIQUE SIMPLIFIÉE ===
func get_movement() -> float:
	return movement_input

func wants_to_jump() -> bool:
	return jump_buffer_timer > 0.0

func consume_jump() -> bool:
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = 0.0  # Consommer le buffer
		return true
	return false

func has_coyote_time() -> bool:
	return coyote_timer > 0.0 and not is_grounded

func is_jump_held() -> bool:
	return jump_held

func was_jump_released() -> bool:
	return jump_just_released

func was_dash_pressed() -> bool:
	return dash_just_pressed

# === GROUNDING ===
func set_grounded(grounded: bool):
	var was_grounded = is_grounded
	is_grounded = grounded
	
	# Démarrer coyote time quand on quitte le sol
	if was_grounded and not grounded:
		coyote_timer = PlayerConstants.COYOTE_TIME
