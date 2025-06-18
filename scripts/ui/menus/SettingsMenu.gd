# scripts/ui/menus/SettingsMenu.gd - RETOUR SIMPLIFIÉ
extends Control

signal back_requested

@onready var volume_slider: HSlider = $CenterContainer/VBoxContainer/VolumeSlider
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	# Connecter les contrôles
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Initialiser avec les valeurs actuelles
	volume_slider.value = AudioManager.master_volume

func _on_volume_changed(value: float):
	print("Volume changé: ", value)
	AudioManager.set_master_volume(value)
	
func _on_back_pressed():
	# 🔧 SIMPLIFIÉ: Toujours émettre le signal
	# GameLevel gère la logique de retour
	print("Retour demandé depuis settings")
	back_requested.emit()

func show_settings():
	visible = true

func hide_settings():
	visible = false
