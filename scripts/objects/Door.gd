# scripts/objects/Door.gd - Intégration complète avec CheckpointManager
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
	# Ajouter au groupe pour recherche facile
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
	
	# IMPORTANT: Sauvegarder le checkpoint AVANT la transition
	_save_checkpoint()
	
	_open_door()
	SceneManager.transition_to_room_with_spawn(target_room_id, target_spawn_id)

func _save_checkpoint():
	"""Sauvegarde cette door comme checkpoint dans TOUS les managers"""
	var current_room_id = get_current_room_id()
	var spawn_position = get_spawn_position()
	
	# 1. CheckpointManager (pour la logique de respawn)
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager:
		checkpoint_manager.set_door_checkpoint(door_id, current_room_id, spawn_position)
	
	# 2. GameManager (pour la sauvegarde persistante)
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_last_door"):
		game_manager.set_last_door(door_id, current_room_id)
	
	print("Door: Checkpoint complet sauvegardé - door '%s' room '%s' pos %v" % [door_id, current_room_id, spawn_position])

func get_current_room_id() -> String:
	"""Récupère l'ID de la room actuelle depuis SceneManager"""
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("get_current_room_id"):
		return scene_manager.get_current_room_id()
	return ""

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
