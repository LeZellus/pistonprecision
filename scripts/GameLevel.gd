# GameLevel.gd
extends Node2D

@export var starting_world: WorldData
@export var starting_room: String = ""
@export var player_spawn_position: Vector2 = Vector2(150, 220)

func _ready():
	if not starting_world:
		push_error("Aucun monde de départ défini!")
		return
	
	var player_scene = preload("res://scenes/player/Player.tscn")
	
	SceneManager.initialize_with_player(player_scene)
	await SceneManager.load_world(starting_world, starting_room)
	
	# Position initiale du joueur
	if SceneManager.player:
		SceneManager.player.global_position = player_spawn_position
		SceneManager.player.velocity = Vector2.ZERO
