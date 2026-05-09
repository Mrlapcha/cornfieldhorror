extends CanvasLayer

@onready var blocker: ColorRect = $Blocker
@onready var panel: PanelContainer = $Center/EndingPanel
@onready var title_label: Label = $Center/EndingPanel/EndingVBox/Title
@onready var ending_name_label: Label = $Center/EndingPanel/EndingVBox/EndingName
@onready var description_label: Label = $Center/EndingPanel/EndingVBox/Description
@onready var button_container: HBoxContainer = $Center/EndingPanel/EndingVBox/ButtonContainer
@onready var restart_btn: Button = $Center/EndingPanel/EndingVBox/ButtonContainer/RestartBtn
@onready var menu_btn: Button = $Center/EndingPanel/EndingVBox/ButtonContainer/MenuBtn

var _visible_ending: bool = false
var _cinzel_font: Font
var _barlow_font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_load_fonts()

	restart_btn.pressed.connect(_restart_scene)
	menu_btn.pressed.connect(_return_to_menu)


func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf"):
		_cinzel_font = load("res://assets/fonts/Cinzel.ttf")
	if ResourceLoader.exists("res://assets/fonts/Barlow-Regular.ttf"):
		_barlow_font = load("res://assets/fonts/Barlow-Regular.ttf")


func show_ending(ending_id: String, title: String, description: String, accent_color: Color) -> void:
	visible = true
	_visible_ending = true

	# Ensure mouse is visible for clicking buttons
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	title_label.text = "ENDING"
	ending_name_label.text = title
	description_label.text = description

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.03, 0.04, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = accent_color
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", panel_style)

	# Apply fonts
	if _cinzel_font:
		title_label.add_theme_font_override("font", _cinzel_font)
		ending_name_label.add_theme_font_override("font", _cinzel_font)
	if _barlow_font:
		description_label.add_theme_font_override("font", _barlow_font)

	title_label.add_theme_color_override("font_color", Color(0.84, 0.84, 0.86, 1.0))
	title_label.add_theme_font_size_override("font_size", 24)
	ending_name_label.add_theme_color_override("font_color", accent_color)
	ending_name_label.add_theme_font_size_override("font_size", 48)
	description_label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93, 1.0))
	description_label.add_theme_font_size_override("font_size", 20)

	# Style buttons
	_style_ending_button(restart_btn, accent_color)
	_style_ending_button(menu_btn, Color(0.5, 0.5, 0.52, 0.8))

	print("Ending triggered: %s (%s)" % [title, ending_id])


func _style_ending_button(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.9)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = color * Color(1, 1, 1, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	hover.border_color = color

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.95))
	btn.add_theme_font_size_override("font_size", 24)
	if _cinzel_font:
		btn.add_theme_font_override("font", _cinzel_font)


func _unhandled_input(event: InputEvent) -> void:
	if not _visible_ending:
		return

	# Keep R key for desktop convenience
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
			_restart_scene()


func _restart_scene() -> void:
	_visible_ending = false
	# Reset audio before reload — AudioManager persists as autoload
	var audio_mgr := get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("reset_audio"):
		audio_mgr.call("reset_audio")
	get_tree().reload_current_scene()


func _return_to_menu() -> void:
	_visible_ending = false
	var audio_mgr := get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("reset_audio"):
		audio_mgr.call("reset_audio")
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
