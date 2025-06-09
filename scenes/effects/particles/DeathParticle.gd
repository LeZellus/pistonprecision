# scripts/player/particles/DeathParticle.gd
extends Node2D

signal finished

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var intensity: float = 1.0

func _ready():
	pass

func start_effect():
	# Créer un effet simple si pas d'AnimatedSprite2D
	if not animated_sprite:
		_create_simple_effect()
	else:
		# Si vous avez une vraie animation
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
			animated_sprite.speed_scale = intensity
			animated_sprite.play("death")
			animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
		else:
			_create_simple_effect()
	
	# Son d'explosion
	AudioManager.play_sfx("player/explosion", 0.8)

func _create_simple_effect():
	"""Crée un effet simple sans AnimatedSprite2D"""
	# Créer un sprite rouge temporaire
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)
	
	# Animation d'explosion avec Tween
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(3.0, 3.0), 0.5)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_on_animation_finished)

func set_intensity(intens: float):
	intensity = clamp(intens, 0.5, 2.0)

func _on_animation_finished():
	# Nettoyer les enfants créés (le sprite rouge)
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	
	finished.emit()

func is_finished() -> bool:
	if animated_sprite and animated_sprite.is_playing():
		return false
	return true

# Nouvelle méthode pour nettoyer la particule
func cleanup():
	"""Nettoie la particule avant retour au pool"""
	# Supprimer tous les sprites temporaires
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	
	# Reset des propriétés
	intensity = 1.0
	visible = false
