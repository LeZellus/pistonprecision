# scripts/managers/GameManager.gd - Version optimisée
extends Node

# === GAME STATES ===
enum GameState { MENU, PLAYING, PAUSED, LEVEL_TRANSITION }

# === SIGNALS ===
signal state_changed(new_state: GameState)
signal level_completed(level_name: String)
signal checkpoint_reached(checkpoint_id: String)

# === GAME DATA ===
var current_state: GameState = GameState.MENU
var current_level: String = ""
var current_checkpoint: String = ""
var level_time: float = 0.0
var total_time: float = 0.0

# === LEVEL PROGRESSION ===
var completed_levels: Array[String] = []
var collectibles_found: Dictionary = {}
var best_times: Dictionary = {}

# === CONSTANTS ===
const SAVE_FILE_PATH = "user://save_game.dat"

func _ready():
	name = "GameManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_data()
	print("GameManager initialisé - État: ", GameState.keys()[current_state])
	
	var transition_manager = preload("res://scenes/ui/DeathTransitionManager.tscn").instantiate()
	add_child(transition_manager)

func _process(delta):
	if current_state == GameState.PLAYING:
		level_time += delta
		total_time += delta
		
		# Debug info optimisé
		_update_debug_info()

func _update_debug_info():
	"""Mise à jour des infos debug de façon optimisée"""
	var debug_manager = get_node_or_null("/root/DebugManager")
	if debug_manager and debug_manager.has_method("add_custom_info"):
		debug_manager.add_custom_info("GAME", "Current Level", current_level)
		debug_manager.add_custom_info("GAME", "Level Time", "%.1fs" % level_time)

# === STATE MANAGEMENT OPTIMISÉ ===
func change_state(new_state: GameState):
	if current_state == new_state:
		return
	
	var old_state_name = GameState.keys()[current_state]
	var new_state_name = GameState.keys()[new_state]
	
	print("GameManager: %s → %s" % [old_state_name, new_state_name])
	
	# Actions de sortie
	_exit_state(current_state)
	
	# Changement d'état
	current_state = new_state
	state_changed.emit(new_state)
	
	# Actions d'entrée
	_enter_state(new_state)

func _exit_state(state: GameState):
	"""Actions lors de la sortie d'un état"""
	match state:
		GameState.PLAYING:
			pass  # Rien de spécial
		GameState.PAUSED:
			get_tree().paused = false

func _enter_state(state: GameState):
	"""Actions lors de l'entrée dans un état"""
	match state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.LEVEL_TRANSITION:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false

# === LEVEL MANAGEMENT OPTIMISÉ ===
func start_level(level_name: String):
	current_level = level_name
	current_checkpoint = ""
	level_time = 0.0
	change_state(GameState.PLAYING)

func complete_level():
	if current_level.is_empty():
		return
	
	# Mise à jour du meilleur temps
	if not current_level in best_times or level_time < best_times[current_level]:
		best_times[current_level] = level_time
		print("Nouveau record pour %s: %.2fs" % [current_level, level_time])
	
	# Marquer comme complété
	if not current_level in completed_levels:
		completed_levels.append(current_level)
	
	level_completed.emit(current_level)
	save_game_data()

func set_checkpoint(checkpoint_id: String):
	current_checkpoint = checkpoint_id
	checkpoint_reached.emit(checkpoint_id)
	print("Checkpoint atteint: ", checkpoint_id)

# === SAVE/LOAD OPTIMISÉ ===
func save_game_data():
	var save_data = {
		"completed_levels": completed_levels,
		"collectibles_found": collectibles_found,
		"best_times": best_times,
		"total_time": total_time,
		"version": "1.0"  # Pour la compatibilité future
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Données sauvegardées (%d niveaux complétés)" % completed_levels.size())
	else:
		push_error("Impossible de sauvegarder: " + SAVE_FILE_PATH)

func load_game_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("Nouvelle partie - aucune sauvegarde trouvée")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Sauvegarde corrompue - utilisation des valeurs par défaut")
		return
	
	var save_data = json.data
	completed_levels = save_data.get("completed_levels", [])
	collectibles_found = save_data.get("collectibles_found", {})
	best_times = save_data.get("best_times", {})
	total_time = save_data.get("total_time", 0.0)
	
	print("Données chargées: %d niveaux, %.1fs de jeu total" % [completed_levels.size(), total_time])

# === UTILITIES ===
func get_state_name() -> String:
	return GameState.keys()[current_state]

func is_level_completed(level_name: String) -> bool:
	return level_name in completed_levels

func get_best_time(level_name: String) -> float:
	return best_times.get(level_name, -1.0)
