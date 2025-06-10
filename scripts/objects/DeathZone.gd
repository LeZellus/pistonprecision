# scripts/objects/DeathZone.gd - Version corrigée
extends Area2D
class_name DeathZone

func _ready():
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1

func _on_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	
	if not body.has_method("trigger_death"):
		return
	
	# Le DeathState et Player.gd gèrent toute la logique
	body.trigger_death()
	
	# Optionnel : stats pour le GameManager
	_notify_game_manager()

func _notify_game_manager():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_signal("player_died"):
		game_manager.player_died.emit()
