class_name PlayerStateMachine
extends Node

# === STATES ===
enum State { IDLE, RUNNING, JUMPING, FALLING, WALL_SLIDING }

# === SIGNALS ===
signal state_changed(old_state: State, new_state: State)

# === PROPERTIES ===
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var player: Player

func _init(player_ref: Player):
	player = player_ref

func _ready():
	name = "StateMachine"

func _physics_process(_delta):
	var new_state = _calculate_state()
	
	if new_state != current_state:
		_change_state(new_state)

func _calculate_state() -> State:
	var velocity = player.velocity
	var is_grounded = player.ground_detector.is_grounded()
	var wall_data = player.wall_detector.get_wall_state()
	
	# Wall sliding prioritaire
	if wall_data.touching and velocity.y > 50:
		return State.WALL_SLIDING
	
	# États aériens
	if not is_grounded:
		if velocity.y < -50:
			return State.JUMPING
		else:
			return State.FALLING
	
	# États au sol
	if abs(velocity.x) > 10:
		return State.RUNNING
	else:
		return State.IDLE

func _change_state(new_state: State):
	_exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	_enter_state(new_state)
	
	state_changed.emit(previous_state, current_state)

func _enter_state(state: State):
	match state:
		State.IDLE:
			player.sprite.play("Idle")
		State.RUNNING:
			pass  # Animation de course si nécessaire
		State.JUMPING:
			player.sprite.play("Jump")
		State.FALLING:
			player.sprite.play("Fall")
		State.WALL_SLIDING:
			pass  # Animation wall slide si nécessaire

func _exit_state(state: State):
	match state:
		State.JUMPING:
			player.is_jumping = false
		_:
			pass

# === GETTERS ===
func is_state(state: State) -> bool:
	return current_state == state

func is_grounded_state() -> bool:
	return current_state in [State.IDLE, State.RUNNING]

func is_airborne_state() -> bool:
	return current_state in [State.JUMPING, State.FALLING, State.WALL_SLIDING]

func get_state_name() -> String:
	return State.keys()[current_state]
