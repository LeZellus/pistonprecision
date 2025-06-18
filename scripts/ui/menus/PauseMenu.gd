# scripts/ui/menus/PauseMenu.gd - VERSION AVEC TRANSITION
extends Control

signal resume_requested
signal settings_requested
signal menu_requested

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

# === TRANSITION SYSTEM ===
var pause_transition_manager: Node
var is_transitioning: bool = false

func _ready():
	# Connecter les boutons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Récupérer le transition manager
	pause_transition_manager = get_node_or_null("/root/PauseTransitionManager")
	if pause_transition_manager:
		pause_transition_manager.pause_animation_complete.connect(_on_pause_transition_complete)
		pause_transition_manager.resume_animation_complete.connect(_on_resume_transition_complete)
	else:
		print("⚠️ PauseTransitionManager introuvable")

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

# === NOUVELLES MÉTHODES AVEC TRANSITION ===
func show_pause():
	"""Affiche le menu pause avec transition"""
	if is_transitioning:
		return
	
	visible = true
	_disable_buttons()  # Désactiver pendant la transition
	
	# Démarrer la transition
	if pause_transition_manager:
		is_transitioning = true
		pause_transition_manager.start_pause_transition()
	else:
		# Fallback sans transition
		_complete_pause_show()

func _start_resume_transition():
	"""Démarre l'animation de reprise"""
	if not pause_transition_manager:
		hide_pause()
		return
	
	_disable_buttons()
	is_transitioning = true
	pause_transition_manager.start_resume_transition()

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
	"""Désactive tous les boutons pendant les transitions"""
	resume_button.disabled = true
	settings_button.disabled = true
	menu_button.disabled = true

func _enable_buttons():
	"""Réactive tous les boutons"""
	resume_button.disabled = false
	settings_button.disabled = false
	menu_button.disabled = false

# === DEBUG ===
func get_transition_state() -> Dictionary:
	return {
		"is_transitioning": is_transitioning,
		"menu_visible": visible,
		"manager_exists": pause_transition_manager != null
	}
