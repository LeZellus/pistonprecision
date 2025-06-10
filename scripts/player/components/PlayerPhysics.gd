# scripts/player/components/PlayerPhysics.gd - Version optimisée
class_name PlayerPhysics
extends Node

var player: CharacterBody2D
var gravity: float

func _init(player_ref: CharacterBody2D):
	player = player_ref

func _ready():
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func apply_gravity(delta: float):
	if not player.is_on_floor():
		player.velocity.y += gravity * PlayerConstants.GRAVITY_MULTIPLIER * delta
		player.velocity.y = min(player.velocity.y, PlayerConstants.MAX_FALL_SPEED)

func apply_movement(delta: float, air_modifier: float = 1.0):
	"""Mouvement unifié pour sol et air"""
	var input_dir = InputManager.get_movement()
	
	if input_dir != 0:
		var target_speed = input_dir * PlayerConstants.SPEED * air_modifier
		var acceleration = PlayerConstants.ACCELERATION * delta
		
		player.velocity.x = move_toward(player.velocity.x, target_speed, acceleration)

func apply_friction(delta: float):
	var friction_value = PlayerConstants.FRICTION if player.is_on_floor() else PlayerConstants.AIR_RESISTANCE
	player.velocity.x = move_toward(player.velocity.x, 0, friction_value * delta)

func apply_wall_slide(_delta: float):
	if player.velocity.y > 0:
		player.velocity.y *= PlayerConstants.WALL_SLIDE_MULTIPLIER
		player.velocity.y = min(player.velocity.y, PlayerConstants.MAX_FALL_SPEED * PlayerConstants.WALL_SLIDE_MAX_SPEED_MULTIPLIER)
