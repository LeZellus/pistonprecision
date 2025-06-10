class_name RunState
extends State

func _ready():
	animation_name = "Run"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_movement(delta)
	parent.move_and_slide()
	
	return StateTransitions.get_next_state(self, parent, delta)
