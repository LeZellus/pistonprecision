extends CanvasLayer
class_name DeathTransitionManager

# === SPRITES ===
var rock_sprite: Sprite2D
var piston_head_sprite: Sprite2D

# === ANIMATION ===
var tween: Tween

# === SIGNALS ===
signal transition_middle_reached
signal transition_complete

# === CONSTANTS ===
const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const PISTON_HEAD_WIDTH = 96 * 4      # 384px - largeur de la tête rouge
const PISTON_TOTAL_WIDTH = 270 * 4    # 1080px - largeur totale du sprite
const PISTON_HEAD_CENTER_OFFSET = 48 * 4  # 192px - distance du bord gauche au centre de la tête
const ROCK_SIZE = Vector2(384 * 4, 270 * 4)  # Dimensions du rocher
const PISTON_SIZE = Vector2(270 * 4, 270 * 4)  # Dimensions du piston

func _ready():
	name = "DeathTransitionManager"
	layer = 100  # Au-dessus de tout
	_create_sprites()

func _create_sprites():
	"""Crée les sprites du rocher et du piston"""
	
	# === ROCHER ===
	rock_sprite = Sprite2D.new()
	rock_sprite.name = "RockSprite"
	rock_sprite.texture = load("res://assets/sprites/transition/rock.png")
	rock_sprite.position = Vector2(ROCK_SIZE.x / 2, -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	add_child(rock_sprite)
	
	# === TÊTE DU PISTON ===
	piston_head_sprite = Sprite2D.new()
	piston_head_sprite.name = "PistonHeadSprite"
	piston_head_sprite.texture = load("res://assets/sprites/transition/piston.png")
	piston_head_sprite.position = Vector2(SCREEN_WIDTH + PISTON_SIZE.x / 2, SCREEN_HEIGHT / 2)
	piston_head_sprite.visible = false
	add_child(piston_head_sprite)

func start_death_transition(duration: float = 3.0, _delay_before_fade: float = 0.0):
	"""Lance la transition créative avec piston"""
	if tween:
		tween.kill()
	
	print("🎬 Début de la transition créative")
	
	# Phase 1: Chute du rocher ET arrivée du piston
	_phase_1_rock_falls_and_piston_arrives()
	
	# Phase 2 après positionnement (après 1.5s total)
	await get_tree().create_timer(1.5).timeout
	_phase_2_piston_strikes()
	
	# Phase 3 après la frappe (après 2.3s total)
	await get_tree().create_timer(0.8).timeout
	_phase_3_cleanup()

func _phase_1_rock_falls_and_piston_arrives():
	"""Phase 1: Le rocher tombe ET le piston arrive en slide"""
	print("📉 Phase 1: Chute du rocher + slide du piston")
	
	# === ANIMATION DU ROCHER ===
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2  # Centré horizontalement
	rock_sprite.position.y = -ROCK_SIZE.y / 2  # Hors écran en haut
	
	# Animation de chute avec rebond
	var fall_tween = create_tween()
	var final_y = SCREEN_HEIGHT / 2  # Centre vertical
	
	# Chute principale (0.7s)
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.7)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	# Premier rebond
	fall_tween.tween_property(rock_sprite, "position:y", final_y - 60, 0.15)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BOUNCE)
	
	# Retombée
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_BOUNCE)
	
	# Petit rebond final
	fall_tween.tween_property(rock_sprite, "position:y", final_y - 15, 0.05)
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.05)
	
	# Son d'impact
	fall_tween.tween_callback(func(): 
		print("🎵 Son d'impact du rocher")
		# AudioManager.play_sfx("objects/wall_impact", 0.8)
	)
	
	# === ANIMATION DU PISTON EN PARALLÈLE ===
	# Démarrer le slide du piston après 0.3s de chute du rocher
	var delay_timer = get_tree().create_timer(0.3)
	delay_timer.timeout.connect(_start_piston_slide)

func _start_piston_slide():
	"""Démarre l'animation de slide du piston"""
	print("🎬 Début du slide du piston")
	
	# === CALCUL DE LA POSITION FINALE ===
	var rock_right_edge = (ROCK_SIZE.x / 2) + (ROCK_SIZE.x / 2)  # = 1536px
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)  # 1536 + 192 = 1728px
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET  # 540 - 192 = 348px
	var final_piston_x = head_center_x + sprite_center_offset  # 1728 + 348 = 2076px
	
	# === POSITION DE DÉPART (HORS ÉCRAN À DROITE) ===
	piston_head_sprite.visible = true
	piston_head_sprite.position.x = SCREEN_WIDTH + PISTON_TOTAL_WIDTH  # Complètement hors écran
	piston_head_sprite.position.y = SCREEN_HEIGHT / 2
	
	print("Position départ piston: ", piston_head_sprite.position.x)
	print("Position finale piston: ", final_piston_x)
	
	# === ANIMATION DE SLIDE SIMPLE ===
	var slide_tween = create_tween()
	slide_tween.tween_property(piston_head_sprite, "position:x", final_piston_x, 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUART)  # Slide simple et propre
	
	# Son de glissement
	slide_tween.tween_callback(func(): 
		print("🎵 Son de slide du piston")
		# AudioManager.play_sfx("mechanics/slide", 0.6)
	)

func _phase_2_piston_strikes():
	"""Phase 2: Le piston frappe le rocher (recul → frappe → rétraction)"""
	print("💥 Phase 2: Frappe du piston")
	
	# Signal du milieu de transition (respawn)
	transition_middle_reached.emit()
	
	var strike_tween = create_tween()
	
	var head_start_x = piston_head_sprite.position.x
	var recoil_distance = 80  # Distance de recul avant frappe
	var strike_position = head_start_x - 40  # Position de frappe
	
	# ÉTAPE 1: Recul pour prendre de l'élan (0.2s)
	strike_tween.tween_property(piston_head_sprite, "position:x", head_start_x + recoil_distance, 0.2)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	# ÉTAPE 2: Frappe rapide et puissante (0.08s)
	strike_tween.tween_property(piston_head_sprite, "position:x", strike_position, 0.08)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	# Son de frappe + effets au moment de l'impact
	strike_tween.tween_callback(func(): 
		AudioManager.play_sfx("player/dash", 1.0)
		_screen_shake()
		# Lancer l'animation du rocher après l'impact
		_animate_rock_exit()
	)
	
	# ÉTAPE 3: Rétraction rapide du piston (0.4s)
	strike_tween.tween_property(piston_head_sprite, "position:x", SCREEN_WIDTH + PISTON_SIZE.x, 0.4)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)

func _animate_rock_exit():
	"""Animation séparée pour la sortie du rocher"""
	var rock_tween = create_tween()
	rock_tween.tween_property(rock_sprite, "position:x", -ROCK_SIZE.x, 0.5)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)

func _phase_3_cleanup():
	"""Phase 3: Nettoyage final"""
	print("🧹 Phase 3: Nettoyage")
	
	# Attendre un peu puis finir la transition
	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(0.3)
	cleanup_tween.tween_callback(func():
		_hide_all_sprites()
		transition_complete.emit()
		print("✅ Transition créative terminée")
	)

func _screen_shake():
	"""Effet de shake lors de l'impact"""
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12.0, 0.4)

func _hide_all_sprites():
	"""Cache tous les sprites"""
	rock_sprite.visible = false
	piston_head_sprite.visible = false

# === MÉTHODES DE COMPATIBILITY ===
func instant_black():
	"""Met l'écran en noir instantanément (fallback)"""
	_hide_all_sprites()

func instant_clear():
	"""Retire le noir instantanément (fallback)"""
	_hide_all_sprites()

func quick_death_transition():
	"""Version rapide pour debug"""
	start_death_transition(1.5)

func slow_death_transition():
	"""Version lente/cinématique"""
	start_death_transition(4.0)

func start_death_transition_immediate():
	"""Version sans délai (ancien comportement)"""
	start_death_transition(3.0, 0.0)
