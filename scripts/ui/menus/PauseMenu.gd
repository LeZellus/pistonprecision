# scripts/ui/menus/PauseMenu.gd - PAUSE INSTANTANÉE
extends Control

signal resume_requested
signal settings_requested
signal menu_requested

# === RÉFÉRENCES UI DIRECTES ===
@onready var resume_button: Button = $CanvasLayer/RockSprite/CenterContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $CanvasLayer/RockSprite/CenterContainer/VBoxContainer/SettingsButton
@onready var menu_button: Button = $CanvasLayer/RockSprite/CenterContainer/VBoxContainer/MenuButton

# === TRANSITION MANAGER ===
@onready var transition_manager: Node = $CanvasLayer

var is_transitioning: bool = false

func _ready():
	# IMPORTANT: Permettre le traitement pendant la pause
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Connecter les boutons avec vérification
	if resume_button: resume_button.pressed.connect(_on_resume_pressed)
	if settings_button: settings_button.pressed.connect(_on_settings_pressed)
	if menu_button: menu_button.pressed.connect(_on_menu_pressed)
	
	# Connecter SEULEMENT le signal de resume (pas le pause)
	if transition_manager:
		transition_manager.resume_animation_complete.connect(_on_resume_transition_complete)
	
	# Commencer caché
	visible = false

func _input(event):
	# Échap pour fermer SEULEMENT si visible et pas en transition
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

# === MÉTHODES PUBLIQUES ===
func show_pause():
	"""🔧 NOUVELLE LOGIQUE: Pause INSTANTANÉE + animation en parallèle"""
	if is_transitioning:
		return
	
	visible = true
	_disable_buttons()
	
	# 🔧 PAUSE IMMÉDIATE - PAS D'ATTENTE !
	get_tree().paused = true
	print("⏸️ Pause INSTANTANÉE activée")
	
	# Animation EN PARALLÈLE (fonctionne grâce à PROCESS_MODE_WHEN_PAUSED)
	if transition_manager:
		transition_manager.start_pause_transition()
	
	# Activation immédiate des boutons (pas d'attente d'animation)
	_complete_pause_show()

func hide_pause():
	"""Cache le menu pause sans signal"""
	visible = false
	get_tree().paused = false

# === TRANSITIONS ===
func _start_resume_transition():
	if not transition_manager:
		_resume_game()
		return
	
	_disable_buttons()
	is_transitioning = true
	transition_manager.start_resume_transition()

func _on_resume_transition_complete():
	"""Appelé APRÈS l'animation de resume"""
	print("✅ Animation reprise terminée")
	is_transitioning = false
	_resume_game()

func _complete_pause_show():
	"""Active les boutons IMMÉDIATEMENT"""
	_enable_buttons()
	# Focus automatique sur le premier bouton
	if resume_button:
		resume_button.grab_focus()

func _resume_game():
	"""Reprend le jeu et émet le signal"""
	visible = false
	get_tree().paused = false
	resume_requested.emit()

# === UTILITAIRES ===
func _disable_buttons():
	if resume_button: resume_button.disabled = true
	if settings_button: settings_button.disabled = true
	if menu_button: menu_button.disabled = true

func _enable_buttons():
	if resume_button: resume_button.disabled = false
	if settings_button: settings_button.disabled = false
	if menu_button: menu_button.disabled = false
