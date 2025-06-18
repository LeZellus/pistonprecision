# scripts/player/Player.gd - FIX PAUSE COMPLET
extends CharacterBody2D
class_name Player

# === COMPONENTS UI ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# === HANDLERS (initialisés directement) ===
var action_handler: PlayerActionHandler = PlayerActionHandler.new()
var death_handler: PlayerDeathHandler = PlayerDeathHandler.new()

# === SYSTÈMES CORE ===
var detection_system: DetectionSystem
var physics_component: PlayerPhysics
var movement_system: MovementSystem

# === CACHED REFERENCES ===
var camera: Camera2D

# === STATE MINIMAL ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === PHYSICS STATE ===
var was_grounded: bool = false
var wall_jump_timer: float = 0.0
var last_wall_side: int = 0
var last_wall_position: float = 0.0

# === GAMEPLAY DATA ===
var collectibles_count: int = 0

func _ready():
	# 🔧 CRITIQUE: Le joueur doit TOTALEMENT s'arrêter pendant la pause
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	camera = get_viewport().get_camera_2d()
	_setup_handlers()
	_setup_core_systems()
	state_machine.init(self)
	add_to_group("player")
	print("✅ Player initialisé avec handlers")

# === SETUP AVEC HANDLERS ===
func _setup_handlers():
	"""Initialise les handlers qui gèrent les actions complexes"""
	# Les ajouter comme enfants
	add_child(action_handler)
	add_child(death_handler)
	
	# 🔧 CRITIQUE: Tous les handlers doivent s'arrêter pendant la pause
	action_handler.process_mode = Node.PROCESS_MODE_PAUSABLE
	death_handler.process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Les configurer
	action_handler.setup(self)
	death_handler.setup(self)

func _setup_core_systems():
	"""Initialise les systèmes core (physique, détection, mouvement)"""
	# Systèmes existants
	detection_system = DetectionSystem.new(self)
	physics_component = PlayerPhysics.new(self)
	add_child(detection_system)
	add_child(physics_component)
	
	# 🔧 CRITIQUE: Tous les systèmes doivent s'arrêter pendant la pause
	detection_system.process_mode = Node.PROCESS_MODE_PAUSABLE
	physics_component.process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Système de mouvement unifié
	movement_system = MovementSystem.new(self)
	movement_system.add_component(JumpComponent.new(self))
	movement_system.add_component(WallSlideComponent.new(self))
	movement_system.add_component(DashComponent.new(self))
	add_child(movement_system)
	
	# 🔧 CRITIQUE: Le système de mouvement aussi doit s'arrêter
	movement_system.process_mode = Node.PROCESS_MODE_PAUSABLE

# === GAME LOOP ALLÉGÉ ===
func _process(delta: float):
	# Gestion du wall jump timer
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			last_wall_side = 0
	
	# Update des systèmes
	movement_system.update_all(delta)
	
	# Vérification automatique de mort (avec garde)
	if death_handler and death_handler.check_death_conditions():
		death_handler.trigger_death()

func _physics_process(delta: float):
	# Garde pour éviter l'erreur
	if not death_handler:
		return
		
	if is_player_dead():
		state_machine.process_physics(delta)
		return
	
	delta = min(delta, 1.0/30.0)
	_handle_grounding()
	state_machine.process_physics(delta)

func _handle_grounding():
	"""Gestion du sol - logique préservée"""
	var grounded = self.is_on_floor()
	detection_system.set_active(not grounded)
	
	if grounded and not was_grounded:
		AudioManager.play_sfx("player/land", 1)
		ParticleManager.emit_dust(global_position, 0.0, self)
		wall_jump_timer = 0.0
	
	if grounded != was_grounded:
		InputManager.set_grounded(grounded)
		was_grounded = grounded

func _unhandled_input(event: InputEvent) -> void:
	# 🔧 NOUVELLE GARDE: Pas d'input si en pause
	if get_tree().paused:
		return
		
	if not is_player_dead():
		state_machine.process_input(event)

# === DÉLÉGATION AUX HANDLERS (avec gardes) ===

# Actions déléguées à ActionHandler
func rotate_piston(direction: int):
	if action_handler:
		action_handler._rotate_piston(direction)

func execute_push():
	if action_handler:
		action_handler.execute_push()

# Mort déléguée à DeathHandler
func trigger_death():
	if death_handler:
		death_handler.trigger_death()

func is_player_dead() -> bool:
	if not death_handler:
		return false
	return death_handler.is_player_dead()

# === MÉTHODES POUR LA COMPATIBILITÉ ===
func has_death_immunity() -> bool:
	"""Méthode pour StateTransitions"""
	return false  # Pas d'immunité dans ce système simple

# === MÉTHODES HÉRITÉES (compatibility) ===
func start_room_transition():
	"""Pour compatibilité avec le SceneManager"""
	pass

func add_collectible():
	collectibles_count += 1
	print("💎 Collectible ramassé! Total: %d" % collectibles_count)

func get_collectibles_count() -> int:
	return collectibles_count

# === DEBUG INFO ===
func get_debug_info() -> Dictionary:
	return {
		"position": global_position,
		"velocity": velocity,
		"piston_direction": PistonDirection.keys()[piston_direction],
		"is_dead": is_player_dead(),
		"collectibles": collectibles_count,
		"wall_jump_timer": wall_jump_timer
	}
