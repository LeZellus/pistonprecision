# scripts/player/states/DeathState.gd - Version DEBUG COMPLET
class_name DeathState
extends State

var death_transition_manager: DeathTransitionManager
var has_respawned: bool = false
var transition_complete: bool = false
var debug_entry_time: float = 0.0

func _ready():
	animation_name = "Death"

func enter() -> void:
	debug_entry_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	print("🔥 DeathState.enter() - DÉBUT à ", debug_entry_time, "s")
	print("  ├─ Parent valide: ", parent != null)
	print("  ├─ Parent nom: ", parent.name if parent else "NULL")
	print("  ├─ Parent position: ", parent.global_position if parent else "NULL")
	print("  ├─ Parent velocity: ", parent.velocity if parent else "NULL")
	print("  └─ Player mort avant enter: ", parent.is_player_dead() if parent else "UNKNOWN")
	
	super.enter()
	has_respawned = false
	transition_complete = false
	
	# Vérifier l'état du joueur
	if parent:
		print("🔥 DeathState: État du joueur:")
		print("  ├─ Vitesse actuelle: ", parent.velocity)
		print("  ├─ Au sol: ", parent.is_on_floor())
		print("  ├─ Position: ", parent.global_position)
		print("  ├─ Immunité: ", parent.has_death_immunity())
		print("  └─ State machine actuel: ", parent.state_machine.current_state.get_script().get_global_name() if parent.state_machine.current_state else "NULL")
	
	# Arrêter le mouvement
	parent.velocity = Vector2.ZERO
	print("🔥 DeathState: Vélocité mise à zéro")
	
	# Obtenir le gestionnaire de transition
	death_transition_manager = _get_transition_manager()
	print("🔥 DeathState: DeathTransitionManager obtenu: ", death_transition_manager != null)
	
	if death_transition_manager:
		print("🔥 DeathState: Connexion des signaux...")
		
		# Déconnecter d'abord si déjà connecté (sécurité)
		if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
			print("  ├─ Signal middle déconnecté (était connecté)")
		if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.disconnect(_on_transition_complete)
			print("  ├─ Signal complete déconnecté (était connecté)")
		
		# Reconnecter
		death_transition_manager.transition_middle_reached.connect(_on_transition_middle)
		death_transition_manager.transition_complete.connect(_on_transition_complete)
		print("  ├─ Signaux reconnectés")
		print("  └─ Lancement de la transition...")
		
		# Lancer la transition avec délai pour voir les effets de mort
		death_transition_manager.start_death_transition(1.8, 0.6)
		print("🔥 DeathState: Transition lancée (1.8s total, fade après 0.6s)")
	else:
		print("🔥 DeathState: FALLBACK - Pas de transition manager")
		await get_tree().create_timer(1.0).timeout
		print("🔥 DeathState: Timer fallback terminé, respawn forcé")
		_perform_respawn()
		transition_complete = true
	
	# Effets visuels/audio
	print("🔥 DeathState: Lancement des effets de mort")
	_play_death_effects()
	print("🔥 DeathState.enter() - FIN")

func _get_transition_manager() -> DeathTransitionManager:
	var manager = get_node_or_null("/root/DeathTransitionManager")
	print("🔥 DeathState: DeathTransitionManager trouvé: ", manager != null)
	if manager:
		print("  └─ Manager nom: ", manager.name)
	return manager

func process_physics(_delta: float) -> State:
	# Debug périodique (toutes les 60 frames = ~1 seconde)
	if Engine.get_process_frames() % 60 == 0:
		print("🔥 DeathState.process_physics() - État:")
		print("  ├─ has_respawned: ", has_respawned)
		print("  ├─ transition_complete: ", transition_complete)
		print("  ├─ Temps écoulé: ", Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - debug_entry_time, "s")
		print("  └─ Velocity: ", parent.velocity if parent else "NULL")
	
	# Pas de mouvement pendant la mort
	if parent:
		parent.velocity = Vector2.ZERO
	return null

func process_input(event: InputEvent) -> State:
	# Log des inputs pendant la mort
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		print("🔥 DeathState.process_input() - INPUT DÉTECTÉ:")
		print("  ├─ Action: ", "ui_accept" if event.is_action_pressed("ui_accept") else "jump")
		print("  ├─ has_respawned: ", has_respawned)
		print("  └─ Appel _trigger_early_respawn()")
		
		if not has_respawned:
			_trigger_early_respawn()
		else:
			print("  └─ Ignoré (déjà respawné)")
	
	return null

func _trigger_early_respawn():
	print("🔥 DeathState._trigger_early_respawn() - DÉBUT")
	print("  ├─ death_transition_manager valide: ", death_transition_manager != null)
	
	if death_transition_manager and death_transition_manager.has_method("quick_death_transition"):
		print("  ├─ Appel quick_death_transition()")
		death_transition_manager.quick_death_transition()
	else:
		print("  ├─ Méthode quick_death_transition non disponible")
		print("  └─ Respawn forcé immédiat")
		_perform_respawn()
		transition_complete = true

func _on_transition_middle():
	print("🔥 DeathState._on_transition_middle() - SIGNAL REÇU")
	print("  ├─ Temps: ", Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - debug_entry_time, "s depuis l'entrée")
	print("  ├─ has_respawned avant: ", has_respawned)
	print("  └─ Appel _perform_respawn()")
	_perform_respawn()

func _on_transition_complete():
	print("🔥 DeathState._on_transition_complete() - SIGNAL REÇU")
	print("  ├─ Temps: ", Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - debug_entry_time, "s depuis l'entrée")
	print("  ├─ has_respawned: ", has_respawned)
	print("  ├─ transition_complete avant: ", transition_complete)
	print("  └─ Marquage transition_complete = true")
	transition_complete = true

func _perform_respawn():
	print("🔥 DeathState._perform_respawn() - DÉBUT")
	print("  ├─ has_respawned avant: ", has_respawned)
	
	if has_respawned:
		print("  └─ DÉJÀ RESPAWNÉ - SORTIE")
		return
	
	has_respawned = true
	print("  ├─ has_respawned = true")
	
	if not parent:
		print("  └─ ERREUR: Parent null!")
		return
	
	print("  ├─ Position avant respawn: ", parent.global_position)
	print("  ├─ Velocity avant respawn: ", parent.velocity)
	
	# Reset position - position sécurisée
	parent.global_position = Vector2(-185, 30)
	parent.velocity = Vector2.ZERO
	print("  ├─ Position après respawn: ", parent.global_position)
	print("  ├─ Velocity après respawn: ", parent.velocity)
	
	parent.move_and_slide()
	await get_tree().process_frame  # Attendre 1 frame pour mise à jour collision

	
	# Reset visuel
	parent.sprite.modulate.a = 1.0
	parent.sprite.visible = true
	print("  ├─ Sprite remis visible (alpha=1.0)")
	
	# Activer l'immunité
	parent.start_respawn_immunity()
	print("  ├─ Immunité activée")
	
	# État du joueur après respawn
	print("  ├─ Au sol après respawn: ", parent.is_on_floor())
	print("  ├─ Immunité active: ", parent.has_death_immunity())
	print("  └─ _perform_respawn() - FIN")

func process_frame(_delta: float) -> State:
	# Log détaillé de la condition de sortie
	if has_respawned and transition_complete:
		print("🔥 DeathState.process_frame() - CONDITIONS DE SORTIE REMPLIES:")
		print("  ├─ has_respawned: ", has_respawned)
		print("  ├─ transition_complete: ", transition_complete)
		print("  ├─ Temps total: ", Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - debug_entry_time, "s")
		print("  ├─ État du joueur:")
		print("  │   ├─ Position: ", parent.global_position if parent else "NULL")
		print("  │   ├─ Velocity: ", parent.velocity if parent else "NULL")
		print("  │   ├─ Au sol: ", parent.is_on_floor() if parent else "NULL")
		print("  │   └─ Immunité: ", parent.has_death_immunity() if parent else "NULL")
		print("  └─ TRANSITION VERS IdleState")
		
		var fall_state = StateTransitions._get_state("FallState")
		if fall_state:
			print("      ├─ IdleState trouvé: ", fall_state.name)
			return fall_state
		else:
			print("      └─ ERREUR: IdleState non trouvé!")
			return null
	
	return null

func _play_death_effects():
	print("🔥 DeathState._play_death_effects() - DÉBUT")
	
	if not parent:
		print("  └─ Parent null, pas d'effets")
		return
	
	# Particules
	print("  ├─ Émission particules de mort à ", parent.global_position)
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	# Camera shake
	if parent.camera and parent.camera.has_method("shake"):
		print("  ├─ Camera shake activé")
		parent.camera.shake(8.0, 0.6)
	else:
		print("  ├─ Pas de camera ou méthode shake manquante")
	
	# Audio
	print("  ├─ Son de mort")
	AudioManager.play_sfx("player/death", 0.8)
	print("  └─ _play_death_effects() - FIN")

func exit() -> void:
	print("🔥 DeathState.exit() - DÉBUT")
	print("  ├─ has_respawned: ", has_respawned)
	print("  ├─ transition_complete: ", transition_complete)
	print("  ├─ Temps total dans DeathState: ", Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - debug_entry_time, "s")
	
	# Déconnecter les signaux
	if death_transition_manager:
		print("  ├─ Déconnexion des signaux...")
		if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
			print("  │   ├─ Signal middle déconnecté")
		if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.disconnect(_on_transition_complete)
			print("  │   └─ Signal complete déconnecté")
	else:
		print("  ├─ Pas de death_transition_manager à déconnecter")
	
	# État final du joueur
	if parent:
		print("  ├─ État final du joueur:")
		print("  │   ├─ Position: ", parent.global_position)
		print("  │   ├─ Velocity: ", parent.velocity)
		print("  │   ├─ Au sol: ", parent.is_on_floor())
		print("  │   ├─ Immunité: ", parent.has_death_immunity())
		print("  │   └─ Sprite visible: ", parent.sprite.visible)
	
	print("🔥 DeathState.exit() - FIN")
	print("═══════════════════════════════════════════════════════════════")
