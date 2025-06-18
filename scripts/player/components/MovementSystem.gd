# MovementSystem.gd - Version optimisée
class_name MovementSystem
extends Node

var player: Player
var components: Array[MovementComponent] = []

func _init(player_ref: Player):
	player = player_ref

func add_component(component: MovementComponent):
	components.append(component)
	add_child(component)

func update_all(delta: float):
	# Optimisation : update seuls les composants actifs en premier
	for component in components:
		if component.is_active():
			component.update(delta)
	
	# Puis les composants inactifs (pour vérifier s'ils doivent s'activer)
	for component in components:
		if not component.is_active():
			component.update(delta)
