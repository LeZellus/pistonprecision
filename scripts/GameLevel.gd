# GameLevel.gd
extends Node2D

@export var starting_world: WorldData
@export var starting_room: String = ""
@export var player_spawn_position: Vector2 = Vector2(150, 220)

# À ajouter dans votre GameLevel.gd après les @export
@onready var menu_layer: CanvasLayer = $MenuLayer
@onready var main_menu: Control = $MenuLayer/MainMenu

# Modifier votre fonction _ready() existante :
func _ready():
	# NOUVEAU : Connecter le signal du menu
	if main_menu:
		main_menu.play_requested.connect(_start_game)
	
	# Commencer par afficher le menu
	_show_menu()

# NOUVELLES fonctions à ajouter :
func _show_menu():
	if menu_layer:
		menu_layer.visible = true

func _start_game():
	print("Démarrage du jeu...")
	if menu_layer:
		menu_layer.visible = false
	
	# VOTRE CODE EXISTANT (déplacé ici depuis _ready)
	if not starting_world:
		push_error("Aucun monde de départ défini!")
		return
	
	var player_scene = preload("res://scenes/player/Player.tscn")
	
	SceneManager.initialize_with_player(player_scene)
	await SceneManager.load_world(starting_world, starting_room)
	
	if SceneManager.player:
		SceneManager.player.global_position = player_spawn_position
		SceneManager.player.velocity = Vector2.ZERO
