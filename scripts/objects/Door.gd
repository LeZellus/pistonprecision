# scripts/objects/Door.gd - Version avec SpawnPoint manuel
extends Area2D
class_name Door

# === CONFIGURATION EXISTANTE ===
@export var target_room_id: String = ""
@export var is_locked: bool = false

# === SYSTÈME CHECKPOINT ===
@export var door_id: String = ""
@export var target_door_id: String = ""
@export var is_default_spawn: bool = false

# === COMPONENTS ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var spawn_point: Marker2D = $SpawnPoint  # Point de spawn

# === DOOR STATES ===
var is_open: bool = false

func _ready():
	add_to_group("doors")
	body_entered.connect(_on_body_entered)
	
	# Configuration des layers
	collision_layer = 0
	collision_mask = 1
	
	# Auto-générer door_id si vide
	if door_id.is_empty():
		door_id = name.to_lower()
		print("Door: Auto-generated door_id = %s" % door_id)
	
	# Vérifier que le SpawnPoint existe
	if not spawn_point:
		print("ATTENTION: Door '%s' n'a pas de SpawnPoint enfant!" % door_id)
	
	# État initial
	_update_door_visual()
	
	print("Door '%s' initialisée - target_room: %s, target_door: %s, default: %s" % [door_id, target_room_id, target_door_id, is_default_spawn])

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
		print("Door '%s' verrouillée" % door_id)
		return
	
	if target_room_id == "":
		print("Door '%s' sans destination" % door_id)
		return
	
	print("Door '%s' utilisée par le joueur" % door_id)
	_open_door()

func _open_door():
	if is_open:
		return
	
	is_open = true
	
	# Animation simple
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.5, 0.2)
	
	# Son d'ouverture
	AudioManager.play_sfx("doors/open", 0.3)
	
	# Sauvegarder cette door comme checkpoint
	print("Door: Sauvegarde checkpoint - door_id: %s" % door_id)
	_save_as_checkpoint()
	
	# NOUVEAU : Dire au SceneManager de téléporter à la door cible
	print("Door: Transition vers room '%s', door '%s'" % [target_room_id, target_door_id])
	SceneManager.transition_to_room_with_target_door(target_room_id, target_door_id)

func _save_as_checkpoint():
	"""Sauvegarde la door de DESTINATION comme checkpoint (pas cette door)"""
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.has_method("set_last_door"):
		print("ERREUR: GameManager introuvable ou méthode set_last_door manquante")
		return
	
	# Sauvegarder la door de DESTINATION, pas cette door
	if target_door_id.is_empty():
		print("ATTENTION: Door '%s' n'a pas de target_door_id défini!" % door_id)
		return
	
	game_manager.set_last_door(target_door_id, target_room_id)
	print("Checkpoint sauvegardé: door de DESTINATION '%s' dans room '%s'" % [target_door_id, target_room_id])

# === SPAWN POSITION ===
func get_spawn_position() -> Vector2:
	"""Retourne la position du SpawnPoint"""
	if spawn_point:
		var pos = spawn_point.global_position
		print("Door '%s': spawn à la position du SpawnPoint %v" % [door_id, pos])
		return pos
	else:
		# Fallback si pas de SpawnPoint
		var fallback_pos = global_position
		print("Door '%s': ATTENTION - Pas de SpawnPoint, utilisation position door %v" % [door_id, fallback_pos])
		return fallback_pos

# === API PUBLIQUE ===
func unlock():
	is_locked = false
	_update_door_visual()

func lock():
	is_locked = true
	_update_door_visual()
