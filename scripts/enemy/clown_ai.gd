extends CharacterBody3D

enum State {
	PATROL,
	ALERT,
	CHASE,
}

@export_group("Movement")
@export var patrol_speed: float = 2.3
@export var alert_speed: float = 3.1
@export var chase_speed: float = 5.2
@export var acceleration: float = 9.0
@export var stop_distance: float = 0.85
@export var turn_speed: float = 5.5
@export var obstacle_probe_distance: float = 1.25
@export var stuck_repath_delay: float = 0.8

@export_group("Perception")
@export var hearing_base_range: float = 6.0
@export var hearing_noise_multiplier: float = 14.0
@export var sight_range: float = 28.0
@export var sight_fov_degrees: float = 78.0
@export var forget_player_after: float = 4.0

@export_group("State Timings")
@export var patrol_wait_at_point: float = 1.2
@export var alert_duration: float = 3.2

@export_group("Capture")
@export var catch_distance: float = 1.3

@export_group("Glitch Teleport")
@export var glitch_enabled: bool = true
@export var glitch_interval_min: float = 3.4
@export var glitch_interval_max: float = 6.3
@export var glitch_distance_min: float = 1.8
@export var glitch_distance_max: float = 4.8
@export var glitch_attempts: int = 8
@export var glitch_min_player_distance: float = 8.0 # Increased to stop him going through player
@export var glitch_stuck_threshold: float = 1.5 # Only glitch if stuck for 1.5s

@export_group("References")
@export var patrol_points_root_path: NodePath
@export var player_path: NodePath
@export var model_animation_player_path: NodePath = NodePath("VisualRoot/HarlequinnModel/AnimationPlayer")

@export_group("Animation Assets")
@export var idle_animation_path: String = "res://assets/models/clown/animations/clown_idle.fbx"
@export var walk_animation_path: String = "res://assets/models/clown/animations/clown_walk.fbx"
@export var alert_walk_animation_path: String = "res://assets/models/clown/animations/clown_walk_creepy.fbx"
@export var run_animation_path: String = "res://assets/models/clown/animations/clown_run.fbx"

@onready var sight_origin: Node3D = $SightOrigin
@onready var _animation_player: AnimationPlayer = get_node_or_null(model_animation_player_path) as AnimationPlayer

var state: State = State.PATROL
var state_name: String = "PATROL"
var _current_animation_name: StringName = &""
var _animation_library: AnimationLibrary

var _player: Node3D
var _patrol_points: Array[Marker3D] = []
var _patrol_index: int = -1
var _patrol_wait_timer: float = 0.0
var _alert_timer: float = 0.0
var _alert_target_position: Vector3 = Vector3.ZERO
var _last_known_player_position: Vector3 = Vector3.ZERO
var _lost_player_timer: float = 0.0
var _has_line_of_sight: bool = false
var _next_glitch_time: float = 0.0
var _rng := RandomNumberGenerator.new()
var _has_caught_player: bool = false
var _stuck_timer: float = 0.0


func _ready() -> void:
	_rng.randomize()
	if not is_in_group("enemy_clown"):
		add_to_group("enemy_clown")
	_cache_patrol_points()
	_player = _find_player()
	_setup_animations()
	_snap_to_floor()
	_set_state(State.PATROL)
	_advance_patrol_point()
	_schedule_next_glitch()



func _physics_process(delta: float) -> void:
	if _has_caught_player:
		velocity = Vector3.ZERO
		return

	if not _player or not is_instance_valid(_player):
		_player = _find_player()

	_has_line_of_sight = _can_see_player()
	var heard_player := _can_hear_player()

	_update_state(delta, heard_player)
	_update_movement(delta)
	_update_animation()
	_update_glitch()

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	_check_for_player_capture()


func _update_state(delta: float, heard_player: bool) -> void:
	match state:
		State.PATROL:
			if _has_line_of_sight:
				_enter_chase()
				return

			if heard_player and _player:
				_alert_target_position = _player.global_position
				_set_state(State.ALERT)
				_alert_timer = alert_duration
				return

			if _reached_current_patrol_point():
				if _patrol_wait_timer <= 0.0:
					_patrol_wait_timer = patrol_wait_at_point
				else:
					_patrol_wait_timer -= delta
					if _patrol_wait_timer <= 0.0:
						_advance_patrol_point()

		State.ALERT:
			if _has_line_of_sight:
				_enter_chase()
				return

			if heard_player and _player:
				_alert_target_position = _player.global_position
				_alert_timer = alert_duration

			_alert_timer -= delta
			if _alert_timer <= 0.0:
				_set_state(State.PATROL)
				_patrol_wait_timer = 0.0

		State.CHASE:
			if _has_line_of_sight and _player:
				_last_known_player_position = _player.global_position
				_lost_player_timer = forget_player_after
			else:
				_lost_player_timer -= delta
				if _lost_player_timer <= 0.0:
					_set_state(State.ALERT)
					_alert_target_position = _last_known_player_position
					_alert_timer = alert_duration


func _update_movement(delta: float) -> void:
	var target_position := _get_target_position()
	target_position.y = global_position.y

	var to_target := target_position - global_position
	to_target.y = 0.0

	if to_target.length() <= stop_distance:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		_stuck_timer = 0.0
		return

	var direction := to_target.normalized()
	if _is_path_blocked(direction):
		_stuck_timer += delta
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

		if state == State.PATROL and _stuck_timer >= stuck_repath_delay:
			_advance_patrol_point()
			_stuck_timer = 0.0
		return

	_stuck_timer = 0.0
	var desired_velocity := direction * _get_target_speed()

	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)

	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(turn_speed * delta, 0.0, 1.0))


func _get_target_speed() -> float:
	match state:
		State.PATROL:
			return patrol_speed
		State.ALERT:
			return alert_speed
		State.CHASE:
			return chase_speed
	return patrol_speed


func _get_target_position() -> Vector3:
	match state:
		State.PATROL:
			if _patrol_points.is_empty() or _patrol_index < 0:
				return global_position
			return _patrol_points[_patrol_index].global_position
		State.ALERT:
			return _alert_target_position
		State.CHASE:
			if _has_line_of_sight and _player:
				return _player.global_position
			return _last_known_player_position
	return global_position


func _reached_current_patrol_point() -> bool:
	if _patrol_points.is_empty() or _patrol_index < 0:
		return false

	var target := _patrol_points[_patrol_index].global_position
	target.y = global_position.y
	return global_position.distance_to(target) <= stop_distance + 0.2


func _advance_patrol_point() -> void:
	if _patrol_points.is_empty():
		return
	_patrol_index = (_patrol_index + 1) % _patrol_points.size()
	_patrol_wait_timer = patrol_wait_at_point


func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state
	match state:
		State.PATROL:
			state_name = "PATROL"
		State.ALERT:
			state_name = "ALERT"
			_play_audio_sfx("alert")
		State.CHASE:
			state_name = "CHASE"
			_play_audio_sfx("chase_start")


func _enter_chase() -> void:
	if not _player:
		return
	_set_state(State.CHASE)
	_last_known_player_position = _player.global_position
	_lost_player_timer = forget_player_after
	_schedule_next_glitch()


func _play_audio_sfx(sfx_name: String) -> void:
	var audio_mgr := get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", sfx_name)


func _can_hear_player() -> bool:
	if not _player:
		return false

	var noise_level := _get_player_noise_level()
	if noise_level <= 0.05:
		return false

	var hearing_range := hearing_base_range + (noise_level * hearing_noise_multiplier)
	return global_position.distance_to(_player.global_position) <= hearing_range


func _get_player_noise_level() -> float:
	if not _player:
		return 0.0

	if _player.has_method("get_noise_level"):
		return float(_player.call("get_noise_level"))

	var fallback_value: Variant = _player.get("current_noise_level")
	if typeof(fallback_value) == TYPE_FLOAT or typeof(fallback_value) == TYPE_INT:
		return float(fallback_value)

	return 0.0


func _can_see_player() -> bool:
	if not _player:
		return false

	var from := sight_origin.global_position
	var to := _player.global_position + Vector3.UP * 1.2
	var to_player := to - from
	var distance := to_player.length()

	var current_sight_range := sight_range
	if distance > current_sight_range:
		return false

	var forward := -global_transform.basis.z
	var direction := to_player.normalized()
	var min_dot := cos(deg_to_rad(sight_fov_degrees * 0.5))

	if forward.dot(direction) < min_dot:
		return false

	var ray := PhysicsRayQueryParameters3D.create(from, to)
	ray.exclude = [self]
	ray.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)

	if hit.is_empty():
		return true

	var collider: Variant = hit.get("collider")
	if collider == _player:
		return true
	if collider is Node and _player.is_ancestor_of(collider):
		return true

	return false


func _update_glitch() -> void:
	if not glitch_enabled:
		return
	if state != State.CHASE:
		return
	if _has_caught_player:
		return
	if _player and global_position.distance_to(_player.global_position) <= glitch_min_player_distance:
		return

	var now := Time.get_ticks_msec() * 0.001
	if now < _next_glitch_time:
		return

	_attempt_glitch_teleport()
	_schedule_next_glitch()


func _schedule_next_glitch() -> void:
	var now := Time.get_ticks_msec() * 0.001
	_next_glitch_time = now + _rng.randf_range(glitch_interval_min, glitch_interval_max)


func _attempt_glitch_teleport() -> void:
	var origin := global_position
	for _attempt in glitch_attempts:
		var angle := _rng.randf_range(0.0, TAU)
		var distance := _rng.randf_range(glitch_distance_min, glitch_distance_max)
		var candidate := origin + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		if _position_is_valid(candidate):
			global_position = Vector3(candidate.x, origin.y, candidate.z)
			return


func _position_is_valid(candidate: Vector3) -> bool:
	if not _has_ground(candidate):
		return false

	var shape := SphereShape3D.new()
	shape.radius = 0.55

	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = shape
	shape_query.transform = Transform3D(Basis.IDENTITY, candidate + Vector3.UP * 1.0)
	shape_query.exclude = [self]
	shape_query.collide_with_areas = false

	var collisions := get_world_3d().direct_space_state.intersect_shape(shape_query, 1)
	return collisions.is_empty()


func _is_path_blocked(direction: Vector3) -> bool:
	if direction.length() <= 0.001:
		return false

	var from := global_position + Vector3.UP * 1.0
	var to := from + direction.normalized() * obstacle_probe_distance
	var ray := PhysicsRayQueryParameters3D.create(from, to)
	ray.exclude = [self]
	ray.collide_with_areas = false
	return not get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _has_ground(candidate: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 2.0, candidate + Vector3.DOWN * 3.0)
	ray.exclude = [self]
	ray.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty()


func _snap_to_floor() -> void:
	var ray := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 2.0,
		global_position + Vector3.DOWN * 5.0)
	ray.exclude = [self]
	ray.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var floor_y: float = hit.position.y
		# Clown character body is 1.6 units tall; snap so feet land on floor
		global_position.y = floor_y


func _cache_patrol_points() -> void:
	_patrol_points.clear()

	var root: Node = null
	if patrol_points_root_path != NodePath(""):
		root = get_node_or_null(patrol_points_root_path)

	if not root:
		root = get_tree().current_scene.get_node_or_null("World/ClownPatrolPoints")

	if not root:
		return

	for child in root.get_children():
		if child is Marker3D:
			_patrol_points.append(child)


func _find_player() -> Node3D:
	if player_path != NodePath(""):
		var explicit_player := get_node_or_null(player_path)
		if explicit_player is Node3D:
			return explicit_player

	var grouped_players := get_tree().get_nodes_in_group("player")
	if not grouped_players.is_empty() and grouped_players[0] is Node3D:
		return grouped_players[0]

	var current_scene := get_tree().current_scene
	if current_scene:
		var fallback_player := current_scene.find_child("Player", true, false)
		if fallback_player is Node3D:
			return fallback_player

	return null


func _check_for_player_capture() -> void:
	if _has_caught_player:
		return
	if state != State.CHASE:
		return
	if not _player:
		return

	var distance_to_player: float = global_position.distance_to(_player.global_position)
	if distance_to_player > catch_distance:
		return

	_has_caught_player = true
	_freeze_after_catch()
	_request_caught_ending()


func _request_caught_ending() -> void:
	var managers: Array[Node] = get_tree().get_nodes_in_group("ending_manager")
	if managers.is_empty():
		return

	var manager: Node = managers[0]
	if manager.has_method("trigger_caught_ending"):
		manager.call("trigger_caught_ending", _player)


func _freeze_after_catch() -> void:
	velocity = Vector3.ZERO
	set_process(false)
	set_physics_process(false)
	if _animation_player:
		_animation_player.stop()


func _setup_animations() -> void:
	if not _animation_player:
		return

	if _animation_player.has_animation_library(&""):
		_animation_player.remove_animation_library(&"")

	_animation_library = AnimationLibrary.new()
	_register_animation_from_scene("idle", idle_animation_path)
	_register_animation_from_scene("walk", walk_animation_path)
	_register_animation_from_scene("alert_walk", alert_walk_animation_path)
	_register_animation_from_scene("run", run_animation_path)
	_animation_player.add_animation_library(&"", _animation_library)

	if _animation_player.has_animation("mixamo_com"):
		_animation_player.stop()


func _register_animation_from_scene(anim_name: StringName, scene_path: String) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path) or not _animation_player:
		return

	var packed := load(scene_path) as PackedScene
	if not packed:
		return

	var inst := packed.instantiate()
	var source_player := inst.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not source_player or not source_player.has_animation("mixamo_com"):
		inst.free()
		return

	var source_animation := source_player.get_animation("mixamo_com")
	if not source_animation:
		inst.free()
		return

	var cloned_animation := source_animation.duplicate(true) as Animation
	cloned_animation.loop_mode = Animation.LOOP_LINEAR
	_animation_library.add_animation(anim_name, cloned_animation)
	inst.free()


func _update_animation() -> void:
	if not _animation_player:
		return

	var next_animation: StringName = &"idle"

	match state:
		State.PATROL:
			if _velocity_is_moving():
				next_animation = &"walk"
		State.ALERT:
			next_animation = &"alert_walk"
		State.CHASE:
			next_animation = &"run"

	if next_animation == _current_animation_name:
		return

	_current_animation_name = next_animation
	if _animation_player.has_animation(next_animation):
		_animation_player.play(next_animation, 0.15)


func _velocity_is_moving() -> bool:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	return horizontal_speed > 0.15
