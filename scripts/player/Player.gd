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

# === DEATH SYSTEM SIMPLIFIÉ ===
var respawn_immunity_timer: float = 0.0
const RESPAWN_IMMUNITY_TIME: float = 1.0

func _process(delta: float):
	# Seulement le timer d'immunité après respawn
	if respawn_immunity_timer > 0:
		respawn_immunity_timer -= delta

func _ready():
	world_space_state = get_world_2d().direct_space_state
	camera = get_viewport().get_camera_2d()
	
	_setup_components()
	_connect_signals()
	state_machine.init(self)
	add_to_group("player")

func _physics_process(_delta: float):
	# IMPORTANT: Bloquer complètement la physique si mort
	if is_player_dead():
		return
	
	# Le PlayerController a son propre _physics_process automatique

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
	if is_player_dead():
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

# === DEATH SYSTEM REFACTORISÉ ===
func trigger_death():
	"""Version simplifiée - délègue tout au DeathState"""
	if is_player_dead() or has_death_immunity():
		print("Player: Mort ignorée (déjà mort ou immunité)")
		return
	
	print("Player: Transition vers DeathState")
	
	# Simple transition vers l'état de mort
	var death_state = state_machine.get_node_or_null("DeathState")
	if death_state:
		state_machine.change_state(death_state)
	else:
		push_error("DeathState non trouvé dans la StateMachine!")

func is_player_dead() -> bool:
	"""Vérifie si le joueur est dans l'état de mort"""
	var current_state = state_machine.current_state
	return current_state != null and current_state.get_script().get_global_name() == "DeathState"

func has_death_immunity() -> bool:
	"""Immunité après respawn"""
	return respawn_immunity_timer > 0

func start_respawn_immunity():
	"""Appelé par le DeathState après respawn"""
	respawn_immunity_timer = RESPAWN_IMMUNITY_TIME
	print("Player: Immunité de respawn activée pour ", RESPAWN_IMMUNITY_TIME, "s")

# === API POUR COMPATIBILITY (si nécessaire) ===
func start_room_transition():
	"""Pour compatibilité avec le SceneManager"""
	# Plus besoin d'immunité de transition spéciale
	pass
