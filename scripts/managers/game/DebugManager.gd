extends Node

# === DEBUG PANEL ===
var debug_panel_scene = preload("res://scenes/ui/DebugPanel.tscn")
var debug_panel: CanvasLayer  # Retour au bon type

# === CUSTOM DATA ===
var custom_info: Dictionary = {}

func _ready():
	name = "DebugManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("DebugManager: Initialisation...")
	_create_debug_panel()
	print("DebugManager: Panel créé, F3 pour toggle")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle_debug_panel()
		print("F3 détecté - Toggle debug panel")

func _create_debug_panel():
	# Instancier votre scène custom
	debug_panel = debug_panel_scene.instantiate()
	add_child(debug_panel)

# === PANEL CONTROL ===
func toggle_debug_panel():
	if debug_panel:
		debug_panel.toggle_visibility()

func show_debug_panel():
	if debug_panel:
		debug_panel.show_panel()

func hide_debug_panel():
	if debug_panel:
		debug_panel.hide_panel()

# === API CUSTOM (Pour compatibilité avec votre GameManager) ===
func add_custom_info(category: String, key: String, value):
	if not custom_info.has(category):
		custom_info[category] = {}
	custom_info[category][key] = value
	
	# TODO: Mettre à jour la UI si vous voulez afficher les custom infos

func log_performance(block_name: String, start_time_ms: int):
	var current_time = Time.get_time_dict_from_system()
	var current_ms = current_time.hour * 3600000 + current_time.minute * 60000 + current_time.second * 1000 + current_time.msec
	var duration = current_ms - start_time_ms
	
	print("PERF [%s]: %dms" % [block_name, duration])

# === GETTERS ===
func is_visible() -> bool:
	return debug_panel.visible if debug_panel else false
