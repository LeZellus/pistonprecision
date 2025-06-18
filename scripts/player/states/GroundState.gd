class_name GroundState
extends State

func enter() -> void:
	# Les composants gèrent déjà leur activation automatiquement
	pass

func process_physics(delta: float) -> State:
	# 1. PHYSIQUE MINIMALE (gravity + movement)
	parent.physics_component.apply_gravity(delta)
	
	var movement = InputManager.get_movement()
	if movement != 0:
		parent.physics_component.apply_movement(delta)
	else:
		parent.physics_component.apply_friction(delta)
	
	# 2. ANIMATION DYNAMIQUE
	parent.sprite.play("Run" if movement != 0 else "Idle")
	
	# 3. MOUVEMENT
	parent.move_and_slide()
	
	# 4. TRANSITION (seule condition : quitter le sol)
	return StateTransitions.get_instance().get_next_state(self, parent, delta)
