# Version simplifiée avec Time.get_ticks_msec()
extends Node

# === AUDIO PLAYERS POOL ===
var sfx_players_pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var next_pool_index: int = 0

# === AUDIO COLLECTIONS ===
var audio_collections: Dictionary = {}

# === SETTINGS ===
var master_volume: float = 1.0
var sfx_volume: float = 0.7
var music_volume: float = 0.5
var category_volumes: Dictionary = {}

# === COOLDOWN SYSTEM SIMPLIFIÉ ===
var sound_cooldowns: Dictionary = {}  # "category" -> timestamp en ms
const DEFAULT_COOLDOWN_MS: int = 100  # 100ms par défaut

const POOL_SIZE: int = 20

func play_sfx(category: String, volume_override: float = -1.0, random_selection: bool = true, cooldown_ms: int = -1):
	# Vérification du cooldown
	if _is_on_cooldown(category, cooldown_ms):
		return
	
	# Vérification rapide
	if not audio_collections.has(category):
		return
	
	var sounds = audio_collections[category]
	if sounds.is_empty():
		return
	
	var audio_player = _get_available_player()
	
	# Sélection de l'audio
	audio_player.stream = sounds.pick_random() if random_selection and sounds.size() > 1 else sounds[0]
	
	# Volume final
	var final_volume = (volume_override if volume_override >= 0 else sfx_volume * category_volumes.get(category, 1.0)) * master_volume
	audio_player.volume_db = linear_to_db(final_volume)
	
	audio_player.play()
	
	# Enregistrer le cooldown
	_set_cooldown(category)

func _is_on_cooldown(category: String, custom_cooldown_ms: int) -> bool:
	"""Vérifie si le son est en cooldown"""
	if not sound_cooldowns.has(category):
		return false
	
	var current_time = Time.get_ticks_msec()
	var last_played = sound_cooldowns[category]
	var cooldown_duration = custom_cooldown_ms if custom_cooldown_ms > 0 else DEFAULT_COOLDOWN_MS
	
	return (current_time - last_played) < cooldown_duration

func _set_cooldown(category: String):
	"""Enregistre le timestamp du son joué"""
	sound_cooldowns[category] = Time.get_ticks_msec()

# === MÉTHODE PRATIQUE POUR LES SONS CRITIQUES ===
func play_sfx_with_cooldown(category: String, cooldown_ms: int, volume_override: float = -1.0):
	"""Version explicite avec cooldown personnalisé"""
	play_sfx(category, volume_override, true, cooldown_ms)

# === RESTE DU CODE INCHANGÉ ===
func _ready():
	name = "AudioManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_audio_pool()
	_create_music_player()
	_scan_audio_folders()

func _create_audio_pool():
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		add_child(player)
		sfx_players_pool.append(player)

func _create_music_player():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

func _scan_audio_folders():
	_scan_directory("res://audio/sfx/", "")

func _scan_directory(path: String, category_path: String):
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + file_name
		
		if dir.current_is_dir():
			var new_category = category_path + "/" + file_name if category_path != "" else file_name
			_scan_directory(full_path + "/", new_category)
		else:
			if _is_audio_file(file_name):
				_add_to_collection(category_path, full_path)
		
		file_name = dir.get_next()

func _is_audio_file(file_name: String) -> bool:
	var extensions = [".ogg", ".wav", ".mp3"]
	return extensions.any(func(ext): return file_name.ends_with(ext))

func _add_to_collection(category: String, file_path: String):
	if category == "":
		return
	
	if not audio_collections.has(category):
		audio_collections[category] = []
		category_volumes[category] = 1.0
	
	var stream = load(file_path)
	if stream:
		audio_collections[category].append(stream)

func _get_available_player() -> AudioStreamPlayer:
	var audio_player = sfx_players_pool[next_pool_index]
	next_pool_index = (next_pool_index + 1) % POOL_SIZE
	
	if audio_player.playing:
		audio_player.stop()
	
	return audio_player

# === AUTRES MÉTHODES ===
func play_multi_sfx(categories: Array[String], volume_override: float = -1.0):
	for category in categories:
		play_sfx(category, volume_override)

func play_music(music_name: String):
	var base_path = "res://audio/music/" + music_name
	var extensions = [".ogg", ".wav", ".mp3"]
	
	for ext in extensions:
		if ResourceLoader.exists(base_path + ext):
			music_player.stream = load(base_path + ext)
			music_player.volume_db = linear_to_db(music_volume * master_volume)
			music_player.play()
			return

func stop_music():
	music_player.stop()

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)

func set_category_volume(category: String, volume: float):
	category_volumes[category] = clamp(volume, 0.0, 1.0)

func get_category_volume(category: String) -> float:
	return category_volumes.get(category, 1.0)

func stop_all_sfx():
	for player in sfx_players_pool:
		if player.playing:
			player.stop()

func get_pool_status() -> Dictionary:
	var active_count = 0
	for player in sfx_players_pool:
		if player.playing:
			active_count += 1
	
	return {
		"total": POOL_SIZE,
		"active": active_count,
		"available": POOL_SIZE - active_count,
		"next_index": next_pool_index
	}
