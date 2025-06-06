class_name JumpState
extends State

func _ready() -> void:
	animation_name = "Jump"

func enter() -> void:
	super.enter()
	_perform_jump()

func process_physics(delta: float) -> State:
	apply_air_physics(delta)
	
	# Jump cut
	if parent.velocity.y < 0 and InputManager.was_jump_released():
		parent.velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
	
	# Transitions dans l'ordre de priorité
	var next_state = check_air_transitions()
	if next_state: return next_state
	
	next_state = _check_fall()
	if next_state: return next_state
	
	# NOUVELLE LIGNE AJOUTÉE ICI :
	next_state = check_dash_input()
	if next_state: return next_state
	
	return check_wall_slide_transition()

func _perform_jump():
	parent.velocity.y = PlayerConstants.JUMP_VELOCITY
	AudioManager.play_sfx("player/jump", 0.1)
	var particle_pos = parent.global_position + Vector2(0, -4)
	ParticleManager.emit_jump(particle_pos)

func _check_fall() -> State:
	if parent.velocity.y >= 0:
		return get_node("../FallState")
	return null
