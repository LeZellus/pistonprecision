class_name IdleState
extends State

func _ready() -> void:
	animation_name = "Idle"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_friction(delta)
	parent.move_and_slide()
	
	return StateTransitions.get_next_state(self, parent, delta)
