# scripts/player/components/PlayerActionHandler.gd - FIX PAUSE
class_name PlayerActionHandler
extends Node

var player: Player
var world_space_state: PhysicsDirectSpaceState2D

func _ready():
	# 🔧 CRITIQUE: Handler doit s'arrêter pendant la pause
	process_mode = Node.PROCESS_MODE_PAUSABLE

func setup(player_ref: Player):
	player = player_ref
	world_space_state = player.get_world_2d().direct_space_state
	_connect_input_signals()
	print("🎮 PlayerActionHandler initialisé")

func _connect_input_signals():
	InputManager.rotate_left_requested.connect(_rotate_piston.bind(-1))
	InputManager.rotate_right_requested.connect(_rotate_piston.bind(1))
	InputManager.push_requested.connect(execute_push)

# === ROTATION DU PISTON ===
func _rotate_piston(direction: int):
	# 🔧 GARDE: Pas d'action si en pause
	if get_tree().paused:
		return
		
	var new_direction = (player.piston_direction + direction + 4) % 4
	player.piston_direction = new_direction as Player.PistonDirection
	player.sprite.rotation_degrees = player.piston_direction * 90
	
	# Effet sonore de rotation
	AudioManager.play_sfx("player/rotate", 0.3)
	print("🔄 Piston tourné vers: %s" % Player.PistonDirection.keys()[player.piston_direction])

# === SYSTÈME DE PUSH ===
func execute_push():
	# 🔧 GARDE: Pas d'action si en pause
	if get_tree().paused:
		return
		
	if player.piston_direction == Player.PistonDirection.DOWN:
		print("❌ Push impossible - piston vers le bas")
		return
	
	var push_vector = _get_push_vector()
	var pushable_object = player.detection_system.detect_pushable_object(push_vector)
	
	if pushable_object and _can_push(push_vector):
		var success = pushable_object.push(push_vector, pushable_object.push_force)
		_play_push_effects(success)
		print("✅ Push effectué - succès: %s" % success)
	else:
		print("❌ Push impossible - pas d'objet ou bloqué")

func _get_push_vector() -> Vector2:
	match player.piston_direction:
		Player.PistonDirection.LEFT: return Vector2.LEFT
		Player.PistonDirection.UP: return Vector2.UP
		Player.PistonDirection.RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN

func _can_push(direction: Vector2) -> bool:
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + direction * 8.0,
		0b00000010  # Layer des murs
	)
	query.exclude = [player]
	var result = world_space_state.intersect_ray(query)
	return not result.has("collider")

func _play_push_effects(success: bool):
	# Animation de push
	player.sprite.play("Push")
	AudioManager.play_sfx("player/push", 0.5)
	
	# Screen shake si succès
	if success and player.camera and player.camera.has_method("shake"):
		player.camera.shake(8.0, 0.15)
	
	# Retour à l'animation normale après push
	player.sprite.animation_finished.connect(_on_push_finished, CONNECT_ONE_SHOT)

func _on_push_finished():
	# Retourner à l'animation appropriée
	if player.is_on_floor():
		var movement = InputManager.get_movement()
		player.sprite.play("Run" if movement != 0 else "Idle")
