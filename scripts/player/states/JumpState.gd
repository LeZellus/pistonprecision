class_name JumpState
extends State

func _ready() -> void:
	animation_name = "Jump"

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_air_movement(delta)
	parent.move_and_slide()
	
	# Cut jump if button released
	if parent.velocity.y < 0 and InputManager.was_jump_released():
		parent.velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
	
	# Transitions - PRIORITÉ au sol
	if parent.is_on_floor():
		if InputManager.get_movement() != 0:
			return get_node("../RunState")
		else:
			return get_node("../IdleState")
	
	if parent.velocity.y >= 0:
		return get_node("../FallState")
	
	if parent.wall_detector.is_touching_wall():
		return get_node("../WallSlideState")
	
	return null
