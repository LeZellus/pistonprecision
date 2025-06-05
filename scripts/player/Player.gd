extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var ground_detector: GroundDetector
@onready var wall_detector: WallDetector

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === STATE ===
var was_grounded: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	_setup_detectors()
	_connect_signals()
	state_machine.init(self)

func _setup_detectors():
	ground_detector = GroundDetector.new(self)
	wall_detector = WallDetector.new(self)
	add_child(ground_detector)
	add_child(wall_detector)

func _connect_signals():
	InputManager.rotate_left_requested.connect(_on_rotate_left)
	InputManager.rotate_right_requested.connect(_on_rotate_right)

func _unhandled_input(event: InputEvent):
	state_machine.process_input(event)

func _process(delta: float):
	state_machine.process_frame(delta)

func _physics_process(delta: float):
	delta = min(delta, 1.0/30.0)
	_handle_grounding()
	state_machine.process_physics(delta)

# === MOVEMENT METHODS ===
func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * PlayerConstants.GRAVITY_MULTIPLIER * delta
		velocity.y = min(velocity.y, PlayerConstants.MAX_FALL_SPEED)

func apply_movement(delta: float):
	var input_dir = InputManager.get_movement()
	if input_dir != 0:
		velocity.x = input_dir * PlayerConstants.SPEED

func apply_air_movement(delta: float):
	var input_dir = InputManager.get_movement()
	if input_dir != 0:
		velocity.x = input_dir * PlayerConstants.SPEED

func apply_friction(delta: float):
	var friction = PlayerConstants.FRICTION if is_on_floor() else PlayerConstants.AIR_RESISTANCE
	velocity.x = move_toward(velocity.x, 0, friction * delta)

func apply_wall_slide(delta: float):
	if velocity.y > 0:
		velocity.y *= PlayerConstants.WALL_SLIDE_MULTIPLIER
		velocity.y = min(velocity.y, PlayerConstants.MAX_FALL_SPEED * PlayerConstants.WALL_SLIDE_MAX_SPEED_MULTIPLIER)

# === ACTIONS ===
func jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY
	AudioManager.play_sfx("player/jump", 0.1)
	var particle_pos = global_position + Vector2(0, -4)
	ParticleManager.emit_jump(particle_pos)

func wall_jump():
	var wall_side = wall_detector.get_wall_side()
	velocity.y = PlayerConstants.JUMP_VELOCITY
	velocity.x = -wall_side * PlayerConstants.SPEED * 1.2
	AudioManager.play_sfx("player/jump", 0.1)

# === ROTATION ===
func _on_rotate_left():
	_rotate_piston(-1)

func _on_rotate_right():
	_rotate_piston(1)

func _rotate_piston(direction: int):
	piston_direction = (piston_direction + direction + 4) % 4
	sprite.rotation_degrees = piston_direction * 90

# === GROUNDING ===
func _handle_grounding():
	var grounded = is_on_floor()
	
	if grounded and not was_grounded:
		AudioManager.play_sfx("player/land", 0.01)
		var dust_pos = global_position + Vector2(0, -4)
		ParticleManager.emit_dust(dust_pos, 0.0, self)
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded
