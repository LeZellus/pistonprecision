# scripts/objects/DeathZone.gd
extends Area2D
class_name DeathZone

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Configuration des layers pour éviter les conflits
	collision_layer = 0
	collision_mask = 1  # Layer du joueur

func _on_body_entered(body: Node2D):
	# Vérifications de sécurité
	if not body.is_in_group("player"):
		return
		
	if not body.has_method("trigger_death") or not body.has_method("is_player_dead"):
		push_warning("DeathZone: Le joueur n'a pas les méthodes de mort requises")
		return
	
	# Vérifier que le joueur n'est pas déjà mort
	if body.is_player_dead():
		return
	
	# Déclencher la mort du joueur de manière différée pour éviter les conflits de collision
	body.call_deferred("trigger_death")
	
	# Notifier le GameManager pour les statistiques
	call_deferred("_notify_game_manager")

func _notify_game_manager():
	"""Notifie le GameManager de la mort du joueur pour les stats"""
	var game_manager = get_node("/root/GameManager")
	if game_manager and game_manager.has_signal("player_died"):
		game_manager.player_died.emit()
