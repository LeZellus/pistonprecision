class_name StateMachine
extends Node

@export var starting_state: NodePath
var current_state: State

func init(parent: Player) -> void:
	for child in get_children():
		child.parent = parent
	
	if starting_state:
		var state_node = get_node(starting_state)
		if state_node:  # ✅ Vérification ajoutée
			change_state(state_node)
		else:
			push_error("StateMachine: starting_state invalide!")

func change_state(new_state: State) -> void:
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func process_physics(delta: float) -> void:
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)

func process_input(event: InputEvent) -> void:
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)

func process_frame(delta: float) -> void:
	var new_state = current_state.process_frame(delta)
	if new_state:
		change_state(new_state)
