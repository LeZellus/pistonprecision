# MovementSystem.gd - VERSION CORRIGÉE
class_name MovementSystem
extends Node

var player: Player
var components: Array[MovementComponent] = []

func _init(player_ref: Player):
	player = player_ref

func add_component(component: MovementComponent):
	components.append(component)
	add_child(component)
	print("🔧 Composant ajouté: ", component.get_script().get_global_name())  # DEBUG

func update_all(delta: float):
	print("🔧 MovementSystem.update_all() - ", components.size(), " composants")
	for component in components:
		print("🔧 Updating component: ", component.get_script().get_global_name())
		component.update(delta)  # ← CETTE LIGNE DOIT EXISTER !
