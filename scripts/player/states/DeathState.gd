# scripts/player/states/DeathState.gd - Timer corrigé
class_name DeathState
extends State

var death_timer: float = 0.0
const DEATH_DURATION: float = 2.0

func _ready():
	animation_name = "Death"

func enter() -> void:
	super.enter()
	death_timer = DEATH_DURATION
	
	print("DeathState: Entrée dans l'état de mort (timer: ", DEATH_DURATION, "s)")
	
	# Arrêter le mouvement
	parent.velocity = Vector2.ZERO
	
	# Effets visuels/audio
	_play_death_effects()

func process_frame(delta: float) -> State:
	print("DeathState: Timer = ", death_timer)
	death_timer -= delta
	
	if death_timer <= 0.0:
		print("DeathState: Timer écoulé, respawn!")
		return _respawn()
	
	return null

func process_physics(_delta: float) -> State:
	# Garder le joueur immobile pendant la mort
	parent.velocity = Vector2.ZERO
	# PAS de move_and_slide() pendant la mort
	return null

func process_input(_event: InputEvent) -> State:
	# Respawn anticipé avec espace/enter
	if _event.is_action_pressed("ui_accept") or _event.is_action_pressed("jump"):
		print("DeathState: Respawn anticipé demandé")
		return _respawn()
	
	return null

func _play_death_effects():
	print("DeathState: Lancement des effets de mort")
	
	# Particules
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	# Camera shake
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(5.0, 0.5)
	
	# Audio
	AudioManager.play_sfx("player/death", 0.8)
	
	# Visuel - fade out progressif
	var tween = parent.create_tween()
	tween.tween_property(parent.sprite, "modulate:a", 0.0, 0.3)

func _respawn() -> State:
	print("DeathState: Début du respawn...")
	
	# Reset position - position sécurisée
	parent.global_position = Vector2(0, -50)  # Un peu au-dessus pour éviter de re-trigger
	parent.velocity = Vector2.ZERO
	
	# Reset visuel
	parent.sprite.modulate.a = 1.0
	parent.sprite.visible = true
	
	# Activer l'immunité
	parent.start_respawn_immunity()
	
	print("DeathState: Respawn terminé, transition vers IdleState")
	
	# Transition directe vers IdleState
	return StateTransitions._get_state("IdleState")

func exit() -> void:
	death_timer = 0.0
	print("DeathState: Sortie de l'état de mort")
