class_name PushDetector
extends CollisionDetector

const RAY_LENGTH = 10.0

func detect_pushable_object(direction: Vector2) -> PushableObject:
	var result = raycast(direction * RAY_LENGTH, 0b00000100)
	
	if result.has("collider"):
		var collider = result.collider
		if collider.is_in_group("pushable"):
			return collider as PushableObject
	
	return null

func get_push_distance(direction: Vector2) -> float:
	var result = raycast(direction * RAY_LENGTH, 0b00000100)
	return result.get("position", player.global_position + direction * RAY_LENGTH).distance_to(player.global_position)
