# scripts/managers/InputManager.gd - Version optimisée
extends Node

# === INPUT CACHE (NOUVEAU) ===
var _input_cache: Dictionary = {}
var _cache_frame: int = -1

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
	_update_input_cache()  # Une seule fois par frame
	_read_inputs()

func _update_input_cache():
	"""Met à jour le cache d'inputs une seule fois par frame"""
	var current_frame = Engine.get_process_frames()
	
	if _cache_frame == current_frame:
		return  # Déjà mis à jour cette frame
	
	_cache_frame = current_frame
	
	# Cache tous les inputs en une fois
	_input_cache.movement = Input.get_axis("move_left", "move_right")
	_input_cache.jump_pressed = Input.is_action_just_pressed("jump")
	_input_cache.jump_held = Input.is_action_pressed("jump")
	_input_cache.jump_released = Input.is_action_just_released("jump")
	_input_cache.dash_pressed = Input.is_action_just_pressed("dash")

func _read_inputs():
	# Buffer automatique
	if _input_cache.jump_pressed:
		jump_buffer_timer = PlayerConstants.JUMP_BUFFER_TIME
	
	# Actions instantanées
	if Input.is_action_just_pressed("rotate_left"):
		rotate_left_requested.emit()
	
	if Input.is_action_just_pressed("rotate_right"):
		rotate_right_requested.emit()
	
	if Input.is_action_just_pressed("push"):
		push_requested.emit()
	
	if _input_cache.dash_pressed:
		dash_requested.emit()

func _update_timers(delta):
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if coyote_timer > 0:
		coyote_timer -= delta

# === API PUBLIQUE OPTIMISÉE ===
func get_movement() -> float:
	_update_input_cache()  # Sécurité
	return _input_cache.movement

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
	_update_input_cache()
	return _input_cache.jump_held

func was_jump_released() -> bool:
	_update_input_cache()
	return _input_cache.jump_released

func was_dash_pressed() -> bool:
	_update_input_cache()
	return _input_cache.dash_pressed

# === GROUNDING ===
func set_grounded(grounded: bool):
	var was_grounded = is_grounded
	is_grounded = grounded
	
	if was_grounded and not grounded:
		coyote_timer = PlayerConstants.COYOTE_TIME
