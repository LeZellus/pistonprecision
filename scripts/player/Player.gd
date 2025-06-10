extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Components simplifiés - UN SEUL détecteur au lieu de 3
var detection_system: DetectionSystem
var physics_component: PlayerPhysics
var actions_component: PlayerActions
var controller: PlayerController

# === CACHED REFERENCES ===
var camera: Camera2D
var world_space_state: PhysicsDirectSpaceState2D

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === PHYSICS STATE ===
var was_grounded: bool = false
var wall_jump_timer: float = 0.0
const WALL_JUMP_GRACE_TIME: float = 0.15

# === DEATH SYSTEM ===
var is_dead: bool = false
var death_immunity_timer: float = 0.0
var transition_immunity_timer: float = 0.0

const DEATH_IMMUNITY_TIME: float = 0.5
const TRANSITION_IMMUNITY_TIME: float = 1.0

func _process(delta: float):
	# Mise à jour des timers d'immunité
	if death_immunity_timer > 0:
		death_immunity_timer -= delta
	
	if transition_immunity_timer > 0:
		transition_immunity_timer -= delta
	
	# Le PlayerController a son propre _process, pas besoin de l'appeler

func _ready():
	world_space_state = get_world_2d().direct_space_state
	camera = get_viewport().get_camera_2d()
	
	_setup_components()
	_connect_signals()
	state_machine.init(self)
	add_to_group("player")

func _physics_process(delta: float):
	# IMPORTANT: Bloquer complètement la physique si mort
	if is_dead:
		return
	
	# Le PlayerController a son propre _physics_process, pas besoin de l'appeler
	# Il s'exécute automatiquement car c'est un node enfant

func _setup_components():
	"""Setup simplifié avec un seul système de détection"""
	# UN SEUL détecteur unifié
	detection_system = DetectionSystem.new(self)
	physics_component = PlayerPhysics.new(self)
	actions_component = PlayerActions.new(self)
	controller = PlayerController.new(self)
	
	# Ajout optimisé
	for component in [detection_system, physics_component, actions_component, controller]:
		add_child(component)

func _connect_signals():
	"""Connexion des signaux simplifiée"""
	var signals = [
		[InputManager.rotate_left_requested, _on_rotate_left],
		[InputManager.rotate_right_requested, _on_rotate_right],
		[InputManager.push_requested, _on_push_requested]
	]
	
	for signal_data in signals:
		if not signal_data[0].is_connected(signal_data[1]):
			signal_data[0].connect(signal_data[1])

func _unhandled_input(event: InputEvent):
	# IMPORTANT: Bloquer les inputs si mort
	if is_dead:
		return
	
	state_machine.process_input(event)

# === API SIMPLIFIÉE ===
func can_wall_slide() -> bool:
	return detection_system.is_touching_wall() and wall_jump_timer <= 0

# === COMPATIBILITY PROPERTIES (pour garder le code existant) ===
var wall_detector: DetectionSystem:
	get: return detection_system

var ground_detector: DetectionSystem:
	get: return detection_system
	
var push_detector: DetectionSystem:
	get: return detection_system

# === ROTATION & PUSH ===
func _on_rotate_left():
	actions_component.rotate_piston(-1)

func _on_rotate_right():
	actions_component.rotate_piston(1)

func _on_push_requested():
	actions_component.execute_push()
	
func trigger_death():
	"""Déclenche la mort du joueur"""
	if is_dead or has_death_immunity():
		print("Player: Mort ignorée (déjà mort ou immunité)")
		return
	
	print("Player: Mort déclenchée!")
	is_dead = true
	
	# Arrêter COMPLÈTEMENT le mouvement
	velocity = Vector2.ZERO
	
	# Désactiver la collision (optionnel, empêche autres interactions)
	collision_shape.set_deferred("disabled", true)
	
	# Effet visuel de mort
	_play_death_effect()
	
	# Respawn après délai
	await get_tree().create_timer(1.5).timeout
	respawn()

func _play_death_effect():
	"""Effet visuel de mort"""
	# Particule de mort
	ParticleManager.emit_death(global_position)
	
	# Camera shake
	if camera and camera.has_method("shake"):
		camera.shake(10.0, 0.8)
	
	# Son de mort
	AudioManager.play_sfx("player/death", 0.8)
	
	# Rendre invisible
	sprite.visible = false

func respawn():
	"""Fait respawn le joueur"""
	print("Player: Respawn!")
	
	# IMPORTANT: Reset l'état de mort AVANT tout le reste
	is_dead = false
	
	# Réactiver la collision
	collision_shape.set_deferred("disabled", false)
	
	# Rendre visible
	sprite.visible = true
	
	# Position de respawn (à adapter selon votre système)
	global_position = Vector2(0, 0)
	velocity = Vector2.ZERO
	
	# Immunité temporaire APRÈS le reset
	death_immunity_timer = DEATH_IMMUNITY_TIME
	
	# Reset state machine vers un état sûr
	if state_machine and state_machine.has_method("change_state"):
		var idle_state = state_machine.get_node_or_null("IdleState")
		if idle_state:
			state_machine.change_state(idle_state)
	
	print("Player: Respawn terminé, immunité active pour ", DEATH_IMMUNITY_TIME, "s")

func start_room_transition():
	"""Appelé au début d'une transition de salle"""
	transition_immunity_timer = TRANSITION_IMMUNITY_TIME

func has_death_immunity() -> bool:
	"""Vérifie si le joueur a une immunité"""
	return death_immunity_timer > 0

func has_transition_immunity() -> bool:
	"""Vérifie si le joueur est en immunité de transition"""
	return transition_immunity_timer > 0

func is_player_dead() -> bool:
	"""Vérifie si le joueur est mort"""
	return is_dead
