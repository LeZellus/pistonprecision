# scripts/ui/transitions/PauseTransitionManager.gd - ANIMATION INDÉPENDANTE
extends CanvasLayer

# === RÉFÉRENCES AUX SPRITES (directes) ===
@onready var rock_sprite: Sprite2D = $RockSprite
@onready var piston_sprite: Sprite2D = $PistonSprite

# === ANIMATION STATE ===
var current_tween: Tween
var is_paused: bool = false
var is_animating: bool = false

# === SIGNALS ===
# 🔧 PLUS BESOIN du signal pause_animation_complete !
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
const ROCK_FALL_TIME = 0.3  # 🔧 ACCÉLÉRÉ: était 0.8
const PISTON_DELAY = 0.3
const PISTON_SLIDE_TIME = 0.6
const CRUSH_DELAY = 0.2

func _ready():
	# IMPORTANT: Process pendant la pause pour les animations
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

# === ANIMATION PAUSE ===
func start_pause_transition():
	"""🔧 CORRECTION: Animation complète qui marche vraiment"""
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
	rock_sprite.position.y = -ROCK_SIZE.y / 2  # Haut de l'écran
	
	piston_sprite.visible = true
	piston_sprite.position.x = -PISTON_TOTAL_WIDTH  # Hors écran à gauche
	piston_sprite.position.y = SCREEN_HEIGHT / 2

func _animate_pause_fall():
	current_tween = create_tween()
	current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var final_rock_y = SCREEN_HEIGHT / 2
	var final_piston_x = _calculate_piston_position_left()
	
	# 🔧 ANIMATIONS EN PARALLÈLE - même timing !
	# Rocher tombe
	current_tween.tween_property(rock_sprite, "position:y", final_rock_y, ROCK_FALL_TIME)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	# Piston arrive EN MÊME TEMPS (parallel)
	current_tween.parallel().tween_property(piston_sprite, "position:x", final_piston_x, ROCK_FALL_TIME)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	
	# Son d'impact à la fin
	current_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 0.8))
	
	# Fin de l'animation
	current_tween.tween_callback(_on_pause_animation_finished)

func _animate_piston_arrival():
	var final_piston_x = _calculate_piston_position_left()
	
	var piston_tween = create_tween()
	piston_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	piston_tween.tween_property(piston_sprite, "position:x", final_piston_x, PISTON_SLIDE_TIME)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

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
	"""🔧 CORRECTION: Vérification et reset proper"""
	if is_animating:
		print("❌ Animation déjà en cours")
		return
		
	if not is_paused:
		print("❌ Pas en état pause - reset forcé")
		# Reset d'urgence si état incohérent
		_setup_sprites_for_pause()
		is_paused = true
	
	print("🎬 Démarrage transition reprise - état pause: %s" % is_paused)
	is_animating = true
	_cleanup_previous_transition()
	_animate_crush_sequence()

func _animate_crush_sequence():
	"""🔧 CORRECTION: Animation complète dans un seul tween"""
	var crush_tween = create_tween()
	crush_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var current_piston_x = piston_sprite.position.x
	var recoil_position = current_piston_x - 100
	var final_exit_piston = -PISTON_SIZE.x
	var final_exit_rock = SCREEN_WIDTH + ROCK_SIZE.x
	
	print("🎬 Positions - Current piston: %f, Recoil: %f" % [current_piston_x, recoil_position])
	
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
	"""🔧 AMÉLIORATION: Cleanup plus propre"""
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

# === DEBUG ===
func get_debug_info() -> Dictionary:
	return {
		"is_paused": is_paused,
		"is_animating": is_animating,
		"rock_pos": rock_sprite.position if rock_sprite else Vector2.ZERO,
		"piston_pos": piston_sprite.position if piston_sprite else Vector2.ZERO,
		"rock_visible": rock_sprite.visible if rock_sprite else false,
		"piston_visible": piston_sprite.visible if piston_sprite else false
	}
