extends CharacterBody3D

signal status_message_requested(message: String, duration: float)

@export_group("Movement")
@export var walk_speed: float = 3.8
@export var sprint_speed: float = 6.3
@export var crouch_speed: float = 2.1
@export var acceleration: float = 14.0
@export var deceleration: float = 18.0

@export_group("Stamina")
@export var max_stamina: float = 5.5
@export var sprint_stamina_drain_per_second: float = 1.35
@export var stamina_recover_per_second: float = 0.9
@export var stamina_recover_delay: float = 0.4
@export var exhausted_stamina_threshold: float = 1.4
@export var breathing_rise_speed: float = 2.5
@export var breathing_fall_speed: float = 1.1

@export_group("Look")
@export var mouse_sensitivity: float = 0.08
@export var touch_sensitivity: float = 0.11
@export var min_pitch: float = -80.0
@export var max_pitch: float = 72.0

@export_group("Crouch")
@export var standing_head_height: float = 1.65
@export var crouching_head_height: float = 1.1
@export var crouch_transition_speed: float = 7.5
@export var standing_shape_height: float = 1.1
@export var crouching_shape_height: float = 0.4

@export_group("Flashlight")
@export var max_flashlight_battery: float = 90.0
@export var flashlight_drain_per_second: float = 1.0

@export_group("Interaction")
@export var interact_distance: float = 2.5

@onready var head: Node3D = $Head
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var inventory: InventoryComponent = $Inventory

var current_noise_level: float = 0.0

var _pitch_degrees: float = 0.0
var _is_crouching: bool = false
var _is_sprinting: bool = false
var _flashlight_battery: float = 0.0
var _stamina: float = 0.0
var _stamina_recover_cooldown: float = 0.0
var _is_exhausted: bool = false
var _breathing_intensity: float = 0.0
var _controls_locked: bool = false


func _ready() -> void:
	_ensure_default_input_map()
	_flashlight_battery = max_flashlight_battery
	_stamina = max_stamina
	if not is_in_group("player"):
		add_to_group("player")
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interaction_ray.target_position = Vector3(0.0, 0.0, -interact_distance)
	_sync_flashlight_visual()


func _unhandled_input(event: InputEvent) -> void:
	if _controls_locked:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative.x * mouse_sensitivity, event.relative.y * mouse_sensitivity)
	elif event is InputEventScreenDrag:
		_apply_look(event.relative.x * touch_sensitivity, event.relative.y * touch_sensitivity)

	if event.is_action_pressed("flashlight_toggle"):
		_toggle_flashlight()

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if _controls_locked:
		velocity = Vector3.ZERO
		current_noise_level = 0.0
		return

	_update_crouch(delta)
	_update_flashlight(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()

	var sprint_requested := Input.is_action_pressed("sprint") and not _is_crouching and input_vector.y < -0.1
	var sprinting := _update_stamina(delta, sprint_requested)
	_is_sprinting = sprinting
	var current_speed := walk_speed
	if sprinting:
		current_speed = sprint_speed
	elif _is_crouching:
		current_speed = crouch_speed

	var target_velocity := move_direction * current_speed
	var blend := acceleration if move_direction.length() > 0.0 else deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, blend * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, blend * delta)

	current_noise_level = _compute_noise_level(input_vector.length(), sprinting, _breathing_intensity)

	move_and_slide()


func _apply_look(delta_yaw: float, delta_pitch: float) -> void:
	rotate_y(deg_to_rad(-delta_yaw))
	_pitch_degrees = clamp(_pitch_degrees - delta_pitch, min_pitch, max_pitch)
	head.rotation_degrees.x = _pitch_degrees


func _update_crouch(delta: float) -> void:
	_is_crouching = Input.is_action_pressed("crouch")

	var target_head_y := crouching_head_height if _is_crouching else standing_head_height
	head.position.y = move_toward(head.position.y, target_head_y, crouch_transition_speed * delta)

	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule:
		var target_capsule_height := crouching_shape_height if _is_crouching else standing_shape_height
		capsule.height = move_toward(capsule.height, target_capsule_height, crouch_transition_speed * delta)
		collision_shape.position.y = capsule.radius + (capsule.height * 0.5)


func _update_flashlight(delta: float) -> void:
	if not flashlight.visible:
		return

	_flashlight_battery = max(_flashlight_battery - flashlight_drain_per_second * delta, 0.0)
	if _flashlight_battery <= 0.0:
		flashlight.visible = false


func _toggle_flashlight() -> void:
	if _flashlight_battery <= 0.0:
		return
	flashlight.visible = not flashlight.visible
	# Play flashlight SFX
	var audio_mgr := get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx"):
		if flashlight.visible:
			audio_mgr.call("play_sfx", "flashlight_on")
		else:
			audio_mgr.call("play_sfx", "flashlight_off")


func _sync_flashlight_visual() -> void:
	flashlight.visible = _flashlight_battery > 0.0


func _update_stamina(delta: float, sprint_requested: bool) -> bool:
	var sprinting: bool = false

	if sprint_requested and not _is_exhausted and _stamina > 0.0:
		sprinting = true
		_stamina = max(_stamina - sprint_stamina_drain_per_second * delta, 0.0)
		_stamina_recover_cooldown = stamina_recover_delay
		if _stamina <= 0.0:
			_is_exhausted = true
	else:
		if _stamina_recover_cooldown > 0.0:
			_stamina_recover_cooldown = max(_stamina_recover_cooldown - delta, 0.0)
		else:
			_stamina = min(_stamina + stamina_recover_per_second * delta, max_stamina)
			if _is_exhausted and _stamina >= exhausted_stamina_threshold:
				_is_exhausted = false

	_update_breathing(delta, sprinting)
	return sprinting


func _update_breathing(delta: float, sprinting: bool) -> void:
	var stamina_pressure: float = 1.0 - get_stamina_ratio()
	var target_intensity: float = clampf(stamina_pressure * 1.1, 0.0, 1.0)

	if sprinting:
		target_intensity = minf(target_intensity + 0.25, 1.0)
	if _is_exhausted:
		target_intensity = minf(target_intensity + 0.35, 1.0)

	var speed: float = breathing_rise_speed if target_intensity > _breathing_intensity else breathing_fall_speed
	_breathing_intensity = move_toward(_breathing_intensity, target_intensity, speed * delta)


func _compute_noise_level(input_strength: float, sprinting: bool, breathing_intensity: float) -> float:
	var movement_noise: float = 0.0
	if input_strength >= 0.1:
		if sprinting:
			movement_noise = 1.0
		elif _is_crouching:
			movement_noise = 0.3
		else:
			movement_noise = 0.65

	var breathing_noise: float = breathing_intensity * 0.45
	if input_strength < 0.1:
		breathing_noise *= 0.65

	return clampf(movement_noise + breathing_noise, 0.0, 1.2)


func _try_interact() -> void:
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return

	var collider: Variant = interaction_ray.get_collider()
	if collider and collider.has_method("interact"):
		collider.interact(self)


func get_flashlight_battery_ratio() -> float:
	if max_flashlight_battery <= 0.0:
		return 0.0
	return _flashlight_battery / max_flashlight_battery


func add_flashlight_battery(charge_amount: float) -> float:
	var resolved_charge: float = maxf(charge_amount, 0.0)
	_flashlight_battery = minf(_flashlight_battery + resolved_charge, max_flashlight_battery)
	_sync_flashlight_visual()
	return _flashlight_battery


func get_stamina_ratio() -> float:
	if max_stamina <= 0.0:
		return 0.0
	return _stamina / max_stamina


func get_breathing_intensity() -> float:
	return _breathing_intensity


func is_exhausted() -> bool:
	return _is_exhausted


func is_sprinting() -> bool:
	return _is_sprinting


func is_crouching() -> bool:
	return _is_crouching


func get_noise_level() -> float:
	return current_noise_level


func add_inventory_item(item_id: String, amount: int = 1) -> int:
	if not inventory:
		return 0
	return inventory.add_item(item_id, amount)


func has_inventory_item(item_id: String, amount: int = 1) -> bool:
	if not inventory:
		return false
	return inventory.has_item(item_id, amount)


func consume_inventory_item(item_id: String, amount: int = 1) -> bool:
	if not inventory:
		return false
	return inventory.consume_item(item_id, amount)


func get_inventory_item_count(item_id: String) -> int:
	if not inventory:
		return 0
	return inventory.get_item_count(item_id)


func add_note_entry(note_id: String, note_text: String) -> bool:
	if not inventory:
		return false
	return inventory.add_note(note_id, note_text)


func get_note_count() -> int:
	if not inventory:
		return 0
	return inventory.get_note_count()


func show_status_message(message: String, duration: float = 2.2) -> void:
	status_message_requested.emit(message, duration)


func set_controls_locked(locked: bool) -> void:
	_controls_locked = locked
	if locked:
		velocity = Vector3.ZERO
		current_noise_level = 0.0


func _ensure_default_input_map() -> void:
	_ensure_action("move_forward")
	_bind_key_to_action("move_forward", KEY_W as Key)
	_bind_key_to_action("move_forward", KEY_UP as Key)

	_ensure_action("move_back")
	_bind_key_to_action("move_back", KEY_S as Key)
	_bind_key_to_action("move_back", KEY_DOWN as Key)

	_ensure_action("move_left")
	_bind_key_to_action("move_left", KEY_A as Key)
	_bind_key_to_action("move_left", KEY_LEFT as Key)

	_ensure_action("move_right")
	_bind_key_to_action("move_right", KEY_D as Key)
	_bind_key_to_action("move_right", KEY_RIGHT as Key)

	_ensure_action("sprint")
	_bind_key_to_action("sprint", KEY_SHIFT as Key)

	_ensure_action("crouch")
	_bind_key_to_action("crouch", KEY_CTRL as Key)
	_bind_key_to_action("crouch", KEY_C as Key)

	_ensure_action("flashlight_toggle")
	_bind_key_to_action("flashlight_toggle", KEY_F as Key)

	_ensure_action("interact")
	_bind_key_to_action("interact", KEY_E as Key)


func _ensure_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)


func _bind_key_to_action(action_name: String, keycode: Key) -> void:
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = keycode
	key_event.keycode = keycode

	if not InputMap.action_has_event(action_name, key_event):
		InputMap.action_add_event(action_name, key_event)


func get_save_state() -> Dictionary:
	var state = {
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"pos_z": global_position.z,
		"rot_y": global_rotation.y,
		"flashlight_battery": _flashlight_battery,
		"stamina": _stamina,
		"inventory": {}
	}
	if inventory:
		state["inventory"] = inventory.get_save_state()
	return state


func restore_save_state(data: Dictionary) -> void:
	if data.has("flashlight_battery"):
		_flashlight_battery = data["flashlight_battery"]
	if data.has("stamina"):
		_stamina = data["stamina"]
		if _stamina <= 0.0:
			_is_exhausted = true
	
	if data.has("inventory") and inventory:
		inventory.restore_save_state(data["inventory"])
	
	_sync_flashlight_visual()
