# scripts/managers/DeathTransitionManager.gd - Version DEBUG COMPLÈTE
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

# === DEBUG ===
var debug_start_time: float = 0.0
var debug_phase: String = "IDLE"

# === CONSTANTS CALCULÉES ===
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
	print("🎬 DeathTransitionManager._ready() - DÉBUT")
	
	# Charger et instancier la scène UI
	var ui_scene = preload("res://scenes/ui/DeathTransitionManager.tscn")
	canvas_layer = ui_scene.instantiate()
	add_child(canvas_layer)
	print("  ├─ Scène UI instanciée et ajoutée")
	
	# Récupérer les références après ajout
	rock_sprite = canvas_layer.get_node("RockSprite")
	piston_sprite = canvas_layer.get_node("PistonSprite") 
	death_count_label = canvas_layer.get_node("RockSprite/HBoxContainer/DeathCountLabel")
	print("  ├─ Références récupérées:")
	print("  │   ├─ rock_sprite: ", rock_sprite != null)
	print("  │   ├─ piston_sprite: ", piston_sprite != null)
	print("  │   └─ death_count_label: ", death_count_label != null)
	
	# Initialiser
	call_deferred("_init_sprites")
	print("🎬 DeathTransitionManager._ready() - FIN")

func _init_sprites():
	print("🎬 DeathTransitionManager._init_sprites() - DÉBUT")
	
	# Vérifications de sécurité
	if not rock_sprite:
		push_error("RockSprite non trouvé!")
		return
	if not piston_sprite:
		push_error("PistonSprite non trouvé!")
		return
	if not death_count_label:
		print("  ⚠️ DeathCountLabel non trouvé dans RockSprite!")
	
	# Position initiale du rocher (hors écran en haut)
	rock_sprite.position = Vector2(ROCK_SIZE.x / 2, -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	print("  ├─ RockSprite initialisé: pos=", rock_sprite.position, " visible=", rock_sprite.visible)
	
	# Position initiale du piston (hors écran à droite)
	piston_sprite.position = Vector2(SCREEN_WIDTH + PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false
	print("  ├─ PistonSprite initialisé: pos=", piston_sprite.position, " visible=", piston_sprite.visible)
	
	# Initialiser le label si il existe
	if death_count_label:
		death_count_label.visible = false
		print("  ├─ DeathCountLabel initialisé")
	
	print("🎬 DeathTransitionManager._init_sprites() - FIN")

func start_death_transition(duration: float = 3.0, _delay_before_fade: float = 0.0):
	debug_start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	debug_phase = "STARTING"
	
	print("🎬 DeathTransitionManager.start_death_transition() - DÉBUT")
	print("  ├─ Durée demandée: ", duration, "s")
	print("  ├─ Delay avant fade: ", _delay_before_fade, "s")
	print("  ├─ Heure de début: ", debug_start_time)
	print("  └─ Sprites disponibles: rock=", rock_sprite != null, " piston=", piston_sprite != null)
	
	if tween:
		print("  ├─ Tween existant tué")
		tween.kill()
	
	# Mettre à jour le compteur AVANT de commencer l'animation
	_update_death_count()
	
	debug_phase = "PHASE_1"
	print("🎬 Phase 1 commencée")
	_phase_1_rock_falls_and_piston_arrives()
	
	# Phase 2 après positionnement (après 1.5s total)
	await get_tree().create_timer(1.5).timeout
	debug_phase = "PHASE_2"
	print("🎬 Phase 2 commencée (", _get_elapsed_time(), "s)")
	_phase_2_piston_strikes()
	
	# Phase 3 après la frappe (après 2.3s total)
	await get_tree().create_timer(0.8).timeout
	debug_phase = "PHASE_3"
	print("🎬 Phase 3 commencée (", _get_elapsed_time(), "s)")
	_phase_3_cleanup()

func _get_elapsed_time() -> float:
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	return current_time - debug_start_time

func _update_death_count():
	print("🎬 DeathTransitionManager._update_death_count() - DÉBUT")
	
	if not death_count_label:
		print("  └─ Pas de label, compteur non mis à jour")
		return
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and "death_count" in game_manager:
		death_count_label.text = "DEATHS : " + str(game_manager.death_count)
		print("  ├─ Compteur GameManager trouvé: ", game_manager.death_count)
	else:
		death_count_label.text = "DEATHS : 42"
		print("  ├─ GameManager non trouvé, placeholder utilisé")
	
	print("  └─ Texte du label: ", death_count_label.text)

func _phase_1_rock_falls_and_piston_arrives():
	print("🎬 _phase_1_rock_falls_and_piston_arrives() - DÉBUT")
	
	# === ANIMATION DU ROCHER ===
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2
	rock_sprite.position.y = -ROCK_SIZE.y / 2
	print("  ├─ Rocher visible, position initiale: ", rock_sprite.position)
	
	# === AFFICHAGE DU COMPTEUR ===
	if death_count_label:
		death_count_label.visible = true
		print("  ├─ Label compteur visible")
	
	# Animation de chute avec rebond
	var fall_tween = create_tween()
	var final_y = SCREEN_HEIGHT / 2
	print("  ├─ Animation de chute vers y=", final_y)
	
	# Chute principale (0.7s)
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.7)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	# Premier rebond + callback
	fall_tween.tween_property(rock_sprite, "position:y", final_y - 60, 0.15)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BOUNCE)
		
	fall_tween.tween_callback(func(): 
		print("  ├─ Impact du rocher! (", _get_elapsed_time(), "s)")
		AudioManager.play_sfx("ui/transition/impact", 1.0)
	)
	
	# Retombée + petit rebond
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.1)
	fall_tween.tween_property(rock_sprite, "position:y", final_y - 15, 0.05)
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.05)
	
	# === ANIMATION DU PISTON EN PARALLÈLE ===
	var delay_timer = get_tree().create_timer(0.3)
	delay_timer.timeout.connect(func():
		print("  ├─ Début slide piston (", _get_elapsed_time(), "s)")
		_start_piston_slide()
	)
	
	print("🎬 _phase_1_rock_falls_and_piston_arrives() - FIN")

func _start_piston_slide():
	print("🎬 _start_piston_slide() - DÉBUT")
	
	# === CALCUL DE LA POSITION FINALE ===
	var rock_right_edge = ROCK_SIZE.x
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET
	var final_piston_x = head_center_x + sprite_center_offset
	
	print("  ├─ Position finale calculée: x=", final_piston_x)
	print("  ├─ Position actuelle: ", piston_sprite.position)
	
	# === ANIMATION DE SLIDE ===
	piston_sprite.visible = true
	print("  ├─ Piston visible")
	
	var slide_tween = create_tween()
	slide_tween.tween_property(piston_sprite, "position:x", final_piston_x, 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUART)
	
	slide_tween.tween_callback(func(): 
		print("  ├─ Slide terminé (", _get_elapsed_time(), "s)")
	)
	
	print("🎬 _start_piston_slide() - FIN")

func _phase_2_piston_strikes():
	print("🎬 _phase_2_piston_strikes() - DÉBUT (", _get_elapsed_time(), "s)")
	
	# **SIGNAL DU MILIEU DE TRANSITION (RESPAWN)**
	print("  ├─ ÉMISSION DU SIGNAL transition_middle_reached")
	transition_middle_reached.emit()
	
	var strike_tween = create_tween()
	var head_start_x = piston_sprite.position.x
	var recoil_distance = 100
	var strike_position = head_start_x - 40
	
	print("  ├─ Position initiale piston: ", head_start_x)
	print("  ├─ Position de frappe: ", strike_position)
	
	# ÉTAPE 1: Recul
	strike_tween.tween_callback(func(): 
		print("  ├─ Son hydraulique (", _get_elapsed_time(), "s)")
		AudioManager.play_sfx("ui/transition/hydraulic", 1.0)
	)
	
	strike_tween.tween_property(piston_sprite, "position:x", head_start_x + recoil_distance, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	# ÉTAPE 2: Frappe
	strike_tween.tween_callback(func(): 
		print("  ├─ Son de frappe (", _get_elapsed_time(), "s)")
		AudioManager.play_sfx("ui/transition/smash", 1.0)
	)
	
	strike_tween.tween_property(piston_sprite, "position:x", strike_position, 0.08)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	# Impact + animation rocher
	strike_tween.tween_callback(func(): 
		print("  ├─ IMPACT! (", _get_elapsed_time(), "s)")
		AudioManager.play_sfx("ui/transition/impact", 1.0)
		_animate_rock_exit()
	)
	
	# ÉTAPE 3: Rétraction
	strike_tween.tween_property(piston_sprite, "position:x", SCREEN_WIDTH + PISTON_SIZE.x, 0.4)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	print("🎬 _phase_2_piston_strikes() - FIN")

func _animate_rock_exit():
	print("🎬 _animate_rock_exit() - DÉBUT (", _get_elapsed_time(), "s)")
	
	var rock_tween = create_tween()
	rock_tween.tween_property(rock_sprite, "position:x", -ROCK_SIZE.x, 0.5)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	rock_tween.tween_callback(func():
		print("  └─ Rocher sorti de l'écran (", _get_elapsed_time(), "s)")
	)

func _phase_3_cleanup():
	print("🎬 _phase_3_cleanup() - DÉBUT (", _get_elapsed_time(), "s)")
	debug_phase = "CLEANUP"
	
	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(0.3)
	cleanup_tween.tween_callback(func():
		print("  ├─ Nettoyage sprites (", _get_elapsed_time(), "s)")
		_hide_all_sprites()
		
		print("  ├─ ÉMISSION DU SIGNAL transition_complete")
		transition_complete.emit()
		
		debug_phase = "COMPLETE"
		print("🎬 Transition créative terminée (durée totale: ", _get_elapsed_time(), "s)")
	)

func _hide_all_sprites():
	print("🎬 _hide_all_sprites() - DÉBUT")
	
	if rock_sprite:
		rock_sprite.visible = false
		print("  ├─ RockSprite caché")
	
	if piston_sprite:
		piston_sprite.visible = false
		print("  ├─ PistonSprite caché")
	
	if death_count_label:
		death_count_label.visible = false
		print("  ├─ DeathCountLabel caché")
	
	print("🎬 _hide_all_sprites() - FIN")

# === MÉTHODES DE COMPATIBILITY ===
func instant_black():
	print("🎬 DeathTransitionManager.instant_black() - Mode fallback")
	_hide_all_sprites()

func instant_clear():
	print("🎬 DeathTransitionManager.instant_clear() - Mode fallback")
	_hide_all_sprites()

func quick_death_transition():
	print("🎬 DeathTransitionManager.quick_death_transition() - Mode rapide")
	start_death_transition(1.5)

func slow_death_transition():
	print("🎬 DeathTransitionManager.slow_death_transition() - Mode lent")
	start_death_transition(4.0)

func start_death_transition_immediate():
	print("🎬 DeathTransitionManager.start_death_transition_immediate() - Sans délai")
	start_death_transition(3.0, 0.0)

# === DEBUG SUPPLÉMENTAIRE ===
func get_debug_info() -> Dictionary:
	return {
		"phase": debug_phase,
		"elapsed_time": _get_elapsed_time() if debug_start_time > 0 else 0.0,
		"rock_visible": rock_sprite.visible if rock_sprite else false,
		"piston_visible": piston_sprite.visible if piston_sprite else false,
		"label_visible": death_count_label.visible if death_count_label else false,
		"tween_active": tween.is_valid() if tween else false,
		"rock_position": rock_sprite.position if rock_sprite else Vector2.ZERO,
		"piston_position": piston_sprite.position if piston_sprite else Vector2.ZERO
	}
