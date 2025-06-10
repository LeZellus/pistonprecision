# scripts/GameLevel.gd
extends Node2D

@export var starting_world: WorldData
@export var starting_room: String = ""

# === MENU REFERENCES ===
@onready var menu_layer: CanvasLayer = $MenuLayer
@onready var main_menu: Control = $MenuLayer/MainMenu
@onready var settings_menu: Control = $MenuLayer/SettingsMenu
@onready var pause_menu: Control = $MenuLayer/PauseMenu

var game_started: bool = false

func _ready():
	# Connecter les signaux des menus
	if main_menu:
		main_menu.play_requested.connect(_start_game)
		main_menu.settings_requested.connect(_show_settings)
	
	if settings_menu:
		settings_menu.back_requested.connect(_show_main_menu)
	
	if pause_menu:
		pause_menu.resume_requested.connect(_resume_game)
		pause_menu.settings_requested.connect(_show_settings_from_pause)
		pause_menu.menu_requested.connect(_return_to_main_menu)
	
	# Commencer par afficher le menu principal
	_show_main_menu()

func _input(event):
	# Échap pendant le jeu = pause
	if event.is_action_pressed("ui_cancel") and game_started and menu_layer and not menu_layer.visible:
		_pause_game()

func _show_main_menu():
	"""Affiche le menu principal et cache les autres"""
	if menu_layer:
		menu_layer.visible = true
	if main_menu:
		main_menu.visible = true
	if settings_menu:
		settings_menu.visible = false

func _show_settings():
	"""Affiche le menu paramètres et cache le menu principal"""
	if main_menu:
		main_menu.visible = false
	if settings_menu:
		settings_menu.visible = true

func _start_game():
	"""Lance le jeu et cache tous les menus"""
	print("Démarrage du jeu...")
	game_started = true
	
	# Cacher les menus AVANT d'initialiser le jeu
	if menu_layer:
		menu_layer.visible = false
	
	# S'assurer que le GameManager est en mode PLAYING (avec vérification de sécurité)
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		# Vérifier que l'enum GameState existe
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.PLAYING)
		else:
			print("GameManager trouvé mais sans enum GameState")
	else:
		print("GameManager non trouvé ou méthode change_state manquante")
	
	# MAINTENANT initialiser le jeu
	if not starting_world:
		push_error("Aucun monde de départ défini!")
		return
	
	var player_scene = preload("res://scenes/player/Player.tscn")
	
	SceneManager.initialize_with_player(player_scene)
	await SceneManager.load_world(starting_world, starting_room)
	
	print("=== Initialisation terminée ===")

# === GESTION DE LA PAUSE ===
func _pause_game():
	"""Met le jeu en pause"""
	if pause_menu:
		pause_menu.show_pause()

func _resume_game():
	"""Reprend le jeu"""
	if pause_menu:
		pause_menu.hide_pause()

func _show_settings_from_pause():
	"""Affiche les paramètres depuis la pause"""
	if pause_menu:
		pause_menu.visible = false
	if settings_menu:
		settings_menu.visible = true

func _return_to_main_menu():
	"""Retourne au menu principal depuis la pause"""
	if pause_menu:
		pause_menu.hide_pause()
	return_to_menu()

# === API POUR RETOURNER AU MENU DEPUIS LE JEU ===
func return_to_menu():
	"""Retourne au menu principal depuis le jeu"""
	print("Retour au menu...")
	game_started = false
	
	# Nettoyer proprement le SceneManager
	SceneManager.cleanup_world()
	
	# Remettre le GameManager en état MENU (avec vérification de sécurité)
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.MENU)
	
	_show_main_menu()
