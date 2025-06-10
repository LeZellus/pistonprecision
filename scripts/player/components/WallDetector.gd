class_name WallDetector
extends Node2D

var player: CharacterBody2D
var is_active: bool = true

func _init(player_ref: CharacterBody2D):
	player = player_ref

func set_active(active: bool):
	is_active = active

func is_touching_wall() -> bool:
	if not is_active:
		return false
	
	var space_state = player.world_space_state
	
	# 3 raycasts à gauche (comme avant)
	var left_queries = [
		Vector2(-9, -7),  # Top
		Vector2(-9, 0),   # Center  
		Vector2(-9, 7)    # Bottom
	]
	
	for offset in left_queries:
		var query = PhysicsRayQueryParameters2D.create(
			player.global_position,
			player.global_position + offset
		)
		query.collision_mask = 4
		if space_state.intersect_ray(query):
			return true
	
	# 3 raycasts à droite
	var right_queries = [
		Vector2(9, -7),   # Top
		Vector2(9, 0),    # Center
		Vector2(9, 7)     # Bottom
	]
	
	for offset in right_queries:
		var query = PhysicsRayQueryParameters2D.create(
			player.global_position,
			player.global_position + offset
		)
		query.collision_mask = 4
		if space_state.intersect_ray(query):
			return true
	
	return false

func get_wall_side() -> int:
	if not is_active:
		return 0
	
	var space_state = player.world_space_state
	
	# Test gauche avec 3 points
	var left_queries = [Vector2(-9, -7), Vector2(-9, 0), Vector2(-9, 7)]
	for offset in left_queries:
		var query = PhysicsRayQueryParameters2D.create(
			player.global_position,
			player.global_position + offset
		)
		query.collision_mask = 4
		if space_state.intersect_ray(query):
			return -1
	
	# Test droite avec 3 points
	var right_queries = [Vector2(9, -7), Vector2(9, 0), Vector2(9, 7)]
	for offset in right_queries:
		var query = PhysicsRayQueryParameters2D.create(
			player.global_position,
			player.global_position + offset
		)
		query.collision_mask = 4
		if space_state.intersect_ray(query):
			return 1
	
	return 0
