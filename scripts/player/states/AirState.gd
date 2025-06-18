class_name AirState
extends State

func enter() -> void:
	pass

func process_physics(delta: float) -> State:
	# 1. PHYSIQUE MINIMALE
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_precise_air_movement(delta)
	
	# 2. ANIMATION DYNAMIQUE
	parent.sprite.play("Jump" if parent.velocity.y < 0 else "Fall")
	
	# 3. MOUVEMENT
	parent.move_and_slide()
	
	# 4. TRANSITION (seule condition : toucher le sol)
	return StateTransitions.get_instance().get_next_state(self, parent, delta)
