class_name JumpState
extends State

func _ready() -> void:
	animation_name = "Jump"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	
	# WALL JUMP TIMER: Mouvement limité pendant le timer
	if parent.wall_jump_timer > 0:
		_apply_wall_jump_movement(delta)
	else:
		parent.physics_component.apply_precise_air_movement(delta)
	
	parent.move_and_slide()
	
	return StateTransitions.get_instance().get_next_state(self, parent, delta)

func _apply_wall_jump_movement(delta: float):
	"""Mouvement contraint pendant le wall jump timer"""
	var input_dir = InputManager.get_movement()
	
	# Réduire drastiquement le contrôle horizontal
	if input_dir != 0:
		var current_sign = sign(parent.velocity.x)
		var input_sign = sign(input_dir)
		
		# Empêcher de contrer immédiatement le wall jump
		if current_sign != 0 and input_sign != current_sign:
			# Autoriser seulement 20% de contrôle contre le momentum
			var target_speed = input_dir * PlayerConstants.SPEED * 0.2
			parent.velocity.x = move_toward(parent.velocity.x, target_speed, 
				PlayerConstants.AIR_ACCELERATION * 0.3 * delta)
		else:
			# Mouvement normal dans la même direction
			var target_speed = input_dir * PlayerConstants.SPEED * PlayerConstants.AIR_SPEED_MULTIPLIER
			parent.velocity.x = move_toward(parent.velocity.x, target_speed, 
				PlayerConstants.AIR_ACCELERATION * delta)
	else:
		# Friction très réduite pour conserver le momentum
		parent.velocity.x = move_toward(parent.velocity.x, 0, 
			PlayerConstants.AIR_FRICTION * 0.3 * delta)
