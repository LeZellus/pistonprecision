class_name StateTransitions

static var _instance: StateTransitions
var _state_cache: Dictionary = {}

static func get_instance() -> StateTransitions:
	if not _instance:
		_instance = StateTransitions.new()
	return _instance

func get_next_state(current_state: State, player: Player, delta: float) -> State:
	if _state_cache.is_empty():
		_cache_states(current_state)
	
	if _should_die(player):
		return _get_state("DeathState")
	
	match current_state.get_script().get_global_name():
		"IdleState", "RunState":
			return _handle_ground_states(current_state, player, delta)
		"JumpState", "FallState":
			return _handle_air_states(current_state, player, delta)
		"DeathState":
			return null
	
	return null

func _should_die(player: Player) -> bool:
	if player.global_position.y > 1000:
		return true
	if player.is_player_dead() or player.has_death_immunity():
		return false
	return false

func _cache_states(reference_state: State):
	var state_machine = reference_state.get_parent()
	for child in state_machine.get_children():
		if child is State:
			_state_cache[child.get_script().get_global_name()] = child

func _get_state(state_name: String) -> State:
	return _state_cache.get(state_name)

func _handle_ground_states(current_state: State, player: Player, _delta: float) -> State:
	if not player.is_on_floor():
		return _get_state("JumpState") if player.velocity.y < 0 else _get_state("FallState")
	
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		return _get_state("JumpState")
	
	var movement = InputManager.get_movement()
	var current_name = current_state.get_script().get_global_name()
	
	if current_name == "IdleState" and movement != 0:
		return _get_state("RunState")
	elif current_name == "RunState" and movement == 0:
		return _get_state("IdleState")
	
	return null

func _handle_air_states(current_state: State, player: Player, _delta: float) -> State:
	if player.is_on_floor():
		return _get_state("RunState") if InputManager.get_movement() != 0 else _get_state("IdleState")
	
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		if InputManager.has_coyote_time():
			return _get_state("JumpState")
	
	var current_name = current_state.get_script().get_global_name()
	
	if current_name == "JumpState" and player.velocity.y >= 0:
		return _get_state("FallState")
	
	# NOUVEAU: Activer wall slide component au lieu de changer d'état
	if current_name == "FallState" and player.wall_slide_component:
		if player.wall_slide_component.has_method("try_activate"):
			player.wall_slide_component.try_activate()
	
	return null
