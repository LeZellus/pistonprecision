# scripts/player/states/AirState.gd - VERSION DE BASE
class_name AirState
extends State

func _ready() -> void:
	# Pas d'animation fixe - on change dynamiquement
	animation_name = ""

func enter() -> void:
	# Pas d'animation fixe au début
	_update_animation()

func process_physics(delta: float) -> State:
	# 1. PHYSIQUE DE BASE
	parent.physics_component.apply_gravity(delta)
	
	# 2. MOUVEMENT AÉRIEN
	if parent.wall_jump_timer > 0:
		# Contrôle limité pendant wall jump
		_apply_wall_jump_movement(delta)
	else:
		# Contrôle aérien normal
		parent.physics_component.apply_precise_air_movement(delta)
	
	# 3. ANIMATION DYNAMIQUE
	_update_animation()
	
	# 4. MOUVEMENT
	parent.move_and_slide()
	
	# 5. TRANSITIONS (vers GroundState quand on atterrit)
	return StateTransitions.get_instance().get_next_state(self, parent, delta)

func _update_animation():
	"""Met à jour l'animation selon la vélocité"""
	if parent.velocity.y < 0:
		parent.sprite.play("Jump")
	else:
		parent.sprite.play("Fall")

func _apply_wall_jump_movement(delta: float):
	"""Mouvement contraint pendant le wall jump timer - COPIÉ de JumpState"""
	var input_dir = InputManager.get_movement()
	
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
