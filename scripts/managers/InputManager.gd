# scripts/managers/InputManager.gd
extends Node

# === INPUT STATES ===
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_grounded: bool = false

# === CACHED INPUT DATA ===
var movement_input: float = 0.0
var jump_held: bool = false
var dash_just_pressed: bool = false

# === JUMP PROTECTION ===
var jump_consumed_this_frame: bool = false  # NOUVEAU : Protection contre double consommation

# === SIGNALS ===
signal jump_buffered
signal coyote_jump_available
signal movement_changed(direction: float)
signal rotate_left_requested
signal rotate_right_requested
signal push_requested
signal dash_requested

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	# IMPORTANT : Reset au début de chaque frame
	jump_consumed_this_frame = false
	
	_update_timers(delta)
	_read_inputs()

func _read_inputs():
	# Movement (optimisé - seulement si changement)
	var new_movement = Input.get_axis("move_left", "move_right")
	if new_movement != movement_input:
		movement_input = new_movement
		movement_changed.emit(movement_input)
	
	# Jump state
	jump_held = Input.is_action_pressed("jump")
	
	# Dash - Lecture directe sans stockage
	if Input.is_action_just_pressed("dash"):
		dash_just_pressed = true
		dash_requested.emit()
	
	# Actions instantanées (just_pressed)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = PlayerConstants.JUMP_BUFFER_TIME
		jump_buffered.emit()
	
	if Input.is_action_just_pressed("rotate_left"):
		rotate_left_requested.emit()
	
	if Input.is_action_just_pressed("rotate_right"):
		rotate_right_requested.emit()
	
	if Input.is_action_just_pressed("push"):
		push_requested.emit()

func _update_timers(delta):
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if coyote_timer > 0:
		coyote_timer -= delta

# === GROUNDING SYSTEM ===
func set_grounded(grounded: bool):
	var was_grounded = is_grounded
	is_grounded = grounded
	
	if was_grounded and not grounded:
		coyote_timer = PlayerConstants.COYOTE_TIME
		coyote_jump_available.emit()

# === BUFFER CHECKS (PROTÉGÉS) ===
func consume_jump_buffer() -> bool:
	# PROTECTION : Un seul jump par frame
	if jump_consumed_this_frame:
		print("PROTECTION: Jump déjà consommé cette frame!")
		return false
	
	if jump_buffer_timer > 0:
		print("=== JUMP BUFFER CONSUMED ===")
		jump_buffer_timer = 0.0
		jump_consumed_this_frame = true  # Marquer comme consommé
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
	return Input.is_action_just_released("jump")

func was_dash_pressed() -> bool:
	return Input.is_action_just_pressed("dash")
