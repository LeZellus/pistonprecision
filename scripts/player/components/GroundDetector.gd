class_name GroundDetector
extends CollisionDetector

const GROUND_OFFSETS: Array[Vector2] = [Vector2(-7, 9), Vector2(0, 9), Vector2(7, 9)]

func is_grounded() -> bool:
	return player.is_on_floor()

func get_ground_normal() -> Vector2:
	var result = check_multiple_rays(GROUND_OFFSETS, 2)
	return result.get("normal", Vector2.UP)

func get_collision_point() -> Vector2:
	var result = check_multiple_rays(GROUND_OFFSETS, 2)
	return result.get("position", Vector2.ZERO)
