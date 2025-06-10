extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var ground_detector: GroundDetector
@onready var wall_detector: WallDetector
@onready var push_detector: PushDetector
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var physics_component: PlayerPhysics
@onready var actions_component: PlayerActions
@onready var controller: PlayerController 

# === CACHED REFERENCES ===
var camera: Camera2D  # Cache de la caméra pour éviter les appels répétés
var world_space_state: PhysicsDirectSpaceState2D
var viewport_cache: Viewport

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

var transition_immunity_timer: float = 0.0
const TRANSITION_IMMUNITY_TIME = 0.1

# === PHYSICS CACHE ===
var was_grounded: bool = false
var wall_jump_timer: float = 0.0

# === DEATH STATE ===
var is_dead: bool = false
var death_explosion: Node = null

# === CONSTANTS ===
const WALL_JUMP_GRACE_TIME: float = 0.15

func _ready():
	world_space_state = get_world_2d().direct_space_state
	viewport_cache = get_viewport()
	
	_cache_camera_reference()
	_setup_detectors()
	_connect_signals()
	state_machine.init(self)
	
	add_to_group("player")

func _cache_camera_reference():
	# Cache la référence caméra une seule fois
	camera = get_viewport().get_camera_2d()
	if not camera:
		push_warning("Aucune caméra trouvée dans la scène")

func _connect_signals():
	InputManager.rotate_left_requested.connect(_on_rotate_left)
	InputManager.rotate_right_requested.connect(_on_rotate_right)
	
	if InputManager.has_signal("push_requested"):
		if not InputManager.push_requested.is_connected(_on_push_requested):
			InputManager.push_requested.connect(_on_push_requested)
			
func _unhandled_input(event: InputEvent):
	if not is_dead:
		state_machine.process_input(event)

# === WALL DETECTION ===
func can_wall_slide() -> bool:
	return wall_detector.is_touching_wall() and wall_jump_timer <= 0

# === ROTATION & PUSH ===
func _on_rotate_left():
	if not is_dead:
		actions_component.rotate_piston(-1)

func _on_rotate_right():
	if not is_dead:
		actions_component.rotate_piston(1)

func _on_push_requested():
	if not is_dead:
		actions_component.execute_push()

func _setup_detectors():
	ground_detector = GroundDetector.new(self)
	wall_detector = WallDetector.new(self)
	push_detector = PushDetector.new(self)
	physics_component = PlayerPhysics.new(self)
	actions_component = PlayerActions.new(self)
	controller = PlayerController.new(self)
	
	add_child(ground_detector)
	add_child(wall_detector)
	add_child(push_detector)
	add_child(physics_component)
	add_child(actions_component)
	add_child(controller)
	
func start_room_transition():
	transition_immunity_timer = TRANSITION_IMMUNITY_TIME

# === DEATH SYSTEM ===
func trigger_death():
	if is_player_dead():
		return
	
	# Simple transition vers DeathState
	state_machine.change_state(state_machine.get_node("DeathState"))

func is_player_dead() -> bool:
	return state_machine.current_state is DeathState
