# WallDetector.gd optimisé
class_name WallDetector
extends Node2D

# === WALL DATA ===
class WallData:
	var touching: bool = false
	var side: int = 0  # -1 = left, 1 = right, 0 = none
	var normal: Vector2 = Vector2.ZERO

var wall_left_rays: Array[RayCast2D] = []
var wall_right_rays: Array[RayCast2D] = []
var player: CharacterBody2D
var is_active: bool = true

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _ready():
	_setup_rays()

func _setup_rays():
	wall_left_rays = [
		player.get_node("WallLeftTop"),
		player.get_node("WallLeftCenter"),
		player.get_node("WallLeftBottom")
	]
	
	wall_right_rays = [
		player.get_node("WallRightTop"),
		player.get_node("WallRightCenter"),
		player.get_node("WallRightBottom")
	]

# OPTIMISATION: Désactiver quand pas nécessaire
func set_active(active: bool):
	if is_active == active:
		return
	
	is_active = active
	for ray in wall_left_rays + wall_right_rays:
		ray.enabled = active

func get_wall_state() -> WallData:
	var data = WallData.new()
	
	# Pas de détection si au sol ET pas actif
	if player.is_on_floor() and not is_active:
		return data
	
	var left_wall = _any_ray_colliding(wall_left_rays)
	var right_wall = _any_ray_colliding(wall_right_rays)
	
	if left_wall:
		data.touching = true
		data.side = -1
		data.normal = _get_wall_normal(wall_left_rays)
	elif right_wall:
		data.touching = true
		data.side = 1
		data.normal = _get_wall_normal(wall_right_rays)
	
	return data

# === API PUBLIQUE (compatibilité avec votre code existant) ===
func is_touching_wall() -> bool:
	return get_wall_state().touching

func get_wall_side() -> int:
	return get_wall_state().side

# Reste identique...
func _any_ray_colliding(rays: Array[RayCast2D]) -> bool:
	return rays.any(func(ray): return ray and ray.is_colliding())

func _get_wall_normal(rays: Array[RayCast2D]) -> Vector2:
	for ray in rays:
		if ray.is_colliding():
			return ray.get_collision_normal()
	return Vector2.ZERO
