# scripts/core/game/GameManager.gd - VERSION SIMPLIFIÉE
extends Node

# === GAME STATES ===
enum GameState { MENU, PLAYING, PAUSED }

# === SIGNALS ===
signal state_changed(new_state: GameState)
signal player_died(death_count: int)

# === GAME DATA ===
var current_state: GameState = GameState.MENU
var death_count: int = 0

# === CHECKPOINT SYSTEM ===
var last_door_id: String = ""
var last_room_id: String = ""

# === CONSTANTS ===
const SAVE_FILE_PATH = "user://save_game.dat"

func _ready():
	name = "GameManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_data()

func _process(delta):
	# Timer pour auto-save périodique (toutes les 30 secondes)
	if randf() < 0.001: # Environ toutes les 30s à 60fps
		save_game_data()

# === CHECKPOINT SYSTEM ===
func set_last_door(door_id: String, room_id: String):
	if door_id.is_empty() or room_id.is_empty():
		return
	
	last_door_id = door_id
	last_room_id = room_id
	save_game_data()

func get_last_door_id() -> String:
	return last_door_id

func get_last_room_id() -> String:
	return last_room_id

func has_checkpoint() -> bool:
	return not last_door_id.is_empty() and not last_room_id.is_empty()

func clear_checkpoint():
	last_door_id = ""
	last_room_id = ""
	save_game_data()

# === DEATH SYSTEM ===
func register_player_death():
	death_count += 1
	player_died.emit(death_count)
	save_game_data()

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
		GameState.PLAYING:
			get_tree().paused = false

# === SAVE/LOAD OPTIMISÉ ===
func save_game_data() -> bool:
	var save_data = {
		"death_count": death_count,
		"last_door_id": last_door_id,
		"last_room_id": last_room_id,
		"version": "1.0"
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		return false
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	return true

func load_game_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return
	
	var save_data = json.data
	death_count = save_data.get("death_count", 0)
	last_door_id = save_data.get("last_door_id", "")
	last_room_id = save_data.get("last_room_id", "")

# === GETTERS ===
func get_state_name() -> String:
	return GameState.keys()[current_state]

func get_total_deaths() -> int:
	return death_count
