extends SceneTree
var player
var timer = 0.0
func _init():
	player = AudioStreamPlayer.new()
	var root = get_root()
	root.add_child(player)
	var stream = load("res://assets/audio/ambient/creepy_ambience.wav")
	player.stream = stream
	player.play()
	print("Stream format: ", stream.format)
	print("Is playing? ", player.playing)
func _process(delta):
	timer += delta
	if timer > 1.0:
		print("Is playing after 1s? ", player.playing)
		quit()
