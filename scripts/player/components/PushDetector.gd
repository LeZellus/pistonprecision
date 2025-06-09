class_name PushDetector
extends Node2D

var player: CharacterBody2D
const RAY_LENGTH = 10.0

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _ready():
	# OPTIMISATION: Plus de création de raycasts permanents !
	# Les anciens raycasts seront remplacés par des queries à la demande
	pass

func detect_pushable_object(direction: Vector2) -> PushableObject:
	# OPTIMISATION: PhysicsRayQuery à la demande au lieu de raycasts permanents
	var space_state = player.world_space_state
	
	var start_pos = player.global_position
	var end_pos = start_pos + direction * RAY_LENGTH
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 0b00000100  # Layer 3 seulement (objets pushables)
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		var collider = result.collider
		print("Objet détecté: ", collider.name)
		print("Groupes: ", collider.get_groups())
		
		if collider.is_in_group("pushable"):
			print("✓ Objet pushable trouvé!")
			return collider as PushableObject
		else:
			print("✗ Objet pas pushable")
	else:
		print("Aucune collision détectée")
	
	return null

func get_push_distance(direction: Vector2) -> float:
	var space_state = player.world_space_state
	
	var start_pos = player.global_position
	var end_pos = start_pos + direction * RAY_LENGTH
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 0b00000100
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var distance = start_pos.distance_to(result.position)
		print("Distance de push: ", distance)
		return distance
	
	return RAY_LENGTH
