extends CanvasLayer  # Retour au CanvasLayer

# === REFS UI ===
@onready var fps_label: Label = $Panel/VBoxContainer/FpsLabel
@onready var state_label: Label = $Panel/VBoxContainer/StateLabel
@onready var pos_label: Label = $Panel/VBoxContainer/PosLabel
@onready var vel_label: Label = $Panel/VBoxContainer/VelLabel
@onready var ground_label: Label = $Panel/VBoxContainer/GroundLabel

# === DATA ===
var frame_times: Array[float] = []
var max_frame_samples: int = 60

func _ready():
	# Visible par défaut
	visible = true

func _process(delta):
	if visible:
		_update_performance(delta)
		_update_player_info()

func _update_performance(delta):
	# Calcul FPS moyenné
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
	
	# État actuel
	var current_state = player.state_machine.current_state
	var state_name = current_state.get_script().get_global_name() if current_state else "None"
	state_label.text = "State: " + state_name.replace("State", "")
	
	# Position (arrondies)
	pos_label.text = "Pos: %.0f,%.0f" % [player.global_position.x, player.global_position.y]
	
	# Vélocité (arrondies)
	vel_label.text = "Vel: %.0f,%.0f" % [player.velocity.x, player.velocity.y]
	
	# Grounded
	ground_label.text = "Ground: " + ("Y" if player.is_on_floor() else "N")

# === API PUBLIQUE ===
func toggle_visibility():
	visible = !visible

func show_panel():
	visible = true

func hide_panel():
	visible = false

# Ajouter des infos custom si besoin
func add_custom_info(text: String):
	# Vous pouvez étendre ça pour ajouter des labels dynamiques
	pass
