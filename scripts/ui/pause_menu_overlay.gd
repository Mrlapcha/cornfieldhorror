extends CanvasLayer

@onready var resume_btn: Button = $CenterContainer/VBoxContainer/ResumeBtn
@onready var main_menu_btn: Button = $CenterContainer/VBoxContainer/MainMenuBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitBtn
@onready var title: Label = $CenterContainer/VBoxContainer/Title

var _cinzel_font: Font
var _barlow_font: Font


func _ready() -> void:
	visible = false
	_load_fonts()
	_apply_theme()

	resume_btn.pressed.connect(_on_resume)
	main_menu_btn.pressed.connect(_on_main_menu)
	quit_btn.pressed.connect(_on_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()


func _pause_game() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	visible = true

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_resume() -> void:
	visible = false
	get_tree().paused = false

	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _save_current_game() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_save_state"):
		SaveManager.current_save_data["player"] = player.get_save_state()
		SaveManager.save_game(SaveManager.current_save_data)


func _on_main_menu() -> void:
	_save_current_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_quit() -> void:
	_save_current_game()
	get_tree().quit()


func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf"):
		_cinzel_font = load("res://assets/fonts/Cinzel.ttf")
	if ResourceLoader.exists("res://assets/fonts/Barlow-Regular.ttf"):
		_barlow_font = load("res://assets/fonts/Barlow-Regular.ttf")


func _apply_theme() -> void:
	if _cinzel_font:
		title.add_theme_font_override("font", _cinzel_font)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55, 1.0))

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.4, 0.38, 0.3, 0.6)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_top = 12.0
	btn_style.content_margin_bottom = 12.0

	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.12, 0.11, 0.14, 0.95)
	btn_hover.border_color = Color(0.85, 0.78, 0.55, 0.7)

	var btn_pressed := btn_style.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.06, 0.06, 0.08, 1.0)

	for btn: Button in [resume_btn, main_menu_btn, quit_btn]:
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.95, 0.88, 0.65, 1.0))
		btn.add_theme_font_size_override("font_size", 24)
		if _cinzel_font:
			btn.add_theme_font_override("font", _cinzel_font)
