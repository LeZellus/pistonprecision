# scripts/ui/transitions/PauseTransitionManager.gd - AJOUT FORCE STOP
extends CanvasLayer

# === RÉFÉRENCES AUX SPRITES (directes) ===
@onready var rock_sprite: Sprite2D = $RockSprite
@onready var piston_sprite: Sprite2D = $PistonSprite

# === ANIMATION STATE ===
var current_tween: Tween
var is_paused: bool = false
var is_animating: bool = false

# === SIGNALS ===
signal resume_animation_complete

# === CONSTANTS ===
const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const PISTON_HEAD_WIDTH = 384
const PISTON_TOTAL_WIDTH = 1080
const PISTON_HEAD_CENTER_OFFSET = 192
const ROCK_SIZE = Vector2(1536, 1080)
const PISTON_SIZE = Vector2(1080, 1080)

# === TIMING ===
const ROCK_FALL_TIME = 0.3
const PISTON_DELAY = 0.3
const PISTON_SLIDE_TIME = 0.6
const CRUSH_DELAY = 0.2

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_init_sprites()

func _init_sprites():
	if not rock_sprite or not piston_sprite:
		push_error("PauseTransitionManager: Sprites manquants!")
		return
	
	# POSITIONS INVERSÉES par rapport à death transition
	rock_sprite.position = Vector2(SCREEN_WIDTH - (ROCK_SIZE.x / 2), -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	
	piston_sprite.position = Vector2(-PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false

# 🔧 NOUVELLE MÉTHODE CRITIQUE
func force_stop():
	"""ARRÊT IMMÉDIAT de toute animation pour retour main menu"""
	print("🛑 FORCE STOP: Arrêt immédiat des animations pause")
	
	# 1. Tuer les tweens
	_cleanup_previous_transition()
	
	# 2. Reset des états
	is_animating = false
	is_paused = false
	
	# 3. Masquer immédiatement tous les sprites
	_hide_all_sprites()

# === ANIMATION PAUSE ===
func start_pause_transition():
	"""Animation complète qui marche vraiment"""
	if is_animating:
		return
	
	print("🎬 Animation pause complète")
	is_animating = true
	_cleanup_previous_transition()
	
	# Reset des états
	is_paused = false
	
	_setup_sprites_for_pause()
	_animate_pause_fall()

func _setup_sprites_for_pause():
	"""Reset complet des positions"""
	rock_sprite.visible = true
	rock_sprite.position.x = SCREEN_WIDTH - (ROCK_SIZE.x / 2)
	rock_sprite.position.y = -ROCK_SIZE.y / 2
	
	piston_sprite.visible = true
	piston_sprite.position.x = -PISTON_TOTAL_WIDTH
	piston_sprite.position.y = SCREEN_HEIGHT / 2

func _animate_pause_fall():
	current_tween = create_tween()
	current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var final_rock_y = SCREEN_HEIGHT / 2
	var final_piston_x = _calculate_piston_position_left()
	
	# Animations en parallèle
	current_tween.tween_property(rock_sprite, "position:y", final_rock_y, ROCK_FALL_TIME)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	current_tween.parallel().tween_property(piston_sprite, "position:x", final_piston_x, ROCK_FALL_TIME)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	
	# Son d'impact à la fin
	current_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 0.8))
	
	# Fin de l'animation
	current_tween.tween_callback(_on_pause_animation_finished)

func _calculate_piston_position_left() -> float:
	var rock_x = SCREEN_WIDTH - (ROCK_SIZE.x / 2)
	var rock_left_edge = rock_x - (ROCK_SIZE.x / 2)
	var head_center_x = rock_left_edge - (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	return head_center_x - sprite_center_offset

func _on_pause_animation_finished():
	"""Marque l'animation pause comme terminée"""
	is_animating = false
	is_paused = true
	print("✅ Animation pause terminée - sprites en position")

# === ANIMATION RESUME ===
func start_resume_transition():
	"""Vérification et reset proper"""
	if is_animating:
		print("❌ Animation déjà en cours")
		return
		
	if not is_paused:
		print("❌ Pas en état pause - reset forcé")
		_setup_sprites_for_pause()
		is_paused = true
	
	print("🎬 Démarrage transition reprise")
	is_animating = true
	_cleanup_previous_transition()
	_animate_crush_sequence()

func _animate_crush_sequence():
	"""Animation complète dans un seul tween"""
	var crush_tween = create_tween()
	crush_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var current_piston_x = piston_sprite.position.x
	var recoil_position = current_piston_x - 100
	var final_exit_piston = -PISTON_SIZE.x
	var final_exit_rock = SCREEN_WIDTH + ROCK_SIZE.x
	
	# PHASE 1: Recul de préparation
	crush_tween.tween_property(piston_sprite, "position:x", recoil_position, 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# PHASE 2: Frappe + son
	crush_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/smash", 0.8))
	crush_tween.tween_property(piston_sprite, "position:x", current_piston_x, 0.1)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	# PHASE 3: Pause dramatique
	crush_tween.tween_interval(0.2)
	
	# PHASE 4: Éjection simultanée
	crush_tween.tween_property(rock_sprite, "position:x", final_exit_rock, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	crush_tween.parallel().tween_property(piston_sprite, "position:x", final_exit_piston, 0.4)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	# PHASE 5: Fin de séquence
	crush_tween.tween_callback(_on_resume_sequence_complete)

func _on_resume_sequence_complete():
	_hide_all_sprites()
	is_animating = false
	is_paused = false
	print("✅ Transition reprise terminée")
	resume_animation_complete.emit()

# === UTILITAIRES ===
func _cleanup_previous_transition():
	"""Cleanup plus propre"""
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = null

func _hide_all_sprites():
	"""Reset complet des sprites"""
	if rock_sprite: 
		rock_sprite.visible = false
		rock_sprite.position = Vector2(SCREEN_WIDTH - (ROCK_SIZE.x / 2), -ROCK_SIZE.y / 2)
	if piston_sprite: 
		piston_sprite.visible = false
		piston_sprite.position = Vector2(-PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)

# === API PUBLIQUE ===
func is_pause_active() -> bool:
	return is_paused

func is_transition_active() -> bool:
	return is_animating
