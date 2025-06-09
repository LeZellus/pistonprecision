extends Node2D

signal finished

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func start_effect():
	
	# Lance l'animation
	animated_sprite.play("dust_effect")

func _on_animation_finished():
	finished.emit()

func is_finished() -> bool:
	return not animated_sprite.is_playing()
