# scripts/ui/DeathCounterAnimation.gd - Version corrigée
extends Label
class_name DeathCounterAnimation

var target_number: int = 0
var current_number: int = 0
var animation_tween: Tween
var is_animating: bool = false

func animate_to_number(new_number: int, start_from: int = -1):
	"""Lance l'animation avec ralentissement vers le nouveau nombre"""
	if is_animating:
		stop_animation()
	
	if start_from >= 0:
		current_number = start_from
	
	target_number = new_number
	is_animating = true
	
	print("DeathCounterAnimation: Animation de %d vers %d" % [current_number, target_number])
	
	# ✅ CORRECTION : Pas d'overshoot si la différence est petite
	var diff = target_number - current_number
	if diff <= 0:
		set_number_instantly(target_number)
		return
	
	# ✅ CORRECTION : Overshoot proportionnel et limité
	var overshoot = 0
	if diff > 3:  # Seulement si la différence est > 3
		overshoot = min(5, diff + 2)  # Maximum 5 de overshoot
	
	_start_counting_animation(overshoot)

func _start_counting_animation(overshoot: int):
	"""Animation de comptage avec ralentissement"""
	var max_number = target_number + overshoot
	
	print("DeathCounterAnimation: Comptage de %d à %d puis retour à %d" % [current_number, max_number, target_number])
	
	animation_tween = create_tween()
	
	# Phase 1: Monter rapidement puis ralentir
	var current = current_number
	
	while current < max_number:
		current += 1
		var progress = float(current - current_number) / float(max_number - current_number)
		
		# Ralentissement progressif : début rapide, fin lente
		var delay = 0.02 + (progress * progress * 0.12)  # De 0.02s à 0.14s
		
		animation_tween.tween_callback(_update_display.bind(current))
		animation_tween.tween_interval(delay)
	
	# Phase 2: Si overshoot, redescendre lentement
	if overshoot > 0:
		while current > target_number:
			current -= 1
			animation_tween.tween_callback(_update_display.bind(current))
			animation_tween.tween_interval(0.15)  # Plus lent pour la descente
	
	# Finaliser
	animation_tween.tween_callback(_finish_animation)

func _update_display(number: int):
	"""Met à jour l'affichage du nombre"""
	current_number = number
	text = "DEATHS : " + str(number)
	
	# Petit effet visuel
	_add_number_flash()

func _add_number_flash():
	"""Flash léger à chaque changement"""
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE * 1.2, 0.03)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.03)

func _finish_animation():
	"""Termine l'animation"""
	is_animating = false
	current_number = target_number
	text = "DEATHS : " + str(target_number)
	
	print("DeathCounterAnimation: Animation terminée sur %d" % target_number)
	
	# Effet final
	_add_final_effect()

func _add_final_effect():
	"""Effet final de fin d'animation"""
	var final_tween = create_tween()
	
	# Scale + couleur
	final_tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
	final_tween.parallel().tween_property(self, "modulate", Color.YELLOW, 0.1)
	
	# Retour normal
	final_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	final_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)

func stop_animation():
	"""Arrête l'animation en cours"""
	if animation_tween:
		animation_tween.kill()
	
	is_animating = false
	current_number = target_number
	text = "DEATHS : " + str(target_number)

func set_number_instantly(number: int):
	"""Définit le nombre sans animation"""
	target_number = number
	current_number = number
	text = "DEATHS : " + str(number)
	is_animating = false

func get_current_number() -> int:
	return target_number

func is_animation_playing() -> bool:
	return is_animating
