extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var ground_detector: GroundDetector
@onready var wall_detector: WallDetector
@onready var push_detector: PushDetector

# === CACHED REFERENCES ===
var camera: Camera2D  # Cache de la caméra pour éviter les appels répétés

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

var transition_immunity_timer: float = 0.0
const TRANSITION_IMMUNITY_TIME = 0.1

# === LANDING SOUND MANAGEMENT ===
var landing_sound_cooldown: float = 0.0

# === PHYSICS CACHE ===
var gravity: float
var was_grounded: bool = false
var wall_jump_timer: float = 0.0

var dash_cooldown_timer: float = 0.0

# === CONSTANTS ===
const WALL_JUMP_GRACE_TIME: float = 0.15
const MAX_STEP_HEIGHT: float = 1.0  # Hauteur max des marches (assez pour 0.1px + marge)
const STEP_CHECK_DISTANCE: float = 8.0  # Distance de détection devant le joueur

func _ready():
	_cache_physics_values()
	_cache_camera_reference()
	_setup_detectors()
	_connect_signals()
	state_machine.init(self)
	
	floor_snap_length = 3.0
	floor_max_angle = deg_to_rad(50)
	
	add_to_group("player")
	
func _process(delta: float):
	state_machine.process_frame(delta)

func _physics_process(delta: float):
	delta = min(delta, 1.0/30.0)
	_handle_grounding()
	_update_wall_jump_timer(delta)
	_update_dash_cooldown(delta)
	
	# Décrémenter le cooldown du son d'atterrissage
	if landing_sound_cooldown > 0:
		landing_sound_cooldown -= delta
	
	state_machine.process_physics(delta)
	
	# Gestion des transitions de salle
	if transition_immunity_timer > 0:
		transition_immunity_timer -= delta
		global_position += velocity * delta
		return

func _cache_physics_values():
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

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
	state_machine.process_input(event)

func _update_wall_jump_timer(delta: float):
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		
func _update_dash_cooldown(delta: float):
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

# === MOVEMENT METHODS (Optimisées) ===
func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * PlayerConstants.GRAVITY_MULTIPLIER * delta
		velocity.y = min(velocity.y, PlayerConstants.MAX_FALL_SPEED)

func apply_movement(_delta: float):
	var input_dir = InputManager.get_movement()
	if input_dir != 0:
		velocity.x = input_dir * PlayerConstants.SPEED

func apply_air_movement(delta: float):
	# Même logique que apply_movement pour l'instant
	apply_movement(delta)

func apply_friction(delta: float):
	var friction_value = PlayerConstants.FRICTION if is_on_floor() else PlayerConstants.AIR_RESISTANCE
	velocity.x = move_toward(velocity.x, 0, friction_value * delta)

func apply_wall_slide(_delta: float):
	if velocity.y > 0:
		velocity.y *= PlayerConstants.WALL_SLIDE_MULTIPLIER
		velocity.y = min(velocity.y, PlayerConstants.MAX_FALL_SPEED * PlayerConstants.WALL_SLIDE_MAX_SPEED_MULTIPLIER)

# === WALL DETECTION ===
func can_wall_slide() -> bool:
	return wall_detector.is_touching_wall() and wall_jump_timer <= 0

# === ROTATION & PUSH ===
func _on_rotate_left():
	_rotate_piston(-1)

func _on_rotate_right():
	_rotate_piston(1)

func _on_push_requested():
	push()
		
func use_dash():
	"""Appelée quand un dash est effectué"""
	dash_cooldown_timer = PlayerConstants.DASH_COOLDOWN

func can_dash() -> bool:
	# Peut dasher si cooldown terminé ET tête pas vers le bas
	return dash_cooldown_timer <= 0.0 and piston_direction != PistonDirection.DOWN

func _rotate_piston(direction: int):
	var new_direction = (piston_direction + direction + 4) % 4
	piston_direction = new_direction as PistonDirection
	sprite.rotation_degrees = piston_direction * 90

func _get_push_vector() -> Vector2:
	match piston_direction:
		PistonDirection.DOWN: return Vector2.DOWN
		PistonDirection.LEFT: return Vector2.LEFT
		PistonDirection.UP: return Vector2.UP
		PistonDirection.RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN

# === PUSH SYSTEM (Optimisé) ===
func push():
	if piston_direction == PistonDirection.DOWN:
		return
	
	var push_vector = _get_push_vector()
	
	if not _can_perform_push_action(push_vector):
		return
	
	var pushable_object = push_detector.detect_pushable_object(push_vector)
	var success = false
	
	if pushable_object:
		success = _attempt_push(push_vector)
	else:
		print("Aucun objet pushable détecté")
	
	# ✅ SOLUTION : Animation joue toujours si action possible
	_play_push_animation()
	
	# Shake seulement en cas de succès
	if success:
		_trigger_push_shake()

func _play_push_animation():
	sprite.play("Push")
	
	# Déconnecter si déjà connecté
	if sprite.animation_finished.is_connected(_on_push_animation_finished):
		sprite.animation_finished.disconnect(_on_push_animation_finished)
	
	sprite.animation_finished.connect(_on_push_animation_finished, CONNECT_ONE_SHOT)

func _can_perform_push_action(direction: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * 8.0
	)
	query.collision_mask = 0b00000010  # Seulement les murs
	query.exclude = [self]
	
	return not space_state.intersect_ray(query)

func _attempt_push(direction: Vector2) -> bool:
	var pushable_object = push_detector.detect_pushable_object(direction)
	if not pushable_object:
		return false
	
	return pushable_object.push(direction, pushable_object.push_force)

func _trigger_push_shake():
	if not camera or not camera.has_method("shake"):
		return
	
	camera.shake(8.0, 0.15)

func _on_push_animation_finished():
	print("Animation push terminée") # Debug
	if sprite.animation_finished.is_connected(_on_push_animation_finished):
		sprite.animation_finished.disconnect(_on_push_animation_finished)
	
	# Retour à l'animation appropriée
	if state_machine and state_machine.current_state:
		state_machine.current_state.enter()

# === GROUNDING ===
func _handle_grounding():
	var grounded = is_on_floor()
	
	if grounded and was_grounded:
		wall_detector.set_active(false)
	elif not grounded:
		wall_detector.set_active(true)
	
	# Son d'atterrissage avec cooldown simple
	if grounded and not was_grounded and landing_sound_cooldown <= 0:
		AudioManager.play_sfx("player/land", 0.1)
		ParticleManager.emit_dust(global_position, 0.0, self)
		landing_sound_cooldown = 0.3  # 200ms de cooldown
		wall_jump_timer = 0.0
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded

func _setup_detectors():
	ground_detector = GroundDetector.new(self)
	wall_detector = WallDetector.new(self)
	push_detector = PushDetector.new(self)
	add_child(ground_detector)
	add_child(wall_detector)
	add_child(push_detector)
	
func start_room_transition():
	transition_immunity_timer = TRANSITION_IMMUNITY_TIME
	
