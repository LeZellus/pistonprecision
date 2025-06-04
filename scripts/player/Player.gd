extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var ground_left: RayCast2D = $GroundLeft
@onready var ground_right: RayCast2D = $GroundRight
@onready var ground_center: RayCast2D = $GroundCenter
@onready var wall_left_top: RayCast2D = $WallLeftTop
@onready var wall_left_center: RayCast2D = $WallLeftCenter
@onready var wall_left_bottom: RayCast2D = $WallLeftBottom
@onready var wall_right_top: RayCast2D = $WallRightTop
@onready var wall_right_center: RayCast2D = $WallRightCenter
@onready var wall_right_bottom: RayCast2D = $WallRightBottom

# === STATE ===
var was_grounded: bool = false
var is_on_wall: bool = false
var wall_side: int = 0  # -1 = left, 1 = right, 0 = none
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Connect to InputManager signals
	InputManager.jump_buffered.connect(_on_jump_buffered)
	InputManager.movement_changed.connect(_on_movement_changed)
	
	# Debug RayCast configuration
	print("Wall RayCast config:")
	if wall_left_center:
		print("Left Center - Enabled: ", wall_left_center.enabled, " Mask: ", wall_left_center.collision_mask)
	if wall_right_center:
		print("Right Center - Enabled: ", wall_right_center.enabled, " Mask: ", wall_right_center.collision_mask)

func _physics_process(delta):
	_handle_wall_detection()
	_handle_gravity(delta)
	_handle_grounding()
	_handle_horizontal_movement(delta)
	_handle_jump()
	
	move_and_slide()

# === WALL DETECTION ===
func _handle_wall_detection():
	# Debug continu des raycast
	print("RayCast states - Left: ", wall_left_center.is_colliding(), " Right: ", wall_right_center.is_colliding())
	
	var left_wall = (wall_left_top and wall_left_top.is_colliding()) or \
					(wall_left_center and wall_left_center.is_colliding()) or \
					(wall_left_bottom and wall_left_bottom.is_colliding())
	
	var right_wall = (wall_right_top and wall_right_top.is_colliding()) or \
					 (wall_right_center and wall_right_center.is_colliding()) or \
					 (wall_right_bottom and wall_right_bottom.is_colliding())
	
	# Debug
	if left_wall or right_wall:
		print("Wall detected - Left: ", left_wall, " Right: ", right_wall, " On floor: ", is_on_floor())
	
	if left_wall and not is_on_floor():
		is_on_wall = true
		wall_side = -1
		print("On left wall")
	elif right_wall and not is_on_floor():
		is_on_wall = true
		wall_side = 1
		print("On right wall")
	else:
		if is_on_wall:
			print("Left wall")
		is_on_wall = false
		wall_side = 0

# === GRAVITY ===
func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * PlayerConstants.GRAVITY_MULTIPLIER * delta
		
		# Variable jump height
		if velocity.y < 0 and InputManager.was_jump_released():
			velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
		
		# Max fall speed
		velocity.y = min(velocity.y, PlayerConstants.MAX_FALL_SPEED)

# === GROUNDING ===
func _handle_grounding():
	var grounded = is_on_floor()
	
	# Détection par raycast si disponibles
	if ground_left and ground_right and ground_center:
		grounded = ground_left.is_colliding() or ground_right.is_colliding() or ground_center.is_colliding()
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded

# === HORIZONTAL MOVEMENT ===
func _handle_horizontal_movement(delta):
	var input_dir = InputManager.get_movement()
	
	if input_dir != 0:
		# Acceleration instantanée pour réactivité Celeste
		velocity.x = input_dir * PlayerConstants.SPEED
	else:
		# Friction rapide
		var friction_force = PlayerConstants.FRICTION if is_on_floor() else PlayerConstants.AIR_RESISTANCE
		velocity.x = move_toward(velocity.x, 0, friction_force * delta)

# === JUMP ===
func _handle_jump():
	# Check for buffered jump or coyote jump
	if InputManager.consume_jump_buffer():
		if is_on_floor() or InputManager.can_coyote_jump():
			_perform_jump()
		elif is_on_wall:
			_perform_wall_jump()

func _perform_jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY

func _perform_wall_jump():
	velocity.y = PlayerConstants.JUMP_VELOCITY
	# Push away from wall
	velocity.x = -wall_side * PlayerConstants.SPEED * 1.2

# === SIGNAL HANDLERS ===
func _on_jump_buffered():
	# Jump buffer handled in _handle_jump()
	pass

func _on_movement_changed(direction: float):
	# Movement handled in _handle_horizontal_movement()
	pass
