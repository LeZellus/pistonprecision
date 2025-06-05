class_name JumpingState
extends BaseState

func enter():
	player.sprite.play("Jump")

func exit():
	player.is_jumping = false

func physics_update(delta: float):
	var velocity = player.velocity
	var wall_data = player.wall_detector.get_wall_state()
	
	# Transitions
	if wall_data.touching and velocity.y > 50:
		transition_to("WallSlidingState")
	elif velocity.y >= -50:
		transition_to("FallingState")
