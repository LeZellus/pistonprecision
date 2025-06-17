# scripts/player/states/WallSlideState.gd - AVEC DÉTECTION SAUT DIRECTE
class_name WallSlideState
extends State

func _ready() -> void:
	animation_name = "Fall"

func process_input(event: InputEvent) -> State:
	# DÉTECTION DIRECTE du saut en wall slide
	if event.is_action_pressed("jump") and parent.piston_direction == Player.PistonDirection.DOWN:
		print("Wall jump input détecté directement dans WallSlideState!")
		InputManager.consume_jump()  # Consommer le buffer
		return get_parent().get_node("JumpState")
	return null

func process_physics(delta: float) -> State:
	parent.physics_component.apply_gravity(delta)
	parent.physics_component.apply_wall_slide(delta)
	
	var input_dir = InputManager.get_movement()
	var wall_side = parent.wall_detector.get_wall_side()
	
	# Style Rite: Wall slide RÉACTIF
	if input_dir == wall_side:
		# Coller au mur = ZERO mouvement (adhérence totale)
		parent.velocity.x = 0
	elif input_dir == -wall_side:
		# S'éloigner du mur = mouvement IMMÉDIAT et puissant
		parent.velocity.x = input_dir * PlayerConstants.SPEED * 0.8  # Plus réactif
	else:
		# Pas d'input = friction normale mais pas trop
		parent.velocity.x = move_toward(parent.velocity.x, 0, PlayerConstants.AIR_RESISTANCE * 0.6 * delta)
	
	parent.move_and_slide()
	
	var StateTransitionsClass = preload("res://scripts/player/states/StateTransitions.gd")
	var state_transitions = StateTransitionsClass.new()
	return state_transitions.get_next_state(self, parent, delta)
