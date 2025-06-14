# scripts/player/states/DeathState.gd - Version avec respawn manuel
class_name DeathState
extends State

var death_transition_manager: DeathTransitionManager
var has_respawned: bool = false
var transition_complete: bool = false
var death_registered: bool = false
var waiting_for_input: bool = false  # ✅ NOUVEAU : État d'attente input

func _ready():
	animation_name = "Death"
	
func _input(event: InputEvent):
	if not waiting_for_input:
		return
		
	# Test actions Godot
	if event.is_action_pressed("ui_accept"):
		_perform_respawn()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		_perform_respawn()
		get_viewport().set_input_as_handled()

func enter() -> void:
	super.enter()
	has_respawned = false
	transition_complete = false
	death_registered = false
	waiting_for_input = false
	
	_register_death()
	
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
		
		# ✅ MODIFIÉ : Transition sans respawn automatique
		death_transition_manager.start_death_transition_no_respawn()
	else:
		# Fallback simple - attendre input directement
		waiting_for_input = true
	
	_play_death_effects()

func _register_death():
	if death_registered:
		return
	
	death_registered = true
	
	var game_manager = get_tree().get_first_node_in_group("managers")
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()
		print("DeathState: Mort enregistrée - Total: %d" % game_manager.death_count)

func process_physics(_delta: float) -> State:
	if parent:
		parent.velocity = Vector2.ZERO
	return null

func process_input(event: InputEvent) -> State:
	# ✅ MODIFIÉ : Input uniquement quand on attend + debug
	if waiting_for_input and event.is_action_pressed("ui_accept"):
		print("DeathState: ui_accept détecté, respawn...")
		_perform_respawn()
		return null
	elif waiting_for_input and event.is_action_pressed("jump"):
		print("DeathState: jump détecté, respawn...")
		_perform_respawn()
		return null
	return null

func process_frame(_delta: float) -> State:
	if has_respawned and transition_complete:
		return StateTransitions.get_instance()._get_state("FallState")
	return null

# ✅ NOUVEAU : Appelé par le DeathTransitionManager quand l'animation est finie
func _on_transition_middle():
	waiting_for_input = true
	print("DeathState: En attente d'input pour respawn... (waiting_for_input = true)")

func _on_transition_complete():
	transition_complete = true

func _perform_respawn():
	if has_respawned or not parent:
		return
	
	has_respawned = true
	waiting_for_input = false
	
	print("DeathState: Respawn du joueur...")
	
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
	
	# Nettoyer la transition (finir l'animation)
	if death_transition_manager:
		death_transition_manager.cleanup_transition()

func _play_death_effects():
	if not parent:
		return
	
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(8.0, 0.6)
	
	AudioManager.play_sfx("player/death", 0.8)

func exit() -> void:
	waiting_for_input = false
	
	# Déconnexion propre des signaux
	if death_transition_manager:
		if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
		if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.disconnect(_on_transition_complete)
