class_name StateTransitions

# Système centralisé de transitions - plus de duplication !
static func get_next_state(current_state: State, player: Player, delta: float) -> State:
	
	# === PRIORITÉ 1 : Mort ===
	if _should_die(player):
		return current_state.get_node("../DeathState")
	
	# === PRIORITÉ 2 : Transitions spéciales selon l'état actuel ===
	if current_state is IdleState or current_state is RunState:
		return _handle_ground_states(current_state, player, delta)
	elif current_state is JumpState or current_state is FallState:
		return _handle_air_states(current_state, player, delta)
	elif current_state is WallSlideState:
		return _handle_wall_slide_state(current_state, player, delta)
	elif current_state is DashState:
		return null  # DashState gère ses propres transitions
	
	return null

static func _should_die(player: Player) -> bool:
	# Logique de mort centralisée ici si besoin
	return false

static func _handle_ground_states(current_state: State, player: Player, _delta: float) -> State:
	# Quitter le sol ?
	if not player.is_on_floor():
		return current_state.get_node("../JumpState") if player.velocity.y < 0 else current_state.get_node("../FallState")
	
	# Jump ?
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		return current_state.get_node("../JumpState")
	
	# Dash ?
	if InputManager.was_dash_pressed() and player.actions_component.can_dash():
		return current_state.get_node("../DashState")
	
	# Idle <-> Run
	var movement = InputManager.get_movement()
	if current_state is IdleState and movement != 0:
		return current_state.get_node("../RunState")
	elif current_state is RunState and movement == 0:
		return current_state.get_node("../IdleState")
	
	return null

static func _handle_air_states(current_state: State, player: Player, _delta: float) -> State:
	# Atterrir ?
	if player.is_on_floor():
		return current_state.get_node("../RunState") if InputManager.get_movement() != 0 else current_state.get_node("../IdleState")
	
	# Jump depuis l'air (coyote/wall jump) ?
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		if InputManager.has_coyote_time():
			return current_state.get_node("../JumpState")
	
	# Dash ?
	if InputManager.was_dash_pressed() and player.actions_component.can_dash():
		return current_state.get_node("../DashState")
	
	# Jump -> Fall ?
	if current_state is JumpState and player.velocity.y >= 0:
		return current_state.get_node("../FallState")
	
	# Wall slide ?
	if current_state is FallState and player.wall_detector.is_touching_wall() and player.velocity.y > 50:
		return current_state.get_node("../WallSlideState")
	
	return null

static func _handle_wall_slide_state(current_state: State, player: Player, _delta: float) -> State:
	# Atterrir ?
	if player.is_on_floor():
		return current_state.get_node("../RunState") if InputManager.get_movement() != 0 else current_state.get_node("../IdleState")
	
	# Wall jump ?
	if InputManager.consume_jump_buffer() and player.piston_direction == Player.PistonDirection.DOWN:
		return current_state.get_node("../JumpState")
	
	# Plus de mur ?
	if not player.can_wall_slide():
		return current_state.get_node("../FallState")
	
	return null
