extends Node

@export var player_path: NodePath = NodePath("../Player")
@export var world_path: NodePath = NodePath("../World")
@export var ending_overlay_path: NodePath = NodePath("../EndingOverlay")

@export_group("Stay Ending")
@export var enable_stay_ending: bool = false
@export var stay_duration_seconds: float = 300.0
@export var stay_movement_threshold: float = 0.14

var _player: Node3D
var _world: Node
var _ending_overlay: CanvasLayer

var _ending_triggered: bool = false
var _stay_timer: float = 0.0
var _last_player_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	if not is_in_group("ending_manager"):
		add_to_group("ending_manager")

	_cache_nodes()
	if _player:
		_last_player_position = _player.global_position


func _process(delta: float) -> void:
	if _ending_triggered:
		return

	if not _player or not is_instance_valid(_player):
		_cache_player()
		if _player:
			_last_player_position = _player.global_position

	if enable_stay_ending:
		_update_stay_ending(delta)


func trigger_escape_ending(_activator: Node = null) -> bool:
	return _trigger_ending(
		"escape",
		"Escape",
		"You unlocked the barn, found the final key, and escaped the cornfield.",
		Color(0.2, 0.74, 0.42, 1.0)
	)


func trigger_well_ending(_activator: Node = null) -> bool:
	return _trigger_ending(
		"well",
		"The Well",
		"The music box sank into the well and a hidden ritual awakened beneath the farm.",
		Color(0.26, 0.52, 0.88, 1.0)
	)


func trigger_caught_ending(_activator: Node = null) -> bool:
	return _trigger_ending(
		"caught",
		"Caught",
		"The clown caught you before dawn. The field falls silent.",
		Color(0.83, 0.18, 0.18, 1.0)
	)


func trigger_burn_ending(_activator: Node = null) -> bool:
	return _trigger_ending(
		"burn",
		"Burn It Down",
		"The cornfield burned to ash. The clown's laughter vanished into smoke.",
		Color(0.95, 0.52, 0.12, 1.0)
	)


func trigger_stay_ending(_activator: Node = null) -> bool:
	return _trigger_ending(
		"stay",
		"Stay",
		"You stood perfectly still for too long. Something in the dark decided to let you stay.",
		Color(0.65, 0.65, 0.68, 1.0)
	)


func is_ending_triggered() -> bool:
	return _ending_triggered


func _trigger_ending(ending_id: String, title: String, description: String, accent_color: Color) -> bool:
	if _ending_triggered:
		return false

	_ending_triggered = true
	_freeze_gameplay()

	# Fade all game audio
	var audio_mgr := get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("trigger_ending_fade"):
		audio_mgr.call("trigger_ending_fade")

	if _ending_overlay and _ending_overlay.has_method("show_ending"):
		_ending_overlay.call("show_ending", ending_id, title, description, accent_color)

	return true


func _cache_nodes() -> void:
	_cache_player()
	_world = get_node_or_null(world_path)
	_ending_overlay = get_node_or_null(ending_overlay_path) as CanvasLayer


func _cache_player() -> void:
	var player_node: Node = get_node_or_null(player_path)
	if player_node is Node3D:
		_player = player_node
		return

	var grouped_players: Array[Node] = get_tree().get_nodes_in_group("player")
	if not grouped_players.is_empty() and grouped_players[0] is Node3D:
		_player = grouped_players[0] as Node3D
		return

	_player = null


func _freeze_gameplay() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if _player and _player.has_method("set_controls_locked"):
		_player.call("set_controls_locked", true)

	var clown_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy_clown")
	for clown_node: Node in clown_nodes:
		clown_node.set_process(false)
		clown_node.set_physics_process(false)


func _update_stay_ending(delta: float) -> void:
	if not _player:
		return

	var movement_distance: float = _player.global_position.distance_to(_last_player_position)
	_last_player_position = _player.global_position

	if movement_distance <= stay_movement_threshold:
		_stay_timer += delta
	else:
		_stay_timer = 0.0

	if _stay_timer >= stay_duration_seconds:
		trigger_stay_ending(_player)
