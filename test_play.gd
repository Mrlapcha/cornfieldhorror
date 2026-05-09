extends SceneTree
var player
var timer = 0.0
func _init():
	player = AudioStreamPlayer.new()
	root.add_child(player)
	var stream = load("res://assets/audio/sfx/footsteps_walk.wav")
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream = stream
	player.play()
	print("Started playing.")
func _process(delta):
	timer += delta
	if timer > 3.0:
		print("Is playing after 3s? ", player.playing)
		quit()
