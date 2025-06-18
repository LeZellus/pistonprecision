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

# === TIMING RAPIDE ===
const ROCK_FALL_TIME = 0.2
const PISTON_DELAY = 0.1    
const PISTON_SLIDE_TIME = 0.25
const CRUSH_DELAY = 0.15
const TOTAL_TRANSITION_TIME = 0.7  # Très rapide !

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
func start_fast_death_transition():
	"""Transition rapide et automatique - juste animation visuelle"""
	_cleanup_previous_transition()
	
	# Animation rapide sans compteur
	_start_fast_animation()
	
	# Timer pour la fin automatique
	get_tree().create_timer(TOTAL_TRANSITION_TIME).timeout.connect(_finish_transition)

func _cleanup_previous_transition():
	if current_tween and current_tween.is_valid():
		current_tween.kill()

func _start_fast_animation():
	"""Animation rapide : rock tombe, piston arrive, crush"""
	_setup_sprites_for_animation()
	
	# Animation du rocher
	current_tween = create_tween()
	var final_rock_y = SCREEN_HEIGHT / 2
	
	current_tween.tween_property(rock_sprite, "position:y", final_rock_y, ROCK_FALL_TIME)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	current_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 0.8))
	
	# Animation du piston en parallèle (avec délai)
	get_tree().create_timer(PISTON_DELAY).timeout.connect(_animate_piston)
	
	# Animation de crush finale
	get_tree().create_timer(ROCK_FALL_TIME + PISTON_SLIDE_TIME + CRUSH_DELAY).timeout.connect(_animate_crush)

func _setup_sprites_for_animation():
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2
	rock_sprite.position.y = -ROCK_SIZE.y / 2

func _animate_piston():
	"""Animation du piston qui arrive"""
	var final_piston_x = _calculate_piston_position()
	
	piston_sprite.visible = true
	
	var piston_tween = create_tween()
	piston_tween.tween_property(piston_sprite, "position:x", final_piston_x, PISTON_SLIDE_TIME)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _calculate_piston_position() -> float:
	var rock_right_edge = ROCK_SIZE.x
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	return head_center_x + sprite_center_offset

func _animate_crush():
	"""Animation finale de crush"""
	var crush_tween = create_tween()
	var current_piston_x = piston_sprite.position.x
	var strike_position = current_piston_x - 60
	
	# Son + mouvement de crush
	crush_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/smash", 0.8))
	crush_tween.tween_property(piston_sprite, "position:x", strike_position, 0.08)\
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
	return TOTAL_TRANSITION_TIME
