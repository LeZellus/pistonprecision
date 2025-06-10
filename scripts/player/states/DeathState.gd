# scripts/player/states/DeathState.gd
class_name DeathState
extends State

var death_timer: float = 0.0
const DEATH_DURATION: float = 1.5

func _ready():
	animation_name = "Death"  # Si tu as cette animation

func enter() -> void:
	super.enter()
	death_timer = DEATH_DURATION
	
	# Arrêter le mouvement
	parent.velocity = Vector2.ZERO
	parent.set_physics_process(false)
	
	# Effets visuels/audio
	_play_death_effects()
	
	print("Player: Mort - début de l'état")

func process_frame(delta: float) -> State:
	death_timer -= delta
	
	if death_timer <= 0.0:
		return _respawn()
	
	return null

func process_physics(_delta: float) -> State:
	# Pas de physique pendant la mort
	return null

func process_input(_event: InputEvent) -> State:
	# Optionnel : permettre un respawn anticipé avec une touche
	if _event.is_action_pressed("ui_accept"):  # Ou "jump"
		print("Player: Respawn anticipé demandé")
		return _respawn()
	
	return null

func _play_death_effects():
	"""Centralise tous les effets de mort"""
	# Particules
	ParticleManager.emit_death(parent.global_position)
	
	# Camera shake
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(10.0, 0.8)
	
	# Audio
	AudioManager.play_sfx("player/death", 0.8)
	
	# Visuel - fade out au lieu de disparaître brutalement
	var tween = parent.create_tween()
	tween.tween_property(parent.sprite, "modulate:a", 0.3, 0.5)

func _respawn() -> State:
	"""Gère le respawn et retourne l'état suivant"""
	print("Player: Respawn en cours...")
	
	# Reset position
	parent.global_position = _get_respawn_position()
	parent.velocity = Vector2.ZERO
	
	# Reset visuel
	parent.sprite.modulate.a = 1.0
	parent.sprite.visible = true
	
	# Réactiver la physique
	parent.set_physics_process(true)
	
	# Activer l'immunité
	parent.start_respawn_immunity()
	
	# Retourner vers l'état approprié
	if parent.is_on_floor():
		return StateTransitions._get_state("IdleState")
	else:
		return StateTransitions._get_state("FallState")

func _get_respawn_position() -> Vector2:
	"""Détermine la position de respawn"""
	# Version 1: Position fixe (simple)
	# return Vector2(0, 0)
	
	# Version 2: Avec GameManager/CheckpointManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("get_last_checkpoint"):
		return game_manager.get_last_checkpoint()
	
	# Version 3: Spawn de la salle actuelle
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("get_room_spawn_position"):
		return scene_manager.get_room_spawn_position()
	
	# Fallback
	return Vector2(0, 0)

func exit() -> void:
	death_timer = 0.0
	print("Player: Sortie de l'état de mort")

# === MÉTHODES UTILITAIRES ===
func can_transition() -> bool:
	"""Vérifie si on peut sortir de l'état de mort"""
	return death_timer <= 0.0

func force_respawn():
	"""Force le respawn (appelable depuis l'extérieur si nécessaire)"""
	death_timer = 0.0
