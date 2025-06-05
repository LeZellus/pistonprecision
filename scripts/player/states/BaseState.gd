class_name BaseState
extends Node

# === RÉFÉRENCES ===
var player: Player
var state_machine: PlayerStateMachine

# === INTERFACE ===
func enter():
	pass

func exit():
	pass

func update(delta: float):
	pass

func physics_update(delta: float):
	pass

func can_transition_to(new_state: String) -> bool:
	return true

# === UTILITAIRES ===
func get_state_name() -> String:
	return get_script().get_path().get_file().get_basename()

func transition_to(state_name: String):
	if state_machine:
		state_machine.transition_to(state_name)
