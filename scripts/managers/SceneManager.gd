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
	print("=== DÉBUT initialize_with_player ===")
	print("world_container existe: ", world_container != null)
	if world_container:
		print("world_container parent: ", world_container.get_parent().name if world_container.get_parent() else "AUCUN")
	
	# FIX: Vérifier que le joueur existe ET qu'il est valide
	if player and is_instance_valid(player):
		print("Suppression ancien joueur: ", player.name)
		player.queue_free()
		await player.tree_exited  # Attendre qu'il soit vraiment supprimé
		print("Ancien joueur supprimé")
	
	print("Instanciation nouveau joueur...")
	player = player_scene.instantiate()
	print("Nouveau joueur créé: ", player.name)
	print("Joueur visible: ", player.visible)
	print("Joueur modulate: ", player.modulate)
	
	if world_container:
		print("Ajout du joueur au world_container...")
		world_container.add_child(player)
		print("Joueur ajouté. Parent: ", player.get_parent().name)
		print("Position globale: ", player.global_position)
		print("Enfants de world_container: ", world_container.get_child_count())
		for i in world_container.get_child_count():
			var child = world_container.get_child(i)
			print("  - ", child.name, " (", child.get_class(), ")")
	else:
		print("ERREUR: world_container est NULL!")
	
	print("=== FIN initialize_with_player ===")

func load_world(world_resource: WorldData, start_room_id: String = ""):
	if not world_resource:
		push_error("SceneManager: Ressource monde null!")
		return
	
	current_world = world_resource
	var room_id = start_room_id if start_room_id != "" else world_resource.spawn_room_id
	
	if room_id == "":
		push_error("SceneManager: Aucune salle de spawn définie!")
		return
	
	await load_room(room_id)

func load_room(room_id: String):
	print("=== DÉBUT load_room: ", room_id, " ===")
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	var room_data = current_world.get_room(room_id)
	if not room_data:
		push_error("Salle introuvable: " + room_id)
		return
	
	current_room = room_data
	print("Room data trouvée: ", room_data.scene_path)
	
	# Supprimer l'ancienne salle
	if current_room_node and is_instance_valid(current_room_node):
		print("Suppression ancienne salle: ", current_room_node.name)
		current_room_node.queue_free()
		await current_room_node.tree_exited
		print("Ancienne salle supprimée")
	
	# Charger la nouvelle salle
	var room_scene = load(room_data.scene_path)
	if not room_scene:
		push_error("Impossible de charger: " + room_data.scene_path)
		return
	
	print("Instanciation nouvelle salle...")
	current_room_node = room_scene.instantiate()
	current_room_node.name = "CurrentRoom"
	world_container.add_child(current_room_node)
	print("Nouvelle salle ajoutée: ", current_room_node.name)
	
	# S'assurer que le joueur reste au-dessus
	if player and is_instance_valid(player):
		print("Déplacement joueur au premier plan...")
		world_container.move_child(player, -1)
		print("Position joueur dans la hiérarchie: ", player.get_index())
		print("Position joueur globale: ", player.global_position)
	else:
		print("ATTENTION: Pas de joueur à déplacer!")
	
	print("=== FIN load_room ===")

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

# === TRANSITIONS ===
func transition_to_room(direction: String):
	if not current_room:
		push_error("Aucune salle actuelle")
		return
	
	var next_room_id = current_room.connections.get(direction)
	if not next_room_id:
		return
	
	# Sauvegarder la vélocité du joueur
	var preserved_velocity = player.velocity if player and is_instance_valid(player) else Vector2.ZERO
	
	# Calculer la nouvelle position
	var new_position = _calculate_transition_position(direction)
	
	# Commencer la transition sur le joueur
	if player and is_instance_valid(player) and player.has_method("start_room_transition"):
		player.start_room_transition()
	
	# Charger la nouvelle salle
	await load_room(next_room_id)
	
	# Repositionner le joueur
	if player and is_instance_valid(player):
		player.global_position = new_position
		player.velocity = preserved_velocity

func _calculate_transition_position(direction: String) -> Vector2:
	if not player or not is_instance_valid(player):
		return Vector2.ZERO
	
	var current_pos = player.global_position
	
	match direction:
		"right":
			return Vector2(TRANSITION_BUFFER, current_pos.y)
		"left":
			return Vector2(ROOM_SIZE.x - TRANSITION_BUFFER, current_pos.y)
		"up":
			return Vector2(current_pos.x, ROOM_SIZE.y - TRANSITION_BUFFER)
		"down":
			return Vector2(current_pos.x, TRANSITION_BUFFER)
	
	return current_pos

# === GETTERS ===
func get_current_room_id() -> String:
	return current_room.room_id if current_room else ""

func get_current_world_id() -> String:
	return current_world.world_id if current_world else ""
