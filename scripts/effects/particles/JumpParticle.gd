extends Node2D

signal particle_finished

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var follow_target: Node2D = null
var target_offset: Vector2 = Vector2.ZERO
var direction: float = 0.0
var intensity: float = 1.0

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(_delta):
	# Jump particle reste à sa position initiale
	pass

func start_effect():
	# Applique la direction (flip si nécessaire)
	if direction < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	# Applique l'intensité (vitesse d'animation)
	animated_sprite.speed_scale = intensity
	
	# Lance l'animation
	animated_sprite.play("jump_effect")

func set_direction(dir: float):
	direction = dir

func set_intensity(intens: float):
	intensity = clamp(intens, 0.5, 2.0)

func set_follow_target(target: Node2D):
	follow_target = target

func set_target_offset(offset: Vector2):
	target_offset = offset

func _on_animation_finished():
	animated_sprite.visible = false
	particle_finished.emit()

func is_finished() -> bool:
	return not animated_sprite.is_playing()
