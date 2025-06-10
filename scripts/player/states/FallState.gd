class_name FallState
extends State

func _ready() -> void:
	animation_name = "Fall"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_movement(delta, 0.8)  # 80% efficacité en l'air
	
	parent.move_and_slide()
	return StateTransitions.get_next_state(self, parent, delta)
