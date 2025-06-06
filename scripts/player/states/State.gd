class_name State
extends Node

@export var animation_name: String
var parent: Player

func enter() -> void:
	if animation_name:
		parent.sprite.play(animation_name)

func exit() -> void:
	pass

func process_input(_event: InputEvent) -> State:
	return null

func process_frame(_delta: float) -> State:
	return null

func process_physics(_delta: float) -> State:
	return null

# === PHYSIQUE COMMUNE ===
func apply_basic_physics(delta: float):
	parent.apply_gravity(delta)
	parent.move_and_slide()

func apply_ground_physics(delta: float):
	parent.apply_gravity(delta)
	parent.apply_movement(delta)
	parent.move_and_slide()

func apply_air_physics(delta: float):
	parent.apply_gravity(delta)
	parent.apply_air_movement(delta)
	parent.move_and_slide()

# === TRANSITIONS COMMUNES ===
func check_ground_transitions() -> State:
	if not parent.is_on_floor():
		return get_node("../JumpState") if parent.velocity.y < 0 else get_node("../FallState")
	return null

func check_air_transitions() -> State:
	if parent.is_on_floor():
		return get_node("../RunState") if InputManager.get_movement() != 0 else get_node("../IdleState")
	return null

func check_jump_input() -> State:
	if InputManager.consume_jump_buffer() and parent.piston_direction == Player.PistonDirection.DOWN:
		return get_node("../JumpState")
	return null

func check_wall_slide_transition() -> State:
	if parent.wall_detector.is_touching_wall():
		return get_node("../WallSlideState")
	return null
	
func check_dash_input() -> State:
	# Vérifie l'input dash seulement si on peut dasher
	if InputManager.was_dash_pressed() and parent.can_dash():
		return get_node("../DashState")
	return null
