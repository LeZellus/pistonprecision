class_name AirState
extends State

func process_physics(delta: float) -> State:
	# PHYSIQUE
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_precise_air_movement(delta)
	
	# ANIMATION
	parent.sprite.play("Jump" if parent.velocity.y < 0 else "Fall")
	
	# MOUVEMENT
	parent.move_and_slide()
	
	# TRANSITION (seule condition)
	return parent.state_machine.get_node("GroundState") if parent.is_on_floor() else null
