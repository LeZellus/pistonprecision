extends Marker2D
class_name SpawnPoint

@export var spawn_id: String = "default"
@export var is_default_spawn: bool = false

func _ready():
	add_to_group("spawn_points")
	
	# Visuel en mode debug
	if Engine.is_editor_hint():
		return
	
	# Optionnel : ajouter un petit sprite pour voir le spawn en jeu
	if is_default_spawn:
		modulate = Color.GREEN
	else:
		modulate = Color.BLUE
