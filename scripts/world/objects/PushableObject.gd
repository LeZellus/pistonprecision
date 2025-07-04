# scripts/objects/PushableObject.gd - Version nettoyée
class_name PushableObject
extends CharacterBody2D

# === PUSH SETTINGS ===
@export var push_force: float = 4000.0
@export var friction: float = 800.0
@export var can_be_pushed: bool = true

# === PHYSICS ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var push_velocity: Vector2 = Vector2.ZERO

# === WALL COLLISION ===
var wall_impact_threshold: float = 50.0
var has_impacted: bool = false

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
	
func _physics_process(delta):
	var old_push_velocity = push_velocity.x
	
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Appliquer la vélocité de push
	velocity.x = push_velocity.x
	
	# Mouvement
	var was_moving = abs(velocity.x) > wall_impact_threshold
	move_and_slide()
	var stopped_by_collision = was_moving and abs(velocity.x) < 10.0 and is_on_wall()
	
	# Détecter l'impact
	if not has_impacted and stopped_by_collision:
		_trigger_wall_impact_shake(abs(old_push_velocity))
		push_velocity.x = 0
		has_impacted = true
	
	# Appliquer la friction si pas d'impact
	if not stopped_by_collision:
		push_velocity.x = move_toward(push_velocity.x, 0, friction * delta)
	
	# Reset du flag quand l'objet s'arrête
	if abs(push_velocity.x) < 10.0:
		has_impacted = false

func _trigger_wall_impact_shake(impact_velocity: float):
	var shake_intensity = clamp(impact_velocity * 0.01, 2.0, 5.0)
	var shake_duration = 0.5
	
	# Son d'impact
	var impact_volume = clamp(impact_velocity * 0.002, 0.1, 0.3)
	AudioManager.play_sfx("objects/wall_impact", impact_volume)
	
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(shake_intensity, shake_duration)

func push(direction: Vector2, force: float) -> bool:
	if not can_be_pushed:
		return false
	
	# Reset du flag à chaque nouveau push
	has_impacted = false
	
	# Vérifier si l'objet n'est pas déjà bloqué
	if abs(push_velocity.x) > wall_impact_threshold * 0.1:
		return false
	
	push_velocity = direction * force
	return true
