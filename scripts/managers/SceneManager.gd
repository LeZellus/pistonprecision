# scripts/managers/SceneManager.gd - Version optimisée
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

func _ready():
	name = "SceneManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	world_container = Node2D.new()
	world_container.name = "WorldContainer"
	add_child(world_container)

# === INITIALIZATION OPTIMISÉE ===
func initialize_with_player(player_scene: PackedScene):
	# Cleanup sécurisé du joueur existant
	_cleanup_player()
	
	player = player_scene.instantiate()
	world_container.add_child(player)

func _cleanup_player():
	"""Nettoyage sécurisé du joueur"""
	if not player or not is_instance_valid(player):
		return
	
	player.queue_free()
	player = null

# === WORLD LOADING OPTIMISÉ ===
func load_world(world_resource: WorldData, start_room_id: String = ""):
	if not world_resource:
		push_error("SceneManager: Ressource monde null!")
		return
	
	current_world = world_resource
	
	# Déterminer la salle avec fallback intelligent
	var room_id = _get_valid_room_id(start_room_id)
	if room_id.is_empty():
		push_error("SceneManager: Aucune salle valide trouvée!")
		return
	
	await load_room(room_id)

func _get_valid_room_id(requested_id: String) -> String:
	"""Retourne un room_id valide avec fallback"""
	# Si une salle spécifique est demandée et existe
	if not requested_id.is_empty() and current_world.get_room(requested_id):
		return requested_id
	
	# Fallback sur la première salle disponible
	if current_world.rooms.size() > 0:
		var fallback_id = current_world.rooms[0].room_id
		if not requested_id.is_empty():
			print("SceneManager: Salle '%s' introuvable, utilisation de '%s'" % [requested_id, fallback_id])
		return fallback_id
	
	return ""

# === ROOM LOADING OPTIMISÉ ===
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
	"""Charge une nouvelle salle avec cleanup sécurisé"""
	# Supprimer l'ancienne salle
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		await current_room_node.tree_exited
	
	# Charger la nouvelle salle
	var room_scene = load(room_data.scene_path)
	if not room_scene:
		push_error("Impossible de charger: " + room_data.scene_path)
		return
	
	current_room_node = room_scene.instantiate()
	current_room_node.name = "CurrentRoom"
	world_container.add_child(current_room_node)

func _setup_player_in_room():
	"""Configure le joueur dans la salle"""
	if not player or not is_instance_valid(player):
		return
	
	# S'assurer que le joueur est au-dessus de la salle
	world_container.move_child(player, -1)
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(10, 10)

# === TRANSITIONS OPTIMISÉES ===
func transition_to_room(target_room_id: String):
	"""Transition vers une autre salle avec preservation de vélocité"""
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	# Préserver la vélocité pour transition fluide
	var preserved_velocity = Vector2.ZERO
	if player and is_instance_valid(player):
		preserved_velocity = player.velocity
		
		# Démarrer la transition côté joueur
		if player.has_method("start_room_transition"):
			player.start_room_transition()
	
	# Charger la nouvelle salle
	await load_room(target_room_id)
	
	# Restaurer la vélocité
	if player and is_instance_valid(player):
		player.velocity = preserved_velocity

# === CLEANUP OPTIMISÉ ===
func cleanup_world():
	"""Nettoie tout le contenu du monde"""
	_cleanup_player()
	_cleanup_room()
	_cleanup_world_data()

func _cleanup_room():
	"""Nettoie la salle actuelle"""
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null

func _cleanup_world_data():
	"""Nettoie les données du monde"""
	current_world = null
	current_room = null

# === GETTERS SÉCURISÉS ===
func get_current_room_id() -> String:
	return current_room.room_id if current_room else ""

func get_current_world_id() -> String:
	return current_world.world_id if current_world else ""

func is_world_loaded() -> bool:
	return current_world != null

func is_room_loaded() -> bool:
	return current_room != null and current_room_node != null
