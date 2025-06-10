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

func _ready():
	name = "SceneManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	world_container = Node2D.new()
	world_container.name = "WorldContainer"
	add_child(world_container)

# === INITIALIZATION ===
func initialize_with_player(player_scene: PackedScene):
	# Vérifier que le joueur existe ET qu'il est valide
	if player and is_instance_valid(player):
		player.queue_free()
		await player.tree_exited
	
	player = player_scene.instantiate()
	
	if world_container:
		world_container.add_child(player)

func load_world(world_resource: WorldData, start_room_id: String = ""):
	if not world_resource:
		push_error("SceneManager: Ressource monde null!")
		return
	
	current_world = world_resource
	
	# Déterminer la salle à charger
	var room_id = start_room_id
	if room_id == "":
		# Prendre la première salle disponible par défaut
		if current_world.rooms.size() > 0:
			room_id = current_world.rooms[0].room_id
			print("SceneManager: Utilisation de la première salle disponible: ", room_id)
		else:
			push_error("SceneManager: Aucune salle disponible dans le monde!")
			return
	
	await load_room(room_id)

func load_room(room_id: String, _spawn_id: String = "default"):
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	var room_data = current_world.get_room(room_id)
	if not room_data:
		push_error("Salle introuvable: " + room_id)
		return
	
	current_room = room_data
	
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
	
	# Positionner le joueur au bon spawn
	if player and is_instance_valid(player):
		world_container.move_child(player, -1)
		player.velocity = Vector2.ZERO
		player.global_position = Vector2(10, 10)

# === TRANSITIONS ===
func transition_to_room(target_room_id: String):
	"""Transition vers une autre salle avec spawn spécifique"""
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	# Sauvegarder la vélocité pour une transition fluide
	var preserved_velocity = Vector2.ZERO
	if player and is_instance_valid(player):
		preserved_velocity = player.velocity
	
	# Commencer la transition
	if player and is_instance_valid(player) and player.has_method("start_room_transition"):
		player.start_room_transition()
	
	# Charger la nouvelle salle
	await load_room(target_room_id)
	
	# Restaurer la vélocité pour une transition fluide
	if player and is_instance_valid(player):
		player.velocity = preserved_velocity

# === CLEANUP METHOD ===
func cleanup_world():
	"""Nettoie tout le contenu du monde (salles + joueur)"""
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null
	
	current_world = null
	current_room = null

# === GETTERS ===
func get_current_room_id() -> String:
	return current_room.room_id if current_room else ""

func get_current_world_id() -> String:
	return current_world.world_id if current_world else ""
