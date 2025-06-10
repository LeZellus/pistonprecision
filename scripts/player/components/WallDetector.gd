class_name WallDetector
extends CollisionDetector

var is_active: bool = true

# Constantes pour éviter la re-création d'arrays
const LEFT_OFFSETS: Array[Vector2] = [Vector2(-9, -7), Vector2(-9, 0), Vector2(-9, 7)]
const RIGHT_OFFSETS: Array[Vector2] = [Vector2(9, -7), Vector2(9, 0), Vector2(9, 7)]
const ALL_WALL_OFFSETS: Array[Vector2] = LEFT_OFFSETS + RIGHT_OFFSETS

func set_active(active: bool):
	is_active = active

func is_touching_wall() -> bool:
	return is_active and has_collision_in_direction(ALL_WALL_OFFSETS, 4)

func get_wall_side() -> int:
	if not is_active:
		return 0
	
	if has_collision_in_direction(LEFT_OFFSETS, 4):
		return -1
	elif has_collision_in_direction(RIGHT_OFFSETS, 4):
		return 1
	
	return 0
