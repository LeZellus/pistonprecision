# scripts/core/game/GameLevel.gd - VERSION COMPLÈTE SANS RÉCURSION
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
		# 🔧 CONNEXION UNIQUE - pas de récursion
		pause_menu.resume_requested.connect(_on_pause_resume_requested)
		pause_menu.settings_requested.connect(_show_settings_from_pause)
		pause_menu.menu_requested.connect(_return_to_main_menu)
	
	_show_main_menu()

func _input(event):
	# Échap pendant le jeu = pause
	if event.is_action_pressed("ui_cancel") and game_started and not _any_menu_visible():
		_pause_game()

func _any_menu_visible() -> bool:
	return (main_menu and main_menu.visible) or \
		   (settings_menu and settings_menu.visible) or \
		   (pause_menu and pause_menu.visible)

# === GESTION PAUSE SANS RÉCURSION ===
func _pause_game():
	if not game_started:
		return
		
	if pause_menu:
		pause_menu.show_pause()
		if menu_layer:
			menu_layer.visible = true

func _on_pause_resume_requested():
	"""Appelé UNE SEULE FOIS par le signal du PauseMenu"""
	print("🔄 GameLevel: Resume demandé par PauseMenu")
	
	# Cacher le menu layer si aucun autre menu visible
	if not _any_menu_visible():
		if menu_layer:
			menu_layer.visible = false
	
	# Le PauseMenu a déjà géré get_tree().paused = false

func _show_settings_from_pause():
	if pause_menu:
		pause_menu.visible = false
	if settings_menu:
		settings_menu.visible = true

func _return_to_main_menu():
	if pause_menu:
		pause_menu.hide_pause()  # Sans signal
	return_to_menu()

# === DÉMARRAGE DU JEU ===
func _start_game():
	"""Démarre le jeu avec gestion des checkpoints"""
	print("Démarrage du jeu...")
	game_started = true
	
	_hide_all_menus()
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.PLAYING)
	
	if not starting_world:
		push_error("Aucun monde de départ défini!")
		return
	
	# Vérifier s'il y a un checkpoint sauvegardé
	if game_manager and game_manager.has_checkpoint():
		var saved_room = game_manager.get_last_room_id()
		var saved_door = game_manager.get_last_door_id()
		
		print("GameLevel: Checkpoint trouvé! Spawn sur door '%s' dans room '%s'" % [saved_door, saved_room])
		await _start_at_checkpoint(saved_room, saved_door)
	else:
		print("GameLevel: Pas de checkpoint, spawn au starting_room '%s'" % starting_room)
		await _start_at_beginning()
	
	print("=== Jeu initialisé et prêt ===")

func _start_at_checkpoint(room_id: String, door_id: String):
	"""Démarre le jeu au checkpoint sauvegardé"""
	await SceneManager.load_world_with_player(starting_world, room_id)
	
	# Attendre que le joueur soit créé et la room chargée
	await get_tree().process_frame
	
	# Spawner sur la door spécifique
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		await scene_manager._spawn_at_door(door_id)

func _start_at_beginning():
	"""Démarre le jeu normalement (nouveau jeu)"""
	await SceneManager.load_world_with_player(starting_world, starting_room)

# === GESTION DES MENUS ===
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

func _hide_all_menus():
	if menu_layer:
		menu_layer.visible = false
	if main_menu:
		main_menu.visible = false
	if settings_menu:
		settings_menu.visible = false
	if pause_menu:
		pause_menu.visible = false

func return_to_menu():
	print("Retour au menu...")
	game_started = false
	
	SceneManager.cleanup_world()
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.MENU)
	
	_show_main_menu()
