class_name JumpState
extends State

func _ready() -> void:
	animation_name = "Jump"

func enter() -> void:
	super.enter()
	_perform_jump()

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_precise_air_movement(delta)
	
	if parent.velocity.y < 0 and InputManager.was_jump_released():
		parent.velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
	
	parent.move_and_slide()
	
	# CORRECTION: Utiliser preload
	var StateTransitionsClass = preload("res://scripts/player/states/StateTransitions.gd")
	var state_transitions = StateTransitionsClass.new()
	return state_transitions.get_next_state(self, parent, delta)

func _perform_jump():
	parent.velocity.y = PlayerConstants.JUMP_VELOCITY
	AudioManager.play_sfx_with_cooldown("player/jump", 150, 1.0)
	ParticleManager.emit_jump(parent.global_position)
