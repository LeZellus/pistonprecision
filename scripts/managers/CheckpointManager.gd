# scripts/managers/CheckpointManager.gd - Version mise à jour
extends Node

signal checkpoint_activated(checkpoint_id: String)

# === CHECKPOINT DATA ===
var active_checkpoint_door_id: String = ""
var active_checkpoint_room_id: String = ""
var checkpoint_position: Vector2 = Vector2.ZERO

# === SPAWN POINTS (pour fallback) ===
var spawn_points: Dictionary = {}

func _ready():
	name = "CheckpointManager"
	process_mode = Node.PROCESS_MODE_ALWAYS

# === DOOR CHECKPOINT SYSTEM ===
func set_door_checkpoint(door_id: String, room_id: String, position: Vector2):
	"""Enregistre un checkpoint basé sur une door"""
	active_checkpoint_door_id = door_id
	active_checkpoint_room_id = room_id
	checkpoint_position = position
	
	checkpoint_activated.emit(door_id)
	
	# Notifier le GameManager pour sauvegarde
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_last_door"):
		game_manager.set_last_door(door_id, room_id)
	
	print("CheckpointManager: Door checkpoint '%s' activé en %v (room: %s)" % [door_id, position, room_id])

func get_checkpoint_position() -> Vector2:
	"""Retourne la position de checkpoint actuelle"""
	if has_door_checkpoint():
		return checkpoint_position
	
	# Fallback vers SpawnPoint par défaut
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		return spawn_manager.get_default_spawn_position()
	
	# Dernier fallback
	return Vector2.ZERO

func get_checkpoint_door_id() -> String:
	"""Retourne l'ID de la door checkpoint"""
	return active_checkpoint_door_id

func get_checkpoint_room_id() -> String:
	"""Retourne l'ID de la room checkpoint"""
	return active_checkpoint_room_id

func has_door_checkpoint() -> bool:
	"""Vérifie s'il y a un checkpoint door valide"""
	return not active_checkpoint_door_id.is_empty() and not active_checkpoint_room_id.is_empty()

# === SPAWN POINTS (pour compatibilité) ===
func register_spawn_point(id: String, position: Vector2):
	"""Enregistre un point de spawn (délégué au SpawnManager)"""
	spawn_points[id] = position
	
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		spawn_manager.register_spawn_point(id, position, id == "default")
	
	print("CheckpointManager: Spawn '%s' enregistré à %v" % [id, position])

# === RESET ===
func clear_checkpoint():
	"""Efface le checkpoint door"""
	active_checkpoint_door_id = ""
	active_checkpoint_room_id = ""
	checkpoint_position = Vector2.ZERO
	print("CheckpointManager: Checkpoint door effacé")

func reset_to_default():
	"""Reset complet"""
	clear_checkpoint()
	spawn_points.clear()

# === API DE COMPATIBILITÉ ===
func activate_checkpoint(checkpoint_id: String):
	"""Pour compatibilité avec l'ancien système"""
	print("CheckpointManager: activate_checkpoint() est deprecated, utilisez set_door_checkpoint()")

func get_spawn_position() -> Vector2:
	"""Alias pour get_checkpoint_position()"""
	return get_checkpoint_position()
