# scripts/player/components/PlayerDeathHandler.gd
class_name PlayerDeathHandler
extends Node

var player: Player

func setup(player_ref: Player):
	player = player_ref
	print("💀 PlayerDeathHandler initialisé")

# === POINT D'ENTRÉE UNIQUE POUR LA MORT ===
func trigger_death():
	"""Méthode principale pour déclencher la mort du joueur"""
	if player.is_player_dead():
		print("🚫 Mort bloquée - déjà mort")
		return
	
	print("💀 DÉCLENCHEMENT MORT - Position: %v" % player.global_position)
	
	# Transition immédiate vers DeathState
	var death_state = player.state_machine.get_node("DeathState")
	if death_state:
		player.state_machine.change_state(death_state)
	else:
		push_error("DeathState introuvable dans la StateMachine!")

# === VÉRIFICATION D'ÉTAT ===
func is_player_dead() -> bool:
	"""Vérifie si le joueur est actuellement mort"""
	var current_state = player.state_machine.current_state
	return current_state and current_state.get_script().get_global_name() == "DeathState"

# === GESTION DES CONDITIONS DE MORT ===
func check_death_conditions() -> bool:
	"""Vérifie toutes les conditions qui peuvent causer la mort"""
	if is_player_dead():
		return false
	
	# Condition 1: Tombé trop bas
	if player.global_position.y > 200:
		print("💀 Condition de mort: Y = %f > 200" % player.global_position.y)
		return true
	
	# Ici vous pouvez ajouter d'autres conditions :
	# - Collision avec des pièges
	# - Dégâts de combat
	# - etc.
	
	return false

# === MÉTHODES DE RESPAWN ===
func get_respawn_position() -> Vector2:
	"""Trouve la meilleure position de respawn"""
	# PRIORITÉ 1: Checkpoint door sauvegardé
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_checkpoint():
		var door_id = game_manager.get_last_door_id()
		var door = _find_door_by_id(door_id)
		if door:
			print("📍 Respawn sur door: %s" % door_id)
			return door.get_spawn_position()
	
	# PRIORITÉ 2: SpawnPoint par défaut de la room
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		var spawn_pos = spawn_manager.get_default_spawn_position()
		if spawn_pos != Vector2.ZERO:
			print("📍 Respawn sur spawn par défaut")
			return spawn_pos
	
	# FALLBACK: Position de sécurité
	print("📍 Respawn fallback à (0, 100)")
	return Vector2(0, 100)

func _find_door_by_id(door_id: String) -> Door:
	"""Recherche une door par son ID dans la scène actuelle"""
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door is Door and door.door_id == door_id:
			return door
	return null

# === MÉTHODES UTILITAIRES ===
func reset_player_state():
	"""Remet le joueur dans un état propre après respawn"""
	player.velocity = Vector2.ZERO
	player.piston_direction = Player.PistonDirection.DOWN
	player.sprite.rotation_degrees = 0
	player.sprite.visible = true
	player.sprite.modulate = Color.WHITE
	player.sprite.scale = Vector2.ONE
	
	print("🔄 État du joueur remis à zéro")
