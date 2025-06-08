# scripts/managers/SceneManager.gd - Version avec reset
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
	
	# FIX: Vérifier que le joueur existe ET qu'il est valide
	if player and is_instance_valid(player):
		print("Suppression ancien joueur: ", player.name)
		player.queue_free()
		await player.tree_exited
		print("Ancien joueur supprimé")
	
	print("Instanciation nouveau joueur...")
	player = player_scene.instantiate()
	print("Nouveau joueur créé: ", player.name)
	
	if world_container:
		print("Ajout du joueur au world_container...")
		world_container.add_child(player)
		print("Joueur ajouté. Parent: ", player.get_parent().name)
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

func load_room(room_id: String, spawn_id: String = "default"):
	print("=== DÉBUT load_room: ", room_id, " spawn: ", spawn_id, " ===")
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
		
		var spawn_pos = _get_spawn_position(spawn_id)
		player.global_position = spawn_pos
		player.velocity = Vector2.ZERO
		
		print("Joueur positionné au spawn: ", spawn_pos)

# === NOUVEAU : RESET DE SALLE ===
func reset_current_room():
	"""Reset complet de la salle actuelle"""
	if not current_room:
		push_error("Aucune salle à reset")
		return
	
	print("=== RESET SALLE ===")
	
	# Recharger la salle
	var current_room_id = current_room.room_id
	await load_room(current_room_id, "default")
	
	print("=== SALLE RESETÉE ===")

# === TRANSITIONS ===
func transition_to_room(target_room_id: String, spawn_id: String = "default"):
	"""Transition vers une autre salle avec spawn spécifique"""
	if not current_world:
		push_error("Aucun monde chargé")
		return
	
	# Sauvegarder la vélocité
	var preserved_velocity = player.velocity if player and is_instance_valid(player) else Vector2.ZERO
	
	# Commencer la transition
	if player and is_instance_valid(player) and player.has_method("start_room_transition"):
		player.start_room_transition()
	
	# Charger la nouvelle salle
	await load_room(target_room_id, spawn_id)
	
	# Restaurer la vélocité si c'est une transition fluide (pas un reset)
	if player and is_instance_valid(player) and spawn_id != "default":
		player.velocity = preserved_velocity

func _get_spawn_position(spawn_id: String = "default") -> Vector2:
	"""Trouve la position d'un spawn dans la salle actuelle"""
	if not current_room_node:
		return Vector2(0, 96)  # Position de secours
	
	# 1. Chercher le SpawnPoint avec l'ID demandé
	var spawn_points = current_room_node.get_children().filter(
		func(node): return node.is_in_group("spawn_points")
	)
	
	for spawn in spawn_points:
		if spawn.spawn_id == spawn_id:
			return spawn.global_position
	
	# 2. Chercher le spawn par défaut
	for spawn in spawn_points:
		if spawn.is_default_spawn:
			return spawn.global_position
	
	# 3. Prendre le premier spawn trouvé
	if spawn_points.size() > 0:
		return spawn_points[0].global_position
	
	# 4. Position de secours
	return Vector2(0, 96)

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
