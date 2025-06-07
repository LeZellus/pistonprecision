# scripts/managers/SpawnManager.gd - Version mise à jour
extends Node

var current_spawn_id: String = "default"

func _ready():
	name = "SpawnManager"

# NOUVEAU : Méthode principale qui utilise SceneManager
func respawn_player_at_current_room():
	"""Respawn le joueur dans la salle actuelle au bon spawn point"""
	var spawn_position = get_current_room_spawn_position()
	
	if SceneManager.player and is_instance_valid(SceneManager.player):
		SceneManager.player.global_position = spawn_position
		SceneManager.player.velocity = Vector2.ZERO
		print("Joueur respawné via SpawnManager à: ", spawn_position)
	else:
		push_error("SpawnManager: Aucun joueur trouvé pour respawn")

func get_current_room_spawn_position() -> Vector2:
	"""Obtient la position de spawn pour la salle actuelle"""
	# 1. SpawnPoint dans la salle actuelle
	if SceneManager.current_room_node:
		var spawn_point = SceneManager.current_room_node.get_node_or_null("SpawnPoint")
		if spawn_point:
			return spawn_point.global_position
	
	# 2. RoomData spawn points
	if SceneManager.current_room and SceneManager.current_room.spawn_points.has("default"):
		return SceneManager.current_room.spawn_points["default"]
	
	# 3. Chercher par ID dans la salle
	var spawn_by_id = _find_spawn_by_id(current_spawn_id)
	if spawn_by_id != Vector2.ZERO:
		return spawn_by_id
	
	# 4. Fallback : spawn par défaut
	return Vector2(32, 96)

func _find_spawn_by_id(spawn_id: String) -> Vector2:
	"""Cherche un spawn point par ID dans la salle actuelle"""
	if not SceneManager.current_room_node:
		return Vector2.ZERO
	
	var spawn_points = SceneManager.current_room_node.get_children().filter(
		func(node): return node.is_in_group("spawn_points")
	)
	
	for spawn in spawn_points:
		if spawn.spawn_id == spawn_id:
			return spawn.global_position
	
	return Vector2.ZERO

# LEGACY : Garder pour compatibilité mais adapter
func set_spawn_point(spawn_id: String):
	"""Définit le point de spawn actuel"""
	current_spawn_id = spawn_id
	print("Spawn point défini: ", spawn_id)

func get_spawn_position() -> Vector2:
	"""LEGACY - Redirige vers la nouvelle méthode"""
	return get_current_room_spawn_position()

func respawn_player(reset_room: bool = false):
	"""LEGACY - Respawn avec option de reset"""
	if reset_room:
		await _reset_current_room()
	else:
		respawn_player_at_current_room()

func _reset_current_room():
	"""Recharge la room entière puis respawn"""
	var current_room_id = SceneManager.get_current_room_id()
	if current_room_id == "":
		print("ERREUR: Aucune room actuelle trouvée")
		respawn_player_at_current_room()
		return
	
	# Recharger la room via SceneManager
	await SceneManager.load_room(current_room_id)
	
	# Respawn après rechargement
	await get_tree().process_frame
	respawn_player_at_current_room()
