class_name PlayerStateMachine
extends Node

# === STATES ===
enum State { IDLE, RUNNING, JUMPING, FALLING, WALL_SLIDING }

# === SIGNALS ===
signal state_changed(old_state: State, new_state: State)

# === PROPERTIES ===
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var fall_frame_override: bool = false
var player: Player

func _init(player_ref: Player):
	player = player_ref

func _ready():
	name = "StateMachine"

func _physics_process(_delta):
	var new_state = _calculate_state()
	
	# Override frame pendant la chute
	if current_state == State.FALLING and fall_frame_override:
		_set_fall_frame_based_on_velocity()
	
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
			pass
		State.JUMPING:
			player.sprite.play("Jump")
		State.FALLING:
			player.sprite.play("Fall")
			# Empêcher l'animation d'atteindre la dernière frame
			player.sprite.pause()
			_set_fall_frame_based_on_velocity()
		State.WALL_SLIDING:
			pass

func _exit_state(state: State):
	match state:
		State.JUMPING:
			player.is_jumping = false
		State.FALLING:
			fall_frame_override = false
		_:
			pass
			
func _set_fall_frame_based_on_velocity():
	var velocity_y = abs(player.velocity.y)
	var total_frames = player.sprite.sprite_frames.get_frame_count("Fall")
	
	if total_frames <= 1:
		return
	
	# Progression basée sur la vitesse (max 80% pour éviter crash frame)
	var max_velocity = PlayerConstants.MAX_FALL_SPEED
	var velocity_ratio = clamp(velocity_y / max_velocity, 0.0, 0.8)
	
	var target_frame = int(velocity_ratio * (total_frames - 1))
	player.sprite.frame = target_frame

# === GETTERS ===
func is_state(state: State) -> bool:
	return current_state == state

func is_grounded_state() -> bool:
	return current_state in [State.IDLE, State.RUNNING]

func is_airborne_state() -> bool:
	return current_state in [State.JUMPING, State.FALLING, State.WALL_SLIDING]

func get_state_name() -> String:
	return State.keys()[current_state]
