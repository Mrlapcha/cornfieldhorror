extends Control
class_name VirtualJoystick

## Virtual joystick for mobile touch input.
## Outputs a normalized Vector2 direction that gets injected as input events.

@export var dead_zone: float = 0.15
@export var clamp_zone: float = 1.0

@onready var bg: TextureRect = $Background
@onready var knob: TextureRect = $Background/Knob

var _is_pressed: bool = false
var _touch_index: int = -1
var _output: Vector2 = Vector2.ZERO
var _bg_radius: float = 0.0


func _ready() -> void:
	_bg_radius = bg.size.x * 0.5
	knob.pivot_offset = knob.size * 0.5
	_reset_knob()


func get_output() -> Vector2:
	return _output


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _is_within_joystick(touch.position) and not _is_pressed:
				_is_pressed = true
				_touch_index = touch.index
				_update_knob(touch.position)
		elif touch.index == _touch_index:
			_is_pressed = false
			_touch_index = -1
			_output = Vector2.ZERO
			_reset_knob()
			_emit_input_actions(Vector2.ZERO)

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index and _is_pressed:
			_update_knob(drag.position)


func _is_within_joystick(screen_pos: Vector2) -> bool:
	var bg_center := bg.global_position + bg.size * 0.5
	return screen_pos.distance_to(bg_center) <= _bg_radius * 1.5


func _update_knob(screen_pos: Vector2) -> void:
	var bg_center := bg.global_position + bg.size * 0.5
	var diff := screen_pos - bg_center
	var dist := diff.length()
	var max_dist := _bg_radius * clamp_zone

	if dist > max_dist:
		diff = diff.normalized() * max_dist

	# Position knob
	knob.position = diff + bg.size * 0.5 - knob.size * 0.5

	# Calculate output
	var normalized := diff / max_dist
	if normalized.length() < dead_zone:
		_output = Vector2.ZERO
	else:
		_output = normalized

	_emit_input_actions(_output)


func _reset_knob() -> void:
	knob.position = bg.size * 0.5 - knob.size * 0.5


func _emit_input_actions(dir: Vector2) -> void:
	# Inject as action strengths so player_controller picks them up
	_set_action_strength("move_left", max(-dir.x, 0.0))
	_set_action_strength("move_right", max(dir.x, 0.0))
	_set_action_strength("move_forward", max(-dir.y, 0.0))
	_set_action_strength("move_back", max(dir.y, 0.0))


func _set_action_strength(action: String, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength > 0.01:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = true
		ev.strength = strength
		Input.parse_input_event(ev)
	else:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = false
		ev.strength = 0.0
		Input.parse_input_event(ev)
