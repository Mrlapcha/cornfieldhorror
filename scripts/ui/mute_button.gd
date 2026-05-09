extends TextureButton

var mute_icon: Texture2D = preload("res://assets/ui/icons/volume_off.svg")
var unmute_icon: Texture2D = preload("res://assets/ui/icons/volume_on.svg")

func _ready() -> void:
	texture_normal = mute_icon if AudioManager.is_muted() else unmute_icon
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var currently_muted = AudioManager.toggle_mute()
	texture_normal = mute_icon if currently_muted else unmute_icon
