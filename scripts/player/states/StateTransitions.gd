# scripts/player/states/StateTransitions.gd - VERSION DEBUG
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
	
	# DEBUG: Vérifier régulièrement les conditions de mort
	var should_die = _should_die(player)
	if should_die:
		print("🔥 StateTransitions: Mort détectée!")
		print("Position Y: %f" % player.global_position.y)
		print("Is dead: %s" % player.is_player_dead())
		print("Has immunity: %s" % player.has_death_immunity())
		return _get_state("DeathState")
	
	# États principaux
	match current_state.get_script().get_global_name():
		"GroundState":
			return _handle_ground_state(player)
		"AirState":
			return _handle_air_state(player)
		"DeathState":
			return null
	
	return null

func _handle_ground_state(player: Player) -> State:
	if not player.is_on_floor():
		return _get_state("AirState")
	return null

func _handle_air_state(player: Player) -> State:
	if player.is_on_floor():
		return _get_state("GroundState")
	return null

func _should_die(player: Player) -> bool:
	# Ne pas redéclencher si déjà mort
	if player.is_player_dead() or player.has_death_immunity():
		return false
	
	# TEST: Mort quand Y > 200 (plus bas que d'habitude)
	if player.global_position.y > 200:
		print("🔥 Condition de mort: Y = %f > 200" % player.global_position.y)
		return true
	
	return false

func _cache_states(reference_state: State):
	var state_machine = reference_state.get_parent()
	for child in state_machine.get_children():
		if child is State:
			_state_cache[child.get_script().get_global_name()] = child
	
	print("États cachés: %s" % _state_cache.keys())

func _get_state(state_name: String) -> State:
	var state = _state_cache.get(state_name)
	if not state:
		print("❌ État '%s' introuvable!" % state_name)
	return state
