class_name PushableObject
extends CharacterBody2D

# === PUSH SETTINGS ===
@export var push_force: float = 2000.0  # ÉNORME FORCE pour 15-20 cubes de distance
@export var friction: float = 800.0     # Friction plus forte pour arrêt naturel
@export var can_be_pushed: bool = true

# === PHYSICS ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var push_velocity: Vector2 = Vector2.ZERO

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

func _physics_process(delta):
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Appliquer la vélocité de push
	velocity.x = push_velocity.x
	
	# Mouvement
	var old_pos = global_position.x
	move_and_slide()
	var new_pos = global_position.x
	
	# Détection de collision : si push_velocity élevée mais aucun mouvement
	if abs(push_velocity.x) > 10.0 and abs(new_pos - old_pos) < 0.1:
		push_velocity.x = 0  # Arrêter immédiatement le push
	else:
		# Appliquer la friction seulement si pas de collision
		push_velocity.x = move_toward(push_velocity.x, 0, friction * delta)

func push(direction: Vector2, force: float) -> bool:
	if not can_be_pushed:
		return false
	
	# Appliquer la force directement (pas additionner)
	push_velocity = direction * force
	
	return true

func is_pushable() -> bool:
	return can_be_pushed
