class_name RunState
extends State

func _ready():
	pass
func enter() -> void:
	super.enter()

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_movement(delta)
	parent.move_and_slide()
	
	# Transitions (reste inchangé)
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
