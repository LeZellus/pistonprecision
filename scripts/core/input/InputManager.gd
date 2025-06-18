# scripts/managers/InputManager.gd - FIX PAUSE
extends Node

# === TIMERS ===
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_grounded: bool = false

# === SIGNALS ===
signal rotate_left_requested
signal rotate_right_requested  
signal push_requested

func _ready():
	# 🔧 CRITIQUE: InputManager doit s'arrêter pendant la pause
	# Les inputs de jeu ne doivent PAS fonctionner en pause
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta):
	_update_timers(delta)
	_read_action_inputs()

func _update_timers(delta):
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	coyote_timer = maxf(0.0, coyote_timer - delta)

func _read_action_inputs():
	"""Actions instantanées - BLOQUÉES EN PAUSE"""
	# 🔧 GARDE: Pas d'inputs de jeu si en pause
	if get_tree().paused:
		return
		
	if Input.is_action_just_pressed("rotate_left"):
		rotate_left_requested.emit()
	if Input.is_action_just_pressed("rotate_right"):
		rotate_right_requested.emit()
	if Input.is_action_just_pressed("push"):
		push_requested.emit()
	
	# Auto-buffer du jump
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = PlayerConstants.JUMP_BUFFER_TIME

# === API PUBLIQUE (avec gardes de pause) ===
func get_movement() -> float:
	# 🔧 GARDE: Pas de mouvement si en pause
	if get_tree().paused:
		return 0.0
	return Input.get_axis("move_left", "move_right")

func wants_to_jump() -> bool:
	# 🔧 GARDE: Pas de saut si en pause
	if get_tree().paused:
		return false
	return jump_buffer_timer > 0.0

func consume_jump() -> bool:
	# 🔧 GARDE: Pas de consommation si en pause
	if get_tree().paused:
		return false
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = 0.0
		return true
	return false

func has_coyote_time() -> bool:
	# 🔧 GARDE: Pas de coyote time si en pause
	if get_tree().paused:
		return false
	return coyote_timer > 0.0 and not is_grounded

func is_jump_held() -> bool:
	# 🔧 GARDE: Pas de maintien si en pause
	if get_tree().paused:
		return false
	return Input.is_action_pressed("jump")

func was_jump_released() -> bool:
	# 🔧 GARDE: Pas de relâchement si en pause
	if get_tree().paused:
		return false
	return Input.is_action_just_released("jump")

func set_grounded(grounded: bool):
	var was_grounded = is_grounded
	is_grounded = grounded
	
	if was_grounded and not grounded:
		coyote_timer = PlayerConstants.COYOTE_TIME
