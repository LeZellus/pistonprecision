# scripts/player/states/GroundState.gd - État sol unifié
class_name GroundState
extends State

func _ready() -> void:
	# Pas d'animation fixe - change dynamiquement
	animation_name = ""

func enter() -> void:
	_update_animation()

func process_physics(delta: float) -> State:
	# 1. PHYSIQUE DE BASE
	parent.physics_component.apply_gravity(delta)
	
	# 2. MOUVEMENT AU SOL
	var movement = InputManager.get_movement()
	if movement != 0:
		parent.physics_component.apply_movement(delta)
	else:
		parent.physics_component.apply_friction(delta)
	
	# 3. ANIMATION DYNAMIQUE
	_update_animation()
	
	# 4. MOUVEMENT
	parent.move_and_slide()
	
	# 5. TRANSITIONS (vers AirState quand on quitte le sol)
	return StateTransitions.get_instance().get_next_state(self, parent, delta)

func _update_animation():
	"""Met à jour l'animation selon le mouvement"""
	var movement = InputManager.get_movement()
	
	if movement != 0:
		parent.sprite.play("Run")
	else:
		parent.sprite.play("Idle")
