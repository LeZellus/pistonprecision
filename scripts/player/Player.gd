extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var ground_detector: GroundDetector
@onready var wall_detector: WallDetector
@onready var push_detector: PushDetector

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

func _get_push_vector() -> Vector2:
	match piston_direction:
		PistonDirection.DOWN: return Vector2.DOWN
		PistonDirection.LEFT: return Vector2.LEFT
		PistonDirection.UP: return Vector2.UP
		PistonDirection.RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN

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

# === PUSH SYSTEM ===
func push():
	# Ne pas push si la tête est vers le bas (contre le sol)
	if piston_direction == PistonDirection.DOWN:
		print("Impossible de pousser vers le bas!")
		return
	
	var push_vector = _get_push_vector()
	
	# Vérifier si on peut faire l'action (même sans objet)
	if not _can_perform_push_action(push_vector):
		print("Push bloqué - Joueur contre un mur")
		return
	
	# Tenter de pousser un objet (AVANT l'animation)
	var success = _attempt_push(push_vector)
	var has_pushable_object = push_detector.detect_pushable_object(push_vector) != null
	
	# Animation seulement si :
	# - Il y a un objet ET le push a réussi
	# - OU il n'y a pas d'objet (animation dans le vide)
	if (has_pushable_object and success) or (not has_pushable_object):
		# Faire l'animation de push
		sprite.play("Push")
		
		# FIX: Déconnecter d'abord si déjà connecté pour éviter les doublons
		if sprite.animation_finished.is_connected(_on_push_animation_finished):
			sprite.animation_finished.disconnect(_on_push_animation_finished)
		
		sprite.animation_finished.connect(_on_push_animation_finished, CONNECT_ONE_SHOT)
		
		if success:
			print("Objet poussé avec succès!")
			# AudioManager.play_sfx("player/push", 0.2)  # Commenté car son manquant
			
			# SHAKE ÉCRAN quand push réussi
			_trigger_push_shake()
		else:
			print("Animation de push dans le vide")
	else:
		print("Push impossible - Objet bloqué, pas d'animation")

func _can_perform_push_action(direction: Vector2) -> bool:
	# Vérifier si le joueur lui-même est contre un mur dans la direction du push
	var space_state = get_world_2d().direct_space_state
	var test_distance = 8.0  # Distance de test depuis le joueur
	var start_pos = global_position
	var end_pos = start_pos + direction * test_distance
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 0b00000010  # SEULEMENT les murs (layer 2), PAS les objets pushables (layer 3)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Joueur bloqué par un mur dans la direction: ", direction)
		return false
	
	return true

func _attempt_push(direction: Vector2) -> bool:
	var pushable_object = push_detector.detect_pushable_object(direction)
	
	if not pushable_object:
		print("Aucun objet pushable détecté")
		return false
	
	# Vérifier si l'objet peut être poussé (il gère sa propre détection de mur)
	var success = pushable_object.push(direction, pushable_object.push_force)
	return success

func _on_push_animation_finished():
	# FIX: Déconnecter explicitement le signal pour éviter les résidus
	if sprite.animation_finished.is_connected(_on_push_animation_finished):
		sprite.animation_finished.disconnect(_on_push_animation_finished)
	
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

func _trigger_push_shake():
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("Aucune caméra trouvée pour le shake")
		return
	
	# Appeler directement shake() sur la caméra
	if camera.has_method("shake"):
		camera.shake(8.0, 0.15)
		print("Shake déclenché!")
	else:
		print("ERREUR: Méthode shake() introuvable sur la caméra")

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
		
func _setup_detectors():
	ground_detector = GroundDetector.new(self)
	wall_detector = WallDetector.new(self)
	push_detector = PushDetector.new(self)
	add_child(ground_detector)
	add_child(wall_detector)
	add_child(push_detector)
