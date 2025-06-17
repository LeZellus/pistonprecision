# scripts/player/states/JumpState.gd - VERSION AVEC WALL JUMP FORCÉ
class_name JumpState
extends State

func _ready() -> void:
	animation_name = "Jump"

func enter() -> void:
	super.enter()
	_perform_jump()

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	
	# WALL JUMP TIMER: Mouvement limité pendant le timer
	if parent.wall_jump_timer > 0:
		_apply_wall_jump_movement(delta)
	else:
		parent.physics_component.apply_precise_air_movement(delta)
	
	if parent.velocity.y < 0 and InputManager.was_jump_released():
		parent.velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
	
	parent.move_and_slide()
	
	return StateTransitions.get_instance().get_next_state(self, parent, delta)

func _perform_jump():
	var wall_side = parent.wall_detector.get_wall_side()
	
	# WALL JUMP DÉTECTÉ
	if wall_side != 0:
		_perform_wall_jump(wall_side)
	else:
		_perform_normal_jump()

func _perform_wall_jump(wall_side: int):
	"""Wall jump avec momentum forcé"""
	parent.velocity.y = PlayerConstants.JUMP_VELOCITY * 0.95  # Légèrement plus faible
	
	# MOMENTUM HORIZONTAL FORCÉ (opposé au mur)
	var horizontal_force = -wall_side * PlayerConstants.SPEED * 1.2
	parent.velocity.x = horizontal_force
	
	# TIMER pour empêcher le re-grab du MÊME mur uniquement
	parent.wall_jump_timer = PlayerConstants.WALL_JUMP_GRACE_TIME
	parent.last_wall_side = wall_side  # Mémoriser le côté du mur
	
	print("Wall jump! Côté mur: %d, Direction forcée: %d" % [wall_side, -wall_side])
	
	AudioManager.play_sfx("player/wall_jump", 0.8)
	ParticleManager.emit_jump(parent.global_position)

func _perform_normal_jump():
	"""Saut normal"""
	parent.velocity.y = PlayerConstants.JUMP_VELOCITY
	AudioManager.play_sfx_with_cooldown("player/jump", 150, 1.0)
	ParticleManager.emit_jump(parent.global_position)

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
			parent.velocity.x = move_toward(parent.velocity.x, target_speed, PlayerConstants.AIR_ACCELERATION * 0.3 * delta)
		else:
			# Mouvement normal dans la même direction
			var target_speed = input_dir * PlayerConstants.SPEED * PlayerConstants.AIR_SPEED_MULTIPLIER
			parent.velocity.x = move_toward(parent.velocity.x, target_speed, PlayerConstants.AIR_ACCELERATION * delta)
	else:
		# Friction très réduite pour conserver le momentum
		parent.velocity.x = move_toward(parent.velocity.x, 0, PlayerConstants.AIR_FRICTION * 0.3 * delta)
