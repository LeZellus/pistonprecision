# scripts/player/states/DashState.gd - Version corrigée
class_name DashState
extends State

var dash_direction: Vector2
var dash_timer: float = 0.0
var fade_tween: Tween
var afterimage_counter: int = 0

func enter() -> void:
	super.enter()
	_perform_dash()

func process_physics(delta: float) -> State:
	dash_timer -= delta
	
	# Maintenir la vélocité de dash
	parent.velocity = dash_direction * PlayerConstants.DASH_SPEED
	
	# Afterimages optimisées (tous les 4 frames)
	afterimage_counter += 1
	if afterimage_counter >= 4:
		_create_afterimage()
		afterimage_counter = 0
	
	parent.move_and_slide()
	
	# Vérifier fin du dash
	if dash_timer <= 0 or _should_end_dash():
		return _get_end_dash_state()
	
	return null

func _perform_dash() -> void:
	dash_direction = _get_dash_direction()
	
	if dash_direction == Vector2.ZERO:
		return
	
	dash_timer = PlayerConstants.DASH_DURATION
	afterimage_counter = 0
	
	# Activer le cooldown
	parent.actions_component.use_dash()
	
	# Effets
	_apply_dash_effects()

func _get_dash_direction() -> Vector2:
	match parent.piston_direction:
		Player.PistonDirection.LEFT: return Vector2.RIGHT
		Player.PistonDirection.RIGHT: return Vector2.LEFT  
		Player.PistonDirection.UP: return Vector2.DOWN
		Player.PistonDirection.DOWN: return Vector2.ZERO
		_: return Vector2.ZERO

func _should_end_dash() -> bool:
	return (parent.is_on_wall() or 
			(dash_direction.y > 0 and parent.is_on_floor()))

func _get_end_dash_state() -> State:
	"""Détermine l'état suivant après le dash - VERSION CORRIGÉE"""
	# Restaurer vélocité appropriée
	if dash_direction.y > 0:  # Dash vers le bas
		parent.velocity.y = PlayerConstants.DASH_SPEED * 0.3
		parent.velocity.x = 0
	else:  # Dash horizontal/vertical
		parent.velocity.x = dash_direction.x * PlayerConstants.DASH_SPEED * 0.2
		parent.velocity.y = 0
	
	# Transition logique - UTILISE LA NOUVELLE API
	var state_machine = get_parent()
	if parent.is_on_floor():
		if InputManager.get_movement() != 0:
			return state_machine.get_node("RunState")
		else:
			return state_machine.get_node("IdleState")
	else:
		return state_machine.get_node("FallState")

func _apply_dash_effects():
	# Audio
	AudioManager.play_sfx("player/dash", 0.2)
	
	# Camera shake
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(5.0, 0.1)
	
	# Effet visuel
	_create_dash_fade_effect()

func _create_dash_fade_effect():
	_create_afterimage()
	
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(parent.sprite, "modulate:a", 0.1, 0.05)
	fade_tween.tween_interval(PlayerConstants.DASH_DURATION - 0.1)
	fade_tween.tween_property(parent.sprite, "modulate:a", 1.0, 0.05)

func _create_afterimage() -> void:
	if not parent.sprite.sprite_frames:
		return
	
	var afterimage = Sprite2D.new()
	afterimage.texture = parent.sprite.sprite_frames.get_frame_texture(
		parent.sprite.animation, 
		parent.sprite.frame
	)
	
	# Configuration
	afterimage.global_position = parent.global_position
	afterimage.flip_h = parent.sprite.flip_h
	afterimage.rotation = parent.sprite.rotation
	afterimage.z_index = parent.z_index - 1
	afterimage.modulate = Color(0.5, 0.7, 1.0, 0.6)
	
	parent.get_parent().add_child(afterimage)
	
	# Fade out
	var tween = afterimage.create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, 0.3)
	tween.tween_callback(afterimage.queue_free)

func exit() -> void:
	dash_timer = 0.0
	afterimage_counter = 0
	
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	parent.sprite.modulate.a = 1.0
