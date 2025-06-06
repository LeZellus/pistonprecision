extends Control

signal play_requested
signal settings_requested

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	# Connecter les boutons
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	print("Bouton Jouer pressé")
	play_requested.emit()

func _on_settings_pressed():
	print("Bouton Paramètres pressé")
	settings_requested.emit()

func _on_quit_pressed():
	print("Bouton Quitter pressé")
	get_tree().quit()
