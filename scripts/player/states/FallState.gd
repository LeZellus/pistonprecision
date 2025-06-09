# scripts/player/states/FallState.gd
class_name FallState
extends State

func _ready() -> void:
	animation_name = "Fall"

func process_physics(delta: float) -> State:
	apply_air_physics(delta)
	
	var next_state = check_jump_input()
	if next_state: return next_state
	
	# Transitions dans l'ordre de priorité  
	next_state = check_air_transitions()
	if next_state: return next_state
	
	next_state = _check_wall_slide()
	if next_state: return next_state
	
	next_state = check_dash_input()
	if next_state: return next_state
	
	return null

func _check_wall_slide() -> State:
	if parent.wall_detector.is_touching_wall() and parent.velocity.y > 50:
		return get_node("../WallSlideState")
	return null
