# scripts/managers/SceneManager.gd - Système spawn simple
extends Node

# === REFERENCES ===
var world_container: Node2D
var player: Player
var current_room_node: Node2D
var current_world: WorldData
var current_room: RoomData

# === CONSTANTS ===
const PLAYER_SCENE = preload("res://scenes/player/Player.tscn")

func _ready():
	name = "SceneManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	world_container = Node2D.new()
	world_container.name = "WorldContainer"
	add_child(world_container)

# === API PRINCIPALE ===
func load_world_with_player(world_resource: WorldData, start_room_id: String = ""):
	if not world_resource:
		push_error("SceneManager: Ressource monde null!")
		return
	
	current_world = world_resource
	_create_player()
	
	var room_id = _get_valid_room_id(start_room_id)
	if room_id.is_empty():
		push_error("SceneManager: Aucune salle valide trouvée!")
		return
	
	await load_room(room_id)

func _create_player():
	_cleanup_player()
	
	player = PLAYER_SCENE.instantiate()
	world_container.add_child(player)
	print("SceneManager: Joueur créé")

func _cleanup_player():
	if not player or not is_instance_valid(player):
		return
	
	player.queue_free()
	player = null

func _get_valid_room_id(requested_id: String) -> String:
	if not requested_id.is_empty() and current_world.get_room(requested_id):
		return requested_id
	
	if current_world.rooms.size() > 0:
		return current_world.rooms[0].room_id
	
	return ""

func load_room(room_id: String):
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	var room_data = current_world.get_room(room_id)
	if not room_data:
		push_error("Salle introuvable: " + room_id)
		return
	
	current_room = room_data
	await _load_new_room(room_data)
	await _setup_player_in_room()

func _load_new_room(room_data: RoomData):
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		await current_room_node.tree_exited
	
	var room_scene = load(room_data.scene_path)
	if not room_scene:
		push_error("Impossible de charger: " + room_data.scene_path)
		return
	
	current_room_node = room_scene.instantiate()
	current_room_node.name = "CurrentRoom"
	world_container.add_child(current_room_node)

func _setup_player_in_room():
	if not player or not is_instance_valid(player):
		return
	
	world_container.move_child(player, -1)
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(-185, 30)
	
	await _safe_spawn_player()

func _safe_spawn_player():
	"""Fix universel spawn"""
	if not player:
		return
	
	var collision_shape = player.get_node("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	
	await get_tree().process_frame

# === TRANSITION AVEC SPAWN ID ===
func transition_to_room_with_spawn(target_room_id: String, target_spawn_id: String):
	"""Transition vers une salle et spawn sur la porte avec l'ID donné"""
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	var preserved_velocity = Vector2.ZERO
	if player and is_instance_valid(player):
		preserved_velocity = player.velocity
		
		if player.has_method("start_room_transition"):
			player.start_room_transition()
	
	await load_room(target_room_id)
	
	if player and is_instance_valid(player):
		player.velocity = preserved_velocity
		await _spawn_at_door(target_spawn_id)

func _spawn_at_door(door_id: String):
	"""Trouve la porte avec l'ID et spawne le joueur à côté"""
	if not current_room_node:
		return
	
	# Chercher la porte dans la scène actuelle
	var target_door = _find_door_by_id(door_id)
	if not target_door:
		print("SceneManager: Porte '%s' introuvable, spawn par défaut" % door_id)
		await _safe_spawn_player()
		return
	
	# Spawner à la position de la porte
	var spawn_pos = target_door.get_spawn_position()
	player.global_position = spawn_pos
	await _safe_spawn_player()
	
	print("SceneManager: Spawn sur porte '%s' en %s" % [door_id, spawn_pos])

func _find_door_by_id(door_id: String) -> Door:
	"""Trouve une porte par son ID dans la scène actuelle"""
	if not current_room_node:
		return null
	
	# Chercher récursivement dans tous les enfants
	return _search_door_recursive(current_room_node, door_id)

func _search_door_recursive(node: Node, door_id: String) -> Door:
	"""Recherche récursive d'une porte"""
	# Vérifier le nœud actuel
	if node is Door and node.door_id == door_id:
		return node
	
	# Chercher dans les enfants
	for child in node.get_children():
		var result = _search_door_recursive(child, door_id)
		if result:
			return result
	
	return null

# === LEGACY ===
func transition_to_room(target_room_id: String):
	await load_room(target_room_id)

func cleanup_world():
	_cleanup_player()
	_cleanup_room()
	_cleanup_world_data()

func _cleanup_room():
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null

func _cleanup_world_data():
	current_world = null
	current_room = null

# === GETTERS ===
func get_current_room_id() -> String:
	return current_room.room_id if current_room else ""

func get_current_world_id() -> String:
	return current_world.world_id if current_world else ""

func is_world_loaded() -> bool:
	return current_world != null

func is_room_loaded() -> bool:
	return current_room != null and current_room_node != null
