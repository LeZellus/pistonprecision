class_name PushableObject
extends CharacterBody2D

# === PUSH SETTINGS ===
@export var push_force: float = 2000.0
@export var friction: float = 800.0
@export var can_be_pushed: bool = true

# === PHYSICS ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var push_velocity: Vector2 = Vector2.ZERO

# === WALL COLLISION DETECTION ===
var previous_position: Vector2
var wall_impact_threshold: float = 50.0
var has_impacted: bool = false  # FIX: Flag pour éviter les impacts multiples

func _ready():
	add_to_group("pushable")
	
	# Configuration des layers
	collision_layer = 0b00000100
	collision_mask = 0b00000110
	
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
	
	previous_position = global_position

func _physics_process(delta):
	var old_velocity = push_velocity.x
	previous_position = global_position
	
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Appliquer la vélocité de push
	velocity.x = push_velocity.x
	
	# Mouvement
	move_and_slide()
	
	# FIX: Détecter l'impact seulement si pas encore impacté
	if not has_impacted:
		_check_wall_impact(old_velocity)
	
	# Appliquer la friction
	push_velocity.x = move_toward(push_velocity.x, 0, friction * delta)
	
	# FIX: Reset du flag quand l'objet s'arrête complètement
	if abs(push_velocity.x) < 10.0:  # Vitesse très faible
		has_impacted = false

func _check_wall_impact(old_velocity: float):
	var movement_delta = global_position.distance_to(previous_position)
	
	if abs(old_velocity) > wall_impact_threshold and movement_delta < 1.0:
		_trigger_wall_impact_shake(abs(old_velocity))
		push_velocity.x = 0
		has_impacted = true  # FIX: Marquer comme impacté
		print("IMPACT MUR détecté! Vitesse:", abs(old_velocity))

func _trigger_wall_impact_shake(impact_velocity: float):
	var shake_intensity = clamp(impact_velocity * 0.01, 2.0, 15.0)
	# var shake_duration = clamp(impact_velocity * 0.0001, 0.1, 0.4)
	var shake_duration = 1.5
	
	# NOUVEAU : Son d'impact basé sur la vélocité
	var impact_volume = clamp(impact_velocity * 0.002, 0.1, 0.3)
	AudioManager.play_sfx("objects/wall_impact", impact_volume)
	
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("Aucune caméra trouvée pour le shake d'impact")
		return
	
	# Appeler directement shake() sur la caméra
	if camera.has_method("shake"):
		camera.shake(shake_intensity, shake_duration)
		print("Shake d'impact déclenché! Intensité:", shake_intensity, "Durée:", shake_duration)
	else:
		print("ERREUR: Méthode shake() introuvable sur la caméra")

func push(direction: Vector2, force: float) -> bool:
	if not can_be_pushed:
		return false
	
	# FIX: Améliorer la détection de collision pour éviter les faux positifs
	var space_state = get_world_2d().direct_space_state
	var test_distance = 12.0  # Distance plus longue pour un test plus fiable
	
	# Commencer le test depuis le bord de l'objet (pas le centre)
	var collision_shape = $CollisionShape2D.shape as RectangleShape2D
	var object_size = collision_shape.size if collision_shape else Vector2(8, 8)
	var start_offset = (object_size * 0.5 + Vector2(2, 2)) * direction
	var start_pos = global_position + start_offset
	var end_pos = start_pos + direction * test_distance
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 0b00000010  # SEULEMENT les murs (layer 2), pas les objets pushables
	query.exclude = [self]  # Exclure l'objet lui-même
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Mur réel détecté derrière l'objet - Push impossible")
		return false
	
	# FIX: Reset du flag à chaque nouveau push
	has_impacted = false
	
	if abs(push_velocity.x) > wall_impact_threshold * 0.1:
		print("Objet déjà bloqué contre un mur")
		return false
	
	push_velocity = direction * force
	print("Push réussi! Vitesse appliquée: ", push_velocity)
	return true

func is_pushable() -> bool:
	return can_be_pushed
