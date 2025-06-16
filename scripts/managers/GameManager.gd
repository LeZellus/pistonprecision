# scripts/managers/GameManager.gd - Ajout système checkpoint doors
extends Node

# === GAME STATES ===
enum GameState { MENU, PLAYING, PAUSED, LEVEL_TRANSITION }

# === SIGNALS ===
signal state_changed(new_state: GameState)
signal level_completed(level_name: String)
signal checkpoint_reached(checkpoint_id: String)
signal player_died(death_count: int)

# === GAME DATA ===
var current_state: GameState = GameState.MENU
var current_level: String = ""
var current_checkpoint: String = ""
var level_time: float = 0.0
var total_time: float = 0.0

# === DEATH SYSTEM ===
var death_count: int = 0
var session_deaths: int = 0

# === NOUVEAU : DOOR CHECKPOINT SYSTEM ===
var last_door_id: String = ""
var last_room_id: String = ""

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
	print("GameManager: Chargé avec %d morts totales" % death_count)
	print("GameManager: Dernier checkpoint - door: '%s' dans room: '%s'" % [last_door_id, last_room_id])
	
func _input(event):
	# Appuyer sur F12 pour simuler 3000 morts
	if Input.is_key_pressed(KEY_F12):
		reset_death_count()
		death_count = 6000
		print("Debug: Death count mis à 3000")

func _process(delta):
	if current_state == GameState.PLAYING:
		level_time += delta
		total_time += delta

# === NOUVEAU : DOOR CHECKPOINT SYSTEM ===
func set_last_door(door_id: String, room_id: String):
	"""Sauvegarde la dernière door traversée comme checkpoint"""
	last_door_id = door_id
	last_room_id = room_id
	
	print("GameManager: Nouveau checkpoint - door '%s' dans room '%s'" % [door_id, room_id])
	
	# Sauvegarde automatique
	save_checkpoint_data()

func get_last_door_id() -> String:
	"""Retourne l'ID de la dernière door traversée"""
	return last_door_id

func get_last_room_id() -> String:
	"""Retourne l'ID de la dernière room"""
	return last_room_id

func has_checkpoint() -> bool:
	"""Vérifie s'il y a un checkpoint sauvegardé"""
	return not last_door_id.is_empty() and not last_room_id.is_empty()

func clear_checkpoint():
	"""Efface le checkpoint (pour nouveau jeu)"""
	last_door_id = ""
	last_room_id = ""
	print("GameManager: Checkpoint effacé")

func save_checkpoint_data():
	"""Sauvegarde rapide du checkpoint uniquement"""
	var save_data = _create_save_data()
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("GameManager: Checkpoint sauvegardé")
	else:
		push_error("Impossible de sauvegarder le checkpoint: " + SAVE_FILE_PATH)

# === DEATH SYSTEM ===
func register_player_death():
	"""Appelé quand le joueur meurt"""
	death_count += 1
	session_deaths += 1
	
	print("GameManager: Mort #%d (session: %d)" % [death_count, session_deaths])
	
	# Émettre le signal
	player_died.emit(death_count)
	
	# Sauvegarde automatique du compteur de morts
	save_death_data()

func save_death_data():
	"""Sauvegarde rapide uniquement des données de mort"""
	var save_data = _create_save_data()
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
	else:
		push_error("Impossible de sauvegarder les morts: " + SAVE_FILE_PATH)

# === STATE MANAGEMENT ===
func change_state(new_state: GameState):
	if current_state == new_state:
		return
	
	_exit_state(current_state)
	current_state = new_state
	state_changed.emit(new_state)
	_enter_state(new_state)

func _exit_state(state: GameState):
	match state:
		GameState.PAUSED:
			get_tree().paused = false

func _enter_state(state: GameState):
	match state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.LEVEL_TRANSITION:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false

# === LEVEL MANAGEMENT ===
func start_level(level_name: String):
	current_level = level_name
	current_checkpoint = ""
	level_time = 0.0
	session_deaths = 0
	change_state(GameState.PLAYING)

func complete_level():
	if current_level.is_empty():
		return
	
	if not current_level in best_times or level_time < best_times[current_level]:
		best_times[current_level] = level_time
	
	if not current_level in completed_levels:
		completed_levels.append(current_level)
	
	level_completed.emit(current_level)
	save_game_data()

func set_checkpoint(checkpoint_id: String):
	current_checkpoint = checkpoint_id
	checkpoint_reached.emit(checkpoint_id)

# === SAVE/LOAD ===
func _create_save_data() -> Dictionary:
	return {
		"death_count": death_count,
		"last_door_id": last_door_id,        # NOUVEAU
		"last_room_id": last_room_id,        # NOUVEAU
		"completed_levels": completed_levels,
		"collectibles_found": collectibles_found,
		"best_times": best_times,
		"total_time": total_time,
		"version": "1.0"
	}

func save_game_data():
	var save_data = _create_save_data()
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
	else:
		push_error("Impossible de sauvegarder: " + SAVE_FILE_PATH)

func load_game_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("GameManager: Aucune sauvegarde trouvée, utilisation des valeurs par défaut")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Sauvegarde corrompue")
		return
	
	var save_data = json.data
	death_count = save_data.get("death_count", 0)
	last_door_id = save_data.get("last_door_id", "")        # NOUVEAU
	last_room_id = save_data.get("last_room_id", "")        # NOUVEAU
	
	var loaded_levels = save_data.get("completed_levels", [])
	completed_levels.clear()
	for level in loaded_levels:
		if level is String:
			completed_levels.append(level)
	
	collectibles_found = save_data.get("collectibles_found", {})
	best_times = save_data.get("best_times", {})
	total_time = save_data.get("total_time", 0.0)
	
	print("GameManager: Sauvegarde chargée - %d morts totales" % death_count)

# === UTILITIES ===
func get_state_name() -> String:
	return GameState.keys()[current_state]

func is_level_completed(level_name: String) -> bool:
	return level_name in completed_levels

func get_best_time(level_name: String) -> float:
	return best_times.get(level_name, -1.0)

func get_total_deaths() -> int:
	return death_count

func get_session_deaths() -> int:
	return session_deaths

# === DEBUG ===
func reset_death_count():
	"""Pour les tests - remet le compteur à zéro"""
	death_count = 0
	session_deaths = 0
	save_death_data()
	print("GameManager: Compteur de morts remis à zéro")
