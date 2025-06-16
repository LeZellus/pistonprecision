# scripts/world/SpawnPoint.gd
extends Marker2D
class_name SpawnPoint

@export var spawn_id: String = "default"
@export var is_default_spawn: bool = false

func _ready():
	# Ajouter au groupe pour recherche facile
	add_to_group("spawn_points")
	
	# S'enregistrer auprès du SpawnManager
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		spawn_manager.register_spawn_point(spawn_id, global_position, is_default_spawn)
	
	# Debug visuel en mode éditeur
	if Engine.is_editor_hint():
		_setup_editor_visual()

func _setup_editor_visual():
	"""Affichage visuel dans l'éditeur"""
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	if is_default_spawn:
		image.fill(Color.GREEN)  # Vert pour spawn par défaut
	else:
		image.fill(Color.BLUE)   # Bleu pour spawns normaux
	
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate.a = 0.7
	add_child(sprite)

func get_spawn_position() -> Vector2:
	"""Retourne la position de spawn"""
	return global_position
