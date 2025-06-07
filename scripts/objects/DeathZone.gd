# scripts/objects/DeathZone.gd - Version corrigée
extends Area2D
class_name DeathZone

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		print("Joueur mort dans la deathzone!")
		
		# Utiliser le système de spawn unifié via SceneManager
		_respawn_player()
		
		# Notifier le GameManager pour les stats
		var game_manager = get_node("/root/GameManager")
		if game_manager and game_manager.has_method("player_died"):
			game_manager.player_died.emit()

func _respawn_player():
	# Obtenir la position de spawn de la salle actuelle
	var spawn_position = _get_current_room_spawn()
	
	# Téléporter le joueur
	if SceneManager.player and is_instance_valid(SceneManager.player):
		SceneManager.player.global_position = spawn_position
		SceneManager.player.velocity = Vector2.ZERO
		
		# Optionnel : petit effet de respawn
		_play_respawn_effects()
		
		print("Joueur respawné à: ", spawn_position)
	else:
		push_error("Impossible de respawn : joueur non trouvé")

func _get_current_room_spawn() -> Vector2:
	# 1. Chercher un SpawnPoint dans la salle actuelle
	if SceneManager.current_room_node:
		var spawn_point = SceneManager.current_room_node.get_node_or_null("SpawnPoint")
		if spawn_point:
			return spawn_point.global_position
	
	# 2. Utiliser les spawn_points du RoomData si définis
	if SceneManager.current_room and SceneManager.current_room.spawn_points.has("default"):
		return SceneManager.current_room.spawn_points["default"]
	
	# 3. Position par défaut sécurisée
	return Vector2(32, 96)  # Position par défaut comme dans votre SpawnManager

func _play_respawn_effects():
	# Shake caméra
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(3.0, 0.2)
	
	# Son de mort/respawn
	AudioManager.play_sfx("player/death", 0.3)
	
	# Particules de respawn (optionnel)
	if SceneManager.player:
		ParticleManager.emit_dust(SceneManager.player.global_position, 0.0)
