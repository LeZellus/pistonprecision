class_name RunState
extends State

func enter() -> void:
	super.enter()
	_update_facing()

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_movement(delta)
	parent.move_and_slide()
	
	_update_facing()
	
	# Transitions
	if not parent.is_on_floor():
		if parent.velocity.y < 0:
			return get_node("../JumpState")
		else:
			return get_node("../FallState")
	
	if InputManager.get_movement() == 0:
		return get_node("../IdleState")
	
	if InputManager.consume_jump_buffer() and parent.piston_direction == Player.PistonDirection.DOWN:
		parent.jump()
		return get_node("../JumpState")
	
	return null

func _update_facing() -> void:
	var input_dir = InputManager.get_movement()
	if input_dir != 0:
		parent.sprite.flip_h = input_dir < 0
