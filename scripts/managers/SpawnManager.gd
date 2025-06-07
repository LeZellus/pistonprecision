extends Node

var current_spawn_id: String = "default"

func _ready():
	name = "SpawnManager"

func set_spawn_point(spawn_id: String):
	"""Définit le point de spawn actuel"""
	current_spawn_id = spawn_id
	print("Spawn point défini: ", spawn_id)

func get_spawn_position() -> Vector2:
	"""Retourne la position du spawn actuel"""
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	
	# Chercher le spawn avec l'ID actuel
	for spawn in spawn_points:
		if spawn.spawn_id == current_spawn_id:
			return spawn.global_position
	
	# Fallback: chercher le spawn par défaut
	for spawn in spawn_points:
		if spawn.is_default_spawn:
			return spawn.global_position
	
	# Fallback ultime
	print("ATTENTION: Aucun spawn point trouvé!")
	return Vector2(32, 96)

func respawn_player(reset_room: bool = false):
	"""Téléporte le joueur au spawn actuel"""
	if reset_room:
		await _reset_current_room()
	else:
		_simple_respawn()

func _simple_respawn():
	"""Respawn simple sans recharger la room"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERREUR: Aucun joueur trouvé pour respawn")
		return
	
	var spawn_pos = get_spawn_position()
	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO
	
	print("Joueur respawné à: ", spawn_pos)

func _reset_current_room():
	"""Recharge la room entière puis respawn"""
	var current_room_id = SceneManager.get_current_room_id()
	if current_room_id == "":
		print("ERREUR: Aucune room actuelle trouvée")
		_simple_respawn()
		return
	
	# Recharger la room
	await SceneManager.load_room(current_room_id)
	
	# Respawn après rechargement
	await get_tree().process_frame  # Attendre que tout soit stable
	_simple_respawn()
