class_name RunningState
extends BaseState

func enter():
	player.sprite.play("Run")

func physics_update(delta: float):
	var velocity = player.velocity
	var is_grounded = player.ground_detector.is_grounded()
	
	# Transitions
	if not is_grounded:
		if velocity.y < -50:
			transition_to("JumpingState")
		else:
			transition_to("FallingState")
	elif abs(velocity.x) <= 10:
		transition_to("IdleState")
