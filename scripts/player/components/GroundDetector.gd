class_name GroundDetector
extends Node2D

# === RAYCAST REFS ===
var ground_rays: Array[RayCast2D] = []
var player: CharacterBody2D

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _ready():
	_setup_rays()

func _setup_rays():
	ground_rays = [
		player.get_node("GroundLeft"),
		player.get_node("GroundCenter"), 
		player.get_node("GroundRight")
	]

func is_grounded() -> bool:
	return player.is_on_floor()

func _any_ray_colliding() -> bool:
	return ground_rays.any(func(ray): return ray and ray.is_colliding())

func get_ground_normal() -> Vector2:
	for ray in ground_rays:
		if ray.is_colliding():
			return ray.get_collision_normal()
	return Vector2.UP

func get_collision_point() -> Vector2:
	for ray in ground_rays:
		if ray.is_colliding():
			return ray.get_collision_point()
	return Vector2.ZERO
