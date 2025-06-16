# scripts/objects/Door.gd - Système simple avec ID
extends Area2D
class_name Door

# === CONFIGURATION ===
@export var door_id: String = ""  # ID de cette porte (ex: "room_01_left")
@export var target_room_id: String = ""  # Salle cible (ex: "room_02")
@export var target_spawn_id: String = ""  # ID de la porte cible (ex: "room_02_right")
@export_enum("left", "right") var spawn_side: String = "left"  # Côté où spawner
@export var is_locked: bool = false

# === COMPONENTS ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_open: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1
	_update_door_visual()

func _update_door_visual():
	if not sprite:
		return
	
	if is_locked:
		sprite.modulate = Color.RED
	elif target_room_id == "":
		sprite.modulate = Color.GRAY
	else:
		sprite.modulate = Color.WHITE

func _on_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	
	if is_locked or target_room_id == "" or target_spawn_id == "":
		return
	
	_open_door()
	SceneManager.transition_to_room_with_spawn(target_room_id, target_spawn_id)

func get_spawn_position() -> Vector2:
	"""Retourne la position de spawn selon le côté"""
	var door_pos = global_position
	
	if spawn_side == "left":
		return Vector2(door_pos.x - 24, door_pos.y)
	else:  # right
		return Vector2(door_pos.x + 24, door_pos.y)

func _open_door():
	if is_open:
		return
	
	is_open = true
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.5, 0.2)
	
	AudioManager.play_sfx("doors/open", 0.3)

# === API PUBLIQUE ===
func unlock():
	is_locked = false
	_update_door_visual()

func lock():
	is_locked = true
	_update_door_visual()
