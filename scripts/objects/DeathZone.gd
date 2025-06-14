# scripts/objects/DeathZone.gd - Version simplifiée
extends Area2D
class_name DeathZone

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Configuration des layers
	collision_layer = 0
	collision_mask = 1  # Layer du joueur

func _on_body_entered(body: Node2D):
	# Vérifications simples
	if not body.is_in_group("player"):
		return
		
	if not body.has_method("trigger_death"):
		return
	
	# Vérifier que le joueur n'est pas déjà mort ou immunisé
	if body.is_player_dead() or body.has_death_immunity():
		return
	
	# Déclencher la mort
	body.trigger_death()
