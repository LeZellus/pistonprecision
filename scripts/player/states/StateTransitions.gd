# scripts/player/states/StateTransitions.gd - AVEC WALL JUMP TIMER
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
		"WallSlideState":
			return _handle_wall_slide_state(current_state, player, delta)
		"DashState":
			return null
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
	
	if InputManager.was_dash_pressed() and player.actions_component.can_dash():
		return _get_state("DashState")
	
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
	
	if InputManager.was_dash_pressed() and player.actions_component.can_dash():
		return _get_state("DashState")
	
	var current_name = current_state.get_script().get_global_name()
	
	if current_name == "JumpState" and player.velocity.y >= 0:
		return _get_state("FallState")
	
	# CORRECTION: Vérifier le wall jump timer avant d'autoriser wall slide
	if current_name == "FallState" and _can_wall_slide(player):
		return _get_state("WallSlideState")
	
	return null

func _handle_wall_slide_state(_current_state: State, player: Player, _delta: float) -> State:
	if player.is_on_floor():
		return _get_state("RunState") if InputManager.get_movement() != 0 else _get_state("IdleState")
	
	# CORRECTION: Wall jump depuis wall slide - PRIORITÉ ABSOLUE
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		print("Wall jump détecté depuis WallSlideState!")
		return _get_state("JumpState")
	
	# Sortir du wall slide si plus de mur OU timer actif
	if not _can_wall_slide(player):
		return _get_state("FallState")
	
	return null

func _can_wall_slide(player: Player) -> bool:
	"""Logique wall slide style Rite"""
	var current_wall_side = player.wall_detector.get_wall_side()
	
	# Empêcher re-grab du même mur trop rapidement
	if player.wall_jump_timer > 0 and current_wall_side == player.last_wall_side:
		# MAIS autoriser si on s'est suffisamment éloigné (style Rite)
		var distance_moved = abs(player.global_position.x - player.last_wall_position)
		if distance_moved < PlayerConstants.WALL_JUMP_MIN_SEPARATION:
			return false
	
	# Conditions normales de wall slide
	return (player.wall_detector.is_touching_wall() and 
			player.velocity.y > 30 and  # Seuil plus bas pour Rite
			player.wall_detector.wall_detection_active)
