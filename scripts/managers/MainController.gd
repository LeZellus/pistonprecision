extends Node

# === SCENES REFERENCES ===
const MAIN_MENU_SCENE = "res://scenes/ui/MainMenu.tscn"
const GAME_LEVEL_SCENE = "res://scenes/worlds/MainScene.tscn"  # Votre scène existante

# === CURRENT STATE ===
var current_scene: Node = null

func _ready():
	name = "MainController"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Démarrer par le menu principal
	call_deferred("goto_main_menu")

func goto_main_menu():
	print("MainController: Chargement du menu principal...")
	_change_scene(MAIN_MENU_SCENE)

func goto_game():
	print("MainController: Lancement du jeu...")
	_change_scene(GAME_LEVEL_SCENE)

func _change_scene(scene_path: String):
	# Supprimer l'ancienne scène
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited
	
	# Charger la nouvelle scène
	var new_scene_resource = load(scene_path)
	if not new_scene_resource:
		push_error("MainController: Impossible de charger " + scene_path)
		return
	
	current_scene = new_scene_resource.instantiate()
	get_tree().current_scene.add_child(current_scene)
	
	print("MainController: Scène changée vers ", scene_path)

# === API PUBLIQUE ===
func get_current_scene() -> Node:
	return current_scene
