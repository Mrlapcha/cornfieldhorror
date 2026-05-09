extends SceneTree
func _init():
	print("Checking res://assets/audio/sfx/breathing_slow.wav: ", ResourceLoader.exists("res://assets/audio/sfx/breathing_slow.wav"))
	print("Checking res://assets/audio/sfx/button_click.wav: ", ResourceLoader.exists("res://assets/audio/sfx/button_click.wav"))
	quit()
