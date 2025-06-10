class_name GroundDetector
extends CollisionDetector  # ← Hérite maintenant

func is_grounded() -> bool:
	return player.is_on_floor()

func get_ground_normal() -> Vector2:
	var ground_offsets = [
		Vector2(-7, 9),   # Left
		Vector2(0, 9),    # Center
		Vector2(7, 9)     # Right
	]
	
	for offset in ground_offsets:
		var result = cast_ray(offset, 2)  # ← Utilise la méthode factorisée
		if result:
			return result.normal
	
	return Vector2.UP

func get_collision_point() -> Vector2:
	var ground_offsets = [Vector2(-7, 9), Vector2(0, 9), Vector2(7, 9)]
	
	for offset in ground_offsets:
		var result = cast_ray(offset, 2)  # ← Utilise la méthode factorisée
		if result:
			return result.position
	
	return Vector2.ZERO
