class_name PushableObject
extends CharacterBody2D

# === PUSH SETTINGS ===
@export var push_force: float = 2000.0  # ÉNORME FORCE pour 15-20 cubes de distance
@export var friction: float = 800.0     # Friction plus forte pour arrêt naturel
@export var can_be_pushed: bool = true

# === PHYSICS ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var push_velocity: Vector2 = Vector2.ZERO

# === WALL COLLISION DETECTION ===
var previous_position: Vector2
var wall_impact_threshold: float = 50.0  # Vitesse minimum pour déclencher le shake

func _ready():
	add_to_group("pushable")
	
	# Configuration des layers - IMPORTANT pour éviter que le joueur pousse en bougeant
	collision_layer = 0b00000100  # Layer 3 seulement (séparé du joueur)
	collision_mask = 0b00000110   # Layers 2 et 3 (ground et walls)
	
	# Forcer la mise à jour
	set_collision_layer_value(1, false)  # Désactiver layer 1 (joueur)
	set_collision_layer_value(2, false)  # Désactiver layer 2 (ground)
	set_collision_layer_value(3, true)   # Activer layer 3 seulement
	set_collision_mask_value(2, true)    # Sol (layer 2)
	set_collision_mask_value(3, true)    # Murs (layer 3)
	
	previous_position = global_position

func _physics_process(delta):
	# Sauvegarder la position et vélocité avant le mouvement
	var old_velocity = push_velocity.x
	previous_position = global_position
	
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Appliquer la vélocité de push
	velocity.x = push_velocity.x
	
	# Mouvement
	move_and_slide()
	
	# Détecter l'impact avec un mur
	_check_wall_impact(old_velocity)
	
	# Appliquer la friction
	push_velocity.x = move_toward(push_velocity.x, 0, friction * delta)

func _check_wall_impact(old_velocity: float):
	# Vérifier si on avait une vitesse élevée mais qu'on s'est arrêté brutalement
	var movement_delta = global_position.distance_to(previous_position)
	
	# Si on avait une vitesse élevée mais très peu de mouvement = collision
	if abs(old_velocity) > wall_impact_threshold and movement_delta < 1.0:
		_trigger_wall_impact_shake(abs(old_velocity))
		push_velocity.x = 0  # Arrêter immédiatement le push
		print("IMPACT MUR détecté! Vitesse:", abs(old_velocity))

func _trigger_wall_impact_shake(impact_velocity: float):
	# Calculer l'intensité du shake basée sur la vitesse d'impact
	var shake_intensity = clamp(impact_velocity * 0.01, 2.0, 15.0)  # Entre 2 et 15 pixels
	var shake_duration = clamp(impact_velocity * 0.0001, 0.1, 0.3)  # Entre 0.1 et 0.3 secondes
	
	# Chercher la caméra dans la scène
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("Aucune caméra trouvée pour le shake d'impact")
		return
	
	# Chercher le composant CameraShake ou le créer
	var shake_component = camera.get_node_or_null("Camera2D")
	if not shake_component:
		# Créer le composant dynamiquement si pas trouvé
		var shake_script = load("res://scripts/utilities/Camera.gd")
		if shake_script:
			shake_component = shake_script.new()
			shake_component.name = "CameraShake"
			shake_component.camera = camera
			camera.add_child(shake_component)
			print("CameraShake créé pour impact mur")
		else:
			print("ERREUR: Script CameraShake introuvable pour impact")
			return
	
	# Déclencher le shake d'impact
	if shake_component and shake_component.has_method("shake"):
		shake_component.shake(shake_intensity, shake_duration)
		print("Shake d'impact déclenché! Intensité:", shake_intensity, "Durée:", shake_duration)
	else:
		print("ERREUR: Méthode shake() introuvable pour impact")

func push(direction: Vector2, force: float) -> bool:
	if not can_be_pushed:
		return false
	
	# Vérifier s'il y a déjà une vitesse élevée (objet déjà en mouvement contre un mur)
	if abs(push_velocity.x) > wall_impact_threshold * 0.1:  # 10% du seuil
		print("Objet déjà bloqué contre un mur")
		return false
	
	# Appliquer la force directement (pas additionner)
	push_velocity = direction * force
	
	return true

func is_pushable() -> bool:
	return can_be_pushed
