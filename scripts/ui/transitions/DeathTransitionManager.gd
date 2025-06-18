# scripts/ui/transitions/DeathTransitionManager.gd - VERSION SIMPLIFIÉE AUTOMATIQUE
extends Node

# === RÉFÉRENCES AUX SPRITES ===
var rock_sprite: Sprite2D
var piston_sprite: Sprite2D  
var canvas_layer: CanvasLayer

# === ANIMATION STATE ===
var current_tween: Tween

# === SIGNALS ===
signal transition_complete

# === CONSTANTS ===
const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const PISTON_HEAD_WIDTH = 384
const PISTON_TOTAL_WIDTH = 1080
const PISTON_HEAD_CENTER_OFFSET = 192
const ROCK_SIZE = Vector2(1536, 1080)
const PISTON_SIZE = Vector2(1080, 1080)

# === TIMING RALENTI POUR DEBUG ===
const ROCK_FALL_TIME = 1.0      # était 0.2
const PISTON_DELAY = 0.5         # était 0.1    
const PISTON_SLIDE_TIME = 1.0    # était 0.25
const CRUSH_DELAY = 0.5          # était 0.15
const TOTAL_TRANSITION_TIME = 4.0  # était 0.7 - Beaucoup plus lent !

# === MULTIPLICATEUR DE VITESSE ===
var speed_multiplier: float = 1.0  # 1.0 = normal, 2.0 = 2x plus rapide, 0.5 = 2x plus lent

# === CACHE ===
# Plus de game_manager car plus besoin du compteur

func _ready():
	name = "DeathTransitionManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var ui_scene = preload("res://scenes/ui/DeathTransitionManager.tscn")
	canvas_layer = ui_scene.instantiate()
	add_child(canvas_layer)
	
	_setup_sprite_references()
	call_deferred("_init_sprites")

func _setup_sprite_references():
	rock_sprite = canvas_layer.get_node("RockSprite")
	piston_sprite = canvas_layer.get_node("PistonSprite")

func _init_sprites():
	if not rock_sprite or not piston_sprite:
		push_error("DeathTransitionManager: Sprites manquants!")
		return
	
	# Positions initiales
	rock_sprite.position = Vector2(ROCK_SIZE.x / 2, -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	
	piston_sprite.position = Vector2(SCREEN_WIDTH + PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false

# === MÉTHODE PRINCIPALE SIMPLIFIÉE ===
func start_fast_death_transition(speed_mult: float = 1.0):
	"""Transition rapide et automatique - juste animation visuelle"""
	speed_multiplier = speed_mult
	_cleanup_previous_transition()
	
	_start_fast_animation()
	
	# Timer pour la fin automatique (ajusté par la vitesse)
	var adjusted_time = TOTAL_TRANSITION_TIME / speed_multiplier
	get_tree().create_timer(adjusted_time).timeout.connect(_finish_transition)

func _cleanup_previous_transition():
	if current_tween and current_tween.is_valid():
		current_tween.kill()

func _start_fast_animation():
	"""Animation rapide : rock tombe, piston arrive, crush"""
	_setup_sprites_for_animation()
	
	# Animation du rocher (temps ajusté)
	current_tween = create_tween()
	var final_rock_y = SCREEN_HEIGHT / 2
	
	current_tween.tween_property(rock_sprite, "position:y", final_rock_y, ROCK_FALL_TIME / speed_multiplier)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	current_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 0.8))
	
	# Animation du piston en parallèle (avec délai ajusté)
	get_tree().create_timer(PISTON_DELAY / speed_multiplier).timeout.connect(_animate_piston)
	
	# Animation de crush finale (délai ajusté)
	var crush_delay_total = (ROCK_FALL_TIME + PISTON_SLIDE_TIME + CRUSH_DELAY) / speed_multiplier
	get_tree().create_timer(crush_delay_total).timeout.connect(_animate_crush)

func _setup_sprites_for_animation():
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2
	rock_sprite.position.y = -ROCK_SIZE.y / 2

func _animate_piston():
	"""Animation du piston qui arrive et se positionne"""
	var final_piston_x = _calculate_piston_position()
	
	piston_sprite.visible = true
	
	var piston_tween = create_tween()
	piston_tween.tween_property(piston_sprite, "position:x", final_piston_x, PISTON_SLIDE_TIME / speed_multiplier)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _calculate_piston_position() -> float:
	var rock_right_edge = ROCK_SIZE.x
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	return head_center_x + sprite_center_offset

func _animate_crush():
	"""Animation séquence crush : recul -> frappe -> pause -> éjection rocher -> recul final"""
	var crush_tween = create_tween()
	var current_piston_x = piston_sprite.position.x  # Position de base (à droite du rocher)
	var recoil_position = current_piston_x + 100      # Recul de préparation
	var final_exit = SCREEN_WIDTH + PISTON_SIZE.x     # Sortie complète hors écran
	
	# PHASE 1: Recul de préparation (temps ajusté)
	crush_tween.tween_property(piston_sprite, "position:x", recoil_position, 0.3 / speed_multiplier)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# PHASE 2: Frappe (retour à la position de base) + son (temps ajusté)
	crush_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/smash", 0.8))
	crush_tween.tween_property(piston_sprite, "position:x", current_piston_x, 0.15 / speed_multiplier)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	# PHASE 3: PAUSE - le piston reste en position de frappe (temps ajusté)
	crush_tween.tween_interval(0.4 / speed_multiplier)  # Pause ajustée
	
	# PHASE 4: ÉJECTION DU ROCHER (temps ajusté)
	crush_tween.tween_property(rock_sprite, "position:x", -ROCK_SIZE.x, 0.8 / speed_multiplier)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	# Rebond vertical du rocher (temps ajusté)
	crush_tween.parallel().tween_property(rock_sprite, "position:y", SCREEN_HEIGHT / 2 - 50, 0.4 / speed_multiplier)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	crush_tween.parallel().tween_property(rock_sprite, "position:y", SCREEN_HEIGHT / 2 + 20, 0.4 / speed_multiplier)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# PHASE 5: Recul final du piston HORS ÉCRAN (temps ajusté)
	crush_tween.parallel().tween_property(piston_sprite, "position:x", final_exit, 0.6 / speed_multiplier)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

func _finish_transition():
	"""Termine la transition automatiquement"""
	_hide_all_sprites()
	transition_complete.emit()

func _hide_all_sprites():
	if rock_sprite:
		rock_sprite.visible = false
	if piston_sprite:
		piston_sprite.visible = false

# === API PUBLIQUE ===
func get_transition_time() -> float:
	return TOTAL_TRANSITION_TIME / speed_multiplier

# === MÉTHODES DE CONVENANCE ===
func set_speed_2x():
	"""2x plus rapide"""
	speed_multiplier = 2.0

func set_speed_4x():
	"""4x plus rapide"""
	speed_multiplier = 4.0

func set_speed_normal():
	"""Vitesse normale"""
	speed_multiplier = 1.0

func set_speed_slow():
	"""2x plus lent"""
	speed_multiplier = 0.5
