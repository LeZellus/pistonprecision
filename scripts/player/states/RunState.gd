class_name RunState
extends State

func _ready():
	animation_name = "Run"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	
	if InputManager.get_movement() != 0:
		parent.physics_component.apply_movement(delta)
	else:
		parent.physics_component.apply_friction(delta)
	
	parent.move_and_slide()
	
	return StateTransitions.get_instance().get_next_state(self, parent, delta)
