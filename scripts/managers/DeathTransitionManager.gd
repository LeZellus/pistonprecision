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

# === CONSTANTS CALCULÉES ===
const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const PISTON_HEAD_WIDTH = 384        # 96 * 4
const PISTON_TOTAL_WIDTH = 1080      # 270 * 4  
const PISTON_HEAD_CENTER_OFFSET = 192 # 48 * 4
const ROCK_SIZE = Vector2(1536, 1080) # 384 * 4, 270 * 4
const PISTON_SIZE = Vector2(1080, 1080) # 270 * 4, 270 * 4

func _ready():
	name = "DeathTransitionManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Charger et instancier la scène UI
	var ui_scene = preload("res://scenes/ui/DeathTransitionManager.tscn")
	canvas_layer = ui_scene.instantiate()
	add_child(canvas_layer)
	
	# Récupérer les références après ajout
	rock_sprite = canvas_layer.get_node("RockSprite")
	piston_sprite = canvas_layer.get_node("PistonSprite") 
	death_count_label = canvas_layer.get_node("RockSprite/HBoxContainer/DeathCountLabel")
	
	# Initialiser
	call_deferred("_init_sprites")

func _init_sprites():
	"""Initialise les sprites (vérifications et positions initiales)"""
	# Vérifications de sécurité
	if not rock_sprite:
		push_error("RockSprite non trouvé!")
		return
	if not piston_sprite:
		push_error("PistonSprite non trouvé!")
		return
	if not death_count_label:
		push_error("DeathCountLabel non trouvé dans RockSprite!")
		# Continue même sans le label
	
	# Position initiale du rocher (hors écran en haut)
	rock_sprite.position = Vector2(ROCK_SIZE.x / 2, -ROCK_SIZE.y / 2)
	rock_sprite.visible = false
	
	# Position initiale du piston (hors écran à droite)
	piston_sprite.position = Vector2(SCREEN_WIDTH + PISTON_TOTAL_WIDTH, SCREEN_HEIGHT / 2)
	piston_sprite.visible = false
	
	# Initialiser le label si il existe (sans toucher au layout)
	if death_count_label:
		death_count_label.visible = false
		print("✅ DeathCountLabel trouvé et initialisé")
	
	print("✅ Sprites initialisés avec succès")

func start_death_transition(duration: float = 3.0, _delay_before_fade: float = 0.0):
	"""Lance la transition créative avec piston"""
	if tween:
		tween.kill()
	
	print("🎬 Début de la transition créative")
	
	# Mettre à jour le compteur AVANT de commencer l'animation
	_update_death_count()
	
	# Phase 1: Chute du rocher ET arrivée du piston
	_phase_1_rock_falls_and_piston_arrives()
	
	# Phase 2 après positionnement (après 1.5s total)
	await get_tree().create_timer(1.5).timeout
	_phase_2_piston_strikes()
	
	# Phase 3 après la frappe (après 2.3s total)
	await get_tree().create_timer(0.8).timeout
	_phase_3_cleanup()

func _update_death_count():
	"""Met à jour SEULEMENT le texte du compteur de morts"""
	if not death_count_label:
		print("⚠️ DeathCountLabel non trouvé!")
		return
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and "death_count" in game_manager:
		death_count_label.text = "DEATHS : " + str(game_manager.death_count)
		print("💀 Compteur mis à jour: ", game_manager.death_count)
	else:
		death_count_label.text = "DEATHS : 42"  # Placeholder
		print("💀 Placeholder utilisé: 42")

func _phase_1_rock_falls_and_piston_arrives():
	"""Phase 1: Le rocher tombe ET le piston arrive en slide"""
	print("📉 Phase 1: Chute du rocher + slide du piston")
	
	# === ANIMATION DU ROCHER ===
	rock_sprite.visible = true
	rock_sprite.position.x = ROCK_SIZE.x / 2  # Centré horizontalement
	rock_sprite.position.y = -ROCK_SIZE.y / 2  # Hors écran en haut
	
	# === AFFICHAGE DU COMPTEUR (la scène gère le positionnement) ===
	if death_count_label:
		death_count_label.visible = true
	
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
		
	fall_tween.tween_callback(func(): 
		print("🎵 Son d'impact du rocher")
		AudioManager.play_sfx("ui/transition/impact", 1.0)
		# Particules GPU au bas de l'écran SEULEMENT à l'impact rocher
		_create_ground_particles()
	)
	
	# Retombée
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_BOUNCE)
	
	# Petit rebond final
	fall_tween.tween_property(rock_sprite, "position:y", final_y - 15, 0.05)
	fall_tween.tween_property(rock_sprite, "position:y", final_y, 0.05)
	
	# === ANIMATION DU PISTON EN PARALLÈLE ===
	# Démarrer le slide du piston après 0.3s de chute du rocher
	var delay_timer = get_tree().create_timer(0.3)
	delay_timer.timeout.connect(_start_piston_slide)

func _start_piston_slide():
	"""Démarre l'animation de slide du piston"""
	print("🎬 Début du slide du piston")
	
	# === CALCUL DE LA POSITION FINALE ===
	var rock_right_edge = ROCK_SIZE.x  # 1536px
	var head_center_x = rock_right_edge + (PISTON_HEAD_WIDTH / 2)  # 1536 + 192 = 1728px
	var sprite_center_offset = (PISTON_TOTAL_WIDTH / 2) - PISTON_HEAD_CENTER_OFFSET  # 540 - 192 = 348px
	var final_piston_x = head_center_x + sprite_center_offset  # 1728 + 348 = 2076px
	
	# === ANIMATION DE SLIDE ===
	piston_sprite.visible = true
	
	var slide_tween = create_tween()
	slide_tween.tween_property(piston_sprite, "position:x", final_piston_x, 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUART)
	
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
	
	var head_start_x = piston_sprite.position.x
	var recoil_distance = 100  # Distance de recul avant frappe
	var strike_position = head_start_x - 40  # Position de frappe
	
	# ÉTAPE 1: Recul pour prendre de l'élan (0.2s)
	strike_tween.tween_property(piston_sprite, "position:x", head_start_x + recoil_distance, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	# ÉTAPE 2: Frappe rapide et puissante (0.08s)
	strike_tween.tween_property(piston_sprite, "position:x", strike_position, 0.08)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)
	
	# Son de frappe + effets au moment de l'impact
	strike_tween.tween_callback(func(): 
		AudioManager.play_sfx("ui/transition/impact", 1.0)
		# PLUS de particules pour l'impact piston
		# Lancer l'animation du rocher après l'impact
		_animate_rock_exit()
	)
	
	# ÉTAPE 3: Rétraction rapide du piston (0.4s)
	strike_tween.tween_property(piston_sprite, "position:x", SCREEN_WIDTH + PISTON_SIZE.x, 0.4)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUART)

func _animate_rock_exit():
	"""Animation séparée pour la sortie du rocher (le label suit automatiquement)"""
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

func _hide_all_sprites():
	"""Cache tous les sprites"""
	rock_sprite.visible = false
	piston_sprite.visible = false
	if death_count_label:
		death_count_label.visible = false

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

# === SYSTÈME DE PARTICULES GPU ===
const SMOKE_PARTICLE_SCENE = preload("res://scenes/effects/particles/RockMenuParticle.tscn")

func _create_ground_particles(explosive: bool = false):
	"""Crée vos particules GPU au bas de l'écran UNIQUEMENT pour l'impact rocher"""
	var particle_count = 5  # Seulement impact rocher
	
	# Position fixe au bas de l'écran, centrée sur la largeur du piston
	var base_position = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 20)  # Tout en bas
	
	print("🎆 Création de ", particle_count, " particules GPU à la position : ", base_position)
	
	for i in range(particle_count):
		var particle_instance = SMOKE_PARTICLE_SCENE.instantiate()
		
		# Répartir uniformément sur la largeur du piston
		var spread_ratio = float(i) / float(particle_count - 1)
		var offset_x = (spread_ratio - 0.5) * PISTON_SIZE.x
		particle_instance.position = base_position + Vector2(offset_x, 0)
		
		# Z-index élevé
		particle_instance.z_index = 1000
		
		print("🎆 Particule ", i, " créée à la position : ", particle_instance.position)
		
		# Ajouter à la scène
		canvas_layer.add_child(particle_instance)
		
		# Votre nœud racine EST le GPUParticles2D
		if particle_instance is GPUParticles2D:
			var gpu_particles = particle_instance as GPUParticles2D
			print("✅ GPUParticles2D racine trouvé, démarrage...")
			
			# FORCER One Shot par code (même si coché dans l'éditeur)
			gpu_particles.emitting = false
			gpu_particles.one_shot = true
			gpu_particles.amount = 50
			gpu_particles.lifetime = 2.0
			
			# Méthode alternative pour forcer One Shot
			await get_tree().process_frame
			gpu_particles.emitting = true
			
			print("🎆 Émission One Shot démarrée pour particule ", i)
		else:
			print("❌ Le nœud racine n'est pas un GPUParticles2D")
		
		# Auto-destruction après la durée de vie des particules
		var cleanup_timer = get_tree().create_timer(3.0)
		cleanup_timer.timeout.connect(particle_instance.queue_free)

func _start_particle(gpu_particles: GPUParticles2D):
	"""Démarre une particule One Shot après la création"""
	gpu_particles.emitting = false
	gpu_particles.restart()
	gpu_particles.emitting = true

func _find_gpu_particles_recursive(node: Node) -> GPUParticles2D:
	"""Recherche récursive d'un GPUParticles2D dans toute la hiérarchie"""
	if node is GPUParticles2D:
		return node as GPUParticles2D
	
	for child in node.get_children():
		var result = _find_gpu_particles_recursive(child)
		if result:
			return result
	
	return null
