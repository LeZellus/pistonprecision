# scripts/player/components/DetectionSystem.gd - Version avec pool
class_name DetectionSystem
extends Node2D

var player: CharacterBody2D
var space_state: PhysicsDirectSpaceState2D

# === RAYCAST QUERY POOL (évite les allocations) ===
var _query_pool: Array[PhysicsRayQueryParameters2D] = []
var _pool_index: int = 0
const POOL_SIZE: int = 8

# === CONSTANTES ===
const WALL_LEFT_RAYS: Array[Vector2] = [Vector2(-9, -7), Vector2(-9, 0), Vector2(-9, 7)]
const WALL_RIGHT_RAYS: Array[Vector2] = [Vector2(9, -7), Vector2(9, 0), Vector2(9, 7)]
const GROUND_RAYS: Array[Vector2] = [Vector2(-7, 9), Vector2(0, 9), Vector2(7, 9)]

# Cache combiné
var _all_wall_rays: Array[Vector2] = []

# === MASKS ===
const WALL_MASK: int = 4
const GROUND_MASK: int = 2
const PUSHABLE_MASK: int = 4

var wall_detection_active: bool = true

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _ready():
	space_state = player.get_world_2d().direct_space_state
	_all_wall_rays = WALL_LEFT_RAYS + WALL_RIGHT_RAYS
	_create_query_pool()

func _create_query_pool():
	"""Crée un pool de queries pour éviter les allocations"""
	for i in POOL_SIZE:
		_query_pool.append(PhysicsRayQueryParameters2D.new())

func _get_pooled_query() -> PhysicsRayQueryParameters2D:
	"""Récupère une query du pool"""
	var query = _query_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	return query

func raycast(offset: Vector2, mask: int) -> Dictionary:
	"""Raycast optimisé avec pool"""
	var query = _get_pooled_query()
	query.from = player.global_position
	query.to = player.global_position + offset
	query.collision_mask = mask
	query.exclude = [player]
	return space_state.intersect_ray(query)

# === DÉTECTION OPTIMISÉE ===
func check_multiple_rays(rays: Array[Vector2], mask: int) -> bool:
	for ray in rays:
		if raycast(ray, mask).has("collider"):
			return true
	return false

func is_touching_wall() -> bool:
	return wall_detection_active and check_multiple_rays(_all_wall_rays, WALL_MASK)

func get_wall_side() -> int:
	if not wall_detection_active:
		return 0
	
	if check_multiple_rays(WALL_LEFT_RAYS, WALL_MASK):
		return -1
	elif check_multiple_rays(WALL_RIGHT_RAYS, WALL_MASK):
		return 1
	return 0

# === MÉTHODES DE COMPATIBILITÉ ===
func set_wall_detection_active(active: bool):
	wall_detection_active = active

func set_active(active: bool):
	set_wall_detection_active(active)

func is_grounded() -> bool:
	return player.is_on_floor()

func detect_pushable_object(direction: Vector2) -> PushableObject:
	var result = raycast(direction * 10.0, PUSHABLE_MASK)
	if result.has("collider") and result.collider.is_in_group("pushable"):
		return result.collider as PushableObject
	return null
