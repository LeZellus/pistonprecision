# scripts/player/states/DeathState.gd - VERSION AUTOMATIQUE SIMPLIFIÉE
class_name DeathState
extends State

var death_transition_manager: Node
var transition_started: bool = false

func _ready():
	animation_name = "Death"

func enter() -> void:
	super.enter()
	transition_started = false
	
	print("💀 DeathState: Entrée dans l'état de mort")
	
	# Immobiliser le joueur
	parent.velocity = Vector2.ZERO
	parent.sprite.visible = true
	
	# Référence au DeathTransitionManager
	death_transition_manager = get_node_or_null("/root/DeathTransitionManager")
	if not death_transition_manager:
		push_error("DeathTransitionManager introuvable!")
		_fallback_death()
		return
	
	# Connecter le signal de fin
	if not death_transition_manager.transition_complete.is_connected(_on_transition_complete):
		death_transition_manager.transition_complete.connect(_on_transition_complete, CONNECT_ONE_SHOT)
	
	# Séquence automatique
	_play_death_effects()
	_start_automatic_transition()
	
	# Enregistrer la mort
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()

func _play_death_effects():
	"""Effets visuels et sonores de mort"""
	AudioManager.play_sfx("player/death", 0.8)
	
	if parent.sprite.sprite_frames.has_animation("Death"):
		parent.sprite.play("Death")
	else:
		_play_death_fallback_effect()
	
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(15.0, 0.8)

func _play_death_fallback_effect():
	var tween = create_tween()
	tween.parallel().tween_property(parent.sprite, "modulate", Color.RED, 0.3)
	tween.parallel().tween_property(parent.sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(parent.sprite, "modulate:a", 0.0, 0.5)

func _start_automatic_transition():
	"""Démarre la transition automatique après un court délai"""
	await get_tree().create_timer(0.6).timeout  # Court délai pour voir les effets
	
	if death_transition_manager:
		death_transition_manager.start_fast_death_transition()
		transition_started = true
		print("🎬 Transition automatique démarrée")

func _on_transition_complete():
	"""Appelé automatiquement quand la transition se termine"""
	print("✅ Transition terminée - respawn automatique")
	_respawn_player()
	
	# Changer d'état pour respawn
	var respawn_state = _get_respawn_state()
	if respawn_state:
		parent.state_machine.change_state(respawn_state)

func process_physics(delta: float) -> State:
	# Maintenir immobilisation pendant la transition
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	
	# Pas de logique de sortie ici - tout géré par les signaux
	return null

func _respawn_player():
	"""Respawn via le handler"""
	var respawn_pos = parent.death_handler.get_respawn_position()
	parent.global_position = respawn_pos
	parent.death_handler.reset_player_state()
	print("🔄 Joueur respawné à: %v" % respawn_pos)

func _get_respawn_state() -> State:
	"""État de retour après respawn"""
	var air_state = parent.state_machine.get_node("AirState")
	return air_state if air_state else parent.state_machine.get_node("GroundState")

func _fallback_death():
	"""Système de secours si pas de transition"""
	print("⚠️ Fallback: mort sans transition")
	await get_tree().create_timer(1.0).timeout
	_respawn_player()
	
	var respawn_state = _get_respawn_state()
	if respawn_state:
		parent.state_machine.change_state(respawn_state)

func exit() -> void:
	"""Nettoyage à la sortie"""
	# Restaurer l'état du joueur
	if parent.sprite:
		parent.sprite.visible = true
		parent.sprite.modulate = Color.WHITE
		parent.sprite.scale = Vector2.ONE
	
	print("✅ DeathState: Sortie de l'état de mort")
