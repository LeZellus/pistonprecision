# scripts/ui/menus/PauseMenu.gd - VERSION AVEC RÉFÉRENCES DIRECTES
extends Control

signal resume_requested
signal settings_requested
signal menu_requested

@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var menu_button: Button = %MenuButton

# === RÉFÉRENCE DIRECTE À LA TRANSITION (plus d'autoload!) ===
@onready var transition_manager: Node = $CanvasLayer  # Ou le nom que tu as donné à ton instance

var is_transitioning: bool = false

func _ready():
	# Connecter les boutons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Connecter les signaux de transition directement
	if transition_manager:
		transition_manager.pause_animation_complete.connect(_on_pause_transition_complete)
		transition_manager.resume_animation_complete.connect(_on_resume_transition_complete)

func _input(event):
	# Échap pour fermer la pause SEULEMENT si pas en transition
	if event.is_action_pressed("ui_cancel") and visible and not is_transitioning:
		_on_resume_pressed()

func _on_resume_pressed():
	if is_transitioning:
		return
	
	print("Reprendre le jeu avec transition")
	_start_resume_transition()

func _on_settings_pressed():
	if is_transitioning:
		return
	
	print("Paramètres depuis la pause")
	settings_requested.emit()

func _on_menu_pressed():
	if is_transitioning:
		return
	
	print("Retour au menu principal")
	menu_requested.emit()

# === MÉTHODES AVEC TRANSITION (références directes) ===
func show_pause():
	"""Affiche le menu pause avec transition"""
	if is_transitioning:
		return
	
	visible = true
	_disable_buttons()
	
	# Démarrer la transition via référence directe
	if transition_manager:
		is_transitioning = true
		transition_manager.start_pause_transition()
	else:
		_complete_pause_show()

func _start_resume_transition():
	"""Démarre l'animation de reprise"""
	if not transition_manager:
		hide_pause()
		return
	
	_disable_buttons()
	is_transitioning = true
	transition_manager.start_resume_transition()

func _on_pause_transition_complete():
	"""Appelé quand l'animation de pause est terminée"""
	print("✅ Animation pause terminée - menu actif")
	is_transitioning = false
	_complete_pause_show()

func _on_resume_transition_complete():
	"""Appelé quand l'animation de reprise est terminée"""
	print("✅ Animation reprise terminée")
	is_transitioning = false
	hide_pause()

func _complete_pause_show():
	"""Termine l'affichage du menu pause"""
	_enable_buttons()
	get_tree().paused = true

func hide_pause():
	"""Cache le menu pause"""
	visible = false
	get_tree().paused = false
	resume_requested.emit()

# === GESTION DES BOUTONS ===
func _disable_buttons():
	resume_button.disabled = true
	settings_button.disabled = true
	menu_button.disabled = true

func _enable_buttons():
	resume_button.disabled = false
	settings_button.disabled = false
	menu_button.disabled = false
