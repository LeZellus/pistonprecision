class_name WallSlideState
extends State

func _ready() -> void:
	animation_name = "Fall"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_wall_slide(delta)
	
	# Physique spéciale du wall slide
	var input_dir = InputManager.get_movement()
	var wall_side = parent.wall_detector.get_wall_side()
	
	if input_dir == wall_side:
		parent.velocity.x = input_dir * PlayerConstants.SPEED * 0.3
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, PlayerConstants.AIR_RESISTANCE * 0.5 * delta)
	
	parent.move_and_slide()
	
	return StateTransitions.get_next_state(self, parent, delta)
