class_name WallSlideState
extends State

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_wall_slide(delta)
	
	# Réduction de la friction horizontale pendant le wall slide
	var input_dir = InputManager.get_movement()
	var wall_side = parent.wall_detector.get_wall_side()
	
	# Si on pousse vers le mur, on maintient la vitesse
	if input_dir == wall_side:
		parent.velocity.x = input_dir * PlayerConstants.SPEED * 0.3
	else:
		# Sinon friction réduite pour permettre de se détacher
		parent.velocity.x = move_toward(parent.velocity.x, 0, PlayerConstants.AIR_RESISTANCE * 0.5 * delta)
	
	parent.move_and_slide()
	
	# Wall jump
	if InputManager.consume_jump_buffer() and parent.piston_direction == Player.PistonDirection.DOWN:
		return get_node("../JumpState")
	
	# Transitions
	if parent.is_on_floor():
		if InputManager.get_movement() != 0:
			return get_node("../RunState")
		else:
			return get_node("../IdleState")
	
	# Utilise la nouvelle méthode avec timer de grâce
	if not parent.can_wall_slide():
		return get_node("../FallState")
	
	return null
