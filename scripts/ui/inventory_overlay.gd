extends CanvasLayer

@export var player_group_name: StringName = &"player"
@export var required_keys_for_barn: int = 3

@onready var hud_panel: PanelContainer = $TopLeftMargin/HudPanel
@onready var title_label: Label = $TopLeftMargin/HudPanel/HudVBox/Title
@onready var keys_label: Label = $TopLeftMargin/HudPanel/HudVBox/KeysRow/KeysLabel
@onready var keys_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/KeysRow/KeysValue
@onready var notes_label: Label = $TopLeftMargin/HudPanel/HudVBox/NotesRow/NotesLabel
@onready var notes_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/NotesRow/NotesValue
@onready var flashlight_label: Label = $TopLeftMargin/HudPanel/HudVBox/FlashlightRow/FlashlightLabel
@onready var flashlight_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/FlashlightRow/FlashlightValue
@onready var batteries_label: Label = $TopLeftMargin/HudPanel/HudVBox/BatteriesRow/BatteriesLabel
@onready var batteries_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/BatteriesRow/BatteriesValue
@onready var matches_label: Label = $TopLeftMargin/HudPanel/HudVBox/MatchesRow/MatchesLabel
@onready var matches_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/MatchesRow/MatchesValue
@onready var fuel_label: Label = $TopLeftMargin/HudPanel/HudVBox/FuelRow/FuelLabel
@onready var fuel_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/FuelRow/FuelValue
@onready var music_box_label: Label = $TopLeftMargin/HudPanel/HudVBox/MusicBoxRow/MusicBoxLabel
@onready var music_box_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/MusicBoxRow/MusicBoxValue
@onready var objective_label: Label = $TopLeftMargin/HudPanel/HudVBox/ObjectiveRow/ObjectiveLabel
@onready var objective_value_label: Label = $TopLeftMargin/HudPanel/HudVBox/ObjectiveRow/ObjectiveValue
@onready var stamina_label: Label = $TopLeftMargin/HudPanel/HudVBox/StaminaRow/StaminaLabel
@onready var stamina_bar_bg: ColorRect = $TopLeftMargin/HudPanel/HudVBox/StaminaRow/StaminaBarBG
@onready var stamina_bar_fill: ColorRect = $TopLeftMargin/HudPanel/HudVBox/StaminaRow/StaminaBarBG/StaminaBarFill
@onready var crosshair_h: ColorRect = $CrosshairCenter/CrosshairH
@onready var crosshair_v: ColorRect = $CrosshairCenter/CrosshairV
@onready var interact_prompt: Label = $InteractPrompt
@onready var message_panel: PanelContainer = $BottomCenter/MessagePanel
@onready var message_label: Label = $BottomCenter/MessagePanel/MessageLabel
@onready var mini_hud: PanelContainer = $MiniHud

# Mini HUD labels
@onready var mini_keys_label: Label = $MiniHud/MiniHBox/MiniKeysLabel
@onready var mini_flashlight_label: Label = $MiniHud/MiniHBox/MiniFlashlightLabel
@onready var mini_stamina_bar: ColorRect = $MiniHud/MiniHBox/MiniStaminaBar
@onready var mini_stamina_fill: ColorRect = $MiniHud/MiniHBox/MiniStaminaBar/MiniStaminaFill
@onready var mini_objective_label: Label = $MiniHud/MiniHBox/MiniObjectiveLabel

# Icon TextureRects (Used)
@onready var _icon_matches: TextureRect = $TopLeftMargin/HudPanel/HudVBox/MatchesRow/MatchesIcon
@onready var _icon_fuel: TextureRect = $TopLeftMargin/HudPanel/HudVBox/FuelRow/FuelIcon
@onready var _icon_musicbox: TextureRect = $TopLeftMargin/HudPanel/HudVBox/MusicBoxRow/MusicBoxIcon

var _player: Node
var _message_time_left: float = 0.0
var _displayed_stamina: float = 1.0
var _hud_open: bool = false
var _barlow_font: Font
var _cinzel_font: Font

const ICON_DIM := Color(0.35, 0.35, 0.38, 0.5)
const ICON_BRIGHT := Color(1.0, 1.0, 1.0, 0.95)
const COLOR_LABEL := Color(0.58, 0.6, 0.65, 0.85)
const COLOR_NOT_FOUND := Color(0.4, 0.4, 0.42, 0.6)
const COLOR_KEY_VALUE := Color(0.92, 0.78, 0.2, 1.0)
const COLOR_NOTE_VALUE := Color(0.82, 0.78, 0.62, 1.0)
const COLOR_BATTERY_VALUE := Color(0.35, 0.88, 0.52, 1.0)
const COLOR_MATCHES_FOUND := Color(0.95, 0.55, 0.18, 1.0)
const COLOR_FUEL_FOUND := Color(0.88, 0.42, 0.2, 1.0)
const COLOR_MUSICBOX_FOUND := Color(0.62, 0.52, 0.88, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_fonts()
	message_panel.visible = false
	interact_prompt.text = ""
	hud_panel.visible = false
	_hud_open = false
	_apply_hud_theme()
	_apply_mini_hud_theme()
	_update_inventory_labels()

	# Register TAB key for toggle
	_ensure_action("toggle_inventory")
	_bind_key_to_action("toggle_inventory", KEY_TAB)
	
	# Make Mini HUD clickable (especially for mobile)
	mini_hud.mouse_filter = Control.MOUSE_FILTER_STOP
	mini_hud.gui_input.connect(_on_mini_hud_gui_input)
	
	# Make full HUD clickable to close it
	hud_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_panel.gui_input.connect(_on_hud_panel_gui_input)

	# Start icons dimmed
	for icon in [_icon_matches, _icon_fuel, _icon_musicbox]:
		if icon:
			icon.modulate = ICON_DIM


func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf"):
		_cinzel_font = load("res://assets/fonts/Cinzel.ttf")
	if ResourceLoader.exists("res://assets/fonts/Barlow-Regular.ttf"):
		_barlow_font = load("res://assets/fonts/Barlow-Regular.ttf")


func _unhandled_input(event: InputEvent) -> void:
	# TAB key to toggle inventory — works even with mouse captured
	if event.is_action_pressed("toggle_inventory"):
		_toggle_hud()
		get_viewport().set_input_as_handled()


func _on_mini_hud_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_toggle_hud()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_toggle_hud()
			get_viewport().set_input_as_handled()


func _on_hud_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_toggle_hud()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_toggle_hud()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_player = _find_player()
		_bind_status_message_signal()

	_update_inventory_labels()
	_update_stamina_bar(delta)
	_update_interact_prompt()
	_update_message_timeout(delta)
	_update_mini_hud()


func _toggle_hud() -> void:
	_hud_open = not _hud_open
	hud_panel.visible = _hud_open
	mini_hud.visible = not _hud_open


func _find_player() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)
	if players.is_empty():
		return null
	return players[0]


func _bind_status_message_signal() -> void:
	if not _player:
		return
	if not _player.has_signal("status_message_requested"):
		return
	var message_callable := Callable(self, "_on_player_status_message_requested")
	if _player.is_connected("status_message_requested", message_callable):
		return
	_player.connect("status_message_requested", message_callable)


func _update_inventory_labels() -> void:
	var key_count: int = _get_inventory_count("key")
	var note_count: int = _get_note_count()
	var battery_pickups: int = _get_inventory_count("battery")
	var flashlight_percent: int = int(round(_get_flashlight_ratio() * 100.0))
	var matches_count: int = _get_inventory_count("matches")
	var fuel_count: int = _get_inventory_count("fuel_can")
	var music_box_count: int = _get_inventory_count("music_box")

	keys_value_label.text = "%d / %d" % [key_count, required_keys_for_barn]
	notes_value_label.text = str(note_count)
	batteries_value_label.text = str(battery_pickups)
	flashlight_value_label.text = "%d%%" % clampi(flashlight_percent, 0, 100)

	matches_value_label.text = "FOUND" if matches_count > 0 else ""
	fuel_value_label.text = "FOUND" if fuel_count > 0 else ""
	music_box_value_label.text = "FOUND" if music_box_count > 0 else ""

	_set_item_state(_icon_matches, matches_value_label, matches_count > 0, COLOR_MATCHES_FOUND)
	_set_item_state(_icon_fuel, fuel_value_label, fuel_count > 0, COLOR_FUEL_FOUND)
	_set_item_state(_icon_musicbox, music_box_value_label, music_box_count > 0, COLOR_MUSICBOX_FOUND)

	if flashlight_percent <= 15:
		flashlight_value_label.add_theme_color_override("font_color", Color(0.95, 0.28, 0.22, 1.0))
	elif flashlight_percent <= 40:
		flashlight_value_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.2, 1.0))
	else:
		flashlight_value_label.add_theme_color_override("font_color", Color(0.65, 0.92, 0.72, 1.0))

	if key_count >= required_keys_for_barn:
		objective_value_label.text = "Go to barn"
		objective_value_label.add_theme_color_override("font_color", Color(0.35, 0.88, 0.52, 1.0))
	else:
		objective_value_label.text = "Find %d keys" % required_keys_for_barn
		objective_value_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.28, 1.0))


func _set_item_state(icon: TextureRect, value_label: Label, found: bool, found_color: Color) -> void:
	if not icon or not value_label:
		return
	if found:
		icon.modulate = ICON_BRIGHT
		value_label.add_theme_color_override("font_color", found_color)
	else:
		icon.modulate = ICON_DIM
		value_label.add_theme_color_override("font_color", COLOR_NOT_FOUND)


func _update_stamina_bar(delta: float) -> void:
	var target_ratio: float = _get_stamina_ratio()
	_displayed_stamina = move_toward(_displayed_stamina, target_ratio, 2.5 * delta)
	stamina_bar_fill.anchor_right = clampf(_displayed_stamina, 0.0, 1.0)

	var is_exhausted: bool = _get_is_exhausted()
	if is_exhausted:
		stamina_bar_fill.color = Color(0.45, 0.45, 0.5, 0.7)
		mini_stamina_fill.color = Color(0.45, 0.45, 0.5, 0.7)
		stamina_label.add_theme_color_override("font_color", Color(0.65, 0.45, 0.42, 1.0))
	elif _displayed_stamina <= 0.25:
		stamina_bar_fill.color = Color(0.92, 0.28, 0.2, 0.9)
		mini_stamina_fill.color = Color(0.92, 0.28, 0.2, 0.9)
		stamina_label.add_theme_color_override("font_color", Color(0.92, 0.55, 0.45, 1.0))
	elif _displayed_stamina <= 0.55:
		stamina_bar_fill.color = Color(0.92, 0.72, 0.18, 0.9)
		mini_stamina_fill.color = Color(0.92, 0.72, 0.18, 0.9)
		stamina_label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.55, 1.0))
	else:
		stamina_bar_fill.color = Color(0.3, 0.82, 0.45, 0.9)
		mini_stamina_fill.color = Color(0.3, 0.82, 0.45, 0.9)
		stamina_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.75, 1.0))


func _update_mini_hud() -> void:
	if _hud_open:
		return
	var key_count := _get_inventory_count("key")
	var flashlight_percent := int(round(_get_flashlight_ratio() * 100.0))
	mini_keys_label.text = "KEYS  %d / %d" % [key_count, required_keys_for_barn]
	mini_flashlight_label.text = "LIGHT  %d%%" % clampi(flashlight_percent, 0, 100)
	mini_stamina_fill.anchor_right = clampf(_displayed_stamina, 0.0, 1.0)

	if key_count >= required_keys_for_barn:
		mini_objective_label.text = "GO TO BARN"
		mini_objective_label.add_theme_color_override("font_color", Color(0.35, 0.88, 0.52, 1.0))
	else:
		mini_objective_label.text = "Find keys"
		mini_objective_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.28, 0.8))


func _update_interact_prompt() -> void:
	if not _player:
		interact_prompt.text = ""
		return

	var ray: RayCast3D = null
	if _player.has_method("get_node_or_null"):
		ray = _player.get_node_or_null("Head/Camera3D/InteractionRay") as RayCast3D

	if not ray or not ray.is_colliding():
		interact_prompt.text = ""
		_set_crosshair_color(Color(0.85, 0.85, 0.85, 0.4))
		return

	var collider: Variant = ray.get_collider()
	if collider and collider is Node and collider.has_method("get_interact_prompt"):
		var prompt: String = str(collider.call("get_interact_prompt"))
		var is_touch := _is_touch_active()
		if is_touch:
			interact_prompt.text = "TAP  %s" % prompt
		else:
			interact_prompt.text = "[E]  %s" % prompt
		interact_prompt.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65, 0.95))
		_set_crosshair_color(Color(0.95, 0.82, 0.3, 0.85))
	else:
		interact_prompt.text = ""
		_set_crosshair_color(Color(0.85, 0.85, 0.85, 0.4))


func _is_touch_active() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


func _set_crosshair_color(color: Color) -> void:
	crosshair_h.color = color
	crosshair_v.color = color


func _get_inventory_count(item_id: String) -> int:
	if not _player:
		return 0
	if not _player.has_method("get_inventory_item_count"):
		return 0
	return int(_player.call("get_inventory_item_count", item_id))


func _get_note_count() -> int:
	if not _player:
		return 0
	if not _player.has_method("get_note_count"):
		return 0
	return int(_player.call("get_note_count"))


func _get_flashlight_ratio() -> float:
	if not _player:
		return 0.0
	if not _player.has_method("get_flashlight_battery_ratio"):
		return 0.0
	return float(_player.call("get_flashlight_battery_ratio"))


func _get_stamina_ratio() -> float:
	if not _player:
		return 1.0
	if not _player.has_method("get_stamina_ratio"):
		return 1.0
	return float(_player.call("get_stamina_ratio"))


func _get_is_exhausted() -> bool:
	if not _player:
		return false
	if not _player.has_method("is_exhausted"):
		return false
	return bool(_player.call("is_exhausted"))


func _on_player_status_message_requested(message: String, duration: float) -> void:
	if message.is_empty():
		return
	message_label.text = message
	message_panel.visible = true
	_message_time_left = maxf(duration, 0.2)


func _update_message_timeout(delta: float) -> void:
	if not message_panel.visible:
		return
	_message_time_left = maxf(_message_time_left - delta, 0.0)
	if _message_time_left <= 0.0:
		message_panel.visible = false


func _ensure_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)


func _bind_key_to_action(action_name: String, keycode: Key) -> void:
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and (existing_event as InputEventKey).keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action_name, ev)


func _apply_mini_hud_theme() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.7)
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.32, 0.28, 0.4)
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	mini_hud.add_theme_stylebox_override("panel", style)

	var lbl_color := Color(0.72, 0.68, 0.58, 0.9)
	for lbl in [mini_keys_label, mini_flashlight_label, mini_objective_label]:
		if lbl:
			lbl.add_theme_color_override("font_color", lbl_color)
			lbl.add_theme_font_size_override("font_size", 16)
			if _barlow_font:
				lbl.add_theme_font_override("font", _barlow_font)


func _apply_hud_theme() -> void:
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0.04, 0.04, 0.06, 0.78)
	hud_style.border_width_left = 1
	hud_style.border_width_right = 1
	hud_style.border_width_top = 1
	hud_style.border_width_bottom = 1
	hud_style.border_color = Color(0.35, 0.32, 0.28, 0.5)
	hud_style.corner_radius_top_left = 6
	hud_style.corner_radius_top_right = 6
	hud_style.corner_radius_bottom_left = 6
	hud_style.corner_radius_bottom_right = 6
	hud_style.content_margin_left = 14.0
	hud_style.content_margin_right = 14.0
	hud_style.content_margin_top = 10.0
	hud_style.content_margin_bottom = 10.0
	hud_panel.add_theme_stylebox_override("panel", hud_style)

	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.3, 0.32, 0.38, 0.2)
	sep_style.content_margin_top = 2.0
	sep_style.content_margin_bottom = 2.0
	for child in $TopLeftMargin/HudPanel/HudVBox.get_children():
		if child is HSeparator:
			child.add_theme_stylebox_override("separator", sep_style)

	# Title
	if _cinzel_font:
		title_label.add_theme_font_override("font", _cinzel_font)
	title_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58, 0.9))
	title_label.add_theme_font_size_override("font_size", 16)

	# Row labels — Barlow font, readable size
	for lbl in [keys_label, notes_label, flashlight_label, batteries_label, matches_label, fuel_label, music_box_label, objective_label, stamina_label]:
		if lbl:
			lbl.add_theme_color_override("font_color", COLOR_LABEL)
			lbl.add_theme_font_size_override("font_size", 15)
			if _barlow_font:
				lbl.add_theme_font_override("font", _barlow_font)

	# Value labels
	for lbl in [keys_value_label, notes_value_label, batteries_value_label, flashlight_value_label, matches_value_label, fuel_value_label, music_box_value_label, objective_value_label]:
		if lbl:
			lbl.add_theme_font_size_override("font_size", 15)
			if _barlow_font:
				lbl.add_theme_font_override("font", _barlow_font)

	keys_value_label.add_theme_color_override("font_color", COLOR_KEY_VALUE)
	notes_value_label.add_theme_color_override("font_color", COLOR_NOTE_VALUE)
	batteries_value_label.add_theme_color_override("font_color", COLOR_BATTERY_VALUE)

	# Message panel
	var msg_style := StyleBoxFlat.new()
	msg_style.bg_color = Color(0.03, 0.03, 0.05, 0.82)
	msg_style.border_width_left = 1
	msg_style.border_width_right = 1
	msg_style.border_width_top = 1
	msg_style.border_width_bottom = 1
	msg_style.border_color = Color(0.45, 0.42, 0.32, 0.5)
	msg_style.corner_radius_top_left = 5
	msg_style.corner_radius_top_right = 5
	msg_style.corner_radius_bottom_left = 5
	msg_style.corner_radius_bottom_right = 5
	msg_style.content_margin_left = 20.0
	msg_style.content_margin_right = 20.0
	msg_style.content_margin_top = 10.0
	msg_style.content_margin_bottom = 10.0
	message_panel.add_theme_stylebox_override("panel", msg_style)

	message_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.75, 1.0))
	message_label.add_theme_font_size_override("font_size", 18)
	if _barlow_font:
		message_label.add_theme_font_override("font", _barlow_font)

	# Interact prompt
	interact_prompt.add_theme_font_size_override("font_size", 18)
	interact_prompt.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 0.9))
	if _barlow_font:
		interact_prompt.add_theme_font_override("font", _barlow_font)
