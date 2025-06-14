# scripts/objects/Door.gd - Version nettoyée
extends Area2D
class_name Door

# === CONFIGURATION ===
@export var target_room_id: String = ""
@export var target_spawn_id: String = "default"
@export var is_locked: bool = false

# === COMPONENTS ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# === DOOR STATES ===
var is_open: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Configuration des layers
	collision_layer = 0  # La porte ne collide avec rien
	collision_mask = 1   # Détecte seulement le joueur (layer 1)
	
	# État initial
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
	
	if is_locked:
		# TODO: Son de porte verrouillée
		return
	
	if target_room_id == "":
		return
	
	# Transition vers la salle cible
	_open_door()
	SceneManager.transition_to_room(target_room_id)

func _open_door():
	if is_open:
		return
	
	is_open = true
	
	# Animation simple
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.5, 0.2)
	
	# Son d'ouverture
	AudioManager.play_sfx("doors/open", 0.3)

# === API PUBLIQUE ===
func unlock():
	is_locked = false
	_update_door_visual()

func lock():
	is_locked = true
	_update_door_visual()
