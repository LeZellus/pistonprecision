# scripts/objects/Door.gd - CORRECTION SIMPLE: Une seule source de vérité
extends Area2D
class_name Door

# === CONFIGURATION ===
@export var door_id: String = ""  
@export var target_room_id: String = ""  
@export var target_spawn_id: String = ""  
@export_enum("left", "right") var spawn_side: String = "left"  
@export var is_locked: bool = false

# === COMPONENTS ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_open: bool = false

func _ready():
	add_to_group("doors")
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
	
	# Effectuer la transition
	SceneManager.transition_to_room_with_spawn(target_room_id, target_spawn_id)
	
	# CORRECTION: Sauvegarder IMMÉDIATEMENT la destination 
	# (pas besoin d'attendre que la door destination existe)
	_save_destination_as_checkpoint()

func _save_destination_as_checkpoint():
	"""SIMPLIFIÉ: Sauvegarde directement les infos de destination"""
	print("Door: Sauvegarde checkpoint - door '%s' dans room '%s'" % [target_spawn_id, target_room_id])
	
	# Une seule source de vérité : GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_last_door"):
		game_manager.set_last_door(target_spawn_id, target_room_id)

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
