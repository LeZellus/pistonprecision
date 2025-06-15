# scripts/player/states/DeathState.gd - Version optimisée
class_name DeathState
extends State

var death_transition_manager: DeathTransitionManager
var has_respawned: bool = false
var transition_complete: bool = false
var waiting_for_input: bool = false

# === DÉLAI POUR VOIR L'ANIMATION ===
var death_animation_delay: float = 0.0
const DEATH_VISIBLE_TIME: float = 0.5

func _ready():
	animation_name = "Death"
	
func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		# Pendant le délai : skip vers transition rapide
		if death_animation_delay > 0:
			print("DeathState: Skip animation - transition rapide")
			death_animation_delay = 0.0
			_start_transition(true)  # true = fast
			return
		
		# Sinon : respawn
		if waiting_for_input:
			_perform_respawn()

func _process(delta: float):
	# Délai avant transition normale
	if death_animation_delay > 0:
		death_animation_delay -= delta
		if death_animation_delay <= 0:
			_start_transition(false)  # false = normal

func enter() -> void:
	super.enter()
	has_respawned = false
	transition_complete = false
	waiting_for_input = false
	
	death_animation_delay = DEATH_VISIBLE_TIME
	parent.velocity = Vector2.ZERO
	
	# Enregistrer mort et effets
	_register_death()
	_play_death_effects()

func _start_transition(fast: bool):
	"""Démarre la transition (normale ou rapide)"""
	death_transition_manager = get_node_or_null("/root/DeathTransitionManager") as DeathTransitionManager
	
	if not death_transition_manager:
		print("DeathState: ERREUR - DeathTransitionManager introuvable!")
		waiting_for_input = true
		return
	
	# Connecter signaux
	death_transition_manager.transition_middle_reached.connect(_on_transition_middle, CONNECT_ONE_SHOT)
	death_transition_manager.transition_complete.connect(_on_transition_complete, CONNECT_ONE_SHOT)
	
	# Démarrer transition
	if fast:
		death_transition_manager.start_fast_death_transition()
	else:
		death_transition_manager.start_death_transition_no_respawn()

func _register_death():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()

func _on_transition_middle():
	waiting_for_input = true

func _on_transition_complete():
	transition_complete = true

func _perform_respawn():
	if has_respawned:
		return
	
	has_respawned = true
	waiting_for_input = false
	
	# Repositionner joueur
	parent.global_position = Vector2(-185, 30)
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	await get_tree().process_frame
	
	# Reset visuel
	parent.sprite.modulate.a = 1.0
	parent.sprite.visible = true
	parent.start_respawn_immunity()
	
	# Nettoyer transition
	if death_transition_manager:
		death_transition_manager.cleanup_transition()

func _play_death_effects():
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(8.0, 0.6)
	
	AudioManager.play_sfx("player/death", 0.8)

# === STATE MACHINE (simplifié) ===
func process_physics(_delta: float) -> State:
	parent.velocity = Vector2.ZERO
	return null

func process_frame(_delta: float) -> State:
	if has_respawned and transition_complete:
		return StateTransitions.get_instance()._get_state("FallState")
	return null

func exit() -> void:
	death_animation_delay = 0.0
	waiting_for_input = false
