# scripts/ui/DebugPanel.gd - Version optimisée
extends CanvasLayer

# === REFS UI ===
@onready var fps_label: Label = $Panel/VBoxContainer/FpsLabel
@onready var state_label: Label = $Panel/VBoxContainer/StateLabel
@onready var pos_label: Label = $Panel/VBoxContainer/PosLabel
@onready var vel_label: Label = $Panel/VBoxContainer/VelLabel
@onready var ground_label: Label = $Panel/VBoxContainer/GroundLabel

# === OPTIMISATION ===
var frame_times: Array[float] = []
var max_frame_samples: int = 30  # Réduit de 60 à 30
var update_counter: int = 0
const UPDATE_FREQUENCY: int = 10  # Mise à jour tous les 10 frames

func _process(delta):
	if not visible:
		return
	
	update_counter += 1
	if update_counter >= UPDATE_FREQUENCY:
		update_counter = 0
		_update_performance(delta)
		_update_player_info()

func _update_performance(delta):
	frame_times.append(delta)
	if frame_times.size() > max_frame_samples:
		frame_times.pop_front()
	
	var avg_frame_time = frame_times.reduce(func(a, b): return a + b) / frame_times.size()
	var fps = 1.0 / avg_frame_time if avg_frame_time > 0 else 0
	fps_label.text = "FPS: %.0f" % fps

func _update_player_info():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		state_label.text = "State: No Player"
		pos_label.text = "Pos: N/A"
		vel_label.text = "Vel: N/A"
		ground_label.text = "Ground: N/A"
		return
	
	# État actuel (optimisé)
	var current_state = player.state_machine.current_state
	if current_state:
		var state_name = current_state.get_script().get_global_name().replace("State", "")
		state_label.text = "State: " + state_name
	else:
		state_label.text = "State: None"
	
	# Position et vélocité (arrondies)
	pos_label.text = "Pos: %.0f,%.0f" % [player.global_position.x, player.global_position.y]
	vel_label.text = "Vel: %.0f,%.0f" % [player.velocity.x, player.velocity.y]
	ground_label.text = "Ground: " + ("Y" if player.is_on_floor() else "N")

# === API PUBLIQUE ===
func toggle_visibility():
	visible = !visible

func show_panel():
	visible = true

func hide_panel():
	visible = false
