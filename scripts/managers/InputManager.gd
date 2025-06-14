# scripts/managers/InputManager.gd - Version simplifiée
extends Node

# === TIMERS ===
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
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
	_read_action_inputs()

func _update_timers(delta):
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	coyote_timer = maxf(0.0, coyote_timer - delta)

func _read_action_inputs():
	"""Actions instantanées"""
	if Input.is_action_just_pressed("rotate_left"):
		rotate_left_requested.emit()
	if Input.is_action_just_pressed("rotate_right"):
		rotate_right_requested.emit()
	if Input.is_action_just_pressed("push"):
		push_requested.emit()
	if Input.is_action_just_pressed("dash"):
		dash_requested.emit()
	
	# Auto-buffer du jump
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = PlayerConstants.JUMP_BUFFER_TIME

# === API PUBLIQUE (accès direct, pas de cache) ===
func get_movement() -> float:
	return Input.get_axis("move_left", "move_right")

func wants_to_jump() -> bool:
	return jump_buffer_timer > 0.0

func consume_jump() -> bool:
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = 0.0
		return true
	return false

func has_coyote_time() -> bool:
	return coyote_timer > 0.0 and not is_grounded

func is_jump_held() -> bool:
	return Input.is_action_pressed("jump")

func was_jump_released() -> bool:
	return Input.is_action_just_released("jump")

func was_dash_pressed() -> bool:
	return Input.is_action_just_pressed("dash")

func set_grounded(grounded: bool):
	var was_grounded = is_grounded
	is_grounded = grounded
	
	if was_grounded and not grounded:
		coyote_timer = PlayerConstants.COYOTE_TIME
