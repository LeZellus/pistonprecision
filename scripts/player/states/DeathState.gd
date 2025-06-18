# scripts/player/states/DeathState.gd - VERSION FINALE SANS IMMUNITÉ
class_name DeathState
extends State

var death_timer: float = 0.0
var death_animation_played: bool = false

func _ready():
	animation_name = "Death"

func enter() -> void:
	super.enter()
	death_timer = 2.0
	death_animation_played = false
	
	print("💀 Joueur mort - début de l'animation")
	
	# Garder le joueur visible pour l'animation
	parent.velocity = Vector2.ZERO
	parent.sprite.visible = true
	
	# Animation et effets de mort
	_play_death_effects()
	
	# Enregistrer la mort
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("register_player_death"):
		game_manager.register_player_death()

func _play_death_effects():
	"""Joue tous les effets de mort"""
	# SON de mort
	AudioManager.play_sfx("player/death", 0.8)
	
	# ANIMATION de mort si elle existe
	if parent.sprite.sprite_frames.has_animation("Death"):
		parent.sprite.play("Death")
		death_animation_played = true
		print("🎬 Animation de mort lancée")
	else:
		print("⚠️ Animation 'Death' introuvable, effet alternatif")
		_play_death_fallback_effect()
	
	# PARTICULES de mort
	ParticleManager.emit_death(parent.global_position, 1.5)
	
	# SCREEN SHAKE
	if parent.camera and parent.camera.has_method("shake"):
		parent.camera.shake(15.0, 0.8)

func _play_death_fallback_effect():
	"""Effet visuel de remplacement si pas d'animation Death"""
	var tween = create_tween()
	tween.parallel().tween_property(parent.sprite, "modulate", Color.RED, 0.3)
	tween.parallel().tween_property(parent.sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(parent.sprite, "modulate:a", 0.0, 0.5)

func process_physics(delta: float) -> State:
	# Immobiliser pendant la mort
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	
	# Gérer le timer de respawn
	death_timer -= delta
	
	if death_timer <= 0:
		print("✨ Timer de respawn écoulé")
		_respawn_player()
		return _get_respawn_state()
	
	return null

func _respawn_player():
	"""Respawn du joueur"""
	# Position de respawn
	var respawn_pos = _get_respawn_position()
	parent.global_position = respawn_pos
	parent.velocity = Vector2.ZERO
	
	# Restaurer l'apparence
	parent.sprite.visible = true
	parent.sprite.modulate = Color.WHITE
	parent.sprite.scale = Vector2.ONE
	
	print("🔄 Joueur respawné à: %v" % respawn_pos)

func _get_respawn_position() -> Vector2:
	"""Trouve la meilleure position de respawn"""
	# PRIORITÉ 1: Checkpoint door
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_checkpoint():
		var door_id = game_manager.get_last_door_id()
		var door = _find_door_by_id(door_id)
		if door:
			print("📍 Respawn sur door: %s" % door_id)
			return door.get_spawn_position()
	
	# PRIORITÉ 2: SpawnPoint par défaut
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		var spawn_pos = spawn_manager.get_default_spawn_position()
		if spawn_pos != Vector2.ZERO:
			print("📍 Respawn sur spawn par défaut")
			return spawn_pos
	
	# FALLBACK
	print("📍 Respawn fallback")
	return Vector2(0, 100)

func _get_respawn_state() -> State:
	"""Détermine l'état après respawn"""
	# Toujours retourner à AirState pour éviter les bugs
	var air_state = parent.state_machine.get_node("AirState")
	if air_state:
		return air_state
	
	# Fallback vers GroundState
	return parent.state_machine.get_node("GroundState")

func _find_door_by_id(door_id: String) -> Door:
	"""Recherche une door par son ID"""
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door is Door and door.door_id == door_id:
			return door
	return null

func exit() -> void:
	"""Nettoyage à la sortie de l'état"""
	# S'assurer que le joueur est visible
	if parent.sprite:
		parent.sprite.visible = true
		parent.sprite.modulate = Color.WHITE
		parent.sprite.scale = Vector2.ONE
