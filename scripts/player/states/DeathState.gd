# scripts/player/states/DeathState.gd - Version nettoyée
class_name DeathState
extends State

var death_transition_manager: DeathTransitionManager
var has_respawned: bool = false
var transition_complete: bool = false

func _ready():
	animation_name = "Death"

func enter() -> void:
	super.enter()
	has_respawned = false
	transition_complete = false
	
	# Arrêter le mouvement
	parent.velocity = Vector2.ZERO
	
	# Obtenir le gestionnaire de transition
	death_transition_manager = get_node_or_null("/root/DeathTransitionManager")
	
	if death_transition_manager:
		# Connexion sécurisée des signaux
		if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
		if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.disconnect(_on_transition_complete)
		
		death_transition_manager.transition_middle_reached.connect(_on_transition_middle)
		death_transition_manager.transition_complete.connect(_on_transition_complete)
		death_transition_manager.start_death_transition(1.8, 0.6)
	else:
		# Fallback simple
		await get_tree().create_timer(1.0).timeout
		_perform_respawn()
		transition_complete = true
	
	_play_death_effects()

func process_physics(_delta: float) -> State:
	if parent:
		parent.velocity = Vector2.ZERO
	return null

func process_input(event: InputEvent) -> State:
	if (event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")) and not has_respawned:
		_trigger_early_respawn()
	return null

func process_frame(_delta: float) -> State:
	if has_respawned and transition_complete:
		return StateTransitions._get_state("IdleState")
	return null

func _trigger_early_respawn():
	if death_transition_manager and death_transition_manager.has_method("quick_death_transition"):
		death_transition_manager.quick_death_transition()
	else:
		_perform_respawn()
		transition_complete = true

func _on_transition_middle():
	_perform_respawn()

func _on_transition_complete():
	transition_complete = true

func _perform_respawn():
	if has_respawned or not parent:
		return
	
	has_respawned = true
	
	# Reset position et vitesse
	parent.global_position = Vector2(-185, 30)
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	await get_tree().process_frame
	
	# Reset visuel
	parent.sprite.modulate.a = 1.0
	parent.sprite.visible = true
	
	# Activer l'immunité
	parent.start_respawn_immunity()

func _play_death_effects():
	if not parent:
		return
	
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(8.0, 0.6)
	
	AudioManager.play_sfx("player/death", 0.8)

func exit() -> void:
	# Déconnexion propre des signaux
	if death_transition_manager:
		if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
		if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.disconnect(_on_transition_complete)
