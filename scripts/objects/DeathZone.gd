# scripts/objects/DeathZone.gd
extends Area2D
class_name DeathZone

var death_triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configuration des layers pour éviter les conflits
	collision_layer = 0
	collision_mask = 1  # Layer du joueur

func _on_body_entered(body: Node2D):
	# Debug
	print("DeathZone: Corps entré - ", body.name, " à la position ", body.global_position)
	print("DeathZone position: ", global_position)
	
	# Vérifications de sécurité
	if not body.is_in_group("player"):
		return
		
	if not body.has_method("trigger_death") or not body.has_method("is_player_dead"):
		push_warning("DeathZone: Le joueur n'a pas les méthodes de mort requises")
		return
	
	# Vérifier que le joueur n'est pas déjà mort ou en immunité
	if body.is_player_dead():
		print("DeathZone: Joueur déjà mort, ignoré")
		return
	
	# Vérifier l'immunité de transition
	if body.has_method("has_transition_immunity") and body.has_transition_immunity():
		print("DeathZone: Joueur en immunité, ignoré")
		return
	
	# Éviter les déclenchements multiples
	if death_triggered:
		print("DeathZone: Déjà déclenché, ignoré")
		return
	
	death_triggered = true
	
	print("DeathZone: Déclenchement de la mort!")
	
	# Déclencher la mort du joueur de manière différée pour éviter les conflits de collision
	body.call_deferred("trigger_death")
	
	# Notifier le GameManager pour les statistiques
	call_deferred("_notify_game_manager")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		# Reset le flag quand le joueur sort de la zone
		death_triggered = false

func _notify_game_manager():
	"""Notifie le GameManager de la mort du joueur pour les stats"""
	var game_manager = get_node("/root/GameManager")
	if game_manager and game_manager.has_signal("player_died"):
		game_manager.player_died.emit()
