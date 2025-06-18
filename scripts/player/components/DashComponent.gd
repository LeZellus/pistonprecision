# scripts/player/components/DashComponent.gd
class_name DashComponent
extends MovementComponent

var dash_direction: Vector2
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var afterimage_counter: int = 0

func update(delta: float):
	cooldown_timer = maxf(0.0, cooldown_timer - delta)
	
	# Input pour démarrer le dash
	if Input.is_action_just_pressed("dash"):
		print("🎮 Input dash détecté!")
		if can_dash():
			print("✅ Can dash = true")
			start_dash()
		else:
			print("❌ Can dash = false, raison:", cooldown_timer, player.piston_direction)
	
	if is_active():
		_process_dash(delta)

func can_dash() -> bool:
	return cooldown_timer <= 0.0 and player.piston_direction != Player.PistonDirection.DOWN

func start_dash():
	dash_direction = _get_dash_direction()
	if dash_direction == Vector2.ZERO:
		return
	
	enable()
	dash_timer = PlayerConstants.DASH_DURATION
	cooldown_timer = PlayerConstants.DASH_COOLDOWN
	afterimage_counter = 0
	
	# Effets
	AudioManager.play_sfx("player/dash", 0.2)
	if player.camera and player.camera.has_method("shake"):
		player.camera.shake(5.0, 0.1)

func _process_dash(delta: float):
	dash_timer -= delta
	
	# Maintenir vélocité
	player.velocity = dash_direction * PlayerConstants.DASH_SPEED
	
	# Afterimages
	afterimage_counter += 1
	if afterimage_counter >= 4:
		_create_afterimage()
		afterimage_counter = 0
	
	# Fin du dash
	if dash_timer <= 0 or _should_end_dash():
		_end_dash()

func _should_end_dash() -> bool:
	return (player.is_on_wall() or 
			(dash_direction.y > 0 and player.is_on_floor()))

func _end_dash():
	disable()
	# Réduire vélocité finale
	if dash_direction.y > 0:
		player.velocity.y = PlayerConstants.DASH_SPEED * 0.3
		player.velocity.x = 0
	else:
		player.velocity.x = dash_direction.x * PlayerConstants.DASH_SPEED * 0.2
		player.velocity.y = 0

func _get_dash_direction() -> Vector2:
	match player.piston_direction:
		Player.PistonDirection.LEFT: return Vector2.RIGHT
		Player.PistonDirection.RIGHT: return Vector2.LEFT  
		Player.PistonDirection.UP: return Vector2.DOWN
		Player.PistonDirection.DOWN: return Vector2.ZERO
		_: return Vector2.ZERO

func _create_afterimage():
	# Copiez votre logique existante de DashState._create_afterimage()
	if not player.sprite.sprite_frames:
		return
	
	var afterimage = Sprite2D.new()
	afterimage.texture = player.sprite.sprite_frames.get_frame_texture(
		player.sprite.animation, 
		player.sprite.frame
	)
	
	afterimage.global_position = player.global_position
	afterimage.flip_h = player.sprite.flip_h
	afterimage.rotation = player.sprite.rotation
	afterimage.z_index = player.z_index - 1
	afterimage.modulate = Color(0.5, 0.7, 1.0, 0.6)
	
	player.get_parent().add_child(afterimage)
	
	var tween = afterimage.create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, 0.3)
	tween.tween_callback(afterimage.queue_free)
