# scripts/managers/SceneManager.gd
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

# === NOUVELLE API PRINCIPALE ===
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

func _create_player():
	"""Crée le joueur dans le monde"""
	# Cleanup sécurisé du joueur existant
	_cleanup_player()
	
	player = PLAYER_SCENE.instantiate()
	world_container.add_child(player)
	print("SceneManager: Joueur créé et ajouté au monde")

# === METHODES LEGACY (pour compatibilité) ===
func initialize_with_player(player_scene: PackedScene):
	"""Méthode legacy - dépréciée, utilisez load_world_with_player"""
	push_warning("initialize_with_player est déprécié, utilisez load_world_with_player")
	_create_player()

func load_world(world_resource: WorldData, start_room_id: String = ""):
	await load_world_with_player(world_resource, start_room_id)

# === RESTE DU CODE IDENTIQUE ===
func _cleanup_player():
	if not player or not is_instance_valid(player):
		return
	
	player.queue_free()
	player = null

func _get_valid_room_id(requested_id: String) -> String:
	if not requested_id.is_empty() and current_world.get_room(requested_id):
		return requested_id
	
	if current_world.rooms.size() > 0:
		var fallback_id = current_world.rooms[0].room_id
		if not requested_id.is_empty():
			print("SceneManager: Salle '%s' introuvable, utilisation de '%s'" % [requested_id, fallback_id])
		return fallback_id
	
	return ""

func load_room(room_id: String, _spawn_id: String = "default"):
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	var room_data = current_world.get_room(room_id)
	if not room_data:
		push_error("Salle introuvable: " + room_id)
		return
	
	current_room = room_data
	
	# Cleanup et chargement de la nouvelle salle
	await _load_new_room(room_data)
	
	# Setup du joueur
	_setup_player_in_room()

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
	
	# S'assurer que le joueur est au-dessus de la salle
	world_container.move_child(player, -1)
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(-185, 30)

func transition_to_room(target_room_id: String):
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
