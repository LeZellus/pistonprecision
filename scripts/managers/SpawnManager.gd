# scripts/managers/SpawnManager.gd
extends Node

var spawn_points: Dictionary = {}
var default_spawn_id: String = ""

func _ready():
	name = "SpawnManager"
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_spawn_point(spawn_id: String, position: Vector2, is_default: bool = false):
	"""Enregistre un point de spawn"""
	spawn_points[spawn_id] = position
	
	if is_default:
		default_spawn_id = spawn_id
		print("SpawnManager: Spawn par défaut '%s' enregistré à %v" % [spawn_id, position])
	else:
		print("SpawnManager: Spawn '%s' enregistré à %v" % [spawn_id, position])

func get_spawn_position(spawn_id: String = "") -> Vector2:
	"""Retourne la position d'un spawn. Si vide, utilise le spawn par défaut"""
	var target_id = spawn_id if not spawn_id.is_empty() else default_spawn_id
	
	if target_id.is_empty():
		push_error("SpawnManager: Aucun spawn par défaut défini!")
		return Vector2.ZERO
	
	if not spawn_points.has(target_id):
		push_error("SpawnManager: Spawn '%s' introuvable!" % target_id)
		return get_default_spawn_position()
	
	return spawn_points[target_id]

func get_default_spawn_position() -> Vector2:
	"""Retourne la position du spawn par défaut"""
	if default_spawn_id.is_empty():
		push_error("SpawnManager: Aucun spawn par défaut défini!")
		return Vector2.ZERO
	
	return spawn_points.get(default_spawn_id, Vector2.ZERO)

func has_spawn(spawn_id: String) -> bool:
	"""Vérifie si un spawn existe"""
	return spawn_points.has(spawn_id)

func clear_spawns():
	"""Efface tous les spawns (pour changement de niveau)"""
	spawn_points.clear()
	default_spawn_id = ""
	print("SpawnManager: Tous les spawns effacés")

func find_spawns_in_scene():
	"""Trouve automatiquement tous les SpawnPoints dans la scène actuelle"""
	clear_spawns()
	
	var spawns = get_tree().get_nodes_in_group("spawn_points")
	for spawn in spawns:
		if spawn is SpawnPoint:
			register_spawn_point(spawn.spawn_id, spawn.global_position, spawn.is_default_spawn)
