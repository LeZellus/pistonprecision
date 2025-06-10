class_name WallDetector
extends CollisionDetector  # ← Hérite maintenant

var is_active: bool = true

func set_active(active: bool):
	is_active = active

func is_touching_wall() -> bool:
	if not is_active:
		return false
	
	var wall_offsets = [
		Vector2(-9, -7), Vector2(-9, 0), Vector2(-9, 7),  # Gauche
		Vector2(9, -7), Vector2(9, 0), Vector2(9, 7)     # Droite
	]
	
	for offset in wall_offsets:
		if cast_ray(offset, 4):  # ← Utilise la méthode factorisée
			return true
	
	return false

func get_wall_side() -> int:
	if not is_active:
		return 0
	
	# Test gauche
	var left_offsets = [Vector2(-9, -7), Vector2(-9, 0), Vector2(-9, 7)]
	for offset in left_offsets:
		if cast_ray(offset, 4):
			return -1
	
	# Test droite  
	var right_offsets = [Vector2(9, -7), Vector2(9, 0), Vector2(9, 7)]
	for offset in right_offsets:
		if cast_ray(offset, 4):
			return 1
	
	return 0
