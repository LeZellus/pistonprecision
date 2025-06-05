class_name IdleState
extends State

func _ready() -> void:
	animation_name = "Idle"

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_friction(delta)
	parent.move_and_slide()
	
	# Transitions
	if not parent.is_on_floor():
		if parent.velocity.y < 0:
			return get_node("../JumpState")
		else:
			return get_node("../FallState")
	
	if InputManager.get_movement() != 0:
		return get_node("../RunState")
	
	if InputManager.consume_jump_buffer() and parent.piston_direction == Player.PistonDirection.DOWN:
		return get_node("../JumpState")
	
	return null
