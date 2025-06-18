# scripts/core/game/GameLevel.gd - ORDRE CRITIQUE CORRIGÉ
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connecter les signaux des menus
	if main_menu:
		main_menu.play_requested.connect(_start_game)
		main_menu.settings_requested.connect(_show_settings_from_main)
	
	if settings_menu:
		settings_menu.back_requested.connect(_on_settings_back)
	
	if pause_menu:
		pause_menu.resume_requested.connect(_on_pause_resume_requested)
		pause_menu.settings_requested.connect(_show_settings_from_pause)
		pause_menu.menu_requested.connect(_quit_to_main_menu)
	
	_show_main_menu()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and game_started:
		if get_tree().paused:
			if pause_menu:
				pause_menu.hide_pause()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game():
	if not game_started:
		return
		
	print("🔄 GameLevel: Mise en pause du jeu")
	
	if menu_layer:
		menu_layer.visible = true
		
	if pause_menu:
		pause_menu.show_pause()

func _on_pause_resume_requested():
	print("🔄 GameLevel: Resume demandé par PauseMenu")
	if menu_layer:
		menu_layer.visible = false

# ===== CORRECTION PRINCIPALE =====
func _quit_to_main_menu():
	"""🔧 ORDRE CRITIQUE: Fermer pause menu AVANT tout le reste"""
	print("🏠 Retour au main menu - ordre critique...")
	
	# 🔧 ÉTAPE 1: Fermer IMMÉDIATEMENT le pause menu
	if pause_menu:
		pause_menu.force_reset()  # ✅ Reset complet IMMÉDIAT
	
	# 🔧 ÉTAPE 2: Forcer l'arrêt de la pause
	get_tree().paused = false
	
	# 🔧 ÉTAPE 3: Attendre 1 frame pour la propagation
	await get_tree().process_frame
	
	# ÉTAPE 4: Nettoyer le monde de jeu
	SceneManager.cleanup_world()
	
	# ÉTAPE 5: Marquer le jeu comme arrêté
	game_started = false
	
	# ÉTAPE 6: Changer l'état du GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("change_state"):
		if "GameState" in game_manager:
			game_manager.change_state(game_manager.GameState.MENU)
	
	# ÉTAPE 7: Reset et affichage des menus
	_force_reset_all_menus()
	_show_main_menu()
	
	print("✅ Retour au main menu terminé - PauseMenu complètement fermé")

func _force_reset_all_menus():
	"""Reset forcé de l'état de tous les menus"""
	# 🔧 Le pause menu est DÉJÀ reseté par force_reset() plus haut
	
	if settings_menu:
		settings_menu.visible = false
		settings_menu.remove_meta("came_from_pause")
	
	if main_menu:
		main_menu.visible = false  # On va le réactiver après

# ===== GESTION SETTINGS =====
func _show_settings_from_main():
	"""Paramètres depuis le main menu"""
	if main_menu:
		main_menu.visible = false
	if settings_menu:
		settings_menu.visible = true
		settings_menu.set_meta("came_from_pause", false)

func _show_settings_from_pause():
	"""Paramètres depuis le pause menu"""
	if pause_menu:
		pause_menu.visible = false
	if settings_menu:
		settings_menu.visible = true
		settings_menu.set_meta("came_from_pause", true)

func _on_settings_back():
	"""Gestion centralisée du retour settings"""
	var came_from_pause = settings_menu.get_meta("came_from_pause", false)
	
	settings_menu.visible = false
	settings_menu.remove_meta("came_from_pause")
	
	if came_from_pause and game_started:
		# Retour au pause menu (seulement si le jeu est encore actif)
		if pause_menu:
			pause_menu.visible = true
	else:
		# Retour au main menu
		if main_menu:
			main_menu.visible = true

# === MÉTHODES EXISTANTES ===
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
	"""Affichage propre du main menu uniquement"""
	game_started = false
	get_tree().paused = false
	
	if menu_layer:
		menu_layer.visible = true
	
	# S'assurer qu'SEUL le main menu est visible
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

func _hide_all_menus():
	if menu_layer:
		menu_layer.visible = false
	if main_menu:
		main_menu.visible = false
	if settings_menu:
		settings_menu.visible = false
	if pause_menu:
		pause_menu.visible = false
