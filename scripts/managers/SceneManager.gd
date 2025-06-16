# scripts/managers/SceneManager.gd - Version propre
extends Node

# === REFERENCES ===
var world_container: Node2D
var player: Player
var current_room_node: Node2D
var current_world: WorldData
var current_room: RoomData

# === CONSTANTS ===
const ROOM_SIZE = Vector2(1320, 240)
const TRANSITION_BUFFER = 16
const PLAYER_SCENE = preload("res://scenes/player/Player.tscn")

func _ready():
	name = "SceneManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	world_container = Node2D.new()
	world_container.name = "WorldContainer"
	add_child(world_container)

# === API PRINCIPALE ===
func load_world_with_player(world_resource: WorldData, start_room_id: String = ""):
	"""Point d'entrée principal : charge le monde ET crée le joueur"""
	if not world_resource:
		push_error("SceneManager: Ressource monde null!")
		return
	
	current_world = world_resource
	
	# Créer le joueur en premier
	_create_player()
	
	# Déterminer la salle avec fallback intelligent
	var room_id = _get_valid_room_id(start_room_id)
	if room_id.is_empty():
		push_error("SceneManager: Aucune salle valide trouvée!")
		return
	
	await load_room(room_id)
	
	# Position initiale du joueur (première fois)
	_setup_initial_player_position()

func _create_player():
	"""Crée le joueur dans le monde"""
	_cleanup_player()
	
	player = PLAYER_SCENE.instantiate()
	world_container.add_child(player)
	print("SceneManager: Joueur créé et ajouté au monde")

func _setup_initial_player_position():
	"""Position le joueur au spawn initial (première fois seulement)"""
	if not player or not is_instance_valid(player):
		return
	
	# Vérifier si on a un checkpoint sauvegardé
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_checkpoint():
		var door_id = game_manager.get_last_door_id()
		var room_id = game_manager.get_last_room_id()
		
		print("SceneManager: Checkpoint trouvé - door '%s' dans room '%s'" % [door_id, room_id])
		
		# Si on est dans la bonne room, spawn à la door
		if room_id == get_current_room_id():
			var door = _find_door_by_id(door_id)
			if door:
				player.global_position = door.get_spawn_position()
				print("SceneManager: Position initiale à la door '%s'" % door_id)
				return
	
	# Sinon, chercher la door par défaut dans la room
	var default_door = _find_default_spawn_door()
	if default_door:
		player.global_position = default_door.get_spawn_position()
		print("SceneManager: Position initiale à la door par défaut '%s'" % default_door.door_id)
	else:
		# Fallback absolu (ne devrait plus arriver)
		player.global_position = Vector2(0, 0)
		print("SceneManager: ATTENTION - Aucune door de spawn trouvée, position (0,0)")

func _find_default_spawn_door() -> Door:
	"""Trouve la door marquée comme spawn par défaut"""
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door is Door and door.is_default_spawn:
			return door
	
	# Si aucune door par défaut, prendre la première
	if doors.size() > 0:
		return doors[0] as Door
	
	return null

func _find_door_by_id(door_id: String) -> Door:
	"""Trouve une door par son ID"""
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door is Door and door.door_id == door_id:
			return door
	return null

# === METHODES LEGACY ===
func initialize_with_player(player_scene: PackedScene):
	"""Méthode legacy - dépréciée"""
	push_warning("initialize_with_player est déprécié, utilisez load_world_with_player")
	_create_player()

func load_world(world_resource: WorldData, start_room_id: String = ""):
	await load_world_with_player(world_resource, start_room_id)

# === CHARGEMENT DE ROOMS ===
func load_room(room_id: String, _spawn_id: String = "default"):
	"""Charge une room (pour transitions normales)"""
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	var room_data = current_world.get_room(room_id)
	if not room_data:
		push_error("Salle introuvable: " + room_id)
		return
	
	current_room = room_data
	await _load_new_room(room_data)

func load_room_for_respawn(room_id: String):
	"""Charge une room pour respawn (ne modifie PAS la position du joueur)"""
	print("SceneManager: Chargement room '%s' pour respawn" % room_id)
	await load_room(room_id)

func _load_new_room(room_data: RoomData):
	"""Charge physiquement la nouvelle room"""
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
	
	# S'assurer que le joueur est au-dessus de la room
	if player and is_instance_valid(player):
		world_container.move_child(player, -1)

func transition_to_room(target_room_id: String):
	"""Transition normale entre rooms (via doors)"""
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

func transition_to_room_with_target_door(target_room_id: String, target_door_id: String):
	"""Transition avec téléportation à une door spécifique"""
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	var preserved_velocity = Vector2.ZERO
	if player and is_instance_valid(player):
		preserved_velocity = player.velocity
		
		if player.has_method("start_room_transition"):
			player.start_room_transition()
	
	await load_room(target_room_id)
	
	# Téléporter le joueur à la door cible
	_teleport_player_to_door(target_door_id)
	
	if player and is_instance_valid(player):
		player.velocity = preserved_velocity

func _teleport_player_to_door(door_id: String):
	"""Téléporte le joueur à une door spécifique"""
	if not player or not is_instance_valid(player):
		return
	
	var target_door = _find_door_by_id(door_id)
	if not target_door:
		print("SceneManager: ERREUR - Door '%s' introuvable pour téléportation" % door_id)
		return
	
	var spawn_pos = target_door.get_spawn_position()
	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO
	print("SceneManager: Joueur téléporté à la door '%s' position %v" % [door_id, spawn_pos])

# === CLEANUP ===
func _cleanup_player():
	if not player or not is_instance_valid(player):
		return
	
	player.queue_free()
	player = null

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

func _get_valid_room_id(requested_id: String) -> String:
	if not requested_id.is_empty() and current_world.get_room(requested_id):
		return requested_id
	
	if current_world.rooms.size() > 0:
		var fallback_id = current_world.rooms[0].room_id
		if not requested_id.is_empty():
			print("SceneManager: Salle '%s' introuvable, utilisation de '%s'" % [requested_id, fallback_id])
		return fallback_id
	
	return ""

# === GETTERS ===
func get_current_room_id() -> String:
	return current_room.room_id if current_room else ""

func get_current_world_id() -> String:
	return current_world.world_id if current_world else ""

func is_world_loaded() -> bool:
	return current_world != null

func is_room_loaded() -> bool:
	return current_room != null and current_room_node != null
