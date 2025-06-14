class_name StateTransitions

static var _instance: StateTransitions
var _state_cache: Dictionary = {}

static func get_instance() -> StateTransitions:
	if not _instance:
		_instance = StateTransitions.new()
	return _instance

func get_next_state(current_state: State, player: Player, delta: float) -> State:
	# Cache des états au premier appel
	if _state_cache.is_empty():
		_cache_states(current_state)
	
	# IMPORTANT: Toujours vérifier la mort en premier
	if _should_die(player):
		return _get_state("DeathState")
	
	# Dispatch selon le type d'état
	match current_state.get_script().get_global_name():
		"IdleState", "RunState":
			return _handle_ground_states(current_state, player, delta)
		"JumpState", "FallState":
			return _handle_air_states(current_state, player, delta)
		"WallSlideState":
			return _handle_wall_slide_state(current_state, player, delta)
		"DashState":
			return null  # DashState gère ses propres transitions
		"DeathState":
			return null  # DeathState gère sa propre logique
	
	return null

func _should_die(player: Player) -> bool:
	"""Vérifie si le joueur devrait mourir (chute dans le vide, etc.)"""
	# Exemple : mort par chute (à adapter selon ton niveau)
	if player.global_position.y > 1000:  # Limite du niveau
		return true
	
	# Déjà mort ou en immunité
	if player.is_player_dead() or player.has_death_immunity():
		return false
	
	# Ajoute ici d'autres conditions de mort automatique si nécessaire
	# Par exemple : contact avec des ennemis, pièges, etc.
	
	return false

func _cache_states(reference_state: State):
	"""Cache les références d'états une seule fois"""
	var state_machine = reference_state.get_parent()
	
	for child in state_machine.get_children():
		if child is State:
			_state_cache[child.get_script().get_global_name()] = child

func _get_state(state_name: String) -> State:
	"""Récupère un état depuis le cache"""
	return _state_cache.get(state_name)

func _handle_ground_states(current_state: State, player: Player, _delta: float) -> State:
	# Quitter le sol ?
	if not player.is_on_floor():
		return _get_state("JumpState") if player.velocity.y < 0 else _get_state("FallState")
	
	# Jump ?
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		return _get_state("JumpState")
	
	# Dash ?
	if InputManager.was_dash_pressed() and player.actions_component.can_dash():
		return _get_state("DashState")
	
	# Idle <-> Run
	var movement = InputManager.get_movement()
	var current_name = current_state.get_script().get_global_name()
	
	if current_name == "IdleState" and movement != 0:
		return _get_state("RunState")
	elif current_name == "RunState" and movement == 0:
		return _get_state("IdleState")
	
	return null

func _handle_air_states(current_state: State, player: Player, _delta: float) -> State:
	# Atterrir ?
	if player.is_on_floor():
		return _get_state("RunState") if InputManager.get_movement() != 0 else _get_state("IdleState")
	
	# Jump depuis l'air ?
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		if InputManager.has_coyote_time():
			return _get_state("JumpState")
	
	# Dash ?
	if InputManager.was_dash_pressed() and player.actions_component.can_dash():
		return _get_state("DashState")
	
	var current_name = current_state.get_script().get_global_name()
	
	# Jump -> Fall ?
	if current_name == "JumpState" and player.velocity.y >= 0:
		return _get_state("FallState")
	
	# Wall slide ?
	if current_name == "FallState" and player.wall_detector.is_touching_wall() and player.velocity.y > 50:
		return _get_state("WallSlideState")
	
	return null

func _handle_wall_slide_state(_current_state: State, player: Player, _delta: float) -> State:
	# Atterrir ?
	if player.is_on_floor():
		return _get_state("RunState") if InputManager.get_movement() != 0 else _get_state("IdleState")
	
	# Wall jump ?
	if InputManager.consume_jump() and player.piston_direction == Player.PistonDirection.DOWN:
		return _get_state("JumpState")
	
	# Plus de mur ?
	if not player.can_wall_slide():
		return _get_state("FallState")
	
	return null
