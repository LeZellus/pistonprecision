class_name DeathState
extends State

signal death_animation_finished

var death_explosion: Node = null

func _ready() -> void:
	animation_name = ""

func enter() -> void:
	print("=== ENTREE DEATH STATE ===")
	
	# Désactiver la physique immédiatement
	parent.set_physics_process(false)
	parent.collision_shape.disabled = true
	parent.sprite.visible = false
	parent.is_dead = true
	
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
	
	# Attendre un peu puis signaler la fin
	await parent.get_tree().create_timer(0.5).timeout
	
	# Signal que l'animation de mort est terminée
	death_animation_finished.emit()

func exit() -> void:
	print("=== SORTIE DEATH STATE ===")
	death_explosion = null
