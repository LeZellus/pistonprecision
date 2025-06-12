class_name DeathState
extends State

var death_transition_manager: DeathTransitionManager
var has_respawned: bool = false
var transition_complete: bool = false  # NOUVEAU FLAG

func _ready():
	animation_name = "Death"

func enter() -> void:
	super.enter()
	has_respawned = false
	transition_complete = false  # Reset du flag
	
	print("DeathState: Entrée dans l'état de mort")
	
	# Arrêter le mouvement
	parent.velocity = Vector2.ZERO
	
	# Obtenir le gestionnaire de transition
	death_transition_manager = _get_transition_manager()
	
	if death_transition_manager:
		# Connecter les signaux
		if not death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.connect(_on_transition_middle)
		if not death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.connect(_on_transition_complete)
		
		# Lancer la transition avec délai pour voir les effets de mort
		death_transition_manager.start_death_transition(1.8, 0.6)  # Total 1.8s, fade après 0.6s
	else:
		# Fallback sans transition
		await get_tree().create_timer(1.0).timeout
		_perform_respawn()
		transition_complete = true  # Marquer comme terminé
	
	# Effets visuels/audio
	_play_death_effects()

func _get_transition_manager() -> DeathTransitionManager:
	 # Retourne le DeathTransitionManager
	return DeathTransitionManager

func process_physics(_delta: float) -> State:
	# Pas de mouvement pendant la mort
	parent.velocity = Vector2.ZERO
	return null

func process_input(_event: InputEvent) -> State:
	# Respawn anticipé avec espace/enter
	if not has_respawned and (_event.is_action_pressed("ui_accept") or _event.is_action_pressed("jump")):
		print("DeathState: Respawn anticipé demandé")
		_trigger_early_respawn()
	
	return null

func _trigger_early_respawn():
	"""Force un respawn anticipé"""
	if death_transition_manager:
		# Accélérer la transition
		death_transition_manager.quick_death_transition()

func _on_transition_middle():
	"""Appelé au milieu de la transition (écran noir)"""
	print("DeathState: Milieu de transition - Preparation du respawn")
	_perform_respawn()

func _on_transition_complete():
	"""Appelé à la fin de la transition (fade in terminé)"""
	print("DeathState: Transition terminée - Joueur peut maintenant être actif")
	transition_complete = true  # NOUVEAU : Marquer la transition comme terminée

func _perform_respawn():
	"""Effectue le respawn du joueur (sans le rendre actif)"""
	if has_respawned:
		return
	
	has_respawned = true
	print("DeathState: Préparation du respawn...")
	
	# Reset position - position sécurisée
	parent.global_position = Vector2(-185, 30)
	parent.velocity = Vector2.ZERO
	
	# Reset visuel
	parent.sprite.modulate.a = 1.0
	parent.sprite.visible = true
	
	# Activer l'immunité réduite
	parent.start_respawn_immunity()
	
	# TODO: Ici vous pourrez ajouter votre animation de respawn
	# parent.sprite.play("Respawn")

func process_frame(_delta: float) -> State:
	# MODIFIÉ : Transition vers IdleState seulement après la fin complète de la transition
	if has_respawned and transition_complete:
		print("DeathState: Transition vers IdleState")
		return StateTransitions._get_state("IdleState")
	
	return null

func _play_death_effects():
	"""Effets de mort (sans fade du sprite car géré par transition)"""
	print("DeathState: Lancement des effets de mort")
	
	# Particules
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	# Camera shake
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(8.0, 0.6)
	
	# Audio
	AudioManager.play_sfx("player/death", 0.8)

func exit() -> void:
	print("DeathState: Sortie de l'état de mort")
	
	# Déconnecter les signaux
	if death_transition_manager:
		if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
		if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.disconnect(_on_transition_complete)
