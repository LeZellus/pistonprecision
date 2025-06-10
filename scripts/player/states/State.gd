class_name State
extends Node

@export var animation_name: String
var parent: Player

func enter() -> void:
	if animation_name:
		parent.sprite.play(animation_name)

func exit() -> void:
	pass

func process_input(_event: InputEvent) -> State:
	return null

func process_frame(_delta: float) -> State:
	return null

func process_physics(_delta: float) -> State:
	return null

# SUPPRIMEZ toutes les autres fonctions - elles sont maintenant dans StateTransitions !
