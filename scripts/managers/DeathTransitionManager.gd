extends CanvasLayer
class_name DeathTransitionManager

var transition_rect: ColorRect
var tween: Tween

signal transition_middle_reached
signal transition_complete

func _ready():
	name = "DeathTransitionManager"
	layer = 100  # Au-dessus de tout
	
	# Chercher le TransitionRect existant OU le créer
	transition_rect = get_node_or_null("TransitionRect")
	
	if not transition_rect:
		# Créer le ColorRect si il n'existe pas
		transition_rect = ColorRect.new()
		transition_rect.name = "TransitionRect"
		transition_rect.color = Color.BLACK
		transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(transition_rect)
	
	# S'assurer qu'il est invisible au début
	transition_rect.modulate.a = 0.0

func start_death_transition(duration: float = 1.5, delay_before_fade: float = 0.6):
	"""Lance la transition de mort complète"""
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	# Phase 1: DÉLAI pour voir les effets de mort (0.6s par défaut)
	tween.tween_interval(delay_before_fade)
	
	# Phase 2: Fade to black (0.4s)
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.4)
	
	# Phase 3: Signal au milieu + attendre au noir
	tween.tween_callback(_emit_middle_signal)
	tween.tween_interval(duration - delay_before_fade - 0.8)  # Temps au noir ajusté
	
	# Phase 4: Fade from black (0.4s)
	tween.tween_property(transition_rect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_emit_complete_signal)

func _emit_middle_signal():
	"""Signal émis au milieu de la transition (respawn moment)"""
	transition_middle_reached.emit()

func _emit_complete_signal():
	"""Signal émis à la fin de la transition"""
	transition_complete.emit()

func instant_black():
	"""Met l'écran en noir instantanément"""
	if tween:
		tween.kill()
	transition_rect.modulate.a = 1.0

func instant_clear():
	"""Retire le noir instantanément"""
	if tween:
		tween.kill()
	transition_rect.modulate.a = 0.0

# === TRANSITIONS RAPIDES POUR TESTS ===
func quick_death_transition():
	"""Version rapide pour debug"""
	start_death_transition(1.0, 0.3)  # Délai réduit

func slow_death_transition():
	"""Version lente/cinématique"""
	start_death_transition(2.5, 0.8)  # Délai plus long pour voir les effets

func start_death_transition_immediate():
	"""Version sans délai (ancien comportement)"""
	start_death_transition(1.5, 0.0)
