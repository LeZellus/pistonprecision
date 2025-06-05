
# JumpingState.gd
class_name JumpingState
extends BaseState

func enter():
	player.sprite.play("Jump")

func exit():
	player.is_jumping = false

func physics_update(delta: float):
	var velocity = player.velocity
	var is_grounded = player.is_on_floor()  # Utiliser directement is_on_floor()
	var wall_data = player.wall_detector.get_wall_state()
	
	# PRIORITÉ ABSOLUE à l'atterrissage
	if is_grounded:
		if abs(velocity.x) > 5:  # Seuil plus bas
			transition_to("RunningState")
		else:
			transition_to("IdleState")
		return  # Sortir immédiatement
	
	# Autres transitions seulement si pas au sol
	if wall_data.touching and velocity.y > 50:
		transition_to("WallSlidingState")
	elif velocity.y >= 0:  # Changer de -50 à 0 pour transition plus rapide
		transition_to("FallingState")
