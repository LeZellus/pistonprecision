class_name Camera
extends Node

@export var camera: Camera2D
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_position: Vector2

func _ready():
	if not camera:
		camera = get_parent() as Camera2D
	
	if camera:
		original_position = camera.position
	else:
		print("ERREUR: Aucune caméra trouvée pour CameraShake")

func _process(delta):
	if not camera:
		return
		
	if shake_timer > 0:
		shake_timer -= delta
		
		# Calculer l'intensité actuelle (diminue avec le temps)
		var current_intensity = shake_intensity * (shake_timer / shake_duration)
		
		# Appliquer le shake
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		
		camera.position = original_position + shake_offset
		
		# Fin du shake
		if shake_timer <= 0:
			camera.position = original_position
			shake_intensity = 0.0

func shake(intensity: float, duration: float):
	if not camera:
		print("ERREUR: Impossible de faire le shake, caméra manquante")
		return
		
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	
	# Mettre à jour la position originale au cas où la caméra aurait bougé
	if shake_timer <= 0:
		original_position = camera.position

func stop_shake():
	shake_timer = 0.0
	shake_intensity = 0.0
	if camera:
		camera.position = original_position
