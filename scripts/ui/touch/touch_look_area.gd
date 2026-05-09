extends Control
class_name TouchLookArea

## Invisible area on the right side of the screen for camera look control.
## Drag on this area to rotate the camera, similar to mouse look.

@export var sensitivity: float = 0.3
@export var max_look_speed: float = 5.0

var _touch_index: int = -1
var _is_looking: bool = false


func _ready() -> void:
	# Make this area transparent and fill right half of screen
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# Only accept touches on the right side of the screen
			if _is_in_look_area(touch.position) and not _is_looking:
				_is_looking = true
				_touch_index = touch.index
		elif touch.index == _touch_index:
			_is_looking = false
			_touch_index = -1

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index and _is_looking:
			_inject_mouse_motion(drag.relative)


func _is_in_look_area(screen_pos: Vector2) -> bool:
	# Accept touches on the right 60% of the screen, but not on buttons
	var viewport_size := get_viewport().get_visible_rect().size
	return screen_pos.x > viewport_size.x * 0.35


func _inject_mouse_motion(relative: Vector2) -> void:
	# Clamp to avoid extreme movements
	relative = relative.clampf(-max_look_speed, max_look_speed)

	# Create a fake mouse motion event so the player controller's
	# existing mouse look code handles it
	var motion := InputEventMouseMotion.new()
	motion.relative = relative * sensitivity
	Input.parse_input_event(motion)
