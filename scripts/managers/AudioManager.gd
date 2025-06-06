extends Node

# === AUDIO PLAYERS POOL ===
var sfx_players_pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var next_pool_index: int = 0  # Index circulaire pour éviter la recherche

# === AUDIO COLLECTIONS ===
var audio_collections: Dictionary = {}

# === SETTINGS ===
var master_volume: float = 1.0
var sfx_volume: float = 0.7
var music_volume: float = 0.5

# === INDIVIDUAL VOLUMES ===
var category_volumes: Dictionary = {}

const POOL_SIZE: int = 20

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

# === SFX PLAYBACK (Optimisé) ===
func play_sfx(category: String, volume_override: float = -1.0, random_selection: bool = true):
	if not audio_collections.has(category) or audio_collections[category].is_empty():
		return
	
	var audio_player = _get_available_player()
	if not audio_player:
		return
	
	# Sélection de l'audio
	var audio_stream
	if random_selection and audio_collections[category].size() > 1:
		audio_stream = audio_collections[category].pick_random()
	else:
		audio_stream = audio_collections[category][0]
	
	audio_player.stream = audio_stream
	
	# Calcul du volume final
	var final_volume = _calculate_final_volume(category, volume_override)
	audio_player.volume_db = linear_to_db(final_volume)
	
	audio_player.play()

func play_multi_sfx(categories: Array[String], volume_override: float = -1.0):
	for category in categories:
		play_sfx(category, volume_override)

# === OPTIMISATION PRINCIPALE ===
func _get_available_player() -> AudioStreamPlayer:
	# Recherche circulaire depuis le dernier index utilisé
	for i in range(POOL_SIZE):
		var index = (next_pool_index + i) % POOL_SIZE
		var audio_player = sfx_players_pool[index]  # ← Renommé pour éviter confusion
		
		# Si le player n'est pas en train de jouer, on l'utilise
		if not audio_player.playing:
			next_pool_index = (index + 1) % POOL_SIZE
			return audio_player
	
	# Si tous sont occupés, écraser le plus ancien (round-robin)
	var fallback_player = sfx_players_pool[next_pool_index]  # ← Nom distinct
	next_pool_index = (next_pool_index + 1) % POOL_SIZE
	return fallback_player

func _calculate_final_volume(category: String, volume_override: float) -> float:
	var category_vol = category_volumes.get(category, 1.0)
	var final_volume = sfx_volume * category_vol
	
	if volume_override >= 0:
		final_volume = volume_override
	
	return final_volume * master_volume

# === MUSIC ===
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

# === VOLUME ===
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

# === UTILITIES ===
func stop_all_sfx():
	for player in sfx_players_pool:
		if player.playing:
			player.stop()

# === DEBUG ===
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
