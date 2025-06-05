extends Node2D

signal finished

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var direction: float = 0.0
var intensity: float = 1.0

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func start_effect():
	# Applique la direction (flip si nécessaire)
	if direction < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	# Applique l'intensité (vitesse d'animation)
	animated_sprite.speed_scale = intensity
	
	# Lance l'animation
	animated_sprite.play("dust_effect")

func set_direction(dir: float):
	direction = dir

func set_intensity(intens: float):
	intensity = clamp(intens, 0.5, 2.0)

func _on_animation_finished():
	finished.emit()

func is_finished() -> bool:
	return not animated_sprite.is_playing()
