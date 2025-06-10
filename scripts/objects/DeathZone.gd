# scripts/objects/DeathZone.gd - Version corrigée
extends Area2D
class_name DeathZone

# Éviter les déclenchements multiples
var triggered_players: Dictionary = {}

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configuration des layers
	collision_layer = 0
	collision_mask = 1  # Layer du joueur

func _on_body_entered(body: Node2D):
	print("DeathZone: Corps entré - ", body.name)
	
	# Vérifications de sécurité
	if not body.is_in_group("player"):
		return
		
	if not body.has_method("trigger_death"):
		push_warning("DeathZone: Le joueur n'a pas la méthode trigger_death")
		return
	
	# Vérifier que le joueur n'est pas déjà mort
	if body.is_player_dead():
		print("DeathZone: Joueur déjà mort, ignoré")
		return
	
	# Éviter les déclenchements multiples
	var player_id = body.get_instance_id()
	if triggered_players.has(player_id):
		print("DeathZone: Déjà déclenché pour ce joueur, ignoré")
		return
	
	# Marquer ce joueur comme déclenché
	triggered_players[player_id] = true
	
	print("DeathZone: Déclenchement de la mort!")
	
	# Déclencher la mort du joueur
	body.trigger_death()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		var player_id = body.get_instance_id()
		# Reset le flag quand le joueur sort de la zone
		triggered_players.erase(player_id)
