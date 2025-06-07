extends Node

# === PARTICLE POOLS ===
var particle_pools: Dictionary = {}
var active_particles: Dictionary = {}

# === PRELOADED SCENES (Optimisation principale) ===
const PARTICLE_SCENES = {
	"dust": preload("res://scenes/effects/particles/DustParticle.tscn"),
	"jump": preload("res://scenes/effects/particles/JumpParticle.tscn"),
	"run": preload("res://scenes/effects/particles/RunParticle.tscn")
}

# === POOL SETTINGS ===
const POOL_SIZES = {
	"dust": 15,
	"jump": 8,
	"run": 10
}

func _ready():
	name = "ParticleManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_particle_pools()

func _create_particle_pools():
	for particle_type in POOL_SIZES.keys():
		particle_pools[particle_type] = []
		active_particles[particle_type] = []
		
		var scene = PARTICLE_SCENES[particle_type]  # Direct access au lieu de _get_particle_scene()
		
		for i in POOL_SIZES[particle_type]:
			var particle = scene.instantiate()
			particle.visible = false
			add_child(particle)
			particle_pools[particle_type].append(particle)

func emit_jump(position: Vector2, follow_target: Node2D = null, target_offset: Vector2 = Vector2.ZERO):
	var params = {}
	if follow_target:
		params["follow_target"] = follow_target
		params["target_offset"] = target_offset
	_emit_particle("jump", position, params)

func emit_dust(position: Vector2, direction: float = 0.0, follow_target: Node2D = null):
	var params = {"direction": direction}
	_emit_particle("dust", position, params)

func _emit_particle(type: String, pos: Vector2, params: Dictionary):
	var particle = _get_available_particle(type)
	if not particle:
		return
	
	particle.global_position = pos
	particle.visible = true
	
	if particle.has_node("AnimatedSprite2D"):
		particle.get_node("AnimatedSprite2D").visible = true
	
	# Appliquer les paramètres
	for key in params.keys():
		if particle.has_method("set_" + key):
			particle.call("set_" + key, params[key])
	
	if particle.has_method("start_effect"):
		particle.start_effect()
	
	active_particles[type].append(particle)
	
	# Auto-retour au pool
	if particle.has_signal("finished"):
		particle.finished.connect(_return_to_pool.bind(particle, type), CONNECT_ONE_SHOT)

func _get_available_particle(type: String) -> Node:
	_cleanup_finished_particles(type)
	
	for particle in particle_pools[type]:
		if not particle in active_particles[type]:
			return particle
	return null

func _return_to_pool(particle: Node, type: String):
	particle.visible = false
	active_particles[type].erase(particle)

func _cleanup_finished_particles(type: String):
	if not active_particles.has(type):
		return
	
	active_particles[type] = active_particles[type].filter(
		func(p): return p.visible and (not p.has_method("is_finished") or not p.is_finished())
	)

func stop_all_particles():
	for type in active_particles.keys():
		for particle in active_particles[type]:
			if particle.has_method("stop_effect"):
				particle.stop_effect()
			particle.visible = false
		active_particles[type].clear()
