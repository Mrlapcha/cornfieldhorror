extends CanvasLayer

@export_group("Detection")
@export var player_group_name: StringName = &"player"
@export var clown_group_name: StringName = &"enemy_clown"
@export var max_heartbeat_distance: float = 34.0

@export_group("Pulse")
@export var min_bpm: float = 52.0
@export var max_bpm: float = 136.0
@export var pulse_sharpness: float = 5.0
@export var max_pulse_intensity: float = 0.42
@export var pulse_tint: Color = Color(0.76, 0.08, 0.08, 1.0)
@export var intensity_smoothing: float = 4.4

@export_group("Vignette")
@export var min_inner_radius: float = 0.28
@export var max_inner_radius: float = 0.55
@export var outer_radius: float = 1.0
@export var softness: float = 0.55

@export_group("Player Pressure")
@export var breathing_influence: float = 0.24

@onready var pulse_rect: TextureRect = $PulseRect

var _player: Node3D
var _heartbeat_phase: float = 0.0
var _display_intensity: float = 0.0
var _shader_material: ShaderMaterial


func _ready() -> void:
	pulse_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_material = pulse_rect.material as ShaderMaterial
	if _shader_material:
		_shader_material.set_shader_parameter("vignette_color", Vector4(pulse_tint.r, pulse_tint.g, pulse_tint.b, 1.0))
		_shader_material.set_shader_parameter("intensity", 0.0)
		_shader_material.set_shader_parameter("inner_radius", max_inner_radius)
		_shader_material.set_shader_parameter("outer_radius", outer_radius)
		_shader_material.set_shader_parameter("softness", softness)


func _process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_player = _find_player()

	var threat_intensity := _compute_threat_intensity()
	var breathing_pressure := _compute_breathing_pressure()
	var target_intensity: float = clampf(threat_intensity + (breathing_pressure * breathing_influence), 0.0, 1.0)

	_display_intensity = move_toward(_display_intensity, target_intensity, intensity_smoothing * delta)

	if not _shader_material:
		return

	if _display_intensity <= 0.01:
		_shader_material.set_shader_parameter("intensity", 0.0)
		return

	var bpm: float = lerpf(min_bpm, max_bpm, _display_intensity)
	_heartbeat_phase = wrapf(_heartbeat_phase + delta * ((bpm / 60.0) * TAU), 0.0, TAU)

	var beat: float = float(pow(maxf(0.0, sin(_heartbeat_phase)), pulse_sharpness))
	var pulse_alpha: float = beat * _display_intensity * max_pulse_intensity

	# Vignette inner radius shrinks as intensity rises (edges creep inward)
	var current_inner: float = lerpf(max_inner_radius, min_inner_radius, _display_intensity)

	_shader_material.set_shader_parameter("intensity", pulse_alpha)
	_shader_material.set_shader_parameter("inner_radius", current_inner)


func _compute_threat_intensity() -> float:
	if not _player:
		return 0.0

	var nearest_distance: float = INF
	var clown_nodes: Array[Node] = get_tree().get_nodes_in_group(clown_group_name)
	for clown_node: Node in clown_nodes:
		if clown_node is Node3D:
			var clown := clown_node as Node3D
			var distance := _player.global_position.distance_to(clown.global_position)
			if distance < nearest_distance:
				nearest_distance = distance

	if nearest_distance == INF:
		return 0.0

	return clampf(1.0 - (nearest_distance / max_heartbeat_distance), 0.0, 1.0)


func _compute_breathing_pressure() -> float:
	if not _player:
		return 0.0

	if _player.has_method("get_breathing_intensity"):
		var breathing_intensity := float(_player.call("get_breathing_intensity"))
		return clampf(breathing_intensity, 0.0, 1.0)

	if _player.has_method("get_stamina_ratio"):
		var stamina_ratio := float(_player.call("get_stamina_ratio"))
		return clampf(1.0 - stamina_ratio, 0.0, 1.0)

	return 0.0


func _find_player() -> Node3D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)
	if players.is_empty():
		return null

	if players[0] is Node3D:
		return players[0] as Node3D

	return null
