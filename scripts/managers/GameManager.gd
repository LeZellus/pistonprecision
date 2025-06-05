extends Node

# === GAME STATES ===
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	LEVEL_TRANSITION
}

# === SIGNALS ===
signal state_changed(new_state: GameState)
signal level_completed(level_name: String)
signal player_died
signal checkpoint_reached(checkpoint_id: String)

# === GAME DATA ===
var current_state: GameState = GameState.MENU
var current_level: String = ""
var current_checkpoint: String = ""
var player_lives: int = 3
var deaths_count: int = 0
var level_time: float = 0.0
var total_time: float = 0.0

# === LEVEL PROGRESSION ===
var completed_levels: Array[String] = []
var collectibles_found: Dictionary = {} # level_name -> count
var best_times: Dictionary = {} # level_name -> time

# === CONSTANTS ===
const SAVE_FILE_PATH = "user://save_game.dat"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_data()

func _process(delta):
	if current_state == GameState.PLAYING:
		level_time += delta
		total_time += delta
		
		# DEBUG: Envoyer des métriques au debug manager
		var debug_manager = get_node("/root/DebugManager") if has_node("/root/DebugManager") else null
		if debug_manager:
			debug_manager.add_custom_info("GAME", "Deaths", str(deaths_count))
			debug_manager.add_custom_info("GAME", "Current Level", current_level)

# === STATE MANAGEMENT ===
func change_state(new_state: GameState):
	if current_state == new_state:
		return
	
	# var old_state = current_state
	current_state = new_state
	state_changed.emit(new_state)
	
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false
		GameState.LEVEL_TRANSITION:
			get_tree().paused = true

# === LEVEL MANAGEMENT ===
func start_level(level_name: String):
	current_level = level_name
	current_checkpoint = ""
	level_time = 0.0
	change_state(GameState.PLAYING)

func complete_level():
	if current_level.is_empty():
		return
	
	# Update best time
	if not best_times.has(current_level) or level_time < best_times[current_level]:
		best_times[current_level] = level_time
	
	# Mark as completed
	if not current_level in completed_levels:
		completed_levels.append(current_level)
	
	level_completed.emit(current_level)
	save_game_data()

func set_checkpoint(checkpoint_id: String):
	current_checkpoint = checkpoint_id
	checkpoint_reached.emit(checkpoint_id)

# === PLAYER MANAGEMENT ===
func player_die():
	deaths_count += 1
	player_lives -= 1
	player_died.emit()
	
	if player_lives <= 0:
		change_state(GameState.GAME_OVER)

func reset_player_stats():
	player_lives = 3
	deaths_count = 0

# === SAVE/LOAD ===
func save_game_data():
	var save_data = {
		"completed_levels": completed_levels,
		"collectibles_found": collectibles_found,
		"best_times": best_times,
		"total_time": total_time
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_game_data():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var save_data = json.data
		completed_levels = save_data.get("completed_levels", [])
		collectibles_found = save_data.get("collectibles_found", {})
		best_times = save_data.get("best_times", {})
		total_time = save_data.get("total_time", 0.0)
		
func example_performance_measurement():
	var start_time = Time.get_time_dict_from_system()
	var start_ms = start_time.hour * 3600000 + start_time.minute * 60000 + start_time.second * 1000 + start_time.msec
	
	# ...  code à mesurer ...
	
	var debug_manager = get_node("/root/DebugManager")
	if debug_manager:
		debug_manager.log_performance("MonBloc", start_ms)
