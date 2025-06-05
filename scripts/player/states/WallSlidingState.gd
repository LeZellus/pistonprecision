class_name WallSlidingState
extends BaseState

func enter():
	player.sprite.play("WallSlide")

func physics_update(delta: float):
	var velocity = player.velocity
	var is_grounded = player.ground_detector.is_grounded()
	var wall_data = player.wall_detector.get_wall_state()
	
	# Transitions
	if is_grounded:
		if abs(velocity.x) > 10:
			transition_to("RunningState")
		else:
			transition_to("IdleState")
	elif not wall_data.touching:
		if velocity.y < -50:
			transition_to("JumpingState")
		else:
			transition_to("FallingState")
