class_name RunningState
extends BaseState

func enter():
	pass # Animation manquante
	# Flip horizontal selon la direction
	var movement = InputManager.get_movement()
	if movement != 0:
		player.sprite.flip_h = movement < 0

func physics_update(delta: float):
	var velocity = player.velocity
	var is_grounded = player.ground_detector.is_grounded()
	
	# Mise à jour du flip horizontal pendant la course
	var movement = InputManager.get_movement()
	if movement != 0:
		player.sprite.flip_h = movement < 0
	
	# Transitions
	if not is_grounded:
		if velocity.y < -50:
			transition_to("JumpingState")
		else:
			transition_to("FallingState")
	elif abs(velocity.x) <= 10:
		transition_to("IdleState")
