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
	# Une seule boucle, actifs en premier pour performance
	var inactive_components: Array[MovementComponent] = []
	
	for component in components:
		if component.is_active():
			component.update(delta)
		else:
			inactive_components.append(component)
	
	# Update inactifs après
	for component in inactive_components:
		component.update(delta)
