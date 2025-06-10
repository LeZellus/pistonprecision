class_name PushDetector
extends CollisionDetector  # ← Hérite maintenant

const RAY_LENGTH = 10.0

func detect_pushable_object(direction: Vector2) -> PushableObject:
	var result = cast_ray(direction * RAY_LENGTH, 0b00000100)  # ← Factorisé
	
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
	var result = cast_ray(direction * RAY_LENGTH, 0b00000100)  # ← Factorisé
	
	if result:
		var distance = player.global_position.distance_to(result.position)
		print("Distance de push: ", distance)
		return distance
	
	return RAY_LENGTH
