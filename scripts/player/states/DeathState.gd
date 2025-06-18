# scripts/player/states/DeathState.gd - VERSION ULTRA-SIMPLIFIÉE
class_name DeathState
extends State

# === TIMER SIMPLE ===
var respawn_timer: float = 0.0
const RESPAWN_DELAY: float = 1.5  # Délai avant respawn automatique

func _ready():
	animation_name = "Death"

func enter() -> void:
	super.enter()
	respawn_timer = RESPAWN_DELAY
	
	print("=== DEATH STATE ACTIVÉ ===")
	
	# CACHER le joueur immédiatement
	parent.sprite.visible = false
	parent.velocity = Vector2.ZERO
	
	# Enregistrer la mort
	_register_death()
	_play_death_effects()
	
	print("Joueur caché, timer de respawn: %f secondes" % RESPAWN_DELAY)

func _register_death():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()

func _play_death_effects():
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(8.0, 0.6)
	
	AudioManager.play_sfx("player/death", 0.8)

func process_frame(delta: float) -> State:
	# TIMER SIMPLE
	respawn_timer -= delta
	
	if respawn_timer <= 0:
		print("=== TIMER ÉCOULÉ - DÉBUT RESPAWN ===")
		_do_immediate_respawn()
		return parent.state_machine.get_node("AirState")  # Transition immédiate
	
	return null

func _do_immediate_respawn():
	"""Respawn immédiat et simple"""
	print("_do_immediate_respawn() appelé")
	
	# 1. TROUVER POSITION DE SPAWN
	var spawn_position = _get_respawn_position()
	print("Position de respawn trouvée: %v" % spawn_position)
	
	# 2. TÉLÉPORTER LE JOUEUR
	parent.global_position = spawn_position
	parent.velocity = Vector2.ZERO
	
	# 3. RENDRE VISIBLE
	parent.sprite.visible = true
	parent.sprite.modulate.a = 1.0
	
	# 4. RESET ÉTAT
	parent.start_respawn_immunity()
	
	print("=== RESPAWN TERMINÉ - JOUEUR VISIBLE ===")
	print("Position finale: %v" % parent.global_position)
	print("Sprite visible: %s" % parent.sprite.visible)

func _get_respawn_position() -> Vector2:
	"""Trouve la position de respawn (simplifié)"""
	
	# PRIORITÉ 1: Checkpoint door
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_checkpoint():
		var door_id = game_manager.get_last_door_id()
		print("Checkpoint door trouvé: %s" % door_id)
		
		var door = _find_door_by_id(door_id)
		if door:
			print("Door trouvée: %s" % door.door_id)
			return door.get_spawn_position()
		else:
			print("Door '%s' introuvable dans la scène" % door_id)
	
	# PRIORITÉ 2: SpawnPoint par défaut
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		var spawn_pos = spawn_manager.get_default_spawn_position()
		print("SpawnPoint par défaut: %v" % spawn_pos)
		if spawn_pos != Vector2.ZERO:
			return spawn_pos
	
	# FALLBACK: Position fixe
	print("FALLBACK: Position par défaut")
	return Vector2(0, 0)

func _find_door_by_id(door_id: String) -> Door:
	"""Recherche simple de door"""
	var doors = get_tree().get_nodes_in_group("doors")
	print("Recherche door '%s' parmi %d doors" % [door_id, doors.size()])
	
	for door in doors:
		if door is Door:
			print("Door trouvée: '%s'" % door.door_id)
			if door.door_id == door_id:
				return door
	
	return null

func process_physics(_delta: float) -> State:
	# Immobiliser le joueur pendant la mort
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	return null

func exit() -> void:
	print("=== SORTIE DE DEATH STATE ===")
	# S'assurer que le joueur est visible
	if parent.sprite:
		parent.sprite.visible = true
		parent.sprite.modulate.a = 1.0
