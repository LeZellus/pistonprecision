extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_rays: Array[RayCast2D] = [$GroundLeft, $GroundRight, $GroundCenter]
@onready var wall_left_rays: Array[RayCast2D] = [$WallLeftTop, $WallLeftCenter, $WallLeftBottom]
@onready var wall_right_rays: Array[RayCast2D] = [$WallRightTop, $WallRightCenter, $WallRightBottom]

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === STATE ===
var was_grounded: bool = false
var is_on_wall: bool = false
var wall_side: int = 0
var is_jumping: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	InputManager.jump_buffered.connect(_on_jump_buffered)
	InputManager.movement_changed.connect(_on_movement_changed)
	InputManager.rotate_left_requested.connect(_on_rotate_left)
	InputManager.rotate_right_requested.connect(_on_rotate_right)

func _physics_process(delta: float):
	delta = min(delta, 1.0/30.0)
	
	_handle_wall_detection()
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

# === WALL DETECTION ===
func _handle_wall_detection():
	var left_wall = _any_ray_colliding(wall_left_rays)
	var right_wall = _any_ray_colliding(wall_right_rays)
	
	if not is_on_floor():
		if left_wall:
			is_on_wall = true
			wall_side = -1
		elif right_wall:
			is_on_wall = true
			wall_side = 1
		else:
			is_on_wall = false
			wall_side = 0
	else:
		is_on_wall = false
		wall_side = 0

func _any_ray_colliding(rays: Array[RayCast2D]) -> bool:
	return rays.any(func(ray): return ray and ray.is_colliding())

# === GRAVITY ===
func _handle_gravity(delta: float):
	if not is_on_floor():
		var gravity_multiplier = PlayerConstants.GRAVITY_MULTIPLIER
		var max_fall = PlayerConstants.MAX_FALL_SPEED
		
		if is_on_wall and velocity.y > 0:
			gravity_multiplier *= PlayerConstants.WALL_SLIDE_MULTIPLIER
			max_fall *= PlayerConstants.WALL_SLIDE_MAX_SPEED_MULTIPLIER
		
		velocity.y += gravity * gravity_multiplier * delta
		
		if velocity.y < -100 and InputManager.was_jump_released():
			velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
		
		velocity.y = min(velocity.y, max_fall)

# === GROUNDING ===
func _handle_grounding():
	var grounded = is_on_floor() or _any_ray_colliding(ground_rays)
	
	# Son et particule d'atterrissage
	if grounded and not was_grounded:
		AudioManager.play_sfx("player/land", 0.1)
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
	elif is_on_wall:
		_perform_wall_jump()

func _perform_jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY
	is_jumping = true
	AudioManager.play_sfx("player/jump", 0.1)

func _perform_wall_jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY
	velocity.x = -wall_side * PlayerConstants.SPEED * 1.2
	AudioManager.play_sfx("player/jump", 0.1)

# === SIGNAL HANDLERS ===
func _on_jump_buffered(): pass
func _on_movement_changed(direction: float): pass
