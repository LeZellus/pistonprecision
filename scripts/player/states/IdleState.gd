class_name IdleState
extends State

func _ready() -> void:
	animation_name = "Idle"

func process_physics(delta: float) -> State:
	parent.apply_gravity(delta)
	parent.apply_friction(delta)
	parent.move_and_slide()
	
	# Transitions dans l'ordre de priorité
	var next_state = check_ground_transitions()
	if next_state: return next_state
	
	next_state = check_jump_input()
	if next_state: return next_state
	
	return _check_movement()

func _check_movement() -> State:
	if InputManager.get_movement() != 0:
		return get_node("../RunState")
	return null
