# scripts/objects/SpawnPoint.gd - Version corrigée
extends Marker2D
class_name SpawnPoint

@export var spawn_id: String = "default"
@export var is_default_spawn: bool = true

func _ready():
	# IMPORTANT: Ajouter au groupe spawn_points
	add_to_group("spawn_points")
	
	# Debug
	print("SpawnPoint créé - ID: ", spawn_id, ", Position: ", global_position, ", Default: ", is_default_spawn)
	
	# Debug visuel (optionnel)
	if not Engine.is_editor_hint():
		_setup_debug_visual()

func _setup_debug_visual():
	"""Petit indicateur visuel pour voir les spawns en jeu"""
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	
	# Couleur selon le type
	var color = Color.GREEN if is_default_spawn else Color.BLUE
	image.fill(color)
	
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate.a = 0.7  # Semi-transparent
	add_child(sprite)
