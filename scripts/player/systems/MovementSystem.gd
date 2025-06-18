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
	# OPTIMISATION: Une seule boucle, traitement des actifs prioritaire
	for component in components:
		component.update(delta)
