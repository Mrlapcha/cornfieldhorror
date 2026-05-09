extends CanvasLayer

## TouchControlOverlay — virtual joystick + action buttons for touch devices.

@onready var safe_area: Control = $SafeArea
@onready var joystick_container: Control = $SafeArea/JoystickContainer
@onready var sprint_btn: TextureButton = $SafeArea/SprintBtn
@onready var interact_btn: TextureButton = $SafeArea/InteractBtn
@onready var flashlight_btn: TextureButton = $SafeArea/FlashlightBtn
@onready var pause_btn: TextureButton = $SafeArea/PauseBtn
@onready var touch_look: TouchLookArea = $SafeArea/TouchLookArea

var _using_touch: bool = false
var _sprint_held: bool = false

var _sprint_touch_index: int = -1

func _ready() -> void:
	layer = 12
	_using_touch = _is_mobile_platform()
	_set_controls_visible(_using_touch)
	# We rely on manual _input checks for touch to fix multi-touch bugs with TextureButton
	# but we still connect signals for mouse testing if needed on PC.
	if not _using_touch:
		sprint_btn.button_down.connect(_on_sprint_pressed)
		sprint_btn.button_up.connect(_on_sprint_released)
		interact_btn.pressed.connect(_on_interact_pressed)
		flashlight_btn.pressed.connect(_on_flashlight_pressed)
		pause_btn.pressed.connect(_on_pause_pressed)


func _process(_delta: float) -> void:
	if _using_touch:
		_update_interact_visibility()


func _input(event: InputEvent) -> void:
	if _is_mobile_platform():
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed:
				if _is_point_in_control(touch.position, sprint_btn):
					_sprint_touch_index = touch.index
					_on_sprint_pressed()
					sprint_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
				elif _is_point_in_control(touch.position, interact_btn):
					_on_interact_pressed()
					interact_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
				elif _is_point_in_control(touch.position, flashlight_btn):
					_on_flashlight_pressed()
					flashlight_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
				elif _is_point_in_control(touch.position, pause_btn):
					_on_pause_pressed()
					pause_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
			else:
				if touch.index == _sprint_touch_index:
					_sprint_touch_index = -1
					_on_sprint_released()
					sprint_btn.modulate = Color(1.0, 1.0, 1.0, 0.65)
				
				# Reset visual state on release anywhere for tap buttons
				if interact_btn.modulate != Color(1.0, 1.0, 1.0, 1.0): # It uses alpha 0.25/0.85 normally, handled in process
					pass 
				flashlight_btn.modulate = Color(1, 1, 1, 0.65)
				pause_btn.modulate = Color(1, 1, 1, 0.65)
		return # Stop execution here for mobile

	# Desktop fallback visibility logic
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not _using_touch:
			_using_touch = true
			_set_controls_visible(true)
	elif event is InputEventKey or event is InputEventMouseButton:
		if _using_touch:
			_using_touch = false
			_set_controls_visible(false)


func _is_point_in_control(point: Vector2, control: Control) -> bool:
	if not control or not control.visible:
		return false
	var rect := control.get_global_rect()
	# Expand hit area slightly for fat fingers
	rect = rect.grow(20.0)
	return rect.has_point(point)


func _set_controls_visible(should_show: bool) -> void:
	safe_area.visible = should_show


func _is_mobile_platform() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


func _update_interact_visibility() -> void:
	var player := _find_player()
	if not player:
		interact_btn.modulate.a = 0.25
		return
	var ray: RayCast3D = null
	if player.has_method("get_node_or_null"):
		ray = player.get_node_or_null("Head/Camera3D/InteractionRay") as RayCast3D
	if ray and ray.is_colliding():
		var collider := ray.get_collider()
		if collider and collider is Node and collider.has_method("get_interact_prompt"):
			interact_btn.modulate.a = 0.85
			return
	interact_btn.modulate.a = 0.25


func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0]


func _on_sprint_pressed() -> void:
	_sprint_held = true
	var ev := InputEventAction.new()
	ev.action = "sprint"
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)


func _on_sprint_released() -> void:
	_sprint_held = false
	var ev := InputEventAction.new()
	ev.action = "sprint"
	ev.pressed = false
	ev.strength = 0.0
	Input.parse_input_event(ev)


func _on_interact_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.1).timeout
	var ev_release := InputEventAction.new()
	ev_release.action = "interact"
	ev_release.pressed = false
	Input.parse_input_event(ev_release)


func _on_flashlight_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = "flashlight_toggle"
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.1).timeout
	var ev_release := InputEventAction.new()
	ev_release.action = "flashlight_toggle"
	ev_release.pressed = false
	Input.parse_input_event(ev_release)


func _on_pause_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	
	# Release it immediately
	await get_tree().create_timer(0.1).timeout
	var ev_release := InputEventAction.new()
	ev_release.action = "ui_cancel"
	ev_release.pressed = false
	Input.parse_input_event(ev_release)
