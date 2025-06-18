# scripts/objects/DeathZone.gd - VERSION SIMPLIFIÉE
extends Area2D
class_name DeathZone

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Configuration des layers
	collision_layer = 0
	collision_mask = 1  # Layer du joueur
	
	print("💀 DeathZone initialisée à: %v" % global_position)

func _on_body_entered(body: Node2D):
	print("🔍 Quelque chose entre dans la DeathZone: %s" % body.name)
	
	# Vérifier que c'est le joueur
	if not body.is_in_group("player"):
		print("❌ Pas un joueur, ignoré")
		return
	
	# Vérifier que le joueur a la méthode trigger_death
	if not body.has_method("trigger_death"):
		print("❌ Le joueur n'a pas trigger_death()")
		return
	
	# Vérifier qu'il n'est pas déjà mort
	if body.is_player_dead():
		print("❌ Joueur déjà mort")
		return
	
	print("💀 DÉCLENCHEMENT MORT via DeathZone")
	
	# Déclencher la mort
	body.trigger_death()
