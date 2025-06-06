class_name RunState
extends State

func _ready():
	animation_name = "Run"

func process_physics(delta: float) -> State:
	apply_ground_physics(delta)
	
	# Transitions dans l'ordre de priorité
	var next_state = check_ground_transitions()
	if next_state: return next_state
	
	next_state = check_dash_input()  # NOUVELLE LIGNE
	if next_state: return next_state
	
	next_state = check_jump_input()
	if next_state: return next_state
	
	return _check_idle()

func _check_idle() -> State:
	if InputManager.get_movement() == 0:
		return get_node("../IdleState")
	return null
