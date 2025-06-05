extends Node2D

signal finished

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var follow_target: Node2D = null
var offset: Vector2 = Vector2.ZERO

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(_delta):
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position + offset

func start_effect():
	animated_sprite.play("dust_effect")

func set_follow_target(target: Node2D, target_offset: Vector2 = Vector2.ZERO):
	follow_target = target
	offset = target_offset

func _on_animation_finished():
	follow_target = null
	finished.emit()

func is_finished() -> bool:
	return not animated_sprite.is_playing()
