# scripts/player/components/JumpComponent.gd
class_name JumpComponent
extends MovementComponent

# === JUMP STATE ===
var just_jumped: bool = false
var jump_cut_applied: bool = false

func update(delta: float):
	# Vérifier les conditions de saut
	if _should_jump():
		_perform_jump()
	
	# Gestion du cut jump
	if _should_cut_jump():
		_cut_jump()
	
	# Reset des flags
	if just_jumped and player.is_on_floor():
		just_jumped = false
		jump_cut_applied = false

func _should_jump() -> bool:
	if not InputManager.wants_to_jump() or just_jumped:
		return false
	
	# Saut normal seulement si piston DOWN
	if player.piston_direction == Player.PistonDirection.DOWN:
		return true
	
	# Wall jump possible si contre un mur
	return _can_wall_jump()

func _can_wall_jump() -> bool:
	var wall_side = player.detection_system.get_wall_side()
	if wall_side == 0:
		return false
	
	# Éviter re-grab du même mur
	if player.wall_jump_timer > 0 and wall_side == player.last_wall_side:
		return abs(player.global_position.x - player.last_wall_position) >= PlayerConstants.WALL_JUMP_MIN_SEPARATION
	
	return true

func _perform_jump():
	var wall_side = player.detection_system.get_wall_side()
	
	if wall_side != 0:
		_perform_wall_jump(wall_side)
	else:
		_perform_normal_jump()
	
	InputManager.consume_jump()
	just_jumped = true
	jump_cut_applied = false

func _perform_normal_jump():
	"""Saut normal au sol ou coyote"""
	player.velocity.y = PlayerConstants.JUMP_VELOCITY
	AudioManager.play_sfx_with_cooldown("player/jump", 150, 1.0)
	ParticleManager.emit_jump(player.global_position)
	
	print("🦘 Saut normal effectué")

func _perform_wall_jump(wall_side: int):
	"""Wall jump avec momentum forcé"""
	player.velocity.y = PlayerConstants.JUMP_VELOCITY * 0.95
	
	# MOMENTUM HORIZONTAL FORCÉ (opposé au mur)
	var horizontal_force = -wall_side * PlayerConstants.SPEED * PlayerConstants.WALL_JUMP_HORIZONTAL_FORCE
	player.velocity.x = horizontal_force
	
	# TIMER pour empêcher le re-grab du MÊME mur
	player.wall_jump_timer = PlayerConstants.WALL_JUMP_GRACE_TIME
	player.last_wall_side = wall_side
	player.last_wall_position = player.global_position.x
	
	AudioManager.play_sfx("player/wall_jump", 0.8)
	ParticleManager.emit_jump(player.global_position)
	
	print("🧗 Wall jump effectué! Côté mur: %d" % wall_side)

func _should_cut_jump() -> bool:
	"""Vérifie si on doit couper le saut (relâcher le bouton)"""
	return (player.velocity.y < 0 and 
			InputManager.was_jump_released() and 
			not jump_cut_applied)

func _cut_jump():
	"""Applique la réduction de vélocité quand on relâche le bouton"""
	player.velocity.y *= PlayerConstants.JUMP_CUT_MULTIPLIER
	jump_cut_applied = true
	print("✂️ Jump cut appliqué")

# === DEBUG ===
func get_debug_info() -> String:
	if just_jumped:
		return "Jump: ACTIF"
	return "Jump: prêt"
