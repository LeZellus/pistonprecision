class_name IdleState
extends State

func _ready() -> void:
	animation_name = "Idle"

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	
	if InputManager.get_movement() != 0:
		parent.physics_component.apply_movement(delta)
	else:
		parent.physics_component.apply_friction(delta)
	
	parent.move_and_slide()
	
	# SOLUTION: Créer une instance de StateTransitions
	var StateTransitionsClass = preload("res://scripts/player/states/StateTransitions.gd")
	var state_transitions = StateTransitionsClass.new()
	return state_transitions.get_next_state(self, parent, delta)
