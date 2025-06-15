# scripts/managers/DeathTransitionManager.gd - Fix animation compteur
extends Node

# === RÉFÉRENCES AUX SPRITES ===
var rock_sprite: Sprite2D
var piston_sprite: Sprite2D  
var death_count_label: Label
var canvas_layer: CanvasLayer

# === ANIMATION ===
var tween: Tween
var waiting_for_input_emitted: bool = false  # NOUVEAU : éviter double émission

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
const NORMAL_ROCK_FALL_TIME = 0.35  # Divisé par 2
const NORMAL_PISTON_DELAY = 0.15    # Divisé par 2  
const NORMAL_PISTON_SLIDE_TIME = 0.4 # Divisé par 2
const NORMAL_TOTAL_PHASE1_TIME = 0.8 # Divisé par ~2

const FAST_ROCK_FALL_TIME = 0.15
const FAST_PISTON_DELAY = 0.05
const FAST_PISTON_SLIDE_TIME = 0.2
const FAST_TOTAL_PHASE1_TIME = 0.3

func _ready():
	name = "DeathTransitionManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var ui_scene = preload("res://scenes/ui/DeathTransitionManager.tscn")
	canvas_layer = ui_scene.instantiate()
	add_child(canvas_layer)
	
	# Récupérer les références
	rock_sprite = canvas_layer.get_node("RockSprite")
	piston_sprite = canvas_layer.get_node("PistonSprite") 
	death_count_label = canvas_layer.get_node("RockSprite/VBoxContainer/HBoxContainer/DeathCountLabel")
	
	call_deferred("_init_sprites")

func _init_sprites():
	if not rock_sprite or not piston_sprite:
		push_error("Sprites manquants dans DeathTransitionManager!")
		return
	
	rock_sprite.position = Vector2(ROCK_SIZE.x / 2, -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	
	piston_sprite.position = Vector2(SCREEN_WIDTH + PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false
	
	if death_count_label:
		death_count_label.visible = false

# === MÉTHODES PRINCIPALES ===
func start_death_transition_no_respawn():
	"""Lance la transition normale"""
	_start_transition(false)

func start_fast_death_transition():
	"""Lance la transition rapide"""
	_start_transition(true)

func _start_transition(fast_mode: bool):
	if tween:
		tween.kill()
	
	waiting_for_input_emitted = false  # NOUVEAU : reset flag
	
	_update_death_count(fast_mode)
	_phase_1_rock_falls_and_piston_arrives(fast_mode)
	
	var wait_time = FAST_TOTAL_PHASE1_TIME if fast_mode else NORMAL_TOTAL_PHASE1_TIME
	await get_tree().create_timer(wait_time).timeout
	
	if not waiting_for_input_emitted:  # NOUVEAU : éviter double émission
		transition_middle_reached.emit()
		waiting_for_input_emitted = true

func cleanup_transition():
	"""Appelé après le respawn pour finir l'animation"""
	_phase_2_piston_strikes()
	await get_tree().create_timer(0.4).timeout
	_hide_all_sprites()
	transition_complete.emit()

# === NOUVELLES MÉTHODES PUBLIQUES ===
func accelerate_counter_on_input():
	"""Appelé dès qu'on détecte un input de respawn"""
	_finish_counter_animation_quickly()

func accelerate_visual_animation():
	"""Accélère l'animation visuelle (rocher + piston) en cours"""
	if tween and tween.is_valid():
		print("DeathTransitionManager: Accélération animation visuelle")
		
		# Accélérer le tween existant (multiplier vitesse par 4)
		tween.set_speed_scale(4.0)
		
		# Forcer l'émission du signal plus rapidement
		var time_remaining = NORMAL_TOTAL_PHASE1_TIME * 0.25  # Diviser par 4
		get_tree().create_timer(time_remaining).timeout.connect(
			func(): 
				if not waiting_for_input_emitted:  # Éviter double émission
					transition_middle_reached.emit()
					waiting_for_input_emitted = true
		)

# === NOUVELLE MÉTHODE : ACCÉLÉRER LE COMPTEUR ===
func _finish_counter_animation_quickly():
	"""Termine rapidement l'animation du compteur si elle est en cours"""
	if not death_count_label:
		return
	
	# Vérifier si le label a le script DeathCounterAnimation
	if death_count_label.get_script() and death_count_label.has_method("is_animation_playing"):
		if death_count_label.is_animation_playing():
			print("DeathTransitionManager: Accélération animation compteur")
			
			# Obtenir le nombre final
			var game_manager = get_tree().get_first_node_in_group("managers") 
			if not game_manager:
				game_manager = get_node_or_null("/root/GameManager")
			
			if game_manager and "death_count" in game_manager:
				# Arrêter l'animation actuelle et afficher le nombre final
				death_count_label.stop_animation()
				death_count_label.set_number_instantly(game_manager.death_count)

# === ANIMATION DU COMPTEUR ===
func _update_death_count(fast_mode: bool = false):
	if not death_count_label:
		return
	
	var game_manager = get_tree().get_first_node_in_group("managers") 
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and "death_count" in game_manager:
		var death_count = game_manager.death_count
		
		# Transformer le label en DeathCounterAnimation
		death_count_label.set_script(preload("res://scripts/ui/DeathCounterAnimation.gd"))
		death_count_label.visible = true
		death_count_label.set_number_instantly(0)
		
		# Délai adapté au mode - RÉDUIT pour mode normal
		var delay = 0.1 if fast_mode else 0.3
		await get_tree().create_timer(delay).timeout
		
		# En mode rapide, on affiche directement le nombre final
		if fast_mode:
			death_count_label.set_number_instantly(death_count)
		else:
			# === NOUVEAU : ANIMATION LIMITÉE DANS LE TEMPS ===
			_animate_counter_with_time_limit(death_count)
	else:
		death_count_label.text = "PROBLEM"

func _animate_counter_with_time_limit(final_count: int):
	"""Anime le compteur mais plafonné à 1 seconde max"""
	const MAX_ANIMATION_TIME = 1.0  # 1 seconde maximum
	
	if final_count <= 0:
		death_count_label.set_number_instantly(final_count)
		return
	
	# Si on a peu de morts, utiliser l'animation normale avec ralentissement
	if final_count <= 50:
		death_count_label.animate_to_number(final_count, 0)
	else:
		# Pour beaucoup de morts : animation accélérée mais gardant le ralentissement final
		_fast_counter_with_slowdown(final_count, MAX_ANIMATION_TIME)

func _fast_counter_with_slowdown(final_count: int, max_time: float):
	"""Animation rapide pour gros nombres MAIS garde le ralentissement sur les 5 derniers"""
	
	# Séparer en 2 phases : phase rapide + phase lente (5 derniers)
	var fast_phase_end = final_count - 5
	var fast_phase_time = max_time - 1.0  # Réserver 1s pour les 5 derniers
	fast_phase_time = max(fast_phase_time, 0.2)  # Minimum 0.2s pour la phase rapide
	
	if fast_phase_end <= 0:
		# Pas assez de morts pour séparer, utiliser animation normale
		death_count_label.animate_to_number(final_count, 0)
		return
	
	print("DeathCounter: Phase rapide 0→%d (%.2fs), puis ralentissement %d→%d" % [fast_phase_end, fast_phase_time, fast_phase_end, final_count])
	
	# Utiliser ton système existant mais avec override du timing
	var script = death_count_label.get_script()
	if script and death_count_label.has_method("animate_to_number_with_custom_timing"):
		# Nouvelle méthode à ajouter dans DeathCounterAnimation
		death_count_label.animate_to_number_with_custom_timing(final_count, 0, fast_phase_time)
	else:
		# Fallback : animation manuelle
		_manual_counter_animation(final_count, fast_phase_end, fast_phase_time)

func _manual_counter_animation(final_count: int, fast_phase_end: int, fast_phase_time: float):
	"""Animation manuelle si la méthode custom n'existe pas encore"""
	var tween = create_tween()
	
	# Phase 1 : Rapide jusqu'à final_count - 5
	var fast_steps = fast_phase_end
	var step_time = fast_phase_time / fast_steps
	
	for i in range(fast_steps):
		var value = i + 1
		tween.tween_callback(func(): death_count_label.text = str(value))
		tween.tween_interval(step_time)
	
	# Phase 2 : Ralentissement sur les 5 derniers (comme ton système)
	var slow_timings = [0.2, 0.25, 0.3, 0.35, 0.4]  # Même timing que ton système
	
	for i in range(5):
		var value = fast_phase_end + i + 1
		if value <= final_count:
			tween.tween_callback(func(): death_count_label.text = str(value))
			tween.tween_interval(slow_timings[i])

# === ANIMATIONS VISUELLES ===
func _phase_1_rock_falls_and_piston_arrives(fast_mode: bool = false):
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2
	rock_sprite.position.y = -ROCK_SIZE.y / 2
	
	if death_count_label:
		death_count_label.visible = true
	
	var fall_time = FAST_ROCK_FALL_TIME if fast_mode else NORMAL_ROCK_FALL_TIME
	var piston_delay = FAST_PISTON_DELAY if fast_mode else NORMAL_PISTON_DELAY
	
	var fall_tween = create_tween()
	var final_y = SCREEN_HEIGHT / 2
	
	if fast_mode:
		# Animation rapide simplifiée
		fall_tween.tween_property(rock_sprite, "position:y", final_y, fall_time)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		fall_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 0.6))
	else:
		# Animation complète normale mais ACCÉLÉRÉE
		fall_tween.tween_property(rock_sprite, "position:y", final_y, fall_time)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
		fall_tween.tween_property(rock_sprite, "position:y", final_y - 30, 0.08)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		fall_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/impact", 1.0))
		fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.05)
		fall_tween.tween_property(rock_sprite, "position:y", final_y - 8, 0.025)
		fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.025)
	
	# Piston en parallèle avec timing adapté
	get_tree().create_timer(piston_delay).timeout.connect(_start_piston_slide.bind(fast_mode))

func _start_piston_slide(fast_mode: bool = false):
	var rock_right_edge = ROCK_SIZE.x
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	var final_piston_x = head_center_x + sprite_center_offset
	
	piston_sprite.visible = true
	
	var slide_time = FAST_PISTON_SLIDE_TIME if fast_mode else NORMAL_PISTON_SLIDE_TIME
	var slide_tween = create_tween()
	slide_tween.tween_property(piston_sprite, "position:x", final_piston_x, slide_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _phase_2_piston_strikes():
	var strike_tween = create_tween()
	var head_start_x = piston_sprite.position.x
	var recoil_distance = 100
	var strike_position = head_start_x - 40
	
	# Animation rapide pour la sortie
	strike_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/hydraulic", 0.8))
	strike_tween.tween_property(piston_sprite, "position:x", head_start_x + recoil_distance, 0.05)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
	strike_tween.tween_callback(func(): AudioManager.play_sfx("ui/transition/smash", 0.8))
	
	strike_tween.tween_property(piston_sprite, "position:x", strike_position, 0.04)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
		
	strike_tween.tween_property(piston_sprite, "position:x", SCREEN_WIDTH + PISTON_SIZE.x, 0.2)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

func _animate_rock_exit():
	var rock_tween = create_tween()
	rock_tween.tween_property(rock_sprite, "position:x", -ROCK_SIZE.x, 0.25)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

func _hide_all_sprites():
	if rock_sprite:
		rock_sprite.visible = false
	if piston_sprite:
		piston_sprite.visible = false
	if death_count_label:
		death_count_label.visible = false

# === MÉTHODES DE COMPATIBILITY ===
func quick_death_transition():
	start_fast_death_transition()

# === API PUBLIQUE ===
func get_fast_transition_time() -> float:
	"""Retourne le temps total de la transition rapide"""
	return FAST_TOTAL_PHASE1_TIME

func get_normal_transition_time() -> float:
	"""Retourne le temps total de la transition normale"""
	return NORMAL_TOTAL_PHASE1_TIME
