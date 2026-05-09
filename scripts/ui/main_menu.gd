extends Control

## MainMenu — Title screen with Play, Settings, and Quit buttons.

@onready var continue_btn: Button = $VBoxContainer/ContinueBtn
@onready var new_game_btn: Button = $VBoxContainer/NewGameBtn
@onready var settings_btn: Button = $VBoxContainer/SettingsBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var music_slider: HSlider = $SettingsPanel/SettingsVBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/SettingsVBox/SfxRow/SfxSlider
@onready var back_btn: Button = $SettingsPanel/SettingsVBox/BackBtn

var _cinzel_font: Font
var _barlow_font: Font


func _ready() -> void:
	_load_fonts()
	_apply_theme()
	settings_panel.visible = false

	continue_btn.pressed.connect(_on_continue)
	new_game_btn.pressed.connect(_on_new_game)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	back_btn.pressed.connect(_on_back)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	_init_slider_values()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if SaveManager.has_savegame():
		continue_btn.visible = true
	else:
		continue_btn.visible = false


func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf"):
		_cinzel_font = load("res://assets/fonts/Cinzel.ttf")
	if ResourceLoader.exists("res://assets/fonts/Barlow-Regular.ttf"):
		_barlow_font = load("res://assets/fonts/Barlow-Regular.ttf")


func _apply_theme() -> void:
	var bg := $Background as ColorRect
	bg.color = Color(0.02, 0.02, 0.04, 1.0)

	var title := $TitleLabel as Label
	if _cinzel_font:
		title.add_theme_font_override("font", _cinzel_font)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55, 1.0))

	var subtitle := $SubtitleLabel as Label
	if _barlow_font:
		subtitle.add_theme_font_override("font", _barlow_font)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42, 0.8))

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
	btn_style.content_margin_left = 32.0
	btn_style.content_margin_right = 32.0
	btn_style.content_margin_top = 12.0
	btn_style.content_margin_bottom = 12.0

	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.12, 0.11, 0.14, 0.95)
	btn_hover.border_color = Color(0.85, 0.78, 0.55, 0.7)

	var btn_pressed := btn_style.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.06, 0.06, 0.08, 1.0)

	for btn: Button in [continue_btn, new_game_btn, settings_btn, quit_btn, back_btn]:
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.95, 0.88, 0.65, 1.0))
		btn.add_theme_font_size_override("font_size", 24)
		if _cinzel_font:
			btn.add_theme_font_override("font", _cinzel_font)

	var settings_style := StyleBoxFlat.new()
	settings_style.bg_color = Color(0.04, 0.04, 0.06, 0.95)
	settings_style.border_width_left = 1
	settings_style.border_width_right = 1
	settings_style.border_width_top = 1
	settings_style.border_width_bottom = 1
	settings_style.border_color = Color(0.4, 0.38, 0.3, 0.5)
	settings_style.corner_radius_top_left = 6
	settings_style.corner_radius_top_right = 6
	settings_style.corner_radius_bottom_left = 6
	settings_style.corner_radius_bottom_right = 6
	settings_style.content_margin_left = 24.0
	settings_style.content_margin_right = 24.0
	settings_style.content_margin_top = 16.0
	settings_style.content_margin_bottom = 16.0
	settings_panel.add_theme_stylebox_override("panel", settings_style)

	var settings_title := $SettingsPanel/SettingsVBox/SettingsTitle as Label
	if _cinzel_font:
		settings_title.add_theme_font_override("font", _cinzel_font)
	settings_title.add_theme_font_size_override("font_size", 28)
	settings_title.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68, 1.0))

	var label_color := Color(0.6, 0.58, 0.52, 0.9)
	for node_path in ["MusicRow/MusicLabel", "SfxRow/SfxLabel"]:
		var lbl := settings_panel.get_node("SettingsVBox/" + node_path) as Label
		if lbl:
			lbl.add_theme_color_override("font_color", label_color)
			lbl.add_theme_font_size_override("font_size", 20)
			if _barlow_font:
				lbl.add_theme_font_override("font", _barlow_font)


func _init_slider_values() -> void:
	var profile = SaveManager.load_profile()
	var music_val = profile.get("music_vol", 0.5)
	var sfx_val = profile.get("sfx_vol", 0.8)

	music_slider.value = music_val
	sfx_slider.value = sfx_val

	_on_music_volume_changed(music_val)
	_on_sfx_volume_changed(sfx_val)


func _on_continue() -> void:
	SaveManager.load_game()
	SaveManager.is_loading_save = true
	_start_game()


func _on_new_game() -> void:
	SaveManager.delete_savegame()
	SaveManager.is_loading_save = false
	_start_game()


func _start_game() -> void:
	visible = false
	var audio_mgr := get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "button_click")
		# Wait for sound to play before changing scenes
		await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/ui/LoadingScreen.tscn")


func _on_settings() -> void:
	settings_panel.visible = true
	$VBoxContainer.visible = false


func _on_back() -> void:
	settings_panel.visible = false
	$VBoxContainer.visible = true


func _on_quit() -> void:
	get_tree().quit()


func _on_music_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	var ambient_idx := AudioServer.get_bus_index("Ambient")
	if ambient_idx >= 0:
		AudioServer.set_bus_volume_db(ambient_idx, linear_to_db(value))

	var profile = SaveManager.load_profile()
	profile["music_vol"] = value
	SaveManager.save_profile(profile)


func _on_sfx_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	var voice_idx := AudioServer.get_bus_index("Voice")
	if voice_idx >= 0:
		AudioServer.set_bus_volume_db(voice_idx, linear_to_db(value))

	var profile = SaveManager.load_profile()
	profile["sfx_vol"] = value
	SaveManager.save_profile(profile)
