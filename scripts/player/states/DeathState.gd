# scripts/player/states/DeathState.gd - VERSION AVEC HANDLERS
class_name DeathState
extends State

var death_timer: float = 0.0
var death_animation_played: bool = false

func _ready():
	animation_name = "Death"

func enter() -> void:
	super.enter()
	death_timer = 2.0
	death_animation_played = false
	
	print("💀 DeathState: Entrée dans l'état de mort")
	
	# Immobiliser le joueur
	parent.velocity = Vector2.ZERO
	parent.sprite.visible = true
	
	# Jouer les effets de mort
	_play_death_effects()
	
	# Enregistrer la mort dans le GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()

func _play_death_effects():
	"""Joue tous les effets visuels et sonores de mort"""
	# Son de mort
	AudioManager.play_sfx("player/death", 0.8)
	
	# Animation de mort si disponible
	if parent.sprite.sprite_frames.has_animation("Death"):
		parent.sprite.play("Death")
		death_animation_played = true
		print("🎬 Animation de mort lancée")
	else:
		print("⚠️ Animation 'Death' introuvable, effet de remplacement")
		_play_death_fallback_effect()
	
	# Particules de mort
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	# Screen shake
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(15.0, 0.8)

func _play_death_fallback_effect():
	"""Effet visuel simple si pas d'animation Death"""
	var tween = create_tween()
	tween.parallel().tween_property(parent.sprite, "modulate", Color.RED, 0.3)
	tween.parallel().tween_property(parent.sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(parent.sprite, "modulate:a", 0.0, 0.5)

func process_physics(delta: float) -> State:
	# Maintenir immobilisation
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	
	# Gérer le timer de respawn
	death_timer -= delta
	
	if death_timer <= 0:
		print("✨ Timer de respawn écoulé - respawn du joueur")
		_respawn_player()
		return _get_respawn_state()
	
	return null

func _respawn_player():
	"""Utilise le DeathHandler pour respawn proprement"""
	# Obtenir la position de respawn via le handler
	var respawn_pos = parent.death_handler.get_respawn_position()
	parent.global_position = respawn_pos
	
	# Remettre l'état du joueur à zéro via le handler
	parent.death_handler.reset_player_state()
	
	print("🔄 Joueur respawné à: %v" % respawn_pos)

func _get_respawn_state() -> State:
	"""Détermine l'état de retour après respawn"""
	# Toujours retourner à AirState pour éviter les bugs de collision
	var air_state = parent.state_machine.get_node("AirState")
	if air_state:
		return air_state
	
	# Fallback vers GroundState
	return parent.state_machine.get_node("GroundState")

func exit() -> void:
	"""Nettoyage à la sortie - s'assurer que le joueur est dans un bon état"""
	if parent.sprite:
		parent.sprite.visible = true
		parent.sprite.modulate = Color.WHITE
		parent.sprite.scale = Vector2.ONE
	
	print("✅ DeathState: Sortie de l'état de mort")
