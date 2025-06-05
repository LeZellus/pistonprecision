extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var ground_detector: GroundDetector
@onready var wall_detector: WallDetector

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }  # Ordre corrigé pour l'animation
var piston_direction: PistonDirection = PistonDirection.DOWN

# === STATE ===
var was_grounded: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var wall_jump_timer: float = 0.0
const WALL_JUMP_GRACE_TIME: float = 0.15

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
	
	# Connexion sécurisée pour le dash
	if InputManager.has_signal("dash_requested"):
		if not InputManager.dash_requested.is_connected(_on_push_requested):
			InputManager.dash_requested.connect(_on_push_requested)
			print("Signal dash_requested connecté avec succès")
	else:
		push_error("Signal dash_requested n'existe pas dans InputManager!")

func _unhandled_input(event: InputEvent):
	state_machine.process_input(event)

func _process(delta: float):
	state_machine.process_frame(delta)

func _physics_process(delta: float):
	delta = min(delta, 1.0/30.0)
	_handle_grounding()
	_update_wall_jump_timer(delta)
	state_machine.process_physics(delta)

func _update_wall_jump_timer(delta: float):
	if wall_jump_timer > 0:
		wall_jump_timer -= delta

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
	velocity.x = -wall_side * PlayerConstants.SPEED * 1.4
	
	global_position.x += -wall_side * 2
	wall_jump_timer = WALL_JUMP_GRACE_TIME
	
	AudioManager.play_sfx("player/jump", 0.1)

func push():
	# Ne pas push si la tête est vers le bas (contre le sol)
	if piston_direction == PistonDirection.DOWN:
		print("Impossible de pousser vers le bas!")
		return
	
	print("Push direction: ", PistonDirection.keys()[piston_direction])
	
	var push_vector = _get_push_vector()
	_attempt_push(push_vector)
	
	# Joue l'animation et revient à l'état normal après
	sprite.play("Push")
	
	# Attendre la fin de l'animation puis revenir à l'état normal
	if not sprite.animation_finished.is_connected(_on_push_animation_finished):
		sprite.animation_finished.connect(_on_push_animation_finished, CONNECT_ONE_SHOT)

func _on_push_animation_finished():
	# Revenir à l'animation appropriée selon l'état
	if is_on_floor():
		if InputManager.get_movement() != 0:
			sprite.play("Run")
		else:
			sprite.play("Idle")
	else:
		if velocity.y < 0:
			sprite.play("Jump")
		else:
			sprite.play("Fall")

func _get_push_vector() -> Vector2:
	match piston_direction:
		PistonDirection.DOWN: return Vector2.DOWN
		PistonDirection.LEFT: return Vector2.LEFT
		PistonDirection.UP: return Vector2.UP
		PistonDirection.RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN

func _attempt_push(direction: Vector2):
	# TODO: Ajouter ici la logique de détection et push d'objets
	# Exemple: détecter les objets pushables dans la direction
	print("Tentative de push vers: ", direction)

# === WALL DETECTION ===
func can_wall_slide() -> bool:
	return wall_detector.is_touching_wall() and wall_jump_timer <= 0

# === ROTATION & PUSH ===
func _on_rotate_left():
	_rotate_piston(-1)

func _on_rotate_right():
	_rotate_piston(1)

func _on_push_requested():
	print("Push requested!")
	push()

func _rotate_piston(direction: int):
	piston_direction = (piston_direction + direction + 4) % 4
	# Rotation normale du sprite pour la tête du piston
	sprite.rotation_degrees = piston_direction * 90
	print("Nouvelle direction piston: ", PistonDirection.keys()[piston_direction])
	print("Rotation sprite: ", sprite.rotation_degrees, "°")

# === GROUNDING ===
func _handle_grounding():
	var grounded = is_on_floor()
	
	if grounded and not was_grounded:
		AudioManager.play_sfx("player/land", 0.01)
		var dust_pos = global_position + Vector2(0, -4)
		ParticleManager.emit_dust(dust_pos, 0.0, self)
		wall_jump_timer = 0.0
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded
