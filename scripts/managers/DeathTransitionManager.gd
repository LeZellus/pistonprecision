# scripts/managers/DeathTransitionManager.gd - Version avec affichage des morts
extends Node

# === RÉFÉRENCES AUX SPRITES ===
var rock_sprite: Sprite2D
var piston_sprite: Sprite2D  
var death_count_label: Label
var canvas_layer: CanvasLayer

# === ANIMATION ===
var tween: Tween

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

func _ready():
	name = "DeathTransitionManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var ui_scene = preload("res://scenes/ui/DeathTransitionManager.tscn")
	canvas_layer = ui_scene.instantiate()
	add_child(canvas_layer)
	
	# Récupérer les références
	rock_sprite = canvas_layer.get_node("RockSprite")
	piston_sprite = canvas_layer.get_node("PistonSprite") 
	death_count_label = canvas_layer.get_node("RockSprite/HBoxContainer/DeathCountLabel")
	
	call_deferred("_init_sprites")

func _init_sprites():
	if not rock_sprite or not piston_sprite:
		push_error("Sprites manquants dans DeathTransitionManager!")
		return
	
	# Position initiale du rocher (hors écran)
	rock_sprite.position = Vector2(ROCK_SIZE.x / 2, -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	
	# Position initiale du piston (hors écran)
	piston_sprite.position = Vector2(SCREEN_WIDTH + PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false
	
	if death_count_label:
		death_count_label.visible = false

func start_death_transition(duration: float = 3.0, _delay_before_fade: float = 0.0):
	if tween:
		tween.kill()
	
	_update_death_count()
	_phase_1_rock_falls_and_piston_arrives()
	
	# Phase 2 - Signal de respawn
	await get_tree().create_timer(1.5).timeout
	transition_middle_reached.emit()
	_phase_2_piston_strikes()
	
	# Phase 3 - Cleanup
	await get_tree().create_timer(0.8).timeout
	_phase_3_cleanup()

func _update_death_count():
	"""✅ NOUVEAU : Récupère le vrai compteur de morts du GameManager"""
	if not death_count_label:
		return
	
	# Utilise la même méthode que ton code existant
	var game_manager = get_tree().get_first_node_in_group("managers") 
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and "death_count" in game_manager:
		var death_count = game_manager.death_count
		death_count_label.text = "DEATHS : " + str(death_count)
		print("DeathTransitionManager: Affichage de %d morts" % death_count)
	else:
		# Fallback - utilise l'ancienne logique que tu avais
		death_count_label.text = "DEATHS : 42"
		print("DeathTransitionManager: Utilisation fallback")

func _phase_1_rock_falls_and_piston_arrives():
	# Animation du rocher
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2
	rock_sprite.position.y = -ROCK_SIZE.y / 2
	
	if death_count_label:
		death_count_label.visible = true
	
	# Chute avec rebond
	var fall_tween = create_tween()
	var final_y = SCREEN_HEIGHT / 2
	
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.7)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	fall_tween.tween_property(rock_sprite, "position:y", final_y - 60, 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	fall_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 1.0))
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.1)
	fall_tween.tween_property(rock_sprite, "position:y", final_y - 15, 0.05)
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.05)
	
	# Piston en parallèle
	get_tree().create_timer(0.3).timeout.connect(_start_piston_slide)

func _start_piston_slide():
	var rock_right_edge = ROCK_SIZE.x
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	var final_piston_x = head_center_x + sprite_center_offset
	
	piston_sprite.visible = true
	
	var slide_tween = create_tween()
	slide_tween.tween_property(piston_sprite, "position:x", final_piston_x, 0.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _phase_2_piston_strikes():
	var strike_tween = create_tween()
	var head_start_x = piston_sprite.position.x
	var recoil_distance = 100
	var strike_position = head_start_x - 40
	
	# Recul
	strike_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/hydraulic", 1.0))
	strike_tween.tween_property(piston_sprite, "position:x", head_start_x + recoil_distance, 0.1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Frappe
	strike_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/smash", 1.0))
	strike_tween.tween_property(piston_sprite, "position:x", strike_position, 0.08)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	# Impact
	strike_tween.tween_callback(func(): 
		AudioManager.play_sfx("ui/transition/impact", 1.0)
		_animate_rock_exit()
	)
	
	# Rétraction
	strike_tween.tween_property(piston_sprite, "position:x", SCREEN_WIDTH + PISTON_SIZE.x, 0.4)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

func _animate_rock_exit():
	var rock_tween = create_tween()
	rock_tween.tween_property(rock_sprite, "position:x", -ROCK_SIZE.x, 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

func _phase_3_cleanup():
	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(0.3)
	cleanup_tween.tween_callback(func():
		_hide_all_sprites()
		transition_complete.emit()
	)

func _hide_all_sprites():
	if rock_sprite:
		rock_sprite.visible = false
	if piston_sprite:
		piston_sprite.visible = false
	if death_count_label:
		death_count_label.visible = false

# === MÉTHODES DE COMPATIBILITY ===
func instant_black():
	_hide_all_sprites()

func instant_clear():
	_hide_all_sprites()

func quick_death_transition():
	start_death_transition(1.5)

func slow_death_transition():
	start_death_transition(4.0)

func start_death_transition_immediate():
	start_death_transition(3.0, 0.0)
