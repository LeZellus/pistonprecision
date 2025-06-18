extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var detection_system: DetectionSystem
var physics_component: PlayerPhysics
var actions_component: PlayerActions
var controller: PlayerController
var movement_system: MovementSystem
var dash_component: DashComponent

# === CACHED REFERENCES ===
var camera: Camera2D
var world_space_state: PhysicsDirectSpaceState2D

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === PHYSICS STATE ===
var was_grounded: bool = false
var wall_jump_timer: float = 0.0
var wall_jump_control_timer: float = 0.0  # Timer pour contrôle
var last_wall_side: int = 0              # -1 = gauche, 1 = droite, 0 = aucun
var last_wall_position: float = 0.0      # Position X du dernier wall jump

# === DEATH SYSTEM ===
var respawn_immunity_timer: float = 0.0
const RESPAWN_IMMUNITY_TIME: float = 0.0

# === COLLECTIBLES ===
var collectibles_count: int = 0

func _ready():
	world_space_state = get_world_2d().direct_space_state
	camera = get_viewport().get_camera_2d()
	_setup_components()
	_connect_signals()
	state_machine.init(self)
	add_to_group("player")
	
	call_deferred("_setup_hybrid_system")
	
func _setup_hybrid_system():
	print("🔧 Setup système hybride APRÈS stabilisation")
	movement_system = MovementSystem.new(self)
	add_child(movement_system)
	print("✅ MovementSystem créé en deferred")
	
	dash_component = DashComponent.new(self)
	movement_system.add_component(dash_component)
	print("✅ DashComponent ajouté en deferred")

func _process(delta: float):
	if respawn_immunity_timer > 0:
		respawn_immunity_timer -= delta
		
	# Décrémenter le wall jump timer
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			last_wall_side = 0  # Reset du côté quand timer fini
			
	if wall_jump_control_timer > 0:
		wall_jump_control_timer -= delta
		
	if movement_system:
		movement_system.update_all(delta)
		print("🔄 MovementSystem update appelé")

func _setup_components():
	detection_system = DetectionSystem.new(self)
	physics_component = PlayerPhysics.new(self)
	actions_component = PlayerActions.new(self)
	controller = PlayerController.new(self)
	
	movement_system = MovementSystem.new(self)
	add_child(movement_system)
	print("✅ MovementSystem créé")
	
	dash_component = DashComponent.new(self)
	movement_system.add_component(dash_component)
	print("✅ DashComponent ajouté")
	
	for component in [detection_system, physics_component, actions_component, controller]:
		add_child(component)

func _connect_signals():
	InputManager.rotate_left_requested.connect(_on_rotate_left)
	InputManager.rotate_right_requested.connect(_on_rotate_right)
	InputManager.push_requested.connect(_on_push_requested)

func _unhandled_input(event: InputEvent) -> void:
	if is_player_dead():
		return
	state_machine.process_input(event)

# === API ===
func can_wall_slide() -> bool:
	return detection_system.is_touching_wall() and wall_jump_timer <= 0

# === COMPATIBILITY PROPERTIES ===
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

# === DEATH SYSTEM ===
func trigger_death():
	if is_player_dead() or has_death_immunity():
		return
	
	var death_state: Node = state_machine.get_node_or_null("DeathState")
	if death_state:
		state_machine.change_state(death_state)

func is_player_dead() -> bool:
	var current_state: State = state_machine.current_state
	return current_state != null and current_state.get_script().get_global_name() == "DeathState"

func has_death_immunity() -> bool:
	return respawn_immunity_timer > 0

func start_respawn_immunity():
	respawn_immunity_timer = RESPAWN_IMMUNITY_TIME

func start_room_transition():
	pass
	
# === COLLECTIBLES ===
func add_collectible():
	collectibles_count += 1

func get_collectibles_count() -> int:
	return collectibles_count
