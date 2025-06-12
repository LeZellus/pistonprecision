class_name JumpState
extends State

func _ready() -> void:
	animation_name = "Jump"

func enter() -> void:
	super.enter()
	_perform_jump()

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_movement(delta, 1.0)  # 100% de contrôle en l'air
	
	if parent.velocity.y < 0 and InputManager.was_jump_released():
		parent.velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
	
	parent.move_and_slide()
	return StateTransitions.get_next_state(self, parent, delta)

func _perform_jump():
	parent.velocity.y = PlayerConstants.JUMP_VELOCITY
	
	# Son avec cooldown de 150ms pour éviter les doublons
	AudioManager.play_sfx_with_cooldown("player/jump", 150, 1.0)
	
	ParticleManager.emit_jump(parent.global_position)
