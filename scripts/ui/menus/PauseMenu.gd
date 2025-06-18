extends Control

signal resume_requested
signal settings_requested
signal menu_requested

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

func _ready():
	# Connecter les boutons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _input(event):
	# Échap pour fermer la pause
	if event.is_action_pressed("ui_cancel") and visible:
		_on_resume_pressed()

func _on_resume_pressed():
	print("Reprendre le jeu")
	resume_requested.emit()

func _on_settings_pressed():
	print("Paramètres depuis la pause")
	settings_requested.emit()

func _on_menu_pressed():
	print("Retour au menu principal")
	menu_requested.emit()

func show_pause():
	visible = true
	get_tree().paused = true

func hide_pause():
	visible = false
	get_tree().paused = false
