@tool  # Pour que ça marche dans l'éditeur
extends Area2D
class_name Door

# === CONFIGURATION ===
@export var target_room_id: String = "" : set = _set_target_room_id
@export var target_spawn_id: String = "default"
@export var is_locked: bool = false

# === COMPONENTS ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# === DOOR STATES ===
var is_open: bool = false

func _ready():
	# Connexions
	body_entered.connect(_on_body_entered)
	
	# Configuration des layers
	collision_layer = 0  # La porte ne collide avec rien
	collision_mask = 1   # Détecte seulement le joueur (layer 1)
	
	# État initial
	_update_door_visual()

func _set_target_room_id(value: String):
	target_room_id = value
	if is_inside_tree():
		_update_door_visual()

func _update_door_visual():
	"""Met à jour l'apparence de la porte selon son état"""
	if not sprite:
		return
	
	if is_locked:
		sprite.modulate = Color.RED  # Porte fermée/verrouillée
	elif target_room_id == "":
		sprite.modulate = Color.GRAY  # Porte non configurée
	else:
		sprite.modulate = Color.WHITE  # Porte normale

func _on_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	
	if is_locked:
		print("Porte verrouillée!")
		# TODO: Son de porte verrouillée
		return
	
	if target_room_id == "":
		print("Porte non configurée!")
		return
	
	# Transition vers la salle cible
	print("Transition vers: ", target_room_id, " (spawn: ", target_spawn_id, ")")
	_open_door()
	SceneManager.transition_to_room(target_room_id, target_spawn_id)

func _open_door():
	"""Animation d'ouverture de porte"""
	if is_open:
		return
	
	is_open = true
	
	# Animation simple (tu peux l'améliorer plus tard)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.5, 0.2)
	
	# Son d'ouverture
	AudioManager.play_sfx("doors/open", 0.3)

# === API PUBLIQUE ===
func unlock():
	"""Déverrouille la porte"""
	is_locked = false
	_update_door_visual()

func lock():
	"""Verrouille la porte"""
	is_locked = true
	_update_door_visual()
