# scripts/managers/DeathTransitionManager.gd - Version finale optimisée
extends Node

# === RÉFÉRENCES AUX SPRITES ===
var rock_sprite: Sprite2D
var piston_sprite: Sprite2D  
var death_count_label: Label
var canvas_layer: CanvasLayer

# === ANIMATION STATE ===
var current_tween: Tween  # Plus descriptif que "tween"
var waiting_for_input_emitted: bool = false

# === SIGNALS ===
signal transition_middle_reached
signal transition_complete

# === CONSTANTS ===
const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const PISTON_HEAD_WIDTH = 384
const PISTON_TOTAL_WIDTH = 1080
const PISTON_HEAD_CENTER_OFFSET = 192
const ROCK_SIZE = Vector2(1536, 1080)
const PISTON_SIZE = Vector2(1080, 1080)

# === TIMING CONSTANTS ===
const NORMAL_ROCK_FALL_TIME = 0.35
const NORMAL_PISTON_DELAY = 0.15    
const NORMAL_PISTON_SLIDE_TIME = 0.4
const NORMAL_TOTAL_PHASE1_TIME = 0.8

const FAST_ROCK_FALL_TIME = 0.15
const FAST_PISTON_DELAY = 0.05
const FAST_PISTON_SLIDE_TIME = 0.2
const FAST_TOTAL_PHASE1_TIME = 0.3

# === CACHE ===
var game_manager: Node
var death_counter_script: GDScript

func _ready():
	name = "DeathTransitionManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cache des références importantes
	game_manager = get_node_or_null("/root/GameManager")
	death_counter_script = preload("res://scripts/ui/transitions/DeathCounterAnimation.gd")
	
	var ui_scene = preload("res://scenes/ui/DeathTransitionManager.tscn")
	canvas_layer = ui_scene.instantiate()
	add_child(canvas_layer)
	
	_setup_sprite_references()
	call_deferred("_init_sprites")

func _setup_sprite_references():
	"""Centralise la récupération des références"""
	rock_sprite = canvas_layer.get_node("RockSprite")
	piston_sprite = canvas_layer.get_node("PistonSprite") 
	death_count_label = canvas_layer.get_node("RockSprite/VBoxContainer/HBoxContainer/DeathCountLabel")

func _init_sprites():
	if not rock_sprite or not piston_sprite:
		push_error("DeathTransitionManager: Sprites manquants!")
		return
	
	# Positions initiales
	rock_sprite.position = Vector2(ROCK_SIZE.x / 2, -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	
	piston_sprite.position = Vector2(SCREEN_WIDTH + PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false
	
	if death_count_label:
		death_count_label.visible = false

# === MÉTHODES PRINCIPALES ===
func start_death_transition_no_respawn():
	_start_transition(false)

func start_fast_death_transition():
	_start_transition(true)

func _start_transition(fast_mode: bool):
	_cleanup_previous_transition()
	waiting_for_input_emitted = false
	
	_update_death_count(fast_mode)
	_phase_1_rock_falls_and_piston_arrives(fast_mode)
	
	# Timer unifié pour émission du signal
	var wait_time = FAST_TOTAL_PHASE1_TIME if fast_mode else NORMAL_TOTAL_PHASE1_TIME
	_schedule_middle_signal(wait_time)

func _cleanup_previous_transition():
	"""Nettoie les animations précédentes"""
	if current_tween and current_tween.is_valid():
		current_tween.kill()

func _schedule_middle_signal(wait_time: float):
	"""Programme l'émission du signal middle"""
	await get_tree().create_timer(wait_time).timeout
	
	if not waiting_for_input_emitted:
		transition_middle_reached.emit()
		waiting_for_input_emitted = true

func cleanup_transition():
	_phase_2_piston_strikes()
	await get_tree().create_timer(0.4).timeout
	_hide_all_sprites()
	transition_complete.emit()

# === MÉTHODES D'ACCÉLÉRATION ===
func accelerate_counter_on_input():
	if not _is_counter_valid():
		return
	
	if death_count_label.has_method("is_animation_playing") and death_count_label.is_animation_playing():
		var death_count = _get_death_count()
		if death_count >= 0:
			death_count_label.stop_animation()
			death_count_label.set_number_instantly(death_count)

func accelerate_visual_animation():
	if current_tween and current_tween.is_valid():
		current_tween.set_speed_scale(4.0)
		
		# Signal accéléré
		var time_remaining = NORMAL_TOTAL_PHASE1_TIME * 0.25
		get_tree().create_timer(time_remaining).timeout.connect(_emit_middle_signal_if_needed)

func _emit_middle_signal_if_needed():
	"""Évite la duplication de signal"""
	if not waiting_for_input_emitted:
		transition_middle_reached.emit()
		waiting_for_input_emitted = true

# === ANIMATION DU COMPTEUR (OPTIMISÉ) ===
func _update_death_count(fast_mode: bool = false):
	if not death_count_label:
		return
	
	var death_count = _get_death_count()
	if death_count < 0:
		death_count_label.text = "ERROR"
		return
	
	_setup_death_counter()
	
	# Délai avant animation
	var delay = 0.1 if fast_mode else 0.3
	await get_tree().create_timer(delay).timeout
	
	_animate_death_count(death_count, fast_mode)

func _setup_death_counter():
	"""Configure le compteur de morts"""
	death_count_label.set_script(death_counter_script)
	death_count_label.visible = true
	death_count_label.set_number_instantly(0)

func _animate_death_count(death_count: int, fast_mode: bool):
	"""Gère l'animation du compteur selon le mode"""
	if fast_mode:
		death_count_label.set_number_instantly(death_count)
	elif death_count <= 50:
		death_count_label.animate_to(death_count)
	else:
		_animate_counter_fast(death_count)

func _animate_counter_fast(final_count: int):
	"""Animation rapide et simple pour gros nombres"""
	var animation_time = min(1.0, final_count * 0.001)  # Max 1 seconde
	
	var counter_tween = create_tween()
	counter_tween.tween_method(
		func(value: int): death_count_label.text = str(value),
		0,
		final_count,
		animation_time
	)

# === ANIMATIONS VISUELLES ===
func _phase_1_rock_falls_and_piston_arrives(fast_mode: bool):
	_setup_sprites_for_animation()
	
	var timings = _get_animation_timings(fast_mode)
	_animate_rock_fall(timings, fast_mode)
	
	# Programme le piston en parallèle
	get_tree().create_timer(timings.piston_delay).timeout.connect(_start_piston_slide.bind(fast_mode))

func _setup_sprites_for_animation():
	"""Prépare les sprites pour l'animation"""
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2
	rock_sprite.position.y = -ROCK_SIZE.y / 2
	
	if death_count_label:
		death_count_label.visible = true

func _get_animation_timings(fast_mode: bool) -> Dictionary:
	"""Retourne les timings selon le mode"""
	return {
		"fall_time": FAST_ROCK_FALL_TIME if fast_mode else NORMAL_ROCK_FALL_TIME,
		"piston_delay": FAST_PISTON_DELAY if fast_mode else NORMAL_PISTON_DELAY,
		"slide_time": FAST_PISTON_SLIDE_TIME if fast_mode else NORMAL_PISTON_SLIDE_TIME
	}

func _animate_rock_fall(timings: Dictionary, fast_mode: bool):
	"""Animation du rocher qui tombe"""
	current_tween = create_tween()
	var final_y = SCREEN_HEIGHT / 2
	
	if fast_mode:
		_animate_rock_fast(current_tween, final_y, timings.fall_time)
	else:
		_animate_rock_with_bounce(current_tween, final_y, timings.fall_time)

func _animate_rock_fast(tween: Tween, final_y: float, fall_time: float):
	"""Animation rapide du rocher"""
	tween.tween_property(rock_sprite, "position:y", final_y, fall_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 0.6))

func _animate_rock_with_bounce(tween: Tween, final_y: float, fall_time: float):
	"""Animation complète avec rebond"""
	tween.tween_property(rock_sprite, "position:y", final_y, fall_time)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tween.tween_property(rock_sprite, "position:y", final_y - 30, 0.08)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 1.0))
	tween.tween_property(rock_sprite, "position:y", final_y, 0.05)
	tween.tween_property(rock_sprite, "position:y", final_y - 8, 0.025)
	tween.tween_property(rock_sprite, "position:y", final_y, 0.025)

func _start_piston_slide(fast_mode: bool):
	var final_piston_x = _calculate_piston_position()
	
	piston_sprite.visible = true
	
	var slide_time = FAST_PISTON_SLIDE_TIME if fast_mode else NORMAL_PISTON_SLIDE_TIME
	var slide_tween = create_tween()
	slide_tween.tween_property(piston_sprite, "position:x", final_piston_x, slide_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _calculate_piston_position() -> float:
	"""Calcule la position finale du piston"""
	var rock_right_edge = ROCK_SIZE.x
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	return head_center_x + sprite_center_offset

func _phase_2_piston_strikes():
	var strike_tween = create_tween()
	var head_start_x = piston_sprite.position.x
	var recoil_distance = 100
	var strike_position = head_start_x - 40
	
	# Séquence de frappe
	strike_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/hydraulic", 0.8))
	strike_tween.tween_property(piston_sprite, "position:x", head_start_x + recoil_distance, 0.05)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
	strike_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/smash", 0.8))
	strike_tween.tween_property(piston_sprite, "position:x", strike_position, 0.04)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
		
	strike_tween.tween_property(piston_sprite, "position:x", SCREEN_WIDTH + PISTON_SIZE.x, 0.2)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

func _hide_all_sprites():
	if rock_sprite:
		rock_sprite.visible = false
	if piston_sprite:
		piston_sprite.visible = false
	if death_count_label:
		death_count_label.visible = false

# === UTILITAIRES ===
func _get_death_count() -> int:
	"""Récupère le nombre de morts du GameManager"""
	if not game_manager or not "death_count" in game_manager:
		return -1
	return game_manager.death_count

func _is_counter_valid() -> bool:
	"""Vérifie si le compteur est valide"""
	return death_count_label != null and death_count_label.get_script() != null

# === API PUBLIQUE ===
func get_fast_transition_time() -> float:
	return FAST_TOTAL_PHASE1_TIME

func get_normal_transition_time() -> float:
	return NORMAL_TOTAL_PHASE1_TIME
