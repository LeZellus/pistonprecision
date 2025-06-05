# FallingState.gd
class_name FallingState
extends BaseState

var frame_override: bool = false

func enter():
	player.sprite.play("Fall")
	player.sprite.pause()
	frame_override = true
	_set_fall_frame_based_on_velocity()

func exit():
	frame_override = false

func physics_update(delta: float):
	var velocity = player.velocity
	var is_grounded = player.ground_detector.is_grounded()
	var wall_data = player.wall_detector.get_wall_state()
	
	# Update fall frame
	if frame_override:
		_set_fall_frame_based_on_velocity()
	
	# PRIORITÉ à la détection du sol
	if is_grounded:
		if abs(velocity.x) > 10:
			transition_to("RunningState")
		else:
			transition_to("IdleState")
	# Ensuite les autres transitions
	elif wall_data.touching and velocity.y > 50:
		transition_to("WallSlidingState")
	elif velocity.y < -50:
		transition_to("JumpingState")

func _set_fall_frame_based_on_velocity():
	var velocity_y = abs(player.velocity.y)
	var total_frames = player.sprite.sprite_frames.get_frame_count("Fall")
	
	if total_frames <= 1:
		return
	
	var max_velocity = PlayerConstants.MAX_FALL_SPEED
	var velocity_ratio = clamp(velocity_y / max_velocity, 0.0, 0.8)
	var target_frame = int(velocity_ratio * (total_frames - 1))
	player.sprite.frame = target_frame
