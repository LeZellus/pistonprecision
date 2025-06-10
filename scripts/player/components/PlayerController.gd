class_name PlayerController
extends Node

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _process(delta: float):
	# Vérifier si le joueur est mort avant tout traitement
	if player.is_dead:
		return
	
	player.state_machine.process_frame(delta)

func _physics_process(delta: float):
	# Vérifier si le joueur est mort avant tout traitement
	if player.is_dead:
		return
		
	delta = min(delta, 1.0/30.0)
	_handle_grounding()
	_update_wall_jump_timer(delta)
	player.state_machine.process_physics(delta)

func _handle_grounding():
	var grounded = player.is_on_floor()
	
	if grounded and player.was_grounded:
		player.wall_detector.set_active(false)
	elif not grounded:
		player.wall_detector.set_active(true)
	
	if grounded and not player.was_grounded:
		AudioManager.play_sfx("player/land", 1)
		ParticleManager.emit_dust(player.global_position, 0.0, player)
		player.wall_jump_timer = 0.0
	
	if grounded != player.was_grounded:
		InputManager.set_grounded(grounded)
		player.was_grounded = grounded

func _update_wall_jump_timer(delta: float):
	if player.wall_jump_timer > 0:
		player.wall_jump_timer -= delta
