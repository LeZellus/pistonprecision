# scripts/core/game/GameLevel.gd - CORRECTION INPUT PAUSE
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
	# CRITIQUE: Process toujours pour gérer les inputs même en pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connecter les signaux des menus
	if main_menu:
		main_menu.play_requested.connect(_start_game)
		main_menu.settings_requested.connect(_show_settings)
	
	if settings_menu:
		settings_menu.back_requested.connect(_show_main_menu)
	
	if pause_menu:
		pause_menu.resume_requested.connect(_on_pause_resume_requested)
		pause_menu.settings_requested.connect(_show_settings_from_pause)
		pause_menu.menu_requested.connect(_return_to_main_menu)
	
	_show_main_menu()

func _unhandled_input(event):
	# GESTION PAUSE/UNPAUSE avec Escape
	if event.is_action_pressed("ui_cancel") and game_started:
		
		if get_tree().paused:
			# Déjà en pause -> unpause
			print("🔄 Unpause via Escape")
			if pause_menu:
				pause_menu.hide_pause()
		else:
			# Pas en pause -> pause
			print("🔄 Pause via Escape")
			_pause_game()
		
		# Marquer l'input comme traité
		get_viewport().set_input_as_handled()

func _pause_game():
	"""Met le jeu en pause et affiche le menu"""
	if not game_started:
		return
		
	print("🔄 GameLevel: Mise en pause du jeu")
	
	if menu_layer:
		menu_layer.visible = true
		
	if pause_menu:
		pause_menu.show_pause()

func _on_pause_resume_requested():
	"""Appelé quand le menu pause demande de reprendre"""
	print("🔄 GameLevel: Resume demandé par PauseMenu")
	
	# Cacher le menu layer
	if menu_layer:
		menu_layer.visible = false

# === RESTE DU CODE INCHANGÉ ===
func _show_settings_from_pause():
	if pause_menu:
		pause_menu.visible = false
	if settings_menu:
		settings_menu.visible = true

func _return_to_main_menu():
	if pause_menu:
		pause_menu.hide_pause()
	return_to_menu()

func _start_game():
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
	await SceneManager.load_world_with_player(starting_world, room_id)
	await get_tree().process_frame
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		await scene_manager._spawn_at_door(door_id)

func _start_at_beginning():
	await SceneManager.load_world_with_player(starting_world, starting_room)

func _show_main_menu():
	game_started = false
	get_tree().paused = false
	
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
	get_tree().paused = false
	
	SceneManager.cleanup_world()
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.MENU)
	
	_show_main_menu()
