# scripts/objects/Collectible.gd
extends Area2D
class_name Collectible

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# === ÉTAT ===
var is_collected: bool = false
var target_player: Player = null

# === SUIVI ===
var current_offset: Vector2
var preferred_side: int = -1  # -1 = gauche, 1 = droite
var dead_zone_radius: float = 30.0
var follow_speed: float = 12.0
var smooth_factor: float = 8.0

# === EFFETS ===
var float_time: float = 0.0
var float_amplitude: float = 3.0
var float_speed: float = 2.0
var lag_distance: float = 15.0

func _ready():
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	if is_collected and _is_player_valid():
		_update_floating(delta)
		_update_side_preference()
		_follow_player(delta)

# === COLLECTION ===
func _on_body_entered(body: Node2D):
	if not body.is_in_group("player") or is_collected:
		return
	
	_collect(body as Player)

func _collect(player: Player):
	"""Active le suivi du joueur"""
	is_collected = true
	target_player = player
	current_offset = global_position - player.global_position
	
	# Désactiver collision et effets
	collision.set_deferred("disabled", true)
	AudioManager.play_sfx("objects/collectibles/pickup", 0.8)
	_play_collection_animation()
	
	# Notifier le joueur
	if player.has_method("add_collectible"):
		player.add_collectible()

func _play_collection_animation():
	"""Animation rapide de collection"""
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(0.8, 0.8), 0.1)

# === FLOTTEMENT ===
func _update_floating(delta: float):
	"""Effet de flottement vertical"""
	float_time += delta * float_speed
	sprite.position.y = sin(float_time) * float_amplitude

# === LOGIQUE DE CÔTÉ ===
func _update_side_preference():
	"""Change de côté quand le joueur traverse la ligne centrale"""
	if _is_in_dead_zone():
		return
		
	var object_relative_x = (global_position - target_player.global_position).x
	
	# Basculement selon la position relative
	if preferred_side == -1 and object_relative_x < 0:
		preferred_side = 1
	elif preferred_side == 1 and object_relative_x > 0:
		preferred_side = -1

# === SUIVI INTELLIGENT ===
func _follow_player(delta: float):
	"""Suivi avec zone morte et retard"""
	var ideal_offset = _calculate_ideal_offset()
	current_offset = global_position - target_player.global_position
	
	# Zone morte : pas de mouvement si trop proche du joueur
	if _is_in_dead_zone():
		return
	
	# Mouvement fluide vers la position idéale
	var new_offset = current_offset.lerp(ideal_offset, smooth_factor * delta)
	var target_pos = target_player.global_position + new_offset
	
	global_position = global_position.lerp(target_pos, follow_speed * delta)

func _calculate_ideal_offset() -> Vector2:
	"""Calcule la position idéale avec retard"""
	var base_offset = Vector2(preferred_side * 25.0, -15.0)
	
	# Ajouter le retard selon le mouvement du joueur
	if target_player.velocity.length() > 10.0:
		var lag_offset = -target_player.velocity.normalized() * lag_distance
		base_offset += lag_offset
	
	return base_offset

# === UTILITAIRES ===
func _is_player_valid() -> bool:
	"""Vérifie si le joueur cible est valide"""
	return target_player and is_instance_valid(target_player)

func _is_in_dead_zone() -> bool:
	"""Vérifie si l'objet est dans la zone morte (proche du joueur)"""
	if not _is_player_valid():
		return false
		
	var distance_to_player = current_offset.length()
	return distance_to_player <= dead_zone_radius
