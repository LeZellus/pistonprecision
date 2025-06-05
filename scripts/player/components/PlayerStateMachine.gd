class_name PlayerStateMachine
extends Node

# === SIGNALS ===
signal state_changed(old_state: String, new_state: String)

# === STATES ===
var states: Dictionary = {}
var current_state: BaseState
var previous_state: BaseState

# === RÉFÉRENCES ===
var player: Player

func _init(player_ref: Player):
	player = player_ref

func _ready():
	name = "StateMachine"
	_create_states()
	_initialize_state("IdleState")

func _create_states():
	var state_classes = {
		"IdleState": IdleState,
		"RunningState": RunningState,
		"JumpingState": JumpingState,
		"FallingState": FallingState,
		"WallSlidingState": WallSlidingState
	}
	
	for state_name in state_classes:
		var state = state_classes[state_name].new()
		state.player = player
		state.state_machine = self
		states[state_name] = state
		add_child(state)

func _initialize_state(state_name: String):
	if not states.has(state_name):
		return
	
	current_state = states[state_name]
	current_state.enter()

func _process(delta: float):
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float):
	if current_state:
		current_state.physics_update(delta)

func transition_to(new_state_name: String):
	if not states.has(new_state_name):
		return
	
	if current_state and not current_state.can_transition_to(new_state_name):
		return
	
	var old_state_name = current_state.get_state_name() if current_state else ""
	
	if current_state:
		current_state.exit()
		previous_state = current_state
	
	current_state = states[new_state_name]
	current_state.enter()
	
	state_changed.emit(old_state_name, new_state_name)

# === GETTERS ===
func get_current_state_name() -> String:
	return current_state.get_state_name() if current_state else ""

func is_state(state_name: String) -> bool:
	return get_current_state_name() == state_name

func is_grounded_state() -> bool:
	return get_current_state_name() in ["IdleState", "RunningState"]

func is_airborne_state() -> bool:
	return get_current_state_name() in ["JumpingState", "FallingState", "WallSlidingState"]
