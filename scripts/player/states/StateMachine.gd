class_name StateMachine
extends Node

@export var starting_state: NodePath
var current_state: State

func _ready():
	# 🔧 CRITIQUE: StateMachine doit s'arrêter pendant la pause
	process_mode = Node.PROCESS_MODE_PAUSABLE

func init(parent: Player) -> void:
	for child in get_children():
		child.parent = parent
		# 🔧 CRITIQUE: Tous les états doivent s'arrêter pendant la pause
		child.process_mode = Node.PROCESS_MODE_PAUSABLE
	
	if starting_state:
		var state_node = get_node(starting_state)
		if state_node:
			change_state(state_node)
		else:
			push_error("StateMachine: starting_state invalide!")

func change_state(new_state: State) -> void:
	print("🔄 StateMachine: Changement d'état")
	print("  Ancien état: %s" % (current_state.get_script().get_global_name() if current_state else "Aucun"))
	print("  Nouvel état: %s" % (new_state.get_script().get_global_name() if new_state else "Aucun"))
	
	if current_state:
		print("  Sortie de l'ancien état...")
		current_state.exit()
	
	current_state = new_state
	print("  Entrée dans le nouvel état...")
	current_state.enter()
	print("✅ Changement d'état terminé")

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
