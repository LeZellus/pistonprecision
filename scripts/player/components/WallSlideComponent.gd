# scripts/player/components/WallSlideComponent.gd
class_name WallSlideComponent
extends MovementComponent

# === WALL SLIDE STATE ===
var was_wall_sliding: bool = false

func update(delta: float):
	# Vérifier si on DOIT être en wall slide
	if _should_wall_slide():
		if not is_active():
			_start_wall_slide()
		_process_wall_slide(delta)
	else:
		if is_active():
			_end_wall_slide()

func _should_wall_slide() -> bool:
	"""Conditions pour activer le wall slide"""
	if player.is_on_floor():
		return false
	
	if player.velocity.y <= 30:  # Pas assez de vitesse de chute
		return false
	
	if not player.wall_detector.wall_detection_active:
		return false
	
	var current_wall_side = player.wall_detector.get_wall_side()
	if current_wall_side == 0:
		return false
	
	# Éviter de re-grab le même mur après wall jump
	if player.wall_jump_timer > 0 and current_wall_side == player.last_wall_side:
		var distance_moved = abs(player.global_position.x - player.last_wall_position)
		if distance_moved < PlayerConstants.WALL_JUMP_MIN_SEPARATION:
			return false
	
	return true

func _start_wall_slide():
	"""Démarre le wall slide"""
	enable()
	was_wall_sliding = false
	print("🧗 Wall slide activé")
	
	# Mémoriser position pour éviter re-grab
	player.last_wall_position = player.global_position.x

func _process_wall_slide(delta: float):
	"""Logique du wall slide - Copié de WallSlideState"""
	# Appliquer la physique de wall slide
	if player.velocity.y > 0:
		player.velocity.y *= PlayerConstants.WALL_SLIDE_MULTIPLIER
		player.velocity.y = min(player.velocity.y, 
			PlayerConstants.MAX_FALL_SPEED * PlayerConstants.WALL_SLIDE_MAX_SPEED_MULTIPLIER)
	
	# Mouvement horizontal (style Rite)
	var input_dir = InputManager.get_movement()
	var wall_side = player.wall_detector.get_wall_side()
	
	if input_dir == wall_side:
		# Coller au mur = ZERO mouvement (adhérence totale)
		player.velocity.x = 0
	elif input_dir == -wall_side:
		# S'éloigner du mur = mouvement IMMÉDIAT et puissant
		player.velocity.x = input_dir * PlayerConstants.SPEED * 0.8
	else:
		# Pas d'input = friction normale mais pas trop
		player.velocity.x = move_toward(player.velocity.x, 0, 
			PlayerConstants.AIR_RESISTANCE * 0.6 * delta)

func _end_wall_slide():
	"""Termine le wall slide"""
	disable()
	print("🧗 Wall slide désactivé")

# === DEBUG ===
func get_debug_info() -> String:
	if is_active():
		return "WallSlide: ACTIF"
	return "WallSlide: inactif"
