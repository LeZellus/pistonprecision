# scripts/ui/transitions/PauseTransitionManager.gd
extends Node

# === RÉFÉRENCES AUX SPRITES ===
var rock_sprite: Sprite2D
var piston_sprite: Sprite2D  
var canvas_layer: CanvasLayer

# === ANIMATION STATE ===
var current_tween: Tween
var is_paused: bool = false
var is_animating: bool = false

# === SIGNALS ===
signal pause_animation_complete
signal resume_animation_complete

# === CONSTANTS (IDENTIQUES À DEATH TRANSITION) ===
const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const PISTON_HEAD_WIDTH = 384
const PISTON_TOTAL_WIDTH = 1080
const PISTON_HEAD_CENTER_OFFSET = 192
const ROCK_SIZE = Vector2(1536, 1080)
const PISTON_SIZE = Vector2(1080, 1080)

# === TIMING (IDENTIQUE À DEATH TRANSITION) ===
const ROCK_FALL_TIME = 1.0
const PISTON_DELAY = 0.5
const PISTON_SLIDE_TIME = 1.0
const CRUSH_DELAY = 0.5

func _ready():
	# Plus de setup d'autoload, juste références aux sprites
	_setup_sprite_references()
	call_deferred("_init_sprites")

func _setup_sprite_references():
	rock_sprite = $RockSprite
	piston_sprite = $PistonSprite

func _init_sprites():
	if not rock_sprite or not piston_sprite:
		push_error("PauseTransitionManager: Sprites manquants!")
		return
	
	# POSITIONS INVERSÉES par rapport à death transition
	# Rocher : tombe à DROITE de l'écran
	rock_sprite.position = Vector2(SCREEN_WIDTH - (ROCK_SIZE.x / 2), -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	
	# Piston : arrive de la GAUCHE
	piston_sprite.position = Vector2(-PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false

# === ANIMATION PAUSE (COMME DEATH MAIS SANS CRUSH) ===
func start_pause_transition():
	"""Rocher tombe à droite, piston arrive de gauche - S'ARRÊTE en position"""
	if is_animating:
		return
	
	print("🎬 Démarrage transition pause")
	is_animating = true
	_cleanup_previous_transition()
	
	_setup_sprites_for_pause()
	_animate_pause_fall()

func _setup_sprites_for_pause():
	rock_sprite.visible = true
	rock_sprite.position.x = SCREEN_WIDTH - (ROCK_SIZE.x / 2)  # À droite
	rock_sprite.position.y = -ROCK_SIZE.y / 2  # En haut
	
	piston_sprite.visible = true
	piston_sprite.position.x = -PISTON_TOTAL_WIDTH  # À gauche hors écran

func _animate_pause_fall():
	"""Identique à death transition : rocher tombe, piston arrive"""
	current_tween = create_tween()
	
	# PHASE 1: Rocher tombe (identique à death)
	var final_rock_y = SCREEN_HEIGHT / 2
	current_tween.tween_property(rock_sprite, "position:y", final_rock_y, ROCK_FALL_TIME)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	current_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 0.8))
	
	# PHASE 2: Piston arrive en parallèle (après délai)
	get_tree().create_timer(PISTON_DELAY).timeout.connect(_animate_piston_arrival)
	
	# FIN: S'arrête ici (pas de crush)
	var total_time = ROCK_FALL_TIME + PISTON_SLIDE_TIME + PISTON_DELAY
	get_tree().create_timer(total_time).timeout.connect(_on_pause_sequence_complete)

func _animate_piston_arrival():
	"""Piston arrive de gauche et se positionne"""
	var final_piston_x = _calculate_piston_position_left()
	
	var piston_tween = create_tween()
	piston_tween.tween_property(piston_sprite, "position:x", final_piston_x, PISTON_SLIDE_TIME)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _calculate_piston_position_left() -> float:
	"""Position du piston À GAUCHE du rocher (inverse de death)"""
	var rock_x = SCREEN_WIDTH - (ROCK_SIZE.x / 2)
	var rock_left_edge = rock_x - (ROCK_SIZE.x / 2)
	var head_center_x = rock_left_edge - (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	return head_center_x - sprite_center_offset

func _on_pause_sequence_complete():
	"""Pause établie - éléments en position"""
	is_animating = false
	is_paused = true
	print("✅ Transition pause terminée - éléments en place")
	pause_animation_complete.emit()

# === ANIMATION RESUME (AVEC CRUSH COMME DEATH) ===
func start_resume_transition():
	"""Animation de crush identique à death transition"""
	if is_animating or not is_paused:
		return
	
	print("🎬 Démarrage transition reprise")
	is_animating = true
	_cleanup_previous_transition()
	
	_animate_crush_sequence()

func _animate_crush_sequence():
	"""IDENTIQUE à death transition : recul -> frappe -> éjection"""
	var crush_tween = create_tween()
	var current_piston_x = piston_sprite.position.x
	var recoil_position = current_piston_x - 100  # Recul vers la gauche
	var final_exit_piston = -PISTON_SIZE.x  # Sort par la gauche
	var final_exit_rock = SCREEN_WIDTH + ROCK_SIZE.x  # Sort par la droite
	
	# PHASE 1: Recul de préparation
	crush_tween.tween_property(piston_sprite, "position:x", recoil_position, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# PHASE 2: Frappe + son
	crush_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/smash", 0.8))
	crush_tween.tween_property(piston_sprite, "position:x", current_piston_x, 0.15)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	# PHASE 3: Pause
	crush_tween.tween_interval(0.4)
	
	# PHASE 4: Éjection rocher vers la droite
	crush_tween.tween_property(rock_sprite, "position:x", final_exit_rock, 0.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	# Rebond vertical
	crush_tween.parallel().tween_property(rock_sprite, "position:y", SCREEN_HEIGHT / 2 - 50, 0.4)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	crush_tween.parallel().tween_property(rock_sprite, "position:y", SCREEN_HEIGHT / 2 + 20, 0.4)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# PHASE 5: Piston repart vers la gauche
	crush_tween.parallel().tween_property(piston_sprite, "position:x", final_exit_piston, 0.6)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	crush_tween.tween_callback(_on_resume_sequence_complete)

func _on_resume_sequence_complete():
	"""Resume terminé"""
	_hide_all_sprites()
	is_animating = false
	is_paused = false
	print("✅ Transition reprise terminée")
	resume_animation_complete.emit()

func _cleanup_previous_transition():
	if current_tween and current_tween.is_valid():
		current_tween.kill()

func _hide_all_sprites():
	if rock_sprite:
		rock_sprite.visible = false
	if piston_sprite:
		piston_sprite.visible = false

# === API PUBLIQUE ===
func is_pause_active() -> bool:
	return is_paused

func is_transition_active() -> bool:
	return is_animating
