extends Camera2D

# === SHAKE VARIABLES ===
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_position: Vector2

func _ready():
	original_position = position

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Calculer l'intensité actuelle (diminue avec le temps)
		var current_intensity = shake_intensity * (shake_timer / shake_duration)
		
		# Appliquer le shake
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		
		position = original_position + shake_offset
		
		# Fin du shake
		if shake_timer <= 0:
			position = original_position
			shake_intensity = 0.0

func shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	
	# Mettre à jour la position originale
	if shake_timer <= 0:
		original_position = position

func stop_shake():
	shake_timer = 0.0
	shake_intensity = 0.0
	position = original_position
