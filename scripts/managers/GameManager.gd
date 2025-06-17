# scripts/managers/GameManager.gd - DEBUG SAUVEGARDE
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

# === DOOR CHECKPOINT SYSTEM ===
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
	
	# DEBUG: Vérifier les permissions d'écriture
	print("=== GAMEMANAGER DEBUG SAUVEGARDE ===")
	print("Chemin de sauvegarde: ", SAVE_FILE_PATH)
	print("Répertoire user:// = ", OS.get_user_data_dir())
	
	load_game_data()
	print("GameManager: Chargé avec %d morts totales" % death_count)
	_debug_current_checkpoint()
	
	# TEST: Sauvegarder immédiatement pour vérifier
	_test_save_system()
	
func _input(event):
	# Debug: F12 pour simuler morts, F11 pour clear checkpoint, F10 pour test save
	if Input.is_key_pressed(KEY_F12):
		reset_death_count()
		death_count = 6000
		print("Debug: Death count mis à 6000")
	elif Input.is_key_pressed(KEY_F11):
		clear_checkpoint()
		print("Debug: Checkpoint effacé")
	elif Input.is_key_pressed(KEY_F10):
		_test_save_system()

func _test_save_system():
	"""TEST: Vérifier que la sauvegarde fonctionne"""
	print("\n=== TEST SYSTÈME DE SAUVEGARDE ===")
	
	# Test écriture
	var test_data = {"test": "valeur_test", "timestamp": Time.get_unix_time_from_system()}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	
	if not file:
		print("ERREUR: Impossible d'ouvrir le fichier en écriture!")
		print("Code d'erreur: ", FileAccess.get_open_error())
		return
	
	file.store_string(JSON.stringify(test_data))
	file.close()
	print("✅ Test écriture: OK")
	
	# Test lecture
	file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("ERREUR: Impossible de lire le fichier!")
		return
	
	var content = file.get_as_text()
	file.close()
	print("✅ Test lecture: OK")
	print("Contenu lu: ", content)
	
	# Restaurer vraies données
	save_game_data()
	print("✅ Données restaurées")

func _process(delta):
	if current_state == GameState.PLAYING:
		level_time += delta
		total_time += delta

# === DOOR CHECKPOINT SYSTEM ===
func set_last_door(door_id: String, room_id: String):
	"""CORRECTION: Remplace toujours l'ancien checkpoint"""
	print("\n=== SET_LAST_DOOR APPELÉ ===")
	print("Anciens: door='%s', room='%s'" % [last_door_id, last_room_id])
	print("Nouveaux: door='%s', room='%s'" % [door_id, room_id])
	
	# DEBUG: Vérifier que les paramètres ne sont pas vides
	if door_id.is_empty():
		print("ERREUR: door_id est vide!")
		return
	if room_id.is_empty():
		print("ERREUR: room_id est vide!")
		return
	
	# Remplacer l'ancien checkpoint
	last_door_id = door_id
	last_room_id = room_id
	
	print("✅ Checkpoint mis à jour en mémoire")
	
	# Sauvegarde automatique AVEC DEBUG
	var success = save_checkpoint_data()
	if success:
		print("✅ Sauvegarde sur disque réussie")
	else:
		print("❌ ÉCHEC sauvegarde sur disque")
	
	_debug_current_checkpoint()

func get_last_door_id() -> String:
	return last_door_id

func get_last_room_id() -> String:
	return last_room_id

func has_checkpoint() -> bool:
	return not last_door_id.is_empty() and not last_room_id.is_empty()

func clear_checkpoint():
	"""Efface le checkpoint"""
	print("GameManager: Effacement checkpoint '%s' (room '%s')" % [last_door_id, last_room_id])
	last_door_id = ""
	last_room_id = ""
	save_checkpoint_data()

func _debug_current_checkpoint():
	"""Affiche le checkpoint actuel"""
	print("--- CHECKPOINT ACTUEL ---")
	if has_checkpoint():
		print("Door: '%s'" % last_door_id)
		print("Room: '%s'" % last_room_id)
	else:
		print("Aucun checkpoint door")
	print("------------------------")

func save_checkpoint_data() -> bool:
	"""Sauvegarde rapide du checkpoint uniquement - AVEC DEBUG"""
	print("save_checkpoint_data() appelé...")
	
	var save_data = _create_save_data()
	print("Données à sauvegarder: ", save_data)
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		print("ERREUR: Impossible d'ouvrir fichier pour sauvegarde!")
		print("Code d'erreur: ", FileAccess.get_open_error())
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("✅ Fichier sauvegardé: %d caractères" % json_string.length())
	return true

# === DEATH SYSTEM ===
func register_player_death():
	"""Appelé quand le joueur meurt"""
	death_count += 1
	session_deaths += 1
	
	print("GameManager: Mort #%d (session: %d)" % [death_count, session_deaths])
	_debug_current_checkpoint()
	
	# Émettre le signal
	player_died.emit(death_count)
	
	# Sauvegarde automatique du compteur de morts
	save_death_data()

func save_death_data() -> bool:
	"""Sauvegarde rapide uniquement des données de mort"""
	return save_checkpoint_data()  # Même fonction maintenant

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

# === SAVE/LOAD ===
func _create_save_data() -> Dictionary:
	return {
		"death_count": death_count,
		"last_door_id": last_door_id,        
		"last_room_id": last_room_id,        
		"completed_levels": completed_levels,
		"collectibles_found": collectibles_found,
		"best_times": best_times,
		"total_time": total_time,
		"version": "1.0"
	}

func save_game_data() -> bool:
	print("save_game_data() appelé...")
	return save_checkpoint_data()

func load_game_data():
	print("=== CHARGEMENT SAUVEGARDE ===")
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("❌ Aucune sauvegarde trouvée à: ", SAVE_FILE_PATH)
		print("Utilisation des valeurs par défaut")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	print("✅ Fichier lu: %d caractères" % json_string.length())
	print("Contenu brut: ", json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ Sauvegarde corrompue!")
		print("Erreur: ", json.get_error_message())
		return
	
	var save_data = json.data
	print("✅ JSON parsé: ", save_data)
	
	death_count = save_data.get("death_count", 0)
	last_door_id = save_data.get("last_door_id", "")        
	last_room_id = save_data.get("last_room_id", "")        
	
	var loaded_levels = save_data.get("completed_levels", [])
	completed_levels.clear()
	for level in loaded_levels:
		if level is String:
			completed_levels.append(level)
	
	collectibles_found = save_data.get("collectibles_found", {})
	best_times = save_data.get("best_times", {})
	total_time = save_data.get("total_time", 0.0)
	
	print("✅ Données chargées:")
	print("  - Deaths: %d" % death_count)
	print("  - Last door: '%s'" % last_door_id)
	print("  - Last room: '%s'" % last_room_id)

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
