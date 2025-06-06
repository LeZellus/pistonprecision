extends Area2D
class_name RoomTrigger

@export var direction: String = "right"  # "left", "right", "up", "down"

func _ready():
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1  # Layer du joueur

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		SceneManager.transition_to_room(direction)
