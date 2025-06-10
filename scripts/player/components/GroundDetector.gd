class_name GroundDetector
extends Node2D

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D):
	player = player_ref

func is_grounded() -> bool:
	return player.is_on_floor()

func get_ground_normal() -> Vector2:
	var space_state = player.world_space_state
	
	# 3 raycasts comme avant : gauche, centre, droite
	var ground_queries = [
		Vector2(-7, 9),   # Left
		Vector2(0, 9),    # Center
		Vector2(7, 9)     # Right
	]
	
	for offset in ground_queries:
		var query = PhysicsRayQueryParameters2D.create(
			player.global_position,
			player.global_position + offset
		)
		query.collision_mask = 2
		
		var result = space_state.intersect_ray(query)
		if result:
			return result.normal
	
	return Vector2.UP

func get_collision_point() -> Vector2:
	var space_state = player.world_space_state
	
	var ground_queries = [Vector2(-7, 9), Vector2(0, 9), Vector2(7, 9)]
	
	for offset in ground_queries:
		var query = PhysicsRayQueryParameters2D.create(
			player.global_position,
			player.global_position + offset
		)
		query.collision_mask = 2
		
		var result = space_state.intersect_ray(query)
		if result:
			return result.position
	
	return Vector2.ZERO
