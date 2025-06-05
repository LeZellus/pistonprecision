class_name FallState
extends State

func _ready() -> void:
	animation_name = "Fall"

func process_physics(delta: float) -> State:
	apply_air_physics(delta)
	
	# Coyote jump
	if InputManager.consume_jump_buffer() and InputManager.can_coyote_jump():
		return get_node("../JumpState")
	
	# Transitions dans l'ordre de priorité  
	var next_state = check_air_transitions()
	if next_state: return next_state
	
	return _check_wall_slide()

func _check_wall_slide() -> State:
	if parent.wall_detector.is_touching_wall() and parent.velocity.y > 50:
		return get_node("../WallSlideState")
	return null
