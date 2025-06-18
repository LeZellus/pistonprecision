# scripts/player/components/MovementComponent.gd
class_name MovementComponent
extends Node

var player: Player
var is_enabled: bool = false

func _init(player_ref: Player):
	player = player_ref

func is_active() -> bool:
	return is_enabled

func update(delta: float):
	# À override dans les sous-classes
	pass

func enable():
	is_enabled = true

func disable():
	is_enabled = false
