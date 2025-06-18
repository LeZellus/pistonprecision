class_name GroundState
extends State

func process_physics(delta: float) -> State:
	# PHYSIQUE
	parent.physics_component.apply_gravity(delta)
	var movement = InputManager.get_movement()
	
	if movement != 0:
		parent.physics_component.apply_movement(delta)
		parent.sprite.play("Run")
	else:
		parent.physics_component.apply_friction(delta)
		parent.sprite.play("Idle")
	
	# MOUVEMENT
	parent.move_and_slide()
	
	# TRANSITION (seule condition)
	return null if parent.is_on_floor() else parent.state_machine.get_node("AirState")
