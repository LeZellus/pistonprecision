class_name PlayerActions
extends Node

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _process(delta: float):
	pass

# === ROTATION ===
func rotate_piston(direction: int):
	var new_direction = (player.piston_direction + direction + 4) % 4
	player.piston_direction = new_direction as Player.PistonDirection
	player.sprite.rotation_degrees = player.piston_direction * 90

func get_push_vector() -> Vector2:
	match player.piston_direction:
		Player.PistonDirection.DOWN: return Vector2.DOWN
		Player.PistonDirection.LEFT: return Vector2.LEFT
		Player.PistonDirection.UP: return Vector2.UP
		Player.PistonDirection.RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN

# === PUSH ===
func execute_push():
	if player.piston_direction == Player.PistonDirection.DOWN:
		return
	
	var push_vector = get_push_vector()
	
	if not _can_perform_push_action(push_vector):
		return
	
	var pushable_object = player.detection_system.detect_pushable_object(push_vector)
	var success = false
	
	if pushable_object:
		success = _attempt_push(push_vector)
	else:
		print("Aucun objet pushable détecté")
	
	_play_push_animation()
	
	if success:
		_trigger_push_shake()

func _can_perform_push_action(direction: Vector2) -> bool:
	var space_state = player.world_space_state
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + direction * 8.0
	)
	query.collision_mask = 0b00000010
	query.exclude = [player]
	
	return not space_state.intersect_ray(query)

func _attempt_push(direction: Vector2) -> bool:
	var pushable_object = player.detection_system.detect_pushable_object(direction)
	if not pushable_object:
		return false
	
	return pushable_object.push(direction, pushable_object.push_force)

func _play_push_animation():
	player.sprite.play("Push")
	AudioManager.play_sfx("player/push", 0.5)
	
	# Déconnecter si déjà connecté
	if player.sprite.animation_finished.is_connected(_on_push_animation_finished):
		player.sprite.animation_finished.disconnect(_on_push_animation_finished)
	
	player.sprite.animation_finished.connect(_on_push_animation_finished, CONNECT_ONE_SHOT)
	
func _on_push_animation_finished():
	if player.sprite.animation_finished.is_connected(_on_push_animation_finished):
		player.sprite.animation_finished.disconnect(_on_push_animation_finished)
	
	if player.is_on_floor():
		player.sprite.play("Run" if InputManager.get_movement() != 0 else "Idle")
	# Si en l'air, AirState._update_animation() s'en occupe déjà

func _trigger_push_shake():
	if not player.camera or not player.camera.has_method("shake"):
		return
	
	player.camera.shake(8.0, 0.15)
