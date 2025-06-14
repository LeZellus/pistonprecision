# scripts/ui/DeathCounterAnimation.gd - Version nettoyée
extends Label
class_name DeathCounterAnimation

var target_number: int = 0
var current_number: int = 0
var animation_tween: Tween
var is_animating: bool = false

func animate_to_number(new_number: int, start_from: int = 0):
	"""Lance l'animation depuis start_from vers new_number"""
	if is_animating:
		stop_animation()
	
	current_number = start_from
	target_number = new_number
	is_animating = true
	
	print("DeathCounterAnimation: Animation de %d vers %d" % [current_number, target_number])
	
	var diff = target_number - current_number
	if diff <= 0:
		set_number_instantly(target_number)
		return
	
	_start_counting_animation(diff)

func _start_counting_animation(total_steps: int):
	"""Animation de comptage adaptée à la distance"""
	animation_tween = create_tween()
	
	var current = current_number
	
	# Calcul de délai adaptatif selon le nombre total
	for step in range(total_steps):
		current += 1
		var progress = float(step + 1) / float(total_steps)
		
		# Démarrage rapide puis ralentissement progressif
		var delay = _get_step_delay(progress, total_steps)
		
		animation_tween.tween_callback(_update_display.bind(current))
		animation_tween.tween_interval(delay)
	
	# Finaliser
	animation_tween.tween_callback(_finish_animation)

func _get_step_delay(progress: float, total_steps: int) -> float:
	"""Calcule le délai pour chaque étape selon la progression"""
	var current_step = int(progress * total_steps)
	var remaining_steps = total_steps - current_step
	
	# Ralentissement sur les 5 derniers
	if remaining_steps <= 5:
		match remaining_steps:
			5: return 0.2
			4: return 0.25
			3: return 0.3
			2: return 0.35
			1: return 0.4
			_: return 0.5
	
	# Pour le reste : calculer pour que ça prenne max 2s (3s - 1s pour les 5 derniers)
	var fast_steps = total_steps - 5
	var time_for_fast = 2.0  # 2 secondes pour tout sauf les 5 derniers
	
	return time_for_fast / fast_steps if fast_steps > 0 else 0.01

func _update_display(number: int):
	"""Met à jour l'affichage du nombre"""
	current_number = number
	text = str(number)
	
	AudioManager.play_sfx("ui/counter_tick", 0.2)

func _finish_animation():
	"""Termine l'animation avec effet final"""
	is_animating = false
	current_number = target_number
	text = str(target_number)
	
	print("DeathCounterAnimation: Animation terminée sur %d" % target_number)
	
	# Effet final
	var final_tween = create_tween()
	final_tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	final_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func stop_animation():
	"""Arrête l'animation en cours"""
	if animation_tween:
		animation_tween.kill()
	is_animating = false

func set_number_instantly(number: int):
	"""Définit le nombre sans animation"""
	target_number = number
	current_number = number
	text = str(number)
	is_animating = false

func get_current_number() -> int:
	return target_number

func is_animation_playing() -> bool:
	return is_animating
