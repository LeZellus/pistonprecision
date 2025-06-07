extends Area2D
class_name DeathZone

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		print("Joueur mort dans la deathzone!")
		
		# Utiliser le système de spawn
		SpawnManager.respawn_player(true)
		
		# Optionnel: notifier le GameManager pour les stats
		var game_manager = get_node("/root/GameManager")
		if game_manager and game_manager.has_method("player_die"):
			game_manager.player_die()
