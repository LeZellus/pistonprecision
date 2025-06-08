extends Area2D
class_name DeathZone

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		print("Joueur mort dans la deathzone!")
		
		# Effets visuels/sonores
		_play_death_effects()
		
		# Reset complet de la salle via SceneManager
		SceneManager.reset_current_room()
		
		# Notifier le GameManager pour les stats
		var game_manager = get_node("/root/GameManager")
		if game_manager and game_manager.has_signal("player_died"):
			game_manager.player_died.emit()

func _play_death_effects():
	# Shake caméra
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(3.0, 0.2)
	
	# Son de mort
	AudioManager.play_sfx("player/death", 0.3)
	
	# Particules de mort (optionnel)
	if SceneManager.player:
		ParticleManager.emit_dust(SceneManager.player.global_position, 0.0)
