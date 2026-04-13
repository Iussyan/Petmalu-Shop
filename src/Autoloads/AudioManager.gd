extends Node

# AudioManager - Global Singleton for BGM and SFX
# Note: You should add this to Project Settings -> Autoload as "AudioManager"

var bgm_player: AudioStreamPlayer
var bgm_tween: Tween

func _ready():
	# Setup BGM Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	bgm_player.process_mode = PROCESS_MODE_ALWAYS
	add_child(bgm_player)
	
	# Setup Audio Buses if they don't exist (Runtime check)
	_ensure_bus_exists("Music")
	_ensure_bus_exists("SFX")

func play_bgm(path: String, fade_duration: float = 1.5):
	if not FileAccess.file_exists(path):
		print("[AudioManager] BGM file not found at: ", path)
		return
		
	if bgm_player.stream and bgm_player.stream.resource_path == path:
		return # Already playing
		
	var new_stream = load(path)
	if not new_stream: return
		
	# Fade out current
	if bgm_player.playing:
		if bgm_tween: bgm_tween.kill()
		bgm_tween = create_tween()
		bgm_tween.tween_property(bgm_player, "volume_db", -80, fade_duration).set_trans(Tween.TRANS_SINE)
		await bgm_tween.finished
		
	bgm_player.stream = new_stream
	bgm_player.volume_db = -80
	bgm_player.play()
	
	# Fade in new
	if bgm_tween: bgm_tween.kill()
	bgm_tween = create_tween()
	bgm_tween.tween_property(bgm_player, "volume_db", 0, fade_duration).set_trans(Tween.TRANS_SINE)

func play_sfx(path: String, volume_db: float = 0.0, pitch: float = 1.0):
	if not FileAccess.file_exists(path): return
	
	var player = AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.bus = "SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _ensure_bus_exists(bus_name: String):
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
