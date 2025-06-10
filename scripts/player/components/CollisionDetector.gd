class_name CollisionDetector
extends Node2D

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D):
	player = player_ref

func create_ray_query(start_pos: Vector2, end_pos: Vector2, mask: int) -> PhysicsRayQueryParameters2D:
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = mask
	query.exclude = [player]
	return query

func cast_ray(offset: Vector2, mask: int) -> Dictionary:
	var space_state = player.world_space_state
	var query = create_ray_query(
		player.global_position,
		player.global_position + offset,
		mask
	)
	return space_state.intersect_ray(query)
