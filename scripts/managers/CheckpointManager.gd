# scripts/world/CheckpointManager.gd
extends Node

signal checkpoint_activated(checkpoint_id: String)

var active_checkpoint: String = ""
var spawn_points: Dictionary = {}

func _ready():
	name = "CheckpointManager"
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_spawn_point(id: String, position: Vector2):
	"""Enregistre un point de spawn"""
	spawn_points[id] = position
	print("CheckpointManager: Spawn '%s' enregistré à %v" % [id, position])

func activate_checkpoint(checkpoint_id: String):
	"""Active un nouveau checkpoint"""
	if checkpoint_id == active_checkpoint:
		return
	
	active_checkpoint = checkpoint_id
	checkpoint_activated.emit(checkpoint_id)
	
	# Notifier le GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.set_checkpoint(checkpoint_id)
	
	print("CheckpointManager: Checkpoint '%s' activé" % checkpoint_id)

func get_spawn_position() -> Vector2:
	"""Retourne la position de respawn actuelle"""
	if active_checkpoint.is_empty():
		return Vector2(-185, 30)  # Position par défaut
	
	return spawn_points.get(active_checkpoint, Vector2(-185, 30))

func reset_to_default():
	"""Reset au spawn par défaut"""
	active_checkpoint = ""
