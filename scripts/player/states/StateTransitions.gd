# scripts/player/states/StateTransitions.gd - SIMPLIFIÉ avec 2 états principaux
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
	
	# Mort = priorité absolue
	if _should_die(player):
		return _get_state("DeathState")
	
	# LOGIQUE SIMPLIFIÉE : 2 états principaux + mort
	match current_state.get_script().get_global_name():
		"GroundState":
			return _handle_ground_state(player)
		"AirState":
			return _handle_air_state(player)
		"DeathState":
			return null  # Géré en interne
	
	return null

func _handle_ground_state(player: Player) -> State:
	"""GroundState → AirState quand on quitte le sol"""
	if not player.is_on_floor():
		return _get_state("AirState")
	return null

func _handle_air_state(player: Player) -> State:
	"""AirState → GroundState quand on touche le sol"""
	if player.is_on_floor():
		return _get_state("GroundState")
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
