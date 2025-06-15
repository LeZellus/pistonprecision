# scripts/ui/DeathCounterAnimation.gd - Version simplifiée
extends Label
class_name DeathCounterAnimation

var target_value: int = 0
var current_value: int = 0
var is_animating: bool = false

func animate_to(new_value: int):
	"""Lance l'animation vers le nouveau nombre"""
	if is_animating:
		_stop_animation()
	
	target_value = new_value
	is_animating = true
	
	var tween = create_tween()
	var duration = min(1.0, target_value * 0.05)  # Max 1 seconde
	
	tween.tween_method(_update_display, current_value, target_value, duration)
	tween.tween_callback(_on_animation_complete)

func set_number_instantly(value: int):
	"""Met le nombre instantanément sans animation"""
	current_value = value
	target_value = value
	text = str(value)
	is_animating = false

func animate_to_number(new_value: int, start_from: int = 0):
	"""Méthode de compatibilité avec l'ancien code"""
	current_value = start_from
	text = str(start_from)
	animate_to(new_value)

func animate_to_number_with_custom_timing(final_count: int, start_from: int, fast_phase_time: float):
	"""Nouvelle méthode pour animation personnalisée avec timing rapide"""
	if is_animating:
		_stop_animation()
	
	current_value = start_from
	target_value = final_count
	is_animating = true
	
	# Animation simple mais rapide
	var tween = create_tween()
	var total_duration = fast_phase_time + 1.0  # Phase rapide + ralentissement
	
	tween.tween_method(_update_display, current_value, target_value, total_duration)
	tween.tween_callback(_on_animation_complete)

func is_animation_playing() -> bool:
	return is_animating

func stop_animation():
	"""Arrête l'animation en cours (alias pour _stop_animation)"""
	_stop_animation()

func _update_display(value: int):
	"""Met à jour l'affichage pendant l'animation"""
	current_value = int(value)
	text = str(current_value)
	
	# Son léger tous les 5 nombres
	if current_value % 5 == 0:
		AudioManager.play_sfx("ui/counter_tick", 0.1)

func _on_animation_complete():
	"""Appelé à la fin de l'animation"""
	is_animating = false
	current_value = target_value
	text = str(target_value)
	
	# Petit effet de fin
	var bounce_tween = create_tween()
	bounce_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	bounce_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _stop_animation():
	"""Arrête l'animation en cours"""
	var tweens = get_tree().get_tween_instances()
	for tween in tweens:
		if tween.is_valid():
			tween.kill()
	is_animating = false
