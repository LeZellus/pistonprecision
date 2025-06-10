class_name FallState
extends State

func _ready() -> void:
	animation_name = "Fall"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_air_movement(delta)
	parent.move_and_slide()
	
	return StateTransitions.get_next_state(self, parent, delta)
