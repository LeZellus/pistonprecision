class_name DashState
extends State

var dash_direction: Vector2
var dash_timer: float = 0.0
var fade_tween: Tween

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
	
	# Créer des afterimages pendant le dash
	if int(dash_timer * 60) % 4 == 0:  # Tous les 4 frames environ
		_create_afterimage()
	
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
	
	# Si pas de direction valide, annuler le dash
	if dash_direction == Vector2.ZERO:
		return
	
	dash_timer = PlayerConstants.DASH_DURATION
	parent.use_dash()  # IMPORTANT : Activer le cooldown
	
	# Effet de disparition
	_create_dash_fade_effect()
	
	# Effets
	AudioManager.play_sfx("player/dash", 0.2)
	# ParticleManager.emit_dash(parent.global_position, dash_direction)
	
	# Camera shake
	if parent.camera:
		parent.camera.shake(5.0, 0.1)

func _get_dash_direction() -> Vector2:
	match parent.piston_direction:
		Player.PistonDirection.LEFT:
			return Vector2.RIGHT  # Corrigé : dash vers la gauche
		Player.PistonDirection.RIGHT:
			return Vector2.LEFT  # Corrigé : dash vers la droite
		Player.PistonDirection.UP:
			return Vector2.DOWN
		_: # DOWN = pas de dash
			return Vector2.ZERO

func _check_end_dash_state() -> State:
	# Restaurer une vélocité appropriée
	if dash_direction.y > 0:  # Dash vers le bas
		parent.velocity.y = PlayerConstants.DASH_SPEED * 0.3
		parent.velocity.x = 0
	else:  # Dash horizontal ou vers le haut
		parent.velocity.x = dash_direction.x * PlayerConstants.DASH_SPEED * 0.2
		parent.velocity.y = 0
	
	# Transition vers l'état approprié
	if parent.is_on_floor():
		return get_node("../RunState") if InputManager.get_movement() != 0 else get_node("../IdleState")
	else:
		return get_node("../FallState")

func exit() -> void:
	dash_timer = 0.0
	
	# Nettoyer le tween si encore actif
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# S'assurer que le sprite est visible
	parent.sprite.modulate.a = 1.0

func _create_dash_fade_effect():
	# Créer des afterimages avant de disparaître
	_create_afterimage()
	
	# Tween pour la disparition/réapparition
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	fade_tween = create_tween()
	
	# Disparition rapide
	fade_tween.tween_property(parent.sprite, "modulate:a", 0.1, 0.05)
	
	# Rester semi-transparent pendant le dash
	fade_tween.tween_interval(PlayerConstants.DASH_DURATION - 0.1)
	
	# Réapparition en fondu
	fade_tween.tween_property(parent.sprite, "modulate:a", 1.0, 0.05)

func _create_afterimage():
	# Créer une copie du sprite actuel comme afterimage
	var afterimage = Sprite2D.new()
	afterimage.texture = parent.sprite.sprite_frames.get_frame_texture(
		parent.sprite.animation, 
		parent.sprite.frame
	)
	afterimage.global_position = parent.global_position
	afterimage.rotation = parent.sprite.rotation
	afterimage.flip_h = parent.sprite.flip_h
	afterimage.flip_v = parent.sprite.flip_v
	afterimage.z_index = parent.z_index - 1
	
	# Couleur bleutée façon Celeste
	afterimage.modulate = Color(0.5, 0.7, 1.0, 0.6)
	
	# Ajouter à la scène
	parent.get_parent().add_child(afterimage)
	
	# Fade out et suppression
	var after_tween = afterimage.create_tween()
	after_tween.tween_property(afterimage, "modulate:a", 0.0, 0.3)
	after_tween.tween_callback(afterimage.queue_free)
