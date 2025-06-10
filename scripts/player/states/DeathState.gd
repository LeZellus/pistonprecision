class_name DeathState
extends State

var death_explosion: Node = null

func _ready() -> void:
	animation_name = ""  # Pas d'animation par défaut

func enter() -> void:
	print("=== ENTREE DEATH STATE ===")
	
	# Désactiver la physique immédiatement
	parent.set_physics_process(false)
	parent.collision_shape.disabled = true
	parent.sprite.visible = false
	
	# Créer l'explosion
	death_explosion = ParticleManager.emit_death(parent.global_position, 1.5)
	if death_explosion and death_explosion.has_signal("finished"):
		death_explosion.finished.connect(_on_explosion_finished, CONNECT_ONE_SHOT)
	
	# Shake caméra
	if parent.camera:
		parent.camera.shake(8.0, 0.3)

func process_physics(_delta: float) -> State:
	# Pas de physique pendant la mort
	return null

func _on_explosion_finished():
	print("=== EXPLOSION TERMINEE ===")
	
	# Nettoyer la particule
	if death_explosion and is_instance_valid(death_explosion):
		death_explosion.visible = false
		if death_explosion.has_method("cleanup"):
			death_explosion.cleanup()
	
	# Attendre un peu puis respawn
	await parent.get_tree().create_timer(0.5).timeout
	
	print("=== DEMANDE DE RESPAWN ===")
	SceneManager.respawn_player()

func exit() -> void:
	print("=== SORTIE DEATH STATE ===")
	
	# Réactiver le joueur
	parent.set_physics_process(true)
	parent.collision_shape.disabled = false
	
	# Reset visuel avec fade-in
	parent.sprite.visible = true
	parent.sprite.modulate.a = 0.0
	
	var tween = parent.create_tween()
	tween.tween_property(parent.sprite, "modulate:a", 1.0, 0.3)
	
	# Reset states
	parent.velocity = Vector2.ZERO
	parent.piston_direction = Player.PistonDirection.DOWN
	parent.sprite.rotation_degrees = 0
	
	death_explosion = null
