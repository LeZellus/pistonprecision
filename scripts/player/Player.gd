# scripts/player/Player.gd - VERSION OPTIMISÉE
extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# SYSTÈMES UNIFIÉS
var detection_system: DetectionSystem
var physics_component: PlayerPhysics
var movement_system: MovementSystem

# === CACHED REFERENCES ===
var camera: Camera2D
var world_space_state: PhysicsDirectSpaceState2D

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === PHYSICS STATE ===
var was_grounded: bool = false
var wall_jump_timer: float = 0.0
var last_wall_side: int = 0
var last_wall_position: float = 0.0

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
	
func _input(event):
	if Input.is_key_pressed(KEY_F6):
		print("🔥 MORT FORCÉE PAR F6")
		trigger_death()
	
	# TEST 2: Respawn manuel (R)
	if Input.is_key_pressed(KEY_F7): # Entrée
		print("🔄 RESPAWN MANUEL FORCÉ")
		sprite.visible = true
		sprite.modulate.a = 1.0
		global_position = Vector2(0, 100)
		velocity = Vector2.ZERO
		print("Sprite visible: %s, Position: %v" % [sprite.visible, global_position])

func _setup_components():
	# COMPOSANTS CORE
	detection_system = DetectionSystem.new(self)
	physics_component = PlayerPhysics.new(self)
	add_child(detection_system)
	add_child(physics_component)
	
	# SYSTÈME DE MOUVEMENT UNIFIÉ
	movement_system = MovementSystem.new(self)
	movement_system.add_component(JumpComponent.new(self))
	movement_system.add_component(WallSlideComponent.new(self))
	movement_system.add_component(DashComponent.new(self))
	add_child(movement_system)

func _process(delta: float):
	if respawn_immunity_timer > 0:
		respawn_immunity_timer -= delta
	
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			last_wall_side = 0
	
	# UPDATE UNIFIÉ
	movement_system.update_all(delta)

func _physics_process(delta: float):
	if is_player_dead():
		state_machine.process_physics(delta)
		return
	
	delta = min(delta, 1.0/30.0)
	_handle_grounding()
	state_machine.process_physics(delta)

func _handle_grounding():
	var grounded = self.is_on_floor()
	detection_system.set_active(not grounded)
	
	if grounded and not was_grounded:
		AudioManager.play_sfx("player/land", 1)
		ParticleManager.emit_dust(global_position, 0.0, self)
		wall_jump_timer = 0.0
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded

func _connect_signals():
	InputManager.rotate_left_requested.connect(rotate_piston.bind(-1))
	InputManager.rotate_right_requested.connect(rotate_piston.bind(1))
	InputManager.push_requested.connect(execute_push)

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_dead():
		state_machine.process_input(event)

# === ACTIONS INTÉGRÉES ===
func rotate_piston(direction: int):
	var new_direction = (piston_direction + direction + 4) % 4
	piston_direction = new_direction as PistonDirection
	sprite.rotation_degrees = piston_direction * 90

func execute_push():
	if piston_direction == PistonDirection.DOWN:
		return
	
	var push_vector = _get_push_vector()
	var pushable_object = detection_system.detect_pushable_object(push_vector)
	
	if pushable_object and _can_push(push_vector):
		var success = pushable_object.push(push_vector, pushable_object.push_force)
		_play_push_effects(success)

func _get_push_vector() -> Vector2:
	match piston_direction:
		PistonDirection.LEFT: return Vector2.LEFT
		PistonDirection.UP: return Vector2.UP
		PistonDirection.RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN

func _can_push(direction: Vector2) -> bool:
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * 8.0,
		0b00000010
	)
	query.exclude = [self]
	return not world_space_state.intersect_ray(query)

func _play_push_effects(success: bool):
	sprite.play("Push")
	AudioManager.play_sfx("player/push", 0.5)
	
	if success and camera and camera.has_method("shake"):
		camera.shake(8.0, 0.15)
	
	sprite.animation_finished.connect(_on_push_finished, CONNECT_ONE_SHOT)

func _on_push_finished():
	if is_on_floor():
		sprite.play("Run" if InputManager.get_movement() != 0 else "Idle")

# === DEATH SYSTEM ===
func trigger_death():
	if is_player_dead() or has_death_immunity():
		return
	
	var death_state = state_machine.get_node("DeathState")
	if death_state:
		state_machine.change_state(death_state)

func is_player_dead() -> bool:
	var current_state = state_machine.current_state
	return current_state and current_state.get_script().get_global_name() == "DeathState"

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
