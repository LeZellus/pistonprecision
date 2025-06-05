class_name WallSlideState
extends State

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_wall_slide(delta)
	parent.move_and_slide()
	
	# Wall jump
	if InputManager.consume_jump_buffer() and parent.piston_direction == Player.PistonDirection.DOWN:
		parent.wall_jump()
		return get_node("../JumpState")
	
	# Transitions
	if parent.is_on_floor():
		if InputManager.get_movement() != 0:
			return get_node("../RunState")
		else:
			return get_node("../IdleState")
	
	if not parent.wall_detector.is_touching_wall():
		return get_node("../FallState")
	
	return null
