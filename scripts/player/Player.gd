extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Components créés dynamiquement (plus propre)
var ground_detector: GroundDetector
var wall_detector: WallDetector
var push_detector: PushDetector
var physics_component: PlayerPhysics
var actions_component: PlayerActions
var controller: PlayerController

# === CACHED REFERENCES (simplifiées) ===
var camera: Camera2D
var world_space_state: PhysicsDirectSpaceState2D

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === PHYSICS STATE ===
var was_grounded: bool = false
var wall_jump_timer: float = 0.0

const WALL_JUMP_GRACE_TIME: float = 0.15

func _ready():
	# Initialisation optimisée
	world_space_state = get_world_2d().direct_space_state
	camera = get_viewport().get_camera_2d()
	
	_setup_components()
	_connect_signals()
	state_machine.init(self)
	add_to_group("player")

func _setup_components():
	"""Création et setup des components en une fois"""
	# Création
	ground_detector = GroundDetector.new(self)
	wall_detector = WallDetector.new(self) 
	push_detector = PushDetector.new(self)
	physics_component = PlayerPhysics.new(self)
	actions_component = PlayerActions.new(self)
	controller = PlayerController.new(self)
	
	# Ajout à la scène
	var components = [ground_detector, wall_detector, push_detector, 
					 physics_component, actions_component, controller]
	
	for component in components:
		add_child(component)

func _connect_signals():
	"""Connexion des signaux simplifiée"""
	var input_signals = [
		[InputManager.rotate_left_requested, _on_rotate_left],
		[InputManager.rotate_right_requested, _on_rotate_right],
		[InputManager.push_requested, _on_push_requested]
	]
	
	for signal_data in input_signals:
		if not signal_data[0].is_connected(signal_data[1]):
			signal_data[0].connect(signal_data[1])

func _unhandled_input(event: InputEvent):
	state_machine.process_input(event)

# === WALL DETECTION ===
func can_wall_slide() -> bool:
	return wall_detector.is_touching_wall() and wall_jump_timer <= 0

# === ROTATION & PUSH (inchangé) ===
func _on_rotate_left():
	actions_component.rotate_piston(-1)

func _on_rotate_right():
	actions_component.rotate_piston(1)

func _on_push_requested():
	actions_component.execute_push()
