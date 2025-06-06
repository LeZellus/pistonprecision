class_name DashState
extends State

var dash_direction: Vector2
var dash_timer: float = 0.0

func _ready() -> void:
	# animation_name = "Dash"
	pass

func enter() -> void:
	super.enter()
	_perform_dash()

func process_physics(delta: float) -> State:
	dash_timer -= delta
	
	# Maintenir la vélocité de dash
	parent.velocity = dash_direction * PlayerConstants.DASH_SPEED
	
	# Pas de gravité pendant le dash
	parent.move_and_slide()
	
	# Transitions
	if dash_timer <= 0:
		return _check_end_dash_state()
	
	# Collision avec mur ou sol peut terminer le dash prématurément
	if parent.is_on_wall() or (dash_direction.y > 0 and parent.is_on_floor()):
		return _check_end_dash_state()
	
	return null

func _perform_dash():
	dash_direction = _get_dash_direction()
	dash_timer = PlayerConstants.DASH_DURATION
	
	# Effets
	AudioManager.play_sfx("player/dash", 0.2)
	# ParticleManager.emit_dash(parent.global_position, dash_direction)
	
	# Camera shake
	if parent.camera:
		parent.camera.shake(5.0, 0.1)

func _get_dash_direction() -> Vector2:
	match parent.piston_direction:
		Player.PistonDirection.LEFT:  # Tête à gauche = dash droite
			return Vector2.RIGHT
		Player.PistonDirection.RIGHT: # Tête à droite = dash gauche  
			return Vector2.LEFT
		Player.PistonDirection.UP:    # Tête en haut = dash bas
			return Vector2.DOWN
		_: # PistonDirection.DOWN = pas de dash (garde le jump)
			return Vector2.ZERO

func _check_end_dash_state() -> State:
	# Restaurer une vélocité appropriée
	if dash_direction.y > 0:  # Dash vers le bas
		parent.velocity.y = PlayerConstants.DASH_SPEED * 0.3  # Momentum réduit
		parent.velocity.x = 0
	else:  # Dash horizontal
		parent.velocity.x = dash_direction.x * PlayerConstants.DASH_SPEED * 0.2
		parent.velocity.y = 0
	
	# Transition vers l'état approprié
	if parent.is_on_floor():
		return get_node("../RunState") if InputManager.get_movement() != 0 else get_node("../IdleState")
	else:
		return get_node("../FallState")

func exit() -> void:
	dash_timer = 0.0
