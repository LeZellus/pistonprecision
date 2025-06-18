# scripts/player/states/DeathState.gd - VERSION FINALE
class_name DeathState
extends State

var death_timer: float = 0.0

func _ready():
	animation_name = "Death"
	set_process(true)

func enter() -> void:
	super.enter()
	death_timer = 2.0  # 2 secondes avant respawn
	
	print("💀 Joueur mort - respawn dans 2 secondes")
	
	# Arrêter le mouvement et cacher le joueur
	parent.velocity = Vector2.ZERO
	parent.sprite.visible = false
	
	# Enregistrer la mort
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()
	
	# Activer le process pour ce node
	set_process(true)

func _process(delta: float):
	death_timer -= delta
	
	# Quand le timer est écoulé
	if death_timer <= 0:
		print("✨ Respawn du joueur")
		set_process(false)  # Arrêter le process
		_respawn_player()
		
		# Transition vers AirState
		var air_state = parent.state_machine.get_node("AirState")
		if air_state:
			parent.state_machine.change_state(air_state)
		else:
			# Fallback vers GroundState
			var ground_state = parent.state_machine.get_node("GroundState")
			if ground_state:
				parent.state_machine.change_state(ground_state)

func _respawn_player():
	# Position de respawn intelligente
	var respawn_pos = _get_respawn_position()
	
	# Téléporter le joueur
	parent.global_position = respawn_pos
	parent.velocity = Vector2.ZERO
	
	# Rendre visible
	parent.sprite.visible = true
	parent.sprite.modulate.a = 1.0
	
	# Immunité temporaire
	parent.start_respawn_immunity()

func _get_respawn_position() -> Vector2:
	"""Trouve la meilleure position de respawn"""
	
	# PRIORITÉ 1: Checkpoint door
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_checkpoint():
		var door_id = game_manager.get_last_door_id()
		var door = _find_door_by_id(door_id)
		if door:
			return door.get_spawn_position()
	
	# PRIORITÉ 2: SpawnPoint par défaut
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		var spawn_pos = spawn_manager.get_default_spawn_position()
		if spawn_pos != Vector2.ZERO:
			return spawn_pos
	
	# FALLBACK: Position fixe
	return Vector2(0, 100)

func _find_door_by_id(door_id: String) -> Door:
	"""Recherche une door par son ID"""
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door is Door and door.door_id == door_id:
			return door
	return null

func process_frame(delta: float) -> State:
	# Plus utilisé, on utilise _process() à la place
	return null

func process_physics(_delta: float) -> State:
	# Immobiliser pendant la mort
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	return null

func exit() -> void:
	# Arrêter le process et s'assurer que le joueur est visible
	set_process(false)
	parent.sprite.visible = true
