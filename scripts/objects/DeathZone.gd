extends Area2D
class_name DeathZone

# Dictionnaire pour tracker les joueurs par instance
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
		
	if not body.has_method("trigger_death") or not body.has_method("is_player_dead"):
		push_warning("DeathZone: Le joueur n'a pas les méthodes de mort requises")
		return
	
	# Vérifier que le joueur n'est pas déjà mort
	if body.is_player_dead():
		print("DeathZone: Joueur déjà mort, ignoré")
		return
	
	# Vérifier l'immunité de transition
	if body.has_method("has_transition_immunity") and body.has_transition_immunity():
		print("DeathZone: Joueur en immunité de transition, ignoré")
		return
	
	# Vérifier l'immunité de mort
	if body.has_method("has_death_immunity") and body.has_death_immunity():
		print("DeathZone: Joueur en immunité de mort, ignoré")
		return
	
	# Éviter les déclenchements multiples pour ce joueur spécifique
	var player_id = body.get_instance_id()
	if triggered_players.has(player_id):
		print("DeathZone: Déjà déclenché pour ce joueur, ignoré")
		return
	
	# Marquer ce joueur comme déclenché
	triggered_players[player_id] = true
	
	print("DeathZone: Déclenchement de la mort!")
	
	# Déclencher la mort du joueur de manière différée
	body.call_deferred("trigger_death")
	
	# Notifier le GameManager pour les statistiques
	call_deferred("_notify_game_manager")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		var player_id = body.get_instance_id()
		# Reset le flag quand le joueur sort de la zone
		if triggered_players.has(player_id):
			triggered_players.erase(player_id)
		print("DeathZone: Joueur sorti, flag reset")

func _notify_game_manager():
	"""Notifie le GameManager de la mort du joueur pour les stats"""
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_signal("player_died"):
		game_manager.player_died.emit()
