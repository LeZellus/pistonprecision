class_name CollisionDetector
extends Node2D

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D):
	player = player_ref

# === MÉTHODE PRINCIPALE OPTIMISÉE ===
func raycast(offset: Vector2, mask: int) -> Dictionary:
	"""Méthode principale de raycast optimisée"""
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + offset,
		mask
	)
	query.exclude = [player]
	return space_state.intersect_ray(query)

# === MÉTHODES UTILITAIRES ===
func check_multiple_rays(offsets: Array[Vector2], mask: int) -> Dictionary:
	"""Teste plusieurs rayons et retourne le premier hit"""
	for offset in offsets:
		var result = raycast(offset, mask)
		if result.has("collider"):
			return result
	return {}

func has_collision_in_direction(offsets: Array[Vector2], mask: int) -> bool:
	"""Simple check booléen pour plusieurs rayons"""
	for offset in offsets:
		if raycast(offset, mask).has("collider"):
			return true
	return false
