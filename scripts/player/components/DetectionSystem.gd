# scripts/player/components/DetectionSystem.gd - NOUVEAU FICHIER
class_name DetectionSystem
extends Node2D

var player: CharacterBody2D
var space_state: PhysicsDirectSpaceState2D

# === CONSTANTES DE DÉTECTION ===
const WALL_LEFT_RAYS: Array[Vector2] = [Vector2(-9, -7), Vector2(-9, 0), Vector2(-9, 7)]
const WALL_RIGHT_RAYS: Array[Vector2] = [Vector2(9, -7), Vector2(9, 0), Vector2(9, 7)]
const GROUND_RAYS: Array[Vector2] = [Vector2(-7, 9), Vector2(0, 9), Vector2(7, 9)]

# Cache pour éviter la concaténation répétée
var _all_wall_rays: Array[Vector2] = []

# === MASKS ===
const WALL_MASK = 4      # 0b00000100
const GROUND_MASK = 2    # 0b00000010  
const PUSHABLE_MASK = 4  # 0b00000100

var wall_detection_active: bool = true

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _ready():
	space_state = player.get_world_2d().direct_space_state
	# Préparer le cache des rayons combinés
	_all_wall_rays = WALL_LEFT_RAYS + WALL_RIGHT_RAYS

# === API PRINCIPALE ===
func raycast(offset: Vector2, mask: int) -> Dictionary:
	"""Raycast optimisé avec cache du space_state"""
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + offset,
		mask
	)
	query.exclude = [player]
	return space_state.intersect_ray(query)

func check_multiple_rays(rays: Array[Vector2], mask: int) -> bool:
	"""Vérifie si AU MOINS un rayon touche"""
	for ray in rays:
		if raycast(ray, mask).has("collider"):
			return true
	return false

func get_first_hit(rays: Array[Vector2], mask: int) -> Dictionary:
	"""Retourne le premier hit trouvé"""
	for ray in rays:
		var result = raycast(ray, mask)
		if result.has("collider"):
			return result
	return {}

# === WALL DETECTION ===
func is_touching_wall() -> bool:
	if not wall_detection_active:
		return false
	return check_multiple_rays(_all_wall_rays, WALL_MASK)

func get_wall_side() -> int:
	if not wall_detection_active:
		return 0
	
	if check_multiple_rays(WALL_LEFT_RAYS, WALL_MASK):
		return -1
	elif check_multiple_rays(WALL_RIGHT_RAYS, WALL_MASK):
		return 1
	return 0

func set_wall_detection_active(active: bool):
	wall_detection_active = active

# === COMPATIBILITY METHOD ===
func set_active(active: bool):
	"""Méthode de compatibilité pour WallDetector"""
	set_wall_detection_active(active)

# === GROUND DETECTION ===
func is_grounded() -> bool:
	return player.is_on_floor()

func get_ground_normal() -> Vector2:
	var result = get_first_hit(GROUND_RAYS, GROUND_MASK)
	return result.get("normal", Vector2.UP)

func get_ground_collision_point() -> Vector2:
	var result = get_first_hit(GROUND_RAYS, GROUND_MASK)
	return result.get("position", Vector2.ZERO)

# === PUSH DETECTION ===
func detect_pushable_object(direction: Vector2) -> PushableObject:
	var result = raycast(direction * 10.0, PUSHABLE_MASK)
	
	if result.has("collider"):
		var collider = result.collider
		if collider.is_in_group("pushable"):
			return collider as PushableObject
	
	return null

func get_push_distance(direction: Vector2) -> float:
	var result = raycast(direction * 10.0, PUSHABLE_MASK)
	return result.get("position", player.global_position + direction * 10.0).distance_to(player.global_position)
