extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_left: RayCast2D = $GroundLeft
@onready var ground_right: RayCast2D = $GroundRight
@onready var ground_center: RayCast2D = $GroundCenter
@onready var wall_left_top: RayCast2D = $WallLeftTop
@onready var wall_left_center: RayCast2D = $WallLeftCenter
@onready var wall_left_bottom: RayCast2D = $WallLeftBottom
@onready var wall_right_top: RayCast2D = $WallRightTop
@onready var wall_right_center: RayCast2D = $WallRightCenter
@onready var wall_right_bottom: RayCast2D = $WallRightBottom

# === PISTON STATE ===
enum PistonDirection {
	DOWN,
	LEFT,
	UP,
	RIGHT
}

var piston_direction: PistonDirection = PistonDirection.DOWN

# === STATE ===
var was_grounded: bool = false
var is_on_wall: bool = false
var wall_side: int = 0
var is_jumping: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	InputManager.jump_buffered.connect(_on_jump_buffered)
	InputManager.movement_changed.connect(_on_movement_changed)
	InputManager.rotate_left_requested.connect(_on_rotate_left)
	InputManager.rotate_right_requested.connect(_on_rotate_right)

func _physics_process(delta):
	delta = min(delta, 1.0/30.0)
	_handle_wall_detection()
	_handle_gravity(delta)
	_handle_horizontal_movement(delta)
	
	_handle_grounding()
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
		sprite.play("Idle")

# === ROTATION SYSTEM ===
func _on_rotate_left():
	_rotate_piston(-1)

func _on_rotate_right():
	_rotate_piston(1)

func _rotate_piston(direction: int):
	var new_direction = (piston_direction + direction) % 4
	if new_direction < 0:
		new_direction = 3
	
	piston_direction = new_direction
	_update_sprite_rotation()

func _update_sprite_rotation():
	sprite.rotation_degrees = piston_direction * 90

# === WALL DETECTION ===
func _handle_wall_detection():
	var left_wall = (wall_left_top and wall_left_top.is_colliding()) or \
					(wall_left_center and wall_left_center.is_colliding()) or \
					(wall_left_bottom and wall_left_bottom.is_colliding())
	
	var right_wall = (wall_right_top and wall_right_top.is_colliding()) or \
					 (wall_right_center and wall_right_center.is_colliding()) or \
					 (wall_right_bottom and wall_right_bottom.is_colliding())
	
	if left_wall and not is_on_floor():
		is_on_wall = true
		wall_side = -1
	elif right_wall and not is_on_floor():
		is_on_wall = true
		wall_side = 1
	else:
		is_on_wall = false
		wall_side = 0

# === GRAVITY ===
func _handle_gravity(delta):
	if not is_on_floor():
		var gravity_multiplier = PlayerConstants.GRAVITY_MULTIPLIER
		
		if is_on_wall and velocity.y > 0:
			gravity_multiplier *= PlayerConstants.WALL_SLIDE_MULTIPLIER
		
		velocity.y += gravity * gravity_multiplier * delta
		
		if velocity.y < 0 and InputManager.was_jump_released():
			velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
		
		var max_fall = PlayerConstants.MAX_FALL_SPEED
		if is_on_wall and velocity.y > 0:
			max_fall *= PlayerConstants.WALL_SLIDE_MAX_SPEED_MULTIPLIER
			
		velocity.y = min(velocity.y, max_fall)

# === GROUNDING ===
func _handle_grounding():
	var grounded = is_on_floor()
	
	if ground_left and ground_right and ground_center:
		grounded = ground_left.is_colliding() or ground_right.is_colliding() or ground_center.is_colliding()
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded

# === HORIZONTAL MOVEMENT ===
func _handle_horizontal_movement(delta):
	var input_dir = InputManager.get_movement()
	
	if input_dir != 0:
		velocity.x = input_dir * PlayerConstants.SPEED
	else:
		var friction_force = PlayerConstants.FRICTION if is_on_floor() else PlayerConstants.AIR_RESISTANCE
		velocity.x = move_toward(velocity.x, 0, friction_force * delta)

# === JUMP ===
func _handle_jump():
	# Ne peut sauter que si le piston pointe vers le bas
	if piston_direction != PistonDirection.DOWN:
		return
		
	if InputManager.consume_jump_buffer():
		if is_on_floor() or InputManager.can_coyote_jump():
			_perform_jump()
		elif is_on_wall:
			_perform_wall_jump()

func _perform_jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY
	is_jumping = true

func _perform_wall_jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY
	velocity.x = -wall_side * PlayerConstants.SPEED * 1.2

# === SIGNAL HANDLERS ===
func _on_jump_buffered():
	pass

func _on_movement_changed(direction: float):
	pass
