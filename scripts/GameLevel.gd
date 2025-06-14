# scripts/GameLevel.gd
extends Node2D

@export var starting_world: WorldData
@export var starting_room: String = "room_01"

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
	
	# Commencer par le menu principal
	_show_main_menu()

func _input(event):
	# Échap pendant le jeu = pause
	if event.is_action_pressed("ui_cancel") and game_started and not _any_menu_visible():
		_pause_game()

func _any_menu_visible() -> bool:
	return (main_menu and main_menu.visible) or \
		   (settings_menu and settings_menu.visible) or \
		   (pause_menu and pause_menu.visible)

func _show_main_menu():
	game_started = false
	if menu_layer:
		menu_layer.visible = true
	if main_menu:
		main_menu.visible = true
	if settings_menu:
		settings_menu.visible = false
	if pause_menu:
		pause_menu.visible = false
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.MENU)

func _show_settings():
	if main_menu:
		main_menu.visible = false
	if settings_menu:
		settings_menu.visible = true

func _start_game():
	"""Lance le jeu - le joueur sera créé par le SceneManager"""
	print("Démarrage du jeu...")
	game_started = true
	
	# Cache tous les menus
	_hide_all_menus()
	
	# Changer l'état du GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.PLAYING)
	
	# Vérifier les dépendances
	if not starting_world:
		push_error("Aucun monde de départ défini!")
		return
	
	# NOUVEAU: Charger le monde qui créera automatiquement le joueur
	await SceneManager.load_world_with_player(starting_world, starting_room)
	
	print("=== Jeu initialisé et prêt ===")

func _hide_all_menus():
	if menu_layer:
		menu_layer.visible = false
	if main_menu:
		main_menu.visible = false
	if settings_menu:
		settings_menu.visible = false
	if pause_menu:
		pause_menu.visible = false

# === GESTION DE LA PAUSE ===
func _pause_game():
	if not game_started:
		return
		
	if pause_menu:
		pause_menu.show_pause()
		if menu_layer:
			menu_layer.visible = true

func _resume_game():
	if pause_menu:
		pause_menu.hide_pause()
	if not _any_menu_visible():
		if menu_layer:
			menu_layer.visible = false

func _show_settings_from_pause():
	if pause_menu:
		pause_menu.visible = false
	if settings_menu:
		settings_menu.visible = true

func _return_to_main_menu():
	if pause_menu:
		pause_menu.hide_pause()
	return_to_menu()

func return_to_menu():
	print("Retour au menu...")
	game_started = false
	
	# Nettoyer le SceneManager (qui détruira aussi le joueur)
	SceneManager.cleanup_world()
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.MENU)
	
	_show_main_menu()
