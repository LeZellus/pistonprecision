class_name FallState
extends State

func _ready() -> void:
	animation_name = "Fall"

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_air_movement(delta)
	parent.move_and_slide()
	
	# Ajoutez cette vérification pour le coyote jump
	if InputManager.consume_jump_buffer() and InputManager.can_coyote_jump():
		parent.jump()
		return get_node("../JumpState")
	
	# Transitions - PRIORITÉ au sol
	if parent.is_on_floor():
		if InputManager.get_movement() != 0:
			return get_node("../RunState")
		else:
			return get_node("../IdleState")
	
	if parent.velocity.y < -50:
		return get_node("../JumpState")
	
	if parent.wall_detector.is_touching_wall() and parent.velocity.y > 50:
		return get_node("../WallSlideState")
	
	return null
