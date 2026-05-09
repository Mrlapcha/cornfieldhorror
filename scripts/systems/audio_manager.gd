extends Node

## AudioManager — Central audio controller for the horror game.
## Autoloaded as "AudioManager". Uses ONLY real audio assets.

@export var player_group: StringName = &"player"
@export var clown_group: StringName = &"enemy_clown"

# Threat distance thresholds
@export var threat_near_distance: float = 8.0
@export var threat_far_distance: float = 35.0

var _player: Node = null

var _is_ending_active: bool = false
var _fade_out_progress: float = 0.0
var _needs_reset: bool = false

# Real audio stream players
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _frogs_player: AudioStreamPlayer
var _heartbeat_player: AudioStreamPlayer
var _breathing_player: AudioStreamPlayer
var _footstep_player: AudioStreamPlayer
var _sfx_players: Dictionary = {}

# Paths for real audio files
const AUDIO_DIR := "res://assets/audio/"
const SFX_FILES := {
	"pickup": "sfx/pickup_key.wav",
	"pickup_key": "sfx/pickup_key.wav",
	"flashlight_on": "sfx/flashlight_on.wav",
	"flashlight_off": "sfx/flashlight_off.wav",
	"match_strike": "sfx/match_strike.wav",
	"gasp": "sfx/gasp.wav",
	"button_click": "sfx/button_click.wav",
	"collectible_pickup": "sfx/pickup_key.wav" # fallback alias
}
const STINGER_FILES := {
	"alert": "stingers/alert_stinger.wav",
	"chase_start": "stingers/chase_stinger.wav",
	"stinger": "stingers/stinger.wav",
}

# Preload dynamic streams
var _stream_footstep_walk: AudioStream
var _stream_footstep_run: AudioStream
var _stream_breathing_slow: AudioStream
var _stream_breathing_fast: AudioStream


func _ready() -> void:
	_setup_audio_buses()
	_preload_dynamic_streams()
	_create_real_audio_players()
	# Unmute master bus on boot in case previous session was muted
	reset_audio()


func _process(delta: float) -> void:
	if _is_ending_active:
		_process_fade_out(delta)
		return

	var new_player := _find_player()
	# Detect scene reload: player was gone (scene freed) and now exists again
	if new_player and not _player and _needs_reset:
		reset_audio()
	if not new_player:
		_needs_reset = true
	_player = new_player

	if not _player:
		# Pause dynamic sounds if player is dead/missing
		if _footstep_player.playing: _footstep_player.stop()
		if _breathing_player.playing: _breathing_player.stop()
		if _heartbeat_player.playing: _heartbeat_player.stop()
		return

	var threat := _compute_threat_intensity()
	_update_heartbeat(threat)
	_update_breathing()
	_update_footsteps()


# --- Public API ---

func play_sfx(sfx_name: String) -> void:
	if _is_ending_active:
		return

	var path: String = ""
	if SFX_FILES.has(sfx_name):
		path = AUDIO_DIR + SFX_FILES[sfx_name]
	elif STINGER_FILES.has(sfx_name):
		path = AUDIO_DIR + STINGER_FILES[sfx_name]

	if not path.is_empty() and ResourceLoader.exists(path):
		_play_real_sfx(path, sfx_name)
	else:
		print("AudioManager warning: SFX not found: ", sfx_name)


func trigger_ending_fade() -> void:
	_is_ending_active = true
	_fade_out_progress = 0.0


func reset_audio() -> void:
	_is_ending_active = false
	_fade_out_progress = 0.0
	_needs_reset = false

	var master_idx := AudioServer.get_bus_index("Master")
	var profile = SaveManager.load_profile()

	if master_idx >= 0:
		var mute_status = profile.get("is_muted", false)
		AudioServer.set_bus_mute(master_idx, mute_status)
		AudioServer.set_bus_volume_db(master_idx, 0.0)

	var music_val = profile.get("music_vol", 0.5)
	var sfx_val = profile.get("sfx_vol", 0.8)

	for bus in ["Music", "Ambient"]:
		var idx = AudioServer.get_bus_index(bus)
		if idx >= 0: AudioServer.set_bus_volume_db(idx, linear_to_db(music_val))

	for bus in ["SFX", "Voice"]:
		var idx = AudioServer.get_bus_index(bus)
		if idx >= 0: AudioServer.set_bus_volume_db(idx, linear_to_db(sfx_val))

	_start_ambient_loops()

func toggle_mute() -> bool:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx < 0: return false
	var new_mute = !AudioServer.is_bus_mute(master_idx)
	AudioServer.set_bus_mute(master_idx, new_mute)

	var profile = SaveManager.load_profile()
	profile["is_muted"] = new_mute
	SaveManager.save_profile(profile)
	return new_mute

func is_muted() -> bool:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx < 0: return false
	return AudioServer.is_bus_mute(master_idx)

# --- Setup ---

func _setup_audio_buses() -> void:
	_ensure_bus("Ambient")
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("Voice")

	_set_bus_volume("Ambient", -6.0)
	_set_bus_volume("Music", -10.0)
	_set_bus_volume("SFX", -2.0)
	_set_bus_volume("Voice", -3.0)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _set_bus_volume(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)


func _preload_dynamic_streams() -> void:
	_stream_footstep_walk = _load_and_loop_wav("res://assets/audio/sfx/footsteps_walk.wav")
	_stream_footstep_run = _load_and_loop_wav("res://assets/audio/sfx/footsteps_run.wav")
	_stream_breathing_slow = _load_and_loop_wav("res://assets/audio/sfx/breathing_slow.wav")
	_stream_breathing_fast = _load_and_loop_wav("res://assets/audio/sfx/breathing_fast.wav")


func _load_and_loop_wav(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		return stream
	return null


func _create_real_audio_players() -> void:
	# Music
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)

	# Ambient loops
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = "Ambient"
	_ambient_player.volume_db = -4.0
	_ambient_player.finished.connect(func(): if _ambient_player.stream: _ambient_player.play())
	add_child(_ambient_player)
	
	_frogs_player = AudioStreamPlayer.new()
	_frogs_player.name = "FrogsPlayer"
	_frogs_player.bus = "Ambient"
	_frogs_player.volume_db = -8.0
	_frogs_player.finished.connect(func(): if _frogs_player.stream: _frogs_player.play())
	add_child(_frogs_player)

	# Dynamic loops
	_heartbeat_player = AudioStreamPlayer.new()
	_heartbeat_player.name = "HeartbeatPlayer"
	_heartbeat_player.bus = "Voice"
	_heartbeat_player.stream = _load_and_loop_wav("res://assets/audio/sfx/heartbeat.wav")
	_heartbeat_player.finished.connect(func(): if _heartbeat_player.stream: _heartbeat_player.play())
	add_child(_heartbeat_player)
	
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.name = "FootstepPlayer"
	_footstep_player.bus = "SFX"
	add_child(_footstep_player)
	
	_breathing_player = AudioStreamPlayer.new()
	_breathing_player.name = "BreathingPlayer"
	_breathing_player.bus = "Voice"
	add_child(_breathing_player)

	_start_ambient_loops()


func _start_ambient_loops() -> void:
	var music_path := AUDIO_DIR + "music/dark_ambient.ogg"
	if ResourceLoader.exists(music_path):
		var stream: AudioStream = load(music_path)
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		_music_player.stream = stream
		_music_player.play()

	var ambient_path := AUDIO_DIR + "ambient/creepy_ambience.wav"
	if ResourceLoader.exists(ambient_path):
		_ambient_player.stream = _load_and_loop_wav(ambient_path)
		_ambient_player.play()
		
	var frogs_path := AUDIO_DIR + "ambient/frogs.wav"
	if ResourceLoader.exists(frogs_path):
		_frogs_player.stream = _load_and_loop_wav(frogs_path)
		_frogs_player.play()


func _play_real_sfx(path: String, sfx_name: String) -> void:
	var stream: AudioStream = load(path)
	if not stream: return

	var player: AudioStreamPlayer
	if _sfx_players.has(sfx_name) and is_instance_valid(_sfx_players[sfx_name]):
		player = _sfx_players[sfx_name]
	else:
		player = AudioStreamPlayer.new()
		player.name = "SFX_" + sfx_name
		player.bus = "SFX"
		add_child(player)
		_sfx_players[sfx_name] = player

	player.stream = stream
	player.volume_db = 0.0
	player.play()


# --- State Polling ---

func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group(player_group)
	if players.is_empty(): return null
	return players[0]


func _compute_threat_intensity() -> float:
	if not _player or not is_instance_valid(_player):
		return 0.0

	var player_pos: Vector3
	if _player is Node3D:
		player_pos = (_player as Node3D).global_position
	else:
		return 0.0

	var clowns := get_tree().get_nodes_in_group(clown_group)
	var closest_dist: float = 9999.0

	for clown in clowns:
		if not is_instance_valid(clown): continue
		if clown is Node3D:
			closest_dist = minf(closest_dist, player_pos.distance_to((clown as Node3D).global_position))

	if closest_dist >= threat_far_distance: return 0.0
	if closest_dist <= threat_near_distance: return 1.0

	var range_size: float = threat_far_distance - threat_near_distance
	return 1.0 - ((closest_dist - threat_near_distance) / range_size)


func _update_heartbeat(threat: float) -> void:
	if threat < 0.05 or not _heartbeat_player.stream:
		if _heartbeat_player.playing: _heartbeat_player.stop()
		return
		
	if not _heartbeat_player.playing:
		_heartbeat_player.play()
		
	_heartbeat_player.pitch_scale = lerpf(0.8, 1.8, threat)
	_heartbeat_player.volume_db = lerpf(-20.0, 0.0, threat)


func _update_breathing() -> void:
	var stamina_ratio: float = 1.0
	var is_exhausted: bool = false
	
	if _player.has_method("get_stamina_ratio"):
		stamina_ratio = float(_player.call("get_stamina_ratio"))
	if _player.has_method("is_exhausted"):
		is_exhausted = bool(_player.call("is_exhausted"))

	if stamina_ratio > 0.8 and not is_exhausted:
		if _breathing_player.playing: _breathing_player.stop()
		return
		
	var target_stream = _stream_breathing_fast if is_exhausted else _stream_breathing_slow
	
	if _breathing_player.stream != target_stream or not _breathing_player.playing:
		_breathing_player.stream = target_stream
		_breathing_player.play(0.0)
		
	if is_exhausted:
		_breathing_player.volume_db = 0.0
	else:
		_breathing_player.volume_db = lerpf(-15.0, -5.0, 1.0 - (stamina_ratio / 0.8))


func _update_footsteps() -> void:
	var is_moving: bool = false
	var is_sprinting: bool = false
	var is_crouching: bool = false

	if _player is CharacterBody3D:
		var char_body := _player as CharacterBody3D
		var horiz_vel := Vector2(char_body.velocity.x, char_body.velocity.z)
		is_moving = horiz_vel.length() > 0.5 and char_body.is_on_floor()

	if _player.has_method("is_sprinting"): is_sprinting = bool(_player.call("is_sprinting"))
	if _player.has_method("is_crouching"): is_crouching = bool(_player.call("is_crouching"))

	if not is_moving or is_crouching:
		if _footstep_player.playing: _footstep_player.stop()
		return
		
	var target_stream = _stream_footstep_run if is_sprinting else _stream_footstep_walk
	
	if _footstep_player.stream != target_stream or not _footstep_player.playing:
		_footstep_player.stream = target_stream
		_footstep_player.play(0.0)


# --- Ending Fade ---

func _process_fade_out(delta: float) -> void:
	_fade_out_progress = minf(_fade_out_progress + delta * 0.4, 1.0)
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, lerpf(0.0, -40.0, _fade_out_progress))

	if _fade_out_progress >= 1.0:
		if master_idx >= 0: AudioServer.set_bus_mute(master_idx, true)
		if _music_player: _music_player.stop()
		if _ambient_player: _ambient_player.stop()
		if _frogs_player: _frogs_player.stop()
		if _heartbeat_player: _heartbeat_player.stop()
		if _breathing_player: _breathing_player.stop()
		if _footstep_player: _footstep_player.stop()
