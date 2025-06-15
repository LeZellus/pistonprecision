# scripts/player/states/DeathState.gd - Version corrigée
class_name DeathState
extends State

var death_transition_manager: DeathTransitionManager
var has_respawned: bool = false
var transition_complete: bool = false
var death_registered: bool = false
var waiting_for_input: bool = false

# === DÉTECTION SPAM ===
var spam_detection_active: bool = false
var spam_press_count: int = 0
var spam_timer: float = 0.0
const SPAM_WINDOW_TIME: float = 1.0
const SPAM_THRESHOLD: int = 3

func _ready():
	animation_name = "Death"
	
func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		if spam_detection_active and not waiting_for_input:
			_register_spam_press()
			return
		
		if waiting_for_input:
			_perform_respawn()
			get_viewport().set_input_as_handled()

func _process(delta: float):
	if spam_detection_active and spam_timer > 0:
		spam_timer -= delta
		if spam_timer <= 0:
			_reset_spam_detection()

func enter() -> void:
	super.enter()
	has_respawned = false
	transition_complete = false
	death_registered = false
	waiting_for_input = false
	
	_start_spam_detection()
	_register_death()
	
	parent.velocity = Vector2.ZERO
	
	# === CORRECTION : Chercher spécifiquement le DeathTransitionManager ===
	death_transition_manager = _find_death_transition_manager()
	
	if death_transition_manager:
		_connect_transition_signals()
		death_transition_manager.start_death_transition_no_respawn()
	else:
		print("DeathState: ERREUR - DeathTransitionManager introuvable!")
		waiting_for_input = true
	
	_play_death_effects()

func _find_death_transition_manager() -> DeathTransitionManager:
	"""Trouve le vrai DeathTransitionManager de manière sécurisée"""
	# DEBUG: Voir ce qui existe dans /root/
	var root = get_tree().root
	print("=== DEBUG: Enfants de root ===")
	for child in root.get_children():
		print("  - %s (type: %s)" % [child.name, child.get_class()])
	
	# Méthode 1: Par nom exact avec debug
	var manager = get_node_or_null("/root/DeathTransitionManager")
	print("DEBUG: get_node_or_null retourne: %s" % manager)
	if manager:
		print("  Type: %s, Script: %s" % [manager.get_class(), manager.get_script()])
		if manager is DeathTransitionManager:
			print("DeathState: DeathTransitionManager trouvé par chemin")
			return manager
		else:
			print("ERREUR: L'objet trouvé n'est PAS un DeathTransitionManager!")
	
	# Méthode 2: Chercher manuellement
	for child in root.get_children():
		if child.name == "DeathTransitionManager":
			print("DEBUG: Trouvé %s, vérifiant le type..." % child.name)
			if child is DeathTransitionManager:
				print("DeathState: DeathTransitionManager trouvé dans root")
				return child
			else:
				print("ERREUR: %s n'est pas du bon type!" % child.name)
	
	print("ERREUR: Aucun DeathTransitionManager trouvé!")
	return null

func _search_for_manager(node: Node) -> DeathTransitionManager:
	"""Recherche récursive du DeathTransitionManager"""
	if node is DeathTransitionManager:
		return node
	
	for child in node.get_children():
		var result = _search_for_manager(child)
		if result:
			return result
	
	return null

func _connect_transition_signals():
	"""Connecte les signaux de manière sécurisée"""
	if not death_transition_manager:
		print("ERREUR: Impossible de connecter - death_transition_manager est null!")
		return
	
	# Vérifier que l'objet a bien les signaux
	if not death_transition_manager.has_signal("transition_middle_reached"):
		print("ERREUR: L'objet n'a pas le signal transition_middle_reached!")
		return
	
	if not death_transition_manager.has_signal("transition_complete"):
		print("ERREUR: L'objet n'a pas le signal transition_complete!")
		return
	
	# Déconnecter d'abord si déjà connecté
	if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
		death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
	if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
		death_transition_manager.transition_complete.disconnect(_on_transition_complete)
	
	# Reconnecter
	death_transition_manager.transition_middle_reached.connect(_on_transition_middle)
	death_transition_manager.transition_complete.connect(_on_transition_complete)
	print("DeathState: Signaux connectés avec succès")

# === MÉTHODES SPAM ===
func _start_spam_detection():
	spam_detection_active = true
	spam_press_count = 0
	spam_timer = SPAM_WINDOW_TIME

func _register_spam_press():
	spam_press_count += 1
	spam_timer = SPAM_WINDOW_TIME
	
	if spam_press_count >= SPAM_THRESHOLD:
		_on_spam_detected()

func _on_spam_detected():
	print("DeathState: SPAM DÉTECTÉ!")
	_reset_spam_detection()

func _reset_spam_detection():
	spam_detection_active = false
	spam_press_count = 0
	spam_timer = 0.0

# === RESTE DU CODE ===
func _register_death():
	if death_registered:
		return
	
	death_registered = true
	
	var game_manager = get_tree().get_first_node_in_group("managers")
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()

func process_physics(_delta: float) -> State:
	if parent:
		parent.velocity = Vector2.ZERO
	return null

func process_input(event: InputEvent) -> State:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		if spam_detection_active and not waiting_for_input:
			_register_spam_press()
			return null
		
		if waiting_for_input:
			_perform_respawn()
			return null
	return null

func process_frame(_delta: float) -> State:
	if has_respawned and transition_complete:
		return StateTransitions.get_instance()._get_state("FallState")
	return null

func _on_transition_middle():
	_reset_spam_detection()
	waiting_for_input = true

func _on_transition_complete():
	transition_complete = true

func _perform_respawn():
	if has_respawned or not parent:
		return
	
	has_respawned = true
	waiting_for_input = false
	
	parent.global_position = Vector2(-185, 30)
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	await get_tree().process_frame
	
	parent.sprite.modulate.a = 1.0
	parent.sprite.visible = true
	parent.start_respawn_immunity()
	
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
	_reset_spam_detection()
	
	if death_transition_manager:
		if death_transition_manager.transition_middle_reached.is_connected(_on_transition_middle):
			death_transition_manager.transition_middle_reached.disconnect(_on_transition_middle)
		if death_transition_manager.transition_complete.is_connected(_on_transition_complete):
			death_transition_manager.transition_complete.disconnect(_on_transition_complete)
