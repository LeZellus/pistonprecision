extends CharacterBody2D
class_name Player

# === COMPONENTS ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Components simplifiés - UN SEUL détecteur au lieu de 3
var detection_system: DetectionSystem
var physics_component: PlayerPhysics
var actions_component: PlayerActions
var controller: PlayerController

# === CACHED REFERENCES ===
var camera: Camera2D
var world_space_state: PhysicsDirectSpaceState2D

# === PISTON STATE ===
enum PistonDirection { DOWN, LEFT, UP, RIGHT }
var piston_direction: PistonDirection = PistonDirection.DOWN

# === PHYSICS STATE ===
var was_grounded: bool = false
var wall_jump_timer: float = 0.0
const WALL_JUMP_GRACE_TIME: float = 0.15

# === DEATH SYSTEM SIMPLIFIÉ ===
var respawn_immunity_timer: float = 0.0
const RESPAWN_IMMUNITY_TIME: float = 0.0

# === DEBUG PROCESS POUR SURVEILLER L'IMMUNITÉ ===
func _process(delta: float):
	if Input.is_physical_key_pressed(KEY_R):
		print("💀 DEBUG: Respawn forcé avec R")
		debug_force_respawn()
	# Timer d'immunité avec logs
	if respawn_immunity_timer > 0:
		var old_timer = respawn_immunity_timer
		respawn_immunity_timer -= delta
		
		# Log quand l'immunité se termine
		if old_timer > 0 and respawn_immunity_timer <= 0:
			print("💀 Player._process() - Immunité de respawn TERMINÉE")
			print("  ├─ Était à: ", old_timer)
			print("  └─ Maintenant: ", respawn_immunity_timer)


func _ready():
	world_space_state = get_world_2d().direct_space_state
	camera = get_viewport().get_camera_2d()
	
	_setup_components()
	_connect_signals()
	state_machine.init(self)
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	# Debug de blocage physique si mort
	if is_player_dead():
		# Log périodique de l'état bloqué
		if Engine.get_process_frames() % 180 == 0:  # Toutes les 3 secondes
			print("💀 Player._physics_process() - BLOQUÉ (mort):")
			print("  ├─ Position: ", global_position)
			print("  ├─ Velocity: ", velocity)
			print("  └─ État: ", state_machine.current_state.get_script().get_global_name())
		return

func _setup_components():
	"""Setup simplifié avec un seul système de détection"""
	# UN SEUL détecteur unifié
	detection_system = DetectionSystem.new(self)
	physics_component = PlayerPhysics.new(self)
	actions_component = PlayerActions.new(self)
	controller = PlayerController.new(self)
	
	# Ajout optimisé
	for component in [detection_system, physics_component, actions_component, controller]:
		add_child(component)

func _connect_signals():
	"""Connexion des signaux simplifiée"""
	var signals: Array[Variant] = [
		[InputManager.rotate_left_requested, _on_rotate_left],
		[InputManager.rotate_right_requested, _on_rotate_right],
		[InputManager.push_requested, _on_push_requested]
	]
	
	for signal_data in signals:
		if not signal_data[0].is_connected(signal_data[1]):
			signal_data[0].connect(signal_data[1])

# === DEBUG POUR LES INPUTS PENDANT LA MORT ===
func _unhandled_input(event: InputEvent) -> void:
	if is_player_dead():
		# Log des inputs bloqués
		if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			print("💀 Player._unhandled_input() - INPUT BLOQUÉ (mort):")
			print("  ├─ Action: ", "jump" if event.is_action_pressed("jump") else "ui_accept")
			print("  └─ État: ", state_machine.current_state.get_script().get_global_name())
		return
	
	state_machine.process_input(event)

# === API SIMPLIFIÉE ===
func can_wall_slide() -> bool:
	return detection_system.is_touching_wall() and wall_jump_timer <= 0

# === COMPATIBILITY PROPERTIES (pour garder le code existant) ===
var wall_detector: DetectionSystem:
	get: return detection_system

var ground_detector: DetectionSystem:
	get: return detection_system
	
var push_detector: DetectionSystem:
	get: return detection_system

# === ROTATION & PUSH ===
func _on_rotate_left():
	actions_component.rotate_piston(-1)

func _on_rotate_right():
	actions_component.rotate_piston(1)

func _on_push_requested():
	actions_component.execute_push()

# === DEATH SYSTEM REFACTORISÉ ===
func trigger_death():
	print("💀 Player.trigger_death() - DÉBUT")
	print("  ├─ Position actuelle: ", global_position)
	print("  ├─ Velocity actuelle: ", velocity)
	print("  ├─ Au sol: ", is_on_floor())
	print("  ├─ État actuel: ", state_machine.current_state.get_script().get_global_name() if state_machine.current_state else "NULL")
	
	# Vérifications de sécurité
	if is_player_dead():
		print("  ├─ DÉJÀ MORT - Trigger ignoré")
		print("  └─ État actuel confirmé: ", state_machine.current_state.get_script().get_global_name())
		return
	
	if has_death_immunity():
		print("  ├─ IMMUNITÉ ACTIVE - Trigger ignoré")
		print("  ├─ Timer immunité: ", respawn_immunity_timer)
		print("  └─ Immunité restante: ", respawn_immunity_timer, "s")
		return
	
	print("  ├─ Conditions OK, transition vers DeathState")
	
	# Vérifier que le DeathState existe
	var death_state: Node = state_machine.get_node_or_null("DeathState")
	if death_state:
		print("  ├─ DeathState trouvé: ", death_state.name)
		print("  ├─ Script DeathState: ", death_state.get_script().get_global_name())
		print("  └─ Changement d'état...")
		state_machine.change_state(death_state)
		print("💀 Player.trigger_death() - Transition effectuée")
	else:
		push_error("💀 DeathState non trouvé dans la StateMachine!")
		print("  └─ ERREUR: Impossible de changer vers DeathState")

func is_player_dead() -> bool:
	var current_state: State = state_machine.current_state
	var is_dead = current_state != null and current_state.get_script().get_global_name() == "DeathState"
	
	# Debug périodique (toutes les 120 frames = ~2 secondes)
	if Engine.get_process_frames() % 120 == 0:
		print("💀 Player.is_player_dead() - Check:")
		print("  ├─ État actuel: ", current_state.get_script().get_global_name() if current_state else "NULL")
		print("  ├─ Est mort: ", is_dead)
		print("  └─ Position: ", global_position)
	
	return is_dead

func has_death_immunity() -> bool:
	var has_immunity = respawn_immunity_timer > 0
	
	# Log seulement quand l'immunité change
	if has_immunity and Engine.get_process_frames() % 60 == 0:
		print("💀 Player.has_death_immunity() - Immunité active: ", respawn_immunity_timer, "s restantes")
	
	return has_immunity

func start_respawn_immunity():
	print("💀 Player.start_respawn_immunity() - DÉBUT")
	print("  ├─ Timer avant: ", respawn_immunity_timer)
	print("  ├─ Constante utilisée: ", RESPAWN_IMMUNITY_TIME)
	
	respawn_immunity_timer = RESPAWN_IMMUNITY_TIME
	
	print("  ├─ Timer après: ", respawn_immunity_timer)
	print("  └─ Immunité activée pour ", RESPAWN_IMMUNITY_TIME, "s")
	
	# Si l'immunité est à 0, c'est probablement normal mais signalons-le
	if RESPAWN_IMMUNITY_TIME == 0.0:
		print("  ⚠️  ATTENTION: RESPAWN_IMMUNITY_TIME = 0, immunité instantanément désactivée")

# === API POUR COMPATIBILITY (si nécessaire) ===
func start_room_transition():
	"""Pour compatibilité avec le SceneManager"""
	# Plus besoin d'immunité de transition spéciale
	pass
	
# === COLLECTIBLES (nouveau) ===
var collectibles_count: int = 0

# Méthode à ajouter :
func add_collectible():
	"""Incrémente le compteur de collectibles"""
	collectibles_count += 1
	print("Collectibles: ", collectibles_count)

func get_collectibles_count() -> int:
	"""Retourne le nombre de collectibles"""
	return collectibles_count
	
func debug_death_system():
	print("💀 === DEBUG DEATH SYSTEM ===")
	print("💀 État actuel: ", state_machine.current_state.get_script().get_global_name() if state_machine.current_state else "NULL")
	print("💀 Est mort: ", is_player_dead())
	print("💀 Immunité timer: ", respawn_immunity_timer)
	print("💀 Immunité active: ", has_death_immunity())
	print("💀 Position: ", global_position)
	print("💀 Velocity: ", velocity)
	print("💀 Au sol: ", is_on_floor())
	print("💀 Sprite visible: ", sprite.visible)
	print("💀 Sprite alpha: ", sprite.modulate.a)
	
	# État du DeathTransitionManager
	var dtm = get_node_or_null("/root/DeathTransitionManager")
	if dtm and dtm.has_method("get_debug_info"):
		var info = dtm.get_debug_info()
		print("💀 DeathTransitionManager:")
		for key in info.keys():
			print("💀   ├─ ", key, ": ", info[key])
	else:
		print("💀 DeathTransitionManager: Non trouvé ou pas de debug")
	
	print("💀 === FIN DEBUG DEATH SYSTEM ===")
	
func debug_force_respawn():
	print("💀 DEBUG: Force respawn demandé")
	if is_player_dead():
		var death_state = state_machine.current_state
		if death_state and death_state.has_method("_trigger_early_respawn"):
			print("💀 DEBUG: Appel _trigger_early_respawn() sur DeathState")
			death_state._trigger_early_respawn()
		else:
			print("💀 DEBUG: Transition forcée vers IdleState")
			var idle_state = state_machine.get_node_or_null("IdleState")
			if idle_state:
				state_machine.change_state(idle_state)
	else:
		print("💀 DEBUG: Joueur pas mort, respawn non nécessaire")
