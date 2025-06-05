class_name PushDetector
extends Node2D

# === RAYCAST REFS ===
var push_rays: Dictionary = {}
var player: CharacterBody2D

const RAY_LENGTH = 20.0  # Augmenté pour debug

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _ready():
	_setup_rays()

func _setup_rays():
	# Créer les raycast pour chaque direction
	var directions = {
		"up": Vector2.UP,
		"down": Vector2.DOWN,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT
	}
	
	for dir_name in directions.keys():
		var ray = RayCast2D.new()
		ray.name = "PushRay" + dir_name.capitalize()
		ray.target_position = directions[dir_name] * RAY_LENGTH
		ray.collision_mask = 0b00000100  # Layer 3 seulement (où sont maintenant les objets pushables)
		ray.enabled = true
		ray.modulate = Color.CYAN  # Visible pour debug
		player.add_child(ray)
		push_rays[dir_name] = ray
		
		print("Raycast créé: ", ray.name, " - Position: ", ray.target_position)

func detect_pushable_object(direction: Vector2) -> PushableObject:
	var dir_name = _vector_to_direction_name(direction)
	print("Détection direction: ", dir_name, " (", direction, ")")
	
	if not push_rays.has(dir_name):
		print("Aucun raycast pour direction: ", dir_name)
		return null
	
	var ray = push_rays[dir_name]
	print("Raycast ", ray.name, " - Collision: ", ray.is_colliding())
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		print("Objet détecté: ", collider.name if collider else "null")
		print("Type: ", collider.get_class() if collider else "null")
		print("Groupes: ", collider.get_groups() if collider else "null")
		
		if collider and collider.is_in_group("pushable"):
			print("✓ Objet pushable trouvé!")
			return collider as PushableObject
		else:
			print("✗ Objet pas pushable")
	else:
		print("Aucune collision détectée")
	
	return null

func _vector_to_direction_name(direction: Vector2) -> String:
	if direction.y < -0.5:
		return "up"
	elif direction.y > 0.5:
		return "down"
	elif direction.x < -0.5:
		return "left"
	elif direction.x > 0.5:
		return "right"
	return ""

func get_push_distance(direction: Vector2) -> float:
	var dir_name = _vector_to_direction_name(direction)
	if not push_rays.has(dir_name):
		return 0.0
	
	var ray = push_rays[dir_name]
	if ray.is_colliding():
		var distance = ray.global_position.distance_to(ray.get_collision_point())
		print("Distance de push: ", distance)
		return distance
	
	return RAY_LENGTH
