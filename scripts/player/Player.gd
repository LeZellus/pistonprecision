extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_detector: GroundDetector
@onready var wall_detector: WallDetector

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === STATE ===
var was_grounded: bool = false
var is_jumping: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	_setup_detectors()
	_connect_signals()

func _setup_detectors():
	ground_detector = GroundDetector.new(self)
	wall_detector = WallDetector.new(self)
	add_child(ground_detector)
	add_child(wall_detector)

func _connect_signals():
	InputManager.jump_buffered.connect(_on_jump_buffered)
	InputManager.movement_changed.connect(_on_movement_changed)
	InputManager.rotate_left_requested.connect(_on_rotate_left)
	InputManager.rotate_right_requested.connect(_on_rotate_right)

func _physics_process(delta: float):
	delta = min(delta, 1.0/30.0)
	
	_handle_gravity(delta)
	_handle_grounding() 
	_handle_horizontal_movement(delta)
	_handle_jump()
	_handle_animations()
	
	move_and_slide()

# === ANIMATIONS ===
func _handle_animations():
	if not is_on_floor():
		if is_jumping or velocity.y < -50:
			if sprite.animation != "Jump":
				sprite.play("Jump")
	else:
		is_jumping = false
		if sprite.animation != "Idle":
			sprite.play("Idle")

# === ROTATION SYSTEM ===
func _on_rotate_left():
	_rotate_piston(-1)

func _on_rotate_right():
	_rotate_piston(1)

func _rotate_piston(direction: int):
	piston_direction = (piston_direction + direction) % 4 if direction > 0 else (piston_direction + direction + 4) % 4
	sprite.rotation_degrees = piston_direction * 90

# === GRAVITY ===
func _handle_gravity(delta: float):
	if not is_on_floor():
		var wall_data = wall_detector.get_wall_state()
		var gravity_multiplier = PlayerConstants.GRAVITY_MULTIPLIER
		var max_fall = PlayerConstants.MAX_FALL_SPEED
		
		if wall_data.touching and velocity.y > 0:
			gravity_multiplier *= PlayerConstants.WALL_SLIDE_MULTIPLIER
			max_fall *= PlayerConstants.WALL_SLIDE_MAX_SPEED_MULTIPLIER
		
		velocity.y += gravity * gravity_multiplier * delta
		
		if velocity.y < -100 and InputManager.was_jump_released():
			velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
		
		velocity.y = min(velocity.y, max_fall)

# === GROUNDING ===
func _handle_grounding():
	var grounded = ground_detector.is_grounded()
	
	# Son et particule d'atterrissage
	if grounded and not was_grounded:
		AudioManager.play_sfx("player/land", 0.01)
		var dust_pos = global_position + Vector2(0, -4)
		ParticleManager.emit_dust(dust_pos, 0.0, self)
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded

# === HORIZONTAL MOVEMENT ===
func _handle_horizontal_movement(delta: float):
	var input_dir = InputManager.get_movement()
	
	if input_dir != 0:
		velocity.x = input_dir * PlayerConstants.SPEED
	else:
		var friction = PlayerConstants.FRICTION if is_on_floor() else PlayerConstants.AIR_RESISTANCE
		velocity.x = move_toward(velocity.x, 0, friction * delta)

# === JUMP ===
func _handle_jump():
	if piston_direction != PistonDirection.DOWN or not InputManager.consume_jump_buffer():
		return
	
	if is_on_floor() or InputManager.can_coyote_jump():
		_perform_jump()
	elif wall_detector.is_touching_wall():
		_perform_wall_jump()

func _perform_jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY
	is_jumping = true
	AudioManager.play_sfx("player/jump", 0.1)
	
	var jump_pos = global_position + Vector2(0, -4)
	ParticleManager.emit_jump(jump_pos)

func _perform_wall_jump():
	var wall_side = wall_detector.get_wall_side()
	velocity.y = PlayerConstants.JUMP_VELOCITY
	velocity.x = -wall_side * PlayerConstants.SPEED * 1.2
	AudioManager.play_sfx("player/jump", 0.1)

# === SIGNAL HANDLERS ===
func _on_jump_buffered(): pass
func _on_movement_changed(direction: float): pass
